import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:drun/drun.dart';
import 'package:dexeca/dexeca.dart';
import 'package:path/path.dart' as p;

Future<void> main(argv) async => drun(argv);

/// Builds the golang shared library for all supported targets
Future<void> build() async {
  await Future.wait([
    buildLinuxGlibc(),
    buildMacos(),
  ]);
}

/// Builds the linux glibc version of the golang shared library
///
/// Hoping that one day dartlang will support musl :)
Future<void> buildLinuxGlibc() async {
  await dexeca('docker', [
    'run',
    '--rm',
    '-v',
    '${p.current}:/app',
    '--entrypoint',
    'go',
    'golang:${await _parseVersionFile('go')}',
    'build',
    '-v',
    '--buildmode',
    'c-shared',
    '-o',
    '/app/lib/src/linux-glibc-x64.so',
    '/app/lib/src/exec.go',
  ]);
}

/// Builds the macos version of the golang shared library
Future<void> buildMacos() async {
  await dexeca('docker', [
    'run',
    '--rm',
    '-v',
    '${p.current}:/app',
    '--entrypoint',
    'go',
    '-e',
    'GOOS=darwin',
    '-e',
    'GOARCH=amd64',
    '-e',
    'CGO_ENABLED=1',
    '-e',
    'CC=o64-clang',
    '-e',
    'CXX=o64-clang++',
    'crazymax/xgo:${await _parseVersionFile('go')}',
    'build',
    '-v',
    '--buildmode',
    'c-shared',
    '-o',
    '/app/lib/src/macos-x64.dylib',
    '/app/lib/src/exec.go',
  ]);
}

/// Executes the test suite for all supported targets
///
/// * [noBuild] By default the build is performed before running the test,
///   unless this flag is provided.
Future<void> test([bool noBuild = false]) async {
  await Future.wait([
    testLinuxGlibc(noBuild),
    testMacos(noBuild),
  ]);
}

/// Executes the test suite for the linux glibc target
///
/// * [noBuild] By default the build is performed before running the test,
///   unless this flag is provided.
Future<void> testLinuxGlibc([bool noBuild = false]) async {
  if (!noBuild) {
    await buildLinuxGlibc();
  }

  var build = dexeca('docker', [
    'build',
    p.current,
    '-f',
    '-',
    '-t',
    'dexecve/linux-glibc-test:latest',
  ]);
  build.stdin.write('''
    FROM google/dart:2.7.1
    WORKDIR /app
    COPY ./pubspec.* ./
    RUN pub get
    COPY ./example ./example/
    COPY ./lib ./lib/
    COPY ./test ./test/
  ''');
  await build.stdin.close();
  await build;

  await dexeca('docker', [
    'run',
    '--rm',
    'dexecve/linux-glibc-test:latest',
    'pub',
    'run',
    'test',
  ]);
}

/// Executes the test suite for the macos target
///
/// * [noBuild] By default the build is performed before running the test,
///   unless this flag is provided.
Future<void> testMacos([bool noBuild = false]) async {
  if (!noBuild) {
    await buildMacos();
  }

  // TODO: work out what to do here???
}

/// Gets things ready to perform a release.
///
/// * [nextVersion] Should be a valid semver version number string.
///   see: https://semver.org
///
///   This version number will be used to replace the `0.0.0-semantically-released`
///   placeholder in the files `./pubspec.yaml`, `./bin/drun.dart` &
///   `./lib/src/executor.dart`.
Future<void> releasePrepare(String nextVersion) async {
  await test();
  await _searchReplaceVersion(File(p.absolute('pubspec.yaml')), nextVersion);
}

/// Actually publishes the package to https://pub.dev.
///
/// Beaware that `pub publish` does not really support being used inside a CI
/// pipeline yet. What this does is uses someone's local OAUTH creds which is a
/// bit hacky.
///
/// see: https://github.com/dart-lang/pub/issues/2227
/// also: https://medium.com/evenbit/publishing-dart-packages-with-github-actions-5240068a2f7d
///
/// * [nextVersion] Should be a valid semver version number string.
///   see: https://semver.org
///
/// * [dryRun] If supplied then nothing will actually get published.
///
/// * [accessToken] Get this from your local `credentials.json` file.
///
/// * [refreshToken] Get this from your local `credentials.json` file.
///
/// * [oAuthExpiration] Get this from your local `credentials.json` file.
Future<void> releasePublish(
  String nextVersion,
  bool dryRun, [
  @Env('PUB_OAUTH_ACCESS_TOKEN') String accessToken = '',
  @Env('PUB_OAUTH_REFRESH_TOKEN') String refreshToken = '',
  @Env('PUB_OAUTH_EXPIRATION') int oAuthExpiration = 0,
]) async {
  String tmpDir;
  var gitIgnore = File(p.absolute('.gitignore'));

  try {
    // Copy our custom .pubignore rules into .gitignore
    // see: https://github.com/dart-lang/pub/issues/2222
    tmpDir = (await Directory.systemTemp.createTemp('dexecve')).path;
    var pubIgnoreRulesFuture = File(p.absolute('.pubignore')).readAsString();
    await gitIgnore.copy(p.join(tmpDir, '.gitignore'));
    await gitIgnore.writeAsString(
      '\n${(await pubIgnoreRulesFuture)}',
      mode: FileMode.append,
    );

    if (dryRun) {
      await dexeca('pub', ['publish', '--dry-run'],
          runInShell: Platform.isWindows);
      return;
    }

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw 'accessToken & refreshToken must be supplied!';
    }

    // on windows the path is actually %%UserProfile%%\AppData\Roaming\Pub\Cache
    // not that this really matters because we only intend on running this inside
    // a pipeline which will be running linux.
    var credsFilePath = p.join(_homeDir(), '.pub-cache', 'credentials.json');

    await File(credsFilePath).writeAsString(jsonEncode({
      'accessToken': '${accessToken}',
      'refreshToken': '${refreshToken}',
      'tokenEndpoint': 'https://accounts.google.com/o/oauth2/token',
      'scopes': ['openid', 'https://www.googleapis.com/auth/userinfo.email'],
      'expiration': oAuthExpiration,
    }));

    await dexeca('pub', ['publish', '--force'], runInShell: Platform.isWindows);
  } finally {
    if (tmpDir != null) {
      if (await File(p.join(tmpDir, '.gitignore')).exists()) {
        await File(p.join(tmpDir, '.gitignore')).copy(gitIgnore.path);
      }
      await Directory(tmpDir).delete(recursive: true);
    }
  }
}

String _homeDir() {
  if (Platform.isWindows) return Platform.environment['UserProfile'];
  return Platform.environment['HOME'];
}

Future<void> _searchReplaceFile(File file, String from, String to) async {
  var src = await file.readAsString();
  var newSrc = src.replaceAll(from, to);
  await file.writeAsString(newSrc);
}

Future<void> _searchReplaceVersion(File file, String nextVersion) {
  return _searchReplaceFile(file, '0.0.0-semantically-released', nextVersion);
}

var toolVersions = <String, String>{};
Future<String> _parseVersionFile(String tool) async {
  if (!toolVersions.containsKey(tool)) {
    toolVersions[tool] =
        (await File(p.absolute('.${tool}-version')).readAsString()).trim();
  }
  return toolVersions[tool];
}
