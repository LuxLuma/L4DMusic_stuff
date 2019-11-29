/*  
*    Fixes for gamebreaking bugs and stupid gameplay aspects
*    Copyright (C) 2019  LuxLuma		acceliacat@gmail.com
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU General Public License as published by
*    the Free Software Foundation, either version 3 of the License, or
*    (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.
*
*    You should have received a copy of the GNU General Public License
*    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define REQUIRE_EXTENSIONS
#include <dhooks>
#undef REQUIRE_EXTENSIONS

#pragma newdecls required

#define PLUGIN_VERSION "0.2"

#define GAMEDATA "l4d1musicproxy"

enum L4D2_SurvivorSet
{
	L4D2_SurvivorSet_Invalid = 0,
	L4D2_SurvivorSet_L4D1,
	L4D2_SurvivorSet_L4D2,
}

L4D2_SurvivorSet CurrentSet = L4D2_SurvivorSet_Invalid;

public Plugin myinfo =
{
	name = "[L4D2]l4d1musicproxy",
	author = "Lux",
	description = "restores music in l4d1 missions while using l4d2 survivor set(don't work if mission.txt edited)",
	version = PLUGIN_VERSION,
	url = "-"
};

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if(hGamedata == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	Handle hDetour;
	hDetour = DHookCreateFromConf(hGamedata, "Music::IsL4D1");
	if(!hDetour)
		SetFailState("Failed to find \"Music::IsL4D1\" signature.");
	
	if(!DHookEnableDetour(hDetour, true, IsL4D1))
		SetFailState("Failed to detour \"Music::IsL4D1\".");
	
	hDetour = DHookCreateFromConf(hGamedata, "CTerrorGameRules::GetSurvivorSet");
	if(!hDetour)
		SetFailState("Failed to setup detour for CTerrorGameRules::GetSurvivorSet");
	
	if(!DHookEnableDetour(hDetour, true, OnGetSurvivorSet))
		SetFailState("Failed to detour \"CTerrorGameRules::GetSurvivorSet\".");
		
	delete hGamedata;
	
}

public MRESReturn IsL4D1(Handle hReturn)
{
	if(CurrentSet == L4D2_SurvivorSet_L4D1)
	{
		DHookSetReturn(hReturn, true);
	}
	else
	{
		DHookSetReturn(hReturn, false);
	}
	return MRES_Override;
}

public MRESReturn OnGetSurvivorSet(Handle hReturn)
{
	CurrentSet = DHookGetReturn(hReturn);
	return MRES_Ignored;
}
