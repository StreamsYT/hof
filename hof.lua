--[[
--
-- Accept hand of fate quest & hand in the quest with lightning speed!
--
--
-- Best regards,
-- Perjantai / Tiistai @ In-game
-- zz#6108
--]]
--
--
--
--

local hof, misc = {}, {}
local session_enabled = nil
local hof_hint_spam = 99

--number of interactions before giving user a hint on how to set the spec
local interactions_before_spam = 5

function misc:chat(format, ...)
	print(misc:sprintf("|cff00ff00HOF:|r %s", string.format(format, ...)))
end

function misc:sprintf(format, ...)
	return string.format(format, ...)
end

function misc:specializationString()
	return misc:sprintf("Specialization %d:", spec)
end

function misc:debug(format, ...)
	if (debug ~= nil and debug == true) then
		misc:chat("debug - %s", misc:sprintf(format, ...))
	end
end

function misc:getHumanReadableSpec()
	if (spec == nil) then
		return "<not set>"
	else
		return tostring(spec)
	end
end

function misc:getStateHumanReadable()
	if (enabled) then
		return "enabled"
	else
		return "disabled"
	end
end

function misc:cleanSlashCmd(input)
	msg = string.gsub(msg, "add", "")
end

function misc:printHelp()
	misc:chat("Hand of fate turnin made fast!")
	misc:chat(misc:sprintf("Your current specialization number set for this is: %s", misc:getHumanReadableSpec())) --todo
	misc:chat(misc:sprintf("hof is currently %s", misc:getStateHumanReadable())) --todo enabeld/disabled
	misc:chat("- list of commands -")
	misc:chat("/hof set <spec number>")
	misc:chat("        for example:")
	misc:chat("        /hof set 2")
	misc:chat("/hof toggle        - toggles hof on/off")
	misc:chat("/hof enable        - toggles hof on")
	misc:chat("/hof disable       - toggles hof off")
end

function misc:gossipToTable(gossip)
	local available = {}
	for k, v in pairs(gossip) do
		if k == 1 or ((k - 1) % 5 == 0) then
			table.insert(available, v)
		end
	end
	return available
end

function misc:createDialog()
	misc:debug("createDialog refreshed")
	StaticPopupDialogs["HOF_CONFIRM"] = {
		text = misc:sprintf("HOF is currently enabled, your spec number is set to %s\npress yes if you want to automatically accept & complete Hand of Fate quests?", misc:getHumanReadableSpec()),
		button1 = "Yes",
		button2 = "No",
		OnAccept = function()
			misc:chat("Hof enabled for the session!")
			session_enabled = true
			hof:GOSSIP_SHOW();
		end,
		OnCancel = function()
			misc:chat("Hof disabled for the session! type /hof enable to reset.")
			session_enabled = false
		end,
		timeout = 0,
		whileDead = false,
		hideOnEscape = true,
		preferredIndex = 3,
	  }
end

function misc:getQuestIndex(gossip, quest)
	for k, v in pairs(gossip) do
		if string.find(v, quest) then
			return {k, v}
		end
	end

	return nil --no quest id?
end


function misc:hofSpam(force)
	if (spec == nil and hof_hint_spam >= interactions_before_spam) or force ~= nil then
		misc:chat("pssst, set your spec for fast HOF handins with /hof set <spec number>")
		hof_hint_spam = 0
	elseif (spec == nil and hof_hint_spam <= interactions_before_spam) then
		hof_hint_spam = hof_hint_spam + 1
	end
end


function hof:GOSSIP_SHOW(...)
	misc:hofSpam()
	if (enabled ~= true or session_enabled == false) then
		return;
	end
	
	local available = misc:gossipToTable({GetGossipAvailableQuests()})
	local active = misc:gossipToTable({GetGossipActiveQuests()})

	local activeIndex = misc:getQuestIndex(active, misc:specializationString())
	local availableIndex = misc:getQuestIndex(available, misc:specializationString())
	if (activeIndex ~= nil or availableIndex ~= nil) and spec == nil then
		misc:hofSpam(true)
		return
	end

	if activeIndex ~= nil then
		if (session_enabled == nil) then
			StaticPopup_Show("HOF_CONFIRM");
			return
		end
		misc:debug("found quest available for completion on index %s", tostring(activeIndex[1]))
		SelectGossipActiveQuest(activeIndex[1])
	else
		if availableIndex ~= nil then
			if (session_enabled == nil) then
				StaticPopup_Show("HOF_CONFIRM");
				return
			end
			misc:debug("found quest available for pickup on index %s", tostring(availableIndex[1]))
			SelectGossipAvailableQuest(availableIndex[1])
		end
	end
