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
		GetTeamNumber = "Get team index",
		GetBioluminesceIntensity = "Controls intensity of light.",
		GetBioluminesceColor = "Controls the color of the light.",
		GetBioluminesceCastsShadows = "Controls if light casts shadows."
	}

	local kBioluminesceEnabled = false
	local kBioluminesceChangeRate = 0.1
	local kDefaultIntensity = 20
	local kDefaultRadius = 5
	local kDefaultColor = Color( 1, 0.792, 0.227, 1 )
	
	local function UpdateRenderLightSettings(self)
		self.bioLight:SetColor(self.bioluminesceColor)
		self.bioLight:SetCastsShadows(self.bioluminesceShadows)
		self.bioLight:SetRadius(self.bioluminesceRadius)
		self.bioLight:SetIntensity(self.bioluminesceIntensity)
	end
	
	local function UpdateRenderLightCoords(self)
		self.bioLight:SetCoords(self:GetCoords())
	end

	local function CreateRenderLight(self)
		self.bioLight = Client.CreateRenderLight()
		self.bioLight:SetType(RenderLight.Type_Point)
		self.bioLight:SetGroup("Bioluminesce")
		self.bioLight.ignorePowergrid = true
		//Do I need this? hmmmmmmmmmmmmmm
		self.bioLight:SetSpecular(false)
		UpdateRenderLightSettings(self)
		UpdateRenderLightCoords(self)
	end
	
	local function DestroyRenderLight(self)
		if self.bioLight then
			Client.DestroyRenderLight(self.bioLight)
		end
	end
	
	local function UpdateCachedSettings(self)
		self.bioluminesceIntensity = self.GetBioluminesceIntensity and self:GetBioluminesceIntensity() or kDefaultIntensity
		self.bioluminesceRadius = self.GetBioluminesceRadius and self:GetBioluminesceRadius() or kDefaultRadius
		self.bioluminesceColor = self.GetBioluminesceColor and self:GetBioluminesceColor() or kDefaultColor
		self.bioluminesceShadows = self.GetBioluminesceCastsShadows and self:GetBioluminesceCastsShadows() or false
	end

	function BioluminesceMixin:__initmixin()
		self.bioluminesceEnabled = Client.GetOptionBoolean("graphics/Bioluminesce", false)
		UpdateCachedSettings(self)
		if self.bioluminesceEnabled then
			CreateRenderLight(self)
		end
		self.lastOptionsUpdate = Shared.GetTime()
	end
	
	function BioluminesceMixin:OnDestroy()
        DestroyRenderLight(self)
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
			end
			
			self.bioluminesceEnabled = kBioluminesceEnabled
			
		end
		
		if self.bioluminesceEnabled then
			local sTime = Shared.GetTime()
			if self.lastOptionsUpdate + kBioluminesceChangeRate > sTime then
				//Update cached settings
				UpdateCachedSettings(self)
				//Update the lights settings
				UpdateRenderLightSettings(self)
				//Alien structures can move, so check for that funnnnn
				UpdateRenderLightCoords(self)
				//This seems a little wierd, but it ensures more even distribution of updates.
				self.lastOptionsUpdate = self.lastOptionsUpdate + kBioluminesceChangeRate
			end
		end
		
	end

	function Bioluminesce_SyncOptions()
		//kBioluminesceEnabled = Client.GetOptionBoolean("graphics/Bioluminesce", false)
		kBioluminesceEnabled = true
	end

	Event.Hook("LoadComplete", Bioluminesce_SyncOptions)

end