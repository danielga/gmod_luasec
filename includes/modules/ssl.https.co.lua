----------------------------------------------------------------------------
-- LuaSec 0.5
-- Copyright (C) 2009-2014 PUC-Rio
--
-- Author: Pablo Musa
-- Author: Tomas Guisasola
-- Coroutines version
---------------------------------------------------------------------------

local socket = require("socket") or socket
local ssl    = require("ssl") or ssl
local ltn12  = require("ltn12") or ltn12
local http   = require("socket.http") or socket.http
local url    = require("socket.url") or socket.url

local try          = socket.try

--
-- Module
--
local _M = {
  _VERSION   = "0.5",
  _COPYRIGHT = "LuaSec 0.5 - Copyright (C) 2009-2014 PUC-Rio",
  PORT       = 443,
}

-- TLS configuration
local cfg = {
	protocol = "tlsv1",
	options  = "all",
	verify   = "none",
}

--------------------------------------------------------------------
-- Auxiliar Functions
--------------------------------------------------------------------

-- Insert default HTTPS port.
local function default_https_port(u)
   return url.build(url.parse(u, {port = _M.PORT}))
end

-- Convert an URL to a table according to Luasocket needs.
local function urlstring_totable(url, body, result_table)
	url = {
		url = default_https_port(url),
		method = body and "POST" or "GET",
		sink = ltn12.sink.table(result_table)
	}
	if body then
		url.source = ltn12.source.string(body)
		url.headers = {
			["content-length"] = #body,
			["content-type"] = "application/x-www-form-urlencoded",
		}
	end
	return url
end

-- Forward calls to the real connection object.
local function reg(conn)
	local mt = getmetatable(conn.sock).__index
	for name, method in pairs(mt) do
		if type(method) == "function" then
			conn[name] = function(self, ...)
				return method(self.sock, ...)
			end
		end
	end
end

local running, yield, sselect = coroutine.running, coroutine.yield, socket.select
local function connect(sock, address, port)
    local result, msg = sock:connect(address, port)
    if msg == "timeout" and running() ~= nil then
        local writeable = {sock}
        local _, ready_write
        while ready_write == nil or not ready_write[sock] do
            yield()
            _, ready_write = sselect(nil, writeable, 0)
        end

        return 1
    end

    return result, msg
end

local function dohandshake(sock)
	local result, msg = sock:dohandshake()
	if running() ~= nil then
		local socktab = {sock}
		while not result and (msg == "wantread" or msg == "wantwrite") do
			local readable, writeable = msg == "wantread" and socktab or nil, msg == "wantwrite" and socktab or nil
			while true do
				local ready_read, ready_write = sselect(readable, writeable, 0)
				if (ready_read ~= nil and ready_read[sock]) or (ready_write ~= nil and ready_write[sock]) then
					break
				end

				yield()
			end

			result, msg = sock:dohandshake()
		end
	end

	return result, msg
end

-- Return a function which performs the SSL/TLS connection.
local function tcp(params)
	params = params or {}
	-- Default settings
	for k, v in pairs(cfg) do 
		params[k] = params[k] or v
	end
	-- Force client mode
	params.mode = "client"
	-- 'create' function for LuaSocket
	return function()
		local conn = {}
		conn.sock = try(socket.tcp())
		local st = getmetatable(conn.sock).__index.settimeout
		function conn:settimeout(...)
			return st(self.sock, ...)
		end
		-- Replace TCP's connection function
		function conn:connect(host, port)
			local hasco = running() ~= nil
			if hasco then try(st(self.sock, 0)) end
			try(connect(self.sock, host, port))
			self.sock = try(ssl.wrap(self.sock, params))
			if hasco then try(self.sock:settimeout(0)) end
			try(dohandshake(self.sock))
			reg(self)

			local receive = getmetatable(self.sock).__index.receive
			local yield = coroutine.yield
			function self:receive(pattern, prefix)
				local result, msg, partial = receive(self.sock, pattern, prefix)

				if running() ~= nil then
					while result == nil and #partial == 0 and msg ~= "closed" do
						yield()
						result, msg, partial = receive(self.sock, pattern, prefix)
					end

					if result == nil and #partial > 0 then
						return partial, msg
					end
				end

				return result, msg, partial
			end

			return 1
		end
		return conn
	end
end

--------------------------------------------------------------------
-- Main Function
--------------------------------------------------------------------

-- Make a HTTP request over secure connection.  This function receives
--  the same parameters of LuaSocket's HTTP module (except 'proxy' and
--  'redirect') plus LuaSec parameters.
--
-- @param url mandatory (string or table)
-- @param body optional (string)
-- @return (string if url == string or 1), code, headers, status
--
local function request(url, body)
	local result_table = {}
	local stringrequest = type(url) == "string"
	if stringrequest then
		url = urlstring_totable(url, body, result_table)
	else
		url.url = default_https_port(url.url)
	end
	if http.PROXY or url.proxy then
		return nil, "proxy not supported"
	elseif url.redirect then
		return nil, "redirect not supported"
	elseif url.create then
		return nil, "create function not permitted"
	end
	-- New 'create' function to establish a secure connection
	url.create = tcp(url)
	local res, code, headers, status = http.request(url)
	if res and stringrequest then
		return table.concat(result_table), code, headers, status
	end
	return res, code, headers, status
end

--------------------------------------------------------------------------------
-- Export module
--

_M.request = request

ssl.https = _M

return _M
