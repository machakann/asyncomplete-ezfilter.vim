asyncomplete-ezfilter.vim
=========================

[![Build Status](https://travis-ci.org/machakann/asyncomplete-ezfilter.vim.svg?branch=master)](https://travis-ci.org/machakann/asyncomplete-ezfilter.vim)

This plugin provides helper functions to build a custom preprocessor for [asyncomplete.vim](https://github.com/prabirshrestha/asyncomplete.vim).


## Usage

This plugin aimed at filtering completion candidates by source specific filter functions.

First, assign the funcref of `asyncomplete#preprocessor#ezfilter#filter` at the beginning of `g:asyncomplete_preprocessor`. Then, set filter functions for each complete-source with its name as a key of `g:asyncomplete#preprocessor#ezfilter#config`. If no particular filter function was assigned, the filter associated with the key `'*'` is used.

The filter function should accept two arguments and return a list of completion items.

The first argument `ctx` has the context information. For example, `ctx.base` is the string just before the cursor. Additionally, the `ctx` has several useful methods for filtering, see the reference.

The second argument `items` is a list of items to complete. It is a shallow copy of `matches.items` (Refer the help of asyncomplete.vim). Check out `:help complete-items` for the specification of a completion item.


### Example

 * Match items case-insensitive

```vim
let g:asyncomplete_preprocessor =
  \ [function('asyncomplete#preprocessor#ezfilter#filter')]

let g:asyncomplete#preprocessor#ezfilter#config = {}
let g:asyncomplete#preprocessor#ezfilter#config['*'] =
  \ {ctx, items -> ctx.filter(items)}
```

 * Match items case-sensitive

```vim
let g:asyncomplete_preprocessor =
  \ [function('asyncomplete#preprocessor#ezfilter#filter')]

let s:FALSE = 0
let g:asyncomplete#preprocessor#ezfilter#config = {}
let g:asyncomplete#preprocessor#ezfilter#config['*'] =
  \ {ctx, items -> ctx.filter(items, s:FALSE)}
```

 * Use [asyncomplete-unicodesymbol.vim](https://github.com/machakann/asyncomplete-unicodesymbol.vim)

```vim
let g:asyncomplete_preprocessor =
  \ [function('asyncomplete#preprocessor#ezfilter#filter')]

autocmd User asyncomplete_setup call asyncomplete#register_source(
  \ asyncomplete#sources#unicodesymbol#get_source_options({
  \   'name': 'unicodesymbol',
  \   'whitelist': ['julia'],
  \   'completor': function('asyncomplete#sources#unicodesymbol#completor'),
  \ }))

let g:asyncomplete#preprocessor#ezfilter#config = {}
let g:asyncomplete#preprocessor#ezfilter#config.unicodesymbol =
  \ {ctx, items -> filter(items, 'ctx.match(v:val.menu)')}
```

 * Use [vim-Verdin](https://github.com/machakann/vim-Verdin) with fuzzy-matching

```vim
let g:asyncomplete_preprocessor =
  \ [function('asyncomplete#preprocessor#ezfilter#filter')]

autocmd User asyncomplete_setup call asyncomplete#register_source(
  \ asyncomplete#sources#Verdin#get_source_options({
  \   'name': 'Verdin',
  \   'whitelist': ['vim', 'vimspec', 'help'],
  \   'completor': function('asyncomplete#sources#Verdin#completor'),
  \ }))

let g:asyncomplete#preprocessor#ezfilter#config = {}
let g:asyncomplete#preprocessor#ezfilter#config.Verdin =
  \ {ctx, items -> ctx.osa_filter(items, 1)}
```


## Methods of ctx

### ctx.match({item} [, {ic}])

Return 1 if `{item}.word` is forward-matched with `ctx.base`, otherwise 0.
This method ignores case in default; it can be case-sensitive only when `{ic}` is given and it is a faly value (like 0), however.

### ctx.jw_ditance({item}[, {base} [, {ic}]])

Return the [Jaro-Winker distance](https://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance) between the two string `{item}` and `{base}`. Jaro-Winkler distance ranges from 0 to 1, smaller is similar. `ctx.base` is used as `{base}` if it is omitted.
This method ignores case in default; it can be case-sensitive only when `{ic}` is given and it is a falsy value (like 0), however.

### ctx.osa_distance({item}[, {base} [, {ic}]])

Return the [ristricted Damerau-Levenshtein distance](https://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance) (Optimal string alignment distance) between the two string `{item}` and `{base}`. Ristricted Damerau-Levenshtein distance represents the number of edit to make the two strings equal by deletion, insertion, substitution or transposition. Smaller is similar. `ctx.base` is used as `{base}` if it is omitted.
This method ignores case in default; it can be case-sensitive only when `{ic}` is given and it is a falsy value (like 0), however.

### ctx.filter({items} [, {ic}])

Filter items in `{items}` by forward-matching. This is an equivalent of `filter(copy({items}), 'ctx.match(v:val.word)')` but might be faster if python3 interface is available.
This method ignores case in default; it can be case-sensitive only when `{ic}` is given and it is a falsy value (like 0), however.

### ctx.jw_filter({items}, {thr} [, {ic}])

Filter items in `{items}` by Jaro-Winkler distance; items with a distance larger than `{thr}` are filtered out. Jaro-Winkler distance ranges from 0 to 1, typically 0.15 may work.
This method ignores case in default; it can be case-sensitive only when `{ic}` is given and it is a falsy value (like 0), however.

### ctx.osa_filter({items}, {thr} [, {ic}])

Filter items in `{items}` by optimal string alignment distance; items with a distance larger than `{thr}` are filtered out. Typically, 1 or 2 may work.
This method ignores case in default; it can be case-sensitive only when `{ic}` is given and it is a falsy value (like 0), however.


## Note

This plugin uses python3 interface if available. If you don't want, set a false value to `g:asyncomplete#preprocessor#ezfilter#python3`.

```vim
let g:asyncomplete#preprocessor#ezfilter#python3 = 0
```
