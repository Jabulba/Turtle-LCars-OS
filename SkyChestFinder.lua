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

--	if attempts > 30 then
--		return false
--	end

	if direction == "f" or direction == "forward" then
		turtle.dig()

		if not turtle.forward() then
			turtle.attack()
			digMove("f", attempts)
		end
	elseif direction == "d" or direction == "down" then
		turtle.digDown()

		if not turtle.down() then
			turtle.attackDown()
			digMove("d", attempts)
		end
	elseif direction == "u" or direction == "up" then
		turtle.digUp()

		if not turtle.up() then
			turtle.attackUp()
			digMove("u", attempts)
		end
	end

	return true
end

while not skyChestFound do
	local hasBlock, blockData = turtle.inspectDown()

	if hasBlock and blockData.name == skyChestId then
		while turtle.suckDown() do
			print("Picking item from sky chest")
		end

		turtle.dig()
		skyChestFound = true
	elseif hasBlock and blockData.name == skyStoneId and not skyStoneFound then
		skyStoneFound = true
	elseif hasBlock then
	else
		if skyStoneFound then
			break
		end
		
		if digMove("down") then
			movesDone = movesDone + 1
		end
	end
end

while movesDone > 0 do
	if digMove("up") then
		movesDone = movesDone -1
	end

	if movesDone < 5 then
		placeFloor()
	end
end
