-- BrainrotService: the belt. It spawns absurd characters at the north
-- tunnel, walks them down the middle of the map, and sells them to the first
-- player who can pay. A bought brainrot walks to its owner's base slot and
-- stands there earning. A stolen one is handed to BaseService to chase.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local BrainrotService = {}

export type BeltBrainrot = {
	uid: string,
	characterId: string,
	mutation: string,
	model: Model,
	prompt: ProximityPrompt,
	sold: boolean,
}

local belt = {} :: { [string]: BeltBrainrot }
local beltFolder: Folder
local basesFolder: Folder
local buyRemote: RemoteEvent
local uidCounter = 0
local random = Random.new()

local function nextUid(): string
	uidCounter += 1
	return "br-" .. tostring(uidCounter) .. "-" .. tostring(math.random(1000, 9999))
end

-- Builds the 3D model of one character: a body, a head, two eyes, a
-- mutation-coloured hat, and a floating label with name, rarity and $/s.
-- The body colour is the character's own; the rarity paints the label.
function BrainrotService.buildBrainrotModel(def, mutation: string): Model
	local model = Instance.new("Model")
	model.Name = def.name

	local size = def.size
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Block
	body.Size = Vector3.new(size, size, size)
	body.Color = def.bodyColor
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = false
	body.CanCollide = true
	body.Position = Vector3.new(0, size / 2, 0)
	body.Parent = model

	-- Rounded head on top, in the accent colour.
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(size * 0.8, size * 0.8, size * 0.8)
	head.Color = def.accentColor
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = false
	head.CanCollide = false
	head.Position = Vector3.new(0, size + size * 0.35, 0)
	head.Parent = model

	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(size * 0.16, size * 0.16, size * 0.1)
		eye.Color = Color3.fromRGB(20, 20, 20)
		eye.Material = Enum.Material.SmoothPlastic
		eye.Anchored = false
		eye.CanCollide = false
		eye.Position = Vector3.new(side * size * 0.18, size + size * 0.4, size * 0.38)
		eye.Parent = model
	end

	-- A mutation paints a little crown on the head.
	local mutationInfo = BrainrotCatalog.MUTATIONS[mutation]
	if mutation ~= "Normal" and mutationInfo.color then
		local crown = Instance.new("Part")
		crown.Name = "MutationCrown"
		crown.Shape = Enum.PartType.Block
		crown.Size = Vector3.new(size * 0.6, size * 0.25, size * 0.6)
		crown.Color = mutationInfo.color
		crown.Material = Enum.Material.Neon
		crown.Anchored = false
		crown.CanCollide = false
		crown.Position = Vector3.new(0, size + size * 0.85, 0)
		crown.Parent = model
	end

	-- Weld everything to the body so the model walks as one piece.
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and part ~= body then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = part
			weld.Parent = body
		end
	end
	model.PrimaryPart = body
	return model
end

-- The floating label above a brainrot: name, rarity, mutation, $/s, price.
local function attachLabel(model: Model, def, mutation: string, price: number?)
	local rarityColor = BrainrotCatalog.RARITIES[def.rarity].color
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.fromOffset(220, 84)
	gui.StudsOffset = Vector3.new(0, def.size + 2.2, 0)
	gui.AlwaysOnTop = true
	gui.Parent = model.PrimaryPart

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 0, 28)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = gui

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "Rarity"
	rarityLabel.Position = UDim2.new(0, 0, 0, 28)
	rarityLabel.Size = UDim2.new(1, 0, 0, 22)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = def.rarity .. (mutation ~= "Normal" and (" • " .. mutation) or "")
	rarityLabel.TextColor3 = rarityColor
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = gui

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "Rate"
	rateLabel.Position = UDim2.new(0, 0, 0, 50)
	rateLabel.Size = UDim2.new(1, 0, 0, 34)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = Format.ratePerSecond(BrainrotCatalog.effectiveRate(def, mutation, 1))
		.. (price and ("  •  " .. Format.money(price)) or "")
	rateLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	rateLabel.TextStrokeTransparency = 0
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.Parent = gui
end

