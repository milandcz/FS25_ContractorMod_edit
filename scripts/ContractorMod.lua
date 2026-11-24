ContractorMod = {}
ContractorMod.debug = false --true --
ContractorMod.MAX_WORKERS = 10
ContractorMod.MIN_WORKERS = 1

-- KO: Driver exists with passenger
local modDirectory = g_currentModDirectory
local modSettingsDir = g_modSettingsDirectory
local ContractorMod_mt = Class(ContractorMod)

function ContractorMod:new(mission, i18n, inputBinding, gui, soundManager, modDirectory, modName)
    --print("ContractorMod:new")
    local self = setmetatable({}, ContractorMod_mt)

    self.isServer = mission:getIsServer()
    self.isClient = mission:getIsClient()
    self.modDirectory = modDirectory
    self.modName = modName

    return self
end

function ContractorMod:delete()
    --print("ContractorMod:delete")

end
-- Create multiple players and add them to the PlayerSystem
--local player1 = Player.new(...)
--local player2 = Player.new(...)
--g_playerSystem:addPlayer(player1)
--g_playerSystem:addPlayer(player2)


-- Switch control
-- g_playerSystem:setLocalPlayer(player2) -- Now you control player2

---Called when the player clicks the Start button
function ContractorMod:onMissionStart(mission)
    print("ContractorMod:onMissionStart")

    self:init()
end

function ContractorMod:init()
  if ContractorMod.debug then print("ContractorMod:init()") end
    ContractorMod.currentID = 1
    ContractorMod.numWorkers = 2
    ContractorMod.workers = {}
    ContractorMod.shouldStopWorker = true
    ContractorMod.switching = false 
    ContractorMod.displayPlayerNames = true
    ContractorMod.enablePassenger = false
    ContractorMod.registeredActivatables = {}

    self:registerXmlSchema()

    local savegameDir
    if g_currentMission.missionInfo.savegameDirectory then
      savegameDir = g_currentMission.missionInfo.savegameDirectory
    end
    if not savegameDir and g_careerScreen.currentSavegame and g_careerScreen.currentSavegame.savegameIndex then
      savegameDir = ('%ssavegame%d'):format(getUserProfileAppPath(), g_careerScreen.currentSavegame.savegameIndex)
    end
    if not savegameDir and g_currentMission.missionInfo.savegameIndex ~= nil then
      savegameDir = ('%ssavegame%d'):format(getUserProfileAppPath(), g_careerScreen.missionInfo.savegameIndex)
    end
    ContractorMod.savegameFolderPath = savegameDir
    ContractorMod.ContractorModXmlFilePath = ContractorMod.savegameFolderPath .. '/ContractorMod.xml'

    -- Try to load from savegame, else create default workers
    if not self:initFromSave() then
      if not self:initFromParameters() then
        table.insert(ContractorMod.workers, ContractorModWorker:new("Alex", 1, g_localPlayer.graphicsComponent:getStyle()))
        local brendaStyle = g_helperManager:getRandomHelperStyle()
        while brendaStyle:getIsMale() do
            brendaStyle = g_helperManager:getRandomHelperStyle()
        end
        table.insert(ContractorMod.workers, ContractorModWorker:new("Brenda", 2, brendaStyle))
        table.insert(ContractorMod.workers, ContractorModWorker:new("Chris", 3, g_helperManager:getRandomHelperStyle()))
        local davidStyle = g_helperManager:getRandomHelperStyle()
        while davidStyle:getIsMale() == false do
            davidStyle = g_helperManager:getRandomHelperStyle()
        end
        table.insert(ContractorMod.workers, ContractorModWorker:new("David", 4, davidStyle))
        local edStyle = g_helperManager:getRandomHelperStyle()
        while edStyle:getIsMale() == false do
            edStyle = g_helperManager:getRandomHelperStyle()
        end
        table.insert(ContractorMod.workers, ContractorModWorker:new("Ed", 5, edStyle))
        local franckStyle = g_helperManager:getRandomHelperStyle()
        while franckStyle:getIsMale() == false do
            franckStyle = g_helperManager:getRandomHelperStyle()
        end
        table.insert(ContractorMod.workers, ContractorModWorker:new("Franck", 6, franckStyle))
        local garyStyle = g_helperManager:getRandomHelperStyle()
        while garyStyle:getIsMale() == false do
            garyStyle = g_helperManager:getRandomHelperStyle()
        end
        table.insert(ContractorMod.workers, ContractorModWorker:new("Gary", 7, garyStyle))
        local henryStyle = g_helperManager:getRandomHelperStyle()
        while henryStyle:getIsMale() == false do
            henryStyle = g_helperManager:getRandomHelperStyle()
        end
        table.insert(ContractorMod.workers, ContractorModWorker:new("Henry", 8, henryStyle))
        ContractorMod.numWorkers = #ContractorMod.workers
        ContractorMod.displaySettings = {
            characterName = {
                x = 0.9828,
                y = 0.90,
                size = 0.024
            }
        }
      end
    end
    g_currentMission.nickname = ContractorMod.workers[ContractorMod.currentID].name
end

-- ===== ACCESSOR FUNCTIONS =====
-- These return live state for the active worker and stored state for others

