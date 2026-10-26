-- Build script for scout-robot-girl.aseprite (300x400).
-- Run through the aseprite MCP (run_lua_script) or:
--   aseprite -b --script ArtSrc/aseprite/scout-robot-girl.lua
local W, H = 300, 400
local OUT_DIR = (os.getenv("SCOUT_OUT_DIR") or "/workspace/ArtSrc/aseprite") .. "/"
local pc = app.pixelColor

local PAL, PALSEEN = {}, {}
local function C(hex)
  local r = tonumber(hex:sub(2, 3), 16)
  local g = tonumber(hex:sub(4, 5), 16)
  local b = tonumber(hex:sub(6, 7), 16)
  if not PALSEEN[hex] then PALSEEN[hex] = true; PAL[#PAL + 1] = Color(r, g, b, 255) end
  return pc.rgba(r, g, b, 255)
end

local seed = 1337
local function rnd()
  seed = (seed * 1103515245 + 12345) % 2147483648
  return seed / 2147483648
end
local function ri(a, b) return a + math.floor(rnd() * (b - a + 1)) end

---------------------------------------------------------------- palette
local OUT  = C"#120e17"
local LIN  = C"#2a2232"
local ARM  = { hi = C"#f7f2e6", base = C"#dbd3c2", sh = C"#a89f94", deep = C"#756e78" }
local ORG  = { hi = C"#ffb15c", base = C"#ec7a30", sh = C"#b14823", deep = C"#7a2d1f" }
local DRK  = { hi = C"#60657c", base = C"#3e4156", sh = C"#2b2d3d", deep = C"#1f2030" }
local MET  = { hi = C"#a6aeb8", base = C"#747c8a", sh = C"#4e5563", deep = C"#363b48" }
local SKN  = { hi = C"#fde9da", base = C"#f2c9ae", sh = C"#d59587", deep = C"#a5636a" }
local HAIR = { hi = C"#95bbdb", base = C"#5476a3", sh = C"#374e73", deep = C"#252f4d" }
local SCF  = { hi = C"#ec6c52", base = C"#bb3c3a", sh = C"#802633", deep = C"#531a2b" }
local LTH  = { hi = C"#9b6d4b", base = C"#724c37", sh = C"#4c3228", deep = C"#33231e" }
local EYE  = { hi = C"#7ef6ff", base = C"#22b6d3", sh = C"#106385", deep = C"#0b2c45" }
local WHT  = C"#ffffff"
local WIRE = { r = C"#d9453d", y = C"#f1c64b", b = C"#4c92db", cu = C"#e0a060" }
local NRG  = { w = C"#ffffff", a = C"#cafff7", b = C"#5ef2e6", c = C"#23b9ca", d = C"#147087", e = C"#0c3f56" }
local BG   = { a = C"#151821", b = C"#1a1e2a", c = C"#1f2433", ring = C"#262c3e",
               ruin = C"#1e2230", ruin2 = C"#23293a", win = C"#171a24",
               ground = C"#1b1e29", line = C"#2a3043", shadow = C"#0e1016", dust = C"#384058" }

---------------------------------------------------------------- canvas
local L = {}
local ORDER = { "bg", "body", "damage", "core", "hand_front", "outline", "energy" }
for _, n in ipairs(ORDER) do L[n] = Image(W, H, ColorMode.RGB) end
local ID = {}

local function put(img, x, y, c, id, clip)
  if x < 0 or y < 0 or x >= W or y >= H then return end
  local k = y * W + x
  if clip and not ID[k] then return end
  img:drawPixel(x, y, c)
  if id then ID[k] = id end
end
local function hasId(x, y)
  if x < 0 or y < 0 or x >= W or y >= H then return false end
  return ID[y * W + x] ~= nil
end

---------------------------------------------------------------- shapes
local function Poly(t)
  local n = #t // 2
  local xs, ys = {}, {}
  local x0, y0, x1, y1 = 1e9, 1e9, -1e9, -1e9
  for i = 1, n do
    xs[i], ys[i] = t[2 * i - 1], t[2 * i]
    x0 = math.min(x0, xs[i]); x1 = math.max(x1, xs[i])
    y0 = math.min(y0, ys[i]); y1 = math.max(y1, ys[i])
  end
  return { x0 = math.floor(x0) - 1, y0 = math.floor(y0) - 1, x1 = math.ceil(x1) + 1, y1 = math.ceil(y1) + 1,
    inside = function(x, y)
      local px, py = x + 0.5, y + 0.5
      local c, j = false, n
      for i = 1, n do
        local xi, yi, xj, yj = xs[i], ys[i], xs[j], ys[j]
        if ((yi > py) ~= (yj > py)) and (px < (xj - xi) * (py - yi) / (yj - yi) + xi) then c = not c end
        j = i
      end
      return c
    end }
end

local function Ell(cx, cy, rx, ry)
  ry = ry or rx
  return { x0 = math.floor(cx - rx) - 1, y0 = math.floor(cy - ry) - 1, x1 = math.ceil(cx + rx) + 1, y1 = math.ceil(cy + ry) + 1,
    inside = function(x, y)
      local dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
      return dx * dx + dy * dy <= 1
    end }
end

local function Cap(ax, ay, bx, by, r0, r1)
  r1 = r1 or r0
  local vx, vy = bx - ax, by - ay
  local L2 = math.max(vx * vx + vy * vy, 1e-6)
  local rm = math.max(r0, r1)
  return { x0 = math.floor(math.min(ax, bx) - rm) - 1, y0 = math.floor(math.min(ay, by) - rm) - 1,
           x1 = math.ceil(math.max(ax, bx) + rm) + 1, y1 = math.ceil(math.max(ay, by) + rm) + 1,
    inside = function(x, y)
      local px, py = x + 0.5 - ax, y + 0.5 - ay
      local t = (px * vx + py * vy) / L2
      if t < 0 then t = 0 elseif t > 1 then t = 1 end
      local dx, dy = px - vx * t, py - vy * t
      local r = r0 + (r1 - r0) * t
      return dx * dx + dy * dy <= r * r
    end }
end

local function Rect(x, y, w, h)
  return { x0 = x, y0 = y, x1 = x + w - 1, y1 = y + h - 1,
    inside = function(px, py) return px >= x and py >= y and px < x + w and py < y + h end }
end

local function Union(...)
  local list = { ... }
  local s = { x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9 }
  for _, a in ipairs(list) do
    s.x0 = math.min(s.x0, a.x0); s.y0 = math.min(s.y0, a.y0)
    s.x1 = math.max(s.x1, a.x1); s.y1 = math.max(s.y1, a.y1)
  end
  s.inside = function(x, y)
    for _, a in ipairs(list) do if a.inside(x, y) then return true end end
    return false
  end
  return s
end
local function Sub(a, b)
  return { x0 = a.x0, y0 = a.y0, x1 = a.x1, y1 = a.y1,
    inside = function(x, y) return a.inside(x, y) and not b.inside(x, y) end }
end
local function Inter(a, b)
  return { x0 = math.max(a.x0, b.x0), y0 = math.max(a.y0, b.y0), x1 = math.min(a.x1, b.x1), y1 = math.min(a.y1, b.y1),
    inside = function(x, y) return a.inside(x, y) and b.inside(x, y) end }
end

---------------------------------------------------------------- painters
local nextId = 0
local function newId() nextId = nextId + 1; return nextId end

-- Flat fill + bottom-right shadow rim + top-left highlight rim (light from top-left).
local function part(img, S, m, o)
  o = o or {}
  local id = (not o.noid) and (o.id or newId()) or nil
  local sx, sy = o.sx or 2, o.sy or 2
  local hx, hy = o.hx or 1, o.hy or 1
  local ins = S.inside
  for y = math.max(0, S.y0), math.min(H - 1, S.y1) do
    for x = math.max(0, S.x0), math.min(W - 1, S.x1) do
      if ins(x, y) and (not o.clip or ID[y * W + x]) then
        local c = m.base
        if not o.flat then
          if (sx ~= 0 or sy ~= 0) and not ins(x + sx, y + sy) then c = m.sh
          elseif o.hi ~= false and not ins(x - hx, y - hy) then c = m.hi end
        end
        put(img, x, y, c, id)
      end
    end
  end
  return id
end

local function fill(img, S, c, o)
  o = o or {}
  local id = (o.id) or ((o.newid) and newId()) or nil
  for y = math.max(0, S.y0), math.min(H - 1, S.y1) do
    for x = math.max(0, S.x0), math.min(W - 1, S.x1) do
      if S.inside(x, y) then
        if not o.dither or ((x + y) % 2 == 0) then put(img, x, y, c, id, o.clip) end
      end
    end
  end
  return id
end

local function line(img, x0, y0, x1, y1, c, o)
  o = o or {}
  local dx, dy = math.abs(x1 - x0), -math.abs(y1 - y0)
  local sx, sy = x0 < x1 and 1 or -1, y0 < y1 and 1 or -1
  local err = dx + dy
  while true do
    put(img, x0, y0, c, o.id, o.clip)
    if o.w2 then put(img, x0 + 1, y0, c, o.id, o.clip) end
    if o.w2v then put(img, x0, y0 + 1, c, o.id, o.clip) end
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 >= dy then err = err + dy; x0 = x0 + sx end
    if e2 <= dx then err = err + dx; y0 = y0 + sy end
  end
end

local function path(img, pts, c, o)
  for i = 1, #pts - 3, 2 do line(img, pts[i], pts[i + 1], pts[i + 2], pts[i + 3], c, o) end
end

-- Pixel rows: one character per pixel, legend maps characters to colours.
local function rows(img, x0, y0, R, legend, o)
  o = o or {}
  local id = (not o.noid) and (o.id or newId()) or nil
  for j, row in ipairs(R) do
    local n = #row
    for i = 1, n do
      local ch = row:sub(i, i)
      local c = legend[ch]
      if c then
        local x = o.flip and (x0 + n - i) or (x0 + i - 1)
        put(img, x, y0 + j - 1, c, id, o.clip)
      end
    end
  end
  return id
end

-- Engraved scratch: dark groove with a lit lip underneath.
local function scratch(img, x0, y0, x1, y1, dark, lit)
  line(img, x0, y0, x1, y1, dark, { clip = true })
  if lit then line(img, x0, y0 + 1, x1, y1 + 1, lit, { clip = true }) end
end

---------------------------------------------------------------- background
local bg = L.bg
local bayer = { { 0, 8, 2, 10 }, { 12, 4, 14, 6 }, { 3, 11, 1, 9 }, { 15, 7, 13, 5 } }
for y = 0, H - 1 do
  for x = 0, W - 1 do
    local t = (y - 60) / 260
    local th = bayer[y % 4 + 1][x % 4 + 1] / 16
    bg:drawPixel(x, y, (t > th) and BG.b or BG.a)
  end
end
-- hazy sun disk behind the figure
do
  local cx, cy, r = 150, 150, 112
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local d = math.sqrt((x + 0.5 - cx) ^ 2 + (y + 0.5 - cy) ^ 2)
      if d <= r then
        if d > r - 1.2 then bg:drawPixel(x, y, BG.ring)
        elseif d > r - 5 and (x + y) % 2 == 0 then bg:drawPixel(x, y, BG.c)
        elseif d <= r - 5 then
          local th = bayer[y % 4 + 1][x % 4 + 1] / 16
          bg:drawPixel(x, y, ((1 - d / r) * 1.6 > th) and BG.c or BG.b)
        end
      end
    end
  end
end
-- ruined skyline
do
  local x = -4
  while x < W do
    local w = ri(12, 34)
    local top = ri(262, 340)
    if x > 90 and x < 200 then top = top + 25 end
    for yy = top, 383 do
      for xx = x, x + w - 1 do
        if xx >= 0 and xx < W then bg:drawPixel(xx, yy, BG.ruin) end
      end
    end
    -- broken jagged roof
    local yy = top
    for xx = x, x + w - 1 do
      yy = math.max(top - 8, math.min(top + 6, yy + ri(-2, 2)))
      for k = math.min(yy, top), math.max(yy, top) do
        if xx >= 0 and xx < W then bg:drawPixel(xx, k, (k < top) and BG.ruin or BG.a) end
      end
    end
    for xx = x, x + w - 1 do if xx >= 0 and xx < W and top - 1 >= 0 then bg:drawPixel(xx, top, BG.ruin2) end end
    -- windows
    for wy = top + 6, 376, 9 do
      for wx = x + 3, x + w - 5, 7 do
        if rnd() < 0.55 then
          for a = 0, 2 do for b = 0, 3 do
            if wx + a >= 0 and wx + a < W then bg:drawPixel(wx + a, wy + b, BG.win) end
          end end
        end
      end
    end
    -- leaning antenna / rebar
    if rnd() < 0.4 then
      local ax = x + ri(2, w - 3)
      local h = ri(10, 22)
      for k = 0, h do
        local xx = ax + (k // 5)
        if xx >= 0 and xx < W then bg:drawPixel(xx, top - k, BG.ruin2) end
      end
    end
    x = x + w + ri(0, 6)
  end
end
for y = 384, H - 1 do for x = 0, W - 1 do bg:drawPixel(x, y, BG.ground) end end
for x = 0, W - 1 do bg:drawPixel(x, 384, BG.line) end
for _ = 1, 90 do
  local x, y = ri(0, W - 1), ri(386, H - 1)
  bg:drawPixel(x, y, BG.line)
end
fill(bg, Ell(154, 390, 54, 6), BG.shadow)
for _ = 1, 70 do
  local x, y = ri(0, W - 1), ri(0, 380)
  bg:drawPixel(x, y, BG.dust)
end

---------------------------------------------------------------- body (back to front)
local body = L.body

-- scarf tail, blown to the left behind the shoulder
local scarfTail = Sub(Poly{
  134, 96, 118, 98, 100, 108, 86, 124, 76, 146, 70, 168, 62, 190, 70, 184, 72, 198, 78, 182, 84, 194, 86, 176,
  92, 160, 100, 140, 112, 124, 128, 112, 138, 106 },
  Union(Ell(84, 158, 2.2, 3), Ell(96, 132, 1.6, 2.4)))
part(body, scarfTail, SCF, { sx = 3, sy = 1 })
local scarfTail2 = Poly{ 128, 104, 110, 120, 98, 138, 92, 156, 90, 172, 94, 186, 98, 172, 102, 182, 104, 166, 108, 148, 116, 132, 132, 114 }
part(body, scarfTail2, SCF, { sx = 3, sy = 1 })

-- neck
part(body, Cap(150, 80, 150, 102, 7), DRK, { sx = 3, sy = 0 })
for y = 88, 100, 4 do line(body, 144, y, 156, y, DRK.sh) end

-- torso bodysuit
local torso = Poly{ 124, 100, 176, 100, 183, 118, 177, 146, 168, 164, 171, 180, 178, 198, 162, 206, 150, 210, 138, 206, 122, 198, 129, 180, 132, 164, 123, 146, 117, 118 }
part(body, torso, DRK, { sx = 4, sy = 1 })

-- legs: thighs (bodysuit)
local thighL = Cap(140, 200, 138, 276, 12, 8)
local thighR = Cap(160, 200, 167, 276, 12, 8)
part(body, thighL, DRK, { sx = 4, sy = 0 })
part(body, thighR, DRK, { sx = 4, sy = 0 })

-- shins (inner frame)
local shinL = Cap(138, 288, 135, 348, 9, 7)
local shinR = Cap(167, 288, 172, 348, 9, 7)
part(body, shinL, DRK, { sx = 3, sy = 0 })
part(body, shinR, DRK, { sx = 3, sy = 0 })

-- knee joints (exposed ball joints)
part(body, Ell(138, 282, 8, 7), MET, { sx = 3, sy = 2 })
part(body, Ell(167, 282, 8, 7), MET, { sx = 3, sy = 2 })
fill(body, Ell(137, 281, 2.5, 2.5), MET.deep)
fill(body, Ell(166, 281, 2.5, 2.5), MET.deep)
put(body, 136, 280, MET.hi); put(body, 165, 280, MET.hi)

-- shin armor plates
local shinPlateL = Poly{ 128, 290, 147, 290, 146, 328, 141, 342, 131, 342, 127, 326 }
local shinPlateR = Sub(Poly{ 158, 290, 177, 290, 181, 326, 177, 342, 167, 342, 162, 328 },
                       Poly{ 175, 332, 184, 326, 184, 346, 172, 346 })
part(body, shinPlateL, ARM, { sx = 3, sy = 1 })
part(body, shinPlateR, ARM, { sx = 3, sy = 1 })
line(body, 130, 295, 145, 295, ORG.base); line(body, 130, 296, 145, 296, ORG.sh)
line(body, 160, 295, 176, 295, ORG.base); line(body, 160, 296, 176, 296, ORG.sh)

-- boots
local bootL = Poly{ 125, 338, 148, 338, 149, 360, 152, 374, 152, 388, 112, 388, 112, 380, 118, 372, 122, 360 }
local bootR = Poly{ 158, 338, 181, 338, 183, 360, 188, 370, 197, 378, 197, 388, 157, 388, 157, 376, 159, 362 }
part(body, bootL, DRK, { sx = 3, sy = 1 })
part(body, bootR, DRK, { sx = 3, sy = 1 })
part(body, Poly{ 124, 336, 149, 336, 150, 346, 123, 346 }, ARM, { sx = 2, sy = 1 })
part(body, Poly{ 157, 336, 182, 336, 183, 346, 156, 346 }, ARM, { sx = 2, sy = 1 })
part(body, Poly{ 112, 381, 152, 381, 152, 388, 112, 388 }, LTH, { sx = 0, sy = -2, hi = false })
part(body, Poly{ 157, 381, 197, 381, 197, 388, 157, 388 }, LTH, { sx = 0, sy = -2, hi = false })
part(body, Poly{ 113, 374, 121, 369, 127, 372, 127, 381, 113, 381 }, ORG, { sx = 1, sy = 1 })
part(body, Poly{ 182, 372, 188, 368, 196, 376, 196, 381, 182, 381 }, ORG, { sx = 1, sy = 1 })
for _, bx in ipairs({ 128, 136, 144, 161, 169, 177 }) do line(body, bx, 384, bx + 3, 384, LTH.deep) end

-- thigh armor plates (right plate cracked open at the bottom)
local thighPlateL = Poly{ 128, 214, 147, 212, 148, 248, 143, 262, 133, 262, 128, 246 }
local thighChunk = Poly{ 162, 246, 170, 240, 178, 250, 175, 264, 164, 264 }
local thighPlateR = Sub(Poly{ 153, 212, 172, 214, 173, 246, 168, 262, 158, 262, 153, 248 }, thighChunk)
part(body, thighPlateL, ARM, { sx = 3, sy = 1 })
part(body, thighPlateR, ARM, { sx = 3, sy = 1 })
line(body, 130, 218, 146, 217, ORG.base, { w2v = true })
line(body, 155, 217, 171, 218, ORG.base, { w2v = true })

-- belt, pouch and hip plates
part(body, Poly{ 128, 175, 172, 175, 175, 187, 125, 187 }, LTH, { sx = 0, sy = 2 })
part(body, Rect(145, 177, 10, 8), MET, { sx = 1, sy = 1 })
fill(body, Rect(148, 179, 4, 4), MET.deep)
local hipL = Poly{ 118, 185, 148, 188, 146, 204, 132, 212, 117, 203 }
local hipR = Poly{ 152, 188, 182, 185, 183, 203, 168, 212, 154, 204 }
part(body, hipL, ARM, { sx = 3, sy = 2 })
part(body, hipR, ARM, { sx = 3, sy = 2 })
path(body, { 119, 201, 132, 209, 145, 203 }, ORG.base, { clip = true })
path(body, { 155, 203, 168, 209, 182, 201 }, ORG.base, { clip = true })
part(body, Poly{ 108, 188, 122, 188, 123, 206, 109, 206 }, LTH, { sx = 2, sy = 2 })
part(body, Poly{ 107, 187, 123, 187, 123, 195, 107, 194 }, LTH, { sx = 1, sy = 1 })
put(body, 115, 193, MET.hi); put(body, 114, 193, MET.base)

-- chest armor
local chest = Poly{ 126, 103, 174, 103, 182, 117, 178, 139, 168, 155, 150, 160, 132, 155, 122, 139, 118, 117 }
part(body, chest, ARM, { sx = 4, sy = 2 })
-- chest contour seams + orange collar chevrons
path(body, { 150, 120, 150, 158 }, ARM.sh)
path(body, { 128, 132, 138, 142, 150, 144, 162, 142, 172, 132 }, ARM.sh)
path(body, { 128, 131, 138, 141, 150, 143, 162, 141, 172, 131 }, ARM.hi)
part(body, Poly{ 128, 103, 150, 118, 172, 103, 166, 103, 150, 112, 134, 103 }, ORG, { sx = 1, sy = 1, id = nil })
-- chest power socket, dimmed
part(body, Poly{ 146, 122, 154, 122, 156, 127, 154, 132, 146, 132, 144, 127 }, MET, { sx = 1, sy = 1 })
fill(body, Rect(148, 125, 4, 5), NRG.e)
put(body, 149, 126, NRG.d); put(body, 150, 127, NRG.c)
-- abdomen ribs
for y = 160, 172, 4 do line(body, 134, y, 166, y, DRK.sh, { clip = true }) end
for y = 161, 173, 4 do line(body, 135, y, 160, y, DRK.hi, { clip = true }) end

-- left (image) arm, hanging
part(body, Cap(114, 118, 108, 166, 8, 7), DRK, { sx = 3, sy = 0 })
part(body, Ell(107, 172, 7, 7), MET, { sx = 2, sy = 2 })
fill(body, Ell(107, 172, 2.5, 2.5), MET.deep)
local gauntletL = Cap(107, 182, 104, 218, 9, 8)
part(body, gauntletL, ARM, { sx = 3, sy = 0 })
line(body, 98, 186, 115, 188, ORG.base, { w2v = true, clip = true })
part(body, Ell(104, 222, 5, 4), DRK, { sx = 2, sy = 1 })
rows(body, 96, 223, {
  "..nMMMMMMMn..",
  ".nMmmmmmmMMn.",
  ".dhhDDDDDDDd.",
  "dhDDDDDDDDDDd",
  "dhDDDDDDDDDdd",
  "dhDLDDLDDLDdd",
  "dhDLDDLDDLDd.",
  "dhDLDDLDDLDd.",
  "dmDLmDLmDLdd.",
  ".dDLDDLDDLd..",
  ".dMLdMLdMLd..",
  "..LddLddLd...",
  "...LL.LL.L...",
}, { D = DRK.base, d = DRK.sh, h = DRK.hi, M = MET.base, m = MET.hi, n = MET.sh, L = LIN })
-- thumb on the inner side
rows(body, 108, 227, {
  ".nM.",
  "nMMd",
  "DDDd",
  "DDd.",
  "Dd..",
}, { D = DRK.base, d = DRK.sh, M = MET.base, n = MET.sh })
local padL = Ell(112, 113, 15, 12)
part(body, padL, ARM, { sx = 3, sy = 3 })
part(body, Inter(padL, Poly{ 97, 116, 127, 106, 128, 110, 97, 120 }), ORG, { sx = 0, sy = 1, noid = true })

-- right (image) arm, raised and holding the core
part(body, Cap(188, 118, 198, 164, 8, 7), DRK, { sx = 3, sy = 0 })
part(body, Ell(200, 169, 7, 7), MET, { sx = 2, sy = 2 })
fill(body, Ell(200, 169, 2.5, 2.5), MET.deep)
local forearmR = Cap(204, 172, 223, 160, 8, 7)
part(body, forearmR, ARM, { sx = 1, sy = 3 })
line(body, 210, 162, 214, 176, ORG.base, { w2 = true, clip = true })
part(body, Ell(226, 158, 5, 5), DRK, { sx = 1, sy = 2 })
-- palm under the core
part(body, Ell(238, 158, 13, 5), DRK, { sx = 0, sy = 2 })
local padChunk = Poly{ 192, 100, 206, 104, 204, 112, 198, 110, 196, 116, 190, 106 }
local padR = Sub(Ell(188, 113, 15, 12), padChunk)
part(body, padR, ARM, { sx = 3, sy = 3 })
part(body, Inter(padR, Poly{ 173, 106, 203, 116, 203, 120, 173, 110 }), ORG, { sx = 0, sy = 1, noid = true })

-- head: face
local face = Poly{ 130, 40, 170, 40, 174, 58, 172, 72, 165, 82, 156, 89, 150, 91, 144, 89, 135, 82, 128, 72, 126, 58 }
part(body, face, SKN, { sx = 3, sy = 1 })

-- hair
local hair = Union(Poly{
  115, 108, 113, 84, 112, 60, 117, 38, 127, 24, 140, 16, 150, 14, 162, 16, 175, 24, 184, 38, 188, 58, 188, 80, 183, 100,
  178, 90, 176, 78, 174, 64,
  170, 56, 167, 68, 163, 55, 158, 64, 153, 51, 147, 64, 142, 54, 137, 67, 133, 56, 129, 66,
  126, 64, 125, 80, 121, 96 },
  Poly{ 147, 17, 150, 8, 157, 3, 163, 4, 157, 7, 154, 12, 153, 17 })
local hairId = part(body, hair, HAIR, { sx = 3, sy = 3, hx = 2, hy = 2 })
-- strand lines and the shine band
path(body, { 136, 22, 128, 36, 124, 54 }, HAIR.sh, { clip = true })
path(body, { 150, 18, 147, 34, 145, 48 }, HAIR.sh, { clip = true })
path(body, { 164, 20, 170, 36, 172, 52 }, HAIR.sh, { clip = true })
path(body, { 118, 70, 117, 86, 119, 96 }, HAIR.sh, { clip = true })
path(body, { 182, 68, 183, 84, 182, 96 }, HAIR.deep, { clip = true })
for x = 124, 176 do
  local y = math.floor(32 - 6 * math.sin((x - 124) / 52 * math.pi) + 0.5)
  if (x % 9) ~= 0 then put(body, x, y, HAIR.hi, nil, true); put(body, x, y + 1, HAIR.hi, nil, true) end
end

-- ear sensors over the hair
part(body, Ell(114, 68, 5, 9), MET, { sx = 2, sy = 2 })
part(body, Ell(186, 68, 5, 9), MET, { sx = 2, sy = 2 })
fill(body, Rect(112, 64, 2, 7), ORG.base); put(body, 112, 64, ORG.hi)
fill(body, Rect(186, 64, 2, 7), ORG.base); put(body, 186, 64, ORG.hi)
-- antenna (bent) on the right ear
path(body, { 187, 59, 190, 44, 193, 40, 197, 22 }, MET.base, { w2 = true, id = newId() })
path(body, { 188, 59, 191, 44 }, MET.sh)
fill(body, Rect(196, 18, 4, 4), ORG.base, { id = nextId }); put(body, 196, 18, ORG.hi)

-- eyes
local eyeLegend = { K = HAIR.deep, s = C"#eef0f7", d = EYE.sh, b = EYE.base, c = EYE.hi, p = EYE.deep, w = WHT }
local eyeRows = {
  "..KKKKKKKKK..",
  ".KKKKKKKKKKKK",
  "KK.sddddddsKK",
  "..sdpppppdds.",
  "..dwwpppbbdd.",
  "..dwwpppbbbd.",
  "..dbppppbbbd.",
  "..dbbbbbbbbd.",
  "..dbcccccbbd.",
  "..sdcccccbds.",
  "...sdddddds..",
  "....KKKKKK...",
}
rows(body, 131, 64, eyeRows, eyeLegend, { noid = true })
rows(body, 156, 64, eyeRows, eyeLegend, { noid = true, flip = true })
-- scope monocle ring around the right eye
for a = 0, 359 do
  local r = math.rad(a)
  local x = math.floor(162.5 + 10 * math.cos(r))
  local y = math.floor(70 + 9 * math.sin(r))
  if a < 195 or a > 255 then put(body, x, y, (a > 180 and a < 300) and MET.hi or MET.sh) end
end
path(body, { 172, 70, 178, 68 }, MET.base)
put(body, 166, 63, ORG.hi); put(body, 167, 64, ORG.base)
-- nose, mouth, blush
put(body, 151, 80, SKN.sh)
line(body, 147, 85, 152, 85, SKN.deep)
put(body, 148, 86, SKN.sh); put(body, 151, 86, SKN.sh)
for i = 0, 2 do
  put(body, 134 + i * 2, 79, SKN.sh); put(body, 135 + i * 2, 78, SKN.sh)
  put(body, 161 + i * 2, 79, SKN.sh); put(body, 162 + i * 2, 78, SKN.sh)
end
-- face panel seam
path(body, { 129, 72, 134, 80, 140, 85 }, SKN.sh, { clip = true })

-- scarf wrap around the neck (front)
local scarf = Poly{ 128, 90, 172, 90, 176, 100, 168, 108, 150, 110, 132, 108, 124, 100 }
part(body, scarf, SCF, { sx = 3, sy = 2 })
part(body, Ell(132, 104, 7, 6), SCF, { sx = 2, sy = 2 })
path(body, { 136, 96, 150, 100, 166, 96 }, SCF.sh, { clip = true })
path(body, { 136, 101, 150, 105, 166, 101 }, SCF.sh, { clip = true })

---------------------------------------------------------------- damage
local dmg = L.damage

-- right shoulder pad: shell thickness along the broken edge
part(dmg, Inter(Ell(188, 113, 15, 12), Sub(Poly{ 189, 98, 208, 102, 206, 115, 198, 113, 196, 119, 187, 106 }, padChunk)),
  MET, { sx = 1, sy = 1 })
path(dmg, { 180, 108, 184, 112, 182, 116, 187, 121 }, ARM.deep, { clip = true })
-- left shoulder pad scratches
scratch(dmg, 104, 107, 112, 104, ARM.deep, ARM.hi)
scratch(dmg, 106, 112, 117, 108, ARM.deep, ARM.hi)
scratch(dmg, 116, 118, 121, 116, ARM.deep)

-- chest crack + scratches + scorch
path(dmg, { 173, 110, 168, 116, 170, 120, 164, 127, 166, 131, 160, 138 }, ARM.deep, { clip = true })
path(dmg, { 174, 111, 169, 117, 171, 121, 165, 128, 167, 132, 161, 139 }, ARM.hi, { clip = true })
path(dmg, { 168, 116, 176, 121 }, ARM.deep, { clip = true })
scratch(dmg, 126, 120, 136, 116, ARM.deep, ARM.hi)
scratch(dmg, 128, 125, 133, 123, ARM.deep)
for y = 146, 156 do for x = 126, 142 do
  local d = ((x - 134) / 9) ^ 2 + ((y - 151) / 6) ^ 2
  if d < 1 and (x + y) % 2 == 0 then put(dmg, x, y, (d < 0.4) and LTH.sh or ARM.deep, nil, true) end
end end

-- abdomen tear showing frame and a cable
local tear = Poly{ 152, 158, 162, 157, 165, 164, 160, 170, 153, 169, 150, 163 }
part(dmg, Inter(tear, torso), MET, { sx = 1, sy = 1 })
for y = 159, 168, 3 do line(dmg, 153, y, 162, y, MET.deep, { clip = true }) end
path(dmg, { 154, 161, 157, 166, 161, 167 }, WIRE.r, { clip = true })

-- left forearm: armor broken away, wires spilling out
local hole = Inter(Poly{ 98, 196, 104, 192, 108, 198, 114, 194, 116, 214, 108, 218, 100, 216, 97, 206 }, gauntletL)
part(dmg, hole, DRK, { sx = -2, sy = -1, hi = false })
line(dmg, 101, 200, 111, 202, MET.base, { clip = true })
line(dmg, 101, 208, 111, 210, MET.base, { clip = true })
local wireId = newId()
path(dmg, { 104, 201, 101, 210, 97, 220, 94, 230, 95, 238 }, WIRE.r, { id = wireId, w2 = true })
path(dmg, { 108, 203, 108, 212, 112, 222, 116, 234, 115, 240 }, WIRE.y, { id = wireId, w2 = true })
path(dmg, { 106, 206, 104, 214, 102, 220 }, WIRE.b, { id = wireId, w2 = true })
put(dmg, 95, 239, WIRE.cu, wireId); put(dmg, 96, 239, WIRE.cu, wireId)
put(dmg, 115, 241, WIRE.cu, wireId); put(dmg, 116, 241, WIRE.cu, wireId)
-- broken edge chips
for _, p in ipairs({ { 97, 196 }, { 115, 193 }, { 99, 191 } }) do put(dmg, p[1], p[2], ARM.deep, nil, true) end

-- right forearm scratches
scratch(dmg, 206, 166, 216, 160, ARM.deep, ARM.hi)
scratch(dmg, 207, 174, 214, 171, ARM.deep)

-- right thigh: exposed frame + piston where the plate broke off
part(dmg, Inter(thighChunk, thighR), MET, { sx = 2, sy = 1 })
line(dmg, 166, 249, 168, 262, MET.hi, { clip = true, w2 = true })
line(dmg, 171, 251, 172, 262, MET.deep, { clip = true })
path(dmg, { 156, 226, 161, 232, 159, 238, 164, 244 }, ARM.deep, { clip = true })
path(dmg, { 157, 226, 162, 232, 160, 238, 165, 244 }, ARM.hi, { clip = true })
scratch(dmg, 131, 228, 144, 222, ARM.deep, ARM.hi)
scratch(dmg, 132, 240, 140, 237, ARM.deep)

-- left knee: wire bundle bridging the joint
local kneeWire = newId()
path(dmg, { 131, 274, 128, 282, 131, 290 }, WIRE.b, { id = kneeWire, w2 = true })
path(dmg, { 134, 275, 132, 283, 134, 289 }, WIRE.r, { id = kneeWire })

-- shin dents and dirt
scratch(dmg, 131, 308, 143, 304, ARM.deep, ARM.hi)
scratch(dmg, 163, 314, 176, 318, ARM.deep, ARM.hi)
path(dmg, { 172, 300, 168, 308, 171, 312 }, ARM.deep, { clip = true })
for _, b in ipairs({ { 127, 320, 146, 342 }, { 162, 320, 181, 342 }, { 112, 350, 152, 380 }, { 157, 350, 197, 380 } }) do
  for _ = 1, 40 do
    local x, y = ri(b[1], b[3]), ri(b[2], b[4])
    if hasId(x, y) then put(dmg, x, y, (y > 350) and DRK.deep or LTH.sh, nil, true) end
  end
end

-- cheek crack
path(dmg, { 129, 75, 132, 78, 131, 80, 135, 83 }, SKN.deep, { clip = true })
put(dmg, 132, 79, MET.base, nil, true)

-- scarf frayed holes
for _, p in ipairs({ { 80, 170 }, { 92, 150 }, { 100, 176 } }) do
  put(dmg, p[1], p[2], SCF.deep, nil, true); put(dmg, p[1] + 1, p[2] + 1, SCF.deep, nil, true)
end

-- torn sleeve on the raised upper arm
local sleeveTear = Poly{ 190, 134, 196, 131, 199, 140, 194, 146, 189, 141 }
part(dmg, Inter(sleeveTear, Cap(188, 118, 198, 164, 8, 7)), MET, { sx = 1, sy = 1 })
put(dmg, 192, 136, MET.hi, nil, true); put(dmg, 194, 141, MET.deep, nil, true)
path(dmg, { 191, 138, 195, 142, 197, 139 }, WIRE.y, { clip = true })

---------------------------------------------------------------- stance: lean the lower legs into an A-stance
do
  local function lerp(a, b, t) return a + (b - a) * math.max(0, math.min(1, t)) end
  local function dxL(y)
    if y < 282 then return math.floor(lerp(0, -4, (y - 213) / 69) + 0.5) end
    return math.floor(lerp(-4, -8, (y - 282) / 66) + 0.5)
  end
  local function dxR(y)
    if y < 282 then return math.floor(lerp(0, 2, (y - 213) / 69) + 0.5) end
    return math.floor(lerp(2, 6, (y - 282) / 66) + 0.5)
  end
  local imgs = { body, dmg }
  local src = {}
  for i, img in ipairs(imgs) do src[i] = img:clone() end
  local srcId = {}
  for y = 213, H - 1 do
    for x = 100, 210 do srcId[y * W + x] = ID[y * W + x] end
  end
  for y = 213, H - 1 do
    local leftStart = (y < 250) and 120 or 104
    for x = leftStart, 210 do
      for _, img in ipairs(imgs) do img:drawPixel(x, y, 0) end
      ID[y * W + x] = nil
    end
    for x = leftStart, 210 do
      local dx = (x < ((y < 282) and 150 or 155)) and dxL(y) or dxR(y)
      local tx = x + dx
      local sid = srcId[y * W + x]
      for i, img in ipairs(imgs) do
        local c = src[i]:getPixel(x, y)
        if c ~= 0 then img:drawPixel(tx, y, c) end
      end
      if sid then ID[y * W + tx] = sid end
    end
  end
end

---------------------------------------------------------------- core (cracked power cell)
local core = L.core
local CX = 238
local glass = Rect(CX - 9, 114, 19, 32)
part(core, glass, { hi = NRG.a, base = NRG.c, sh = NRG.d }, { sx = 3, sy = 0, hx = 2, hy = 0 })
-- inner fluid level / swirl
for y = 116, 143 do
  for x = CX - 7, CX + 7 do
    local v = math.sin((y + x * 0.6) / 3.2)
    if v > 0.75 then put(core, x, y, NRG.b) end
  end
end
fill(core, Rect(CX - 2, 118, 4, 24), NRG.a)
fill(core, Rect(CX - 1, 120, 2, 20), NRG.w)
-- broken top cap with a missing shard
local capTop = Sub(Rect(CX - 12, 107, 25, 8), Poly{ CX + 4, 104, CX + 14, 104, CX + 14, 112, CX + 9, 110 })
part(core, capTop, MET, { sx = 2, sy = 2 })
line(core, CX - 12, 110, CX + 3, 110, MET.deep, { clip = true })
local capBot = Rect(CX - 12, 145, 25, 8)
part(core, capBot, MET, { sx = 2, sy = 2 })
fill(core, Rect(CX - 5, 146, 11, 2), ORG.base)
put(core, CX - 5, 146, ORG.hi)
-- side struts
part(core, Rect(CX - 12, 114, 3, 31), MET, { sx = 1, sy = 0 })
part(core, Rect(CX + 10, 114, 3, 31), MET, { sx = 1, sy = 0 })
-- glass cracks + a missing pane revealing the dark interior
local cr = newId()
path(core, { CX + 3, 115, CX + 6, 121, CX + 3, 126, CX + 8, 133 }, NRG.w, { clip = true })
path(core, { CX + 6, 121, CX + 9, 119 }, NRG.w, { clip = true })
path(core, { CX - 7, 136, CX - 3, 140, CX - 6, 144 }, NRG.w, { clip = true })
part(core, Poly{ CX + 4, 128, CX + 10, 126, CX + 10, 138, CX + 6, 136 }, { hi = NRG.d, base = NRG.e, sh = NRG.e }, { sx = 0, sy = 0, hi = false })

---------------------------------------------------------------- fingers wrapping the base of the core
local hand = L.hand_front
rows(hand, 224, 145, {
  ".nMn.......................",
  ".MmMd......................",
  ".DhDd......................",
  ".DhDd.....nmMn.nmMn.nmMn.n.",
  "dDhDd.....mMMd.mMMd.mMMd.mn",
  "dDDDd.....DhDdLDhDdLDhDdLDd",
  "dDDDDd....DDDdLDDDdLDDDdLDd",
  "dDDDDDdddDDDDdLDDDdLDDDdLdd",
  ".dDDDDDDDDDDDDDDDDDDDDDDDd.",
  "..ddDDDDDDDDDDDDDDDDDDDdd..",
  "....ddddddddddddddddddd....",
}, { D = DRK.base, d = DRK.sh, h = DRK.hi, M = MET.base, m = MET.hi, n = MET.sh, L = LIN })

---------------------------------------------------------------- outline (outer + selective internal lines)
local ol = L.outline
for y = 0, H - 1 do
  for x = 0, W - 1 do
    local k = y * W + x
    local p = ID[k]
    if not p then
      if hasId(x - 1, y) or hasId(x + 1, y) or hasId(x, y - 1) or hasId(x, y + 1) then ol:drawPixel(x, y, OUT) end
    else
      local function front(nx, ny)
        if nx < 0 or ny < 0 or nx >= W or ny >= H then return false end
        local q = ID[ny * W + nx]
        return q ~= nil and q > p
      end
      if front(x - 1, y) or front(x + 1, y) or front(x, y - 1) or front(x, y + 1) then ol:drawPixel(x, y, LIN) end
    end
  end
end

---------------------------------------------------------------- energy (particles, arcs, rim light)
local en = L.energy
local ECX, ECY = CX, 130
-- glow halo (sparse dither so no new blended colours)
for y = ECY - 40, ECY + 40 do
  for x = ECX - 40, ECX + 40 do
    local d = math.sqrt((x - ECX) ^ 2 + ((y - ECY) * 0.9) ^ 2)
    if d > 22 and d < 38 and x >= 0 and x < W and y >= 0 and y < H and not hasId(x, y) and L.outline:getPixel(x, y) == 0 then
      local th = bayer[y % 4 + 1][x % 4 + 1] / 16
      if (1 - (d - 22) / 16) * 0.35 > th then en:drawPixel(x, y, NRG.e) end
    end
  end
end
-- particles spiralling in toward the core
for i = 1, 120 do
  local ang = rnd() * math.pi * 2
  local rad = 26 + rnd() * 66
  local x = math.floor(ECX + math.cos(ang) * rad)
  local y = math.floor(ECY + math.sin(ang) * rad * 0.85)
  if x >= 2 and x < W - 2 and y >= 2 and y < H - 2 then
    local near = 1 - (rad - 26) / 66
    local c = (near > 0.7) and NRG.a or (near > 0.4) and NRG.b or (near > 0.18) and NRG.c or NRG.d
    en:drawPixel(x, y, c)
    if near > 0.45 and rnd() < 0.5 then
      -- short streak pointing at the core
      local tx = x + ((ECX > x) and 1 or -1)
      local ty = y + ((ECY > y) and 1 or -1)
      en:drawPixel(tx, ty, NRG.d)
    elseif near > 0.25 and rnd() < 0.25 then
      en:drawPixel(x + 1, y, c); en:drawPixel(x - 1, y, c); en:drawPixel(x, y + 1, c); en:drawPixel(x, y - 1, c)
      en:drawPixel(x, y, NRG.w)
    end
  end
end
-- curved streams of motes being drawn in from the wasteland
local function stream(x0, y0, cx, cy, n)
  for i = 0, n do
    local t = i / n
    local u = 1 - t
    local x = math.floor(u * u * x0 + 2 * u * t * cx + t * t * ECX + 0.5)
    local y = math.floor(u * u * y0 + 2 * u * t * cy + t * t * ECY + 0.5)
    local d = math.sqrt((x - ECX) ^ 2 + (y - ECY) ^ 2)
    if d > 18 and not hasId(x, y) and x >= 1 and y >= 1 and x < W - 1 and y < H - 1 then
      if i % 2 == 0 then
        local c = (t > 0.8) and NRG.a or (t > 0.55) and NRG.b or (t > 0.3) and NRG.c or NRG.d
        en:drawPixel(x, y, c)
        if t > 0.6 and i % 8 == 0 then en:drawPixel(x + 1, y, NRG.c); en:drawPixel(x, y + 1, NRG.c) end
      elseif t > 0.45 then
        en:drawPixel(x, y, NRG.d)
      end
    end
  end
end
stream(292, 262, 300, 160, 90)
stream(214, 250, 280, 210, 70)
stream(286, 30, 300, 110, 70)
stream(206, 40, 196, 96, 60)
stream(262, 330, 232, 230, 90)

-- lightning arcs jumping off the broken cap and the cracks
local function arc(x0, y0, x1, y1, segs)
  local px, py = x0, y0
  for s = 1, segs do
    local t = s / segs
    local nx = math.floor(x0 + (x1 - x0) * t + ((s < segs) and ri(-4, 4) or 0))
    local ny = math.floor(y0 + (y1 - y0) * t + ((s < segs) and ri(-4, 4) or 0))
    line(en, px, py, nx, ny, NRG.b)
    line(en, px, py - 1, nx, ny - 1, NRG.a)
    px, py = nx, ny
  end
end
arc(CX + 10, 106, CX + 26, 88, 4)
arc(CX + 13, 128, CX + 34, 132, 4)
arc(CX - 12, 118, CX - 26, 100, 4)
arc(CX + 4, 103, CX + 2, 84, 3)
-- cyan rim light on whatever faces the core
for y = ECY - 60, ECY + 60 do
  for x = ECX - 60, ECX + 60 do
    if x >= 198 and hasId(x, y) and x >= 0 and y >= 0 and x < W and y < H then
      local dx, dy = ECX - x, ECY - y
      local d = math.sqrt(dx * dx + dy * dy)
      if d > 16 and d < 58 then
        local sx = (math.abs(dx) > d * 0.38) and ((dx > 0) and 1 or -1) or 0
        local sy = (math.abs(dy) > d * 0.38) and ((dy > 0) and 1 or -1) or 0
        if not hasId(x + sx, y + sy) and (L.core:getPixel(x, y) == 0) then
          en:drawPixel(x, y, (d < 34) and NRG.b or NRG.c)
        end
      end
    end
  end
end

---------------------------------------------------------------- assemble + save
local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = ORDER[1]
spr:newCel(spr.layers[1], 1, L[ORDER[1]], Point(0, 0))
for i = 2, #ORDER do
  local layer = spr:newLayer()
  layer.name = ORDER[i]
  spr:newCel(layer, 1, L[ORDER[i]], Point(0, 0))
end
local pal = Palette(#PAL)
for i, c in ipairs(PAL) do pal:setColor(i - 1, c) end
spr:setPalette(pal)
spr:saveAs(OUT_DIR .. "scout-robot-girl.aseprite")
spr:saveCopyAs(OUT_DIR .. "scout-robot-girl.png")
print("saved " .. OUT_DIR .. "scout-robot-girl.aseprite; palette=" .. #PAL .. " parts=" .. nextId)
