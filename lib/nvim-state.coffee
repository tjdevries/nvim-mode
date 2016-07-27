os = require 'os'

NvimGlobals = require './nvim-globals.coffee'

if os.platform() is 'win32'
  CONNECT_TO = '\\\\.\\pipe\\neovim'
else
  CONNECT_TO = '/tmp/neovim/neovim'


element = document.createElement("item-view")
editor_views = {}

nvim_send_message = (message,f = undefined) ->
  try
    if message[0] and message[1]
      NvimGlobals.session.require(message[0], message[1], (err, res) ->
        if f
          if typeof(res) is 'number'
            f(util.inspect(res))
          else
            f(res)
      )
  catch
    console.log 'error in nvim_send_message '+err
    console.log 'm1:',message[0]
    console.log 'm2:',message[1]


nvim_mode_save_file = () ->
  console.log 'inside neovim save file'

  NvimGlobals.current_editor = atom.workspace.getActiveTextEditor()
  neovim_send_message(['vim_command',['write!']])
  setTimeout( ( ->
    NvimGlobals.current_editor.buffer.reload()
    NvimGlobals.internal_change = false
    NvimGlobals.updating = false
  ), 500)

  #NvimGlobals.current_editor.setText(a)

module.exports = class NvimState
  editor: null

  constructor: (@editorView) ->
    @editor = @editorView.getModel()
    editor_views[@editor.getURI()] = @editorView
    @editorView.component.setInputEnabled(false)
    mode = 'command'
    @cursor_visible = true
    @scrolled_down = false
    NvimGlobals.tlnumber = 0
    @status_bar = []
    @location = []


    if not NvimGlobals.current_editor
      NvimGlobals.current_editor = @editor
    @changeModeClass('command-mode')
    @activateCommandMode()

    atom.packages.onDidActivatePackage(  ->
      element.innerHTML = ''
      @statusbar =
        document.querySelector('status-bar').addLeftTile(item:element,
          priority:10 )
    )

    if not buffer_change_subscription
      buffer_change_subscription =
        atom.workspace.onDidChangeActivePaneItem activePaneChanged
    if not buffer_destroy_subscription
      buffer_destroy_subscription =
        atom.workspace.onDidDestroyPaneItem destroyPaneItem

    atom.commands.add 'atom-text-editor', 'core:save', (e) ->
      NvimGlobals.internal_change = true
      NvimGlobals.updating = true
      e.preventDefault()
      e.stopPropagation()
      vim_mode_save_file()


    @editorView.onkeypress = (e) =>
      deactivate_timer()
      q1 = @editorView.classList.contains('is-focused')
      q2 = @editorView.classList.contains('autocomplete-active')
      q3 = NvimGlobals.current_editor.getSelectedBufferRange().isEmpty()
      if q1 and not q2 and q3
        @editorView.component.setInputEnabled(false)
        q =  String.fromCharCode(e.which)
        neovim_send_message(['vim_input',[q]])
        activate_timer()
        false
      else if q1 and not q2 and not q3
        @editorView.component.setInputEnabled(true)
        activate_timer()
        true
      else
        NvimGlobals.internal_change = false
        NvimGlobals.updating = false
        q =  String.fromCharCode(e.which)
        neovim_send_message(['vim_input',[q]])
        activate_timer()
        true

    @editorView.onkeydown = (e) =>
      deactivate_timer()
      q1 = @editorView.classList.contains('is-focused')
      q2 = @editorView.classList.contains('autocomplete-active')
      q3 = NvimGlobals.current_editor.getSelectedBufferRange().isEmpty()
      if q1 and not q2 and not e.altKey and q3
        @editorView.component.setInputEnabled(false)
        translation = @translateCode(e.which, e.shiftKey, e.ctrlKey)
        if translation != ""
          neovim_send_message(['vim_input',[translation]])
          activate_timer()
          false
      else if q1 and not q2 and not q3
        @editorView.component.setInputEnabled(true)
        activate_timer()
        true
      else
        NvimGlobals.internal_change = false
        NvimGlobals.updating = false
        activate_timer()
        true



  translateCode: (code, shift, control) ->
#console.log 'code:',code
    if control && code>=65 && code<=90
      String.fromCharCode(code-64)
    else if code>=8 && code<=10 || code==13 || code==27
      String.fromCharCode(code)
    else if code==35
      '<End>'
    else if code==36
      '<Home>'
    else if code==33
      '<PageUp>'
    else if code==34
      '<PageDown>'
    else if code==37
      '<left>'
    else if code==38
      '<up>'
    else if code==39
      '<right>'
    else if code==40
      '<down>'
    else if code==188 and shift
      '<lt>'
    else
      ""

  destroy_sockets:(editor) =>
    if subscriptions['redraw']
      if editor.getURI() != @editor.getURI()
