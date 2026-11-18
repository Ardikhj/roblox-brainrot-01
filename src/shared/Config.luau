-- Config: every tuning number of Brainrot Bay in one place.
-- The services read from here so a balance pass touches one file.

local Config = {}

-- The belt down the middle of the map: brainrots walk from the spawn tunnel
-- (north, -Z) to the exit portal (south, +Z) and despawn there.
Config.BELT = {
	width = 16,
	startZ = -175,
	endZ = 175,
	walkSpeed = 7, -- studs per second
	spawnInterval = 6, -- seconds between spawns
	maxOnBelt = 10,
	laneX = 0,
}

-- Bases: eight plots, four on each side of the belt. A player claims the
-- lowest free plot when they join; the plot's colour is its identity.
Config.BASES = {
	count = 8,
	slotsPerBase = 10,
	positions = {
		Vector3.new(-42, 0, -120), Vector3.new(-42, 0, -40),
		Vector3.new(-42, 0, 40), Vector3.new(-42, 0, 120),
		Vector3.new(42, 0, -120), Vector3.new(42, 0, -40),
		Vector3.new(42, 0, 40), Vector3.new(42, 0, 120),
	},
	colors = {
		Color3.fromRGB(255, 90, 90), Color3.fromRGB(90, 160, 255),
		Color3.fromRGB(90, 220, 120), Color3.fromRGB(255, 200, 60),
		Color3.fromRGB(190, 110, 255), Color3.fromRGB(255, 140, 200),
		Color3.fromRGB(60, 220, 220), Color3.fromRGB(255, 150, 60),
	},
}

-- Stealing: a base is safe while locked. Lock lasts 60 s, then a 90 s
-- cooldown before it can lock again. A stolen brainrot follows its thief;
-- the thief has 25 s to reach their own base, or it walks home.
Config.STEAL = {
	lockDuration = 60,
	lockCooldown = 90,
	stealEscapeTime = 25,
	stealRange = 10, -- studs from a brainrot to grab it
	slapCooldown = 3,
	slapRange = 12,
	slapKnockback = 55,
}

-- The wave: a tsunami wall sweeps the map every 150 s. Ten seconds of
-- warning, then the wall crosses in 12 s. Anyone caught outside their own
-- base is flung back to spawn and slowed for 5 s. Belt brainrots wash away.
Config.WAVE = {
	interval = 150,
	warningTime = 10,
	sweepTime = 12,
	slowDuration = 5,
	slowSpeed = 8, -- WalkSpeed while slowed (normal is 16)
}

-- Rebirth: pay the price, lose your cash and your brainrots, keep a
-- permanent +50% earnings multiplier per rebirth and a new aura colour.
Config.REBIRTH = {
	baseCost = 250000,
	costGrowth = 5, -- cost = baseCost * costGrowth ^ rebirths
	multiplierPerRebirth = 0.5,
	auraColors = {
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(255, 210, 60),
		Color3.fromRGB(140, 220, 255),
		Color3.fromRGB(255, 110, 220),
		Color3.fromRGB(0, 255, 180),
		Color3.fromRGB(255, 80, 20),
	},
}

-- Economy: earnings tick once a second; new players start with $100.
Config.ECONOMY = {
	startCash = 100,
	tickInterval = 1,
}

-- Prices of the free starting slap: every player spawns able to slap.
Config.SLAP = {
	knockback = 55,
	range = 12,
	cooldown = 3,
}

return Config
