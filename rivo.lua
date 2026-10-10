local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Settings = {
	MaxDistance = 10000,
	AimMaxDistance = 100,
	TeamCheck = true,
	FOVStep = 10,
	MinFOV = 40,
	MaxFOV = 350,
	MenuKey = Enum.KeyCode.LeftAlt,
	StickyFovBonus = 30,
}

local State = {
	BackpackESP = false,
	PlayerESP = false,
	AimLock = false,
	WallCheck = false,
	FOV = 110,
	TargetMode = "Auto",
	MenuOpen = false,
	FriendsOpen = false,
	Allies = {},
}

local COLORS = {
	On = Color3.fromRGB(22, 163, 74),
	Off = Color3.fromRGB(220, 38, 38),
	Purple = Color3.fromRGB(147, 51, 234),
	Blue = Color3.fromRGB(37, 99, 235),
	Ally = Color3.fromRGB(56, 189, 248),
	Enemy = Color3.fromRGB(239, 68, 68),
	Bg = Color3.fromRGB(12, 12, 14),
	Row = Color3.fromRGB(28, 28, 32),
	Text = Color3.fromRGB(255, 255, 255),
}

local lockedPlayer = nil

local function getCharacter(player)
	return player and player.Character
end

local function getHumanoid(character)
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(character)
	if not character then return nil end
	return character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("UpperTorso")
end

local function getHead(character)
	return character and character:FindFirstChild("Head")
end

local function getBodyPart(character)
	if not character then return nil end
	return character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
end

local function worldToScreen(position)
	camera = workspace.CurrentCamera
	if not camera then return nil, false end
	local sp, onScreen = camera:WorldToViewportPoint(position)
	return Vector2.new(sp.X, sp.Y), onScreen and sp.Z > 0, sp.Z
end

local function hasWallBetween(part)
	camera = workspace.CurrentCamera
	local char = getCharacter(localPlayer)
	if not camera or not part then return true end
	local origin = camera.CFrame.Position
	local direction = part.Position - origin
	if direction.Magnitude < 1 then return false end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = {}
	if char then table.insert(exclude, char) end
	if part.Parent then table.insert(exclude, part.Parent) end
	params.FilterDescendantsInstances = exclude
	params.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, params)
	return result ~= nil
end

local function getTargetPart(character)
	if not character then return nil end
	if State.TargetMode == "Head" then
		return getHead(character) or getRoot(character)
	elseif State.TargetMode == "Body" then
		return getBodyPart(character) or getRoot(character)
	end
	local head = getHead(character)
	if head and not (State.WallCheck and hasWallBetween(head)) then
		return head
	end
	return getBodyPart(character) or getRoot(character)
end

local function isAlly(player)
	if State.Allies[player.UserId] then return true end
	if Settings.TeamCheck and localPlayer.Team and player.Team and player.Team == localPlayer.Team then
		if localPlayer.Team.Name == "Spectators" then
			return false
		end
		return true
	end
	return false
end

local function isAlive(player)
	local char = getCharacter(player)
	local hum = getHumanoid(char)
	return char and hum and hum.Health > 0
end

local function getHeldAndBackpack(player)
	local names = {}
	local seen = {}
	local function add(tool)
		if tool and tool:IsA("Tool") and not seen[tool.Name] then
			seen[tool.Name] = true
			table.insert(names, tool.Name)
		end
	end
	local char = getCharacter(player)
	if char then
		for _, child in ipairs(char:GetChildren()) do
			add(child)
		end
	end
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, child in ipairs(backpack:GetChildren()) do
			add(child)
		end
	end
	return names
end

local function targetModeLabel()
	if State.TargetMode == "Head" then
		return "الهدف: رأس"
	elseif State.TargetMode == "Body" then
		return "الهدف: جسم"
	end
	return "الهدف: تبديل تلقائي (رأس -- جسم)"
end

local function allyCount()
	local n = 0
	for _, on in pairs(State.Allies) do
		if on then
			n += 1
		end
	end
	return n
end

