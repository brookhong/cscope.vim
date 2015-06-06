    " vim: tabstop=2 shiftwidth=2 softtabstop=2 expandtab foldmethod=marker
"    Copyright: Copyright (C) 2012-2015 Brook Hong
"    License: The MIT License
"
let s:cscope_vim_db_dir = substitute($HOME,'\\','/','g')."/.cscope.vim"
let s:cscope_vim_db_index_file = s:cscope_vim_db_dir.'/index'
let s:cscope_vim_db_current_prepend_path = ""
let s:cscope_vim_db_entry_len = 5
let s:cscope_vim_db_entry_idx_prepend_path = 0
let s:cscope_vim_db_entry_idx_id = 1
let s:cscope_vim_db_entry_idx_loadtimes = 2
let s:cscope_vim_db_entry_idx_dirty = 3
let s:cscope_vim_db_entry_idx_depedency = 4
let s:cscope_vim_db_entry_key_id = 'id'
let s:cscope_vim_db_entry_key_loadtimes = 'loadtimes'
let s:cscope_vim_db_entry_key_dirty = 'dirty'
let s:cscope_vim_db_entry_key_depedency = 'depedency'

function! CscopeFind(action, word, ...)
  " ============================================
  " the a:1 is used for window spliting control.
  " ============================================
  let l:current_path = tolower(substitute(expand('%:p:h'), '\\', '/', 'g'))
  let l:prepend_path = <SID>GetPrependPath(l:current_path)
  let l:in_dependency = 0

  " possible reasons for empty prepend path
  "   - DB not yet built
  "   - we are in depedency files 
  if l:prepend_path == "" && s:cscope_vim_db_current_prepend_path != ""
    for l:d in split(s:dbs[s:cscope_vim_db_current_prepend_path][s:cscope_vim_db_entry_key_depedency], ';')
      let l:d = substitute(l:d, "\/\\s*$", '', 'g')

      if stridx(l:current_path, l:d) == 0
        let l:in_dependency = 1
        break
      endif
    endfor
  endif
  
  " build a brand new db
  if l:prepend_path == "" && l:in_dependency == 0 
    let l:prepend_path = <SID>InitDB(l:current_path)

    if l:prepend_path != ""
      call <SID>BuildDB(l:prepend_path, 1)
      call <SID>LoadDB(l:prepend_path)
    endif
  endif

  if l:prepend_path != ""
    let l:id = s:dbs[l:prepend_path][s:cscope_vim_db_entry_key_id]

    if cscope_connection(2, s:cscope_vim_db_dir.'/'.l:id.'.db') == 0
      call <SID>LoadDB(l:prepend_path)
    endif
  endif

  try
    if a:0 == 0 
      exe ':cs f '.a:action.' '.a:word
    elseif a:0 >= 1 && a:1 == 'horizontal'
      exe ':scs f '.a:action.' '.a:word
    elseif a:0 >= 1 && a:1 == 'vertical'
      exe ':vert scs f '.a:action.' '.a:word
    endif

    if g:cscope_open_location == 1
      cw
    endif
  catch
    echohl WarningMsg | echo 'Can not find '.a:word.' with querytype as '.a:action.'.' | echohl None
  endtry
endfunction

function! CscopeFindInteractive(pat)
    call inputsave()

    let qt = input("\nChoose a querytype for '".a:pat."'(:help cscope-find)\n  c: functions calling this function\n  d: functions called by this function\n  e: this egrep pattern\n  f: this file\n  g: this definition\n  i: files #including this file\n  s: this C symbol\n  t: this text string\n\n  or\n  <querytype><pattern> to query `pattern` instead of '".a:pat."' as `querytype`, Ex. `smain` to query a C symbol named 'main'.\n> ")

    call inputrestore()

    if len(qt) > 1
      call CscopeFind(qt[0], qt[1:])
    elseif len(qt) > 0
      call CscopeFind(qt, a:pat)
    endif
endfunction

function! CscopeUpdateAllDB()
  call <SID>UpdateDBs(keys(s:dbs))
endfunction

function! CscopeUpdateCurrentDB()
  let l:current_path = expand('%:p:h')
  let l:prepend_path = <SID>GetPrependPath(l:current_path)

  if l:prepend_path != ""
    call <SID>UpdateDBs([l:prepend_path])
  else
    let l:prepend_path = <SID>InitDB(l:current_path)

    if l:prepend_path != ""
      call <SID>BuildDB(l:prepend_path, 1)
      call <SID>LoadDB(l:prepend_path)
    endif
  endif
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

" @param clearWhich:  -1   all database
"                      0   the current database
function! s:ClearDBs(clearWhich)
  cs kill -1
  
  if a:clearWhich == -1
    let s:dbs = {}
    call <SID>RmDBfiles()
    call writefile([], s:cscope_vim_db_index_file)
  endif

endfunction

