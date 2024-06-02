function ugaterm#open(opts) abort
  let opts = {}
  let opts.new = get(a:opts, 'new', v:false)
  let opts.toggle = get(a:opts, 'toggle', v:false)
  let opts.select = get(a:opts, 'select', v:false)
  let opts.keep_cursor = get(a:opts, 'keep_cursor', v:false)
  let name = get(a:opts, 'name', '')
  let cmd = get(a:opts, 'cmd', '')

  call luaeval('require("ugaterm.terminal"):open(_A.opts, _A.name, _A.cmd)',
        \ #{opts: opts, name: name, cmd: cmd})
endfunction

function ugaterm#hide(opts) abort
  let opts = {}
  let opts.delete = get(a:opts, 'delete', v:false)

  call luaeval('require("ugaterm.terminal"):hide(_A)', opts)
endfunction

function ugaterm#send(opts) abort
  let opts = {}
  let opts.name = get(a:opts, 'name', '')
  let opts.cmd = get(a:opts, 'cmd', '')

  if opts.cmd ==# ''
    call ugaterm#util#error('No command')
  else
    call luaeval('require("ugaterm.terminal"):send(_A.cmd, _A.name)', opts)
  endif
endfunction

function ugaterm#rename(opts) abort
  let opts = {}
  let opts.target = get(a:opts, 'target', '')
  let opts.newname = get(a:opts, 'newname', '')

  call luaeval('require("ugaterm.terminal"):send(_A.newname, _A.target)', opts)
endfunction
