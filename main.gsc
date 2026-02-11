/*
*	 Infinity Loader :: The Best GSC IDE!
*
*	 Project : Gun Game
*	 Author : Littof
*	 Game : Project Bundle
*	 Description : Starts Multiplayer code execution!
*	 Date : 31/01/2026 23:51:41
*
*/



#ifdef WW2

#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#define STRING_BASE_ADDR = 0x04DDE650; // pointer 0x183

#redirect PlayLocalSound => method_8615;

#else

#include scripts\mp\_hud_util;
#include scripts\engine\_utility;
#include scripts\mp\_utility;

#define STRING_BASE_ADDR = 0x04280678; // pointer chain 0x15 , 0x568 , 0x28 , 0x1D0 , 0xB0 , 0x40 , 0xA8

#redirect TakeAllWeapons => method_83B7;

#endif



init()
{
    level thread onPlayerConnect();

    level.presets = [];

    level.presets["X"] = 0;
    level.presets["Y"] = 0; 

    #ifdef WW2
     
    level.prev_onplayerkilled = level.var_6B7B;
    level.var_6B7B = ::onPlayerKilled;

    level.gametype = level.var_3FDC;

	level.classicMode = ["m1911_mp" , "p38_mp" , "luger_mp",  "winchester1897_mp" ,"walther_mp", "model21_mp" , "zk383_mp" , "type100_mp" , "ppsh41_mp" , "m1garand_mp" , "bar_mp" , "sudaev_mp" , "mg42_mp" , "lewis_mp" , "bren_mp" ,"springfield_mp" , "kar98_mp" , "bazooka_mp" , "shovel_mp" , "baseballbat_mp"];
    maps\mp\_utility::func_7BF9("dm", 0);

    #else

    level.classicMode = [ "iw7_mag_mp+loot7", "iw7_nrg_mp+mod_recoil+loot39", "iw7_revolver_mpr_explosive+mod_ads_stability+loot4", "iw7_devastator_mp+mod_ammo+loot38", "iw7_mod2187_mpl+akimbomod2187l+loot35", "iw7_crb_mpl+crblscope_camo+mod_hip_spread+loot5", "iw7_mp28_mpl_fasthip+glmp28_smoke+phasesmg_camo+loot36", "iw7_ar57_mp+ar57scope_camo+mod_hip_spread+loot2" , "iw7_ake_mpl_bal+mod_hip_spread+loot8" , "iw7_m4_mpr_hb+mod_silencer_m4+loot42" , "iw7_minilmg_mpl_spooled+minilmgscope+mod_damage_range+scope1+loot6" , "iw7_unsalmg_mp+glsmoke+loot36" , "iw7_lmg03_mpl_silencer+elolmg_camo+loot8" , "iw7_ba50cal_mp+ba50calscope+mod_ads_stability_sniper+loot40" , "iw7_cheytac_mpl_silencer+cheytaclscope_camo+mod_silencer+loot35" , "iw7_cheytacc_mp+cheytacscope_camo+fmj+stocksnpr" , "iw7_lockon_mp+lockonscope_camo" , "iw7_venomx_mp+venomxalt_burst" , "iw7_axe_mpr_melee" , "iw7_katana_mp+mod_fast_melee_minor+loot3"];
    
    scripts\mp\_utility::func_DF0B("dm",0); 

    //Disable payloads
    level.var_1CAA = 0; // level.allowsupers
    SetDvar("scr_game_allowsupers", 0);
     	
    #endif    
    
    SetDynamicDvar("scr_dm_scorelimit", 0);
    SetDynamicDvar("scr_dm_winlimit", 0);
    

}

onPlayerConnect()
{
    for(;;)
    {
        level waittill("connected", player);
        player thread onPlayerSpawned();
    }
}

