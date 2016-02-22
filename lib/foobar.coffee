FoobarView = require './foobar-view'
{CompositeDisposable} = require 'atom'

module.exports = Foobar =
  foobarView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @foobarView = new FoobarView(state.foobarViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @foobarView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'foobar:toggle':  => @toggle()
      'foobar:tigress': => @tigress()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @foobarView.destroy()

  serialize: ->
    foobarViewState: @foobarView.serialize()

  tigress: ->
    console.log 'purr...'

  toggle: ->
    atom.workspace.observeTextEditors (editor) ->
      editor.onDidSave ->
        buffer = editor.getBuffer()
        require('atom-space-pen-views').$.ajax {
          method:      'POST'
          url:         'https://api.github.com/markdown/raw'
          contentType: 'text/plain'
          data:        buffer.cachedText
          success: (html) ->
            path = buffer.file.path
            dot  = path.lastIndexOf('.')
            ext  = path.substr(dot + 1) if dot != -1
            if 'md' == ext
              filename = new String(path).substr(path.lastIndexOf('/') + 1)
              Foobar.push filename, html
        }
        return false

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()

  push: (key, body) ->
    AWS = require('aws-sdk')
    AWS.config.update
      accessKeyId: 'foo'
      secretAccessKey: 'bar'
    s3 = new AWS.S3 params: Bucket: 'deraps'
    s3.headObject Key: key, (err, data) ->
      if data? and !err?
        params =
          Key:  key
          Body: body
        s3.upload params, (err, data) ->
          if data? and !err?
            console.log "Successfully uploaded data to deraps/" + key
          else
            console.log "Error uploading data: ", err
