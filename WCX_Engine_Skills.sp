/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

#pragma semicolon 1

new String:explosionSound1[]="war3source/particle_suck1.wav";


#define MAXWARDS 64*4 //on map LOL
#define WARDBELOW -2.0 // player is 60 units tall about (6 feet)
#define WARDABOVE 160.0

new BeamSprite;
new HaloSprite;
new ExplosionModel;
new SuicidedAsTeam[MAXPLAYERSCUSTOM];
new Float:SuicideLocation[MAXPLAYERSCUSTOM][3];
new bool:SuicideEffects[MAXPLAYERSCUSTOM];
new SuicideTeam[MAXPLAYERSCUSTOM];
new Float:SuicideRadius[MAXPLAYERSCUSTOM];
new Float:SuicideDamage[MAXPLAYERSCUSTOM];

new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERSCUSTOM][3];
new Float:teleportpos[MAXPLAYERSCUSTOM][3];
new bool:inteleportcheck[MAXPLAYERSCUSTOM];


new String:teleportSound[]="war3source/blinkarrival.wav";

public Plugin:myinfo = 
{
	name = "WCX - Skills Engine",
	author = "necavi, Anthony Iacono",
	description = "Provides natives for use with War3 mod",
	version = "0.1",
	url = "http://0xf.org"
}

public OnPluginStart()
{
	if(War3_GetGame()==Game_TF)
	{
		ExplosionModel=PrecacheModel("materials/particles/explosion/explosionfiresmoke.vmt",false);
		PrecacheSound("weapons/explode1.wav",false);
	}
	else
	{
		ExplosionModel=PrecacheModel("materials/sprites/zerogxplode.vmt",false);
		PrecacheSound("weapons/explode5.wav",false);
	}
	
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	
	War3_PrecacheSound(explosionSound1);
	
	War3_PrecacheSound(teleportSound);
}
public OnWar3EventSpawn(client)
{
	SuicidedAsTeam[client] = GetClientTeam(client);
}

public bool:InitNativesForwards()
{
	CreateNative("War3_SuicideBomber",Native_War3_SuicideBomber);
	CreateNative("War3_Teleport",Native_War3_Teleport);
	return true;
}


//Suicide Bomber

public Native_War3_SuicideBomber(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	if(SuicidedAsTeam[client]!=GetClientTeam(client))
		return;
	SuicideRadius[client] = Float:GetNativeCell(4);
	SuicideTeam[client] = GetClientTeam(client);
	GetNativeArray(2,SuicideLocation[client],3);
	SuicideDamage[client] = Float:GetNativeCell(3);
	if(numParams==5)
	{
		SuicideEffects[client] = bool:GetNativeCell(5);
	} else {
		SuicideEffects[client] = false;
	}
	CreateTimer(0.15,SuicideAction,client);
}

public Action:SuicideAction(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		new Float:radius = SuicideRadius[client];
		new our_team = SuicideTeam[client];
		if(SuicideEffects[client])
		{
			TE_SetupExplosion(SuicideLocation[client],ExplosionModel,10.0,1,0,RoundToFloor(radius),160);
			TE_SendToAll();
			if(War3_GetGame()==Game_TF){
				
				
				ThrowAwayParticle("ExplosionCore_buildings", SuicideLocation[client],  5.0);
				ThrowAwayParticle("ExplosionCore_MidAir", SuicideLocation[client],  5.0);
				ThrowAwayParticle("ExplosionCore_MidAir_underwater", SuicideLocation[client],  5.0);
				ThrowAwayParticle("ExplosionCore_sapperdestroyed", SuicideLocation[client],  5.0);
				ThrowAwayParticle("ExplosionCore_Wall", SuicideLocation[client],  5.0);
				ThrowAwayParticle("ExplosionCore_Wall_underwater", SuicideLocation[client],  5.0);
			}
			else{
				SuicideLocation[client][2]-=40.0;
			}
			
			TE_SetupBeamRingPoint(SuicideLocation[client], 10.0, radius, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, {255,255,255,33}, 120, 0);
			TE_SendToAll();
			
			new beamcolor[]={0,200,255,255}; //blue //secondary ring
			if(our_team==2)
			{ //TERRORISTS/RED in TF?
				beamcolor[0]=255;
				beamcolor[1]=0;
				beamcolor[2]=0;
				
			} //secondary ring
			TE_SetupBeamRingPoint(SuicideLocation[client], 20.0, radius+10.0, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, beamcolor, 120, 0);
			TE_SendToAll();
			
			if(War3_GetGame()==Game_TF){
				SuicideLocation[client][2]-=30.0;
			}
			else{
				SuicideLocation[client][2]+=40.0;
			}
			
			EmitSoundToAll(explosionSound1,client);
			
			if(War3_GetGame()==Game_TF){
				EmitSoundToAll("weapons/explode1.wav",client);
			}
			else{
				EmitSoundToAll("weapons/explode5.wav",client);
			}
		}
		
		new Float:location_check[3];
		for(new x=1;x<=MaxClients;x++)
		{
			if(ValidPlayer(x,true)&&client!=x)
			{
				new team=GetClientTeam(x);
				if(team==our_team)
					continue;
				
				GetClientAbsOrigin(x,location_check);
				new Float:distance=GetVectorDistance(SuicideLocation[client],location_check);
				if(distance>radius)
					continue;
				
				if(!W3HasImmunity(x,Immunity_Ultimates))
				{
					new Float:factor=(radius-distance)/radius;
					new damage;
					damage=RoundFloat(SuicideDamage[client]*factor);
					War3_DealDamage(x,damage,client,_,"suicidebomber",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_PHYSICAL);
					War3_ShakeScreen(x,3.0*factor,250.0*factor,30.0);
					W3FlashScreen(x,RGBA_COLOR_RED);
				}
				else
				{
					PrintToConsole(client,"%T","Could not damage player {player} due to immunity",client,x);
				}
				
			}
		}
	}
}

