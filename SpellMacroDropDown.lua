
-- Constants for spell macro types
local MACRO_TYPES = {
    NORMAL_CAST = "normalCast",
    MOUSEOVER_BASIC = "mouseoverBasic",
    MOUSEOVER_HARM = "mouseoverHarm",
    MOUSEOVER_HELP = "mouseoverHelp",
    MOUSEOVER_HARM_OR_HELP = "mouseoverHarmOrHelp",
    MOUSEOVER_HARM_OR_HELP_OR_TARGET = "mouseoverHarmOrHelpOrTarget",
    MOUSEOVER_CAST = "mouseoverCast",
    CURSOR_CAST = "cursorCast",
    CAST_PLAYER = "Castplayer",
    RANDOM_FRIENDLY = "randomFriendly",
    RANDOM_ENEMY = "randomEnemy"
}

-- Templates for macro text
local macroTextTemplates = {
    [MACRO_TYPES.NORMAL_CAST] = "#showtooltip\n/cast %s",
    [MACRO_TYPES.MOUSEOVER_BASIC] = "#showtooltip\n/cast [@mouseover,exists,nodead] [] %s",
    [MACRO_TYPES.MOUSEOVER_HARM] = "#showtooltip\n/cast [@mouseover,harm,nodead] [] %s",
    [MACRO_TYPES.MOUSEOVER_HELP] = "#showtooltip\n/cast [@mouseover,help,nodead] [] %s",
    [MACRO_TYPES.MOUSEOVER_HARM_OR_HELP] = "#showtooltip\n/cast [@mouseover,harm,nodead][@mouseover,help,nodead] [] %s",
    [MACRO_TYPES.MOUSEOVER_HARM_OR_HELP_OR_TARGET] = "#showtooltip\n/cast [@mouseover,harm,nodead][@mouseover,help,nodead][@targettarget,harm,nodead] [] %s",
    [MACRO_TYPES.MOUSEOVER_CAST] = "#showtooltip\n/cast [@mouseover] %s",
    [MACRO_TYPES.CURSOR_CAST] = "#showtooltip\n/cast [@cursor] %s",
    [MACRO_TYPES.CAST_PLAYER] = "#showtooltip\n/stopspelltarget\n/cast [@player] %s",
    [MACRO_TYPES.RANDOM_FRIENDLY] = "#showtooltip\n/targetfriendplayer\n/cast %s\n/cleartarget",
    [MACRO_TYPES.RANDOM_ENEMY] = "#showtooltip\n/targetenemyplayer\n/cast %s\n/cleartarget"
}

--- Creates a macro for a given spell ID and macro type.
-- @param spellId The ID of the spell.
-- @param macroType The type of macro to create. See MACRO_TYPES for options.
local function generateSpellMacro(spellId, macroType)
    local spellInfo = C_Spell.GetSpellInfo(spellId)
    if not spellInfo then
        -- print("Invalid spell ID: " .. spellId)
        return
    end

    local spellName = spellInfo.name
    local icon = spellInfo.iconID
    local macroText = string.format(macroTextTemplates[macroType] or macroTextTemplates[MACRO_TYPES.NORMAL_CAST],
        spellName)
    local macroName = spellName

    CreateMacro(macroName, icon, macroText, nil) -- Changed 1 to nil
    -- print("Macro created for " .. spellName .. " - " .. macroType)
    PickupMacro(macroName)
end

--- Creates a menu frame if it doesn't already exist.
-- @return The menu frame.
local function createMenuFrame()
    local frameName = "MyAddonCustomSpellMenuFrame"
    local menuFrame = _G[frameName]
    if not menuFrame then
        menuFrame = CreateFrame("Frame", frameName, UIParent, "UIDropDownMenuTemplate")
        menuFrame:SetFrameStrata("TOOLTIP") -- Set the frame strata to TOOLTIP
        menuFrame:SetFrameLevel(1000) -- Optionally set a high frame level
    end
    return menuFrame
end

--- Creates menu items for the custom spell menu.
-- @param spellId The ID of the spell for which to create menu items.
-- @return A table of menu items.
local function generateMenuItems(spellId)
    local actions = {{
        text = "Create Cast",
        macroType = MACRO_TYPES.NORMAL_CAST
    }, {
        text = "Create Mouseover Basic",
        macroType = MACRO_TYPES.MOUSEOVER_BASIC
    }, {
        text = "Create Mouseover Harm",
        macroType = MACRO_TYPES.MOUSEOVER_HARM
    }, {
        text = "Create Mouseover Help",
        macroType = MACRO_TYPES.MOUSEOVER_HELP
    }, {
        text = "Create Mouseover Harm or Help",
        macroType = MACRO_TYPES.MOUSEOVER_HARM_OR_HELP
    }, {
        text = "Create Mouseover Harm or Help or Target",
        macroType = MACRO_TYPES.MOUSEOVER_HARM_OR_HELP_OR_TARGET
    }, {
        text = "Create Mouseover Cast",
        macroType = MACRO_TYPES.MOUSEOVER_CAST
    }, {
        text = "Create Cursor Cast",
        macroType = MACRO_TYPES.CURSOR_CAST
    }, {
        text = "Create Cast Player",
        macroType = MACRO_TYPES.CAST_PLAYER
    }, {
        text = "Create Random Friendly",
        macroType = MACRO_TYPES.RANDOM_FRIENDLY
    }, {
        text = "Create Random Enemy",
        macroType = MACRO_TYPES.RANDOM_ENEMY
    }}

    local menuItems = {}
    for _, action in ipairs(actions) do
        table.insert(menuItems, {
            text = action.text,
            func = function()
                generateSpellMacro(spellId, action.macroType)
            end
        })
    end

    return menuItems
