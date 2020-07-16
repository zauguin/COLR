#!/bin/sh
BASEFONT="$1";shift
PALETTES="$1";shift

# Generate enlarged font with separate glyphs for every layer
python prepare_font.py "$BASEFONT"
# Build the actual COLR/CPAL tables out if that. (Could be in python too, but Lua is nicer to work with)
texlua build_colr.lua "$BASEFONT.colr.g2n" "$BASEFONT.colr.layers" "$PALETTES" "$BASEFONT.colr.COLR" "$BASEFONT.colr.CPAL"
python add_table.py "$BASEFONT.colr.ttf" COLR "$BASEFONT.colr.COLR" CPAL "$BASEFONT.colr.CPAL"
