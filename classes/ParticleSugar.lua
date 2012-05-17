---
-- Created by IntelliJ IDEA.
-- @author callin2@gmail.com
-- @copyright 2012 임창진
--

require 'Coat'

local _ = require("lib.underscore")

local Emitter = require("classes.Emitter")
local ParticleType = require("classes.ParticleType")

local sin, cos, rad = math.sin, math.cos, math.rad
local random, floor, max = math.random, math.floor, math.max
local _MARGIN = 0

local defaultParticleTypeProp = {
    scaleStart = 1,
    scaleVariation = 0,
    scaleInSpeed = 0,
    scaleOutSpeed = 0,
    scaleMax = 2,
    scaleOutDelay = 50000,
    velocityStart = 10, -- pixel per sec
    velocityVariation = 0,
    velocityChange = 0,
    directionVariation = 0,
    rotationStart = 0,
    rotationVariation = 0,
    rotationChange = 0,
    alphaStart = 1,
    alphaVariation = 0,
    fadeInSpeed = 0,
    fadeOutSpeed = .5,
    fadeOutDelay = 50000,
    bounceX = false,
    bounceY = false,
    bounciness = 0.5,
    killOutsideScreen = true,
}

local function merge(t1,t2)
	local t0 = {}
	for i,v in pairs(t1) do
		t0[i]=v
	end

	for i,v in pairs(t2) do
		t0[i]=v
	end

	return t0
end

function clone(t)            
  local new = {}             
  local i, v = next(t, nil)  
  while i do
    new[i] = v
    i, v = next(t, i)        
  end
  return new
end
----------------------------------------------------------------------------
singleton 'classes.ParticleSugar'

has._emitterPool = {is="ro", isa="table", default={} }
has._particleTypePool = {is="ro", isa="table", default={} }

--[[
 	EPLink --> store emitter particletype link info
	key : {emittername, particletypename,emittionRate,duration,delay}
	value : true
--]]

has._EPLink = {is="ro", isa="table", default=function() return {} end}
has._activeParticles = {is="ro", isa="table", default=function() return {} end}
has._lastTimeStamp = {is="rw", default=function() return system.getTimer() end}
has._freezeTime = {is="rw"}

has.active = {is="rw", isa="boolean", default=true}
has.deltaT = {is="rw", isa="number", default=33}

-------------------------------

--- @param :name is optional if exist iverride param.name
function method:newEmitter(param, name)
    local em = Emitter.new(param)


    if name then
        em.name = name
    end

    if self._emitterPool[em.name] then
        self._emitterPool[em.name]:__gc()
    end


    -- print(em, em.name)

    self._emitterPool[em.name] = em;
    return em;
end


function method:newParticleType(...)
    local pt = ParticleType.new(...)

    pt.prop = merge(defaultParticleTypeProp, pt.prop)

    if self._particleTypePool[pt.name] then
        self._particleTypePool[pt.name]:__gc()
    end

    self._particleTypePool[pt.name] = pt;
    return pt;
end


function method:listEmitters()
    print('All emitter')
    _(self._emitterPool):each(function(em)
        print(' emitter : ', em)

    -- todo print particle type name
    end)
end


function method:getEmitter(name)
    return self._emitterPool[name];
end

-- todo
function method:getEmitterScale(name)
    return self._emitterPool[name].scale;
end

function method:deleteEmitter(name)
    self._emitterPool[name]:delete()
    self._emitterPool[name] = nil
end

function method:emitterIsActive(name)
    return self._emitterPool[name] and self._emitterPool[name].active or nil
end

-- todo
function method:setEmitterListener(emitterName, listener)
end

-- todo
function method:SetEmitterSound(emitterName, SoundHandle, delay, autoStop, SoundSettings)
end

-- todo
function method:setEmitterTarget(emitterName, dispObj, autoRotate, rotationOffset, xOffset, yOffset)
	local em = self._emitterPool[emitterName]

    if not em then
        print('emiiter not exist', emName, ptName)
        error('emiiter not exist')
    end

	if not( dispObj.x and dispObj.y ) then
		print('taget type must be corona display object')
		error('taget type must be corona display object')
	end

	-- default value setting
	autoRotate = autoRotate or false
	rotationOffset = rotationOffset or 0
	xOffset = xOffset or 0
	yOffset = yOffset or 0


	if dispObj then
		em.followObjInfo = {
			target		 = dispObj,
			autoRotate 	 = autoRotate ,
			rotationOffset = rotationOffset,
			xOffset 	 = xOffset,
			yOffset 	 = yOffset,
		}
	else
		em.followObjInfo = nil
	end

