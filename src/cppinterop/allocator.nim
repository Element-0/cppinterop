proc cmalloc*(size: int): pointer {.importc: "malloc", header: "stdlib.h", nodecl.}
proc cfree*(target: pointer) {.importc: "free", header: "stdlib.h", nodecl.}
proc cmemset*(target: pointer; c: int; n: int) {.importc: "memset", header: "stdlib.h", nodecl.}

proc calloc*(T: typedesc): ptr T {.inline.} =
  cast[ptr T](cmalloc(sizeof T))

proc calloc*(T: typedesc; count: int): ptr UncheckedArray[T] {.inline.} =
  cast[ptr UncheckedArray[T]](cmalloc(count * sizeof T))

proc cnew*[T](target: var ptr T; count: int = 1) {.inline.} =
  target = cast[ptr T](cmalloc(count * sizeof T))

proc creset*[T](target: ptr T; count: int = 1) {.inline.} =
  cmemset(target, 0, count * sizeof T)

proc creset*[T](target: var T) {.inline.} =
  cmemset(addr target, 0, sizeof T)
