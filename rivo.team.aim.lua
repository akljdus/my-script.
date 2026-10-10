-- Rivo Team Script - Fully Decrypted & Unlocked (Fixed Navigation)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ================= CONFIGURATION =================
local espInventoryEnabled = true 
local MAX_DISTANCE = 2000 
local UPDATE_INTERVAL = 1 
local BillboardCache = {}
local nameCache = {} 
local RARITY_COLORS = {
    ["Common"] = Color3.fromRGB(255, 255, 255),
    ["Uncommon"] = Color3.fromRGB(99, 255, 52),
    ["Rare"] = Color3.fromRGB(51, 170, 255),
    ["Epic"] = Color3.fromRGB(237, 44, 255),
    ["Legendary"] = Color3.fromRGB(255, 150, 0),
    ["Omega"] = Color3.fromRGB(255, 20, 51),
}

local function getRealName(t)
    if not t or not t.Name then return nil end
    
    local originalName = t.Name
    local lowerName = originalName:lower()

    local cleaned = lowerName
        :gsub("%d+$", "")
        :gsub("_%d+$", "")
        :gsub("%s*%d+%s*$", "")
        :gsub("[%s_]+", " ")
        :gsub("([^%w%s])", "")
        :match("^%s*(.-)%s*$")

    if cleaned:find("fishing") or cleaned:find("rod") or cleaned:find("canne") or cleaned:find("pêche") then
        if cleaned:find("ultimate") or cleaned:find("ult") then
            return "Ultimate Fishing Rod"
        elseif cleaned:find("advanced") then
            return "Advanced Fishing Rod"
        elseif cleaned:find("pro") then
            return "Pro Fishing Rod"
        else
            return "Regular Fishing Rod"
        end
    end

    if nameCache[originalName] then 
        return nameCache[originalName] 
    end
    
    local h = t:FindFirstChild("Handle")
    local fallbackName = cleaned
    
    for _, folder in ipairs({ReplicatedStorage:FindFirstChild("Items"), StarterPack}) do
        if folder then
            for _, item in ipairs(folder:GetDescendants()) do
                if item:IsA("Tool") and item:FindFirstChild("Handle") then
                    local match = true
                    if h then
                        for _, c in ipairs(h:GetChildren()) do
                            if not item.Handle:FindFirstChild(c.Name) then 
                                match = false 
                                break 
                            end
                        end
                    else
                        match = false
                    end
                    if match then 
                        nameCache[originalName] = item.Name 
                        return item.Name 
                    end
                end
            end
        end
    end
    
    nameCache[originalName] = fallbackName
    return fallbackName
end

