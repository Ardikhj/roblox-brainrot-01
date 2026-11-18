-- BrainrotCatalog: the whole cast of Brainrot Bay.
-- Every character is original to this game: absurd, meme-born, named, and
-- ranked on a ladder of six rarities. A character's money-per-second is its
-- base rate; mutations and rebirths multiply it (see Config).

local BrainrotCatalog = {}

export type RarityName = "Common" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Secret"
export type MutationName = "Normal" | "Golden" | "Diamond" | "Rainbow" | "Lava"

export type CharacterDef = {
	id: string,
	name: string,
	rarity: RarityName,
	rate: number, -- dollars per second at Normal mutation, 0 rebirths
	cost: number, -- dollars to buy it off the belt
	bodyColor: Color3,
	accentColor: Color3,
	size: number, -- body studs, bigger for rarer characters
	blurb: string, -- the joke the floating label shows
}

-- Rarity ladder: spawn weight, rate band and the colour the world paints it.
BrainrotCatalog.RARITIES = {
	Common = { weight = 55, color = Color3.fromRGB(120, 200, 90), glow = 0 },
	Rare = { weight = 25, color = Color3.fromRGB(70, 140, 255), glow = 0 },
	Epic = { weight = 12, color = Color3.fromRGB(170, 90, 230), glow = 0.15 },
	Legendary = { weight = 5.5, color = Color3.fromRGB(255, 190, 40), glow = 0.3 },
	Mythic = { weight = 2, color = Color3.fromRGB(255, 70, 120), glow = 0.5 },
	Secret = { weight = 0.5, color = Color3.fromRGB(40, 40, 40), glow = 0.8 },
}

-- Mutations: a random roll when a character spawns on the belt.
BrainrotCatalog.MUTATIONS = {
	Normal = { weight = 80, multiplier = 1, color = nil },
	Golden = { weight = 10, multiplier = 2, color = Color3.fromRGB(255, 210, 60) },
	Diamond = { weight = 6, multiplier = 4, color = Color3.fromRGB(140, 220, 255) },
	Rainbow = { weight = 3, multiplier = 8, color = Color3.fromRGB(255, 110, 220) },
	Lava = { weight = 1, multiplier = 15, color = Color3.fromRGB(255, 80, 20) },
}

