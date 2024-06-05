# lune-bazooka

a simple wrapper around lune's net library with support for roblox's quirks such as csrf tokens

## Example

```lua
local bazooka = Bazooka({
    token = "<insert .ROBLOSECURITY token>",
    handleRatelimits = false, -- default: true
    defaultRatelimitTimeout = 15, -- default: 10
    handleUnauthorizedRequests = false, -- default: true
})

local response = bazooka:get("https://users.roblox.com/v1/users/authenticated")
print(net.jsonDecode(response.body))
```
