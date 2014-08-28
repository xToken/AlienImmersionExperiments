//    
// lua\BioluminesceMixin.lua    
//    
if Client then

	BioluminesceMixin = CreateMixin(BioluminesceMixin)
	BioluminesceMixin.type = "Bioluminesce"

	BioluminesceMixin.expectedMixins =
	{
		Model = "Needed for effects",
		Team = "Needed for team number"
	}

	BioluminesceMixin.optionalCallbacks =
	{
		GetBioluminesceIntensity = "Controls intensity of light.",
		GetBioluminesceColor = "Controls the color of the light.",
		GetBioluminesceCastsShadows = "Controls if light casts shadows.",
		GetBioluminesceLightHeightOffset = "Can adjust the height of the light relative to the model.",
		GetBioluminescePulseLength = "Controls the durations of pulses in intensity.",
		GetBioluminescePulseStrength = "Controls max/min change in intensity."
	}

	local kBioluminesceEnabled = false
	local kBioluminesceChangeRate = 0.1
	local kDefaultIntensity = 20
	local kDefaultRadius = 5
	local kDefaultColor = Color( 1, 0.792, 0.227, 1 )
	local kCastsShadows = false
	local kDefaultPulseStrength = 20

	local function CreateRenderLight(self)
		self.bioLight = Client.CreateRenderLight()
		self.bioLight:SetType(RenderLight.Type_Point)
		self.bioLight:SetGroup("Bioluminesce")
		self.bioLight.ignorePowergrid = true
		self.bioLightCreated = Shared.GetTime()
		//Do I need this? hmmmmmmmmmmmmmm
		self.bioLight:SetSpecular(false)
	end
	
	local function DestroyRenderLight(self)
		if self.bioLight then
			Client.DestroyRenderLight(self.bioLight)
		end
	end
	
	local function UpdateDefaultSettings(self)
		self.bioluminesceIntensity = self.GetBioluminesceIntensity and self:GetBioluminesceIntensity() or kDefaultIntensity
		self.bioluminesceRadius = self.GetBioluminesceRadius and self:GetBioluminesceRadius() or kDefaultRadius
		self.bioluminesceColor = self.GetBioluminesceColor and self:GetBioluminesceColor() or kDefaultColor
		self.bioluminesceShadows = self.GetBioluminesceCastsShadows and self:GetBioluminesceCastsShadows() or kCastsShadows
	end
	
	local function UpdateRenderLightSettings(self)
		self.bioLight:SetColor(self.bioluminesceColor)
		self.bioLight:SetCastsShadows(self.bioluminesceShadows)
		self.bioLight:SetRadius(self.bioluminesceRadius)
		self.bioLight:SetIntensity(self.bioluminesceIntensity * self:GetVisibilityFraction())
	end
	
	local function UpdateRenderLightCoords(self)
		self.bioLight:SetCoords(self:GetCoords())
	end

	function BioluminesceMixin:__initmixin()
		self.bioluminesceEnabled = kBioluminesceEnabled
		UpdateDefaultSettings(self)
		if self.bioluminesceEnabled then
			CreateRenderLight(self)
			UpdateRenderLightSettings(self)
			UpdateRenderLightCoords(self)
		end
		self.lastOptionsUpdate = Shared.GetTime()
		self.updatesNow = false
	end
	
	function BioluminesceMixin:OnDestroy()
        DestroyRenderLight(self)
    end
	
	function BioluminesceMixin:SetColor(color)
        self.bioluminesceColor = color
		self:SetUpdatesNow()
    end
	
	function BioluminesceMixin:SetIntensity(intesity)
        self.bioluminesceIntensity = intesity
		self:SetUpdatesNow()
    end
	
	function BioluminesceMixin:SetRadius(radius)
        self.bioluminesceRadius = radius
		self:SetUpdatesNow()
    end
	
	function BioluminesceMixin:SetCastsShadows(castsshadows)
        self.bioluminesceShadows = castsshadows
		self:SetUpdatesNow()
    end
	
	function BioluminesceMixin:SetUpdatesNow()
        self.updatesNow = true
    end
	
	function BioluminesceMixin:GetVisibilityFraction()
		local playerIsEnemy = GetAreEnemies(self, Client.GetLocalPlayer()) or false
		local cloakFraction = (playerIsEnemy and HasMixin(self, "Cloakable")) and self:GetCloakFraction() or 0
		return 1 - cloakFraction
	end

	function BioluminesceMixin:OnUpdateRender()

		PROFILE("BioluminesceMixin:OnUpdateRender")
		
		if self.bioluminesceEnabled ~= kBioluminesceEnabled then
		
			if self.bioLight and not kBioluminesceEnabled then
				//Destroy light
				DestroyRenderLight(self)
			elseif not self.bioLight and kBioluminesceEnabled then
				//Create light
				CreateRenderLight(self)
				UpdateRenderLightSettings(self)
				UpdateRenderLightCoords(self)
			end
			
			self.bioluminesceEnabled = kBioluminesceEnabled
			
		end
		
		if self.bioluminesceEnabled then
			local sTime = Shared.GetTime()
			if self.lastOptionsUpdate + kBioluminesceChangeRate > sTime or self.updatesNow then
				//Update the lights settings
				UpdateRenderLightSettings(self)
				//Alien structures can move, so check for that funnnnn
				UpdateRenderLightCoords(self)
				//This seems a little wierd, but it ensures more even distribution of updates.
				if self.updatesNow then
					self.updatesNow = false
				else
					self.lastOptionsUpdate = self.lastOptionsUpdate + kBioluminesceChangeRate				
				end
			end
			
			//Pulsing always updates
			local pulseCycle = self.GetBioluminescePulseLength and self:GetBioluminescePulseLength() or 5
			if pulseCycle > 0 then
				local timePassed = Shared.GetTime() - self.bioLightCreated
				local intensityChange = self.GetBioluminescePulseStrength and self:GetBioluminescePulseStrength() or kDefaultPulseStrength
				local scalar = math.cos((timePassed / (pulseCycle / 2)) * math.pi / 2)
				self.bioLight:SetIntensity((self.bioluminesceIntensity + (intensityChange * scalar)) * self:GetVisibilityFraction())
			end
			
		end
		
	end

	function Bioluminesce_SyncOptions()
		kBioluminesceEnabled = Client.GetOptionBoolean("graphics/Bioluminesce", false)
		//kBioluminesceEnabled = true
	end

	Event.Hook("LoadComplete", Bioluminesce_SyncOptions)

end