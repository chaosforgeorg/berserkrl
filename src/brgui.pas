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

uses SysUtils, vutil, vgenerics, vrltools, vvision, vtextures, vglimage,
     vimage, brui, brdata, vglquadsheet, vglquadbuffer, vgltypes, vglprogram,
     vanimation, branimation;

const
  SpriteSheetSizeX = 384;
  SpriteSheetSizeY = 384;
  SpriteSheetLine  = SpriteSheetSizeX div 24;

type

{ TBerserkGUI }

TBerserkGUI = class(TBerserkUI)
    // Initialization of all data.
    constructor Create(FullScreen : Boolean = False);
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
    // Draws a firey background
    procedure RenderBG(); override;
    // Pre update
    procedure PreUpdate( aTickTime : DWord ); override;
    // Post update
    procedure PostUpdate( aTickTime : DWord ); override;
    // Update light map
    procedure UpdateLight( aVision : TVision );
    // Draws the level, player status, messages, and updates the screen.
    procedure Draw; override;
    // destructor
    destructor Destroy; override;
    function GetSpritePos( aIndex : Byte ) : TGLVec2f;
    function GetSpriteSize( aSize : TGLVec2i ) : TGLVec2f;
    function ToScreenVec( const aCoord : TCoord2D ) : TGLVec2i;
    function ToScreenCoord( const aCoord : TCoord2D ) : TCoord2D;
    function ToAbsPos( const aCoord : TCoord2D; aDepth : Integer ) : TGLVec3i;
    procedure DrawSprite( aTile : Word; const aAbsPos : TGLVec3i; const aSize : TGLVec2i; const aColor : TGLQVec4f; aFlip : Boolean; aZoom : Single = 1.0 );
    procedure SetOverlay( aColor : TGLVec4f );
    private
    procedure DrawSprites;
  private
    FLightVecMap : array [0..MAP_MAXX, 0..MAP_MAXY] of TGLVec4f;
    FLightQVecMap: array [1..MAP_MAXX, 1..MAP_MAXY] of TGLQVec4f;
    FPreQuads    : TGLTexturedColoredQuadLayer;
    FTerrain     : TGLTexturedColoredQuads;
    FTarget      : TCoord2D;
    FSpriteTexID : TTextureID;
    FAnimations  : TAnimations;

    FPixelSize   : TGLVec2f;
    FSprite2424  : TGLVec2f;
    FSprite2432  : TGLVec2f;

    FProgram     : TGLProgram;
    FLTexture    : LongInt;
    FLOverlay    : LongInt;
    public
    property PreQuads  : TGLTexturedColoredQuadLayer read FPreQuads;
    property Terrain   : TGLTexturedColoredQuads     read FTerrain;
  end;

var GUI : TBerserkGUI = nil;

var Textures : TTextureManager = nil;


implementation

uses {$IFDEF WINDOWS}Windows,{$ENDIF}
     vuid, vgl3library, vsystems,
     vioconsole, vsdlio, vglconsole, vlog,
     vcolor, viotypes, vmath, vdebug, math,
     brbeing, brplayer, brlevel;

{ TBerserkTextures }

function TBerserkGUI.GetSpritePos( aIndex: Byte ): TGLVec2f;
begin
  Result.Init( FSprite2432.X*(( aIndex - 1 ) mod SpriteSheetLine ), FSprite2432.Y*((aIndex - 1) div SpriteSheetLine) );
end;

function TBerserkGUI.GetSpriteSize(aSize: TGLVec2i): TGLVec2f;
begin
  Result.Init( FPixelSize.X * aSize.X, FPixelSize.Y * aSize.Y );
end;

function TBerserkGUI.ToScreenVec( const aCoord: TCoord2D ): TGLVec2i;
begin
  Result.Init( ( aCoord.X - 1 )*24 - FShift + 12,( aCoord.Y - 1 )*24 + 12 );
end;

function TBerserkGUI.ToScreenCoord(const aCoord: TCoord2D): TCoord2D;
begin
  Result.Create( ( aCoord.X - 1 )*24  - FShift + 12,( aCoord.Y - 1 )*24 + 12 );
end;

function TBerserkGUI.ToAbsPos(const aCoord: TCoord2D; aDepth: Integer ): TGLVec3i;
begin
  Result.Init( ( aCoord.X - 1 )*24,( aCoord.Y - 1 )*24 - 8, aDepth );
