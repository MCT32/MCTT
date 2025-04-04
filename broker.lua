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

function sendSuback(id, topic)
    modem.transmit(1883, 1883, {
        id=id,
        type="SUBACK",
        topic=topic
    })
end

function sendUnsuback(id, topic)
    modem.transmit(1883, 1883, {
        id=id,
        type="UNSUBACK",
        topic=topic
    })
end

function sendPublish(id, topic, content)
    modem.transmit(1883, 1883, {
        id=id,
        type="PUBLISH",
        topic=topic,
        content=content
    })
end

function sendMessage(topic, content)
    for id, client in pairs(clients) do
        if client["subs"][topic] == true then
            sendPublish(id, topic, content)
        end
    end

    print("Published to topic " .. topic .. " message " .. textutils.serialise(content))
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

function subscribe(id, topic)
    if clients[id] == nil then
        print("Client " .. id .. " not in server client list, ignoring")
    elseif type(topic) ~= "string" then
        print("Client " .. id .. " sent non string topic, ignoring")
    else
        -- See if client is already subscribed
        if clients[id]["subs"][topic] ~= nil then
            print("Client " .. id .. " already subscribed to topic, ignoring and acknowledging")
            sendSuback(id, topic)
        else
            clients[id]["subs"][topic] = true
            print("Client " .. id .. " subscribed to topic " .. topic)
            sendSuback(id, topic)
        end
    end
end

function unsubscribe(id, topic)
    if clients[id] == nil then
        print("Client " .. id .. " not in server client list, ignoring")
    elseif type(topic) ~= "string" then
        print("Client " .. id .. " sent non string topic, ignoring")
    else
        -- See if client is subscribed
        if clients[id]["subs"][topic] == nil then
            print("Client " .. id .. " isn't already subscribed to topic, ignoring and acknowledging")
            sendUnsuback(id, topic)
        else
            clients[id]["subs"][topic] = nil
            print("Client " .. id .. " unsubscribed from topic " .. topic)
            sendUnsuback(id, topic)
        end
    end
end

function publish(id, topic, content)
    if clients[id] == nil then
        print("Client " .. id .. " not in server client list, ignoring")
    elseif type(topic) ~= "string" then
        print("Client " .. id .. " sent non string topic, ignoring")
    else
        sendMessage(topic, content)
    end
end

function disconnect(id)
    if clients[id] == nil then
        print("Client " .. id .. " not in server client list, ignoring")
    else
        clients[id] = nil

        print("Client " .. id .. " disconnected")
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
        print("Received message only server should send, ignoring")
    elseif payload["type"] == "SUBSCRIBE" then
        subscribe(id, payload["topic"])
    elseif payload["type"] == "SUBACK" then
        print("Received message only server should send, ignoring")
    elseif payload["type"] == "UNSUBSCRIBE" then
        unsubscribe(id, payload["topic"])
    elseif payload["type"] == "UNSUBACK" then
        print("Received message only server should send, ignoring")
    elseif payload["type"] == "PUBLISH" then
        publish(id, payload["topic"], payload["content"])
    elseif payload["type"] == "PUBACK" then
        print("QoS not yet supported")
    elseif payload["type"] == "PUBREC" then
        print("Received message only server should send, ignoring")
    elseif payload["type"] == "PUBREL" then
        print("QoS not yet supported")
    elseif payload["type"] == "PUBCOMP" then
        print("Received message only server should send, ignoring")
    elseif payload["type"] == "DISCONNECT" then
        disconnect(id)
    else
        print("Unknown message type, ignoring")
    end
    
    -- Continue label to skip loop iteration
    ::continue::
end

-- Exit label to exit the program
::exit::
