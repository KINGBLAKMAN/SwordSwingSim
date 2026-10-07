--!strict
-- EggService: opening eggs (GDD A6, TDD B6, B11).
--
-- OpenEgg(eggId, count) is checked in this order, and the first failure
-- tells the player why (except broken requests, which are dropped):
--   1. the egg's island is unlocked,
--   2. the player stands near the egg,
--   3. ComplianceService lets them open it,
--   4. they have room for the pets,
--   5. they can pay (CurrencyService takes the Coins).
-- Each egg then rolls through OddsCalculator, the same module the odds
-- panel uses, with luck from ComplianceService.luckFor and pity from the
-- profile. HatchResult tells the client what came out.
--
-- Hatched pets go to PetService, which owns the inventory.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BigNum = require(ReplicatedStorage.Shared.Util.BigNum)
local EggRules = require(ReplicatedStorage.Shared.Util.EggRules)
local Eggs = require(ReplicatedStorage.Shared.Config.Eggs)
local Hatching = require(ReplicatedStorage.Shared.Config.Hatching)
local OddsCalculator = require(ReplicatedStorage.Shared.Util.OddsCalculator)
local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Remotes = require(script.Parent.Parent.Net.Remotes)
local ComplianceService = require(script.Parent.ComplianceService)
local CurrencyService = require(script.Parent.CurrencyService)
local DataService = require(script.Parent.DataService)
local PetService = require(script.Parent.PetService)
local StatService = require(script.Parent.StatService)
local WorldService = require(script.Parent.WorldService)

export type HatchedPet = { uid: string, pet: string, isNew: boolean }

local EggService = {}

-- (player, eggId, opens) after a paid open, for quests.
EggService.opened = Signal.new()

-- One server-side Random per player (TDD B7).
local randoms: { [Player]: Random } = {}

local function randomFor(player: Player): Random
	local existing = randoms[player]
	if existing then
		return existing
	end
	local random = Random.new()
	randoms[player] = random
	return random
end

local function notify(player: Player, message: string)
	Remotes.fire("Notify", player, message)
end

local function isNearEgg(player: Player, egg: Eggs.EggDef): boolean
	local stand = WorldService.eggStand(egg.island)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if stand == nil or root == nil or not root:IsA("BasePart") then
		return false
	end
	local reach = Hatching.OPEN_RANGE + Hatching.RANGE_TOLERANCE
	return (root.Position - stand.Position).Magnitude <= reach
end

-- Rolls one egg: picks the pet, updates pity and stores the pet.
local function hatchOne(player: Player, egg: Eggs.EggDef, luck: number): HatchedPet
	local data = DataService.get(player) :: ProfileTypes.Profile
	local opensSincePity = data.pity[egg.id] or 0
	local options = { luck = luck, pityActive = OddsCalculator.isPityOpen(egg, opensSincePity) }
	local petId = OddsCalculator.roll(egg, options, randomFor(player):NextNumber())

	DataService.set(player, { "pity", egg.id }, EggRules.nextPity(egg, opensSincePity, petId))
	-- Room was checked before paying, so this always finds space.
	local uid, isNew = PetService.addPet(player, petId, `Egg:{egg.id}`)
	return { uid = uid or "", pet = petId, isNew = isNew }
end

local function onOpenEgg(player: Player, eggId: string, count: number?)
	local data = DataService.get(player)
	local egg = Eggs[eggId]
	if data == nil or egg == nil then
		return
	end
	local opens = count or 1

	if not data.islandsUnlocked[egg.island] then
		notify(player, "Unlock this island first.")
		return
	end
	if not isNearEgg(player, egg) then
		notify(player, "Walk up to the egg to open it.")
		return
	end
	if not ComplianceService.canOpenEgg(player, egg) then
		notify(player, "This egg isn't available in your region.")
		return
	end
	if not PetService.hasRoom(player, opens) then
		notify(player, "Your pet storage is full. Delete some pets to make room.")
		return
	end
	-- Every egg is priced in Coins (GDD A5, Config/Eggs).
	assert(egg.currency == "coins", `EggService: {egg.id} isn't priced in Coins`)
	local cost = BigNum.fromNumber(egg.cost * opens)
	if not CurrencyService.trySpend(player, "coins", cost, `Egg:{egg.id}`) then
		notify(player, "Not enough Coins.")
		return
	end

	local luck = ComplianceService.luckFor(player, StatService.luckSources(player))
	local hatched: { HatchedPet } = {}
	for _ = 1, opens do
		table.insert(hatched, hatchOne(player, egg, luck))
	end
	DataService.update(player, { "stats", "eggsOpened" }, function(total)
		return total + opens
	end)
	Remotes.fire("HatchResult", player, egg.id, hatched)
	EggService.opened:Fire(player, egg.id, opens)
end

function EggService.start()
	Remotes.on("OpenEgg", onOpenEgg)
	Players.PlayerRemoving:Connect(function(player)
		randoms[player] = nil
	end)
end

return EggService
