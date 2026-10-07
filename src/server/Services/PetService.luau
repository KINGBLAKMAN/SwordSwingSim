--!strict
-- PetService: owns every player's pets (GDD A7, TDD B2).
--
-- Pets are records in profile.pets by uid; profile.equippedPets lists the
-- equipped uids. Every change goes through here, so StatService hears
-- about it (the pet multiplier) and other players see the right pets
-- following (the EQUIPPED_ATTRIBUTE player attribute).
--
-- Remotes: EquipPet, UnequipPet, EquipBest, DeletePets and LockPet. Each
-- checks the player owns the pets; locked or equipped pets can't be
-- deleted.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EggRules = require(ReplicatedStorage.Shared.Util.EggRules)
local PetMath = require(ReplicatedStorage.Shared.Util.PetMath)
local PetRules = require(ReplicatedStorage.Shared.Config.PetRules)
local Pets = require(ReplicatedStorage.Shared.Config.Pets)
local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Remotes = require(script.Parent.Parent.Net.Remotes)
local DataService = require(script.Parent.DataService)
local StatService = require(script.Parent.StatService)

local PetService = {}

-- Fired with (player: Player, petCount: number) after the equipped pets
-- change, with how many are equipped now.
PetService.equippedChanged = Signal.new()

local function notify(player: Player, message: string)
	Remotes.fire("Notify", player, message)
end

-- Tells StatService and every client the equipped pets changed.
local function equippedPetsChanged(player: Player)
	local data = DataService.get(player)
	if data == nil then
		return
	end
	StatService.invalidate(player)
	local ids = {}
	for _, uid in data.equippedPets do
		local pet = data.pets[uid]
		if pet then
			table.insert(ids, pet.id)
		end
	end
	player:SetAttribute(PetRules.EQUIPPED_ATTRIBUTE, table.concat(ids, ","))
	PetService.equippedChanged:Fire(player, #data.equippedPets)
end

local function setEquipped(player: Player, uids: { string })
	DataService.set(player, { "equippedPets" }, uids)
	equippedPetsChanged(player)
end

-- True if the player has room for `count` more pets.
function PetService.hasRoom(player: Player, count: number): boolean
	local data = DataService.get(player)
	return data ~= nil and PetMath.count(data.pets) + count <= data.petStorageCap
end

-- Gives the player a new pet. Returns its uid and whether it's the first of
-- its kind they've owned, or nil if their storage is full.
function PetService.addPet(player: Player, petId: string, source: string): (string?, boolean)
	assert(Pets[petId], `PetService.addPet: unknown pet "{petId}"`)
	local data = DataService.get(player)
	if data == nil or not PetService.hasRoom(player, 1) then
		return nil, false
	end
	local seen = data.index.pets[petId]
	local isNew = seen == nil or seen.Normal ~= true

	local uid = HttpService:GenerateGUID(false)
	DataService.set(player, { "pets", uid }, EggRules.newPet(uid, petId, source, os.time()))
	DataService.update(player, { "index", "pets", petId }, function(variants)
		local updated = variants or {}
		updated.Normal = true
		return updated
	end)
	return uid, isNew
end

local function onEquipPet(player: Player, uid: string)
	local data = DataService.get(player)
	if data == nil or data.pets[uid] == nil or table.find(data.equippedPets, uid) then
		return
	end
	if #data.equippedPets >= StatService.equipSlots(player) then
		notify(player, "All pet slots are full. Unequip a pet first.")
		return
	end
	local equipped = table.clone(data.equippedPets)
	table.insert(equipped, uid)
	setEquipped(player, equipped)
end

local function onUnequipPet(player: Player, uid: string)
	local data = DataService.get(player)
	local index = data and table.find(data.equippedPets, uid)
	if data == nil or index == nil then
		return
	end
	local equipped = table.clone(data.equippedPets)
	table.remove(equipped, index)
	setEquipped(player, equipped)
end

local function onEquipBest(player: Player)
	local data = DataService.get(player)
	if data then
		setEquipped(player, PetMath.bestPets(data.pets, StatService.equipSlots(player)))
	end
end

local function onDeletePets(player: Player, uids: { string })
	local data = DataService.get(player)
	if data == nil then
		return
	end
	-- Check every pet first, so a bad uid deletes nothing.
	for _, uid in uids do
		if PetMath.deleteBlocker(data.pets[uid], data.equippedPets) then
			notify(player, "Locked and equipped pets can't be deleted.")
			return
		end
	end
	for _, uid in uids do
		DataService.set(player, { "pets", uid }, nil)
	end
end

local function onLockPet(player: Player, uid: string, locked: boolean)
	local data = DataService.get(player)
	if data and data.pets[uid] then
		DataService.set(player, { "pets", uid, "locked" }, locked)
	end
end

local function onProfileLoaded(player: Player, data: ProfileTypes.Profile)
	-- Drop equipped uids whose pet is gone (e.g. a rollback), so slots and
	-- the multiplier only count real pets.
	local kept = {}
	for _, uid in data.equippedPets do
		if data.pets[uid] then
			table.insert(kept, uid)
		end
	end
	if #kept ~= #data.equippedPets then
		DataService.set(player, { "equippedPets" }, kept)
	end
	player:SetAttribute(PetRules.SLOTS_ATTRIBUTE, StatService.equipSlots(player))
	equippedPetsChanged(player)
end

function PetService.start()
	Remotes.on("EquipPet", onEquipPet)
	Remotes.on("UnequipPet", onUnequipPet)
	Remotes.on("EquipBest", onEquipBest)
	Remotes.on("DeletePets", onDeletePets)
	Remotes.on("LockPet", onLockPet)
	DataService.onLoaded(onProfileLoaded)
end

return PetService
