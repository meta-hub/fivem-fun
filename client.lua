fun.ready = true
fun.active = false

fun.allEnts = {}

fun.setReady = function()
  fun.ready = true
end

fun.toggleActive = function()
  fun.active = not fun.active
end

fun.start = function()
  while not fun.ready do Wait(0); end
  fun.scaleform = fun.getScaleform()
  fun.update()
end

fun.update = function()
  local lastDist = GetGameTimer()
  while true do
    fun.entTracker()
    if GetGameTimer() - lastDist > 100 then
      fun.entDist()
      lastDist = GetGameTimer()
    end
    fun.inputController()   
    fun.effectController() 
    Wait(0)
  end
end

fun.entTracker = function()
  if not fun.entLastTracked then
    fun.entLastTracked = GetGameTimer()
    fun.allEnts = {}
    for ped in EnumeratePeds() do
      table.insert(fun.allEnts,ped)
    end
    for veh in EnumerateVehicles() do
      table.insert(fun.allEnts,veh)
    end
    for obj in EnumerateObjects() do
      table.insert(fun.allEnts,obj)
    end
  else
    if (GetGameTimer() - fun.entLastTracked) > 5000 then
      fun.entLastTracked = GetGameTimer()
      fun.allEnts = {}
      for ped in EnumeratePeds() do
        table.insert(fun.allEnts,ped)
      end
      for veh in EnumerateVehicles() do
        table.insert(fun.allEnts,veh)
      end
      for obj in EnumerateObjects() do
        table.insert(fun.allEnts,obj)
      end
    end
  end
end

fun.entDist = function()
  local delTab
  local closest,closestDist

  if fun.rayHit then
    for key,val in pairs(fun.allEnts) do
      if DoesEntityExist(val) and val ~= GetPlayerPed(-1) and not IsEntityDead(val) and (not fun.mountedTarget or fun.mountedTarget ~= val) then
        local dist = GetVecDist(fun.rayHit, GetEntityCoords(val))
        if (not closestDist or dist < closestDist) and dist > 2.0 then
          closest = val
          closestDist = dist
        end
      else
        if not delTab then delTab = {}; end
        delTab[key] = true
      end
    end
    if closestDist and closestDist < 50.0 then
      fun.targetEnt = closest
    end
  end

  if delTab then 
    for k,v in pairs(delTab) do 
      if fun.allEnts[k] then
        table.remove(fun.allEnts,k)
      end
    end
  end
end

fun.effectController = function()
  if fun.active then
    if fun.selectorActive then
      local start,fin = GetCoordsInFrontOfCam(0,5000)
      local ray = StartShapeTestRay(start.x,start.y,start.z, fin.x,fin.y,fin.z, -1, GetPlayerPed(-1), 5000)
      local r,hit,pos,norm,ent = GetShapeTestResult(ray)

      fun.rayHit = pos

      if ent and ent ~= 0 and DoesEntityExist(ent) then
        local coord = GetEntityCoords(ent)
        if coord and coord.x and coord.x ~= 0 and coord.x ~= 0.0 then
          fun.handleSelector(ent)
        else
          if fun.targetEnt then
            if DoesEntityExist(fun.targetEnt) then
              fun.handleSelector(fun.targetEnt)
            end
          end
        end
      end
    end
  end
end

fun.handleSelector = function(ent)
  ShowHudComponentThisFrame(14)

  local modelE = GetEntityModel(ent)
  local coordsE = GetEntityCoords(ent)
  local minE,maxE = GetModelDimensions(modelE)

  local pos = vector3(coordsE.x,coordsE.y,coordsE.z + maxE.z)

  DrawMarker(0, pos.x,pos.y,pos.z+1.0, 0.0,0.0,0.0, 0.0,0.0,0.0, 0.5,0.5,0.5, 255,0,0,255, false,true, 2, false,false,false,false)    
  DrawText3D(pos.x,pos.y,pos.z+2.0, "[~r~"..modelE.."~s~] [~g~"..(modelE % 0x100000000).."~s~]", 500)  

  if fun.teleportNextFrame then
    fun.teleportNextFrame = false
    fun.teleportOnto(ent,pos,maxE)
  end
