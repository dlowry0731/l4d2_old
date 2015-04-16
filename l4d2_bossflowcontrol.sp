#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2_direct>
#include <l4d2lib>

new iTankFlow;

public Plugin:myinfo = {
	name        = "L4D2 Boss Flow Control",
	author      = "DLowry",
	version     = "1.1a",
	description = "Accurately announces and bans boss flow percents"
};

new Handle:g_hVSBossBuffer;

public OnPluginStart() {
	g_hVSBossBuffer = FindConVar("versus_boss_buffer");
	RegConsoleCmd("sm_tank", TankCmd);
	HookEvent("player_left_start_area", EventHook:LeftStartAreaEvent, EventHookMode_PostNoCopy);
}

public LeftStartAreaEvent( ) {
	new roundNumber = GameRules_GetProp("m_bInSecondHalfOfRound") ? 1 : 0;
	
	iTankFlow = RoundToNearest(GetTankFlow(roundNumber)*100);
	
	AdjustTankFlow();
		
	if(L4D2Direct_GetVSTankToSpawnThisRound(roundNumber))
	{
		PrintToChatAll("Tank Spawn: %d%%", iTankFlow);
	}
	if(L4D2Direct_GetVSWitchToSpawnThisRound(roundNumber))
	{
		PrintToChatAll("Witch Spawn: %d%%", RoundToNearest(GetWitchFlow(roundNumber)*100));
	}
}


public Action:TankCmd(client, args) {
	new roundNumber = GameRules_GetProp("m_bInSecondHalfOfRound") ? 1 : 0;
	if(L4D2Direct_GetVSTankToSpawnThisRound(roundNumber))
	{
		ReplyToCommand(client, "Tank Spawn: %d%%", RoundToNearest(GetTankFlow(roundNumber)*100));
	}
	if(L4D2Direct_GetVSWitchToSpawnThisRound(roundNumber))
	{
		ReplyToCommand(client, "Witch Spawn: %d%%", RoundToNearest(GetWitchFlow(roundNumber)*100));
	}
}

Float:GetTankFlow(roundNumber)
{
	return L4D2Direct_GetVSTankFlowPercent(roundNumber) - 
		( GetConVarInt(g_hVSBossBuffer) / L4D2Direct_GetMapMaxFlowDistance() );
}

Float:GetWitchFlow(roundNumber)
{
	return L4D2Direct_GetVSWitchFlowPercent(roundNumber) - 
		( GetConVarInt(g_hVSBossBuffer) / L4D2Direct_GetMapMaxFlowDistance() );
}

AdjustTankFlow() 
{
	new minFlow = L4D2_GetMapValueInt("tank_ban_flow_min", -1);
	new maxFlow = L4D2_GetMapValueInt("tank_ban_flow_max", -1);
	new roundNumber = GameRules_GetProp("m_bInSecondHalfOfRound") ? 1 : 0;
	
	if ( minFlow == -1 || maxFlow == -1 || maxFlow < minFlow ) {
		return;
}
	
	if ( iTankFlow < minFlow || iTankFlow > maxFlow ) {
		return;
}

	LogMessage("Found a banned tank spawn at %d (banned area: %d to %d)",
	iTankFlow, minFlow, maxFlow);

	minFlow = minFlow < 15 ? 15 : minFlow;
	maxFlow = maxFlow > 85 ? 85 : maxFlow;

	// XXX: Spawn the tank between 15% and 85% cutting out the banned area
	new range = maxFlow - minFlow;
	new r     = 15 + GetRandomInt(0, 70-range);
	iTankFlow = r >= minFlow ? r + range : r;
	
	new Float:flow;

	flow = float(iTankFlow)/100.0;
	
	LogMessage("Adjusted tank spawn to %d (%f)", iTankFlow, flow);
	
	L4D2Direct_SetVSTankFlowPercent( roundNumber , Float:flow );
}