end;

procedure TBerserkGUI.DrawSprite( aTile : Word; const aAbsPos : TGLVec3i; const aSize : TGLVec2i; const aColor : TGLQVec4f; aFlip : Boolean; aZoom : Single = 1.0);
var iPos    : TGLVec3i;
    iSize   : TGLVec2i;
    iC1,iC2 : TGLVec3i;
    iT1,iT2 : TGLVec2f;
    iTemp   : Single;
begin
  if aTile = 0 then Exit;
  iSize := aSize;
  if aZoom <> 1.0 then
  begin
    iSize.X := Round( iSize.X * aZoom );
    iSize.Y := Round( iSize.Y * aZoom );
  end;
  iPos := aAbsPos;
  iPos.X := iPos.X - FShift;
  iC1.Init( iPos.X + ( ( 24-iSize.X ) div 2 ), iPos.Y + ( 32-iSize.Y ), iPos.Z );
  iC2 := iC1 + GLVec3i( iSize );

  iT1 := GetSpritePos( aTile );
  iT2 := iT1 + GetSpriteSize( aSize );
  if aFlip then begin iTemp := iT1.x; iT1.x := iT2.x; iT2.x := iTemp; end;
  FTerrain.PushQuad( iC1, iC2, aColor, iT1,iT2 );
end;

procedure TBerserkGUI.SetOverlay(aColor: TGLVec4f);
begin
  FProgram.Bind;
  glUniform4f( FLOverlay, aColor.Data[0], aColor.Data[1], aColor.Data[2], aColor.Data[3] );
  FProgram.UnBind;
end;

procedure TBerserkGUI.DrawSprites;
  function GetColor( aCoord : TCoord2D; ax, ay : ShortInt ) : TGLVec4f;
  var iValue : Byte;
  begin
    GetColor := FLightVecMap[ aCoord.x + ax, aCoord.y + ay ];
    if Player.isBerserk
      then begin GetColor.Data[1] := 0.1; GetColor.Data[2] := 0.1; end;
  end;

  function  RandomSide( aTerra : Word; aCoord : TCoord2D ) : boolean;
  begin
    if TF_NOMIRROR in TerraData[aTerra].Flags then Exit( False );
    Exit(((aCoord.x+5)*(aCoord.x+3)*aCoord.y mod 193*197) mod 2 = 0);
  end;

var iColor4     : TGLQVec4f;
    iColor      : TGLVec4f;
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
    iMin        : Integer;
    iMax        : Integer;

begin
  iMin   := ( FShift div 24 ) + 1;
  iMax   := ( FShift div 24 ) + 21;

  iSSquare.Init( 24, 24 );
  iSTall.Init( 24, 32 );
  iSBig.Init( 32, 32 );

  for iCoord in NewArea(iMin,1,iMax,MAP_MAXY) do
  begin
    iDepth   := iCoord.Y * GMODE_STEP_Z;
    iTerrain := Level.GetCell( iCoord );
    iColor4  := FLightQVecMap[ iCoord.x, iCoord.y ];
    if Player.isBerserk then
      for iCount := 0 to 5 do
      begin
        iColor4.Data[ iCount ].Data[ 1 ] := 0.1;
        iColor4.Data[ iCount ].Data[ 2 ] := 0.1;
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
          if not Player.isBerserk
            then iColor.Init( 1.0*FVisual.Overlay[1], 1.0*FVisual.Overlay[2], 1.0*FVisual.Overlay[3], 1.0 )
            else iColor.Init( 1.0, 0.3, 0.3, 1.0 );
          iSize := iStall;
          if Flags[ SF_BIG ] then iSize := iSBig;
          DrawSprite( FVisual.Sprite, ToAbsPos( iCoord, iDepth ), iSize, TGLQVec4f.CreateAll( iColor ), not FVisual.Mirror );
        end;
  end;
          
  iColor.Init(1,1,1,1);
  if FTarget.X <> 0 then
    DrawSprite( 30, ToAbsPos( FTarget, GMODE_GUI_Z ), iSTall, TGLQVec4f.CreateAll( iColor ), False );
end;

procedure set_ortho_matrix( left, right, bottom, top, nearz, farz : Single; iLocation : Integer );
var m : packed array[0..3,0..3] of Single;
    rml, rpl, tmb, tpb, fmn, fpn : Single;
    i,j : Integer;
