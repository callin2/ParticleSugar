
--
-- lua-Coat : <http://fperrad.github.com/lua-Coat/>
--

local basic_type = type
local setmetatable = setmetatable
local next = next

_ENV = nil
local _M = {}

local _classes = {}
function _M.classes ()
    return _classes
end

function _M.class (name)
    return _classes[name]
end

function _M.has (class, name)
    return class._ATTR[name]
end

local reserved = {
    BUILD = true,
    can = true,
    does = true,
    dump = true,
    extends = true,
    instance = true,
    isa = true,
    memoize = true,
    mock = true,
    new = true,
    type = true,
    unmock = true,
    with = true,
    _INIT = true,
    __gc = true,
}

function _M.attributes (class)
    return next, class._ATTR, nil
end

function _M.methods (class)
    local function getnext (t, k)
        local v
        repeat
            k, v = next(t, k)
            if not k then return nil end
        until not reserved[k]
          and basic_type(v) == 'function'
          and not k:match '^_get_' and not k:match '^_set_'
          and not k:match '^_build_'
        return k, v
    end
    return getnext, class, nil
end

function _M.metamethods (class)
    local function getnext (mt, k)
        local v
        repeat
            k, v = next(mt, k)
            if not k then return nil end
        until k ~= '__index'
        return k, v
    end
    return getnext, class._MT, nil
end

function _M.parents (class)
    local i = 0
    return  function ()
                i = i + 1
                local parent = class._PARENT[i]
                return parent and parent._NAME, parent
            end
end

function _M.roles (class)
    local i = 0
    return  function ()
                i = i + 1
                local role = class._ROLE[i]
                return role and role._NAME, role
            end
end

_M._CACHE = setmetatable({}, { __mode = 'v' })

return _M
--
-- Copyright (c) 2009-2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
