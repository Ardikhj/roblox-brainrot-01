-- Format: the small text helpers the HUD and the floating labels share.

local Format = {}

-- $1,234,567 -> "$1.23M"; $950 -> "$950". Money is the game's heartbeat,
-- so it is always short enough to read at a glance.
function Format.money(amount: number): string
	local negative = amount < 0
	local value = math.abs(math.floor(amount + 0.5))
	local suffixes = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, pair in ipairs(suffixes) do
		local threshold, suffix = pair[1], pair[2]
		if value >= threshold then
			local short = value / threshold
			local text
			if short >= 100 then
				text = string.format("%d%s", math.floor(short + 0.5), suffix)
			else
				text = string.format("%.2f%s", short, suffix)
				text = text:gsub("%.?0+$", "") .. suffix
			end
			if negative then
				return "-$" .. text
			end
			return "$" .. text
		end
	end
	-- Under 1,000: plain number with commas.
	local text = tostring(value)
	local out = ""
	while #text > 3 do
		out = "," .. text:sub(-3) .. out
		text = text:sub(1, -4)
	end
	out = text .. out
	if negative then
		return "-$" .. out
	end
	return "$" .. out
end

-- 95 -> "1:35". Used for the lock timer, the steal countdown and the wave.
function Format.clock(seconds: number): string
	local total = math.max(0, math.floor(seconds + 0.5))
	local minutes = math.floor(total / 60)
	local rest = total % 60
	return string.format("%d:%02d", minutes, rest)
end

-- "$12/s" with the mutation and rebirth already folded in.
function Format.ratePerSecond(rate: number): string
	return Format.money(rate) .. "/s"
end

return Format
