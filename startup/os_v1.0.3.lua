-- os.lua
local modem = peripheral.find("modem")
if not modem then
    print("No modem attached")
    return
end

local monitor = peripheral.wrap("left")  -- Ensure this is the correct side
if not monitor then
    print("No monitor found on the left")
    return
end

modem.open(1)  -- Open channel 1 for receiving commands
modem.open(2)  -- Open channel 2 for sending acknowledgments

monitor.setTextScale(1)  -- Set text scale to a slightly larger size
monitor.setTextColor(colors.green)  -- Set text color to green
monitor.clear()

local mainScreenActive = true

local function displayHeader()
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write(string.rep("-", 50))
    monitor.setCursorPos(1, 2)
    monitor.write("KaliLinux MC Edition v1.0.8")
    monitor.setCursorPos(1, 3)
    monitor.write(string.rep("-", 50))
end

local function displayMessage(message)
    local _, y = monitor.getCursorPos()
    monitor.setCursorPos(1, y + 1)
    monitor.write(message)
end

local function displayCommands()
    local commands = {
        "1.  > Program 1 <",
        "2.  > Program 2 <",
        "3.  > Program 3 <",
        "4.  > Program 4 <",
        "5.  > Program 5 <",
        "6.  > Reboot <",
        "7.  > Exit <"
    }
    
    monitor.setCursorPos(1, 4)
    monitor.write("Available Commands:")
    for i, cmd in ipairs(commands) do
        monitor.setCursorPos(1, 5 + i)
        monitor.write(cmd)
    end
    monitor.setCursorPos(1, 13)
    monitor.write(string.rep("-", 50))
end

local function displayMainScreen()
    displayHeader()
    displayCommands()
    monitor.setCursorPos(1, 15)
    monitor.write("kali@kaliLinux~usr:")
    mainScreenActive = true
end

local function displayProgramScreen(programName)
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write(string.rep("-", 50))
    monitor.setCursorPos(1, 2)
    monitor.write("Executing " .. programName)
    monitor.setCursorPos(1, 3)
    monitor.write(string.rep("-", 50))
    monitor.setCursorPos(1, 4)
end

local function runProgram(programName)
    mainScreenActive = false
    displayProgramScreen(programName)
    monitor.setCursorPos(1, 5)
    monitor.write("Please wait...")
    sleep(2)  -- Simulate running the program
    monitor.setCursorPos(1, 7)
    monitor.write(programName .. " finished successfully.")
    sleep(2)  -- Pause to show the completion message
    displayMainScreen()
end

local function handleCommand(command)
    if command == "shutdown" then
        displayMessage("Shutting down...")
        sleep(1)
        os.shutdown()
    elseif command == "reboot" then
        displayMessage("Rebooting...")
        sleep(1)
        os.reboot()
    elseif command == "exit" then
        displayMessage("Exiting OS...")
        sleep(1)
        return true
    elseif command:match("^program%d$") then
        runProgram(command)
    else
        displayMessage("Unknown command: " .. command)
    end

    -- Send acknowledgment
    modem.transmit(2, 1, "Acknowledged: " .. command)
    return false
end

local function generateRandomText(length)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = ""
    for i = 1, length do
        local rand = math.random(1, #charset)
        result = result .. charset:sub(rand, rand)
    end
    return result
end

local function displayStartupScreen()
    monitor.clear()
    local startupLines = 20
    for i = 1, startupLines do
        local length = math.random(20, 50)
        local randomText = generateRandomText(length)
        monitor.setCursorPos(1, i)
        monitor.write(randomText)
        sleep(0.1)
    end

    displayMainScreen()
end

local function blinkCursor()
    local cursorState = false
    while true do
        if mainScreenActive then
            monitor.setCursorPos(20, 15)  -- Position after "kali@kaliLinux~usr:"
            if cursorState then
                monitor.write(" ")
            else
                monitor.write("_")
            end
            cursorState = not cursorState
        end
        sleep(0.5)
    end
end

displayStartupScreen()

local function runOS()
    local exitOS = false
    while not exitOS do
        parallel.waitForAny(
            function()
                local input = read()
                displayMessage("Local command: " .. input)
                exitOS = handleCommand(input)
            end,
            function()
                local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
                if channel == 1 then
                    displayMessage("Remote command: " .. message)
                    exitOS = handleCommand(message)
                end
            end,
            blinkCursor
        )
    end
end

runOS()
