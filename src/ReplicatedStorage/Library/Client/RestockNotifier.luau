-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMeCkFybW9yc1Nob3AJU3dvcmRTaG9wB01lc3NhZ2UEVGltZQpTaG93U2hhZG93BVNvdW5kDERlbGF5SW5Sb3VuZAZzdHJpbmcGZm9ybWF0ZllvdXIgPGZvbnQgY29sb3I9IiMlcyI+UGlja2F4ZSBTaG9wPC9mb250PiBhbmQgPGZvbnQgY29sb3I9IiMlcyI+U3dvcmQgU2hvcDwvZm9udD4gaGF2ZSBiZWVuIHJlc3RvY2tlZAVUb0hleARtYXRoA21heBJnZXRDb21iaW5lZFJlc3RvY2sDVG9wBXRhYmxlBWNsZWFyDWZsdXNoUmVzdG9ja3MEdGFzawVkZWxheQRQdXNoBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkGQ2xpZW50EE5vdGlmaWNhdGlvbkNtZHMGQ29sb3IzB2Zyb21SR0IABAgAAwAAADv7AQAATQABtQAAAAD7AgAATQEC+gEAAAAOAAEAKwEBAIIAAQDiAgcApAMKAAAkgIBvBAsA+wUBALwFBR8MAAAAnwUCAvsGAgC8BgYfDAAAAJ8GAgCfAwACMAMC+AIAAABNBQBKAwAAAJAEBQ1NBgFKAwAAAJAFBg2eEgQDBQAAAKQDEAAAPOCAnwMDAjADAkoDAAAATQMAAgQAAAArAwIATQMBAgQAAAAwAwICBAAAAE0DAG4FAAAAKwMCAE0DAW4FAAAAMAMCbgUAAABNAwABBgAAACsDAgBNAwEBBgAAADADAgEGAAAAggICABEDAQMCAwMDBAMFAwYDBwUFAgMEBQYDCAMJBAAkgIADCgMLAgAAAAAAABRAAwwDDQQAPOCAABsOARgAAAABAAACAAEDAQABAQAAAAEAAAD9AAAFAAAAAAAAAAAAAAAAAQAAAAAAAAEAAAAAAAABAAAAAAAAABwAAAAACAAEAAAAG/sAAACfAAECDgAGAPsBAQBNAQGYAAAAAFICAACfAQIBZQALAPsBAgDGAgAAxgMAAGQBBQD7BgEATQYGmAAAAABSBwUAnwYCAW4B+v8CAAAApAEDAAAIEID7AgIAnwECAakBAADeAQMAggABAAQDDwMQAxEEAAgQgAAwEgEYAAACAQAAAAAAAgAAAAEAAAAA/wAFAAAAAQABMQAAAAAFAgMAAAcEAAAFAgMPDfsCAABqAQIA+wIBAA4CAQCCAAEAqQIBAN4CAQCkAgIAAAQAgIwDAwD7BAIAnwIDAYIAAQADAxMDFAQABACAAD8VARgAAAIAAQMAAQAAAAABQAAAAAAKAAABAgA0owAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgJNBwAAAE0CAmwIAAAATQIC+AkAAACfAQICpAIMAAAsoICMA+4AjAT/AIwFAACfAgQCpAMMAAAsoICMBP8AjAWRAIwGAACfAwQC/wQAAAAAAACpBQAA/wYBAAAAAADABw0AEgAEABIAAgASAAMA2QgBABIABwASAAEAEgAEABIBBf/ZCQIAEgAEABIBBf8SAAgAMAkGGQ4AAADBBQAAggYCAA8DFgQAAABAAxcDGAMZBAAAQEADGgMbAxwDAwMdAx4EACyggAYAAxUDAAECAQABGAADAAAAAAADAAAAAAAAAAAAAAkAAAAAAAEAAAAAAAMAAQMAAwAAABUAAAAADwAAAAAACwABAAAAAAN2Y+qwq5CpUY7/MIFKs8MVBnv9xESngLE=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Message = require(ReplicatedStorage.Library.Client.NotificationCmds.Message)
local color3 = Color3.fromRGB(238.0, 255.0, 0.0)
local color3_2 = Color3.fromRGB(255.0, 145.0, 0.0)
local t1 = {}
local u6 = false
local t2 = {}

local function getCombinedRestock() -- line: 27
	-- upvalues: t1 (copy), color3 (copy), color3_2 (copy)
	local ArmorsShop = t1.ArmorsShop
	local SwordShop = t1.SwordShop

	if not ArmorsShop or not SwordShop then
		return
	end

	return {
		Message = string.format("Your <font color=\"#%s\">Pickaxe Shop</font> and <font color=\"#%s\">Sword Shop</font> have been restocked", color3:ToHex(), color3_2:ToHex()),
		Time = math.max(ArmorsShop.Time or 5.0, SwordShop.Time or 5.0),
		ShowShadow = ArmorsShop.ShowShadow or SwordShop.ShowShadow,
		Sound = ArmorsShop.Sound or SwordShop.Sound,
		DelayInRound = ArmorsShop.DelayInRound or SwordShop.DelayInRound
	}
end
local function flushRestocks() -- line: 48
	-- upvalues: getCombinedRestock (copy), Message (copy), t1 (copy), u6 (ref)
	local v12 = getCombinedRestock()

	if v12 then
		Message.Top(v12)
	else
		for _, v14 in t1 do
			Message.Top(v14)
		end
	end

	table.clear(t1)
	u6 = false
end

function t2.Push(s1: string, p1) -- line: 63
	-- upvalues: t1 (copy), u6 (ref), flushRestocks (copy)
	t1[s1] = p1

	if u6 then
		return
	end

	u6 = true
	task.delay(3.0, flushRestocks)
end

return t2

