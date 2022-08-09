core.declare("being_demon_table")
core.declare("BeingSkills",{})

core.register_blueprint "being"
{
	id         = { true, core.TSTRING },
	picture    = { true, core.TSTRING },
	name       = { true, core.TSTRING },
	color      = { true, core.TNUMBER },
	sprite     = { true, core.TNUMBER },
	namep      = { false, core.TSTRING },
	st         = { false, core.TNUMBER, 10 },
	dx         = { false, core.TNUMBER, 10 },
	wp         = { false, core.TNUMBER, 10 },
	en         = { false, core.TNUMBER, 10 },
	hp         = { false, core.TNUMBER, 10 },
	energy     = { false, core.TNUMBER, 100 },
	speed      = { false, core.TNUMBER, 100 },
	armor      = { false, core.TNUMBER, 0 },
	weight     = { false, core.TNUMBER, 10 },
	ranged     = { false, core.TNUMBER, 0 },
	flags      = { false, core.TFLAGS, {} },
	ai         = { false, core.TNUMBER, AI_MONSTER },

	OnCreate   = { false, core.TFUNC },
	OnAction   = { false, core.TFUNC },
	OnDie      = { false, core.TFUNC },
}

core.declare( "register_being", core.register_storage( "beings", "being", function (b) b.namep = b.namep or b.name.."s" end ))

function BeingSkills.Consume(self)
	if self.hp < self.hp_max / 3 and self.energy > 30 then
		local c = level:find_cell( function(c) 
				local being = level:get_being(c) 
				return being and being.flags[ BF_CONSUMABLE ]
			end,
			area.around( self.position, 1 )
		)
		if c then
			local being = level:get_being(c)
			if being then
				self:play_sound("consume")
				if self.visible then ui.msg('The '..self.name..' consumes the '..being.name..'!') end
				self.hp = math.min( self.hp_max, self.hp + being.hp )
				being:die()
				self.energy = self.energy - 30
				self.speed_count = self.speed_count - 1500
				return true
			end
		end
	end
	return false
end

function BeingSkills.Scavenge(self)
	if self.hp < self.hp_max / 2 and self.energy > 30 and math.random(10) < 5 then
		local c = level:find_cell( 
			function(c) return level:get_cell(c) == "bloody_corpse" end,
			area.around( self.position, 1 )
		)
		if c then
			self:play_sound("scavenge")
			if self.visible then ui.msg('The '..self.name..' eats a corpse!') end
			level:set_cell( c, "pool_of_blood" )
			self.hp = self.hp_max
			self.energy = self.energy - 30
			self.speed_count = self.speed_count - 1500
			return true
		end
	end
	return false
end

function BeingSkills.Ressurect(self)
	if self.energy > 10 then
		local count = 0
		level:for_all_cells( 
			function(c) 
				if self.energy > 10 and level:get_cell(c) == "bloody_corpse" and 
					math.random(100) < 30 and level:get_being(c) == nil then
					self:play_sound("ressurect")
					level:set_cell( c, "pool_of_blood" )
					level:summon( "skeleton", c )
					self.energy = self.energy - 10
					count = count + 1
				end
			end,
			area.around( self.position, 3 )
		)
		if count > 0 then
			self.speed_count = self.speed_count - math.min(3000,500+count*100)
			return true
		end
	end
	return false
end

function BeingSkills.Animate(self)
	if self.energy > 60 then
		local c = level:find_cell( 
			function(c) 
				return cells[level:get_cell(c)].is_tree 
			end,
			area.around( self.position, 3 )
		)
		if c then
			self:play_sound("animate")
			level:set_cell( c, "grass" )
			local tree = level:summon( "treant", c )
			if tree.visible then ui.msg('Suddenly a tree starts moving!') end
			self.energy      = self.energy - 60
			self.speed_count = self.speed_count - 2000
			return true
		end
	end
	return false
end

