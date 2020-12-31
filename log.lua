LogLevel = {
	TRACE = 0,
	INFO = 1,
	ERROR = 2,
}

LOG_LEVEL = LogLevel.INFO
LOG_FILE = {}
LOG_IO = {}

function openLog(logPrefix)
	if LOG_IO[logPrefix] ~= nil then
		LOG_IO[logPrefix].close()
	end

	LOG_FILE[logPrefix] = "logs/" .. logPrefix .. "_d" .. os.day() .. "_t" .. os.time() .. ".log"
	LOG_IO[logPrefix] = fs.open(LOG_FILE[logPrefix], "w")
	info("Logging started at " ..  textutils.formatTime(os.time()) .. " on the " .. os.day() .. "th day. System has been running for " .. os.clock() .. " seconds and the log file is " .. LOG_FILE[logPrefix])
end

function getLevel()
	return LOG_LEVEL
end

function setLevel(level)
	assert(type(level) == "number", "Log level must be a number. Please use logger.LogLevel to avoid errors!")
	assert(level >= LogLevel.TRACE, "Unknown log level: " .. level .. ". Please use logger.LogLevel to avoid errors!")
	assert(level <= LogLevel.ERROR, "Unknown log level: " .. level .. ". Please use logger.LogLevel to avoid errors!")

	LOG_LEVEL = level
end

function logIO(message, logLevel, printStackTrace)
	if LOG_LEVEL > logLevel then
		return
	end

	local logPrefix = debug.getinfo(3, 'S').short_src
	if LOG_IO[logPrefix] == nil then
		openLog(logPrefix)
	end

	print(message)
	local callerName = debug.getinfo(3, "n").name
	local callerLine = debug.getinfo(3, 'l').currentline
	message = callerName .. ":" .. callerLine .. " - " .. message

	if printStackTrace then
		local stackTrace = debug.traceback(message, 3)
		LOG_IO[logPrefix].write(stackTrace)
	else
		LOG_IO[logPrefix].writeLine(message)
	end

	LOG_IO[logPrefix].flush()
end

function trace(message)
	logIO(message, LogLevel.TRACE, false)
end

function info(message)
	logIO(message, LogLevel.INFO, false)
end

function error(message, error)
	logIO(message, LogLevel.ERROR, true)
end
