" vim: tabstop=2 shiftwidth=2 softtabstop=2 expandtab foldmethod=marker
"    Copyright: Copyright (C) 2012 Brook Hong
"    License: The MIT License
"
set cscopequickfix=s-,g-,d-,c-,t-,e-,f-,i-
" s: Find this C symbol
map <leader>fs :call CscopeFind('s', expand('<cword>'))<CR>
" g: Find this definition
map <leader>fg :call CscopeFind('g', expand('<cword>'))<CR>
" d: Find functions called by this function
map <leader>fd :call CscopeFind('d', expand('<cword>'))<CR>
" c: Find functions calling this function
map <leader>fc :call CscopeFind('c', expand('<cword>'))<CR>
" t: Find this text string
map <leader>ft :call CscopeFind('t', expand('<cword>'))<CR>
" e: Find this egrep pattern
map <leader>fe :call CscopeFind('e', expand('<cword>'))<CR>
" f: Find this file
map <leader>ff :call CscopeFind('f', expand('<cword>'))<CR>
" i: Find files #including this file
map <leader>fi :call CscopeFind('i', expand('<cword>'))<CR>
map <leader>l :call ToggleLocationList()<CR>

com! -nargs=? -complete=dir CscopeGen call CreateCscopeDB("<args>")
com! -nargs=0 CscopeList call <SID>ListDBs()
com! -nargs=0 CscopeClear call <SID>ClearCscopeDB()

function! s:ClearCscopeDB()
  cs kill -1
  let s:loaded_dbs = []
  let s:dbs = {}
  let s:dbstat = {}
  let s:db_dirs = []
  call <SID>RmDBfiles()
  call writefile([], s:index_file)
endfunction

function! s:ListDBs()
  let s = [' ID                   COUNT    PATH']
  for d in s:db_dirs
    if count(s:loaded_dbs,d)
      let l = printf("*%d  %10d        %s",s:dbs[d],s:dbstat[d],d)
    else
      let l = printf(" %d  %10d        %s",s:dbs[d],s:dbstat[d],d)
    endif
    call add(s, l)
  endfor
  echo join(s, "\n")
endfunction

function! ToggleLocationList()
  let l:own = winnr()
  lw
  let l:cwn = winnr()
  if(l:cwn == l:own)
    if &buftype == 'quickfix'
      lclose
    elseif len(getloclist(winnr())) > 0
      lclose
    else
      echohl WarningMsg | echo "No location list." | echohl None
    endif
  endif
endfunction

function! CscopeFind(action, word)
  let r = <SID>AutoloadCscopeDB()
  if r
    try
      exe ':lcs f '.a:action.' '.a:word
      lw
    catch
      echohl WarningMsg | echo 'Can not find '.a:word.' with querytype as '.a:action.'.' | echohl None
    endtry
  endif
endfunction

if !exists('g:cscope_cmd')
  let g:cscope_cmd = 'cscope'
endif

