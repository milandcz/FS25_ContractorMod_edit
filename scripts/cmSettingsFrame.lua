cmSettingsFrame = {}

local cmModDirectory = g_currentModDirectory

ContractorModSettingsFrame = {}
ContractorModSettingsFrame._mt = Class(ContractorModSettingsFrame, TabbedMenuFrameElement)
ContractorModSettingsFrame.PAGE_NAME = "contractorModSettingsFrame"
ContractorModSettingsFrame.ICON_UVS = { 0, 0, 512, 512 }
ContractorModSettingsFrame.ICON_REF = { 512, 512 }

function ContractorModSettingsFrame.new()
  local self = ContractorModSettingsFrame:superClass().new(nil, ContractorModSettingsFrame._mt)
  self.name = ContractorModSettingsFrame.PAGE_NAME
  self.workerRows = {}
  self.builtWorkerCount = -1
  self.refreshTimer = 0
  return self
end

function ContractorModSettingsFrame:delete()
  if self.headerRow ~= nil then
    self.headerRow:delete()
    self.headerRow = nil
  end
  for _, row in ipairs(self.workerRows) do
    row:delete()
  end
  self.workerRows = {}
  ContractorModSettingsFrame:superClass().delete(self)
end

function ContractorModSettingsFrame:onGuiSetupFinished()
  ContractorModSettingsFrame:superClass().onGuiSetupFinished(self)
  if self.headerIcon ~= nil and cmModDirectory ~= nil then
    self.headerIcon:setImageFilename(Utils.getFilename("icon_ContractorMod.dds", cmModDirectory))
  end
  if self.headerRowTemplate ~= nil then
    self.headerRowTemplate:setVisible(false)
  end
  if self.workerRowTemplateA ~= nil then
    self.workerRowTemplateA:setVisible(false)
  end
  if self.workerRowTemplateB ~= nil then
    self.workerRowTemplateB:setVisible(false)
  end
  if self.hireRowTemplate ~= nil then
    self.hireRowTemplate:setVisible(false)
  end
end

function ContractorModSettingsFrame:onFrameOpen()
  ContractorModSettingsFrame:superClass().onFrameOpen(self)
  self.builtWorkerCount = -1
  self:updateWorkerRows()
end

function ContractorModSettingsFrame:onFrameClose()
  ContractorModSettingsFrame:superClass().onFrameClose(self)
end

function ContractorModSettingsFrame:update(dt)
  ContractorModSettingsFrame:superClass().update(self, dt)
  if self.visible then
    self.refreshTimer = self.refreshTimer + dt
    if self.refreshTimer >= 500 then
      self.refreshTimer = 0
      self:updateWorkerRows()
    end
  end
end

function ContractorModSettingsFrame:updateWorkerRows()
  if self.workersLayout == nil or self.workerRowTemplateA == nil or self.workerRowTemplateB == nil then
    return
  end
  if ContractorMod.workers == nil then
    return
  end
  if #ContractorMod.workers ~= self.builtWorkerCount then
    self:rebuildWorkerRows()
  else
    self:refreshWorkerRows()
  end
end

