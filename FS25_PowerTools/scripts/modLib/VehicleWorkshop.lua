--[[

'Vehicle Workshop' (part of WeezlsModLib) is a specialization for Farming Simulator 25 that enables a portable/mobile workshop to be created. 
This workshop works similar to a placeable workshop, but can be lifted and moved like a pallet or other vehicle.

Author:     w33zl (github.com/w33zl)
Version:    1.0
Modified:   2024-12-15

Changelog:
v1.0        Initial public release

License:    CC BY-NC-SA 4.0
This license allows reusers to distribute, remix, adapt, and build upon the material in any medium or 
format for noncommercial purposes only, and only so long as attribution is given to the creator (i.e. this license header).
If you remix, adapt, or build upon the material, you must license the modified material under identical terms. 

TL;DR: You can use this script for free, but you must give credit to the author (w33zl), you cannot sell it, and you need to keep this header.

--------------------------------------------------------------------------------------

USAGE INSTRUCTIONS:

	<modDesc>

		...

		<specializations>
			<specialization name="vehicleWorkshop" className="VehicleWorkshop" filename="scripts/modLib/VehicleWorkshop.lua" />
		</specializations>

		<vehicleTypes>
			<type name="mobileWorkshop" filename="$dataS/scripts/vehicles/Vehicle.lua" parent="base">
				<specialization name="vehicleWorkshop" />
			</type>
		</vehicleTypes>

		...

	</modDesc>

]]


VehicleWorkshop = {}
local SPEC_NAME = ("spec_%s.vehicleWorkshop"):format(g_currentModName)
function VehicleWorkshop.prerequisitesPresent(specializations)
	return true
end
function VehicleWorkshop.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setOwnerFarmId", VehicleWorkshop.setOwnerFarmId)
end
function VehicleWorkshop.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", VehicleWorkshop)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", VehicleWorkshop)
end

function VehicleWorkshop.initSpecialization()
	local schema = Vehicle.xmlSchema
	local baseKey = "vehicle.vehicleWorkshop"
	schema:setXMLSpecializationType("VehicleWorkshop")
	VehicleSellingPoint.registerXMLPaths(schema, baseKey .. ".sellingPoint")
	schema:setXMLSpecializationType()
end

function VehicleWorkshop:onLoad()
	local spec = self[SPEC_NAME]
	spec.sellingPoint = VehicleSellingPoint.new()
	spec.sellingPoint:load(self.components, self.xmlFile, "vehicle.vehicleWorkshop.sellingPoint", self.i3dMappings)
	spec.sellingPoint:setOwnerFarmId(self:getOwnerFarmId())
end

function VehicleWorkshop.onDelete(self)
	local spec = self[SPEC_NAME]
	if spec.sellingPoint ~= nil then
		spec.sellingPoint:delete()
	end
end

function VehicleWorkshop.setOwnerFarmId(self, superFunc, farmId, noEventSend)
	local spec = self[SPEC_NAME]
	superFunc(self, farmId, noEventSend)
	if spec.sellingPoint ~= nil then
		spec.sellingPoint:setOwnerFarmId(farmId)
	end
end
