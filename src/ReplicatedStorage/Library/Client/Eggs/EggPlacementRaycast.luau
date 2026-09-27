-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaFEFwcGVuZFJheWNhc3RUYXJnZXRzDVJheWNhc3RQYXJhbXMDbmV3BEVudW0RUmF5Y2FzdEZpbHRlclR5cGUHSW5jbHVkZQpGaWx0ZXJUeXBlGkZpbHRlckRlc2NlbmRhbnRzSW5zdGFuY2VzC0lnbm9yZVdhdGVyFnBsYWNlbWVudFJheWNhc3RQYXJhbXMIQmFzZVBhcnQGbnVtYmVyB1JheWNhc3QEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQdBc3NlcnRzB01vZHVsZXMIUGFja2FnZXMFSW5wdXQGc2NyaXB0BlBhcmVudBFQbGFjZWRFZ2dSZW5kZXJlcgVNb3VzZQADBgIBAAAHBAAABQIHAhj/AgAAAQAAAFIDAADFAgMCAQAAAPsDAABNAwPDAAAAAFIEAgBSBQEAnwMDAaQDAwAACBCAnwMBAqQEBwAGFEDAMAQDVwgAAAAwAgN9CQAAAKkEAQAwBANjCgAAAIIDAgALAwEDAgMDBAAIEIADBAMFAwYEBhRAwAMHAwgDCQAYCgEYAAAAAAABAAAAAAACAAABAAAAAQABAAABGQAAAAAHAgMAAAcEAAAFAgcCFPsCAABNAgJjAAAAAFIDAACfAgIB+wIAAE0CAmABAAAAUgMBAJ8CAgH7AgEA+wQCAFIFAABSBgEAnwQDAowF9AG8AgLCAgAAAJ8CBACCAgAAAwMLAwwDDQAnDQEYAAAAAAABAAAAAAIAAAAAAAAAAAAoAAAAAAgAAAECADKjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAokHAAAAnwECAqQCBQAAAEBATQMAagYAAABNAwPoCAAAAE0DA+YJAAAATQMD3AoAAACfAgICpAMFAAAAQECkBAwAAACwQE0EBCQNAAAATQQEBQ4AAACfAwICTQQCnQ8AAABNBATvEAAAAJ8EAQL/BQEAAAAAAMAGEQASAAMAwAcSABIAAQASAAQAEgAGADAHBcITAAAAggUCABQDDgQAAABAAw8DEAMRBAAAQEADEgMTAxQDFQMWAxcEAACwQAMYAxkDGgMDBgAGAQMNAgABAQABGAADAAAAAAADAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAAGAAAAAAMABgAPAAAAAAAHAQAAAAACRynIt21SQCNyVocBB9zrajcx38N17aK2

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local Input = require(ReplicatedStorage.Library.Modules.Packages.Input)
local PlacedEggRenderer = require(script.Parent.PlacedEggRenderer)
local v5 = Input.Mouse.new()
local t1 = {}

local function placementRaycastParams(p1, n1: number) -- line: 24
	-- upvalues: PlacedEggRenderer (copy)
	local t2 = { p1 }

	PlacedEggRenderer.AppendRaycastTargets(t2, n1)

	local raycastParams = RaycastParams.new()

	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = t2
	raycastParams.IgnoreWater = true

	return raycastParams
end

function t1.Raycast(p2, n2: number) -- line: 39
	-- upvalues: Asserts (copy), v5 (copy), placementRaycastParams (copy)
	Asserts.BasePart(p2)
	Asserts.number(n2)

	return v5:Raycast(placementRaycastParams(p2, n2), 500.0)
end

return t1

