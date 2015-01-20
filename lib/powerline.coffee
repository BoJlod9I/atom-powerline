{CompositeDisposable, Disposable} = require 'atom'

PowerlineElement = require './powerline-element'

module.exports = Powerline =
  config:
    socket:
      type: 'string'
      default: "/tmp/powerline-ipc-#{process.getuid()}"
    updateInterval:
      description: 'Time between updates, in seconds'
      type: 'number'
      default: 5
      minimum: 1

  activate: ->
    @powerlines = []

    @subscriptions = new CompositeDisposable
    @subscriptions.add new Disposable => @cancelRefresh()

    @subscriptions.add atom.workspace.addBottomPanel
      item: do =>
        div = document.createElement('div')
        div.classList.add 'powerline-panel'
        div.appendChild @makePowerline('atom', 'left')
        div.appendChild @makePowerline('atom', 'right')
        div

    @subscriptions.add atom.commands.add 'atom-workspace',
      'powerline:refresh': => @refresh()

    @scheduleRefresh()

  deactivate: ->
    @subscriptions.dispose()

  scheduleRefresh: ->
    @cancelRefresh()

    time = atom.config.get('powerline.updateInterval')
    @refreshTimer ?= setInterval(@refresh.bind(this), time * 1000)

  cancelRefresh: ->
    clearInterval @refreshTimer if @refreshTimer?
    @refreshTimer = null

  refresh: ->
    if require('remote').getCurrentWindow().isFocused()
      promise = Promise.resolve()
      for powerline in @powerlines then do (powerline) ->
        promise = promise.then -> powerline.refresh()

  makePowerline: (ext, side) ->
    powerline = new PowerlineElement
    powerline.ext = ext
    powerline.side = side
    @powerlines.push powerline
    powerline
