-- empty file that fools luasec into thinking we exist
local ssl = require("ssl.core") or ssl
return ssl.context
