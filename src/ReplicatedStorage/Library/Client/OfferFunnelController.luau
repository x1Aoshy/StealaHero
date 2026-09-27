-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local Network = require(ReplicatedStorage.Library.Client.Network)
local Constants = require(ReplicatedStorage.Library.Globals.Constants)

require(ReplicatedStorage.Library.Types.OfferFunnel)

local wcall = require(ReplicatedStorage.Library.Functions.wcall)
local Analytics = Constants.NETWORK_MAP.Analytics
local t1 = {}
local t2 = {}

local function fireStep(p1, p2, s1: string) -- line: 31
	-- upvalues: Asserts (copy), Network (copy), Analytics (copy)
	Asserts.string(p1)
	Asserts.string(p2)
	Asserts.string(s1)
	assert(s1 ~= "", "SessionKey cannot be empty")

	local t3 = {
		OfferName = p1,
		StepName = p2,
		SessionKey = s1
	}

	Network.Fire(Analytics.OFFER_FUNNEL_STEP, t3)
end

function t2.TrackImpression(p3, s2: string) -- line: 49
	-- upvalues: t1 (copy), wcall (copy), fireStep (copy)
	if s2 == t1[p3] then
		return
	end

	t1[p3] = s2
	task.spawn(wcall, fireStep, p3, "Impression", s2)
end
function t2.TrackOfferClick(p4, s3: string) -- line: 59
	-- upvalues: wcall (copy), fireStep (copy)
	task.spawn(wcall, fireStep, p4, "OfferClick", s3)
end
function t2.TrackBuyClick(p5, s4: string) -- line: 63
	-- upvalues: wcall (copy), fireStep (copy)
	task.spawn(wcall, fireStep, p5, "BuyClick", s4)
end
function t2.TrackDeclined(p6, s5: string) -- line: 67
	-- upvalues: wcall (copy), fireStep (copy)
	task.spawn(wcall, fireStep, p6, "Declined", s5)
end

return t2

