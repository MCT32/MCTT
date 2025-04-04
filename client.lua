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

function waitForSuback()
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
        if payload["type"] == "SUBACK" and payload["topic"] == subTopic then
            subscribed = true
            print("Subscription acknowledged")
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

function sendSubscribe(id, topic)
    modem.transmit(1883, 1883, {
        id=id,
        type="SUBSCRIBE",
        topic=topic
    })
end

function disconnect(id)
    modem.transmit(1883, 1883, {
        id=id,
        type="DISCONNECT"
    })

    print("Disconnected")
end

function connect()
    -- Connect to broker
    sendConnect(os.computerID())

    -- Wait for broker reply
    parallel.waitForAny(timeout, waitForConnack)
    if not connected then
        print("Connection not acknowledged, exiting")
        return false
    end

    return true
end

function subscribe(topic)
    subscribed = false
    subTopic = topic
    local tries = 3

    while tries > 0 do
        -- Send subscription message
        sendSubscribe(os.computerID(), topic)

        -- Wait for broker reply
        parallel.waitForAny(timeout, waitForSuback)
        if subscribed then
            goto found
        end

        print("Subscription not acknowledged, retrying")
        tries = tries - 1
    end

    disconnect()
    print("Unable to subscribe, exiting")

    ::found::
end

-- Varibles used for waiting
connected = false
subscribed = false
subTopic = ""

if not connect() then goto exit end
os.sleep(2)
subscribe("test/hello")
os.sleep(5)
disconnect(os.computerID())

-- Exit label to exit the program
::exit::
