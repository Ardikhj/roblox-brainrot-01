-- Effects: the juice. A cash pop when the wallet jumps, a screen shake
-- when the wave hits, and a flash on a steal or a slap. Small, cheap, and
-- all client-side so the server never waits on them.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Effects = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- A quick shake of the camera: used when the wave washes the player out.
function Effects.shakeCamera(strength: number, duration: number)
	if not camera then
		return
	end
	local start = tick()
	task.spawn(function()
		while tick() - start < duration do
			local offset = Vector3.new(
				(math.random() - 0.5) * strength,
				(math.random() - 0.5) * strength,
				0
			)
			camera.CFrame = camera.CFrame * CFrame.new(offset)
			task.wait(0.05)
		end
	end)
end

-- A full-screen colour flash that fades in half a second: gold for a buy,
-- red for a steal, blue for the wave.
function Effects.flash(color: Color3)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end
	local gui = playerGui:FindFirstChild("BrainrotBayGui")
	if not gui then
		return
	end
	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 0.7
	flash.BorderSizePixel = 0
	flash.ZIndex = 50
	flash.Parent = gui
	local tween = TweenService:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
	tween:Play()
	tween.Completed:Connect(function()
		flash:Destroy()
	end)
end

-- Pops the cash label bigger for a beat when a purchase lands.
function Effects.popCash(cashLabel: TextLabel)
	if not cashLabel then
		return
	end
	local tween = TweenService:Create(cashLabel, TweenInfo.new(0.15, Enum.EasingStyle.Back), { TextSize = 38 })
	tween:Play()
	tween.Completed:Connect(function()
		local back = TweenService:Create(cashLabel, TweenInfo.new(0.2), { TextSize = 30 })
		back:Play()
	end)
end

return Effects
