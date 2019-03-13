function! asyncomplete#preprocessor#ezfilter#JaroWinkler#similarity(a, b) abort "{{{
  " NOTE: Cannot apply for multi-byte strings
  if a:a ==# '' && a:b ==# ''
    return 1.0
  elseif a:a ==# '' || a:b ==# ''
    return 0.0
  elseif a:a ==? a:b
    return 1.0
  endif
  let a = toupper(a:a)
  let b = toupper(a:b)
  let na = strlen(a:a)
  let nb = strlen(a:b)
  let [c, acommons, bcommons] = s:commonchar(a, b, na, nb)
  if c == 0.0
    return 0.0
  endif
  let t = s:transposechar(acommons, bcommons)
  let dj = (c/na + c/nb + 1.0 - t/c)/3.0
  let l = s:commonprefix(a, b, na, nb)
  let p = 0.1
  let djw = dj + l*p*(1.0 - dj)
  return djw
endfunction "}}}


function! asyncomplete#preprocessor#ezfilter#JaroWinkler#distance(a, b) abort "{{{
  return 1.0 - asyncomplete#preprocessor#ezfilter#JaroWinkler#similarity(a:a, a:b)
endfunction "}}}


function! s:commonchar(a, b, na, nb) abort "{{{
  " NOTE: Cannot apply for multi-byte strings
  let window = max([a:na, a:nb, 4])/2 - 1
  let c = 0.0
  let acommons = []
  let bindexes = []
  for i in range(len(a:a))
    let j = i - window
    while j <= i + window
      let start = j
      let j = stridx(a:b, a:a[i], start)
      if j == -1 || !count(bindexes, j)
        break
      endif
      let j += 1
    endwhile
    if j != -1 && j <= i + window
      call add(acommons, a:a[i])
      call add(bindexes, j)
      let c += 1.0
    endif
  endfor
  return [c, acommons, map(sort(bindexes), 'a:b[v:val]')]
endfunction "}}}


function! s:transposechar(acommons, bcommons) abort "{{{
  let n = len(a:acommons)
  if n <= 1
    return 0.0
  endif
  let t = 0.0
  for i in range(n)
    if a:acommons[i] !=# a:bcommons[i]
      let t += 1.0
    endif
  endfor
  return t/2
endfunction "}}}


function! s:commonprefix(a, b, na, nb) abort "{{{
  " NOTE: Cannot apply for multi-byte strings
  let l = 0
  while l < min([3, a:na, a:nb])
    if a:a[l] !=# a:b[l]
      break
    endif
    let l += 1
  endwhile
  return l > 4 ? 4 : l
endfunction "}}}

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" vim:set ts=2 sts=2 sw=2:

