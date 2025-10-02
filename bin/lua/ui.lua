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
