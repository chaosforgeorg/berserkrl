core.register_blueprint "skill"
{
	id          = { true,  core.TSTRING },
	name        = { true,  core.TSTRING },
	type        = { true,  core.TNUMBER },
	name_short  = { false, core.TSTRING },
	name_use    = { false, core.TSTRING },
	name_altuse = { false, core.TSTRING },
	description = { false, core.TSTRING, ''},
	picture     = { false, core.TSTRING, ''},
	max_level   = { false, core.TNUMBER, 1 },
	reqs        = { false, core.TTABLE, {} },
	pickable    = { false, core.TBOOL, true },
	ammo_slot   = { false, core.TNUMBER, 0 },
	quiver_slot = { false, core.TNUMBER, 0 },
	ammo_max    = { false, core.TNUMBER, 0 },
	quiver_max  = { false, core.TNUMBER, 0 },

	OnPick      = { false, core.TFUNC },
	OnUse       = { false, core.TFUNC },
	OnAltUse    = { false, core.TFUNC },
}

core.declare( "register_skill", core.register_storage( "skills", "skill", 
	function ( s )
		s.name_short  = s.name_short or s.name
		s.name_use    = s.name_use or s.name
		s.name_altuse = s.name_altuse or s.name
	end
))

register_skill "crossbow"
{
	name        = "Crossbow",
	name_use    = "Fire Crossbow",
	name_altuse = "Reload Crossbow",
	pickable    = false,
	type        = SKILL_ITEM,
	ammo_slot   = 1,
	ammo_max    = 12,
	quiver_slot = 2,
	quiver_max  = 60,

	OnUse       = function( p, level, command ) 
		local ammo_slot = skills.crossbow.ammo_slot
		local ammo      = p:get_ammo( ammo_slot )

		if ammo == 0 then 
			ui.msg( "Magazine empty, reload!" ) 
			return false 
		end

		if p.enemies_around > 0 then
			ui.msg( "You can't fire in combat!" ) 
			return false 
		end

		ui.msg( "Choose target, @<"..ui.get_keybinding( command ).."@> to fire:" )

		if not p:choose_target( TM_FIRE, command ) then return false end
		local target = p.tposition
		if target == p.position then 
			ui.msg( "Suicide? Too easy... ")
			return false
		end

		p:play_sound("crossbow","fire")
		p:set_ammo( ammo_slot, ammo - 3 )
		p:send_missile( target, MTBOLT, 0 )
		p:send_missile( target, MTBOLT, 100 )
		p:send_missile( target, MTBOLT, 200 )
		p.speed_count = p.speed_count - 1000
		return true 
	end,

	OnAltUse    = function( p, level, command ) 
		local ammo_slot   = skills.crossbow.ammo_slot
		local ammo        = p:get_ammo( ammo_slot )
		local quiver_slot = skills.crossbow.quiver_slot
		local quiver      = p:get_ammo( quiver_slot )
		local ammo_max    = skills.crossbow.ammo_max

		if p.flags[ BF_BERSERK ] then
			ui.msg( "No time, need to KILL!" ) 
			return false
		end
		if ammo >= ammo_max then
			ui.msg( "Magazine already full!" ) 
			return false
		end
		if quiver == 0 then
			ui.msg( "You have no more bolts!" ) 
			return false
		end
		if p.enemies_around > 0 then
			ui.msg( "Cannot reload in combat!" ) 
			return false
		end

		p:play_sound("crossbow","reload")
		ui.msg( "You reload the crossbow.")
		local amount = math.min( math.min( ammo_max, quiver ), ammo_max - ammo ) 
		p:set_ammo( ammo_slot,   ammo   + amount )
		p:set_ammo( quiver_slot, quiver - amount )
		p.speed_count = p.speed_count - 2000
		return true 
	end,

}

