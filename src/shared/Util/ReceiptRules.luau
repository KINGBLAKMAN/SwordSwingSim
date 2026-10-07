--!strict
-- ReceiptRules: what ProcessReceipt does with a receipt (TDD B10). Pure,
-- so Lune can test that a purchase is never granted twice.
--
--   no loaded profile         -> NotProcessedYet (Roblox retries later)
--   purchase id already saved -> PurchaseGranted (a retry; grant nothing)
--   no handler for the id     -> NotProcessedYet and an alert, never granted
--   otherwise                 -> grant, record the id, save, PurchaseGranted

export type Decision = "NoProfile" | "AlreadyGranted" | "UnknownProduct" | "Grant"

local ReceiptRules = {}

function ReceiptRules.decide(
	receipts: { [string]: number }?,
	purchaseId: string,
	hasHandler: boolean
): Decision
	if receipts == nil then
		return "NoProfile"
	elseif receipts[purchaseId] ~= nil then
		return "AlreadyGranted"
	elseif not hasHandler then
		return "UnknownProduct"
	end
	return "Grant"
end

-- Receipts with this purchase recorded, keeping only the newest `keep`.
-- The purchase just recorded is always kept, so its retry is never granted
-- again.
function ReceiptRules.record(
	receipts: { [string]: number },
	purchaseId: string,
	now: number,
	keep: number
): { [string]: number }
	local updated = table.clone(receipts)
	updated[purchaseId] = now

	local older = {}
	for id in updated do
		if id ~= purchaseId then
			table.insert(older, id)
		end
	end
	-- Oldest first; ties by id so the trim is the same every time.
	table.sort(older, function(a, b)
		if updated[a] ~= updated[b] then
			return updated[a] < updated[b]
		end
		return a < b
	end)
	for index = 1, #older - (keep - 1) do
		updated[older[index]] = nil
	end
	return updated
end

return ReceiptRules
