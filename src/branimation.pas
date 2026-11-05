// @abstract(BerserkRL -- views)
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
unit branimation;
interface

uses Classes, SysUtils,
     vutil, vrltools, vgltypes, vanimation, vsound,
     brdata, brbeing, brgui;

type

{ TGLTileAnimation }

TGLTileAnimation = class( TAnimation )
  constructor Create( aGUI : TBerserkGUI; aDuration : DWord; aDelay : DWord; aUID : TUID; aTile : Word; const aSize : TGLVec2i; const aColor : TGLVec4f; aFlip : Boolean );
  procedure OnStart; override;
  destructor Destroy; override;
protected
  procedure DrawTile( const aPos : TGLVec3i );
protected
  FGUI   : TBerserkGUI; // borrowed; owns the animation
  FTile  : Word;
  FSize  : TGLVec2i;
  FColor : TGLRawQColor;
  FFlip  : Boolean;
end;


{ TGLMoveAnimation }

TGLMoveAnimation = class( TGLTileAnimation )
  constructor Create( aGUI : TBerserkGUI; aDuration : DWord; aDelay : DWord; aBeing : TBeing; const aFrom, aTo : TCoord2D );
  procedure OnDraw; override;
private
  FStart : TGLVec3i;
  FStop  : TGLVec3i;
end;

{ TGLAttackAnimation }

TGLAttackAnimation = class( TGLTileAnimation )
  constructor Create( aGUI : TBerserkGUI; aDuration : DWord; aDelay : DWord; aBeing : TBeing; const aFrom, aTo : TCoord2D );
  procedure OnDraw; override;
private
  FStart : TGLVec3i;
  FStop  : TGLVec3i;
end;

{ TGLMarkAnimation }

TGLMarkAnimation = class( TGLTileAnimation )
  constructor Create( aGUI : TBerserkGUI; aDuration : DWord; aDelay : DWord; aTile : Word; const aPosition : TGLVec3i; const aSize : TGLVec2i; const aColor : TGLVec4f; aFlip : Boolean );
  procedure OnDraw; override;
private
  FPosition : TGLVec3i;
end;

{ TGLScreenMoveAnimation }

TGLScreenMoveAnimation = class( TAnimation )
  constructor Create( aGUI : TBerserkGUI; aDuration : DWord; aDelay : DWord; aUID : TUID; const aFrom, aTo : TCoord2D );
  procedure OnUpdate( aTime : DWord ); override;
private
  FGUI   : TBerserkGUI; // borrowed; owns the animation
  FStart : TCoord2D;
  FStop  : TCoord2D;
end;

{ TGLMissileAnimation }

TGLMissileAnimation = class( TGLTileAnimation )
  constructor Create( aGUI : TBerserkGUI; aDuration : DWord; aDelay : DWord; aTile : Word; aUID : TUID; const aFrom, aTo : TCoord2D; const aSize : TGLVec2i; const aColor : TGLVec4f; aRotated : Boolean; aZoom : Single );
  procedure OnDraw; override;
private
  FStart   : TGLVec3i;
  FStop    : TGLVec3i;
  FZoom    : Single;
  FHeading : Single;
  FRotated : Boolean;
end;

{ TGLExplAnimation }

TGLExplAnimation = class( TGLTileAnimation )
  constructor Create( aGUI : TBerserkGUI; aDuration : DWord; aDelay : DWord; const aPosition : TCoord2D; const aSize : TGLVec2i; const aColor : TGLVec4f );
  procedure OnDraw; override;
private
  FPosition : TGLVec3i;
end;

{ TGLBlinkAnimation }

TGLBlinkAnimation = class( TAnimation )
  constructor Create( aGUI : TBerserkGUI; aDuration : DWord; aDelay : DWord; const aColor : TGLVec4f );
  procedure OnDraw; override;
private
  FGUI   : TBerserkGUI; // borrowed; owns the animation
  FColor : TGLVec4f;
end;

{ TSoundAnimation }

TSoundAnimation = class( TAnimation )
  constructor Create( aAudio : TSound; aDelay : DWord; aPosition : TCoord2D; const aSoundID : AnsiString );
  procedure OnStart; override;
private
  FAudio    : TSound;
  FPosition : TCoord2D;
  FSoundID  : AnsiString;
end;



implementation

uses vmath, math, vcolor, vdebug, brplayer;

{ TSoundAnimation }

constructor TSoundAnimation.Create(aAudio: TSound; aDelay: DWord; aPosition: TCoord2D;  const aSoundID: AnsiString);
begin
  inherited Create( 1, aDelay, 0 );
  FAudio    := aAudio;
  FPosition := aPosition;
  FSoundID  := aSoundID;
end;

procedure TSoundAnimation.OnStart;
begin
  if ( FAudio <> nil ) and FAudio.SampleExists( FSoundID ) then
    FAudio.PlaySample( FSoundID, FPosition );
end;

{ TGLTileAnimation }

constructor TGLTileAnimation.Create( aGUI : TBerserkGUI; aDuration: DWord; aDelay: DWord;
  aUID: TUID; aTile: Word; const aSize: TGLVec2i; const aColor: TGLVec4f;
  aFlip: Boolean);