end

function hof:QUEST_DETAIL(...)
	if (enabled ~= true or session_enabled == false or spec == nil) then
		return;
	end
	misc:debug("QUEST_DETAIL AcceptQuest")
	AcceptQuest()
end

function hof:QUEST_COMPLETE(...)
	if (enabled ~= true or session_enabled == false or spec == nil) then
		return;
	end
	misc:debug("QUEST_COMPLETE GetQuestReward")
	GetQuestReward()
end

function hof:QUEST_PROGRESS(...)
	if (enabled ~= true or session_enabled == false or spec == nil) then
		return;
	end
	misc:debug("QUEST_PROGRESS CompleteQuest")
	CompleteQuest()
end

function hof:PLAYER_LOGIN(...)
	misc:debug("PLAYER_LOGIN fired")
	if (spec == nil) then
		misc:printHelp()
	end
end

function hof:ADDON_LOADED(...)
	misc:debug("ADDON_LOADED fired")
	misc:createDialog();
	if (enabled == nil) then
		enabled = true
	end

	if (debug == nil) then
		debug = false
	end
end

local hofFrame = CreateFrame("Frame")

hofFrame:SetScript(
	"OnEvent",
	function(self, event, ...)
		hof[event](self, ...)
	end
)

for k, v in pairs(hof) do
	hofFrame:RegisterEvent(k)
	misc:debug("Listening events on %s", k)
end

local cmd, cmdCommands = {}, {}

function cmdCommands:patterns()
	local patterns = {}
	patterns["set"] = "^%w- %d-$"
	patterns["toggle"] = "^%w-$"
	patterns["enable"] = "^%w-$"
	patterns["disable"] = "^%w-$"
	patterns["verbose"] = "^%w-$"
	return patterns
end

function cmdCommands:set(specNumber)
	if (specNumber ~= nil and specNumber ~= "") then
		specNumber = tonumber(specNumber);
		if (specNumber >= 1 and specNumber <= 12) then -- 12 specs available
			spec = specNumber
			misc:chat("Your spec has been set to %d!", specNumber)
			misc:createDialog()
			return true
		end
	end
	return false
end

function cmdCommands:enable()
	misc:createDialog()
	enabled = true
	session_enabled = nil
	if (spec == nil) then
		misc:chat("Enabled!")
		misc:hofSpam(true)
	else
		misc:chat("Enabled! You're ready to go down on silas!")
	end
	return true
end
function cmdCommands:disable()
	enabled = false
	session_enabled = nil
	misc:chat("Disabled! I'm sure Silas is satisfied with the work you did.")
	return true
end

function cmdCommands:toggle()
	
	if (enabled == nil or enabled == false) then
		return cmdCommands:enable()
	else
		return cmdCommands:disable()
	end
end

function cmdCommands:verbose()
	if (debug == nil or debug == false) then
		debug = true;
		misc:chat("Verbose logging enabled!")
	else
		debug = false;
		misc:chat("Verbose logging disabled!");
	end

	return true;
end

function cmd:input(data)
	self.original = data
	self.cmd = data

	if cmd:call() == false then
		misc:printHelp()
	end
end

function cmd:call()
	local patterns = cmdCommands:patterns()

	for command, v in pairs(patterns) do
		if (self.cmd:match(v)) then
			if (self.cmd:match("^%w*", 1) == command) then


				 --we're actually abusing a lua 'feature' here.. you may see the obvious bug, but it's intentional!
				local callArgs = {}
				for str in self.cmd:gmatch("(%w+)") do
						table.insert(callArgs, str) 
				end

				return cmdCommands[command](unpack(callArgs))
			end
		end
	end
	return false
end

SLASH_HOF1 = "/hof"
SLASH_HOF2 = "/spec"
SlashCmdList["HOF"] = function(msg)
	cmd:input(msg)
end
