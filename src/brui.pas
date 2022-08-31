// @abstract(BerserkRL -- User Interface class)
// @author(Kornel Kisielewicz <admin@chaosforge.org>)
// @created(Jan 9, 2007)
// @lastmod(Jan 9, 2007)
//
// This unit holds the User Interface class of Berserk!. Every input/output
// related task should be done via this class. This unit opens a possibility
// of a different UI for Berserk!, for example with tiles.
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
unit brui;
interface

uses vutil, vio, viorl, vsystem, vrltools, vglquadsheet,
     vuielement, vconui, vuitypes, viotypes, vioevent, vioconsole,
     brviews, brgviews, brdata, vnode;

const
    // Option that makes the name always "random"
    Option_AlwaysRandomName : Boolean = False;
    // Option that sets the name always to given string
    Option_AlwaysName       : AnsiString = '';
    // Option that turns on message coloring
    Option_MessageColoring  : Boolean = False;
    // Option for the kill count showing
    Option_KillCount        : Boolean = False;
    // Option of the message buffer size
    Option_MessageBuffer    : DWord = 100;
    // Option of the number of last messages in mortem.
    Option_MortemMessages   : DWord = 10;

    COMMAND_SKILLS     = [ COMMAND_SKILL1,COMMAND_SKILL2,
                           COMMAND_SKILL3,COMMAND_SKILL4,
                           COMMAND_SKILL5,COMMAND_SKILL6,
                           COMMAND_SKILL7,COMMAND_SKILL8,
                           COMMAND_SKILL9,COMMAND_SKILL0 ];
    SKILL_SLOTS        = 10;

    // Set of move commands
    COMMANDS_MOVE        = [COMMAND_WALKNORTH,COMMAND_WALKSOUTH,
                            COMMAND_WALKEAST, COMMAND_WALKWEST,
                            COMMAND_WALKNE,   COMMAND_WALKSE,
                            COMMAND_WALKNW,   COMMAND_WALKSW];
                            
// Color constants
const Black        = 0;    DarkGray     = 8;
      Blue         = 1;    LightBlue    = 9;
      Green        = 2;    LightGreen   = 10;
      Cyan         = 3;    LightCyan    = 11;
      Red          = 4;    LightRed     = 12;
      Magenta      = 5;    LightMagenta = 13;
      Brown        = 6;    Yellow       = 14;
      LightGray    = 7;    White        = 15;

// Picture
type TPicture = Word;