-- Get current vehicle for a worker (live for active, stored for inactive)
function ContractorMod:getWorkerVehicle(worker)
  if worker.index == ContractorMod.currentID and g_localPlayer ~= nil then
    return g_localPlayer:getCurrentVehicle()
  end
  return worker.currentVehicle
end

-- Get position of a worker (live for active, stored for inactive)
function ContractorMod:getWorkerPosition(worker)
  if worker.index == ContractorMod.currentID and g_localPlayer ~= nil then
    return g_localPlayer:getPosition()
  end
  return worker.x, worker.y, worker.z
end

-- Get yaw (rotation) of a worker (live for active, stored for inactive)
function ContractorMod:getWorkerYaw(worker)
  if worker.index == ContractorMod.currentID and g_localPlayer ~= nil then
    return g_localPlayer:getGraphicalYaw()
  end
  return worker.yaw
end

-- Get seat in vehicle for a worker (live for active, stored for inactive)
function ContractorMod:getWorkerSeat(worker)
  if worker.index == ContractorMod.currentID and g_localPlayer ~= nil then
    local vehicle = g_localPlayer:getCurrentVehicle()
    if vehicle and vehicle.spec_enterable then
      return worker.currentSeat
    end
  end
  return worker.currentSeat
end

function ContractorMod:getWorkerFromNPC(npc)
  if ContractorMod.debug then print("ContractorMod:getWorkerFromNPC()") end
  if npc ~= nil then
    if ContractorMod.workers ~= nil then
      for _, worker in pairs(ContractorMod.workers) do
        if worker.npc == npc then
          return worker
        end
      end
    end
    if npc.name ~= nil and string.sub(npc.name, 1, 6) == "HELPER" and string.len(npc.name) > 6 then
      local workerId = tonumber(string.sub(npc.name, 7))
      if workerId ~= nil then
        local worker = ContractorMod.workers[workerId]
        if worker ~= nil then
            return worker
        else
            if ContractorMod.debug then print("Worker not found for id "..tostring(workerId)) end
        end
      else
        if ContractorMod.debug then print("Invalid worker id in npc name "..npc.name) end
      end
    else
      if ContractorMod.debug then print("Not a worker npc "..npc.name) end
    end
  end
end
-- ===== END ACCESSORS =====

function ContractorMod:initFromSave()
  if ContractorMod.debug then print("ContractorMod:initFromSave()") end
  -- Copy ContractorMod.xml from zip to modSettings dir
  ContractorMod:CopyContractorModXML()
  -- Minimal: load worker name, position, style from XML
  if ContractorMod.savegameFolderPath and ContractorMod.ContractorModXmlFilePath then
    createFolder(ContractorMod.savegameFolderPath)
    local xml
    if fileExists(ContractorMod.ContractorModXmlFilePath) then
      xml = XMLFile.load('ContractorMod', ContractorMod.ContractorModXmlFilePath, ContractorMod.xmlSchema)
    else
      xml = XMLFile.create('ContractorMod', ContractorMod.ContractorModXmlFilePath, 'ContractorMod', ContractorMod.xmlSchema)
      xml:save()
      xml:delete()
      return false
    end
    local num = math.min(xml:getInt("ContractorMod.workers#numWorkers") or 0, ContractorMod.MAX_WORKERS)
    for i = 1, num do
        local key = string.format("ContractorMod.workers.worker(%d)", i-1)
        local name = xml:getString(key.."#name")
        local pos = xml:getString(key.."#position")
        local yaw = xml:getString(key.."#yaw")
        local style = PlayerStyle.new()
        style:loadFromXMLFile(xml, key..".style")
        local worker = ContractorModWorker:new(name, i, style)
        if ContractorMod.debug then print(pos) end
        local posVector = string.getVector(pos)
        if ContractorMod.debug then print("posVector "..tostring(posVector)) end
        local rotVector = string.getVector(rot)
        worker.x = posVector[1]
        worker.y = posVector[2]
        worker.z = posVector[3]
        worker.yaw = tonumber(yaw) or 0.0
        local vehicleID = xml:getString(key.."#vehicleID")
        if vehicleID ~= "0" then
          if ContractorMod.mapVehicleLoad ~= nil then
            -- map savegame vehicle id and network id
            local saveId = ContractorMod.mapVehicleLoad[vehicleID]
            local vehicle = NetworkUtil.getObject(tonumber(saveId))
            if vehicle ~= nil then
              if ContractorMod.debug then print("ContractorMod: vehicle not nil") end
              worker.currentVehicle = vehicle
              local currentSeat = xml:getString(key.."#currentSeat")
              if currentSeat ~= nil then
                worker.currentSeat = tonumber(currentSeat)
              end
            end
          end
        end
        table.insert(ContractorMod.workers, worker)
    end
    xmlKey = "ContractorMod.displaySettings.characterName"
    ContractorMod.displaySettings = {}
    ContractorMod.displaySettings.characterName = {}
    local x = xml:getFloat(xmlKey .. string.format("#x"))
    if x == nil then
      x = 0.9828
    end
    ContractorMod.displaySettings.characterName.x = x
    local y = xml:getFloat(xmlKey .. string.format("#y"))
    if y == nil then
      y = 0.90
    end
    ContractorMod.displaySettings.characterName.y = y
    local size = xml:getFloat(xmlKey .. string.format("#size"))
    if size == nil then
      size = 0.024
    end
    ContractorMod.displaySettings.characterName.size = size
    xmlKey = "ContractorMod.displaySettings.playerName"
    ContractorMod.displayPlayerNames = Utils.getNoNil(xml:getBool(xmlKey .. string.format("#displayPlayerNames")), true)
    ContractorMod.enablePassenger = Utils.getNoNil(xml:getBool("ContractorMod.workers#enablePassenger"), false)
    ContractorMod.numWorkers = #ContractorMod.workers
    xml:delete()
    return ContractorMod.numWorkers > 0
  end
