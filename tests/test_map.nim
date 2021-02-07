import unittest
import cppinterop/[map, cppstr]

{.compile: "test.cpp".}

# proc tmp() =
#   var m: Map[cint, CppString]
#   m.initMap
#   m[0] = "asd"
#   echo dump(m)

# tmp()

# var m: Map[int, int]
# m.initMap
# for i in 1..10:
#   m[i] = i + 1
# # m[1] = 2
# # m[2] = 3
# # m[3] = 4
# # m[4] = 5
# # m[5] = 6
# # echo dump(m.find(-1)[])
# # echo dump(m.find(1)[])
# echo dump(m)
# for item in m:
#   echo item

# discard m.erase(m.erase(m.find(1)))

# echo dump(m)
# for item in m:
#   echo item

# echo repr m

proc printmap(str: sink Map[cint, cint]) {.importc.}
proc printstrmap(str: sink Map[cint, CppString]) {.importc.}
proc returnmap(): Map[cint, cint] {.importc.}
proc returnstrmap(): Map[cint, CppString] {.importc.}

suite "Basic usage":
  test "Empty print":
    var m: Map[cint, cint]
    m.initMap
    printmap(m)

  test "Simple print":
    var m: Map[cint, cint]
    m.initMap
    m[0] = 1
    m[2] = 2
    m[1] = 3
    printmap(m)

  test "Erase node":
    var m: Map[cint, cint]
    m.initMap
    m[0] = 1
    m[1] = 3
    discard m.erase(m.find(1))
    printmap(m)

  test "String map":
    var m: Map[cint, CppString]
    m.initMap
    m[0] = "asd"
    printstrmap(m)

  test "Return map":
    var m = returnmap()
    echo dump(m)

  test "Return strmap":
    var m = returnstrmap()
    echo dump(m)
