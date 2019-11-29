/*  
*    Ability to intercept music cmds sent to clients in l4d2
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
#include <dhooks>

#pragma newdecls required

#define GAMEDATA "musiccmdfilter"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "MusicCmdFilter",
	author = "Lux",
	description = "Ability to intercept music cmds sent to clients in l4d2",
	version = "1.0",
	url = "-"
};

StringMap hMusicFilterKeys;

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if(hGamedata == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	Handle hDetour;
	hDetour = DHookCreateFromConf(hGamedata, "Music::Play");
	if(!hDetour)
		SetFailState("Failed to find \"Music::Play\" signature.");
	
	if(!DHookEnableDetour(hDetour, false, MusicFilter))
		SetFailState("Failed to detour \"Music::Play\".");
		
	delete hGamedata;
	
	CreateMusicHashMapFilter();
}

public MRESReturn MusicFilter(Handle hParams)
{
	bool bPlayNoTank;
	static char sMusicKey[256];
	DHookGetParamString(hParams, 1, sMusicKey, sizeof(sMusicKey));
	
	if(!hMusicFilterKeys.GetValue(sMusicKey, bPlayNoTank))
		return MRES_Ignored;
	
	if(bPlayNoTank && !IsATankAlive())
		return MRES_Ignored;
	return MRES_Supercede;
}

void CreateMusicHashMapFilter()
{
	hMusicFilterKeys = CreateTrie();
	hMusicFilterKeys.SetValue("Event.WitchAttack", true);
	hMusicFilterKeys.SetValue("Event.WitchBurning", true);
	hMusicFilterKeys.SetValue("Event.HunterHit", false);
	hMusicFilterKeys.SetValue("Event.SmokerChokeHit", false);
	hMusicFilterKeys.SetValue("Event.SmokerDragHit", false);
	hMusicFilterKeys.SetValue("Event.BoomerHit", false);
	hMusicFilterKeys.SetValue("Event.ChargerHit", false);
	hMusicFilterKeys.SetValue("Event.ChargerSlamHit", false);
	hMusicFilterKeys.SetValue("Event.JockeyHit", false);
	hMusicFilterKeys.SetValue("Event.SpitterSpit", false);
	hMusicFilterKeys.SetValue("Event.LedgeHangTwoHandsHit", false);
	hMusicFilterKeys.SetValue("Event.LedgeHangOneHandHit", false);
	hMusicFilterKeys.SetValue("Event.Down", false);
	hMusicFilterKeys.SetValue("Event.DownHit", false);
	hMusicFilterKeys.SetValue("Event.BleedingOut", false);
	hMusicFilterKeys.SetValue("Event.BleedingOutHit", false);
	hMusicFilterKeys.SetValue("Event.SurvivorDeath", false);
	hMusicFilterKeys.SetValue("Event.SurvivorDeathHit", false);
	hMusicFilterKeys.SetValue("Event.Down_L4D1", false);
	hMusicFilterKeys.SetValue("Event.DownHit_L4D1", false);
	hMusicFilterKeys.SetValue("Event.BleedingOut_L4D1", false);
	hMusicFilterKeys.SetValue("Event.BleedingOutHit_L4D1", false);
	hMusicFilterKeys.SetValue("Event.SurvivorDeath_L4D1", false);
	hMusicFilterKeys.SetValue("Event.SurvivorDeathHit_L4D1", false);
}

bool IsATankAlive()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 3 && 
			IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == 8)
			return true;
	}
	return false;
}
