{$INCLUDE brinclude.inc}
unit brdisplay;
interface

uses viotypes, brconfiguration;

const DISPLAY_WIDTH = 640;
      DISPLAY_HEIGHT = 360;
      DISPLAY_CELL_WIDTH = 8;
      DISPLAY_LINE_SPACING = 0;
      DISPLAY_CELL_HEIGHT = 14 + DISPLAY_LINE_SPACING;
      DISPLAY_MAP_COLUMNS = 50;
      DISPLAY_TILE_SIZE = 24;

type TBerserkDisplaySettings = object
       Width, Height, FontMultiplier, SpriteMultiplier : Integer;
       Fullscreen : Boolean;
       function Valid : Boolean;
       procedure Read( aConfiguration : TBerserkConfiguration );
       procedure Write( aConfiguration : TBerserkConfiguration );
     end;

     TBerserkDisplayLayout = object
       Width, Height, FontScale, SpriteScale, Left, Top : Integer;
       function Calculate( aWidth, aHeight, aFontRequested, aSpriteRequested : Integer ) : Boolean;
       function MapPixels : TIOPoint;
       function CameraFor( aPosition, aMapSize : TIOPoint ) : TIOPoint;
       function WindowToConsole( aPoint, aWindowSize : TIOPoint ) : TIOPoint;
       function ConsoleToWindow( aPoint, aWindowSize : TIOPoint ) : TIOPoint;
     end;

implementation

uses Math, vutil;

function TBerserkDisplaySettings.Valid : Boolean;
begin
  Result := ( ( ( Width = 0 ) and ( Height = 0 ) ) or
            ( ( Width >= DISPLAY_WIDTH ) and ( Width <= 16384 ) and
              ( Height >= DISPLAY_HEIGHT ) and ( Height <= 16384 ) ) ) and
            ( FontMultiplier >= 0 ) and ( SpriteMultiplier >= 0 );
end;

procedure TBerserkDisplaySettings.Read( aConfiguration : TBerserkConfiguration );
var iMultiplier : Integer;
begin
  iMultiplier := aConfiguration.GetInteger( 'window_multiplier' );
  Width := -1;
  Height := -1;
  if ( iMultiplier >= 0 ) and ( iMultiplier <= 25 ) then
  begin
    Width := DISPLAY_WIDTH * iMultiplier;
    Height := DISPLAY_HEIGHT * iMultiplier;
  end;
  FontMultiplier := aConfiguration.GetInteger( 'scale_multiplier' );
  SpriteMultiplier := aConfiguration.GetInteger( 'sprite_multiplier' );
  Fullscreen := aConfiguration.GetBoolean( 'fullscreen' );
end;

procedure TBerserkDisplaySettings.Write( aConfiguration : TBerserkConfiguration );
begin
  aConfiguration.AccessInteger( 'window_multiplier' )^ := Width div DISPLAY_WIDTH;
  aConfiguration.AccessInteger( 'scale_multiplier' )^ := FontMultiplier;
  aConfiguration.AccessInteger( 'sprite_multiplier' )^ := SpriteMultiplier;
  aConfiguration.AccessBoolean( 'fullscreen' )^ := Fullscreen;
end;

function TBerserkDisplayLayout.Calculate( aWidth, aHeight, aFontRequested, aSpriteRequested : Integer ) : Boolean;
var iMaximum : Integer;
    iMap : TIOPoint;
