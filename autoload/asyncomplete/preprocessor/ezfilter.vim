let s:FALSE = 0
let s:TRUE = 1

let g:asyncomplete#preprocessor#ezfilter#python3 =
  \ get(g:, 'asyncomplete#preprocessor#ezfilter#python3', s:TRUE)


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


if s:python3_available && g:asyncomplete#preprocessor#ezfilter#python3

  " load python script if available
  py3 import vim
  py3file <sfile>:h:h:h:h/python3/asyncomplete_ezfilter.py

  function! s:jw_distance(word, base) abort "{{{
    return py3eval('asyncomplete_ezfilter.jaro_winkler_distance(vim.eval("a:word"), vim.eval("a:base"))')
  endfunction "}}}

  function! s:osa_distance(word, ...) dict abort "{{{
    let base = get(a:000, 0, self.base)
    return py3eval('asyncomplete_ezfilter.optimal_string_alignment_distance(vim.eval("a:word"), vim.eval("base"))')
  endfunction "}}}

  function! s:filter(items) abort "{{{
    return py3eval('asyncomplete_ezfilter.filter(vim.eval("a:items"), vim.eval("self.base"))')
  endfunction "}}}

  function! s:jw_filter(items, thr) dict abort "{{{
    return py3eval('asyncomplete_ezfilter.jaro_winkler_filter(vim.eval("a:items"), vim.eval("self.base"), vim.eval("a:thr"))')
  endfunction "}}}

  function! s:osa_filter(items, thr) dict abort "{{{
    return py3eval('asyncomplete_ezfilter.optimal_string_alignment_filter(vim.eval("a:items"), vim.eval("self.base"), vim.eval("a:thr"))')
  endfunction "}}}

else

  function! s:jw_distance(word, ...) dict abort "{{{
    let base = get(a:000, 0, self.base)
    return asyncomplete#preprocessor#ezfilter#JaroWinkler#distance(a:word, base)
  endfunction "}}}

  function! s:osa_distance(word, ...) dict abort "{{{
    let base = get(a:000, 0, self.base)
    return asyncomplete#preprocessor#ezfilter#OptimalStringAlignment#distance(a:word, base)
  endfunction "}}}

  function! s:filter(items) dict abort "{{{
    return filter(copy(a:items), 'self.match(v:val.word)')
  endfunction "}}}

  function! s:jw_filter(items, thr) dict abort "{{{
    let matchlist = self.filter(a:items)
    let fuzzymatchlist = filter(a:items, '!self.match(v:val.word) && self.jw_distance(v:val.word) <= a:thr')
    return extend(matchlist, fuzzymatchlist)
  endfunction "}}}

  function! s:osa_filter(items, thr) dict abort "{{{
    let matchlist = self.filter(a:items)
    let fuzzymatchlist = filter(a:items, '!self.match(v:val.word) && self.osa_distance(v:val.word) <= a:thr')
    return extend(matchlist, fuzzymatchlist)
  endfunction "}}}

endif


function! s:set_methods(ctx) abort "{{{
  let matchpat = '^' . s:escape(a:ctx.base)
  let a:ctx.match = {word -> word =~? matchpat}
  let a:ctx.jw_distance = function('s:jw_distance')
  let a:ctx.osa_distance = function('s:osa_distance')
  let a:ctx.filter = function('s:filter')
  let a:ctx.jw_filter = function('s:jw_filter')
  let a:ctx.osa_filter = function('s:osa_filter')
  return a:ctx
endfunction "}}}


function! s:escape(string) abort "{{{
    return escape(a:string, '~"\.^$[]*')
endfunction "}}}


" load g:asyncomplete#preprocessor#ezfilter#config
let g:asyncomplete#preprocessor#ezfilter#config =
  \ get(g:, 'asyncomplete#preprocessor#ezfilter#config', {})
call extend(g:asyncomplete#preprocessor#ezfilter#config, {
  \ '*': {ctx, items -> ctx.osa_filter(items, 1)}}, 'keep')

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
