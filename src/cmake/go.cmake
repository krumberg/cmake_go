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

set(CGO_RESOLVE_BLACKLIST
  pthread
  rt
  gcov
  systemd
)

set(CGO_CFLAGS_BLACKLIST
  "-Werror"
  "-Wall"
  "-Wextra"
  "-Wold-style-definition"
  "-fdiagnostics-color=always"
  "-Wformat-nonliteral"
  "-Wformat=2"
)

macro(add_cgo_executable GO_MOD_NAME GO_FILES CGO_DEPS GO_BIN)
  cgo_fetch_cflags_and_ldflags(${CGO_DEPS})
  cgo_build_envs(${GO_BIN})

  set(CGO_BUILT_FLAG ${CMAKE_CURRENT_BINARY_DIR}/${GO_MOD_NAME}.cgo.module)
  add_custom_command(
    OUTPUT ${CGO_BUILT_FLAG}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMAND echo Building CGO modules for ${GO_BIN}
    COMMAND ${CMAKE_COMMAND} -E remove ${CGO_BUILT_FLAG}
    COMMAND env ${CGO_ENVS} go build -a -o ${GO_BIN} ./...
    COMMAND touch ${CGO_BUILT_FLAG}
    DEPENDS ${CGO_DEPS_HANDLED}
  )
  add_custom_target(${GO_MOD_NAME}_cgo ALL
    DEPENDS ${CGO_BUILT_FLAG}
  )

  set(GO_BUILT_FLAG  ${CMAKE_CURRENT_BINARY_DIR}/${GO_MOD_NAME}.go.module)
  add_custom_command(
    OUTPUT ${GO_BUILT_FLAG}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMAND echo Building GO modules for ${GO_BIN}
    COMMAND env ${CGO_ENVS} go build -o ${GO_BIN} ./...
    COMMAND env ${CGO_ENVS} golangci-lint run --enable-all --disable=exhaustivestruct,godot,goerr113,gomnd,nlreturn,wrapcheck,wsl
    COMMAND touch ${GO_BUILT_FLAG}
    DEPENDS ${CGO_BUILT_FLAG} ${${GO_FILES}}
  )
  add_custom_target(${GO_MOD_NAME}_go ALL
    DEPENDS ${GO_BUILT_FLAG}
  )

endmacro()