onPlayerSpawned()
{
    self endon("disconnect");
	level endon("game_ended");

    deathMatch =  IsDeathMatch();
    if(!deathMatch)
    {
       

        level.wrongGamemode = CreateServerText("default", 1.5, "CENTER", "CENTER", level.presets["X"], level.presets["Y"], 1, 1, "^1FFA ONLY !", (1,1,1));
        
        #ifdef WW2 
        level thread maps\mp\gametypes\_gamelogic::func_36B9("tie", "");
        #else
        level thread scripts\mp\_gamelogic::endgame("tie", "");
        #endif
    }

    CustomGameModeName();
    
    level thread DisableDropItem();
    
    for(;;)
    {
        
        self waittill("spawned_player");
        
        if(!IsDefined(self.gunGameIndex))
            self.gunGameIndex = 0;

        self thread TakeCustomClass(); 
        
        currentWeapon = level.classicMode[self.gunGameIndex];
        self thread ChangeWeapon(currentWeapon);
        
        self thread DisableStreaks();

        if(!IsDefined(self.customText))
        {
            self thread CustomHUD();
            self.customText = true;
        }
        else
        {
            self.hud["WEAPON"]["WEAPON_COUNT"] SetSafeText("Weapon : ^3"+(self.gunGameIndex + 1)+"^7/"+level.classicMode.size);
        }

        #ifdef IW

        bannedPerks = ["specialty_ghost" , "specialty_sixth_sense" , "specialty_enhanced_sixth_sense"];

        #else

        bannedPerks = ["specialty_blastshield"];
       
        #endif

        foreach(perk in bannedPerks)
        {
            if(HasPerk(self , perk))
            {
              self UnsetPerk(self , perk);
            }

        }
        

        self thread SweepingRadar();
        
    }
}

CustomGameModeName()
{
    // IW : These are the correct pointers chain for iw, but for some reason it always returns 0 when reading the base address, so I removed it.  
    // PS : If you still want to use it, wait a few seconds before writing, as the pointer chain takes about 5 to 10 seconds to initialise in mem (if you call the function in onPlayerSpawned).

    #ifdef WW2

    baseAddr = GetAddress(STRING_BASE_ADDR);
    ptr = ReadInt64(baseAddr);
    
    if(IsDefined(ptr) && ptr > 0) 
    {
        offset = ptr + 0x183;
        
        name = ReadString(offset);
        if(name != "^2Gun Game^7")
        WriteString(offset, "^2Gun Game^7");
    }
    #endif
}

CustomHUD()
{
    if(!IsDefined(self.hud["WEAPON"]))
        self.hud["WEAPON"] = [];
    
    
    self.presets = [];

    self.presets["X"] = 0;
    self.presets["Y"] = 0;

    self.hud["WEAPON"]["WEAPON_COUNT"] = self CreateText("hudbigboldi", 1.3, "CENTER", "CENTER", self.presets["X"] - 360, self.presets["Y"] - 90, 4, 1, "Weapon : ^3"+(self.gunGameIndex + 1)+"^7/"+level.classicMode.size, (1,1,1));  

}

IsDeathMatch()
{
    level.deathmatch = (level.gametype == "dm") ? true : false;
    return level.deathmatch;
}

TakeCustomClass()
{
    self TakeAllWeapons();
}

DisableStreaks()
{   
    #ifdef WW2 
    for(;;)
    {
        self SetClientOmnVar("ks_count_updated",0);
        self.var_012C["killstreaks"] = undefined;
        wait(1);
    }
    #else
    self.pers["killstreaks"] = undefined;
    #endif
	
}


#ifdef IW

// The OnPlayerKilled callback function is not present in ffa, because on IW, kill callbacks are handled differently and, for some reason, the level.var_C579 callback function does not work. So I simply hooked the function "func_C579".

