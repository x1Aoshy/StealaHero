-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMGBHV0ZjgGb2Zmc2V0AAZzdHJpbmcDc3ViB1VURjhTdWIAAgsDAAAAHAUABQUDAwKCDwcVDg8DACwCBAErDwUCKgIGEBwskAMCAMYEAACkBQMAAAgQgFIGAABSBwEAnwUDAisFBwCMBgAAYAYDAAEAAABvBgQAggYCAIwEAQBlAAEAUgQFAMYGAAANAwMAAAAAgBwGAABlAA4ApAcDAAAIEIBSCAAAlQkDBZ8HAwIOBwIAeAYHBWUABgCMCAAAYAMDAAgAAACMBgAAZQABABwGAAA0LQAGBAYAAFIIAABSCQQAUgoGAKQHCAAAHGCAnwcEAoIHAgAJAgAAAAAAAPC/AwEDAgQACBCAAwMCAAAAAAAA8D8DBAMFBAAcYIAAFAYBGAADAQAAAAABAgAAAgADAAMEAQACAAIAAAAAAQEAAwAAAgADBQAAAAAAAAAAFQAAAAABAAABAwcAAAEPAAECA6MAAADAAAAAggACAAEGAAEAAQABGAATKwEAAAAAAYfwL3Ztx+2dkOiWBj6Rlyf36DgCtTRFdw==

-- decompilation:
--!native
local function UTF8Sub(s1: string, n1: number, n2: number?) -- line: 20
	local v5 = n2 or -1.0
	local v6 = utf8.offset(s1, n1)

	if not v6 then
		if n1 > 0.0 then
			return ""
		end

		v6 = 1.0
	end

	local v7

	if v5 == -1.0 then
		v7 = #s1
	else
		local v8 = utf8.offset(s1, v5 + 1.0)

		v7 = if not v8 then if not (v5 < 0.0) then #s1 else 0.0 else v8 - 1.0
	end

	return (string.sub(s1, v6, v7))
end

return UTF8Sub

