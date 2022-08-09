core.register_blueprint "cell"
{
	id         = { true, core.TSTRING },
	picture    = { true, core.TSTRING },
	name       = { true, core.TSTRING },
	color      = { true, core.TNUMBER },
	dpicture   = { false, core.TSTRING, ' ' },
	dcolor     = { false, core.TNUMBER, DARKGRAY },
	dr         = { false, core.TNUMBER, 0 },
	blood_id   = { false, core.TSTRING, "" },
	destroy_id = { false, core.TSTRING, "" },
	act_id     = { false, core.TSTRING, "" },
	edgeset    = { false, core.TNUMBER, 0 },
	sprite     = { false, core.TNUMBER, 0 },
	spriteb    = { false, core.TNUMBER, 0 },
	move_cost  = { false, core.TNUMBER, 100 },
	flags      = { false, core.TFLAGS, {} },
	is_tree    = { false, core.TBOOL, false },

	OnAct      = { false, core.TFUNC },
	OnDestroy  = { false, core.TFUNC },
	OnStanding = { false, core.TFUNC },
}

core.declare( "register_cell", core.register_storage( "cells", "cell" ) )

register_cell "grass"
{
	name       = 'grass',
	picture    = '.',
	color      = GREEN,
	blood_id   = 'blood',
	spriteb    = 129,
	move_cost  = 105,
}

register_cell "stone_wall"
{
	name       = 'stone wall',
	picture    = '#',
	color      = LIGHTGRAY,
	dpicture   = '.',
	dr         = 40,
	blood_id   = 'bloody_stone_wall',
	destroy_id = 'floor',
	spriteb    = 4,
	flags      = { TF_NOMOVE, TF_NOSIGHT, SF_TALLBASE },
}

register_cell "bloody_stone_wall"
{
	name       = 'bloody stone wall',
	picture    = '#',
	color      = RED,
	dpicture   = '.',
	dr         = 40,
	destroy_id = 'blood',
	spriteb    = 4,
	sprite     = 9,
	flags      = { TF_NOMOVE, TF_NOSIGHT, SF_TALLBASE },
}

register_cell "blood"
{
	name       = 'blood',
	picture    = '.',
	color      = RED,
	blood_id   = 'pool_of_blood',
	sprite     = 13, 
	move_cost  = 105, 
}

register_cell "pool_of_blood"
{
	name       = 'pool of blood',
	picture    = ':',
	color      = RED,
	sprite     = 14, 
	move_cost  = 105, 
}

register_cell "bloody_corpse"
{
	name       = 'bloody corpse',
	picture    = '%',
	color      = RED,
	sprite     = 15, 
	move_cost  = 110, 
	flags      = { TF_HIGHLIGHT },
}

register_cell "closed_door"
{
	name       = 'closed door',
	picture    = '+',
	color      = BROWN,
	act_id     = 'open_door', 
	spriteb    = 21, 
	sprite     = 7, 
}

register_cell "open_door"
{
	name       = 'open door',
	picture    = '/',
	color      = BROWN,
	dr         = 20, 
	destroy_id = 'floor', 
	act_id     = 'closed_door', 
	spriteb    = 21, 
	sprite     = 8, 
	move_cost  = 110, 
}

register_cell "floor"
{
	name       = 'floor',
	picture    = '.',
	color      = LIGHTGRAY,
	blood_id   = 'blood', 
	spriteb    = 21, 
	move_cost  = 90, 
	edgeset    = 1,
	flags      = { TF_EDGES },
}

register_cell "wooden_floor"
{
	name       = 'wooden floor',
	picture    = '.',
	color      = LIGHTGRAY,
	blood_id   = 'blood', 
	spriteb    = 22, 
	move_cost  = 90, 
}

register_cell "mud"
{
	name       = 'mud',
	picture    = '.',
	color      = BROWN,
	blood_id   = 'blood', 
	sprite     = 12, 
}

register_cell "wooden_wall"
{
	name       = 'wooden wall',
	picture    = '#',
	color      = BROWN,
	dpicture   = '#',
	dr         = 30, 
	blood_id   = 'bloody_wooden_wall',
	destroy_id = 'floor', 
	spriteb    = 6, 
	flags      = { TF_NOMOVE, TF_NOSIGHT, SF_TALLBASE },
}

