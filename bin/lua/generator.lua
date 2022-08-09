function generator.drunkard_walks( amount, steps, cell, ignore, break_on_edge, drunk_area )
	if amount <= 0 then return end
	drunk_area = drunk_area or area.FULL_SHRINKED
	for i=1,amount do
		generator.run_drunkard_walk( drunk_area, drunk_area:random_coord(), steps, cell, ignore, break_on_edge )
	end
end

function generator.scatter(fill,count,scatter_area)
	scatter_area = scatter_area or area.FULL
	if type(fill) == "string" then fill = cells[fill].nid end
	for c = 1, count do
		local c = scatter_area:random_coord()
		generator.set_cell( c, fill )
	end
end

function generator.place_city()
	local tries = 200
	local dim_max = coord.new( 10, 10 )
	local dim_min = coord.new( 6, 6 )
	local city = area.shrinked( area.FULL, 3 )

	local good_cell  = cells["grass"].nid
	local door_cell  = cells["open_door"].nid

	for i=1,tries do
		local room = area.random_subarea( city, coord.random( dim_min, dim_max ) )
		if generator.scan(room,good_cell,true) == 0 then
			local wall_cell  = cells["wooden_wall"].nid
			local floor_cell = cells["wooden_floor"].nid
			if math.random(3) == 1 then 
				wall_cell  = cells["stone_wall"].nid
				floor_cell = cells["floor"].nid
			end
			room:shrink(1)
			generator.fill( wall_cell, room )
			generator.set_cell( area.random_inner_edge_coord( room ), door_cell )
			room:shrink(1)
			generator.fill( floor_cell, room )
		end
	end
end

function generator.horiz_river( cell, width, bridge_cell )
	if bridge_cell then bridge_cell = cells[ bridge_cell ].nid end
	local y = math.ceil( MAP_MAXY / 2 ) + math.random(2*width) - width
	for x = 1,MAP_MAXX do
		local bridge = false
		for w = 1,width do
			local c = coord.new( x, w + y )
			local fill = cell
			if bridge_cell and generator.get_cell( c ) == bridge_cell then fill = "bridge" end
			generator.set_cell( c, fill )
		end
		if not bridge and math.random(4) == 1 then y = math.min( math.max( y + math.random(3) - 2, 3 ), MAP_MAXY - width - 2 ) end
	end
end

function generator.vert_river( cell, width, bridge_cell )
	if bridge_cell then bridge_cell = cells[ bridge_cell ].nid end
	local x = math.ceil( MAP_MAXX / 2 ) + math.random(2*width) - width
	for y = 1,MAP_MAXY do
		local bridge = false
		for w = 1,width do
			local c = coord.new( x + w, y )
			local fill = cell
			if bridge_cell and generator.get_cell( c ) == bridge_cell then fill = "bridge" end
			generator.set_cell( c, fill )
		end
		if not bridge and math.random(4) == 1 then x = math.min( math.max( x + math.random(3) - 2, 3 ), MAP_MAXX - width - 2 ) end
	end
end

function generator.random_road()
	local roll = math.random(5)
	local mat = "mud"
	if math.random(4) == 1 then mat = "floor" end
	    if roll == 1 then generator.horiz_river( mat, 2 )
	elseif roll == 2 then generator.horiz_river( mat, 3 )
	elseif roll == 3 then generator.vert_river( mat, 2 )
						generator.horiz_river( mat, 2 )
	elseif roll == 4 then generator.vert_river( mat, 3 )
	elseif roll == 5 then generator.vert_river( mat, 2 )
	end
end

function generator.random_river( mat )
	local roll = math.random(4)
	    if roll == 1 then generator.horiz_river( mat, 2 )
	elseif roll == 2 then generator.horiz_river( mat, 3 )
	elseif roll == 3 then generator.vert_river( mat, 3 )
	elseif roll == 4 then generator.vert_river( mat, 2 )
	end
end

function generator.random_river_road( water_cell )
	local roll = math.random(6)
	if roll <  3 then generator.random_road() end
	if roll == 3 then generator.random_river( water_cell ) end
	if roll >  3 then
		if math.random(2) == 1 then
			generator.vert_river( water_cell, math.random(3)+1 )
			generator.horiz_river( "mud", math.random(2)+1, water_cell )
		else
			generator.horiz_river( water_cell, math.random(3)+1 )
			generator.vert_river( "mud", math.random(2)+1, water_cell )
		end
	end
	
end

function generator.generate_fields()
	generator.fill( "grass" )
	local roll = math.random(5)
	if roll < 4 then
		generator.drunkard_walks( 20, 10, "mud" )
		generator.scatter( "floor", 50 )
		generator.scatter( "stones", 50 )
	elseif roll == 4 then
		generator.fill( "mud" )
		generator.drunkard_walks( 10, 10, "floor" )
		generator.drunkard_walks( 10, 10, "stones" )
		generator.scatter( "floor", 30 )
		generator.scatter( "stones", 30 )
	elseif roll == 5 then
		generator.drunkard_walks( 30, 10, "stones" )
		generator.scatter( "stones", 30 )
	end
	if math.random(6) > 1 then generator.random_river_road( "shallow_water" ) end
