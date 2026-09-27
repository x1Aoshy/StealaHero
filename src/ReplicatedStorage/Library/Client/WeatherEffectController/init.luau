-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
require(script.Types)

local t1 = {
	Effects = {},
	ActiveEffects = {}
}

function t1.Activate(_, p2) -- line: 8
	-- upvalues: t1 (copy)
	local v4 = t1.Effects[p2]

	if not v4 then
		return false
	end

	if type(v4.Activate) == "function" then
		v4:Activate()
	end

	return true
end
function t1.Run(_, p4, p5) -- line: 19
	-- upvalues: t1 (copy)
	local v8 = t1.Effects[p5]

	if not v8 then
		return false
	end

	if not t1.ActiveEffects[p5] then
		t1.ActiveEffects[p5] = {}
	end

	local v9 = table.clone(t1.ActiveEffects[p5])

	t1.ActiveEffects[p5][p4] = true

	if next(v9) then
		return false
	end

	if type(v8.OnStart) == "function" then
		v8:OnStart()
	end

	return true
end
function t1.Stop(_, p7, p8) -- line: 38
	-- upvalues: t1 (copy)
	local v13 = t1.Effects[p8]

	if not v13 then
		return false
	end

	if not t1.ActiveEffects[p8] then
		return false
	end

	if not next(t1.ActiveEffects[p8]) then
		return false
	end

	t1.ActiveEffects[p8][p7] = nil

	if next(t1.ActiveEffects[p8]) then
		return false
	end

	t1.ActiveEffects[p8] = nil

	if type(v13.OnStop) == "function" then
		v13:OnStop()
	end

	return true
end
function t1.Load() -- line: 60
	-- upvalues: t1 (copy)
	for _, child in script.Effects:GetChildren() do
		if not child:IsA("ModuleScript") then
			continue
		end

		local ok, result = coroutine.resume(coroutine.create(require), child)

		if ok and type(result) == "table" then
			if type(result.OnLoad) == "function" then
				local ok2, result2 = coroutine.resume(coroutine.create(result.OnLoad), result)

				if not ok2 then
					warn(("Effect %s failed to call Load function:\n%s"):format(child:GetFullName(), if result2 ~= nil then result2 else "yielded (possibly)"))

					continue
				end
			end

			t1.Effects[child.Name] = result

			continue
		end

		warn(("Effect %s failed to load:\n%s"):format(child:GetFullName(), if result ~= nil then result else "yielded (possibly)"))
	end
end
function t1.Start() -- line: 90
end

return t1

