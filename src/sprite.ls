
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

luminosity-overlay = (ctx, width, height) -> (image) ->
  ctx.global-composite-operation = \luminosity
  ctx.draw-image image, 0, 0, width, height
  ctx.global-composite-operation = \source-over


#
# Empty Sprite
#

empty-sprite = (width, height) ->
  blitter = document.create-element \canvas
  blitter.width = width
  blitter.height = height
  blitter.ctx = blitter.get-context \2d
  blitter.draw = -> blitter.ctx.draw-image it, 0, 0, width, height
  blitter.luminosity = luminosity-overlay blitter.ctx, width, height
  return blitter


#
# Simple Sprite
#

export sprite = (src, width, height = width) ->
  blitter = empty-sprite width, height
  image-loader src, blitter~draw
  return blitter


#
# Palette-controller luminosity-mapped sprite
#

export palette-sprite = (color-src, lumin-src, palette, size) ->
  state =
    color-loaded: no
    lumin-loaded: no

  output  = empty-sprite size, size
  diffuse = empty-sprite size, size
  overlay = empty-sprite size, size

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

  output.greyscale = -> output.draw overlay

  return output

