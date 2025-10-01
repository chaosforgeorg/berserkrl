core.register_blueprint "ui_element"
{
	id          = { true, core.TSTRING },
	base        = { false, core.TSTRING },
	inherited   = { false, core.TSTRING },
	background  = { false, core.TSTRING },
	header      = { false, core.TSTRING },
	footer      = { false, core.TSTRING },

	on_create   = { false, core.TFUNC },
	on_redraw   = { false, core.TFUNC },
	on_render   = { false, core.TFUNC },
	on_key_down = { false, core.TFUNC },
}

register_ui "ui_screen"
{
	background = 'menuback',
	on_create  = function( self )
		self:add_property( "seed", math.random( 65000 ) )
	end,
	on_redraw  = function( self )
		ui.draw_fire( self.seed )
	end,
	on_render  = function( self )
		ui.render_bg()
	end,
	on_key_down = function( self, key )
		if key.code == io.KEY_ESCAPE or key.code == io.KEY_ENTER or key.code == io.KEY_SPACE then
			self:destroy()
			return true
		end
		return false
	end,
}

register_ui "ui_night_screen"
{
	inherited  = "ui_screen",
	on_create  = function( self )
		ui_elements.ui_screen.on_create( self )
		local night  = player.night
		local kills  = player.kills
		local quote  = quotes[math.random(#quotes)]
		local window = ui.new_window( self, rect.new( 9, 2, 61, 20 ) )

		ui.new_con_label( window, point.new( 21, 2 ), "@RBERSERK! Night "..night )
		ui.new_con_text( window, rect.new( 10, 4, 40, 6 ), quote.text.."\n".."@d                        -- @l"..quote.author)
		if night > 1 then ui.new_con_label( window, point.new( 17, 13 ), "@R"..kills.." kills and counting..." ) end
		ui.new_con_label( window, point.new( 15, 14 ), "@R[@yc@R]ontinue or [@ys@R]ave and exit" )
	end,
	on_key_down = function( self, key )
		if key.code == io.KEY_C then
			self:destroy()
			return true
		end
		if key.code == io.KEY_S then
			ui.save_game()
			self:destroy()
			return true
		end
		return false
	end,
}

register_ui "ui_skills_screen"
{
	inherited  = "ui_screen",
	on_create  = function( self )
		ui_elements.ui_screen.on_create( self )
		local window = ui.new_window( self, rect.new( 3, 1, 50, 21 ) )
		window.padding = point.new(1,0)

		ui.new_con_text( window, "Choose a skill you want to upgrade. Most skills offer some otherwise unattainable option in the game. Further levels increase that option's effectiveness." )

		local stat_names = { st = "Strength", dx = "Dexterity", en = "Endurance", wp = "Willpower" }

		local list = {}
		for i,v in ipairs( skills ) do
			if v.pickable then
				local name = v.name
				local lev  = player:get_skill( i )
				if lev > 0 then name = name.." ("..(lev+1)..")" end
				table.insert( list, { name, player:can_pick_skill(v.id), v.nid } )
			end
		end
		
		self:add_property( "desc", ui.new_con_text( window, rect.new( 0, 6, 46, 15 ), "" ) )
		self:add_property( "pic",  ui.new_con_text( window, rect.new( 36, 6, 10, 5 ), "" ) )

		window = ui.new_window( self, rect.new( 57, 1, 20, skills.__counter+2 ) )
		window.padding = point.new(1,0)

		local menu = ui.new_con_menu( window, point.new(1,1), list )

		menu.on_select = function( menu, selected, data )
			if data == 0 or data > skills.__counter then return false end
			local skill = skills[data]
			local desc= "Name      : @<"..skill.name.."@>\n"..
						"Max level : @<"..skill.max_level.."@>\n"..
						"Requires  : " 
			local lines = 1 

			for id,value in pairs(skill.reqs) do
				local rdesc = core.iif( player:req_met( id, value ), "@g", "@r" )
				if lines > 1 then rdesc = rdesc.."            " end
				if skills[id] then
					rdesc = rdesc..skills[id].name.." level "..value
				else
					rdesc = rdesc..stat_names[id].." "..value
				end
				desc = desc..rdesc.."@>\n"
				lines = lines + 1
			end
			if lines == 1 then desc = desc.."@gnothing@>\n" end
			self.desc.text = desc.."\n"..skill.description
			self.pic.text  = skill.picture 
			return true
		end

		menu.on_confirm = function( menu, selected, data )
			player:inc_skill( data )
			self:destroy()
			return true
		end

		menu.selected = 1
	end,
	on_key_down = function() return false end,
}

register_ui "ui_char_screen"
{
	inherited  = "ui_screen",
	on_create  = function( self )
		ui_elements.ui_screen.on_create( self )
		local game_type = { "Massacre", "Endless", "Campaign" }

		local padded = function( line, size, char )
			return line..string.rep( char, size - #line )
		end

		local window = ui.new_window( self, rect.new( 6, 2, 67, 21 ) )
		ui.new_con_label( window, point.new( 0, -1 ), padded( '-', 65, '-' ) )
		ui.new_con_text( window, rect.new( 2, 1, 35, 8 ),
			"Name      : @<"..player.name.."@>\n"..
			"Game type : @<"..game_type[player.mode].."@>\n"..
			"Strength : @<"..player.st.."@>  Dexterity: @<"..player.dx.."@>\n"..
			"Endurance: @<"..player.en.."@>  Willpower: @<"..player.wp.."@>\n"..
			"Weight   : @<"..player.weight.."@>  Speed    : @<"..player.speed.."@>\n"..
			"Base damage - @<"..player.dmg_dice.."@>d6+@<"..player.dmg_mod.."@>" )

		ui.new_con_label( window, point.new( 34, 1 ), "Monsters killed : @<"..kills.count )
		if player.mode ~= MODE_MASSACRE then
			ui.new_con_label( window, point.new( 34, 2 ), "Nights survived : @<"..(player.night-1) )
		end

		local ammo1 = ""
		local ammo2 = ""
		local odd   = true

		for i,s in ipairs( skills ) do
			if s.ammo_slot > 0 and player:get_skill( i ) > 0 then
				local str = padded( s.name, core.iif( odd, 10, 8 ), " " )..": @<"..player:get_ammo(s.ammo_slot).."@>"
				if s.quiver_slot > 0 then str = str.."/@<"..player:get_ammo(s.quiver_slot).."@>" end
				if odd then
					ammo1 = ammo1..str.."\n"
				else
					ammo2 = ammo2..str.."\n"
				end
				odd = not odd
			end
		end
		ui.new_con_text( window, rect.new( 34, 4, 18, 5 ), ammo1 )
		ui.new_con_text( window, rect.new( 52, 4, 18, 5 ), ammo2 )
		
		--[[
		ui.new_con_text( window, rect.new( 34, 4, 35, 5 ),
			"Crossbow  : @<"..player:get_ammo(3).."@>/@<"..player:get_ammo(4).."@>  Cannon : @<"..player:get_ammo(1).."@>/@<"..player:get_ammo(2).."@>\n"..
			"Knives    : @<"..player:get_ammo(5).."@>     Bombs  : @<"..player:get_ammo(6).."@>\n"..
			"Fairydust : @<"..player:get_ammo(7).."@>" )
		--]]

		local sk = padded("-- @<Skills@> ",34,"-").."\n\n";
		for i,s in ipairs( skills ) do
			if s.pickable then
				local l = player:get_skill( i )
				if l > 0 then sk = sk.."  "..s.name.." (level @<"..l.."@>)\n" end
			end
		end

		ui.new_con_text( window, rect.new( 0, 9, 35, 8 ), sk )
		ui.new_con_text( window, rect.new( 32, 9, 35, 8 ),
			padded("-- @<Achievements@> ",37,"-").."\n\n"..
			"  Kills in 1 turn   : @<"..kills.best_turn.."@>\n"..
			"  Killing sequence  : @<"..kills.best_sequence.."@>\n"..
			"  Sequence duration : @<"..kills.best_sequence_length.."t@>\n"..
			"  Kills w/o damage  : @<"..kills.best_no_damage_sequence.."@>\n"..
			"  Survived for      : @<"..player.turn_count.."t@>" )
		ui.new_con_label( window, point.new( 0, 19 ), padded("-- Press <@<Enter@>> to exit... ",69,"-") )
	end,
}


register_ui "ui_full_screen"
{
	base       = "ui_con_full_window",
	on_render  = function( self )
		ui.render_bg()
	end,
	on_key_down = function( self, key )
		if key.code == io.KEY_ESCAPE or key.code == io.KEY_ENTER or key.code == io.KEY_SPACE then
			self:destroy()
			return true
		end
		return false
	end,
}

register_ui "ui_mortem_screen"
{
	inherited  = "ui_full_screen",
	base       = "ui_con_full_window",
	background = 'menuback',
    header     = " @<Berserk!@> Post Mortem (mortem.txt)",
    footer     = " Use @<arrows@>, @<PgUp@>, @<PgDown@> to scroll, @<Escape@> or @<Enter@> to exit.",

	on_create  = function( self )
		local dimrect = self.pdimrect:shrinked(1,2)
		local absrect = self.absdim
		local content = ui.new_con_string_list( self, dimrect, ui.get_mortem_file() )
		ui.new_con_scrollable_icons( self, content, dimrect, point.new( absrect.x2 - 7, absrect.y ) )
	end,
}

register_ui "ui_message_screen"
{
	inherited  = "ui_full_screen",
	base       = "ui_con_full_window",
	background = 'menuback',
    header     = " @<Berserk!@> Previous messages",
    footer     = " Use @<arrows@>, @<PgUp@>, @<PgDown@> to scroll, @<Escape@> or @<Enter@> to exit.",

	on_create  = function( self )
		local dimrect = self.pdimrect:shrinked(1,2)
		local absrect = self.absdim
		local content = ui.get_message_buffer( self, dimrect )
		ui.new_con_scrollable_icons( self, content, dimrect, point.new( absrect.x2 - 7, absrect.y ) )
	end,
}

register_ui "ui_hof_screen"
{
	inherited  = "ui_full_screen",
	base       = "ui_con_full_window",
	background = 'menuback',
	footer     = " @<Escape@> or @<Enter@> to exit.",

	on_create  = function( self )
		local game_type = { "Massacre", "Endless", "Campaign" }
	    self.header   = " @<Berserk@>! Hall of Fame : @<"..game_type[player.mode].."@> Mode"
		local dimrect = self.pdimrect:shrinked(1,2)
		local text    = ""
		local current = ui.get_hof_current()
		local pad     = function( text, l ) return text..string.rep(" ", l - #text) end
		local bold    = function( text, i ) return core.iif( i == current, "@L"..text.."@y", "@<"..text.."@>" ) end
		local lines   = 0
		local i       = 0
		repeat
			i = i + 1
			local m,n,t,k,kb = ui.get_hof_entry( i )
			if m then 
				if m == player.mode then
					local reason   = "commited suicide"
					if kb > 1 and kb <= beings.__counter then 
						reason = "killed by "..bold(beings[kb].name) 
					end
					text = text.."  "..pad(bold(n),18).." "..pad("survived "..bold(t).." turns",26).." "..pad(bold(k).." kills",16).." "..reason.."\n"
					lines = lines + 1
				end
			else
				break
			end
		until lines == 20
		ui.new_con_text( self, dimrect, text )
	end,
}

register_ui "ui_help_screen"
{
	inherited  = "ui_full_screen",
	base       = "ui_con_full_window",
	background = 'menuback',

	on_create  = function( self )
		self:add_property( "help_header", " @<Berserk@>! Help System" )
		self:add_property( "help_footer", " Choose the topic, @<Escape@> exits." )
		self:add_property( "view_header", " @<Berserk! Help:@> " )
		self:add_property( "view_footer", " Use @<arrows@>, @<PgUp@>, @<PgDown@> to scroll, @<Escape@> or @<Enter@> to exit." )
		self:add_property( "items",      { "Getting Started", "Tips and Tricks", "Feedback",     "Credits", "Disclaimer", "Quit Help" } )
		self:add_property( "files",      { "start.hlp",       "tips.hlp",        "feedback.hlp", "credits.hlp", "disclaim.hlp" } )

		local dimrect = self.pdimrect:shrinked(1,2)
		local absrect = self.absdim

		self.header = self.help_header
		self.footer = self.help_footer

		local commands = { 
			{ COMMAND_WAIT, "Wait a turn" },
			{ COMMAND_LOOK, "Look mode" },
			{ COMMAND_RUNNING, "Run mode" },
			{ COMMAND_PLAYERINFO, "Character screen" },
			{ COMMAND_QUIT, "Quit" },
			{ COMMAND_HELP, "Help" },
		}
		for i = 1,10 do
			local skill_id = player:get_skill_slot( i )
			if skill_id > 0 and player:get_skill( skill_id ) > 0 and skills[ skill_id ].OnUse then
				local skill = skills[ skill_id ]
				table.insert( commands, { COMMAND_SKILL1-1+i, skill.name_use } )
				if skill.OnAltUse then
					table.insert( commands, { COMMAND_SKILLALT1-1+i, skill.name_altuse } )
				end
			end
		end

		local keys = "@<Keybindings@>\n"
		for _,c in ipairs( commands ) do
			keys = keys.."  "..c[2]..string.rep( " ", 17 - #(c[2]) ).."@<"..ui.get_keybinding( c[1] ).."@>\n"
		end

		self:add_property( "menu",  ui.new_con_menu( self, rect.new(3,3,20,7), self.items ) )
		self:add_property( "text",  ui.new_con_string_list( self, dimrect ) )
		self:add_property( "icons", ui.new_con_scrollable_icons( self, self.text, dimrect, point.new( absrect.x2 - 7, absrect.y ) ) )
		self:add_property( "keys",  ui.new_con_text( self, rect.new( 38, 3, 40, 23 ), keys ) )

		self.text.enabled      = false
		self.keys.enabled      = true
		self.icons.enabled     = false

		self.menu.on_confirm = function( menu, selected )
			if selected == 0 or selected == menu.count then self:destroy() return true end
			local file = ui.get_help_path()..self.files[ selected ]
			self.text.content = file

			self.header = self.view_header..self.files[ selected ]
			self.footer = self.view_footer
			self.text.enabled  = true
			self.icons.enabled = true
			self.keys.enabled  = false
			self.menu.enabled  = false
			return true
		end
	end,

	on_key_down = function( self, key )
		if key.code == io.KEY_ESCAPE or key.code == io.KEY_ENTER or key.code == io.KEY_SPACE then
			if self.text.enabled then
				self.header = self.help_header
				self.footer = self.help_footer
				self.text.enabled  = false
				self.icons.enabled = false
				self.keys.enabled  = true
				self.menu.enabled  = true
			else
				self:destroy()
			end
			return true
		end
		return false
	end,
}
