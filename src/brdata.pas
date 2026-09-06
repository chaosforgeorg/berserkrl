// @abstract(BerserkRL -- general data unit)
// @author(Kornel Kisielewicz <admin@chaosforge.org>)
// @created(Oct 16, 2006)
// @lastmod(Oct 22, 2006)
//
// This unit holds the global variables and the game data for Berserk. It also
// implements some global helper functions.
//
//  @html <div class="license">
//  This file is part of BerserkRL.
//
//  BerserkRL is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  BerserkRL is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with BerserkRL; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//  @html </div>
{$INCLUDE brinclude.inc}
unit brdata;
interface
uses vutil;

const 

      // All the below paths can be set from the command line (see berserk.pas),
      // all except config can be set from the configuration file.

      // This is the full path to the configuration file ("config.lua" by default)
      ConfigurationPath : AnsiString = 'config.lua';
      // This is the directory path to the read only data folder ("" by default, 
      // needs slash at end)
      DataPath          : AnsiString = '';
      // This is the directory path for writing (save, log, crash) ("" by default, 
      // needs slash at end)
      WritePath         : AnsiString = '';
      // This is the directory path for score table (by default it will be the
      // same as WritePath, change for multi-user systems
      ScorePath         : AnsiString = '';

const COMMAND_QUIT       = 1;
      COMMAND_WALKNORTH  = 2;
      COMMAND_WALKSOUTH  = 3;
      COMMAND_WALKEAST   = 4;
      COMMAND_WALKWEST   = 5;
      COMMAND_WALKNE     = 6;
      COMMAND_WALKSE     = 7;
      COMMAND_WALKNW     = 8;
      COMMAND_WALKSW     = 9;
      COMMAND_WAIT       = 10;
      COMMAND_ESCAPE     = 11;
      COMMAND_OK         = 12;
      COMMAND_ENTER      = 13;
      COMMAND_LOOK       = 21;
      COMMAND_HELP       = 25;
      COMMAND_PLAYERINFO = 26;
      COMMAND_RUNNING    = 27;
      COMMAND_MESSAGES   = 28;

      COMMAND_SKILL1     = 51;
      COMMAND_SKILL2     = 52;
      COMMAND_SKILL3     = 53;
      COMMAND_SKILL4     = 54;
      COMMAND_SKILL5     = 55;
      COMMAND_SKILL6     = 56;
      COMMAND_SKILL7     = 57;
      COMMAND_SKILL8     = 58;
      COMMAND_SKILL9     = 59;
      COMMAND_SKILL0     = 60;

      COMMAND_SKILLALTSHIFT = 10;

      COMMAND_SKILLALT1  = COMMAND_SKILLALTSHIFT + COMMAND_SKILL1;
      COMMAND_SKILLALT2  = COMMAND_SKILLALTSHIFT + COMMAND_SKILL2;
      COMMAND_SKILLALT3  = COMMAND_SKILLALTSHIFT + COMMAND_SKILL3;
      COMMAND_SKILLALT4  = COMMAND_SKILLALTSHIFT + COMMAND_SKILL4;
      COMMAND_SKILLALT5  = COMMAND_SKILLALTSHIFT + COMMAND_SKILL5;
      COMMAND_SKILLALT6  = COMMAND_SKILLALTSHIFT + COMMAND_SKILL6;
      COMMAND_SKILLALT7  = COMMAND_SKILLALTSHIFT + COMMAND_SKILL7;
      COMMAND_SKILLALT8  = COMMAND_SKILLALTSHIFT + COMMAND_SKILL8;
      COMMAND_SKILLALT9  = COMMAND_SKILLALTSHIFT + COMMAND_SKILL9;
      COMMAND_SKILLALT0  = COMMAND_SKILLALTSHIFT + COMMAND_SKILL0;

{$INCLUDE ../bin/lua/const.lua}

var
    // Holds the version of the game -- read from the first line of 'version.txt'
    Version      : string  = '';
    // Set to true if GodMode enabled -- activated by launching the game with
    // the -god parameter.
    GodMode      : Boolean = False;
    // Quickstart for starting immidately on the field for debug purposes.
    QuickStart   : Boolean = False;
    // Whether we are in Graphics mode or not
    GraphicsMode : Boolean = True;
    // Whether we use High ASCII or not
    HighASCII    : Boolean = True;
    // Whether to start in fullscreen (Graphics only)
    FullScreen   : Boolean = False;
    // Audio driver to use
    AudioDriver  : AnsiString = 'SDL';


