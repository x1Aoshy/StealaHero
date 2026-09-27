-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local Players = game:GetService("Players")
local t1 = {}
local u3 = false

local function create(p1, p2) -- line: 5
	-- upvalues: t1 (copy)
	local v9 = p2:lower()

	if v9 ~= "mouse1down" and (v9 ~= "mouse1up" and v9 ~= "mouse1click" and v9 ~= "mouse2down" and v9 ~= "mouse2up" and v9 ~= "mouse2click") then
		error("Functions.Clicked - \"" .. v9 .. "\" is an invalid event type. Check spelling!")
	end

	local v10 = t1[p1]

	if not v10 then
		v10 = {}
		t1[p1] = v10
	end

	local v11 = v10[v9]

	if v11 then
		return v11
	end

	local BindableEvent = Instance.new("BindableEvent")

	v10[v9] = BindableEvent

	return BindableEvent
end
local function fire(p3) -- line: 31
	-- upvalues: Players (copy), t1 (copy)
	local v14 = p3:lower()
	local Target = Players.LocalPlayer:GetMouse().Target
	local v16 = Target.ClassName == "Folder" or Target.ClassName == "Model"

	if Target and Target.Parent then
		for k, v in pairs(t1) do
			if (v16 and ((k.ClassName == "Folder" or k.ClassName == "Model") and Target:IsDescendantOf(k)) or Target == k) and v[v14] then
				v[v14]:Fire()

				return
			end
		end
	end
end
local function init() -- line: 53
	-- upvalues: u3 (ref), Players (copy), fire (copy)
	u3 = true

	local Mouse = Players.LocalPlayer:GetMouse()

	Mouse.Button1Down:Connect(function() -- line: 56
		-- upvalues: fire (copy), Mouse (copy)
		fire("mouse1down")
		Mouse.Button1Up:Wait()
		fire("mouse1click")
	end)
	Mouse.Button1Up:Connect(function() -- line: 61
		-- upvalues: fire (copy)
		fire("mouse1up")
	end)
	Mouse.Button2Down:Connect(function() -- line: 64
		-- upvalues: fire (copy), Mouse (copy)
		fire("mouse2down")
		Mouse.Button2Up:Wait()
		fire("mouse2click")
	end)
	Mouse.Button2Up:Connect(function() -- line: 69
		-- upvalues: fire (copy)
		fire("mouse2up")
	end)
end

return function(p4, p5) -- line: 74
	-- upvalues: u3 (ref), init (copy), create (copy)
	if not u3 then
		init()
	end

	return (create(p4, p5 or "mouse1click"))
end

