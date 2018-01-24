--[[
	Demonstrates a box that's attached via two different springs to the mouse.

	On the X axis, the default values from RoactMotion are used.
	On the Y axis, a much bouncier spring is used. It's a happy box.

	The box contains its current position in text.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Root = script.Parent.Parent

local Roact = require(Root.Roact)
local Rodux = require(Root.Rodux)
local RoactRodux = require(Root.RoactRodux)
local RoactMotion = require(Root.RoactMotion)

-- Our state is just two values, X and Y position.
local function reducer(state, action)
	state = state or {0, 0}

	if action.type == "mouse" then
		return action.position
	end

	return state
end

--[[
	This will become our happy box.

	It's just a component that renders at the given position.
]]
local function Box(props)
	local x = props.x
	local y = props.y

	return Roact.createElement("TextLabel", {
		Size = UDim2.new(0, 140, 0, 140),
		Position = UDim2.new(0, props.x, 0, props.y),
		Font = Enum.Font.SourceSans,
		TextSize = 30,
		TextYAlignment = Enum.TextYAlignment.Top,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Text = ("(%d, %d)"):format(x, y),
	})
end

--[[
	This is where all the magic happens for this demo.

	App wraps out Box in a SimpleMotion component and connects to the store for
	mouse information.
]]
local function App(props)
	local targetX = props.x
	local targetY = props.y

	return Roact.createElement("ScreenGui", nil, {
		A = Roact.createElement(RoactMotion.SimpleMotion, {
			style = {
				-- RoactMotion provides a good spring by default for most cases.
				x = RoactMotion.spring(targetX),

				-- We can also pass stiffnes and damping values to make it bouncy!
				-- y = RoactMotion.spring(targetY),
				y = RoactMotion.spring(targetY, 220, 10),
			},
			render = function(values)
				-- We render our component and pass our values right through.

				return Roact.createElement(Box, values)
			end,
		})
	})
end

-- Connect to the store to get our mouse X/Y position
App = RoactRodux.connect(function(store)
	local state = store:GetState()

	return {
		x = state[1],
		y = state[2],
	}
end)(App)

return function()
	local store = Rodux.Store.new(reducer)

	-- Translate mouse movement directly into store dispatches
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			store:Dispatch({
				type = "mouse",
				position = {input.Position.X, input.Position.Y},
			})
		end
	end)

	-- Render the first frame of the app!
	local app = Roact.createElement(RoactRodux.StoreProvider, {
		store = store,
	}, {
		App = Roact.createElement(App),
	})

	Roact.reify(app, Players.LocalPlayer.PlayerGui, "RoactMotion Mouse Demo")
end