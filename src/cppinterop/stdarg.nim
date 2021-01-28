type
  va_list* {.importc, header: "stdarg.h".} = cstring

proc vsnprintf(buffer: cstring; size: int; fmt: cstring; args: va_list): int {.importc.}

proc cfmt*(fmt: cstring; args: va_list): string =
  let len = vsnprintf(nil, 0, fmt, args)
  result.setLen len
  if len > 0:
    discard vsnprintf(result, len + 1, fmt, args)