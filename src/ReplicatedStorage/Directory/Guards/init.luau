-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleLoader = require(ReplicatedStorage.ModuleLoader)
local Constants = require(ReplicatedStorage.Library.Globals.Constants)
local MakeTableStrict = require(ReplicatedStorage.Library.Functions.MakeTableStrict)
local Interface = require(script.Types.Interface)
local t1 = {
	typeCast = "GuardsDir",
	rootName = "Guards.Dir",
	noPrint = true,
	shouldInject = true,
	forceSafeLoad = Constants.IS_CLIENT
}
local t2 = {}
local v8 = ModuleLoader(script._Index, {}, t1)
local n1 = 1e999
local n2 = 0.0

for _, v in pairs(v8) do
	n1 = math.min(n1, v.WalkSpeed)
	n2 = math.max(n2, v.WalkSpeed)
end

t2.Directory = v8
t2.Types = Interface

if Constants.IS_STUDIO then
	for _, child in pairs(script._Index:GetChildren()) do
		assert(child:IsA("ModuleScript"), `Bad instance found inside the guard configs env: { child.Name }`)

		local v15 = v8[child.Name]
		local v16, v17 = Interface.DefaultConfig(v15)

		assert(v16, `Failed to validate guard config { child.Name }: { v17 }`)
	end
end

MakeTableStrict(v8, "Guards")

function t2.Types.GuardNameExists(s1: string) -- line: 54
	-- upvalues: v8 (copy)
	if pcall(function() -- line: 55
		-- upvalues: v8 (copy), s1 (copy)
		return v8[s1]
	end) then
		return true
	end

	return false, `Guard name "{ s1 }" does not exist in the Guards directory.`
end
function t2.GetLowestWalkSpeed() -- line: 66
	-- upvalues: n1 (ref)
	if n1 == 1e999 then
		return 0.0
	end

	return n1
end
function t2.GetHighestWalkSpeed() -- line: 74
	-- upvalues: n2 (ref), n1 (ref)
	return (math.max(n2, (math.max(n1, 1.0))))
end

return t2