local function updateESP(p)
    local bb = BillboardCache[p]
    if not bb then return end
    
    local char = p.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then 
        bb.Enabled = false
        return 
    end
    
    local lChar = LocalPlayer.Character
    if lChar and lChar:FindFirstChild("HumanoidRootPart") then
        local dist = (lChar.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
        if dist > MAX_DISTANCE then
            bb.Enabled = false
            return
        end
    end

    local container = bb:FindFirstChild("EspContainer")
    if not container then return end
    container:ClearAllChildren()

    local layout = Instance.new("UIListLayout", container)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom 
    layout.Padding = UDim.new(0, 2)

    local tools = {}
    if p:FindFirstChild("Backpack") then
        for _, t in ipairs(p.Backpack:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower() ~= "fists" then table.insert(tools, t) end
        end
    end
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower() ~= "fists" then table.insert(tools, t) end
        end
    end

    bb.Enabled = espInventoryEnabled and (#tools > 0)
    
    for _, tool in ipairs(tools) do
        local name = getRealName(tool)
        if name then
            local lbl = Instance.new("TextLabel", container)
            lbl.Size = UDim2.new(0, 180, 0, 14)
            lbl.BackgroundTransparency = 1
            lbl.Text = name
            lbl.Font = Enum.Font.SourceSansBold
            lbl.TextSize = 11
            lbl.TextStrokeTransparency = 0.4
            
            local rarity = tool:GetAttribute("RarityName") or tool:GetAttribute("Rarity")
            lbl.TextColor3 = RARITY_COLORS[rarity] or Color3.new(1, 1, 1)
        end
    end
end

local function createESP(p)
    if p == LocalPlayer then return end
    
    local function setup(char)
        local root = char:WaitForChild("HumanoidRootPart", 15)
        if not root then return end
        
        if BillboardCache[p] then BillboardCache[p]:Destroy() end
        
        local bb = Instance.new("BillboardGui", root)
        bb.Name = "FixedUnderfootESP"
        bb.Size = UDim2.new(0, 200, 0, 150)
        bb.StudsOffset = Vector3.new(0, -3.5, 0) 
        bb.AlwaysOnTop = true
        bb.MaxDistance = MAX_DISTANCE
        
        local cont = Instance.new("Frame", bb)
        cont.Name = "EspContainer"
        cont.Size = UDim2.new(1, 0, 1, 0)
        cont.BackgroundTransparency = 1
        
        BillboardCache[p] = bb

        updateESP(p)
        
        char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then task.wait(0.1); updateESP(p) end
        end)
        char.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") then task.wait(0.1); updateESP(p) end
        end)
        
        local backpack = p:WaitForChild("Backpack", 5)
        if backpack then
            backpack.ChildAdded:Connect(function() updateESP(p) end)
            backpack.ChildRemoved:Connect(function() updateESP(p) end)
        end

        task.spawn(function()
            while char.Parent and bb.Parent do
                updateESP(p)
                task.wait(UPDATE_INTERVAL)
            end
        end)
    end
    
    p.CharacterAdded:Connect(setup)
    if p.Character then setup(p.Character) end
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)

-- ================= INTERFACE =================
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "RivoTeam_HUB"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false

-- Device Selection Prompt (Mobile vs PC)
local SelectGui = Instance.new("ScreenGui", game.CoreGui)
SelectGui.Name = "RivoTeam_DeviceSelector"
SelectGui.IgnoreGuiInset = true
SelectGui.ResetOnSpawn = false

local SelectFrame = Instance.new("Frame", SelectGui)
SelectFrame.Size = UDim2.new(0, 320, 0, 180)
SelectFrame.Position = UDim2.new(0.5, -160, 0.5, -90)
SelectFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SelectFrame.BorderSizePixel = 0
Instance.new("UICorner", SelectFrame).CornerRadius = UDim.new(0, 12)

local SelectTitle = Instance.new("TextLabel", SelectFrame)
SelectTitle.Size = UDim2.new(1, 0, 0, 40)
SelectTitle.BackgroundTransparency = 1
SelectTitle.Text = "CHOOSE YOUR DEVICE"
SelectTitle.TextColor3 = Color3.fromRGB(0, 255, 0)
SelectTitle.TextScaled = true
SelectTitle.Font = Enum.Font.SourceSansBold

local MobileBtn = Instance.new("TextButton", SelectFrame)
MobileBtn.Size = UDim2.new(0.8, 0, 0, 45)
MobileBtn.Position = UDim2.new(0.1, 0, 0.35, 0)
MobileBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
MobileBtn.Text = "📱 Mobile"
MobileBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MobileBtn.TextScaled = true
Instance.new("UICorner", MobileBtn).CornerRadius = UDim.new(0, 8)

local PCBtn = Instance.new("TextButton", SelectFrame)
PCBtn.Size = UDim2.new(0.8, 0, 0, 45)
PCBtn.Position = UDim2.new(0.1, 0, 0.68, 0)
PCBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
PCBtn.Text = "💻 PC (Press G)"
PCBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PCBtn.TextScaled = true
Instance.new("UICorner", PCBtn).CornerRadius = UDim.new(0, 8)

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 450)
MainFrame.Position = UDim2.new(0.3, 0, 0.18, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,8)

local isMobileMode = false

-- Mobile Toggle Button (Open / Close)
local ToggleButton = Instance.new("TextButton", ScreenGui)
ToggleButton.Size = UDim2.new(0,100,0,40)
ToggleButton.Position = UDim2.new(0.85,0,0.05,0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(255,0,0)
ToggleButton.Text = "فتح"
ToggleButton.TextColor3 = Color3.fromRGB(255,255,255)
ToggleButton.TextScaled = true
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0,8)
ToggleButton.Visible = false

