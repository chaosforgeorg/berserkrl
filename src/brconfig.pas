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
uses Classes, SysUtils, vluasystem, vluaconfig, vbindings, vioevent;

type TGameConfig = class(TLuaConfig)
  constructor Create( const FileName : Ansistring );
  procedure LoadGodKeys( aContext : TBindingContext );
  function RunGodKey( aKey : TIOKeyCode ) : Variant;
private
  FGodKeyNames : array of AnsiString;
end;

implementation

uses brui, brdata, viotypes, vluatable, vlualibrary;

{ TGameConfig }

constructor TGameConfig.Create ( const FileName : Ansistring ) ;
var b : byte;
begin
  inherited Create;
  for b := 0 to 15 do SetConstant( ColorNames[b], b );

  
  LoadMain( FileName );

  Option_AlwaysRandomName := Configure( 'AlwaysRandomName', False );
  Option_AlwaysName       := Configure( 'AlwaysName', '' );
  Option_MessageColoring  := Configure( 'MessageColoring', True );
  Option_MessageBuffer    := Configure( 'MessageBuffer', 100 );
  Option_KillCount        := Configure( 'KillCount', False );
  Option_MortemMessages   := Configure( 'MortemMessages', 10 );
end;

procedure TGameConfig.LoadGodKeys( aContext : TBindingContext );
var iTable : TLuaTable;
    iPair : TLuaValuePair;
    iKey : TIOKeyCode;
begin
  if not TableExists( 'GodKeys' ) then Exit;
  SetLength( FGodKeyNames, IOKeyCodeMax + 1 );
  iTable := TLuaTable.Create( Raw, 'GodKeys' );
  try
    for iPair in iTable.Pairs do
      if iPair.Key.IsString and ( iPair.Value.LuaType = LUA_TFUNCTION ) then
      begin
        iKey := StringToIOKeyCode( iPair.Key.ToString );
        if ( iKey <> 0 ) and ( aContext.ResolveKey( iKey ) = BINDING_NONE ) then
        begin
          FGodKeyNames[iKey] := iPair.Key.ToString;
          aContext.BindKey( iKey, BINDING_FORWARD_LUA );
        end;
      end;
  finally
    iTable.Free;
  end;
end;

function TGameConfig.RunGodKey( aKey : TIOKeyCode ) : Variant;
begin
  Result := Call( ['GodKeys', FGodKeyNames[aKey]], [] );
end;

end.

