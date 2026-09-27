-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMHEkFic29sdXRlV2luZG93U2l6ZQFZEEFic29sdXRlUG9zaXRpb24MQWJzb2x1dGVTaXplDkNhbnZhc1Bvc2l0aW9uBG1hdGgDbWluAAILAgAAAAAkTQIAxQAAAABNAgJ4AQAAAE0DAXUCAAAATQMDeAEAAABNBAFxAwAAAE0EBHgBAAAATQUAlQQAAABNBQV4AQAAAIwGAABgAwIABgAAAIIFAgA+BwQFQwYDB30GAgACAAAAggUCAEMHAwQmBgcCnhMDBQYAAABSCQMAUgoGAKQICAAAHGCAnwgDAkMHCAWCBwIACQMBAwIDAwMEAwUCAAAAAAAAAEADBgMHBAAcYIAAAQABGAAAAAABAAAAAQAAAAEAAAABAAABAgAAAAECAAEAAAAAAAAAAAIAAAAAAQAAAQIAA6MAAADAAAAAggACAAEGAAEAAQABGAAAAAEAAAAAAccqEt3346a9FQlcXEV9S8C3MgWp9e543A==

-- decompilation:
return function(p1, p2) -- line: 1
	local AbsoluteWindowSizeY = p1.AbsoluteWindowSize.Y
	local AbsolutePositionY = p2.AbsolutePosition.Y
	local AbsoluteSizeY = p2.AbsoluteSize.Y
	local CanvasPositionY = p1.CanvasPosition.Y

	if AbsolutePositionY < 0.0 then
		return CanvasPositionY
	end

	if AbsoluteWindowSizeY >= AbsolutePositionY + AbsoluteSizeY / 2.0 then
		return CanvasPositionY
	end

	return math.min(AbsolutePositionY, AbsolutePositionY + AbsoluteSizeY - AbsoluteWindowSizeY) + CanvasPositionY
end