function! s:BuildDB(prepend_path, init)
  let l:id = s:dbs[a:prepend_path][s:cscope_vim_db_entry_key_id]
  let l:depedency = split(s:dbs[a:prepend_path][s:cscope_vim_db_entry_key_depedency], ';')
  let l:cscope_files = s:cscope_vim_db_dir."/".id."_inc.files"
  let l:cscope_db = s:cscope_vim_db_dir.'/'.id.'_inc.db'

  if ! filereadable(cscope_files) || a:init
    let l:cscope_files = s:cscope_vim_db_dir."/".id.".files"
    let l:cscope_db = s:cscope_vim_db_dir.'/'.id.'.db'
  endif

  " validate depedency
  for i in range(len(l:depedency))
    let l:depedency[i] = <SID>CheckAbsolutePath(l:depedency[i], "")
  endfor

  " force update file list
  let files = []
  for d in [a:prepend_path] + l:depedency
    let files += <SID>ListFiles(d)
  endfor
  call writefile(files, cscope_files)

  " build cscope database
  exec 'cs kill '.cscope_db
  redir @x
  exec 'silent !'.g:cscope_cmd.' -b -i '.cscope_files.' -f'.cscope_db
  redir END

  " check build result and add database
  if @x =~ "\nCommand terminated\n"
    echohl WarningMsg | echo "Failed to create cscope database for ".a:prepend_path.", please check if " | echohl None
  else
    let s:dbs[a:prepend_path][s:cscope_vim_db_entry_key_dirty] = 0
  endif

  call <SID>FlushIndex()
endfunction

function! s:FlushIndex()
  let l:lines = []

  for d in keys(s:dbs)
    call add(l:lines, d.'|'.s:dbs[d][s:cscope_vim_db_entry_key_id].'|'.s:dbs[d][s:cscope_vim_db_entry_key_loadtimes].'|'.s:dbs[d][s:cscope_vim_db_entry_key_dirty].'|'.s:dbs[d][s:cscope_vim_db_entry_key_depedency].'|')
  endfor

  call writefile(l:lines, s:cscope_vim_db_index_file)
endfunction

function! s:GetPrependPath(dir)
  let f = tolower(substitute(a:dir,'\\','/','g'))
  let bestDir = ""

  for d in keys(s:dbs)
    if stridx(f, d) == 0 && len(d) > len(bestDir)
      let bestDir = d
    endif
  endfor

  return bestDir
endfunction

function! s:InitDB(current_path)
  echohl WarningMsg | echo "Can not find a proper cscope db, please input a path to generate one." | echohl None
  let l:prepend_path = tolower(substitute(input("", a:current_path, 'dir'),'\\','/','g'))

  if l:prepend_path != ''
    let prepend_path = <SID>CheckAbsolutePath(l:prepend_path, a:current_path)

    echohl WarningMsg | echo "\nPlease input depedency paths (separated with ';'), if any." | echohl None
    let l:depedency_path = tolower(substitute(input("", "", 'dir'),'\\','/','g'))

    let s:dbs[l:prepend_path] = {}
    let s:dbs[l:prepend_path][s:cscope_vim_db_entry_key_id] = localtime()
    let s:dbs[l:prepend_path][s:cscope_vim_db_entry_key_loadtimes] = 0
    let s:dbs[l:prepend_path][s:cscope_vim_db_entry_key_dirty] = 0
    let s:dbs[l:prepend_path][s:cscope_vim_db_entry_key_depedency] = l:depedency_path

    call <SID>FlushIndex()

    return l:prepend_path
  else
    echohl WarningMsg | echo "Error: path can not be empty." | echohl None
  endif
endfunction

function! s:ListDBs()
  let dirs = keys(s:dbs)

  if len(dirs) == 0
    echo "You have no cscope dbs now."
  else
    let s = [' ID                   LOADTIMES    PATH']

    for d in dirs
      let id = s:dbs[d]['id']

      if cscope_connection(2, s:cscope_vim_db_dir.'/'.id.'.db') == 1
        let l = printf("*%d  %10d            %s", id, s:dbs[d]['loadtimes'], d)
      else
        let l = printf(" %d  %10d            %s", id, s:dbs[d]['loadtimes'], d)
      endif

      call add(s, l)
    endfor

    echo join(s, "\n")
  endif
endfunction

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
      elseif fn !~? g:cscope_interested_files
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

