vim9script

import autoload 'popupmenufilter.vim'

const path_separator = has('win64') ? '\' : '/'

def FormatMenuItem(file_path: string, max_width: number): string
  var depth: number = len(split(file_path, path_separator))
  var top_folder: string = fnamemodify(file_path, repeat(':h', depth - 2))
  var bottom_folder: string = fnamemodify(file_path, ':h:t')
  var filename: string = fnamemodify(file_path, ':t')
  var formatted_path: string = $"{filename} {fnamemodify(file_path, ":p:.:h")}"

  # If everything fits, return formatted value
  if strlen(formatted_path) < max_width
    return formatted_path
  endif

  var i: number = depth
  var temp: string = ''

  # Loop bottom up
  while i >= 3
    var current_folder: string = fnamemodify(file_path, ':h' .. repeat(':h', depth - i) .. ':t')
    var test_path = $"{filename} {top_folder}{path_separator}{current_folder}{temp}"
    if strlen(test_path) <= max_width
      temp = $"{path_separator}{current_folder}{temp}"
    else
      return $"{filename} {top_folder}{path_separator}...{temp}"
    endif
    i -= 1
  endwhile

  return $"{filename} {temp}"
enddef

export def PickFile(qarg: string, qmods: string)
  var fd_cmd = 'fd -tf'
  var buf_list: list<string> = systemlist(fd_cmd)
  var files = mapnew(buf_list, (_, v) => fnamemodify(v, ':p:.'))

  if len(files) <= 1
    return
  endif

  var options: dict<any> = {
    title: 'Files',
    wrap: 0,
    pos: 'center',
    maxwidth: &columns - 10,
    maxheight: &lines - 10,
    mapping: 1,
    fixed: 1,
    cb: (id: number, result: number) => {
      if result < 0
        return
      endif
      var filename = files[result - 1]
      var w: list<number> = win_findbuf(bufnr(filename))
      if empty(w)
        if &modified || &buftype != ''
          execute $"{qmods} split {filename}"
        else
          var edit_cmd: string = 'confirm'
          if qmods != ''
            edit_cmd ..= $" {qmods} split"
          else
            edit_cmd ..= " edit"
          endif
          execute $"{edit_cmd} {filename}"
        endif
      else
        win_gotoid(w[0])
      endif
      },
  }

  var formatted_filenames = mapnew(files, (_, v) => FormatMenuItem(v, &columns - 14))
  popupmenufilter.PopupMenuFilter(formatted_filenames, options)
enddef

