let s:FALSE = 0
let s:TRUE = 1


" check whether python 3 interface is available or not
let s:python3_available = s:TRUE
if has('python3')
  try
    call py3eval('1')
  catch
    let s:python3_available = s:FALSE
  endtry
else
  let s:python3_available = s:FALSE
endif


" load python script if available
if s:python3_available
  py3 import vim
  py3file <sfile>:h:h:h:h/python3/asyncomplete_ezfilter.py
endif


function! asyncomplete#preprocessor#ezfilter#filter(ctx, matches) abort "{{{
  let config = g:asyncomplete#preprocessor#ezfilter#config
  let ctx = s:set_methods(copy(a:ctx))
  let items = []
  for [source_name, matches] in items(a:matches)
    let key = has_key(config, source_name) ? source_name : '*'
    let candidates = copy(matches.items)
    call extend(items, config[key](ctx, candidates))
  endfor
  call asyncomplete#preprocess_complete(a:ctx, items)
endfunction "}}}


if s:python3_available

  function! s:jw_distance(word, ...) dict abort "{{{
    let base = get(a:000, 0, self.base)
    return py3eval('asyncomplete_ezfilter.jaro_winkler_distance(vim.eval("a:word"), vim.eval("base"))')
  endfunction "}}}

  function! s:rDLdistance(word, ...) dict abort "{{{
    let base = get(a:000, 0, self.base)
    return py3eval('asyncomplete_ezfilter.ristricted_damerau_levenshtein_distance(vim.eval("a:word"), vim.eval("base"))')
  endfunction "}}}

  function! s:match_filter(items) abort "{{{
    return py3eval('asyncomplete_ezfilter.match_filter(vim.eval("a:items"), vim.eval("self.base"))')
  endfunction "}}}

  function! s:jw_filter(items, thr) dict abort "{{{
    return py3eval('asyncomplete_ezfilter.jaro_winkler_filter(vim.eval("a:items"), vim.eval("self.base"), vim.eval("a:thr"))')
  endfunction "}}}

  function! s:rDLdistance_filter(items, thr) dict abort "{{{
    return py3eval('asyncomplete_ezfilter.ristricted_damerau_levenshtein_filter(vim.eval("a:items"), vim.eval("self.base"), vim.eval("a:thr"))')
  endfunction "}}}

else

  function! s:jw_distance(word, ...) dict abort "{{{
    let base = get(a:000, 0, self.base)
    return asyncomplete#preprocessor#ezfilter#JaroWinkler#distance(a:word, base)
  endfunction "}}}

  function! s:rDLdistance(word, ...) dict abort "{{{
    let base = get(a:000, 0, self.base)
    return asyncomplete#preprocessor#ezfilter#rDamerauLevenshtein#distance(a:word, base)
  endfunction "}}}

  function! s:match_filter(items) dict abort "{{{
    return filter(a:items, 'self.match(v:val.word)')
  endfunction "}}}

  function! s:jw_filter(items, thr) dict abort "{{{
    let matchlist = self.match_filter(copy(a:items))
    let fuzzymatchlist = filter(a:items, '!self.match(v:val.word) && self.jw_distance(v:val.word) <= a:thr')
    return extend(matchlist, fuzzymatchlist)
  endfunction "}}}

  function! s:rDLdistance_filter(items, thr) dict abort "{{{
    let matchlist = self.match_filter(copy(a:items))
    let fuzzymatchlist = filter(a:items, '!self.match(v:val.word) && self.rDLdistance(v:val.word) <= a:thr')
    return extend(matchlist, fuzzymatchlist)
  endfunction "}}}

endif


function! s:set_methods(ctx) abort "{{{
  let matchpat = '^' . s:escape(a:ctx.base)
  let a:ctx.match = {word -> word =~? matchpat}
  let a:ctx.jw_distance = function('s:jw_distance')
  let a:ctx.rDLdistance = function('s:rDLdistance')
  let a:ctx.match_filter = function('s:match_filter')
  let a:ctx.jw_filter = function('s:jw_filter')
  let a:ctx.rDL_filter = function('s:rDLdistance_filter')
  return a:ctx
endfunction "}}}


function! s:escape(string) abort "{{{
    return escape(a:string, '~"\.^$[]*')
endfunction "}}}


" load g:asyncomplete#preprocessor#ezfilter#config
let g:asyncomplete#preprocessor#ezfilter#config =
  \ get(g:, 'asyncomplete#preprocessor#ezfilter#config', {})
call extend(g:asyncomplete#preprocessor#ezfilter#config, {
  \ '*': {ctx, items -> ctx.rDL_filter(items, 1)}}, 'keep')

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
