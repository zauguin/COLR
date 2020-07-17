local function build_colr(t)
  local bases = {}
  for gid in next, t do
    bases[#bases+1] = gid
  end
  table.sort(bases)
  local layers = {}
  for i=1,#bases do
    local base = bases[i]
    local glyphs = t[base]
    local first = #layers
    local num = #glyphs
    bases[i] = string.pack(">HHH", base, first, num)
    for j, glyph in next, glyphs do -- Must allow nils
      layers[first+j] = string.pack(">HH", glyphs[j], j-1)
    end
  end
  return string.pack(">HHI4I4H", 0, #bases, 14, 14+#bases*6, #layers) .. table.concat(bases) .. table.concat(layers)
end

local l = lpeg or require'lpeg'

local hexByte = l.R('09', 'AF', 'af') * l.R('09', 'af', 'AF')/function(s)return tonumber(s, 16)end
local htmlColor = '#' * hexByte * hexByte * hexByte * (hexByte+l.Cc(0)) * -1 / function(r,g,b,a) return string.char(r,g,b,a)end

local function build_cpal(t, layers)
  local bases = {}
  local colors = {}
  for i=1,#t do
    local base = #colors
    bases[i] = string.pack(">H", base)
    for j, layer in ipairs(layers) do
      local color = t[i][layer]
      colors[base+j] = color and assert(htmlColor:match(color)) or '\xFF\xFF\xFF\xFF'
    end
  end
  return string.pack(">HHHHI4", 0, #layers, #t, #colors, 12+#bases*2) .. table.concat(bases) .. table.concat(colors)
end

local parse_layers do
  local str = "'" * l.C((1-l.P"'")^0) * "'"
  local function list_of(p) return p * (', ' * p)^0 end
  local function dict_of(p) return l.Cf(l.Ct'' * '{' * list_of(l.Cg(str * ': ' * p))^-1 * '}', rawset) end
  local dict = dict_of(dict_of(str))
  local array = l.Ct('[' * list_of(str)^-1 * ']')
  function parse_layers(fn)
    local f = assert(io.open(fn))
    local arr, dict = assert((array*dict*-1):match(f:read'a'))
    f:close()
    return arr, dict
  end
end

local parse_g2n do
  local line = l.P'GLYPHID ' * (l.R'09'^1/tonumber) * '\tPSNAME ' * l.C((1-l.S'\t\n')^1) * ('\tUNICODE ' * l.R('09', 'AF', 'af')^4)^-1 * '\n'
  local lines = l.Cf(l.Ct'' * l.Cg(line)^0, function(t, gid, name, _uni) t[name] = gid return t end)*-1
  function parse_g2n(fn)
    local f = assert(io.open(fn))
    local map = assert(lines:match(f:read'a'))
    f:close()
    return map
  end
end

local gid_map = parse_g2n(arg[1])
local layer_list, decompositions = parse_layers(arg[2])
local colr = {}
for gname, layers in next, decompositions do
  local gid_list = {}
  for i, layer_name in ipairs(layer_list) do
    gid_list[i] = gid_map[layers[layer_name]]
  end
  colr[gid_map[gname]] = gid_list
end
local out_file = io.open(arg[4], 'wb')
out_file:write(build_colr(colr))
out_file:close()
out_file = io.open(arg[5], 'wb')
out_file:write(build_cpal(assert(loadfile(arg[3]))(), layer_list))
out_file:close()
