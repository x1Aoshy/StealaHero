-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMNFHBhdGhTdHJpbmdGb3JTb3J0aW5nA25ldwV0YWJsZQRzb3J0BmlwYWlycwRwYXRoBm1ldGhvZAdhZGRSb290CmNyZWF0ZVBsYW4HcmVxdWlyZQZzY3JpcHQGUGFyZW50CFRlc3RQbGFuAAMFAgAAAAAJTQMAdwAAAABNBAF3AAAAALcDAgAEAAAAqQIAAakCAQCCAgIAAQMBAB0AARgAAAAAAAAAAAAeAAAAAA0DAQAAABr7AwAATQMD7wAAAABSBAEAUgUCAJ8DAwKkBAMAAAgQgFIFAADABgQAnwQDAaQEBgAAAFBAUgUAAJ8EAgRRBAcATQsIYQcAAABNDAjyCAAAALwJA2wJAAAAnwkEAW4E+P8CAACAggMCAAoDAgMDAwQEAAgQgAYAAwUEAABQQAMGAwcDCAEAGgkBGAAAAAAAAAIAAAAABAAAAAABAAAAAAAA/wAEGwAAAAADAAABAgARowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BAfsFAAAAnwACAv8BAQAAAAAAwAIGABIAAAAwAgEQBwAAAIIBAgAIAwoEAAAAQAMLBAAAIEADDAMNBgEDCQEBAQABGAAFAAAAAAAAAAACABIAAAAOAQAAAAAC4KsapBWA1CD5KWCXafROEJCzDdDSb3Cl

-- decompilation:
local TestPlan = require(script.Parent.TestPlan)

return {
	createPlan = function(p1, p2, p3) -- line: 26
		-- upvalues: TestPlan (copy)
		local v5 = TestPlan.new(p2, p3)

		table.sort(p1, function(p4, p5) -- line: 29
			return p4.pathStringForSorting < p5.pathStringForSorting
		end)

		for _, v in ipairs(p1) do
			v5:addRoot(v.path, v.method)
		end

		return v5
	end
}

