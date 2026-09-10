// @abstract(BerserkRL -- Graphical User Interface class)
// @author(Kornel Kisielewicz <admin@chaosforge.org>)
// @created(Apr 11, 2007)
// @lastmod(Apr 11, 2007)
//
// This unit holds the graphical User Interface class of Berserk!.
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
unit brgui;
interface

uses vapp, brconfiguration, brdisplay, vioevent, SysUtils, vutil, vgenerics, vrltools, vvision, vtextures, vglimage, viotypes,
     vimage, brui, brdata, vglquadrenderer, vgltypes, vspriteengine,
     vanimation, branimation;

type

{ TBerserkGUI }

TBerserkGUI = class(TBerserkUI)
    // Initialization of all data.
    constructor Create( aConfiguration : TBerserkConfiguration; const aPaths : TGamePaths );
    procedure Reconfigure; override;
    procedure FullUpdate; override;
    procedure PreUpdate; override;
    function OnEvent( const aEvent : TIOEvent ) : Boolean; override;
    function DeviceCoordToConsoleCoord( aCoord : TIOPoint ) : TIOPoint; override;
    function ConsoleCoordToDeviceCoord( aCoord : TIOPoint ) : TIOPoint; override;
    procedure CenterCamera( const aWhere : TCoord2D ); override;
    function CameraFor( const aWhere : TCoord2D ) : TGLVec2i;
    // Sends missile
    procedure SendMissile( const aSource, aTarget : TCoord2D; aType : Byte; aSequence : DWord ); override;
    // Draws target X
    procedure Target( Coord : TCoord2D; color : Byte); override;
    // Renders an explosion on the screen.
    procedure AddExplosion( aWhere : TCoord2D; aColor : byte; aRange : byte; aStep : byte; aDrawDelay, aSequence : Word ); override;
    // Renders a breath weapon attack
    procedure Breath( aWhere : TCoord2D; aDirection : TDirection; aColor : byte; aRange : byte; aStep : byte; aDrawDelay : Word ); override;
    // Graphical effect of a screen flash, of the given color, and Duration in
    // miliseconds.
    procedure Blink( aColor : Byte; aDuration : Word; aSequence : Word ); override;
    // Animates a move if in GFX
    procedure AddMove( aWho : TUID; const aFrom, aTo : TCoord2D ); override;
    // Animates an attack if in GFX
    procedure AddAttack( aWho : TUID; aHit : Boolean; const aFrom, aTo : TCoord2D ); override;
    // Renders a nine-patch window
    procedure RenderWindow( aSize, aPos : TIOPoint ); override;
    // Draws a firey background
    procedure RenderBG(); override;
    //  update
    procedure Update( aMSec : DWord ); override;
    // Update light map
    procedure UpdateLight( aVision : TVision );
    // Draws the level, player status, messages, and updates the screen.
    procedure Draw; override;
    // destructor
    destructor Destroy; override;
    procedure Clear; override;
    function ToScreenCoord( const aCoord : TCoord2D ) : TCoord2D;
    function ToAbsPos( const aCoord : TCoord2D; aDepth : Integer ) : TGLVec3i;
    procedure DrawSprite( aTile : Word; const aAbsPos : TGLVec3i; const aSize : TGLVec2i; const aColor : TGLRawQColor; aFlip : Boolean; aZoom : Single = 1.0 );
    procedure RenderBlink( const aColor : TGLVec4f );
    private
    procedure DrawSprites;
  private
    FAppliedDisplay : TBerserkDisplaySettings;
    FLayout : TBerserkDisplayLayout;
    FWindowSize, FLastWindowSize : TIOPoint;
    FLightQVecMap: array [1..MAP_MAXX, 1..MAP_MAXY] of TGLRawQColor;
    FBackgroundQuads : TGLQuadList;
    FPreQuads    : TGLQuadList;
    FPostQuads   : TGLQuadList;
    FQuadRenderer : TGLQuadRenderer;
    FSpriteEngine : TSpriteEngine;
    FSprites     : TSpriteDataSet;
    FTarget      : TCoord2D;
    FTextures    : TTextureManager;
    FAnimations  : TAnimations;

    procedure ConfigureWindowResolutions( aConfiguration : TBerserkConfiguration );
    function Projection( aScale : Integer ) : TMatrix44;
    function ReadDisplaySize( out aWindowSize, aPixels : TIOPoint ) : Boolean;
    function RefreshDisplay( const aSettings : TBerserkDisplaySettings ) : Boolean;
    procedure SetDisplayMode( const aSettings : TBerserkDisplaySettings );
    procedure RestoreDisplay( aWindowSize : TIOPoint );
    public
    property Layout : TBerserkDisplayLayout read FLayout;
    property SpriteEngine : TSpriteEngine read FSpriteEngine;
    property Sprites : TSpriteDataSet read FSprites;
  end;