register_skill "cannon"
{
	name        = "Cannon",
	name_use    = "Fire Cannon",
	name_altuse = "Reload Cannon",
	pickable    = false,
	type        = SKILL_ITEM,
	ammo_slot   = 3,
	ammo_max    = 1,
	quiver_slot = 4,
	quiver_max  = 3,

	OnUse       = function( p, level, command ) 
		local ammo_slot = skills.cannon.ammo_slot
		local ammo      = p:get_ammo( ammo_slot )

		if ammo == 0 then 
			ui.msg( "Cannon empty, reload!" ) 
			return false 
		end
		ui.msg( "Cannon: Choose direction...")
		local d = ui.choose_dir()
		ui.msg_kill()
		if not d then return false end

		p:play_sound("cannon","fire")
		p:set_ammo( ammo_slot, ammo - 1 )
		ui.blink( RED, 200, 0)
		ui.blink( YELLOW, 50, 300)
		p:breath( d, RED, 18, 9, 30 )
		p:knockback( d, 20, false )		
		p.speed_count = p.speed_count - 1000
		return true 
	end,

	OnAltUse    = function( p, level, command ) 
		local ammo_slot   = skills.cannon.ammo_slot
		local ammo        = p:get_ammo( ammo_slot )
		local quiver_slot = skills.cannon.quiver_slot
		local quiver      = p:get_ammo( quiver_slot )

		if p.flags[ BF_BERSERK ] then
			ui.msg( "No time, need to KILL!" ) 
			return false
		end
		if ammo == skills.cannon.ammo_max then
			ui.msg( "Cannon already loaded!" ) 
			return false
		end
		if quiver == 0 then
			ui.msg( "You have no more charges!" ) 
			return false
		end
		if p.enemies_around > 0 then
			ui.msg( "Cannot reload in combat!" ) 
			return false
		end

		p:play_sound("cannon","reload")
		ui.msg( "You reload the cannon.")
		p:set_ammo( ammo_slot,   ammo   + 1 )
		p:set_ammo( quiver_slot, quiver - 1 )
		p.speed_count = p.speed_count - 3000
		return true 
	end,

}

register_skill "knives"
{
	name        = "Knives",
	name_use    = "Throw Knife",
	pickable    = false,
	type        = SKILL_ITEM,
	ammo_slot   = 5,
	ammo_max    = 10,

	OnUse       = function( p, level, command ) 
		local ammo_slot = skills.knives.ammo_slot
		local ammo      = p:get_ammo( ammo_slot )

		if ammo == 0 then 
			ui.msg( "You have no more knives!" ) 
			return false 
		end

		ui.msg( "Choose target, @<"..ui.get_keybinding( command ).."@> to throw:" )

		if not p:choose_target( TM_FIRE, command ) then return false end
		local target = p.tposition
		if target == p.position then 
			ui.msg( "Suicide? Too easy... ")
			return false
		end

		p:play_sound("knives","throw")
		p:set_ammo( ammo_slot, ammo - 1 )
		p:send_missile( target, MTKNIFE )
		p.speed_count = p.speed_count - 1000
		return true 
	end,
}


register_skill "bombs"
{
	name        = "Bombs",
	name_use    = "Throw Bomb",
	pickable    = false,
	type        = SKILL_ITEM,
	ammo_slot   = 6,
	ammo_max    = 5,

	OnUse       = function( p, level, command ) 
		local ammo_slot = skills.bombs.ammo_slot
		local ammo      = p:get_ammo( ammo_slot )

		if ammo == 0 then 
			ui.msg( "You have no more bombs!" ) 
			return false 
		end

		ui.msg( "Choose target, @<"..ui.get_keybinding( command ).."@> to throw:" )

		if not p:choose_target( TM_THROW, command ) then return false end
		local target = p.tposition
		if target == p.position then 
			ui.msg( "Suicide? Too easy... ")
			return false
		end
		if target:distance( p.position ) > 7 then
			ui.msg( "That's too far!") 
			return false
		end

		p:play_sound("bombs","throw")
		p:set_ammo( ammo_slot, ammo - 1 )
		p:send_missile( target, MTBOMB )
		p.speed_count = p.speed_count - 1000
		return true 
	end,
}

