-- remote_control.lua
local modem = peripheral.find("modem")
if not modem then
    print("No modem attached")
    return
end

modem.open(2) -- Open a different channel to receive acknowledgments

local function sendCommand(command)
    modem.transmit(1, 2, command)
    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        if channel == 2 then
            print("Response: " .. tostring(message))
            break
        end
    end
end

local commands = {
    "program1",
    "program2",
    "program3",
    "program4",
    "program5",
    "reboot",
    "exit"
}

print("Remote Control Ready")
print("Commands:")
for i, cmd in ipairs(commands) do
    print(i .. ". " .. cmd)
end
print("Type 'quit' to exit.")

while true do
    term.write("Enter command number: ")
    local input = read()
    if input == "quit" then
        break
    end

    local commandNumber = tonumber(input)
    if commandNumber and commandNumber >= 1 and commandNumber <= #commands then
        local command = commands[commandNumber]
        sendCommand(command)
        print("")  -- Print a new line after the command
    else
        print("Invalid command number.")
    end
end

modem.close(2) -- Close channel 2 after exiting
