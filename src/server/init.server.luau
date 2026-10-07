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
}

Bootstrap.run("Server", services)
