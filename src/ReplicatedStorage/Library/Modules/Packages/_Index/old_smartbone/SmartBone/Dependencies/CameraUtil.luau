-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRCXdvcmtzcGFjZQ1DdXJyZW50Q2FtZXJhBU1vZGVsA0lzQQ5HZXRCb3VuZGluZ0JveAhCYXNlUGFydAZDRnJhbWUEU2l6ZQR3YXJuRE9iamVjdCBpcyBuZWl0aGVyIGEgTW9kZWwgbm9yIGEgQmFzZVBhcnQhIERpc3JlZ2FyZGluZyBDYW1lcmEgY2hlY2shA25ldwFYAVkBWghQb3NpdGlvbhRXb3JsZFRvVmlld3BvcnRQb2ludA5XaXRoaW5WaWV3cG9ydAACEAEAAAAGAwAABQEHUaQBAQAAAABATQEBSAIAAADGAgAAxgMAAG8GAwC8BAD+BAAAAJ8EAwIOBAYAvAQAlQUAAACfBAIDUgIEAFIDBQBlABAAbwYGALwEAP4EAAAAnwQDAg4EBQBNAgCFBwAAAE0DAC8IAAAAZQAGAKQECgAAAJBAbwULAJ8EAgGpBAAAggQCAIwGAQCMBAgAjAUBAKgEKgCkCA0AADBwgE0KA3kOAAAAIQwGDw0MAwAQAACAbwsRAGUAAQBvCxIACQkKC00LA3gTAAAAIQ0GFIwOAQBgDgMADQAAAG8MEQBlAAEAbwwSAAkKCwxNDAN7FQAAACEOBhaMDwMAYA8DAA4AAABvDREAZQABAG8NEgAJCwwNnwgEAgkHAghNCgc7FwAAALwIAfgYAAAAnwgDAg4IAgCpCAEAgggCAIsE1v+pBAAAggQCABkDAQQAAABAAwIDAwMEAwUDBgMHAwgDCQQAAJBAAwoDCwQAMHCAAwwCAAAAAAAAAEACAAAAAAAAAAACAAAAAAAA4D8CAAAAAAAA4L8DDQIAAAAAAAAQQAMOAgAAAAAAACBAAw8DEAADEQEYAAAAAAEAAgAAAAABAAAAAAABAAAAAAEAAAAAAgAAAAEAAwAAAAIAAQAAAAAAAAAAAQAAAAAAAAAAAAEAAAAAAAAAAAD9AAYAAAAAAAEA9w0ABAAAAAACAAABAgAHowAAAP8AAQAAAAAAwAEAADABAM8BAAAAggACAAIGAAMRAQABAAEYAAAAAgAAHQEAAAAAAc8PK9ThbIXysSUn8P7OTUa/Fzyg/ctB1Q==

-- decompilation:
return {
	WithinViewport = function(p1) -- line: 3
		local CurrentCamera = workspace.CurrentCamera
		local BoundingBox, v4

		if p1:IsA("Model") then
			BoundingBox, v4 = p1:GetBoundingBox()
		else
			if not p1:IsA("BasePart") then
				warn("Object is neither a Model nor a BasePart! Disregarding Camera check!")

				return false
			end

			BoundingBox = p1.CFrame
			v4 = p1.Size
		end

		for i = 1.0, 8.0 do
			if CurrentCamera:WorldToViewportPoint((BoundingBox * CFrame.new(v4.X * (i % 2.0 ~= 0.0 and -0.5 or 0.5), v4.Y * (not (i % 4.0 > 1.0) and -0.5 or 0.5), v4.Z * (not (i % 8.0 > 3.0) and -0.5 or 0.5))).Position) then
				return true
			end
		end

		return false
	end
}

