function cleanup(file)
	if fs.exists(file) then
		print("Deleting " .. file)
		shell.run("delete", file)
	end
end

function download(programName, fileName, url)
	local fileStream = http.get(url)
	local fileData = fileStream.readAll()
	fileStream.close()

	local file = fs.open(fileName, "w")
	file.write(fileData)
	file.close()

	print(programName .. " program updated!")
end

cleanup("skychest.lua")
cleanup("quarry.run")
cleanup("quarry.ignoredblocks")
cleanup("quarry.enderchests")
cleanup("q.lua")
cleanup("log.lua")
cleanup("fuel.lua")
cleanup("rw.lua")

download("SkyChest", "skychest.lua", "https://raw.githubusercontent.com/Jabulba/Turtle-LCars-OS/master/SkyChestFinder.lua")
download("Quarry", "q.lua", "https://raw.githubusercontent.com/Jabulba/Turtle-LCars-OS/master/quarry.lua")
download("Logger API", "log.lua", "https://raw.githubusercontent.com/Jabulba/Turtle-LCars-OS/master/log.lua")
download("Fuel API", "fuel.lua", "https://raw.githubusercontent.com/Jabulba/Turtle-LCars-OS/master/fuel.lua")
download("Refuel Wizard", "refuelwizard.lua", "https://raw.githubusercontent.com/Jabulba/Turtle-LCars-OS/master/refuelwizard.lua")
