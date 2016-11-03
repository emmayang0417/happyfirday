--[[
Example:
local q = TSW.q()
		:write('log')
		:add_tag('type',type)
		:add_field('content',content)

local r = Timeseries.write({ query = tostring(q) })
]]--

TSW = {}
TSW.__index = TSW

local bool_values = {'t', 'T', 'true', 'True', 'f', 'F', 'false', 'False'}

function TSW.q()
	local ts = {}
	setmetatable(ts, TSW)

	return ts
end

function TSW.escape_measurement(msmt)
	msmt = string.gsub(msmt,',','\\,')
	msmt = string.gsub(msmt,' ','\\ ')
	return msmt
end

function TSW.escape_key(idf)
	idf = string.gsub(idf,',','\\,')
	idf = string.gsub(idf,' ','\\ ')
	idf = string.gsub(idf,'=','\\=')
	return idf
end

function TSW.escape_field(field)
	field = string.gsub(field,'"','\\"')
	return '"' .. field .. '"'
end

function TSW.escape_field_bool(field)
	local value = nil
	if field == true or field == false then
		value = tostring(field)
	else
		for i,v in ipairs(bool_values) do
			if v == field then
				if i <= 4 then
					value = 'true'
				else
					value = 'false'
				end
			end
		end
	end
	return value
end

function TSW.escape_field_number(field)
	field = tonumber(field)
	return tostring(field)
end

function TSW.is_boolean(bool)
	for i,v in ipairs(bool_values) do
		if v == bool then
			return true
		end
	end
	return (bool == true) or (bool == false)
end

-- function TSW.escape_value(val)
-- 	if val == tonumber(val) then
-- 		return val
-- 	elseif TSW.is_boolean(val) then
-- 		return val
-- 	else
-- 		val = tostring(val)
-- 		return tostring(val)
-- 	end
-- end

function TSW:write(name)
	self._name = TSW.escape_measurement(tostring(name))
	return self
end

function TSW:add_tag(tag,value)
	if type(self._tag) ~= "table" then
		self._tag = {}
	end
	tag = TSW.escape_key(tag)
	value = TSW.escape_key(value)
	self._tag[tag] = value
	return self
end

function TSW:add_field(field,value)
	if type(self._field) ~= "table" then
		self._field = {}
	end
	field = TSW.escape_key(field)
	value = TSW.escape_field(value)
	self._field[field] = value
	return self
end

function TSW:add_field_bool(field,value)
	if type(self._field) ~= "table" then
		self._field = {}
	end
	field = TSW.escape_key(field)
	value = TSW.escape_field_bool(value)
	self._field[field] = value
	return self
end

function TSW:add_field_number(field,value,integer)
	if type(self._field) ~= "table" then
		self._field = {}
	end
	field = TSW.escape_key(field)
	value = TSW.escape_field_number(value)
	if integer ~= nil then
		value = value .. 'i'
	end
	self._field[field] = value
	return self
end

function TSW:at(time)
	self._time = tostring(time)
end

-- keys are ordered so everytime the query is created they are the same
-- Influxdb also have best performance with it
function TSW:__tostring()
	-- local s = 'INSERT ' -- Murano does this for you
	local s = ''

	s = s .. self._name

	local sep = ','
	if self._tag ~= nil then
		for k,v in orderedPairs(self._tag) do
			s = s .. sep .. k .. '=' .. tostring(v)
		end
	end

	if self._field ~= nil then
		sep = ' '
		for k,v in orderedPairs(self._field) do
			s = s .. sep .. k .. '=' .. tostring(v)
			sep = ','
		end
	end

	if self._time ~= nil then
		s = s .. ' ' .. self._time
	end
	return s
end

--
-- ordered pairs
--
function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
end

function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    local key = nil
    --print("orderedNext: state = "..tostring(state) )
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
    else
        -- fetch the next value
        for i = 1,#t.__orderedIndex do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i+1]
            end
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

-- end of ordered pairs

if _VERSION == "Lua 5.1" then
	-- From https://github.com/keplerproject/lua-compat-5.2
	table.unpack = unpack
	table.pack = function(...)
		return { n = select('#', ...), ... }
	end
end

