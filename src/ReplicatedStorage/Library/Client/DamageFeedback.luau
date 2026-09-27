-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMhDFByZWxvYWRBc3luYxFJbWFnZVRyYW5zcGFyZW5jeQR0YXNrBXNwYXduB0F0RGVidWcnRGFtYWdlIGZlZWRiYWNrIGltYWdlIHByZWxvYWQgcmVxdWVzdGVkA0xvZwdQcmVsb2FkBkNhbmNlbARQbGF5BnNjcmlwdAZDcmVhdGUEZ2FtZQ9Db250ZW50UHJvdmlkZXIKR2V0U2VydmljZRFSZXBsaWNhdGVkU3RvcmFnZQxUd2VlblNlcnZpY2UHcmVxdWlyZQdMaWJyYXJ5BUF1ZGlvBkNsaWVudANHVUkHTW9kdWxlcwhQYWNrYWdlcwlUd2VlbkluZm8DbmV3BEVudW0LRWFzaW5nU3R5bGUEUXVhZA9FYXNpbmdEaXJlY3Rpb24DT3V0BkRhbWFnZQpJbWFnZUxhYmVsAAQEAAIAAAAK+wAAAP8CAAABAAAA+wMBAMUCAwIBAAAAvAAATwAAAACfAAMBggABAAEDAQAgAAEYAAAAAAAAAAAAASEAAAAAAwADAAAAE/sAAACMAQEAMAEAowAAAACkAAMAAAgQgMABBAASAgEAEgIAAJ8AAgH7AAIAvAAAHAUAAACfAAICbwIGALwAAKEHAAAAnwADAYIAAQAIAwIDAwMEBAAIEIAGAAMFAwYDBwEAHggBGAAAAAABAAAAAAADAAAAAAAAAAEfAAAAAAYABQAAAB77AAAADgADALwBAKEAAAAAnwECAfsBAQCMAgAAMAIBowEAAAD7AQIATQEB7gIAAABvAgMApAMFAAAAQECMBAEAbwUGAJ8BBQH7AQMA+wMBAPsEBADiBQgAvAEBlgkAAACfAQUC3gEAALwCAe4CAAAAnwICAYIAAQAKAwkDAgMKAkCQcA+atd9CAwsEAABAQAIAAAAAAADgPwIAAAAAAADwPwgBAQcAAAADDAAmCgEYAAEBAAADAAAAAQAAAAAAAAAAAgAAAAAAAAMBAAABJwAAAAAMAAABAgBRowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBAQAAAABAbwMEALwBARYDAAAAnwEDAqQCAQAAAABAbwQFALwCAhYDAAAAnwIDAqQDBwAAAGBATQQBaggAAABNBATSCQAAAJ8DAgKkBAcAAABgQE0FAWoIAAAATQUFTQoAAABNBQU5CwAAAJ8EAgKkBQcAAABgQE0GAWoIAAAATQYG6AwAAABNBgbmDQAAAE0GBqEOAAAAnwUCAqQGEQAAQPCAbwcSAKQIFgAVUDDBpAkZABhcMMGfBgQCTQcF7xAAAACfBwECTQgEDxoAAACfCAECTQgILxsAAADGCQAA/woCAAAAAADACxwAEgAIABIAAAASAAcAMAsKSB0AAADZCwEAEgEJ/xIACAASAAMAEgACABIABgAwCwruHgAAAMEJAACCCgIAHwMNBAAAAEADDgMPAxADEQMSBAAAYEADEwMUAxUDFgMXAxgDBwMZAxoEAEDwgAKamZmZmZnZPwMbAxwDHQQVUDDBAx4DHwQYXDDBAyADIQYBAwgDCgIBAgEAARgAAwAAAAAAAQAAAAAAAQAAAAAAAwAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAAAAwAAAAAAAAAFAAABAAAAAAEDAAYAAAAAAAgAAAAAAAAAEAABAAAAAANSiKKqwuWOEg01axkWs9YdIpC13mBMyKs=

-- decompilation:
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Audio = require(ReplicatedStorage.Library.Audio)
local GUI = require(ReplicatedStorage.Library.Client.GUI)
local Log = require(ReplicatedStorage.Library.Modules.Packages.Log)
local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local v8 = Log.new()
local ImageLabel = GUI.Damage().ImageLabel
local u10 = nil

return {
	Preload = function() -- line: 30
		-- upvalues: ImageLabel (copy), ContentProvider (copy), v8 (copy)
		ImageLabel.ImageTransparency = 1.0
		task.spawn(function() -- line: 32
			-- upvalues: ContentProvider (copy), ImageLabel (copy)
			ContentProvider:PreloadAsync({ ImageLabel })
		end)
		v8:AtDebug():Log("Damage feedback image preload requested")
	end,
	Play = function() -- line: 38
		-- upvalues: u10 (ref), ImageLabel (copy), Audio (copy), TweenService (copy), tweenInfo (copy)
		local v11 = u10

		if v11 then
			v11:Cancel()
		end

		ImageLabel.ImageTransparency = 0.0
		Audio.Play(139459336979009.0, script, 1.0, 0.5)

		local tween = TweenService:Create(ImageLabel, tweenInfo, {
			ImageTransparency = 1.0
		})

		u10 = tween
		tween:Play()
	end
}

