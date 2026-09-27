-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMYDHNldG1ldGF0YWJsZQVDZWl2ZQlQcm9wZXJ0eXMHUmVxdWVzdAdSZWxlYXNlBlJldGFpbgRJbml0B0VuYWJsZWQGQ2lyY2xlBERyYXcGQ0ZyYW1lBkFuZ2xlcwlUcmFuc2Zvcm0GUmFkaXVzDFN1YmRpdmlzaW9ucwVBbmdsZQtBbHdheXNPblRvcAxUcmFuc3BhcmVuY3kGQ29sb3IzB0Rlc3Ryb3kGQ3JlYXRlDFB1c2hQcm9wZXJ0eQZVcGRhdGUHX19pbmRleAELAAUIBQEAAAAT/wYEAAAAAAD7BwAAnj0GAwcAAACkBQEAAAAAQJ8FAwIwAAU3AgAAADABBeoDAAAAMAIFTAQAAAAwAwVcBQAAADAEBY8GAAAAggUCAAcDAQQAAABAAwIDAwMEAwUDBgAGBwEYAAAAAAAAAAACAAEAAQABAAEAAgcAAAAADQUAAAAKBwAABQUEQAICAi5NBQA3AAAAAE0GBfABAAAAKwYBAIIAAQBNBgVwAgAAAFIIAQBSCQIAUgoDAFILBAC8BgbUAwAAAJ8GBgFNBgVwAgAAAKQJBgAAFECAjAoAAG8LBwCMDAAAnwkEAgkIAQlSCQIAUgoDAFILBAC8BgbUAwAAAJ8GBgFNBgVwAgAAAKQJBgAAFECAbwoHAIwLAACMDAAAnwkEAgkIAQlSCQIAUgoDAFILBAC8BgbUAwAAAJ8GBgGCAAEACAMCAwgDCQMKAwsDDAQAFECAAhgtRFT7Ifk/ABIKARgAAAIAAAEDAAAAAAAAAAABAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAABEwAAAAAJBQAAAAoHAAAFBQRAAgICIeIFCwAwAQUhAAAAADACBXEBAAAAMAMFmQIAAAAwBAUtAwAAAE0GAOoMAAAATQYGjgQAAAAwBgWOBAAAAE0GAOoMAAAATQYG2QUAAAAwBgXZBQAAAE0GAOoMAAAATQYGmgYAAAAwBgWaBgAAAE0GAI8NAAAAUgcAAFIIBQCfBgMBggUCAA4DDQMOAw8DEAMRAxIDEwMIAQEDFAEACAkA/////wH/////Av////8D/////wT/////Bf////8G/////wcIAAAACQoAAAADAwMGAB4VARgAAQABAAEAAQABAAAAAAABAAAAAAABAAAAAAAFAAAAAAIfAAAAAAkCAAAAACBNAgA3AAAAAE0DAjMBAAAAbwQCAE0FAY4CAAAAnwMDAU0DAjMBAAAAbwQDAE0FAdkDAAAAnwMDAU0DAjMBAAAAbwQEAE0FAZoEAAAAnwMDAU0FASEFAAAATQYBcQYAAABNBwGZBwAAAE0IAS0IAAAAvAMA1AkAAACfAwYBggABAAoDAgMWAxEDEgMTAw0DDgMPAxADCgAwFwEYAAACAAAAAAABAAAAAAABAAAAAAACAAAAAAAAAAAAAAExAAAAAAIAAAECABOjAAAA/wAEAAAAAAAwAABuAAAAAMABAQASAAAAMAEAcwIAAADAAQMAMAEA1AQAAADAAQUAMAEAlgYAAADAAQcAMAEAJggAAACCAAIACQMYBgADBwYBAwoGAgMVBgMDFwQAAQIDAQABGAACAAEAAgAAAAwAAAwAABIAAAoBAAAAAASETcb/b1REhcQC/kGOWJCR9FXRi7aJrP4=

-- decompilation:
local t1 = {}

t1.__index = t1

function t1.Init(p1, p2, p3, p4, p5) -- line: 6
	-- upvalues: t1 (copy)
	local self = setmetatable({}, t1)

	self.Ceive = p1
	self.Propertys = p2
	self.Request = p3
	self.Release = p4
	self.Retain = p5

	return self
end
function t1.Draw(t2: {[any]: any}, cFrame: CFrame, n1: number, n2: number, n3: number) -- line: 18
	local Ceive = t2.Ceive

	if not Ceive.Enabled then
		return
	end

	Ceive.Circle:Draw(cFrame, n1, n2, n3)
	Ceive.Circle:Draw(cFrame * CFrame.Angles(0.0, 1.5707963267948966, 0.0), n1, n2, n3)
	Ceive.Circle:Draw(cFrame * CFrame.Angles(1.5707963267948966, 0.0, 0.0), n1, n2, n3)
end
function t1.Create(t3: {[any]: any}, cFrame: CFrame, n4: number, n5: number, n6: number) -- line: 30
	local t4 = {
		Enabled = true,
		Destroy = false,
		Transform = cFrame,
		Radius = n4,
		Subdivisions = n5,
		Angle = n6,
		AlwaysOnTop = t3.Propertys.AlwaysOnTop,
		Transparency = t3.Propertys.Transparency,
		Color3 = t3.Propertys.Color3
	}

	t3:Retain(t4)

	return t4
end
function t1.Update(p6, p7) -- line: 48
	local Ceive = p6.Ceive

	Ceive.PushProperty("AlwaysOnTop", p7.AlwaysOnTop)
	Ceive.PushProperty("Transparency", p7.Transparency)
	Ceive.PushProperty("Color3", p7.Color3)
	p6:Draw(p7.Transform, p7.Radius, p7.Subdivisions, p7.Angle)
end

return t1

