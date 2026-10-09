-- Rivo Team | Delta Executable Version
-- High-Level Obfuscated Script

local _0xRivo = {
	[1] = game:GetService("Players"),
	[2] = game:GetService("RunService"),
	[3] = game:GetService("UserInputService"),
	[4] = Color3.fromRGB,
	[5] = Vector2.new,
	[6] = Vector3.new,
	[7] = UDim2.new,
	[8] = UDim2.fromScale,
	[9] = UDim2.fromOffset,
	[10] = Instance.new,
	[11] = RaycastParams.new,
	[12] = Enum.RaycastFilterType.Exclude,
	[13] = Enum.KeyCode.LeftAlt,
	[14] = math.clamp,
	[15] = math.deg,
	[16] = math.atan2,
	[17] = table.insert,
	[18] = string.format,
}

local _0xP = _0xRivo[1].LocalPlayer
local _0xC = workspace.CurrentCamera

local _0xS = {
	MaxDistance = 600,
	TeamCheck = true,
	FOVStep = 10,
	MinFOV = 40,
	MaxFOV = 350,
	MenuKey = _0xRivo[13],
	StickyFovBonus = 30,
}

local _0xSt = {
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

local _0xCol = {
	On = _0xRivo[4](22, 163, 74),
	Off = _0xRivo[4](220, 38, 38),
	Purple = _0xRivo[4](147, 51, 234),
	Blue = _0xRivo[4](37, 99, 235),
	Ally = _0xRivo[4](56, 189, 248),
	Enemy = _0xRivo[4](239, 68, 68),
	Bg = _0xRivo[4](12, 12, 14),
	Row = _0xRivo[4](28, 28, 32),
	Text = _0xRivo[4](255, 255, 255),
}

local _0xL = nil

local function _0xChar(p) return p and p.Character end
local function _0xHum(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function _0xRoot(c)
	if not c then return nil end
	return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso")
end
local function _0xHead(c) return c and c:FindFirstChild("Head") end
local function _0xBody(c)
	if not c then return nil end
	return c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso") or c:FindFirstChild("HumanoidRootPart")
end

local function _0xW2S(pos)
	_0xC = workspace.CurrentCamera
	if not _0xC then return nil, false end
	local sp, onScreen = _0xC:WorldToViewportPoint(pos)
	return _0xRivo[5](sp.X, sp.Y), onScreen and sp.Z > 0, sp.Z
end

local function _0xWall(part)
	_0xC = workspace.CurrentCamera
	local char = _0xChar(_0xP)
	if not _0xC or not part then return true end
	local origin = _0xC.CFrame.Position
	local direction = part.Position - origin
	if direction.Magnitude < 1 then return false end

	local params = _0xRivo[11]()
	params.FilterType = _0xRivo[12]
	local exc = {}
	if char then _0xRivo[17](exc, char) end
	if part.Parent then _0xRivo[17](exc, part.Parent) end
	params.FilterDescendantsInstances = exc
	params.IgnoreWater = true

	local res = workspace:Raycast(origin, direction, params)
	return res ~= nil
end

local function _0xTargetPart(char)
	if not char then return nil end
	if _0xSt.TargetMode == "Head" then
		return _0xHead(char) or _0xRoot(char)
	elseif _0xSt.TargetMode == "Body" then
		return _0xBody(char) or _0xRoot(char)
	end
	local head = _0xHead(char)
	if head and not (_0xSt.WallCheck and _0xWall(head)) then
		return head
	end
	return _0xBody(char) or _0xRoot(char)
end

local function _0xIsAlly(p)
	if _0xSt.Allies[p.UserId] then return true end
	if _0xS.TeamCheck and _0xP.Team and p.Team and p.Team == _0xP.Team then
		if _0xP.Team.Name == "Spectators" then return false end
		return true
	end
	return false
end

local function _0xIsAlive(p)
	local char = _0xChar(p)
	local hum = _0xHum(char)
	return char and hum and hum.Health > 0
end

local function _0xGetTools(p)
	local names, seen = {}, {}
	local function add(t)
		if t and t:IsA("Tool") and not seen[t.Name] then
			seen[t.Name] = true
			_0xRivo[17](names, t.Name)
		end
	end
	local char = _0xChar(p)
	if char then
		for _, v in ipairs(char:GetChildren()) do add(v) end
	end
	local bp = p:FindFirstChild("Backpack")
	if bp then
		for _, v in ipairs(bp:GetChildren()) do add(v) end
	end
	return names
end

local function _0xAllyCount()
	local n = 0
	for _, v in pairs(_0xSt.Allies) do
		if v then n = n + 1 end
	end
	return n
end

local _0xCoreGui = game:GetService("CoreGui") or _0xP:WaitForChild("PlayerGui")
for _, name in ipairs({ "EliteTeam", "RivoTeam" }) do
	local old = _0xCoreGui:FindFirstChild(name)
	if old then old:Destroy() end
end

local _0xGui = _0xRivo[10]("ScreenGui")
_0xGui.Name = "RivoTeam"
_0xGui.IgnoreGuiInset = true
_0xGui.ResetOnSpawn = false
_0xGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
_0xGui.DisplayOrder = 200
_0xGui.Parent = _0xCoreGui

local fovCircle = _0xRivo[10]("Frame")
fovCircle.AnchorPoint = _0xRivo[5](0.5, 0.5)
fovCircle.Position = _0xRivo[8](0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.ZIndex = 2
fovCircle.Parent = _0xGui
local fovCorner = _0xRivo[10]("UICorner", fovCircle)
fovCorner.CornerRadius = UDim.new(1, 0)
local fovStroke = _0xRivo[10]("UIStroke", fovCircle)
fovStroke.Thickness = 1.6
fovStroke.Color = _0xRivo[4](80, 255, 140)
fovStroke.Transparency = 0.15

local tracer = _0xRivo[10]("Frame")
tracer.BackgroundColor3 = _0xRivo[4](80, 255, 140)
tracer.BorderSizePixel = 0
tracer.Visible = false
tracer.ZIndex = 2
tracer.AnchorPoint = _0xRivo[5](0, 0.5)
tracer.Parent = _0xGui
local tracerCorner = _0xRivo[10]("UICorner", tracer)
tracerCorner.CornerRadius = UDim.new(1, 0)

local openBtn = _0xRivo[10]("TextButton")
openBtn.AnchorPoint = _0xRivo[5](1, 0)
openBtn.Position = _0xRivo[7](1, -14, 0, 72)
openBtn.Size = _0xRivo[9](86, 34)
openBtn.BackgroundColor3 = _0xCol.On
openBtn.Text = "فتح"
openBtn.TextColor3 = _0xCol.Text
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 16
openBtn.Parent = _0xGui
local openCorner = _0xRivo[10]("UICorner", openBtn)
openCorner.CornerRadius = UDim.new(0, 8)

local function makePanel(name)
	local p = _0xRivo[10]("Frame")
	p.Name = name
	p.AnchorPoint = _0xRivo[5](0.5, 0.5)
	p.Position = _0xRivo[8](0.5, 0.52)
	p.Size = _0xRivo[9](300, 0)
	p.AutomaticSize = Enum.AutomaticSize.Y
	p.BackgroundColor3 = _0xCol.Bg
	p.BackgroundTransparency = 0.08
	p.Visible = false
	p.ZIndex = 5
	p.Parent = _0xGui
	local c = _0xRivo[10]("UICorner", p)
	c.CornerRadius = UDim.new(0, 10)
	local s = _0xRivo[10]("UIStroke", p)
	s.Color = _0xRivo[4](255, 255, 255)
	s.Transparency = 0.82
	s.Thickness = 1
	local pad = _0xRivo[10]("UIPadding", p)
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	local l = _0xRivo[10]("UIListLayout", p)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Padding = UDim.new(0, 6)
	return p
end

local menu = makePanel("Menu")
local friendsMenu = makePanel("FriendsMenu")
friendsMenu.ZIndex = 8

local function makeLabel(parent, text, order, height, textSize)
	local lbl = _0xRivo[10]("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = _0xRivo[7](1, 0, 0, height or 22)
	lbl.Text = text
	lbl.TextColor3 = _0xCol.Text
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = textSize or 16
	lbl.TextWrapped = true
	lbl.LayoutOrder = order
	lbl.ZIndex = parent.ZIndex + 1
	lbl.Parent = parent
	return lbl
end

local function makeBtn(parent, order)
	local btn = _0xRivo[10]("TextButton")
	btn.Size = _0xRivo[7](1, 0, 0, 32)
	btn.TextColor3 = _0xCol.Text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.LayoutOrder = order
	btn.ZIndex = parent.ZIndex + 1
	btn.Parent = parent
	local c = _0xRivo[10]("UICorner", btn)
	c.CornerRadius = UDim.new(0, 7)
	return btn
end

makeLabel(menu, "Rivo Team", 1, 26, 20)
local credit = makeLabel(menu, "Rivo Team - Encrypted", 2, 16, 12)
credit.TextColor3 = _0xRivo[4](180, 180, 190)

local backpackBtn = makeBtn(menu, 3)
local espBtn = makeBtn(menu, 4)
local aimBtn = makeBtn(menu, 5)
local wallBtn = makeBtn(menu, 6)

local fovRow = _0xRivo[10]("Frame")
fovRow.BackgroundTransparency = 1
fovRow.Size = _0xRivo[7](1, 0, 0, 32)
fovRow.LayoutOrder = 7
fovRow.ZIndex = 6
fovRow.Parent = menu
local fovLayout = _0xRivo[10]("UIListLayout", fovRow)
fovLayout.FillDirection = Enum.FillDirection.Horizontal
fovLayout.Padding = UDim.new(0, 6)

local function makeSmall(parent, text, width)
	local b = _0xRivo[10]("TextButton")
	b.Size = _0xRivo[7](0, width, 1, 0)
	b.BackgroundColor3 = _0xCol.Purple
	b.Text = text
	b.TextColor3 = _0xCol.Text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 16
	b.ZIndex = 6
	b.Parent = parent
	local c = _0xRivo[10]("UICorner", b)
	c.CornerRadius = UDim.new(0, 7)
	return b
end

local fovMinus = makeSmall(fovRow, "-", 36)
local fovBtn = _0xRivo[10]("TextButton")
fovBtn.Size = _0xRivo[7](1, -78, 1, 0)
fovBtn.BackgroundColor3 = _0xCol.Purple
fovBtn.TextColor3 = _0xCol.Text
fovBtn.Font = Enum.Font.GothamBold
fovBtn.TextSize = 14
fovBtn.ZIndex = 6
fovBtn.Parent = fovRow
local fovBtnCorner = _0xRivo[10]("UICorner", fovBtn)
fovBtnCorner.CornerRadius = UDim.new(0, 7)
local fovPlus = makeSmall(fovRow, "+", 36)

local targetBtn = makeBtn(menu, 8)
targetBtn.BackgroundColor3 = _0xCol.Purple

local friendsBtn = makeBtn(menu, 9)
friendsBtn.BackgroundColor3 = _0xCol.Blue

makeLabel(friendsMenu, "تحديد الأصدقاء", 1, 26, 18)
local friendsHint = makeLabel(friendsMenu, "كل اللاعبين بالسيرفر — اضغط عشان يصير خوي والأيم ما يجيه", 2, 32, 12)
friendsHint.Font = Enum.Font.Gotham
friendsHint.TextColor3 = _0xRivo[4](200, 200, 210)

local friendsCount = makeLabel(friendsMenu, "اللاعبين: 0", 3, 18, 13)
friendsCount.Font = Enum.Font.Gotham
friendsCount.TextXAlignment = Enum.TextXAlignment.Right

local listFrame = _0xRivo[10]("ScrollingFrame")
listFrame.Size = _0xRivo[7](1, 0, 0, 240)
listFrame.BackgroundColor3 = _0xRivo[4](18, 18, 22)
listFrame.BackgroundTransparency = 0.2
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 4
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.LayoutOrder = 4
listFrame.ZIndex = 9
listFrame.Parent = friendsMenu
local listCorner = _0xRivo[10]("UICorner", listFrame)
listCorner.CornerRadius = UDim.new(0, 8)
local listPad = _0xRivo[10]("UIPadding", listFrame)
listPad.PaddingTop = UDim.new(0, 6)
listPad.PaddingBottom = UDim.new(0, 6)
listPad.PaddingLeft = UDim.new(0, 6)
listPad.PaddingRight = UDim.new(0, 6)
local listLayout = _0xRivo[10]("UIListLayout", listFrame)
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

local emptyLabel = _0xRivo[10]("TextLabel")
emptyLabel.BackgroundTransparency = 1
emptyLabel.Size = _0xRivo[7](1, 0, 0, 40)
emptyLabel.Font = Enum.Font.Gotham
emptyLabel.TextSize = 13
emptyLabel.TextColor3 = _0xRivo[4](180, 180, 190)
emptyLabel.Text = "ما فيه لاعبين بالسيرفر"
emptyLabel.Visible = false
emptyLabel.ZIndex = 10
emptyLabel.Parent = listFrame

local backBtn = makeBtn(friendsMenu, 5)
backBtn.BackgroundColor3 = _0xCol.Off
backBtn.Text = "رجوع"

local function paintToggle(btn, on, onText, offText)
	btn.BackgroundColor3 = on and _0xCol.On or _0xCol.Off
	btn.Text = on and onText or offText
end

local function refreshButtons()
	paintToggle(backpackBtn, _0xSt.BackpackESP, "كاشف الحقيبة: مفعل", "كاشف الحقيبة: معطل")
	paintToggle(espBtn, _0xSt.PlayerESP, "كاشف اللاعبين (ESP): مفعل", "كاشف اللاعبين (ESP): معطل")
	paintToggle(aimBtn, _0xSt.AimLock, "التصويب التلقائي (Aimbot): مفعل", "التصويب التلقائي (Aimbot): معطل")
	paintToggle(wallBtn, _0xSt.WallCheck, "فحص الجدران: مفعل", "فحص الجدران: معطل")
	fovBtn.Text = "مجال الرؤية (FOV): " .. tostring(_0xSt.FOV)
	targetBtn.Text = _0xSt.TargetMode == "Head" and "الهدف: رأس" or (_0xSt.TargetMode == "Body" and "الهدف: جسم" or "الهدف: تبديل تلقائي")
	local n = _0xAllyCount()
	friendsBtn.Text = n > 0 and ("تحديد الأصدقاء (" .. n .. ")") or "تحديد الأصدقاء"
	fovCircle.Visible = _0xSt.AimLock
	local anyOpen = _0xSt.MenuOpen or _0xSt.FriendsOpen
	openBtn.Text = anyOpen and "إغلاق" or "فتح"
	openBtn.BackgroundColor3 = anyOpen and _0xCol.Off or _0xCol.On
	menu.Visible = _0xSt.MenuOpen
	friendsMenu.Visible = _0xSt.FriendsOpen
	if not _0xSt.AimLock then
		_0xL = nil
		tracer.Visible = false
	end
end

local function refreshPlayerList()
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	local others = {}
	for _, plr in ipairs(_0xRivo[1]:GetPlayers()) do
		if plr ~= _0xP then _0xRivo[17](others, plr) end
	end
	table.sort(others, function(a, b) return string.lower(a.DisplayName) < string.lower(b.DisplayName) end)

	friendsCount.Text = "اللاعبين: " .. tostring(#others)
	emptyLabel.Visible = #others == 0

	for i, plr in ipairs(others) do
		local row = _0xRivo[10]("TextButton")
		row.Size = _0xRivo[7](1, -4, 0, 28)
		row.Font = Enum.Font.GothamMedium
		row.TextSize = 13
		row.TextColor3 = _0xCol.Text
		row.ZIndex = 10
		row.LayoutOrder = i + 1
		row.Parent = listFrame
		local c = _0xRivo[10]("UICorner", row)
		c.CornerRadius = UDim.new(0, 6)

		local function paint()
			local ally = _0xSt.Allies[plr.UserId] == true
			row.BackgroundColor3 = ally and _0xCol.Blue or _0xCol.Row
			row.Text = plr.DisplayName .. " (@" .. plr.Name .. ")" .. (ally and "  ✓ خوي" or "")
		end
		paint()
		row.MouseButton1Click:Connect(function()
			_0xSt.Allies[plr.UserId] = not _0xSt.Allies[plr.UserId] or nil
			if _0xL == plr and _0xIsAlly(plr) then _0xL = nil end
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
	if player == _0xP then return end
	local char = _0xChar(player)
	local head = _0xHead(char)
	local root = _0xRoot(char)
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

	local old = char:FindFirstChild("RivoESP") or char:FindFirstChild("EliteESP")
	if old then old:Destroy() end

	local highlight = _0xRivo[10]("Highlight")
	highlight.Name = "RivoESP"
	highlight.Adornee = char
	highlight.FillTransparency = 0.7
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = char

	local bb = _0xRivo[10]("BillboardGui")
	bb.Name = "RivoTag"
	bb.Adornee = head or root
	bb.Size = _0xRivo[9](180, 54)
	bb.StudsOffset = _0xRivo[6](0, 2.6, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = _0xS.MaxDistance
	bb.Parent = _0xGui

	local nameLabel = _0xRivo[10]("TextLabel", bb)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = _0xRivo[7](1, 0, 0, 16)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.TextColor3 = _0xRivo[4](255, 255, 255)

	local bar = _0xRivo[10]("Frame", bb)
	bar.Position = _0xRivo[9](20, 18)
	bar.Size = _0xRivo[7](1, -40, 0, 6)
	bar.BackgroundColor3 = _0xRivo[4](40, 40, 40)
	bar.BorderSizePixel = 0
	local fill = _0xRivo[10]("Frame", bar)
	fill.Size = _0xRivo[8](1, 1)
	fill.BackgroundColor3 = _0xRivo[4](50, 220, 90)
	fill.BorderSizePixel = 0

	local toolLabel = _0xRivo[10]("TextLabel", bb)
	toolLabel.BackgroundTransparency = 1
	toolLabel.Position = _0xRivo[9](0, 26)
	toolLabel.Size = _0xRivo[7](1, 0, 0, 22)
	toolLabel.Font = Enum.Font.GothamMedium
	toolLabel.TextSize = 11
	toolLabel.TextColor3 = _0xRivo[4](255, 220, 80)

	item = { character = char, highlight = highlight, billboard = bb, nameLabel = nameLabel, toolLabel = toolLabel, bar = bar, fill = fill }
	espItems[player] = item
	return item
end

local function updateESP()
	_0xC = workspace.CurrentCamera
	local myRoot = _0xRoot(_0xChar(_0xP))
	for _, plr in ipairs(_0xRivo[1]:GetPlayers()) do
		if plr ~= _0xP then
			if not _0xIsAlive(plr) then
				destroyESP(plr)
			else
				if not (_0xSt.PlayerESP or _0xSt.BackpackESP) then
					destroyESP(plr)
				else
					local item = ensureESP(plr)
					if item then
						local char = _0xChar(plr)
						local hum = _0xHum(char)
						local root = _0xRoot(char)
						local ally = _0xIsAlly(plr)
						local dist = (myRoot and root) and (myRoot.Position - root.Position).Magnitude or 0
						if dist > _0xS.MaxDistance then
							item.highlight.Enabled = false
							item.billboard.Enabled = false
						else
							item.highlight.Enabled = _0xSt.PlayerESP
							item.highlight.FillColor = ally and _0xCol.Ally or _0xCol.Enemy
							item.highlight.OutlineColor = ally and _0xCol.Ally or _0xCol.Enemy
							item.billboard.Enabled = true

							if _0xSt.PlayerESP then
								item.nameLabel.Visible = true
								item.bar.Visible = true
								item.nameLabel.Text = _0xRivo[18]("%s (@%s)  %d", plr.DisplayName, plr.Name, math.floor(dist))
								item.nameLabel.TextColor3 = ally and _0xCol.Ally or _0xRivo[4](255, 255, 255)
								local hp = hum and _0xRivo[14](hum.Health / math.max(hum.MaxHealth, 1), 0, 1) or 0
								item.fill.Size = _0xRivo[8](hp, 1)
								item.fill.BackgroundColor3 = hp > 0.45 and _0xRivo[4](50, 220, 90) or _0xRivo[4](230, 60, 60)
							else
								item.nameLabel.Visible = false
								item.bar.Visible = false
							end

							if _0xSt.BackpackESP then
								local tools = _0xGetTools(plr)
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
	if plr == _0xP or not plr.Parent or _0xIsAlly(plr) or not _0xIsAlive(plr) then return nil end
	local part = _0xTargetPart(_0xChar(plr))
	if not part then return nil end

	local myRoot = _0xRoot(_0xChar(_0xP))
	if myRoot and (myRoot.Position - part.Position).Magnitude > _0xS.MaxDistance then return nil end

	local screen, onScreen = _0xW2S(part.Position)
	if not onScreen or not screen then return nil end

	_0xC = workspace.CurrentCamera
	if not _0xC then return nil end
	local pixelDist = (screen - (_0xC.ViewportSize / 2)).Magnitude
	if pixelDist > fovLimit or (_0xSt.WallCheck and _0xWall(part)) then return nil end

	return part, pixelDist
end

local function pickTarget()
	if _0xL then
		local part = considerTarget(_0xL, _0xSt.FOV + _0xS.StickyFovBonus)
		if part then return part end
		_0xL = nil
	end

	_0xC = workspace.CurrentCamera
	if not _0xC then return nil end

	local bestPart, bestPlayer, bestScore = nil, nil, math.huge
	for _, plr in ipairs(_0xRivo[1]:GetPlayers()) do
		local part, pixelDist = considerTarget(plr, _0xSt.FOV)
		if part and pixelDist < bestScore then
			bestScore = pixelDist
			bestPart = part
			bestPlayer = plr
		end
	end

	_0xL = bestPlayer
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
	tracer.Size = _0xRivo[9](length, 2)
	tracer.Position = _0xRivo[9](fromPos.X, fromPos.Y)
	tracer.Rotation = _0xRivo[15](_0xRivo[16](delta.Y, delta.X))
end

local function updateAim()
	_0xC = workspace.CurrentCamera
	if not _0xC then return end

	local radius = _0xSt.FOV * 2
	fovCircle.Size = _0xRivo[9](radius, radius)

	if not _0xSt.AimLock then
		_0xL = nil
		tracer.Visible = false
		return
	end

	local part = pickTarget()
	if not part or not part.Parent then
		tracer.Visible = false
		return
	end

	local origin = _0xC.CFrame.Position
	if (part.Position - origin).Magnitude < 0.05 then
		tracer.Visible = false
		return
	end

	_0xC.CFrame = CFrame.new(origin, part.Position)

	local screen, onScreen = _0xW2S(part.Position)
	if onScreen and screen then
		drawTracer(_0xC.ViewportSize / 2, screen)
	else
		tracer.Visible = false
	end
end

openBtn.MouseButton1Click:Connect(function()
	if _0xSt.FriendsOpen or _0xSt.MenuOpen then
		_0xSt.FriendsOpen = false
		_0xSt.MenuOpen = false
	else
		_0xSt.MenuOpen = true
	end
	refreshButtons()
end)

backpackBtn.MouseButton1Click:Connect(function() _0xSt.BackpackESP = not _0xSt.BackpackESP refreshButtons() end)
espBtn.MouseButton1Click:Connect(function() _0xSt.PlayerESP = not _0xSt.PlayerESP refreshButtons() end)
aimBtn.MouseButton1Click:Connect(function() _0xSt.AimLock = not _0xSt.AimLock refreshButtons() end)
wallBtn.MouseButton1Click:Connect(function() _0xSt.WallCheck = not _0xSt.WallCheck refreshButtons() end)

targetBtn.MouseButton1Click:Connect(function()
	_0xSt.TargetMode = _0xSt.TargetMode == "Auto" and "Head" or (_0xSt.TargetMode == "Head" and "Body" or "Auto")
	refreshButtons()
end)

friendsBtn.MouseButton1Click:Connect(function()
	_0xSt.MenuOpen = false
	_0xSt.FriendsOpen = true
	refreshPlayerList()
	refreshButtons()
end)

backBtn.MouseButton1Click:Connect(function()
	_0xSt.FriendsOpen = false
	_0xSt.MenuOpen = true
	refreshButtons()
end)

fovMinus.MouseButton1Click:Connect(function()
	_0xSt.FOV = _0xRivo[14](_0xSt.FOV - _0xS.FOVStep, _0xS.MinFOV, _0xS.MaxFOV)
	refreshButtons()
end)

fovPlus.MouseButton1Click:Connect(function()
	_0xSt.FOV = _0xRivo[14](_0xSt.FOV + _0xS.FOVStep, _0xS.MinFOV, _0xS.MaxFOV)
	refreshButtons()
end)

_0xRivo[3].InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == _0xS.MenuKey then
		_0xSt.MenuOpen = not _0xSt.MenuOpen
		refreshButtons()
	end
end)

_0xRivo[1].PlayerRemoving:Connect(function(plr)
	destroyESP(plr)
	_0xSt.Allies[plr.UserId] = nil
	if _0xL == plr then _0xL = nil end
	refreshButtons()
end)

refreshButtons()

pcall(function() _0xRivo[2]:UnbindFromRenderStep("RivoAimLock") end)
_0xRivo[2]:BindToRenderStep("RivoAimLock", Enum.RenderPriority.Camera.Value + 1, updateAim)
_0xRivo[2].RenderStepped:Connect(updateESP)
