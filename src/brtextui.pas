// @abstract(BerserkRL -- Textmode User Interface class)
// @author(Kornel Kisielewicz <admin@chaosforge.org>)
// @created(Apr 11, 2007)
// @lastmod(Apr 11, 2007)

// This unit holds the texmode User Interface class of Berserk!.

//  @html <div class="license">
//  This file is part of BerserkRL.

//  BerserkRL is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.

//  BerserkRL is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with BerserkRL; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//  @html </div>
{$INCLUDE brinclude.inc}
unit brtextui;

interface

uses SysUtils, viotypes, vutil, vmath, vrltools, brui, brgviews, vconuirl;

type

  { TBerserkTextUI }

  TBerserkTextUI = class( TBerserkUI, IConUIASCIIMap )
    // Initialization of all data.
    constructor Create; reintroduce;
    // Sends missile
    procedure SendMissile( const aSource, aTarget : TCoord2D; aType : Byte; aSequence : DWord ); override;
    // Draws target X
    procedure Target( Where : TCoord2D; color : Byte ); override;
    // Renders an explosion on the screen.
    procedure AddExplosion( aWhere : TCoord2D; aColor : byte; aRange : byte; aStep : byte; aDrawDelay, aSequence : Word ); override;
    // Renders a breath weapon attack
    procedure Breath( aWhere : TCoord2D; aDirection : TDirection; aColor : byte; aRange : byte; aStep : byte; aDrawDelay : Word ); override;
    // Graphical effect of a screen flash, of the given color, and Duration in
    // miliseconds.
    procedure Blink( aColor : Byte; aDuration : Word; aSequence : Word ); override;
    // Sound effect
    procedure AddAttack( aWho : TUID; aHit : Boolean; const aFrom, aTo : TCoord2D ); override;
    // Draws a firey background
    procedure DrawFire( aSeed : Cardinal = 0 ); override;
    // Draws the level, player status, messages, and updates the screen.
    procedure Draw; override;
    // IConUIASCIIMap implementation
    function getGylph( const aCoord : TCoord2D ) : TIOGylph;
  private
    // Marks the given tile with the specified gylph. Use MarkDisplay afterwards.
    procedure MarkTile( aCoord : TCoord2D; atr : byte; chr : char );
  end;


implementation

uses vsystems, vuid, vvision, vioconsole, vtextio, vtextconsole, vuiconsole,
     branimation, brlevel, brdata, brbeing, brplayer;

{ TBerserkTextUI }

constructor TBerserkTextUI.Create;
begin
  FIODriver := TTextIODriver.Create( 80, 25 );
  FConsole := TTextConsoleRenderer.Create( 80, 25, [VIO_CON_BGCOLOR, VIO_CON_CURSOR] );
  inherited Create;
  FConsole.Clear;
  FMap := TConUIMapArea.Create( Root, Rectangle( 0,0, 50,25 ), Self );
  FMap.Enabled := False;
end;

procedure TBerserkTextUI.SendMissile( const aSource, aTarget : TCoord2D; aType : Byte; aSequence : DWord );
var iScan      : Byte;
    iDrawDelay : Word;
    iDuration  : DWord;
    iColor     : Byte;
    iChar      : Char;
begin
  iDrawDelay := 10;
  iColor     := LightGray;
  iChar      := '*';
  case aType of
    MTBOLT   : begin iDrawDelay := 5;  iColor := LightGray;  iChar := '-'; end;
    MTKNIFE  : begin iDrawDelay := 10; iColor := White;      iChar := '-'; end;
    MTBOMB   : begin iDrawDelay := 25; iColor := Brown;      iChar := '*'; end;
    MTENERGY : begin iDrawDelay := 10; iColor := White;      iChar := '*'; end;
    MTICE    : begin iDrawDelay := 15; iColor := LightBlue;  iChar := '*'; end;
    MTSPORE  : begin iDrawDelay := 40; iColor := LightGreen; iChar := '*'; end;
  end;

  iDuration := iDrawDelay * (aSource - aTarget).LargerLength;
  FMap.AddAnimation( TConUIBulletAnimation.Create( Level, aSource, aTarget, IOGylph( iChar, iColor ), iDuration, aSequence ) );

  iScan := Player.TryMove( aTarget );
  if iScan in [ Move_Block, Move_Invalid ] then // Missile hits non-passable feature
    if Level.Vision.isVisible( aTarget ) then
      FMap.AddAnimation( TConUIMarkAnimation.Create( aTarget, IOGylph( '*', LightGray ), 50, aSequence + iDuration ) );

  if iScan = Move_Being then // Missile hits Being
    FMap.AddAnimation( TConUIMarkAnimation.Create( aTarget, IOGylph( '*', Red ), 100, aSequence + iDuration ) );
end;

