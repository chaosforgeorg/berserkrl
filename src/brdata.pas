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

const ConfigurationPath : AnsiString = '';
      DataPath          : AnsiString = '';
      SaveFilePath      : AnsiString = '';

const
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
var TerraData : array of TTerrainData;

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
function ModeToString( Mode : Byte ) : string;


implementation

uses SysUtils, brui;

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
  RollDice := Dice(3,6);
  if (RollDice = 3)  or (RollDice = 4)  then Exit(-100);
  if (RollDice = 17) or (RollDice = 18) then Exit(100);
end;


function GodStr(Str : String) : string;
begin
  if GodMode then Exit(Str) else Exit('');
end;

function ModeToString( Mode : Byte ) : string;
begin
  case Mode of
    mode_Campaign : Exit('Campaign');
    mode_Endless  : Exit('Endless');
    mode_Massacre : Exit('Massacre');
  end;
  Exit('');
end;

end.

