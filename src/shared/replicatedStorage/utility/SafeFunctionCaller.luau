local TypeCheck = require(script.Parent.TypeCheck)

-- Configuration
local MaxRetries = 3

return function(callback, ...): (boolean, ...any)
	if TypeCheck["function"](callback) then
		local Args = { ... }
		if Args then
			for _Index = MaxRetries, 1, -1 do
				local Status, Response = pcall(callback, table.unpack(Args))
				if Status then
					return Status, Response
				else
					warn(Response, "-", debug.traceback())
				end
			end
		end
	end
	return false, nil
end
