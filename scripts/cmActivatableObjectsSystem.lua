cmActivatableObjectsSystem = {}

function cmActivatableObjectsSystem:app_addActivatable(activatable)
  if ContractorMod.registeredActivatables ~= nil then
    ContractorMod.registeredActivatables[activatable] = true
  end
end
ActivatableObjectsSystem.addActivatable = Utils.appendedFunction(ActivatableObjectsSystem.addActivatable, cmActivatableObjectsSystem.app_addActivatable)

function cmActivatableObjectsSystem:pre_removeActivatable(activatable)
  if ContractorMod.registeredActivatables ~= nil then
    ContractorMod.registeredActivatables[activatable] = nil
  end
end
ActivatableObjectsSystem.removeActivatable = Utils.prependedFunction(ActivatableObjectsSystem.removeActivatable, cmActivatableObjectsSystem.pre_removeActivatable)

function ContractorMod:resetOutOfRangeActivatables(maxDistance)
  if ContractorMod.debug then print("ContractorMod:resetOutOfRangeActivatables()") end
  local activatableObjectsSystem = g_currentMission and g_currentMission.activatableObjectsSystem
  if activatableObjectsSystem == nil or ContractorMod.registeredActivatables == nil or g_localPlayer == nil then
    return
  end
  local x, y, z = g_localPlayer:getPosition()
  for activatable, _ in pairs(ContractorMod.registeredActivatables) do
    if activatable ~= nil and activatable.getDistance ~= nil then
      local success, distance = pcall(activatable.getDistance, activatable, x, y, z)
      if success and distance ~= nil and distance > maxDistance then
        activatableObjectsSystem:removeActivatable(activatable)
      end
    end
  end
end