var iColor : TGLVec3b;
    i : Integer;
begin
  inherited Create( aDuration, aDelay, aUID );
  FGUI   := aGUI;
  FTile  := aTile;
  FSize  := aSize;
  for i := 0 to 2 do
    iColor.Data[i] := Clamp( Round( aColor.Data[i] * 255 ), 0, 255 );
  FColor.SetAll( iColor );
  FFlip  := aFlip;
end;

procedure TGLTileAnimation.OnStart;
var iBeing : TBeing;
begin
  if FUID <> 0 then
  begin
    iBeing := FGUI.BeingByUID( FUID );
    if iBeing <> nil then
      Inc( iBeing.FVisual.AnimCount );
  end;
end;

destructor TGLTileAnimation.Destroy;
var iBeing : TBeing;
begin
  if FUID <> 0 then
  begin
    iBeing := FGUI.BeingByUID( FUID );
    if iBeing <> nil then
      Dec( iBeing.FVisual.AnimCount );
    FUID := 0;
  end;
  inherited Destroy;
end;

procedure TGLTileAnimation.DrawTile( const aPos: TGLVec3i );
begin
  FGUI.DrawSprite( FTile, aPos, FSize, FColor, FFlip );
end;

{ TGLMoveAnimation }

constructor TGLMoveAnimation.Create( aGUI : TBerserkGUI; aDuration: DWord; aDelay: DWord; aBeing : TBeing; const aFrom, aTo : TCoord2D );
var iColor : TGLVec4f;
    iZ     : Integer;
begin
  if not aGUI.Player.isBerserk
    then iColor.Init( 1.0*aBeing.FVisual.Overlay[1], 1.0*aBeing.FVisual.Overlay[2], 1.0*aBeing.FVisual.Overlay[3], 1.0 )
    else iColor.Init( 1.0, 0.3, 0.3, 1.0 );

  inherited Create( aGUI, aDuration, aDelay, aBeing.UID, aBeing.FVisual.Sprite,
    GLVec2i( IIf( aBeing.Flags[ SF_BIG ], 32, 24 ), 32 ), iColor, not aBeing.FVisual.Mirror
  );

  iZ     := Max( aFrom.Y * GMODE_STEP_Z + 1, aTo.Y * GMODE_STEP_Z + 1 );
  FStart := FGUI.ToAbsPos( aFrom, iZ );
  FStop  := FGUI.ToAbsPos( aTo, iZ );
end;

procedure TGLMoveAnimation.OnDraw;
begin
  FGUI.DrawSprite( FTile, Lerp( FStart, FStop, Min( FTime / FDuration, 1.0 ) ), FSize, FColor, FFlip, 1.1 );
end;

{ TGLAttackAnimation }

constructor TGLAttackAnimation.Create( aGUI : TBerserkGUI; aDuration: DWord; aDelay: DWord; aBeing: TBeing; const aFrom, aTo: TCoord2D);
var iColor : TGLVec4f;
    iZ     : Integer;
begin
  if not aGUI.Player.isBerserk
    then iColor.Init( 1.0*aBeing.FVisual.Overlay[1], 1.0*aBeing.FVisual.Overlay[2], 1.0*aBeing.FVisual.Overlay[3], 1.0 )
    else iColor.Init( 1.0, 0.3, 0.3, 1.0 );

  inherited Create( aGUI, aDuration, aDelay, aBeing.UID, aBeing.FVisual.Sprite,
    GLVec2i( IIf( aBeing.Flags[ SF_BIG ], 32, 24 ), 32 ), iColor, not aBeing.FVisual.Mirror
  );

  iZ     := Max( aFrom.Y * GMODE_STEP_Z + 1, aTo.Y * GMODE_STEP_Z + 1 );
  FStart := FGUI.ToAbsPos( aFrom, iZ );
  FStop  := FGUI.ToAbsPos( aTo, iZ );
end;

procedure TGLAttackAnimation.OnDraw;
var iValue : Single;
begin
  iValue := 0.5 - Abs( Min( FTime / FDuration, 1.0 ) - 0.5 );
  FGUI.DrawSprite( FTile, Lerp( FStart, FStop, iValue ), FSize, FColor, FFlip, 1.2 );
end;

{ TGLMarkAnimation }

constructor TGLMarkAnimation.Create( aGUI : TBerserkGUI; aDuration: DWord; aDelay: DWord; aTile: Word; const aPosition : TGLVec3i; const aSize: TGLVec2i; const aColor: TGLVec4f; aFlip: Boolean);
begin
  inherited Create( aGUI, aDuration, aDelay, 0, aTile, aSize, aColor, aFlip );
  FPosition := aPosition;
end;

procedure TGLMarkAnimation.OnDraw;
begin
  FGUI.DrawSprite( FTile, FPosition, FSize, FColor, FFlip, 1.3 );
end;

{ TGLScreenMoveAnimation }

