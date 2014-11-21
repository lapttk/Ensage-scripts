require("libs.Utils")
require("libs.HeroInfo")
--[[
                         '''''''''''                               
                     ''''```````````'''''''''''.                   
                 ''''`````````````````````..../.                   
              '''``````````````````````.../////.                   
          ''''``````````````````````...////////.                   
        ''wwwwwwwwww````````````....///////////.                   
         weeeeeeeeeewwwwwwwwww..//////////////.                    
         weeeeeeeeeeeeeeeeeeeew///////////////.                    
          weeeeeeeeeeeeeeeeeeew///////////////.                    
           weeeeeeeeeeeeeeeeeew///////////////.                    
           weeeeeeeeeeeeeeeeeeew//////////////.                    
            weeeeeeeeeeeeeeeeeew/////////////.                     
             weeeeeeeeeeeeeeeeew/////////////.                     
             weeeeeeeeeeeeeeeeew/////////////.                     
              weeeeeeeeeeeeeeeew/////////////.                     
               weeeeeeeeeeeeeeeew////////////.                     
               weeeeeeeeeeeeeeeew///////////.                      
                weeeeeeeeeeeeeeew//////////.                       
                 weeeeeeeeeeeeeew////////..                        
                 weeeeeeeeeeeeeeew//////.                          
                  wweeeeeeeeeeeeew/////.                           
                    wwwweeeeeeeeew////.                              *           
                        wwwweeeeew//..                    *       *              
                            wwwwew/.            * *     **    **      *    
                                ww.             *      **    *     **          
                                                 *      **   * *****    * **   
                                                   *      ****** ** * *     ***
                                                      *** *********           *
        +-------------------------------------------------+   * *  *            
        |                                                 |    *  *** **        
        |       ANIMATIONS LIBRARY - Made by Moones       |    *   *    **      
        |       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^       |    *    *     **    
        +-------------------------------------------------+    *   **      **   
                                                                            *       
        =+=+=+=+=+=+=+=+= VERSION 1.0.2 =+=+=+=+=+=+=+=+=+=
	 
        Description:
        ------------
	
             - This library tracks animations duration of all heroes.
             - Tracks attack animations as well as spell animations.
			 
        Usage:
        ------
		
             - Animations.getDuration(ability) - If specified ability is animating then returns how much time left since ability started its animation.
             - Animations.getAttackDuration(hero) - If specified hero is attacking then returns how much time left since his current attack animation started.
             - Animations.isAttacking(hero) - Returns true if specified hero is currently attacking.
             - Animations.CanMove(hero) - If specified hero already finished his attack and is in his backswing animation then true is returned.
             - Animations.maxCount - Returns how much times per second is library checking. Can be used for sleeps in EVENT_FRAME function.
			 
        Example:
        --------
        
             - Simple OrbWalker:
			 
                 require("libs.Animations")
                 require("libs.Utils")
				 
                 local attack = 0
                 local move = 0
				 
                 function Tick(tick)
                     if PlayingGame() then
                         local me = entityList:GetMyHero()
                         if IsKeyDown(49) then
                             if not Animations.CanMove(me) then
                                 for i,v in ipairs(entityList:GetEntities({type=LuaEntity.TYPE_HERO,alive=true,visible=true,team = me:GetEnemyTeam()})) do
                                     if tick > attack GetDistance2D(me, v) <= me.attackRange*2 then
                                         me:Attack(v)
                                         attack = tick + Animations.maxCount/1.5
                                     end
                                 end
                             elseif tick > move then
                                 me:Move(client.mousePosition)
                                 move = tick + Animations.maxCount/1.5
                             end
                         end
                     end
                 end

                 script:RegisterEvent(EVENT_FRAME,Tick)
			 
	   
        Changelog:
        ----------
		
             - 21. 11. 2014 - Version 1.0.2 Fixed bug with tick count.
		
             - 21. 11. 2014 - Version 1.0.1 Now CanMove returning false when hero is casting an ability.
	
             - 21. 11. 2014 - Version 1.0 First Release
]]--

Animations = {}

Animations.table = {}
Animations.attacksTable = {}
Animations.startTime = nil
Animations.count = 0
Animations.maxCount = 0