var GUI : TBerserkGUI = nil;


implementation

uses {$IFDEF WINDOWS}Windows,{$ENDIF}
     vuid, vgl3library, vsystems, vtig,
     vioconsole, vsdlio, vsdl3library, vglconsole, vlog,
     vmath, vdebug, math, vcolor,
     brbeing, brplayer, brlevel;

{ TBerserkTextures }

function TBerserkGUI.ToScreenCoord(const aCoord: TCoord2D): TCoord2D;
begin
  Result.Create( ( aCoord.X - 1 )*24 + 12,( aCoord.Y - 1 )*24 + 12 );
end;

function TBerserkGUI.ToAbsPos(const aCoord: TCoord2D; aDepth: Integer ): TGLVec3i;
begin
  Result.Init( ( aCoord.X - 1 )*24,( aCoord.Y - 1 )*24 - 8, aDepth );
end;

procedure TBerserkGUI.DrawSprite( aTile : Word; const aAbsPos : TGLVec3i; const aSize : TGLVec2i; const aColor : TGLRawQColor; aFlip : Boolean; aZoom : Single = 1.0 );
var iSize, iP1, iP2 : TGLVec2i;
    iT1, iT2 : TGLVec2f;
    iColor : TGLRawQColor;
begin
  if aTile = 0 then Exit;
  iSize.Init( Round( aSize.X * aZoom ), Round( aSize.Y * aZoom ) );
  iP1.Init( aAbsPos.X + ( ( DISPLAY_TILE_SIZE - iSize.X ) div 2 ),
    aAbsPos.Y + FSpriteEngine.TileSize.Y - iSize.Y );
  iP2 := iP1 + iSize;
  iT1.Init( 0, 0 );
  iT2.Init( aSize.X / FSpriteEngine.TileSize.X, aSize.Y / FSpriteEngine.TileSize.Y );
  if aFlip then
  begin
    iT1.X := iT2.X;
    iT2.X := 0;
  end;
  iColor := aColor;
  FSprites.PushPart( aTile, iP1, iP2, @iColor, ColorZero, ColorZero, ColorZero,
    aAbsPos.Z, iT1, iT2 );
end;

procedure TBerserkGUI.RenderBlink( const aColor : TGLVec4f );
begin
  FPostQuads.PushColoredQuad( GLVec2i(), GLVec2i( FLayout.Width, FLayout.Height ), aColor );
end;

procedure TBerserkGUI.DrawSprites;
  function  RandomSide( aTerra : Word; aCoord : TCoord2D ) : boolean;
  begin
    if TF_NOMIRROR in TerraData[aTerra].Flags then Exit( False );
    Exit(((aCoord.x+5)*(aCoord.x+3)*aCoord.y mod 193*197) mod 2 = 0);
  end;

var iColor4     : TGLRawQColor;
    iColor      : TGLVec3b;
    iSSquare    : TGLVec2i;
    iSTall      : TGLVec2i;
    iSBig       : TGLVec2i;
    iSize       : TGLVec2i;
    iCoord      : TCoord2D;
    iCount      : Integer;
    iDepth      : Word;
    iTerrain    : Word;
    iTerrainB   : Word;
    iRotation   : Byte;
    iMin, iMax  : TCoord2D;
    iView       : TIOPoint;

