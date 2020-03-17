import 'package:test/test.dart';
import 'package:dexeca/dexeca.dart';
import 'package:path/path.dart' as p;

void main() {
  test('dexecve should replace the process', () async {
    var result = await dexeca(
      'dart',
      [p.absolute('test', 'sut.dart')],
      inheritStdio: false,
    );
    expect(result.stdout, isNot(contains('I should never see this')));
    expect(result.stdout, contains('PID PARENT: ${result.pid}'));
    expect(result.stdout, contains('PID CHILD: ${result.pid}'));
    expect(result.stdout, contains('FOO=BAR'));
    expect(result.stderr, equals(''));
    expect(result.exitCode, equals(0));
  });
}
