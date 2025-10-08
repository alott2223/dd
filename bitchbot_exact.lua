local BitchBot = {}
BitchBot.__index = BitchBot

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local function create(class, properties)
    local obj = Drawing.new(class)
    for i, v in next, properties do
        obj[i] = v
    end
    return obj
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function color3ToRGB(color)
    return math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)
end

local function RGBToColor3(r, g, b)
    return Color3.fromRGB(r, g, b)
end

function BitchBot.new()
    local self = setmetatable({}, BitchBot)
    
    self.windows = {}
    self.connections = {}
    self.theme = {
        ["Accent"] = Color3.fromRGB(138, 43, 226),
        ["Window Background"] = Color3.fromRGB(25, 25, 25),
        ["Window Border"] = Color3.fromRGB(138, 43, 226),
        ["Tab Background"] = Color3.fromRGB(35, 35, 35),
        ["Tab Border"] = Color3.fromRGB(138, 43, 226),
        ["Tab Toggle Background"] = Color3.fromRGB(138, 43, 226),
        ["Section Background"] = Color3.fromRGB(30, 30, 30),
        ["Section Border"] = Color3.fromRGB(138, 43, 226),
        ["Text"] = Color3.fromRGB(255, 255, 255),
        ["Disabled Text"] = Color3.fromRGB(150, 150, 150),
        ["Object Background"] = Color3.fromRGB(40, 40, 40),
        ["Object Border"] = Color3.fromRGB(138, 43, 226),
        ["Dropdown Option Background"] = Color3.fromRGB(50, 50, 50),
        ["Ghosts"] = Color3.fromRGB(255, 165, 0),
        ["Phantoms"] = Color3.fromRGB(135, 206, 250),
        ["Local Player"] = Color3.fromRGB(135, 206, 250),
        ["Header Background"] = Color3.fromRGB(138, 43, 226),
        ["Header Text"] = Color3.fromRGB(255, 255, 255),
        ["Player Row Background"] = Color3.fromRGB(35, 35, 35),
        ["Player Row Alt"] = Color3.fromRGB(30, 30, 30)
    }
    
    self.flags = {}
    self.configs = {}
    
    return self
end

