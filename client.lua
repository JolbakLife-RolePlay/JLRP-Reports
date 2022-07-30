CreateThread(function()
	Wait(1000)
	TriggerServerEvent("JLRP-Reports:FetchFeedbackTable")
end)

-------------------------- VARS

local oneSync = false
local FeedbackTable = {}
local canFeedback = true
local timeLeft = Config.FeedbackCooldown

-------------------------- COMMANDS

RegisterCommand(Config.FeedbackClientCommand, function(source, args, rawCommand)
	if canFeedback then
		FeedbackMenu(false)
	else
		Framework.ShowNotification("You can't report so quickly!", "warning", 3000, {title = Config.Locale.System})
	end
end, false)

RegisterCommand(Config.FeedbackAdminCommand, function(source, args, rawCommand)
	if Framework.PlayerData.admin then
		FeedbackMenu(true)
	end
end, false)

-------------------------- MENU

function FeedbackMenu(showAdminMenu)
	SetNuiFocus(true, true)
	if showAdminMenu then
		SendNUIMessage({
			action = "updateFeedback",
			FeedbackTable = FeedbackTable
		})
		SendNUIMessage({
			action = "OpenAdminFeedback",
		})
	else
		SendNUIMessage({
			action = "ClientFeedback",
		})
	end
end

-------------------------- EVENTS

function OnPlayerData(key, value, lastValue)
	if key == "admin" then
		if value then TriggerServerEvent("JLRP-Reports:FetchFeedbackTable") else FeedbackTable = {} end
	end
end

RegisterNetEvent('JLRP-Reports:NewFeedback')
AddEventHandler('JLRP-Reports:NewFeedback', function(newFeedback)
	if Framework.PlayerData.admin then
		FeedbackTable[#FeedbackTable+1] = newFeedback
		Framework.ShowNotification("New Report! Some one needs help!", "info", 3000, {title = Config.Locale.System})
		SendNUIMessage({
			action = "updateFeedback",
			FeedbackTable = FeedbackTable
		})
	end
end)

RegisterNetEvent('JLRP-Reports:FetchFeedbackTable')
AddEventHandler('JLRP-Reports:FetchFeedbackTable', function(feedback, oneS)
	FeedbackTable = feedback
	oneSync = oneS
end)

RegisterNetEvent('JLRP-Reports:FeedbackConclude')
AddEventHandler('JLRP-Reports:FeedbackConclude', function(feedbackID, info)
	if Framework.PlayerData.admin then
		local feedbackid = FeedbackTable[feedbackID]
		feedbackid.concluded = info
		SendNUIMessage({
			action = "updateFeedback",
			FeedbackTable = FeedbackTable
		})
	end
end)

-------------------------- ACTIONS

RegisterNUICallback("action", function(data)
	if data.action ~= "concludeFeedback" then
		SetNuiFocus(false, false)
	end

	if data.action == "newFeedback" then
		Framework.ShowNotification("Report successfully sent to the STAFF!", "success", 3000, {title = Config.Locale.System})
		
		local feedbackInfo = {subject = data.subject, information = data.information, category = data.category}
		TriggerServerEvent("JLRP-Reports:NewFeedback", feedbackInfo)

		local time = Config.FeedbackCooldown * 60
		local pastTime = 0
		canFeedback = false

		while (time > pastTime) do
			Wait(1000)
			pastTime = pastTime + 1
			timeLeft = time - pastTime
		end
		canFeedback = true
	elseif data.action == "assistFeedback" then
		if FeedbackTable[data.feedbackid] then
			if oneSync then
				TriggerServerEvent("JLRP-Reports:AssistFeedback", data.feedbackid, true)
			else
				local playerFeedbackID = FeedbackTable[data.feedbackid].playerid
				local playerID = GetPlayerFromServerId(playerFeedbackID)
				local playerOnline = NetworkIsPlayerActive(playerID)
				if playerOnline then
					SetEntityCoords(PlayerPedId(), GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(playerFeedbackID))))
					TriggerServerEvent("JLRP-Reports:AssistFeedback", data.feedbackid, true)
				else
					Framework.ShowNotification("That player is no longer in the server!", "error", 3000, {title = Config.Locale.System})
				end
			end
		end
	elseif data.action == "concludeFeedback" then
		local feedbackID = data.feedbackid
		local canConclude = data.canConclude
		local feedbackInfo = FeedbackTable[feedbackID]
		if feedbackInfo then
			if feedbackInfo.concluded ~= true or canConclude then
				TriggerServerEvent("JLRP-Reports:FeedbackConclude", feedbackID, canConclude)
				Framework.ShowNotification("Feedback #"..feedbackID.." concluded!", "success", 3000, {title = Config.Locale.System})
			end
		end
	end
end)