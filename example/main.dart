import 'dart:io' as io;
import 'package:path/path.dart' as p;
import 'package:dexecve/dexecve.dart';

void main(List<String> argv) {
  // This branch should be executed by `dexecve` call below
  if (argv.isNotEmpty && argv[0] == 'executed') {
    print('PID CHILD: ${io.pid}');
    print('FOO=${io.Platform.environment['FOO']}');
    return;
  }

  // This PID should be inherited by the next invocation of this script
  print('PID PARENT: ${io.pid}');

  // This can be an absolute or relative path.
  // Under the hood we use the golang `exec.LookPath` function to find the binary.
  // see: https://golang.org/pkg/os/exec/#LookPath
  var binaryToExecute = 'dart';

  // The arguments to pass to the binary
  // NOTE: This example is actually used as part of the test for this project
  // and assumes the current working directory in the root of this project.
  var args = [p.absolute('example', 'main.dart'), 'executed'];

  // Optionally you may pass a MAP that represents the environment variables
  // the binary should see.
  var environment = {'FOO': 'BAR'};

  // By default the executed binary will also inherit the environment from the
  // current process. You can disable this functionality if you wish.
  var inheritEnvironment = false;

  // If the binary is succesfully executed then no further instructions in this
  // app will be executed, effectively it would be as though you called the
  // `exit()` function.
  dexecve(
    binaryToExecute,
    args,
    environment: environment,
    inheritEnvironment: inheritEnvironment,
  );

  print('I should never see this');
}
