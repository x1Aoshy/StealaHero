-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local t1 = {
	DebugLogging = false,
	VisualizeCasts = false
}

t1.__index = t1
t1.__type = "FastCast"
t1.HighFidelityBehavior = {
	Default = 1.0,
	Always = 3.0
}

local ActiveCast = require(script.ActiveCast)
local Signal = require(script.Signal)

require(script.Table)
require(script.TypeDefinitions)
ActiveCast.SetStaticFastCastReference(t1)

function t1.new() -- line: 108
	-- upvalues: Signal (copy), t1 (copy)
	return (setmetatable({
		LengthChanged = Signal.new("LengthChanged"),
		RayHit = Signal.new("RayHit"),
		RayPierced = Signal.new("RayPierced"),
		CastTerminating = Signal.new("CastTerminating"),
		WorldRoot = workspace
	}, t1))
end
function t1.newBehavior() -- line: 120
	-- upvalues: t1 (copy)
	return {
		RaycastParams = nil,
		MaxDistance = 1000.0,
		CanPierceFunction = nil,
		HighFidelitySegmentSize = 0.5,
		CosmeticBulletTemplate = nil,
		CosmeticBulletProvider = nil,
		CosmeticBulletContainer = nil,
		AutoIgnoreContainer = true,
		Acceleration = Vector3.new(),
		HighFidelityBehavior = t1.HighFidelityBehavior.Default
	}
end

local v4 = t1.newBehavior()

function t1.Fire(t2: {[any]: any}, vector3: Vector3, vector3_2: Vector3, p1, p2) -- line: 137
	-- upvalues: v4 (copy), ActiveCast (copy)
	if p2 == nil then
		p2 = v4
	end

	local v10 = ActiveCast.new(t2, vector3, vector3_2, p1, p2)

	v10.RayInfo.WorldRoot = t2.WorldRoot

	return v10
end

return t1

