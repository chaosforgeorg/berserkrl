// @abstract(BerserkRL -- Config class)
// @author(Kornel Kisielewicz <admin@chaosforge.org>)
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
unit brconfig;
interface
uses Classes, SysUtils, vluasystem, vluaconfig;

type TGameConfig = class(TLuaConfig)
  constructor Create( const FileName : Ansistring );
end;

implementation

uses brui, brdata, viotypes;

{ TGameConfig }

constructor TGameConfig.Create ( const FileName : Ansistring ) ;
var b : byte;
begin
  inherited Create;
  for b := 0 to 15 do SetConstant( ColorNames[b], b );

  SetConstant( 'COMMAND_QUIT',      COMMAND_QUIT );
  SetConstant( 'COMMAND_WALKNORTH', COMMAND_WALKNORTH );
  SetConstant( 'COMMAND_WALKSOUTH', COMMAND_WALKSOUTH );
  SetConstant( 'COMMAND_WALKEAST',  COMMAND_WALKEAST );
  SetConstant( 'COMMAND_WALKWEST',  COMMAND_WALKWEST );
  SetConstant( 'COMMAND_WALKNE',    COMMAND_WALKNE );
  SetConstant( 'COMMAND_WALKSE',    COMMAND_WALKSE );
  SetConstant( 'COMMAND_WALKNW',    COMMAND_WALKNW );
  SetConstant( 'COMMAND_WALKSW',    COMMAND_WALKSW );
  SetConstant( 'COMMAND_WAIT',      COMMAND_WAIT );
  SetConstant( 'COMMAND_ESCAPE',    COMMAND_ESCAPE );
  SetConstant( 'COMMAND_OK',        COMMAND_OK );
  SetConstant( 'COMMAND_ENTER',     COMMAND_ENTER );

  SetConstant( 'COMMAND_LOOK',       COMMAND_LOOK );
  SetConstant( 'COMMAND_HELP',       COMMAND_HELP );
  SetConstant( 'COMMAND_PLAYERINFO', COMMAND_PLAYERINFO );
  SetConstant( 'COMMAND_RUNNING',    COMMAND_RUNNING );
  SetConstant( 'COMMAND_MESSAGES',   COMMAND_MESSAGES );

  SetConstant( 'COMMAND_SKILL1',  COMMAND_SKILL1 );
  SetConstant( 'COMMAND_SKILL2',  COMMAND_SKILL2 );
  SetConstant( 'COMMAND_SKILL3',  COMMAND_SKILL3 );
  SetConstant( 'COMMAND_SKILL4',  COMMAND_SKILL4 );
  SetConstant( 'COMMAND_SKILL5',  COMMAND_SKILL5 );
  SetConstant( 'COMMAND_SKILL6',  COMMAND_SKILL6 );
  SetConstant( 'COMMAND_SKILL7',  COMMAND_SKILL7 );
  SetConstant( 'COMMAND_SKILL8',  COMMAND_SKILL8 );
  SetConstant( 'COMMAND_SKILL9',  COMMAND_SKILL9 );
  SetConstant( 'COMMAND_SKILL0',  COMMAND_SKILL0 );

  LoadMain( FileName );
  //if GodMode then Load( 'godmode.lua' );

  Option_AlwaysRandomName := Entries['AlwaysRandomName'];
  Option_MessageColoring  := Entries['MessageColoring'];
  Option_MessageBuffer    := Entries['MessageBuffer'];
  Option_KillCount        := Entries['KillCount'];
  Option_MortemMessages   := Entries['MortemMessages'];
end;

end.

