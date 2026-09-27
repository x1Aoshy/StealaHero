-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMZCXdvcmtzcGFjZRBHZXRTZXJ2ZXJUaW1lTm93B0lzTmlnaHQFSXNEYXkCb3MFY2xvY2sOQmxvb2Rtb29uRXZlbnQMR2V0QXR0cmlidXRlEVRyaWNrT3JUcmVhdEV2ZW50DkdyYXZleWFyZEV2ZW50DE1hZ21hV2VhdGhlcghTdGFyZmFsbAlDbG9ja1RpbWUEbWF0aANhYnMJVHdlZW5JbmZvA25ldwZDcmVhdGUEUGxheQZVcGRhdGUFU3RhcnQEZ2FtZQxUd2VlblNlcnZpY2UKR2V0U2VydmljZQhMaWdodGluZwAFBAAAAAAADKQCAgAAABBAvAICtwMAAACfAgICIQECAIwChAPUAgIAAQAAAKkAAAGpAAEAggACAAQCAAAAAAAgnEADAQQAABBAAwIADwMBGAAAAAAAAAAAAAAAABAAAAAABAAAAAAADKQCAgAAABBAvAICtwMAAACfAgICIQECAIwChAO3AQIAAgAAAKkAAAGpAAEAggACAAQCAAAAAAAgnEADAQQAABBAAwIAEwQBGAAAAAAAAAAAAAAAABQAAAAACAAEAAAAU6QAAgAABACAnwABAt4AAACpAAEAxgEAAKQCBAAAADBAbwQFALwCAhIGAAAAnwIDAg4CAQCMARQApAIEAAAAMEBvBAcAvAICEgYAAACfAgMCKwIHAKQCBAAAADBAbwQIALwCAhIGAAAAnwIDAg4CAgCMAQUAqQAAAKQCBAAAADBAbwQJALwCAhIGAAAAnwIDAisCBwCkAgQAAAAwQG8ECgC8AgISBgAAAJ8CAwIOAgEAjAEAAFYCAQArAQEAbwELAPsFAQBNBQUgDAAAACYEAQW7AgQCpAMPAAA40ICfAwICjAQBAGAEFAADAAAA+wMCAPECEQADAAAA+wMDAPsFAQCkBhIAAEQAgYwHBQCfBgIC4gcTADABByAMAAAAvAMDlhQAAACfAwUCvAMD7hUAAACfAwIBZQADAPsDAQAwAQMgDAAAAN4CAgCCAAEAFgMFAwYEAAQAgAMBBAAAMEADBwMIAwkDCgMLAwwCAAAAAAAALUADDQMOAw8EADjQgAMQAxEEAEQAgQUBDAMSAxMAFxQBGAAAAAACAQIAAAAAAAABAwAAAAAAAAAAAAAAAAABAQIAAAAAAAAAAAAAAAAAAQMBAQ8AAAAAAAAAAAAAAAAAAQAAAAAAAAEA/wAAAgAAAAUAAAMBGAAAAAAAAAAAAAABggABAAAASBUBGABRAAAAAAYAAAECACajAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEBAAAAAEBvAwQAvAEBFgMAAACfAQMCxgIAAMYDAAD/BAMAAAAAAMAFBQAwBQQUBgAAAMAFBwAwBQTGCAAAANkFAgASAQL/EgABABIBA/8SAAAAMAUEJgkAAADABQoAMAUEHAsAAABNBQQcCwAAAJ8FAQHBAgAAggQCAAwDFgQAAABAAxcDGAMZBgADAwYBAwQDFAYDAxUEAAECAwEAARgAAwAAAAAAAQAAAAAAAwEDAAMAAAQAAAQAAAAAAAAxAAALAAACAAEAAAAABBlOemA66s8EJQA6STDDC7ZpVm0UK4oQYQ==

-- decompilation:
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local elapsed = nil
local u4 = nil
local t1 = {
	IsNight = function() -- line: 15
		return workspace:GetServerTimeNow() % 1800.0 >= 900.0
	end,
	IsDay = function() -- line: 19
		return workspace:GetServerTimeNow() % 1800.0 < 900.0
	end,
	Update = function() -- line: 23
		-- upvalues: elapsed (ref), Lighting (copy), u4 (ref), TweenService (copy)
		elapsed = os.clock()

		local n1 = nil

		if workspace:GetAttribute("BloodmoonEvent") then
			n1 = 20.0
		end

		if workspace:GetAttribute("TrickOrTreatEvent") or workspace:GetAttribute("GraveyardEvent") then
			n1 = 5.0
		end

		if workspace:GetAttribute("MagmaWeather") or workspace:GetAttribute("Starfall") then
			n1 = 0.0
		end

		local v7 = not n1

		if not n1 then
			n1 = 14.5
		end

		if math.abs(n1 - Lighting.ClockTime) > 1.0 and v7 ~= u4 then
			TweenService:Create(Lighting, TweenInfo.new(5.0), {
				ClockTime = n1
			}):Play()
		else
			Lighting.ClockTime = n1
		end

		u4 = v7
	end,
	Start = function() -- line: 72
	end
}

t1.Start()

return t1

