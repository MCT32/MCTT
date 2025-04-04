-- Open modem
peripheral.find("modem", rednet.open)
if not rednet.isOpen() then
    print("Could not open modem, exiting")
    goto exit
end

BROKER_ID = nil

-- TODO: Fix these, prob use parallel event parser
function waitForConnack()
    -- Pull event
    local id, message = rednet.receive("mctt", 5)

    return id ~= nil
end

function waitForSuback()
    -- Pull event
    local id, message = rednet.receive("mctt", 5)

    return id ~= nil
end

function waitForUnsuback()
    -- Pull event
    local id, message = rednet.receive("mctt", 5)

    return id ~= nil
end

function sendConnect()
    rednet.send(BROKER_ID, {type="CONNECT"}, "mctt")
end

function sendSubscribe(topic)
    rednet.send(BROKER_ID, {type="SUBSCRIBE",topic=topic}, "mctt")
end

function sendUnsubscribe(topic)
    rednet.send(BROKER_ID, {type="UNSUBSCRIBE",topic=topic}, "mctt")
end

function disconnect()
    rednet.send(BROKER_ID, {type="DISCONNECT"}, "mctt")

    print("Disconnected")
end

function connect()
    -- Connect to broker
    sendConnect()

    -- Wait for broker reply
    if waitForConnack() then
        print("Connected to broker")
    else
        error("Connection not acknowledged")
    end
end

function subscribe(topic)
    -- Send subscription message
    sendSubscribe(topic)

    -- Wait for broker reply
    if waitForSuback() then
        print("Subscribed to " .. topic)
    else
        error("Unable to subscribe")
    end
end

function unsubscribe(topic)
    -- Send subscription message
    sendUnsubscribe(topic)

    -- Wait for broker reply
    if waitForUnsuback() then
        print("Unsubscribed from " .. topic)
    else
        error("Unable to unsubscribe")
    end
end

function publish(topic, content)
    rednet.send(BROKER_ID, {type="PUBLISH",topic=topic,content=content}, "mctt")
end

function receiveMessages()
    -- Wait for messages
    while true do
        -- Pull event
        local id, message = rednet.receive("mctt")

        -- Validate payload
        if type(message) ~= "table" then
            print("Non table message, ignoring")
            goto continue
        end

        -- Read message type
        if message["type"] == "PUBLISH" then
            print("Received message on topic " .. message["topic"] .. ": " .. textutils.serialise(message["content"]))
        end

        -- Continue label to skip loop iteration
        ::continue::
    end
end

BROKER_ID = rednet.lookup("mctt", "broker")
if BROKER_ID == nil then
    print("Could not find broker, exiting")
    goto exit
end

if not pcall(connect) then
    print("Couldn't connect, exiting")
    goto exit
end

function main()
    subscribe("test/hello")
    publish("test/hello", "hello, world!")
    unsubscribe("test/hello")
    disconnect(os.computerID())
    os.sleep(5)
end

parallel.waitForAny(main, receiveMessages)

-- Exit label to exit the program
::exit::
