# import NvimModeView from './nvim-mode-view';

{Disposable, CompositeDisposable} = require 'event-kit'
NvimState = require './nvim-state'

module.exports =

  activate: ->
    console.log atom.workspace.getTextEditors()

    @disposables = new CompositeDisposable

    # editor = atom.workspace.getActiveTextEditor()
    @disposables.add atom.workspace.observeTextEditors (editor) ->

      console.log 'uri:',editor.getURI()
      editorView = atom.views.getView(editor)

      if editorView
        console.log 'view:',editorView
        editorView.classList.add('nvim-mode')
        editorView.nvimState = new NvimState(editorView)

  deactivate: ->

    atom.workspaceView?.eachEditorView (editorView) ->
      editorView.off('.nvim-mode')

      @disposables.dispose()