local playerGui = localPlayer:WaitForChild("PlayerGui")
for _, name in ipairs({ "EliteTeam", "RivoTeam" }) do
	local old = playerGui:FindFirstChild(name)
	if old then old:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "RivoTeam"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 200
gui.Parent = playerGui

local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.fromScale(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.ZIndex = 2
fovCircle.Parent = gui
local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle
local fovStroke = Instance.new("UIStroke")
fovStroke.Thickness = 1.6
fovStroke.Color = Color3.fromRGB(80, 255, 140)
fovStroke.Transparency = 0.15
fovStroke.Parent = fovCircle

local tracer = Instance.new("Frame")
tracer.Name = "Tracer"
tracer.BackgroundColor3 = Color3.fromRGB(80, 255, 140)
tracer.BorderSizePixel = 0
tracer.Visible = false
tracer.ZIndex = 2
tracer.AnchorPoint = Vector2.new(0, 0.5)
tracer.Parent = gui
local tracerCorner = Instance.new("UICorner")
tracerCorner.CornerRadius = UDim.new(1, 0)
tracerCorner.Parent = tracer

local openBtn = Instance.new("TextButton")
openBtn.Name = "ToggleMenu"
openBtn.AnchorPoint = Vector2.new(1, 0)
openBtn.Position = UDim2.new(1, -14, 0, 72)
openBtn.Size = UDim2.fromOffset(86, 34)
openBtn.BackgroundColor3 = COLORS.On
openBtn.Text = "فتح"
openBtn.TextColor3 = COLORS.Text
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 16
openBtn.AutoButtonColor = true
openBtn.Parent = gui
local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 8)
openCorner.Parent = openBtn

local function makePanel(name)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.52)
	panel.Size = UDim2.fromOffset(300, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = COLORS.Bg
	panel.BackgroundTransparency = 0.08
	panel.Visible = false
	panel.ZIndex = 5
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.82
	stroke.Thickness = 1
	stroke.Parent = panel
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = panel
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 6)
	list.Parent = panel
	return panel
end

local menu = makePanel("Menu")
local friendsMenu = makePanel("FriendsMenu")
friendsMenu.ZIndex = 8

local function makeLabel(parent, text, order, height, textSize)
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, 0, 0, height or 22)
	lbl.Text = text
	lbl.TextColor3 = COLORS.Text
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = textSize or 16
	lbl.TextWrapped = true
	lbl.LayoutOrder = order
	lbl.ZIndex = parent.ZIndex + 1
	lbl.Parent = parent
	return lbl
end

local function makeBtn(parent, order)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.AutoButtonColor = true
	btn.TextColor3 = COLORS.Text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.LayoutOrder = order
	btn.ZIndex = parent.ZIndex + 1
	btn.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 7)
	c.Parent = btn
	return btn
end

local title = makeLabel(menu, "Rivo Team", 1, 26, 18)
title.TextSize = 20

local credit = makeLabel(menu, "Rivo Team", 2, 16, 12)
credit.TextColor3 = Color3.fromRGB(180, 180, 190)
credit.Font = Enum.Font.Gotham

local backpackBtn = makeBtn(menu, 3)
local espBtn = makeBtn(menu, 4)
local aimBtn = makeBtn(menu, 5)
local wallBtn = makeBtn(menu, 6)

local fovRow = Instance.new("Frame")
fovRow.BackgroundTransparency = 1
fovRow.Size = UDim2.new(1, 0, 0, 32)
fovRow.LayoutOrder = 7
fovRow.ZIndex = 6
fovRow.Parent = menu
local fovLayout = Instance.new("UIListLayout")
fovLayout.FillDirection = Enum.FillDirection.Horizontal
fovLayout.Padding = UDim.new(0, 6)
fovLayout.Parent = fovRow

local function makeSmall(parent, text, width)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, width, 1, 0)
	b.BackgroundColor3 = COLORS.Purple
	b.Text = text
	b.TextColor3 = COLORS.Text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 16
	b.AutoButtonColor = true
	b.ZIndex = 6
	b.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 7)
	c.Parent = b
	return b
