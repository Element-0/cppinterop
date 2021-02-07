{.experimental: "implicitDeref".}
{.experimental: "caseStmtMacros".}
import fusion/matching

import ../allocator, ../utility

type
  Color = enum
    cRed = "red"
    cBlack = "black"

  TreeNode*[T] = object
    left, parent, right: ptr TreeNode[T]
    color {.bitsize: 8.}: Color
    isNil*: bool
    data*: T

  TreeChild* = enum
    childRight = "right"
    childLeft = "left"
    childUnused = "unused"

  TreeIterator*[T] = object
    raw*: ptr TreeNode[T]

  TreeId*[T] = object
    parent*: ptr TreeNode[T]
    kind*: TreeChild

  TreeFindResult*[T] = object
    loc*: TreeId[T]
    val*: ptr TreeNode[T]

  TreeVal*[T] = object
    head*: ptr TreeNode[T]
    size*: int

  Tree*[T] = object
    val*: TreeVal[T]

func dump*[T](self: ptr TreeNode[T], level: string = ""): string =
  if self.isNil:
    return "nil"
  let next = level & "  "
  result &= (if self.color == cRed: "R " else: "B ")
  result &= $cast[int](self)
  result &= "\n"
  result &= level & "= " & $self.data
  result &= "\n"
  result &= level & "< " & self.left.dump(next)
  result &= "\n"
  result &= level & "> " & self.right.dump(next)

func min[T](self: ptr TreeNode[T]): ptr TreeNode[T] {.inline.} =
  result = self
  while (left: @next is (isNil: false)) ?= result:
    result = next

func max[T](self: ptr TreeNode[T]): ptr TreeNode[T] {.inline.} =
  result = self
  while (right: @next is (isNil: false)) ?= result:
    result = next

template climb[T](self: var TreeIterator[T]; dir, op: untyped) =
  if (dir: (isNil: true), parent: @parent) ?= self.raw:
    var pnode: ptr TreeNode[T]
    while true:
      pnode = self.raw.parent
      if pnode.isNil or self.raw != pnode.dir:
        break
      self.raw = pnode
    self.raw = pnode
  else:
    self.raw = op(self.raw.dir)

func next*[T](self: var TreeIterator[T]) {.inline.} =
  self.climb(right, min)
func prev*[T](self: var TreeIterator[T]) {.inline.} =
  self.climb(left, max)

func `==`*[T](a, b: TreeIterator[T]): bool {.inline.} = a.raw == b.raw

func `[]`*[T](self: TreeIterator[T]): ptr TreeNode[T] {.inline.} = self.raw

template rotate[T](self: var TreeVal[T]; where: ptr TreeNode[T]; dir, neg: untyped) =
  let pnode = where.neg
  where.neg = pnode.dir

  if not pnode.dir.isNil:
    pnode.dir.parent = where

  pnode.parent = where.parent

  if where == self.head.parent:
    self.head.parent = pnode
  elif where == where.parent.dir:
    where.parent.dir = pnode
  else:
    where.parent.neg = pnode

  pnode.dir = where
  where.parent = pnode

func rotateLeft[T](self: var TreeVal[T]; where: ptr TreeNode[T]) {.inline.} =
  self.rotate(where, left, right)
func rotateRight[T](self: var TreeVal[T]; where: ptr TreeNode[T]) {.inline.} =
  self.rotate(where, right, left)

