-- BaseService: the eight base plots, their locks, stealing and slapping.
-- A base is a plot from the place file (Workspace.Bases.Base1..Base8) with
-- ten slot pads. Stealing is the genre's heart: while a base is unlocked,
-- anyone can grab a brainrot off it and run it home; the owner slaps the
-- thief (F) to make them drop it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local BrainrotService = require(script.Parent:WaitForChild("BrainrotService"))

local BaseService = {}

local basesFolder: Folder
local stealRemote: RemoteEvent
local lockRemote: RemoteEvent
local slapRemote: RemoteEvent
local notifyRemote: RemoteEvent

-- A steal in progress: the thief carries the brainrot and must reach their
-- own base before the timer runs out, or it walks back to its owner.
local activeSteals = {} :: { [string]: { thief: Player, victim: Player, owned: DataService.OwnedBrainrot, deadline: number } }

local lastSlapAt = {} :: { [Player]: number }

-- The world position of one base slot: two rows of five pads on the plot.
function BaseService.getSlotPosition(baseIndex: number, slot: number): Vector3
	local basePos = Config.BASES.positions[baseIndex]
	local row = math.floor((slot - 1) / 5)
	local col = (slot - 1) % 5
	local x = basePos.X - 8 + col * 4
	local z = basePos.Z - 4 + row * 8
	return Vector3.new(x, 1, z)
end

-- The plot's centre, for the wave's "are you home?" check.
function BaseService.getBaseCenter(baseIndex: number): Vector3
	return Config.BASES.positions[baseIndex]
end

-- Is this world position inside the given base's plot?
function BaseService.isInsideBase(position: Vector3, baseIndex: number): boolean
	local center = Config.BASES.positions[baseIndex]
	return math.abs(position.X - center.X) <= 14 and math.abs(position.Z - center.Z) <= 14
end

