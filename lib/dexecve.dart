import 'dart:async';
import 'dart:cli';
import 'dart:convert';
import 'dart:io';
import 'package:dexeca/dexeca.dart';
import 'package:dexecve/src/exec.dart';
import 'package:dexecve/src/go_string.dart';

/// Replace the running process, with a POSIX execve system call.
/// Under the hood this calls golang's `syscall.Exec`
///
/// see: https://golang.org/pkg/syscall/#Exec
///
/// * [binary] This can be an absolute or relative path. Under the hood we use
///   the golang `exec.LookPath` function to find the binary.
///   see: https://golang.org/pkg/os/exec/#LookPath
///
/// * [args] The arguments to pass to the binary.
///
/// * [environment] Optionally you may pass a MAP that represents the
///   environment variables the binary should see.
///
/// * [inheritEnvironment] By default the executed binary will also inherit the
///   environment from the current process. You can disable this functionality
///   if you wish.
///
/// > NOTE: On Windows this will fall back to starting a child process
/// >       and proxying all it's STDIO.
void dexecve(
  String binary,
  List<String> args, {
  Map<String, String> environment,
  bool inheritEnvironment = true,
}) {
  if (Platform.isWindows) {
    var proc = dexeca(
      binary,
      args,
      inheritStdio: true,
      captureOutput: false,
      environment: environment,
      includeParentEnvironment: inheritEnvironment,
    );
    waitFor(proc.stdin.addStream(stdin));
    waitFor(proc.stdin.close());
    try {
      waitFor(proc);
    } on AsyncError catch (e) {
      var err = e.error;
      if (err is ProcessResult) {
        exit(err.exitCode);
      }
      rethrow;
    }
    exit(0);
  }

  var env = <String>[];
  for (var k in environment?.keys ?? []) {
    env.add('${k}=${environment[k]}');
  }

  if (inheritEnvironment) {
    for (var k in Platform.environment.keys) {
      // specfically provided env vars will always override inherited env vars
      if (environment?.containsKey(k) ?? false) continue;
      env.add('${k}=${environment[k]}');
    }
  }

  // bit of hack, ffi in dart isn't terriable muture or expressive so we
  // encode all input to the golang function as json and decode it inside
  // the golang function.
  final goStr = GoString.fromString(jsonEncode({
    'bin': binary,
    'args': args,
    'env': env,
  }));

  // execute the golang function
  exec(goStr);

  // can't execute this here
  // this is free`ed by the golang function
  // free(goStr);
}
