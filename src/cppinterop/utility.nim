func exchange*[T](self: var T; rhs: T): T =
  result = self
  self = rhs