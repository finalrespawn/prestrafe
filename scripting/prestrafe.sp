#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "Prestrafe",
	author = "Clarkey",
	description = "Simple prestrafe for CS:GO.",
	version = "1.0",
	url = "http://finalrespawn.com"
};

bool g_bSlowing[MAXPLAYERS + 1];

float g_fLastLook[MAXPLAYERS + 1][3];

int g_iTickCounter[MAXPLAYERS + 1];
int g_iSlowDelay;

public void OnPluginStart()
{
	float TickRate = 1.0 / GetTickInterval();
	g_iSlowDelay = RoundFloat(TickRate) / 2;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	bool LookingLeft, LookingRight;
	float Look[3];
	GetClientEyeAngles(client, Look);
	
	if (Look[1] < 0)
		Look[1] += 360.0;
		
	LookingLeft = false;
	LookingRight = false;
	
	if (Look[1] > g_fLastLook[client][1])
		LookingLeft = true;
	else if (Look[1] < g_fLastLook[client][1])
		LookingRight = true;
		
	g_fLastLook[client] = Look;
	
	if ((((buttons & IN_FORWARD) && (buttons & IN_MOVELEFT) && LookingLeft)
	|| ((buttons & IN_FORWARD) && (buttons & IN_MOVERIGHT) && LookingRight))
	&& (GetEntityFlags(client) & FL_ONGROUND))
	{
		float Velocity[3], Speed;
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", Velocity);
		Speed = SquareRoot(Pow(Velocity[0], 2.0) + Pow(Velocity[1], 2.0));
		
		if ((Speed >= 175.0) && !g_bSlowing[client])
		{
			g_bSlowing[client] = true;
			g_iTickCounter[client] = 0;
		}
		
		if (!g_bSlowing[client])
		{
			SetEntPropFloat(client, Prop_Send, "m_flVelocityModifier", 1.1);
		}
	}
	
	if (g_bSlowing[client])
		SlowDown(client);
		
	return Plugin_Continue;
}

stock void SlowDown(int client)
{
	float VelocityModifier = (0.1 / g_iSlowDelay) * g_iTickCounter[client];
	VelocityModifier = 1.1 - VelocityModifier;
	SetEntPropFloat(client, Prop_Send, "m_flVelocityModifier", VelocityModifier);
	
	if (g_iTickCounter[client] == g_iSlowDelay)
	{
		g_bSlowing[client] = false;
		SetEntPropFloat(client, Prop_Send, "m_flVelocityModifier", 1.0);
	}
	
	g_iTickCounter[client]++;
}