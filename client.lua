-- Open first modem
modem = peripheral.find("modem")
if modem == nil then
    print("No modems found, exiting")
    goto exit
end
modem.open(1883)

-- 5 second timeout
function timeout()
    os.sleep(5)
end

function waitForConnack()
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
        if payload["type"] == "CONNACK" then
            connected = true
            print("Connection acknowledged")
            goto found
        end

        -- Continue label to skip loop iteration
        ::continue::
    end

    ::found::
end

function sendConnect(id)
    modem.transmit(1883, 1883, {
        id=id,
        type="CONNECT"
    })
end

connected = false

-- Connect to broker
sendConnect(os.computerID())

-- Wait for broker reply
parallel.waitForAny(timeout, waitForConnack)
if not connected then
    print("Connection not acknowledged, exiting")
    goto exit
end

-- Exit label to exit the program
::exit::
