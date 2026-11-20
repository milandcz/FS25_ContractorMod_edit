cmActivatableObjectsSystem = {}

function cmActivatableObjectsSystem:app_addActivatable(activatable)
  if activatable ~= nil and ContractorMod.registeredActivatables ~= nil then
    if g_localPlayer ~= nil then
      local x, y, z = g_localPlayer:getPosition()
      ContractorMod.registeredActivatables[activatable] = {x = x, y = y, z = z}
    else
      ContractorMod.registeredActivatables[activatable] = true
    end
  end
end
ActivatableObjectsSystem.addActivatable = Utils.appendedFunction(ActivatableObjectsSystem.addActivatable, cmActivatableObjectsSystem.app_addActivatable)

function cmActivatableObjectsSystem:pre_removeActivatable(activatable)
  if activatable ~= nil and ContractorMod.registeredActivatables ~= nil then
    ContractorMod.registeredActivatables[activatable] = nil
  end
end
ActivatableObjectsSystem.removeActivatable = Utils.prependedFunction(ActivatableObjectsSystem.removeActivatable, cmActivatableObjectsSystem.pre_removeActivatable)
