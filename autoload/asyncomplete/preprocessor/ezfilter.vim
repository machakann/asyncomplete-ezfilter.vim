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
  let forwardmatchpat = '^' . s:escape(a:ctx.base)
  let ctx = copy(a:ctx)
  let ctx.forwardmatch = {word -> word =~? forwardmatchpat}
  let ctx.JWdistance = function('s:JWdistance')
  let ctx.rDLdistance = function('s:rDLdistance')
  let config = g:asyncomplete#preprocessor#ezfilter#config
  let items = []
  for [source_name, matches] in items(a:matches)
    let key = has_key(config, source_name) ? source_name : '*'
    let candidates = copy(matches.items)
    call extend(items, config[key](ctx, candidates))
  endfor
  call asyncomplete#preprocess_complete(a:ctx, items)
endfunction "}}}


" function! s:forwardmatch_filter() abort {{{
if s:python3_available
  function! s:forwardmatch_filter(ctx, items) abort
    return py3eval('asyncomplete_ezfilter.forwardmatch_filter(vim.eval("a:items"), vim.eval("a:ctx.base"))')
  endfunction
else
  function! s:forwardmatch_filter(ctx, items) abort
    return filter(a:items, 'ctx.forwardmatch(v:val.word)')
  endfunction
endif
"}}}


function! s:JWdistance(item, ...) dict abort "{{{
  let base = get(a:000, 0, self.base)
  return asyncomplete#preprocessor#ezfilter#JaroWinkler#distance(a:item, base)
endfunction "}}}


function! s:rDLdistance(item, ...) dict abort "{{{
  let base = get(a:000, 0, self.base)
  return asyncomplete#preprocessor#ezfilter#rDamerauLevenshtein#distance(a:item, base)
endfunction "}}}


function! s:escape(string) abort "{{{
    return escape(a:string, '~"\.^$[]*')
endfunction "}}}


" load g:asyncomplete#preprocessor#ezfilter#config
let g:asyncomplete#preprocessor#ezfilter#config =
  \ get(g:, 'asyncomplete#preprocessor#ezfilter#config', {})
call extend(g:asyncomplete#preprocessor#ezfilter#config, {
  \ '*': function('s:forwardmatch_filter')}, 'keep')

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
