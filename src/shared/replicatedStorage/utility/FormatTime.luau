local function Format(Int)
	return string.format("%02i", Int)
end
return function(Seconds, MinuteFormat: boolean)
	local Minutes = (Seconds - Seconds % 60) / 60
	Seconds = Seconds - Minutes * 60
	local Hours = (Minutes - Minutes % 60) / 60
	Minutes = Minutes - Hours * 60
	if MinuteFormat then
		return Format(Minutes) .. ":" .. Format(Seconds)
	end
	return Format(Hours) .. ":" .. Format(Minutes) .. ":" .. Format(Seconds)
end