begin
  iView := FLayout.MapPixels;
  iMin.Create( Max( FSpriteEngine.Position.X div 24, 1 ), Max( FSpriteEngine.Position.Y div 24, 1 ) );
  iMax.Create( Min( ( FSpriteEngine.Position.X + iView.X div FLayout.SpriteScale ) div 24 + 2, MAP_MAXX ),
    Min( ( FSpriteEngine.Position.Y + iView.Y div FLayout.SpriteScale ) div 24 + 2, MAP_MAXY ) );

  iSSquare.Init( 24, 24 );
  iSTall.Init( 24, 32 );
  iSBig.Init( 32, 32 );

  for iCoord in NewArea( iMin, iMax ) do
  begin
    iDepth   := iCoord.Y * GMODE_STEP_Z;
    iTerrain := Level.GetCell( iCoord );
    iColor4  := FLightQVecMap[ iCoord.x, iCoord.y ];
    if Player.isBerserk then
      for iCount := 0 to 3 do
      begin
        iColor4.Data[ iCount ].Data[ 1 ] := 26;
        iColor4.Data[ iCount ].Data[ 2 ] := 26;
      end;

    with Level.FMap[iCoord.X,iCoord.Y] do
    begin
      iTerrainB := TerrainB;
      iRotation := Rotation;
    end;

    if TerraData[iTerrain].SpriteB <> 0 then
    begin
      if SF_TALLBASE in TerraData[iTerrain].Flags
        then DrawSprite( TerraData[iTerrain].SpriteB, ToAbsPos( iCoord, iDepth ), iSTall,   iColor4, RandomSide( iTerrain, iCoord ) )
        else DrawSprite( TerraData[iTerrain].SpriteB, ToAbsPos( iCoord, 0 ),      iSSquare, iColor4, RandomSide( iTerrain, iCoord ) );
    end
    else
    begin
      if TerraData[iTerrainB].SpriteB <> 0
        then DrawSprite( TerraData[iTerrainB].SpriteB, ToAbsPos( iCoord, 0 ), iSSquare, iColor4, RandomSide( iTerrainB, iCoord ) )
        else DrawSprite( Level.sprite_base,            ToAbsPos( iCoord, 0 ), iSSquare, iColor4, RandomSide( 1,         iCoord ) );
    end;

    if TerraData[iTerrain].Sprite <> 0 then
      DrawSprite( TerraData[iTerrain].Sprite, ToAbsPos( iCoord, iDepth ), iSTall, iColor4, RandomSide( iTerrain, iCoord ) );
    if iRotation > 0 then
      DrawSprite( Level.sprite_base + iRotation, ToAbsPos( iCoord, 1 ), iSSquare, iColor4, False);
    with Level do
      if Vision.getLight( iCoord ) > 0 then
        if (Being[ iCoord ] <> nil) and (Being[ iCoord ].FVisual.AnimCount = 0) then
        with Being[ iCoord ] do
        begin
          if not Player.isBerserk then
            for iCount := 0 to 2 do
              iColor.Data[iCount] := Clamp( Round( 255 * FVisual.Overlay[iCount + 1] ), 0, 255 )
          else iColor.Init( 255, 76, 76 );
          iSize := iStall;
          if Flags[ SF_BIG ] then iSize := iSBig;
          iColor4.SetAll( iColor );
          DrawSprite( FVisual.Sprite, ToAbsPos( iCoord, iDepth ), iSize, iColor4, not FVisual.Mirror );
        end;
  end;
          
  iColor4.FillAll( 255 );
  if FTarget.X <> 0 then
    DrawSprite( 30, ToAbsPos( FTarget, GMODE_GUI_Z ), iSTall, iColor4, False );
end;

{ TBreserkGUI }

constructor TBerserkGUI.Create( aConfiguration : TBerserkConfiguration; const aPaths : TGamePaths );
var iFlags : TSDLIOFlags;
begin
  {$IFDEF WINDOWS}
  if not GodMode then
    FreeConsole
  else
  begin
    Logger.AddSink( TConsoleLogSink.Create( LOGDEBUG, true ) );
  end;
  {$ENDIF}

  ConfigureWindowResolutions( aConfiguration );
  FAppliedDisplay.Read( aConfiguration );
  if not FAppliedDisplay.Valid then
    raise EIOException.Create( 'Invalid display settings: use a listed resolution and nonnegative multipliers. Use --console to change them.' );
  iFlags := [ SDLIO_OpenGL ];
  if FAppliedDisplay.Fullscreen or aConfiguration.FullScreenOverride then Include( iFlags, SDLIO_DesktopFullScreen );
  FIODriver := TSDLIODriver.Create( FAppliedDisplay.Width, FAppliedDisplay.Height, 32, iFlags );
  if not SDL_SyncWindow( TSDLIODriver( FIODriver ).NativeWindow ) then
    raise EIOException.Create( 'Could not initialize display: ' + SDL_GetError() + '. Use --console.' );
  if not SDL_GetWindowSize( TSDLIODriver( FIODriver ).NativeWindow, @FLastWindowSize.X, @FLastWindowSize.Y ) then
    raise EIOException.Create( 'Could not read initial window size: ' + SDL_GetError() );

  FTextures := TTextureManager.Create( False );
  FTextures.LoadTextureFolder(aPaths.DataPath+'graphics');
  FTextures.Upload;
  FConsole := TGLConsoleRenderer.Create( aPaths.DataPath+'ter_font8x14.png', 32, 256-32, 32, 80, 25, DISPLAY_LINE_SPACING, [VIO_CON_CURSOR] );
  FConsole.HideCursor;

  FSpriteEngine := TSpriteEngine.Create( GLVec2i( 24, 32 ) );
  FSprites := FSpriteEngine.Layers[ FSpriteEngine.Add( FTextures.Textures['spritesheet'], nil, nil, nil, 0 ) ];
  FQuadRenderer := TGLQuadRenderer.Create;
  FBackgroundQuads := TGLQuadList.Create;
  FPreQuads := TGLQuadList.Create;
  FPostQuads := TGLQuadList.Create;

  inherited Create( aConfiguration );
  GUI := Self;

  FTarget.Create( 0,0 );

  FAnimations  := TAnimations.Create;
end;

procedure TBerserkGUI.ConfigureWindowResolutions( aConfiguration : TBerserkConfiguration );
var iMaximum, i : Integer;
    iNames : array of AnsiString;
    iNativeSize, iUsableSize : TIOPoint;
    iBounds : SDL_Rect;
