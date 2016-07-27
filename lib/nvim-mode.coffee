
{Disposable, CompositeDisposable} = require 'event-kit'

module.exports =
  subscriptions: null

  activate: ->
    console.log 'inside of nvim-mode'
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'nvim-mode:toggle': => @toggle()
    # @subscriptions = new CompositeDisposable
    # @subscriptions.add atom.workspace.observeTextEditors (editor) ->
    #   console.log 'uri:',editor.getURI()
    #   editorView = atom.views.getView(editor)
    #
    #   if editorView
    #     console.log 'view:',editorView
    #     editorView.classList.add('nvim-mode')
    #     # editorView.nvimState = new NvimState(editorView)

  deactivate: ->
    console.log 'outside of nvim-mode'
    @subscriptions.dispose()
    # atom.workspaceView?.eachEditorView (editorView) ->
    #   editorView.off('.nvim-mode')
    #
    #   @subscriptions.dispose()

  toggle: ->
    console.log 'toggling'

    t = atom.workspace.getActiveTextEditor()
    atom.workspace.addBottomPanel({'item':t})


    # NvimElement = require './nvim-view'
    #
    # @subscriptions.add atom.views.addViewProvider(TextEditor, (textEditor)) ->
    #   new NvimElement.initialize()
