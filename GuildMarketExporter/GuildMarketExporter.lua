local status = {} -- build status table

local init = false
local current_guild = 0
local c = 0

local function OnAddOnLoaded(eventCode, addOnName) -- initialize the saved variables
    if(addOnName == "GuildMarketExporter") then
		local defaults = {['data']={}}
		savedVars = ZO_SavedVars:New('GuildMarketExporter_marketData', 1, nil, defaults)
	end
end

function GME_init() -- GME_init sets up the status variables, and begins the search process
	init = true -- allows other functions to run
	savedVars['data'] = {} -- clear the save variable
    GME_Show() -- show the status window
	local market_count = GetNumTradingHouseGuilds() -- check for guild stores
	if  market_count == 0 then
		GMEStatus:SetText('No Markets Found. Open a guild store and try again.')
	else 
		for i = 1, 5 do -- reset the queue (5 guild max)
			status[i] = {['valid'] = false,['current_page'] = 0}
		end
		for i = 1, market_count do -- set guilds as valid
			status[i]['valid'] = true
		end
		current_guild = 1 -- begin queue by starting with guild 1
		SelectTradingHouseGuildId(current_guild)
		status[current_guild]['current_page'] = 1
    	ClearAllTradingHouseSearchTerms() -- clear ui search settings before proceeding
		GME_get_results() -- get the first set of results
	end
end

function GME_get_results()
	ExecuteTradingHouseSearch(status[current_guild]['current_page'], TRADING_HOUSE_SORT_SALE_PRICE, true)
end

function GME_receive_results(eventId, guildId, numItemsOnPage, currentPage, hasMorePages)
	if init == true then
		GMEStatus:SetText("Processing Items on Page")
		local current_time = GetTimeStamp()
		local guild_id, guild_name, guild_alliance = GetTradingHouseGuildDetails(current_guild)
		
		-- no way to know how many items on the page... :(
		for i = 1, numItemsOnPage do
			-- walk through the items on the page
			local texture_name, item_name, quality, stack_count, seller_name, time_remaining, purchase_price = GetTradingHouseSearchResultItemInfo(i)
			-- append info to save variable
			GME_append_to_save(guild_id, guild_name, guild_alliance, texture_name, item_name, quality, stack_count, seller_name, time_remaining, purchase_price, current_time)
		end
		if hasMorePages == true then
			-- request next page
			status[current_guild]['current_page'] = status[current_guild]['current_page'] + 1
			GME_get_results()
		else
			-- check to see if we can switch to the next guild
			local can_switch_guilds = false
			if current_guild < 5 then
				if status[current_guild + 1]['valid'] == true then
					can_switch_guilds = true
				end
			end
			-- make the switch to the next guild
			if can_switch_guilds == true then
				current_guild = current_guild + 1
				SelectTradingHouseGuildId(current_guild)
				status[current_guild]['current_page'] = 1
				-- get the next set of results
				GME_get_results()
			else
				-- process ended
				GMEStatus:SetText("Work Complete (" .. c .. ")")
				GMECloseButton_Show()
			end
		end
	end
end

function GME_append_to_save(guild_id, guild_name, guild_alliance, texture_name, item_name, quality, stack_count, seller_name, time_remaining, purchase_price, current_time)
	local item = {}
	item['guild_id'] = guild_id
	item['guild_name'] = guild_name
	item['guild_alliance'] = guild_alliance
	item['texture_name'] = texture_name
	item['item_name'] = item_name
	item['quality'] = quality
	item['stack_count'] = stack_count
	item['seller_name'] = seller_name
	item['time_remaining'] = time_remaining
	item['purchase_price'] = purchase_price
	item['current_time'] = current_time
	c = c + 1
	savedVars['data'][c] = item

	
end

function GME_Hide()
    GME:SetHidden(true)
    GMECloseButton_Hide()
    ReloadUI("ingame")
end

function GME_Show()
    GME:SetHidden(false)
end

function GMECloseButton_Hide()
    GMECloseButton:SetHidden(true)
end

function GMECloseButton_Show()
    GMECloseButton:SetHidden(false)
end




function GMEUpdate_EVENT_TRADING_HOUSE_AWAITING_RESPONSE(n)
	--last_EVENT_TRADING_HOUSE_AWAITING_RESPONSE = n
	GMEStatus:SetText("Waiting for Server to Send Next Page of Results")
end
EVENT_MANAGER:RegisterForEvent("GuildMarketExporter", EVENT_TRADING_HOUSE_AWAITING_RESPONSE, GMEUpdate_EVENT_TRADING_HOUSE_AWAITING_RESPONSE)
EVENT_MANAGER:RegisterForEvent("GuildMarketExporter", EVENT_TRADING_HOUSE_SEARCH_RESULTS_RECEIVED, GME_receive_results)
EVENT_MANAGER:RegisterForEvent("GuildMarketExporter", EVENT_ADD_ON_LOADED, OnAddOnLoaded)

SLASH_COMMANDS["/gme"] = GME_init
