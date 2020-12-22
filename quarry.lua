-- Turtle Quarry by Jabulba

-- Global Variables:
-- integer  width
-- integer  length
-- integer  height
-- integer  refuelSlot
-- string[] ignoredBlocks
-- integer  enderChestSlot
-- boolean  hasEnderChest

boolToInt = { [true] = 1, [false] = 0 }
turtleFuncMapping = {
	["up"] =		{ ["detect"] = turtle.detectUp,		["dig"] = turtle.digUp,		["place"] = turtle.placeUp,		["inspect"] = turtle.inspectUp,		["drop"] = turtle.dropUp,	["suck"] = turtle.suckUp },
	["down"] =		{ ["detect"] = turtle.detectDown,	["dig"] = turtle.digDown,	["place"] = turtle.placeDown,	["inspect"] = turtle.inspectDown,	["drop"] = turtle.dropDown,	["suck"] = turtle.suckDown },
	["forward"] =	{ ["detect"] = turtle.detect,		["dig"] = turtle.dig,		["place"] = turtle.place,		["inspect"] = turtle.inspect,		["drop"] = turtle.drop,		["suck"] = turtle.suck }
}

local function emptyInventory(directionFunc)
	directionFunc = directionFunc or turtleFuncMapping["forward"]

	if hasEnderChest then
		print("Clearing inventory...")
		turtle.select(enderChestSlot)

		while directionFunc["detect"]() do
			local success, err = directionFunc["dig"]()
			if not success and err == "Unbreakable block detected" then
				-- TODO: backtrack?
				error(err)
			end
			os.sleep(0.2)
		end

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
			if i == enderChestSlot or i == bucketSlot then
				break
			end

			turtle.select(i)
			directionFunc["drop"]()
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
		io.write(" Inventory cleared!\n")
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

function getFuelLevel()
	local fuelLevel = turtle.getFuelLevel()
	if fuelLevel == "unlimited" then -- No fuel required
		return math.huge
	end

	return fuelLevel
end

function startupRefuel()
	refuelSlot = 2
	local fuelEstimate = width * length * (height + curHeight)
	if not hasEnderChest then
		fuelEstimate = math.floor(fuelEstimate * 1.3)
	end

	local unlocked = false
	repeat
		local fuelLevel = getFuelLevel()
		if fuelLevel < fuelEstimate then
			term.clear()
			io.write("Fuel level might not be enougth to complete the run!\n")
			io.write("Current: " .. fuelLevel .. " Required Estimate: " .. fuelEstimate .. "\n")
			io.write("Missing: " .. (fuelEstimate - fuelLevel) .. "\n\n")

			turtle.select(refuelSlot)
			if not turtle.refuel(0) then
				io.write("Place fuel in slot " .. refuelSlot .. " or press [ENTER] to continue...\n")
				repeat
					local event, param1 = os.pullEvent()
					if event == "key" and param1 == keys.enter then
						unlocked = true
						break
					elseif event == "turtle_inventory" then
						break
					end
				until false
			else
				turtle.refuel()
			end
		else
			unlocked = true
		end
	until unlocked

	return true
end

