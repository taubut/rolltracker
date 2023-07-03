-- RollTracker.lua

-- Create a frame to handle events
local frame = CreateFrame("FRAME")
frame:RegisterEvent("CHAT_MSG_SYSTEM")

-- Event handler function
local function OnEvent(self, event, ...)
    local message = ...
    local player, roll, min, max = message:match("(%a+) rolls (%d+) %((%d+)%-(%d+)%)")
    if roll and ((min == "1" and max == "100") or (min == "1" and max == "99") or (min == "1" and max == "98")) then
        -- Check if the DB exists and if not, initialize it
        if not RollTrackerDB then
            RollTrackerDB = {}
        end
        table.insert(RollTrackerDB, { roll = tonumber(roll), location = GetRealZoneText(), timestamp = time() })
    end
end

-- Register the event handler
frame:SetScript("OnEvent", OnEvent)

-- Create a container frame
local containerFrame = CreateFrame("Frame", nil, UIParent)
containerFrame:SetSize(250, 330)  -- Increase the width to accommodate the text
containerFrame:SetPoint("CENTER")
containerFrame:SetFrameStrata("BACKGROUND")
containerFrame:SetFrameLevel(0)
containerFrame:SetMovable(true)  -- Make the container frame movable
containerFrame:EnableMouse(true)  -- Enable mouse interaction

-- Create a background frame
local bgFrame = CreateFrame("Frame", nil, containerFrame)
bgFrame:SetSize(250, 300)  -- Set the size to match historyFrame
bgFrame:SetPoint("BOTTOM", containerFrame, "BOTTOM", 0, 0)  -- Position to match historyFrame
bgFrame:SetFrameLevel(0) -- To ensure it stays behind the contentFrame
bgFrame:Hide() -- Hide the black frame on load

-- Set bgFrame color and texture
bgFrame.texture = bgFrame:CreateTexture()
bgFrame.texture:SetAllPoints()
bgFrame.texture:SetColorTexture(0, 0, 0, 0.75) -- Black color with 75% opacity

-- Create frame border
bgFrame.border = CreateFrame("Frame", nil, bgFrame, "BackdropTemplate")
bgFrame.border:SetPoint("TOPLEFT", -5, 5)
bgFrame.border:SetPoint("BOTTOMRIGHT", 5, -5)
bgFrame.border:SetBackdrop({
    bgFile = "Interface\\Stationery\\StationeryTest1",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 },
})
bgFrame.border:SetBackdropBorderColor(0.6, 0.6, 0.6) -- Light gray color

-- Create history frame
local historyFrame = CreateFrame("ScrollFrame", nil, containerFrame, "UIPanelScrollFrameTemplate")
historyFrame:SetSize(250, 300)
historyFrame:SetPoint("BOTTOM", containerFrame, "BOTTOM", 0, 0) -- Position to the bottom of the container frame
historyFrame:Hide()

-- Create scrollable content frame
local contentFrame = CreateFrame("Frame", nil, historyFrame)
contentFrame:SetSize(240, 240)  -- Adjust the size to accommodate the text
contentFrame:SetPoint("TOPLEFT", historyFrame, "TOPLEFT", 5, -5)  -- Adjust the position and add a small padding

-- Set historyFrame as the scroll child of contentFrame
historyFrame:SetScrollChild(contentFrame)

-- Create a title bar
local titleBar = CreateFrame("Frame", nil, containerFrame)
titleBar:SetSize(250, 60)  -- Increase the height to accommodate the text
titleBar:SetPoint("BOTTOM", historyFrame, "TOP", 0, 0) -- Position at the top of the history frame
titleBar:SetFrameStrata("BACKGROUND")
titleBar:Hide() -- Hide the title bar initially

-- Create title text
local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetText("ROLL HISTORY")
titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 10)

-- Create percentage text
local percentageText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
percentageText:SetTextColor(1, 1, 1) -- White color
percentageText:SetPoint("TOP", titleText, "BOTTOM", 0, -5)

-- Create close button
local closeButton = CreateFrame("Button", nil, historyFrame, "GameMenuButtonTemplate")
closeButton:SetPoint("TOP", historyFrame, "BOTTOM", -55, -10) -- Adjust the X position to center the button
closeButton:SetSize(100, 25)
closeButton:SetText("Close")
closeButton:SetScript("OnClick", function()
    historyFrame:Hide()
    titleBar:Hide()  -- Hide the title bar when clicked
    bgFrame:Hide() -- Hide the black frame when clicked
end)
closeButton:Hide() -- Hide the close button on load