macro(cgo_build_envs GO_BIN)
  set(CGO_ENVS
    CGO_ENABLED=1
    CC=${CMAKE_C_COMPILER}
    CGO_CFLAGS="${CGO_CFLAGS}"
    CGO_LDFLAGS="${CGO_LDFLAGS}"
  )

  # Assume ARM7 if on ARM
  if ("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "arm")
    list(APPEND CGO_ENVS GOARCH=arm GOARM=7)
  endif()
endmacro()


macro(cgo_fetch_cflags_and_ldflags CGO_DEPS)
  set(CGO_LDFLAGS "")
  set(CGO_CFLAGS "")

  set(CGO_DEPS_STACK ${${CGO_DEPS}})
  set(CGO_DEPS_HANDLED "")
  set(CGO_RPATHS "")

  while (CGO_DEPS_STACK)
    foreach(L ${CGO_DEPS_STACK})
      # Skip if already handled once
      if ("${L}" IN_LIST CGO_DEPS_HANDLED)
        continue()
      endif()

      # Don't resolve system libs
      if ("${L}" IN_LIST CGO_RESOLVE_BLACKLIST)
        continue()
      endif()

      # Resolve PkgConfig libs
      if ("${L}" MATCHES "PkgConfig")
        get_target_property(L_INTERFACE_LIB ${L} INTERFACE_LINK_LIBRARIES)

        # Mark handled
        list(APPEND CGO_DEPS_HANDLED ${L})

        # Finally override L
        set(L "${L_INTERFACE_LIB}")

        # L might be a list so iterate over it when adding rpaths
        foreach (L_ITEM ${L})
          # Fetch directory and add it to rpath-link if not already added
          get_filename_component(R "${L_ITEM}" DIRECTORY)

          if (NOT "${R}" IN_LIST CGO_RPATHS)
            # Linker may need to find private libraries in the same directory
            list(APPEND CGO_RPATHS "${R}")
          endif()
        endforeach()

        # Add libraries to linker flags
        list(APPEND CGO_LDFLAGS ${L})
      else()
        # Try resolve alias
        get_target_property(L_ALIASED ${L} ALIASED_TARGET)
        if (NOT "${L_ALIASED}" MATCHES "NOTFOUND")
          set(L "${L_ALIASED}")
        endif()

        # Mark handled
        list(APPEND CGO_DEPS_HANDLED ${L})

        get_target_property(L_INCLUDES ${L} INCLUDE_DIRECTORIES)
        get_target_property(L_BUILD_DIR ${L} BINARY_DIR)

        list(APPEND CGO_LDFLAGS -L${L_BUILD_DIR})
        list(APPEND CGO_LDFLAGS -l${L})

        foreach(I ${L_INCLUDES})
          list(APPEND CGO_CFLAGS -I${I})
        endforeach()

        list(REMOVE_ITEM CGO_DEPS_STACK "${L}")

        get_target_property(DEPS ${L} LINK_LIBRARIES)
        foreach(D ${DEPS})
          list(APPEND CGO_DEPS_STACK "${D}")
        endforeach()

      endif()

    endforeach()
  endwhile()

  #### Adding cflags and ldflags #####

  # Must split sentences into CMake List before adding cflags and ldflags
  string(REPLACE " " ";" CMAKE_C_FLAGS_LIST ${CMAKE_C_FLAGS})
  list(APPEND CGO_CFLAGS ${CMAKE_C_FLAGS_LIST})

  string(REPLACE " " ";" CMAKE_EXE_LINKER_FLAGS_LIST "${CMAKE_EXE_LINKER_FLAGS}")
  list(APPEND CGO_LDFLAGS "${CMAKE_EXE_LINKER_FLAGS_LIST}")
  string(REPLACE " " ";" CMAKE_C_LINK_FLAGS_LIST "${CMAKE_C_LINK_FLAGS}")
  list(APPEND CGO_LDFLAGS "${CMAKE_C_LINK_FLAGS_LIST}")

  if(CMAKE_BUILD_TYPE MATCHES debug)
    string(REPLACE " " ";" CMAKE_C_FLAGS_DEBUG_LIST "${CMAKE_C_FLAGS_DEBUG}")
    list(APPEND CGO_CFLAGS ${CMAKE_C_FLAGS_DEBUG_LIST})
    string(REPLACE " " ";" CMAKE_EXE_LINKER_FLAGS_DEBUG_LIST "${CMAKE_EXE_LINKER_FLAGS_DEBUG}")
    list(APPEND CGO_LDFLAGS "${CMAKE_EXE_LINKER_FLAGS_DEBUG_LIST}")
  endif()

  if(CMAKE_BUILD_TYPE MATCHES release)
    string(REPLACE " " ";" CMAKE_C_FLAGS_RELEASE_LIST "${CMAKE_C_FLAGS_RELEASE}")
    list(APPEND CGO_CFLAGS ${CMAKE_C_FLAGS_RELEASE_LIST})
    string(REPLACE " " ";" CMAKE_EXE_LINKER_FLAGS_RELEASE_LIST "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
    list(APPEND CGO_LDFLAGS "${CMAKE_EXE_LINKER_FLAGS_RELEASE_LIST}")
  endif()

  # Need to remove warnings for CGo to work
  foreach(F ${CGO_CFLAGS_BLACKLIST})
    list(REMOVE_ITEM CGO_CFLAGS "${F}")
  endforeach()

  # Add rpaths if present
  foreach(R ${CGO_RPATHS})
    list(APPEND CGO_LDFLAGS "-Wl,-rpath-link=${R}")
  endforeach()

endmacro()