begin
  Result := False;
  if ( aWidth < DISPLAY_WIDTH ) or ( aHeight < DISPLAY_HEIGHT ) or
     ( aFontRequested < 0 ) or ( aSpriteRequested < 0 ) then Exit;
  iMaximum := Min( aWidth div DISPLAY_WIDTH, aHeight div DISPLAY_HEIGHT );
  Width := aWidth;
  Height := aHeight;
  FontScale := iMaximum;
  if aFontRequested > 0 then FontScale := Min( aFontRequested, iMaximum );
  Left := ( Width - DISPLAY_WIDTH * FontScale ) div 2;
  Top := ( Height - DISPLAY_HEIGHT * FontScale ) div 2;
  SpriteScale := aSpriteRequested;
  if SpriteScale = 0 then
  begin
    SpriteScale := Max( 1, Min( Width div 960, Height div 540 ) );
    if ( Width >= 2560 ) and ( Height >= 1440 ) then SpriteScale := Max( 3, SpriteScale );
  end;
  iMap := MapPixels;
  // Keep at least one complete tall sprite visible, retaining the saved request.
  iMaximum := Max( 1, Min( iMap.X div DISPLAY_TILE_SIZE, iMap.Y div 32 ) );
  SpriteScale := Min( SpriteScale, iMaximum );
  Result := True;
end;

function TBerserkDisplayLayout.MapPixels : TIOPoint;
begin
  Result := Point( DISPLAY_MAP_COLUMNS * DISPLAY_CELL_WIDTH * FontScale, DISPLAY_HEIGHT * FontScale );
end;

function TBerserkDisplayLayout.CameraFor( aPosition, aMapSize : TIOPoint ) : TIOPoint;
var iView : TIOPoint;
begin
  iView := MapPixels;
  iView.X := ( iView.X + SpriteScale - 1 ) div SpriteScale;
  iView.Y := ( iView.Y + SpriteScale - 1 ) div SpriteScale;
  Result := Point(
    Min( Max( ( aPosition.X - 1 ) * DISPLAY_TILE_SIZE + DISPLAY_TILE_SIZE div 2 - iView.X div 2, 0 ),
      Max( aMapSize.X * DISPLAY_TILE_SIZE - iView.X, 0 ) ),
    Min( Max( ( aPosition.Y - 1 ) * DISPLAY_TILE_SIZE + DISPLAY_TILE_SIZE div 2 - iView.Y div 2, 0 ),
      Max( aMapSize.Y * DISPLAY_TILE_SIZE - iView.Y, 0 ) ) );
end;

function TBerserkDisplayLayout.WindowToConsole( aPoint, aWindowSize : TIOPoint ) : TIOPoint;
var iX, iY : Int64;
begin
  Result := Point( -1, -1 );
  if ( aWindowSize.X <= 0 ) or ( aWindowSize.Y <= 0 ) or ( FontScale <= 0 ) or
     ( aPoint.X < 0 ) or ( aPoint.Y < 0 ) then Exit;
  iX := Int64( aPoint.X ) * Width div aWindowSize.X - Left;
  iY := Int64( aPoint.Y ) * Height div aWindowSize.Y - Top;
  if ( iX < 0 ) or ( iY < 0 ) or
     ( iX >= 80 * DISPLAY_CELL_WIDTH * FontScale ) or ( iY >= 25 * DISPLAY_CELL_HEIGHT * FontScale ) then Exit;
  Result := Point( iX div ( DISPLAY_CELL_WIDTH * FontScale ) + 1,
                   iY div ( DISPLAY_CELL_HEIGHT * FontScale ) + 1 );
end;

function TBerserkDisplayLayout.ConsoleToWindow( aPoint, aWindowSize : TIOPoint ) : TIOPoint;
begin
  Result := Point( -1, -1 );
  if ( Width <= 0 ) or ( Height <= 0 ) or
     ( aPoint.X < 1 ) or ( aPoint.X > 80 ) or ( aPoint.Y < 1 ) or ( aPoint.Y > 25 ) then Exit;
  // Cell centers round-trip through window-coordinate/DPI quantization.
  Result := Point(
    Int64( Left + ( ( aPoint.X - 1 ) * DISPLAY_CELL_WIDTH + DISPLAY_CELL_WIDTH div 2 ) * FontScale ) * aWindowSize.X div Width,
    Int64( Top + ( ( aPoint.Y - 1 ) * DISPLAY_CELL_HEIGHT + DISPLAY_CELL_HEIGHT div 2 ) * FontScale ) * aWindowSize.Y div Height );
end;

end.
