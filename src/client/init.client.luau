--!strict
-- Client entry point. Add each controller here as it gets built. The client
-- only renders and sends intent; the server decides every outcome (TDD B6–B7).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bootstrap = require(ReplicatedStorage.Shared.Bootstrap)

local controllers: { Bootstrap.Entry } = {
	-- DataController first: other controllers read the profile copy it keeps.
	{ name = "DataController", module = require(script.Controllers.DataController) },
	{ name = "ClickController", module = require(script.Controllers.ClickController) },
	{ name = "EnemyController", module = require(script.Controllers.EnemyController) },
	{ name = "CombatController", module = require(script.Controllers.CombatController) },
	{
		name = "DamageNumberController",
		module = require(script.Controllers.DamageNumberController),
	},
	{ name = "UIController", module = require(script.Controllers.UIController) },
}

Bootstrap.run("Client", controllers)