register_skill "fairydust"
{
	name        = "Fairydust",
	name_use    = "Use Fairydust",
	pickable    = false,
	type        = SKILL_ITEM,
	ammo_slot   = 7,
	ammo_max    = 5,

	OnUse       = function( p, level ) 
		local ammo_slot = skills.fairydust.ammo_slot
		local ammo      = p:get_ammo( ammo_slot )

		if ammo == 0 then 
			ui.msg( "You have no more fairydust!" ) 
			return false 
		end
		p:set_ammo( ammo_slot, ammo - 1 )

		if p.hp == p.hp_max then 
			ui.msg( "Nothing happens." ) 
		else
			ui.msg( "You feel a lot better!" )
			ui.blink( LIGHTGREEN, 100 )
		end
		
		p:play_sound("fairydust","use")
		p.hp     = p.hp_max
		p.energy = p.energy_max
		p.pain   = 0
		p.freeze = 0
		if p.flags[ BF_BERSERK ] then
			ui.msg( "You calm down." )
			audio.play_music("passive")
			p.flags[ BF_BERSERK ] = false
			p.health_mark = 0
		end
		p.speed_count = p.speed_count - 1000
		return true 
	end,
}

register_skill "ironman"
{
	name        = 'Ironman',
	type        = SKILL_PASSIVE,
	description = 'Each level of this skill makes you tougher, by giving you an additional 5 hitpoints.',
	max_level   = 100,
	picture     = '@g.....\n@g..@d@@@g..\n@g.....',

	OnPick      = function( p )
		p.hp_bonus = p.hp_bonus + 5
	end,
}

register_skill "running"
{
	name        = 'Running',
	type        = SKILL_PASSIVE,
	description = 'This skill greatly improves the benefits of Running mode. Each successive level increases speed, and reduces energy drain.',
	max_level   = 3,
	picture     = '@g.....\n@g..@d@@@g..\n@g.....',
	reqs        = { en = 12 },

	OnPick      = function( p, level )
		if level == 1 then
			p.run_bonus = p.run_bonus + 2
		else
			p.run_bonus = p.run_bonus + 1
		end
	end,
}

register_skill "survival"
{
	name        = 'Survival',
	type        = SKILL_PASSIVE,
	description = 'If reduced to 10% hitpoints you gain a impressive will to survive. For each level your defense is increased by 1 and armor by 2.',
	max_level   = 3,
	picture     = '@g.....\n@g..@d@@@g..\n@g.....',
	reqs        = { wp = 12 },

	OnPick      = function( p, level )
		p.survive_bonus = p.survive_bonus + 1
	end,
}

register_skill "sweep"
{
	name        = 'Sweep attack',
	name_short  = 'Sweep',
	type        = SKILL_ACTIVE,
	description = 'This skill allows you to attack three enemies at once, as long as they stand side by side and beside you. The attack is less effective than a normal one though. Each level reduces the time needed and energy cost.',
	max_level   = 3,
	picture     = '@g.@B*@g...\n@g.@B*@g@d@@@g..\n@g.@B*@g...',
	reqs        = { st = 12 },

	OnUse       = function( p, level )
		local cost = 25-5*level
		if p.energy < cost then 
			ui.msg("You're to exhausted do that!")
			return false
		end
		ui.msg("Sweep: Choose direction...")
		local d = ui.choose_dir()
		ui.msg_kill()
		if not d then return false end
		p.energy = p.energy - cost
		local tgt = { 0, p.position + d, 0 }
		if d.x * d.y ~= 0 then
			tgt[1] = p.position + coord.new( 0, d.y )
			tgt[3] = p.position + coord.new( d.x, 0 )
		else
			if d.x == 0 then 
				tgt[1] = p.position + coord.new( 1,  d.y )
				tgt[3] = p.position + coord.new( -1, d.y )
			else
				tgt[1] = p.position + coord.new( d.x, 1 )
				tgt[3] = p.position + coord.new( d.x, -1 )
			end
		end
		for _,c in ipairs( tgt ) do
			p:attack( c , { AF_SWEEP } )
		end
		p.speed_count = p.speed_count - ( 1600 - level*200 )
		return true
	end,
}