function ContractorModSettingsFrame:rebuildWorkerRows()
  if self.headerRow ~= nil then
    self.headerRow:delete()
    self.headerRow = nil
  end
  for _, row in ipairs(self.workerRows) do
    row:delete()
  end
  self.workerRows = {}
  if self.headerRowTemplate ~= nil and self.workersLayout ~= nil then
    local headerRow = self.headerRowTemplate:clone(self.workersLayout)
    headerRow:setVisible(true)
    pcall(FocusManager.loadElementFromCustomValues, FocusManager, headerRow)
    self.headerRow = headerRow
  end
  for i, worker in ipairs(ContractorMod.workers) do
    local template = self.workerRowTemplateA
    if i % 2 == 0 then
      template = self.workerRowTemplateB
    end
    local row = template:clone(self.workersLayout)
    row:setVisible(true)
    row.workerIndex = i
    local renameButton = row:getDescendantByName("renameButton")
    if renameButton ~= nil then
      renameButton.onClickCallback = function() self:onClickRenameWorker(i) end
    end
    local switchButton = row:getDescendantByName("switchButton")
    if switchButton ~= nil then
      switchButton.onClickCallback = function() self:onClickSwitchWorker(i) end
    end
    local fireButton = row:getDescendantByName("fireButton")
    if fireButton ~= nil then
      fireButton.onClickCallback = function() self:onClickFireWorker(i) end
    end
    pcall(FocusManager.loadElementFromCustomValues, FocusManager, row)
    table.insert(self.workerRows, row)
  end
  if self.hireRowTemplate ~= nil then
    local hireRow = self.hireRowTemplate:clone(self.workersLayout)
    hireRow:setVisible(true)
    local hireButton = hireRow:getDescendantByName("hireButton")
    if hireButton ~= nil then
      hireButton.onClickCallback = function() self:onClickHireWorker() end
      hireButton:setDisabled(#ContractorMod.workers >= ContractorMod.MAX_WORKERS)
    end
    pcall(FocusManager.loadElementFromCustomValues, FocusManager, hireRow)
    table.insert(self.workerRows, hireRow)
  end
  self.builtWorkerCount = #ContractorMod.workers
  self.workersLayout:invalidateLayout()
  self:refreshWorkerRows()
end

function ContractorModSettingsFrame:refreshWorkerRows()
  for _, row in ipairs(self.workerRows) do
    local index = row.workerIndex
    if index ~= nil then
      local worker = ContractorMod.workers[index]
      if worker ~= nil then
        local renameButton = row:getDescendantByName("renameButton")
        if renameButton ~= nil then
          renameButton:setText("#" .. index .. " - " .. tostring(worker.name))
        end
        local locationText = row:getDescendantByName("locationText")
        if locationText ~= nil then
          locationText:setText(tostring(ContractorMod:getWorkerLocationText(worker)))
        end
        local state, remaining = ContractorMod:getWorkerStateTexts(worker)
        local stateText = row:getDescendantByName("stateText")
        if stateText ~= nil then
          stateText:setText(tostring(state))
        end
        local remainingText = row:getDescendantByName("remainingText")
        if remainingText ~= nil then
          remainingText:setText(tostring(remaining))
        end
        local switchButton = row:getDescendantByName("switchButton")
        if switchButton ~= nil then
          switchButton:setDisabled(index == ContractorMod.currentID or worker.active == false)
        end
        local fireButton = row:getDescendantByName("fireButton")
        if fireButton ~= nil then
          fireButton:setDisabled(index == ContractorMod.PLAYER_WORKER_INDEX or ContractorMod:getWorkerVehicle(worker) ~= nil or #ContractorMod.workers <= ContractorMod.MIN_WORKERS)
        end
      end
    end
  end
end

function ContractorModSettingsFrame:onClickRenameWorker(workerIndex)
  local worker = nil
  if ContractorMod.workers ~= nil then
    worker = ContractorMod.workers[workerIndex]
  end
  if worker == nil then
    return
  end
  TextInputDialog.show(function(_, text, clickOk)
    if clickOk and type(text) == "string" and text ~= "" then
      ContractorMod:setWorkerName(worker, text)
      self:updateWorkerRows()
    end
  end, self, tostring(worker.name), g_i18n:getText("ContractorMod_RENAME_TITLE"), nil, 24)
end

function ContractorModSettingsFrame:onClickSwitchWorker(workerIndex)
  if ContractorMod.workers == nil or ContractorMod.workers[workerIndex] == nil then
    return
  end
  if ContractorMod:setCurrentContractorModWorker(workerIndex) then
    if g_inGameMenu ~= nil then
      g_inGameMenu:onButtonBack()
    end
  else
    ContractorMod:notify(g_i18n:getText("ContractorMod_WORKER_INACTIVE") .. " (" .. ContractorMod.workers[workerIndex].name .. ")", true)
  end
end

function ContractorModSettingsFrame:onClickFireWorker(workerIndex)
  local worker = nil
  if ContractorMod.workers ~= nil then
    worker = ContractorMod.workers[workerIndex]
  end
  if worker == nil then
    return
  end
  local frame = self
  YesNoDialog.show(function(_, clickOk)
    if clickOk then
      ContractorMod:removeWorker(workerIndex)
      frame:updateWorkerRows()
    end
  end, self, string.format(g_i18n:getText("ContractorMod_FIRE_CONFIRM"), worker.name))
end

function ContractorModSettingsFrame:onClickHireWorker()
  ContractorMod:addWorker()
  self:updateWorkerRows()
end

function cmSettingsFrame.registerInGameMenuPage()
  local menu = g_inGameMenu
  if menu == nil and g_gui ~= nil and g_gui.screenControllers ~= nil then
    menu = g_gui.screenControllers[InGameMenu]
  end
  if menu == nil or menu.pagingElement == nil or menu.pageFrames == nil or cmModDirectory == nil then
    return
  end
  if menu.pageTypeControllers ~= nil and menu.pageTypeControllers[ContractorModSettingsFrame] ~= nil then
    return
  end
  if ContractorModSettingsFrame.instance ~= nil then
    return
  end
  local frame = ContractorModSettingsFrame.new()
  local ok, err = pcall(function()
    g_gui:loadGui(Utils.getFilename("gui/ContractorModSettingsFrame.xml", cmModDirectory), ContractorModSettingsFrame.PAGE_NAME, frame, true)
  end)
  if not ok or frame == nil or #frame.elements == 0 then
    print("ContractorMod: could not load settings page gui: " .. tostring(err))
    return
  end
  local frameFieldName = "pageContractorModSettings"
  local registered = pcall(function()
    local xmlFile = loadXMLFile("cmSettingsFrameRefXML", Utils.getFilename("gui/ContractorModSettingsFrameRef.xml", cmModDirectory))
    if xmlFile == nil or xmlFile == 0 then
      error("frame reference xml not found")
    end
    menu.controlIDs[frameFieldName] = nil
    g_gui:loadGuiRec(xmlFile, "FrameReferences", menu.pagingElement, menu)
    menu:exposeControlsAsFields(frameFieldName)
    menu.pagingElement:updatePageMapping()
    delete(xmlFile)
    local resolved = g_gui:resolveFrameReference(menu[frameFieldName])
    if resolved == nil then
      error("frame reference could not be resolved")
    end
    menu[frameFieldName] = resolved
    menu.pagingElement:removePageByElement(resolved)
    local _, actualPosition = menu:registerPage(resolved, nil, function() return ContractorMod.workers ~= nil end)
    local iconFilename = Utils.getFilename("icon_ContractorMod.dds", cmModDirectory)
    menu:addPageTab(resolved, iconFilename, GuiUtils.getUVs(ContractorModSettingsFrame.ICON_UVS, ContractorModSettingsFrame.ICON_REF))
    menu.pagingElement:addPage(string.upper(ContractorModSettingsFrame.PAGE_NAME), resolved, g_i18n:getText("ui_" .. ContractorModSettingsFrame.PAGE_NAME), actualPosition)
    resolved:onGuiSetupFinished()
    menu.pagingElement:updateAbsolutePosition()
    menu.pagingElement:updatePageMapping()
    menu:rebuildTabList()
    ContractorModSettingsFrame.instance = resolved
  end)
  if not registered then
    print("ContractorMod: could not register settings page in in-game menu")
  end
end

InGameMenu.onMenuOpened = Utils.appendedFunction(InGameMenu.onMenuOpened, function()
  cmSettingsFrame.registerInGameMenuPage()
end)
