-- Turtle Quarry by Jabulba

-- Global Variables:
-- integer  width
-- integer  length
-- integer  height
-- string[] ignoredBlocks
-- integer  enderChestSlot
-- boolean  hasEnderChest
-- integer  bucketSlot
-- boolean  hasBucket

os.loadAPI("log.lua")
os.loadAPI("fuel.lua")

boolToInt = { [true] = 1, [false] = 0 }
directionMapping = {
	["up"] = { ["detect"] = turtle.detectUp, ["dig"] = turtle.digUp, ["place"] = turtle.placeUp, ["inspect"] = turtle.inspectUp, ["drop"] = turtle.dropUp, ["suck"] = turtle.suckUp },
	["down"] = { ["detect"] = turtle.detectDown, ["dig"] = turtle.digDown, ["place"] = turtle.placeDown, ["inspect"] = turtle.inspectDown, ["drop"] = turtle.dropDown, ["suck"] = turtle.suckDown },
	["forward"] = { ["detect"] = turtle.detect, ["dig"] = turtle.dig, ["place"] = turtle.place, ["inspect"] = turtle.inspect, ["drop"] = turtle.drop, ["suck"] = turtle.suck }
}

local function emptyInventory(directionFunc)
	directionFunc = directionFunc or directionMapping["forward"]

	if hasEnderChest then
		while directionFunc["detect"]() do
			local success, err = directionFunc["dig"]()
			if not success and err == "Unbreakable block detected" then
				-- TODO: backtrack?
				error(err)
			end
			os.sleep(0.2)
		end

		turtle.select(enderChestSlot)
		while not directionFunc["place"]() do
			turtle.attackUp()
			turtle.attack()
			turtle.attackDown()
			os.sleep(0.5)
		end

		do
			local success, err = directionFunc["inspect"]()
			if not success then
				print("Error: I placed the EnderChest but it's not there!")
				checkForEnderChest()
				return
			end
		end

		for i = 1, 16, 1 do
			local itemData = turtle.getItemDetail(i)
			if itemData ~= nil and i ~= fuel.bucketSlot then
				turtle.select(i)
				directionFunc["drop"]()
			end
		end

		turtle.select(enderChestSlot)
		repeat
			local success, err = directionFunc["dig"]()
			if not success then
				if err == "Nothing to dig here" then
					print("Failed to pickup EnderChest! Has it been stolen?")
					checkForEnderChest()
				else
					print("Failed to pickup EnderChest, trying again!")
				end
			end
		until success
	end
end

local function checkInventory(directionFunc)
	local fullSlots = 0
	for i = 1, 16, 1 do
		fullSlots = fullSlots + boolToInt[turtle.getItemCount(i) > 0]
	end

	if fullSlots > 14 then
		emptyInventory(directionFunc)
	end
end

