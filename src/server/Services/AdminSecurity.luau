-- Small guard helpers shared by every admin remote.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Perms = require(script.Parent.AdminPermissions)

local Security = {}
local lastRequest = {} -- [userId] = os.clock()

-- true = allowed. One call per RequestCooldown seconds per user.
function Security.rateLimit(player)
	local now = os.clock()
	local prev = lastRequest[player.UserId]
	if prev and now - prev < Config.Admin.RequestCooldown then
		return false
	end
	lastRequest[player.UserId] = now
	return true
end

function Security.forget(player)
	lastRequest[player.UserId] = nil
end

-- minRole: "Admin" (Admin or Creator) or "Creator". Returns the role or nil.
function Security.role(player, minRole)
	local role = Perms.roleOf(player.UserId)
	if not role then
		return nil
	end
	if minRole == "Creator" and role ~= "Creator" then
		return nil
	end
	return role
end

return Security
