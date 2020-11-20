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

In addition to binding together Go and C/C++ this project also incorporate ASAN support.

Examples
--------

The "examples" directory contains three examples

-	goodprogram

A small Go program that invokes some C-code.

-	leakyprogram

A small Go program that invokes some C-code and leaks memory. This is detected by ASAN.

-	segfaultprogram

A small Go program that invokes some C-code and reads from a NULL pointer. This is detected by ASAN.

Building and running
--------------------

Make sure that a recent version of Go is installed (https://tip.golang.org/dl/\)

Build

$ make

Run the three examples for host

$ ./out/host/examples/goodprogram/goodprogram

$ ./out/host/examples/leakyprogram/leakyprogram

$ ./out/host/examples/segfaultyprogram/segfaultyprogram
