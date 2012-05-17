---
-- Created by IntelliJ IDEA.
-- @author callin2@gmail.com
-- @copyright 2012 임창진
--

require 'Coat'

---------------------------------------------------------------------------------------------
class 'classes.ParticleType'

has.name        = {is="rw", isa="string"}
has.prop        = {is="rw", isa="table", default=function() return {} end}

function method:DEMOLISH()
    print('ParticleType DEMOLISH',self.name)
    self.name =  nil
    self.prop = nil
end
