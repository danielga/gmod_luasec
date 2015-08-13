newoption({
	trigger = "gmcommon",
	description = "Sets the path to the garrysmod_common (https://bitbucket.org/danielga/garrysmod_common) directory",
	value = "path to garrysmod_common dir"
})

local gmcommon = _OPTIONS.gmcommon or os.getenv("GARRYSMOD_COMMON")
if gmcommon == nil then
	error("you didn't provide a path to your garrysmod_common (https://bitbucket.org/danielga/garrysmod_common) directory")
end

include(gmcommon)

local LUASEC_FOLDER = "../luasec"
local OPENSSL_FOLDER = os.get() .. "/OpenSSL"

CreateSolution("ssl.core")
	CreateProject(SERVERSIDE, SOURCES_MANUAL)
		AddFiles("main.cpp")
		IncludeLuaShared()
		links({"luasocket", "core", "context", "x509"})

		filter("system:windows")
			libdirs(OPENSSL_FOLDER .. "/lib")
			links({"ws2_32", "libeay32", "ssleay32"})

		filter("system:not windows")
			pkg_config({"--cflags", "--static", "--libs", "openssl"})

	CreateProject(CLIENTSIDE, SOURCES_MANUAL)
		AddFiles("main.cpp")
		IncludeLuaShared()
		links({"luasocket", "core", "context", "x509"})

		filter("system:windows")
			libdirs(OPENSSL_FOLDER .. "/lib")
			links({"ws2_32", "libeay32", "ssleay32"})

		filter("system:not windows")
			pkg_config({"--cflags", "--static", "--libs", "openssl"})

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
		includedirs({LUASEC_FOLDER .. "/src", OPENSSL_FOLDER .. "/include"})
		files(LUASEC_FOLDER .. "/src/ssl.c")
		vpaths({["Source files"] = LUASEC_FOLDER .. "/src/**.c"})
		IncludeLuaShared()

	project("context")
		kind("StaticLib")
		warnings("Off")
		includedirs({LUASEC_FOLDER .. "/src", OPENSSL_FOLDER .. "/include"})
		files(LUASEC_FOLDER .. "/src/context.c")
		vpaths({["Source files"] = LUASEC_FOLDER .. "/src/**.c"})
		IncludeLuaShared()

	project("x509")
		kind("StaticLib")
		warnings("Off")
		includedirs({LUASEC_FOLDER .. "/src", OPENSSL_FOLDER .. "/include"})
		files(LUASEC_FOLDER .. "/src/x509.c")
		vpaths({["Source files"] = LUASEC_FOLDER .. "/src/**.c"})
		IncludeLuaShared()
