" vim: tabstop=2 shiftwidth=2 softtabstop=2 expandtab foldmethod=marker
"    Copyright: Copyright (C) 2012-2015 Brook Hong
"    License: The MIT License
"

if !exists('g:cscope_silent')
  let g:cscope_silent = 0
endif

if !exists('g:cscope_auto_update')
  let g:cscope_auto_update = 1
endif

if !exists('g:cscope_open_location')
  let g:cscope_open_location = 1
endif

if !exists('g:cscope_cmd')
  if executable('cscope')
    let g:cscope_cmd = 'cscope'
  else
    call cscope#echo('cscope: command not found')
    finish
  endif
endif

if !exists('g:cscope_ignore_files')
  let g:cscope_ignore_files = '\.3dm$\|\.3g2$\|\.3gp$\|\.7z$\|\.a$\|\.a.out$\|\.accdb$\|\.ai$\|\.aif$\|\.aiff$\|\.app$\|\.arj$\|\.asf$\|\.asx$\|\.au$\|\.avi$\|\.bak$\|\.bin$\|\.bmp$\|\.bz2$\|\.cab$\|\.cer$\|\.cfm$\|\.cgi$\|\.com$\|\.cpl$\|\.csr$\|\.csv$\|\.cue$\|\.cur$\|\.dat$\|\.db$\|\.dbf$\|\.dbx$\|\.dds$\|\.deb$\|\.dem$\|\.dll$\|\.dmg$\|\.dmp$\|\.dng$\|\.doc$\|\.docx$\|\.drv$\|\.dwg$\|\.dxf$\|\.ear$\|\.efx$\|\.eps$\|\.epub$\|\.exe$\|\.fla$\|\.flv$\|\.fnt$\|\.fon$\|\.gadget$\|\.gam$\|\.gbr$\|\.ged$\|\.gif$\|\.gpx$\|\.gz$\|\.hqx$\|\.ibooks$\|\.icns$\|\.ico$\|\.ics$\|\.iff$\|\.img$\|\.indd$\|\.iso$\|\.jar$\|\.jpeg$\|\.jpg$\|\.key$\|\.keychain$\|\.kml$\|\.lnk$\|\.lz$\|\.m3u$\|\.m4a$\|\.max$\|\.mdb$\|\.mid$\|\.mim$\|\.moov$\|\.mov$\|\.movie$\|\.mp2$\|\.mp3$\|\.mp4$\|\.mpa$\|\.mpeg$\|\.mpg$\|\.msg$\|\.msi$\|\.nes$\|\.o$\|\.obj$\|\.ocx$\|\.odt$\|\.otf$\|\.pages$\|\.part$\|\.pct$\|\.pdb$\|\.pdf$\|\.pif$\|\.pkg$\|\.plugin$\|\.png$\|\.pps$\|\.ppt$\|\.pptx$\|\.prf$\|\.ps$\|\.psd$\|\.pspimage$\|\.qt$\|\.ra$\|\.rar$\|\.rm$\|\.rom$\|\.rpm$\|\.rtf$\|\.sav$\|\.scr$\|\.sdf$\|\.sea$\|\.sit$\|\.sitx$\|\.sln$\|\.smi$\|\.so$\|\.svg$\|\.swf$\|\.swp$\|\.sys$\|\.tar$\|\.tar.gz$\|\.tax2010$\|\.tga$\|\.thm$\|\.tif$\|\.tiff$\|\.tlb$\|\.tmp$\|\.toast$\|\.torrent$\|\.ttc$\|\.ttf$\|\.uu$\|\.uue$\|\.vb$\|\.vcd$\|\.vcf$\|\.vcxproj$\|\.vob$\|\.war$\|\.wav$\|\.wma$\|\.wmv$\|\.wpd$\|\.wps$\|\.xll$\|\.xlr$\|\.xls$\|\.xlsx$\|\.xpi$\|\.yuv$\|\.Z$\|\.zip$\|\.zipx$\|\.lib$\|\.res$\|\.rc$\|\.out$\|\.cache$\|\.tgz$\|\.gho$\|\.ghs$'
endif

if exists('g:cscope_ignore_strict') && g:cscope_ignore_strict == 1
  let g:cscope_ignore_files = g:cscope_ignore_files.'\|\.xml$\|\.yml$\|\.ini$\|\.conf$\|\.css$\|\.htc$\|\.bat$\|\.sh$\|\.txt$\|\.log$\|\.dtd$\|\.xsd$'
endif

if exists('g:cscope_preload_path')
  call cscope#preloadDB()
endif

if g:cscope_auto_update == 1
  au BufWritePost * call cscope#onChange()
endif

set cscopequickfix=s-,g-,d-,c-,t-,e-,f-,i-
com! -nargs=0 CscopeClear call cscope#clearDBs()
com! -nargs=0 CscopeList call cscope#listDBs()
call cscope#loadIndex()
