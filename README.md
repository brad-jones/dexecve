# dexecve

![Pub Version](https://img.shields.io/pub/v/dexecve)
![.github/workflows/main.yml](https://github.com/brad-jones/dexecve/workflows/.github/workflows/main.yml/badge.svg?branch=master)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)
[![KeepAChangelog](https://img.shields.io/badge/Keep%20A%20Changelog-1.0.0-%23E05735)](https://keepachangelog.com/)
[![License](https://img.shields.io/github/license/brad-jones/dexecve.svg)](https://github.com/brad-jones/dexecve/blob/master/LICENSE)

Replace the running process, with a POSIX execve system call.

## Usage

```dart
import 'package:dexecve/dexecve.dart';

void main() {
  dexecve('ping', ['1.1.1.1']);
}
```

> see [./example/main.dart](./example/main.dart) for more details

## Dart FFI & Golang

This project is a working example of how to integrate dartlang and golang using
dart's c interop.

Steps basically look like this:

1. Create a golang `c-shared` library.
   
   _hello.go_

   ```go
   package main
   
   import "C"
   
   import (
   	"fmt"
   )
   
   //export HelloWorld
   func HelloWorld() {
   	fmt.Println("hello world")
   }
   
   func main() {}
   ```

2. Compile the library. eg: `go build -o libhello.so -buildmode=c-shared hello.go`
   
   You may want to cross compile the library for multiple platforms.
   Cross compilation of a static golang binary is relatively straight forward
   these days however it's not as easy to cross compile a library as `cgo` is
   required which normally is disabled for cross compilation.

   I have found [xgo](https://github.com/crazy-max/xgo) very helpful for this.

3. Write the dart _ffi_ code to interface with the library. This feels almost
   like writing TypeScript typings for a JavaScript library.

   _hello.dart_

   ```dart
   import 'dart:ffi';
   
   DynamicLibrary _lib = DynamicLibrary.open('libhello.so');
   
   typedef HelloWorld = void Function();
   typedef HelloWorld_func = Void Function();
   final HelloWorld helloWorld = _lib.lookup<NativeFunction<HelloWorld_func>>('HelloWorld').asFunction();
   ```

4. Consume the function in your dart code and profit :)
   
   _main.dart_

   ```dart
   import 'hello.dart';

   void main() {
     helloWorld();
   }
   ```

Essentially all this project does is call golang's
[`syscall.Exec()`](https://golang.org/pkg/syscall/#Exec) function.

> _I understand this might be overkill and a much smaller package could be
> created if I used C directly. One day I might do just that..._

In my opinion this creates a very powerful tool chain, dartlang feels very
familiar with Classes, Generics, Extension Methods, Exceptions, Async/Await
and many other concepts that other more main stream languages have had for
a very long time.

While golang offers a very powerful concurrency model, handy tools like `defer`,
a simplified programming model, native performance and a larger ecosystem which
can help to fill any gaps in the current dart ecosystem.

Anything I can do in Go and I can do in Dart!

### Further Resources

- <https://dart.dev/guides/libraries/c-interop>
- <https://github.com/dart-lang/sdk/issues/37509>
- <https://medium.com/@kyorohiro/code-server-x-dart-fmi-x-go-x-clang-2a5bd440fad8>
- <https://github.com/vladimirvivien/go-cshared-examples>
- <https://medium.com/swlh/build-and-use-go-packages-as-c-libraries-889eb0c19838>
- <https://medium.com/@walkert/fun-building-shared-libraries-in-go-639500a6a669>
- <https://github.com/crazy-max/xgo>
