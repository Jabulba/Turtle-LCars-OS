os.loadAPI("fuel.lua")
args = { ... }
if args[1] ~= nil then
	assert(type(args[1]) == "number")

	if args[1] > fuel.fuelLimit then
		args[1] = fuel.fuelLimit
	end
else
	args[1] = fuel.fuelLimit
end

fuel.refuelWizard(args[1])