end

function ContractorMod:initFromParameters()
  if ContractorMod.debug then print("ContractorMod:initFromParameters()") end
  -- Copy ContractorMod.xml from zip to modSettings dir
  ContractorMod:CopyContractorModXML()
  if modSettingsDir then
    local xmlFilePath = modSettingsDir .. "/ContractorMod.xml"
    local xmlFile;
    if fileExists(xmlFilePath) then
      xml = XMLFile.load('ContractorMod', xmlFilePath, ContractorMod.xmlSchema)
    else
      return false
    end
    local num = math.min(xml:getInt("ContractorMod.workers#numWorkers") or 0, ContractorMod.MAX_WORKERS)
    for i = 1, num do
      local key = string.format("ContractorMod.workers.worker(%d)", i-1)
      local name = xml:getString(key.."#name")
      -- local pos = xml:getString(key.."#position")
      -- local yaw = xml:getString(key.."#yaw")
      local style = PlayerStyle.new()
      style:loadFromXMLFile(xml, key..".style")
      local worker = ContractorModWorker:new(name, i, style)
      if ContractorMod.debug then print(pos) end
      -- local posVector = string.getVector(pos)
      -- if ContractorMod.debug then print("posVector "..tostring(posVector)) end
      -- local rotVector = string.getVector(rot)
      -- worker.x = posVector[1]
      -- worker.y = posVector[2]
      -- worker.z = posVector[3]
      -- worker.yaw = tonumber(yaw) or 0.0
      table.insert(ContractorMod.workers, worker)
    end
    xmlKey = "ContractorMod.displaySettings.characterName"
    ContractorMod.displaySettings = {}
    ContractorMod.displaySettings.characterName = {}
    local x = xml:getFloat(xmlKey .. string.format("#x"))
    if x == nil then
      x = 0.9828
    end
    ContractorMod.displaySettings.characterName.x = x
    local y = xml:getFloat(xmlKey .. string.format("#y"))
    if y == nil then
      y = 0.90
    end
    ContractorMod.displaySettings.characterName.y = y
    local size = xml:getFloat(xmlKey .. string.format("#size"))
    if size == nil then
      size = 0.024
    end
    ContractorMod.displaySettings.characterName.size = size
    xmlKey = "ContractorMod.displaySettings.playerName"
    ContractorMod.displayPlayerNames = Utils.getNoNil(xml:getBool(xmlKey .. string.format("#displayPlayerNames")), true)
    ContractorMod.enablePassenger = Utils.getNoNil(xml:getBool("ContractorMod.workers#enablePassenger"), false)
    ContractorMod.numWorkers = #ContractorMod.workers
    xml:delete()
    return ContractorMod.numWorkers > 0
  end
  return false
end

-- @doc Copy default parameters from mod mod zip file to mods directory so end-user can edit it
function ContractorMod:CopyContractorModXML()
  if ContractorMod.debug then print("ContractorMod:CopyContractorModXML") end
  if g_currentMission ~= nil and g_currentMission:getIsServer() then
    if modSettingsDir then
      local xmlFilePath = modSettingsDir.."/ContractorMod.xml"
      if ContractorMod.debug then print("ContractorMod:CopyContractorModXML_1") end
      local xmlFile
      if not fileExists(xmlFilePath) and modDirectory then
        if ContractorMod.debug then print("ContractorMod:CopyContractorModXML_2") end
        local xmlSourceFilePath = modDirectory .. "/ContractorMod.xml"
        local xmlSourceFile
        if fileExists(xmlSourceFilePath) then
          if ContractorMod.debug then print("ContractorMod:CopyContractorModXML_3") end
          xmlSourceFile = loadXMLFile('ContractorMod', xmlSourceFilePath)
          createFolder(modSettingsDir)
          saveXMLFileTo(xmlSourceFile, xmlFilePath)
          if ContractorMod.debug then print("ContractorMod:CopyContractorModXML_4") end
        end
      end
    end
  end
end

function ContractorMod:registerXmlSchema()
  if ContractorMod.debug then print("ContractorMod:registerXMLPaths ") end
  ContractorMod.xmlSchema = XMLSchema.new("ContractorMod")
  ContractorMod.xmlSchema:register(XMLValueType.STRING, "ContractorMod.workers#numWorkers", "Number of workers", nil, true)
  ContractorMod.xmlSchema:register(XMLValueType.STRING, "ContractorMod.workers#enablePassenger", "Ability to enter vehicles as passenger", nil, false)
  ContractorMod.xmlSchema:register(XMLValueType.STRING, "ContractorMod.workers.worker(?)#name", "Name of worker", nil, true)
  ContractorMod.xmlSchema:register(XMLValueType.STRING, "ContractorMod.workers.worker(?)#yaw", "Rotation (yaw) of worker", nil, true)
  ContractorMod.xmlSchema:register(XMLValueType.STRING, "ContractorMod.workers.worker(?)#vehicleID", "ID of vehicle if any", nil, true)
  PlayerStyle.registerSavegameXMLPaths(ContractorMod.xmlSchema, "ContractorMod.workers.worker(?).style")