local ToggleDrag = Instance.new("Frame", ToggleButton)
ToggleDrag.Size = UDim2.new(1,0,1,0)
ToggleDrag.BackgroundTransparency = 1

MobileBtn.MouseButton1Click:Connect(function()
    isMobileMode = true
    MainFrame.Size = UDim2.new(0, 280, 0, 380)
    MainFrame.Position = UDim2.new(1, -290, 0, 60)
    MainFrame.Visible = false
    ToggleButton.Visible = true
    SelectGui:Destroy()
end)

PCBtn.MouseButton1Click:Connect(function()
    isMobileMode = false
    MainFrame.Visible = false
    ToggleButton.Visible = false
    SelectGui:Destroy()
end)

-- Toggle Button Logic for Mobile
ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    if MainFrame.Visible then
        ToggleButton.Text = "إغلاق"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0,255,0)
    else
        ToggleButton.Text = "فتح"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255,0,0)
    end
end)

local TitleLabel = Instance.new("TextLabel", MainFrame)
TitleLabel.Size = UDim2.new(0.8,0,0.08,0)
TitleLabel.Position = UDim2.new(0.1,0,0.02,0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🔥 RIVO TEAM HACK 🔥"
TitleLabel.TextColor3 = Color3.fromRGB(0,255,0)
TitleLabel.TextScaled = true
TitleLabel.Font = Enum.Font.SourceSansBold

local MainDrag = Instance.new("Frame", MainFrame)
MainDrag.Size = UDim2.new(1,0,0.1,0)
MainDrag.BackgroundTransparency = 1

local ESPInventoryToggle = Instance.new("TextButton", MainFrame)
ESPInventoryToggle.Size = UDim2.new(0.8,0,0.1,0)
ESPInventoryToggle.Position = UDim2.new(0.1,0,0.12,0)
ESPInventoryToggle.BackgroundColor3 = Color3.fromRGB(0,255,0)
ESPInventoryToggle.Text = "ESP Inventory: ON"
ESPInventoryToggle.TextScaled = true
Instance.new("UICorner", ESPInventoryToggle).CornerRadius = UDim.new(0,8)

local ESPToggle = Instance.new("TextButton", MainFrame)
ESPToggle.Size = UDim2.new(0.8,0,0.1,0)
ESPToggle.Position = UDim2.new(0.1,0,0.24,0)
ESPToggle.BackgroundColor3 = Color3.fromRGB(255,0,0)
ESPToggle.Text = "ESP: OFF"
ESPToggle.TextScaled = true
Instance.new("UICorner", ESPToggle).CornerRadius = UDim.new(0,8)

local AimbotToggle = Instance.new("TextButton", MainFrame)
AimbotToggle.Size = UDim2.new(0.8,0,0.1,0)
AimbotToggle.Position = UDim2.new(0.1,0,0.36,0)
AimbotToggle.BackgroundColor3 = Color3.fromRGB(255,0,0)
AimbotToggle.Text = "Aimbot: OFF"
AimbotToggle.TextScaled = true
Instance.new("UICorner", AimbotToggle).CornerRadius = UDim.new(0,8)

local WallcheckToggle = Instance.new("TextButton", MainFrame)
WallcheckToggle.Size = UDim2.new(0.8,0,0.1,0)
WallcheckToggle.Position = UDim2.new(0.1,0,0.48,0)
WallcheckToggle.BackgroundColor3 = Color3.fromRGB(0,255,0)
WallcheckToggle.Text = "Wallcheck: ON"
WallcheckToggle.TextScaled = true
WallcheckToggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", WallcheckToggle).CornerRadius = UDim.new(0,8)

local FOVSlider = Instance.new("TextBox", MainFrame)
FOVSlider.Size = UDim2.new(0.8,0,0.1,0)
FOVSlider.Position = UDim2.new(0.1,0,0.60,0)
FOVSlider.BackgroundColor3 = Color3.fromRGB(50,50,50)
FOVSlider.Text = "FOV: 70"
FOVSlider.TextColor3 = Color3.fromRGB(255,0,0)
FOVSlider.TextScaled = true
Instance.new("UICorner", FOVSlider).CornerRadius = UDim.new(0,8)

local AimPartToggle = Instance.new("TextButton", MainFrame)
AimPartToggle.Size = UDim2.new(0.8,0,0.1,0)
AimPartToggle.Position = UDim2.new(0.1,0,0.72,0)
AimPartToggle.BackgroundColor3 = Color3.fromRGB(100,100,255)
AimPartToggle.Text = "Target: Head (fixed)"
AimPartToggle.TextScaled = true
AimPartToggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", AimPartToggle).CornerRadius = UDim.new(0,8)

local FOVCircleToggle = Instance.new("TextButton", MainFrame)
FOVCircleToggle.Size = UDim2.new(0.8,0,0.1,0)
FOVCircleToggle.Position = UDim2.new(0.1,0,0.84,0)
FOVCircleToggle.BackgroundColor3 = Color3.fromRGB(0,255,0)
FOVCircleToggle.Text = "FOV Circle: ON"
FOVCircleToggle.TextScaled = true
FOVCircleToggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", FOVCircleToggle).CornerRadius = UDim.new(0,8)

-- Friend / Player Selector Button (Works on PC and Mobile)
local FriendMenuBtn = Instance.new("TextButton", MainFrame)
FriendMenuBtn.Size = UDim2.new(0.8,0,0.1,0)
FriendMenuBtn.Position = UDim2.new(0.1,0,0.96,0)
FriendMenuBtn.BackgroundColor3 = Color3.fromRGB(150,0,255)
FriendMenuBtn.Text = "👥 اختيار صديق (Protected)"
FriendMenuBtn.TextScaled = true
FriendMenuBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", FriendMenuBtn).CornerRadius = UDim.new(0,8)

-- Fullscreen / Separate Friend Menu Frame
local FriendMenuFrame = Instance.new("Frame", ScreenGui)
FriendMenuFrame.Size = UDim2.new(0, 350, 0, 450)
FriendMenuFrame.Position = UDim2.new(0.3, 0, 0.18, 0)
FriendMenuFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
FriendMenuFrame.BorderSizePixel = 0
FriendMenuFrame.Visible = false
Instance.new("UICorner", FriendMenuFrame).CornerRadius = UDim.new(0,8)

local FriendTitle = Instance.new("TextLabel", FriendMenuFrame)
FriendTitle.Size = UDim2.new(0.8,0,0.1,0)
FriendTitle.Position = UDim2.new(0.1,0,0.03,0)
FriendTitle.BackgroundTransparency = 1
FriendTitle.Text = "قائمة اختيار الأصدقاء"
FriendTitle.TextColor3 = Color3.fromRGB(255,255,255)
FriendTitle.TextScaled = true
FriendTitle.Font = Enum.Font.SourceSansBold

local BackButton = Instance.new("TextButton", FriendMenuFrame)
BackButton.Size = UDim2.new(0.8,0,0.1,0)
BackButton.Position = UDim2.new(0.1,0,0.85,0)
BackButton.BackgroundColor3 = Color3.fromRGB(255,50,50)
BackButton.Text = "رجوع"
BackButton.TextScaled = true
BackButton.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", BackButton).CornerRadius = UDim.new(0,8)

local PlayerListFrame = Instance.new("ScrollingFrame", FriendMenuFrame)
PlayerListFrame.Size = UDim2.new(0.8,0,0.65,0)
PlayerListFrame.Position = UDim2.new(0.1,0,0.16,0)
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
PlayerListFrame.ScrollBarThickness = 6
PlayerListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", PlayerListFrame).CornerRadius = UDim.new(0,8)

local PlayerListLayout = Instance.new("UIListLayout", PlayerListFrame)
PlayerListLayout.Padding = UDim.new(0,4)

-- ================= VARIABLES =================
local espEnabledStatus = false
local AimbotOn = false
local FOVRadius = 70
local WallCheckEnabled = true
local FOVCircleVisible = true
local FOVCircleForcedOff = false
local ProtectedPlayers = {}
local PlayerButtons = {}
local AIM_SMOOTHNESS = 0.8
local guiOpen = false

local FOVCircle = Drawing.new("Circle")
FOVCircle.Radius = FOVRadius
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(255,0,0)
FOVCircle.Transparency = 0.6
FOVCircle.Filled = false
FOVCircle.Visible = false

local AIM_MODES = {
    {name = "Head (fixed)", parts = "Head", color = Color3.fromRGB(100,100,255)},
    {name = "Torso (fixed)", parts = "HumanoidRootPart", color = Color3.fromRGB(255,150,50)},
}
local currentModeIndex = 1

local function IsAlive(char)
    local h = char and char:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function IsVisible(part)
    if not part then return false end
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character or workspace, part.Parent}
    local result = workspace:Raycast(origin, direction, params)
    return not result
