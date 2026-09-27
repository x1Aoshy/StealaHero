-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRElNjcm9sbGluZ0RpcmVjdGlvbgRFbnVtAVgMVUlMaXN0TGF5b3V0FUZpbmRGaXJzdENoaWxkT2ZDbGFzcxNBYnNvbHV0ZUNvbnRlbnRTaXplDFVJR3JpZExheW91dAlVSVBhZGRpbmcLUGFkZGluZ0xlZnQGT2Zmc2V0DFBhZGRpbmdSaWdodAVVRGltMgNuZXcKQ2FudmFzU2l6ZQFZDVBhZGRpbmdCb3R0b20KUGFkZGluZ1RvcAACCgEAAAAAYk0BAEsAAAAApAIDAAIAEMCaAS8AAgAAAIwBAABvBAQAvAIAuAUAAACfAgMCDgIFAE0DAsYGAAAATQMDeQIAAABDAQEDbwUHALwDALgFAAAAnwMDAg4DBQBNBAPGBgAAAE0EBHkCAAAAQwEBBG8GCAC8BAC4BQAAAJ8EAwIOBAoATQYEvgkAAABNBgZwCgAAAE0HBL4LAAAATQcHcAoAAABDBQYHQwEBBaQFDgAANMCAjAYAAFIHAQCMCAAAjAkAAJ8FBQIwBQDPDwAAAIIAAQCMAQAAbwQEALwCALgFAAAAnwIDAg4CBQBNAwLGBgAAAE0DA3gQAAAAQwEBA28FBwC8AwC4BQAAAJ8DAwIOAwUATQQDxgYAAABNBAR4EAAAAEMBAQRvBggAvAQAuAUAAACfBAMCDgQKAE0GBOwRAAAATQYGcAoAAABNBwQxEgAAAE0HB3AKAAAAQwUGB0MBAQWkBQ4AADTAgIwGAACMBwAAjAgAAFIJAQCfBQUCMAUAzw8AAACCAAEAEwMBAwIDAwQCABDAAwQDBQMGAwcDCAMJAwoDCwMMAw0EADTAgAMOAw8DEAMRAAEAARgAAAAAAAABAQAAAAEBAAAAAAIAAAABAQAAAAACAAAAAQEAAAAAAAAAAAACAAAAAAAAAAAAAgEAAAABAQAAAAACAAAAAQEAAAAAAgAAAAEBAAAAAAAAAAAAAgAAAAAAAAAAAgIAAAAAAQAAAQIAA6MAAADAAAAAggACAAEGAAEAAQABGAAAAAEAAAAAAe4dhWLhm1f5tEyZbM35kEqeBZIW3NnvYw==

-- decompilation:
return function(p1) -- line: 1
	if p1.ScrollingDirection == Enum.ScrollingDirection.X then
		local n1 = 0.0
		local UIListLayout = p1:FindFirstChildOfClass("UIListLayout")

		if UIListLayout then
			n1 += UIListLayout.AbsoluteContentSize.X
		end

		local UIGridLayout = p1:FindFirstChildOfClass("UIGridLayout")

		if UIGridLayout then
			n1 += UIGridLayout.AbsoluteContentSize.X
		end

		local UIPadding = p1:FindFirstChildOfClass("UIPadding")

		if UIPadding then
			n1 += UIPadding.PaddingLeft.Offset + UIPadding.PaddingRight.Offset
		end

		p1.CanvasSize = UDim2.new(0.0, n1, 0.0, 0.0)

		return
	end

	local n2 = 0.0
	local UIListLayout = p1:FindFirstChildOfClass("UIListLayout")

	if UIListLayout then
		n2 += UIListLayout.AbsoluteContentSize.Y
	end

	local UIGridLayout = p1:FindFirstChildOfClass("UIGridLayout")

	if UIGridLayout then
		n2 += UIGridLayout.AbsoluteContentSize.Y
	end

	local UIPadding = p1:FindFirstChildOfClass("UIPadding")

	if UIPadding then
		n2 += UIPadding.PaddingBottom.Offset + UIPadding.PaddingTop.Offset
	end

	p1.CanvasSize = UDim2.new(0.0, 0.0, 0.0, n2)
end