end

function ContractorMod:onSwitchWorker(action)
  if ContractorMod.debug then print("ContractorMod:onSwitchWorker()") end
  ContractorMod.switching = true
  local canSwitch = false
  local currentID = ContractorMod.currentID
  if action == "SWITCH_VEHICLE" then
    if ContractorMod.debug then print('ContractorMod_NEXTWORKER pressed') end
    local nextID = 0
    if ContractorMod.debug then print("ContractorMod: ContractorMod.currentID " .. tostring(ContractorMod.currentID)) end
    repeat
      if currentID < ContractorMod.numWorkers then
        nextID = currentID + 1
      else
        nextID = 1
      end
      if ContractorMod.debug then print("ContractorMod: nextID " .. tostring(nextID)) end
      canSwitch = self:setCurrentContractorModWorker(nextID)
      if canSwitch == false then
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, g_i18n:getText("ContractorMod_WORKER_INACTIVE") .. " (" .. ContractorMod.workers[nextID].name .. ")")
      end
      currentID = nextID
    until canSwitch or nextID == ContractorMod.currentID
  elseif action == "SWITCH_VEHICLE_BACK" then
    if ContractorMod.debug then print('ContractorMod_PREVWORKER pressed') end
    local prevID = 0
    repeat
      if currentID > 1 then
        prevID = currentID - 1
      else
        prevID = ContractorMod.numWorkers
      end    
      canSwitch = self:setCurrentContractorModWorker(prevID)
      if canSwitch == false then
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, g_i18n:getText("ContractorMod_WORKER_INACTIVE") .. " (" .. ContractorMod.workers[prevID].name .. ")")
      end
      currentID = prevID
    until canSwitch or prevID == ContractorMod.currentID
  end
end

-- @doc Switch directly to another worker
function ContractorMod:activateWorker(actionName, keyStatus)
	if ContractorMod.debug then print("ContractorMod:activateWorker") end
  if ContractorMod.debug then print("actionName "..tostring(actionName)) end
  if string.sub(actionName, 1, 20) == "ContractorMod_WORKER" then
    local workerIndex = tonumber(string.sub(actionName, 21))
    if workerIndex ~= nil and ContractorMod.numWorkers >= workerIndex and workerIndex ~= ContractorMod.currentID then
      if self:setCurrentContractorModWorker(workerIndex) == false then
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("ContractorMod_WORKER_INACTIVE") .. " (" .. ContractorMod.workers[workerIndex].name .. ")")
      end
    end
  end
end

function ContractorMod:resetOutOfRangeActivatables(maxDistance)
  if ContractorMod.debug then print("ContractorMod:resetOutOfRangeActivatables()") end
  local activatableObjectsSystem = g_currentMission and g_currentMission.activatableObjectsSystem
  if activatableObjectsSystem == nil or ContractorMod.registeredActivatables == nil or g_localPlayer == nil then
    return
  end
  local entryMaxDistance = 10
  local triggerRegisterMaxDistance = 15
  local x, y, z = g_localPlayer:getPosition()
  for activatable, entry in pairs(ContractorMod.registeredActivatables) do
    if activatable ~= nil then
      local nodeDistance = nil
      if activatable.getDistance ~= nil then
        local success, distance = pcall(activatable.getDistance, activatable, x, y, z)
        if success and type(distance) == "number" and distance > 0 then
          nodeDistance = distance
        end
      end
      local range = maxDistance
      if type(entry) == "table" and entry.distance ~= nil and entry.distance <= triggerRegisterMaxDistance then
        range = entryMaxDistance
      end
      local outOfRange = false
      if nodeDistance ~= nil then
        outOfRange = nodeDistance > range
      elseif type(entry) == "table" and entry.x ~= nil then
        outOfRange = MathUtil.vector3Length(x - entry.x, y - entry.y, z - entry.z) > entryMaxDistance
      end
      if outOfRange then
        activatableObjectsSystem:removeActivatable(activatable)
      end
    end
  end
end

-- @doc Change active worker
function ContractorMod:setCurrentContractorModWorker(setID)
  if ContractorMod.debug then print("ContractorMod:setCurrentContractorModWorker(setID) " .. tostring(setID) .. " - " .. tostring(ContractorMod.currentID)) end
  if ContractorMod.workers[setID].active == false then
    return false
  end
  local currentWorker = ContractorMod.workers[ContractorMod.currentID]
  if currentWorker ~= nil then
    ContractorMod.shouldStopWorker = false
    ContractorMod.switching = true
    currentWorker:beforeSwitch()
  end
  ContractorMod.currentID = setID
  currentWorker = ContractorMod.workers[ContractorMod.currentID]
  if currentWorker ~= nil then
    currentWorker:afterSwitch()
    if ContractorMod.resetOutOfRangeActivatables ~= nil then
      ContractorMod:resetOutOfRangeActivatables(50)
    end
    ContractorMod.shouldStopWorker = true
    ContractorMod.switching = false
  end
  return true
  --DebugUtil.printTableRecursively(ContractorMod.workers, " ", 1, 3)
