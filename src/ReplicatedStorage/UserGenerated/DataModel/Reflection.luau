-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
--!native
local ReflectionService = game:GetService("ReflectionService")
local t1 = {}
local t2 = {}
local t3 = {
	Parent = true,
	ClassName = true,
	Name = true,
	ExtentsCFrame = true,
	ExtentsSize = true,
	ResizeIncrement = true,
	ResizeableFaces = true,
	CurrentPhysicalProperties = true,
	Sandboxed = true,
	Capabilities = true,
	PrivateServerId = true,
	PrivateServerOwnerId = true,
	SerializedDefaultAttributes = true
}
local t4 = {
	Debug = true
}
local ok, result = pcall(function() -- line: 44
	return tostring(SecurityCapabilities.fromCurrent()):split(" | ")
end)
local u8 = if not ok then {} else result

local function canRead(p1) -- line: 50
	-- upvalues: u8 (ref)
	if not p1 then
		return true
	end

	local parts = tostring(p1):split(" | ")

	if parts[1.0] == nil or parts[1.0] == "" then
		return true
	end

	for _, v13 in parts do
		if not table.find(u8, v13) then
			return false
		end
	end

	return true
end

function t1.getReadProperties(s1: string) -- line: 66
	-- upvalues: t2 (copy), ReflectionService (copy), t3 (copy), t4 (copy), canRead (copy)
	local v15 = t2[s1]

	if v15 then
		return v15
	end

	local t5 = {}
	local ok2, result2 = pcall(function() -- line: 73
		-- upvalues: ReflectionService (copy), s1 (copy)
		return ReflectionService:GetPropertiesOfClass(s1)
	end)

	if ok2 and result2 then
		for _, v20 in result2 do
			local Name = v20.Name

			if not t3[Name] then
				local Display = v20.Display

				if not Display or (not Display.DeprecationMessage or Display.DeprecationMessage == "") and (not Display.Category or not t4[Display.Category]) then
					local Type = v20.Type

					if not Type or Type.ScriptType ~= "Instance" then
						local Permits = v20.Permits

						if canRead(Permits and Permits.Read) then
							table.insert(t5, Name)
						end
					end
				end
			end
		end
	end

	t2[s1] = t5

	return t5
end

return t1

