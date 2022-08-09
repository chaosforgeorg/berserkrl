// @abstract(BerserkRL -- Main Application class)
// @author(Kornel Kisielewicz <admin@chaosforge.org>)
// @created(Oct 16, 2006)
// @lastmod(Oct 22, 2006)
//
// This unit just holds the TBerserk class -- the application framework
// for BerserkRL.
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
unit brlua;
interface
uses Classes, SysUtils, vrltools, vluasystem, vluastate;

type

{ TBerserkLua }

TBerserkLua = class(TLuaSystem)
  constructor Create;
  procedure Load;
  procedure LoadCells;
  procedure RegisterPlayer;
  destructor Destroy; override;
  // TODO: this is unused!
  procedure OnError(const ErrorString : Ansistring);
end;

implementation
uses vluaext, strutils, vnode, vluaui, vluatools, vluaentitynode, vluadungen, vdebug, vsound,
     brplayer, brmain, brui, brdata, brbeing, brlevel;

constructor TBerserkLua.Create;
begin
  inherited Create;
end;

procedure TBerserkLua.Load;
var Amount, Count : DWord;
    LuaInfo       : TLuaClassInfo;
begin
  ErrorFunc := @OnError;
  RegisterTableAuxFunctions( FState );
  RegisterMathAuxFunctions( FState );
  RegisterStringListClass( FState );
  RegisterWeightTableClass( FState );

  RegisterCoordClass( FState );
  RegisterAreaClass( FState );
  RegisterAreaFull( FState, NewArea( NewCoord2D( 1, 1 ), NewCoord2D( MAP_MAXX, MAP_MAXY ) ) );

  RegisterPointClass( FState );
  RegisterRectClass( FState );

  RegisterDungenClass( FState, 'generator' );
  if Assigned( Sound ) then 
    TSound.RegisterLuaAPI( FState );

  RegisterUIClass( FState );
  TBerserkUI.RegisterLuaAPI();
  TLevel.RegisterLuaAPI();
  TBeing.RegisterLuaAPI();
  TLuaEntityNode.RegisterLuaAPI( 'being' );

  TNode.RegisterLuaAPI( 'object' );

  RegisterType( TLevel,  'level',  'level' );
  RegisterType( TBeing,  'being',  'beings' );
  RegisterType( TPlayer, 'player', 'beings' );

  LuaInfo := LuaSystem.GetClassInfo( TBeing );
  LuaInfo.RegisterHooks( Hooks_All, HookNames );

  LuaInfo := LuaSystem.GetClassInfo( TPlayer );
  LuaInfo.RegisterHooks( Hooks_All, HookNames );

  TPlayer.RegisterLuaAPI();

  try
    RegisterModule('core',DataPath+'lua' + DirectorySeparator );
    LoadFile(DataPath+'lua' + DirectorySeparator + 'main.lua');
  except
    on e : ELuaException do
      raise Exception.Create( e.Message );
  end;

  LoadCells;
end;

procedure TBerserkLua.LoadCells;
var iAmount, iCount, iHook : DWord;
  function Resolve( const CellID : AnsiString ) : Word;
  begin
    if CellID = '' then Exit(0);
    Exit( LuaSystem.Get(['cells',CellID,'nid']) );
  end;
begin
  iAmount := LuaSystem.Get(['cells','__counter']);
  SetLength( TerraData, iAmount+1 );
  for iCount := 1 to iAmount do
  with LuaSystem.GetTable(['cells',iCount]) do
  try
    with TerraData[ iCount ] do
    begin
      ID        := GetString('id');
      Name      := GetString('name');
      Picture   := Ord(GetString('picture')[1]) + 256 * GetInteger('color');
      DarkPic   := Ord(GetString('dpicture')[1]) + 256 * GetInteger('dcolor');
      DR        := GetInteger('dr');
      BloodID   := Resolve( GetString('blood_id') );
      DestroyID := Resolve( GetString('destroy_id') );
      ActID     := Resolve( GetString('act_id') );
      SpriteB   := GetInteger('spriteb');
      Sprite    := GetInteger('sprite');
      MoveCost  := GetInteger('move_cost');
      EdgeSet   := GetInteger('edgeset');
      Flags     := GetFlags('flags');
      Hooks     := [];
      for iHook := Low( TileHooks ) to High( TileHooks ) do
        if isFunction( TileHooks[ iHook ] ) then
          Include( Hooks, iHook );
    end;
  finally
    Free;
  end;

end;

procedure TBerserkLua.RegisterPlayer;
begin
  LuaSystem.SetValue('player',Player);
  LuaSystem.SetValue('level',Level);
  RegisterKillsClass( LuaSystem.Raw, Player.FKills );
  RegisterDungen( Level.Generator );
end;

destructor TBerserkLua.Destroy;
begin
  inherited Destroy;
end;

procedure TBerserkLua.OnError(const ErrorString: Ansistring);
begin
  Log('LuaError: '+ErrorString);
  if (UI <> nil)  then
  begin
    UI.Msg( 'LuaError: '+ ErrorString );
  end
  else
    raise ELuaException.Create('LuaError: '+ErrorString);
end;

end.

