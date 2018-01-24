--[[
	This is just a fancier version of the 'Menu' demo.

	Press the menu button or the space bar to toggle the menu open/closed.

	Try interrupting the animation!
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Root = script.Parent.Parent

local Roact = require(Root.Roact)
local Rodux = require(Root.Rodux)
local RoactRodux = require(Root.RoactRodux)
local RoactMotion = require(Root.RoactMotion)

-- Try tweaking this value!
-- The animation will be consistent no matter the menu's width
local MENU_WIDTH = 400

-- A simple reducer to keep track of state.
local function reducer(state, action)
	state = state or {
		isOpen = true,
	}

	if action.type == "toggle" then
		return {
			isOpen = not state.isOpen,
		}
	end

	return state
end

--[[
	Defines a simple menu that can be given a position and a toggle callback.

	It doesn't have any knowledge of animation!
]]
local function MenuFrame(props)
	local x = props.x
	local t = props.t

	return Roact.createElement("Frame", {
		Size = UDim2.new(0, MENU_WIDTH, 1, 0),

		-- All we have to do to support animation is use a value from our props!
		Position = UDim2.new(0.5, x, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),

		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(t, t, t),
	}, {
		Scale = Roact.createElement("UIScale", {
			Scale = t,
		}),

		Title = Roact.createElement("TextLabel", {
			Text = "Cool Menu",
			Font = Enum.Font.SourceSansBold,
			TextSize = 46,
			Size = UDim2.new(1, 0, 0, 50),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.new(0, 0, 0),
		})
	})
end

--[[
	A wrapper for MenuFrame (above) that animates open/closed.
]]
local function Menu(props)
	local isOpen = props.isOpen

	local t = isOpen and 1 or 0
	local x = isOpen and 0 or -MENU_WIDTH

	local targetX
	local targetT
	if isOpen then
		targetX = RoactMotion.spring(x, 170, 13)
		targetT = RoactMotion.spring(t, 170, 13)
	else
		targetX = RoactMotion.spring(x)
		targetT = RoactMotion.spring(t)
	end

	-- SimpleMotion is a component that animates a single child.
	-- Pass values into the 'style' prop to have RoactMotion manage them!
	return Roact.createElement(RoactMotion.SimpleMotion, {
		style = {
			x = targetX,
			t = targetT,
		},
		render = function(values)
			-- To use the values, we just pass in a function to SimpleMotion.
			-- Then, we use the properties listed on 'values' in our component!

			return Roact.createElement(MenuFrame, {
				x = values.x,
				t = values.t,
			})
		end,
	})
end

-- Connect to the store so that we can toggle the menu
Menu = RoactRodux.connect(function(store)
	local state = store:GetState()

	return {
		isOpen = state.isOpen,
		onToggle = function()
			store:Dispatch({
				type = "toggle",
			})
		end,
	}
end)(Menu)

-- Wrap everything into a ScreenGui
local function App(props)
	return Roact.createElement("ScreenGui", nil, {
		Menu = Roact.createElement(Menu),
	})
end

return function()
	local store = Rodux.Store.new(reducer)

	-- Connect to user input so that we can use the spacebar!
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Space then
				store:Dispatch({
					type = "toggle",
				})
			elseif input.KeyCode == Enum.KeyCode.F then
				-- Bonus!
				-- This is a hack that lets you press F to toggle slow motion.

				local Config = require(script.Parent.Parent.RoactMotion.Config)

				if Config.TIME_FACTOR < 1 then
					Config.TIME_FACTOR = 1
				else
					Config.TIME_FACTOR = 0.2
				end
			end
		end
	end)

	-- Render the first frame of our app, connected to the store.
	local app = Roact.createElement(RoactRodux.StoreProvider, {
		store = store,
	}, {
		App = Roact.createElement(App),
	})

	Roact.reify(app, Players.LocalPlayer.PlayerGui, "RoactMotion Menu Demo")
end