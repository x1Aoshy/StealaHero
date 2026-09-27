-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMVCElzQ2xpZW50EVJlcGxpY2F0ZWRTdG9yYWdlDVNlcnZlclN0b3JhZ2UISW5zdGFuY2UDbmV3CldvcmxkTW9kZWwSWm9uZVBsdXNXb3JsZE1vZGVsBE5hbWUEZ2FtZQpHZXRTZXJ2aWNlBlBhcmVudA9zZXR1cFdvcmxkTW9kZWwJd29ya3NwYWNlBXBhaXJzBXRhYmxlBmluc2VydBNfZ2V0Q29tYmluZWRSZXN1bHRzEkdldFBhcnRCb3VuZHNJbkJveBVHZXRQYXJ0Qm91bmRzSW5SYWRpdXMOR2V0UGFydHNJblBhcnQKUnVuU2VydmljZQAGBgECAAAAIPsBAAAOAQIA+wEAAIIBAgD7AgEAvAICBAAAAACfAgICDgICAG8BAQBlAAEAbwECAKQCBQAAEDCAbwMGAJ8CAgLeAgAA+wIAAG8DBwAwAwK6CAAAAPsCAACkAwoAAACQQFIFAQC8AwMWCwAAAJ8DAwIwAwIkDAAAAPsCAACCAgIADQMBAwIDAwMEAwUEABAwgAMGAwcDCAMJBAAAkEADCgMLAAYMARgAAAEAAgAAAAAAAAABAAAAAAEAAAABAAAAAAAAAAABAAcAAAAADAIBAQAAHqMCAACkAwEAAAAAQIcCAwGkAwEAAAAAQN0EAACfAgAC+wMAAA4DEwD7BAAAhwMEAfsEAADdBQAAnwMAAqQEAwAAACBAUgUDAJ8EAgQXBAcAnjQCBQgAAABSCgIAUgsIAKQJBgAAFECAnwkDAW4E+P8CAAAAggICAAcDDQQAAABAAw4EAAAgQAMPAxAEABRAgAASEQEYAAEAAAAAAAABAAEAAAAAAQAAAAABAAAAAAAA/wAEEgAAAAAKBAAAAAAIbwYAAFIHAQBSCAIAUgkDALwEAKoBAAAAnwQGAIIEAAACAxIDEQAdEgEYAAAAAAAAAAAeAAAAAAoEAAAAAAhvBgAAUgcBAFIIAgBSCQMAvAQAqgEAAACfBAYAggQAAAIDEwMRACETARgAAAAAAAAAACIAAAAACAMAAAAAB28FAABSBgEAUgcCALwDAKoBAAAAnwMFAIIDAAACAxQDEQAlFAEYAAAAAAAAACYAAAAABQAAAQIAHqMAAAD/AAQAAAAAAMYBAACkAgEAAAAAQG8EAgC8AgIWAwAAAJ8CAwLZAwAAEgEB/xIAAgAwAwDxBAAAANkDAQASAQH/MAMAqgUAAADAAwYAMAMALwcAAADAAwgAMAMATAkAAADAAwoAMAMAtQsAAADBAQAAggACAAwDCQQAAABAAxUDCgMMAxEGAgMSBgMDEwYEAxQFAAECAwQBAAEYAAAAAQEAAAAAAAMAAAAADAAAAAsAAAQAAAQAAAQAAQAAAAAFKXTN8lfm67J+HHUZDlySd1ls2oYbsKfz

-- decompilation:
local t1 = {}
local WorldModel = nil
local RunService = game:GetService("RunService")

function t1.setupWorldModel(_) -- line: 6
	-- upvalues: WorldModel (ref), RunService (copy)
	if WorldModel then
		return WorldModel
	end

	local v5 = not RunService:IsClient() and "ServerStorage" or "ReplicatedStorage"

	WorldModel = Instance.new("WorldModel")
	WorldModel.Name = "ZonePlusWorldModel"
	WorldModel.Parent = game:GetService(v5)

	return WorldModel
end
function t1._getCombinedResults(_, p3, ...) -- line: 18
	-- upvalues: WorldModel (ref)
	local v8 = workspace[p3](workspace, ...)

	if WorldModel then
		local v9 = WorldModel[p3](WorldModel, ...)

		for _, v in pairs(v9) do
			table.insert(v8, v)
		end
	end

	return v8
end
function t1.GetPartBoundsInBox(p4, p5, p6, p7) -- line: 29
	return p4:_getCombinedResults("GetPartBoundsInBox", p5, p6, p7)
end
function t1.GetPartBoundsInRadius(p8, p9, p10, p11) -- line: 33
	return p8:_getCombinedResults("GetPartBoundsInRadius", p9, p10, p11)
end
function t1.GetPartsInPart(p12, p13, p14) -- line: 37
	return p12:_getCombinedResults("GetPartsInPart", p13, p14)
end

return t1