function loadIgnoredBlocks()
	ignoredBlocks = {}
	log.info("Loading ignored blocks IDs")
	local ignoredBlocksFileName = "quarry.ignoredblocks"
	if not fs.exists(ignoredBlocksFileName) then
		log.info("quarry.ignoredblocks not found, creating a new one with default IDs. You can add more IDs to this file, one ID per line!")
		local ignoredBlocksFile = fs.open(ignoredBlocksFileName, "w")

		ignoredBlocksFile.writeLine("minecraft:air")
		ignoredBlocksFile.writeLine("minecraft:andesite")
		ignoredBlocksFile.writeLine("minecraft:bedrock")
		ignoredBlocksFile.writeLine("minecraft:blackstone")
		ignoredBlocksFile.writeLine("minecraft:cobblestone")
		ignoredBlocksFile.writeLine("minecraft:diorite")
		ignoredBlocksFile.writeLine("minecraft:dirt")
		ignoredBlocksFile.writeLine("minecraft:coarse_dirt")
		ignoredBlocksFile.writeLine("minecraft:granite")
		ignoredBlocksFile.writeLine("minecraft:grass")
		ignoredBlocksFile.writeLine("minecraft:grass_block")
		ignoredBlocksFile.writeLine("minecraft:grass_path")
		ignoredBlocksFile.writeLine("minecraft:gravel")
		ignoredBlocksFile.writeLine("minecraft:ice")
		ignoredBlocksFile.writeLine("minecraft:packed_ice")
		ignoredBlocksFile.writeLine("minecraft:blue_ice")
		ignoredBlocksFile.writeLine("minecraft:ladder")
		ignoredBlocksFile.writeLine("minecraft:netherrack")
		ignoredBlocksFile.writeLine("minecraft:polished_blackstone_bricks")
		ignoredBlocksFile.writeLine("minecraft:sand")
		ignoredBlocksFile.writeLine("minecraft:sandstone")
		ignoredBlocksFile.writeLine("minecraft:seagrass")
		ignoredBlocksFile.writeLine("minecraft:snow")
		ignoredBlocksFile.writeLine("minecraft:snow_layer")
		ignoredBlocksFile.writeLine("minecraft:stone")
		ignoredBlocksFile.writeLine("minecraft:tall_grass")
		ignoredBlocksFile.writeLine("minecraft:torch")
		ignoredBlocksFile.writeLine("betterend:bluestone")
		ignoredBlocksFile.writeLine("blockus:bluestone")
		ignoredBlocksFile.writeLine("blockus:limestone")
		ignoredBlocksFile.writeLine("blockus:marble")
		ignoredBlocksFile.writeLine("byg:beach_grass")
		ignoredBlocksFile.writeLine("byg:brimstone")
		ignoredBlocksFile.writeLine("byg:ether_grass")
		ignoredBlocksFile.writeLine("byg:nyliumd_soul_soil")
		ignoredBlocksFile.writeLine("byg:meadow_dirt")
		ignoredBlocksFile.writeLine("byg:meadow_grass_block")
		ignoredBlocksFile.writeLine("byg:prairie_grass")
		ignoredBlocksFile.writeLine("byg:rocky_stone")
		ignoredBlocksFile.writeLine("byg:scorched_grass")
		ignoredBlocksFile.writeLine("byg:short_beach_grass")
		ignoredBlocksFile.writeLine("byg:short_grass")
		ignoredBlocksFile.writeLine("byg:tall_prairie_grass")
		ignoredBlocksFile.writeLine("byg:weed_grass")
		ignoredBlocksFile.writeLine("byg:whaling_grass")
		ignoredBlocksFile.writeLine("byg:wilted_grass")
		ignoredBlocksFile.writeLine("byg:winter_grass")
		ignoredBlocksFile.writeLine("wild_explorer:blunite")
		ignoredBlocksFile.writeLine("wild_explorer:carbonite")
		ignoredBlocksFile.writeLine("terrestria:andisol_grass_path")
		ignoredBlocksFile.writeLine("terrestria:basalt")
		ignoredBlocksFile.writeLine("terrestria:basalt_cobblestone")
		ignoredBlocksFile.writeLine("terrestria:basalt_dirt")
		ignoredBlocksFile.writeLine("terrestria:basalt_grass_block")
		ignoredBlocksFile.writeLine("terrestria:basalt_podzol")
		ignoredBlocksFile.writeLine("terrestria:basalt_sand")
		ignoredBlocksFile.writeLine("terrestria:dead_grass")

		ignoredBlocksFile:close()
	end

	for line in io.lines(ignoredBlocksFileName) do
		ignoredBlocks[line] = true
		log.trace("Loaded ignored block with ID: " .. line)
	end

	log.info("Finished loading ignored blocks IDs")
	return ignoredBlocks
end

function loadEnderChestsList()
	log.info("Loading Ender Chest IDs")
	local enderChests = {}
	if not fs.exists("quarry.enderchests") then
		log.info("quarry.enderchests not found, creating a new one with default IDs. You can add more IDs to this file, one ID per line!")
		local enderChestsFile = fs.open("quarry.enderchests", "w")

		enderChestsFile.writeLine("kibe:entangled_chest")
		enderChestsFile.writeLine("enderstorage:ender_storage")

		enderChestsFile:close()
	end

	for line in io.lines("quarry.enderchests") do
		enderChests[line] = true
		log.trace("Loaded compatible Ender Chest with ID: " .. line)
	end

	log.info("Finished loading Ender Chest IDs")
	return enderChests
end

function loadEnderTanksList()
	local enderChests = {}
	if not fs.exists("quarry.tanks") then
		local enderChestsFile = fs.open("quarry.tanks", "w")

		enderChestsFile.writeLine("kibe:entangled_tank")
		enderChestsFile.writeLine("enderstorage:ender_tank")

		enderChestsFile:close()
	end

	for line in io.lines("quarry.tanks") do
		enderChests[line] = true
	end

	return enderChests
end

