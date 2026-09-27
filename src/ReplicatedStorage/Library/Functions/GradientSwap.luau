-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMGC0dldENoaWxkcmVuClVJR3JhZGllbnQDSXNBB0Rlc3Ryb3kFQ2xvbmUGUGFyZW50AAIKAgAAAAcEAAAFAgeHGLwCAGgAAAAAnwICBGQCCABvCQEAvAcG/gIAAACfBwMCDgcDALwHBlADAAAAnwcCAW4C9/8CAAAARwEDAAAAAIDGAgAAggICALwCAToEAAAAnwICAjAAAiQFAAAAggICAAYDAQMCAwMDBAMFAwYAAQABGAAAAAABAAAAAAEAAP4ABQABAAIAAAEAAQIAAAAAAQAAAQIAA6MAAADAAAAAggACAAEGAAEAAQABGAAAAAEAAAAAAQ==

-- decompilation:
return function(p1, p2) -- line: 1
	for _, child in p1:GetChildren() do
		if child:IsA("UIGradient") then
			child:Destroy()
		end
	end

	if p2 == nil then
		return nil
	end

	local clone = p2:Clone()

	clone.Parent = p1

	return clone
end

