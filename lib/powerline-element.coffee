'use strict'

net = require 'net'

module.exports =
PowerlineElement = document.registerElement 'power-line', class extends HTMLElement
  copyStyle = (element, attr, prop) ->
    if element.hasAttribute(attr)
      element.style[prop] = element.getAttribute(attr)
      element.removeAttribute attr

  attr = (name) ->
    get: -> @getAttribute name
    set: (value) -> @setAttribute name, value

  Object.defineProperties @prototype,
    ext: attr('ext')
    side: attr('side')

  createdCallback: ->
    @createShadowRoot()
    @classList.add 'inline-block'

  attachedCallback: ->
    @refresh()

  refresh: ->
    unless @side in ['left', 'right']
      console.warn "skipping refresh for powerline with side=#{@side}"
      return

    unless @ext
      console.warn "skipping refresh for powerline with no ext attribute"
      return

    path = atom.config.get('powerline.socket')
    args = ['-r', 'powerline.renderers.pango_markup', @ext, @side]
    buffers = []

    socket = net.createConnection path
    socket.on 'connect', ->
      env = ''
      socket.write [
        args.length.toString(16)
        args...
        atom.project.getPath()
      ].join('\0')
      socket.end '\0\0'

    socket.on 'data', (data) ->
      buffers.push data

    socket.on 'error', (error) ->
      console.warn "#{error} (Powerline socket at #{path})"

    socket.on 'end', (bad) =>
      return if bad

      @shadowRoot.innerHTML = Buffer.concat(buffers).toString('utf-8')
      for element in @shadowRoot.children
        copyStyle element, 'foreground', 'color'
        copyStyle element, 'background', 'background-color'
        copyStyle element, 'font_weight', 'font-weight'
