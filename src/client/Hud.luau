-- Hud: the whole ScreenGui over the 3D world. One module builds it all so
-- the client script stays a thin wiring layer: the top bar (cash, income,
-- rebirths), the LOCK and REBIRTH buttons, the wave banner, the toast feed,
-- the rarity legend and the hint line. Nothing here draws the game itself;
-- the game is the 3D world underneath, and this is only its interface.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))

local Hud = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local cashLabel: TextLabel
local incomeLabel: TextLabel
local rebirthLabel: TextLabel
local lockButton: TextButton
local lockTimer: TextLabel
local rebirthButton: TextButton
local rebirthCostLabel: TextLabel
local waveBanner: Frame
local waveText: TextLabel
local toastHolder: Frame
local hintLabel: TextLabel

local toasts = {}

local function makeLabel(parent, name, text, size, color, font)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.TextScaled = true
	label.Font = font or Enum.Font.GothamBold
	label.Size = size
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, size, position, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextStrokeTransparency = 0.2
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	button.Parent = parent
	return button
end

-- Builds the ScreenGui and every element on it. Called once at load.
function Hud.build()
	gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotBayGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 10

	-- Top bar: cash, income, rebirths. Top-left is kept clear of Roblox's
	-- own menu buttons, so the bar sits top-centre.
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.AnchorPoint = Vector2.new(0.5, 0)
	topBar.Position = UDim2.new(0.5, 0, 0, 12)
	topBar.Size = UDim2.new(0, 560, 0, 64)
	topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	topBar.BackgroundTransparency = 0.25
	topBar.BorderSizePixel = 0
	topBar.Parent = gui
	local topCorner = Instance.new("UICorner")
	topCorner.CornerRadius = UDim.new(0, 12)
	topCorner.Parent = topBar

	cashLabel = makeLabel(topBar, "Cash", "$100", UDim2.new(0.55, 0, 0, 40), Color3.fromRGB(120, 255, 140), Enum.Font.GothamBold)
	cashLabel.Position = UDim2.new(0.02, 0, 0, 4)
	cashLabel.TextXAlignment = Enum.TextXAlignment.Left
	cashLabel.TextSize = 30

	incomeLabel = makeLabel(topBar, "Income", "$0/s", UDim2.new(0.4, 0, 0, 26), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold)
	incomeLabel.Position = UDim2.new(0.58, 0, 0, 8)
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Left

	rebirthLabel = makeLabel(topBar, "Rebirths", "Rebirth 0 • x1.0", UDim2.new(0.96, 0, 0, 22), Color3.fromRGB(255, 210, 60), Enum.Font.GothamBold)
	rebirthLabel.Position = UDim2.new(0.02, 0, 0, 40)
	rebirthLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- Right-hand buttons: lock the base, rebirth.
	lockButton = makeButton(gui, "LockButton", "🔒 LOCK BASE", UDim2.new(0, 220, 0, 52), UDim2.new(1, -240, 0, 96), Color3.fromRGB(60, 120, 255))
	lockTimer = makeLabel(lockButton, "LockTimer", "", UDim2.new(1, 0, 0, 18), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold)
	lockTimer.Position = UDim2.new(0, 0, 1, -20)

	rebirthButton = makeButton(gui, "RebirthButton", "✨ REBIRTH", UDim2.new(0, 220, 0, 52), UDim2.new(1, -240, 0, 160), Color3.fromRGB(170, 90, 230))
	rebirthCostLabel = makeLabel(rebirthButton, "RebirthCost", "Cost $250K", UDim2.new(1, 0, 0, 18), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold)
	rebirthCostLabel.Position = UDim2.new(0, 0, 1, -20)

	-- Wave banner: hidden until the warning comes.
	waveBanner = Instance.new("Frame")
	waveBanner.Name = "WaveBanner"
	waveBanner.AnchorPoint = Vector2.new(0.5, 0)
	waveBanner.Position = UDim2.new(0.5, 0, 0, 92)
	waveBanner.Size = UDim2.new(0, 520, 0, 56)
	waveBanner.BackgroundColor3 = Color3.fromRGB(20, 80, 160)
	waveBanner.BackgroundTransparency = 0.15
	waveBanner.BorderSizePixel = 0
	waveBanner.Visible = false
	waveBanner.Parent = gui
	local bannerCorner = Instance.new("UICorner")
	bannerCorner.CornerRadius = UDim.new(0, 12)
	bannerCorner.Parent = waveBanner
	waveText = makeLabel(waveBanner, "WaveText", "🌊 TSUNAMI INCOMING!", UDim2.new(1, 0, 1, 0), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold)

	-- Rarity legend, bottom-left: the ladder a new player reads first.
	local legend = Instance.new("Frame")
	legend.Name = "Legend"
	legend.AnchorPoint = Vector2.new(0, 1)
	legend.Position = UDim2.new(0, 12, 1, -12)
	legend.Size = UDim2.new(0, 220, 0, 168)
	legend.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	legend.BackgroundTransparency = 0.25
	legend.BorderSizePixel = 0
	legend.Parent = gui
	local legendCorner = Instance.new("UICorner")
	legendCorner.CornerRadius = UDim.new(0, 12)
	legendCorner.Parent = legend
	makeLabel(legend, "LegendTitle", "RARITIES", UDim2.new(1, 0, 0, 24), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold).Position = UDim2.new(0, 10, 0, 4)
	local order = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" }
	for i, rarity in ipairs(order) do
		local row = makeLabel(legend, "Rarity" .. rarity, "● " .. rarity, UDim2.new(1, -20, 0, 20), BrainrotCatalog.RARITIES[rarity].color, Enum.Font.GothamBold)
		row.Position = UDim2.new(0, 10, 0, 28 + (i - 1) * 22)
		row.TextXAlignment = Enum.TextXAlignment.Left
	end

	-- Toast feed, bottom-right.
	toastHolder = Instance.new("Frame")
	toastHolder.Name = "Toasts"
	toastHolder.AnchorPoint = Vector2.new(1, 1)
	toastHolder.Position = UDim2.new(1, -12, 1, -12)
	toastHolder.Size = UDim2.new(0, 360, 0, 200)
	toastHolder.BackgroundTransparency = 1
	toastHolder.Parent = gui

	-- Hint line, bottom-centre: what to do right now.
	hintLabel = makeLabel(gui, "Hint", "Buy brainrots on the belt • F = slap • Run home when the wave comes!", UDim2.new(0, 640, 0, 28), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold)
	hintLabel.AnchorPoint = Vector2.new(0.5, 1)
	hintLabel.Position = UDim2.new(0.5, 0, 1, -12)

	gui.Parent = player:WaitForChild("PlayerGui")
