// Try cysts for starters

Script.Load( "lua/BioluminesceMixin.lua" )
//This seems wierd, but its late enough to switch to this setup.
Script.Load("lua/Infestation_Client_BlobPatterns.lua")

Script.Load( "lua/Elixer_Utility.lua" )
Elixer.UseVersion( 1.72 )

local originalCystOnCreate
originalCystOnCreate = Class_ReplaceMethod("Cyst", "OnCreate",
	function(self)
		originalCystOnCreate(self)
		if Client then
			InitMixin(self, BioluminesceMixin)
		end
	end
)

local GenerateBlobCoords = GetUpValue( InfestationCache.GetBlobCoords,   "GenerateBlobCoords" )
local kBlobGenNum = 200

ReplaceLocals(GenerateBlobCoords, { kBlobGenNum = kBlobGenNum })