begin
  if not TSDLIODriver.GetCurrentResolution( iNativeSize ) then
    raise EIOException.Create( 'Could not read native display size. Use --console.' );
  iUsableSize := iNativeSize;
  if SDL_GetDisplayUsableBounds( SDL_GetPrimaryDisplay(), @iBounds ) then
    iUsableSize := vutil.Point( iBounds.w, iBounds.h );
  // Native stays separate; every numbered choice is a smaller 640x360 multiple.
  iMaximum := Max( 0, Min( 25, Min(
    Min( ( iNativeSize.X - 1 ) div DISPLAY_WIDTH, ( iNativeSize.Y - 1 ) div DISPLAY_HEIGHT ),
    Min( iUsableSize.X div DISPLAY_WIDTH, iUsableSize.Y div DISPLAY_HEIGHT ) ) ) );
  SetLength( iNames, iMaximum + 1 );
  iNames[0] := 'Native';
  for i := 1 to iMaximum do
    iNames[i] := IntToStr( DISPLAY_WIDTH * i ) + 'x' + IntToStr( DISPLAY_HEIGHT * i );
  with aConfiguration.CastInteger( 'window_multiplier' ) do
  begin
    SetRange( 0, iMaximum ).SetNames( iNames );
    // A saved window from a larger monitor falls back to this desktop's Native.
    if ( Value < 0 ) or ( Value > iMaximum ) then Value := 0;
  end;
end;

function TBerserkGUI.ReadDisplaySize( out aWindowSize, aPixels : TIOPoint ) : Boolean;
var iWindow : PSDL_Window;
begin
  iWindow := TSDLIODriver( FIODriver ).NativeWindow;
  Result := False;
  if SDL_GetWindowFlags( iWindow ) and SDL_WINDOW_MINIMIZED <> 0 then Exit;
  if not SDL_GetWindowSize( iWindow, @aWindowSize.X, @aWindowSize.Y ) or
     not SDL_GetWindowSizeInPixels( iWindow, @aPixels.X, @aPixels.Y ) then
    raise EIOException.Create( 'Could not read display size: ' + SDL_GetError() );
  Result := ( aWindowSize.X > 0 ) and ( aWindowSize.Y > 0 ) and
            ( aPixels.X > 0 ) and ( aPixels.Y > 0 );
end;

procedure TBerserkGUI.SetDisplayMode( const aSettings : TBerserkDisplaySettings );
var iFlags : TSDLIOFlags;
    iWindow : PSDL_Window;
    iFullscreen : Boolean;
begin
  iWindow := TSDLIODriver( FIODriver ).NativeWindow;
  iFullscreen := aSettings.Fullscreen or FConfiguration.FullScreenOverride;
  iFlags := [ SDLIO_OpenGL ];
  if iFullscreen then Include( iFlags, SDLIO_DesktopFullScreen )
  else if SDL_GetWindowFlags( iWindow ) and SDL_WINDOW_MAXIMIZED <> 0 then
    if not SDL_RestoreWindow( iWindow ) then
      raise EIOException.Create( 'Could not restore window: ' + SDL_GetError() );
  if not TSDLIODriver( FIODriver ).ResetVideoMode( aSettings.Width, aSettings.Height, 32, iFlags ) or
     not SDL_SyncWindow( iWindow ) then
    raise EIOException.Create( 'Could not change display mode: ' + SDL_GetError() );
  if ( SDL_GetWindowFlags( iWindow ) and SDL_WINDOW_FULLSCREEN <> 0 ) <> iFullscreen then
    raise EIOException.Create( 'The window system did not accept the display mode.' );
end;

function TBerserkGUI.RefreshDisplay( const aSettings : TBerserkDisplaySettings ) : Boolean;
var iWindowSize, iPixels, iMouse : TIOPoint;
    iLayout : TBerserkDisplayLayout;
begin
  Result := ReadDisplaySize( iWindowSize, iPixels );
  if not Result then Exit;
  if not iLayout.Calculate( iPixels.X, iPixels.Y, aSettings.FontMultiplier, aSettings.SpriteMultiplier ) then
    raise EIOException.Create( 'The drawable must fit 640x360 pixels. Use --console if this display cannot fit x1.' );
  FWindowSize := iWindowSize;
  if not TSDLIODriver( FIODriver ).FullScreen then FLastWindowSize := iWindowSize;
  if ( FLayout.Width = iLayout.Width ) and
     ( FLayout.Height = iLayout.Height ) and ( FLayout.FontScale = iLayout.FontScale ) and
     ( FLayout.SpriteScale = iLayout.SpriteScale ) then Exit;
  FLayout := iLayout;
  if FIODriver.GetMousePos( iMouse ) then
    FMouse := FLayout.WindowToConsole( iMouse, FWindowSize );
  TGLConsoleRenderer( FConsole ).SetPositionScale( FLayout.Left, FLayout.Top, DISPLAY_LINE_SPACING,
    FLayout.FontScale, vutil.Point( FLayout.Width, FLayout.Height ) );
  if FPlayer <> nil then CenterCamera( FPlayer.Position );