function BeingSkills.Blink(self, _, dist)
	if dist < 3 and self.energy > 20 and self.hp < self.hp_max / 2 then
		local s = self.position
		local c = level:random_coord( function(c) 
				return level:get_being(c) == nil and c:distance( s ) > 3
			end,
			area.around( s, 5 )
		)
		if c then
			self:play_sound("blink")
			if self.visible then ui.msg('The '..self.name..' blinks!') end
			level:explosion( s, BLUE, 1, 0, 30 )
			self:displace(c)
			level:explosion( c, BLUE, 1, 0, 30 )
			self.energy      = self.energy - 20
			self.speed_count = self.speed_count - 1200
			return true
		end
	end
	return false
end

function BeingSkills.Defile(self, vis, dist)
	if vis and dist > 1 and dist < 7 and self.energy > 10 and math.random(3) > 1 then
		local c = level:random_coord( nil, area.around( self.tposition, 2 ) )
		self:play_sound("defile")
		self:send_missile( c, MTSPORE )
		self.energy      = self.energy - 10
		self.speed_count = self.speed_count - 1500
		return true
	end
	return false
end

function BeingSkills.RangedEnergy(self, vis, dist)
	if vis and dist > 1 and dist < 7 and self.energy > 8 then
		self:play_sound("fire")
		self:send_missile( self.tposition, MTENERGY )
		self.energy      = self.energy - 8
		self.speed_count = self.speed_count - 2000
		return true
	end
	return false
end

function BeingSkills.RangedIce(self, vis, dist)
	if vis and dist > 1 and dist < 6 and self.energy > 8 then
		self:play_sound("fire")
		self:send_missile( self.tposition, MTICE )
		self.energy      = self.energy - 8
		self.speed_count = self.speed_count - 2000
		return true
	end
	return false
end

being_demon_table = {
	{ name = 'Ab', hp = 20, color = LIGHTGRAY },
	{ name = 'Da', st = 10, dx = 2, color = DARKGRAY },
	{ name = 'Ian', skill = BeingSkills.RangedEnergy, wp = 4, color = BLUE },
	{ name = 'Hee', speed = 20, color = LIGHTBLUE },
	{ name = 'Nar', skill = BeingSkills.Consume, hp = 20, en = 4, speed = -10, color = RED },
	{ name = 'Tur', flags = {BF_IMPALE}, hp = 10, st = 10, color = RED },
	{ name = 'Keh', skill = BeingSkills.Scavenge, color = RED },
	{ name = 'Gon', skill = BeingSkills.Defile, color = MAGENTA },
	{ name = 'Qua', skill = BeingSkills.Blink, flags = {BF_REGEN}, speed = 5, color = LIGHTCYAN },
	{ name = 'Nod', skill = BeingSkills.Ressurect, hp = 10, wp = 10, color = CYAN },
}

register_being "yourself"
{
	name    = 'yourself',
	namep   = '',
	picture = '@',
	color   = DARKGRAY,
	sprite  = 1,
	ai      = AI_PLAYER,
	flags   = { SF_BIG },
}	

