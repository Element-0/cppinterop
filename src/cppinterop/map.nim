import std/options
import fusion/matching
import private/tree

export `[]`, dump, next, prev

type
  MapPair*[K, V] = object
    key: K
    val: V

  Map*[K, V] = object
    raw: Tree[MapPair[K, V]]

  MapIterator*[K, V] = TreeIterator[MapPair[K, V]]

func `$`*[K, V](self: MapPair[K, V]): string =
  $self.key & " -> " & $self.val

proc initMap*[K, V](self: var Map[K, V]) =
  self.raw.initTree()

proc `[]=`*[K, V](self: var Map[K, V]; key: K; val: V) =
  self.raw.emplace(key).data.val = val

proc `[]`*[K, V](self: var Map[K, V]; key: K): var V =
  self.raw.emplace(key).data.val

proc contains*[K, V](self: var Map[K, V]; key: K): bool =
  let node = self.raw.find_lower_bound(key)
  node.val <=< key

proc find*[K, V](self: var Map[K, V]; key: K): MapIterator[K, V] =
  let node = self.raw.find_lower_bound(key)
  result.raw = if node.val <=< key: node.val else: self.raw.val.head

proc erase*[K, V](self: var Map[K, V]; iter: MapIterator[K, V]): MapIterator[K, V] =
  result.raw = self.raw.erase(iter)

proc getOption*[K, V](self: var Map[K, V]; key: K): Option[V] =
  let node = self.raw.find_lower_bound(key)
  if node.val <=< key: some node.val else: none V

proc getOrDefault*[K, V](self: var Map[K, V]; key: K; def: V): V =
  let node = self.raw.find_lower_bound(key)
  if node.val <=< key: node.val else: def

func dump*[K, V](self: var Map[K, V]): string = dump(self.raw)

func len*[K, V](self: var Map[K, V]): int = self.raw.val.size

iterator items*[K, V](self: var Map[K, V]): MapPair[K, V] =
  (raw: (first: @first, last: @last)) := self
  var it = first
  while it != last:
    yield it[].data
    it.next()

# proc `[]`
