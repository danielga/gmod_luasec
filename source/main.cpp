#include <GarrysMod/Lua/Interface.h>
#include <lua.hpp>

extern "C" int luaopen_ssl_core( lua_State *state );
extern "C" int luaopen_ssl_context( lua_State *state );
extern "C" int luaopen_ssl_x509( lua_State *state );

GMOD_MODULE_OPEN( )
{
	if( luaopen_ssl_core( LUA->GetState( ) ) == 1 )
	{
		lua_replace( LUA->GetState( ), 1 );
		lua_settop( LUA->GetState( ), 1 );
		LUA->Push( -1 );
		LUA->SetField( GarrysMod::Lua::INDEX_GLOBAL, "ssl" );
	}

	if( luaopen_ssl_context( LUA->GetState( ) ) == 1 )
	{
		lua_replace( LUA->GetState( ), 2 );
		lua_settop( LUA->GetState( ), 2 );
		LUA->SetField( -2, "context" );
	}

	if( luaopen_ssl_x509( LUA->GetState( ) ) == 1 )
	{
		lua_replace( LUA->GetState( ), 2 );
		lua_settop( LUA->GetState( ), 2 );
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