register_skill "whirlwind"
{
	name        = 'Whirlwind attack',
	name_short  = 'Whirlwind',
	type        = SKILL_ACTIVE,
	description = 'This skill allows you to attack ALL surrounding enemies at once! The attack is a less effective than the normal attack though. Each level reduces the time needed and energy cost.',
	max_level   = 3,
	picture     = '@g.@B***@g.\n@g.@B*@d@@@B*@g.\n@g.@B***@g.',
	reqs        = { st = 16, sweep = 2 },

	OnUse       = function( p, level )
		local cost = 60-10*level
		if p.energy < cost then 
			ui.msg("You're to exhausted do that!")
			return false
		end
		p.energy = p.energy - cost
		for c in p.position:around_coords() do
			p:attack( c , { AF_SWEEP } )
		end
		p.speed_count = p.speed_count - ( 2250 - level*250 )
		return true
	end,

}

register_skill "impale"
{
	name        = 'Impale attack',
	name_short  = 'Impale',
	type        = SKILL_ACTIVE,
	description = 'This skill makes you dash one step and attack in the given direction immediately with greater strength. It works only if there is exactly one free space between you and the enemy. Each level decreases energy and time cost.',
	max_level   = 3,
	picture     = '@g.....\n@B*@@@d@@@g..\n@g.....',
	reqs        = { st = 14, running = 1 },

	OnUse       = function( p, level )
		local cost = 50-10*level
		if p.energy < cost then 
			ui.msg("You're to exhausted do that!")
			return false
		end
		ui.msg('Impale: Choose direction...');
		local d = ui.choose_dir()
		ui.msg_kill()
		if not d then return false end
		local move = p.position + d
		if p:try_move( move ) ~= MOVE_OK then
			ui.msg("No space to do a Impale attack!")
			return false
		end
		p.energy = p.energy - cost
		p:displace( move )
		p.def_bonus = math.max( 1, p.def_bonus )
		p:attack( move + d , { AF_IMPALE } )
		p.speed_count = p.speed_count - ( 1600 - level*200 )
		return true
	end,

}

register_skill "jump"
{
	name        = 'Jump attack',
	name_short  = 'Jump',
	type        = SKILL_ACTIVE,
	description = "This skill allows you to jump two squares away using the sword as a jump pole. If there's a monster under you during the jump, he'll get impaled!",
	max_level   = 3,
	picture     = '@g.....\n@B@@*@d@@@g..\n@g.....',
	reqs        = { dx = 11, running = 1, impale = 1 },

	OnUse       = function( p, level )
		local cost = 50-10*level
		if p.energy < cost then 
			ui.msg("You're to exhausted do that!")
			return false
		end
		ui.msg('Jump: Choose direction...');
		local d = ui.choose_dir()
		ui.msg_kill()
		if not d then return false end
		local move = p.position + d
		local mr   = p:try_move( move )
		if (mr ~= MOVE_OK and mr ~= MOVE_BEING) or p:try_move( move + d ) ~= MOVE_OK then
			ui.msg("No space to do a Jump attack!")
			return false
		end
		p.energy = p.energy - cost
		p:attack( move , { AF_NOKNOCKBACK } )
		p:displace( move + d )
		p.def_bonus   = math.max( 1, p.def_bonus )
		p.speed_count = p.speed_count - ( 1600 - level*200 )
		return true
	end,
}
