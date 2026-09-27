-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMGBHR5cGUFdGFibGUIaXNmcm96ZW4GZnJlZXplBG5leHQKRGVlcEZyZWV6ZQACCwIAAAATBAADBQIPhA8GHQsPBx0LBAIRHC27KAADUgMAAKQCAQAAAABAnwICAvACAgACAAAAggACAKQCBAAADCCAUgMAAJ8CAgIrAgQApAIGAAAUIIBSAwAAnwICAVICAQArAgIA/wIAAAAAAACHAwIAKwMVAKkDAQBqAwIApAMIAAAAcEBSBAAAxgUAABcDCgA1CADWCQAAAFIJBgBSCgIAnwgDATUIANYJAAAAUgkHAFIKAgCfCAMBbgP1/wIAAADGAwAAagMCAIIAAgAKAwEEAAAAQAMCAwMEAAwggAMEBAAUIIADBQQAAHBAAwYAIAYBGAAAAAAAAAABAgAAAAABAAAABAAAAAEAAQABAAAAAAEAAAAAAQAAAAD+AAQAAiEAAAAAAQAAAQMAB6MAAADAAAAAGAAA1gEAAAA1AADWAQAAAIIAAgACBgADBgEAAQABGAAfAAAVAAABAAAAAAGe6qfPPMYeOd5c7ygzc6Hk7vKwu6wuzc4=

-- decompilation:
--!native
function DeepFreeze(p1, t1: {[any]: any}?) -- line: 32
	if type(p1) ~= "table" then
		return p1
	end

	if not table.isfrozen(p1) then
		table.freeze(p1)
	end

	local v3 = t1 or {}

	if not v3[p1] then
		v3[p1] = true

		for k, v in next, p1 do
			DeepFreeze(k, v3)
			DeepFreeze(v, v3)
		end

		v3[p1] = nil
	end

	return p1
end

return DeepFreeze