#subscriptions['redraw'] = false
        console.log 'unsubscribing'

  afterOpen: =>
#console.log 'in after open'
    neovim_send_message(['vim_command',['set scrolloff=2']])
    neovim_send_message(['vim_command',['set nocompatible']])
    neovim_send_message(['vim_command',['set noswapfile']])
    neovim_send_message(['vim_command',['set nowrap']])
    neovim_send_message(['vim_command',['set numberwidth=8']])
    neovim_send_message(['vim_command',['set nu']])
    neovim_send_message(['vim_command',['set autochdir']])
    neovim_send_message(['vim_command',['set autoindent']])
    neovim_send_message(['vim_command',['set smartindent']])
    neovim_send_message(['vim_command',['set hlsearch']])
    neovim_send_message(['vim_command',['set tabstop=4']])
    neovim_send_message(['vim_command',['set encoding=utf-8']])
    neovim_send_message(['vim_command',['set shiftwidth=4']])
    neovim_send_message(['vim_command',['set shortmess+=I']])
    neovim_send_message(['vim_command',['set expandtab']])
    neovim_send_message(['vim_command',['set hidden']])
    neovim_send_message(['vim_command',['set listchars=eol:$']])
    neovim_send_message(['vim_command',['set list']])
    neovim_send_message(['vim_command',['set wildmenu']])
    neovim_send_message(['vim_command',['set showcmd']])
    neovim_send_message(['vim_command',['set incsearch']])
    neovim_send_message(['vim_command',['set autoread']])
    neovim_send_message(['vim_command',['set laststatus=2']])
    neovim_send_message(['vim_command',['set rulerformat=%L']])
    neovim_send_message(['vim_command',['set ruler']])
    #neovim_send_message(['vim_command',['set visualbell']])


    neovim_send_message(['vim_command',
      ['set backspace=indent,eol,start']])

    neovim_send_message(['vim_input',['<Esc>']])
    @activateCommandMode()

    if not subscriptions['redraw']
#console.log 'subscribing, after open'
      @neovim_subscribe()
#else
#console.log 'NOT SUBSCRIBING, problem'
#

#last_text = NvimGlobals.current_editor.getText()

  postprocess: (rows, dirty) ->
    screen_f = []
    for posi in [0..rows-1]
      line = undefined
      if screen[posi] and dirty[posi]
        line = []
        for posj in [0..COLS-8]
          if screen[posi][posj]=='$' and \
             screen[posi][posj+1]==' ' and \
             screen[posi][posj+2]==' '
            break
          line.push screen[posi][posj]
      else
        if screen[posi]
          line = screen[posi]
      screen_f.push line

  redraw_screen:(rows, dirty) =>

    NvimGlobals.current_editor = atom.workspace.getActiveTextEditor()
    if NvimGlobals.current_editor

      if DEBUG
        initial = 0
      else
        initial = 8

      sbr = NvimGlobals.current_editor.getSelectedBufferRange()
      @postprocess(rows, dirty)
      tlnumberarr = []
      for posi in [0..rows-3]
        try
          pos = parseInt(screen_f[posi][0..8].join(''))
          #if not isNaN(pos)
          tlnumberarr.push (  (pos - 1) - posi  )
