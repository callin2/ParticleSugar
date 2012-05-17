
--
-- lua-Coat : <http://fperrad.github.com/lua-Coat/>
--

_ENV = nil
local _M = {}

local _roles = {}
function _M.roles ()
    return _roles
end

function _M.role (name)
    return _roles[name]
end

function _M.attributes (role)
    local i = 0
    return  function ()
                local v
                repeat
                    i = i + 1
                    v = role._STORE[i]
                    if not v then return nil end
                until v[1] == 'has'
                return v[2], v[3]
            end
end

function _M.methods (role)
    local i = 0
    return  function ()
                local v
                repeat
                    i = i + 1
                    v = role._STORE[i]
                    if not v then return nil end
                    local name = v[2]
                until v[1] == 'method' and not name:match '^_build_'
                  and not name:match '^_get_' and not name:match '^_set_'
                return v[2], v[3]
            end
end

return _M
--
-- Copyright (c) 2009-2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
