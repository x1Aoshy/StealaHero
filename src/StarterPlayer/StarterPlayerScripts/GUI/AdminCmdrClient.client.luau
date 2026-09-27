-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMfBFNob3cERW51bQdLZXlDb2RlAkYyEVNldEFjdGl2YXRpb25LZXlzA25ldwRDbWRyB3NldE5hbWUIc2V0SW1hZ2UIc2V0UmlnaHQHdG9nZ2xlZAdDb25uZWN0CkluaXRpYWxpemUEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQZDbGllbnQHTmV0d29yawdHbG9iYWxzCUNvbnN0YW50cwpDbWRyQ2xpZW50DFdhaXRGb3JDaGlsZAdNb2R1bGVzCFBhY2thZ2VzClRvcEJhclBsdXMLTkVUV09SS19NQVAKQWRtaW5QYW5lbAVGaXJlZBVBRE1JTl9TVEFUVVNfUkVTUE9OU0UABAIAAQAAAAX7AAAAvAAAmAAAAACfAAIBggABAAEDAQAgAAEYAAAAAAEhAAAAAAQAAwAAACOpAAEA3gAAAPsAAQD/AgAAAQAAAKQDAwACBADAxQIDAgEAAAC8AAAXBAAAAJ8AAwH7AAIATQAA7wUAAACfAAECbwMGALwBALoHAAAAnwEDAW8DCAC8AQC5CQAAAJ8BAwG8AQA1CgAAAJ8BAgFNAQBQCwAAAMADDAASAgEAvAEBxw0AAACfAQMBggABAA4DAgMDAwQEAgQAwAMFAwYDBwMIAgAHC7LuS9dCAwkDCgMLBgADDAEAFw0BGAAAAgAAAAAAAAAAAAIAAAABAAAAAQAAAAEAAAEAAAAAAAADGAAAAAACAQIAAAYDAAAFAQEGDgAEAPsBAAArAQIA+wEBAJ8BAQGCAAEAAAAnAAEYAAAAAQACKAAAAAALAAABAgBBowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgJNBwAAAE0CAlIIAAAAnwECAqQCBQAAAEBATQMAagYAAABNAwNLCQAAAE0DAwcKAAAAnwICAqQDBQAAAEBAbwYLALwEANMMAAAAnwQDAJ8DAAKkBAUAAABAQE0FAGoGAAAATQUF6A0AAABNBQXmDgAAAE0FBdUPAAAAnwQCAk0FArMQAAAATQUFsBEAAACpBgAA2QcAABIBBv8SAAMAEgAEAE0IAUsSAAAATQkFdxMAAACfCAIC2QoBABIBBv8SAAcAvAgIxxQAAACfCAMBwQYAAIIAAQAVAw4EAAAAQAMPAxADEQQAAEBAAxIDEwMUAxUDFgMXAxgDGQMaAxsDHAMdAx4DHwMMAgECAQABGAADAAAAAAAEAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAQAAAAAAAAAAAAAEAAAABAQAAAAQAAAAAAAAAAAAAAQAAQAAAAADi1z12ptzAoM0pfCM+bTX1vtE4q65mJ/b

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Library.Client.Network)
local Constants = require(ReplicatedStorage.Library.Globals.Constants)
local CmdrClient = require(ReplicatedStorage:WaitForChild("CmdrClient"))
local TopBarPlus = require(ReplicatedStorage.Library.Modules.Packages.TopBarPlus)
local AdminPanel = Constants.NETWORK_MAP.AdminPanel
local u7 = false

local function Initialize() -- line: 23
	-- upvalues: u7 (ref), CmdrClient (copy), TopBarPlus (copy)
	u7 = true
	CmdrClient:SetActivationKeys({ Enum.KeyCode.F2 })

	local v9 = TopBarPlus.new()

	v9:setName("Cmdr")
	v9:setImage(102459578526748.0)
	v9:setRight()
	v9.toggled:Connect(function() -- line: 32
		-- upvalues: CmdrClient (copy)
		CmdrClient:Show()
	end)
end

Network.Fired(AdminPanel.ADMIN_STATUS_RESPONSE):Connect(function(b1: boolean) -- line: 39
	-- upvalues: u7 (ref), Initialize (copy)
	if b1 and not u7 then
		Initialize()
	end
end)

