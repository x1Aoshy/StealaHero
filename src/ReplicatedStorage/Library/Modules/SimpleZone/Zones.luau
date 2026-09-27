-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMlC0FjdGl2ZVpvbmVzDHJlZ2lzdGVyWm9uZQ5kZXJlZ2lzdGVyWm9uZQxRdWVyeU9wdGlvbnMRVGhyb3R0bGluZ0VuYWJsZWQCb3MFY2xvY2sLX2xhc3RVcGRhdGUOVXBkYXRlSW50ZXJ2YWwIRmlyZU1vZGUHT25FbnRlcgRCb3RoBE5vbmUGT25FeGl0FEluU2VwZXJhdGVRdWVyeVNwYWNlC193b3JsZE1vZGVsC19xdWVyeVNwYWNlB2R5bmFtaWMFdGFibGUGY3JlYXRlCHJlcGxpY2FzBWluZGV4BkNGcmFtZQRFbnVtDEJ1bGtNb3ZlTW9kZRFGaXJlQ0ZyYW1lQ2hhbmdlZApCdWxrTW92ZVRvC1F1ZXJ5UGFyYW1zBlVwZGF0ZQRnYW1lClJ1blNlcnZpY2UKR2V0U2VydmljZQZzY3JpcHQGUGFyZW50D1RvdGFsWm9uZVZvbHVtZQ5Qb3N0U2ltdWxhdGlvbgdDb25uZWN0AAQDAgEAAAcEAAAFAg8EBfsCAABNAgI3AAAAAGoBAgCCAAEAAQMBAA8CARgAAAAAARAAAAAAAwEBAAAABvsBAABNAQE3AAAAAMYCAABqAgEAggABAAEDAQATAwEYAAAAAAABFAAAAAATAQEAAABg+wEAAE0BATcAAAAAxgIAAMYDAABkAVcATQYF0QEAAABNBwb8AgAAAA4HDACkBwUAABAwgJ8HAQJNCQS4BgAAACYIBwlNCQZrBwAAALcISQAJAAAAMAcEuAYAAABNCAbWCAAAAPAIBgAJAAAAqQcAAE0IBtYIAAAA8AgHAAoAAIBNCAbWCAAAAPAIAgALAACAqQcAAakHAQBNCQbWCAAAAPAJBgAMAAAAqQgAAE0JBtYIAAAA8AkHAAoAAIBNCQbWCAAAAPAJAgALAACAqQgAAakIAQBNCQZqDQAAAA4JHgBNCQQSDgAAAE0KBPYPAAAATQsKUxAAAACkDBMAAEgQgU0OCxEUAAAAHA0OAJ8MAgJNDQsCFQAAAMYOAADGDwAAZA0DAE0SEYUWAAAAahIMEG4N/P8CAAAATQ8LERQAAABSEAwApBEaABlgcMG8DQnDGwAAAJ8NBQFNCwVwHAAAAFIMBwBSDQgAvAkEJh0AAACfCQUBbgGo/wIAAACCAAEAHgMBAwQDBQMGAwcEABAwgAMIAwkDCgMLAwwDDQMOAw8DEAMRAxIDEwMUBABIEIEDFQMWAxcDGAMZAxoEGWBwwQMbAxwDHQAXAAEYAAAAAAAAAQACAAABAAABAAAAAAAAAwADAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAACAAABAAEAAQACAAAAAAACAAAAAAEAAP8AAwAAAAAAAAADAAAAAAAA5QAdGAAAAAAGAAABAgAgowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQEBJAYAAADiAgoA/wMAAAAAAAAwAwI3BwAAAMADCwASAAIAMAMCwgwAAADAAw0AEgACADADAo8OAAAATQMAtg8AAADABRAAEgACALwDA8cRAAAAnwMDAYICAgASAx4EAAAAQAMfAyADIQQAAEBAAyIDAQMjAgAAAAAAAAAACAIH/////wgJAAAABgADAgYBAwMDJAYCAyUDAAECAQABGAAAAAAAAAACAAAABwEAAAAEAAAABAAAAAQAAAAAAAAgAQAAAAADSR5zKg+KP+S6EQX9VcsDfDkGZF572hkr

-- decompilation:
local RunService = game:GetService("RunService")
local _ = script.Parent
local t1 = {
	TotalZoneVolume = 0.0,
	ActiveZones = {}
}

function t1.registerZone(p1, t2: {[any]: any}) -- line: 15
	-- upvalues: t1 (copy)
	t1.ActiveZones[p1] = t2
end
function t1.deregisterZone(p2) -- line: 19
	-- upvalues: t1 (copy)
	t1.ActiveZones[p2] = nil
end

RunService.PostSimulation:Connect(function(_) -- line: 23
	-- upvalues: t1 (copy)
	for v8, v9 in t1.ActiveZones do
		local QueryOptions = v9.QueryOptions

		if QueryOptions.ThrottlingEnabled then
			local elapsed = os.clock()

			if elapsed - v8._lastUpdate < QueryOptions.UpdateInterval then
				continue
			end

			v8._lastUpdate = elapsed
		end

		local v12 = (QueryOptions.FireMode == "OnEnter" or QueryOptions.FireMode == "Both") and QueryOptions.FireMode ~= "None"
		local v13 = (QueryOptions.FireMode == "OnExit" or QueryOptions.FireMode == "Both") and QueryOptions.FireMode ~= "None"

		if QueryOptions.InSeperateQuerySpace then
			local _worldModel = v8._worldModel
			local dynamic = v8._querySpace.dynamic
			local t3 = table.create(#dynamic.replicas)

			for v17, v18 in dynamic.index do
				t3[v17] = v18.CFrame
			end

			_worldModel:BulkMoveTo(dynamic.replicas, t3, Enum.BulkMoveMode.FireCFrameChanged)
		end

		v8:Update(v9.QueryParams, v12, v13)
	end
end)

return t1