type
  // Berserk User interface class. Responsible for keeping all the UI in one
  // place. After some twidling, this could allow for a graphics version of
  // Berserk!. All display/input commands should go here.

  { TBerserkUI }

  TBerserkUI = class(TIORL)
    // Holds the current screen info
    Screen  : (Game,Menu);
    // Initialization of all data.
    constructor Create; reintroduce;
    // Runs a view
    function RunUILoop( aElement : TUIElement ) : DWord; override;
    // Runs a Lua view
    function RunUILoop( const aElement : AnsiString ) : DWord;
    // Performs a full update
    procedure FullUpdate; override;
    // Show past messages.
    procedure MsgPast;
    // Dump last messages to file.
    procedure MsgDump(var TextFile : Text);
    // Writes a tile description in the msg area.
    procedure MsgCoord( Coord : TCoord2D );
    // Reads a key from the keyboard and returns it's Command value.
    function GetCommand(Valid : TCommandSet = []) : byte;
    // Interface function for choosing direction. Returns the direction, or 0 if escaped.
    function ChooseDirection : TDirection;
    // Waits for enter key.
    procedure PressEnter;
    // Draws the level, player status, messages, and updates the screen.
    procedure Draw; virtual;
    // Graphical effect of a screen flash, of the given color, and Duration in
    // miliseconds.
    procedure Blink( aColor : Byte; aDuration : Word; aSequence : Word ); virtual; abstract;
    // Cleaning up everything that was initialized in TBerserkUI.Create.
    destructor Destroy; override;
    // Converts Commands to Direction values
    function CommandDirection(Command : byte) : TDirection;
    // Moves the cursor to the position x,y in terms of Map coords.
    procedure Focus( Where : TCoord2D );
    // Renders an explosion on the screen.
    procedure AddExplosion( aWhere : TCoord2D; aColor : byte; aRange : byte; aStep : byte; aDrawDelay, aSequence : Word ); virtual; abstract;
    // Animates a move if in GFX
    procedure AddMove( aWho : TUID; const aFrom, aTo : TCoord2D ); virtual;
    // Animates an attack if in GFX
    procedure AddAttack( aWho : TUID; aHit : Boolean; const aFrom, aTo : TCoord2D ); virtual;
    // Draws a firey background
    procedure DrawFire( aSeed : Cardinal = 0 ); virtual;
    // Draws a firey background
    procedure RenderBG(); virtual;
    // Sends missile
    procedure SendMissile( const aSource, aTarget : TCoord2D; aType : Byte; aSequence : DWord ); virtual; abstract;
    // Draws target X
    procedure Target( Where : TCoord2D; color : Byte); virtual; abstract;
    // Renders a breath weapon attack
    procedure Breath( aWhere : TCoord2D; aDirection : TDirection; aColor : byte; aRange : byte; aStep : byte; aDrawDelay : Word ); virtual; abstract;
    // Pre update
    procedure PreUpdate( aTickTime : DWord ); virtual;
    // Post update
    procedure PostUpdate( aTickTime : DWord ); virtual;
    // Resolve sound ID
    function ResolveSoundID( const aID, aSound : AnsiString ) : AnsiString;
    // Register API
    class procedure RegisterLuaAPI();
  protected
    FStatus      : TUIStatus;
    FLastTick    : DWord;
    FShift       : Integer; // only in GFX mode
  public
    property Status    : TUIStatus    read FStatus;
    property Shift     : Integer      read FShift  write FShift; // only in GFX mode
  end;


// Singleton for the TBerserkUI class
const UI : TBerserkUI = nil;

implementation

uses SysUtils, DateUtils, variants, math, vsound,
     vsystems, vluasystem, vluagamestate, vluaui, zstream, vxmldata,
     brlua, brlevel, brplayer, brmain, brpersistence;

{ TBerserkUI }

constructor TBerserkUI.Create;
var iStyle : TUIStyle;
    iCount : Byte;
    iKey   : TIOKeyCode;
