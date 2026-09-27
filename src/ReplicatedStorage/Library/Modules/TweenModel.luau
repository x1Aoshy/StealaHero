-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local TweenService = game:GetService("TweenService")
local t1 = {}

return function(p1, p2, p3) -- line: 5
	-- upvalues: t1 (copy), TweenService (copy)
	local v6 = t1[p1]

	if v6 then
		v6:Cancel()
		v6:Destroy()
		task.cancel(v6.Thread)
		t1[p1] = nil
		print("Cancel last Loop!", p1)
	end

	local NumberValue = Instance.new("NumberValue")

	NumberValue.Value = p1:GetScale()

	local CFrameValue = Instance.new("CFrameValue")

	CFrameValue.Value = p1:GetPivot()

	local tween = TweenService:Create(NumberValue, p2, {
		Value = p3.Scale
	})
	local tween2 = TweenService:Create(CFrameValue, p2, {
		Value = p3.CFrame
	})
	local t2 = nil

	t2 = {
		Instance = p1,
		Play = function() -- line: 26
			-- upvalues: tween (copy), tween2 (copy), t2 (ref), p3 (copy), p1 (copy), NumberValue (copy), CFrameValue (copy)
			tween:Play()
			tween2:Play()
			task.spawn(function() -- line: 29
				-- upvalues: t2 (ref), tween (copy), p3 (copy), p1 (copy), NumberValue (copy), CFrameValue (copy)
				while true do
					task.wait(0.01)
					t2.PlaybackState = tween.PlaybackState

					if tween.PlaybackState ~= Enum.PlaybackState.Playing then
						break
					end

					if p3.Scale then
						p1:ScaleTo((math.clamp(NumberValue.Value, 1E-09, 1e999)))
					end

					if p3.CFrame then
						p1:PivotTo(CFrameValue.Value)
					end
				end
			end)
		end,
		Pause = function() -- line: 46
			-- upvalues: tween (copy), tween2 (copy)
			tween:Pause()
			tween2:Pause()
		end,
		Destroy = function() -- line: 50
			-- upvalues: tween (copy), tween2 (copy)
			tween:Destroy()
			tween2:Destroy()
		end,
		Cancel = function() -- line: 54
			-- upvalues: tween (copy), tween2 (copy)
			tween:Cancel()
			tween2:Cancel()
		end,
		PlaybackState = Enum.PlaybackState.Begin,
		TweenInfo = p2,
		Completed = tween.Completed,
		Thread = task.delay(180.0, function() -- line: 61
			-- upvalues: t1 (copy), p1 (copy)
			t1[p1] = nil
		end)
	}
	t1[p1] = t2

	return t2
end