func extract*[T](self: var TreeVal[T]; citer: TreeIterator[T]): ptr TreeNode[T] =
  var iter = citer
  let erased: ptr TreeNode[T] = iter.raw
  iter.next()
  var fixnode, fixnodeparent, pnode: ptr TreeNode[T]
  pnode = erased
  template myhead: ptr TreeNode[T] = self.head

  if (left: (isNil: true), right: @next) ?= pnode:
    fixnode = next # stitch up right subtree
  elif (right: (isNil: true), left: @next) ?= pnode:
    fixnode = next # stitch up left subtree
  else: # two subtrees, must lift successor node to replace erased
    pnode = iter.raw # pnode is successor node
    fixnode = pnode.right # fixnode is only subtree

  if pnode == erased: # at most one subtree, relink it
    fixnodeparent = erased.parent
    if not fixnode.isNil:
      fixnode.parent = fixnodeparent # link up

    if myhead.parent == erased:
      myhead.parent = fixnode # link down from root
    elif fixnodeparent.left == erased:
      fixnodeparent.left = fixnode # link down to left
    else:
      fixnodeparent.right = fixnode # link down to right

    if myhead.left == erased:
      myhead.left = if fixnode.isNil:
        fixnodeparent # smallest is parent of erased node
      else:
        min(fixnode) # smallest in relinked subtree
    if myhead.right == erased:
      myhead.right = if fixnode.isNil:
        fixnodeparent # largest is parent of erased node
      else:
        max(fixnode) # largest in relinked subtree
  else: # erased has two subtrees, pnode is successor to erased
    erased.left.parent = pnode # link left up
    pnode.left = erased.left # link successor down

    if pnode == erased.right:
      fixnodeparent = pnode # successor is next to erased
    else: # successor further down, link in place of erased
      fixnodeparent = pnode.parent # parent is successor's
      if not fixnode.isNil:
        fixnode.parent = fixnodeparent # link fix up
      fixnodeparent.left = fixnode # link fix down
      pnode.right = erased.right # link next down
      erased.right.parent = pnode # right up

    if myhead.parent == erased:
      myhead.parent = pnode # link down from root
    elif erased.parent.left == erased:
      erased.parent.left = pnode # link down to left
    else:
      erased.parent.right = pnode # link down to right

    pnode.parent = erased.parent # link successor up
    swap(pnode.color, erased.color) # recolor it

  if erased.color == cBlack: # erasing black link, must recolor/rebalance tree
    while fixnode != myhead.parent and fixnode.color == cBlack:
      defer: fixnodeparent = fixnode.parent
      if fixnode == fixnodeparent.left: # fixup left subtree
        pnode = fixnodeparent.right
        if pnode.color == cRed: # rotate red up from right subtree
          pnode.color = cBlack
          fixnodeparent.color = cRed
          self.rotateLeft(fixnodeparent)
          pnode = fixnodeparent.right
        if pnode.isNil:
          fixnode = fixnodeparent # shouldn't happen
        elif (left: (color: cBlack), right: (color: cBlack)) ?= pnode: # redden right subtree with black children
          pnode.color = cRed
          fixnode = fixnodeparent
        else: # must rearrange right subtree
          if (right: (color: cBlack)) ?= pnode:
            pnode.left.color = cBlack
            pnode.color = cRed
            self.rotateRight(pnode)
            pnode = fixnodeparent.right

          pnode.color = fixnodeparent.color
          fixnodeparent.color = cBlack
          pnode.right.color = cBlack
          self.rotateLeft(fixnodeparent)
          break # tree now recolored/rebalanced
      else: # fixup right subtree
        pnode = fixnodeparent.left
        if pnode.color == cRed: # rotate red up from left subtree
          pnode.color = cBlack
          fixnodeparent.color = cRed
          self.rotateRight(fixnodeparent)
          pnode = fixnodeparent.left
        if pnode.isNil:
          fixnode = fixnodeparent # shouldn't happen
        elif (left: (color: cBlack), right: (color: cBlack)) ?= pnode: # redden left subtree with black children
          pnode.color = cRed
          fixnode = fixnodeparent
        else: # must rearrange left subtree
          if (left: (color: cBlack)) ?= pnode: # rotate red up from right sub-subtree
            pnode.right.color = cBlack
            pnode.color = cRed
            self.rotateLeft(pnode)
            pnode = fixnodeparent.left

          pnode.color = fixnodeparent.color
          fixnodeparent.color = cBlack
          pnode.left.color = cBlack
          self.rotateRight(fixnodeparent)
          break # tree now recolored/rebalanced
    fixnode.color = cBlack
  self.size -= 1
  return erased

