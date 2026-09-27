-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Network = require(ReplicatedStorage.Library.Client.Network)
local CoreCall = require(ReplicatedStorage.Library.Functions.CoreCall)
local t1 = {}
local LocalPlayer = Players.LocalPlayer
local Friend_Notification = LocalPlayer.PlayerGui:WaitForChild("Friend_Notification", 3)
if not Friend_Notification then
	return t1
end
local BodyLabel = Friend_Notification.Frame.Frame.Background.Holder.BodyLabel
local Accept = Friend_Notification.Frame.Frame.Background.Holder.Frame.Accept
local Decline = Friend_Notification.Frame.Frame.Background.Holder.Frame.Decline
local t2 = {}
local u12 = nil

function t1.DismissCurrent() -- line: 23
	-- upvalues: u12 (ref), t2 (copy), BodyLabel (copy), Friend_Notification (copy)
	if not u12 then
		return
	end

	local v13 = table.find(t2, u12)

	if v13 then
		table.remove(t2, v13)
	end

	u12 = nil

	if #t2 > 0.0 then
		if not u12 then
			local v14 = t2[1.0]

			u12 = v14
			BodyLabel.Text = `Friend request from\n{ v14.Name }`
			Friend_Notification.Show_VAL.Value = true

			return
		end

		return
	end

	Friend_Notification.Show_VAL.Value = false
end
function t1.AcceptCurrent() -- line: 45
	-- upvalues: u12 (ref), t1 (copy), CoreCall (copy)
	local v15 = u12

	t1.DismissCurrent()

	if v15 then
		CoreCall("SetCore", "PromptSendFriendRequest", v15)
	end
end

Network.Fired(Network.NET_MAP.Gifting.FRIEND_REQUEST):Connect(function(p1) -- line: 53
	-- upvalues: LocalPlayer (copy), t2 (copy), u12 (ref), BodyLabel (copy), Friend_Notification (copy)
	if p1:IsFriendsWith(LocalPlayer.UserId) then
		return
	end

	if not table.find(t2, p1) then
		table.insert(t2, p1)
	end

	if not u12 then
		local v17 = t2[1.0]

		u12 = v17
		BodyLabel.Text = `Friend request from\n{ v17.Name }`
		Friend_Notification.Show_VAL.Value = true
	end
end)
Accept.MouseButton1Click:Connect(t1.AcceptCurrent)
Decline.MouseButton1Click:Connect(t1.DismissCurrent)

return t1