begin
//  inherited Create;
  iStyle := TUIStyle.Create('default');
  iStyle.Add('','fore_color', LightGray );
  iStyle.Add('','selected_color', White );
  iStyle.Add('','inactive_color', Red );
  iStyle.Add('','selinactive_color', LightRed );
  iStyle.Add('menu','fore_color', DarkGray );
  iStyle.Add('','back_color', Black );
  iStyle.Add('','scroll_chars', '^v' );
  iStyle.Add('','icon_color', LightGray );
  iStyle.Add('','opaque', False );
  if HighASCII then
    iStyle.Add('','frame_chars', #196+#179+#196+#179+#218+#191+#192+#217+#196+#179+'^v' )
  else
    iStyle.Add('','frame_chars', '-|-|/\\/-|^v' );
  iStyle.Add('window','fore_color', LightGray );
  iStyle.Add('full_window','fore_color', LightGray );
  iStyle.Add('','frame_color', DarkGray );
  iStyle.Add('full_window','title_color', LightGray );
  iStyle.Add('full_window','footer_color', LightGray );
  iStyle.Add('input','fore_color', White );
  iStyle.Add('input','back_color', Black );
  iStyle.Add('text','fore_color', LightGray );
  iStyle.Add('text','back_color', ColorNone );

  inherited Create( FIODriver, FConsole, iStyle );

  FStatus := TUIStatus.Create( FUIRoot );
  FStatus.Enabled := False;
  FMessages := FStatus.Messages;

  FIODriver.SetTitle('Berserk!','Berserk!');

  Berserk.Config.LoadKeybindings( 'Keybindings' );
  for iCount in COMMAND_SKILLS do
  begin
    iKey := Berserk.Config.GetKeyCode( iCount );
    Berserk.Config.Commands[ Byte(iKey) + IOKeyCodeShiftMask ] := iCount + COMMAND_SKILLALTSHIFT;
  end;

  if Option_MessageColoring then
    Berserk.Config.EntryFeed( 'Messages', @FStatus.Messages.AddHighlightCallback );

  Screen := Menu;

  Msg('Berserk!');
  Msg('Press @<'+Berserk.Config.GetKeybinding(COMMAND_HELP)+'@> for help.');

  FLastTick := FIODriver.GetMs;
end;

function TBerserkUI.RunUILoop ( aElement : TUIElement ) : DWord;
begin
  FStatus.Enabled := False;
  FConsole.Clear;
  FConsole.HideCursor;
  Exit( inherited RunUILoop( aElement ) );
end;

function TBerserkUI.RunUILoop(const aElement: AnsiString): DWord;
var iElement : TUIElement;
begin
  FStatus.Enabled := False;
  FConsole.Clear;
  FConsole.HideCursor;
  iElement := CreateLuaUIElement( LuaSystem.Raw, aElement, Root );
  Exit( inherited RunUILoop( iElement ) );
end;

procedure TBerserkUI.FullUpdate;
var iTickTime : DWord;
    iNow      : DWord;
begin
  iNow        := FIODriver.GetMs;
  iTickTime   := iNow - FLastTick;
  FLastTick   := iNow;

  PreUpdate( iTickTime );
  FUIRoot.OnUpdate( iTickTime );
  FUIRoot.Render;
  FConsole.Update;
  PostUpdate( iTickTime );
end;

procedure TBerserkUI.PreUpdate( aTickTime : DWord );
begin
  FIODriver.PreUpdate;
end;

procedure TBerserkUI.PostUpdate( aTickTime : DWord );
begin
  FIODriver.PostUpdate;
end;

function TBerserkUI.ResolveSoundID(const aID, aSound: AnsiString): AnsiString;
begin
  if Config = nil then Exit('');
  if aSound = '' then Exit( Config.Configure( 'sounds.'+aID, '' ) );
  Result := Config.Configure( 'sounds.'+aID+'.'+aSound, '-' );
  if Result = '-' then
    Result := Config.Configure( 'sounds.'+aSound, '' );
end;

procedure TBerserkUI.MsgPast;
begin
  RunUILoop( 'ui_message_screen' );
end;

procedure TBerserkUI.MsgDump(var TextFile : Text);
var Count : Word;
begin
{  for Count := Option_MortemMessages downto 1 do
    if Messages.Get(Count) <> '' then
      Writeln(TextFile,' '+StripEncoding(Messages.Get(Count)));}
end;

procedure TBerserkUI.MsgCoord ( Coord : TCoord2D ) ;
begin
  UI.MsgKill;
  if Level.Vision.isVisible( Coord ) then
    if Level.Being[ Coord ] <> nil then
      UI.Msg(Level.Being[ Coord ].LookDescribe)
    else
      UI.Msg(Level.Terrain[ Coord ].Name)
  else
    UI.Msg('nothing');
end;

function TBerserkUI.GetCommand(Valid : TCommandSet) : byte;
begin
  if Assigned( Sound ) then
    Sound.Listener := Player.Position;
  FStatus.Enabled := True;
  //Draw;
  Exit( WaitForCommand( Valid ) );
end;

function TBerserkUI.ChooseDirection : TDirection;
begin
  Exit(CommandDirection(GetCommand(COMMANDS_MOVE+[COMMAND_ESCAPE])));
end;

procedure TBerserkUI.Draw;
begin
  FConsole.Clear;
  Focus(Player.Position);
  Level.Vision.Run(Player.Position,Player.LightRadius);
end;

destructor TBerserkUI.Destroy;
begin
  inherited Destroy;
end;

function TBerserkUI.CommandDirection(Command : byte) : TDirection;
begin
  case Command of
    COMMAND_WALKWEST  : CommandDirection.Create(4);
    COMMAND_WALKEAST  : CommandDirection.Create(6);
    COMMAND_WALKNORTH : CommandDirection.Create(8);
    COMMAND_WALKSOUTH : CommandDirection.Create(2);
    COMMAND_WALKNW    : CommandDirection.Create(7);
    COMMAND_WALKNE    : CommandDirection.Create(9);
    COMMAND_WALKSW    : CommandDirection.Create(1);
    COMMAND_WALKSE    : CommandDirection.Create(3);
    COMMAND_WAIT      : CommandDirection.Create(5);
    else CommandDirection.Create(0);
  end;
end;

procedure TBerserkUI.Focus( Where : TCoord2D );
begin
  FConsole.MoveCursor(Where.x+MAP_POSX-1,Where.y+MAP_POSX-1);
end;

procedure TBerserkUI.AddMove(aWho: TUID; const aFrom, aTo: TCoord2D);
begin

end;

procedure TBerserkUI.AddAttack(aWho: TUID; aHit: Boolean; const aFrom, aTo: TCoord2D);
begin
end;

procedure TBerserkUI.DrawFire ( aSeed : Cardinal ) ;
begin

end;

procedure TBerserkUI.RenderBG;
begin

end;

procedure TBerserkUI.PressEnter;
begin
  GetCommand([COMMAND_OK]);
end;

function lua_ui_msg(L: Plua_State): Integer; cdecl;
var State : TLuaGameState;
begin
  State.Init(L);
  if State.StackSize = 0 then Exit(0);
  UI.Msg(State.ToString(1));
  Result := 0;
end;

function lua_ui_msg_kill(L: Plua_State): Integer; cdecl;
begin
  UI.MsgKill;
  Result := 0;
end;

function lua_ui_blink(L: Plua_State): Integer; cdecl;
var State : TLuaGameState;
begin
  State.Init(L);
  UI.Blink( State.ToInteger( 1 ), State.ToInteger( 2, 50 ), State.ToInteger( 3, 0 ) );
  Result := 0;
end;

function lua_ui_choose_dir(L: Plua_State): Integer; cdecl;
var State : TLuaGameState;
    Dir   : TDirection;
begin
  State.Init(L);
  Dir := UI.ChooseDirection;
  if Dir.code = 0
    then State.PushNil
    else State.PushCoord( Dir.ToCoord );
  Result := 1;
end;

function lua_ui_enter(L: Plua_State): Integer; cdecl;
begin
  UI.PressEnter;
  Result := 0;
end;

function lua_ui_draw_fire(L: Plua_State): Integer; cdecl;
var State : TLuaGameState;
begin
  State.Init(L);
  UI.DrawFire( State.ToInteger(1) );
  Result := 0;
end;

function lua_ui_render_bg(L: Plua_State): Integer; cdecl;
begin
  UI.RenderBG();
  Result := 0;
end;

function lua_ui_save_game(L: Plua_State): Integer; cdecl;
begin
  Berserk.Save;
  Result := 0;
end;

function lua_ui_set_arena(L: Plua_State): Integer; cdecl;
var State : TLuaGameState;
begin
  State.Init(L);
  Berserk.Arena := State.ToInteger(1);
  Result := 0;
end;

function lua_ui_new_window(L: Plua_State): Integer; cdecl;
var iState   : TLuaGameState;
    iElement : TUIElement;
begin
  iState.Init( L );
  iElement := TUIWindow.Create( iState.ToObject( 1 ) as TUIElement, iState.ToRect( 2 ) );
  iElement.RegisterWithLua;
  iState.Push( iElement );
  Result := 1;
end;

function lua_ui_get_keybinding(L: Plua_State): Integer; cdecl;
var State : TLuaGameState;
begin
  State.Init(L);
  State.Push( Berserk.Config.GetKeybinding( State.ToInteger(1) ) );
  Result := 1;
end;

function lua_ui_get_mortem_file(L: Plua_State): Integer; cdecl;
var State : TLuaGameState;
begin
  State.Init(L);
  State.Push( WritePath + 'mortem.txt' );
  Result := 1;
end;

function lua_ui_get_help_path(L: Plua_State): Integer; cdecl;
var State : TLuaGameState;
begin
  State.Init(L);
  State.Push( DataPath+'help'+PathDelim );
  Result := 1;
end;

function lua_ui_get_message_buffer(L: Plua_State): Integer; cdecl;
var iState   : TLuaGameState;
    iElement : TConUIChunkBuffer;
begin
  iState.Init(L);
  iElement := TConUIChunkBuffer.Create( iState.ToObject( 1 ) as TUIElement, iState.ToRect( 2 ), UI.Status.Messages.Content, False );
  iElement.SetScroll( iElement.Count );
  iElement.EventFilter := [ VEVENT_KEYDOWN, VEVENT_MOUSEDOWN ];
  iElement.RegisterWithLua;
  iState.Push( iElement );
  Result := 1;
end;

function lua_ui_get_hof_entry(L: Plua_State): Integer; cdecl;
var iState   : TLuaGameState;
    iEntry   : TScoreEntry;
begin
  iState.Init(L);
  iEntry := Berserk.Persistence.Get( iState.ToInteger( 1 ) );
  if iEntry = nil then Exit( 0 );
  iState.Push( StrToInt( iEntry.GetAttribute('mode') ) );
  iState.Push( iEntry.GetAttribute('name') );
  iState.Push( StrToInt( iEntry.GetAttribute('turns') ) );
  iState.Push( StrToInt( iEntry.GetAttribute('kills') ) );
  iState.Push( StrToInt( iEntry.GetAttribute('result') ) );
  Result := 5;
end;

function lua_ui_get_hof_current(L: Plua_State): Integer; cdecl;
var iState   : TLuaGameState;
begin
  iState.Init(L);
  iState.Push( LongInt( Berserk.Persistence.GetCurrent ) );
  Result := 1;
end;

function lua_ui_resolve_sound_id(L: Plua_State): Integer; cdecl;
var iState   : TLuaGameState;
begin
  iState.Init(L);
  iState.Push( UI.ResolveSoundID( iState.ToString(1), iState.ToString(2,'') ) );
  Result := 1;
end;

const lua_ui_lib : array[0..17] of luaL_Reg = (
  ( name : 'msg';               func: @lua_ui_msg),
  ( name : 'msg_kill';          func: @lua_ui_msg_kill),
  ( name : 'blink';             func: @lua_ui_blink),
  ( name : 'choose_dir';        func: @lua_ui_choose_dir),
  ( name : 'enter';             func: @lua_ui_enter),
  ( name : 'draw_fire';         func: @lua_ui_draw_fire),
  ( name : 'render_bg';         func: @lua_ui_render_bg),
  ( name : 'resolve_sound_id';  func: @lua_ui_resolve_sound_id),
  ( name : 'new_window';        func: @lua_ui_new_window),
  ( name : 'get_message_buffer';func: @lua_ui_get_message_buffer),
  ( name : 'save_game';         func: @lua_ui_save_game),
  ( name : 'set_arena';         func: @lua_ui_set_arena),
  ( name : 'get_keybinding';    func: @lua_ui_get_keybinding),
  ( name : 'get_mortem_file';   func: @lua_ui_get_mortem_file),
  ( name : 'get_help_path';     func: @lua_ui_get_help_path),
  ( name : 'get_hof_entry';     func: @lua_ui_get_hof_entry),
  ( name : 'get_hof_current';   func: @lua_ui_get_hof_current),
  ( name : nil;          func: nil; )
);

// Register API
class procedure TBerserkUI.RegisterLuaAPI();
begin
  LuaSystem.Register( 'ui', lua_ui_lib );
end;


end.