end

local fovMinus = makeSmall(fovRow, "-", 36)
local fovBtn = Instance.new("TextButton")
fovBtn.Size = UDim2.new(1, -78, 1, 0)
fovBtn.BackgroundColor3 = COLORS.Purple
fovBtn.TextColor3 = COLORS.Text
fovBtn.Font = Enum.Font.GothamBold
fovBtn.TextSize = 14
fovBtn.AutoButtonColor = true
fovBtn.ZIndex = 6
fovBtn.Parent = fovRow
local fovBtnCorner = Instance.new("UICorner")
fovBtnCorner.CornerRadius = UDim.new(0, 7)
fovBtnCorner.Parent = fovBtn
local fovPlus = makeSmall(fovRow, "+", 36)

local targetBtn = makeBtn(menu, 8)
targetBtn.BackgroundColor3 = COLORS.Purple

local friendsBtn = makeBtn(menu, 9)
friendsBtn.BackgroundColor3 = COLORS.Blue

local friendsTitle = makeLabel(friendsMenu, "تحديد الأصدقاء", 1, 26, 18)
friendsTitle.TextSize = 18

local friendsHint = makeLabel(friendsMenu, "كل اللاعبين بالسيرفر — اضغط عشان يصير خوي والأيم ما يجيه", 2, 32, 12)
friendsHint.Font = Enum.Font.Gotham
friendsHint.TextColor3 = Color3.fromRGB(200, 200, 210)

local friendsCount = makeLabel(friendsMenu, "اللاعبين: 0", 3, 18, 13)
friendsCount.Font = Enum.Font.Gotham
friendsCount.TextXAlignment = Enum.TextXAlignment.Right

local listFrame = Instance.new("ScrollingFrame")
listFrame.Name = "PlayerList"
listFrame.Size = UDim2.new(1, 0, 0, 240)
listFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
listFrame.BackgroundTransparency = 0.2
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 4
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.LayoutOrder = 4
listFrame.ZIndex = 9
listFrame.Parent = friendsMenu
local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 8)
listCorner.Parent = listFrame
local listPad = Instance.new("UIPadding")
listPad.PaddingTop = UDim.new(0, 6)
listPad.PaddingBottom = UDim.new(0, 6)
listPad.PaddingLeft = UDim.new(0, 6)
listPad.PaddingRight = UDim.new(0, 6)
listPad.Parent = listFrame
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listFrame

local emptyLabel = Instance.new("TextLabel")
emptyLabel.BackgroundTransparency = 1
emptyLabel.Size = UDim2.new(1, 0, 0, 40)
emptyLabel.Font = Enum.Font.Gotham
emptyLabel.TextSize = 13
emptyLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
emptyLabel.Text = "ما فيه لاعبين بالسيرفر"
emptyLabel.Visible = false
emptyLabel.ZIndex = 10
emptyLabel.LayoutOrder = 1
emptyLabel.Parent = listFrame

local backBtn = makeBtn(friendsMenu, 5)
backBtn.BackgroundColor3 = COLORS.Off
backBtn.Text = "رجوع"

local friendsCredit = makeLabel(friendsMenu, "Rivo Team", 6, 16, 12)
friendsCredit.TextColor3 = Color3.fromRGB(180, 180, 190)
friendsCredit.Font = Enum.Font.Gotham

local function paintToggle(btn, on, onText, offText)
	btn.BackgroundColor3 = on and COLORS.On or COLORS.Off
	btn.Text = on and onText or offText
end

