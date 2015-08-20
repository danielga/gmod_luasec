#include <GarrysMod/Lua/Interface.h>
#include <lua.hpp>

extern "C" int luaopen_ssl_core( lua_State *state );
extern "C" int luaopen_ssl_context( lua_State *state );
extern "C" int luaopen_ssl_x509( lua_State *state );

GMOD_MODULE_OPEN( )
{
	if( luaopen_ssl_core( state ) == 1 )
	{
		lua_replace( state, 1 );
		lua_settop( state, 1 );
		LUA->Push( -1 );
		LUA->SetField( GarrysMod::Lua::INDEX_GLOBAL, "ssl" );
	}

	if( luaopen_ssl_context( state ) == 1 )
	{
		lua_replace( state, 2 );
		lua_settop( state, 2 );
		LUA->SetField( -2, "context" );
	}

	if( luaopen_ssl_x509( state ) == 1 )
	{
		lua_replace( state, 2 );
		lua_settop( state, 2 );
		LUA->SetField( -2, "x509" );
	}

	return 1;
}

GMOD_MODULE_CLOSE( )
{
	LUA->PushNil( );
	LUA->SetField( GarrysMod::Lua::INDEX_GLOBAL, "ssl" );
	return 0;
}
