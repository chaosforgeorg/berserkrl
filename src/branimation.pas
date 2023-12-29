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
     vutil, vrltools, vgenerics, vgltypes, vglquadbuffer, vanimation,
     brdata, brbeing;

type

{ TGLTileAnimation }

TGLTileAnimation = class( TAnimation )
  constructor Create( aDuration : DWord; aDelay : DWord; aUID : TUID; aTile : Word; const aSize : TGLVec2i; const aColor : TGLQVec4f; aFlip : Boolean );
  procedure OnStart; override;
  destructor Destroy; override;
protected
  procedure DrawTile( const aPos : TGLVec3i );
protected
  FTile  : Word;
  FSize  : TGLVec2i;
  FColor : TGLQVec4f;
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
  FStart : Integer;
  FStop  : Integer;
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

{ TGLExplAnimation }

{ TGLBlinkAnimation }

TGLBlinkAnimation = class( TAnimation )
  constructor Create( aDuration : DWord; aDelay : DWord; const aColor : TGLVec4f );
  procedure OnStart; override;
  destructor Destroy; override;
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

uses vmath, math, vsound, vdebug, vuid, brplayer, brgui;

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
  aUID: TUID; aTile: Word; const aSize: TGLVec2i; const aColor: TGLQVec4f;
  aFlip: Boolean);
begin
  inherited Create( aDuration, aDelay, aUID );
  FTile  := aTile;
  FSize  := aSize;
  FColor := aColor;
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
    GLVec2i( IIf( aBeing.Flags[ SF_BIG ], 32, 24 ), 32 ), TGLQVec4f.CreateAll( iColor ), not aBeing.FVisual.Mirror
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
    GLVec2i( IIf( aBeing.Flags[ SF_BIG ], 32, 24 ), 32 ), TGLQVec4f.CreateAll( iColor ), not aBeing.FVisual.Mirror
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
  inherited Create( aDuration, aDelay, 0, aTile, aSize, TGLQVec4f.CreateAll( aColor ), aFlip );
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
  FStart := Clamp( aFrom.x-11, 0, MAP_MAXX-21 ) * 24;
  FStop  := Clamp( aTo.x-11, 0, MAP_MAXX-21 ) * 24;
end;

procedure TGLScreenMoveAnimation.OnUpdate(aTime: DWord);
begin
  inherited OnUpdate(aTime);
  if (FStart <> FStop) and (FTime > 0) then
    GUI.Shift := Lerp( FStart, FStop, Min( FTime / FDuration, 1.0 ) );
end;

{ TGLMissileAnimation }

constructor TGLMissileAnimation.Create(aDuration: DWord; aDelay: DWord;
  aTile: Word; aUID : TUID; const aFrom, aTo: TCoord2D; const aSize: TGLVec2i;
  const aColor: TGLVec4f; aRotated : Boolean; aZoom: Single);
begin
  inherited Create( aDuration, aDelay, aUID, aTile, aSize, TGLQVec4f.CreateAll( aColor ), False );
  FStart   := GUI.ToAbsPos( aFrom, GMODE_EFFECT_Z );
  FStop    := GUI.ToAbsPos( aTo, GMODE_EFFECT_Z ) + GLVec3i( Random(21) - 10, Random(21) - 10, 0 );
  FZoom    := aZoom;
  FRotated := aRotated;
  FHeading := radtodeg(-arctan2( FStop.x - FStart.x, FStop.y - FStart.y ) + PI/2);
end;

procedure TGLMissileAnimation.OnDraw;
var iPos    : TGLVec3i;
    iT1,iT2 : TGLVec2f;
    iSize   : TGLVec2i;
begin
  iPos := Lerp( FStart, FStop, Min( FTime / FDuration, 1.0 ) );
  if FRotated then
  begin
    iT1 := GUI.GetSpritePos( FTile );
    iT2 := iT1 + GUI.GetSpriteSize( GLVec2i( 24,24 ) );
    iPos   := iPos + GLVec3i( 12, 16, 0 );
    iPos.X := iPos.X - GUI.Shift;
    iSize  := FSize;
    if FZoom <> 1.0 then
    begin
      iSize.X := Round( iSize.X * FZoom );
      iSize.Y := Round( iSize.Y * FZoom );
    end;

    GUI.Terrain.PushRotatedQuad(
        iPos, GLVec3i( iSize, GMODE_EFFECT_Z ), FHeading, FColor.Data[0],
        iT1, iT2
      );
  end
  else GUI.DrawSprite( FTile, iPos, FSize, FColor, FFlip, FZoom );
end;

{ TGLExplAnimation }

constructor TGLExplAnimation.Create(aDuration: DWord; aDelay: DWord;
    const aPosition: TCoord2D; const aSize: TGLVec2i; const aColor: TGLVec4f);
begin
  inherited Create( aDuration, aDelay, 0, 0, aSize, TGLQVec4f.CreateAll( aColor ), False );
  FPosition := GUI.ToAbsPos( aPosition, GMODE_EFFECT_Z ) + GLVec3i( 12, 16 );
  FSize.X   := FSize.X div 2;
  FSize.Y   := FSize.Y div 2;
end;

procedure TGLExplAnimation.OnDraw;
var iT1,iT2 : TGLVec2f;
    iSize   : TGLVec3i;
    iPos    : TGLVec2i;
    iStep   : Byte;
begin
  iStep  := Floor( Min( FTime / FDuration, 1.0 ) * 6 ) + 1;
  iStep  := Clamp( iStep, 1, 6 );
  iT1    := GUI.GetSpritePos( 81 + 2*iStep );
  iT2    := iT1 + GUI.GetSpriteSize( GLVec2i( 48,48 ) );
  iPos.Y := FPosition.Y;
  iPos.X := FPosition.X - GUI.Shift;
  GUI.Terrain.PushQuad(
    GLVec3i( iPos - FSize, GMODE_EFFECT_Z ), GLVec3i( iPos + FSize, GMODE_EFFECT_Z ),
    FColor,
    iT1, iT2
  );
end;

{ TGLBlinkAnimation }

constructor TGLBlinkAnimation.Create(aDuration: DWord; aDelay: DWord; const aColor: TGLVec4f);
begin
  inherited Create( aDuration, aDelay, 0 );
  FColor := aColor;
end;

procedure TGLBlinkAnimation.OnStart;
begin
  GUI.SetOverlay( FColor );
end;

destructor TGLBlinkAnimation.Destroy;
begin
  GUI.SetOverlay( GLVec4f() );
  inherited Destroy;
end;

end.

