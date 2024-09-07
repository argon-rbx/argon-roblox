local MarketPlaceService = game:GetService("MarketplaceService")

local name = game.Name
local isFile = name:find(".rbxl") or name:find(".rbxlx")

if not isFile then
	pcall(function()
		name = MarketPlaceService:GetProductInfo(game.PlaceId).Name
	end)
end

return {
	Name = name,
	IsFile = isFile,
	Version = game.PlaceVersion,
}
