import autoload 'popupmenufilter/pickfile.vim'

command! -nargs=* -complete=dir PickFile call pickfile.PickFile(<q-args>, <q-mods>)
