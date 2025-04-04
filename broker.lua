-- Open first modem
modem = peripheral.find("modem")
if modem == nil then
    print("No modems found, exiting")
    goto exit
end
modem.open(1883)

-- List of connected clients
clients = {}

function sendConnack(id)
    modem.transmit(1883, 1883, {
        id=id,
        type="CONNACK"
    })
end

function connect(id)
    if clients[id] ~= nil then
        print("Client " .. id .. " already in server client list, ignoring and acknowledging")
        sendConnack(id)
    else
        local client = {
            subs={}
        }

        clients[id] = client

        sendConnack(id)

        print("Client " .. id .. " connected")
    end
end

term.clear()
print("Accepting connections...")

-- Wait for messages
while true do
    -- Pull event
    local event, side, channel, reply, payload, distance = os.pullEvent("modem_message")

    -- Check the correct channel
    if channel ~= 1883 then
        goto continue
    end

    -- Validate payload
    if type(payload) ~= "table" then
        print("Non table message, ignoring")
        goto continue
    end

    -- Validate ID
    local id = payload["id"]
    if type(id) ~= "number" then
        print("Non number id, ignoring")
        goto continue
    end

    -- Read message type
    if payload["type"] == "CONNECT" then
        connect(id)
    elseif payload["type"] == "CONNACK" then
        print("TODO")
    elseif payload["type"] == "SUBSCRIBE" then
        print("TODO")
    elseif payload["type"] == "SUBACK" then
        print("TODO")
    elseif payload["type"] == "PUBLISH" then
        print("TODO")
    elseif payload["type"] == "PUBACK" then
        print("TODO")
    elseif payload["type"] == "PUBREC" then
        print("TODO")
    elseif payload["type"] == "PUBREL" then
        print("TODO")
    elseif payload["type"] == "PUBCOMP" then
        print("TODO")
    elseif payload["type"] == "DISCONNECT" then
        print("TODO")
    else
        print("Unknown message type, ignoring")
    end
    
    -- Continue label to skip loop iteration
    ::continue::
end

-- Exit label to exit the program
::exit::
