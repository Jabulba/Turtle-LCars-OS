os.loadAPI("fuel.lua")
args = { ... }
if args[1] ~= nil then
	args[1] = tonumber(args[1])
	assert(type(args[1]) == "number", "Provided input '" .. args[1] .. "' is not a number!")

	if args[1] > fuel.fuelLimit then
		args[1] = fuel.fuelLimit
	end
else
	args[1] = fuel.fuelLimit
end

fuel.refuelWizard(args[1])