register_cell "bloody_wooden_wall"
{
	name       = 'bloody wooden wall',
	picture    = '#',
	color      = RED,
	dpicture   = '#',
	dr         = 30, 
	destroy_id = 'blood', 
	spriteb    = 6, 
	sprite     = 9, 
	flags      = { TF_NOMOVE, TF_NOSIGHT, SF_TALLBASE },
}

register_cell "tree"
{
	name       = 'tree',
	picture    = 'T',
	color      = GREEN,
	dpicture   = '.',
	dr         = 20, 
	blood_id   = 'bloody_tree',
	destroy_id = 'mud', 
	spriteb    = 3, 
	sprite     = 23, 
	is_tree    = true,
	flags      = { TF_NOMOVE, TF_NOSIGHT },
}

register_cell "bloody_tree"
{
	name       = 'bloody tree',
	picture    = 'T',
	color      = RED,
	dpicture   = '.',
	dr         = 20, 
	destroy_id = 'blood', 
	spriteb    = 3, 
	sprite     = 24, 
	is_tree    = true,
	flags      = { TF_NOMOVE, TF_NOSIGHT },
}

register_cell "stones"
{
	name       = 'stones',
	picture    = '#',
	color      = LIGHTGRAY,
	dpicture   = '.',
	dr         = 40, 
	blood_id   = 'bloody_stones',
	destroy_id = 'mud', 
	sprite     = 10, 
	flags      = { TF_NOMOVE, TF_NOSIGHT },
}

register_cell "bloody_stones"
{
	name       = 'bloody stones',
	picture    = '#',
	color      = RED,
	dpicture   = '.',
	dr         = 40, 
	destroy_id = 'blood', 
	sprite     = 11, 
	flags      = { TF_NOMOVE, TF_NOSIGHT },
}

register_cell "shallow_water"
{
	name       = 'shallow water',
	picture    = '=',
	color      = LIGHTBLUE,
	dpicture   = '=',
	spriteb    = 25, 
	move_cost  = 200, 
	edgeset    = 1,
	flags      = { TF_WATER, TF_NOCORPSE, TF_EDGES, TF_NOMIRROR },

}

register_cell "deep_water"
{
	name       = 'deep water',
	picture    = '=',
	color      = BLUE,
	dpicture   = '=',
	spriteb    = 27, 
	edgeset    = 1,
	flags      = { TF_NOMOVE, TF_WATER, TF_NOCORPSE, TF_EDGES, TF_NOMIRROR },
}

register_cell "bridge"
{
	name       = 'bridge',
	picture    = '-',
	color      = BROWN,
	dpicture   = '-',
	blood_id   = 'bloody_bridge',
	spriteb    = 22, 
	edgeset    = 1,
	flags      = { TF_EDGES },
}

register_cell "bloody_bridge"
{
	name       = 'bloody bridge',
	picture    = '-',
	color      = RED,
	dpicture   = '-',
	spriteb    = 22, 
	sprite     = 13, 
	edgeset    = 1,
	flags      = { TF_EDGES },
}

register_cell "snow"
{
	name       = 'snow',
	picture    = '.',
	color      = WHITE,
	blood_id   = 'blood', 
	spriteb    = 145, 
	move_cost  = 120, 
}

register_cell "ice"
{
	name       = 'ice',
	picture    = '-',
	color      = LIGHTCYAN,
	dpicture   = '.',
	spriteb    = 36, 
	move_cost  = 150, 
	edgeset    = 2,
	flags      = { TF_ICE, TF_EDGES, TF_NOMIRROR },
}

register_cell "icy_water"
{
	name       = 'icy water',
	picture    = '=',
	color      = LIGHTBLUE,
	dpicture   = '=',
	spriteb    = 41, 
	move_cost  =  200, 
	edgeset    = 1,
	flags      = { TF_WATER, TF_EDGES, TF_NOMIRROR },

	OnStanding = function( coord, being )
		being:apply_damage( 4, DAMAGE_FREEZE )
		ui.msg( "Freezing!" )
	end,

}