//Teleportation







public Native_War3_Teleport(Handle:plugin,numParams)
{
	new client = GetNativeCell(client);
	if(client>0)
	{
		if(IsPlayerAlive(client)&&!inteleportcheck[client])
		{
			new Float:distance = GetNativeCell(2);
			
			new Float:angle[3];
			GetClientEyeAngles(client,angle);
			new Float:endpos[3];
			new Float:startpos[3];
			GetClientEyePosition(client,startpos);
			new Float:dir[3];
			GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
			
			ScaleVector(dir, distance);
			
			AddVectors(startpos, dir, endpos);
			
			GetClientAbsOrigin(client,oldpos[client]);
			
			
			ClientTracer=client;
			TR_TraceRayFilter(startpos,endpos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
			TR_GetEndPosition(endpos);
			
			if(enemyImmunityInRange(client,endpos)){
				W3MsgEnemyHasImmunity(client);
				return false;
			}
			
			new Float:distanceteleport=GetVectorDistance(startpos,endpos);
			if(distanceteleport<150.0){
				new String:buffer[100];
				Format(buffer, sizeof(buffer), "%T", "Distance too short.", client);
				PrintHintText(client,buffer);
				return false;
			}
			GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);///get dir again
			ScaleVector(dir, distanceteleport-33.0);
			
			AddVectors(startpos,dir,endpos);
			emptypos[0]=0.0;
			emptypos[1]=0.0;
			emptypos[2]=0.0;
			
			endpos[2]-=30.0;
			getEmptyLocationHull(client,endpos);
			
			if(GetVectorLength(emptypos)<1.0){
				new String:buffer[100];
				Format(buffer, sizeof(buffer), "%T", "NoEmptyLocation", client);
				PrintHintText(client,buffer);
				return false; //it returned 0 0 0
			}
			
			
			TeleportEntity(client,emptypos,NULL_VECTOR,NULL_VECTOR);
			EmitSoundToAll(teleportSound,client);
			EmitSoundToAll(teleportSound,client);
			
			
			
			teleportpos[client][0]=emptypos[0];
			teleportpos[client][1]=emptypos[1];
			teleportpos[client][2]=emptypos[2];
			
			inteleportcheck[client]=true;
			CreateTimer(0.14,checkTeleport,client);
			
			
			
			
			
			
			return true;
		}
	}
	return false;
}
public Action:checkTeleport(Handle:h,any:client){
	inteleportcheck[client]=false;
	new Float:pos[3];
	
	GetClientAbsOrigin(client,pos);
	
	if(GetVectorDistance(teleportpos[client],pos)<0.001)//he didnt move in this 0.1 second
	{
		TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
		PrintHintText(client,"%T","CantTeleportHere",client);
	}
	else{
		
		
		PrintHintText(client,"%T","Teleported",client);
		
	}
}
public bool:AimTargetFilter(entity,mask)
{
	return !(entity==ClientTracer);
}


new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};//,27,-27,30,-30,33,-33,40,-40}; //for human it needs to be smaller

public bool:getEmptyLocationHull(client,Float:originalpos[3]){
	
	
	new Float:mins[3];
	new Float:maxs[3];
	GetClientMins(client,mins);
	GetClientMaxs(client,maxs);
	
	new absincarraysize=sizeof(absincarray);
	
	new limit=5000;
	for(new x=0;x<absincarraysize;x++){
		if(limit>0){
			for(new y=0;y<=x;y++){
				if(limit>0){
					for(new z=0;z<=y;z++){
						new Float:pos[3]={0.0,0.0,0.0};
						AddVectors(pos,originalpos,pos);
						pos[0]+=float(absincarray[x]);
						pos[1]+=float(absincarray[y]);
						pos[2]+=float(absincarray[z]);
						
						TR_TraceHullFilter(pos,pos,mins,maxs,MASK_SOLID,CanHitThis,client);
						//new ent;
						if(!TR_DidHit(_))
						{
							AddVectors(emptypos,pos,emptypos); ///set this gloval variable
							limit=-1;
							break;
						}
						
						if(limit--<0){
							break;
						}
					}
					
					if(limit--<0){
						break;
					}
				}
			}
			
			if(limit--<0){
				break;
			}
			
		}
		
	}
	
} 

public bool:CanHitThis(entityhit, mask, any:data)
{
	if(entityhit == data )
	{// Check if the TraceRay hit the itself.
		return false; // Don't allow self to be hit, skip this result
	}
	if(ValidPlayer(entityhit)&&ValidPlayer(data)&&War3_GetGame()==Game_TF&&GetClientTeam(entityhit)==GetClientTeam(data)){
		return false; //skip result, prend this space is not taken cuz they on same team
	}
	return true; // It didn't hit itself
}


public bool:enemyImmunityInRange(client,Float:playerVec[3])
{
	//ELIMINATE ULTIMATE IF THERE IS IMMUNITY AROUND
	new Float:otherVec[3];
	new team = GetClientTeam(client);
	
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates))
		{
			GetClientAbsOrigin(i,otherVec);
			if(GetVectorDistance(playerVec,otherVec)<350)
			{
				return true;
			}
		}
	}
	return false;
}             

