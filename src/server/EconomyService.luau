-- EconomyService: the one-second tick that pays every brainrot on every
-- base. It owns no state of its own; it asks DataService for the income and
-- adds it, then syncs leaderstats and pushes a StateSync to the clients.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local EconomyService = {}

local stateSync: RemoteEvent

-- One tick: pay everyone, sync the leaderboard numbers, tell the clients.
function EconomyService.tickEarnings()
	for _, player in ipairs(Players:GetPlayers()) do
		local income = DataService.getIncomePerSecond(player)
		if income > 0 then
			DataService.addCash(player, income)
		end
		DataService.syncLeaderstats(player)
	end
	if stateSync then
		for _, player in ipairs(Players:GetPlayers()) do
			local state = DataService.getState(player)
			if state then
				stateSync:FireClient(player, {
					cash = math.floor(state.cash),
					income = DataService.getIncomePerSecond(player),
					rebirths = state.rebirths,
					rebirthCost = DataService.getRebirthCost(player),
					multiplier = DataService.getRebirthMultiplier(player),
					baseIndex = state.baseIndex,
					lockLeft = DataService.lockSecondsLeft(player),
					lockCooldownLeft = DataService.lockCooldownLeft(player),
					ownedCount = #state.owned,
				})
			end
		end
	end
end

function EconomyService.init(remotes: { [string]: RemoteEvent })
	stateSync = remotes.StateSync
	task.spawn(function()
		while true do
			task.wait(Config.ECONOMY.tickInterval)
			EconomyService.tickEarnings()
		end
	end)
end

return EconomyService