function requestValidInput(val, name)
	val = tonumber(val)
	while val == nil or not 'number' == type(val) or not math.floor(val) == val or val <= 0 do
		io.write(name .. ": ")
		val = tonumber(io.read())
	end

	return val
end

function checkForEnderChest()
	hasEnderChest = false
	local enderChestList = loadEnderChestsList()
	log.info("Searching inventory for compatible Ender Chests")
	for slot = 1, 16, 1 do
		log.trace("Searching slot " .. slot)
		local itemData = turtle.getItemDetail(slot)
		if itemData then
			log.trace("Slot " .. slot .. " has item: " .. itemData.name)
			if enderChestList[itemData.name] then
				log.info("Ender Chest found in slot " .. slot)
				enderChestSlot = slot
				hasEnderChest = true
				break
			end
		end
	end
	log.trace("Finished searching for Ender Chest")

	if not hasEnderChest then
		log.error("No Ender Chest found")
		error("No EnderChest found.")
	end

	return true
end

function loadPerimeter(args)
	if args[1] == nil or args[2] == nil then
		io.write("Select the area to mine, all values must be positive integers:\n\n")
	end

	width = nil
	length = nil
	height = nil

	curWidth = 1
	curLength = 1
	curHeight = 1

	action = "idle"
	lengthInverted = false
	WidthInverted = false
	local configExists = fs.exists("quarry.run")
	if configExists then
		fs.delete("quarry.run")
		configExists = false
	end

	if configExists then
		local configFile = fs.open("quarry.run", "w")

		width = configFile.readLine()
		length = configFile.readLine()
		height = configFile.readLine()
		curWidth = configFile.readLine()
		curLength = configFile.readLine()
		curHeight = configFile.readLine()
		action = configFile.readLine()
		lengthInverted = configFile.readLine()
		WidthInverted = configFile.readLine()

		configFile.close()
	else
		local configFile = fs.open("quarry.run", "w")

		width = requestValidInput(args[1], "Width")
		length = requestValidInput(args[2], "Length")
		height = 256 -- TODO

		configFile.write(getRunData())

		configFile.close()
	end
end

function getRunData()
	return width .. "\n" .. length .. "\n" .. height .. "\n" .. curWidth .. "\n" .. curLength .. "\n" .. curHeight .. "\n" .. action
end

function updateRunData()
	local configFile = fs.open("quarry.run", "w")
	configFile.write(getRunData())
	configFile.close()
end

function moveDown()
	if curHeight > height then
		return
	end

	dig(directionMapping["down"], true)
	action = "moveDown"
	updateRunData()
	local inspected, blockData = directionMapping["down"]["inspect"]()
	if inspected and blockData and blockData.name == "minecraft:bedrock" then
		height = curHeight
	else
		while not turtle.down() do
			dig(directionMapping["down"], true)
			turtle.attackDown()
		end
		curHeight = curHeight + 1
	end
	action = "idle"
	updateRunData()

	if curHeight > 2 and curHeight < 6 then
		local placeBlock = false
		local placeSlot
		for i = 1, 16, 1 do
			local slotData = turtle.getItemDetail(i)
			if slotData and ignoredBlocks[slotData.name] then
				placeBlock = true
				placeSlot = i
				break
			end
		end

		if placeBlock then
			turtle.select(placeSlot)
			turtle.placeUp()
		end
	end
end

function moveForward(increaseWidth)
	checkLava(directionMapping["forward"])
	action = "moveForward"
	updateRunData()
	while not turtle.forward() do
		dig(directionMapping["forward"], true)
		turtle.attack()
	end
	action = "idle"
	if increaseWidth then
		curLength = curLength + 1 -- TODO: Add Direction for positive/negative
	end
	updateRunData()
	return success
end

function moveUp()
	if curHeight <= 1 then
		return
	end

	dig(directionMapping["up"], true)
	action = "moveUp"
	updateRunData()
	while not turtle.up() do
		dig(directionMapping["up"], true)
		turtle.attackUp()
	end
	action = "idle"
	curHeight = curHeight - 1
	updateRunData()

	if curHeight < 5 then
		local placeBlock = false
		local placeSlot
		for i = 1, 16, 1 do
			local slotData = turtle.getItemDetail(i)
			if slotData and ignoredBlocks[slotData.name] then
				placeBlock = true
				placeSlot = i
				break
			end
		end

		if placeBlock then
			turtle.select(placeSlot)
			turtle.placeDown()
		end
	end
