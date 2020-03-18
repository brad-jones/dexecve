import 'dart:io';
import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'package:dexecve/src/exec.dart';
import 'package:dexecve/src/go_string.dart';

/// Replace the running process, with a POSIX execve system call.
void dexecve(
  String binary,
  List<String> args, {
  Map<String, String> environment,
  bool inheritEnvironment = true,
}) {
  if (Platform.isWindows) throw 'Windows does not support execve!';

  var env = <String>[];
  for (var k in environment.keys) {
    env.add('${k}=${environment[k]}');
  }

  if (inheritEnvironment) {
    for (var k in Platform.environment.keys) {
      // specfically provided env vars will always override inherited env vars
      if (environment.containsKey(k)) continue;
      env.add('${k}=${environment[k]}');
    }
  }

  final goStr = GoString.fromString(jsonEncode({
    'bin': binary,
    'args': args,
    'env': env,
  }));
  exec(goStr);

  // can't execute this here
  // this is free`ed by the golang function
  // free(goStr);
}
