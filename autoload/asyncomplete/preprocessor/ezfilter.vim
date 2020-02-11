let s:FALSE = 0
let s:TRUE = 1

let g:asyncomplete#preprocessor#ezfilter#python3 =
  \ get(g:, 'asyncomplete#preprocessor#ezfilter#python3', s:TRUE)


" check whether python 3 interface is available or not
let s:python3_available = s:FALSE
if g:asyncomplete#preprocessor#ezfilter#python3 && has('python3')
  try
    let s:python3_available = py3eval('1')
  catch
  endtry
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

  function! s:jw_distance(word, base, ...) abort "{{{
    let ignorecase = get(a:000, 0, s:TRUE) ? 'True' : 'False'
    let pyexpr = printf('asyncomplete_ezfilter.jaro_winkler_distance(vim.eval("a:word"), vim.eval("a:base"), ignorecase=%s)', ignorecase)
    return py3eval(pyexpr)
  endfunction "}}}

  function! s:osa_distance(word, base, ...) abort "{{{
    let ignorecase = get(a:000, 0, s:TRUE) ? 'True' : 'False'
    let pyexpr = printf('asyncomplete_ezfilter.optimal_string_alignment_distance(vim.eval("a:word"), vim.eval("a:base"), ignorecase=%s)', ignorecase)
    return py3eval(pyexpr)
  endfunction "}}}

  function! s:filter(items, base, ...) abort "{{{
    let ignorecase = get(a:000, 0, s:TRUE) ? 'True' : 'False'
    let pyexpr = printf('asyncomplete_ezfilter.match_filter(vim.eval("a:items"), vim.eval("a:base"), ignorecase=%s)', ignorecase)
    return py3eval(pyexpr)
  endfunction "}}}

  function! s:jw_filter(items, base, thr, ...) abort "{{{
    let ignorecase = get(a:000, 0, s:TRUE) ? 'True' : 'False'
    let pyexpr = printf('asyncomplete_ezfilter.jaro_winkler_filter(vim.eval("a:items"), vim.eval("a:base"), vim.eval("a:thr"), ignorecase=%s)', ignorecase)
    return py3eval(pyexpr)
  endfunction "}}}

  function! s:osa_filter(items, base, thr, ...) abort "{{{
    let ignorecase = get(a:000, 0, s:TRUE) ? 'True' : 'False'
    let pyexpr = printf('asyncomplete_ezfilter.optimal_string_alignment_filter(vim.eval("a:items"), vim.eval("a:base"), vim.eval("a:thr"), ignorecase=%s)', ignorecase)
    return py3eval(pyexpr)
  endfunction "}}}

else

  function! s:jw_distance(...) abort "{{{
    return call('asyncomplete#preprocessor#ezfilter#JaroWinkler#distance', a:000)
  endfunction "}}}

  function! s:osa_distance(...) abort "{{{
    return call('asyncomplete#preprocessor#ezfilter#OptimalStringAlignment#distance', a:000)
  endfunction "}}}

  function! s:filter(items, base, ...) abort "{{{
    let ignorecase = get(a:000, 0, s:TRUE)
    let matchpat = '^' . s:escape(a:base)
    if ignorecase
      return filter(copy(a:items), 'v:val.word =~? matchpat')
    else
      return filter(copy(a:items), 'v:val.word =~# matchpat')
    endif
  endfunction "}}}

  function! s:jw_filter(items, base, thr, ...) abort "{{{
    let ignorecase = get(a:000, 0, s:TRUE)
    let n = strlen(a:base)
    let matchlist = copy(a:items)
    for item in matchlist
      let word = strcharpart(item.word, 0, n)
      let item._distance = s:jw_distance(word, a:base, ignorecase)
    endfor
    call filter(matchlist, 'v:val._distance <= a:thr')
    call sort(matchlist, 's:compare_distance')
    return matchlist
  endfunction "}}}

  function! s:osa_filter(items, base, thr, ...) abort "{{{
    let ignorecase = get(a:000, 0, s:TRUE)
    let n = strlen(a:base)
    let matchlist = copy(a:items)
    for item in matchlist
      let word = strcharpart(item.word, 0, n)
      let item._distance = s:osa_distance(word, a:base, ignorecase)
    endfor
    call filter(matchlist, 'v:val._distance <= a:thr')
    call sort(matchlist, 's:compare_distance')
    return matchlist
  endfunction "}}}

endif


function! s:match(word, pat, ...) abort "{{{
  let ignorecase = get(a:000, 0, 1)
  if ignorecase
    return a:word =~? a:pat
  else
    return a:word =~# a:pat
  endif
endfunction "}}}


function! s:set_methods(ctx) abort "{{{
  let base = a:ctx.base
  let matchpat = '^' . s:escape(base)
  let a:ctx.match = {word -> s:match(word, matchpat, get(a:000, 0, s:TRUE))}
  let a:ctx.jw_distance = {word -> s:jw_distance(word, get(a:000, 0, base), get(a:000, 1, s:TRUE))}
  let a:ctx.osa_distance = {word -> s:osa_distance(word, get(a:000, 0, base), get(a:000, 1, s:TRUE))}
  let a:ctx.filter = {items -> s:filter(items, base, get(a:000, 0, s:TRUE))}
  let a:ctx.jw_filter = {items, thr -> s:jw_filter(items, base, thr, get(a:000, 0, s:TRUE))}
  let a:ctx.osa_filter = {items, thr -> s:osa_filter(items, base, thr, get(a:000, 0, s:TRUE))}
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


" For debug and performance check
function! asyncomplete#preprocessor#ezfilter#_obj(base) abort "{{{
  return s:set_methods({'base': a:base})
endfunction "}}}


" load g:asyncomplete#preprocessor#ezfilter#config
let g:asyncomplete#preprocessor#ezfilter#config =
  \ get(g:, 'asyncomplete#preprocessor#ezfilter#config', {})
call extend(g:asyncomplete#preprocessor#ezfilter#config,
  \ {'*': {ctx, items -> ctx.filter(items)}}, 'keep')

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