end

-- @doc Draw worker name and hotspots on map
function ContractorMod:draw()
  --if ContractorModWorker.debug then print("ContractorMod:draw()") end
  --Display current worker name
  if ContractorMod.workers ~= nil then
    if #ContractorMod.workers > 0 and g_currentMission.hud.isVisible then
      local currentWorker = ContractorMod.workers[ContractorMod.currentID]
      if currentWorker ~= nil then
        --Display current worker name
        currentWorker:displayName(self)
      end
    end
  end
end

function ContractorMod:update(dt)
  if ContractorMod.workers ~= nil then
    if #ContractorMod.workers > 0 then
      local currentWorker = ContractorMod.workers[ContractorMod.currentID]
      if currentWorker ~= nil then
        currentWorker.display_x, currentWorker.display_y, currentWorker.display_z = g_localPlayer:getPosition()
      end
    end
  end
end

function ContractorMod:isControlledByWorker(vehicle)
  -- if ContractorMod.debug then print("ContractorMod:isControlledByWorker()") end
  if ContractorMod.workers ~= nil then
    for _, worker in pairs(ContractorMod.workers) do
      local currentVehicle = ContractorMod:getWorkerVehicle(worker)
      local seat = ContractorMod:getWorkerSeat(worker)
      -- local name = nil
      -- if currentVehicle ~= nil then
      --   name = currentVehicle.getName and currentVehicle:getName() or tostring(currentVehicle)
      -- else
      --   name = "nil"    
      -- end
      -- print("Worker "..worker.name.." currentVehicle "..name.." seat "..tostring(seat))
      if currentVehicle ~= nil and vehicle ~= nil and currentVehicle == vehicle and seat == nil then
        -- A worker is driving this vehicle
        -- printCallstack()
        -- print("Worker "..worker.name.." is already driving ".. (currentVehicle.getName and currentVehicle:getName() or tostring(currentVehicle)))
        return true
      end
    end
  end
  return false
end

function ContractorMod:getFirstFreeSeat(vehicle)
  local spec = vehicle.spec_enterablePassenger
  if not spec or not spec.passengerSeats then
    -- print("Vehicle "..(vehicle.getName and vehicle:getName() or tostring(vehicle)).." does not have passenger seats")
    return 0
  end
  
  local totalSeats = #spec.passengerSeats
  local occupiedSeats = {}

  -- Collect which seat indices are occupied
  for _, worker in pairs(ContractorMod.workers) do
    local currentVehicle = ContractorMod:getWorkerVehicle(worker)
    if currentVehicle == vehicle and worker.currentSeat ~= nil then
      occupiedSeats[worker.currentSeat] = true
    end
  end
  -- print("Vehicle "..(vehicle.getName and vehicle:getName() or tostring(vehicle)))
  -- Find first available seat
  for seatIndex = 1, totalSeats do
    if not occupiedSeats[seatIndex] then
      -- print("First free seat index: " .. seatIndex)
      -- printCallstack()
      return seatIndex
    end
  end
  -- print("No free seats available")
  -- printCallstack()
  -- No seats available
  return 0
end

function ContractorMod:hasDriver(vehicle)
  local hasDriver = false
  if vehicle ~= nil then
    for _, worker in pairs(ContractorMod.workers) do
      local currentVehicle = ContractorMod:getWorkerVehicle(worker)
      if currentVehicle ~= nil and currentVehicle == vehicle and worker.currentSeat == nil then
        -- Driver found for this vehicle
        hasDriver = true
        break
      end
    end
  end
  return hasDriver
end

function ContractorMod:manageSellConfigVehicle(vehicle)
    if ContractorMod.debug then print("ContractorMod:manageSellConfigVehicle()") end
    for _, worker in pairs(ContractorMod.workers) do
        local currentVehicle = ContractorMod:getWorkerVehicle(worker)
        if currentVehicle ~= nil and vehicle ~= nil and currentVehicle == vehicle then
            worker.currentVehicle = nil
            worker.currentSeat = nil
            if vehicle ~= nil then
                if vehicle.getExitNode == nil then
                    return
                else
                    local exitPoint = vehicle:getExitNode(g_localPlayer)
                    local x, y, z = getWorldTranslation(exitPoint)
                    local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
                    local raycastLength = 2
                    local _, _, colY, _ = RaycastUtil.raycastClosest(x, terrainHeight + 2, z, 0, -1, 0, 2, CollisionFlag.STATIC_OBJECT + CollisionFlag.ROAD)
                    colY = colY or terrainHeight
                    y = math.max(colY + 0.1, y)
                    y = math.max(y, vehicle.waterY)
                    worker.x = x
                    worker.y = y
                    worker.z = z
                    local exitDirectionX, _, exitDirectionZ = localDirectionToWorld(exitPoint, 0, 0, 1)
                    local exitYaw = MathUtil.getYRotationFromDirection(exitDirectionX, exitDirectionZ)
                    worker.yaw = exitYaw
                    if worker.index ~= ContractorMod.currentID then
                        local spot = NPCSpot.create(tostring(g_time), worker.npc, worker.x, worker.y, worker.z, 0, 0, 0, false)
                        spot:activate()
                        spot.isAvailable = true
                        g_npcManager:addSpot(spot)
                        worker.npc:setSpot(spot)
                        worker:setYawInstant(exitYaw)
                    end
                end
            end
        end
    end