end;

function TBerserkGUI.CameraFor( const aWhere : TCoord2D ) : TGLVec2i;
var iCamera : TIOPoint;
begin
  iCamera := FLayout.CameraFor( vutil.Point( aWhere.X, aWhere.Y ), vutil.Point( MAP_MAXX, MAP_MAXY ) );
  Result.Init( iCamera.X, iCamera.Y );
end;

procedure TBerserkGUI.CenterCamera( const aWhere : TCoord2D );
begin
  FSpriteEngine.Position := CameraFor( aWhere );
end;

function TBerserkGUI.Projection( aScale : Integer ) : TMatrix44;
begin
  Result := GLCreateOrtho( -FLayout.Left / aScale,
    ( FLayout.Width - FLayout.Left ) / aScale,
    ( FLayout.Height - FLayout.Top ) / aScale,
    -FLayout.Top / aScale, -1000, 1000 );
end;

procedure TBerserkGUI.RestoreDisplay( aWindowSize : TIOPoint );
var iPrevious : TBerserkDisplaySettings;
begin
  iPrevious := FAppliedDisplay;
  iPrevious.Width := aWindowSize.X;
  iPrevious.Height := aWindowSize.Y;
  SetDisplayMode( iPrevious );
  RefreshDisplay( FAppliedDisplay );
end;

procedure TBerserkGUI.Reconfigure;
var iSettings : TBerserkDisplaySettings;
    iPreviousSize : TIOPoint;
    iResize, iModeChange, iAttempted : Boolean;
    iError : AnsiString;
begin
  iSettings.Read( FConfiguration );
  iPreviousSize := FLastWindowSize;
  iAttempted := False;
  try
    if not iSettings.Valid then
      raise EIOException.Create( 'Choose a listed window resolution and nonnegative multipliers (0 = Automatic).' );
    iResize := ( iSettings.Width <> FAppliedDisplay.Width ) or ( iSettings.Height <> FAppliedDisplay.Height );
    iModeChange := ( iSettings.Fullscreen or FConfiguration.FullScreenOverride ) <>
      TSDLIODriver( FIODriver ).FullScreen;
    if iModeChange or ( iResize and not ( iSettings.Fullscreen or FConfiguration.FullScreenOverride ) ) then
    begin
      iAttempted := True;
      SetDisplayMode( iSettings );
    end;
    if not RefreshDisplay( iSettings ) then
      raise EIOException.Create( 'Restore the window before applying display changes.' );
    if iResize and ( iSettings.Width > 0 ) and not ( iSettings.Fullscreen or FConfiguration.FullScreenOverride ) and
       ( ( FWindowSize.X <> iSettings.Width ) or ( FWindowSize.Y <> iSettings.Height ) ) then
      raise EIOException.Create( 'The window system did not accept the requested window size.' );
    FAppliedDisplay := iSettings;
    FAppliedDisplay.Write( FConfiguration );
  except
    on E : Exception do
    begin
      iError := E.Message;
      FAppliedDisplay.Write( FConfiguration );
      if iAttempted then
        try
          RestoreDisplay( iPreviousSize );
        except
          on R : Exception do
            raise EIOException.Create( iError + ' Could not restore display: ' + R.Message );
        end;
      raise EIOException.Create( iError );
    end;
  end;
  inherited Reconfigure;
end;

procedure TBerserkGUI.FullUpdate;
var iError : AnsiString;
    iPreviousSize : TIOPoint;
begin
  iPreviousSize := FLastWindowSize;
  try
    // Refresh once before starting a frame, including after DPI changes.
    if not RefreshDisplay( FAppliedDisplay ) then
    begin
      FLastUpdate := FIODriver.GetMs;
      Exit;
    end;
  except
    on E : Exception do
    begin
      iError := E.Message;
      RestoreDisplay( iPreviousSize );
      ShowSettingsError( iError );
    end;
  end;
  inherited FullUpdate;
end;

procedure TBerserkGUI.PreUpdate;
begin
  inherited PreUpdate;
  glViewport( 0, 0, FLayout.Width, FLayout.Height );
  glScissor( FLayout.Left, FLayout.Height - FLayout.Top - DISPLAY_HEIGHT * FLayout.FontScale,
    DISPLAY_WIDTH * FLayout.FontScale, DISPLAY_HEIGHT * FLayout.FontScale );
  glEnable( GL_SCISSOR_TEST );
end;

function TBerserkGUI.DeviceCoordToConsoleCoord( aCoord : TIOPoint ) : TIOPoint;
begin
  Result := FLayout.WindowToConsole( aCoord, FWindowSize );
