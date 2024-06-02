local net = require("@lune/net")
local stdio = require("@lune/stdio")
local task = require("@lune/task")

export type HttpBody = string | buffer

export type RobloxHttpOptions = {
	token: string?,
	handleRatelimits: boolean?,
	defaultRatelimitTimeout: number?,
	handleUnauthorizedRequests: boolean?,
}

local function merge<T, K>(a: { [T]: K }, ...: { [T]: K }): { [T]: K }
	local clone = table.clone(a)

	for _, b in { ... } do
		for index, value in b do
			clone[index] = value
		end
	end

	return clone
end

local function insertHeaders(fetchParams: net.FetchParams, extraHeaders: net.HttpHeaderMap): net.FetchParams
	local headers = merge(fetchParams.headers or {}, extraHeaders)
	return merge(fetchParams, { headers = headers }) :: net.FetchParams
end

local function logRatelimit(method: net.HttpMethod, url: string, timeout: number)
	print(
		`too many {stdio.color("green") .. method .. stdio.color("reset")} requests to {stdio.style("dim") .. url .. stdio.style(
			"reset"
		)} retrying in {stdio.color("yellow") .. timeout .. stdio.color("reset")} seconds`
	)
end

local function logUnauthorizedRequest(method: net.HttpMethod, url: string)
	error(
		`unauthorized {stdio.color("green") .. method .. stdio.color("reset")} request to {stdio.style("dim") .. url .. stdio.style(
			"reset"
		)} give a valid token to the RobloxHttp constructor to avoid this`
	)
end

local function RobloxHttp(options: RobloxHttpOptions?)
	local patchedOptions = options or {}

	if patchedOptions.defaultRatelimitTimeout == nil then
		patchedOptions.defaultRatelimitTimeout = 10
	end

	if patchedOptions.handleRatelimits == nil then
		patchedOptions.handleRatelimits = true
	end

	if patchedOptions.handleUnauthorizedRequests == nil then
		patchedOptions.handleUnauthorizedRequests = true
	end

	local token: string? = patchedOptions.token
	local handleRatelimits = patchedOptions.handleRatelimits == true
	local defaultRatelimitTimeout: number = patchedOptions.defaultRatelimitTimeout
	local handleUnauthorizedRequests = patchedOptions.handleUnauthorizedRequests == true

	local csrfTokenCache: string? = nil
	local robloxHttp = {}

	function robloxHttp:request(fetchParams: net.FetchParams)
		local response = net.request(insertHeaders(fetchParams, {
			Cookie = ".ROBLOSECURITY=" .. (token or ""),
			["X-Csrf-Token"] = csrfTokenCache,
		}))

		if response.headers["x-csrf-token"] then
			csrfTokenCache = response.headers["x-csrf-token"]
			return robloxHttp:request(fetchParams)
		end

		if response.statusCode == 401 and handleUnauthorizedRequests then
			logUnauthorizedRequest(fetchParams.method :: net.HttpMethod, fetchParams.url)
		elseif response.statusCode == 429 and handleRatelimits then
			local timeout = tonumber(response.headers["retry-after"]) or defaultRatelimitTimeout

			logRatelimit(fetchParams.method :: net.HttpMethod, fetchParams.url, timeout)
			task.wait(timeout)

			return robloxHttp:request(fetchParams)
		end

		return response
	end

	function robloxHttp:get(url: string)
		return robloxHttp:request({
			method = "GET",
			url = url,
		})
	end

	function robloxHttp:post(url: string, body: HttpBody?)
		return robloxHttp:request({
			method = "POST",
			url = url,
			body = body,
		})
	end

	function robloxHttp:patch(url: string, body: HttpBody?)
		return robloxHttp:request({
			method = "PATCH",
			url = url,
			body = body,
		})
	end

	function robloxHttp:put(url: string, body: HttpBody?)
		return robloxHttp:request({
			method = "PUT",
			url = url,
			body = body,
		})
	end

	function robloxHttp:delete(url: string, body: HttpBody?)
		return robloxHttp:request({
			method = "DELETE",
			url = url,
			body = body,
		})
	end

	return robloxHttp
end

return RobloxHttp
