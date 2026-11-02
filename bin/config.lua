audio = {
	-- FMOD, SDL, or NONE to disable audio altogether
	driver = "FMOD",
}

-- Display, audio, gameplay and keyboard preferences are stored in settings.lua
-- and changed in the in-game Settings menu.

-- Message coloring system. Remove or comment out the Messages table to turn it
-- off. You may use the wildcard characters * and ?.
Messages =
{
	["*BERSERK*"]  = RED,
	["*appeared*"] = YELLOW,
}

-- With --god, a GodKeys table here binds function hooks during gameplay, keyed by
-- names such as CTRL+F1. Explicit gameplay keys take precedence, and hooks may
-- return COMMAND_* actions.

-- == Path configuration ==
-- You can use command line switch --config=/something/something/config.lua
-- to load a different config!

-- Uncomment the following paths if needed:

-- This is the directory path to the read only data folder (current dir by
-- default, needs slash at end if changed). --data-path= to override on
-- command line.
--DataPath = ""

-- This is the directory path for writing (save, log) (current dir by
-- default, needs slash at end if changed). --write-path= to override on
-- command line.
--WritePath = ""

-- This is the directory path for score table (by default it will be the
-- same as WritePath, change for multi-user systems. --score-path= to override
-- on command line.
--ScorePath = ""