function! s:LoadDB(prepend_path)
  cs kill -1

  if g:cscope_search_case_insensitive == 1
    exe 'cs add '.s:cscope_vim_db_dir.'/'.s:dbs[a:prepend_path][s:cscope_vim_db_entry_key_id].'.db '.a:prepend_path.' -C'
    echo 'cscope db '.s:cscope_vim_db_dir.'/'.s:dbs[a:prepend_path][s:cscope_vim_db_entry_key_id].'.db added.'

    if filereadable(s:cscope_vim_db_dir.'/'.s:dbs[a:prepend_path][s:cscope_vim_db_entry_key_id].'_inc.db')
      exe 'cs add '.s:cscope_vim_db_dir.'/'.s:dbs[a:prepend_path][s:cscope_vim_db_entry_key_id].'_inc.db '.a:prepend_path.' -C'
      echo 'cscope db '.s:cscope_vim_db_dir.'/'.s:dbs[a:prepend_path][s:cscope_vim_db_entry_key_id].'_inc.db added.'
    endif
  else
    exe 'cs add '.s:cscope_vim_db_dir.'/'.s:dbs[a:prepend_path][s:cscope_vim_db_entry_key_id].'.db'
    echo 'cscope db '.s:cscope_vim_db_dir.'/'.s:dbs[a:prepend_path][s:cscope_vim_db_entry_key_id].'.db added.'

    if filereadable(s:cscope_vim_db_dir.'/'.s:dbs[a:prepend_path][s:cscope_vim_db_entry_key_id].'_inc.db')
      exe 'cs add '.s:cscope_vim_db_dir.'/'.s:dbs[a:prepend_path][s:cscope_vim_db_entry_key_id].'_inc.db'
      echo 'cscope db '.s:cscope_vim_db_dir.'/'.s:dbs[a:prepend_path][s:cscope_vim_db_entry_key_id].'_inc.db added.'
    endif
  endif

  let s:dbs[a:prepend_path][s:cscope_vim_db_entry_key_loadtimes] = s:dbs[a:prepend_path][s:cscope_vim_db_entry_key_loadtimes] + 1
  let s:cscope_vim_db_current_prepend_path = a:prepend_path

  call <SID>FlushIndex()
endfunction

function! s:LoadIndex()
  " s:dbs = { 'prepend1': {'id': '',
  "                        'loadtimes': '',
  "                        'dirty': 0|1,
  "                        'depedency': '...;...'},
  "           ...
  "         }
  let s:dbs = {}
  
  if ! isdirectory(s:cscope_vim_db_dir)
    call mkdir(s:cscope_vim_db_dir)
  elseif filereadable(s:cscope_vim_db_index_file)
    let idx = readfile(s:cscope_vim_db_index_file)
   
    for i in idx
      let e = split(i, '|')
    
      if len(e) != s:cscope_vim_db_entry_len
        call <SID>RmDBfiles()
      else
        let l:db_file = s:cscope_vim_db_dir.'/'.e[s:cscope_vim_db_entry_idx_id].'.db'
        let l:db_file_list = s:cscope_vim_db_dir.'/'.e[s:cscope_vim_db_entry_idx_id].'.files'
       
        if filereadable(l:db_file)
          if isdirectory(e[s:cscope_vim_db_entry_idx_prepend_path])
            let s:dbs[e[s:cscope_vim_db_entry_idx_prepend_path]] = {}
            let s:dbs[e[s:cscope_vim_db_entry_idx_prepend_path]][s:cscope_vim_db_entry_key_id] = e[s:cscope_vim_db_entry_idx_id]
            let s:dbs[e[s:cscope_vim_db_entry_idx_prepend_path]][s:cscope_vim_db_entry_key_loadtimes] = e[s:cscope_vim_db_entry_idx_loadtimes]
            let s:dbs[e[s:cscope_vim_db_entry_idx_prepend_path]][s:cscope_vim_db_entry_key_dirty] = e[s:cscope_vim_db_entry_idx_dirty]
            let s:dbs[e[s:cscope_vim_db_entry_idx_prepend_path]][s:cscope_vim_db_entry_key_depedency] = e[s:cscope_vim_db_entry_idx_depedency]
          else
            call delete(l:db_file)
            call delete(l:db_file_list)
          endif
        endif
      endif
    endfor
  else
    call <SID>RmDBfiles()
  endif
endfunction

function! s:RmDBfiles()
  let odbs = split(globpath(s:cscope_vim_db_dir, "*"), "\n")

  for f in odbs
    call delete(f)
  endfor
endfunction

function! s:UpdateDBs(prepend_paths)
  "======================
  " (0010) re-create db(s),
  "======================
  for d in a:prepend_paths
    call <SID>BuildDB(d, 0)
  endfor
endfunction

if !exists('g:cscope_open_location')
  let g:cscope_open_location = 1
endif

if !exists('g:cscope_search_case_insensitive')
  let g:cscope_search_case_insensitive = 0
endif

if !exists('g:cscope_cmd')
  if executable('cscope')
    let g:cscope_cmd = 'cscope'
  else
    echo 'cscope: command not found'
    finish
  endif
endif

if !exists('g:cscope_interested_files')
  let files = readfile(expand("<sfile>:p:h")."/interested.txt")
  let g:cscope_interested_files = join(map(files, 'v:val."$"'), '\|')
endif

set cscopequickfix=s-,g-,d-,c-,t-,e-,f-,i-
com! -nargs=0 CscopeClearAllDB call <SID>ClearDBs(-1)
com! -nargs=0 CscopeClearCurrentDB call <SID>ClearDBs(0)
com! -nargs=0 CscopeList call <SID>ListDBs()
call <SID>LoadIndex()

