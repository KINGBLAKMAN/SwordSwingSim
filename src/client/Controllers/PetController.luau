--!strict
-- PetController: sends the Pets screen's requests to the server (GDD A7).
-- The server checks every request (ownership, slots, locks) and the
-- profile update is what changes the screen.

local Remotes = require(script.Parent.Parent.Net.Remotes)

local PetController = {}

function PetController.equip(uid: string)
	Remotes.fire("EquipPet", uid)
end

function PetController.unequip(uid: string)
	Remotes.fire("UnequipPet", uid)
end

function PetController.equipBest()
	Remotes.fire("EquipBest")
end

function PetController.setLocked(uid: string, locked: boolean)
	Remotes.fire("LockPet", uid, locked)
end

function PetController.delete(uids: { string })
	Remotes.fire("DeletePets", uids)
end

return PetController
