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


local isInitializied = false

local addonFrame = CreateFrame("Frame") -- Renamed from frame to addonFrame
addonFrame:RegisterEvent("ADDON_LOADED")
addonFrame:SetScript("OnEvent", function(_, event, addonName)
    if addonName == "Blizzard_PlayerSpells" then
        PlayerSpellsFrame:HookScript("OnShow", function()
            if isInitializied then return end
            isInitializied = true

            -- -- Create a button to open the Macro UI
            local macroButton = CreateFrame("Button", nil, PlayerSpellsFrame.SpellBookFrame, "UIPanelButtonTemplate")
            macroButton:SetSize(100, 22)
            macroButton:SetText("Macros")
            macroButton:SetPoint("TOPRIGHT", PlayerSpellsFrame.SpellBookFrame, "TOPRIGHT", -30, -40)
            macroButton:SetScript("OnClick", function()
                MacroFrame_LoadUI();
                ShowUIPanel(MacroFrame);
            end)
            macroButton:Show()

            local pool= PlayerSpellsFrame.SpellBookFrame.PagedSpellsFrame.framePoolCollection
            for elementFrame in pool:EnumerateActiveByTemplate("SpellBookItemTemplate", "SPELL") do
                elementFrame.Button:HookScript("OnClick", function()   
                    if not IsControlKeyDown() then return end

                    local menuItems = generateMenuItems( elementFrame.spellBookItemInfo.spellID)
                    MenuUtil.CreateContextMenu(elementFrame.Button, function(ownerRegion, rootDescription)
                        rootDescription:CreateTitle("Create Macro")
                        for _, menuItem in ipairs(menuItems) do
                            rootDescription:CreateButton(menuItem.text, function() menuItem.func() end)
                        end
                    end)

                end)
            end
        end)

    end
end)
