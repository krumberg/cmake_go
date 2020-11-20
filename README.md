cmake_go: CMake support for mixing Go and C/C++
===============================================

Introduction
------------

This project aims to make it easy for projects using CMake to incorporate Go (Golang) into their existing applications. The CMake macro "add\_cgo\_executable" takes¨ a list of .go files and CMake (library) targets and creates a new CMake target for a set of Go applications. The user does not need to specify any flags to CGO manually, it is all taken care of by the macro.

Cross compilation
-----------------

Support for building for the host platform and Raspberry PI (ARM) is provided.

ASAN
----

In addition to binding together Go and C/C++ this project also incorporates ASAN support.

Examples
--------

The "examples" directory contains several examples

-	goodprogram

A small Go program that invokes some C-code.

-	leakyprogram

A small Go program that invokes some C-code and leaks memory. This is detected by ASAN.

-	nullrefprogram

A small Go program that invokes some C-code and reads from a NULL pointer. This is detected by ASAN.

-	outofboundsprogram

A small Go program that invokes some C-code and writes out of bounds. This is detected by ASAN.

Building and running (Ubuntu/Debian)
------------------------------------

Install a recent version of Go (https://tip.golang.org/dl/\)

$ apt install clang-11 build-essential gcc-8-arm-linux-gnueabihf

$ go get -u github.com/shurcooL/markdownfmt

Build

$ make

Run the three examples for host

$ ./out/host/examples/goodprogram/goodprogram

$ ./out/host/examples/leakyprogram/leakyprogram

$ ./out/host/examples/segfaultyprogram/nullrefprogram

$ ./out/host/examples/segfaultyprogram/outofboundsprogram