#else
#    tlnumberarr.push -1
        catch err
          tlnumberarr.push -9999

      NvimGlobals.tlnumber = NaN
      array = []
      for i in [0..rows-3]
        if not isNaN(tlnumberarr[i]) and tlnumberarr[i] >= 0
          array.push(tlnumberarr[i])
      #console.log array

      NvimGlobals.tlnumber = getMaxOccurrence(array)
      #console.log 'TLNUMBERarr********************',tlnumberarr
      #console.log 'TLNUMBER********************',NvimGlobals.tlnumber

      if dirty

        options =  { normalizeLineEndings: false, undo: 'skip' }
        for posi in [0..rows-3]
          if not isNaN(NvimGlobals.tlnumber) and \
             (NvimGlobals.tlnumber isnt -9999)
            if (tlnumberarr[posi] + posi == NvimGlobals.tlnumber + posi) and \
               dirty[posi]
              qq = screen_f[posi]
              qq = qq[initial..].join('')
              linerange = new Range(new Point(NvimGlobals.tlnumber+posi,0),
                new Point(NvimGlobals.tlnumber + posi,
                  COLS-initial))

              txt = NvimGlobals.current_editor.buffer.getTextInRange(linerange)
              if qq isnt txt
                console.log 'qq:',qq
                console.log 'txt:',txt
                NvimGlobals.current_editor.buffer.setTextInRange(linerange,
                  qq, options)
              dirty[posi] = false

      sbt = @status_bar.join('')
      @updateStatusBarWithText(sbt, (rows - 1 == @location[0]), @location[1])

      q = screen[rows-2]
      text = q[q.length/2..q.length-1].join('')
      text = text.split(' ').join('')
      num_lines = parseInt(text, 10)

      if NvimGlobals.current_editor.buffer.getLastRow() < num_lines
        nl = num_lines - NvimGlobals.current_editor.buffer.getLastRow()
        diff = ''
        for i in [0..nl-2]
          diff = diff + '\n'
        append_options = {normalizeLineEndings: false}
        NvimGlobals.current_editor.buffer.append(diff, append_options)

      else if NvimGlobals.current_editor.buffer.getLastRow() > num_lines
        for i in [num_lines..\
        NvimGlobals.current_editor.buffer.getLastRow()-1]
          NvimGlobals.current_editor.buffer.deleteRow(i)


      if not isNaN(NvimGlobals.tlnumber) and (NvimGlobals.tlnumber isnt -9999)

        if @cursor_visible and @location[0] <= rows - 2
          if not DEBUG
            NvimGlobals.current_editor.setCursorBufferPosition(
              new Point(NvimGlobals.tlnumber + @location[0],
                @location[1]-initial),{autoscroll:false})
          else
            NvimGlobals.current_editor.setCursorBufferPosition(
              new Point(NvimGlobals.tlnumber + @location[0],
                @location[1]),{autoscroll:false})

        if NvimGlobals.current_editor
          NvimGlobals.current_editor.setScrollTop(lineSpacing()*\
              NvimGlobals.tlnumber)

      #console.log 'sbr:',sbr
      if not sbr.isEmpty()
        NvimGlobals.current_editor.setSelectedBufferRange(sbr,
          {reversed:reversed_selection})

  neovim_unsubscribe: ->
    message = ['ui_detach',[]]
    neovim_send_message(message)
    subscriptions['redraw'] = false

  neovim_resize:(cols, rows) =>

    NvimGlobals.internal_change = true
    NvimGlobals.updating = true
    qtop = 10
    qbottom =0
    @rows = 0

    qtop = NvimGlobals.current_editor.getScrollTop()
    qbottom = NvimGlobals.current_editor.getScrollBottom()

    qleft = NvimGlobals.current_editor.getScrollLeft()
    qright= NvimGlobals.current_editor.getScrollRight()

    @cols = Math.floor((qright-qleft)/lineSpacingHorizontal())-1

    COLS = @cols
    @rows = Math.floor((qbottom - qtop)/lineSpacing()+1)

    eventHandler.cols = @cols
    eventHandler.rows= @rows+2
    message = ['ui_try_resize',[@cols,@rows+2]]
    neovim_send_message(message)

    screen = ((' ' for ux in [1..@cols])  for uy in [1..@rows+2])
    @location = [0,0]
    neovim_send_message(['vim_command',['redraw!']],
      (() ->
        NvimGlobals.internal_change = false
      )
    )
    NvimGlobals.internal_change = false
    NvimGlobals.updating = false


  neovim_subscribe: =>
#console.log 'neovim_subscribe'

    eventHandler = new EventHandler this

    message = ['ui_attach',[eventHandler.cols,eventHandler.rows,true]]
    neovim_send_message(message)

    NvimGlobals.session.on('notification', eventHandler.handleEvent)
    #rows = @editor.getScreenLineCount()
    @location = [0,0]
    @status_bar = (' ' for ux in [1..eventHandler.cols])

    subscriptions['redraw'] = true

#Used to enable command mode.
  activateCommandMode: ->
    mode = 'command'
    @changeModeClass('command-mode')
    @updateStatusBar()

#Used to enable insert mode.
  activateInsertMode: (transactionStarted = false)->
    mode = 'insert'
    @changeModeClass('insert-mode')
    @updateStatusBar()

  activateReplaceMode: ()->
    mode = 'replace'
    @changeModeClass('command-mode')

  activateInvisibleMode: (transactionStarted = false)->
    mode = 'insert'
    @changeModeClass('invisible-mode')
    @updateStatusBar()

  changeModeClass: (targetMode) ->
    if NvimGlobals.current_editor
      editorview = editor_views[NvimGlobals.current_editor.getURI()]
      if editorview
        for qmode in ['command-mode',
                      'insert-mode',
                      'visual-mode',
                      'operator-pending-mode',
                      'invisible-mode']
          if qmode is targetMode
            editorview.classList.add(qmode)
          else
            editorview.classList.remove(qmode)

  updateStatusBarWithText:(text, addcursor, loc) ->
    if addcursor
      text = text[0..loc-1].concat('&#9632').concat(text[loc+1..])
    text = text.split(' ').join('&nbsp;')
    q = '<samp>'
    qend = '</samp>'
    element.innerHTML = q.concat(text).concat(qend)

  updateStatusBar: ->
    mode = 'wut face'
    element.innerHTML = mode
