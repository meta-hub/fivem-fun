local drawMario = false

local mario = {
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,3,3,3,3,3,1,1,1,2,2,1,
  1,1,1,1,3,3,3,3,3,3,3,3,3,2,2,1,
  1,1,1,1,5,5,5,2,2,6,2,1,1,3,3,1,
  1,1,1,5,2,5,2,2,2,6,2,2,2,3,3,1,
  1,1,1,5,2,5,5,2,2,2,6,2,2,2,3,1,
  1,1,1,5,5,2,2,2,2,6,6,6,6,3,3,1,
  1,1,1,1,1,2,2,2,2,2,2,2,3,3,1,1,
  1,2,2,2,3,3,4,3,3,3,4,3,3,1,1,1,
  1,2,2,2,3,3,3,4,3,3,3,4,1,1,5,1,
  1,1,2,1,1,3,3,4,4,4,4,7,4,5,5,1,
  1,1,1,1,1,4,4,4,7,4,4,4,4,5,5,1,
  1,1,1,5,5,4,4,4,4,4,4,4,4,5,5,1,
  1,1,5,5,5,4,4,4,4,4,4,4,1,1,1,1,
  1,1,5,5,1,1,1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
}
local cols = {
  [1] = {r = 255, g = 255, b = 255, a = 000},
  [2] = {r = 244, g = 192, b = 128, a = 255},
  [3] = {r = 255, g = 000, b = 000, a = 255},
  [4] = {r = 000, g = 000, b = 255, a = 255},
  [5] = {r = 096, g = 032, b = 000, a = 255},
  [6] = {r = 000, g = 000, b = 000, a = 255},
  [7] = {r = 255, g = 255, b = 000, a = 255},
}

local DrawBits = function(x,y,z, bits,len)
  local height = 0
  local width = 0
  for key,val in pairs(bits) do
    local position = vector3(x,y+width,z+height)
    local col = cols[val]
    DrawBox(position.x+0.5,position.y+0.5,position.z+0.5, position.x-0.5,position.y-0.5,position.z-0.5, col.r,col.g,col.b,col.a)
    width = width + 1
    if width > len then
      width = 0
      height = height - 1
    end
  end
end

local ToggleMario = function()
  drawMario = not drawMario
  if drawMario then
    local plyPed = GetPlayerPed(-1)
    local plyPos = GetEntityCoords(plyPed)
    local plyFwd = GetEntityForwardVector(plyPed)
    local newPos = plyPos + (plyFwd * 20)
    while drawMario do
      DrawBits(newPos.x,newPos.y,newPos.z + 20.0, mario, 15)
      Wait(0)
    end
  end
end

RegisterCommand('drawmario', ToggleMario)
