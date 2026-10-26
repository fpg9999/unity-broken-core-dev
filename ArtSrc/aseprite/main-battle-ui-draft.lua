-- Broken Core main battle UI DRAFT (576x324) — paints onto app.activeSprite
local W, H = 576, 324
local pc = app.pixelColor

local function C(hex, a)
  local r = tonumber(hex:sub(2, 3), 16)
  local g = tonumber(hex:sub(4, 5), 16)
  local b = tonumber(hex:sub(6, 7), 16)
  return pc.rgba(r, g, b, a or 255)
end

local BG     = C"#10131c"
local BG2    = C"#161a26"
local PANEL  = C"#1c2233"
local PANEL2 = C"#252b3d"
local STEEL  = C"#3a465c"
local STEEL2 = C"#56667c"
local HI     = C"#8aa0b8"
local LINE   = C"#4a8eb0"
local LINE2  = C"#6ab0d0"
local PURP   = C"#2e2a3d"
local PURP2  = C"#45405a"
local INK    = C"#0a0c12"
local GRIDBG = C"#121620"
local GRIDLN = C"#2a3348"
local ENERGY = C"#e8c24a"
local GREEN  = C"#6bcf7a"
local RED    = C"#d24a5a"
local CYAN   = C"#5ec8e0"
local MUTED  = C"#6a7488"
local RUST   = C"#8a5a3a"
local BAG    = C"#4a6a4a"
local BAG2   = C"#3a5240"

local spr = app.activeSprite
assert(spr, "no active sprite")
assert(spr.width == W and spr.height == H, "expected 576x324")

-- ensure draft layer
local draft = nil
for _, l in ipairs(spr.layers) do
  if l.name == "draft" then draft = l break end
end
if not draft then
  app.command.NewLayer()
  draft = app.activeLayer
  draft.name = "draft"
end
draft.isVisible = true

-- clear / recreate cel
do
  local old = draft:cel(1)
  if old then spr:deleteCel(old) end
end
local cel = spr:newCel(draft, 1, Image(W, H, ColorMode.RGB), Point(0, 0))
local img = cel.image

local function put(x, y, c)
  if x < 0 or y < 0 or x >= W or y >= H then return end
  img:putPixel(x, y, c)
end
local function hline(x1, x2, y, c)
  if x2 < x1 then x1, x2 = x2, x1 end
  for x = x1, x2 do put(x, y, c) end
end
local function vline(x, y1, y2, c)
  if y2 < y1 then y1, y2 = y2, y1 end
  for y = y1, y2 do put(x, y, c) end
end
local function rect(x, y, w, h, c)
  for yy = y, y + h - 1 do
    for xx = x, x + w - 1 do put(xx, yy, c) end
  end
end
local function rectb(x, y, w, h, c)
  hline(x, x + w - 1, y, c)
  hline(x, x + w - 1, y + h - 1, c)
  vline(x, y, y + h - 1, c)
  vline(x + w - 1, y, y + h - 1, c)
end
local function panel(x, y, w, h, fill, border)
  rect(x, y, w, h, fill or PANEL)
  rectb(x, y, w, h, border or LINE)
  hline(x + 1, x + w - 2, y + 1, HI)
  vline(x + 1, y + 1, y + h - 2, STEEL2)
end

-- background
rect(0, 0, W, H, BG)
for y = 0, H - 1, 4 do
  for x = 0, W - 1 do
    if (x + y) % 8 == 0 then put(x, y, BG2) end
  end
end

-- LEFT monitor
panel(4, 12, 160, 140, PANEL, LINE)
rect(9, 17, 88, 130, PURP)
rectb(9, 17, 88, 130, LINE2)
do
  local cx, cy = 53, 55
  rect(cx - 14, cy - 22, 28, 26, STEEL)
  rect(cx - 12, cy - 20, 24, 10, STEEL2)
  rect(cx + 2, cy - 12, 8, 4, CYAN)
  put(cx - 8, cy - 10, RED); put(cx - 7, cy - 10, RED)
  rect(cx - 18, cy + 6, 36, 48, STEEL)
  rect(cx - 6, cy + 18, 12, 14, ENERGY)
  rectb(cx - 6, cy + 18, 12, 14, CYAN)
  rect(cx - 28, cy + 10, 12, 20, PURP2)
  for i = 0, 5 do put(cx - 26 + i, cy + 28 + i, RUST) end
  for yy = 17, 146 do
    put(97, yy, STEEL); put(98, yy, LINE); put(99, yy, STEEL)
  end
  rect(94, cy + 20, 8, 8, ENERGY)
