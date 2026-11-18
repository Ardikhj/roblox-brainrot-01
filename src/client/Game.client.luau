-- Game.client: the client's front door. It builds the HUD, wires the
-- buttons and the F key to the server's remotes, and listens for the
-- server's state syncs, notifications and wave warnings.
-- The game itself is the 3D world underneath; this script is only the
-- interface over it and the input that drives it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Hud = require(script:WaitForChild("Hud"))
local Effects = require(script:WaitForChild("Effects"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateSync = remotes:WaitForChild("StateSync")
local notifyRemote = remotes:WaitForChild("Notify")
local waveRemote = remotes:WaitForChild("WaveEvent")
local lockRemote = remotes:WaitForChild("LockBase")
local rebirthRemote = remotes:WaitForChild("Rebirth")
local slapRemote = remotes:WaitForChild("SlapPlayer")

Hud.build()

-- Buttons: lock the base, rebirth. The server validates both.
Hud.getLockButton().MouseButton1Click:Connect(function()
	lockRemote:FireServer()
end)
Hud.getRebirthButton().MouseButton1Click:Connect(function()
	rebirthRemote:FireServer()
end)

-- F slaps the nearest player: the defence against a thief at your base.
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		slapRemote:FireServer()
		Effects.flash(Color3.fromRGB(255, 255, 255))
	end
end)

-- One state sync a second: cash, income, rebirths, lock timers.
stateSync.OnClientEvent:Connect(function(state)
	Hud.applyState(state)
end)

-- Toasts from the server: purchases, steals, locks, rebirths.
notifyRemote.OnClientEvent:Connect(function(message, color)
	Hud.toast(message, color)
	if typeof(message) == "string" then
		if message:find("STOLEN") then
			Effects.flash(Color3.fromRGB(255, 60, 60))
		elseif message:find("REBIRTH") then
			Effects.flash(Color3.fromRGB(255, 210, 60))
		end
	end
end)

-- The wave: show the banner on warning, shake the camera if it catches you.
waveRemote.OnClientEvent:Connect(function(kind, seconds)
	Hud.showWave(kind, seconds)
	if kind == "warning" then
		Hud.setHint("🌊 WAVE INCOMING — get to your base!")
		Effects.flash(Color3.fromRGB(90, 180, 255))
	elseif kind == "over" then
		Hud.setHint("Buy brainrots on the belt • F = slap • Run home when the wave comes!")
	end
end)

print("[Brainrot Bay] Client loaded. Good luck out there!")
