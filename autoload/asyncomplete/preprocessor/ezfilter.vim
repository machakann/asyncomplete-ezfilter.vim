" load g:asyncomplete#preprocessor#ezfilter#config
let g:asyncomplete#preprocessor#ezfilter#config =
  \ get(g:, 'asyncomplete#preprocessor#ezfilter#config', {})
call extend(g:asyncomplete#preprocessor#ezfilter#config, {
  \ '*': {ctx, items -> filter(items, 'ctx.forwardmatch(v:val.word)')}},
  \ 'keep')


function! asyncomplete#preprocessor#ezfilter#filter(ctx, matches) abort "{{{
  let forwardmatchpat = '^' . s:escape(a:ctx.base)
  let ctx = copy(a:ctx)
  let ctx.forwardmatch = {item -> item =~? forwardmatchpat}
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

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:
