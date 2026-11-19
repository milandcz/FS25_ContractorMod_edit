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
