-- Persistent action log. Category "action" = give-* commands, "permission" = grant/revoke history.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local store = DataStoreService:GetDataStore("TFFA_AdminLog_v1")
local KEY = "Log"

local AdminLog = {}
local memory = {} -- this server's entries, kept as a fallback when the store is unavailable

function AdminLog.add(entry)
	entry.t = os.time()
	table.insert(memory, entry)
	task.spawn(function()
		local ok, err = pcall(function()
			store:UpdateAsync(KEY, function(old)
				old = typeof(old) == "table" and old or {}
				table.insert(old, entry)
				while #old > Config.Admin.LogLimit do
					table.remove(old, 1)
				end
				return old
			end)
		end)
		if not ok then
			warn("[AdminLog] persist failed: " .. tostring(err))
		end
	end)
end

-- Newest first, filtered by category.
function AdminLog.list(category)
	local ok, stored = pcall(function()
		return store:GetAsync(KEY)
	end)
	local source = (ok and typeof(stored) == "table") and stored or memory
	local out = {}
	for i = #source, 1, -1 do
		local e = source[i]
		if e.category == category then
			table.insert(out, e)
			if #out >= 100 then
				break
			end
		end
	end
	return out
end

return AdminLog
