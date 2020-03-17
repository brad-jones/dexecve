import 'dart:io';
import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'package:dexecve/src/exec.dart';
import 'package:dexecve/src/go_string.dart';

void dexecve(String binary, List<String> args, List<String> env) {
  if (Platform.isWindows) throw 'Windows does not support execve!';
  final goStr = GoString.fromString(jsonEncode({
    'bin': binary,
    'args': args,
    'env': env,
  }));
  exec(goStr);
  free(goStr);
}