-- Create clear history button
local clearButton = CreateFrame("Button", nil, historyFrame, "GameMenuButtonTemplate")
clearButton:SetPoint("TOP", closeButton, "TOP", 110, 0) -- Adjust the X position to center the button
clearButton:SetSize(100, 25)
clearButton:SetText("Clear History")
clearButton:Hide() -- Hide the clear button on load

-- Create a table to keep track of the roll texts
local rollTexts = {}

-- Function to update history
local function UpdateHistory()
    -- Clear content frame
    for _, rollText in ipairs(rollTexts) do
        rollText:Hide()
    end
    wipe(rollTexts)

    -- Populate content frame with roll history
    -- Check if the DB exists and if not, initialize it
    if not RollTrackerDB then
        RollTrackerDB = {}
    end

    local rolls25AndUnder = 0
    local rolls75AndAbove = 0

    for i, rollData in ipairs(RollTrackerDB) do
        local dateText = date("%m/%d/%Y", rollData.timestamp or 0)  -- Get the date in MM/DD/YYYY format
        local rollText = contentFrame:CreateFontString(nil, "HIGHLIGHT", "GameFontNormalSmall")
        rollText:SetText(dateText .. "    |    " .. rollData.location .. "    |    " .. rollData.roll)
        rollText:SetTextColor(1, 1, 1) -- White color

        -- Change text color based on roll value
        if rollData.roll >= 75 then
            rollText:SetTextColor(0, 1, 0) -- Green for rolls 75 and above
            rolls75AndAbove = rolls75AndAbove + 1
        elseif rollData.roll <= 25 then
            rollText:SetTextColor(1, 0, 0) -- Red for rolls 25 and below
            rolls25AndUnder = rolls25AndUnder + 1
        else
            rollText:SetTextColor(1, 1, 0) -- Yellow for all other rolls
        end

        rollText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, -10 - 15 * (i - 1))  -- Adjust the starting point and set draw layer
        rollText:SetDrawLayer("OVERLAY")  -- Set the draw layer to OVERLAY

        rollText:Show()

        -- Add the roll text to the table
        table.insert(rollTexts, rollText)
    end

    -- Calculate percentages
    local totalRolls = #RollTrackerDB
    if totalRolls > 0 then
        local percentage25AndUnder = (rolls25AndUnder / totalRolls) * 100
        local percentage75AndAbove = (rolls75AndAbove / totalRolls) * 100

        -- Update percentage text
        percentageText:SetText(string.format("Percentage of rolls 25 and under: %.2f%%   |   Percentage of rolls 75 and over: %.2f%%", percentage25AndUnder, percentage75AndAbove))
    else
        percentageText:SetText("No roll history available")
    end
end


-- Function to clear history
local function ClearHistory()
    if next(RollTrackerDB) ~= nil then
        StaticPopupDialogs["CLEAR_ROLL_HISTORY"] = {
            text = "Are you sure you want to clear the roll history?",
            button1 = "Accept",
            button2 = "Decline",
            OnAccept = function()
                wipe(RollTrackerDB)
                UpdateHistory()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("CLEAR_ROLL_HISTORY")
    end
end

clearButton:SetScript("OnClick", ClearHistory)

-- Make the container frame draggable
containerFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self.isMoving then
        self:StartMoving()
        self.isMoving = true
    end
end)
containerFrame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
    end
end)
containerFrame:SetScript("OnHide", function(self)
    if self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
    end
end)

-- Slash command to display roll history
SLASH_rolltracker1 = "/rh"
SLASH_rolltracker2 = "/rollhistory"
SlashCmdList["rolltracker"] = function()
    -- Check if the DB exists and if not, print no rolls recorded
    if not RollTrackerDB or #RollTrackerDB == 0 then
        print("No rolls recorded.")
    else
        UpdateHistory()
        historyFrame:Show()
        titleBar:Show()  -- Show the title bar when the command is used
        closeButton:Show()  -- Show the close button when the command is used
        clearButton:Show()  -- Show the clear history button when the command is used
        bgFrame:Show() -- Show the black frame when the command is used
    end
end
