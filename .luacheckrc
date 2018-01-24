-- Incomplete definition of Roblox globals
stds.roblox = {
	globals = {
		"game"
	},
	read_globals = {
		-- Roblox globals
		"script",

		-- Extra functions
		"tick", "warn", "spawn",
		"wait", "settings",

		-- Types
		"Vector2", "Vector3",
		"Color3",
		"UDim", "UDim2",
		"Rect",
		"CFrame",
		"Enum",
		"Instance",
	}
}

ignore = {
	"212", -- unused arguments
}

std = "lua51+roblox"