constructor TGLScreenMoveAnimation.Create( aGUI : TBerserkGUI; aDuration: DWord; aDelay: DWord; aUID : TUID; const aFrom, aTo: TCoord2D );
begin
  inherited Create( aDuration, aDelay, aUID );
  FGUI  := aGUI;
  FStart := aFrom;
  FStop := aTo;
end;

procedure TGLScreenMoveAnimation.OnUpdate(aTime: DWord);
begin
  inherited OnUpdate(aTime);
  if (FStart <> FStop) and (FTime > 0) then
    FGUI.SpriteEngine.Position := Lerp( FGUI.CameraFor( FStart ), FGUI.CameraFor( FStop ), Min( FTime / FDuration, 1.0 ) );
end;

{ TGLMissileAnimation }

constructor TGLMissileAnimation.Create( aGUI : TBerserkGUI; aDuration: DWord; aDelay: DWord;
  aTile: Word; aUID : TUID; const aFrom, aTo: TCoord2D; const aSize: TGLVec2i;
  const aColor: TGLVec4f; aRotated : Boolean; aZoom: Single);
begin
  inherited Create( aGUI, aDuration, aDelay, aUID, aTile, aSize, aColor, False );
  FStart   := FGUI.ToAbsPos( aFrom, GMODE_EFFECT_Z );
  FStop    := FGUI.ToAbsPos( aTo, GMODE_EFFECT_Z ) + GLVec3i(
    FGUI.VisualRNG.RLongInt(21) - 10, FGUI.VisualRNG.RLongInt(21) - 10, 0 );
  FZoom    := aZoom;
  FRotated := aRotated;
  FHeading := -ArcTan2( FStop.X - FStart.X, FStop.Y - FStart.Y ) + PI/2;
end;

procedure TGLMissileAnimation.OnDraw;
var iPos    : TGLVec3i;
    iSize   : TGLVec2i;
    iCoord  : TGLRawQCoord;
    iTex    : TGLRawQTexCoord;
    iTile   : TGLVec2f;
  function Rotated( aX, aY : Integer ) : TGLVec2i;
  begin
    Result.Init( iPos.X + Round( aX * Cos( FHeading ) - aY * Sin( FHeading ) ),
                 iPos.Y + Round( aX * Sin( FHeading ) + aY * Cos( FHeading ) ) );
  end;
begin
  iPos := Lerp( FStart, FStop, Min( FTime / FDuration, 1.0 ) );
  if FRotated then
  begin
    iTile := TGLVec2f.CreateModDiv( FTile - 1, FGUI.Sprites.RowSize );
    iTex.Init( iTile * FGUI.Sprites.TexUnit, ( iTile + GLVec2f( 1, 24/32 ) ) * FGUI.Sprites.TexUnit );
    iPos := iPos + GLVec3i( 12, 16, 0 );
    iSize.Init( Round( FSize.X * FZoom ) div 2, Round( FSize.Y * FZoom ) div 2 );
    iCoord := TGLRawQCoord.Create(
      Rotated( -iSize.X, -iSize.Y ), Rotated( -iSize.X, iSize.Y ),
      Rotated( iSize.X, iSize.Y ), Rotated( iSize.X, -iSize.Y ) );
    FGUI.Sprites.Push( @iCoord, @iTex, @FColor, ColorZero, ColorZero, ColorZero, GMODE_EFFECT_Z );
  end
  else FGUI.DrawSprite( FTile, iPos, FSize, FColor, FFlip, FZoom );
end;

{ TGLExplAnimation }

constructor TGLExplAnimation.Create( aGUI : TBerserkGUI; aDuration: DWord; aDelay: DWord;
    const aPosition: TCoord2D; const aSize: TGLVec2i; const aColor: TGLVec4f);
begin
  inherited Create( aGUI, aDuration, aDelay, 0, 0, aSize, aColor, False );
  FPosition := FGUI.ToAbsPos( aPosition, GMODE_EFFECT_Z ) + GLVec3i( 12, 16 );
  FSize.X   := FSize.X div 2;
  FSize.Y   := FSize.Y div 2;
end;

procedure TGLExplAnimation.OnDraw;
var iPos : TGLVec2i;
    iStep : Byte;
begin
  iStep := Clamp( Floor( Min( FTime / FDuration, 1.0 ) * 6 ) + 1, 1, 6 );
  iPos.Init( FPosition.X, FPosition.Y );
  FGUI.Sprites.PushPart( 81 + 2*iStep, iPos - FSize, iPos + FSize, @FColor,
    ColorZero, ColorZero, ColorZero, GMODE_EFFECT_Z, GLVec2f(), GLVec2f( 48/24, 48/32 ) );
end;

{ TGLBlinkAnimation }

constructor TGLBlinkAnimation.Create( aGUI : TBerserkGUI; aDuration : DWord; aDelay : DWord; const aColor : TGLVec4f );
begin
  inherited Create( aDuration, aDelay, 0 );
  FGUI   := aGUI;
  FColor := aColor;
  FBlocking := False;
end;

procedure TGLBlinkAnimation.OnDraw;
begin
  FGUI.RenderBlink( FColor );
end;

end.