end


function ContractorMod:notify(text, critical)
  if g_currentMission ~= nil then
    if critical then
      g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, text)
    else
      g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, text)
    end
  end
end

function ContractorMod:getFreeNPCIndex()
  local maxWorkers = ContractorMod.MAX_WORKERS or 10
  if ContractorMod.workers ~= nil and g_npcManager ~= nil then
    local used = {}
    for _, worker in pairs(ContractorMod.workers) do
      if worker.npc ~= nil and worker.npc.name ~= nil then
        used[worker.npc.name] = true
      end
    end
    for i = 1, maxWorkers do
      local npc = g_npcManager:getNPCByName("HELPER" .. i)
      if npc ~= nil and not used[npc.name] then
        return i
      end
    end
  end
  return nil
end

function ContractorMod:addWorker()
  if ContractorMod.workers == nil or #ContractorMod.workers >= ContractorMod.MAX_WORKERS or ContractorMod:getFreeNPCIndex() == nil then
    ContractorMod:notify(string.format(g_i18n:getText("ContractorMod_MAX_WORKERS"), ContractorMod.MAX_WORKERS))
    return nil
  end
  local index = #ContractorMod.workers + 1
  local name = string.format(g_i18n:getText("ContractorMod_WORKER"), index)
  local workerStyle = g_helperManager:getRandomHelperStyle()
  local worker = ContractorModWorker:new(name, index, workerStyle)
  if worker.npc == nil then
    ContractorMod:notify(string.format(g_i18n:getText("ContractorMod_MAX_WORKERS"), ContractorMod.MAX_WORKERS), true)
    return nil
  end
  table.insert(ContractorMod.workers, worker)
  ContractorMod.numWorkers = #ContractorMod.workers
  local activeWorker = ContractorMod.workers[ContractorMod.currentID]
  local ax, ay, az = ContractorMod:getWorkerPosition(activeWorker)
  local ayaw = ContractorMod:getWorkerYaw(activeWorker)
  local activeVehicle = ContractorMod:getWorkerVehicle(activeWorker)
  local x, y, z = ax, ay, az
  if activeVehicle ~= nil and activeVehicle.rootNode ~= nil then
    local vx, _, vz = getWorldTranslation(activeVehicle.rootNode)
    local rx, _, rz = localDirectionToWorld(activeVehicle.rootNode, 1, 0, 0)
    local fx, _, fz = localDirectionToWorld(activeVehicle.rootNode, 0, 0, 1)
    x = vx + rx * 7 + fx * 3
    z = vz + rz * 7 + fz * 3
  else
    x = x + 2
    z = z + 1
  end
  local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
  local _, _, colY, _ = RaycastUtil.raycastClosest(x, terrainHeight + 2, z, 0, -1, 0, 2, CollisionFlag.STATIC_OBJECT + CollisionFlag.ROAD)
  y = (colY or terrainHeight) + 0.1
  worker.x, worker.y, worker.z = x, y, z
  worker.yaw = ayaw or 0.0
  local spot = NPCSpot.create(tostring(g_time), worker.npc, worker.x, worker.y, worker.z, 0, 0, 0, false)
  spot:activate()
  spot.isAvailable = true
  g_npcManager:addSpot(spot)
  worker.npc:setSpot(spot)
  worker:setYawInstant(worker.yaw)
  ContractorMod:notify(string.format(g_i18n:getText("ContractorMod_WORKER_HIRED"), worker.name))
  return worker
end

function ContractorMod:removeWorker(index)
  index = tonumber(index)
  if ContractorMod.workers == nil or index == nil then
    return false
  end
  local worker = ContractorMod.workers[index]
  if worker == nil then
    return false
  end
  if #ContractorMod.workers <= ContractorMod.MIN_WORKERS then
    ContractorMod:notify(g_i18n:getText("ContractorMod_MIN_WORKERS"))
    return false
  end
  if ContractorMod:getWorkerVehicle(worker) ~= nil then
    ContractorMod:notify(string.format(g_i18n:getText("ContractorMod_WORKER_IN_VEHICLE"), worker.name))
    return false
  end
  if index == ContractorMod.currentID then
    local target = nil
    for i = 1, #ContractorMod.workers do
      if i ~= index and ContractorMod.workers[i] ~= nil and ContractorMod.workers[i].active then
        target = i
        break
      end
    end
    if target == nil or ContractorMod:setCurrentContractorModWorker(target) == false then
      ContractorMod:notify(g_i18n:getText("ContractorMod_SWITCH_FIRST"), true)
      return false
    end
  end
  if worker.npc ~= nil then
    local spot = worker.npc:getSpot()
    if spot ~= nil then
      worker.npc:setSpot(nil)
      g_npcManager:removeSpot(spot)
    end
    if g_currentMission ~= nil and g_currentMission.activatableObjectsSystem ~= nil and worker.npc.activatable ~= nil then
      g_currentMission.activatableObjectsSystem:removeActivatable(worker.npc.activatable)
    end
    worker.npc.x = 0
    worker.npc.y = -200
    worker.npc.z = 0
    worker.npc.isActive = false
    worker.npc:updateVisibility()
  end
  local name = worker.name
  table.remove(ContractorMod.workers, index)
  for i = index, #ContractorMod.workers do
    ContractorMod.workers[i].index = i
  end
  ContractorMod.numWorkers = #ContractorMod.workers
  if ContractorMod.currentID > index then
    ContractorMod.currentID = ContractorMod.currentID - 1
  end
  ContractorMod:notify(string.format(g_i18n:getText("ContractorMod_WORKER_FIRED"), name))
  return true
