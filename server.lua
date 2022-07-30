local oneSync = false

CreateThread(function()
	if GetConvar("onesync") ~= 'off' then
		oneSync = true
	end
end)

-------------------------- VARS

local Webhook = ''
local staffs = {}
local FeedbackTable = {}

-------------------------- NEW FEEDBACK

RegisterNetEvent("JLRP-Reports:NewFeedback")
AddEventHandler("JLRP-Reports:NewFeedback", function(data)
	local player = Framework.GetPlayerFromId(source)
	if player then
		local identifierlist = ExtractIdentifiers(source)
		local newFeedback = {
			feedbackid = #FeedbackTable+1,
			playerid = source,
			identifier = player.getIdentifier()..' - CitizenID: '..player.getCitizenid(),
			subject = data.subject,
			information = data.information,
			category = data.category,
			concluded = false,
			discord = "<@"..identifierlist.discord:gsub("discord:", "")..">"
		}

		FeedbackTable[#FeedbackTable+1] = newFeedback

		local xPlayers = Framework.GetPlayers() -- Returns all xPlayers
		for _, xPlayer in pairs(xPlayers) do
			local admins = Framework.GetConfig().Server.AdminGroups
			for i = 1, #admins, 1 do
				if xPlayer.getGroup() == admins[i] and xPlayer.adminDuty() then
					xPlayer.triggerEvent("JLRP-Reports:NewFeedback", newFeedback)
				end
			end
		end
		

		if Webhook ~= '' then
			newFeedbackWebhook(newFeedback)
		end
	end
end)

-------------------------- FETCH FEEDBACK

RegisterNetEvent("JLRP-Reports:FetchFeedbackTable")
AddEventHandler("JLRP-Reports:FetchFeedbackTable", function()
	if hasPermission(source) then
		staffs[source] = true
		TriggerClientEvent("JLRP-Reports:FetchFeedbackTable", source, FeedbackTable, oneSync)
	end
end)

-------------------------- ASSIST FEEDBACK

RegisterNetEvent("JLRP-Reports:AssistFeedback")
AddEventHandler("JLRP-Reports:AssistFeedback", function(feedbackId, canAssist)
	if staffs[source] then
		if canAssist then
			local id = FeedbackTable[feedbackId].playerid
			if GetPlayerPing(id) > 0 then
				local ped = GetPlayerPed(id)
				local playerCoords = GetEntityCoords(ped)
				local pedSource = GetPlayerPed(source)
				local identifierlist = ExtractIdentifiers(source)
				local assistFeedback = {
					feedbackid = feedbackId,
					discord = "<@"..identifierlist.discord:gsub("discord:", "")..">"
				}

				SetEntityCoords(pedSource, playerCoords.x, playerCoords.y, playerCoords.z)
				TriggerClientEvent('t-notify:client:Custom', source, {
					style = 'info',
					title = Config.Locale.System,
					message = "You are assisting FEEDBACK #"..feedbackId.."!",
					duration = tonumber(4000),
				})
				TriggerClientEvent('t-notify:client:Custom', id, {
					style = 'info',
					title = Config.Locale.System,
					message = "An admin arrived!",
					duration = tonumber(4000),
				})

				if Webhook ~= '' then
					assistFeedbackWebhook(assistFeedback)
				end
			else
				TriggerClientEvent('t-notify:client:Custom', source, {
					style = 'error',
					title = Config.Locale.System,
					message = 'That player is no longer in the server!',
					duration = tonumber(4000),
				})
			end
			if not FeedbackTable[feedbackId].concluded then
				FeedbackTable[feedbackId].concluded = "assisting"
			end
			TriggerClientEvent("JLRP-Reports:FeedbackConclude", -1, feedbackId, FeedbackTable[feedbackId].concluded)
		end
	end
end)

-------------------------- CONCLUDE FEEDBACK

RegisterNetEvent("JLRP-Reports:FeedbackConclude")
AddEventHandler("JLRP-Reports:FeedbackConclude", function(feedbackId, canConclude)
	if staffs[source] then
		local feedback = FeedbackTable[feedbackId]
		local identifierlist = ExtractIdentifiers(source)
		local concludeFeedback = {
			feedbackid = feedbackId,
			discord = "<@"..identifierlist.discord:gsub("discord:", "")..">"
		}

		if feedback then
			if feedback.concluded ~= true or canConclude then
				if canConclude then
					if FeedbackTable[feedbackId].concluded == true then
						FeedbackTable[feedbackId].concluded = false
					else
						FeedbackTable[feedbackId].concluded = true
					end
				else
					FeedbackTable[feedbackId].concluded = true
				end
				local xPlayers = Framework.GetPlayers() -- Returns all xPlayers
				for _, xPlayer in pairs(xPlayers) do
					local admins = Framework.GetConfig().Server.AdminGroups
					for i = 1, #admins, 1 do
						if xPlayer.getGroup() == admins[i] and xPlayer.adminDuty() then
							xPlayer.triggerEvent("JLRP-Reports:FeedbackConclude", feedbackId, FeedbackTable[feedbackId].concluded)
						end
					end
				end

				if Webhook ~= '' then
					concludeFeedbackWebhook(concludeFeedback)
				end
			end
		end
	end
end)

-------------------------- HAS PERMISSION
Framework = exports['JLRP-Framework']:GetFrameworkObjects()
function hasPermission(id)
	local staff = false

	local xPlayer = Framework.GetPlayerFromId(id)
	if xPlayer then
		local admins = Framework.GetConfig().Server.AdminGroups
		for i = 1, #admins, 1 do
			if xPlayer.getGroup() == admins[i] then
				return xPlayer.adminDuty()
			end
		end
	end

	return staff
end

-------------------------- IDENTIFIERS

function ExtractIdentifiers(id)
    local identifiers = {
        steam = "",
        ip = "",
        discord = "",
        license = "",
        xbl = "",
        live = ""
    }

    for i = 0, GetNumPlayerIdentifiers(id) - 1 do
        local playerID = GetPlayerIdentifier(id, i)

        if string.find(playerID, "steam") then
            identifiers.steam = playerID
        elseif string.find(playerID, "ip") then
            identifiers.ip = playerID
        elseif string.find(playerID, "discord") then
            identifiers.discord = playerID
        elseif string.find(playerID, "license") then
            identifiers.license = playerID
        elseif string.find(playerID, "xbl") then
            identifiers.xbl = playerID
        elseif string.find(playerID, "live") then
            identifiers.live = playerID
        end
    end

    return identifiers
end

-------------------------- NEW FEEDBACK WEBHOOK

function newFeedbackWebhook(data)
	if data.category == 'player_report' then
		category = 'Player Report'
	elseif data.category == 'question' then
		category = 'Question'
	else
		category = 'Bug'
	end

	local information = {
		{
			["color"] = Config.NewFeedbackWebhookColor,
			["author"] = {
				["icon_url"] = Config.IconURL,
				["name"] = Config.ServerName..' - Logs',
			},
			["title"] = 'NEW FEEDBACK #'..data.feedbackid,
			["description"] = '**Category:** '..category..'\n**Subject:** '..data.subject..'\n**Information:** '..data.information..'\n\n**ID:** '..data.playerid..'\n**Identifier:** '..data.identifier..'\n**Discord:** '..data.discord,
			["footer"] = {
				["text"] = os.date(Config.DateFormat),
			}
		}
	}
	PerformHttpRequest(Webhook, function(err, text, headers) end, 'POST', json.encode({username = Config.BotName, embeds = information}), {['Content-Type'] = 'application/json'})
end

-------------------------- ASSIST FEEDBACK WEBHOOK

function assistFeedbackWebhook(data)
	local information = {
		{
			["color"] = Config.AssistFeedbackWebhookColor,
			["author"] = {
				["icon_url"] = Config.IconURL,
				["name"] = Config.ServerName..' - Logs',
			},
			["description"] = '**FEEDBACK #'..data.feedbackid..'** is being assisted by '..data.discord,
			["footer"] = {
				["text"] = os.date(Config.DateFormat),
			}
		}
	}
	PerformHttpRequest(Webhook, function(err, text, headers) end, 'POST', json.encode({username = Config.BotName, embeds = information}), {['Content-Type'] = 'application/json'})
end

-------------------------- CONCLUDE FEEDBACK WEBHOOK

function concludeFeedbackWebhook(data)
	local information = {
		{
			["color"] = Config.ConcludeFeedbackWebhookColor,
			["author"] = {
				["icon_url"] = Config.IconURL,
				["name"] = Config.ServerName..' - Logs',
			},
			["description"] = '**FEEDBACK #'..data.feedbackid..'** has been concluded by '..data.discord,
			["footer"] = {
				["text"] = os.date(Config.DateFormat),
			}
		}
	}
	PerformHttpRequest(Webhook, function(err, text, headers) end, 'POST', json.encode({username = Config.BotName, embeds = information}), {['Content-Type'] = 'application/json'})
end