end;

function TBerserkGUI.ConsoleCoordToDeviceCoord( aCoord : TIOPoint ) : TIOPoint;
begin
  Result := FLayout.ConsoleToWindow( aCoord, FWindowSize );
end;

function TBerserkGUI.OnEvent( const aEvent : TIOEvent ) : Boolean;
begin
  if aEvent.EType in [ VEVENT_MOUSEDOWN, VEVENT_MOUSEUP ] then
    if DeviceCoordToConsoleCoord( aEvent.Mouse.Pos ).X < 0 then Exit( True );
  Result := inherited OnEvent( aEvent );
end;

procedure TBerserkGUI.SendMissile( const aSource, aTarget : TCoord2D; aType : Byte; aSequence : DWord );
var iDist      : Integer;
    iFull      : Integer;
    iVelocity  : Single;
    iColor     : TGLVec4f;
begin
  iColor.Init(0.7,0.7,0.7,1.0);
  iVelocity  := 1.0;
  case aType of
    MTBOLT   : iVelocity := 2.0;
    MTENERGY : iColor.Init(0.6,0.6,1.0,1.0);
    MTICE    : iColor.Init(0.9,0.9,1.0,1.0);
    MTBOMB   : begin iColor.Init(0.6,0.3,0.0,1.0); iVelocity := 0.5; end;
    MTSPORE  : begin iColor.Init(0.3,1.0,0.3,1.0); iVelocity := 0.3; end;
  end;

  iDist := Max( Round( RealDistance( ToScreenCoord( aSource ), ToScreenCoord( aTarget ) ) ), 1 );
  iFull := Max( Round( iDist / iVelocity ), 1);

  if (aType <> MTENERGY) and (aType <> MTICE) then
  begin
    FAnimations.AddAnimation( TGLMissileAnimation.Create(
      iFull, aSequence, 113, 0,
      aSource, aTarget, GLVec2i(24,2), iColor, True, 1.0
    ) );
  end
  else
  begin
    FAnimations.AddAnimation( TGLMissileAnimation.Create(
      iFull, aSequence, 113, 0,
      aSource, aTarget, GLVec2i(24,24), iColor, False, 0.5
    ) );
  end;

  FTarget.Create(0,0);
end;

procedure TBerserkGUI.Target( Coord : TCoord2D; color : Byte);
begin
  FTarget := Coord;
end;

procedure TBerserkGUI.AddExplosion( aWhere : TCoord2D; aColor : byte; aRange : byte; aStep : byte; aDrawDelay, aSequence : Word );
var iGLColor : TGLVec4f;
begin
  iGLColor.Init(1.0,1.0,1.0,1.0);
  case aColor of
    Blue    : iGLColor.Init(0.5,0.5,1.0,1.0);
    Magenta : iGLColor.Init(1.0,0.5,1.0,1.0);
    Green   : iGLColor.Init(0.5,1.0,0.5,1.0);
    LightRed: iGLColor.Init(1.2,1.2,1.2,1.0);
  end;

  FAnimations.AddAnimation( TGLExplAnimation.Create( aDrawDelay * aRange, aSequence, aWhere, GLVec2i( 24*aRange, 24*aRange ), iGLColor ) );
end;

procedure TBerserkGUI.Breath( aWhere : TCoord2D; aDirection : TDirection; aColor : byte;
  aRange : byte; aStep : byte; aDrawDelay : Word );
var iRel        : TCoord2D;
    iCoord      : TCoord2D;
    iDist       : Word;
    iAngle      : Single;
    iGLColor    : TGLVec4f;
begin
  iGLColor.Init(1.0,1.0,1.0,0.7);
  case aColor of
    Blue    : iGLColor.Init(0.5,0.5,1.0,0.7);
    Magenta : iGLColor.Init(1.0,0.5,1.0,0.7);
    Green   : iGLColor.Init(0.5,1.0,0.5,0.7);
    LightRed: iGLColor.Init(1.2,1.2,1.2,0.7);
  end;

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

    FAnimations.AddAnimation( TGLExplAnimation.Create(
       aDrawDelay * 6,
       iDist*aDrawDelay+VisualRNG.RLongInt(aDrawDelay*3),
       iCoord, GLVec2i( 48, 48 ), iGLColor ) );
  end;
end;

procedure TBerserkGUI.Blink( aColor : Byte; aDuration : Word; aSequence : Word );
begin
  with GLFloatColors[ aColor ] do
    FAnimations.AddAnimation(
      TGLBlinkAnimation.Create( aDuration, aSequence,
      GLVec4f( Data[0], Data[1], Data[2], 0.7 ) )
    );
end;