local function refreshButtons()
	paintToggle(backpackBtn, State.BackpackESP, "كاشف الحقيبة: مفعل", "كاشف الحقيبة: معطل")
	paintToggle(espBtn, State.PlayerESP, "كاشف اللاعبين (ESP): مفعل", "كاشف اللاعبين (ESP): معطل")
	paintToggle(aimBtn, State.AimLock, "التصويب التلقائي (Aimbot): مفعل", "التصويب التلقائي (Aimbot): معطل")
	paintToggle(wallBtn, State.WallCheck, "فحص الجدران: مفعل", "فحص الجدران: معطل")
	fovBtn.Text = "مجال الرؤية (FOV): " .. tostring(State.FOV)
	targetBtn.Text = targetModeLabel()
	local n = allyCount()
	friendsBtn.Text = n > 0 and ("تحديد الأصدقاء (" .. n .. ")") or "تحديد الأصدقاء"
	fovCircle.Visible = State.AimLock
	local anyOpen = State.MenuOpen or State.FriendsOpen
	openBtn.Text = anyOpen and "إغلاق" or "فتح"
	openBtn.BackgroundColor3 = anyOpen and COLORS.Off or COLORS.On
	menu.Visible = State.MenuOpen
	friendsMenu.Visible = State.FriendsOpen
	if not State.AimLock then
		lockedPlayer = nil
		tracer.Visible = false
	end
end

local function refreshPlayerList()
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local others = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= localPlayer then
			table.insert(others, plr)
		end
	end
	table.sort(others, function(a, b)
		return string.lower(a.DisplayName) < string.lower(b.DisplayName)
	end)

	friendsCount.Text = "اللاعبين: " .. tostring(#others)
	emptyLabel.Visible = #others == 0

	for i, plr in ipairs(others) do
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, -4, 0, 28)
		row.AutoButtonColor = true
		row.Font = Enum.Font.GothamMedium
		row.TextSize = 13
		row.TextColor3 = COLORS.Text
		row.ZIndex = 10
		row.LayoutOrder = i + 1
		row.Parent = listFrame
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = row

		local function paint()
			local ally = State.Allies[plr.UserId] == true
			row.BackgroundColor3 = ally and COLORS.Blue or COLORS.Row
			local mark = ally and "  ✓ خوي" or ""
			row.Text = plr.DisplayName .. " (@" .. plr.Name .. ")" .. mark
		end
		paint()
		row.MouseButton1Click:Connect(function()
			if State.Allies[plr.UserId] then
				State.Allies[plr.UserId] = nil
			else
				State.Allies[plr.UserId] = true
			end
			if lockedPlayer == plr and isAlly(plr) then
				lockedPlayer = nil
			end
			paint()
			refreshButtons()
		end)
	end
end

local espItems = {}

local function destroyESP(player)
	local item = espItems[player]
	if not item then return end
	if item.highlight then item.highlight:Destroy() end
	if item.billboard then item.billboard:Destroy() end
	espItems[player] = nil
end