if !exists('g:cscope_ignore_files')
  let g:cscope_ignore_files = '\.3dm$\|\.3g2$\|\.3gp$\|\.7z$\|\.a$\|\.a.out$\|\.accdb$\|\.ai$\|\.aif$\|\.aiff$\|\.app$\|\.arj$\|\.asf$\|\.asx$\|\.au$\|\.avi$\|\.bak$\|\.bin$\|\.bmp$\|\.bz2$\|\.cab$\|\.cer$\|\.cfm$\|\.cgi$\|\.com$\|\.cpl$\|\.csr$\|\.csv$\|\.cue$\|\.cur$\|\.dat$\|\.db$\|\.dbf$\|\.dbx$\|\.dds$\|\.deb$\|\.dem$\|\.dll$\|\.dmg$\|\.dmp$\|\.dng$\|\.doc$\|\.docx$\|\.drv$\|\.dwg$\|\.dxf$\|\.ear$\|\.efx$\|\.eps$\|\.epub$\|\.exe$\|\.fla$\|\.flv$\|\.fnt$\|\.fon$\|\.gadget$\|\.gam$\|\.gbr$\|\.ged$\|\.gif$\|\.gpx$\|\.gz$\|\.hqx$\|\.ibooks$\|\.icns$\|\.ico$\|\.ics$\|\.iff$\|\.img$\|\.indd$\|\.iso$\|\.jar$\|\.jpeg$\|\.jpg$\|\.key$\|\.keychain$\|\.kml$\|\.lnk$\|\.lz$\|\.m3u$\|\.m4a$\|\.max$\|\.mdb$\|\.mid$\|\.mim$\|\.moov$\|\.mov$\|\.movie$\|\.mp2$\|\.mp3$\|\.mp4$\|\.mpa$\|\.mpeg$\|\.mpg$\|\.msg$\|\.msi$\|\.nes$\|\.o$\|\.obj$\|\.ocx$\|\.odt$\|\.otf$\|\.pages$\|\.part$\|\.pct$\|\.pdb$\|\.pdf$\|\.pif$\|\.pkg$\|\.plugin$\|\.png$\|\.pps$\|\.ppt$\|\.pptx$\|\.prf$\|\.ps$\|\.psd$\|\.pspimage$\|\.qt$\|\.ra$\|\.rar$\|\.rm$\|\.rom$\|\.rpm$\|\.rtf$\|\.sav$\|\.scr$\|\.sdf$\|\.sea$\|\.sit$\|\.sitx$\|\.sln$\|\.smi$\|\.so$\|\.svg$\|\.swf$\|\.swp$\|\.sys$\|\.tar$\|\.tar.gz$\|\.tax2010$\|\.tga$\|\.thm$\|\.tif$\|\.tiff$\|\.tlb$\|\.tmp$\|\.toast$\|\.torrent$\|\.ttc$\|\.ttf$\|\.uu$\|\.uue$\|\.vb$\|\.vcd$\|\.vcf$\|\.vcxproj$\|\.vob$\|\.war$\|\.wav$\|\.wma$\|\.wmv$\|\.wpd$\|\.wps$\|\.xll$\|\.xlr$\|\.xls$\|\.xlsx$\|\.xpi$\|\.yuv$\|\.Z$\|\.zip$\|\.zipx$\|\.lib$\|\.res$\|\.rc$\|\.out$\|\.cache$\|\.tgz$\|\.gho$\|\.ghs$'
endif

if exists('g:cscope_ignore_strict') && g:cscope_ignore_strict == 1
  let g:cscope_ignore_files = g:cscope_ignore_files.'\|\.xml$\|\.yml$\|\.ini$\|\.conf$\|\.css$\|\.htc$\|\.bat$\|\.sh$\|\.txt$\|\.log$\|\.dtd$\|\.xsd$'
endif

if !exists('g:cscope_files_kept')
  let g:cscope_files_kept = 0
endif

let s:cscope_vim_dir = substitute($HOME,'\\','/','g')."/.cscope.vim"
let s:index_file = s:cscope_vim_dir.'/index'
let s:db_dirs = []
let s:loaded_dbs = []

function! s:ListFiles(dir)
  let d = []
  let f = []
  let cwd = a:dir
  let sl = &l:stl
  while cwd != ''
    let a = split(globpath(cwd, "*"), "\n")
    for fn in a
      if getftype(fn) == 'dir'
        call add(d, fn)
      elseif getftype(fn) != 'file'
        continue
      elseif stridx(fn, '.') == -1
        continue
      elseif fn =~ g:cscope_ignore_files
        continue
      else
        if stridx(fn, ' ') != -1
          let fn = '"'.fn.'"'
        endif
        call add(f, fn)
      endif
    endfor
    let cwd = len(d) ? remove(d, 0) : ''
    sleep 1m | let &l:stl = 'Found '.len(f).' files, finding in '.cwd | redrawstatus
  endwhile
  sleep 1m | let &l:stl = sl | redrawstatus
  return f
endfunction

function! s:RmDBfiles()
  let odbs = split(globpath(s:cscope_vim_dir, "*"), "\n")
  for f in odbs
    call delete(f)
  endfor
endfunction

function! s:LoadIndex()
  let s:dbs = {}
  let s:dbstat = {}
  if ! isdirectory(s:cscope_vim_dir)
    call mkdir(s:cscope_vim_dir)
  elseif filereadable(s:index_file)
    let idx = readfile(s:index_file)
    for i in idx
      let e = matchlist(i,'\(.*\)|\(.*\)|\(.*\)')
      if len(e) == 0
        call delete(s:index_file)
        call <SID>RmDBfiles()
      else
        let db_file = s:cscope_vim_dir.'/'.e[2].'.db'
        if filereadable(db_file)
          if isdirectory(e[1])
            let s:dbs[e[1]] = e[2]
            let s:dbstat[e[1]] = e[3]
          else
            call delete(db_file)
          endif
        endif
      endif
    endfor
  else
    call <SID>RmDBfiles()
  endif
  let s:db_dirs = keys(s:dbs)
