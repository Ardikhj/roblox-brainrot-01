-- DataService: one table of state per player, and the leaderstats the
-- leaderboard reads. State lives here alone; every other service asks this
-- module instead of keeping its own copy.
-- A player's state: cash, rebirths, base plot, base lock, and the brainrots
-- standing on their base slots (each an owned brainrot record).

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotCatalog = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))

local DataService = {}

export type OwnedBrainrot = {
	uid: string,
	characterId: string,
	mutation: string,
	slot: number,
	model: Model?,
}

export type PlayerState = {
	player: Player,
	cash: number,
	rebirths: number,
	baseIndex: number?,
	lockUntil: number, -- os.clock() time the lock ends, 0 when unlocked
	lockReadyAt: number, -- os.clock() time the lock can be used again
	owned: { OwnedBrainrot },
}

local states = {} :: { [Player]: PlayerState }
local usedBases = {} :: { [number]: Player }
local saveStore = nil
local SAVE_KEY_PREFIX = "brainrot-bay-v1-"

-- DataStores are off in Studio playtests without API access; pcall keeps
-- the game running either way and saving silently no-ops.
local ok, store = pcall(function()
	return DataStoreService:GetDataStore("BrainrotBaySaves")
end)
if ok then
	saveStore = store
end

function DataService.getState(player: Player): PlayerState?
	return states[player]
end

function DataService.getRebirthMultiplier(player: Player): number
	local state = states[player]
	if not state then
		return 1
	end
	return 1 + state.rebirths * Config.REBIRTH.multiplierPerRebirth
end

-- Total money-per-second of everything standing on the player's base.
function DataService.getIncomePerSecond(player: Player): number
	local state = states[player]
	if not state then
		return 0
	end
	local total = 0
	local multiplier = DataService.getRebirthMultiplier(player)
	for _, owned in ipairs(state.owned) do
		local def = BrainrotCatalog.getCharacter(owned.characterId)
		if def then
			total += BrainrotCatalog.effectiveRate(def, owned.mutation, multiplier)
		end
	end
	return total
end

function DataService.addCash(player: Player, amount: number)
	local state = states[player]
	if not state then
		return
	end
	state.cash = math.max(0, state.cash + amount)
end

-- Spends cash when the player can afford it; returns whether it was paid.
function DataService.trySpendCash(player: Player, amount: number): boolean
	local state = states[player]
	if not state or state.cash < amount then
		return false
	end
	state.cash -= amount
	return true
end

function DataService.addOwnedBrainrot(player: Player, owned: OwnedBrainrot)
	local state = states[player]
	if state then
		table.insert(state.owned, owned)
	end
end

function DataService.removeOwnedBrainrot(player: Player, uid: string): OwnedBrainrot?
	local state = states[player]
	if not state then
		return nil
	end
	for i, owned in ipairs(state.owned) do
		if owned.uid == uid then
			table.remove(state.owned, i)
			return owned
		end
	end
	return nil
end

function DataService.findOwnedBrainrot(player: Player, uid: string): OwnedBrainrot?
	local state = states[player]
	if not state then
		return nil
	end
	for _, owned in ipairs(state.owned) do
		if owned.uid == uid then
			return owned
		end
	end
	return nil
end

-- Lowest free base plot; nil when all eight are taken (ninth player waits).
function DataService.claimBase(player: Player): number?
	for i = 1, Config.BASES.count do
		if not usedBases[i] then
			usedBases[i] = player
			local state = states[player]
			if state then
				state.baseIndex = i
			end
			return i
		end
	end
	return nil
end

function DataService.freeBase(player: Player)
	local state = states[player]
	if state and state.baseIndex then
		usedBases[state.baseIndex] = nil
	end
end

function DataService.isBaseLocked(player: Player): boolean
	local state = states[player]
	if not state then
		return false
	end
	return os.clock() < state.lockUntil
end

function DataService.lockSecondsLeft(player: Player): number
	local state = states[player]
	if not state then
		return 0
	end
	return math.max(0, state.lockUntil - os.clock())
end

