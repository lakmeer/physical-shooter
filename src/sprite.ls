
{ id, log } = require \std

#
# Helpers
#

image-loader = (src, λ) ->
  image = new Image
  image.onload = -> λ image
  image.src = src

hydrate-svg = (markup) ->
  div = document.createElement("div")
  div.innerHTML = markup
  return div.children.0

svg-loader = (src, λ) ->
  ajax = new XMLHttpRequest
  ajax.open \GET, src, true
  ajax.onload = -> λ hydrate-svg ajax.response-text
  ajax.send!

svg-apply-palette = (svg, colors) ->
  for selector, i in <[ primary secondary tertiary ]>
    for node in svg.get-elements-by-class-name selector
      node.set-attribute \fill, colors[i]

render-svg = (svg, λ) ->
  svg-blob = new Blob [svg.parentNode.innerHTML], type: 'image/svg+xml;charset=utf-8'
  url = URL.createObjectURL svg-blob
  img = new Image
  img.onload = -> URL.revokeObjectURL url; λ img
  img.src = url

luminosity-overlay = (ctx, size) -> (image) ->
  ctx.global-composite-operation = \luminosity
  ctx.draw-image image, 0, 0, size, size
  ctx.global-composite-operation = \source-over


#
# Empty Sprite
#

empty-sprite = (size) ->
  blitter = document.create-element \canvas
  blitter.width = blitter.height = size
  blitter.ctx = blitter.get-context \2d
  blitter.draw = -> blitter.ctx.draw-image it, 0, 0, size, size
  blitter.luminosity = luminosity-overlay blitter.ctx, size
  return blitter


#
# Simple Sprite
#

export sprite = (src, size) ->
  blitter = empty-sprite size
  image-loader src, (img) -> blitter.draw img
  return blitter


#
# Palette-controller luminosity-mapped sprite
#

export palette-sprite = (color-src, lumin-src, palette, size) ->
  state =
    color-loaded: no
    lumin-loaded: no

  diffuse = empty-sprite size
  overlay = empty-sprite size

  svg-loader color-src, (svg) ->
    svg-apply-palette svg, palette
    render-svg svg, (color) ->
      diffuse.draw color
      state.color-loaded = true
      if state.lumin-loaded
        combine!

  image-loader lumin-src, (lumin) ->
    overlay.draw lumin
    state.lumin-loaded = true
    if state.color-loaded
      combine!

  combine = ->
    output.draw diffuse
    output.luminosity overlay

  output = empty-sprite size

