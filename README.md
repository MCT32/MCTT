# MCTT

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
