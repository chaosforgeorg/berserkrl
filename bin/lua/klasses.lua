core.register_blueprint "klass"
{
	id           = { true,  core.TSTRING },
	name         = { true,  core.TSTRING },
	default_name = { true,  core.TSTRING },

	OnCreate     = { true, core.TFUNC },
	OnQuick      = { true, core.TFUNC },
	OnAdvance    = { true, core.TFUNC },
	OnTick       = { true, core.TFUNC },
}

core.declare( "register_klass", core.register_storage( "klasses", "klass" ) )

register_klass "berserker"
{
	name         = "Berserker",
	default_name = "Guts",

	OnCreate     = function( p, mode )
		p:inc_skill( "crossbow" )
		p:inc_skill( "cannon" )
		p:inc_skill( "knives" )
		p:inc_skill( "bombs" )
		p:inc_skill( "fairydust" )

		p.armor = 2

		local modes = {
			[MODE_MASSACRE] = 
			{
				crossbow  = { 12, 60 },
				cannon    = { 1, 2 },
				knives    = { 10 },
				bombs     = { 3 },
				fairydust = { 3 },
			},
			[MODE_ENDLESS] = 
			{
				crossbow  = { 12, 36 },
				cannon    = { 1, 1 },
				knives    = { 5 },
				bombs     = { 2 },
				fairydust = { 2 },
			}
		}
		local inv = modes[ mode ]
		for id,v in pairs( inv ) do
			local s = skills[id]
			p:set_ammo( s.ammo_slot, v[1] )
			if v[2] then 
				p:set_ammo( s.quiver_slot, v[2] )
			end
		end
	end,

	OnQuick      = function( p, mode )
		p.st = 16
		p.dx = 14
		p.en = 10
		p.wp = 10
		if mode == MODE_MASSACRE then
			p:inc_skill( "sweep" )
			p:inc_skill( "sweep" )
			p:inc_skill( "whirlwind" )
		else
			p:inc_skill( "sweep" )
		end
	end,

	OnAdvance    = function( p )
		-- free healing if Fairydust was max
		if p:get_ammo( skills.fairydust.ammo_slot ) == skills.fairydust.ammo_max then p.hp = p.hp_max end

		p:add_ammo( "crossbow", 36, true )
		p:add_ammo( "cannon", 1, true )
		p:add_ammo( "knives", 3 )
		p:add_ammo( "bombs", 2 )
		p:add_ammo( "fairydust", 1 )
	end,

	OnTick      = function( p )
		local is_berserk = p.flags[ BF_BERSERK ]
		local enemies    = p.enemies_around
		local hmark      = p.health_mark
		local hp_max     = p.hp_max
		local hp         = p.hp

		if is_berserk then
			if kills.this_turn == 0 then
				p.health_mark = math.min( hmark + 1, hp_max )
				if p.health_mark == hp_max and hp > p.wp then 
					ui.msg( "You calm down." )
					if audio then
						audio.play_music("passive")
					end
					p.flags[ BF_BERSERK ] = false
					p.health_mark = 0
				end
			end
		else
			if hmark < hp_max / 2 and ((kills.this_turn > 0 and enemies > 0) or p.turn_count % math.max( 1, 25 - p.wp) == 0) then
				p.health_mark = hmark + 1
			end
			if p.health_mark > hp then
				if audio then
					audio.play_music("berserk")
				end
				ui.blink( RED, 150, 0 )
				ui.blink( RED, 200, 300 )
				ui.msg( "You go BERSERK!" )
				p.flags[ BF_BERSERK ] = true
			end
		end

		if p.flags[ BF_BERSERK ] then
			p.pain      = 0
			p.freeze    = 0
			p.def_bonus = math.floor( enemies / 2 )
		end
	end,

}