func insert[T](self: var TreeVal[T]; loc: TreeId[T]; newnode: ptr TreeNode[T]) =
  self.size += 1
  let head = self.head
  newnode.parent = loc.parent
  if loc.parent == head:
    head.left = newnode
    head.parent = newnode
    head.right = newnode
    newnode.color = cBlack
    return

  if loc.kind == childRight:
    assert loc.parent.right.isNil
    loc.parent.right = newnode
    if loc.parent == head.right:
      head.right = newnode
  else:
    assert loc.parent.left.isNil
    loc.parent.left = newnode
    if loc.parent == head.left:
      head.left = newnode

  var pnode = newnode
  while pnode.parent.color == cRed:
    if pnode.parent == pnode.parent.parent.left:
      let parent_sibling = pnode.parent.parent.right
      if parent_sibling.color == cRed:
        pnode.parent.color = cBlack
        parent_sibling.color = cBlack
        pnode.parent.parent.color = cRed
        pnode = pnode.parent.parent
      else:
        if pnode == pnode.parent.right:
          pnode = pnode.parent
          self.rotateLeft pnode
        pnode.parent.color = cBlack
        pnode.parent.parent.color = cRed
        self.rotateRight(pnode.parent.parent)
    else:
      let parent_sibling = pnode.parent.parent.left
      if parent_sibling.color == cRed:
        pnode.parent.color = cBlack
        parent_sibling.color = cBlack
        pnode.parent.parent.color = cRed
        pnode = pnode.parent.parent
      else:
        if pnode == pnode.parent.left:
          pnode = pnode.parent
          self.rotateRight pnode
        pnode.parent.color = cBlack
        pnode.parent.parent.color = cRed
        self.rotateLeft(pnode.parent.parent)
  self.head.parent.color = cBlack

proc buyheadnode[T](): ptr TreeNode[T] =
  result.cnew(1)
  result.left = result
  result.parent = result
  result.right = result
  result.color = cBlack
  result.data.creset()
  result.isNil = true

proc buytempnode*[T, K](head: ptr TreeNode[T], key: sink K): ptr TreeNode[T] {.nodestroy.} =
  result.cnew()
  result.creset()
  result.left = head
  result.parent = head
  result.right = head
  result.color = cRed
  result.isNil = false
  result.data.creset()
  result.data.key = key

proc initTreeVal*[T](self: var TreeVal[T]) =
  self.head = buyheadnode[T]()

template find_bound[T, K](self: Tree[T]; result: untyped; ckey: K; cmp: untyped) =
  result.loc.parent = self.val.head.parent
  result.loc.kind = childRight
  result.val = self.val.head
  var trynode = result.loc.parent
  while (isNil: false, left: @left, right: @right) ?= trynode:
    result.loc.parent = trynode
    if cmp(trynode.data.key, ckey):
      result.loc.kind = childRight
      trynode = right
    else:
      result.loc.kind = childLeft
      result.val = trynode
      trynode = left

func find_lower_bound*[T, K](self: Tree[T]; key: K): TreeFindResult[T] {.inline.} =
  self.find_bound(result, key, `<`)

func find_upper_bound*[T, K](self: Tree[T]; key: K): TreeFindResult[T] {.inline.} =
  self.find_bound(result, key, `<=`)

func `<=<`*[T, K](bound: ptr TreeNode[T]; key: K): bool {.inline.} =
  return (isNil: false, data: (key: <= key)) ?= bound

proc eraseHead[T](self: var TreeVal[T])

proc `=destroy`*[T](self: var Tree[T]) =
  self.val.eraseHead()

proc initTree*[T](self: var Tree[T]) =
  self.val.initTreeVal()

func dump*[T](self: Tree[T]): string =
  # result &= "< "
  result &= dump(self.val.head.left, "| ")
  result &= "\n"
  result &= dump(self.val.head.parent, ": ")

proc emplace*[T, K](self: var Tree[T], key: K): ptr TreeNode[T] =
  let res = self.find_lower_bound(key)
  if res.val <=< key:
    return res.val
  else:
    result = buytempnode(self.val.head, key)
    self.val.insert(res.loc, result)

proc freenode0*[T](node: ptr TreeNode[T]) {.nodestroy.} =
  `=destroy`(node.left[])
  `=destroy`(node.parent[])
  `=destroy`(node.right[])
  cfree(node)
proc freenode*[T](node: ptr TreeNode[T]) {.nodestroy.} =
  `=destroy`(node.data)
  freenode0(node)

proc eraseTree[T](node: ptr TreeNode[T]) =
  var rootnode = node
  while not rootnode.isNil:
    eraseTree rootnode.right
    freenode(exchange(rootnode, rootnode.left))

proc eraseHead[T](self: var TreeVal[T]) =
  eraseTree(self.head.parent)
  freenode0(self.head)

proc erase*[T](self: var Tree[T], iter: TreeIterator[T]): ptr TreeNode[T] =
  if iter[].isNil: return iter[]
  var succ = iter
  succ.next()
  freenode(self.val.extract iter)
  succ[]

func first*[T](self: Tree[T]): TreeIterator[T] = result.raw = self.val.head.left
func last*[T](self: Tree[T]): TreeIterator[T] = result.raw = self.val.head
