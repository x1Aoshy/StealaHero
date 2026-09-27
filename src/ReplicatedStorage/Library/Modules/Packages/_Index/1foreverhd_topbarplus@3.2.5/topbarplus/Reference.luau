-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPCm9iamVjdE5hbWUORmluZEZpcnN0Q2hpbGQISW5zdGFuY2UDbmV3C09iamVjdFZhbHVlBE5hbWUGc2NyaXB0BlBhcmVudAVWYWx1ZRZhZGRUb1JlcGxpY2F0ZWRTdG9yYWdlCWdldE9iamVjdARnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UTVG9wYmFyUGx1c1JlZmVyZW5jZQADAwACAAAAHfsAAAD7AgEATQIC5AAAAAC8AAADAQAAAJ8AAwIOAAIAqQEAAIIBAgCkAQQAAAwggG8CBQCfAQIC+wIBAE0CAuQAAAAAMAIBugYAAACkAggAAABwQE0CAiQJAAAAMAIB7AoAAAD7AgAAMAIBJAkAAACCAQIACwMBAwIDAwMEBAAMIIADBQMGAwcEAABwQAMIAwkACgoBGAAAAAAAAAABAQACAAAAAQAAAAABAAAAAAABAAABCwAAAAADAAIAAAAL+wAAAPsCAQBNAgLkAAAAALwAAAMBAAAAnwADAg4AAQCCAAIAqQEAAIIBAgACAwEDAgAWCwEYAAAAAAAAAAEBAgAXAAAAAAMAAAECABejAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMC/wEDAAAAAABvAgQAMAIB5AUAAADAAgYAEgAAABIAAQAwAgF7BwAAAMACCAASAAAAEgABADACARkJAAAAggECAAoDDAQAAABAAw0DDgMPAwEGAAMKBgEDCwIAAQEAARgABQAAAAAAAQABAAACAAAAAAwAAAAACAEAAAAAAiZLSFkjeLtj2E5Dv3loZHRWU18tFI8iWA==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t1 = {
	objectName = "TopbarPlusReference"
}

function t1.addToReplicatedStorage() -- line: 10
	-- upvalues: ReplicatedStorage (copy), t1 (copy)
	if ReplicatedStorage:FindFirstChild(t1.objectName) then
		return false
	end

	local ObjectValue = Instance.new("ObjectValue")

	ObjectValue.Name = t1.objectName
	ObjectValue.Value = script.Parent
	ObjectValue.Parent = ReplicatedStorage

	return ObjectValue
end
function t1.getObject() -- line: 22
	-- upvalues: ReplicatedStorage (copy), t1 (copy)
	local t1objectName = ReplicatedStorage:FindFirstChild(t1.objectName)

	if t1objectName then
		return t1objectName
	end

	return false
end

return t1