procedure TBerserkTextUI.AddExplosion( aWhere : TCoord2D; aColor : byte; aRange : byte; aStep : byte; aDrawDelay, aSequence : Word );
begin
  Explosion( aWhere, aColor, aRange, aDrawDelay, aSequence );
end;


procedure TBerserkTextUI.Breath( aWhere : TCoord2D; aDirection : TDirection; aColor : byte; aRange : byte; aStep : byte; aDrawDelay : Word );
var iExpl    : TConUIExplosionArray;
var iCoord   : TCoord2D;
    iRel     : TCoord2D;
    iDist    : Word;
    iAngle   : Single;
begin
  SetLength( iExpl, 5 );
  iExpl[0].Time := aDrawDelay;
  iExpl[1].Time := aDrawDelay;
  iExpl[2].Time := aDrawDelay;
  iExpl[3].Time := aDrawDelay;
  iExpl[4].Time := aDrawDelay;
  case aColor of
    Blue    : begin iExpl[0].Color := Blue;    iExpl[1].Color := LightBlue;  iExpl[2].Color := White; end;
    Magenta : begin iExpl[0].Color := Magenta; iExpl[1].Color := Red;        iExpl[2].Color := Blue; end;
    Green   : begin iExpl[0].Color := Green;   iExpl[1].Color := LightGreen; iExpl[2].Color := White; end;
    LightRed: begin iExpl[0].Color := LightRed;iExpl[1].Color := Yellow;     iExpl[2].Color := White; end;
     else     begin iExpl[0].Color := Red;     iExpl[1].Color := LightRed;   iExpl[2].Color := Yellow; end;
  end;
  iExpl[3].Color := iExpl[1].Color;
  iExpl[4].Color := iExpl[0].Color;

  FMap.FreezeMarks;
  aRange := aRange + 4;
  for iCoord in NewArea( aWhere, aRange ).Clamped( Level.Area ) do
  begin
    iDist := Distance( iCoord, aWhere );
    if (iDist = 0) or (iDist > aRange) then Continue;
    iRel := iCoord - aWhere;

    if (aDirection.x <> 0) and (Sgn( iRel.x ) = -aDirection.x) then Continue;
    if (aDirection.y <> 0) and (Sgn( iRel.y ) = -aDirection.y) then Continue;
    if (aDirection.x  = 0) and (Abs( iRel.y ) < Abs( iRel.x )) then Continue;
    if (aDirection.y  = 0) and (Abs( iRel.x ) < Abs( iRel.y )) then Continue;

    iAngle := ( iRel.x * aDirection.x + iRel.y * aDirection.y ) /
      ( RealDistance( aWhere, iCoord ) * RealDistance( aWhere, aWhere + aDirection ) );
    if iAngle < 0.76 + ( iDist * 0.02 ) then Continue;

    if not Level.Vision.isVisible( iCoord ) then Continue;
    if not Level.isEyeContact( iCoord, aWhere ) then Continue;

    AddExplodeAnimation( iCoord, iExpl, iDist*aDrawDelay+Random(aDrawDelay*3) + 5*aDrawDelay );
  end;
  FMap.AddAnimation( TConUIClearMarkAnimation.Create( (aRange+8)*aDrawDelay ) );
end;


procedure TBerserkTextUI.Target( Where : TCoord2D; color : Byte );
begin
  FMap.ClearMarks;
  if Color <> BLACK then
    MarkTile( where, color, 'X' );
end;

procedure TBerserkTextUI.MarkTile( aCoord : TCoord2D; atr : byte; chr : char );
begin
  FMap.Mark( aCoord, chr, atr );
end;

procedure TBerserkTextUI.Blink( aColor : Byte; aDuration : Word; aSequence : Word );
begin
  FMap.AddAnimation( TConUIBlinkAnimation.Create( IOGylph( 'Û', aColor ), aDuration, aSequence ) );
end;

procedure TBerserkTextUI.AddAttack(aWho: TUID; aHit: Boolean; const aFrom,  aTo: TCoord2D);
var iBeing : TBeing;
begin
  iBeing := UIDs.Get( aWho ) as TBeing;
  FMap.AddAnimation( TSoundAnimation.Create( 0, iBeing.Position, ResolveSoundID( iBeing.id, Iif( aHit, 'hit', 'miss' ) ) ) );
end;

type
  TGFXScreen = array[1..25, 1..80] of Word;

procedure TBerserkTextUI.DrawFire( aSeed : Cardinal = 0 );
var
  Temp :  TGFXScreen;
  x, y, Count, limit : byte;
  ishift : shortint;
  iCon :  TUIConsole;
  iSeed : Cardinal;
