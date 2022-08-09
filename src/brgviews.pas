// @abstract(BerserkRL -- game views)
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
//  @html </div>unit brui;
{$INCLUDE brinclude.inc}
unit brgviews;
interface

uses Classes, SysUtils, vtextures, vuielement, vuielements, vconui, vconuiext, vuitypes, vioevent, vgltypes;

type TUIStatus = class( TUIElement )
  constructor Create( aParent : TUIElement );
  procedure OnRender; override; // graphics
  procedure OnRedraw; override; // ascii
private
  FMessages  : TConUIMessages;
  FTextureID : TTextureID;
public
  property Messages : TConUIMessages read FMessages;
end;

implementation

uses math, vrltools, vluasystem, vutil, vuiconsole, brgui, brlevel, brdata, brplayer, brui;

const GLSolid : TGLVec4f = ( Data : ( 1,1,1,1 ) );

{ TUIStatus }

constructor TUIStatus.Create ( aParent : TUIElement ) ;
begin
  inherited Create( aParent, Rectangle( 50, 0, 30, 25 ) );
  if GraphicsMode then
  begin
    FTextureID := Textures.TextureID['background'];
  end;
  FMessages  := TConUIMessages.Create( Self, Rectangle( 1,16,28,8 ), nil, Option_MessageBuffer );
  FMessages.ForeColor := DarkGray;
end;

procedure TUIStatus.OnRender;
begin
  inherited OnRender;
  if GraphicsMode then
  begin
    GUI.PreQuads[ Textures[FTextureID].GLTexture ].PushQuad(
      GLVec3i( 500,0,GMODE_GUI_Z ), GLVec3i( 800,600,GMODE_GUI_Z ), GLSolid,
      GLVec2f(), Textures[FTextureID].GLSize
    );
  end;
end;

procedure TUIStatus.OnRedraw;
var iCon    : TUIConsole;
    iCt     : Word;
    iString : AnsiString;
  procedure DrawBar( aMax, aCur : Integer; aPos : Byte; aColor : TUIColor; aSpec : Word = 0; aColorSpec : TUIColor = 0 );
  var iFull, iFull2,iCount : Byte;
    function BColor(aCnt,aFull : Word) : Byte;
    begin
      if aCnt <= aFull then Exit(aColorSpec) else Exit(aColor);
    end;
  begin
    iFull  := math.Max(Round(aCur*28/aMax),0);
    iFull2 := math.Max(Round(aSpec*28/aMax),0);
    if iFull > 0  then
      for iCount := 1 to iFull do
        iCon.DrawChar( FAbsolute.Pos + Point(iCount,aPos),BColor(iCount,iFull2),'#');
    if iFull < 28 then
      for iCount := iFull+1 to 28 do
        iCon.DrawChar( FAbsolute.Pos + Point(iCount,aPos),BColor(iCount,iFull2),'-');
  end;

  function GetSkillString( aSkillSlot : Byte ) : AnsiString;
  var iSkill  : DWord;
      iAmmo   : Byte;
  begin
    iSkill  := Player.FSkillSlots[ iCt ];
    Result  := '@<'+UI.Config.GetKeybinding( COMMAND_SKILL1-1+aSkillSlot ) + '@>:' + LuaSystem.Get(['skills',iSkill,'name_short']);
    iAmmo   := LuaSystem.Get(['skills',iSkill,'ammo_slot']);
    if iAmmo <> 0 then
    begin
      Result  += ' @<'+IntToStr( Player.FAmmo[ iAmmo ] )+'@>';
      iAmmo   := LuaSystem.Get(['skills',iSkill,'quiver_slot']);
      if iAmmo <> 0 then Result += '/@<'+IntToStr( Player.FAmmo[ iAmmo ] )+'@>';
    end;
  end;

begin
  inherited OnRedraw;
  iCon.Init( TConUIRoot(FRoot).Renderer );
  iCon.ClearRect( FAbsolute, FBackColor );
  with Player do
  begin
    iCon.Print( FAbsolute.Pos + Point(1,0),Yellow,Black,Name+', the Berserker',False);
    iCon.Print( FAbsolute.Pos + Point(1,1),DarkGray,Black,Format('Str:@<%d@> Dex:@<%d@> End:@<%d@> Wil:@<%d@>',[ST,DX,EN,WP]), True);

    iCon.Print( FAbsolute.Pos + Point(1,3),DarkGray,Black,Format('Health : @R%d@d/@R%d',[FHP,FHPMax]), True);
    DrawBar( FHPMax, FHP, 4, LightRed, FHealthMark, Red );
    iCon.Print( FAbsolute.Pos + Point(1,5),DarkGray,Black,Format('Energy : @y%d@d/@y%d',[FEN,FENMax]), True);
    DrawBar( FENMax, FEN, 6, Yellow );

    for iCt := Low( FSkillSlots ) to 5 do
      if FSkillSlots[ iCt ] <> 0 then
        iCon.Print( FAbsolute.Pos + Point(1,7+iCt),DarkGray,Black,GetSkillString( iCt ),True);
    for iCt := 6 to High( FSkillSlots ) do
      if FSkillSlots[ iCt ] <> 0 then
        iCon.Print( FAbsolute.Pos + Point(18,7+iCt-5),DarkGray,Black,GetSkillString( iCt ),True);

    if isBerserk   then iCon.RawPrint( FAbsolute.Pos + Point(21,13),Red,'BERSERK');
    if isRunning   then iCon.RawPrint( FAbsolute.Pos + Point(1,13),Yellow,'RUNNING');

    if FPain > 0    then iCon.Print( FAbsolute.Pos + Point(1,14),Red,Black,
      Format('Pain (@<-%d@>)',[FPain]), true);
    if FFreeze > 0  then iCon.Print( FAbsolute.Pos + Point(12,14),LightBlue,Black,
      Format('Frz (@<-%d@>)',[FFreeze]), true);
    if isBerserk   then
      if EnemiesAround div 2 > 0 then
        iCon.Print( FAbsolute.Pos + Point(21,14),Red,Black,
        Format('Brk (@<+%d@>)',[EnemiesAround div 2]), true);

    iCon.RawPrint( FAbsolute.Pos + Point(1,15),DarkGray,'---------------------------');
    if FMode <> mode_Massacre then
    begin
      iCt := Max(Min(Round((Level.FTickCount/NIGHTDURATION)*28),28),1);
      iCon.DrawChar(FAbsolute.Pos + Point(iCt,15),LightGray,'=');
      if iCt < 14
        then iCon.Print( FAbsolute.Pos + Point(18,15),DarkGray,Black,Format(' Night %d ',[Player.FNight]), true)
        else iCon.Print( FAbsolute.Pos + Point(2,15),DarkGray,Black,Format(' Night %d ',[Player.FNight]), true);

    end;

    if Option_KillCount then
      iCon.Print( FAbsolute.Pos + Point(20,24),DarkGray,Black,Format('[@r%d@>]',[Player.GetKills]), true);
  end;
end;

end.

