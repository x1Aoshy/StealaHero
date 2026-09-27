-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMbCEluc3RhbmNlBkNvbG9yMwZudW1iZXIOU3BlZWRQZXJTZWNvbmQIQmFzZVBhcnQDSXNBMFRyZWFkbWlsbCAiJSoiIFNwZWVkUGVyU2Vjb25kIG11c3QgYmUgYSBCYXNlUGFydAROYW1lBmZvcm1hdAZhc3NlcnQMQmlsbGJvYXJkR3VpQVRyZWFkbWlsbCAiJSoiIFNwZWVkUGVyU2Vjb25kLkJpbGxib2FyZEd1aSBtdXN0IGJlIGEgQmlsbGJvYXJkR3VpBUZyYW1lCVRleHRMYWJlbE5UcmVhZG1pbGwgIiUqIiBTcGVlZFBlclNlY29uZC5CaWxsYm9hcmRHdWkuRnJhbWUuVGV4dExhYmVsIG11c3QgYmUgYSBUZXh0TGFiZWwKVGV4dENvbG9yMwgrJSovc3RlcARUZXh0BUFwcGx5BGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHQXNzZXJ0cwlGdW5jdGlvbnMGQ29tbWFzAQIAAgsDAgAACAUAAAUDB0ACUPsDAABNAwP0AAAAAFIEAACfAwIB+wMAAE0DA5oBAAAAUgQBAJ8DAgH7AwAATQMDYAIAAABSBAIAnwMCAU0DADUDAAAAbwcEALwFA/4FAAAAnwUDAm8GBgBNCAC6BwAAALwGBo0IAAAAnwYDAp4BBQMGAAAApAQKAAAAkECfBAMBTQQDZwsAAABvCAsAvAYE/gUAAACfBgMCbwcMAE0JALoHAAAAvAcHjQgAAACfBwMCngEGAwcAAACkBQoAAACQQJ8FAwFNBQSdDQAAAE0FBZoOAAAAbwkOALwHBf4FAAAAnwcDAm8IDwBNCgC6BwAAALwICI0IAAAAnwgDAp4BBwMIAAAApAYKAAAAkECfBgMBMAEFcxAAAABvBhEA+wgBAFIJAgCfCAICvAYGjQgAAACfBgMCMAYF9RIAAACCBAIAEwMBAwIDAwMEAwUDBgMHAwgDCQMKBAAAkEADCwMMAw0DDgMPAxADEQMSAB4TARgAAAAAAAEAAAAAAQAAAAACAAEAAAAAAAAAAAAAAAAAAAIAAgAAAAEAAAAAAAAA/gAABAAAAAIAAAABAAAAAAAAAP4AAAQAAQAAAAAAAAAAAR8AAAAABQAAAQIAH6MAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQICiQcAAACfAQICpAIFAAAAQEBNAwBqBgAAAE0DA1MIAAAATQMDzgkAAACfAgIC/wMBAAAAAADABAoAEgABABIAAgAwBAMvCwAAAIIDAgAMAxQEAAAAQAMVAxYDFwQAAEBAAxgDGQMaAxsGAAMTAQABAAEYAAMAAAAAAAMAAAAAAAABAAAAAAAAAAAQAAYAAAAAFwEAAAAAAexxrRsaNf22hyzjzlNCjx6cabpv3rXHGg==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local Commas = require(ReplicatedStorage.Library.Functions.Commas)

return {
	Apply = function(p1, color3: Color3, n1: number) -- line: 30
		-- upvalues: Asserts (copy), Commas (copy)
		Asserts.Instance(p1)
		Asserts.Color3(color3)
		Asserts.number(n1)

		local SpeedPerSecond = p1.SpeedPerSecond

		assert(SpeedPerSecond:IsA("BasePart"), `Treadmill "{ p1.Name }" SpeedPerSecond must be a BasePart`)

		local BillboardGui = SpeedPerSecond.BillboardGui

		assert(BillboardGui:IsA("BillboardGui"), `Treadmill "{ p1.Name }" SpeedPerSecond.BillboardGui must be a BillboardGui`)

		local TextLabel = BillboardGui.Frame.TextLabel

		assert(TextLabel:IsA("TextLabel"), `Treadmill "{ p1.Name }" SpeedPerSecond.BillboardGui.Frame.TextLabel must be a TextLabel`)
		TextLabel.TextColor3 = color3
		TextLabel.Text = `+{ Commas(n1) }/step`

		return BillboardGui
	end
}

