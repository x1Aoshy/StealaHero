-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTBGdhbWUKUnVuU2VydmljZQpHZXRTZXJ2aWNlC0h0dHBTZXJ2aWNlBUpvYklkJDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMAhJc1N0dWRpbwZhc3NlcnQISXNTZXJ2ZXIMR2VuZXJhdGVHVUlEBWxvd2VyBnNjcmlwdAZTdHVkaW8MU2V0QXR0cmlidXRlDEdldEF0dHJpYnV0ZQR0eXBlBnN0cmluZwR0YXNrBHdhaXQAAQcAAAEBEwAABA8DMRIPAAFEDwEHPg8CDThFowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBAQAAAABAbwMEALwBARYDAAAAnwEDAqQCAQAAAABATQICfAUAAAAcAwIADQMDAAYAAADwAi8ABwAAgLwEAAoIAAAAnwQCAEwBAAKkAwoAAACQQJ8DAAG8AwALCwAAAJ8DAgIOAxAAqQUAALwDAaQMAAAAnwMDArwDA+8NAAAAnwMCAlICAwCkAw8AAADgQG8FEABSBgIAvAMDLhEAAACfAwQBggICAKQDDwAAAOBAbwUQALwDAxISAAAAnwMDArsoAwNSBQMApAQUAAAAMEGfBAIC8AQDABUAAIBSAgMAggICAKQEGAAAXGCBnwQBAUgA7f+CAgIAGQMBBAAAAEADAgMDAwQDBQIAAAAAAAAAAAMGAwcDCAQAAJBAAwkDCgMLAwwEAADgQAMNAw4DDwMQBAAAMEEDEQMSAxMEAFxggQABAAEYABMAAAAAAAEAAAAAAAIAAAABAAAAAAEAAAAAAAABAAAAAQAAAAAAAAABAAAAAAAAAAMAAAAAAAEAAAAAAAABAQIAAPoLAQAAAAAAwi+EYnrMb665X1xlU9timLI3kxbw6+5j

-- decompilation:
--!native
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local JobId = game.JobId

if #JobId == 0.0 or JobId == "00000000-0000-0000-0000-000000000000" then
	assert(RunService:IsStudio())

	if RunService:IsServer() then
		local v4 = HttpService:GenerateGUID(false):lower()

		script:SetAttribute("Studio", v4)

		return v4
	end

	local Studio = nil

	while true do
		Studio = script:GetAttribute("Studio")

		if type(Studio) == "string" then
			break
		end

		task.wait()
	end

	return Studio
end

return JobId

