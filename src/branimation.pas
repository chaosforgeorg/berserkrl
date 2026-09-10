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
     vutil, vrltools, vgenerics, vgltypes, vanimation,
     brdata, brbeing;

type

{ TGLTileAnimation }

TGLTileAnimation = class( TAnimation )
  constructor Create( aDuration : DWord; aDelay : DWord; aUID : TUID; aTile : Word; const aSize : TGLVec2i; const aColor : TGLVec4f; aFlip : Boolean );
  procedure OnStart; override;
  destructor Destroy; override;
protected
  procedure DrawTile( const aPos : TGLVec3i );
protected
  FTile  : Word;
  FSize  : TGLVec2i;
  FColor : TGLRawQColor;
  FFlip  : Boolean;
end;


{ TGLMoveAnimation }

TGLMoveAnimation = class( TGLTileAnimation )
  constructor Create( aDuration : DWord; aDelay : DWord; aBeing : TBeing; const aFrom, aTo : TCoord2D );
  procedure OnDraw; override;
private
  FStart : TGLVec3i;
  FStop  : TGLVec3i;
end;

{ TGLAttackAnimation }

TGLAttackAnimation = class( TGLTileAnimation )
  constructor Create( aDuration : DWord; aDelay : DWord; aBeing : TBeing; const aFrom, aTo : TCoord2D );
  procedure OnDraw; override;
private
  FStart : TGLVec3i;
  FStop  : TGLVec3i;
end;

{ TGLMarkAnimation }

TGLMarkAnimation = class( TGLTileAnimation )
  constructor Create( aDuration : DWord; aDelay : DWord; aTile : Word; const aPosition : TGLVec3i; const aSize : TGLVec2i; const aColor : TGLVec4f; aFlip : Boolean );
  procedure OnDraw; override;
private
  FPosition : TGLVec3i;
end;

{ TGLScreenMoveAnimation }

TGLScreenMoveAnimation = class( TAnimation )
  constructor Create( aDuration : DWord; aDelay : DWord; aUID : TUID; const aFrom, aTo : TCoord2D );
  procedure OnUpdate( aTime : DWord ); override;
private
  FStart : TCoord2D;
  FStop  : TCoord2D;
end;

{ TGLMissileAnimation }

TGLMissileAnimation = class( TGLTileAnimation )
  constructor Create( aDuration : DWord; aDelay : DWord; aTile : Word; aUID : TUID; const aFrom, aTo : TCoord2D; const aSize : TGLVec2i; const aColor : TGLVec4f; aRotated : Boolean; aZoom : Single );
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
  constructor Create( aDuration : DWord; aDelay : DWord; const aPosition : TCoord2D; const aSize : TGLVec2i; const aColor : TGLVec4f );
  procedure OnDraw; override;
private
  FPosition : TGLVec3i;
end;

{ TGLBlinkAnimation }

TGLBlinkAnimation = class( TAnimation )
  constructor Create( aDuration : DWord; aDelay : DWord; const aColor : TGLVec4f );
  procedure OnDraw; override;
private
  FColor : TGLVec4f;
end;

{ TSoundAnimation }

TSoundAnimation = class( TAnimation )
  constructor Create( aDelay : DWord; aPosition : TCoord2D; const aSoundID : AnsiString );
  procedure OnStart; override;
private
  FPosition : TCoord2D;
  FSoundID  : AnsiString;
end;



implementation

uses vmath, math, vcolor, vsound, vdebug, vuid, brplayer, brgui;

{ TSoundAnimation }

constructor TSoundAnimation.Create(aDelay: DWord; aPosition: TCoord2D;  const aSoundID: AnsiString);
begin
  inherited Create( 1, aDelay, 0 );
  FPosition := aPosition;
  FSoundID  := aSoundID;
end;

procedure TSoundAnimation.OnStart;
begin
  if Assigned( Sound ) and Sound.SampleExists( FSoundID ) then
    Sound.PlaySample( FSoundID, FPosition );
end;

{ TGLTileAnimation }

constructor TGLTileAnimation.Create(aDuration: DWord; aDelay: DWord;
  aUID: TUID; aTile: Word; const aSize: TGLVec2i; const aColor: TGLVec4f;
  aFlip: Boolean);
