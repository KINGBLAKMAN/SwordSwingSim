--!strict
-- SettingsService: saves the player's on/off settings (GDD A22). Only keys
-- in Config/Settings get through the UpdateSetting remote's checks.

local Remotes = require(script.Parent.Parent.Net.Remotes)
local DataService = require(script.Parent.DataService)

local SettingsService = {}

local function onUpdateSetting(player: Player, key: string, value: boolean)
	if DataService.isLoaded(player) then
		DataService.set(player, { "settings", key }, value)
	end
end

function SettingsService.start()
	Remotes.on("UpdateSetting", onUpdateSetting)
end

return SettingsService