begin
  for i := 0 to 3 do for j := 0 to 3 do m[i,j] := 0.0;
  rml := right - left;
  rpl := right + left;
  tmb := top - bottom;
  tpb := top + bottom;
  fmn := farz - nearz;
  fpn := farz + nearz;

  m[0][0] := 2.0 / rml;
  m[3][0] := -rpl / rml;

  m[1][1] := 2.0 / tmb;
  m[3][1] := -tpb / tmb;

  m[2][2] := -2.0 / fmn;
  m[3][2] := -fpn / fmn;

  m[3][3] := 1.0;

  glMatrixMode( GL_PROJECTION );
  glLoadIdentity();
  glMultMatrixf( @m[0] );
  glUniformMatrix4fv( iLocation, 1, 0, @m[0] );
end;

{ TBreserkGUI }

constructor TBerserkGUI.Create(FullScreen : Boolean = False);
var iCount       : DWord;
    iFlags       : TSDLIOFlags;
    iSheetSize   : TGLVec2f;
begin
  {$IFDEF WINDOWS}
  if not GodMode then
  begin
    FreeConsole;
    vdebug.DebugWriteln := nil;
  end
  else
  begin
    Logger.AddSink( TConsoleLogSink.Create( LOGDEBUG, true ) );
  end;
  {$ENDIF}



  iFlags := [ SDLIO_OpenGL ];
  if FullScreen then Include( iFlags, SDLIO_FullScreen );
  FIODriver := TSDLIODriver.Create( 800, 600, 32, iFlags );

  Textures := TTextureManager.Create( True );
  Textures.LoadTextureFolder(DataPath+'graphics');
  Textures.Upload;
  FSpriteTexID := Textures.TextureID['spritesheet'];
  FConsole := TGLConsoleRenderer.Create( DataPath+'font10x18.png', 32, 256-32, 32, 80, 25, 6, [VIO_CON_CURSOR] );

//  glMatrixMode( GL_PROJECTION );
//  glLoadIdentityMatrix();
//  glOrtho(0, FIODriver.GetSizeX, FIODriver.GetSizeY,0, -1, 1 );
  LoadGL3;
  LoadGL3Compat;
  FProgram := TGLProgram.Create(
    SlurpFile( DataPath+'graphics'+PathDelim+'basic.vert' ),
    SlurpFile( DataPath+'graphics'+PathDelim+'basic.frag' )
  );
  FProgram.Bind;
  FLTexture    := FProgram.GetUniformLocation('s_texture');
  FLOverlay    := FProgram.GetUniformLocation('overlay');
  glUniform4f( FLOverlay, 0, 0, 0, 0 );
  set_ortho_matrix(0, FIODriver.GetSizeX, FIODriver.GetSizeY,0, -1000, 1000, FProgram.GetUniformLocation('m_transform') );
  FProgram.UnBind;

  inherited Create;
  GUI := Self;

  FTarget.Create( 0,0 );

  // VISTA DOESN'T LIKE NONBLENDED TEXTURES!
  FPreQuads  := TGLTexturedColoredQuadLayer.Create( FProgram, 's_texture', 'coord3d', 'texcoord', 'color' );
  FTerrain   := TGLTexturedColoredQuads.Create(
    FProgram.GetAttribLocation('coord3d'),
    FProgram.GetAttribLocation('texcoord'),
    FProgram.GetAttribLocation('color')
  );

  iSheetSize := Textures.Textures['spritesheet'].GLSize;
  FPixelSize.Init( iSheetSize.X / SpriteSheetSizeX, iSheetSize.Y / SpriteSheetSizeY );
  FSprite2424.Init( iSheetSize.X * 24 / SpriteSheetSizeX, iSheetSize.Y * 24 / SpriteSheetSizeY );
  FSprite2432.Init( iSheetSize.X * 24 / SpriteSheetSizeX, iSheetSize.Y * 32 / SpriteSheetSizeY );

  FAnimations  := TAnimations.Create;
end;

