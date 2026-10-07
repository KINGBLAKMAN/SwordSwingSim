--!strict
-- Server entry point. Add each service here, in the order listed in
-- TDD B2, as it gets built. DataService goes first so later services can
-- read profiles during their own init.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bootstrap = require(ReplicatedStorage.Shared.Bootstrap)

local services: { Bootstrap.Entry } = {
	-- { name = "DataService", module = require(script.Services.DataService) },
}

Bootstrap.run("Server", services)
