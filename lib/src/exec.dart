import 'dart:io';
import 'dart:cli';
import 'dart:ffi';
import 'dart:isolate';
import 'package:path/path.dart' as p;
import 'package:dexecve/src/go_string.dart';

String _getLibName() {
  switch (Platform.operatingSystem) {
    case 'linux':
      return 'linux-glibc-x64.so';
    case 'macos':
      return 'macos-x64.dylib';
  }
  throw 'unsupported os';
}

var _libUri = 'package:dexecve/src/${_getLibName()}';
var _libPath = waitFor(Isolate.resolvePackageUri(Uri.parse(_libUri))).path;
DynamicLibrary _lib = DynamicLibrary.open(
  p.normalize(_libPath).replaceFirst('\\', ''),
);

typedef Exec = void Function(Pointer<GoString>);
typedef Exec_func = Void Function(Pointer<GoString>);
final Exec exec = _lib.lookup<NativeFunction<Exec_func>>('Exec').asFunction();