var iColor : TGLVec3b;
    i : Integer;
begin
  inherited Create( aDuration, aDelay, aUID );
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
    iBeing := UIDs.Get( FUID ) as TBeing;
    if iBeing <> nil then
      Inc( iBeing.FVisual.AnimCount );
  end;
end;

destructor TGLTileAnimation.Destroy;
var iBeing : TBeing;
begin
  if FUID <> 0 then
  begin
    iBeing := UIDs.Get( FUID ) as TBeing;
    if iBeing <> nil then
      Dec( iBeing.FVisual.AnimCount );
    FUID := 0;
  end;
  inherited Destroy;
end;

procedure TGLTileAnimation.DrawTile( const aPos: TGLVec3i );
begin
  GUI.DrawSprite( FTile, aPos, FSize, FColor, FFlip );
end;

{ TGLMoveAnimation }

constructor TGLMoveAnimation.Create(aDuration: DWord; aDelay: DWord; aBeing : TBeing; const aFrom, aTo : TCoord2D );
var iColor : TGLVec4f;
    iZ     : Integer;
begin
  if not Player.isBerserk
    then iColor.Init( 1.0*aBeing.FVisual.Overlay[1], 1.0*aBeing.FVisual.Overlay[2], 1.0*aBeing.FVisual.Overlay[3], 1.0 )
    else iColor.Init( 1.0, 0.3, 0.3, 1.0 );

  inherited Create( aDuration, aDelay, aBeing.UID, aBeing.FVisual.Sprite,
    GLVec2i( IIf( aBeing.Flags[ SF_BIG ], 32, 24 ), 32 ), iColor, not aBeing.FVisual.Mirror
  );

  iZ     := Max( aFrom.Y * GMODE_STEP_Z + 1, aTo.Y * GMODE_STEP_Z + 1 );
  FStart := GUI.ToAbsPos( aFrom, iZ );
  FStop  := GUI.ToAbsPos( aTo, iZ );
end;

procedure TGLMoveAnimation.OnDraw;
begin
  GUI.DrawSprite( FTile, Lerp( FStart, FStop, Min( FTime / FDuration, 1.0 ) ), FSize, FColor, FFlip, 1.1 );
end;

{ TGLAttackAnimation }

constructor TGLAttackAnimation.Create(aDuration: DWord; aDelay: DWord; aBeing: TBeing; const aFrom, aTo: TCoord2D);
var iColor : TGLVec4f;
    iZ     : Integer;
begin
  if not Player.isBerserk
    then iColor.Init( 1.0*aBeing.FVisual.Overlay[1], 1.0*aBeing.FVisual.Overlay[2], 1.0*aBeing.FVisual.Overlay[3], 1.0 )
    else iColor.Init( 1.0, 0.3, 0.3, 1.0 );

  inherited Create( aDuration, aDelay, aBeing.UID, aBeing.FVisual.Sprite,
    GLVec2i( IIf( aBeing.Flags[ SF_BIG ], 32, 24 ), 32 ), iColor, not aBeing.FVisual.Mirror
  );

  iZ     := Max( aFrom.Y * GMODE_STEP_Z + 1, aTo.Y * GMODE_STEP_Z + 1 );
  FStart := GUI.ToAbsPos( aFrom, iZ );
  FStop  := GUI.ToAbsPos( aTo, iZ );
end;

procedure TGLAttackAnimation.OnDraw;
var iValue : Single;
begin
  iValue := 0.5 - Abs( Min( FTime / FDuration, 1.0 ) - 0.5 );
  GUI.DrawSprite( FTile, Lerp( FStart, FStop, iValue ), FSize, FColor, FFlip, 1.2 );
end;

{ TGLMarkAnimation }

constructor TGLMarkAnimation.Create(aDuration: DWord; aDelay: DWord; aTile: Word; const aPosition : TGLVec3i; const aSize: TGLVec2i; const aColor: TGLVec4f; aFlip: Boolean);
begin
  inherited Create( aDuration, aDelay, 0, aTile, aSize, aColor, aFlip );
  FPosition := aPosition;
end;

