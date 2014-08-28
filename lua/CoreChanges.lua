// Try cysts for starters

Script.Load("lua/Infestation_Client_BlobPatterns.lua")
Script.Load( "lua/AlienImmersion/Elixer_Utility.lua" )
Elixer.UseVersion( 1.72 )

/*
Script.Load( "lua/BioluminesceMixin.lua" )

local originalCystOnCreate
originalCystOnCreate = Class_ReplaceMethod("Cyst", "OnCreate",
	function(self)
		originalCystOnCreate(self)
		if Client then
			InitMixin(self, BioluminesceMixin)
		end
	end
)
*/

local GenerateBlobCoords = GetUpValue( InfestationCache.GetBlobCoords,   "GenerateBlobCoords" )
local kBlobGenNum = 100

ReplaceLocals(GenerateBlobCoords, { kBlobGenNum = kBlobGenNum })

/*
local kPoweredDownCycleTime = 30
local kPoweredDownMinCycleTime = 15
local kPoweredDownFixedTime = 10
local kAuxPowerCycleTime = 10
local kAuxPowerMinIntensity = 0
local kAuxPowerMaxIntensity = 10
local kAuxPowerMinCommanderIntensity = 3
local kAuxPowerMaxCommanderIntensity = 10

local function SetLight(renderLight, intensity, color)

    if intensity then
        renderLight:SetIntensity(intensity)
    end
    
    if color then
    
        renderLight:SetColor(color)
        
        if renderLight:GetType() == RenderLight.Type_AmbientVolume then
        
            renderLight:SetDirectionalColor(RenderLight.Direction_Right,    color)
            renderLight:SetDirectionalColor(RenderLight.Direction_Left,     color)
            renderLight:SetDirectionalColor(RenderLight.Direction_Up,       color)
            renderLight:SetDirectionalColor(RenderLight.Direction_Down,     color)
            renderLight:SetDirectionalColor(RenderLight.Direction_Forward,  color)
            renderLight:SetDirectionalColor(RenderLight.Direction_Backward, color)
            
        end
        
    end
    
end

//function LightGroup:RunCycle(time)
local originalLightGroupRunCycle
originalLightGroupRunCycle = Class_ReplaceMethod("LightGroup", "RunCycle",
	function(self, time)
		if time > self.cycleEndTime then
    
			// end varying cycle and fix things for a while. Note that the intensity will
			// stay a bit random, which is all to the good.
			self.stateFunction = LightGroup.RunFixed
			self.nextThinkTime = time + kPoweredDownFixedTime
			self.cycleUsedTime = self.cycleUsedTime + (time - self.cycleStartTime)
			
		else
		
			// this is the time used to calc intensity. This is calculated so that when
			// we restart after a pause, we continue where we left off.
			local t = time - self.cycleStartTime + self.cycleUsedTime 
			
			local color = PowerPoint.kDisabledColor
			local scalar = math.cos((t / (kAuxPowerCycleTime / 2)) * math.pi / 2)
			local minIntensity = kAuxPowerMinIntensity
			local maxIntensity = kAuxPowerMaxIntensity
			
			local player = Client.GetLocalPlayer()
			if player and player:isa("Commander") then
				color = PowerPoint.kDisabledCommanderColor
				minIntensity = kAuxPowerMinCommanderIntensity
				maxIntensity = kAuxPowerMaxCommanderIntensity
			end
			
			for renderLight,_ in pairs(self.lights) do
			
				// Fade disabled color in and out to make it very clear that the power is out
				SetLight(renderLight, Clamp(renderLight.originalIntensity * scalar, minIntensity, maxIntensity), color)
				
			end
			
		end
	end
)

local originalLightGroupRunFixed
originalLightGroupRunFixed = Class_ReplaceMethod("LightGroup", "RunFixed",
	function(self, t)
		originalLightGroupRunFixed(self, t)
		self.cycleEndTime = t + math.random(kPoweredDownMinCycleTime, kPoweredDownCycleTime)
	end
)
*/