require "core:const"

register_ui = core.register_storage( "ui_elements", "ui_element" )

table.merge( being, object )

function being:get_stat( num )
	if num == 1 then return self.st end
	if num == 2 then return self.dx end
	if num == 3 then return self.en end
	if num == 4 then return self.wp end
	return 0
end

function being:inc_stat( num, amount )
	amount = amount or 1
	if num == 1 then self.st = self.st + amount end
	if num == 2 then self.dx = self.dx + amount end
	if num == 3 then self.en = self.en + amount end
	if num == 4 then self.wp = self.wp + amount end
end

function being:set_stat( num, amount )
	if num == 1 then self.st = amount end
	if num == 2 then self.dx = amount end
	if num == 3 then self.en = amount end
	if num == 4 then self.wp = amount end
end

function being:play_sound( sound, id2 )
	local sid
	if id2 then
		sid = ui.resolve_sound_id( sid, id2 )
	else 
		sid = ui.resolve_sound_id( self.id, sid )
	end
	if sid ~= "" then
		if audio then
			audio.play_sound( sid, self.position )
		end
	end
end

setmetatable( being, getmetatable(object) )

table.merge( player, being )

function player:req_met( id, value )
	if skills[id] then return self:get_skill( id ) >= value end
	return player[id] >= value
end

function player:can_pick_skill( skill )
	if self:get_skill( skill ) >= skills[skill].max_level then return false end
	for id,value in pairs( skills[skill].reqs ) do
		if not self:req_met( id, value ) then return false end
	end
	return true
end

function player:add_ammo( id, amount, reload )
	local skill   = skills[id]
	local sammo   = skill.ammo_slot
	local squiver = skill.quiver_slot
	local mammo   = skill.ammo_max
	local mquiver = skill.quiver_max

	if squiver == 0 then
		self:set_ammo( sammo, math.min( self:get_ammo( sammo ) + amount, mammo ) )
	else
		if reload then
			local sum  = math.min( self:get_ammo( squiver ) + self:get_ammo( sammo ) + amount, mquiver + mammo )
			self:set_ammo( sammo, math.min( mammo, sum ) )
			self:set_ammo( squiver, math.max( 0, sum - mammo ) )
		else
			self:set_ammo( squiver, math.min( self:get_ammo( squiver ) + amount, mquiver ) )
		end			
	end
end

setmetatable( player, getmetatable(being) )

level.default = {}

function level:clamp_area( a )
	if a then 
		return a:clamped( area.FULL )
	else
		return area.FULL:clone()
	end
end

function level:find_cell( condition, a )
	a = self:clamp_area( a )
	for c in a() do
		if condition(c) then return c end
	end
end

function level:for_all_cells( action, a )
	a = self:clamp_area( a )
	for c in a() do
		action(c)
	end
end

function level:random_coord( condition, a )
	a = self:clamp_area( a );
	if type(condition) == "nil" then
		return a:random_coord()
	else
		local count = 0
		local c
		repeat
			if count == 100 then return end
			c = a:random_coord()
			count = count + 1
		until condition(c)
		return c
	end
end

function level:placement_coord( c )
	return level:get_being( c ) == nil and not cells[ level:get_cell( c ) ].flags[ TF_NOMOVE ]
end

function level:spawn_on_edge( id, amount, lvl )
	lvl = lvl or 0
	amount = amount or 1
	local c
	local result 
	repeat
		repeat 
			c = area.FULL:random_edge_coord()
		until self:placement_coord( c )
		result = level:summon( id, c, lvl )
		amount = amount - 1
	until amount <= 0
	return result
end

function level:spawn_on_map( id, amount, lvl )
	lvl = lvl or 0
	amount = amount or 1
	local c
	local result 
	repeat
		repeat 
			c = area.FULL_SHRINKED:random_coord()
		until self:placement_coord( c )
		result = level:summon( id, c, lvl )
		amount = amount - 1
	until amount <= 0
	return result
end

table.merge( level, object )
setmetatable( level, getmetatable(object) )

-- Metatable hack that disallows usage of undeclared variables --
setmetatable(_G, {
  __newindex = function (_, n)
  error("attempt to write to undeclared variable "..n, 2)
  end,
  __index = function (_, n)
  error("attempt to read undeclared variable "..n, 2)
  end,
})
