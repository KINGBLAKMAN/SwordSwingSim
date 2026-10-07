--!strict
-- Client entry point. Add each controller here as it gets built. The client
-- only renders and sends intent; the server decides every outcome (TDD B6–B7).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bootstrap = require(ReplicatedStorage.Shared.Bootstrap)

local controllers: { Bootstrap.Entry } = {
	-- DataController first: other controllers read the profile copy it keeps.
	{ name = "DataController", module = require(script.Controllers.DataController) },
}

Bootstrap.run("Client", controllers)
