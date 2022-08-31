audio = {
	-- Set to "NONE" to disable audio altogether
	driver            = "FMOD",
	-- Common parameters
	sound_enabled     = true,
	music_enabled     = true,
	sound_volume      = 80,
	music_volume      = 80,
	surround_enabled  = false, -- not working in SDL, working bad in FMOD
	pos_min_volume    = 30,    -- minimum sound volume due to distance
	pos_fade_distance = 24,    -- fade over distance (25 squares)
	frequency         = 44100,
	-- SDL parameters
	sdl_chunk_size    = 512,   -- performance
	sdl_format        = 32784, -- bitmask for sdl format
	sdl_channels      = 2,     -- 1 mono, 2 stereo, probably should not be changed
	-- FMOD parameters
	fmod_flags        = 0,     -- fmod flags
	fmod_mix_channels = 32,
}

-- Set to false to always play in ASCII mode
GraphicsMode     = true

-- Do we use the extended ASCII character set
HighASCII        = true

-- Setting to TRUE will skip name entry procedure and choose a random name
-- instead
AlwaysRandomName = false

-- Setting to non-empty string will always use given name (overrides Random)
AlwaysName       = ""

-- Sets wether message coloring will be enabled. Needs [messages] section.
MessageColoring  = true

-- Messages held in the message buffer.
MessageBuffer    = 100

-- Number of last messages in mortem.txt. Can't be bigger than MessageBuffer.
MortemMessages   = 10

-- States wether there should be a killcounter on the screen.
KillCount        = false

-- Message coloring system. Works only if MessageColoring
-- variable is set to true. You may use
-- the wildcard characters * and ?.
Messages = 
{
	["*BERSERK*"]  = RED,
	["*appeared*"] = YELLOW,
}

Keybindings =
{
	["SHIFT+Q"]   = COMMAND_QUIT,
	["LEFT"]      = COMMAND_WALKWEST,
	["RIGHT"]     = COMMAND_WALKEAST,
	["UP"]        = COMMAND_WALKNORTH,
	["DOWN"]      = COMMAND_WALKSOUTH,
	["PGUP"]      = COMMAND_WALKNE,
	["PGDOWN"]    = COMMAND_WALKSE,
	["HOME"]      = COMMAND_WALKNW,
	["END"]       = COMMAND_WALKSW,
	["PERIOD"]    = COMMAND_WAIT,
	["ESCAPE"]    = COMMAND_ESCAPE,
	["ENTER"]     = COMMAND_OK,
	["TAB"]       = COMMAND_RUNNING,

	["L"]         = COMMAND_LOOK,

	["1"]        = COMMAND_SKILL1,
	["2"]        = COMMAND_SKILL2,
	["3"]        = COMMAND_SKILL3,
	["4"]        = COMMAND_SKILL4,
	["5"]        = COMMAND_SKILL5,
	["6"]        = COMMAND_SKILL6,
	["7"]        = COMMAND_SKILL7,
	["8"]        = COMMAND_SKILL8,
	["9"]        = COMMAND_SKILL9,
	["0"]        = COMMAND_SKILL0,

	["H"]         = COMMAND_HELP,
	["SHIFT+P"]   = COMMAND_MESSAGES,
	["SHIFT+C"]   = COMMAND_PLAYERINFO,
}

sounds = {
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

--	beast = {
--		hit      = "",
--		miss     = "",
--		die      = "",
--		pain     = "",
--		appear   = "",
--		passive  = "",
--	}

}

-- bindable id's :
--  yourself - the player
--  beast, bulldemon, mandagore, defiler, imp, phasehound, skeleton, 
--  scavenger, spore, wraith, treespirit, treant, townsman, ice_devil, 
--  yeti, blizzard, demon, 
--  cannon (fire,reload), crossbow (fire,reload), knives (throw), bombs (throw), fairydust (use)
-- if a specific id's sound is "", then the general one will not be used!

-- == Path configuration ==
-- You can use command line switch -config=/something/something/config.lua 
-- to load a different config!

-- Uncomment the following paths if needed:

-- This is the directory path to the read only data folder (current dir by
-- default, needs slash at end if changed). -datapath= to override on 
-- command line.
--DataPath = ""

-- This is the directory path for writing (save, log) (current dir by
-- default, needs slash at end if changed). -writepath= to override on 
-- command line.
--WritePath = ""

-- This is the directory path for score table (by default it will be the
-- same as WritePath, change for multi-user systems. -scorepath= to override
-- on command line.
--ScorePath = ""
