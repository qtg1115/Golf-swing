local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))

local ScheduleService = {}

local currentIndex = 1
local periodEndsAt = 0
local dayNumber = 1
local attendedThisPeriod: { [number]: boolean } = {}
local onPeriodEnd: ((any, { [number]: boolean }) -> ())? = nil

local function now(): number
	return workspace:GetServerTimeNow()
end

local function currentPeriod()
	return Config.Periods[currentIndex]
end

function ScheduleService.snapshot()
	local period = currentPeriod()
	return {
		day = dayNumber,
		index = currentIndex,
		id = period.id,
		name = period.name,
		kind = period.kind,
		subject = period.subject,
		room = period.room,
		hint = period.hint,
		endsAt = periodEndsAt,
		remaining = math.max(0, periodEndsAt - now()),
		periodSeconds = Config.PeriodSeconds,
	}
end

function ScheduleService.markAttended(userId: number)
	attendedThisPeriod[userId] = true
end

function ScheduleService.didAttend(userId: number): boolean
	return attendedThisPeriod[userId] == true
end

function ScheduleService.onPeriodEnded(callback)
	onPeriodEnd = callback
end

function ScheduleService.start()
	periodEndsAt = now() + Config.PeriodSeconds
	Remotes.get("PeriodChanged"):FireAllClients(ScheduleService.snapshot())

	task.spawn(function()
		while true do
			task.wait(0.5)
			if now() < periodEndsAt then
				continue
			end

			local ending = currentPeriod()
			if onPeriodEnd then
				onPeriodEnd(ending, attendedThisPeriod)
			end

			attendedThisPeriod = {}
			currentIndex += 1
			if currentIndex > #Config.Periods then
				currentIndex = 1
				dayNumber += 1
			end
			periodEndsAt = now() + Config.PeriodSeconds
			Remotes.get("PeriodChanged"):FireAllClients(ScheduleService.snapshot())
		end
	end)
end

return ScheduleService