procedure TBerserkGUI.AddMove(aWho: TUID; const aFrom, aTo: TCoord2D);
var iBeing : TBeing;
begin
  iBeing := UIDs.Get( aWho ) as TBeing;
  if Level.Vision.isVisible( aFrom ) or Level.Vision.isVisible( aTo ) then
  if (iBeing <> nil) and (aFrom <> aTo) then
  begin
    FAnimations.AddAnimation( TGLMoveAnimation.Create( 150, 0, iBeing, aFrom, aTo ) );
    if iBeing.isPlayer then
      FAnimations.AddAnimation( TGLScreenMoveAnimation.Create( 150, 0, Level.UID, aFrom, aTo ) );
  end;
end;

procedure TBerserkGUI.AddAttack(aWho: TUID; aHit: Boolean; const aFrom,
  aTo: TCoord2D);
var iBeing : TBeing;
    iDelay : DWord;
begin
  iBeing := UIDs.Get( aWho ) as TBeing;
  if Level.Vision.isVisible( aFrom ) or Level.Vision.isVisible( aTo ) then
  if (iBeing <> nil) and (aFrom <> aTo) then
  begin
    iDelay := FAnimations.AddAnimation( TGLAttackAnimation.Create( 80, 0, iBeing, aFrom, aTo ) );
    if aHit then
      FAnimations.AddAnimation( TGLMarkAnimation.Create( 200, iDelay + 50, 44, ToAbsPos( aTo, GMODE_EFFECT_Z ), GLVec2i(24,32), GLVec4f(1,1,1,1), VisualRNG.RLongInt(2) = 1 ) );
    FAnimations.AddAnimation( TSoundAnimation.Create( iDelay div 2, iBeing.Position, ResolveSoundID( iBeing.id, Iif( aHit, 'hit', 'miss' ) ) ) );
  end;
end;

procedure TBerserkGUI.RenderBG;
const GLShade : TGLVec4f = ( Data : ( 0.5,0.5,0.5,1 ) );
var iTexture : TTexture;
begin
  iTexture := FTextures.Textures['menuback'];
  FBackgroundQuads.PushTexturedQuad(
    GLVec2i(), GLVec2i( DISPLAY_WIDTH-1, DISPLAY_HEIGHT-1 ), GLShade,
    GLVec2f(), iTexture.GLSize, iTexture.GLTexture, GMODE_GUI_Z
  );
end;

procedure TBerserkGUI.RenderWindow( aSize, aPos : TIOPoint );
var iTexture      : TTexture;
    iA,iB,iC,iE   : TGLVec2i;
    is1,is13,is23 : Single;
    iv11          : TGLVec2i;
    iv10          : TGLVec2i;
    iv01          : TGLVec2i;
    ivi           : TGLVec2i;
    iColor        : TGLVec4f;
const Z = GMODE_GUI_Z + 1;
begin
  iTexture := FTextures.Textures['windowskin'];
  iA.Init( (aPos.X-1)*DISPLAY_CELL_WIDTH,         (aPos.Y-1)*DISPLAY_CELL_HEIGHT );
  iB.Init( (aPos.X-1+aSize.X)*DISPLAY_CELL_WIDTH, (aPos.Y-1)*DISPLAY_CELL_HEIGHT );
  iC.Init( (aPos.X-1)*DISPLAY_CELL_WIDTH,         (aPos.Y-1+aSize.Y)*DISPLAY_CELL_HEIGHT );
  iE.Init( (aPos.X-1+aSize.X)*DISPLAY_CELL_WIDTH, (aPos.Y-1+aSize.Y)*DISPLAY_CELL_HEIGHT );

  iv11.Init(10,10);
  iv10.Init(10, 0);
  iv01.Init( 0,10);
  ivi.Init(-10,10);
  iColor.Init( 0.5, 0.5, 0.5, 1.0 );

  is1  := iTexture.GLSize.X;
  is13 := iTexture.GLSize.X/3;
  is23 := (2*iTexture.GLSize.X)/3;

  with FPreQuads do
  begin
    PushTexturedQuad( iA, iA+iv11, iColor, TGLVec2f.Create( 0,   0 ),    TGLVec2f.Create( is13,is13 ), iTexture.GLTexture, Z );
    PushTexturedQuad( iA+iv10, iB+ivi, iColor, TGLVec2f.Create( is13,0 ),    TGLVec2f.Create( is23,is13 ), iTexture.GLTexture, Z );
    PushTexturedQuad( iB-iv10, iB+iv01, iColor, TGLVec2f.Create( is23,0 ),    TGLVec2f.Create( is1, is13 ), iTexture.GLTexture, Z );

    PushTexturedQuad( iA+iv01, iC-ivi, iColor, TGLVec2f.Create( 0,   is13 ), TGLVec2f.Create( is13,is23 ), iTexture.GLTexture, Z );
    PushTexturedQuad( iA+iv11, iE-iv11, iColor, TGLVec2f.Create( is13,is13 ), TGLVec2f.Create( is23,is23 ), iTexture.GLTexture, Z );
    PushTexturedQuad( iB+ivi, iE-iv01, iColor, TGLVec2f.Create( is23,is13 ), TGLVec2f.Create( is1, is23 ), iTexture.GLTexture, Z );

    PushTexturedQuad( iC-iv01, iC+iv10, iColor, TGLVec2f.Create( 0,   is23 ), TGLVec2f.Create( is13,is1 ), iTexture.GLTexture, Z );
    PushTexturedQuad( iC-ivi, iE-iv10, iColor, TGLVec2f.Create( is13,is23 ), TGLVec2f.Create( is23,is1 ), iTexture.GLTexture, Z );
    PushTexturedQuad( iE-iv11, iE, iColor, TGLVec2f.Create( is23,is23 ), TGLVec2f.Create( is1,is1 ), iTexture.GLTexture, Z );
  end;
