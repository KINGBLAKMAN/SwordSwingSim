--!strict
-- Client entry point. Add each controller here as it gets built. The client
-- only renders and sends intent; the server decides every outcome (TDD B6–B7).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bootstrap = require(ReplicatedStorage.Shared.Bootstrap)

local controllers: { Bootstrap.Entry } = {
	-- { name = "InputController", module = require(script.Controllers.InputController) },
}

Bootstrap.run("Client", controllers)
