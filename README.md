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
  - [ ] parse
  - [x] expand
  - [x] inline
  - [x] compile
  - [x] load
- [ ] built-in macros
  - [ ] add more
  - [ ] resolution by number of parameters (`sort` and `sort(.id)` instead of `sort0` and `sort1(.id)`)
  - [ ] vararg indexing macro
  - [ ] autoapply on over-parameterization (`#.name` instead of `.name | #`)
- [ ] other
  - [ ] possibility to bind Lua functions and use them as macros
  - [ ] interpreter
  - [ ] documentation