function BitchBot:CreateWindow(config)
    local window = {}
    window.__index = window
    
    window.title = config.Name or "bitch bot"
    window.size = Vector2.new(config.SizeX or 800, config.SizeY or 600)
    window.position = Vector2.new(100, 100)
    window.visible = true
    window.dragging = false
    window.dragOffset = Vector2.new(0, 0)
    
    window.background = create("Square", {
        Size = window.size,
        Position = window.position,
        Color = self.theme["Window Background"],
        Filled = true,
        Thickness = 0,
        ZIndex = 1
    })
    
    window.border = create("Square", {
        Size = window.size,
        Position = window.position,
        Color = self.theme["Window Border"],
        Filled = false,
        Thickness = 2,
        ZIndex = 2
    })
    
    window.titleBar = create("Square", {
        Size = Vector2.new(window.size.X, 30),
        Position = window.position,
        Color = self.theme["Header Background"],
        Filled = true,
        Thickness = 0,
        ZIndex = 3
    })
    
    window.titleText = create("Text", {
        Text = window.title,
        Position = window.position + Vector2.new(10, 8),
        Color = self.theme["Header Text"],
        Size = 16,
        Font = Drawing.Fonts.Monospace,
        ZIndex = 4
    })
    
    window.tabs = {}
    window.currentTab = nil
    window.sections = {}
    
    function window:CreateTab(name)
        local tab = {}
        tab.__index = tab
        
        tab.name = name
        tab.visible = false
        tab.sections = {}
        
        local tabIndex = #window.tabs
        local tabWidth = window.size.X / 5
        local tabX = window.position.X + (tabIndex * tabWidth)
        
        tab.background = create("Square", {
            Size = Vector2.new(tabWidth, 30),
            Position = Vector2.new(tabX, window.position.Y + 30),
            Color = self.theme["Tab Background"],
            Filled = true,
            Thickness = 0,
            ZIndex = 5
        })
        
        tab.border = create("Square", {
            Size = Vector2.new(tabWidth, 30),
            Position = Vector2.new(tabX, window.position.Y + 30),
            Color = self.theme["Tab Border"],
            Filled = false,
            Thickness = 1,
            ZIndex = 6
        })
        
        tab.text = create("Text", {
            Text = name,
            Position = Vector2.new(tabX + 10, window.position.Y + 38),
            Color = self.theme["Text"],
            Size = 14,
            Font = Drawing.Fonts.Monospace,
            ZIndex = 7
        })
        
        function tab:CreateSection(config)
            local section = {}
            section.__index = section
            
            section.name = config.Name or "Section"
            section.side = config.Side or "Left"
            section.visible = false
            section.objects = {}
            
            local sectionWidth = (window.size.X - 40) / 2
            local sectionX = section.side == "Left" and window.position.X + 20 or window.position.X + sectionWidth + 20
            local sectionY = window.position.Y + 80
            
            section.background = create("Square", {
                Size = Vector2.new(sectionWidth - 20, window.size.Y - 120),
                Position = Vector2.new(sectionX, sectionY),
                Color = self.theme["Section Background"],
                Filled = true,
                Thickness = 0,
                ZIndex = 8
            })
            
            section.border = create("Square", {
                Size = Vector2.new(sectionWidth - 20, window.size.Y - 120),
                Position = Vector2.new(sectionX, sectionY),
                Color = self.theme["Section Border"],
                Filled = false,
                Thickness = 1,
                ZIndex = 9
            })
            
            section.title = create("Text", {
                Text = section.name,
                Position = Vector2.new(sectionX + 10, sectionY + 10),
                Color = self.theme["Text"],
                Size = 14,
                Font = Drawing.Fonts.Monospace,
                ZIndex = 10
            })
            
            function section:CreatePlayerList(players)
                local playerList = {}
                playerList.__index = playerList
                
                playerList.players = players
                playerList.selectedPlayer = nil
                playerList.currentPage = 1
                playerList.playersPerPage = 10
                
                local listY = sectionY + 30
                local listHeight = window.size.Y - 200
                
                playerList.background = create("Square", {
                    Size = Vector2.new(sectionWidth - 40, listHeight),
                    Position = Vector2.new(sectionX + 10, listY),
                    Color = self.theme["Section Background"],
                    Filled = true,
                    Thickness = 0,
                    ZIndex = 11
                })
                
                playerList.border = create("Square", {
                    Size = Vector2.new(sectionWidth - 40, listHeight),
                    Position = Vector2.new(sectionX + 10, listY),
                    Color = self.theme["Section Border"],
                    Filled = false,
                    Thickness = 1,
                    ZIndex = 12
                })
                
                playerList.rows = {}
                for i = 1, playerList.playersPerPage do
                    local rowY = listY + (i - 1) * 25
                    local rowBackground = create("Square", {
                        Size = Vector2.new(sectionWidth - 40, 25),
                        Position = Vector2.new(sectionX + 10, rowY),
                        Color = i % 2 == 0 and self.theme["Player Row Background"] or self.theme["Player Row Alt"],
                        Filled = true,
                        Thickness = 0,
                        ZIndex = 13
                    })
                    
                    local playerName = create("Text", {
                        Text = "",
                        Position = Vector2.new(sectionX + 15, rowY + 5),
                        Color = self.theme["Text"],
                        Size = 12,
                        Font = Drawing.Fonts.Monospace,
                        ZIndex = 14
                    })
                    
                    local status = create("Text", {
                        Text = "",
                        Position = Vector2.new(sectionX + 150, rowY + 5),
                        Color = self.theme["Text"],
                        Size = 12,
                        Font = Drawing.Fonts.Monospace,
                        ZIndex = 14
                    })
                    
                    local localPlayer = create("Text", {
                        Text = "",
                        Position = Vector2.new(sectionX + 250, rowY + 5),
                        Color = self.theme["Text"],
                        Size = 12,
                        Font = Drawing.Fonts.Monospace,
                        ZIndex = 14
                    })
                    
                    table.insert(playerList.rows, {
                        background = rowBackground,
                        playerName = playerName,
                        status = status,
                        localPlayer = localPlayer
                    })
                end
                
                playerList.pagination = create("Text", {
                    Text = "page 1 of",
                    Position = Vector2.new(sectionX + 15, listY + listHeight - 30),
                    Color = self.theme["Text"],
                    Size = 12,
                    Font = Drawing.Fonts.Monospace,
                    ZIndex = 15
                })
                
                playerList.noSelection = create("Text", {
                    Text = "no player selected",
                    Position = Vector2.new(sectionX + 15, listY + listHeight - 15),
                    Color = self.theme["Text"],
                    Size = 12,
                    Font = Drawing.Fonts.Monospace,
                    ZIndex = 15
                })
                
                function playerList:Update()
                    local startIndex = (self.currentPage - 1) * self.playersPerPage + 1
                    for i, row in ipairs(self.rows) do
                        local playerIndex = startIndex + i - 1
                        if playerIndex <= #self.players then
                            local player = self.players[playerIndex]
                            row.playerName.Text = player.name
                            row.status.Text = player.status
                            row.localPlayer.Text = player.localPlayer
                            
                            if player.status == "Ghosts" then
                                row.status.Color = self.theme["Ghosts"]
                            elseif player.status == "Phantoms" then
                                row.status.Color = self.theme["Phantoms"]
                            else
                                row.status.Color = self.theme["Text"]
                            end
                            
                            if player.localPlayer == "Local Player" then
                                row.localPlayer.Color = self.theme["Local Player"]
                            else
                                row.localPlayer.Color = self.theme["Text"]
                            end
                            
                            row.background.Visible = true
                            row.playerName.Visible = true
                            row.status.Visible = true
                            row.localPlayer.Visible = true
                        else
                            row.background.Visible = false
                            row.playerName.Visible = false
                            row.status.Visible = false
                            row.localPlayer.Visible = false
                        end
                    end
                end
                
                playerList:Update()
                table.insert(section.objects, playerList)
                return playerList
            end
            
            function section:CreateLabel(text)
                local label = create("Text", {
                    Text = text,
                    Position = Vector2.new(sectionX + 10, sectionY + 30 + (#section.objects * 25)),
                    Color = self.theme["Text"],
                    Size = 12,
                    Font = Drawing.Fonts.Monospace,
                    ZIndex = 11
                })
                
                table.insert(section.objects, label)
                return label
            end
            
            function section:CreateButton(config)
                local button = {}
                button.__index = button
                
                button.name = config.Name or "Button"
                button.callback = config.Callback or function() end
                button.hovered = false
                
                local buttonY = sectionY + 30 + (#section.objects * 30)
                
                button.background = create("Square", {
                    Size = Vector2.new(sectionWidth - 40, 25),
                    Position = Vector2.new(sectionX + 10, buttonY),
                    Color = self.theme["Object Background"],
                    Filled = true,
                    Thickness = 0,
                    ZIndex = 11
                })
                
                button.border = create("Square", {
                    Size = Vector2.new(sectionWidth - 40, 25),
                    Position = Vector2.new(sectionX + 10, buttonY),
                    Color = self.theme["Object Border"],
                    Filled = false,
                    Thickness = 1,
                    ZIndex = 12
                })
                
                button.text = create("Text", {
                    Text = button.name,
                    Position = Vector2.new(sectionX + 15, buttonY + 5),
                    Color = self.theme["Text"],
                    Size = 12,
                    Font = Drawing.Fonts.Monospace,
                    ZIndex = 13
                })
                
                function button:Update()
                    if button.hovered then
                        button.background.Color = self.theme["Accent"]
                    else
                        button.background.Color = self.theme["Object Background"]
                    end
                end
                
                table.insert(section.objects, button)
                return button
            end
            
            function section:CreateToggle(config)
                local toggle = {}
                toggle.__index = toggle
                
                toggle.name = config.Name or "Toggle"
                toggle.flag = config.Flag or "Toggle"
                toggle.default = config.Default or false
                toggle.callback = config.Callback or function() end
                toggle.value = toggle.default
                toggle.hovered = false
                
                BitchBot.flags[toggle.flag] = toggle.value
                
                local toggleY = sectionY + 30 + (#section.objects * 30)
                
                toggle.background = create("Square", {
                    Size = Vector2.new(sectionWidth - 40, 25),
                    Position = Vector2.new(sectionX + 10, toggleY),
                    Color = self.theme["Object Background"],
                    Filled = true,
                    Thickness = 0,
                    ZIndex = 11
                })
                
                toggle.border = create("Square", {
                    Size = Vector2.new(sectionWidth - 40, 25),
                    Position = Vector2.new(sectionX + 10, toggleY),
                    Color = self.theme["Object Border"],
                    Filled = false,
                    Thickness = 1,
                    ZIndex = 12
                })
                
                toggle.text = create("Text", {
                    Text = toggle.name,
                    Position = Vector2.new(sectionX + 15, toggleY + 5),
                    Color = self.theme["Text"],
                    Size = 12,
                    Font = Drawing.Fonts.Monospace,
                    ZIndex = 13
                })
                
                toggle.checkbox = create("Square", {
                    Size = Vector2.new(15, 15),
                    Position = Vector2.new(sectionX + sectionWidth - 35, toggleY + 5),
                    Color = toggle.value and self.theme["Accent"] or self.theme["Object Background"],
                    Filled = true,
                    Thickness = 0,
                    ZIndex = 14
                })
                
                toggle.checkboxBorder = create("Square", {
                    Size = Vector2.new(15, 15),
                    Position = Vector2.new(sectionX + sectionWidth - 35, toggleY + 5),
                    Color = self.theme["Object Border"],
                    Filled = false,
                    Thickness = 1,
                    ZIndex = 15
                })
                
                function toggle:Set(value)
                    self.value = value
                    BitchBot.flags[self.flag] = value
                    self.checkbox.Color = value and self.theme["Accent"] or self.theme["Object Background"]
                    self.callback(value)
                end
                
                function toggle:Update()
                    if self.hovered then
                        self.background.Color = self.theme["Accent"]
                    else
                        self.background.Color = self.theme["Object Background"]
                    end
                end
                
                table.insert(section.objects, toggle)
                return toggle
            end
            
            function section:CreateDropdown(config)
                local dropdown = {}
                dropdown.__index = dropdown
                
                dropdown.name = config.Name or "Dropdown"
                dropdown.flag = config.Flag or "Dropdown"
                dropdown.content = config.Content or {}
                dropdown.callback = config.Callback or function() end
                dropdown.open = false
                dropdown.selected = nil
                dropdown.hovered = false
                
                BitchBot.flags[dropdown.flag] = dropdown.selected
                
                local dropdownY = sectionY + 30 + (#section.objects * 30)
                
                dropdown.background = create("Square", {
                    Size = Vector2.new(sectionWidth - 40, 25),
                    Position = Vector2.new(sectionX + 10, dropdownY),
                    Color = self.theme["Object Background"],
                    Filled = true,
                    Thickness = 0,
                    ZIndex = 11
                })
                
                dropdown.border = create("Square", {
                    Size = Vector2.new(sectionWidth - 40, 25),
                    Position = Vector2.new(sectionX + 10, dropdownY),
                    Color = self.theme["Object Border"],
                    Filled = false,
                    Thickness = 1,
                    ZIndex = 12
                })
                
                dropdown.text = create("Text", {
                    Text = dropdown.name,
                    Position = Vector2.new(sectionX + 15, dropdownY + 5),
                    Color = self.theme["Text"],
                    Size = 12,
                    Font = Drawing.Fonts.Monospace,
                    ZIndex = 13
                })
                
                dropdown.valueText = create("Text", {
                    Text = dropdown.selected or "Select...",
                    Position = Vector2.new(sectionX + 15, dropdownY + 5),
                    Color = self.theme["Text"],
                    Size = 12,
                    Font = Drawing.Fonts.Monospace,
                    ZIndex = 13
                })
                
                dropdown.arrow = create("Text", {
                    Text = "v",
                    Position = Vector2.new(sectionX + sectionWidth - 25, dropdownY + 5),
                    Color = self.theme["Text"],
                    Size = 12,
                    Font = Drawing.Fonts.Monospace,
                    ZIndex = 13
                })
                
                dropdown.options = {}
                for i, option in ipairs(dropdown.content) do
                    local optionY = dropdownY + 30 + ((i - 1) * 25)
                    
                    local optionBackground = create("Square", {
                        Size = Vector2.new(sectionWidth - 40, 25),
                        Position = Vector2.new(sectionX + 10, optionY),
                        Color = self.theme["Dropdown Option Background"],
                        Filled = true,
                        Thickness = 0,
                        ZIndex = 16,
                        Visible = false
                    })
                    
                    local optionBorder = create("Square", {
                        Size = Vector2.new(sectionWidth - 40, 25),
                        Position = Vector2.new(sectionX + 10, optionY),
                        Color = self.theme["Object Border"],
                        Filled = false,
                        Thickness = 1,
                        ZIndex = 17,
                        Visible = false
                    })
                    
                    local optionText = create("Text", {
                        Text = option,
                        Position = Vector2.new(sectionX + 15, optionY + 5),
                        Color = self.theme["Text"],
                        Size = 12,
                        Font = Drawing.Fonts.Monospace,
                        ZIndex = 18,
                        Visible = false
                    })
                    
                    table.insert(dropdown.options, {
                        background = optionBackground,
                        border = optionBorder,
                        text = optionText,
                        value = option
                    })
                end
                
                function dropdown:Set(value)
                    self.selected = value
                    BitchBot.flags[self.flag] = value
                    self.valueText.Text = value or "Select..."
                    self.callback(value)
                end
                
                function dropdown:Toggle()
                    self.open = not self.open
                    for _, option in ipairs(self.options) do
                        option.background.Visible = self.open
                        option.border.Visible = self.open
                        option.text.Visible = self.open
                    end
                end
                
                function dropdown:Update()
                    if self.hovered then
                        self.background.Color = self.theme["Accent"]
                    else
                        self.background.Color = self.theme["Object Background"]
                    end
                end
                
                table.insert(section.objects, dropdown)
                return dropdown
            end
            
            table.insert(window.sections, section)
            table.insert(tab.sections, section)
            return section
        end
        
        table.insert(window.tabs, tab)
        return tab
    end
    
    function window:SetTab(tab)
        if window.currentTab then
            window.currentTab.visible = false
            for _, section in ipairs(window.currentTab.sections) do
                section.visible = false
            end
        end
        
        window.currentTab = tab
        tab.visible = true
        for _, section in ipairs(tab.sections) do
            section.visible = true
        end
        
        if tab == window.tabs[5] then
            tab.background.Color = self.theme["Tab Toggle Background"]
        else
            tab.background.Color = self.theme["Tab Background"]
        end
    end
    
    function window:Update()
        for _, tab in ipairs(window.tabs) do
            tab.background.Visible = window.visible
            tab.border.Visible = window.visible
            tab.text.Visible = window.visible
        end
        
        if window.currentTab then
            for _, section in ipairs(window.currentTab.sections) do
                section.background.Visible = window.visible and section.visible
                section.border.Visible = window.visible and section.visible
                section.title.Visible = window.visible and section.visible
                
                for _, obj in ipairs(section.objects) do
                    if obj.Visible ~= nil then
                        obj.Visible = window.visible and section.visible
                    end
                end
            end
        end
    end
    
    function window:Destroy()
        window.background:Remove()
        window.border:Remove()
        window.titleBar:Remove()
        window.titleText:Remove()
        
        for _, tab in ipairs(window.tabs) do
            tab.background:Remove()
            tab.border:Remove()
            tab.text:Remove()
        end
    end
    
    table.insert(self.windows, window)
    return window
end

function BitchBot:CreateWatermark(text)
    local watermark = {}
    watermark.__index = watermark
    
    watermark.text = text or "bitch bot | 60 fps | v4.20 | dev"
    watermark.visible = true
    
    watermark.background = create("Square", {
        Size = Vector2.new(200, 30),
        Position = Vector2.new(10, 10),
        Color = self.theme["Window Background"],
        Filled = true,
        Thickness = 0,
        ZIndex = 100
    })
    
    watermark.border = create("Square", {
        Size = Vector2.new(200, 30),
        Position = Vector2.new(10, 10),
        Color = self.theme["Accent"],
        Filled = false,
        Thickness = 1,
        ZIndex = 101
    })
    
    watermark.textObj = create("Text", {
        Text = watermark.text,
        Position = Vector2.new(15, 15),
        Color = self.theme["Text"],
        Size = 12,
        Font = Drawing.Fonts.Monospace,
        ZIndex = 102
    })
    
    function watermark:Set(text)
        self.text = text
        self.textObj.Text = text
    end
    
    function watermark:Hide()
        self.visible = false
        self.background.Visible = false
        self.border.Visible = false
        self.textObj.Visible = false
    end
    
    function watermark:Show()
        self.visible = true
        self.background.Visible = true
        self.border.Visible = true
        self.textObj.Visible = true
    end
    
    return watermark
end

function BitchBot:Unload()
    for _, window in ipairs(self.windows) do
        window:Destroy()
    end
    
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
end

function BitchBot:Close()
    for _, window in ipairs(self.windows) do
        window.visible = false
        window:Update()
    end
end

function BitchBot:Open()
    for _, window in ipairs(self.windows) do
        window.visible = true
        window:Update()
    end
end

return BitchBot
