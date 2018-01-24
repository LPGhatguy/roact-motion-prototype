local MotionSpecifier = require(script.MotionSpecifier)
local SimpleMotion = require(script.SimpleMotion)

local RoactMotion = {}

RoactMotion.spring = MotionSpecifier.spring
RoactMotion.SimpleMotion = SimpleMotion

return RoactMotion