end

function ContractorMod:setWorkerName(worker, name)
  if worker == nil or type(name) ~= "string" or name == "" then
    return
  end
  worker.name = name
  if worker.npc ~= nil then
    worker.npc.title = name
  end
  if worker.index == ContractorMod.currentID and g_currentMission ~= nil then
    g_currentMission.nickname = name
    g_currentMission.playerNickname = name
  end
end

function ContractorMod:getWorkerLocationText(worker)
  local vehicle = ContractorMod:getWorkerVehicle(worker)
  if vehicle ~= nil then
    if vehicle.getFullName ~= nil then
      return vehicle:getFullName()
    end
    if vehicle.getName ~= nil then
      return vehicle:getName()
    end
    return tostring(vehicle)
  end
  local x, y, z = ContractorMod:getWorkerPosition(worker)
  return string.format("%.1f / %.1f / %.1f", Utils.getNoNil(x, 0), Utils.getNoNil(y, 0), Utils.getNoNil(z, 0))
end

function ContractorMod:formatRemainingTime(seconds)
  seconds = math.max(0, seconds or 0)
  local h = math.floor(seconds / 3600)
  local m = math.floor((seconds % 3600) / 60)
  local s = math.floor(seconds % 60)
  return string.format("%d:%02d:%02d", h, m, s)
end

function ContractorMod:getAdModule(vehicle)
  if vehicle == nil then
    return nil
  end
  local ad = vehicle.ad
  if type(ad) ~= "table" then
    ad = vehicle.spec_autodrive
  end
  if type(ad) ~= "table" then
    return nil
  end
  return ad
end

function ContractorMod:isAdActive(vehicle)
  local ad = ContractorMod:getAdModule(vehicle)
  if ad == nil or type(ad.stateModule) ~= "table" or ad.stateModule.isActive == nil then
    return false
  end
  local ok, active = pcall(ad.stateModule.isActive, ad.stateModule)
  return ok and active == true
end

function ContractorMod:isCpActive(vehicle)
  if vehicle == nil or vehicle.getIsCpActive == nil then
    return false
  end
  local ok, active = pcall(vehicle.getIsCpActive, vehicle)
  return ok and active == true
end

function ContractorMod:getAiJob(vehicle)
  if vehicle ~= nil and vehicle.getJob ~= nil then
    local ok, job = pcall(vehicle.getJob, vehicle)
    if ok then
      return job
    end
  end
  if vehicle ~= nil and type(vehicle.spec_aiJobVehicle) == "table" then
    return vehicle.spec_aiJobVehicle.job
  end
  return nil
end

-- Stop assigned work on the vehicle (AutoDrive, CoursePlay, FollowMe, classic AI job), returns true if any was active
function ContractorMod:stopVehicleWork(vehicle)
  if vehicle == nil then
    return false
  end
  local stopped = false
  if ContractorMod:isAdActive(vehicle) and vehicle.stopAutoDrive ~= nil then
    if vehicle.isServer then
      pcall(vehicle.stopAutoDrive, vehicle)
    elseif AutoDriveStartStopEvent ~= nil and g_client ~= nil and g_client.getServerConnection ~= nil then
      pcall(function()
        g_client:getServerConnection():sendEvent(AutoDriveStartStopEvent.new(vehicle, AutoDriveStartStopEvent.TYPE_STOP, false, false))
      end)
    end
    stopped = true
  end
  if vehicle.getIsAIActive ~= nil and vehicle:getIsAIActive() and vehicle.stopCurrentAIJob ~= nil then
    pcall(vehicle.stopCurrentAIJob, vehicle, AIMessageSuccessStoppedByUser.new())
    stopped = true
  end
  return stopped
end

function ContractorMod:getJobRemainingTimeText(vehicle)
  if vehicle == nil then
    return ""
  end
  if ContractorMod:isAdActive(vehicle) then
    local ad = ContractorMod:getAdModule(vehicle)
    local value = nil
    if vehicle.adGetRemainingDriveTime ~= nil then
      local ok, v = pcall(vehicle.adGetRemainingDriveTime, vehicle)
      if ok and type(v) == "number" then
        value = v
      end
    end
    if value == nil and ad.stateModule ~= nil and ad.stateModule.getRemainingDriveTime ~= nil then
      local ok, v = pcall(ad.stateModule.getRemainingDriveTime, ad.stateModule)
      if ok and type(v) == "number" then
        value = v
      end
    end
    if value ~= nil and value > 0 then
      return ContractorMod:formatRemainingTime(value)
    end
    return ""
  end
  if ContractorMod:isCpActive(vehicle) and vehicle.getCpDriveStrategy ~= nil then
    local ok, strategy = pcall(vehicle.getCpDriveStrategy, vehicle)
    if ok and type(strategy) == "table" and strategy.remainingTime ~= nil then
      local remainingTime = strategy.remainingTime
      if type(remainingTime) == "number" and remainingTime > 0 then
        return ContractorMod:formatRemainingTime(remainingTime)
      end
      if type(remainingTime) == "table" then
        if type(remainingTime.time) == "number" and remainingTime.time > 0 then
          return ContractorMod:formatRemainingTime(remainingTime.time)
        end
        if remainingTime.getText ~= nil then
          local okText, text = pcall(remainingTime.getText, remainingTime)
          if okText and type(text) == "string" and text ~= "" then
            return text
          end
        end
      end
    end
  end
  return ""
