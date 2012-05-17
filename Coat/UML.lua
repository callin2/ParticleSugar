
--
-- lua-Coat : <http://fperrad.github.com/lua-Coat/>
--

local pairs = pairs
local table = require 'table'

local mc = require 'Coat.Meta.Class'
local mr = require 'Coat.Meta.Role'

_ENV = nil
local _M = {}

local function escape (txt)
    txt = txt:gsub( '&', '&amp;' )
    txt = txt:gsub( '<', '&lt;' )
    txt = txt:gsub( '>', '&gt;' )
    return txt
end

local function find_type (name)
    if mc.class(name) then
        return name
    end
    if mr.role(name) then
        return name
    end
    local capt = name:match'^table(%b<>)$'
    if capt then
        local typev = capt:sub(2, capt:len()-1)
        local idx = typev:find','
        if idx then
            typev = typev:sub(idx+1)
        end
        return find_type(typev), true
    end
end

local function sort (...)
    local k, v = {}, {}
    for name, val in ... do
        k[#k+1] = name
        v[name] = val
    end
    table.sort(k, function (a, b)
                      return a:gsub('^_', '') < b:gsub('^_', '')
                  end)
    local i = 0
    return  function ()
                i = i + 1
                local name = k[i]
                return name, v[name]
            end
end

function _M.to_dot (opt)
    opt = opt or {}
    local with_attr = not opt.no_attr
    local with_meth = not opt.no_meth
    local with_meta = not opt.no_meta
    local note = opt.note
    local out = 'digraph {\n\n    node [shape=record];\n\n'
    if note then
        out = out .. '    "__note__"\n'
        out = out .. '        [label="' .. note .. '" shape=note];\n\n'
    end
    for classname, class in pairs(mc.classes()) do
        out = out .. '    "' .. classname .. '"\n'
        out = out .. '        [label="{'
        if class.instance then
            out = out .. '&laquo;singleton&raquo;\\n'
        end
        out = out .. '\\N'
        if with_attr then
            local first = true
            for name, attr in sort(mc.attributes(class)) do
                if first then
                    out = out .. '|'
                    first = false
                end
                out = out .. name
                if attr.isa then
                    out = out .. ' : ' .. escape(attr.isa)
                elseif attr.does then
                    out = out .. ' : ' .. attr.does
                end
                out = out .. '\\l'
            end
        end
        if with_meth then
            local first = true
            if with_meta then
                for name in sort(mc.metamethods(class)) do
                    if first then
                        out = out .. '|'
                        first = false
                    end
                    out = out .. name .. '()\\l'
                end
            end
            for name in sort(mc.methods(class)) do
                if first then
                    out = out .. '|'
                    first = false
                end
                out = out .. name .. '()\\l'
            end
        end
        out = out .. '}"];\n'
        for name, attr in mc.attributes(class) do
            if attr.isa then
                local isa, agreg = find_type(attr.isa)
                if isa then
                    out = out .. '    "' .. classname .. '" -> "' .. isa .. '" // attr isa ' .. attr.isa .. '\n'
                    if agreg then
                        out = out .. '        [label = "' .. name .. '", dir = back, arrowtail = odiamond];\n'
                    else
                        out = out .. '        [label = "' .. name .. '", dir = back, arrowtail = diamond];\n'
                    end
                end
            end
            if attr.does and mr.role(attr.does) then
                out = out .. '    "' .. classname .. '" -> "' .. attr.does .. '" // attr does\n'
                out = out .. '        [label = "' .. name .. '", dir = back, arrowtail = diamond];\n'
            end
        end
        for parent in mc.parents(class) do
            out = out .. '    "' .. classname .. '" -> "' .. parent .. '" // extends\n'
            out = out .. '        [arrowhead = onormal, arrowtail = none, arrowsize = 2.0];\n'
        end
        for role in mc.roles(class) do
            out = out .. '    "' .. classname .. '" -> "' .. role .. '" // with\n'
            out = out .. '        [arrowhead = odot, arrowtail = none];\n'
        end
        out = out .. '\n'
    end
    for rolename, role in pairs(mr.roles()) do
        out = out .. '    "' .. rolename .. '"\n'
        out = out .. '        [label="{&laquo;role&raquo;\\n\\N'
        if with_attr then
            local first = true
            for name, attr in sort(mr.attributes(role)) do
                if first then
                    out = out .. '|'
                    first = false
                end
                out = out .. name
                if attr.isa then
                    out = out .. ' : ' .. escape(attr.isa)
                elseif attr.does then
                    out = out .. ' : ' .. attr.does
                end
                out = out .. '\\l'
            end
        end
        if with_meth then
            local first = true
            for name in sort(mr.methods(role)) do
                if first then
                    out = out .. '|'
                    first = false
                end
                out = out .. name .. '()\\l'
            end
        end
        out = out .. '}"];\n\n'
        for name, attr in mr.attributes(role) do
            if attr.isa then
                local isa, agreg = find_type(attr.isa)
                if isa then
                    out = out .. '    "' .. rolename .. '" -> "' .. isa .. '" // attr isa ' .. attr.isa .. '\n'
                    if agreg then
                        out = out .. '        [label = "' .. name .. '", dir = back, arrowtail = odiamond];\n'
                    else
                        out = out .. '        [label = "' .. name .. '", dir = back, arrowtail = diamond];\n'
                    end
                end
            end
            if attr.does and mr.role(attr.does) then
                out = out .. '    "' .. rolename .. '" -> "' .. attr.does .. '" // attr does\n'
                out = out .. '        [label = "' .. name .. '", dir = back, arrowtail = diamond];\n'
            end
        end
    end
    out = out .. '}'
    return out
end

return _M
--
-- Copyright (c) 2009-2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
