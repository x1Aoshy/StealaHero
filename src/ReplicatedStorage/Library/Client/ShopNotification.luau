-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMZBlJhcml0eQVDb2xvcgNUb3AHTWVzc2FnZQRUaW1lBUltYWdlBnN0cmluZwZmb3JtYXQQJXMgaXMgaW4gdGhlICVzIQtEaXNwbGF5TmFtZQRJY29uCkNoZWNrU3RvY2sEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQZDbGllbnQQTm90aWZpY2F0aW9uQ21kcwlEaXJlY3RvcnkIUmFyaXRpZXMGQ29zbWljBlNlY3JldAdFdGVybmFsBkRpdmluZQACDgQDAAAJBgAABQQDAwQCL/sFAACHBAUAKwQEAP8EAAAAAAAA+wUAAGoEBQCHBQQBagMEAUcFAgAAAACAggABAIwGAABgBiAAAwAAAIwGAAB9BR0ABgAAAE0GAvIAAAAADgYZAPsIAQCHBwgGDgcWAE0HBqQBAAAA+wgCAE0ICJgCAAAA4gkHAKQKCgAAJICAbwsLAE0MAlcMAAAAUg0AAJ8KBAIwCgn4AwAAADAHCaQBAAAATQoCrg0AAAAwCgmpBgAAAJ8IAgGCAAEADgMBAwIDAwMEAwUCAAAAAAAAFEADBggEA/////8EBQAAAAH/////Bv////8DBwMIBAAkgIADCQMKAwsAGQwBGAAAAQEAAQADAQIAAQMAAAAAAAEAAQAAAAEAAQAAAAEAAAAAAAAAAAIAAQAAAPwIGgAAAAAHAAABAgA+owAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgJNBwAAAE0CAmwIAAAATQIC+AkAAACfAQICpAIFAAAAQEBNAwCRCgAAAE0DA/ILAAAAnwICAv8DAQAAAAAA/wQDAAAAAABNBQLoDAAAAE0FBQUNAAAAqQYBAGoGBAVNBQLoDAAAAE0FBWcOAAAAqQYBAGoGBAVNBQLoDAAAAE0FBSYPAAAAqQYBAGoGBAVNBQLoDAAAAE0FBccQAAAAqQYBAGoGBAX/BQAAAAAAAMAGEQASAAUAEgAEABIAAQAwBgMJEgAAAIIDAgATAw0EAAAAQAMOAw8DEAQAAEBAAxEDEgMTAwQDFAMBAxUDFgMXAxgDGQYAAwwBAAEAARgAAgAAAAAAAgAAAAAAAAAAAAABAAAAAAAAAgACAAEAAAAAAAEAAAAAAAEAAAAAAAEAAAAAAAMACAAAAAAAHAEAAAAAAezhEIdHjyKVSd9Eskx+kYSc+Qfz3iV6hg==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Message = require(ReplicatedStorage.Library.Client.NotificationCmds.Message)
local Rarity = require(ReplicatedStorage.Directory.Rarity)
local t1 = {}
local t2 = {
	[Rarity.Rarities.Cosmic] = true,
	[Rarity.Rarities.Secret] = true,
	[Rarity.Rarities.Eternal] = true,
	[Rarity.Rarities.Divine] = true
}
local t3 = {}

function t1.CheckStock(s1: string, s2: string, t4: {[any]: any}, n1: number) -- line: 25
	-- upvalues: t3 (copy), t2 (copy), Message (copy)
	local v11 = t3[s1]

	if not v11 then
		v11 = {}
		t3[s1] = v11
	end

	local v12 = v11[s2]

	v11[s2] = n1

	if v12 == nil then
		return
	end

	if n1 > 0.0 and v12 <= 0.0 then
		local Rarity2 = t4.Rarity

		if Rarity2 and t2[Rarity2] then
			local Rarity2Color = Rarity2.Color

			Message.Top({
				Time = 5.0,
				Message = string.format("%s is in the %s!", t4.DisplayName, s1),
				Color = Rarity2Color,
				Image = t4.Icon
			})
		end
	end
end

return t1

