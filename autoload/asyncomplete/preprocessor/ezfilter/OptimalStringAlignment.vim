function! asyncomplete#preprocessor#ezfilter#OptimalStringAlignment#distance(a, b, ...) abort "{{{
  " NOTE: Cannot apply for multi-byte strings
  let ignorecase = get(a:000, 0, 1)
  if ignorecase
    let a = toupper(a:a)
    let b = toupper(a:b)
  else
    let a = a:a
    let b = a:b
  endif
  let na = strchars(a)
  let nb = strchars(b)
  let nmax = max([na, nb])
  if nmax > s:dmax
    let d = s:distancemap(nmax)
  else
    let d = copy(s:distancemap)
  endif
  for i in range(1, na)
    for j in range(1, nb)
      let const = a[i-1] ==# b[j-1] ? 0 : 1
      if i > 1 && j > 1 && a[i-1] ==# b[j-2] && a[i-2] ==# b[j-1]
        let d[i][j] = min([d[i-1][j] + 1, d[i][j-1] + 1, d[i-1][j-1] + const, d[i-2][j-2] + const])
      else
        let d[i][j] = min([d[i-1][j] + 1, d[i][j-1] + 1, d[i-1][j-1] + const])
      endif
    endfor
  endfor
  return d[na][nb]
endfunction "}}}


function! s:distancemap(n) abort "{{{
  let d = [range(a:n + 1)]
  for i in range(1, a:n)
    let d += [[i] + repeat([0], a:n)]
  endfor
  return d
endfunction "}}}
let s:dmax = 20
let s:distancemap = s:distancemap(s:dmax)

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:

