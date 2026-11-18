-- RebirthService: the prestige ladder. Pay the price (which grows fivefold
-- each time), lose your cash and every brainrot on your base, and keep a
-- permanent +50% earnings multiplier and a new aura colour. The HUD's
-- REBIRTH button calls this; the price is checked twice, here and in
-- DataService, so a forged remote cannot mint a free rebirth.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local RebirthService = {}

local rebirthRemote: RemoteEvent
local notifyRemote: RemoteEvent

-- Attempts a rebirth for the player. Returns the new rebirth count.
function RebirthService.tryRebirth(player: Player): number
	local state = DataService.getState(player)
	if not state then
		return 0
	end
	local cost = DataService.getRebirthCost(player)
	if state.cash < cost then
		if notifyRemote then
			notifyRemote:FireClient(player, "Need " .. tostring(cost) .. " for Rebirth " .. tostring(state.rebirths + 1), Color3.fromRGB(255, 210, 60))
		end
		return 0
	end
	local count = DataService.applyRebirth(player)
	if count > 0 then
		DataService.syncLeaderstats(player)
		if notifyRemote then
			notifyRemote:FireClient(player, "✨ REBIRTH " .. tostring(count) .. "! Earnings x" .. tostring(1 + count * Config.REBIRTH.multiplierPerRebirth), Color3.fromRGB(255, 210, 60))
		end
	end
	return count
end

function RebirthService.init(remotes: { [string]: RemoteEvent })
	rebirthRemote = remotes.Rebirth
	notifyRemote = remotes.Notify
	rebirthRemote.OnServerEvent:Connect(function(player)
		RebirthService.tryRebirth(player)
	end)
end

return RebirthService
