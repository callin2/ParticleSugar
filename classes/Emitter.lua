---
-- Created by IntelliJ IDEA.
-- @author callin2@gmail.com
-- @copyright 2012 임창진
--

require 'Coat'
---------------------------------------------------------------------------------------------
class 'classes.Emitter'

has.name        = {is="rw", isa="string"}
has.x           = {is="rw", isa="number"}
has.y           = {is="rw", isa="number"}
has.rotation    = {is="rw", isa="number"}
has.visible     = {is="rw", isa="boolean", default=true}
has.loop        = {is="rw", isa="boolean", default=false}
has.autoDestroy = {is="rw", isa="boolean", default=false}
has.emitterScale= {is="rw", isa="number",default=1}
has.active      = {is="rw", isa="boolean", default=false}
has.group       = {is="rw"}

has._activePtCount = {is="rw", isa="number",default=0}

has._rateTable  = {is="rw", isa="table", default=function() return {} end}

--[[
	em.followObjInfo = {
		target		 = dispObj,
		autoRotate 	 = autoRotate ,
		rotationOffset = rotationOffset,
		xOffset 	 = xOffset,
		yOffset 	 = yOffset,
	}
--]]
has.followObjInfo = {is="rw", isa="table"}


function method:BUILD()
end

function method:setParentGroup(grp)
    self.group = grp
end

function method:changeEmissionRate(particleTypeName, rate)
    self._rateTable[particleTypeName] = rate
end

-- todo change x accroding to emittionShape
function method:getNewX()
	if self.followObjInfo and self.followObjInfo.target then
		return self.followObjInfo.target.x + self.followObjInfo.xOffset
	else
		return self.x
	end
end

-- todo change x accroding to emittionShape
function method:getNewY()
    if self.followObjInfo and self.followObjInfo.target then
		return self.followObjInfo.target.y + self.followObjInfo.yOffset
	else
		return self.y
	end
end


function method:DEMOLISH()
    print('emitter DEMOLISH')

    for i=#(self._rateTable),1,-1 do
        self._rateTable[i] = nil
    end

    self._rateTable = nil
    self.group = nil
end


