-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWEUdldE9yZGVyZWRTdGVwSWRzDkdldEZpcnN0U3RlcElkCEdldEluZGV4DUdldE5leHRTdGVwSWQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQVUeXBlcw1HdWFyZFR1dG9yaWFsBXRhYmxlBmZyZWV6ZQhTdGVhbEVnZwlIZWFkVG9QZW4IRXF1aXBFZ2cIUGxhY2VFZ2cISGF0Y2hFZ2cIUGxhY2VQZXQJRXhwYW5kUGVuDlRyZWFkbWlsbEludHJvBmlwYWlycwAFAQABAAAAAvsAAACCAAIAAAAkAQEYAAAlAAAAAAIAAQAAAAP7AQAAEwABAIIAAgAAACgCARgAAAApAAAAAAMBAQAAAAP7AgAAhwECAIIBAgAAACwDARgAAAAtAAAAAAUBAgAAAA37AQAATQEBZwAAAABSAgAAnwECAkcBAwAAAACAxgIAAIICAgD7AwEAlQQBAYcCAwSCAgIAAgMDAgAAAAAAAPA/ADAEARgAAAAAAAEAAAAAAAAAMQAAAAAMAAABAABBowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgLvBwAAAE0CAgAIAAAAnwECAqQCCwAAKJCA/wMAAAgAAABvBAwAbwUNAG8GDgBvBw8AbwgQAG8JEQBvChIAbwsTAMUDBAkBAAAAnwICAv8DAAAAAAAApAQVAAAAQEFSBQIAnwQCBFEEAQBqBwMIbgT+/wIAAICkBAsAACiQgFIFAwCfBAIB/wQDAAAAAADABRYAEgACADAFBIEXAAAAwAUYABIAAgAwBQSQGQAAAMAFGgASAAMAMAUEZxsAAADABRwAEgAEABIAAgAwBQQcHQAAAIIEAgAeAwUEAAAAQAMGAwcDCAQAAEBAAwkDCgMLAwwDDQQAKJCAAw4DDwMQAxEDEgMTAxQDFQMWBAAAQEEGAAMBBgEDAgYCAwMGAwMEBAABAgMBAAEYAAMAAAAAAAMAAAAAAAAAAAYAAAABAQEBAQEBAQAA+AoAAQAAAAAB/wADAAAAAwAGAAAABAAAAAQAAAAEAAAAAAUBAAAAAAQAczqdI32jfW9/F4ywkfYCcGst6TK3UJw=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Library.Types.GuardTutorial)

local v2 = table.freeze({
	"StealEgg",
	"HeadToPen",
	"EquipEgg",
	"PlaceEgg",
	"HatchEgg",
	"PlacePet",
	"ExpandPen",
	"TreadmillIntro"
})
local t1 = {}

for i, v in ipairs(v2) do
	t1[v] = i
end

table.freeze(t1)

local t2 = {
	GetOrderedStepIds = function() -- line: 36
		-- upvalues: v2 (copy)
		return v2
	end,
	GetFirstStepId = function() -- line: 40
		-- upvalues: v2 (copy)
		return v2[1.0]
	end,
	GetIndex = function(p1) -- line: 44
		-- upvalues: t1 (copy)
		return t1[p1]
	end
}

function t2.GetNextStepId(p2) -- line: 48
	-- upvalues: t2 (copy), v2 (copy)
	local v9 = t2.GetIndex(p2)

	if v9 == nil then
		return nil
	end

	return v2[v9 + 1.0]
end

return t2