procedure TBerserkGUI.SendMissile( const aSource, aTarget : TCoord2D; aType : Byte; aSequence : DWord );
var iPosition  : TCoord2D;
    iDist      : Integer;
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
var iGLColor    : TGLVec4f;
    iSource     : TGLVec2i;
    iSize       : TGLVec2i;
    iBase       : DWord;
    iTime       : DWord;
    iExplSprite : TGLVec2f;
    iExplSize   : TGLVec2f;
    iSpriteID   : Cardinal;
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
       iDist*aDrawDelay+Random(aDrawDelay*3),
       iCoord, GLVec2i( 48, 48 ), iGLColor ) );
  end;
end;

procedure TBerserkGUI.Blink( aColor : Byte; aDuration : Word; aSequence : Word );
begin
  with GLFloatColors[ aColor ] do
    FAnimations.AddAnimation(
      TGLBlinkAnimation.Create( aDuration, aSequence,
      GLVec4f( Data[0], Data[1], Data[2], 1.0 ) )
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
    if iBeing.isPlayer and (aFrom.X <> aTo.X) then
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
      FAnimations.AddAnimation( TGLMarkAnimation.Create( 200, iDelay + 50, 44, ToAbsPos( aTo, GMODE_EFFECT_Z ), GLVec2i(24,32), GLVec4f(1,1,1,1), Random(2) = 1 ) );
    FAnimations.AddAnimation( TSoundAnimation.Create( iDelay div 2, iBeing.Position, ResolveSoundID( iBeing.id, Iif( aHit, 'hit', 'miss' ) ) ) );
  end;
end;

procedure TBerserkGUI.RenderBG;
const GLShade : TGLVec4f = ( Data : ( 0.5,0.5,0.5,1 ) );
var iTexture : TTexture;
begin
  iTexture := Textures.Textures['menuback'];
  GUI.PreQuads[ iTexture.GLTexture ].PushQuad(
    GLVec3i(0,0,GMODE_GUI_Z), GLVec3i( 800-1,600-1,GMODE_GUI_Z), GLShade,
    GLVec2f(), iTexture.GLSize
  );
end;

procedure TBerserkGUI.PreUpdate( aTickTime : DWord );
begin
  inherited PreUpdate( aTickTime );
  glEnable( GL_DEPTH_TEST );
  FAnimations.Update( aTickTime );

  DrawSprites;
  FAnimations.Draw;

  FTerrain.Update;

  FProgram.Bind;
  glActiveTexture( GL_TEXTURE0 );
  glBindTexture( GL_TEXTURE_2D,  Textures.Texture[FSpriteTexID].GLTexture );
  glUniform1i( FLTexture, 0);
  FTerrain.Draw;
  FProgram.UnBind;
  FTerrain.Clear;
  FPreQuads.Draw;
  glDisable( GL_DEPTH_TEST );
end;

procedure TBerserkGUI.PostUpdate( aTickTime : DWord );
begin
  inherited PostUpdate( aTickTime );
end;

procedure TBerserkGUI.UpdateLight ( aVision : TVision ) ;
var Y,X    : DWord;
    iValue : Byte;
  function Get( X, Y : Byte ) : Byte;
  var c : TCoord2D;
  begin
    c.Create( X, Y );
    if not Level.Vision.isVisible(c) then Exit( 30 );
    Exit( 50+ Level.Vision.getLight(c)*2 ); // 15
  end;
begin
  for X := 0 to MAP_MAXX do
    for Y := 0 to MAP_MAXY do
    begin
      iValue := ( Get(X,Y) + Get(X,Y+1) + Get(X+1,Y) + Get(X+1,Y+1) ) div 4;
      FLightVecMap[X,Y].Init( iValue*0.01, iValue*0.01, iValue*0.01, 1.0 );
      if X*Y > 0 then
        FLightQVecMap[X,Y] := TGLQVec4f.Create(
          FLightVecMap[ X - 1, Y - 1 ],
          FLightVecMap[ X - 1, Y     ],
          FLightVecMap[ X    , Y     ],
          FLightVecMap[ X    , Y - 1 ]
        );
    end;
end;

procedure TBerserkGUI.Draw;
begin
  inherited Draw;
  UpdateLight( Level.Vision );
end;

destructor TBerserkGUI.Destroy;
begin
  FreeAndNil(FAnimations);
  FreeAndNil(FProgram);
  FreeAndNil(Textures);
  FreeAndNil(FTerrain);
  FreeAndNil(FPreQuads);
  inherited Destroy;
end;


end.