end

function ContractorMod:getWorkerStateTexts(worker)
  local vehicle = ContractorMod:getWorkerVehicle(worker)
  if vehicle == nil then
    return g_i18n:getText("ContractorMod_ON_FOOT"), ""
  end
  local vehicleName = tostring(vehicle)
  if vehicle.getFullName ~= nil then
    vehicleName = vehicle:getFullName()
  elseif vehicle.getName ~= nil then
    vehicleName = vehicle:getName()
  end
  local seat = ContractorMod:getWorkerSeat(worker)
  if ContractorMod:isCpActive(vehicle) then
    local courseName = ""
    if vehicle.getCurrentCpCourseName ~= nil then
      local ok, name = pcall(vehicle.getCurrentCpCourseName, vehicle)
      if ok and name ~= nil and name ~= "" then
        courseName = tostring(name)
      end
    end
    if courseName == "" then
      local job = ContractorMod:getAiJob(vehicle)
      if job ~= nil and job.getTitle ~= nil then
        local ok, title = pcall(job.getTitle, job)
        if ok and title ~= nil and title ~= "" then
          courseName = tostring(title)
        end
      end
    end
    if courseName == "" then
      courseName = "CoursePlay"
    end
    return string.format(g_i18n:getText("ContractorMod_COURSEPLAY"), courseName), ContractorMod:getJobRemainingTimeText(vehicle)
  end
  if ContractorMod:isAdActive(vehicle) then
    local ad = ContractorMod:getAdModule(vehicle)
    local taskInfo = ""
    if ad.stateModule ~= nil and ad.stateModule.getCurrentLocalizedTaskInfo ~= nil then
      local ok, info = pcall(ad.stateModule.getCurrentLocalizedTaskInfo, ad.stateModule)
      if ok and type(info) == "string" then
        taskInfo = info
      end
    end
    if taskInfo == "" and ad.stateModule ~= nil and ad.stateModule.getCurrentTaskInfo ~= nil then
      local ok, info = pcall(ad.stateModule.getCurrentTaskInfo, ad.stateModule)
      if ok and type(info) == "string" then
        taskInfo = info
      end
    end
    if taskInfo == "" and ad.stateModule ~= nil and ad.stateModule.getCurrentDestination ~= nil then
      local ok, destination = pcall(ad.stateModule.getCurrentDestination, ad.stateModule)
      if ok and type(destination) == "table" and destination.name ~= nil then
        taskInfo = tostring(destination.name)
      end
    end
    if taskInfo == "" then
      taskInfo = "AutoDrive"
    end
    return string.format(g_i18n:getText("ContractorMod_AUTODRIVE"), taskInfo), ContractorMod:getJobRemainingTimeText(vehicle)
  end
  local aiActive = vehicle.getIsAIActive ~= nil and vehicle:getIsAIActive()
  if aiActive then
    local title = ""
    local job = ContractorMod:getAiJob(vehicle)
    if job ~= nil and job.getTitle ~= nil then
      local ok, jobTitle = pcall(job.getTitle, job)
      if ok and jobTitle ~= nil and jobTitle ~= "" then
        title = tostring(jobTitle)
      end
    end
    if title == "" then
      title = vehicleName
    end
    return string.format(g_i18n:getText("ContractorMod_AI_JOB"), title), ""
  end
  if seat ~= nil then
    return string.format(g_i18n:getText("ContractorMod_PASSENGER_IN"), vehicleName), ""
  end
  return string.format(g_i18n:getText("ContractorMod_DRIVING"), vehicleName), ""
end

function ContractorMod:dumpWorkers()
  if ContractorMod.debug then print("ContractorMod:dumpWorkers()") end
  if ContractorMod.workers ~= nil then
    for _, worker in pairs(ContractorMod.workers) do
      DebugUtil.printTableRecursively(worker, "  ", 1, 1)
      local vehicle = ContractorMod:getWorkerVehicle(worker)
      local seat = ContractorMod:getWorkerSeat(worker)
      local name = nil
      if vehicle ~= nil then
        name = vehicle.getName and vehicle:getName() or tostring(vehicle)
      else
        name = "nil"    
      end
      print("Worker "..worker.name.." currentVehicle "..name.." seat "..tostring(seat))
    end
  end
end
addConsoleCommand("cmDumpWorkers", "Dump ContractorMod workers for debug", "dumpWorkers", ContractorMod)
addConsoleCommand("cmHireWorker", "Hire a new worker next to the active one", "addWorker", ContractorMod)
addConsoleCommand("cmFireWorker", "Fire the worker with the given index", "removeWorker", ContractorMod)

    