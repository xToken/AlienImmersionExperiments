// Alien Immersion Experiments
// Source located at - https://github.com/xToken/AlienImmersionExperiments
// lua\Infestation.lua
// Originally Created by 'Andreas Urwalek' for Natural Selection 2 - Unknown Worlds Entertainment, Inc. (http://www.unknownworlds.com)
// - Dragon

PrecacheAsset("materials/infestation/infestation_decal.surface_shader")
PrecacheAsset("materials/infestation/infestation_shell.surface_shader")
PrecacheAsset("materials/infestation/Infestation.surface_shader")
PrecacheAsset("models/alien/infestation/infestation_shell.model")
PrecacheAsset("models/alien/infestation/infestation_blob.model")

Script.Load("lua/InfestationCache.lua")

local kInfestationDecalMaterial = PrecacheAsset("materials/infestation/infestation_decal.material")

local kInfestation = {}
local kDirtyTable = {}
local kInfestationBlobCount = 0
local kInfestationShellCount = 20
local kInfestationLowQuality = false

//Globals?
gInfestationMaxShells = 100
gInfestationMaxBlobs = 100

class 'Infestation'

local kMaxRadius = kInfestationRadius

function CreateStructureInfestation(parent, coords, teamNumber, infestationRadius, blobMultiplier)

    local infestation = Infestation()
    infestation:Initialize()
    infestation:SetCoords(coords)    
    infestation:SetMaxRadius(infestationRadius)
    infestation:SetBlobMultiplier(blobMultiplier)
	infestation.parentclassname = parent:GetClassName()
    
    return infestation
    
end

local function DestroyClientGeometry(self)

    if self.infestationModelArray ~= nil then
        Client.DestroyRenderModelArray(self.infestationModelArray)
        self.infestationModelArray = nil
    end

    if self.infestationShellModelArray ~= nil then
        Client.DestroyRenderModelArray(self.infestationShellModelArray)
        self.infestationShellModelArray = nil
    end
	
	if self.infestationMaterial then
		Client.DestroyRenderMaterial(self.infestationMaterial)
		self.infestationMaterial = nil
	end
	
	if self.infestationDecals ~= nil then
        for i=1,#self.infestationDecals do
            Client.DestroyRenderDecal(self.infestationDecals[i])
        end
        self.infestationDecals = nil
    end
  
    self.hasClientGeometry = false

end


function CreateInfestationModelArray(modelName, blobCoords, origin, radiusScale, radiusScale2, limit)

    local modelArray = nil
    
    if #blobCoords > 0 then
            
        local coordsArray = { }
        local numModels = 0
        
        for index, coords in ipairs(blobCoords) do

			if numModels >= limit then
				break
			end
			
            local c  = Coords()
            c.xAxis  = coords.xAxis  * radiusScale
            c.yAxis  = coords.yAxis  * radiusScale2
            c.zAxis  = coords.zAxis  * radiusScale
            c.origin = coords.origin - coords.yAxis * 0.3
            
            numModels = numModels + 1
            coordsArray[numModels] = c
            
        end
        
        if numModels > 0 then

            modelArray = Client.CreateRenderModelArray(RenderScene.Zone_Default, numModels)
            modelArray:SetCastsShadows(false)
            modelArray:InstanceMaterials()

            modelArray:SetModel(modelName)
            modelArray:SetModels(coordsArray)

        end
        
    end
    
    return modelArray

end

function CreateModelArrays(self)
    
    // Make blobs on the ground thinner to so that Skulks and buildings aren't
    // obscured.
    local scale = 1
	
    if self.coords.yAxis.y > 0.5 then
        scale = 0.75
    end
    
    local origin = self.coords.origin

    self.infestationModelArray = CreateInfestationModelArray( "models/alien/infestation/infestation_blob.model", self.blobCoords, origin, 1, scale, self.blobCount )
    self.infestationShellModelArray = CreateInfestationModelArray( "models/alien/infestation/infestation_shell.model", self.blobCoords, origin, self.shellSize, 1.25 * scale, self.shellCount)
    
end

local function CreateDecals(self)

    local decals = { }
	
	self.infestationMaterial = Client.CreateRenderMaterial()
	self.infestationMaterial:SetMaterial(kInfestationDecalMaterial)
    
    for index, coords in ipairs(self.blobCoords) do
	
		if index > 50 then
			break
		end

        local decal = Client.CreateRenderDecal()
        decal:SetMaterial(self.infestationMaterial)
        decal:SetCoords(coords)
        decal:SetExtents(Vector(1.5, 0.1, 1.5))
        decals[index] = decal
        
    end

    self.infestationDecals = decals

end

local function CreateClientGeometry(self)

	self.blobCount = kInfestationBlobCount
	self.shellCount = kInfestationShellCount
	self.shellSize = kInfestationShellSize
	self.lowquality = kInfestationLowQuality
	
	if self.lowquality then
		CreateDecals(self)
	else
	    CreateModelArrays(self)
	end
	
    self.hasClientGeometry = true
    
