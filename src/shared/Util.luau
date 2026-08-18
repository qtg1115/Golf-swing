local Util = {}

function Util.clamp(value: number, low: number, high: number): number
	return math.clamp(value, low, high)
end

function Util.round(value: number, digits: number): number
	local factor = 10 ^ digits
	return math.floor(value * factor + 0.5) / factor
end

function Util.average(values): number
	local total = 0
	local count = 0
	for _, value in values do
		total += value
		count += 1
	end
	if count == 0 then
		return 0
	end
	return total / count
end

function Util.copy(value)
	if typeof(value) ~= "table" then
		return value
	end
	local out = {}
	for key, child in value do
		out[key] = Util.copy(child)
	end
	return out
end

function Util.xpForLevel(level: number): number
	return 70 + (level - 1) * 40
end

function Util.titleForLevel(level: number, titles): string
	local current = titles[1].title
	for _, entry in titles do
		if level >= entry.min then
			current = entry.title
		end
	end
	return current
end

function Util.formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

function Util.standUpPower(profile): number
	local power = profile.level
	if profile.gear.badge then
		power += 3
	end
	power += profile.stats.friendsHelped or 0
	return power
end

return Util
