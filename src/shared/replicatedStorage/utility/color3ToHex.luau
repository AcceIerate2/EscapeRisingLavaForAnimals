return function(c: Color3)
	local r = math.floor(c.R * 255 + 0.5)
	local g = math.floor(c.G * 255 + 0.5)
	local b = math.floor(c.B * 255 + 0.5)
	return string.format("#%02X%02X%02X", r, g, b)
end
