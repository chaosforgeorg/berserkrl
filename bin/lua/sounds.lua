-- Sound bindings: the sample a being or item plays for each event.
-- Bindable ids:
--  yourself - the player
--  beast, bulldemon, mandagore, defiler, imp, phasehound, skeleton,
--  scavenger, spore, wraith, treespirit, treant, townsman, ice_devil,
--  yeti, blizzard, demon,
--  cannon (fire,reload), crossbow (fire,reload), knives (throw), bombs (throw), fairydust (use)
-- If a specific id's sound is "", then the general one will not be used!
core.declare( "sounds", {
	hit      = "",
	miss     = "",
	die      = "",
	pain     = "",
	appear   = "",
	passive  = "",

	fire     = "",
	reload   = "",
	throw    = "",
	use      = "",

	consume  = "",
	scavenge = "",
	ressurect= "",
	animate  = "",
	defile   = "",

	yourself = {
		hit      = "",
		miss     = "",
		die      = "",
		pain     = "",
		appear   = "",
		passive  = "",

		fire     = "",
		reload   = "",
		throw    = "",
		use      = "",
	},
} )
