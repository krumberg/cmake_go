# Copyright (c) 2020 Kristian Rumberg (kristianrumberg@gmail.com)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

OUT=out

############ All ############

all: pi host

############ Format #############

.PHONY: fmt-md
fmt-md:
	@find *.md | xargs markdownfmt -w

.PHONY: fmt-clang
fmt-clang:
	@find * -type f -name '*.[c,h]' | grep -v out | xargs clang-format -i

.PHONY: fmt-go
fmt-go:
	@find -type f -name go.mod | xargs dirname  | xargs -I X bash -c "cd X && go fmt ./..."

.PHONY: fmt
fmt: fmt-md fmt-clang fmt-go

############ Raspberry Pi ##########
PI_TOOLCHAIN=$(shell pwd)/src/cmake/toolchains/pi.toolchain
PI_OUT=$(OUT)/pi

.PHONY: pi
pi: $(PI_OUT)/pi.toolchain
	@ninja -C $(PI_OUT)

$(PI_OUT)/pi.toolchain: Makefile $(PI_TOOLCHAIN)
	rm -rf $(PI_OUT) && \
	mkdir -p $(PI_OUT) && \
        cmake -DCMAKE_BUILD_TYPE=Debug -GNinja -DCMAKE_TOOLCHAIN_FILE=$(PI_TOOLCHAIN) -B$(PI_OUT) src
	cp $(PI_TOOLCHAIN) $(PI_OUT)/pi.toolchain

########### Host #############
HOST_TOOLCHAIN=$(shell pwd)/src/cmake/toolchains/host.toolchain
HOST_OUT=$(OUT)/host

.PHONY: host
host: $(HOST_OUT)/host.toolchain
	@ninja -C $(HOST_OUT)

$(HOST_OUT)/host.toolchain: Makefile $(HOST_TOOLCHAIN)
	rm -rf $(HOST_OUT) && \
	mkdir -p $(HOST_OUT) && \
        cmake -DCMAKE_BUILD_TYPE=Debug -GNinja -DCMAKE_TOOLCHAIN_FILE=$(HOST_TOOLCHAIN) -B$(HOST_OUT) src
	cp $(HOST_TOOLCHAIN) $(HOST_OUT)/host.toolchain

######### Clean ###########

.PHONY: clean
clean:
	rm -rf $(OUT)
