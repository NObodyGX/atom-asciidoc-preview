const fs = require('fs-plus')
const { CompositeDisposable } = require('atom')

let AsciidocPreviewView = null
let renderer = null

const isAsciidocPreviewView = function (object) {
  if (AsciidocPreviewView == null) {
    AsciidocPreviewView = require('./preview-view')
  }
  return object instanceof AsciidocPreviewView
}

module.exports = {
  activate () {
    this.disposables = new CompositeDisposable()
    this.commandSubscriptions = new CompositeDisposable()

    console.warn(`GX enter activate`)
    this.disposables.add(atom.commands.add('atom-workspace', {
      'asciidoc-preview:toggle': () => this.toggle(),
      'asciidoc-preview:save-as-pdf': {
        displayName: 'Asciidoc Preview: Save as PDF',
        didDispatch: () => this.saveAsPDF()
      }
    }));

    const previewFile = this.previewFile.bind(this)
    for (const extension of [
      'asciidoc',
      'adoc'
    ]) {
      this.disposables.add(
        atom.commands.add(
          `.tree-view .file .name[data-name$=\\.${extension}]`,
          'asciidoc-preview:preview-file',
          previewFile
        )
      )
    }

    this.disposables.add(
      atom.workspace.addOpener(uriToOpen => {
        let [protocol, path] = uriToOpen.split('://')
        if (protocol !== 'asciidoc-preview') {
          return
        }

        try {
          path = decodeURI(path)
        } catch (error) {
          return
        }

        if (path.startsWith('editor/')) {
          return this.createAsciidocPreviewView({ editorId: path.substring(7) })
        } else {
          return this.createAsciidocPreviewView({ filePath: path })
        }
      })
    )
  },

  deactivate () {
    this.disposables.dispose()
    this.commandSubscriptions.dispose()
  },

  createAsciidocPreviewView (state) {
    if (state.editorId || fs.isFileSync(state.filePath)) {
      if (AsciidocPreviewView == null) {
        AsciidocPreviewView = require('./preview-view')
      }
      return new AsciidocPreviewView(state)
    }
  },

  toggle () {
    if (isAsciidocPreviewView(atom.workspace.getActivePaneItem())) {
      atom.workspace.destroyActivePaneItem()
      return
    }

    const editor = atom.workspace.getActiveTextEditor()
    if (editor == null) {
      return
    }

    if (!this.removePreviewForEditor(editor)) {
      return this.addPreviewForEditor(editor)
    }
  },

  uriForEditor (editor) {
    return `asciidoc-preview://editor/${editor.id}`
  },

  removePreviewForEditor (editor) {
    const uri = this.uriForEditor(editor)
    const previewPane = atom.workspace.paneForURI(uri)
    if (previewPane != null) {
      previewPane.destroyItem(previewPane.itemForURI(uri))
      return true
    } else {
      return false
    }
  },

  addPreviewForEditor (editor) {
    const uri = this.uriForEditor(editor)
    const previousActivePane = atom.workspace.getActivePane()
    const options = { searchAllPanes: true, split : 'right' }

    return atom.workspace
      .open(uri, options)
      .then(function (asciidocPreviewView) {
        if (isAsciidocPreviewView(asciidocPreviewView)) {
          previousActivePane.activate()
        }
      })
  },

  previewFile ({ target }) {
    const filePath = target.dataset.path
    if (!filePath) {
      return
    }

    for (const editor of atom.workspace.getTextEditors()) {
      if (editor.getPath() === filePath) {
        return this.addPreviewForEditor(editor)
      }
    }

    atom.workspace.open(`asciidoc-preview://${encodeURI(filePath)}`, {
      searchAllPanes: true
    })
  },

  async copyHTML () {
    const editor = atom.workspace.getActiveTextEditor()
    if (editor == null) {
      return
    }

    if (renderer == null) {
      renderer = require('./renderer')
    }
    const text = editor.getSelectedText() || editor.getText()
    const html = await renderer.toHTML(
      text,
      editor.getPath(),
      editor.getGrammar()
    )

    atom.clipboard.write(html)
  },

  saveAsPDF () {
    const activePaneItem = atom.workspace.getActivePaneItem()
    if (isAsciidocPreviewView(activePaneItem)) {
      atom.workspace.getActivePane().saveItemAs(activePaneItem)
      return
    }

    const editor = atom.workspace.getActiveTextEditor()
    if (editor == null) {
      return
    }

    const grammars = atom.config.get('asciidoc-preview.grammars') || []
    if (!grammars.includes(editor.getGrammar().scopeName)) {
      return
    }

    const uri = this.uriForEditor(editor)
    const asciidocPreviewPane = atom.workspace.paneForURI(uri)
    const asciidocPreviewPaneItem =
      asciidocPreviewPane != null
        ? asciidocPreviewPane.itemForURI(uri)
        : undefined

    if (isAsciidocPreviewView(asciidocPreviewPaneItem)) {
      return asciidocPreviewPane.saveItemAs(asciidocPreviewPaneItem)
    }
  }
}