function DataService.lockCooldownLeft(player: Player): number
	local state = states[player]
	if not state then
		return 0
	end
	return math.max(0, state.lockReadyAt - os.clock())
end

-- Locks the player's base for Config.STEAL.lockDuration. Returns false when
-- the lock is still cooling down or the player has no base.
function DataService.lockBase(player: Player): boolean
	local state = states[player]
	if not state or not state.baseIndex then
		return false
	end
	local now = os.clock()
	if now < state.lockReadyAt then
		return false
	end
	state.lockUntil = now + Config.STEAL.lockDuration
	state.lockReadyAt = state.lockUntil + Config.STEAL.lockCooldown
	return true
end

-- Rebirth: pays the price, wipes cash and brainrots, adds the multiplier.
-- Returns the new rebirth count, or 0 when it could not be paid.
function DataService.applyRebirth(player: Player): number
	local state = states[player]
	if not state then
		return 0
	end
	local cost = Config.REBIRTH.baseCost * (Config.REBIRTH.costGrowth ^ state.rebirths)
	if state.cash < cost then
		return 0
	end
	state.cash = 0
	state.rebirths += 1
	for _, owned in ipairs(state.owned) do
		if owned.model then
			owned.model:Destroy()
		end
	end
	table.clear(state.owned)
	return state.rebirths
end

function DataService.getRebirthCost(player: Player): number
	local state = states[player]
	if not state then
		return Config.REBIRTH.baseCost
	end
	return Config.REBIRTH.baseCost * (Config.REBIRTH.costGrowth ^ state.rebirths)
end

local function setupLeaderstats(player: Player, state: PlayerState)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = state.cash
	cash.Parent = leaderstats

	local income = Instance.new("IntValue")
	income.Name = "$/s"
	income.Value = 0
	income.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = state.rebirths
	rebirths.Parent = leaderstats

	state.leaderCash = cash
	state.incomeValue = income
	state.rebirthValue = rebirths
end

-- Pushes the state's numbers into leaderstats so the leaderboard and the
-- client HUD stay honest. Called once a second by the economy tick.
function DataService.syncLeaderstats(player: Player)
	local state = states[player]
	if not state or not state.leaderCash then
		return
	end
	state.leaderCash.Value = math.floor(state.cash)
	state.incomeValue.Value = DataService.getIncomePerSecond(player)
	state.rebirthValue.Value = state.rebirths
end

local function loadSave(player: Player): (number, number)
	if not saveStore then
		return Config.ECONOMY.startCash, 0
	end
	local okLoad, data = pcall(function()
		return saveStore:GetAsync(SAVE_KEY_PREFIX .. player.UserId)
	end)
	if okLoad and type(data) == "table" then
		local cash = tonumber(data.cash) or Config.ECONOMY.startCash
		local rebirths = tonumber(data.rebirths) or 0
		return cash, rebirths
	end
	return Config.ECONOMY.startCash, 0
end

local function savePlayer(player: Player)
	local state = states[player]
	if not state or not saveStore then
		return
	end
	pcall(function()
		saveStore:SetAsync(SAVE_KEY_PREFIX .. player.UserId, {
			cash = math.floor(state.cash),
			rebirths = state.rebirths,
		})
	end)
end

function DataService.onPlayerAdded(player: Player)
	local cash, rebirths = loadSave(player)
	local state: PlayerState = {
		player = player,
		cash = cash,
		rebirths = rebirths,
		baseIndex = nil,
		lockUntil = 0,
		lockReadyAt = 0,
		owned = {},
	}
	states[player] = state
	setupLeaderstats(player, state)
end

function DataService.onPlayerRemoving(player: Player)
	savePlayer(player)
	DataService.freeBase(player)
	states[player] = nil
end

function DataService.init()
	Players.PlayerAdded:Connect(DataService.onPlayerAdded)
	Players.PlayerRemoving:Connect(DataService.onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		DataService.onPlayerAdded(player)
	end
	-- Autosave every two minutes so a crash keeps most of the grind.
	task.spawn(function()
		while true do
			task.wait(120)
			for _, player in ipairs(Players:GetPlayers()) do
				savePlayer(player)
			end
		end
	end)
end

return DataService
