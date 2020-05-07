package main

// #include <stdlib.h>
import "C"

import (
	"encoding/json"
	"path/filepath"
	"syscall"
	"unsafe"
)

type execInput struct {
	Bin  string   `json:"bin"`
	Args []string `json:"args"`
	Env  []string `json:"env"`
}

//export Exec
func Exec(input *string) {
	var parsedInput execInput
	if err := json.Unmarshal([]byte(*input), &parsedInput); err != nil {
		panic(err)
	}

	C.free(unsafe.Pointer(input))

	args := append([]string{filepath.Base(parsedInput.Bin)}, parsedInput.Args...)

	if err := syscall.Exec(parsedInput.Bin, args, parsedInput.Env); err != nil {
		panic(err)
	}
}

func main() {}
