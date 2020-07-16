#!/usr/bin/env python

import sys
import fontforge

fn = sys.argv[1]

f = fontforge.open(fn)
for i in range(2, len(sys.argv), 2):
  t = open(sys.argv[i+1], 'rb')
  f.setTableData(sys.argv[i], t.read())
  t.close()
f.generate(fn)
f.close()
