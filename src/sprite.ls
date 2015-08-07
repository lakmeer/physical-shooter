
export sprite = (src, size) ->
  blitter = document.create-element \canvas
  blitter.width = blitter.height = size
  ctx = blitter.get-context \2d
  image = new Image
  image.src = src
  image.onload = -> ctx.draw-image image, 0, 0, size, size
  return blitter