end
rect(107, 17, 52, 26, PANEL2); rectb(107, 17, 52, 26, STEEL2)
rect(107, 46, 52, 101, PANEL2); rectb(107, 46, 52, 101, STEEL2)
rect(112, 72, 42, 6, INK); rect(112, 72, 18, 6, ENERGY)
rect(112, 110, 42, 6, INK); rect(112, 110, 28, 6, GREEN)
rect(112, 132, 42, 8, INK)
rect(114, 134, 10, 4, GREEN); rect(128, 134, 10, 4, ENERGY); rect(142, 134, 10, 4, MUTED)

panel(8, 158, 152, 36, PANEL2, LINE)
rect(14, 176, 140, 10, INK); rect(14, 176, 70, 10, ENERGY)

panel(4, 200, 114, 118, PANEL, LINE)
for i = 0, 7 do
  local bx = 12 + i * 12
  rect(bx, 230, 10, 48, INK)
  if i < 5 then rect(bx + 1, 232, 8, 44, GREEN)
  else rect(bx + 1, 260, 8, 16, STEEL) end
  rectb(bx, 230, 10, 48, STEEL2)
end
for x = 8, 110 do
  local t = ((x + 300) // 4) % 2
  hline(x, x, 310, t == 0 and ENERGY or INK)
  hline(x, x, 311, t == 0 and ENERGY or INK)
end

-- CENTER machine
rect(172, 0, 171, 14, STEEL); rectb(172, 0, 171, 14, LINE)
for c = 0, 5 do
  local lx = 184 + 25 * c
  rect(lx, 4, 20, 4, c < 2 and CYAN or STEEL2)
end
rect(172, 14, 7, 257, STEEL); rect(336, 14, 7, 257, STEEL)
vline(174, 14, 270, HI); vline(338, 14, 270, INK)
for r = 0, 9 do put(175, 30 + r * 25, HI); put(339, 30 + r * 25, MUTED) end

panel(179, 14, 157, 257, GRIDBG, LINE)
do
  local gx, gy = 182, 17
  rect(gx, gy, 151, 251, GRIDBG)
  for i = 0, 6 do vline(gx + i * 25, gy, gy + 250, GRIDLN) end
  for j = 0, 10 do hline(gx, gx + 150, gy + j * 25, GRIDLN) end
  local samples = {
    {0, 2, BAG}, {1, 2, BAG2}, {2, 2, BAG},
    {1, 3, BAG}, {2, 3, BAG2},
    {3, 5, STEEL2}, {4, 5, STEEL},
    {0, 7, PURP2}, {0, 8, PURP2}, {1, 8, PURP},
    {5, 1, RUST}, {5, 2, RUST},
  }
  for _, s in ipairs(samples) do
    local c, r, col = s[1], s[2], s[3]
    local x = 183 + 25 * c
    local y = 18 + 25 * r
    rect(x, y, 24, 24, col)
    hline(x + 1, x + 22, y + 1, HI)
  end
  hline(183 + 24, 183 + 25 * 2, 18 + 25 * 2 + 12, ENERGY)
  hline(183 + 24, 183 + 25 * 2, 18 + 25 * 2 + 13, ENERGY)
end
rect(249, 11, 17, 5, LINE2); rect(249, 268, 17, 5, LINE2)
for x = 172, 342 do
  local t = ((x + 200) // 3) % 2
  rect(x, 271, 1, 6, t == 0 and ENERGY or INK)
end

-- PIPE
rect(352, 0, 28, 146, PANEL2); rectb(352, 0, 28, 146, LINE)
vline(355, 2, 144, CYAN); vline(376, 2, 144, CYAN)
for i = 0, 2 do
  local by = 20 + i * 36
  rect(358, by, 16, 20, BAG); rectb(358, by, 16, 20, STEEL2)
  hline(360, 372, by + 6, ENERGY)
end
rect(343, 2, 10, 10, STEEL); rectb(343, 2, 10, 10, LINE)

panel(348, 146, 36, 24, PANEL, LINE2)
rect(352, 154, 28, 10, INK)
rect(356, 157, 4, 4, ENERGY); rect(364, 157, 4, 4, ENERGY); rect(372, 157, 4, 4, ENERGY)

panel(346, 174, 40, 48, PANEL, LINE)
rect(350, 190, 32, 18, BAG2); rectb(350, 190, 32, 18, STEEL2)
rect(359, 208, 14, 10, STEEL2); rectb(359, 208, 14, 10, LINE2)

panel(346, 226, 40, 48, PANEL, LINE)
rect(350, 242, 32, 14, PURP)
for i = 0, 8 do put(354 + i * 2, 250, MUTED) end
rect(359, 260, 14, 10, STEEL2); rectb(359, 260, 14, 10, LINE2)
rect(386, 194, 6, 8, STEEL)
for y = 195, 200 do hline(386, 391, y, (y % 2 == 0) and HI or STEEL) end

-- RIGHT
local btns = { {423, 4, 44}, {470, 4, 32}, {505, 4, 32}, {540, 4, 32} }
for _, b in ipairs(btns) do panel(b[1], b[2], b[3], 16, C"#1e3a4a", LINE2) end

panel(392, 24, 180, 146, PANEL, LINE)
rect(400, 32, 164, 122, INK); rectb(400, 32, 164, 122, STEEL2)
for y = 34, 150, 2 do hline(402, 561, y, C"#0e1420") end
rect(410, 48, 100, 6, STEEL2)
rect(410, 62, 140, 4, MUTED)
rect(410, 72, 120, 4, MUTED)
rect(410, 90, 60, 40, BAG2); rectb(410, 90, 60, 40, STEEL2)
rect(480, 90, 70, 8, ENERGY)
rect(480, 104, 50, 8, GREEN)
rect(480, 118, 40, 8, CYAN)
rect(393, 87, 6, 11, STEEL2); rect(565, 87, 6, 11, STEEL2)
for i = 0, 4 do
  local px = 470 + i * 6
  put(px, 158, i == 0 and CYAN or MUTED)
  put(px + 1, 158, i == 0 and CYAN or MUTED)
end

panel(392, 178, 42, 28, PANEL2, LINE)
rect(398, 186, 8, 14, GREEN); rect(410, 186, 8, 14, GREEN); rect(422, 186, 6, 14, GREEN)
panel(437, 178, 135, 28, C"#1e3a4a", LINE2)

for y = 210, 236 do put(450, y, STEEL); put(452, y, RUST); put(520, y, STEEL2) end
for x = 450, 560 do put(x, 228, ((x // 4) % 2 == 0) and ENERGY or INK) end

rect(500, 248, 76, 76, STEEL); rectb(500, 248, 76, 76, LINE)
rect(505, 253, 66, 50, PANEL2)
for i = 0, 3 do
  local cy = 258 + i * 10
  rect(510, cy, 40, 6, RUST); hline(510, 549, cy, ENERGY)
end
do
  local x, y = 500, 270
  for s = 0, 28 do
    rect(x - s * 2, y - s, 12, 8, STEEL2)
    rectb(x - s * 2, y - s, 12, 8, INK)
  end
  rect(440, 240, 10, 10, CYAN); rectb(438, 238, 14, 14, LINE2)
end
panel(516, 290, 48, 24, C"#5a2030", RED)
rect(520, 294, 40, 16, RED)

-- BOTTOM relics
rect(124, 278, 48, 12, PANEL2); rectb(124, 278, 48, 12, LINE)
rect(282, 278, 60, 12, PANEL2); rectb(282, 278, 60, 12, LINE)
panel(120, 288, 154, 36, PANEL, LINE)
panel(278, 288, 154, 36, PANEL, LINE)
local function relic_row(x0)
  rect(x0 + 2, 296, 8, 20, STEEL2)
  rect(x0 + 144, 296, 8, 20, STEEL2)
  for i = 0, 5 do
    local rx = x0 + 12 + i * 22
    rect(rx, 296, 20, 20, PANEL2); rectb(rx, 296, 20, 20, STEEL2)
    if i < 3 then
      rect(rx + 4, 300, 12, 12, i == 0 and CYAN or (i == 1 and ENERGY or GREEN))
    end
  end
end
relic_row(120); relic_row(278)
for i = 0, 2 do hline(290 + i * 22 + 2, 290 + i * 22 + 16, 318, ENERGY) end

for i = 0, 20 do
  for j = 0, 20 - i do
    put(j, i, INK); put(W - 1 - j, i, INK)
  end
end

-- put draft under labels
draft.stackIndex = 1

spr:saveAs(spr.filename)
local nonempty = 0
for y = 0, H - 1 do
  for x = 0, W - 1 do
    if pc.rgbaA(img:getPixel(x, y)) > 0 then nonempty = nonempty + 1 end
  end
end
print("draft nonempty=" .. nonempty)
print("saved " .. spr.filename)