register_being "demon"
{
	name    = 'demon',
	picture = '&',
	color   = RED,
	sprite  = 49,
	weight  = 20,
	flags   = { BF_DEMON, BF_SPORERES },
	
	OnCreate = function( self, lvl )
		local props = math.min( math.floor(lvl / 5) + 1, 5 )
		if math.random(40) < math.min(lvl,20) then props = props + 1 end
		if math.random(10) + 5 < lvl then self.flags[ BF_REGEN ] = true end
		
		self.st = self.st + lvl + math.min( lvl, 5 )	
		self.dx = self.dx + math.floor( lvl / 5 ) + math.min( lvl, 8 )
		self.en = self.en + math.floor( lvl / 3 )
		self.wp = self.wp + math.floor( lvl / 3 )
		self.speed = self.speed + lvl
		self.hp = 30 + lvl * 3
		self.name = ""
		
		local max_prop = math.max( math.floor( lvl / 2 ) + 4, #being_demon_table )
		local high_prop = 0
		
		for count = 1,props do
			local prop = math.random( max_prop )
			if prop > high_prop then high_prop = prop end
			local demon = being_demon_table[prop]
			self.name = self.name .. demon.name
			if demon.flags then self.flags[demon.flags] = true end
			for k,v in ipairs(demon) do
				if type(v) == "number" then self[k] = self[k] + v end
			end
		end
		
		self.energy = 10*self.wp
		self.hp_max = self.hp
		self.energy_max = self.energy
		self.color = being_demon_table[ high_prop ].color		
	end,
	
	OnAction = function(self, vis, dist)
		local name = self.name
		for _,v in ipairs(being_demon_table) do
			if v.skill and string.find(name,v.name) then
				if v.skill(self,vis,dist) then return true end
			end
		end
		return false
	end,
		
}

register_being "beast"
{
	name    = 'beast',
	picture = 'b',
	color   = DARKGRAY,
	sprite  = 50,
	weight  = 9,
	flags   = { BF_CONSUMABLE },
}

register_being "bulldemon"
{
	name    = 'bulldemon',
	picture = 'B',
	color   = BROWN,
	sprite  = 51,
	st      = 15,
	dx      = 14,
	hp      = 30,
	speed   = 90,
	weight  = 12,
	flags   = { BF_CONSUMABLE, BF_IMPALE },
}

register_being "mandagore"
{
	name 	= 'mandagore',
	picture = 'M',
	color   = RED,
	sprite  = 52,
	st      = 22,
	dx      = 12,
	hp      = 60,
	speed   = 60, 
	armor 	= 2,
	weight  = 12,
	
	OnCreate = function(self)
		ui.msg('You hear a howl!')
	end,
	
	OnAction = BeingSkills.Consume,
}

register_being "defiler"
{
	name 	= 'defiler',
	picture = 'D',
	color   = MAGENTA,
	sprite  = 53,
	st      = 14,
	dx      = 12,
	wp      = 14,
	hp      = 50,
	speed   = 110,
	flags   = { BF_SPORERES },
		
	OnCreate = function(self)
		ui.msg('You feel a stench!')
	end,
	
	OnAction = BeingSkills.Defile,
}

register_being "imp"
{
	name    = 'imp',
	picture = 'i',
	color   = BLUE,
	sprite  = 54,
	st      = 12,
	dx      = 9,
	wp      = 12,
	speed   = 110,
	flags   = { BF_CONSUMABLE },
	OnAction = BeingSkills.RangedEnergy,
}

register_being "phasehound"
{
	name    = 'phasehound',
	picture = 'h',
	color   = CYAN,      
	sprite  = 55,
	st      = 12,
	dx      = 14,
	wp      = 12,
	hp      = 20,
	speed   = 120,
	weight  = 9, 
	flags   = { BF_REGEN, BF_CONSUMABLE },
	
	OnAction = BeingSkills.Blink,
}

register_being "skeleton"
{
	name    = 'skeleton',
	picture = 's',
	color   = LIGHTGRAY,
	sprite  = 56, 
	dx      = 9,
	speed   = 70, 
	weight  = 6,
	flags   = { BF_SPORERES, BF_SKELETAL, BF_NOCORPSE },
}

register_being "wraith"
{
	name    = 'wraith',
	picture = 'W',
	color   = LIGHTCYAN,
	sprite  = 57,
	st      = 20,
	dx      = 12, 
	wp      = 14, 
	hp      = 60,
	speed   = 60,
	flags   = { BF_SPORERES, BF_SKELETAL, BF_NOCORPSE },
	
	OnCreate = function(self)
		ui.msg('The smell of death!')
	end,
	
	OnAction = BeingSkills.Ressurect,
}

register_being "spore"
{
	name    = 'spore',
	picture = '.',
	color   = LIGHTGREEN,
	sprite  = 58,
	dx      = 0,
	energy  = 5,
	armor   = 3, 
	flags   = { BF_SPORERES, BF_DEFILED, BF_NOCORPSE },
	
	OnCreate = function(self)
		self.energy = 0
	end,

	OnAction = function(self)
		self.speed_count = self.speed_count - 500
		if self.energy > 1 then
			if self.energy < 4 then 
				self.picture = 'o' 
				self.sprite = 59 
			elseif self.energy < 10 then 
				self.picture = 'O' 
				self.sprite = 60
			end				
		end
		if self.energy == self.energy_max then self:die() end
		return true
	end,
}

register_being "scavenger"
{
	name    = 'scavenger',
	picture = 's',
	color   = BROWN,     
	sprite  = 61,
	st      = 12, 
	dx      = 14,
    hp      = 25,
	speed   = 110,
	flags   = { BF_CONSUMABLE },

	OnAction = BeingSkills.Scavenge
}


register_being "treespirit"
{
	name    = 'treespirit',
	picture = '*',
	color   = YELLOW,
    sprite  = 63,
	st      = 8,
	dx      = 14,
	wp      = 15,
	hp      = 20,
	speed   = 90,
	armor   = 2,
	weight  = 8, 
	flags   = { BF_SPORERES, BF_FLAMABLE, BF_REGEN },
	
	OnAction = function(self, vis, dist)
		if not BeingSkills.Animate(self,vis,dist) then return true end
		if not BeingSkills.Blink(self,vis,dist) then return true end
		return false
	end,
}

register_being "treant"
{
	name    = 'treant',
	picture = 'T',
	color   = LIGHTGREEN,
	sprite  = 62,
	st      = 20,
	hp      = 70,
	speed   = 40,
	armor   = 2,
	weight  = 20,
	flags   = { BF_SPORERES, BF_FLAMABLE, BF_SKELETAL, BF_NOCORPSE },
}

register_being "townsman"
{
	name 	= 'townsman',
	namep   = 'townsmen',
	picture = '@',
	color   = BROWN,
	sprite  = 65,
	speed   = 90,
	ai      = AI_CIVILIAN,
}

register_being "ice_devil"
{
	name    = 'ice devil',
	picture = 'i',
	color   = LIGHTCYAN,
	sprite  = 70,
	dx      = 9,
	wp      = 11,
	speed   = 90,
	weight  = 8,
	flags   = { BF_CONSUMABLE, BF_FLAMABLE },
	
	OnAction = BeingSkills.RangedIce,
}

register_being "yeti"
{
	name    = 'yeti',
	picture = 'Y',
	color   = BLUE,
	sprite  = 68,
	st      = 22,
	hp      = 80,
	speed   = 80,
	armor   = 2,
	weight  = 14,
	flags   = { BF_FLAMABLE },
		
	OnCreate = function(self)
		ui.msg('You hear a howl!')
	end,
	
	OnAction = BeingSkills.Consume,
}

register_being "blizzard"
{
	name    = 'blizzard',  
	picture = '#',
	color   = LIGHTBLUE,
	sprite  = 66,
	hp      = 160,
	speed   = 80,
	armor   = 2,
	weight  = 5,
	flags   = { BF_FLAMABLE, BF_NOCORPSE, BF_SPORERES },
	
	OnCreate = function( self )
		ui.msg('A gust of cold wind approaches!')
	end,
	
	OnAction = function( self, _, dist )
		if dist < 10 and self.hp > 40 and math.random(3) == 1 then
			local clone = level:summon( self.id, self.position )
			if clone then
				self.hp = math.floor(self.hp / 2)
				clone.hp = self.hp
				self.speed_count = self.speed_count - 2000
			end
		end
		
		if dist == 1 then
			local target = self.target
			if self.energy > 5 then
				if target.id == "yourself" then ui.msg('The blizzard freezes you!') end
				target:apply_damage( 7, DAMAGE_FREEZE )
				self.energy = self.energy - 5
			end
			self.speed_count = self.speed_count - 2000
			return true
		end
		return false
	end,
}

