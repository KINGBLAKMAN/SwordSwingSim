--!strict
-- Player settings (GDD A22). Each is an on/off switch saved in
-- profile.settings and changed with the UpdateSetting remote, which only
-- accepts keys listed here.

export type SettingDef = { key: string, label: string, default: boolean }

local Settings = {
	LIST = {
		{ key = "skipHatchAnimation", label = "Skip hatch animation", default = false },
	} :: { SettingDef },
}

-- The saved value, or the setting's default if the player never changed it.
function Settings.value(saved: { [string]: any }, key: string): boolean
	local value = saved[key]
	if typeof(value) == "boolean" then
		return value
	end
	for _, def in Settings.LIST do
		if def.key == key then
			return def.default
		end
	end
	error(`Settings: unknown setting "{key}"`)
end

-- Every setting key, for the remote's argument check.
function Settings.keys(): { string }
	local keys = {}
	for _, def in Settings.LIST do
		table.insert(keys, def.key)
	end
	return keys
end

return table.freeze(Settings)