-- The cast, cheapest first. Cost is roughly rate x 8-10 seconds of its own
-- earnings, so the next tier always feels one good catch away.
BrainrotCatalog.CHARACTERS = {
	{ id = "crocs", name = "Sir Crocs-a-Lot", rarity = "Common", rate = 6, cost = 50,
		bodyColor = Color3.fromRGB(150, 110, 70), accentColor = Color3.fromRGB(255, 220, 90), size = 2.2,
		blurb = "A capybara in crocs. He pays rent. In crocs." },
	{ id = "flush", name = "DJ Flush", rarity = "Common", rate = 9, cost = 120,
		bodyColor = Color3.fromRGB(230, 240, 245), accentColor = Color3.fromRGB(90, 200, 255), size = 2.2,
		blurb = "A toilet with headphones. Drops beats, not... you know." },
	{ id = "pigeon", name = "Pigeon CEO", rarity = "Common", rate = 12, cost = 200,
		bodyColor = Color3.fromRGB(130, 130, 150), accentColor = Color3.fromRGB(40, 40, 40), size = 2.4,
		blurb = "Middle manager of the park. Bills by the crumb." },
	{ id = "banana", name = "Banana Phone Boi", rarity = "Rare", rate = 25, cost = 500,
		bodyColor = Color3.fromRGB(255, 225, 60), accentColor = Color3.fromRGB(250, 250, 250), size = 2.6,
		blurb = "Hello? Yes, this is banana. He takes calls 24/7." },
	{ id = "wifi", name = "Grandma's WiFi", rarity = "Rare", rate = 35, cost = 900,
		bodyColor = Color3.fromRGB(200, 200, 210), accentColor = Color3.fromRGB(255, 150, 200), size = 2.6,
		blurb = "A router in a shawl. Password is 'password123'." },
	{ id = "cereal", name = "Soggy Cereal Knight", rarity = "Rare", rate = 45, cost = 1400,
		bodyColor = Color3.fromRGB(220, 170, 90), accentColor = Color3.fromRGB(180, 60, 60), size = 2.8,
		blurb = "Sworn to protect the milk. The milk expired in 2019." },
	{ id = "toaster", name = "Turbo Toaster Cat", rarity = "Epic", rate = 80, cost = 3000,
		bodyColor = Color3.fromRGB(255, 170, 60), accentColor = Color3.fromRGB(255, 240, 200), size = 3.0,
		blurb = "A cat in a toaster. Pops up. Always lands on rent." },
	{ id = "llama", name = "Llama in a Lambo", rarity = "Epic", rate = 120, cost = 5500,
		bodyColor = Color3.fromRGB(255, 240, 220), accentColor = Color3.fromRGB(255, 200, 0), size = 3.2,
		blurb = "0 to 100 in 3 seconds. Spits at red lights." },
	{ id = "pickle", name = "Pickle Wizard", rarity = "Epic", rate = 160, cost = 9000,
		bodyColor = Color3.fromRGB(90, 180, 60), accentColor = Color3.fromRGB(150, 90, 230), size = 3.2,
		blurb = "Cast 'Dill-usion'. Your wallet is now his." },
	{ id = "goldfish", name = "Sir Reginald III", rarity = "Legendary", rate = 300, cost = 20000,
		bodyColor = Color3.fromRGB(255, 140, 40), accentColor = Color3.fromRGB(255, 215, 0), size = 3.6,
		blurb = "A goldfish in a top hat. Old money. Literally wet." },
	{ id = "intern", name = "The Unpaid Intern", rarity = "Legendary", rate = 450, cost = 35000,
		bodyColor = Color3.fromRGB(200, 220, 235), accentColor = Color3.fromRGB(60, 60, 90), size = 3.6,
		blurb = "A ghost with a tie. Works for exposure. Haunts HR." },
	{ id = "potato", name = "Couch Potato King", rarity = "Legendary", rate = 600, cost = 60000,
		bodyColor = Color3.fromRGB(190, 140, 80), accentColor = Color3.fromRGB(200, 40, 40), size = 3.8,
		blurb = "A potato on a throne. Rules the remote. Never the remote's batteries." },
	{ id = "quokka", name = "Quantum Quokka", rarity = "Mythic", rate = 1200, cost = 150000,
		bodyColor = Color3.fromRGB(140, 230, 255), accentColor = Color3.fromRGB(255, 255, 255), size = 4.2,
		blurb = "Smiles in two places at once. Physics gave up." },
	{ id = "algorithm", name = "The Algorithm", rarity = "Mythic", rate = 2000, cost = 300000,
		bodyColor = Color3.fromRGB(90, 90, 120), accentColor = Color3.fromRGB(0, 255, 180), size = 4.4,
		blurb = "A floating robot eye. It knows what you watched." },
	{ id = "slipper", name = "Grandma's Revenge", rarity = "Mythic", rate = 3500, cost = 600000,
		bodyColor = Color3.fromRGB(255, 120, 180), accentColor = Color3.fromRGB(255, 255, 255), size = 4.6,
		blurb = "A giant slipper. You know what you did." },
	{ id = "ohio", name = "The Ohio Boss", rarity = "Secret", rate = 8000, cost = 2000000,
		bodyColor = Color3.fromRGB(30, 30, 40), accentColor = Color3.fromRGB(255, 0, 60), size = 5.2,
		blurb = "Only in Ohio. Cannot be explained. Cannot be stopped." },
	{ id = "sandwich", name = "Admin's Lost Sandwich", rarity = "Secret", rate = 15000, cost = 5000000,
		bodyColor = Color3.fromRGB(255, 220, 130), accentColor = Color3.fromRGB(0, 220, 130), size = 5.4,
		blurb = "Glows with forbidden mayo. The admin wants it back." },
	{ id = "founder", name = "Golden Capybara Founder", rarity = "Secret", rate = 30000, cost = 15000000,
		bodyColor = Color3.fromRGB(255, 210, 60), accentColor = Color3.fromRGB(255, 255, 255), size = 6.0,
		blurb = "The first capybara. Statue-ified. Still in crocs." },
}

-- Look a character up by id; returns nil for an unknown id.
function BrainrotCatalog.getCharacter(id: string): CharacterDef?
	for _, def in ipairs(BrainrotCatalog.CHARACTERS) do
		if def.id == id then
			return def
		end
	end
	return nil
end

-- Weighted random pick of a rarity name.
function BrainrotCatalog.rollRarity(random: Random): RarityName
	local total = 0
	for _, info in pairs(BrainrotCatalog.RARITIES) do
		total += info.weight
	end
	local roll = random:NextNumber(0, total)
	local running = 0
	for name, info in pairs(BrainrotCatalog.RARITIES) do
		running += info.weight
		if roll <= running then
			return name :: RarityName
		end
	end
	return "Common"
end

-- Weighted random pick of a mutation name.
function BrainrotCatalog.rollMutation(random: Random): MutationName
	local total = 0
	for _, info in pairs(BrainrotCatalog.MUTATIONS) do
		total += info.weight
	end
	local roll = random:NextNumber(0, total)
	local running = 0
	for name, info in pairs(BrainrotCatalog.MUTATIONS) do
		running += info.weight
		if roll <= running then
			return name :: MutationName
		end
	end
	return "Normal"
end

-- All characters of one rarity, in cost order.
function BrainrotCatalog.getByRarity(rarity: RarityName): { CharacterDef }
	local out = {}
	for _, def in ipairs(BrainrotCatalog.CHARACTERS) do
		if def.rarity == rarity then
			table.insert(out, def)
		end
	end
	return out
end

-- The money-per-second of one owned brainrot after its mutation and its
-- owner's rebirth multiplier.
function BrainrotCatalog.effectiveRate(def: CharacterDef, mutation: MutationName, rebirthMultiplier: number): number
	local mult = BrainrotCatalog.MUTATIONS[mutation].multiplier
	return math.floor(def.rate * mult * rebirthMultiplier + 0.5)
end

return BrainrotCatalog
