cmDebugPickup = {}

-- TEMPORARY diagnostic: trace who sends HandsPickUpObjectEvent (pallet/bale auto-pickup report)
ContractorMod.debugPickupTrace = true

if HandsPickUpObjectEvent ~= nil and HandsPickUpObjectEvent.sendEvent ~= nil then
  HandsPickUpObjectEvent.sendEvent = Utils.overwrittenFunction(HandsPickUpObjectEvent.sendEvent, function(superfunc, ...)
    if ContractorMod.debugPickupTrace then
      print("ContractorMod DEBUG: HandsPickUpObjectEvent.sendEvent called")
      printCallstack()
    end
    return superfunc(...)
  end)
end
