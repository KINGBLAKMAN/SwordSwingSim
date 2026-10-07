--!strict
-- Server entry point. Add each service here, in the order listed in
-- TDD B2, as it gets built. Remotes and then DataService go first so later
-- services can connect remotes and read profiles during their own init.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bootstrap = require(ReplicatedStorage.Shared.Bootstrap)

local services: { Bootstrap.Entry } = {
	-- Remotes first: its init creates the RemoteEvents that services connect to in start.
	{ name = "Remotes", module = require(script.Net.Remotes) },
	{ name = "DataService", module = require(script.Services.DataService) },
	-- Right after DataService: its init() sets ProcessReceipt (TDD B10).
	{ name = "MonetizationService", module = require(script.Services.MonetizationService) },
	{ name = "ComplianceService", module = require(script.Services.ComplianceService) },
	{ name = "StatService", module = require(script.Services.StatService) },
	{ name = "ClickService", module = require(script.Services.ClickService) },
	-- WorldService before EnemyService: its init builds the spawn points
	-- EnemyService's init looks up.
	{ name = "WorldService", module = require(script.Services.WorldService) },
	{ name = "EnemyService", module = require(script.Services.EnemyService) },
	{ name = "CombatService", module = require(script.Services.CombatService) },
	{ name = "DropService", module = require(script.Services.DropService) },
	{ name = "PetService", module = require(script.Services.PetService) },
	{ name = "EggService", module = require(script.Services.EggService) },
	{ name = "QuestService", module = require(script.Services.QuestService) },
	{ name = "IslandService", module = require(script.Services.IslandService) },
	{ name = "FunnelService", module = require(script.Services.FunnelService) },
	{ name = "SettingsService", module = require(script.Services.SettingsService) },
}

Bootstrap.run("Server", services)