endfunction
call <SID>LoadIndex()

function! s:FlushIndex()
  let lines = []
  for d in s:db_dirs
    call add(lines, d.'|'.s:dbs[d].'|'.s:dbstat[d])
  endfor
  call writefile(lines, s:index_file)
endfunction

function! s:GetIndex(dir)
  let id = 0
  if count(s:db_dirs, a:dir)
    let id = s:dbs[a:dir]
  else
    let id = localtime()
    let s:dbs[a:dir] = id
    let s:dbstat[a:dir] = 0
    call add(s:db_dirs, a:dir)
    call <SID>FlushIndex()
  endif
  return id
endfunction

function! s:_CreateCscopeDB(dir,id)
  if ! isdirectory(s:cscope_vim_dir)
    call mkdir(s:cscope_vim_dir)
  endif
  let cscope_files = s:cscope_vim_dir."/".a:id.".files"
  let cscope_db = s:cscope_vim_dir.'/'.a:id.'.db'
  let files = <SID>ListFiles(a:dir)
  call writefile(files, cscope_files)
  exe '!'.g:cscope_cmd.' -b -i '.cscope_files
  call rename('cscope.out', cscope_db)
  if g:cscope_files_kept == 0
    call delete(cscope_files)
  endif
endfunction

function! s:CheckAbsolutePath(dir, defaultPath)
  let d = a:dir
  while 1
    if !isdirectory(d)
      echohl WarningMsg | echo "Please input a valid path." | echohl None
      let d = input("", a:defaultPath, 'dir')
    elseif (len(d) < 2 || (d[0] != '/' && d[1] != ':'))
      echohl WarningMsg | echo "Please input an absolute path." | echohl None
      let d = input("", a:defaultPath, 'dir')
    else
      break
    endif
  endwhile
  let d = substitute(d,'\\','/','g')
  let d = substitute(d,'/\+$','','')
  return d
endfunction

function! CreateCscopeDB(dir)
  cs kill -1
  let s:loaded_dbs = []
  let dirs = []
  if (a:dir == "")
    let dirs = s:db_dirs
  else
    let cwd = <SID>CheckAbsolutePath(a:dir, getcwd())
    let dirs = [cwd]
  endif
  for d in dirs
    if count(s:db_dirs, d)
      let id = s:dbs[d]
      let cscope_db = s:cscope_vim_dir.'/'.id.'.db'
      if filereadable(cscope_db)
        call delete(cscope_db)
      endif
    else
      call add(s:db_dirs, d)
      let s:dbstat[d] = 0
    endif
    let id = localtime()
    let s:dbs[d] = id
    call <SID>FlushIndex()
    call <SID>_CreateCscopeDB(d, id)
  endfor
endfunction

function! s:AutoloadCscopeDB()
  let r = 0
  let p = expand('%:p:h')
  let f = substitute(p,'\\','/','g')
  for d in s:loaded_dbs
    if f =~ d.'.*$'
      return 1
    endif
  endfor
  let m_db_dirs = []
  for d in s:db_dirs
    if f =~ d.'.*$'
      call add(m_db_dirs, d)
    endif
  endfor
  let l = len(m_db_dirs)
  let m_db = ''
  if l > 0
    let m_db_dirs = sort(m_db_dirs)
    let m_dir = m_db_dirs[l-1]
    let m_db = s:cscope_vim_dir.'/'.s:dbs[m_dir].'.db'
  else
    echohl WarningMsg | echo "Can not find proper cscope db, please input a path to generate cscope db for." | echohl None
    let m_dir = input("", p, 'dir')
    if m_dir != ''
      let m_dir = <SID>CheckAbsolutePath(m_dir, p)
      let id = <SID>GetIndex(m_dir)
      let m_db = s:cscope_vim_dir.'/'.id.'.db'
      if ! filereadable(m_db)
        call <SID>_CreateCscopeDB(m_dir, id)
      endif
    endif
  endif
  if m_db != ''
    exe 'cs add '.m_db
    let s:dbstat[m_dir] = s:dbstat[m_dir]+1
    call <SID>FlushIndex()
    call add(s:loaded_dbs, m_dir)
    let r = 1
  endif
  return r
endfunction