function Animations.trackingTick(tick)
	if not PlayingGame() or client.paused then return end
	if not Animations.startTime then Animations.startTime = client.gameTime
	elseif (client.gameTime < 0 and Animations.startTime > 0) then Animations.startTime = client.gameTime Animations.maxCount = 0
	elseif (client.gameTime - Animations.startTime) >= 1 then Animations.startTime = nil Animations.maxCount = Animations.count Animations.count = 0
	else Animations.count = Animations.count + 1 end
	for i,v in ipairs(entityList:GetEntities({type=LuaEntity.TYPE_HERO,visible=true})) do
		if not Animations.table[v.handle] then
			Animations.table[v.handle] = {}
		end
		for i,k in ipairs(v.abilities) do
			if k.abilityPhase then
				if not Animations.table[k.handle] then                                   
					Animations.table[k.handle] = {}
					Animations.table[k.handle].startTime = tick
					Animations.table[k.handle].duration = tick - Animations.table[k.handle].startTime
					Animations.table[v.handle].canmove = false
				end
			else
				Animations.table[k.handle] = nil
			end
			if Animations.table[k.handle] then
				Animations.table[k.handle].duration = tick - Animations.table[k.handle].startTime
				Animations.table[v.handle].canmove = false
			end
		end
		local hero = HeroInfo(v)
		hero:Update()
		if Animations.isAttacking(v) then
			if not Animations.table[v.handle].startTime then
				Animations.table[v.handle].startTime = client.gameTime
			end
			Animations.table[v.handle].endTime = Animations.table[v.handle].startTime + (hero.attackRate) - client.latency/1000 - (1/Animations.maxCount)
			Animations.table[v.handle].canmoveTime = Animations.table[v.handle].startTime + hero.attackPoint - ((client.latency/1000)/(1 + (1 - 1/Animations.maxCount))) + (1/Animations.maxCount)*(1 + (1 - 1/Animations.maxCount))
			Animations.table[v.handle].attackTime = hero.attackRate
		end
		if Animations.table[v.handle].endTime and Animations.table[v.handle].endTime <= client.gameTime then
			Animations.table[v.handle] = {}
			return
		end
		if Animations.table[v.handle].startTime then
			Animations.table[v.handle].duration = client.gameTime - Animations.table[v.handle].startTime + 1/Animations.maxCount + client.latency/1000
		end
		if Animations.table[v.handle].canmoveTime and client.gameTime >= Animations.table[v.handle].canmoveTime then
			Animations.table[v.handle].canmove = true
		end
		local projs = entityList:GetProjectiles({source=v})
		for k,z in ipairs(projs) do
			if GetDistance2D(z.position, v.position) < 127 and not Animations.table[v.handle].canmove then
				Animations.table[v.handle].canmove = true
				Animations.table[v.handle].endTime = client.gameTime + (hero.attackBackswing) - client.latency/1000 - 1/Animations.maxCount
			end
		end
	end
end

function Animations.trackLoad()
	Animations.count = 0
	Animations.maxCount = 0
end

function Animations.getCount()
	return Animations.count
end

function Animations.getDuration(ability)
	if ability and Animations.table[ability.handle] then return Animations.table[ability.handle].duration else return 0 end
end

function Animations.getAttackDuration(hero)
	if hero and Animations.table[hero.handle] then return Animations.table[hero.handle].duration else return 0 end
end

function Animations.isAnimating(ability)
	return ability.abilityPhase
end

function Animations.isAttacking(hero)
	return hero.activity == LuaEntityNPC.ACTIVITY_ATTACK or hero.activity == LuaEntityNPC.ACTIVITY_ATTACK1 or hero.activity == LuaEntityNPC.ACTIVITY_ATTACK2 or hero.activity == LuaEntityNPC.ACTIVITY_CRIT
end

function Animations.CanMove(hero)
	if Animations.table[hero.handle] then return Animations.table[hero.handle].canmove end
end

class 'HeroInfo'

function HeroInfo:__init(entity)   
	self.entity = entity
	local name = entity.name
	if not heroInfo[name] then
		return nil
	end
	self.baseAttackPoint = heroInfo[name].attackPoint
	self.baseBackswing = heroInfo[name].attackBackswing
end

function HeroInfo:Update()	
	self.attackSpeed = self:GetAttackSpeed()
	self.attackRate = self:GetAttackRate()
	self.attackPoint = self:GetAttackPoint()
	self.attackBackswing = self:GetBackswing()
end

function HeroInfo:GetAttackSpeed()
	if self.entity.attackSpeed > 500 then
		return 500
	end
	return self.entity.attackSpeed
end

function HeroInfo:GetAttackPoint()
	return self.baseAttackPoint / (1 + (self.entity.attackSpeed - 100) / 100)
end

function HeroInfo:GetAttackRate()
	return self.entity.attackBaseTime / (1 + (self.entity.attackSpeed - 100) / 100)
end

function HeroInfo:GetBackswing()
	return self.baseBackswing / (1 + (self.entity.attackSpeed - 100) / 100)
end
	
scriptEngine:RegisterLibEvent(EVENT_FRAME,Animations.trackingTick)
scriptEngine:RegisterLibEvent(EVENT_LOAD,Animations.trackLoad)
