import 'dart:ffi';
import 'dart:convert';
import 'package:ffi/ffi.dart';

/// credit: https://gist.github.com/sjindel-google/b88c964eb260e09280e588c41c6af3e5
///
/// also: https://github.com/dart-lang/sdk/issues/37509
class GoString extends Struct {
  Pointer<Uint8> string;

  @IntPtr()
  int length;

  String toString() {
    var units = [];
    for (int i = 0; i < length; ++i) {
      units.add(string.elementAt(i).value);
    }
    return Utf8Decoder().convert(units);
  }

  static Pointer<GoString> fromString(String string) {
    List<int> units = Utf8Encoder().convert(string);
    final ptr = allocate<Uint8>(count: units.length);
    for (int i = 0; i < units.length; ++i) {
      ptr.elementAt(i).value = units[i];
    }
    final str = allocate<GoString>().ref;
    str.length = units.length;
    str.string = ptr;
    return str.addressOf;
  }
}