local function ensureESP(player)
	if player == localPlayer then return end
	local char = getCharacter(player)
	local head = getHead(char)
	local root = getRoot(char)
	if not char or not (head or root) then
		destroyESP(player)
		return
	end

	local item = espItems[player]
	if item and item.character ~= char then
		destroyESP(player)
		item = nil
	end
	if item then return item end

	local oldHighlight = char:FindFirstChild("RivoESP") or char:FindFirstChild("EliteESP")
	if oldHighlight then oldHighlight:Destroy() end

	local adornee = head or root
	local highlight = Instance.new("Highlight")
	highlight.Name = "RivoESP"
	highlight.Adornee = char
	highlight.FillTransparency = 0.7
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = char

	local bb = Instance.new("BillboardGui")
	bb.Name = "RivoTag"
	bb.Adornee = adornee
	bb.Size = UDim2.fromOffset(180, 54)
	bb.StudsOffset = Vector3.new(0, 2.6, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = Settings.MaxDistance
	bb.Parent = gui

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromOffset(0, 0)
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Parent = bb

	local bar = Instance.new("Frame")
	bar.Position = UDim2.fromOffset(20, 18)
	bar.Size = UDim2.new(1, -40, 0, 6)
	bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	bar.BorderSizePixel = 0
	bar.Parent = bb
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(50, 220, 90)
	fill.BorderSizePixel = 0
	fill.Parent = bar
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local toolLabel = Instance.new("TextLabel")
	toolLabel.BackgroundTransparency = 1
	toolLabel.Position = UDim2.fromOffset(0, 26)
	toolLabel.Size = UDim2.new(1, 0, 0, 22)
	toolLabel.Font = Enum.Font.GothamMedium
	toolLabel.TextSize = 11
	toolLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
	toolLabel.TextStrokeTransparency = 0.4
	toolLabel.TextWrapped = true
	toolLabel.Parent = bb

	item = {
		character = char,
		highlight = highlight,
		billboard = bb,
		nameLabel = nameLabel,
		toolLabel = toolLabel,
		bar = bar,
		fill = fill,
	}
	espItems[player] = item
	return item
end

local function updateESP()
	camera = workspace.CurrentCamera
	local myRoot = getRoot(getCharacter(localPlayer))
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= localPlayer then
			if not isAlive(plr) then
				destroyESP(plr)
			else
				local need = State.PlayerESP or State.BackpackESP
				if not need then
					destroyESP(plr)
				else
					local item = ensureESP(plr)
					if item then
						local char = getCharacter(plr)
						local hum = getHumanoid(char)
						local root = getRoot(char)
						local ally = isAlly(plr)
						local dist = 0
						if myRoot and root then
							dist = (myRoot.Position - root.Position).Magnitude
						end
						if dist > Settings.MaxDistance then
							item.highlight.Enabled = false
							item.billboard.Enabled = false
						else
							item.highlight.Enabled = State.PlayerESP
							item.highlight.FillColor = ally and COLORS.Ally or COLORS.Enemy
							item.highlight.OutlineColor = ally and COLORS.Ally or COLORS.Enemy
							item.billboard.Enabled = true

							if State.PlayerESP then
								item.nameLabel.Visible = true
								item.bar.Visible = true
								item.nameLabel.Text = string.format("%s (@%s)  %dم", plr.DisplayName, plr.Name, math.floor(dist))
								item.nameLabel.TextColor3 = ally and COLORS.Ally or Color3.new(1, 1, 1)
								local hp = hum and math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1) or 0
								item.fill.Size = UDim2.fromScale(hp, 1)
								item.fill.BackgroundColor3 = hp > 0.45 and Color3.fromRGB(50, 220, 90) or Color3.fromRGB(230, 60, 60)
							else
								item.nameLabel.Visible = false
								item.bar.Visible = false
							end

							if State.BackpackESP then
								local tools = getHeldAndBackpack(plr)
								item.toolLabel.Visible = true
								item.toolLabel.Text = #tools > 0 and ("معه: " .. table.concat(tools, " | ")) or "معه: فاضي"
							else
								item.toolLabel.Visible = false
							end
						end
					end
				end
			end
		end
	end
end

local function considerTarget(plr, fovLimit)
	if plr == localPlayer or not plr.Parent then return nil end
	if isAlly(plr) then return nil end
	if not isAlive(plr) then return nil end

	local part = getTargetPart(getCharacter(plr))
	if not part then return nil end

	local myRoot = getRoot(getCharacter(localPlayer))
	if myRoot then
		local d = (myRoot.Position - part.Position).Magnitude
		if d < 1 or d > Settings.AimMaxDistance then return nil end
	end

	local screen, onScreen = worldToScreen(part.Position)
	if not onScreen or not screen then return nil end

	camera = workspace.CurrentCamera
	if not camera then return nil end
	local pixelDist = (screen - (camera.ViewportSize / 2)).Magnitude
	if pixelDist > fovLimit then return nil end
	if State.WallCheck and hasWallBetween(part) then return nil end

	return part, pixelDist
end

local function pickTarget()
	if lockedPlayer then
		local part = considerTarget(lockedPlayer, State.FOV + Settings.StickyFovBonus)
		if part then
			return part
		end
		lockedPlayer = nil
	end

	camera = workspace.CurrentCamera
	if not camera then return nil end

	local bestPart, bestPlayer, bestScore = nil, nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		local part, pixelDist = considerTarget(plr, State.FOV)
		if part and pixelDist < bestScore then
			bestScore = pixelDist
			bestPart = part
			bestPlayer = plr
		end
	end

	lockedPlayer = bestPlayer
	return bestPart
