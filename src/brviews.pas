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
unit brviews;
interface

uses Classes, SysUtils, vtextures, vuielement, vuielements, vconui, vuitypes, vioevent, vconuiext, vluaui, vgltypes;

type

{ TUIWindow }

 TUIWindow = class( TUIElement )
  constructor Create( aParent : TUIElement; aArea : TUIRect );
  function GetAvailableDim : TUIRect; override;
  procedure OnRedraw; override;
  procedure OnRender; override; // graphics
  destructor Destroy; override;
private
  FTextureID : TTextureID;
  A,B,C,D : TGLVec2i;
end;

implementation

uses vluasystem, vluatable, vuiconsole, vutil,
     brmain, brdata, brplayer, brui, brgui;

const GLSolid : TGLVec4f = ( Data : ( 1,1,1,1 ) );
      GLShade : TGLVec4f = ( Data : ( 0.5,0.5,0.5,1 ) );

{ TUIWindow }

constructor TUIWindow.Create ( aParent : TUIElement; aArea : TUIRect ) ;
begin
  inherited Create( aParent, aArea );
  if GraphicsMode then
  begin
    FTextureID := Textures.TextureID['windowskin'];
    A.Init( (Pos.X)*10,       (Pos.Y)*24 );
    B.Init( (Pos.X+Dim.X)*10, (Pos.Y)*24 );
    C.Init( (Pos.X)*10,       (Pos.Y+Dim.Y)*24 );
    D.Init( (Pos.X+Dim.X)*10, (Pos.Y+Dim.Y)*24 );
  end;
end;

function TUIWindow.GetAvailableDim : TUIRect;
begin
  Result := inherited GetAvailableDim.Shrinked(1);
end;

procedure TUIWindow.OnRedraw;
var iCon : TUIConsole;
begin
  inherited OnRedraw;
  iCon.Init( TConUIRoot(FRoot).Renderer );
  iCon.ClearRect( FAbsolute, FBackColor );
end;

procedure TUIWindow.OnRender;
var iTexSize : TGLVec2f;
    iTexID   : DWord;
    s1,s13,s23 : Single;
    v11 : TGLVec2i;
    v10 : TGLVec2i;
    v01 : TGLVec2i;
    vi  : TGLVec2i;
    col : TGLVec4f;
const Z = GMODE_GUI_Z;
begin
  inherited OnRender;
  if GraphicsMode then
  begin
    iTexSize := Textures[FTextureID].GLSize;
    iTexID   := Textures[FTextureID].GLTexture;

    v11.Init(10,10);
    v10.Init(10, 0);
    v01.Init( 0,10);
    vi.Init(-10,10);
    col.Init( 0.5, 0.5, 0.5, 0.7 );

    s1  := iTexSize.X;
    s13 := iTexSize.X/3;
    s23 := (2*iTexSize.X)/3;

    with GUI.PreQuads[ iTexID ] do
    begin
      PushQuad( GLVec3i(A,Z),     GLVec3i(A+v11,Z), col, TGLVec2f.Create( 0,0 ),    TGLVec2f.Create( s13,s13 ) );
      PushQuad( GLVec3i(A+v10,Z), GLVec3i(B+vi,Z),  col, TGLVec2f.Create( s13,0 ),  TGLVec2f.Create( s23,s13 ) );
      PushQuad( GLVec3i(B-v10,Z), GLVec3i(B+v01,Z), col, TGLVec2f.Create( s23,0 ),  TGLVec2f.Create( s1,s13 ) );

      PushQuad( GLVec3i(A+v01,Z), GLVec3i(C-vi,Z),  col, TGLVec2f.Create( 0,s13 ),  TGLVec2f.Create( s13,s23 ) );
      PushQuad( GLVec3i(A+v11,Z), GLVec3i(D-v11,Z), col, TGLVec2f.Create( s13,s13 ),TGLVec2f.Create( s23,s23 ) );
      PushQuad( GLVec3i(B+vi,Z),  GLVec3i(D-v01,Z), col, TGLVec2f.Create( s23,s13 ),TGLVec2f.Create( s1,s23 ) );

      PushQuad( GLVec3i(C-v01,Z), GLVec3i(C+v10,Z), col, TGLVec2f.Create( 0,s23 ),  TGLVec2f.Create( s13,s1 ) );
      PushQuad( GLVec3i(C-vi,Z),  GLVec3i(D-v10,Z), col, TGLVec2f.Create( s13,s23 ),TGLVec2f.Create( s23,s1 ) );
      PushQuad( GLVec3i(D-v11,Z), GLVec3i(D,Z),     col, TGLVec2f.Create( s23,s23 ),TGLVec2f.Create( s1,s1 ) );
    end;
  end;
end;

destructor TUIWindow.Destroy;
begin
  inherited Destroy;
end;

end.

