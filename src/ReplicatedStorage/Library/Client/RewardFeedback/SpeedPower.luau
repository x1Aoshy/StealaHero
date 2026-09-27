-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMXBm51bWJlciVFeHBlY3RlZCBwb3NpdGl2ZSBzcGVlZCByZXdhcmQgYW1vdW50BmFzc2VydARtYXRoBXJvdW5kCVNldEFtb3VudARQbGF5G3JieGFzc2V0aWQ6Ly85OTQ1ODY1MDQ0NjIyOAZCb3R0b20ESXRlbQRTaG93BGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHQXNzZXJ0cwZDbGllbnQOUmV3YXJkRmVlZGJhY2sISXRlbVJhaW4QTm90aWZpY2F0aW9uQ21kcwVJdGVtcw5TcGVlZFBvd2VySXRlbQACBQEEAAAGAwAABQECJ/sBAABNAQFgAAAAAFICAACfAQIBjAMAALcDAgAAAAAAqQIAAakCAQCBAQIEAQAAAG8DAQCkAQMAAAAgQJ8BAwH7AQEAnwEBArswAANSBAAApAMGAAAUQICfAwICvAEBdgcAAACfAQMC+wICAE0CAu4IAAAAbwMJAJ8CAgH7AgMATQICEwoAAADiAwwAMAEDygsAAACfAgIBggABAA0DAQMCAwMEAAAgQAMEAwUEABRAgAMGAwcDCAMJAwoFAQsAFgsBGAAAAAAAAQAAAAAAAAAAAAACAAAAAAAAAAAAAQAAAAACAAAAAQD/AxcAAAAABwAAAQIAN6MAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQICiQcAAACfAQICpAIFAAAAQEBNAwBqBgAAAE0DA00IAAAATQMD1AkAAABNAwNSCgAAAJ8CAgKkAwUAAABAQE0EAGoGAAAATQQETQgAAABNBARsCwAAAE0EBMoMAAAAnwMCAqQEBQAAAEBATQUAagYAAABNBQU4DQAAAE0FBacOAAAAnwQCAv8FAQAAAAAAwAYPABIAAQASAAQAEgACABIAAwAwBgWYEAAAAIIFAgARAwwEAAAAQAMNAw4DDwQAAEBAAxADEQMSAxMDFAMVAwoDFgMXBgADCwEAAQABGAADAAAAAAADAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAAAAAEAAAAAAAAAAAYABgAAAAAAAAwBAAAAAAH+KomkW3BzmH6lzp9NUsvmjjKe0Mzu46U=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local ItemRain = require(ReplicatedStorage.Library.Client.RewardFeedback.ItemRain)
local Item = require(ReplicatedStorage.Library.Client.NotificationCmds.Item)
local SpeedPowerItem = require(ReplicatedStorage.Library.Items.SpeedPowerItem)

return {
	Show = function(n1: number) -- line: 22
		-- upvalues: Asserts (copy), SpeedPowerItem (copy), ItemRain (copy), Item (copy)
		Asserts.number(n1)
		assert(n1 > 0.0, "Expected positive speed reward amount")

		local v7 = SpeedPowerItem():SetAmount((math.round(n1)))

		ItemRain.Play("rbxassetid://99458650446228")
		Item.Bottom({
			Item = v7
		})
	end
}

