--[[
    Ultimate Client-Sided Anti-Cheat Test GUI
    Purpose: To test the detection and prevention capabilities of your anti-cheat.
    This script is purely client-sided and does not require a server script.
]]

--//================================\\--
--// Services & Core Variables      \\--
--//================================\\--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()

-- State variables for toggles
local state = {
    fly = false,
    noclip = false,
    infJump = false,
    esp = false,
    clickDelete = false,
    clickTeleport = false,
}

-- For managing loops and connections
local connections = {}

--//================================\\--
--// GUI Creation & Management      \\--
--//================================\\--

-- Cleanup previous GUI
if CoreGui:FindFirstChild("TestGUIMain") then
    CoreGui.TestGUIMain:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TestGUIMain"
screenGui.Parent = CoreGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.Size = UDim2.new(0, 500, 0, 400)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
mainFrame.Active = true
mainFrame.Draggable = true

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Parent = mainFrame
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
title.Text = "Client-Sided Test Suite"
title.Font = Enum.Font.SourceSansBold
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "ContentFrame"
contentFrame.Parent = mainFrame
contentFrame.Size = UDim2.new(1, -10, 1, -35)
contentFrame.Position = UDim2.new(0, 5, 0, 35)
contentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
contentFrame.BorderSizePixel = 0
contentFrame.CanvasSize = UDim2.new(0, 0, 2, 0) -- Expandable canvas
contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = contentFrame
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

--//================================\\--
--// UI Element Factory Functions   \\--
--//================================\\--

local function createCategory(text, order)
    local label = Instance.new("TextLabel")
    label.Name = text
    label.Parent = contentFrame
    label.Size = UDim2.new(1, 0, 0, 25)
    label.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    label.Text = "--- " .. text .. " ---"
    label.Font = Enum.Font.SourceSansSemibold
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 16
    label.LayoutOrder = order
    return label
end

local function createSlider(text, min, max, initial, order, callback)
    local container = Instance.new("Frame")
    container.Parent = contentFrame
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    container.BorderSizePixel = 0
    container.LayoutOrder = order
    
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.Text = text .. ": " .. initial
    label.Font = Enum.Font.SourceSans
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local slider = Instance.new("Slider", container)
    slider.Size = UDim2.new(1, -10, 0, 20)
    slider.Position = UDim2.new(0, 5, 0, 25)
    slider.MinValue = min
    slider.MaxValue = max
    slider.Value = initial
    
    slider.ValueChanged:Connect(function(value)
        local displayValue = math.floor(value * 10) / 10
        label.Text = text .. ": " .. displayValue
        callback(value)
    end)
end

local function createToggle(text, order, callback)
    local button = Instance.new("TextButton")
    button.Parent = contentFrame
    button.Size = UDim2.new(1, 0, 0, 30)
    button.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red for 'Off'
    button.Text = text .. " [OFF]"
    button.Font = Enum.Font.SourceSansBold
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.LayoutOrder = order
    
    local toggled = false
    button.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
            button.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- Green for 'On'
            button.Text = text .. " [ON]"
        else
            button.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red for 'Off'
            button.Text = text .. " [OFF]"
        end
        callback(toggled)
    end)
end

local function createButton(text, order, callback)
    local button = Instance.new("TextButton")
    button.Parent = contentFrame
    button.Size = UDim2.new(1, 0, 0, 30)
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    button.Text = text
    button.Font = Enum.Font.SourceSansBold
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.LayoutOrder = order
    button.MouseButton1Click:Connect(callback)
end

local function createDropdown(text, order, getValuesFunc)
    local container = Instance.new("Frame")
    container.Parent = contentFrame
    container.Size = UDim2.new(1, 0, 0, 30)
    container.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    container.BorderSizePixel = 0
    container.LayoutOrder = order
    
    local dropdown = Instance.new("DropDown", container)
    dropdown.Size = UDim2.new(1, 0, 1, 0)
    
    local function updateValues()
        local selected = dropdown.Value
        dropdown:Clear()
        local values = getValuesFunc()
        dropdown:UpdateValues(values)
        if table.find(values, selected) then
            dropdown.Value = selected
        end
    end
    
    updateValues()
    Players.PlayerAdded:Connect(updateValues)
    Players.PlayerRemoving:Connect(updateValues)
    
    return dropdown
