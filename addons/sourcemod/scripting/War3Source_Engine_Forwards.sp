#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Forwards",
    author = "War3Source Team",
    description = "War3Source Forward Engine"
};

public bool:InitNativesForwards()
{
	CreateNative("War3_CreateForward", Native_CreateForward);
}
public Native_CreateForward(Handle:plugin, numParams)
{
	
}