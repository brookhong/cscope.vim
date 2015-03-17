# Example settings
    nnoremap <leader>fa :call CscopeFindInteractive(expand('<cword>'))<CR>

    " s: Find this C symbol
    nnoremap  <leader>fs :call CscopeFind('s', expand('<cword>'))<CR>
    " g: Find this definition
    nnoremap  <leader>fg :call CscopeFind('g', expand('<cword>'))<CR>
    " d: Find functions called by this function
    nnoremap  <leader>fd :call CscopeFind('d', expand('<cword>'))<CR>
    " c: Find functions calling this function
    nnoremap  <leader>fc :call CscopeFind('c', expand('<cword>'))<CR>
    " t: Find this text string
    nnoremap  <leader>ft :call CscopeFind('t', expand('<cword>'))<CR>
    " e: Find this egrep pattern
    nnoremap  <leader>fe :call CscopeFind('e', expand('<cword>'))<CR>
    " f: Find this file
    nnoremap  <leader>ff :call CscopeFind('f', expand('<cword>'))<CR>
    " i: Find files #including this file
    nnoremap  <leader>fi :call CscopeFind('i', expand('<cword>'))<CR>
    nnoremap  <leader>l :call ToggleLocationList()<CR>
