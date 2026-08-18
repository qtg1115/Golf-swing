local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local ScheduleService = {}

local index = 1
local endsAt = 0
local day = 1
local attended: { [number]: boolean } = {}
local onEnd

local function now(): number
	return workspace:GetServerTimeNow()
end

function ScheduleService.snapshot()
	local period = Config.Periods[index]
	return {
		day = day,
		id = period.id,
		name = period.name,
		kind = period.kind,
		subject = period.subject,
		room = period.room,
		hint = period.hint,
		endsAt = endsAt,
		remaining = math.max(0, endsAt - now()),
	}
end

function ScheduleService.markAttended(userId: number)
	attended[userId] = true
end

function ScheduleService.didAttend(userId: number): boolean
	return attended[userId] == true
end

function ScheduleService.onPeriodEnd(callback)
	onEnd = callback
end

function ScheduleService.start()
	endsAt = now() + Config.PeriodSeconds
	Remotes.get("PeriodChanged"):FireAllClients(ScheduleService.snapshot())

	task.spawn(function()
		while true do
			task.wait(0.5)
			if now() < endsAt then
				continue
			end

			local ending = Config.Periods[index]
			if onEnd then
				pcall(onEnd, ending, attended)
			end

			attended = {}
			index += 1
			if index > #Config.Periods then
				index = 1
				day += 1
			end
			endsAt = now() + Config.PeriodSeconds
			Remotes.get("PeriodChanged"):FireAllClients(ScheduleService.snapshot())
		end
	end)
end

return ScheduleService
