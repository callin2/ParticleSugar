---
-- Created by IntelliJ IDEA.
-- @author callin2@gmail.com
-- @copyright 2012 임창진
--

local storyboard = require("storyboard")
local PS = require("classes.ParticleSugar").instance()

local scene = storyboard.newScene()

function scene:createScene(event)
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene(event)
    storyboard.removeAll()
    local group = self.view

	display.newText(group, "effect 3",20,20,native.systemFont, 24)

	----------- particle begin -------------
	Runtime:addEventListener('enterFrame', PS )
	
	local dustEm = PS:newEmitter{
		name="pointLoopEm",
		x=0,y=0,
		rotation=0,
		visible=true,
		loop=false, 
		autoDestroy=false
	}
    dustEm:setParentGroup(group)
	dustEm.x = 160
	dustEm.y = 160

    PS:newParticleType{
		name="leafPt",prop={
			velocityStart = 40,
			velocityVariation = 120,
			velocityChange = -.05,
			rotationStart = 0,
			rotationChange = 10,
			rotationVariation = 360,
			directionVariation = 60,
			autoOrientation = true,
			killOutsideScreen = false,
			lifeTime = 1200,
			alphaStart = .91,
			fadeInSpeed = 0.5,
			fadeOutSpeed = -0.75,
			fadeOutDelay = 250,
			scaleStart = 2,
			scaleVariation = 2,
			imagePath={
				"image/l1.png",
			},
			imageWidth=9,
			imageHeight=6,
		}
	}

    PS:attachParticleType("pointLoopEm", "leafPt", 300, 300, 0)

	----------- particle end -------------
	
	-- button --
	local caption = display.newText(group, "Prev",20,420,native.systemFont, 24)
	caption:addEventListener('touch',function(event)
		if event.phase == 'ended' then
			storyboard.gotoScene("scene.effect2")
		end
	end)
	
	local caption1 = display.newText(group, "start emit",100,420,native.systemFont, 24)
	caption1:addEventListener('touch',function()
		PS:startEmitter('pointLoopEm',true)
	end)
	
	local caption2 = display.newText(group, "Next",240,420,native.systemFont, 24)
	caption2:addEventListener('touch',function(event)
		if event.phase == 'ended' then
			storyboard.gotoScene("scene.effect4")
		end
	end)
	
	-- button end --
	
	-- button end --
end





-- Called when scene is about to move offscreen:
function scene:exitScene(event)
    local group = self.view

	Runtime:removeEventListener('enterFrame', PS )
	PS:cleanUp()
end

-- If scene's view is removed, scene:destroyScene() will be called just prior to:
function scene:destroyScene(event)
    local group = self.view
    collectgarbage('collect')
end

-----------------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
-----------------------------------------------------------------------------------------

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener("createScene", scene)

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener("enterScene", scene)

-- "exitScene" event is dispatched whenever before next scene's transition begins
scene:addEventListener("exitScene", scene)

-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener("destroyScene", scene)

-----------------------------------------------------------------------------------------

return scene
