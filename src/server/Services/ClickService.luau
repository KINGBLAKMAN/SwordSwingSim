--!strict
-- ClickService: clicking for Energy, by hand and on auto (GDD A10, TDD B7).
--
-- Manual clicks: the client sends Click with no arguments. The remote's own
-- rate limit stops floods; on top of that, at most CLICK_CAP_CPS clicks are
-- credited per second of real time, so an autoclicker earns no more than a
-- fast finger.
--
-- Auto-click: a saved toggle (profile.autos.click). The server clicks for
-- the player at StatService.autoClickRate, all players from one Heartbeat
-- loop (Util/TickScheduler), each started at a random offset so their
-- ticks spread out.
--
-- New players get START_ENERGY once on first join (later, at the end of
-- the tutorial).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BigNum = require(ReplicatedStorage.Shared.Util.BigNum)
local Clicking = require(ReplicatedStorage.Shared.Config.Clicking)
local Combat = require(ReplicatedStorage.Shared.Config.Combat)
local RateLimiter = require(ReplicatedStorage.Shared.Net.RateLimiter)
local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local TickScheduler = require(ReplicatedStorage.Shared.Util.TickScheduler)
local Remotes = require(script.Parent.Parent.Net.Remotes)
local CurrencyService = require(script.Parent.CurrencyService)
local DataService = require(script.Parent.DataService)
local FunnelService = require(script.Parent.FunnelService)
local StatService = require(script.Parent.StatService)

local ClickService = {}

-- Each manual click spends one credit; credits refill at CLICK_CAP_CPS a
-- second, banking at most one second's worth.
local clickCredit = RateLimiter.new({ calls = Clicking.CLICK_CAP_CPS, perSeconds = 1 })
local autoClicks = TickScheduler.new() :: TickScheduler.TickScheduler<Player>
-- Server-only RNG for spreading auto-click start times (TDD B7).
local random = Random.new()

local function addEnergy(player: Player, amount: number, source: string)
	CurrencyService.add(player, "energy", BigNum.fromNumber(amount), source)
end

-- Credits `clicks` clicks' worth of Energy.
function ClickService.grantClicks(player: Player, clicks: number)
	if not DataService.isLoaded(player) then
		return
	end
	addEnergy(player, clicks * StatService.energyPerClick(player), "Click")
	DataService.update(player, { "stats", "totalClicks" }, function(total)
		return total + clicks
	end)
end

local function onClick(player: Player)
	if clickCredit.allow(player, os.clock()) then
		ClickService.grantClicks(player, 1)
		FunnelService.reached(player, "FirstClick")
	end
end

local function startAutoClick(player: Player)
	local interval = 1 / StatService.autoClickRate(player)
	autoClicks.add(player, interval, os.clock(), random:NextNumber())
end

local function onSetAuto(player: Player, key: string, enabled: boolean)
	if key ~= Clicking.AUTO_KEY or not DataService.isLoaded(player) then
		return
	end
	DataService.set(player, { "autos", key }, enabled)
	if enabled then
		startAutoClick(player)
	else
		autoClicks.remove(player)
	end
end

local function onAutoClickHeartbeat()
	for player, ticks in autoClicks.collect(os.clock()) do
		ClickService.grantClicks(player, ticks)
	end
end

local function onProfileLoaded(player: Player, data: ProfileTypes.Profile)
	if not data.flags.startingEnergyGranted then
		addEnergy(player, Combat.START_ENERGY, "StartingEnergy")
		DataService.set(player, { "flags", "startingEnergyGranted" }, true)
	end
	if data.autos[Clicking.AUTO_KEY] == true then
		startAutoClick(player)
	end
end

local function forget(player: Player)
	clickCredit.forget(player)
	autoClicks.remove(player)
end

function ClickService.start()
	Remotes.on("Click", onClick)
	Remotes.on("SetAuto", onSetAuto)
	DataService.onLoaded(onProfileLoaded)
	DataService.onReleasing(forget)
	Players.PlayerRemoving:Connect(forget)
	RunService.Heartbeat:Connect(onAutoClickHeartbeat)
end

return ClickService