end


function method:startEmitter(emitterNameOrInstance, runOnce)
    local em = type(emitterNameOrInstance) == 'string' and
            self._emitterPool[emitterNameOrInstance]
            or emitterNameOrInstance

    -- print('em.active,em._activePtCount', em.active,em._activePtCount)

    em.active = true;
    em._activePtCount = 0

    _(_.keys(self._EPLink)):chain():select(function(link)
        return link.emitterName == em.name
    end):each(function(link)
        link._delay = -link.delay
        link._duration = link.delay + link.duration

        em._activePtCount = em._activePtCount + 1
    end)

    if runOnce then
        -- print('run once')
        _(_.keys(self._EPLink)):chain():select(function(link)
            return link.emitterName == em.name and link._duration > 0 -- 2.1 get attached particle type
        end):each(function(link)
            self:_generateAParticleType(link)

--~             self:_newParticle(link)
        end)

        em.active = false;
        em._activePtCount = 0

        -- print('## em.active,em._activePtCount', em.active,em._activePtCount)
        return
    end


end

function method:stopEmitter(emitterNameOrInstance)
    -- print('stopEmitter')
    local em = type(emitterNameOrInstance) == 'string' and
            self._emitterPool[emitterNameOrInstance]
            or emitterNameOrInstance

    em.active = false;
end

-- todo
function method:defineEmissionShape(emitterName, Array, useEmitterRotation, useCornersOnly, showLines)
end


function method:attachParticleType(emName, ptName, emissionRate, duration, delay)
    -- print('attachParticleType begin')
    local em, pt = self._emitterPool[emName], self._particleTypePool[ptName]

    if not em or not pt then
        print('emiiter or particle type not exist', emName, ptName)
        error('emiiter or particle type not exist')
    end

    local link = _(_.keys(self._EPLink)):select(function(link)
        return link.emitterName == emName and link.particleTypeName == ptName
    end)

    if #link == 1 then
        link[1].emissionRate = emissionRate
        link[1].duration = duration
        link[1].delay = delay
        link[1]._skipCnt = 1
    else
        self._EPLink[{
            emitterName = emName,
            particleTypeName = ptName,
            emissionRate = emissionRate,
            duration = duration,
            delay = delay,
            _skipCnt = 1,
        }] = true
    end

    -- print('attachParticleType end')
end


--- @param particleName (optional) : if not exist all EPLink which has same emmiter wil be detached
function method:detachParticleTypes(emitterName, particleName)
    local em, pt = self._emitterPool[emitterName], self._particleTypePool[particleName]
    local ctx = self
    if not em then
        print('emiiter not exist', emitterName)
        error('emiiter not exist')
    end

    _(_.keys(self._EPLink)):chain():select(function(link)
        if not pt then
            return link.emitterName == emitterName
        else
            return link.emitterName == emitterName and link.particleTypeName == particleName
        end
    end):each(function(k)
        ctx._EPLink[k] = nil
    end)
end

function method:cleanUp()
    self:freez()

    for k, v in pairs(self._activeParticles) do
        self:_deleteParticle(k)
    end

    for k, v in pairs(self._EPLink) do
        self._EPLink[k] = nil
    end

    for k, v in pairs(self._particleTypePool) do
        self._particleTypePool[k]:__gc()
        self._particleTypePool[k] = nil
    end

    for k, v in pairs(self._emitterPool) do
        self._emitterPool[k]:__gc()
        self._emitterPool[k] = nil
    end

    self:wakeup()
end

function method:freez()
    self.active = false
    self._freezeTime = system.getTimer()
end

function method:wakeup()
    local timeGap = system.getTimer() - self._freezeTime

    _(_.keys(self._activeParticles)):each(function(particle)
        _({ '_createTime', 'killTime', '_fadeOutTime', '_scaleOutTime' }):each(function(v)
            particle[v] = particle[v] + timeGap
        end)
    end)

    self.active = true
