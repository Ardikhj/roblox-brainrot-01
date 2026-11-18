-- init.server: the server's front door. It finds the RemoteEvents the
-- place file holds, starts every service in dependency order, and hands the
-- remotes to the services that listen on them.
-- Order matters: DataService first (state), then the belt, the bases, the
-- economy tick, the wave timer and rebirths.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script:WaitForChild("DataService"))
local WorldBuilder = require(script:WaitForChild("WorldBuilder"))
local BrainrotService = require(script:WaitForChild("BrainrotService"))
local BaseService = require(script:WaitForChild("BaseService"))
local EconomyService = require(script:WaitForChild("EconomyService"))
local WaveService = require(script:WaitForChild("WaveService"))
local RebirthService = require(script:WaitForChild("RebirthService"))

-- The RemoteEvents live in ReplicatedStorage (see default.project.json).
-- Every one is created in the place, never at runtime, so the client can
-- WaitForChild them the moment it loads.
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local remotes = {}
for _, remote in ipairs(remotesFolder:GetChildren()) do
	if remote:IsA("RemoteEvent") then
		remotes[remote.Name] = remote
	end
end

local required = { "BuyBrainrot", "StealBrainrot", "LockBase", "SlapPlayer", "Rebirth", "StateSync", "Notify", "WaveEvent" }
for _, name in ipairs(required) do
	assert(remotes[name], "Brainrot Bay is missing RemoteEvent: " .. name)
end

DataService.init()
WorldBuilder.build()
BrainrotService.init(remotes)
BaseService.init(remotes)
EconomyService.init(remotes)
WaveService.init(remotes)
RebirthService.init(remotes)

print("[Brainrot Bay] All services started. Welcome to the bay!")
