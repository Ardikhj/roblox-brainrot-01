-- WorldBuilder: the 3D dressing the Rojo project does not declare. It builds
-- the big "BRAINROT BAY" sign over the spawn tunnel and one name banner per
-- base plot (BaseService.paintBase writes the owner's name on it). All of it
-- is built from Parts and BillboardGuis, which always face the camera, so no
-- surface faces ever need guessing.

local Workspace = game:GetService("Workspace")

local WorldBuilder = {}

-- One sign board with a BillboardGui title. parent is where it hangs.
local function buildSign(text: string, size: Vector3, position: Vector3, color: Color3, textSize: number): Model
	local model = Instance.new("Model")
	model.Name = "Sign"

	local board = Instance.new("Part")
	board.Name = "Board"
	board.Size = size
	board.Position = position
	board.Color = color
	board.Material = Enum.Material.SmoothPlastic
	board.Anchored = true
	board.Parent = model

	local gui = Instance.new("BillboardGui")
	gui.Name = "SignGui"
	gui.Size = UDim2.fromOffset(size.X * 24, size.Y * 24)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 0, 0)
	gui.AlwaysOnTop = false
	gui.Parent = board

	local label = Instance.new("TextLabel")
	label.Name = "SignText"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui

	model.Parent = Workspace
	return model
end

-- Builds the title sign and the eight base banners. Run once at startup,
-- before any player claims a base.
function WorldBuilder.build()
	-- Title sign above the spawn tunnel, facing the players who walk in.
	buildSign("🧠 BRAINROT BAY 🌊", Vector3.new(30, 8, 1), Vector3.new(0, 22, -186),
		Color3.fromRGB(90, 60, 180), 48)
	-- "STEAL • EARN • REBIRTH" under it, on the beam.
	buildSign("STEAL • EARN • REBIRTH", Vector3.new(24, 4, 1), Vector3.new(0, 13.5, -186),
		Color3.fromRGB(30, 30, 40), 32)

	-- One banner per base, on its back wall, named so paintBase finds it.
	local bases = Workspace:WaitForChild("Bases")
	for _, base in ipairs(bases:GetChildren()) do
		local pad = base:FindFirstChild("Pad")
		if pad then
			local banner = Instance.new("BillboardGui")
			banner.Name = "BaseBanner"
			banner.Size = UDim2.fromOffset(320, 60)
			banner.StudsOffsetWorldSpace = Vector3.new(0, 6, 0)
			banner.AlwaysOnTop = true
			banner.Parent = base:FindFirstChild("BackWall") or pad

			local text = Instance.new("TextLabel")
			text.Name = "BannerText"
			text.Size = UDim2.fromScale(1, 1)
			text.BackgroundTransparency = 1
			text.Text = base.Name .. " — EMPTY"
			text.TextColor3 = Color3.fromRGB(255, 255, 255)
			text.TextStrokeTransparency = 0
			text.TextScaled = true
			text.Font = Enum.Font.GothamBold
			text.Parent = banner
		end
	end
end

return WorldBuilder