end

--//================================\\--
--// Cheat Function Implementations \\--
--//================================\\--

-- Get Character & Humanoid safely
local function getCharacter()
    return localPlayer.Character
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- WalkSpeed & JumpPower
local originalWalkSpeed = 16
local originalJumpPower = 50
local originalHipHeight = nil -- Will be set on first use

createCategory("Player Stats", 1)
createSlider("WalkSpeed", 16, 200, 16, 2, function(value)
    local humanoid = getHumanoid()
    if humanoid then humanoid.WalkSpeed = value end
end)
createSlider("JumpPower", 50, 300, 50, 3, function(value)
    local humanoid = getHumanoid()
    if humanoid then humanoid.JumpPower = value end
end)
createSlider("HipHeight", 0.1, 20, 2, 4, function(value)
    local humanoid = getHumanoid()
    if humanoid then
        if not originalHipHeight then
            originalHipHeight = humanoid.HipHeight
        end
        humanoid.HipHeight = value
    end
end)

-- Fly
local flyBodyVelocity, flyBodyGyro
createCategory("Movement", 10)
createToggle("Fly", 11, function(enabled)
    state.fly = enabled
    local humanoid = getHumanoid()
    local char = getCharacter()
    if not humanoid or not char then return end

    if enabled then
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.P = 9e4
        flyBodyGyro.Parent = char.HumanoidRootPart
        
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBodyVelocity.Parent = char.HumanoidRootPart
        
        if connections.flyLoop then connections.flyLoop:Disconnect() end
        connections.flyLoop = RunService.RenderStepped:Connect(function()
            local flySpeed = 50
            local velocity = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then velocity = velocity + Workspace.CurrentCamera.CFrame.lookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then velocity = velocity - Workspace.CurrentCamera.CFrame.lookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then velocity = velocity - Workspace.CurrentCamera.CFrame.rightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then velocity = velocity + Workspace.CurrentCamera.CFrame.rightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then velocity = velocity + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then velocity = velocity - Vector3.new(0,1,0) end
            
            flyBodyGyro.CFrame = Workspace.CurrentCamera.CFrame
            if velocity.Magnitude > 0 then
                flyBodyVelocity.Velocity = velocity.Unit * flySpeed
            else
                flyBodyVelocity.Velocity = Vector3.new(0,0,0)
            end
        end)
    else
        if flyBodyGyro then flyBodyGyro:Destroy() end
        if flyBodyVelocity then flyBodyVelocity:Destroy() end
        if connections.flyLoop then connections.flyLoop:Disconnect() end
    end
end)

