#include <sourcemod>
#include <sdktools>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source Race Pudge",
	author = "necavi",
	description = "A powerful disease-based race",
	version = "0.1",
	url = "http://necavi.org/"
}

new thisRaceID;

new Float:g_fDismemberIncrease[] = {0.0, 0.1, 0.2, 0.3, 0.4};

new g_iCrystalBeam;
new g_iHaloIndex;

new SKILL_ROT, SKILL_FLESHHEAP, SKILL_DISMEMBER, ULT_MEATHOOK;

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num == 10)
	{
		thisRaceID = War3_CreateNewRace("Pudge", "pudge");
		SKILL_ROT = War3_AddRaceSkill(thisRaceID, "Rot", "Create a toxic cloud to damage and slow the enemy.", false, 4);
		SKILL_FLESHHEAP = War3_AddRaceSkill(thisRaceID, "Flesh Heap", "Increases your maxhealth for every unit killed near you.", false, 4);
		SKILL_DISMEMBER = War3_AddRaceSkill(thisRaceID, "Dismember", "Increases all damage done.", false, 4);
		ULT_MEATHOOK = War3_AddRaceSkill(thisRaceID, "Meat Hook", "Launches a hook in a line, if it hits a player it will drag them towards you.", true, 4); 
		
		War3_CreateRaceEnd(thisRaceID);
	}
}
public OnMapStart()
{
	g_iHaloIndex = War3_PrecacheHaloSprite();
	g_iCrystalBeam = PrecacheModel("materials/sprites/crystal_beam1.vmt");
	PrecacheModel("models/Combine_Scanner.mdl");
}
public OnRaceChanged(client, oldrace, newrace)
{
	if(newrace == thisRaceID)
	{
		EnableSkills(client);
	}
	else if(oldrace == thisRaceID)
	{
		DisableSkills(client);
	}
}
public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client) == thisRaceID)
	{
		EnableSkills(client);
	} 
	else 
	{
		DisableSkills(client);
	}
}
public OnAbilityCommand(client, ability, bool:pressed)
{
	CreateToxicCloud(client);
}
public OnUltimateCommand(client, race, bool:pressed)
{
	CreateMeatHook(client);
}
public Action:Timer_KillCloud(Handle:timer, any:entref)
{
	new cloud = EntRefToEntIndex(entref);
	if(cloud > 0)
	{
		AcceptEntityInput(cloud, "kill");
	}
}
EnableSkills(client)
{
	War3_SetBuff(client, fDamageModifier, thisRaceID, g_fDismemberIncrease[War3_GetSkillLevel(client, thisRaceID, SKILL_DISMEMBER)]);
}
DisableSkills(client)
{
	War3_SetBuff(client, fDamageModifier, thisRaceID, 0.0);
}
CreateMeatHook(client)
{
	new hook = CreateEntityByName("prop_dynamic");
	if(hook > 0)
	{
		
	}
}
CreateToxicCloud(client)
{
	new cloud = CreateEntityByName("env_steam");
	if(cloud > 0)
	{
		DispatchKeyValue(cloud, "InitialState", "1");
		DispatchKeyValue(cloud, "rendercolor", "0 255 0");
		DispatchKeyValue(cloud,"targetname", "cloud");
		DispatchKeyValue(cloud, "parentname", "player");
		DispatchKeyValue(cloud,"SpawnFlags", "1");
		DispatchKeyValue(cloud, "angles", "270 0 0");
		DispatchKeyValue(cloud,"Type", "0");
		DispatchKeyValue(cloud,"InitialState", "1");
		DispatchKeyValue(cloud,"Spreadspeed", "20");
		DispatchKeyValue(cloud,"Speed", "100");
		DispatchKeyValue(cloud,"Startsize", "1000");
		DispatchKeyValue(cloud,"EndSize", "1000");
		DispatchKeyValue(cloud,"Rate", "15");
		DispatchKeyValue(cloud,"JetLength", "150");
		DispatchKeyValue(cloud,"RenderAmt", "180");
		new Float:vec[3];
		GetClientAbsOrigin(client, vec);
		DispatchSpawn(cloud);
		AcceptEntityInput(cloud, "enable");
		TeleportEntity(cloud, vec, NULL_VECTOR, NULL_VECTOR);
		TE_SetupBeamLaser(client, cloud, g_iCrystalBeam, g_iHaloIndex, 0, 0, 20.0, 10.0, 15.0, 10, 15.0, {0, 255, 0, 255}, 0);
		TE_SendToAll();
		CreateTimer(60.0, Timer_KillCloud, EntIndexToEntRef(cloud));
	}
}