-- Paints the plot's pads and flag in the owner's colour and writes their
-- name on the banner. Called when a player claims a base.
function BaseService.paintBase(baseIndex: number, player: Player)
	local base = basesFolder:FindFirstChild("Base" .. tostring(baseIndex))
	if not base then
		return
	end
	local color = Config.BASES.colors[baseIndex]
	for _, descendant in ipairs(base:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name == "Pad" then
			descendant.Color = color
		end
	end
	local bannerText = base:FindFirstChild("BannerText", true)
	if bannerText and bannerText:IsA("TextLabel") then
		bannerText.Text = player.DisplayName .. "'s BASE"
	end
	local flag = base:FindFirstChild("Flag")
	if flag and flag:IsA("BasePart") then
		flag.Color = color
	end
end

local function notify(player: Player, message: string, color: Color3?)
	if notifyRemote then
		notifyRemote:FireClient(player, message, color or Color3.fromRGB(255, 255, 255))
	end
end

-- Starts a steal: the victim's brainrot leaves its slot, follows the thief,
-- and must reach the thief's base within Config.STEAL.stealEscapeTime.
function BaseService.startSteal(thief: Player, victim: Player, owned: DataService.OwnedBrainrot): boolean
	local thiefState = DataService.getState(thief)
	local victimState = DataService.getState(victim)
	if not thiefState or not victimState then
		return false
	end
	if not thiefState.baseIndex or not victimState.baseIndex then
		return false
	end
	if DataService.isBaseLocked(victim) then
		notify(thief, victim.DisplayName .. "'s base is LOCKED!", Color3.fromRGB(255, 90, 90))
		return false
	end
	if #thiefState.owned >= Config.BASES.slotsPerBase then
		notify(thief, "Your base is full!", Color3.fromRGB(255, 90, 90))
		return false
	end
	if activeSteals[owned.uid] then
		return false
	end
	local model = owned.model
	if not model or not model.Parent then
		return false
	end
	DataService.removeOwnedBrainrot(victim, owned.uid)
	BrainrotService.unparkModel(model)
	activeSteals[owned.uid] = {
		thief = thief,
		victim = victim,
		owned = owned,
		deadline = os.clock() + Config.STEAL.stealEscapeTime,
	}
	notify(thief, "RUN! Get it to your base!", Color3.fromRGB(255, 210, 60))
	notify(victim, thief.DisplayName .. " is STEALING your brainrot! Slap them! (F)", Color3.fromRGB(255, 90, 90))

	-- The chase: the brainrot trails its thief until the thief reaches home,
	-- is slapped, or the timer runs out.
	task.spawn(function()
		local character = thief.Character
		while activeSteals[owned.uid] and model.Parent do
			if not thief.Parent or not victim.Parent then
				break
			end
			local root = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local target = root.Position + Vector3.new(0, 0, -3)
				BrainrotService.walkModelTo(model, target, 12)
				if thiefState.baseIndex and BaseService.isInsideBase(root.Position, thiefState.baseIndex) then
					BaseService.completeSteal(owned.uid)
					return
				end
			end
			if os.clock() > activeSteals[owned.uid].deadline then
				break
			end
			task.wait(0.2)
		end
		if activeSteals[owned.uid] then
			BaseService.cancelSteal(owned.uid, "It got away and walked home!")
		end
	end)
	return true
end

-- The thief made it home: the brainrot is theirs now, on their next slot.
function BaseService.completeSteal(uid: string)
	local steal = activeSteals[uid]
	if not steal then
		return
	end
	activeSteals[uid] = nil
	local thiefState = DataService.getState(steal.thief)
	if not thiefState or not thiefState.baseIndex then
		return
	end
	steal.owned.slot = #thiefState.owned + 1
	DataService.addOwnedBrainrot(steal.thief, steal.owned)
	local target = BaseService.getSlotPosition(thiefState.baseIndex, steal.owned.slot)
	task.spawn(function()
		BrainrotService.walkModelTo(steal.owned.model, target, 10)
		BrainrotService.parkModel(steal.owned.model)
	end)
	notify(steal.thief, "STOLEN! It is yours now.", Color3.fromRGB(120, 255, 140))
	notify(steal.victim, "Your brainrot was stolen!", Color3.fromRGB(255, 90, 90))
end

-- The steal failed: the brainrot walks back to its owner's slot.
function BaseService.cancelSteal(uid: string, message: string?)
	local steal = activeSteals[uid]
	if not steal then
		return
	end
	activeSteals[uid] = nil
	local victimState = DataService.getState(steal.victim)
	if victimState and victimState.baseIndex then
		steal.owned.slot = #victimState.owned + 1
		DataService.addOwnedBrainrot(steal.victim, steal.owned)
		local target = BaseService.getSlotPosition(victimState.baseIndex, steal.owned.slot)
		task.spawn(function()
			BrainrotService.walkModelTo(steal.owned.model, target, 10)
			BrainrotService.parkModel(steal.owned.model)
		end)
	end
	if message then
		notify(steal.thief, message, Color3.fromRGB(255, 210, 60))
	end
end

-- A slap: knocks a nearby player back and, if they were carrying a stolen
-- brainrot, makes them drop it. Three-second cooldown per player.
function BaseService.slapPlayer(player: Player)
	local now = os.clock()
	if lastSlapAt[player] and now - lastSlapAt[player] < Config.SLAP.cooldown then
		return
	end
	lastSlapAt[player] = now
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other.Character then
			local otherRoot = other.Character:FindFirstChild("HumanoidRootPart")
			if otherRoot then
				local distance = (otherRoot.Position - root.Position).Magnitude
				if distance <= Config.SLAP.range then
					local direction = (otherRoot.Position - root.Position).Unit
					otherRoot.AssemblyLinearVelocity = direction * Config.SLAP.knockback + Vector3.new(0, 25, 0)
					-- Drop any brainrot they were stealing.
					for uid, steal in pairs(activeSteals) do
						if steal.thief == other then
							BaseService.cancelSteal(uid, "You got SLAPPED! You dropped it!")
							notify(player, "You slapped the thief!", Color3.fromRGB(120, 255, 140))
						end
					end
				end
			end
		end
	end
end

-- Touching a brainrot on someone else's base starts a steal (when unlocked).
local function watchTouches()
	Workspace.DescendantAdded:Connect(function(instance)
		if instance:IsA("BasePart") and instance.Name == "Body" then
			instance.Touched:Connect(function(hit)
				local character = hit.Parent
				local player = character and Players:GetPlayerFromCharacter(character)
				if not player then
					return
				end
				local model = instance.Parent
				if not model or not model:IsA("Model") then
					return
				end
				local uid = model:GetAttribute("BrainrotUid")
				if type(uid) ~= "string" then
					return
				end
				-- Whose brainrot is this? Find its owner.
				for _, owner in ipairs(Players:GetPlayers()) do
					if owner ~= player then
						local owned = DataService.findOwnedBrainrot(owner, uid)
						if owned then
							BaseService.startSteal(player, owner, owned)
							return
						end
					end
				end
			end)
		end
	end)
end

function BaseService.init(remotes: { [string]: RemoteEvent })
	basesFolder = Workspace:WaitForChild("Bases")
	stealRemote = remotes.StealBrainrot
	lockRemote = remotes.LockBase
	slapRemote = remotes.SlapPlayer
	notifyRemote = remotes.Notify

	lockRemote.OnServerEvent:Connect(function(player)
		if DataService.lockBase(player) then
			notify(player, "Base LOCKED for " .. tostring(Config.STEAL.lockDuration) .. "s. Nobody can steal!", Color3.fromRGB(120, 255, 140))
		else
			local cooldown = DataService.lockCooldownLeft(player)
			if cooldown > 0 then
				notify(player, "Lock recharges in " .. tostring(math.ceil(cooldown)) .. "s", Color3.fromRGB(255, 210, 60))
			end
		end
	end)

	slapRemote.OnServerEvent:Connect(function(player)
		BaseService.slapPlayer(player)
	end)

	stealRemote.OnServerEvent:Connect(function(player, uid)
		if type(uid) ~= "string" then
			return
		end
		for _, owner in ipairs(Players:GetPlayers()) do
			if owner ~= player then
				local owned = DataService.findOwnedBrainrot(owner, uid)
				if owned then
					BaseService.startSteal(player, owner, owned)
					return
				end
			end
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			local baseIndex = DataService.claimBase(player)
			if baseIndex then
				BaseService.paintBase(baseIndex, player)
				notify(player, "This is YOUR base! Buy brainrots and bring them home.", Color3.fromRGB(120, 255, 140))
			else
				notify(player, "All bases are taken! You are spectating.", Color3.fromRGB(255, 90, 90))
			end
		end)
	end)
	watchTouches()
end

return BaseService