-- Noclip
createToggle("Noclip", 12, function(enabled)
    state.noclip = enabled
    if connections.noclipLoop then connections.noclipLoop:Disconnect() end
    
    if enabled then
        connections.noclipLoop = RunService.Stepped:Connect(function()
            local char = getCharacter()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        -- Note: Noclip doesn't auto-revert part collision states.
        -- A proper anti-cheat should handle respawning the character.
    end
end)

-- Infinite Jump
createToggle("Infinite Jump", 13, function(enabled)
    state.infJump = enabled
    if enabled then
        connections.infJump = UserInputService.JumpRequest:Connect(function()
            local humanoid = getHumanoid()
            if humanoid and state.infJump then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if connections.infJump then connections.infJump:Disconnect() end
    end
end)

-- ESP
local espElements = {}
createCategory("Visuals", 20)
createToggle("ESP", 21, function(enabled)
    state.esp = enabled
    if connections.espLoop then connections.espLoop:Disconnect() end
    
    if enabled then
        connections.espLoop = RunService.RenderStepped:Connect(function()
            local camera = Workspace.CurrentCamera
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = player.Character.HumanoidRootPart
                    local humanoid = player.Character.Humanoid
                    local head = player.Character:FindFirstChild("Head")

                    local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)
                    
                    if onScreen then
                        if not espElements[player] then
                            -- Create ESP elements
                            local box = Instance.new("Frame")
                            box.Name = "Box"
                            box.Parent = screenGui
                            box.BorderSizePixel = 2
                            box.BorderColor3 = Color3.fromRGB(255, 0, 0)
                            box.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                            box.BackgroundTransparency = 1
                            
                            local nameLabel = Instance.new("TextLabel", box)
                            nameLabel.Text = player.Name
                            nameLabel.Font = Enum.Font.SourceSans
                            nameLabel.TextSize = 14
                            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                            nameLabel.BackgroundTransparency = 1
                            nameLabel.Position = UDim2.new(0, 0, 0, -20)
                            nameLabel.Size = UDim2.new(1, 0, 0, 20)
                            
                            local healthBar = Instance.new("Frame", box)
                            healthBar.Name = "HealthBar"
                            healthBar.Size = UDim2.new(0, 4, 1, 0)
                            healthBar.Position = UDim2.new(0, -7, 0, 0)
                            healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                            healthBar.BorderColor3 = Color3.fromRGB(0,0,0)
                            
                            espElements[player] = {Box = box, Name = nameLabel, Health = healthBar}
                        end
                        
                        -- Update ESP elements
                        local size = math.clamp(5000 / vector.Z, 30, 200)
                        local esp = espElements[player]
                        esp.Box.Position = UDim2.fromOffset(vector.x - size/2, vector.y - size/2)
                        esp.Box.Size = UDim2.fromOffset(size, size)
                        esp.Health.Size = UDim2.new(0, 4, humanoid.Health/humanoid.MaxHealth, 0)
                        esp.Health.BackgroundColor3 = Color3.fromHSV(humanoid.Health/humanoid.MaxHealth * 0.33, 1, 1)

                    elseif espElements[player] then
                        -- Hide if off-screen
                        espElements[player].Box.Visible = false
                    end
                    if espElements[player] and not espElements[player].Box.Visible then
                         espElements[player].Box.Visible = true
                    end
                else
                    if espElements[player] then
                        -- Cleanup if player leaves or character is gone
                        espElements[player].Box:Destroy()
                        espElements[player] = nil
                    end
                end
            end
        end)
    else
        -- Cleanup all ESP elements
        for _, elements in pairs(espElements) do
            elements.Box:Destroy()
        end
        espElements = {}
    end
end)

-- Teleport
createCategory("Teleport", 30)
local playerDropdown = createDropdown("Target Player", 31, function()
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= localPlayer then table.insert(names, p.Name) end
    end
    return names
end)
createButton("Teleport to Player", 32, function()
    local targetName = playerDropdown.Value
    local targetPlayer = Players:FindFirstChild(targetName)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local char = getCharacter()
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
        end
    end
end)
createToggle("Click Teleport", 33, function(enabled)
    state.clickTeleport = enabled
    if connections.clickTp then connections.clickTp:Disconnect() end
    if enabled then
        connections.clickTp = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if state.clickTeleport and input.UserInputType == Enum.UserInputType.MouseButton1 then
                local char = getCharacter()
                if char and char:FindFirstChild("HumanoidRootPart") and mouse.Target then
                     char.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
                end
            end
        end)
    end
end)

-- Misc Cheats
createCategory("Misc", 40)
createButton("FE God Mode (Visual)", 41, function()
    local char = getCharacter()
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:Destroy()
    end
end)
createButton("Give BTools", 42, function()
    local char = getCharacter()
    if char then
        local toolNames = {"Clone", "Copy", "Delete"}
        for _, name in ipairs(toolNames) do
            local tool = Instance.new("HopperBin")
            tool.Name = name .. " Tool"
            tool.BinType = Enum.BinType[name]
            tool.Parent = localPlayer.Backpack
        end
    end
end)
createToggle("Click Delete", 43, function(enabled)
    state.clickDelete = enabled
    if connections.clickDel then connections.clickDel:Disconnect() end
    if enabled then
        connections.clickDel = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if state.clickDelete and input.UserInputType == Enum.UserInputType.MouseButton1 then
                if mouse.Target and mouse.Target.Parent ~= Workspace then
                    mouse.Target:Destroy()
                end
            end
        end)
    end
end)

print("Client-Sided Test Suite Loaded.")
