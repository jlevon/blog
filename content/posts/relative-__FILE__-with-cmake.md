---
title: "Relative __FILE__ With CMake"
date: 2022-06-16T10:04:56+01:00
draft: true
---

I have the misfortune of maintaining some things using CMake. One major
annoyance is that `__FILE__` is an absolute path, and that can't be changed in
CMake itself. Like most CMake annoyances, you can find a discussion online from
about 15 years ago, but no sign of an actual fix.

Instead, you need a hack: this - I think - is the simplest one.

First, in our top-level `CMakeLists.txt`, we'll define this helper function:

```
function(add_srcs NAME)
  set(${NAME} ${ARGN} PARENT_SCOPE)
  foreach(f IN LISTS ARGN)
    file(RELATIVE_PATH b ${CMAKE_SOURCE_DIR}
         ${CMAKE_CURRENT_SOURCE_DIR}/${f})
    set_source_files_properties(${f} PROPERTIES COMPILE_DEFINITIONS
                                "__FILE__=\"${b}\"")
  endforeach()
endfunction()
```

This will take each of arguments, convert each file into a path relative to the
top-level directory, then re-define `__FILE__` on a per-source-file basis. We
also `set()` a variable for our parent scope to use.

We'll also need `-Wno-builtin-macro-redefined`.

Then, in each child `CMakeLists.txt`, we will do something like:

```
add_srcs(MYCODE_SRCS mycode.c mycode.h)
add_library(mycode ${MYCODE_SRCS})

add_srcs(CODE2_SRCS code2.c code2.h)
add_library(code2 ${CODE2_SRCS})
```