end

function method:_deleteParticle(particle)
    -- print('_deleteParticle')
    self._activeParticles[particle] = nil
    particle:removeSelf()
    particle = nil
end

function method:_newParticle(link)
    local ctx = self
    local pt = self._particleTypePool[link.particleTypeName] --2.2 cont.
    if not pt then return end
    local em = self._emitterPool[link.emitterName]

    local particle;
    -- print(link.emissionRate,ctx.deltaT,link._skipCnt)
    local howMany = math.floor(link.emissionRate * ctx.deltaT * 0.001 * link._skipCnt)
    link._skipCnt = howMany == 0 and (link._skipCnt + 1) or 1


    local prop = pt.prop
    for i = 1, howMany do
        if prop.spriteSet then
            -- todo
            particle = sprite.newSprite(prop.spriteSet)
			em.group:insert(particle)
			particle.x = em:getNewX()
            particle.y = em:getNewY()

            particle:prepare(prop.animSequence);
            particle:play()

        elseif prop.imagePath then
            if type(prop.imagePath) == 'string' then
                particle = display.newImageRect(em.group, prop.imagePath, prop.imageWidth, prop.imageHeight)
            elseif type(prop.imagePath) == 'table' then
                particle = display.newImageRect(em.group, prop.imagePath[random(1, #prop.imagePath)], prop.imageWidth, prop.imageHeight)
            end
            particle.x = em:getNewX()
            particle.y = em:getNewY()
        elseif prop.text then
            -- todo
        elseif prop.shape then
            if prop.shape.type == 'rect' then
                -- print('rect make')
                particle = display.newRect(em.group, em:getNewX(), em:getNewY(), prop.shape.width, prop.shape.height)
                particle:setFillColor(unpack(prop.colorStart))
                particle.color = clone(prop.colorStart)
            elseif prop.shape.type == 'circle' then
                -- print('circle make')
                particle = display.newCircle(em.group, em:getNewX(), em:getNewY(), prop.shape.radius)
                particle:setFillColor(unpack(prop.colorStart))
                particle.color = clone(prop.colorStart)
            end
        end

        local curTime = system.getTimer()
        local direction = random() * prop.directionVariation + em.rotation

        particle.xScale = prop.scaleStart * em.emitterScale + random() * prop.scaleVariation
        particle.yScale = particle.xScale

        particle.rotation = prop.rotationStart + floor(random() * prop.rotationVariation)
        particle.alpha = prop.alphaStart
        local velocity = (prop.velocityStart + random() * prop.velocityVariation)
        particle.xSpeed = velocity * cos(rad(direction)) * self.deltaT * 0.001
        particle.ySpeed = velocity * sin(rad(direction)) * self.deltaT * 0.001
        particle.killTime = prop.lifeTime + curTime
        particle._fadeOutTime = prop.fadeOutDelay + curTime
        particle._scaleOutTime = prop.scaleOutDelay + curTime
        particle.emitterName = em.name
        particle.isPhysicalParticle = false
        particle.PTypeName = pt.name
        particle._createTime = curTime
        if prop.referencePoint then
            particle:setReferencePoint(prop.referencePoint)
        end

        ctx._activeParticles[particle] = true
    end
end

function method:_moveParticle(particle)
    local pt = self._particleTypePool[particle.PTypeName]
    local em = self._emitterPool[particle.emitterName]

    local prop = pt.prop
    local curT = system.getTimer()

    --[[   =====  alpha  ======  ]]
    if (particle._fadeOutTime < curT) then
        local deltaFadeOut = prop.fadeOutSpeed * 0.001 * self.deltaT
        -- print('fadeout',deltaFadeOut,  curT, particle._fadeOutTime)
        particle.alpha = max(0, particle.alpha + deltaFadeOut)

        -- delete invisible particle
        if (particle.alpha < 0.001) then
            self:_deleteParticle(particle)
            return
        end
    end

    if (particle._fadeOutTime > curT and particle.alpha < 1) then
        -- print('fadein', curT, particle._fadeInEndTime)
        particle.alpha = math.min(1, particle.alpha + prop.fadeInSpeed * 0.001 * self.deltaT)
    end

    --[[   =====  rotation  ======  ]]
    if (prop.rotationChange ~= 0) then
        particle.rotation = particle.rotation + prop.rotationChange
    end

    if (prop.rotationChange ~= 0 or prop.velocityChange ~= 0) then
        particle.xSpeed = particle.xSpeed + prop.velocityChange * cos(rad(em.rotation))
        particle.ySpeed = particle.ySpeed + prop.velocityChange * sin(rad(em.rotation))
    end

    --[[   =====  position  ======  ]]
    if (particle.xSpeed ~= 0 or particle.ySpeed ~= 0) then
        particle.x = particle.x + particle.xSpeed
        particle.y = particle.y + particle.ySpeed
    end

    --[[   =====  scale  ======  ]]
    if ((prop.scaleOutSpeed < 0 or prop.scaleInSpeed > 0)) then
        if particle._scaleOutTime < curT then -- scaleOut
            particle.xScale = particle.xScale + prop.scaleOutSpeed * 0.001 * self.deltaT
            if particle.xScale < 0 then
                self:_deleteParticle(particle)
                return
            end
        elseif particle._scaleOutTime > curT then -- scaleIn
            particle.xScale = particle.xScale + prop.scaleInSpeed * 0.001 * self.deltaT
            if particle.xScale > prop.scaleMax then
                particle.xScale = prop.scaleMax
            end
        end
        particle.yScale = particle.xScale
    end

    --[[   =====  color  ======  ]]
    -- local gap = curT - particle._createTime
    if (prop.colorChange and (prop.colorChange[0] ~= 0 or prop.colorChange[1] ~= 0 or prop.colorChange[2] ~= 0)) then
        -- print('color',prop.colorStart[2] , prop.colorChange[2])
        for i = 1, 3 do
            particle.color[i] = particle.color[i] + prop.colorChange[i]
            if particle.color[i] > 255 then
                particle.color[i] = 255
            elseif particle.color[i] < 0 then
                particle.color[i] = 0
            end
        end
        particle:setFillColor(unpack(particle.color))
    end

    -- delete particle outside screen
    if (particle.x < -_MARGIN or particle.x > display.contentWidth + _MARGIN) then
        if not prop.bounceX and prop.killOutsideScreen then
            self:_deleteParticle(particle)
            return
        elseif prop.bounceX then
            particle.xSpeed = -particle.xSpeed * prop.bounciness
        end
    end

    if (particle.y < -_MARGIN or particle.y > display.contentHeight + _MARGIN) then
        if not prop.bounceY and prop.killOutsideScreen then
            self:_deleteParticle(particle)
            return
        elseif prop.bounceY then
            particle.ySpeed = -particle.ySpeed * prop.bounciness
        end
    end
end

function method:_generateAParticleType(link)
    -- particle generation begins after delaytime and will be finished  after duration + delaytime
    -- _delay start from  -(delay)
    link._delay = link._delay + self.deltaT
    link._duration = link._duration - self.deltaT
    local em = self._emitterPool[link.emitterName]

    -- wait more time until delay is over 0, now no need to generate particle
    if link._delay <= 0 then
        return
    elseif link._duration <= 0 then  -- it means no more paticle is needed
        em._activePtCount = em._activePtCount - 1
        if (em._activePtCount == 0) then
            if em.loop then
                self:startEmitter(em.name)
            else
                self:stopEmitter(em.name)
            end
        end
        return
    end

    self:_newParticle(link)
end

function method:enterFrame()
    self.deltaT = system.getTimer() - self._lastTimeStamp
    -- print(self , self.deltaT)
    self._lastTimeStamp = system.getTimer()

    if not self.active then return end
    local ctx = self

    -- a. move existing particle
    _(_.keys(ctx._activeParticles)):each(function(particle)
        if particle.killTime < ctx._lastTimeStamp then
            ctx:_deleteParticle(particle)
        else
            ctx:_moveParticle(particle)
        end
    end)

    -- b. generate new particle
    _(_.values(ctx._emitterPool)):chain():select(function(em)
        return em.active -- 1. filter active emitter
    end):each(function(em)
        _(_.keys(ctx._EPLink)):chain():select(function(link)
            return link.emitterName == em.name and link._duration > 0 -- 2.1 get attached particle type
        end):each(function(link)
            self:_generateAParticleType(link)
        end)
    end)
end