hook scripts\mp\gametypes\dm::func_C579(param_00, param_01, param_02)
{
    scripts\mp\gametypes\dm::func_C579(param_00, param_01, param_02);

    attacker = param_01;

    if (param_00 == "suicide") 
    {
        if (IsDefined(attacker.gunGameIndex) && attacker.gunGameIndex > 0) 
        {
            attacker.gunGameIndex--;
            attacker thread ChangeWeapon(level.classicMode[attacker.gunGameIndex]);
            attacker thread RefreshHUD();
        }
        return;
    }

    if (!IsDefined(param_00) || !IsSubStr(param_00, "kill")) { return; }
    if (!IsDefined(attacker) || !IsPlayer(attacker)) { return; }

    sWeapon = attacker GetCurrentWeapon();
    currentWeaponRequired = level.classicMode[attacker.gunGameIndex];

    baseInHand = StrTok(sWeapon, "+")[0];
    baseRequired = StrTok(currentWeaponRequired, "+")[0];

    isMeleeKill = IsSubStr(sWeapon, "melee") || IsSubStr(sWeapon, "knife");
    
    isUsingMeleeSpec = IsSubStr(baseRequired, "axe") || IsSubStr(baseRequired, "knife") || IsSubStr(baseRequired, "katana");

    if ((baseInHand == baseRequired) || (isUsingMeleeSpec && isMeleeKill))
    {
        attacker.gunGameIndex++;

        if (attacker.gunGameIndex >= level.classicMode.size)
        {
            attacker.gunGameIndex = level.classicMode.size - 1;
            level thread scripts\mp\_gamelogic::endgame(attacker, "");
            return;
        }

        attacker PlayLocalSound("mp_war_objective_taken");
        attacker thread ChangeWeapon(level.classicMode[attacker.gunGameIndex]);
        attacker thread RefreshHUD();
    }

}

#else

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, lifeId)
{
    self [[level.prev_onplayerkilled]](eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, lifeId);

    if(sMeansOfDeath == "MOD_FALLING" || (IsDefined(attacker) && attacker == self))
    {
        if(isDefined(self.gunGameIndex) && self.gunGameIndex > 0)
        {
            if(self.gunGameIndex == (level.classicMode.size - 1))
                SetDynamicDvar("scr_" + level.gametype + "_scorelimit", 0);

            self.gunGameIndex--;
            self PlayLocalSound("mp_war_objective_lost"); 
            self thread RefreshHUD();
        }
        return; 
    }

    if(IsDefined(attacker) && IsPlayer(attacker) && attacker != self)
    {
        currentWeaponName = level.classicMode[attacker.gunGameIndex];
        
        isMeleeKill = (sMeansOfDeath == "MOD_MELEE");
        isUsingMeleeSpec = IsSubStr(currentWeaponName, "shovel") || IsSubStr(currentWeaponName, "knife") || IsSubStr(currentWeaponName, "baseballbat_mp");

        if(IsSubStr(sWeapon, currentWeaponName) || (isUsingMeleeSpec && sMeansOfDeath == "MOD_MELEE"))
        {
            if(isMeleeKill && !isUsingMeleeSpec)
            {
               
            }
            else 
            {
                if(attacker.gunGameIndex == (level.classicMode.size - 2))
                {
                    SetDynamicDvar("scr_" + level.gametype + "_scorelimit", attacker.pers["score"] + 1);
                }

                if(attacker.gunGameIndex == (level.classicMode.size - 1))
                {
                    attacker thread RefreshHUD();
                    attacker.score++;
                    attacker.pers["score"]++;
                    return; 
                }

                attacker.gunGameIndex++;
                attacker PlayLocalSound("mp_war_objective_taken");
                attacker thread RefreshHUD();
                attacker thread ChangeWeapon(level.classicMode[attacker.gunGameIndex]);
            }
        }

        if(sMeansOfDeath == "MOD_MELEE" || IsSubStr(sWeapon, "knife"))
        {
            if(self.gunGameIndex > 0)
            {
                if(self.gunGameIndex == (level.classicMode.size - 1))
                    SetDynamicDvar("scr_" + level.gametype + "_scorelimit", 0);

                self.gunGameIndex--;
                self PlayLocalSound("mp_war_objective_lost"); 
                self thread RefreshHUD();
            }
        }
    }
}

#endif


