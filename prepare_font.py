#!/usr/bin/env python

import sys
import fontforge

def copyGlyph(font, glyph, suffix, foreground):
  newGlyph = font.createChar(-1, "{}.{}".format(glyph.glyphname, suffix))
  newGlyph.anchorPoints = glyph.anchorPoints
  newGlyph.color = glyph.color
  newGlyph.glyphclass = glyph.glyphclass
  newGlyph.width = glyph.width
  newGlyph.vwidth = glyph.vwidth
  newGlyph.foreground = foreground
  return newGlyph

fn = sys.argv[1]
nfn = sys.argv[1] + '.colr.ttf'

f = fontforge.open(fn)
layers = []
for l in f.layers:
  if not f.layers[l].is_background:
    layers.append(l)
fg_layer_name = f.layers[1].name

f = fontforge.open(fn)
f.selection.all()
for g in f.selection.byGlyphs:
  no_layers = True
  for l in layers:
    if fg_layer_name != l: 
      if not g.layers[l].isEmpty():
        no_layers = False
        break
  if no_layers:
    f.selection.select(("less",), g)

layer_map = {}
for g in f.selection.byGlyphs:
  mapping = {}
  for l in layers:
    mapping[l] = copyGlyph(f, g, l, g.layers[l]).glyphname
  layer_map[g.glyphname] = mapping
layer_file = open(fn + '.colr.layers', 'w')
layer_file.write(str(layers))
layer_file.write(str(layer_map))
layer_file.close()
f.generate(nfn, flags=("glyph-map-file"))
f.close()
