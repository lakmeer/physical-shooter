
{ id, log } = require \std

export sprite = (src, size) ->
  blitter = document.create-element \canvas
  blitter.width = blitter.height = size
  ctx = blitter.get-context \2d
  pending-overlay = null
  image = new Image
  image.src = src
  image.onload = ->
    ctx.draw-image image, 0, 0, size, size
    if pending-overlay
      ctx.global-composite-operation = \luminosity
      ctx.draw-image pending-overlay, 0, 0
      ctx.global-composite-operation = \source-over

  blitter.overlay = (sprite) -> pending-overlay := sprite

  return blitter