end

function Infestation:Initialize()

    self.radius = 0
    self.lastRadius = 0
    self.cloakFraction = 0
    self.lastCloakFraction = 0
    self.visible = false
    self.blobMultiplier = 1
    
    self.maxRadius = kMaxRadius
    self.blobCoords = { }

    self.destroyed = false
    
    table.insertunique(kDirtyTable, self)
    table.insert(kInfestation, self)
 
end

function Infestation:Uninitialize()

    if Client then
    
        DestroyClientGeometry(self)
        
        self.destroyed = true
    
    end
    
    table.removevalue(kInfestation, self)
    
end

function Infestation:SetBlobMultiplier(multiplier)
    self.blobMultiplier = multiplier
end

function Infestation:SetIsVisible(visible)

    if self.visible ~= visible then
        
        table.insertunique(kDirtyTable, self)
        self.visible = visible
        
    end

end

function Infestation:GetIsVisible()
    return self.visible
end

function Infestation:SetCoords(coords)
    self.coords = Coords(coords)
    table.insertunique(kDirtyTable, self)
end

function Infestation:GetCoords()
    return self.coords
end

function Infestation:GetRadius()    
    return self.radius    
end

function Infestation:SetRadius(radius)

    if self.radius ~= radius then

        self.radius = radius
        table.insertunique(kDirtyTable, self)
    
    end
    
end

function Infestation:SetCloakFraction(cloakFraction)

    if self.cloakFraction ~= cloakFraction then
        
        self.cloakFraction = cloakFraction
        
        // this change is not interesting for the server
        if Client then
            table.insertunique(kDirtyTable, self)
        end
    
    end

end

function Infestation:SetMaxRadius(radius)
    self.maxRadius = radius
end

function Infestation:GetMaxRadius()
    return self.maxRadius
end

function Infestation:GenerateBlobs()

    assert(self.coords)
    
    // generate the blobs, use cached blobs if exist
    table.copy(gInfestationCache:GetBlobCoords(self), self.blobCoords)
    
end

// only called when the infestation actually changed
function Infestation:RenderInfestation(generateBlobs)

    PROFILE("Infestation:RenderInfestation")
    
    if #self.blobCoords == 0 then
    
        if generateBlobs then
            self:GenerateBlobs()
        else
            return false
        end
    
    end
    
    local qualityChanged = self.blobCount ~= kInfestationBlobCount or self.shellCount ~= kInfestationShellCount or self.shellSize ~= kInfestationShellSize or self.lowquality ~= kInfestationLowQuality
    
    if qualityChanged then
        DestroyClientGeometry(self)
    end

    if not self.hasClientGeometry and self.visible then
        CreateClientGeometry(self)
    elseif self.hasClientGeometry and not self.visible then
        DestroyClientGeometry(self)
    end

    local origin = self.coords.origin
    local amount = self.maxRadius > 0 and self.radius / self.maxRadius or 0
    
    // Apply cloaking effects.
    amount = amount * (1 - self.cloakFraction)
    
    if self.infestationModelArray then
	
    
		self.infestationModelArray:SetMaterialParameter("amount", amount)
		self.infestationModelArray:SetMaterialParameter("origin", origin)
		self.infestationModelArray:SetMaterialParameter("maxRadius", self.maxRadius)
		
	end
	
	if self.infestationShellModelArray then
	
		self.infestationShellModelArray:SetMaterialParameter("amount", amount)
		self.infestationShellModelArray:SetMaterialParameter("origin", origin)
		self.infestationShellModelArray:SetMaterialParameter("maxRadius", self.maxRadius)
		
	end
	
	if self.infestationDecals then
    
        self.infestationMaterial:SetParameter("amount", amount)
        self.infestationMaterial:SetParameter("origin", origin)
        self.infestationMaterial:SetParameter("maxRadius", self.maxRadius)
        
    end
	
end

// only called when the infestation actually changed
function Infestation:UpdateInfestables()

    PROFILE("Infestation:UpdateInfestables")

    local entityIds = {}
    local smallestRadius = self.radius
    local biggestRadius = self.lastRadius
    // point is guaranteed on infestation when growing, only shrinking requires another check
    local onInfestation = self.radius > self.lastRadius

    if smallestRadius > biggestRadius then
        smallestRadius, biggestRadius = biggestRadius, smallestRadius
    end
    
    local origin = self.coords.origin
    for index, entity in ipairs(GetEntitiesWithMixinWithinRange("InfestationTracker", self.coords.origin, biggestRadius)) do
    
        local range = (origin - entity:GetOrigin()):GetLength()
        if range >= smallestRadius and range <= biggestRadius then
            entity:UpdateInfestedState(onInfestation)
        end
        
    end