-- Picks a random character of a rolled rarity, rolls its mutation, builds
-- it at the spawn tunnel and starts it walking down the belt.
function BrainrotService.spawnBrainrot()
	if #beltFolder:GetChildren() >= Config.BELT.maxOnBelt then
		return
	end
	local rarity = BrainrotCatalog.rollRarity(random)
	local pool = BrainrotCatalog.getByRarity(rarity)
	if #pool == 0 then
		return
	end
	local def = pool[random:NextInteger(1, #pool)]
	local mutation = BrainrotCatalog.rollMutation(random)

	local model = BrainrotService.buildBrainrotModel(def, mutation)
	model:SetPrimaryPartCFrame(CFrame.new(Config.BELT.laneX, 1, Config.BELT.startZ))
	attachLabel(model, def, mutation, def.cost)
	model.Parent = beltFolder

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy " .. def.name
	prompt.ObjectText = Format.money(def.cost)
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart

	local record: BeltBrainrot = {
		uid = nextUid(),
		characterId = def.id,
		mutation = mutation,
		model = model,
		prompt = prompt,
		sold = false,
	}
	belt[record.uid] = record
	model:SetAttribute("BrainrotUid", record.uid)
	model:SetAttribute("CharacterId", def.id)
	model:SetAttribute("Mutation", mutation)
	model:SetAttribute("Cost", def.cost)

	prompt.Triggered:Connect(function(player)
		BrainrotService.buyBrainrot(player, record.uid)
	end)
end

-- The belt walk: every heartbeat each unsold brainrot steps south; one that
-- reaches the exit portal despawns (nobody wanted it).
local function stepBelt(dt: number)
	local step = Config.BELT.walkSpeed * dt
	for uid, record in pairs(belt) do
		if record.sold then
			continue
		end
		local model = record.model
		if not model.Parent then
			belt[uid] = nil
			continue
		end
		local cf = model:GetPrimaryPartCFrame()
		local nextZ = cf.Position.Z + step
		if nextZ >= Config.BELT.endZ then
			belt[uid] = nil
			model:Destroy()
		else
			model:SetPrimaryPartCFrame(CFrame.new(cf.Position.X, cf.Position.Y, nextZ))
		end
	end
end

-- Buys a belt brainrot: pays, pulls it off the belt, and sends it walking
-- to the buyer's next free base slot. Returns false when the buyer cannot
-- pay, has no base, or has no free slot.
function BrainrotService.buyBrainrot(player: Player, uid: string): boolean
	local record = belt[uid]
	if not record or record.sold then
		return false
	end
	local def = BrainrotCatalog.getCharacter(record.characterId)
	if not def then
		return false
	end
	local state = DataService.getState(player)
	if not state or not state.baseIndex then
		return false
	end
	if #state.owned >= Config.BASES.slotsPerBase then
		return false
	end
	if not DataService.trySpendCash(player, def.cost) then
		return false
	end
	record.sold = true
	belt[uid] = nil
	record.prompt.Enabled = false

	local slot = #state.owned + 1
	local owned: DataService.OwnedBrainrot = {
		uid = record.uid,
		characterId = record.characterId,
		mutation = record.mutation,
		slot = slot,
		model = record.model,
	}
	DataService.addOwnedBrainrot(player, owned)
	DataService.syncLeaderstats(player)

	-- Re-label without the price: it is owned now, and earns.
	local label = record.model.PrimaryPart:FindFirstChild("BrainrotLabel")
	if label then
		label:Destroy()
	end
	attachLabel(record.model, def, record.mutation, nil)

	-- Walk it to its slot, then park it there.
	local baseService = require(script.Parent:WaitForChild("BaseService"))
	local target = baseService.getSlotPosition(state.baseIndex, slot)
	task.spawn(function()
		BrainrotService.walkModelTo(record.model, target, 10)
		local cf = record.model:GetPrimaryPartCFrame()
		record.model:SetPrimaryPartCFrame(CFrame.new(target.X, cf.Position.Y, target.Z))
		BrainrotService.parkModel(record.model)
	end)
	return true
end

-- Walks a model toward a point at the belt's speed, in small steps.
function BrainrotService.walkModelTo(model: Model, target: Vector3, speed: number)
	local primary = model.PrimaryPart
	if not primary then
		return
	end
	while model.Parent do
		local pos = primary.Position
		local delta = Vector3.new(target.X - pos.X, 0, target.Z - pos.Z)
		local distance = delta.Magnitude
		if distance < 1 then
			break
		end
		local step = math.min(distance, speed * 0.1)
		local dir = delta.Unit
		primary.CFrame = CFrame.new(pos + dir * step)
		task.wait(0.1)
	end
end

-- Anchors a model in place so it stands still and earns.
function BrainrotService.parkModel(model: Model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
end

-- Frees a parked model so it can walk again (a steal, a rebirth wipe).
function BrainrotService.unparkModel(model: Model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
end

function BrainrotService.getBeltCount(): number
	local count = 0
	for _ in pairs(belt) do
		count += 1
	end
	return count
end

-- Sweeps every unsold belt brainrot away: the wave takes them all.
function BrainrotService.clearBelt()
	for uid, record in pairs(belt) do
		belt[uid] = nil
		if record.model.Parent then
			record.model:Destroy()
		end
	end
end

function BrainrotService.init(remotes: { [string]: RemoteEvent })
	beltFolder = Instance.new("Folder")
	beltFolder.Name = "Belt"
	beltFolder.Parent = Workspace

	basesFolder = Workspace:WaitForChild("Bases")
	buyRemote = remotes.BuyBrainrot

	buyRemote.OnServerEvent:Connect(function(player, uid)
		if type(uid) == "string" then
			BrainrotService.buyBrainrot(player, uid)
		end
	end)

	RunService.Heartbeat:Connect(stepBelt)
	task.spawn(function()
		while true do
			task.wait(Config.BELT.spawnInterval)
			BrainrotService.spawnBrainrot()
		end
	end)
	-- Two starters so the belt is never empty at kickoff.
	BrainrotService.spawnBrainrot()
	BrainrotService.spawnBrainrot()
end

return BrainrotService
