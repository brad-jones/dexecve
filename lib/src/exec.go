package main

// #include <stdlib.h>
import "C"

import (
	"encoding/json"
	"os/exec"
	"path/filepath"
	"syscall"
	"unsafe"
)

type ExecInput struct {
	Bin  string   `json:"bin"`
	Args []string `json:"args"`
	Env  []string `json:"env"`
}

//export Exec
func Exec(input *string) {
	var parsedInput ExecInput
	if err := json.Unmarshal([]byte(*input), &parsedInput); err != nil {
		panic(err)
	}

	C.free(unsafe.Pointer(input))

	binary, lookErr := exec.LookPath(parsedInput.Bin)
	if lookErr != nil {
		panic(lookErr)
	}

	args := append([]string{filepath.Base(binary)}, parsedInput.Args...)

	if err := syscall.Exec(binary, args, parsedInput.Env); err != nil {
		panic(err)
	}
}

func main() {}