end

function turnLeft()
	action = "turnLeft"
	updateRunData()
	local success = turtle.turnLeft()
	-- TODO check turn
	action = "idle"
	--TODO: Update Direction
	updateRunData()
	return success
end

function turnRight()
	action = "turnRight"
	updateRunData()
	local success = turtle.turnRight()
	-- TODO check turn
	action = "idle"
	--TODO: Update Direction
	updateRunData()
	return success
end

function widthTurn()
	if lengthInverted then
		turnLeft()
	else
		turnRight()
	end
end

function shouldMineBlock(directionFunc)
	local success, blockData = directionFunc["inspect"]()
	if success and blockData and ignoredBlocks[blockData.name] then
		return false
	end

	return true
end

function checkChest(directionFunc)
	local success, blockData = directionFunc["inspect"]()
	if success and blockData and string.match(blockData.name, "chest") or blockData.name == "minecraft:barrel" then
		while directionFunc["suck"]() do
			checkInventory(directionFunc["up"])
		end
	end
end

function checkLava(directionFunc)
	if not fuel.hasBucket or not fuel.fuelRequired or fuel.getFuelLevel() + 1000 >= fuelLimit then
		return
	end

	local success, blockData = directionFunc["inspect"]()
	if success and blockData and blockData.name == "minecraft:lava" then
		turtle.select(fuel.bucketSlot)
		directionFunc["place"]()
		if turtle.refuel() == false then
			directionFunc["place"]()
		end
	end
end

function checkTurtle(directionFunc)
	local unlocked = false
	repeat
		local inspected, blockData = directionFunc["inspect"]()
		if inspected and blockData and string.match(blockData.name, "turtle") then
			os.sleep(1)
		else
			unlocked = true
		end
	until unlocked
end

function dig(directionFunc, force)
	if force or shouldMineBlock(directionFunc) then
		checkTurtle(directionFunc)
		checkChest(directionFunc)
		checkLava(directionFunc)
		directionFunc["dig"]()
		checkInventory()
	end
end

function excavate(forceUp, forceForward, forceDown)
	dig(directionMapping["forward"], forceForward)
	dig(directionMapping["up"], forceUp)
	dig(directionMapping["down"], forceDown)
end

function quarry()
	term.clear()
	while curHeight ~= height do
		moveDown()
	end

	moveUp()

	repeat
		if curHeight >= height then
			return
		end

		while curWidth <= width do
			while curLength <= length - 1 do
				excavate(false, true, false)
				moveForward(true)
			end

			curLength = 1
			updateRunData()

			if curWidth < width then
				widthTurn()
				excavate(false, true, false)
				moveForward(false)
				widthTurn()
			end

			lengthInverted = not lengthInverted
			curWidth = curWidth + 1
			updateRunData()
		end

		dig(directionMapping["down"], false)
		widthTurn()
		curWidth = 1
		widthInverted = not widthInverted
		updateRunData()

		moveUp()
		moveUp()
		moveUp()
	until curHeight <= 1
end

function returnToStart()
	if lengthInverted then
		for i = curLength, length - 1, 1 do
			moveForward()
		end
	end

	if widthInverted then
		if lengthInverted then
			widthTurn()
		end
		for i = curWidth, width - 1, 1 do
			moveForward()
		end
	end

	local success, _ = directionMapping["down"]["inspect"]()
	if not success then
		local placeBlock = false
		local placeSlot
		for i = 1, 16, 1 do
			local slotData = turtle.getItemDetail(i)
			if slotData and ignoredBlocks[slotData.name] then
				placeBlock = true
				placeSlot = i
				break
			end
		end

		if placeBlock then
			turtle.select(placeSlot)
			turtle.placeDown()
		end
	end
end

function startup()
	log.trace("Startup with args: " .. table.concat(args, '; '))

	checkForEnderChest()
	fuel.checkForBucket()
	loadIgnoredBlocks()
	loadPerimeter(args)


	local fuelEstimate = width * length * 60
	if not hasEnderChest then
		-- Some fuel will be used when returning itens to the surface!
		fuelEstimate = math.floor(fuelEstimate * 1.1)
	end
	fuel.refuelWizard(fuelEstimate)
	quarry()
	returnToStart()
	emptyInventory(directionMapping["up"])
end

log.setLevel(log.LogLevel.TRACE)
log.setLevel(log.LogLevel.INFO)

args = { ... }
startup()
