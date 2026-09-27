-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLB0Rlc3Ryb3kISW5zdGFuY2UDbmV3CkF0dGFjaG1lbnQGQ0ZyYW1lDVRvT2JqZWN0U3BhY2UGUGFyZW50BUVuZGVkB0Nvbm5lY3QEUGxheQdQbGF5U0ZYAQUAAwIAAQAABAABAA8F+wAAALwAAFAAAAAAnwACAYIAAQABAwEAGQABGAAAAAABGgAAAAAHAwAAAAwFAAEFAwdABw8DABsbpAMCAAAEAIBvBAMAnwMCAk0EAIUEAAAAUgYBALwEBEYFAAAAnwQDAjAEA4UEAAAAMAMCJAYAAAAwAAMkBgAAAE0EAjcHAAAA2QYAABIAAwC8BATHCAAAAJ8EAwG8BALuCQAAAJ8EAgGCAAEACgMCAwMEAAQAgAMEAwUDBgMHAwgDCQMKAQAUCwEYAAAAAAEAAAAAAAAAAQABAAEAAAAAAAADAAABFQAAAAABAAABAwcAAAEPAAECA6MAAADAAAAAggACAAEGAQEBAQABGAATCwEAAAAAAoX0mZWfNx1GwPv4GSu87OT17I7htzDzlA==

-- decompilation:
--!native
local function PlaySFX(p1, cFrame: CFrame, p2) -- line: 20
	local Attachment = Instance.new("Attachment")

	Attachment.CFrame = p1.CFrame:ToObjectSpace(cFrame)
	p2.Parent = Attachment
	Attachment.Parent = p1
	p2.Ended:Connect(function() -- line: 25
		-- upvalues: Attachment (copy)
		Attachment:Destroy()
	end)
	p2:Play()
end

return PlaySFX