end

local function removeESP(char)
    if char then
        local head = char:FindFirstChild("Head")
        if head then local b = head:FindFirstChild("RivoNameHP") if b then b:Destroy() end end
        local h = char:FindFirstChild("RivoHighlight") if h then h:Destroy() end
    end
end

local function applyESP(char)
    local plr = Players:GetPlayerFromCharacter(char)
    if not plr or plr == LocalPlayer then return end
    removeESP(char)

    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not head or not hum or not IsAlive(char) then return end

    local bill = Instance.new("BillboardGui", head)
    bill.Name = "RivoNameHP"
    bill.Adornee = head
    bill.Size = UDim2.new(0,160,0,35)
    bill.StudsOffset = Vector3.new(0,2.8,0)
    bill.AlwaysOnTop = true

    local name = Instance.new("TextLabel", bill)
    name.Size = UDim2.new(1,0,0,16)
    name.BackgroundTransparency = 1
    name.Text = plr.DisplayName ~= plr.Name and (plr.DisplayName .. " (@" .. plr.Name .. ")") or plr.Name
    name.TextColor3 = Color3.new(1,1,1)
    name.TextStrokeTransparency = 0
    name.Font = Enum.Font.SourceSansBold
    name.TextSize = 14

    local hl = Instance.new("Highlight", char)
    hl.Name = "RivoHighlight"
    hl.OutlineColor = Color3.fromRGB(255,255,0)
    hl.OutlineTransparency = 0
    hl.FillTransparency = 1
