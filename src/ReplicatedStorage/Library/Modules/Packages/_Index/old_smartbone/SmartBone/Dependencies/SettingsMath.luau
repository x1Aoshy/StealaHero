-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPBG1hdGgFY2xhbXAFQ2xhbXAFZmxvb3IFRmxvb3IGT2Zmc2V0B0RhbXBpbmcLQW5jaG9yRGVwdGgJU3RpZmZuZXNzB0luZXJ0aWEKRWxhc3RpY2l0eQtCbGVuZFdlaWdodApVcGRhdGVSYXRlDFdpbmRTdHJlbmd0aAdHcmF2aXR5AAYFAQIAAAAJ+wMAAPsEAQA0LgAEAwQAAFICAACkAQIAAAQAgJ8BBAKCAQIAAwMBAwIEAAQAgAACAAEYAAAAAAAAAAAAAwAAAAADAgAAAAAE2QIAABIAAAASAAEAggICAAABAAEDARgAAAAAAgAAAAADAQAAAAAGuwwAA1ICAACkAQIAAAQAgJ8BAgKCAQIAAwMBAwQEAAQAgAAHBQEYAAAAAAAACAAAAAADAQEAAAAD+wIAAEMBAAKCAQIAAAAMAAEYAAAADQAAAAACAQAAAAAD2QEAABIAAACCAQIAAAEDCwYBGAAAAAwAAAAABwAAAQIAPqMAAADAAAAAwAEBAMACAgDiAwwAjAUAAIwGAQDZBAMAEgAFABIABgAwBANgAwAAADABA0sEAAAAjAUAAIwGAQDZBAMAEgAFABIABgAwBAP8BQAAAIwFAACMBgEA2QQDABIABQASAAYAMAQDgAYAAACMBQAAjAYBANkEAwASAAUAEgAGADAEAxgHAAAAjAUAAIwGAQDZBAMAEgAFABIABgAwBAOeCAAAAIwFAACMBqUA2QQDABIABQASAAYAMAQDdgkAAACMBQAAjAYKANkEAwASAAUAEgAGADAEA7oKAAAAbwUNANkEBAASAAUAMAQDJQsAAACCAwIADgYBBgIGBAMHAwgDCQMKAwsDDAMNAw4DDwUJAwQFBgcICQoLBwAAAAAK1yO8AAAAAAAAAAAFAQIEAAMBAAEYAAAGBAbxAAAAABAAAQDvAAAAABIA7gAAAAATAO0AAAAAFADsAAAAABUA6wAAAAAWAOoAAAAAFwDzAAAPAAABAAAAAAXobAgMeEbrSevF8EpPMWhTmHQfeNqoYg0=

-- decompilation:
local function Clamp(p1, p2) -- line: 1
	return function(p3) -- line: 2
		-- upvalues: p1 (copy), p2 (copy)
		return (math.clamp(p3, p1, p2))
	end
end
local function Floor(p4) -- line: 7
	return (math.floor(p4))
end
local function Offset(p5) -- line: 11
	return function(p6) -- line: 12
		-- upvalues: p5 (copy)
		return p6 + p5
	end
end

local t1 = {}
local n1 = 0.0
local n2 = 1.0

function t1.Damping(p7) -- line: 2
	-- upvalues: n1 (copy), n2 (copy)
	return (math.clamp(p7, n1, n2))
end

t1.AnchorDepth = Floor

local n3 = 0.0
local n4 = 1.0

function t1.Stiffness(p8) -- line: 2
	-- upvalues: n3 (copy), n4 (copy)
	return (math.clamp(p8, n3, n4))
end

local n5 = 0.0
local n6 = 1.0

function t1.Inertia(p9) -- line: 2
	-- upvalues: n5 (copy), n6 (copy)
	return (math.clamp(p9, n5, n6))
end

local n7 = 0.0
local n8 = 1.0

function t1.Elasticity(p10) -- line: 2
	-- upvalues: n7 (copy), n8 (copy)
	return (math.clamp(p10, n7, n8))
end

local n9 = 0.0
local n10 = 1.0

function t1.BlendWeight(p11) -- line: 2
	-- upvalues: n9 (copy), n10 (copy)
	return (math.clamp(p11, n9, n10))
end

local n11 = 0.0
local n12 = 165.0

function t1.UpdateRate(p12) -- line: 2
	-- upvalues: n11 (copy), n12 (copy)
	return (math.clamp(p12, n11, n12))
end

local n13 = 0.0
local n14 = 10.0

function t1.WindStrength(p13) -- line: 2
	-- upvalues: n13 (copy), n14 (copy)
	return (math.clamp(p13, n13, n14))
end

local vector3 = Vector3.new(0.0, -0.009999999776482582, 0.0)

function t1.Gravity(p14) -- line: 12
	-- upvalues: vector3 (copy)
	return p14 + vector3
end

return t1

