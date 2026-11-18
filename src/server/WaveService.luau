-- WaveService: the tsunami. Every Config.WAVE.interval seconds a warning
-- goes out, then a giant wave wall sweeps the map from north to south.
-- Anyone caught outside their own base is flung back to spawn and slowed;
-- every brainrot still walking the belt washes away. The dash home is the
-- game's second threat, beside stealing.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local BrainrotService = require(script.Parent:WaitForChild("BrainrotService"))

local WaveService = {}

local waveWall: Part
local notifyRemote: RemoteEvent
local waveRemote: RemoteEvent
local nextWaveAt = 0
local waveRunning = false

-- Flings a player back to the spawn point and slows them for a few seconds.
local function washOutPlayer(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end
	local spawn = Workspace:FindFirstChild("SpawnLocation")
	local spawnPos = Vector3.new(0, 5, 205)
	if spawn and spawn:IsA("SpawnLocation") then
		spawnPos = spawn.Position + Vector3.new(0, 3, 0)
	end
	root.CFrame = CFrame.new(spawnPos)
	root.AssemblyLinearVelocity = Vector3.zero
	humanoid.WalkSpeed = Config.WAVE.slowSpeed
	task.delay(Config.WAVE.slowDuration, function()
		if humanoid.Parent then
			humanoid.WalkSpeed = 16
		end
	end)
end

-- One wave: warn, sweep the wall across the map, wash out anyone caught
-- outside their base, and clear the belt.
function WaveService.triggerWave()
	if waveRunning then
		return
	end
	waveRunning = true
	if waveRemote then
		waveRemote:FireAllClients("warning", Config.WAVE.warningTime)
	end
	if notifyRemote then
		notifyRemote:FireAllClients("🌊 TSUNAMI INCOMING! RUN TO YOUR BASE!", Color3.fromRGB(90, 180, 255))
	end
	task.wait(Config.WAVE.warningTime)

	-- Sweep from z = -230 to z = +230.
	local startZ = -230
	local endZ = 230
	local steps = 60
	waveWall.CFrame = CFrame.new(0, 20, startZ)
	waveWall.Transparency = 0.35
	for i = 1, steps do
		local z = startZ + (endZ - startZ) * (i / steps)
		waveWall.CFrame = CFrame.new(0, 20, z)
		-- Anyone under the wall who is not home gets washed out.
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				local state = DataService.getState(player)
				local home = state and state.baseIndex and BaseService.isInsideBase(root.Position, state.baseIndex)
				if not home and math.abs(root.Position.Z - z) < 6 then
					washOutPlayer(player)
					if notifyRemote then
						notifyRemote:FireClient(player, "🌊 The wave got you! Back to spawn!", Color3.fromRGB(90, 180, 255))
					end
				end
			end
		end
		task.wait(Config.WAVE.sweepTime / steps)
	end
	waveWall.Transparency = 1
	BrainrotService.clearBelt()
	if waveRemote then
		waveRemote:FireAllClients("over", 0)
	end
	waveRunning = false
	nextWaveAt = os.clock() + Config.WAVE.interval
end

-- Seconds until the next wave, for the HUD countdown.
function WaveService.secondsToNextWave(): number
	return math.max(0, nextWaveAt - os.clock())
end

function WaveService.init(remotes: { [string]: RemoteEvent })
	notifyRemote = remotes.Notify
	waveRemote = remotes.WaveEvent
	waveWall = Workspace:WaitForChild("WaveWall")
	nextWaveAt = os.clock() + Config.WAVE.interval
	task.spawn(function()
		while true do
			task.wait(math.max(1, WaveService.secondsToNextWave()))
			WaveService.triggerWave()
		end
	end)
end

return WaveService