end;

procedure TBerserkGUI.Update( aMSec : DWord );
var iMap : TIOPoint;
begin
  VTIG_Clear;
  glEnable( GL_DEPTH_TEST );
  FAnimations.Update( aMSec );

  if Screen = Game then DrawSprites;
  FAnimations.Draw;

  if FStatusVisible then
  begin
    FBackgroundQuads.PushTexturedQuad(
      GLVec2i( DISPLAY_MAP_COLUMNS * DISPLAY_CELL_WIDTH, 0 ), GLVec2i( DISPLAY_WIDTH, DISPLAY_HEIGHT ),
      TGLVec4f.Create( 1, 1, 1, 1 ), GLVec2f(),
      FTextures.Textures['background'].GLSize, FTextures.Textures['background'].GLTexture, GMODE_GUI_Z );
  end;
  iMap := FLayout.MapPixels;
  glScissor( FLayout.Left, FLayout.Height - FLayout.Top - iMap.Y, iMap.X, iMap.Y );
  FSpriteEngine.Update( Projection( FLayout.SpriteScale ) );
  FSpriteEngine.Draw;
  glDisable( GL_DEPTH_TEST );
  glScissor( FLayout.Left, FLayout.Height - FLayout.Top - DISPLAY_HEIGHT * FLayout.FontScale,
    DISPLAY_WIDTH * FLayout.FontScale, DISPLAY_HEIGHT * FLayout.FontScale );
  FQuadRenderer.Update( Projection( FLayout.FontScale ) );
  FQuadRenderer.Render( FBackgroundQuads );
  FQuadRenderer.Render( FPreQuads );
  if FStatusVisible then DrawStatus;
  inherited Update( aMSec );
  glDisable( GL_SCISSOR_TEST );
  FQuadRenderer.Update( GLCreateOrtho( 0, FLayout.Width, FLayout.Height, 0, -1000, 1000 ) );
  FQuadRenderer.Render( FPostQuads );
end;

procedure TBerserkGUI.UpdateLight ( aVision : TVision ) ;
var Y,X    : DWord;
    iValue : Byte;
    iLight : array [0..MAP_MAXX, 0..MAP_MAXY] of TGLVec3b;
  function Get( X, Y : Byte ) : Byte;
  var c : TCoord2D;
  begin
    c.Create( X, Y );
    if not aVision.isVisible(c) then Exit( 30 );
    Exit( 50+ aVision.getLight(c)*2 ); // 15
  end;
begin
  for X := 0 to MAP_MAXX do
    for Y := 0 to MAP_MAXY do
    begin
      iValue := ( Get(X,Y) + Get(X,Y+1) + Get(X+1,Y) + Get(X+1,Y+1) ) div 4;
      iLight[X,Y] := TGLVec3b.CreateAll( Min( Round( iValue * 2.55 ), 255 ) );
      if X*Y > 0 then
        FLightQVecMap[X,Y] := TGLRawQColor.Create(
          iLight[ X - 1, Y - 1 ],
          iLight[ X - 1, Y     ],
          iLight[ X    , Y     ],
          iLight[ X    , Y - 1 ]
        );
    end;
end;

procedure TBerserkGUI.Draw;
begin
  inherited Draw;
  if Screen = Game then UpdateLight( Level.Vision );
end;

procedure TBerserkGUI.Clear;
begin
  inherited Clear;
  if FAnimations <> nil then FAnimations.Clear;
  FTarget.Create( 0, 0 );
  FSpriteEngine.Position := GLVec2i();
end;

destructor TBerserkGUI.Destroy;
begin
  FreeAndNil(FAnimations);
  GUI := nil;
  FreeAndNil(FSpriteEngine);
  FreeAndNil(FQuadRenderer);
  FreeAndNil(FBackgroundQuads);
  FreeAndNil(FPreQuads);
  FreeAndNil(FPostQuads);
  FreeAndNil(FTextures);
  inherited Destroy;
end;


end.
