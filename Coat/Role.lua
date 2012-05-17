
--
-- lua-Coat : <http://fperrad.github.com/lua-Coat/>
--

local setmetatable = setmetatable
local _G = _G
local Coat = require 'Coat'
local Meta = require 'Coat.Meta.Role'

local basic_type = type
local checktype = Coat.checktype
local module = Coat.module

_ENV = nil
local _M = {}

local function has (role, name, options)
    checktype('has', 1, name, 'string')
    checktype('has', 2, options or {}, 'table')
    local t = role._STORE; t[#t+1] = { 'has', name, options }
end
_M.has = has

local function method (role, name, func)
    checktype('method', 1, name, 'string')
    checktype('method', 2, func, 'function')
    local t = role._STORE; t[#t+1] = { 'method', name, func }
end
_M.method = method

local function requires (role, ...)
    local t = role._REQ
    local arg = {...}
    for i = 1, #arg do
        local meth = arg[i]
        checktype('requires', i, meth, 'string')
        t[#t+1] = meth
    end
end
_M.requires = requires

local function excludes (role, ...)
    local t = role._EXCL
    local arg = {...}
    for i = 1, #arg do
        local r = arg[i]
        checktype('excludes', i, r, 'string')
        t[#t+1] = r
    end
end
_M.excludes = excludes

function _G.role (modname)
    checktype('role', 1, modname, 'string')
    local M = module(modname, 3)
    setmetatable(M, { __index = _G })
    M._STORE = {}
    M._REQ = {}
    M._EXCL = {}
    M.has = setmetatable({}, { __newindex = function (t, k, v) has(M, k, v) end })
    M.method = setmetatable({}, { __newindex = function (t, k, v) method(M, k, v) end })
    M.requires = function (...) return requires(M, ...) end
    M.excludes = function (...) return excludes(M, ...) end
    local roles = Meta.roles()
    roles[modname] = M
end

return _M
--
-- Copyright (c) 2009-2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