end

local function UpdateProtectedList()
    for _, b in ipairs(PlayerButtons) do 
        if b and b.Parent then b:Destroy() end 
    end
    PlayerButtons = {}
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local btn = Instance.new("TextButton", PlayerListFrame)
            btn.Size = UDim2.new(1,-10,0,30)
            local prot = ProtectedPlayers[p] or false
            btn.BackgroundColor3 = prot and Color3.fromRGB(0,100,255) or Color3.fromRGB(60,60,60)
            btn.Text = p.DisplayName .. (prot and " ✔ (محمي)" or "")
            btn.TextColor3 = Color3.new(1,1,1)
            btn.TextScaled = true
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
            table.insert(PlayerButtons, btn)

            btn.MouseButton1Click:Connect(function()
                ProtectedPlayers[p] = not ProtectedPlayers[p]
                UpdateProtectedList()
            end)
        end
    end
end

Players.PlayerAdded:Connect(UpdateProtectedList)
Players.PlayerRemoving:Connect(UpdateProtectedList)
UpdateProtectedList()

-- Friend Menu Switching Logic (Fixed Return)
FriendMenuBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    UpdateProtectedList()
    FriendMenuFrame.Visible = true
end)

BackButton.MouseButton1Click:Connect(function()
    FriendMenuFrame.Visible = false
    MainFrame.Visible = true
    -- إذا كان وضع الجوال مفعلاً، يتم تحديث زر الفتح والإغلاق ليتطابق مع حالة القائمة
    if isMobileMode then
        ToggleButton.Text = "إغلاق"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0,255,0)
    end
