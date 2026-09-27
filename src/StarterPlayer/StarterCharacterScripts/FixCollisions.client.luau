-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQCEJhc2VQYXJ0A0lzQQV0YWJsZQRmaW5kBE5hbWUKQ2FuQ29sbGlkZRFwcm9jZXNzRGVzY2VuZGFudAZpcGFpcnMOR2V0RGVzY2VuZGFudHMRZGlzYWJsZUNvbGxpc2lvbnMKVXBwZXJUb3JzbwpMb3dlclRvcnNvBHRhc2sEd2FpdAZzY3JpcHQGUGFyZW50AAMEAQEAAAYDAAAFAQcQbwMAALwBAP4BAAAAnwEDAg4BCgCkAQQAAAwggPsCAABNAwC6BQAAAJ8BAwIOAQMAqQEAADABANMGAAAAggABAAcDAQMCAwMDBAQADCCAAwUDBgAKBwEYAAAAAAAAAAAAAAAAAQAAAgsAAAAACQEBAAAGAwAABQEHGaQBAQAAAABAvAIARwIAAACfAgIAnwEABFEBDwBvCAMAvAYF/gQAAACfBgMCDgYKAKQGBwAAGFCA+wcAAE0IBboIAAAAnwYDAg4GAwCpBgAAMAYF0wkAAABuAfD/AgAAgIIAAQAKAwgEAAAAQAMJAwEDAgMDAwQEABhQgAMFAwYAEAoBGAYAAAAAAAD6AAAAAAAAAAAAAAABAAAFAAMLAAAAAAwAAAEAAC6jAAAA/wAAAAIAAABvAQAAbwIBAMUAAQMBAAAAwAECABIAAADAAgMAEgAAAKQDBgAAFECAbwQHAJ8DAgIOAx0ApAMJAAAAgEBNAwMkCgAAAKQEDAAAALBAvAUDRw0AAACfBQIAnwQABFEEDwBvCw4AvAkI/g8AAACfCQMCDgkKAKQJEgAARACBUgoAAE0LCLoTAAAAnwkDAg4JAwCpCQAAMAkI0xQAAABuBPD/AgAAgEgA3v+CAAEAFQMLAwwGAAYBAw0DDgQAFECAApqZmZmZmdk/Aw8EAACAQAMQAwgEAACwQAMJAwEDAgMDAwQEAEQAgQMFAwYCAAEBAAEYAAMAAQEAAAQABgAGAAAAAAEAAAD6AAAAAAAA+gAAAAAAAAAAAAAAAQAABQAFAwEAAAAAAjgu1zQQzhVwpFu/1QleNIJINsBACuq9NQ==

-- decompilation:
local t1 = {
	"UpperTorso",
	"LowerTorso"
}

local function processDescendant(p1) -- line: 10
	-- upvalues: t1 (copy)
	if p1:IsA("BasePart") and table.find(t1, p1.Name) then
		p1.CanCollide = false
	end
end
local function disableCollisions(p2) -- line: 16
	-- upvalues: t1 (copy)
	for _, descendant in ipairs(p2:GetDescendants()) do
		if descendant:IsA("BasePart") and table.find(t1, descendant.Name) then
			descendant.CanCollide = false
		end
	end
end

while task.wait(0.4) do
	local scriptParent = script.Parent

	for _, descendant in ipairs(scriptParent:GetDescendants()) do
		if descendant:IsA("BasePart") and table.find(t1, descendant.Name) then
			descendant.CanCollide = false
		end
	end
end

