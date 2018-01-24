--[[
	Demonstrates a simple menu that slides out from the left.

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

local PAGE_COUNT = 4

local function join(...)
	local new = {}

	for i = 1, select("#", ...) do
		for key, value in pairs(select(i, ...)) do
			new[key] = value
		end
	end

	return new
end

local function round(v)
	local fractional = v - math.floor(v)

	if fractional >= 0.5 then
		return math.ceil(v)
	else
		return math.floor(v)
	end
end

-- A simple reducer to keep track of state.
local function reducer(state, action)
	state = state or {
		currentPage = 1,
		fingerOffset = Vector2.new(0, 0),
		pageSize = Vector2.new(0, 0),
	}

	if action.type == "setPage" then
		return join(state, {
			currentPage = action.page,
		})
	elseif action.type == "setFingerOffset" then
		return join(state, {
			fingerOffset = action.value,
		})
	elseif action.type == "setPageSize" then
		return join(state, {
			pageSize = action.value,
		})
	end

	return state
end

local function setPage(page)
	return {
		type = "setPage",
		page = page,
	}
end

local function setFingerOffset(value)
	return {
		type = "setFingerOffset",
		value = value,
	}
end

local function setPageSize(value)
	return {
		type = "setPageSize",
		value = value,
	}
end

local function Page(props)
	local title = props.title
	local color = props.color
	local layoutOrder = props.layoutOrder
	local pageSize = props.pageSize

	return Roact.createElement("TextLabel", {
		Size = UDim2.new(0, pageSize.X, 0, pageSize.Y),
		BorderSizePixel = 0,
		BackgroundColor3 = color,
		TextSize = 30,
		Text = title,
		LayoutOrder = layoutOrder,
	})
end

Page = RoactRodux.connect(function(store)
	return {
		pageSize = store:GetState().pageSize,
	}
end)(Page)

local function PageContainer(props)
	local currentPage = props.currentPage
	local offset = props.offset
	local pageSize = props.pageSize
	local pages = props[Roact.Children]

	local pageCount = 0
	for _ in pairs(pages) do
		pageCount = pageCount + 1
	end

	local children = join(pages, {
		-- I don't think this name will conflict with arguments. Still sucks.
		["$Layout"] = Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local x = -pageSize.X * (currentPage - 1) + offset.X

	return Roact.createElement(RoactMotion.SimpleMotion, {
		style = {
			x = RoactMotion.spring(x, 300, 36),
		},
		render = function(values)
			return Roact.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0, pageSize.X * pageCount, 0, pageSize.Y),
				Position = UDim2.new(0, values.x, 0, 0),
			}, children)
		end,
	})
end

PageContainer = RoactRodux.connect(function(store)
	return {
		pageSize = store:GetState().pageSize,
	}
end)(PageContainer)

local function PageView(props)
	local currentPage = props.currentPage
	local offset = props.offset
	local pages = props[Roact.Children]

	return Roact.createElement("Frame", {
		BackgroundTransparency = 0,
		ClipsDescendants = false,
		Size = UDim2.new(1, 0, 1, 0),

		-- For testing in studio
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
	}, {
		Pages = Roact.createElement(PageContainer, {
			currentPage = currentPage,
			offset = offset,
		}, pages),

		Left = Roact.createElement("Frame", {
			Size = UDim2.new(0, 4, 1, 0),
			Position = UDim2.new(0, -4, 0, 0),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(0, 0, 1),
			ZIndex = 2,
		}),

		Right = Roact.createElement("Frame", {
			Size = UDim2.new(0, 4, 1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(0, 0, 1),
			ZIndex = 2,
		}),
	})
end

local PrimaryPageView = RoactRodux.connect(function(store)
	local state = store:GetState()

	return {
		currentPage = state.currentPage,
		offset = state.fingerOffset,
		pageSize = state.pageSize,
	}
end)(PageView)

-- Wrap everything into a ScreenGui
local function App(props)
	return Roact.createElement("ScreenGui", nil, {
		Pages = Roact.createElement(PrimaryPageView, nil, {
			A = Roact.createElement(Page, {
				layoutOrder = 0,
				title = "Page A!",
				color = Color3.new(1, 1, 1),
			}),

			B = Roact.createElement(Page, {
				layoutOrder = 1,
				title = "Page B!",
				color = Color3.new(1, 0.3, 0.3),
			}),

			C = Roact.createElement(Page, {
				layoutOrder = 2,
				title = "Page C!",
				color = Color3.new(0.3, 1, 0.3),
			}),

			D = Roact.createElement(Page, {
				layoutOrder = 3,
				title = "Page D!",
				color = Color3.new(0.3, 0.3, 1),
			}),
		}),
	})
end

local function isCursor(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or
		input.UserInputType == Enum.UserInputType.Touch
end

return function()
	local store = Rodux.Store.new(reducer)

	-- Swipe controls
	local origin
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if isCursor(input) then
			origin = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if isCursor(input) then
			local position = Vector2.new(input.Position.X, input.Position.Y)

			local deltaX = position.X - origin.X
			local pageSize = store:GetState().pageSize
			local movement = round(deltaX / pageSize.X)

			if movement ~= 0 then
				local currentPage = store:GetState().currentPage
				local targetPage = math.max(1, math.min(PAGE_COUNT, currentPage - movement))

				store:Dispatch(setPage(targetPage))
			end

			origin = nil
			store:Dispatch(setFingerOffset(Vector2.new(0, 0)))
		end
	end)

	UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		-- Finger/click is not down
		if not origin then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement or
			input.UserInputType == Enum.UserInputType.Touch then
			local position = Vector2.new(input.Position.X, input.Position.Y)

			store:Dispatch(setFingerOffset(position - origin))
		end
	end)

	-- Keyboard controls
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		local currentPage = store:GetState().currentPage

		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Right then
				store:Dispatch(setPage(currentPage + 1))
			elseif input.KeyCode == Enum.KeyCode.Left then
				store:Dispatch(setPage(currentPage - 1))
			end
		end
	end)

	local gui = Instance.new("ScreenGui")
	gui.Parent = Players.LocalPlayer.PlayerGui

	store:Dispatch(setPageSize(gui.AbsoluteSize))
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		store:Dispatch(setPageSize(gui.AbsoluteSize))
	end)

	-- Render the first frame of our app, connected to the store.
	local app = Roact.createElement(RoactRodux.StoreProvider, {
		store = store,
	}, {
		App = Roact.createElement(App),
	})

	Roact.reify(app, Players.LocalPlayer.PlayerGui, "RoactMotion Pages Demo")
end