end)

local function GetTargetPart(char)
    local mode = AIM_MODES[currentModeIndex]
    return char:FindFirstChild(mode.parts) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function GetClosest()
    local closest, distMin = nil, math.huge
    local center = Camera.ViewportSize / 2
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not ProtectedPlayers[p] and p.Character and IsAlive(p.Character) then
            local part = GetTargetPart(p.Character)
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < distMin and dist <= FOVRadius then
                        if not WallCheckEnabled or IsVisible(part) then
                            distMin = dist
                            closest = p
                        end
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Camera.ViewportSize / 2
    FOVCircle.Radius = FOVRadius
    FOVCircle.Visible = AimbotOn and FOVCircleVisible and not FOVCircleForcedOff
    
    if AimbotOn then
        local target = GetClosest()
        if target and target.Character then
            local part = GetTargetPart(target.Character)
            if part then
                local cf = CFrame.new(Camera.CFrame.Position, part.Position)
                Camera.CFrame = Camera.CFrame:Lerp(cf, AIM_SMOOTHNESS)
            end
        end
    end
end)

-- ================= BUTTONS LOGIC =================
ESPToggle.MouseButton1Click:Connect(function()
    espEnabledStatus = not espEnabledStatus
    ESPToggle.Text = "ESP: " .. (espEnabledStatus and "ON" or "OFF")
    ESPToggle.BackgroundColor3 = espEnabledStatus and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if espEnabledStatus then applyESP(p.Character) else removeESP(p.Character) end
        end
    end
end)

AimbotToggle.MouseButton1Click:Connect(function()
    AimbotOn = not AimbotOn
    AimbotToggle.Text = "Aimbot: " .. (AimbotOn and "ON" or "OFF")
    AimbotToggle.BackgroundColor3 = AimbotOn and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
end)

AimPartToggle.MouseButton1Click:Connect(function()
    currentModeIndex = currentModeIndex % #AIM_MODES + 1
    local mode = AIM_MODES[currentModeIndex]
    AimPartToggle.Text = "Target: " .. mode.name
end)

WallcheckToggle.MouseButton1Click:Connect(function()
    WallCheckEnabled = not WallCheckEnabled
    WallcheckToggle.Text = "Wallcheck: " .. (WallCheckEnabled and "ON" or "OFF")
    WallcheckToggle.BackgroundColor3 = WallCheckEnabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,100,100)
end)

FOVSlider.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local num = tonumber(FOVSlider.Text:match("%d+"))
        if num and num >= 20 and num <= 600 then
            FOVRadius = num
            FOVCircle.Radius = num
            FOVSlider.Text = "FOV: " .. num
        else
            FOVSlider.Text = "FOV: " .. FOVRadius
        end
    end
end)

FOVCircleToggle.MouseButton1Click:Connect(function()
    FOVCircleVisible = not FOVCircleVisible
    FOVCircleToggle.Text = "FOV Circle: " .. (FOVCircleVisible and "ON" or "OFF")
    FOVCircleToggle.BackgroundColor3 = FOVCircleVisible and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
end)

ESPInventoryToggle.MouseButton1Click:Connect(function()
    espInventoryEnabled = not espInventoryEnabled
    ESPInventoryToggle.Text = "ESP Inventory: " .. (espInventoryEnabled and "ON" or "OFF")
    ESPInventoryToggle.BackgroundColor3 = espInventoryEnabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
    for _, p in ipairs(Players:GetPlayers()) do updateESP(p) end
end)

-- ================= DRAG & PC KEYS =================
local function makeDraggable(frame, dragArea)
    local dragging, startPos, startMouse
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = frame.Position
            startMouse = input.Position
        end
    end)
    dragArea.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startMouse
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            dragging = false 
        end
    end)
end

makeDraggable(MainFrame, MainDrag)
makeDraggable(ToggleButton, ToggleDrag)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not isMobileMode and input.KeyCode == Enum.KeyCode.G then
        guiOpen = not guiOpen
        MainFrame.Visible = guiOpen
        if guiOpen then UpdateProtectedList() end
    end
end)