end

-- One state sync per second from the server: cash, income, rebirths, lock.
function Hud.applyState(state)
	if not gui then
		return
	end
	cashLabel.Text = Format.money(state.cash)
	incomeLabel.Text = Format.ratePerSecond(state.income) .. "  •  " .. tostring(state.ownedCount) .. "/10 on base"
	rebirthLabel.Text = "Rebirth " .. tostring(state.rebirths) .. " • x" .. string.format("%.1f", state.multiplier)
	if rebirthCostLabel then
		rebirthCostLabel.Text = "Cost " .. Format.money(state.rebirthCost)
	end
	if state.lockLeft > 0 then
		lockTimer.Text = "Locked " .. Format.clock(state.lockLeft)
		lockButton.Text = "🔒 LOCKED"
		lockButton.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
	elseif state.lockCooldownLeft > 0 then
		lockTimer.Text = "Recharges " .. Format.clock(state.lockCooldownLeft)
		lockButton.Text = "🔒 LOCK BASE"
		lockButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
	else
		lockTimer.Text = "Ready!"
		lockButton.Text = "🔒 LOCK BASE"
		lockButton.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
	end
end

-- Shows the wave banner for the warning, hides it when the wave is over.
function Hud.showWave(kind: string, seconds: number)
	if not gui then
		return
	end
	if kind == "warning" then
		waveBanner.Visible = true
		waveText.Text = "🌊 TSUNAMI IN " .. tostring(seconds) .. "s — RUN TO YOUR BASE!"
	elseif kind == "over" then
		waveBanner.Visible = false
	end
end

-- A toast: a one-line message that fades after four seconds.
function Hud.toast(message: string, color: Color3)
	if not gui then
		return
	end
	local toast = Instance.new("TextLabel")
	toast.Name = "Toast"
	toast.Size = UDim2.new(1, 0, 0, 34)
	toast.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	toast.BackgroundTransparency = 0.2
	toast.BorderSizePixel = 0
	toast.Text = message
	toast.TextColor3 = color
	toast.TextStrokeTransparency = 0.2
	toast.TextScaled = true
	toast.Font = Enum.Font.GothamBold
	toast.TextXAlignment = Enum.TextXAlignment.Left
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toast
	table.insert(toasts, toast)
	Hud.layoutToasts()
	toast.Parent = toastHolder
	task.delay(4, function()
		for i, item in ipairs(toasts) do
			if item == toast then
				table.remove(toasts, i)
				break
			end
		end
		toast:Destroy()
		Hud.layoutToasts()
	end)
end

function Hud.layoutToasts()
	for i, toast in ipairs(toasts) do
		toast.Position = UDim2.new(0, 0, 1, -i * 40)
	end
end

function Hud.getLockButton(): TextButton
	return lockButton
end

function Hud.getRebirthButton(): TextButton
	return rebirthButton
end

function Hud.setHint(text: string)
	if hintLabel then
		hintLabel.Text = text
	end
end

return Hud
