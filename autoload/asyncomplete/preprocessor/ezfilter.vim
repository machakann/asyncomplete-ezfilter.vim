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

  function! s:osa_distance(word, base) abort "{{{
    return py3eval('asyncomplete_ezfilter.optimal_string_alignment_distance(vim.eval("a:word"), vim.eval("a:base"))')
  endfunction "}}}

  function! s:filter(items, base) abort "{{{
    return py3eval('asyncomplete_ezfilter.filter(vim.eval("a:items"), vim.eval("a:base"))')
  endfunction "}}}

  function! s:jw_filter(items, base, thr) abort "{{{
    return py3eval('asyncomplete_ezfilter.jaro_winkler_filter(vim.eval("a:items"), vim.eval("a:base"), vim.eval("a:thr"))')
  endfunction "}}}

  function! s:osa_filter(items, base, thr) abort "{{{
    return py3eval('asyncomplete_ezfilter.optimal_string_alignment_filter(vim.eval("a:items"), vim.eval("a:base"), vim.eval("a:thr"))')
  endfunction "}}}

else

  function! s:jw_distance(word, base) abort "{{{
    return asyncomplete#preprocessor#ezfilter#JaroWinkler#distance(a:word, a:base)
  endfunction "}}}

  function! s:osa_distance(word, base) abort "{{{
    return asyncomplete#preprocessor#ezfilter#OptimalStringAlignment#distance(a:word, a:base)
  endfunction "}}}

  function! s:filter(items, base) abort "{{{
    let matchpat = '^' . s:escape(a:base)
    return filter(copy(a:items), 'v:val.word =~? matchpat')
  endfunction "}}}

  function! s:jw_filter(items, base, thr) abort "{{{
    let matchlist = copy(a:items)
    for item in matchlist
      let item._distance = s:jw_distance(item.word, a:base)
    endfor
    call filter(matchlist, 'v:val._distance <= a:thr')
    call sort(matchlist, 's:compare_distance')
    return matchlist
  endfunction "}}}

  function! s:osa_filter(items, base, thr) abort "{{{
    let matchlist = copy(a:items)
    for item in matchlist
      let item._distance = s:osa_distance(item.word, a:base)
    endfor
    call filter(matchlist, 'v:val._distance <= a:thr')
    call sort(matchlist, 's:compare_distance')
    return matchlist
  endfunction "}}}

endif


function! s:set_methods(ctx) abort "{{{
  let base = a:ctx.base
  let matchpat = '^' . s:escape(base)
  let a:ctx.match = {word -> word =~? matchpat}
  let a:ctx.jw_distance = {word -> s:jw_distance(word, get(a:000, 0, base))}
  let a:ctx.osa_distance = {word -> s:osa_distance(word, get(a:000, 0, base))}
  let a:ctx.filter = {items -> s:filter(items, base)}
  let a:ctx.jw_filter = {items, thr -> s:jw_filter(items, base, thr)}
  let a:ctx.osa_filter = {items, thr -> s:osa_filter(items, base, thr)}
  return a:ctx
endfunction "}}}


function! s:escape(string) abort "{{{
    return escape(a:string, '~"\.^$[]*')
endfunction "}}}


function! s:compare_distance(a, b) abort "{{{
  if a:a._distance > a:b._distance
    return 1
  elseif a:a._distance < a:b._distance
    return -1
  endif
  return 0
endfunction "}}}


" load g:asyncomplete#preprocessor#ezfilter#config
let g:asyncomplete#preprocessor#ezfilter#config =
  \ get(g:, 'asyncomplete#preprocessor#ezfilter#config', {})
call extend(g:asyncomplete#preprocessor#ezfilter#config,
  \ {'*': {ctx, items -> ctx.osa_filter(items, 1)}}, 'keep')

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
