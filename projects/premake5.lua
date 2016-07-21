newoption({
	trigger = "gmcommon",
	description = "Sets the path to the garrysmod_common (https://github.com/danielga/garrysmod_common) directory",
	value = "path to garrysmod_common directory"
})

local gmcommon = _OPTIONS.gmcommon or os.getenv("GARRYSMOD_COMMON")
if gmcommon == nil then
	error("you didn't provide a path to your garrysmod_common (https://github.com/danielga/garrysmod_common) directory")
end

include(gmcommon)

local LUASEC_FOLDER = "../luasec"
local OPENSSL_FOLDER = os.get() .. "/OpenSSL"

CreateWorkspace({name = "ssl.core"})
	CreateProject({serverside = true})
		links({"x509", "context", "core", "luasocket"})
		IncludeLuaShared()

		filter("system:windows")
			libdirs(OPENSSL_FOLDER .. "/lib")
			links({"ws2_32", "libeay32", "ssleay32"})

		filter("system:not windows")
			linkoptions("-Wl,-Bstatic")
			pkg_config({"--cflags", "--libs", "openssl"})

	CreateProject({serverside = false})
		links({"x509", "context", "core", "luasocket"})
		IncludeLuaShared()

		filter("system:windows")
			libdirs(OPENSSL_FOLDER .. "/lib")
			links({"ws2_32", "libeay32", "ssleay32"})

		filter("system:not windows")
			linkoptions("-Wl,-Bstatic")
			pkg_config({"--cflags", "--libs", "openssl"})

	project("luasocket")
		kind("StaticLib")
		warnings("Off")
		includedirs(LUASEC_FOLDER .. "/src/luasocket")
		files({
			LUASEC_FOLDER .. "/src/luasocket/buffer.c",
			LUASEC_FOLDER .. "/src/luasocket/io.c",
			LUASEC_FOLDER .. "/src/luasocket/timeout.c"
		})
		vpaths({["Source files"] = LUASEC_FOLDER .. "/src/luasocket/**.c"})
		IncludeLuaShared()

		filter("system:windows")
			files(LUASEC_FOLDER .. "/src/luasocket/wsocket.c")

		filter("system:not windows")
			files(LUASEC_FOLDER .. "/src/luasocket/usocket.c")

	project("core")
		kind("StaticLib")
		warnings("Off")
		includedirs(LUASEC_FOLDER .. "/src")
		files(LUASEC_FOLDER .. "/src/ssl.c")
		vpaths({["Source files"] = LUASEC_FOLDER .. "/src/**.c"})
		IncludeLuaShared()

		filter("system:windows")
			includedirs(OPENSSL_FOLDER .. "/include")

	project("context")
		kind("StaticLib")
		warnings("Off")
		includedirs(LUASEC_FOLDER .. "/src")
		files(LUASEC_FOLDER .. "/src/context.c")
		vpaths({["Source files"] = LUASEC_FOLDER .. "/src/**.c"})
		IncludeLuaShared()

		filter("system:windows")
			includedirs(OPENSSL_FOLDER .. "/include")

	project("x509")
		kind("StaticLib")
		warnings("Off")
		includedirs(LUASEC_FOLDER .. "/src")
		files(LUASEC_FOLDER .. "/src/x509.c")
		vpaths({["Source files"] = LUASEC_FOLDER .. "/src/**.c"})
		IncludeLuaShared()

		filter("system:windows")
			includedirs(OPENSSL_FOLDER .. "/include")