ChangeWeapon(weaponName)
{
    self endon("disconnect");
    self endon("death");

    #ifdef WW2 
    randomCamo = RandomIntRange(1, 167);
    #else
    randomCamo = RandomIntRange(1, 250);
    #endif
    
    #ifdef IW
    camoStr =  "camo" + randomCamo;
    #else
    camoStr = (randomCamo < 10) ? "camo00" + randomCamo : (randomCamo < 100 ? "camo0" + randomCamo : "camo" + randomCamo);
    #endif

    tokens = StrTok(weaponName, "+");
    baseWeapon = tokens[0];
    finalWeapon = baseWeapon; 

    // IW
    if(IsSubStr(baseWeapon, "iw7"))
    {
        //Rebuild the weapon string because the camo is before the scope.
        if(baseWeapon == "iw7_minilmg_mpl_spooled")
        {
            mods = "minilmgscope+mod_damage_range";
            scope = "scope1";
            loot = "loot6";
            
            finalWeapon = baseWeapon + "+" + mods + "+" + camoStr + "+" + scope + "+" + loot;
        }
        else 
        {
            finalWeapon = baseWeapon;
            camoInserted = false;

            if(tokens.size > 1)
            {
                for(i = 1; i < tokens.size; i++)
                {
                    if(IsSubStr(tokens[i], "loot") && !camoInserted)
                    {
                        finalWeapon += "+" + camoStr;
                        camoInserted = true;
                    }
                    finalWeapon += "+" + tokens[i];
                }
            }

            if(!camoInserted)
            finalWeapon += "+" + camoStr;
            
        }
    }
    else
    {
        // WW2
        finalWeapon = weaponName + "+" + camoStr;
    }

    self TakeAllWeapons();
    
    self GiveWeapon(finalWeapon);
    self GiveMaxAmmo(finalWeapon);
    
    wait(0.2);

    self SwitchToWeapon(finalWeapon);
    //ilog("Weapon : " + finalWeapon);
}

DisableDropItem()
{
    level endon("game_ended");
    
    for(;;)
    {
        dropped_weapons = GetEntArray("dropped_weapon", "targetname");
        
        if(Isdefined(dropped_weapons))
        {
            foreach(weapon in dropped_weapons)
            {
                weapon delete();
            }
        }
       
        wait(0.1);
    }
}


HasPerk(player , perk)
{
    #ifdef IW
    return player scripts\mp\_utility::_hasperk(perk);
    #else
    return player maps\mp\_utility::func_649(perk);
    #endif
}

UnSetPerk(player , perk)
{
    #ifdef IW
    player scripts\mp\_utility::func_E150(perk);
    #else
    player maps\mp\_utility::func_0735(perk);
    #endif
}

SweepingRadar()
{
    self endon ("disconnect");
    self endon("death");

    #ifdef WW2
    self.var_B7 = true; 
    self.var_14C = "normal_radar"; 
    #else

    //Need to be looped 
    for(;;)
    {
        self.var_16E = 1;
        self.var_254 = "normal_radar";
        wait(10);
    }
        
    #endif
}

CreateText(font, fontScale, align, relative, x, y, sort, alpha, text, color)
{
    #ifdef WW2
    textElem = self CreateFontString(font, fontScale);
    textElem SetPoint(align, relative, x, y);
    #else
    textElem = self scripts\mp\_hud_util::CreateFontString(font, fontScale);
    textElem scripts\mp\_hud_util::SetPoint(align, relative, x, y);
    #endif
    
    textElem.hideWhenInMenu = true;
    textElem.archived = false;
    textElem.sort = sort; 
    textElem.alpha = alpha;
    textElem.color = color;
    textElem SetSafeText(text);

    return textElem;
}

CreateServerText(font, fontScale, align, relative, x, y, sort, alpha, text, color)
{
    #ifdef WW2
    textElem = level CreateServerFontString(font, fontScale);
    textElem SetPoint(align, relative, x, y);
    #else
    textElem = level scripts\mp\_hud_util::CreateServerFontString(font, fontScale);
    textElem scripts\mp\_hud_util::SetPoint(align, relative, x, y);
    #endif
    
    textElem.hideWhenInMenu = true;
    textElem.archived = false;
    textElem.sort = sort; 
    textElem.alpha = alpha;
    textElem.color = color;
    textElem SetSafeText(text);

    return textElem;
}

RefreshHUD()
{
    if(IsDefined(self.hud["WEAPON"]["WEAPON_COUNT"]))
    {
        self.hud["WEAPON"]["WEAPON_COUNT"] SetSafeText("Weapon : ^3" + (self.gunGameIndex + 1) + "^7/" + level.classicMode.size);
    }
}