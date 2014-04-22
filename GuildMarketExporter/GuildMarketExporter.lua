--[[###########################################################################
#
#  Guild Market Exporter
#  An AddOn for Elder Scrolls Online
#  Written By Renic Gunderson (@zalrenic)
#
#  Special Thanks to the following authors, who's work helped me understand
#  and work with both LUA and the ESO Mod API:
#    awesomebilly - Author of Trade Sales History
#    trtt - Author of BatmanStoreFilter
#    xevoran - Author of Guild Store Search
#    Errc & SinusPi - Authors of Zgoo
#    Mitazaki - Author of Saved Variables (example addon)
#  ... to the denizens of #esouidev on freenode for putting up with my
#      questions.
#  ... and last, but not least, to early adopters and those who helped test.
#
#  version 0.2
#
###########################################################################]]--


local status = {} -- build status table
local init = false
local started = false
local current_guild = 0
local c = 0
local history_c = 0
local guild_id = 0
local guild_name = 0
local guild_alliance = 0
local max_level = 50

local start_time = 0;
local stop_time = 0;

function GME_On_AddOn_Loaded(eventCode, addOnName) -- initialize the saved variables
    if(addOnName == "GuildMarketExporter") then
		local defaults = {['data']={},['actual_sales']={},['version']=2}
		savedVars = ZO_SavedVars:New('GuildMarketExporter_marketData', 1, nil, defaults)
	end
end


function GME_Init() -- GME_Init sets up the status variables, and begins the search process
	if init == false then
		for i = 1, 5 do -- reset the queue (5 guild max)
			status[i] = {['current_page'] = 0,['level_filter'] = 0}
		end
		for i = 1, 5 do -- set guild info and request history to be loaded
			-- get the names and IDs, etc.
			status[i]['guild_name'] = GetGuildName(i)
			status[i]['guild_id'] = i
			status[i]['guild_alliance'] = GetGuildAlliance(i)
			--[[
			
				There are no callbacks associated with when guild sale
				histories are loaded.  Request them early and save whatever we
				have discovered at the end of the process. 
			
			]]--
			RequestGuildHistoryCategoryNewest(i,GUILD_HISTORY_SALES)
			RequestGuildHistoryCategoryOlder(i,GUILD_HISTORY_SALES)
   	    	
   	    	if status[i]['guild_name'] == nil or status[i]['guild_name'] == "" then
				break -- stop scanning if we run out of guilds before hitting 5
			end
		end
		init = true -- allows other functions to run
		savedVars['data'] = {} -- clear the orders save variable
		savedVars['actual_sales'] = {} -- clear the actuals sales save variable
		savedVars['version'] = 2 -- set the version
	end
end


function GME_Start()
	if started == false then
		start_time = GetTimeStamp()
		started = true
		GME_Show()
		if init == true then
			GME_Next_Guild(0)
		else
			GMEGuildStatus:SetText("Guild Market Exporter not yet full initialized - wait a few seconds and try again.")
		end
	else
		GMEGuildStatus:SetText("Only one scan may be run at a time.")
	end
end


function GME_Next_Level(level_filter)
	if level_filter < max_level then
		status[current_guild]['current_page'] = 0
		status[current_guild]['level_filter'] = status[current_guild]['level_filter'] + 1
		GME_Get_Results() -- get next set of results
	else
		GME_Next_Guild(current_guild)	
	end
end


function GME_Next_Guild(last_guild)
	for i = last_guild, 5 do
		current_guild = i + 1
		if CanBuyFromTradingHouse(current_guild) == true then
			SelectTradingHouseGuildId(current_guild)
			status[current_guild]['current_page'] = 0
			status[current_guild]['level_filter'] = 0
			GME_Get_Results() -- get the first set of results
			GMEGuildStatus:SetText("Scanning: " .. status[current_guild]['guild_name'])
			GMEPageStatus:SetText("Level " .. status[current_guild]['level_filter'] .. " items ... Page: " .. status[current_guild]['current_page'] .. " ...")
			break
		end
		if current_guild == 6 then
			-- do history work
			GMEGuildStatus:SetText("Saving Order History")
			GMEPageStatus:SetText("Examing " .. status[i]['guild_name'])
			for i = 1, 5 do
				local event_count = GetNumGuildEvents(i,GUILD_HISTORY_SALES)
				for j = 0, event_count do
					local event_type, seconds_since_sale, seller, buyer, stack_count, item_name, sale_price = GetGuildEventInfo(i,GUILD_HISTORY_SALES,j)
 					GME_Append_History(event_type, seconds_since_sale, seller, buyer, stack_count, item_name, sale_price, status[i]['guild_name'], status[i]['guild_id'])
				end
			end
			-- process ended
			stop_time = GetTimeStamp()
			local run_time = stop_time - start_time
			GMEGuildStatus:SetText("Work Complete ... " .. run_time .. " seconds.")
			GMEPageStatus:SetText("(" .. c .. " orders examined. " .. history_c .. " sales recorded.)")
			GME_Close_Button_Show()
		end
	end
end


function GME_Get_Results()
	ClearAllTradingHouseSearchTerms() -- clear ui search settings before proceeding
	SetTradingHouseFilter(TRADING_HOUSE_FILTER_TYPE_LEVEL,status[current_guild]['level_filter']) -- filter only for the current level of items
	ExecuteTradingHouseSearch(status[current_guild]['current_page'], TRADING_HOUSE_SORT_SALE_PRICE, true)
end


function GME_Receive_Results(eventId, guildId, numItemsOnPage, currentPage, hasMorePages)
	if init == true then
		if started == true then
			GMEPageStatus:SetText("Processing Items on Page " .. status[current_guild]['current_page'])
			local current_time = GetTimeStamp()
			for i = 1, numItemsOnPage do
				-- walk through the items on the page
				local texture_name, item_name, quality, stack_count, seller_name, time_remaining, purchase_price = GetTradingHouseSearchResultItemInfo(i)
				-- append info to save variable
				GME_Append_To_Save(status[current_guild]['guild_id'], status[current_guild]['guild_name'], status[current_guild]['guild_alliance'], texture_name, item_name, quality, stack_count, seller_name, time_remaining, purchase_price, current_time, status[current_guild]['level_filter'])
			end
			if hasMorePages == true then
				-- request next page
				status[current_guild]['current_page'] = status[current_guild]['current_page'] + 1
				GME_Get_Results()
			else
				GME_Next_Level(status[current_guild]['level_filter'])
			end
		end
	end
end


function GME_Append_To_Save(guild_id, guild_name, guild_alliance, texture_name, item_name, quality, stack_count, seller_name, time_remaining, purchase_price, current_time, level_filter)
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
	item['item_level'] = level_filter
	c = c + 1
	savedVars['data'][c] = item
end


function GME_Hide()
    GME:SetHidden(true)
    GME_Close_Button_Hide()
    ReloadUI("ingame")
end
function GME_Show()
    GME:SetHidden(false)
end
function GME_Close_Button_Hide()
	GMEEventStatus:SetHidden(false)
    GMECloseButton:SetHidden(true)
end
function GME_Close_Button_Show()
	GMEEventStatus:SetHidden(true)
    GMECloseButton:SetHidden(false)
end


function GME_Update_EVENT_TRADING_HOUSE_AWAITING_RESPONSE()
	if CanBuyFromTradingHouse(current_guild) == true then
		GMEPageStatus:SetText("Level " .. status[current_guild]['level_filter'] .. " items ... Page: " .. status[current_guild]['current_page'] .. " ... Waiting for Server.")
	end
end
EVENT_MANAGER:RegisterForEvent("GuildMarketExporter", EVENT_TRADING_HOUSE_AWAITING_RESPONSE, GME_Update_EVENT_TRADING_HOUSE_AWAITING_RESPONSE)
EVENT_MANAGER:RegisterForEvent("GuildMarketExporter", EVENT_TRADING_HOUSE_SEARCH_RESULTS_RECEIVED, GME_Receive_Results)
EVENT_MANAGER:RegisterForEvent("GuildMarketExporter", EVENT_ADD_ON_LOADED, GME_On_AddOn_Loaded)
EVENT_MANAGER:RegisterForEvent("GuildMarketExporter", EVENT_TRADING_HOUSE_STATUS_RECEIVED, GME_Init)


SLASH_COMMANDS["/gme"] = GME_Start


function GME_Append_History(event_type, seconds_since_sale, seller, buyer, stack_count, item_name, sale_price, guild_name, guild_id)
	history_c = history_c + 1
	local this_sale = {}
	this_sale['event_type'] = event_type
	this_sale['time_of_sale'] = GetTimeStamp() - seconds_since_sale
	this_sale['seller'] = seller
	this_sale['buyer'] = buyer
	this_sale['stack_count'] = stack_count
	this_sale['item_name'] = item_name
	this_sale['sale_price'] = sale_price
	this_sale['guild_name'] = guild_name
	this_sale['guild_id'] = guild_id
	table.insert(savedVars['actual_sales'], this_sale)
end
