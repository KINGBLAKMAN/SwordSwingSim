--!strict
-- BossBar: the boss's name and HP along the bottom of the screen while the
-- player is fighting a Boss-tier enemy (GDD A9).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemySpawning = require(ReplicatedStorage.Shared.Config.EnemySpawning)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local EnemyController = require(script.Parent.Parent.Parent.Controllers.EnemyController)
local ProgressBar = require(script.Parent.Parent.Components.ProgressBar)
local useCombatTarget = require(script.Parent.Parent.Hooks.useCombatTarget)

local e = React.createElement

local ATTRIBUTES = EnemySpawning.ATTRIBUTES
local BOSS_TIER = "Boss"

-- The target's HP, re-rendering whenever it changes.
local function useHp(model: Model?): (number, number)
	local hp, setHp = React.useState(0)
	local maxHp, setMaxHp = React.useState(1)

	React.useEffect(function(): (() -> ())?
		if model == nil then
			return nil
		end
		local function read()
			local current, max = EnemyController.hp(model)
			setHp(current)
			setMaxHp(max)
		end
		read()
		local connection = model:GetAttributeChangedSignal(ATTRIBUTES.hp):Connect(read)
		return function()
			connection:Disconnect()
		end
	end, { model })

	return hp, maxHp
end

local function BossBar()
	local target = useCombatTarget()
	local isBoss = target ~= nil and target:GetAttribute(ATTRIBUTES.tier) == BOSS_TIER
	local hp, maxHp = useHp(if isBoss then target else nil)

	if not isBoss or target == nil then
		return nil
	end

	local size = UI.BOSS_BAR.SIZE
	local name = tostring(target:GetAttribute(ATTRIBUTES.name))
	return e(ProgressBar, {
		fraction = hp / maxHp,
		label = `{name}   {Format.number(hp)} / {Format.number(maxHp)}`,
		fillColor = UI.ENEMY_BILLBOARD.HP_FILL,
		size = UDim2.fromOffset(size.X, size.Y),
		position = UDim2.new(0.5, 0, 1, -UI.BOSS_BAR.BOTTOM_OFFSET),
		anchorPoint = Vector2.new(0.5, 1),
	})
end

return BossBar
