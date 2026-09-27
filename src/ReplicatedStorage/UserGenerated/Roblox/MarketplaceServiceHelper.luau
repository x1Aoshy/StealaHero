-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
--!native
local MarketplaceService = game:GetService("MarketplaceService")
local Cache = require(game.ReplicatedStorage.UserGenerated.Concurrency.Cache)
local Asserts = require(game.ReplicatedStorage.UserGenerated.Lang.Asserts)
local v4 = Asserts.TablePermissive({
	PurchaseId = Asserts.String,
	PlayerId = Asserts.Integer,
	ProductId = Asserts.Integer,
	PlaceIdWherePurchased = Asserts.Integer,
	CurrencySpent = Asserts.IntegerNonNegative,
	CurrencyType = Asserts.AnyOf(Asserts.Enum(Enum.CurrencyType), Asserts.String),
	ProductPurchaseChannel = Asserts.Enum(Enum.ProductPurchaseChannel)
})
local v5 = Asserts.Table({
	AssetId = Asserts.Integer,
	InfoType = Asserts.Enum(Enum.InfoType)
})
local v6 = Cache.new({
	Callback = function(t1: {[any]: any}) -- line: 158
		-- upvalues: MarketplaceService (copy)
		return MarketplaceService:GetProductInfo(t1.AssetId, t1.InfoType)
	end,
	AssertKey = function(p1) -- line: 161
		-- upvalues: v5 (copy)
		v5(p1)

		return `{ p1.AssetId },{ p1.InfoType.Value }`
	end
})
local t3 = {
	AssertReceiptInfo = v4,
	GetInfoAsync = function(n1: number, p2, b1: boolean?) -- line: 171
		-- upvalues: Asserts (copy), v6 (copy)
		Asserts.Integer(n1)
		Asserts.Enum(Enum.InfoType)(p2)
		Asserts.Optional(Asserts.Boolean)(b1)

		local t2 = {
			AssetId = n1,
			InfoType = p2
		}

		if b1 then
			return v6:Get(t2)
		end

		return v6:GetAsync(t2)
	end
}

return table.freeze(t3)