const // Number of entries in the hall of fame. If changed then score.dat needs
      // to be deleted.
      HOFENTRIES    = 20;
      // X position from which to draw the map
      MAP_POSX      = 1;
      // Y position from which to draw the map
      MAP_POSY      = 1;
      // The amount of TBeing.SpeedCount needed to be accumulated to make an
      // Action.
      SPEEDLIMIT    = 5000;
      // The amount of TBeing.WillCount needed to make a Energy regeneration.
      WILLLIMIT     = 1000;

      // Amount of damage that produces a 1 field knockback
      KNOCKBACKVALUE = 8;
      
      // Maximum distance of bomb throw
      BOMBDISTANCE   = 7;

      GMODE_EFFECT_Z  = 800;
      GMODE_STEP_Z    = 10;
      GMODE_GUI_Z     = 999;

// Graphics mode only -- sets a color overlay, where all 1.0 are natural color.
type TColorOverlay = array[1..3] of Real;

// Constant for TColorOverlay defining natural color (no overlay)
const NOCOLOROVERLAY : TColorOverlay = (1.0,1.0,1.0);

// Data for a single terrain tile type
type TTerrainData = record
       // ID of the tile
       ID        : AnsiString;
       // Name of the tile for the look command
       Name      : AnsiString;
       // Picture of the lit tile
       Picture   : Word;
       // Picture of the tile when unlit
       DarkPic   : Word;
       // Amount of Damage needed to Destroy
       DR        : Byte;
       // ID of the tile to change to if blood spilled over it
       BloodID   : Word;
       // ID of the tile to change to if tile destroyed (eg. for walls)
       DestroyID : Word;
       // ID of the tile to change to if tile acted upon (eg. doors)
       ActID     : Word;
       // Sprite Base
       SpriteB : Word;
       //
       Sprite  : Word;
       //
       EdgeSet : Byte;
       // Move cost modifier (percent)
       MoveCost  : Byte;
       // Flags of the tile (see constants starting with TF)
       Flags     : TFlags;
       // Hooks of the cell
       Hooks     : TFlags;
     end;

const TileHook_OnAct      = 0;
      TileHook_OnStanding = 1;
      TileHook_OnDestroy  = 2;
const TileHooks  : array[ 0..2 ] of AnsiString = ('OnAct', 'OnStanding', 'OnDestroy');


// Artificial intelligence type
type TAITypeSet = set of Byte;

const // Sets max number of skills.
      MAXSKILLS     = 50;

const STAT_STR = 0;
      STAT_DEX = 1;
      STAT_END = 2;
      STAT_WIL = 3;

// Skill array for the player
type TSkills = array[1..MAXSKILLS] of Byte;
     
// Terrain data -- collection of tile definitions. Tile 0 is special -- it's
// not supposed to be used, but is there to prevent and identify errors.
type TTerrainDataArray = array of TTerrainData;

// Borrowed view of the Runtime generation's terrain definitions.
var TerraData : TTerrainDataArray;

// Visual representation data (sprite, ascii, color, overlay, etc)
type TVisual = record
  // Graphical mode only : The sprite ID for the being.
  Sprite   : Word;
  // Graphical mode only : Values of 1.0,1.0,1.0 is the natural color
  Overlay  : TColorOverlay;
  // Facing for sprite rendering - used only in graphics mode
  Mirror   : Boolean;
  //
  AnimCount: DWord;
end;

const MAX_AMMO = 10;
type TPlayerAmmo = array[1..MAX_AMMO] of Byte;

// Rolls three 6-sided dice. If 3 or 4 is rolled, then the value is -100,
// if 17,18 is rolled then the value is 100.
function RollDice : Integer;
// Function for debug strings. Returns string if GodMode, '' otherwise.
function GodStr(Str : String) : string;
// Returns the name of the battlefield of given ID
function ArenaToString(ArenaID : byte) : string;
// Returns the name of the battlefield of given ID
function ModeToString( Mode : Byte ) : Ansistring;


implementation

uses SysUtils, brui, brmain;

function ArenaToString(ArenaID : byte) : string;
begin
  case ArenaID of
    ARENA_FIELDS : Exit('Fields');
    ARENA_FOREST : Exit('Forest');
    ARENA_TOWN   : Exit('Town');
    ARENA_SNOW   : Exit('Snow');
  else Exit('Unknown');
  end
end;


function RollDice : Integer;
begin
  RollDice := Berserk.Runtime.GameRNG.Dice( 3, 6 );
  if (RollDice = 3)  or (RollDice = 4)  then Exit(-100);
  if (RollDice = 17) or (RollDice = 18) then Exit(100);
end;


function GodStr(Str : String) : string;
begin
  if GodMode then Exit(Str) else Exit('');
end;

function ModeToString( Mode : Byte ) : Ansistring;
begin
  case Mode of
    mode_Campaign : Exit('Campaign');
    mode_Endless  : Exit('Endless');
    mode_Massacre : Exit('Massacre');
  end;
  Exit('');
end;

end.

