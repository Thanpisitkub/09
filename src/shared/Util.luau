local Util = {}

function Util.isFinite(x)
	return typeof(x) == "number" and x == x and x ~= math.huge and x ~= -math.huge
end

-- Positive whole number within [1, max], or nil.
function Util.amount(x, max)
	if not Util.isFinite(x) then
		return nil
	end
	x = math.floor(x)
	if x < 1 or x > max then
		return nil
	end
	return x
end

function Util.fmt(n)
	n = Util.isFinite(n) and n or 0
	if n < 1000 then
		return tostring(math.floor(n))
	end
	local suffix = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
	local i = math.min(math.floor(math.log10(n) / 3), #suffix - 1)
	local s = string.format("%.2f", n / 10 ^ (i * 3))
	s = (s:gsub("0+$", ""))
	s = (s:gsub("%.$", ""))
	return s .. suffix[i + 1]
end

function Util.commas(n)
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

return Util
