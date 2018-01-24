--[[
	Implements motion for a single set of values and a single child object.

	Example:

		Roact.createElement(RoactMotion.SimpleMotion, {
			style = {
				x = RoactMotion.spring(10),
			},
			render = function(values)
				return Roact.createElement(MyThing, {
					x = x,
				})
			end
		})

	When the value passed to `RoactMotion.spring` changes, the rendered children
	will animate to the new value.
]]

local RunService = game:GetService("RunService")

local Roact = require(script.Parent.Parent.Roact)

local stepSpring = require(script.Parent.stepSpring)
local merge = require(script.Parent.merge)
local Config = require(script.Parent.Config)
local MotionType = require(script.Parent.MotionType)
local MotionSpecifier = require(script.Parent.MotionSpecifier)

local SimpleMotion = Roact.Component:extend("SimpleMotion")

function SimpleMotion:init()
	-- Build up a list of initial values to use
	-- First, we pull from 'style', which is a dictionary of specifiers
	-- We also initialize starting velocities for all motion specifiers here
	local startValues = {}
	local velocities = {}
	for key, value in pairs(self.props.style) do
		velocities[key] = 0
		startValues[key] = MotionSpecifier.extractValue(value)
	end

	-- ...and then we pull from defaultStyle, if it's given.
	-- This is just a dictionary of numbers
	if self.props.defaultStyle then
		for key, value in pairs(self.props.defaultStyle) do
			startValues[key] = value
		end
	end

	self.resting = false
	self.accumulator = 0
	self.state = {
		values = startValues,
		velocities = velocities,
		targetSpecifiers = self.props.style,
	}
end

function SimpleMotion:render()
	return self.props.render(self.state.values)
end

function SimpleMotion:didMount()
	self.connection = RunService.RenderStepped:Connect(function(dt)
		if self.resting then
			return
		end

		local newValues = merge(self.state.values)
		local newVelocities = merge(self.state.velocities)

		-- We use a fixed update rate to make sure our springs are predictable.
		self.accumulator = self.accumulator + dt % Config.MAX_ACCUMULATION

		while self.accumulator >= Config.UPDATE_RATE do
			self.accumulator = self.accumulator - Config.UPDATE_RATE

			-- We should only rest if all values have almost reached their goals
			local shouldRest = true

			for key, targetSpecifier in pairs(self.state.targetSpecifiers) do
				local targetType = MotionSpecifier.getType(targetSpecifier)

				local newPosition, newVelocity

				if targetType == MotionType.Instant then
					newPosition = targetSpecifier
					newVelocity = 0
				elseif targetType == MotionType.Spring then
					newPosition, newVelocity = stepSpring(
						Config.UPDATE_RATE * Config.TIME_FACTOR,
						newValues[key],
						newVelocities[key],
						targetSpecifier.value,
						targetSpecifier.stiffness,
						targetSpecifier.damping,
						Config.SPRING_PRECISION
					)
				else
					error(("Unsupported MotionType %q"):format(targetType))
				end

				newValues[key] = newPosition
				newVelocities[key] = newVelocity

				-- Because 'stepSpring' does rounding for us, we don't have to
				-- worry about floating point errors.
				local realTargetValue = MotionSpecifier.extractValue(targetSpecifier)
				if newPosition ~= realTargetValue or newVelocity ~= 0 then
					shouldRest = false
				end
			end

			if shouldRest then
				self.resting = true

				break
			end
		end

		self:setState({
			values = newValues,
			velocities = newVelocities,
		})
	end)
end

function SimpleMotion:willUnmount()
	self.connection:Disconnect()
end

function SimpleMotion:willUpdate(newProps)
	if newProps == self.props then
		return
	end

	self:setState({
		targetSpecifiers = newProps.style,
	})
	self.resting = false
end

return SimpleMotion