procedure TGLMarkAnimation.OnDraw;
begin
  GUI.DrawSprite( FTile, FPosition, FSize, FColor, FFlip, 1.3 );
end;

{ TGLScreenMoveAnimation }

constructor TGLScreenMoveAnimation.Create( aDuration: DWord; aDelay: DWord; aUID : TUID; const aFrom, aTo: TCoord2D );
begin
  inherited Create( aDuration, aDelay, aUID );
  FStart := aFrom;
  FStop := aTo;
end;

procedure TGLScreenMoveAnimation.OnUpdate(aTime: DWord);
begin
  inherited OnUpdate(aTime);
  if (FStart <> FStop) and (FTime > 0) then
    GUI.SpriteEngine.Position := Lerp( GUI.CameraFor( FStart ), GUI.CameraFor( FStop ), Min( FTime / FDuration, 1.0 ) );
end;

{ TGLMissileAnimation }

constructor TGLMissileAnimation.Create(aDuration: DWord; aDelay: DWord;
  aTile: Word; aUID : TUID; const aFrom, aTo: TCoord2D; const aSize: TGLVec2i;
  const aColor: TGLVec4f; aRotated : Boolean; aZoom: Single);
begin
  inherited Create( aDuration, aDelay, aUID, aTile, aSize, aColor, False );
  FStart   := GUI.ToAbsPos( aFrom, GMODE_EFFECT_Z );
  FStop    := GUI.ToAbsPos( aTo, GMODE_EFFECT_Z ) + GLVec3i(
    GUI.VisualRNG.RLongInt(21) - 10, GUI.VisualRNG.RLongInt(21) - 10, 0 );
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
    iTile := TGLVec2f.CreateModDiv( FTile - 1, GUI.Sprites.RowSize );
    iTex.Init( iTile * GUI.Sprites.TexUnit, ( iTile + GLVec2f( 1, 24/32 ) ) * GUI.Sprites.TexUnit );
    iPos := iPos + GLVec3i( 12, 16, 0 );
    iSize.Init( Round( FSize.X * FZoom ) div 2, Round( FSize.Y * FZoom ) div 2 );
    iCoord := TGLRawQCoord.Create(
      Rotated( -iSize.X, -iSize.Y ), Rotated( -iSize.X, iSize.Y ),
      Rotated( iSize.X, iSize.Y ), Rotated( iSize.X, -iSize.Y ) );
    GUI.Sprites.Push( @iCoord, @iTex, @FColor, ColorZero, ColorZero, ColorZero, GMODE_EFFECT_Z );
  end
  else GUI.DrawSprite( FTile, iPos, FSize, FColor, FFlip, FZoom );
end;

{ TGLExplAnimation }

constructor TGLExplAnimation.Create(aDuration: DWord; aDelay: DWord;
    const aPosition: TCoord2D; const aSize: TGLVec2i; const aColor: TGLVec4f);
begin
  inherited Create( aDuration, aDelay, 0, 0, aSize, aColor, False );
  FPosition := GUI.ToAbsPos( aPosition, GMODE_EFFECT_Z ) + GLVec3i( 12, 16 );
  FSize.X   := FSize.X div 2;
  FSize.Y   := FSize.Y div 2;
end;

procedure TGLExplAnimation.OnDraw;
var iPos : TGLVec2i;
    iStep : Byte;
begin
  iStep := Clamp( Floor( Min( FTime / FDuration, 1.0 ) * 6 ) + 1, 1, 6 );
  iPos.Init( FPosition.X, FPosition.Y );
  GUI.Sprites.PushPart( 81 + 2*iStep, iPos - FSize, iPos + FSize, @FColor,
    ColorZero, ColorZero, ColorZero, GMODE_EFFECT_Z, GLVec2f(), GLVec2f( 48/24, 48/32 ) );
end;

{ TGLBlinkAnimation }

constructor TGLBlinkAnimation.Create( aDuration : DWord; aDelay : DWord; const aColor : TGLVec4f );
begin
  inherited Create( aDuration, aDelay, 0 );
  FColor := aColor;
  FBlocking := False;
end;

procedure TGLBlinkAnimation.OnDraw;
begin
  GUI.RenderBlink( FColor );
end;

end.