end

fun.teleportOnto = function(ent,pos,maxE)
  local plyPed = GetPlayerPed(-1)
  local modelP = GetEntityModel(plyPed)
  local minP,maxP = GetModelDimensions(modelP)
  local attached = IsEntityAttached(plyPed)
  if attached then
    DetachEntity(GetPlayerPed(-1), true, true)
    fun.mountedTarget = false
    Wait(0)
  end

  SetEntityCoordsNoOffset(plyPed, pos.x,pos.y,pos.z + maxP.z)

  if ent and DoesEntityExist(ent) and fun.stickNextTeleport then
    AttachEntityToEntity(plyPed,ent,0, 0.0,0.0,maxE.z + maxP.z, 0.0,0.0,0.0, false,false,false,false,0,true)
    fun.mountedTarget = ent
  end
end

fun.inputController = function()
  if fun.active then
    if not fun.keysFrozen then
      fun.keysFrozen = true
      for k,v in pairs(controls) do
        EnableControlAction(0, v, false)
        DisableControlAction(0, v, true)
      end
    else
      local pressedThisFrame = false
      for k,v in pairs(controls) do
        if not pressedThisFrame and IsControlJustPressed(0, v) or IsDisabledControlJustPressed(0, v) then
          pressedThisFrame = true
          fun.performAction(k)
        end
      end
    end
    DrawScaleformMovieFullscreen(fun.scaleform, 255, 255, 255, 255, 0)
  else
    if fun.keysFrozen then
      fun.keysFrozen = false
      for k,v in pairs(controls) do
        DisableControlAction(0, v, false)
        EnableControlAction(0, v, true)
      end
    end
  end
end

fun.performAction = function(action)
  if action == "SelectorToggle" then
    fun.selectorActive = not fun.selectorActive
    ShowNotification((fun.selectorActive and "~g~" or "~r~").."funSelector "..(fun.selectorActive and "enabled" or "disabled"))
  elseif action == "Teleport" then
    fun.teleportNextFrame = true
  elseif action == "StickyToggle" then
    fun.stickNextTeleport = not fun.stickNextTeleport
    ShowNotification((fun.stickNextTeleport and "~g~" or "~r~").."stickyFeet "..(fun.stickNextTeleport and "enabled" or "disabled"))
  end
end

Citizen.CreateThread(fun.start)

RegisterCommand('fun', fun.toggleActive)

fun.getScaleform = function()
  local scaleform = fun.loadScaleform('instructional_buttons') 
  fun.resetSlots(scaleform)
  fun.setSlot(scaleform,0,"Selector",controls["SelectorToggle"])
  fun.setSlot(scaleform,1,"Teleport",controls["Teleport"])
  fun.setSlot(scaleform,2,"StickyFeet",controls["StickyToggle"])
  fun.scaleformBackground(scaleform,0,0,0,80)

  PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
  PopScaleformMovieFunctionVoid()
  return scaleform
end

fun.loadScaleform = function(sf)
  local scaleform = RequestScaleformMovie(sf)
  while not HasScaleformMovieLoaded(scaleform) do Wait(0); end
  return scaleform
end

fun.resetSlots = function(scaleform)
  PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
  PopScaleformMovieFunctionVoid()

  PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
  PushScaleformMovieFunctionParameterInt(200)
  PopScaleformMovieFunctionVoid()
end

fun.setSlot = function(scaleform,slot,msg,...)
  PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
  PushScaleformMovieFunctionParameterInt(slot)

  for _,control in pairs({...}) do
    ScaleformMovieMethodAddParamPlayerNameString(GetControlInstructionalButton(0, control, true))
  end

  BeginTextCommandScaleformString("STRING")
  AddTextComponentScaleform(msg)
  EndTextCommandScaleformString()

  PopScaleformMovieFunctionVoid() 
end

fun.scaleformBackground = function(scaleform,r,g,b,a)
  PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
  PushScaleformMovieFunctionParameterInt(r)
  PushScaleformMovieFunctionParameterInt(g)
  PushScaleformMovieFunctionParameterInt(b)
  PushScaleformMovieFunctionParameterInt(a)
  PopScaleformMovieFunctionVoid()
