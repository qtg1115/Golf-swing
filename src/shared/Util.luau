local Util = {}

function Util.clamp(value: number, minValue: number, maxValue: number): number
	return math.clamp(value, minValue, maxValue)
end

function Util.round(value: number, digits: number): number
	local factor = 10 ^ digits
	return math.floor(value * factor + 0.5) / factor
end

function Util.average(values: { [string]: number }): number
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

function Util.deepCopy(value)
	if typeof(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, child in value do
		copy[key] = Util.deepCopy(child)
	end
	return copy
end

function Util.xpForLevel(level: number): number
	return 80 + (level - 1) * 35
end

function Util.formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local minutes = math.floor(seconds / 60)
	local remain = seconds % 60
	return string.format("%d:%02d", minutes, remain)
end

return Util
