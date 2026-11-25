-- Shared by the server (authority) and the client (preview + animation).
local Config = require(script.Parent.Config)
local W = Config.World

local ThrowMath = {}

function ThrowMath.maxDistance(strength)
	return math.min(2400, 30 + 3 * strength ^ 0.6)
end

function ThrowMath.slotX(slot)
	return (slot - (W.Slots + 1) / 2) * W.SlotSpacing
end

-- Where a plot's owner stands to throw (ground level).
function ThrowMath.spot(slot)
	return Vector3.new(ThrowMath.slotX(slot), 0, W.ThrowZ)
end

-- Food always flies down the runway; the camera can only steer it a little left/right.
function ThrowMath.aim(look)
	local lateral = math.clamp(look.X, -0.5, 0.5)
	return Vector3.new(lateral, 0, -1).Unit
end

function ThrowMath.target(origin, dir, strength, power)
	local dist = ThrowMath.maxDistance(strength) * math.clamp(power, 0.1, 1)
	return origin + dir * dist, dist
end

-- Distance beyond the start line for a world position.
function ThrowMath.trackDistance(position)
	return W.TrackZ - position.Z
end

-- Farthest zone distance a full-power throw can reach with this much strength.
function ThrowMath.reach(strength)
	return ThrowMath.maxDistance(strength) - (W.ThrowZ - W.TrackZ)
end

-- Strength needed for a full-power throw to reach `trackDist`.
function ThrowMath.strengthFor(trackDist)
	local need = trackDist + (W.ThrowZ - W.TrackZ)
	if need <= 30 then
		return 0
	end
	return math.ceil(((need - 30) / 3) ^ (1 / 0.6))
end

function ThrowMath.flightTime(dist)
	return math.clamp(0.6 + dist / 90, 0.6, 2.2)
end

function ThrowMath.arc(from, to, t, dist)
	local h = math.clamp(dist * 0.35, 6, 60)
	return from:Lerp(to, t) + Vector3.new(0, 4 * h * t * (1 - t), 0)
end

return ThrowMath
