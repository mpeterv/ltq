# ltq

[![Build Status](https://travis-ci.org/mpeterv/ltq.svg?branch=master)](https://travis-ci.org/mpeterv/ltq)

ltq is a tiny purely functional programming language that compiles to [Lua](http://www.lua.org/). Its goal is to help constructing functions for exploring complex systems of Lua tables.

A ltq expression represents a Lua function of one argument and one return value. The simplest ltq expession, `.`, is equivalent to identity function, and compiles to `function(x) return x end`. Other primitives are literals and indexing functions, like `.[1]`, which takes a Lua table and returns its first item. 

ltq expressions can be combined using built-in macros to create complex pipelines. For example, `.books | filter(.year >= 2000) \ .ISBN | sort` is equivalent to the following Lua function, assuming conventional definitions of `map` and `filter`:

```lua
function(store)
   local books = store.books
   local new_books = filter(function(book) return book.year >= 2000 end, books)
   local isbns_of_new_books = map(function(book) return book.ISBN end, new_books)
   table.sort(isbns_of_new_books)
   return isbns_of_new_books
end
```

## Status

WIP.

- [ ] compiler pipeline
  - [ ] lex
    - [x] punctuation
    - [ ] short strings
      - [x] simple short strings
      - [x] simple escape sequences
      - [ ] multiline short strings
      - [ ] decimal escape sequences
      - [ ] hexadecimal escape sequences
      - [ ] UTF-8 escape sequences
      - [ ] `\z` escape sequence
    - [ ] long strings
    - [ ] numbers
      - [x] decimal numbers
      - [ ] hexadecimal numbers
    - [ ] comments
      - [ ] short coments
      - [ ] long comments
    - [ ] error handling
  - [ ] parse
  - [ ] expand
    - [x] expand macros by name
    - [ ] expand macros by number of parameters
  - [x] inline
  - [ ] compile
    - [x] compile primitives by name
    - [ ] compile primitives by number of arguments
  - [x] load
- [ ] built-in macros
  - [ ] add more
  - [ ] vararg indexing macro
  - [ ] vararg table construction macro
  - [ ] autoapply on over-parameterization (`#.name` instead of `.name | #`)
- [ ] other
  - [ ] possibility to bind Lua functions and use them as macros
  - [ ] interpreter
  - [ ] documentation
