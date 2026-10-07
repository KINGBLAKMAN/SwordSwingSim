--!strict
-- useViewportScale: the UIScale for the current screen size, updating when
-- the window resizes or a phone rotates. See ScaleMath for the rule.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local ScaleMath = require(script.Parent.Parent.ScaleMath)

local function readScale(): number
	local camera = Workspace.CurrentCamera
	if not camera then
		return UI.SCALE.MIN
	end
	local viewport = camera.ViewportSize
	return ScaleMath.scaleFor(viewport.X, viewport.Y, UI.SCALE)
end

local function useViewportScale(): number
	local scale, setScale = React.useState(readScale)

	React.useEffect(function()
		local viewportConnection: RBXScriptConnection? = nil

		local function watchCamera()
			if viewportConnection then
				viewportConnection:Disconnect()
				viewportConnection = nil
			end
			local camera = Workspace.CurrentCamera
			if camera then
				viewportConnection = camera
					:GetPropertyChangedSignal("ViewportSize")
					:Connect(function()
						setScale(readScale())
					end)
			end
			setScale(readScale())
		end

		-- The camera object can be replaced (rare, but scripts can do it).
		local cameraConnection = Workspace:GetPropertyChangedSignal("CurrentCamera")
			:Connect(watchCamera)
		watchCamera()

		return function()
			cameraConnection:Disconnect()
			if viewportConnection then
				viewportConnection:Disconnect()
			end
		end
	end, {})

	return scale
end

return useViewportScale
