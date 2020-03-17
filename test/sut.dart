import 'dart:io' as io;
import 'package:dexecve/dexecve.dart';

void main(List<String> args) {
  if (args.isNotEmpty && args[0] == 'executed') {
    print('PID CHILD: ${io.pid}');
    print('FOO=${io.Platform.environment['FOO']}');
    return;
  }

  print('PID PARENT: ${io.pid}');

  dexecve('dart', ['/app/test/sut.dart', 'executed'], ['FOO=BAR']);

  print('I should never see this');
}