end

--- Displays a custom menu for creating spell macros.
-- @param spellId The ID of the spell for which to show the menu.
local function displayCustomMenu(spellId)
    print("Displaying custom menu for spellId: " .. tostring(spellId))
    local menuFrame = createMenuFrame()
    local menuItems = generateMenuItems(spellId)
    EasyMenu(menuItems, menuFrame, "cursor", 0, 0, "MENU")
end

--- Hooks the spell button to show the custom menu on right-click with Control key.
-- @param button The spell button to hook.
 -- @param spellId The spell ID associated with the button.
local function hookSpellButton(button, spellId)
    if not button then
        print("Invalid spell button.")
        return
    end

    print("Hooking button: " .. tostring(button) .. " with spellId: " .. tostring(spellId))

    button:RegisterForClicks("AnyUp")
    button:HookScript("OnClick", function()
        print("Button clicked")
        if IsControlKeyDown() then
            print("Control key is down")
            local slot = button:GetID()
            if slot then
                if spellId then
                    print("Displaying custom menu for spellId: " .. tostring(spellId))
                    displayCustomMenu(spellId)
                else
                    print("No spell ID found for slot: " .. slot)
                end
            else
                print("Invalid spell slot.")
            end
            return true
        else
            print("Control key is not down")
        end
    end)
end

local function hookAllSpellButtons()
    local spellBookFrame = PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame

    if not spellBookFrame then
        print("SpellBookFrame is not available.")
        return
    end

    local pagedSpellsFrame = spellBookFrame.PagedSpellsFrame
    if not pagedSpellsFrame then
        print("PagedSpellsFrame is not available.")
        return
    end

    local view1 = pagedSpellsFrame.View1
    if not view1 then
        print("View1 is not available.")
        return
    end

    local numTabs = C_SpellBook.GetNumSpellBookSkillLines()
    for tab = 1, numTabs do
        local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(tab)
        local offset, numSpells = skillLineInfo.itemIndexOffset, skillLineInfo.numSpellBookItems
        print("Tab: " .. tab .. " Offset: " .. offset .. " NumSpells: " .. numSpells)

        if offset and numSpells then
            for i = offset + 1, offset + numSpells do
                -- local name, subName = C_SpellBook.GetSpellBookItemName(i, Enum.SpellBookSpellBank.Player)
                local spellID = select(2, C_SpellBook.GetSpellBookItemType(i, Enum.SpellBookSpellBank.Player))
                local button = view1["SpellButton" .. i]

                if button and spellID then
                    button:HookScript("OnClick", function()
                        -- print("Button clicked: " .. "Button" .. i .. " with spellID: " .. tostring(spellID))
                    end)
                    hookSpellButton(button, spellID)
                else
                    -- print("Button or spellID not found for slot: " .. i)
                end
            end
        end
    end
end

-- Hook into PLAYER_ENTERING_WORLD event to ensure buttons are available
local eventFrame = CreateFrame("Frame") -- Renamed from frame to eventFrame
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then
        print("PLAYER_ENTERING_WORLD")
        C_Timer.After(3, hookAllSpellButtons) -- Delay the hook to ensure frames are available
    end
end)

-- Event handler to hook spell buttons after the player logs in
local function onAddonLoaded(addonName)
    if addonName == "Blizzard_PlayerSpells" then
        print("Blizzard_PlayerSpells loaded")
        C_Timer.After(3, hookAllSpellButtons) -- Increased delay to ensure frames are available

        -- Create a button to open the Macro UI
        C_Timer.After(2, function()
            local macroButton = CreateFrame("Button", "OpenMacroButton", PlayerSpellsFrame.SpellBookFrame,
                "UIPanelButtonTemplate")
            macroButton:SetSize(100, 22)
            macroButton:SetText("Macros")
            macroButton:SetPoint("TOPRIGHT", PlayerSpellsFrame.SpellBookFrame, "TOPRIGHT", -30, -40)
        end)
    end
end

local addonFrame = CreateFrame("Frame") -- Renamed from frame to addonFrame
addonFrame:RegisterEvent("ADDON_LOADED")
addonFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        print("ADDON_LOADED " .. ...)
        onAddonLoaded(...)
    end
end)
