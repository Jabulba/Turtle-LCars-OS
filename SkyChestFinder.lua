-- SkyChest search program by Caio "Jabulba" Jabulka 2015
-- Turtle type: Mining Turtle
-- Purpose: Use this program to find hidden meteores from Applied Energistics 2.
--          The turtle will dig down until it finds the chest or bedrock
--          if the chest is found chest the turtle will empty it, pick it up and retur to the surface
--          if bedrock is found the turtle returns to the surface, if it broke skystone it will print a warning
-- Licensed MIT

local skyChestId = "appliedenergistics2:sky_stone_chest"
local skyStoneId = "appliedenergistics2:sky_stone_block"
local bedrockId = "minecraft:bedrock"
local movesDone = 0
local skyChestFound = false
local skyStoneFound = false

local function placeFloor(slot)
	slot = slot or 1

	if slot > 16 then
		return true
	end

	if turtle.getItemCount(slot) > 0 then
		turtle.select(slot)
		if not turtle.placeDown() then
			placeFloor(slot + 1)
		end
	end

	return true
end

local function digMove(direction, attempts)
	direction = direction or "forward"
	attempts = attempts or 1

	if direction == "d" or direction == "down" then
		local hasBlock, blockData = turtle.inspectDown()
		if hasBlock and blockData.name == bedrockId then
			skyChestFound = true
			return
		end
		turtle.digDown()

		if not turtle.down() then
			turtle.attackDown()
			digMove("d", attempts)
		end

		movesDone = movesDone + 1
	elseif direction == "u" or direction == "up" then
		turtle.digUp()

		if not turtle.up() then
			turtle.attackUp()
			digMove("u", attempts)
		end

		movesDone = movesDone - 1
	end

	return true
end

miss = 0
while not skyChestFound do
	local hasBlock, blockData = turtle.inspectDown()
	local hasBlockInFront, frontBlockData = turtle.inspect()

	if hasBlock and blockData.name == skyChestId then
		while turtle.suckDown() do
			print("Picking item from sky chest")
		end

		turtle.digDown()
		skyChestFound = true
	elseif hasBlockInFront and frontBlockData.name == skyChestId then
		while turtle.suck() do
			print("Picking item from sky chest")
		end

		turtle.dig()
		skyChestFound = true
	elseif hasBlock and blockData.name == skyStoneId or hasBlockInFront and frontBlockData.name == skyStoneId then
		print("Sky Stone!")
		skyStoneFound = true
		miss = 0
		
		digMove("down")
	else
		if skyStoneFound and miss > 4 then
			print("To many misses, returning!")
			break
		end
		miss = miss + 1

		digMove("down")
	end
end

while movesDone > 0 do
	digMove("up")

	if movesDone < 5 then
		placeFloor()
	end
end
