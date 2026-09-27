-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQBXBjYWxsB3RyeVN3YXAFTW9kZWwDSXNBC1ByaW1hcnlQYXJ0C09iamVjdFZhbHVlBVZhbHVlBVBhcnQwBVBhcnQxB0Fkb3JuZWUFcGFpcnMNR2V0QXR0cmlidXRlcwxTZXRBdHRyaWJ1dGUEc3dhcAZpcGFpcnMOR2V0RGVzY2VuZGFudHMABQMABAAAAAv7AQAA+wIBAIcAAQL7AQIAmgAFAAEAAAD7AAAA+wEBAPsCAwBqAgABggABAAAAAgABGAAAAAAAAAEAAAACAwAAAAAGBAAAAAAJpAQBAAAAAEDZBQAAEgAAABIAAQASAAIAEgADAJ8EAgGCAAEAAgMBBAAAAEABAAECARgAAAAAAAAAAAUCAAAAAAwDAAAAAENvBQAAvAMA/gEAAACfAwMCDgMHAE0DAJsCAAAAmgMPAAEAAAAwAgCbAgAAAGUACwBvBQMAvAMA/gEAAACfAwMCDgMGAE0DAOwEAAAAmgMDAAEAAAAwAgDsBAAAAKQDBgAAAFBAbwUHANkEAAASAAAAEgAFABIAAQASAAIAnwMCAaQDBgAAAFBAbwUIANkEAAASAAAAEgAFABIAAQASAAIAnwMCAaQDBgAAAFBAbwUJANkEAAASAAAAEgAFABIAAQASAAIAnwMCAaQDCwAAAKBAvAQA3QwAAACfBAIAnwMABBcDBwCaBwYAAQAAAFIKBgBSCwIAvAgALg0AAACfCAQBbgP4/wIAAACCAAEADgMDAwQDBQMGAwcDAQQAAFBAAwgDCQMKAwsEAACgQAMMAw0BAAkOARgIAAAAAAEAAAABAAACAAAAAAAAAAABAPMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABIAAAAAAAABAAEAAAAA/gAFAgAAAAAMAwEAAAAU+wMAAFIEAABSBQEAUgYCAJ8DBAGkAwEAAAAAQLwEAEcCAAAAnwQCAJ8DAARRAwUA+wgAAFIJBwBSCgEAUgsCAJ8IBAFuA/r/AgAAgIIAAQADAw8EAAAAQAMQABsAARgAAAAAAAEAAAAAAAABAAAAAP8AAxwAAAAAAwAAAQIABqMAAADAAAAAwAEBAMACAgASAAEAggICAAMGAQYCBgMDAQIDAQABGAAACBIAAAEAAAAABNtBPttJjTjQTs/0gOAWSy2rWSmv6YVU2g==

-- decompilation:
local function trySwap(p1, p2, p3, p4) -- line: 1
	pcall(function() -- line: 2
		-- upvalues: p1 (copy), p2 (copy), p3 (copy), p4 (copy)
		if p1[p2] == p3 then
			p1[p2] = p4
		end
	end)
end
local function swap(p5, p6, p7) -- line: 9
	if p5:IsA("Model") then
		if p6 == p5.PrimaryPart then
			p5.PrimaryPart = p7
		end
	elseif p5:IsA("ObjectValue") and p6 == p5.Value then
		p5.Value = p7
	end

	local s1 = "Part0"

	pcall(function() -- line: 2
		-- upvalues: p5 (copy), s1 (copy), p6 (copy), p7 (copy)
		if p5[s1] == p6 then
			p5[s1] = p7
		end
	end)

	local s2 = "Part1"

	pcall(function() -- line: 2
		-- upvalues: p5 (copy), s2 (copy), p6 (copy), p7 (copy)
		if p5[s2] == p6 then
			p5[s2] = p7
		end
	end)

	local s3 = "Adornee"

	pcall(function() -- line: 2
		-- upvalues: p5 (copy), s3 (copy), p6 (copy), p7 (copy)
		if p5[s3] == p6 then
			p5[s3] = p7
		end
	end)

	for k, v in pairs(p5:GetAttributes()) do
		if v == p6 then
			p5:SetAttribute(k, p7)
		end
	end
end

return function(p8, p9, p10) -- line: 27
	-- upvalues: swap (copy)
	swap(p8, p9, p10)

	for _, descendant in ipairs(p8:GetDescendants()) do
		swap(descendant, p9, p10)
	end
end

