-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRBGdhbWUKU3RhcnRlckd1aQpHZXRTZXJ2aWNlDEdVSUZYIEhvbGRlcglTY3JlZW5HdWkPU2hpZnRMb2NrQnV0dG9uBHRhc2sEd2FpdAtHZXRDaGlsZHJlbgV0YWJsZQRmaW5kBE5hbWUDSXNBDFJlc2V0T25TcGF3bgVlcnJvcgtTY3JlZW5HdWkgJzEnIGhhcyBSZXNldE9uU3Bhd24gZW5hYmxlZCwgd2hpY2ggaXMgbm90IGFsbG93ZWQuAAEMAAABAAAwowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAv8BAAADAAAAbwIEAG8DBQBvBAYAxQECBAEAAACkAgkAACBwgIwDAwCfAgIBvAIAaAoAAACfAgIEZAIXAKQHDQAAMLCAUggBAE0JBroOAAAAnwcDAisHEABvCQUAvAcG/g8AAACfBwMCDgcLAE0HBqQQAAAADgcIAKQHEgAAABBBbwkTAE0KBroOAAAAbwsUAHMICQufBwIBbgLo/wIAAACCAAEAFQMBBAAAAEADAgMDAwQDBQMGAwcDCAQAIHCAAwkDCgMLBAAwsIADDAMNAw4DDwQAABBBAxADEQABAAEYAAQAAAAAAAMAAQEBAAAHAAAAAgAAAAEAAAAAAAAAAAAAAAAAAAEAAAAAAAAA/gATAQAAAAAAOamyqHR7AIyT0IW6ZWyprEmxpdwLbdip

-- decompilation:
local StarterGui = game:GetService("StarterGui")

task.wait(3.0)

for _, child in StarterGui:GetChildren() do
	if not table.find({
		"GUIFX Holder",
		"ScreenGui",
		"ShiftLockButton"
	}, child.Name) and child:IsA("ScreenGui") and child.ResetOnSpawn then
		error("ScreenGui '" .. child.Name .. "' has ResetOnSpawn enabled, which is not allowed.")
	end
end

