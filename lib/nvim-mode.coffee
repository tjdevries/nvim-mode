'use babel';

import NvimModeView from './nvim-mode-view';
import { CompositeDisposable } from 'atom';

export default {

  nvimModeView: null,
  modalPanel: null,
  subscriptions: null,

  activate(state) {
    this.nvimModeView = new NvimModeView(state.nvimModeViewState);
    this.modalPanel = atom.workspace.addModalPanel({
      item: this.nvimModeView.getElement(),
      visible: false
    });

    // Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    this.subscriptions = new CompositeDisposable();

    // Register command that toggles this view
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'nvim-mode:toggle': () => this.toggle()
    }));
  },

  deactivate() {
    this.modalPanel.destroy();
    this.subscriptions.dispose();
    this.nvimModeView.destroy();
  },

  serialize() {
    return {
      nvimModeViewState: this.nvimModeView.serialize()
    };
  },

  toggle() {
    console.log('NvimMode was toggled!');
    return (
      this.modalPanel.isVisible() ?
      this.modalPanel.hide() :
      this.modalPanel.show()
    );
  }

};
