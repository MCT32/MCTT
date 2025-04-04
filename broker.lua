-- Open modem
peripheral.find("modem", rednet.open)
if not rednet.isOpen() then
    print("Could not open modem, exiting")
    goto exit
end

rednet.host("mctt", "broker")

-- List of connected clients
clients = {}

function sendConnack(id)
    rednet.send(id, {type="CONNACK"}, "mctt")
end

function sendSuback(id)
    rednet.send(id, {type="SUBACK",topic=topic}, "mctt")
end

function sendUnsuback(id)
    rednet.send(id, {type="UNSUBACK",topic=topic}, "mctt")
end

function sendPublish(id, topic, content)
    rednet.send(id, {type="PUBLISH",topic=topic,content=content}, "mctt")
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
            sendSuback(id)
        else
            clients[id]["subs"][topic] = true
            print("Client " .. id .. " subscribed to topic " .. topic)
            sendSuback(id)
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
            sendUnsuback(id)
        else
            clients[id]["subs"][topic] = nil
            print("Client " .. id .. " unsubscribed from topic " .. topic)
            sendUnsuback(id)
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
    id, message = rednet.receive("mctt")

    -- Validate message
    if type(message) ~= "table" then
        print("Non table message, ignoring")
        goto continue
    end

    -- Read message type
    if message["type"] == "CONNECT" then
        connect(id)
    elseif message["type"] == "CONNACK" then
        print("Received message only server should send, ignoring")
    elseif message["type"] == "SUBSCRIBE" then
        subscribe(id, message["topic"])
    elseif message["type"] == "SUBACK" then
        print("Received message only server should send, ignoring")
    elseif message["type"] == "UNSUBSCRIBE" then
        unsubscribe(id, message["topic"])
    elseif message["type"] == "UNSUBACK" then
        print("Received message only server should send, ignoring")
    elseif message["type"] == "PUBLISH" then
        publish(id, message["topic"], message["content"])
    elseif message["type"] == "PUBACK" then
        print("QoS not yet supported")
    elseif message["type"] == "PUBREC" then
        print("Received message only server should send, ignoring")
    elseif message["type"] == "PUBREL" then
        print("QoS not yet supported")
    elseif message["type"] == "PUBCOMP" then
        print("Received message only server should send, ignoring")
    elseif message["type"] == "DISCONNECT" then
        disconnect(id)
    else
        print("Unknown message type, ignoring")
    end
    
    -- Continue label to skip loop iteration
    ::continue::
end

-- Exit label to exit the program
::exit::