end

function Infestation:GetIsPointOnInfestation(point)

    local onInfestation = false
    
    // Check radius
    local radius = point:GetDistanceTo(self.coords.origin)
    if radius <= self:GetRadius() then
    
        // Check dot product
        local toPoint = point - self.coords.origin
        local verticalProjection = math.abs( self.coords.yAxis:DotProduct( toPoint ) )
        
        onInfestation = (verticalProjection < 1)
        
    end
    
    return onInfestation
   
end

if Server then
	
	local function UpdateDirtyTable()

		PROFILE("Infestation:UpdateDirtyTable")
		
		for i = 1, #kDirtyTable do
		
			local infestation = kDirtyTable[i]
		
			if not infestation.destroyed then
			
				infestation:UpdateInfestables()
				
				infestation.lastRadius = infestation.radius
				infestation.lastCloakFraction = infestation.cloakFraction
			
			end
		
		end
		
		kDirtyTable = { }

	end

    Event.Hook("UpdateServer", UpdateDirtyTable)
	
elseif Client then

	local kUpdatesPerFrame = 1
	local function UpdateDirtyTableClient()

		PROFILE("Infestation:UpdateDirtyTableClient")
		
		//DebugPrint("num infestation %s, num dirty %s", ToString(#kInfestation), ToString(#kDirtyTable))

		local remainingUpdates = {}
		local updatesDone = 0
		
		for i = 1, #kDirtyTable do
		
			local infestation = kDirtyTable[i]

			if not infestation.destroyed then
			
				infestation:RenderInfestation(updatesDone < kUpdatesPerFrame)
				
				if updatesDone >= kUpdatesPerFrame then
					// update later to prevent hitches
					table.insert(remainingUpdates, infestation)            
				else
				
					infestation.lastRadius = infestation.radius
					infestation.lastCloakFraction = infestation.cloakFraction
					
					updatesDone = updatesDone + 1
					
				end    
			
			end
		
		end
		
		kDirtyTable = remainingUpdates
		
	end

    Event.Hook("UpdateClient", UpdateDirtyTableClient)

    function Infestation_SyncOptions()
	
		kInfestationBlobCount = Clamp(Client.GetOptionInteger("graphics/infestationBlobCount", 20), 0, gInfestationMaxBlobs)
		kInfestationShellCount = Clamp(Client.GetOptionInteger("graphics/infestationShellCount", 20), 0, gInfestationMaxShells)
		
		//Testing
		kInfestationBlobCount = 0
		kInfestationShellCount = 20
		kInfestationShellSize = 1.5
		kInfestationLowQuality = false
		
		//Might need to always set this to rich?
		Client.SetRenderSetting("infestation", "rich")
		
        // mark all as dirty to update quality
        table.copy(kInfestation, kDirtyTable)
        
    end
    
    Event.Hook("LoadComplete", Infestation_SyncOptions)
    
    function Infestation_UpdateForPlayer()
		if PlayerUI_IsOverhead() then
            Client.SetRenderSetting("infestation_scale", 0.15)
        else
            Client.SetRenderSetting("infestation_scale", 0.30)
        end
    end
	
	local function UpdateInfestationBlobs(blobs)
		kInfestationBlobCount = tonumber(blobs or 0)
		kInfestationBlobCount = math.min(kInfestationBlobCount, gInfestationMaxBlobs)
		table.copy(kInfestation, kDirtyTable)
		Shared.Message(string.format("Infestation Blobs set to %s", kInfestationBlobCount))
	end
	
	Event.Hook("Console_infestationblobs", UpdateInfestationBlobs)
	
	local function UpdateInfestationShells(shells)
		kInfestationShellCount = tonumber(shells or 20)
		kInfestationShellCount = math.min(kInfestationShellCount, gInfestationMaxShells)
		table.copy(kInfestation, kDirtyTable)
		Shared.Message(string.format("Infestation Shells set to %s", kInfestationShellCount))
	end
	
	Event.Hook("Console_infestationshells", UpdateInfestationShells)
	
	local function UpdateInfestationQuality(high)
		kInfestationLowQuality = high and true or false
		table.copy(kInfestation, kDirtyTable)
		Shared.Message(string.format("Infestation Quality set to %s", ToString(kInfestationLowQuality)))
	end
	
	Event.Hook("Console_infestationquality", UpdateInfestationQuality)
	
	local function UpdateInfestationRender(setting)
		kInfestationRenderQuality = setting and true or false 
		local rsetting = kInfestationRenderQuality and "rich" or "minimal"
		Client.SetRenderSetting("infestation", rsetting)
		table.copy(kInfestation, kDirtyTable)
		Shared.Message(string.format("Infestation Render Mode set to %s", rsetting))
	end
	
	Event.Hook("Console_infestationrender", UpdateInfestationRender)

end

