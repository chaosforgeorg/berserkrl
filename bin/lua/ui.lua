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