const
  RedFire    = Ord( '#' ) + 256 * Red;
  LRedFire   = Ord( '#' ) + 256 * LightRed;
  YellowFire = Ord( '#' ) + 256 * Yellow;

  procedure DrawPart( xx, vy, lim : byte );
  var
    vx : byte;
  begin
    for vy := 25 downto lim do
    begin
    iShift := (((FLastUpdate + vy*100) div 400) mod 3) - 1;
      case iShift of
        -1 : if Random( 4 ) = 0 then
            iShift := 0;
        0 : if Random( 5 ) = 0 then
            iShift := Random( 2 ) * 2 - 1;
        1 : if Random( 4 ) = 0 then
            iShift := 0;
      end;
      vx := Min( Max( 4, xx + iShift ), 77 );
      case vy - lim of
        0..4 : Temp[vy, vx] := RedFire;
        5..7 :
        begin
          Temp[vy, vx - 1] := RedFire;
          Temp[vy, vx] := RedFire;
        end;
        8..11 :
        begin
          Temp[vy, vx - 1] := RedFire;
          Temp[vy, vx] := RedFire;
          Temp[vy, vx + 1] := RedFire;
        end;
        12..14 :
        begin
          Temp[vy, vx - 1] := RedFire;
          Temp[vy, vx] := LRedFire;
          Temp[vy, vx + 1] := RedFire;
        end;
        15..16 :
        begin
          Temp[vy, vx - 2] := RedFire;
          Temp[vy, vx - 1] := LRedFire;
          Temp[vy, vx] := YellowFire;
          Temp[vy, vx + 1] := RedFire;
        end;
        17..18 :
        begin
          Temp[vy, vx - 2] := RedFire;
          Temp[vy, vx - 1] := LRedFire;
          Temp[vy, vx] := YellowFire;
          Temp[vy, vx + 1] := LRedFire;
          Temp[vy, vx + 2] := RedFire;
        end;
        19..20 :
        begin
          Temp[vy, vx - 3] := RedFire;
          Temp[vy, vx - 2] := LRedFire;
          Temp[vy, vx - 1] := YellowFire;
          Temp[vy, vx] := YellowFire;
          Temp[vy, vx + 1] := LRedFire;
          Temp[vy, vx + 2] := RedFire;
        end;
        21..25 :
        begin
          Temp[vy, vx - 3] := RedFire;
          Temp[vy, vx - 2] := LRedFire;
          Temp[vy, vx - 1] := YellowFire;
          Temp[vy, vx] := YellowFire;
          Temp[vy, vx + 1] := YellowFire;
          Temp[vy, vx + 2] := LRedFire;
          Temp[vy, vx + 3] := RedFire;
        end;
      end;
    end;
  end;

  function Cycle( b : shortint ) : byte;
  begin
    if b < 1 then
      b := 1;
    if b > 80 then
      b := 80;
    Exit( b );
  end;

begin
  for x := 1 to 80 do
    for y := 1 to 25 do
      Temp[y, x] := Ord( ' ' ) + LightGray;

  if aSeed <> 0 then
  begin
    iSeed := RandSeed;
    RandSeed := aSeed;
  end;

  for Count := 1 to 20 do
  begin
    x := Max( Min( 76, Random( 4 ) - 2 + Count * 4 ), 4 );
    limit := Random( 10 ) + 5;
    DrawPart( x, y, limit );
  end;
  for Count := 1 to 20 do
  begin
    x := Max( Min( 76, Random( 8 ) - 4 + Count * 4 ), 4 );
    limit := Random( 15 ) + 1;
    DrawPart( x, y, limit );
  end;

  Console.Clear;
  for y := 1 to 25 do
    for x := 1 to 80 do
      Console.OutputChar( x, y, Temp[y, x] div 256, Char( Temp[y, x] mod 256 ) );

  if aSeed <> 0 then
    RandSeed := iSeed;
end;

procedure TBerserkTextUI.Draw;
begin
  FMap.Enabled := True;
  inherited Draw;
end;

function TBerserkTextUI.getGylph( const aCoord : TCoord2D ) : TIOGylph;
begin
  if not Level.Vision.isVisible( aCoord ) then
    with Level.Terrain[ aCoord ] do
      Exit( IOGylph(Chr(DarkPic mod 256), DarkPic div 256) );

  if Level.Being[ aCoord ] <> nil then
  with Level.Being[ aCoord ] do
  begin
    getGylph := Gylph;
    if Player.isBerserk then getGylph.Color := LightRed;
  end
  else
  with Level.Terrain[ aCoord ] do
  begin
    getGylph.ASCII := Chr(Picture mod 256);
    getGylph.Color := Picture div 256;
    if Player.isBerserk then
      getGylph.Color := Iif( TF_HIGHLIGHT in Flags, LightRed, Red );
  end;
  if Player.FHP < 1 then getGylph.Color := Red
end;

end.

