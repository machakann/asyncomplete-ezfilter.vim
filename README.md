asyncomplete-ezfilter.vim
=========================

This plugin provides the helper functions to build a custom preprocessor for [asyncomplete.vim v2](https://github.com/prabirshrestha/asyncomplete.vim/pull/124).


## Usage

Put the funcref of `asyncomplete#preprocessor#ezfilter#filter` at the beginning of `g:asyncomplete_preprocessor`. Then, set filter functions for each complete-source with its name as a key of `g:asyncomplete#preprocessor#ezfilter#config`. If no particular filter function was assigned, the filter in the key `'*'` is used.

The filter function should accept two arguments and return a list of completion items.

The first arguments `ctx` has the context information. For example, `ctx.base` is the string just before the cursor. Additionally, the `ctx` has several methods, `ctx.match(item)` returns true if the assigned string `item` is forward matched to `ctx.base`. Note that `ctx.match()` ignore the cases of the strings.

The second arguments `items` is a list of complete items. It is a shallow copy of `matches.items` (Refer the help of asyncomplete.vim v2). Check out `:help complete-items` for the specification of a complete item.


### Example

 * Match strings case-sensitive

```vim
let g:asyncomplete_preprocessor = [function('asyncomplete#preprocessor#ezfilter#filter')]

let g:asyncomplete#preprocessor#ezfilter#config = {
  \   '*': {ctx, items -> filter(items, 'stridx(v:val.word, ctx.base) == 0')}
  \ }
```

 * Use [asyncomplete-unicodesymbol](https://github.com/machakann/asyncomplete-unicodesymbol)

```vim
let g:asyncomplete_preprocessor = [function('asyncomplete#preprocessor#ezfilter#filter')]
let g:asyncomplete#preprocessor#ezfilter#config = {}

autocmd User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#unicodesymbol#get_source_options({
  \ 'name': 'unicodesymbol',
  \ 'whitelist': ['julia'],
  \ 'completor': function('asyncomplete#sources#unicodesymbol#completor'),
  \ }))

let g:asyncomplete#preprocessor#ezfilter#config.unicodesymbol =
  \ {ctx, items -> filter(items, 'ctx.match(v:val.menu)')}
```

 * Use [vim-Verdin](https://github.com/machakann/vim-Verdin)

```vim
let g:asyncomplete_preprocessor = [function('asyncomplete#preprocessor#ezfilter#filter')]
let g:asyncomplete#preprocessor#ezfilter#config = {}

autocmd User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#Verdin#get_source_options({
  \ 'name': 'Verdin',
  \ 'whitelist': ['vim'],
  \ 'completor': function('asyncomplete#sources#Verdin#completor'),
  \ }))

function! g:asyncomplete#preprocessor#ezfilter#config.Verdin(ctx, items) abort
  let list = filter(copy(a:items), 'a:ctx.match(v:val.word)')
  let n = strlen(a:ctx.base)
  if n > 3
    let fuzzy = filter(a:items, 'a:ctx.JWdistance(v:val.word[: n]) < 0.15')
    call extend(list, fuzzy)
  endif
  return list
endfunction
```


### Methods of ctx

 * ctx.match({item})

Return 1 if {item} is forward-matched with `ctx.base`, otherwise 0.

 * ctx.JWdistance({item}[, {base}])

Return the [Jaro-Winker distance](https://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance) between the two string {item} and {base}. `ctx.base` is used as {base} if it is omitted.

 * ctx.rDLdistance({item}[, {base}])

Return the [ristricted Damerau-Levenshtein distance](https://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance) (Optimal string alignment distance) between the two string {item} and {base}. `ctx.base` is used as {base} if it is omitted.
