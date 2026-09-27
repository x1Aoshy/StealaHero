-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local _require = require
local ReplicatedStorage = game:GetService("ReplicatedStorage")

_require(script:WaitForChild("Signal"))

local HitboxClassRemote = ReplicatedStorage:WaitForChild("HitboxClassRemote")
local v4 = _require(script["HitboxClass Module"].Value)
local t1 = {}

HitboxClassRemote.OnClientEvent:Connect(function(p1, p2) -- line: 11
	-- upvalues: t1 (copy), v4 (copy), HitboxClassRemote (copy)
	if p1 == "Clr" then
		for k, v in pairs(t1) do
			v:Destroy()
			t1[k] = nil
		end

		return
	end

	if p1 ~= "New" and not t1[p2._Tick] then
		warn("No hitbox found on the client for tick value sent. Don't change the tick value manually, change the ID instead. (HitboxClass)")

		return
	end

	if p1 == "New" then
		local v10 = v4.new(p2)

		t1[p2._Tick] = v10
		HitboxClassRemote:FireServer(p2._Tick)
	end

	if p1 == "Start" then
		t1[p2._Tick]:Start()
	end

	if p1 == "Stop" then
		t1[p2._Tick]:Stop()
	end

	if p1 == "ClrTag" then
		t1[p2._Tick]:ClearTaggedChars()
	end

	if p1 == "Weld" then
		t1[p2._Tick]:WeldTo(p2.WeldTo, p2.Offset)
	end

	if p1 == "WeldOfs" then
		t1[p2._Tick]:ChangeWeldOffset(p2.Offset)
	end

	if p1 == "Unweld" then
		t1[p2._Tick]:Unweld()
	end

	if p1 == "PosCh" then
		t1[p2._Tick]:SetPosition(p2.Position)
	end

	if p1 == "Dbg" then
		t1[p2._Tick]:SetDebug(p2.Debug)
	end

	if p1 == "Des" then
		t1[p2._Tick]:Destroy()
		t1[p2._Tick] = nil
	end
end)

