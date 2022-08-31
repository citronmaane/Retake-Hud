// Der kan blive fundet fejl! De vil blive fikset i løbet af tiden

// Include
#include <sourcemod>
#include <sdktools>
#include <cstrike>

// Pragma
#pragma semicolon 1
#pragma newdecls required

// Define
#define MESSAGE_PREFIX "[\x04RETAKE - DANSK\x01]"
#define STYLE_HUD "1"
#define STYLE_HINT "2"
#define STYLE_CHAT "3"

// Handle
Handle cvar_autoplant_enabled = null;
Handle cvar_retakes_enabled = null;
Handle cvar_plugin_enabled = null;
Handle cvar_style = null;

Handle cvar_red = null;
Handle cvar_green = null;
Handle cvar_blue = null;
Handle cvar_fadein = null;
Handle cvar_fadeout = null;
Handle cvar_xcord = null;
Handle cvar_ycord = null;
Handle cvar_holdtime = null;
Handle cvar_showterrorists = null;

// Bool / Char
bool autoplantEnabled = false;
bool retakesEnabled = false;
bool pluginEnabled;
char style[8];

bool showTerrorists;
int red;
int green;
int blue;
float fadein;
float fadeout;
float holdtime;
float xcord;
float ycord;

// Sites
enum 
{
	BOMBSITE_INVALID = -1,
	BOMBSITE_A = 0,
	BOMBSITE_B = 1
}

int bomber = -1;
int bombsite = BOMBSITE_INVALID;

public Plugin myinfo =
{
	name = "RETAKE HUD ( DANSK )",
	description = "Retake HUD system. Nemt at sætte op.",
};

// Indstillinger
public void OnPluginStart()
{
	LoadTranslations("retake-dansk.phrases");

	cvar_plugin_enabled = CreateConVar("sm_retakes_hud_enabled", "1", "Skal HUD'en vises?", _, true, 0.0, true, 1.0);
	cvar_style = CreateConVar("sm_retakes_hud_style", "1", "1: HUD, 2: Hint Text, 3: Chat | You can also use multiple by doing 123", _, true, 0.0, true, 123.0);
	
	cvar_red = CreateConVar("sm_retakes_hud_red", "255", "Hvor meget rød vil du have?", _, true, 0.0, true, 255.0);
	cvar_green = CreateConVar("sm_retakes_hud_green", "255", "Hvor meget grønt vil du have?", _, true, 0.0, true, 255.0);
	cvar_blue = CreateConVar("sm_retakes_hud_blue", "255", "Hvor meget blåt vil du have?", _, true, 0.0, true, 255.0);
	cvar_fadein = CreateConVar("sm_retakes_hud_fade_in", "0.5", "Hvor lang tid skal Fade-in animationen være? (Sekunder)", _, true, 0.0);
	cvar_fadeout = CreateConVar("sm_retakes_hud_fade_out", "0.5", "Hvor lang tid skal Fade-Out animationen være? (Sekunder)", _, true, 0.0);
	cvar_holdtime = CreateConVar("sm_retakes_hud_time", "5.0", "Sekunder som HUD bliver vist i.", _, true, 1.0);
	cvar_xcord = CreateConVar("sm_retakes_hud_position_x", "0.42", "Positionen af HUD på X axis.", _, true, 0.0);
	cvar_ycord = CreateConVar("sm_retakes_hud_position_y", "0.3", "Positionen af HUD på Y axis.", _, true, 0.0);
	cvar_showterrorists = CreateConVar("sm_retakes_hud_showterrorists", "1", "Skal HUD vises for T Sitet?", _, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "retakes_hud");
	
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_Pre);
}

public void OnAllPluginsLoaded()
{
	cvar_autoplant_enabled = FindConVar("sm_autoplant_enabled");
	cvar_retakes_enabled = FindConVar("sm_retakes_enabled");
}

public void OnConfigsExecuted()
{
	if (cvar_autoplant_enabled != null)
	{
		autoplantEnabled = GetConVarBool(cvar_autoplant_enabled);
	}
	
	if (cvar_retakes_enabled != null)
	{
		retakesEnabled = GetConVarBool(cvar_retakes_enabled);
	}
	
	pluginEnabled = GetConVarBool(cvar_plugin_enabled);
	showTerrorists = GetConVarBool(cvar_showterrorists);
	GetConVarString(cvar_style, style, sizeof(style));
	red = GetConVarInt(cvar_red);
	green = GetConVarInt(cvar_green);
	blue = GetConVarInt(cvar_blue);
	fadein = GetConVarFloat(cvar_fadein);
	fadeout = GetConVarFloat(cvar_fadeout);
	holdtime = GetConVarFloat(cvar_holdtime);
	xcord = GetConVarFloat(cvar_xcord);
	ycord = GetConVarFloat(cvar_ycord);
}

public void Event_OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if (!pluginEnabled || !retakesEnabled || IsWarmup())
	{
		return;
	}
	
	bomber = GetBomber();
	
	if (!IsValidClient(bomber))
	{
		return;
	}
	
	bombsite = GetNearestBombsite(bomber);
	
	if (bombsite != BOMBSITE_INVALID)
	{
		CreateTimer(1.0, displayHud);
	}
}

public Action displayHud(Handle timer)
{
	char bombsiteStr[1];
	bombsiteStr = bombsite == BOMBSITE_A ? "A" : "B";
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
		{
			continue;
		}
		
		int clientTeam = GetClientTeam(i);
		char message[64];
		
		if (!autoplantEnabled && i == bomber)
		{
			Format(message, sizeof(message), "%T", "Plant", i);
		}
		else if (clientTeam == CS_TEAM_CT || (clientTeam == CS_TEAM_T && showTerrorists))
		{
			Format(message, sizeof(message), "%T", clientTeam == CS_TEAM_T ? "Beskyt" : "Angrib", i, bombsiteStr);
		}
		
		if (StrContains(style, STYLE_HUD) != -1)
		{
			SetHudTextParams(xcord, ycord, holdtime, red, green, blue, 255, 0, 0.25, fadein, fadeout);
			ShowHudText(i, 5, "%s", message);
		}
		
		if (StrContains(style, STYLE_HINT) != -1)
		{
			PrintHintText(i, "%s", message);
		}
		
		if (StrContains(style, STYLE_CHAT) != -1)
		{
			if (clientTeam == CS_TEAM_CT || clientTeam == CS_TEAM_T)
			{
				PrintToChat(i, "%s %s", MESSAGE_PREFIX, message);
			}
		}
	}
}

stock bool IsWarmup()
{
	return GameRules_GetProp("m_bWarmupPeriod") == 1;
}

stock int GetBomber()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && HasBomb(i))
		{
			return i;
		}
	}
	
	return -1;
}

stock bool HasBomb(int client)
{
	return GetPlayerWeaponSlot(client, 4) != -1;
}

stock int GetNearestBombsite(int client)
{
	int playerResource = GetPlayerResourceEntity();
	if (playerResource == INVALID_ENT_REFERENCE)
	{
		return BOMBSITE_INVALID;
	}
	
	float pos[3];
	GetClientAbsOrigin(client, pos);
	
	float aCenter[3], bCenter[3];
	GetEntPropVector(playerResource, Prop_Send, "m_bombsiteCenterA", aCenter);
	GetEntPropVector(playerResource, Prop_Send, "m_bombsiteCenterB", bCenter);
	
	float aDist = GetVectorDistance(aCenter, pos, true);
	float bDist = GetVectorDistance(bCenter, pos, true);
	
	return (aDist < bDist) ? BOMBSITE_A : BOMBSITE_B;
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}