end

function generator.generate_forest()
	generator.spawns.medium = "scavenger"
	generator.spawns.spec1  = function()
		if math.random(4) == 1 then 
			generator.standard_spawns.spec1() 
		else
			level:spawn_on_edge( "treespirit" )
		end
	end
	generator.fill( "grass" )
	generator.scatter( "stones", 20 )
	local roll = math.random(10)
	local count = 120
	if roll > 8 then count = 200 end
	if roll > 9 then count = 360 end
	generator.scatter( "tree", count )
	generator.drunkard_walks( 20, 10, "mud" )
	if math.random(6) > 1 then generator.random_river_road( "shallow_water" ) end
end

function generator.generate_snow()
	level.sprite_base = 145
	generator.spawns.ranged = "ice_devil"
	generator.spawns.strong = "yeti"
	generator.spawns.spec2  = "blizzard"
	generator.fill( "snow" )
	local roll = math.random(5)
	if roll < 3 then
		generator.drunkard_walks( 10, 10, "mud" )
		generator.drunkard_walks( 10, 10, "ice" )
		generator.scatter( "stones", 50 )
	elseif roll < 5 then
		generator.drunkard_walks( 10, 10, "mud" )
		generator.drunkard_walks( 10, 10, "ice" )
		generator.drunkard_walks( 5, 5, "icy_water" )
		generator.scatter( "stones", 30 )
	elseif roll == 5 then
		generator.drunkard_walks( 30, 10, "stones" )
		generator.drunkard_walks( 10, 10, "ice" )
		generator.drunkard_walks( 5, 25, "icy_water" )
	end

	if math.random(6) > 1 then generator.random_river_road( "icy_water" ) end
end

function generator.generate_town()
	generator.fill( "grass" )
	generator.random_road()
	generator.place_city()
end

generator.standard_spawns =
{
	weak   = "beast",
	fast   = "phasehound",
	medium = "bulldemon",
	strong = "mandagore",
	ranged = "imp",
	spec1  = function()
		level:spawn_on_edge( "skeleton", math.random(2,8) )
		level:spawn_on_edge( "wraith" )
	end,
	spec2  = "defiler",
}

function generator.run()
	local arena = level.arena
	generator.spawns = table.copy( generator.standard_spawns )
	level.sprite_base = 129
		if arena == ARENA_FIELDS then generator.generate_fields()
	elseif arena == ARENA_FOREST then generator.generate_forest()
	elseif arena == ARENA_TOWN   then generator.generate_town()
	elseif arena == ARENA_SNOW   then generator.generate_snow()
	end
end

function generator.start()
	if level.arena == ARENA_TOWN then
		level:spawn_on_map( "townsman", 10 )
	end
	level:spawn_on_edge( "beast", 4 )
end

function generator.random_spawn( stype )
	local result = generator.spawns[ stype ]
	if type(result) == "string" then
		level:spawn_on_edge( result )
	else
		result()
	end
end

function generator.tick()
	local spec_chance = 0
	local night       = player.night
	local mode        = level.mode
	local spawn_level = level.spawn_level
	local tick_count  = level.tick_count

	if mode == MODE_ENDLESS then
		if level.flags[ LF_NOSPAWN ] then
			local monsters_left = 0
			for b in level:children() do
				if b.ai == AI_MONSTER then
					monsters_left = monsters_left + 1
				end
			end

			if monsters_left == 0 then
				level.flags[ LF_CLEARED ] = true
				ui.msg( "That must be all of them..." )
				ui.msg( "...for tonight that is..." )
				ui.msg( "Press <@<Enter@>>..." )
				ui.enter()
			end
			return
		end

		if tick_count >= NIGHTDURATION then
			local demon = level:spawn_on_edge( "demon", 1, night * 2 )
			ui.msg( demon.name.." has appeared!")
			ui.msg( "Now kill all of them!" )
			level.flags[ LF_NOSPAWN ] = true
			return
		end

		spec_chance = math.min( 20, (night-1)*5 + spawn_level*2+1 )
	end

	if mode == MODE_MASSACRE then
		spec_chance = math.min( 20, spawn_level*3 )
	end

	if tick_count % 10 == 0 then
		if tick_count > spawn_level * spawn_level * 100 then
			spawn_level = spawn_level + 1
			level.spawn_level = spawn_level
		end

		if math.random(100) <= 13 + spawn_level*2 + night*2 then
			local roll = math.random(100) + spawn_level + night*2
			if mode == MODE_MASSACRE and roll == 100 then
				local demon = level:spawn_on_edge( "demon", 1, spawn_level + 2 )
				ui.msg( demon.name.." has appeared!")
				return 
			end
			local stype = "weak"
			if roll > 75 then 
					if roll < 86  then stype = "ranged"
				elseif roll < 100 then stype = "medium"
				else
					roll = math.random( spec_chance )
						if roll < 11 then stype = "strong"
					elseif roll < 18 then stype = "fast"
					elseif roll < 20 then stype = "spec1"
					else stype = spec2 end
				end
			end
			generator.random_spawn( stype )
		end
	end
end
