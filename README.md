# MCTT

## TODO

- [X] Subscribing
- [X] Unsubscribing
- [X] Publishing
- [X] Use rednet
- [ ] Make client into API
- [ ] Wildcard subscriptions
- [ ] Heartbeat
- [ ] Retain
- [ ] QoS

## Message format

```lua
{
  type: ...
  id: ...

  -- message specific data
  ...
}
```

**Type:** The type of message being sent. Can be:

- CONNECT
- CONNACK
- SUBSCRIBE
- SUBACK
- UNSUBSCRIBE
- UNSUBACK
- PUBLISH
- PUBACK
- PUBREC
- PUBREL
- PUBCOMP
- DISCONNECT

**Id:** Client ID. By default this is the computer ID for simplicity, but could technically be anything. Keep in mind that IDs have no auth and that collisions could cause issues.

### CONNECT

Used to connect the client to the broker. No other fields required.

### CONNACK

Acknowledgement from the broker to the client that they have connected. No other fields required.

### SUBSCRIBE

Subscribe to a topic.

| Fields | Description |
| --- | --- |
| topic | The topic to subscribe to. |

### UNSUBSCRIBE

Unsubscribe from a topic.

| Fields | Description |
| --- | --- |
| topic | The topic to unsubscribe from. |

### PUBLISH

Publish a message to a topic.

| Fields | Description |
| --- | --- |
| topic | The topic to publish to. |
| content | The content of the message. |

### DISCONNECT

Used to disconnect the client from the broker. No other fields required.