end

GetCoordsInFrontOfCam = function(...)

    local unpack   = table.unpack
    local coords,direction    = GetGameplayCamCoord(), RotationToDirection()
    local inTable  = {...}
    local retTable = {}

    if ( #inTable == 0 ) or ( inTable[1] < 0.000001 ) then inTable[1] = 0.000001 ; end

    for k,distance in pairs(inTable) do
        if ( type(distance) == "number" )
        then
            if    ( distance == 0 )
            then
                retTable[k] = coords
            else
                retTable[k] =
                  vector3(
                    coords.x + ( distance*direction.x ),
                    coords.y + ( distance*direction.y ),
                    coords.z + ( distance*direction.z )
                  )
            end
        end
    end

    return unpack(retTable)
end


RotationToDirection = function(rot)

  if     ( rot == nil ) then rot = GetGameplayCamRot(2);  end
  local  rotZ = rot.z  * ( 3.141593 / 180.0 )
  local  rotX = rot.x  * ( 3.141593 / 180.0 )
  local  c = math.cos(rotX);
  local  multXY = math.abs(c)
  local  res = vector3( ( math.sin(rotZ) * -1 )*multXY, math.cos(rotZ)*multXY, math.sin(rotX) )
  return res

end

local entityEnumerator = {
  __gc = function(enum)
    if enum.destructor and enum.handle then
      enum.destructor(enum.handle)
    end
    enum.destructor = nil
    enum.handle = nil
  end
}

EnumerateEntities = function(initFunc, moveFunc, disposeFunc)
  return coroutine.wrap(function()
    local iter, id = initFunc()
    if not id or id == 0 then
      disposeFunc(iter)
      return
    end
    
    local enum = {handle = iter, destructor = disposeFunc}
    setmetatable(enum, entityEnumerator)
    
    local next = true
    repeat
      coroutine.yield(id)
      next, id = moveFunc(iter)
    until not next
    
    enum.destructor, enum.handle = nil, nil
    disposeFunc(iter)
  end)
end

EnumerateObjects = function()
  return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

EnumeratePeds = function()
  return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end

EnumerateVehicles = function()
  return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

EnumeratePickups = function()
  return EnumerateEntities(FindFirstPickup, FindNextPickup, EndFindPickup)
end

GetVecDist = function(v1,v2)
  if not v1 or not v2 or not v1.x or not v2.x then return 0; end
  return math.sqrt(  ( (v1.x or 0) - (v2.x or 0) )*(  (v1.x or 0) - (v2.x or 0) )+( (v1.y or 0) - (v2.y or 0) )*( (v1.y or 0) - (v2.y or 0) )+( (v1.z or 0) - (v2.z or 0) )*( (v1.z or 0) - (v2.z or 0) )  )
end

ShowNotification = function(msg)
  AddTextEntry('showNotify', msg)
  SetNotificationTextEntry('showNotify')
  DrawNotification(false, true)
end

ShowAdvancedNotification = function(title, subject, msg, icon, iconType)
  AddTextEntry('showAdvNotify', msg)
  SetNotificationTextEntry('showAdvNotify')
  SetNotificationMessage(icon, icon, false, iconType, title, subject)
  DrawNotification(false, false)
end

ShowHelpNotification = function(msg)
  AddTextEntry('showHelp', msg)
  BeginTextCommandDisplayHelp('showHelp')
  EndTextCommandDisplayHelp(0, false, true, -1)
end

DrawText3D = function(x,y,z, text, scale)
  local onScreen,_x,_y = World3dToScreen2d(x,y,z)
  local px,py,pz = table.unpack(GetGameplayCamCoord())
  local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)
  local scale = ((1/dist)*2)*(1/GetGameplayCamFov())*(scale or 100)

  if onScreen then
    SetTextColour(220, 220, 220, 255)
    SetTextScale(0.0*scale, 0.40*scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextCentre(true)

    SetTextEntry("STRING")
    AddTextComponentString(text)
    EndTextCommandDisplayText(_x, _y)
  end
end