function loadIgnoredBlocks()
	ignoredBlocks = {}
	local ignoredBlocksFileName = "quarry.ignoredblocks"
	if not fs.exists(ignoredBlocksFileName) then
		local ignoredBlocksFile = fs.open(ignoredBlocksFileName, "w")

		ignoredBlocksFile.writeLine("minecraft:air")
		ignoredBlocksFile.writeLine("minecraft:andesite")
		ignoredBlocksFile.writeLine("minecraft:bedrock")
		ignoredBlocksFile.writeLine("minecraft:blackstone")
		ignoredBlocksFile.writeLine("minecraft:cobblestone")
		ignoredBlocksFile.writeLine("minecraft:diorite")
		ignoredBlocksFile.writeLine("minecraft:dirt")
		ignoredBlocksFile.writeLine("minecraft:granite")
		ignoredBlocksFile.writeLine("minecraft:grass")
		ignoredBlocksFile.writeLine("minecraft:gravel")
		ignoredBlocksFile.writeLine("minecraft:ice")
		ignoredBlocksFile.writeLine("minecraft:ladder")
		ignoredBlocksFile.writeLine("minecraft:netherrack")
		ignoredBlocksFile.writeLine("minecraft:polished_blackstone_bricks")
		ignoredBlocksFile.writeLine("minecraft:sand")
		ignoredBlocksFile.writeLine("minecraft:sandstone")
		ignoredBlocksFile.writeLine("minecraft:snow")
		ignoredBlocksFile.writeLine("minecraft:snow_layer")
		ignoredBlocksFile.writeLine("minecraft:stone")
		ignoredBlocksFile.writeLine("minecraft:torch")
		ignoredBlocksFile.writeLine("blockus:bluestone")
		ignoredBlocksFile.writeLine("blockus:limestone")
		ignoredBlocksFile.writeLine("blockus:marble")
		ignoredBlocksFile.writeLine("byg:brimstone")
		ignoredBlocksFile.writeLine("byg:nyliumd_soul_soil")
		ignoredBlocksFile.writeLine("byg:meadow_dirt")
		ignoredBlocksFile.writeLine("byg:meadow_grass_block")
		ignoredBlocksFile.writeLine("byg:rocky_stone")
		ignoredBlocksFile.writeLine("wild_explorer:blunite")
		ignoredBlocksFile.writeLine("wild_explorer:carbonite")

		ignoredBlocksFile:close()
	end

	for line in io.lines(ignoredBlocksFileName) do
		ignoredBlocks[line] = true
	end

	return ignoredBlocks
end

function loadEnderChestsList()
	local enderChests = {}
	if not fs.exists("quarry.enderchests") then
		local enderChestsFile = fs.open("quarry.enderchests", "w")

		enderChestsFile.writeLine("kibe:entangled_chest")

		enderChestsFile:close()
	end

	for line in io.lines("quarry.enderchests") do
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
	term.clear()
	hasEnderChest = false
	local enderChestList = loadEnderChestsList()
	for slot = 1, 16, 1 do
		local itemData = turtle.getItemDetail(slot)
		if itemData then
			if enderChestList[itemData.name] then
				enderChestSlot = slot
				hasEnderChest = true
				break
			end
		end
	end

	if not hasEnderChest then
		error("No EnderChest found.")
	end

	return true
end

function checkForBucket()
	hasBucket = false
	local unlocked = false
	repeat
		term.clear()
		for slot = 1, 16, 1 do
			local itemData = turtle.getItemDetail(slot)
			if itemData then
				if itemData.name == "minecraft:bucket" then
					bucketSlot = slot
					hasBucket = true
					break
				end
			end
		end

		if hasBucket then
			print("Using bucket from slot " .. enderChestSlot .. " to refuel with lava!")
			break
		else
			print("Please give me a bucket so I can refuel using lava found along the way!")
			print("or press [ENTER] to disable refueling")

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

	dig(turtleFuncMapping["down"], true)
	action = "moveDown"
	updateRunData()
	local inspected, blockData = turtleFuncMapping["down"]["inspect"]()
	if inspected and blockData and blockData.name == "minecraft:bedrock" then
		height = curHeight
	else
		while not turtle.down() do
			dig(turtleFuncMapping["down"], true)
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
	action = "moveForward"
	updateRunData()
	while not turtle.forward() do
		dig(turtleFuncMapping["forward"], true)
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

	dig(turtleFuncMapping["up"], true)
	action = "moveUp"
	updateRunData()
	while not turtle.up() do
		dig(turtleFuncMapping["up"], true)
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
	local success, blockData = directionFunc["inspect"]()
	if success and blockData and blockData.name == "minecraft:lava" then
		turtle.select(bucketSlot)
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
	dig(turtleFuncMapping["up"], forceUp)
	dig(turtleFuncMapping["forward"], forceForward)
	dig(turtleFuncMapping["down"], forceDown)
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

		dig(turtleFuncMapping["down"], false)
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
		widthTurn()
		for i = curWidth, width - 1, 1 do
			moveForward()
		end
	end
end

args = { ... }
checkForEnderChest()
checkForBucket()
loadIgnoredBlocks()
loadPerimeter(args)
startupRefuel()
quarry()
returnToStart()
emptyInventory(turtleFuncMapping["up"])
