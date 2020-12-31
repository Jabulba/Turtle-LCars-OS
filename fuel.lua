os.loadAPI("log.lua")

fuelLimit = turtle.getFuelLimit()
fuelRequired = turtle.getFuelLevel() ~= "unlimited"
hasBucket = false
bucketSlot = -1

function getFuelLevel()
	local fuelLevel = turtle.getFuelLevel()
	if fuelLevel == "unlimited" then -- No fuel required
		return math.huge
	end

	return fuelLevel
end

function checkForBucket()
	if not fuelRequired then
		log.info("Skipping bucket detection, turtle requires no fuel")
		return
	end

	log.info("Searching inventory for Bucket")
	local unlocked = false
	repeat
		for slot = 1, 16, 1 do
			log.trace("Searching slot " .. slot)
			local itemData = turtle.getItemDetail(slot)
			if itemData then
				log.trace("Slot " .. slot .. " has item: " .. itemData.name)
				if itemData.name == "minecraft:bucket" then
					log.info("Bucket found in slot " .. slot)
					bucketSlot = slot
					hasBucket = true
					break
				elseif itemData.name == "minecraft:lava_bucket" then
					log.info("Lava bucket found in slot " .. slot)
					bucketSlot = slot
					hasBucket = true
					log.info("Consuming lava from bucket")
					turtle.select(bucketSlot)
					turtle.refuel()
					break
				end
			end
		end

		if hasBucket then
			log.info("Turtle will use lava to automatically refuel during mining")
			break
		else
			print("Please give me a bucket so I can refuel using lava found along the way!")
			print("press [ENTER] to disable refueling")

			repeat
				local event, param1 = os.pullEvent()
				if event == "key" and param1 == keys.enter then
					unlocked = true
					break
				elseif event == "turtle_inventory" then
					break
				end
			until false
		end
	until unlocked

	return true
end

function refuelWizard(fuelEstimate)
	if not fuelRequired then
		log.info("Skipping refuel wizard, turtle requires no fuel")
		-- No fuel is required
		return
	end

	log.info("Checking for fuel availability")
	local unlocked = false
	local storageState = { "nil", "nil", "nil", "nil", "nil", "nil", "nil", "nil", "nil", "nil", "nil", "nil", "nil", "nil", "nil", "nil", }
	repeat
		-- Save a snapshot of the inventory and consume any fuel found
		for i = 1, 16, 1 do
			log.trace("Searching for fuel in slot " .. i)
			local slotData = turtle.getItemDetail(i)
			local slotDataName = "nil"
			if slotData then
				slotDataName = slotData.name
			end

			log.trace(tostring(slotDataName ~= storageState[i]) .. " = " .. slotDataName .. " ~= " .. storageState[i])
			if slotDataName ~= storageState[i] then
				-- Slot content changed from last check
				storageState[i] = slotDataName

				log.trace("Slot " .. i .. " changed, updating to: " .. slotDataName)

				if storageState[i] ~= "nil" then
					turtle.select(i)
					if turtle.refuel(0) then
						-- If item in slot is a valid fuel item, refuel!
						log.info("Using item in slot " .. i .. " to refuel")
						turtle.select(i)
						turtle.refuel()
					else
						log.trace("Slot " .. i .. " is not a valid fuel, ignoring")
					end
				end
			end
		end

		-- Repeat until enougth fuel is received or user skips refuel step
		local fuelLevel = getFuelLevel()
		if fuelLevel < fuelEstimate then
			print()
			print("Turtle is low on fuel!")
			print()
			print("Recommended:\t" .. fuelEstimate)
			print("Current:\t\t\t\t\t" .. fuelLevel)
			print("Missing:\t\t\t\t\t" .. (fuelEstimate - fuelLevel))
			print()
			print()
			print("Place fuel in inventory or")
			print("press [ENTER] to finish...")
			repeat
				local event, key = os.pullEvent()
				if event == "key" then
					if key == keys.enter then
						unlocked = true
						break
					end
				elseif event == "turtle_inventory" then
					break
				end
			until false
		else
			unlocked = true
		end
	until unlocked
	log.info("Fuel check complete")

	return true
end
