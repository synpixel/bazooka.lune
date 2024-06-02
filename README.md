# lune-roblox-http

a simple wrapper around lune's net library with support for roblox's quirks such as csrf tokens

## Example

```lua
local robloxHttp = RobloxHttp({
    token = "<insert .ROBLOSECURITY token>",
    showRatelimitWarnings = false, -- default: true
    defaultRatelimitTimeout = 15, -- default: 10
    handleUnauthorizedRequests = false, -- default: true
})

local response = robloxHttp:get("https://users.roblox.com/v1/users/authenticated")
print(net.jsonDecode(response.body))
```