end

local function drawTracer(fromPos, toPos)
	local delta = toPos - fromPos
	local length = delta.Magnitude
	if length < 2 then
		tracer.Visible = false
		return
	end
	tracer.Visible = true
	tracer.Size = UDim2.fromOffset(length, 2)
	tracer.Position = UDim2.fromOffset(fromPos.X, fromPos.Y)
	tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X))
end

local function updateAim()
	camera = workspace.CurrentCamera
	if not camera then return end

	local radius = State.FOV * 2
	fovCircle.Size = UDim2.fromOffset(radius, radius)

	if not State.AimLock then
		lockedPlayer = nil
		tracer.Visible = false
		return
	end

	local part = pickTarget()
	if not part or not part.Parent then
		tracer.Visible = false
		return
	end

	local origin = camera.CFrame.Position
	if (part.Position - origin).Magnitude < 0.05 then
		tracer.Visible = false
		return
	end

	camera.CFrame = CFrame.new(origin, part.Position)

	local screen, onScreen = worldToScreen(part.Position)
	local center = camera.ViewportSize / 2
	if onScreen and screen then
		drawTracer(center, screen)
	else
		tracer.Visible = false
	end
end

local function toggleMenu()
	if State.FriendsOpen or State.MenuOpen then
		State.FriendsOpen = false
		State.MenuOpen = false
	else
		State.MenuOpen = true
	end
	refreshButtons()
end

local function openFriends()
	State.MenuOpen = false
	State.FriendsOpen = true
	refreshPlayerList()
	refreshButtons()
end

local function closeFriends()
	State.FriendsOpen = false
	State.MenuOpen = true
	refreshButtons()
end

openBtn.MouseButton1Click:Connect(toggleMenu)

backpackBtn.MouseButton1Click:Connect(function()
	State.BackpackESP = not State.BackpackESP
	refreshButtons()
end)
espBtn.MouseButton1Click:Connect(function()
	State.PlayerESP = not State.PlayerESP
	refreshButtons()
end)
aimBtn.MouseButton1Click:Connect(function()
	State.AimLock = not State.AimLock
	refreshButtons()
end)
wallBtn.MouseButton1Click:Connect(function()
	State.WallCheck = not State.WallCheck
	refreshButtons()
end)
targetBtn.MouseButton1Click:Connect(function()
	if State.TargetMode == "Auto" then
		State.TargetMode = "Head"
	elseif State.TargetMode == "Head" then
		State.TargetMode = "Body"
	else
		State.TargetMode = "Auto"
	end
	refreshButtons()
end)
friendsBtn.MouseButton1Click:Connect(openFriends)
backBtn.MouseButton1Click:Connect(closeFriends)

local function addFov(n)
	State.FOV = math.clamp(State.FOV + n, Settings.MinFOV, Settings.MaxFOV)
	refreshButtons()
end
fovMinus.MouseButton1Click:Connect(function() addFov(-Settings.FOVStep) end)
fovPlus.MouseButton1Click:Connect(function() addFov(Settings.FOVStep) end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Settings.MenuKey then
		toggleMenu()
	end
end)

Players.PlayerAdded:Connect(function()
	if State.FriendsOpen then refreshPlayerList() end
end)
Players.PlayerRemoving:Connect(function(plr)
	destroyESP(plr)
	State.Allies[plr.UserId] = nil
	if lockedPlayer == plr then
		lockedPlayer = nil
	end
	if State.FriendsOpen then refreshPlayerList() end
	refreshButtons()
end)

refreshButtons()

pcall(function()
	RunService:UnbindFromRenderStep("RivoAimLock")
end)

RunService:BindToRenderStep("RivoAimLock", Enum.RenderPriority.Camera.Value + 1, function()
	updateAim()
end)

RunService.RenderStepped:Connect(function()
    updateESP()
end)
