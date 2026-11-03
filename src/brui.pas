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

uses vutil, vio, viorl, vrltools, viotypes, vioevent, vioconsole, vbindings, vsound, vmessages, vlua,
     brdata, brconfiguration, brbeing, brplayer, brlevel;

const
    COMMAND_SKILLS    = [ COMMAND_SKILL1,COMMAND_SKILL2,
                           COMMAND_SKILL3,COMMAND_SKILL4,
                           COMMAND_SKILL5,COMMAND_SKILL6,
                           COMMAND_SKILL7,COMMAND_SKILL8,
                           COMMAND_SKILL9,COMMAND_SKILL0 ];

// Picture
type TPicture = Word;

type
  // Berserk User interface class. Responsible for keeping all the UI in one
  // place. After some twidling, this could allow for a graphics version of
  // Berserk!. All display/input commands should go here.

  { TBerserkUI }

  TBerserkUI = class(TIORL, IBerserkPresentation)
    // Holds the current screen info
    Screen  : (Game,Menu);
    // Initialization of all data.
    constructor Create( aConfiguration : TBerserkConfiguration; const aDataPath : AnsiString ); reintroduce;
    // Runs a layer
    procedure RunLayer( aLayer : TIOLayer ); override;
    function OnEvent( const aEvent : TIOEvent ) : Boolean; override;
    procedure Clear; override;
    procedure ResetSession;
    procedure Reconfigure; virtual;
    procedure PostUpdate; override;
    procedure ShowSettingsError( const aError : AnsiString );
    procedure ShowSettings( aRecoverInput : Boolean = False );
    function GetKeybinding( aCommand : Byte ) : AnsiString;
    function GetUIKeybinding( aAction : TBindingAction ) : AnsiString;
    // Writes a tile description in the msg area.
    procedure MsgCoord( Coord : TCoord2D );
    // Waits for a gameplay command in the active Session.
    function GetCommand(Valid : TCommandSet = []) : byte;
    // Lets the player choose a target. Returns true when in Fire mode the
    // target is accepted.
    function ChooseTarget( aTargetMode : Byte; aFireCmd : Byte ) : Boolean;
    // Interface function for choosing direction. Returns the direction, or 0 if escaped.
    function ChooseDirection : TDirection;
    // Waits for enter key.
    procedure PressEnter;
    // Draws the level, player status, messages, and updates the screen.
    procedure Draw; virtual;
    // Draw the status HUD panel using VTIG
    procedure DrawStatus;
    // Graphical effect of a screen flash, of the given color, and Duration in
    // miliseconds.
    procedure Blink( aColor : Byte; aDuration : Word; aSequence : Word ); virtual; abstract;
    // Converts Commands to Direction values
    function CommandDirection(Command : byte) : TDirection;
    // Moves the cursor to the position x,y in terms of Map coords.
    procedure Focus( Where : TCoord2D );
    procedure CenterCamera( const aWhere : TCoord2D ); virtual;
    // Renders an explosion on the screen.
    procedure AddExplosion( aWhere : TCoord2D; aColor : byte; aRange : byte; aDrawDelay, aSequence : Word ); virtual; abstract;
    // Animates a move if in GFX
    procedure AddMove( aWho : TUID; const aFrom, aTo : TCoord2D ); virtual;
    // Animates an attack if in GFX
    procedure AddAttack( aWho : TUID; aHit : Boolean; const aFrom, aTo : TCoord2D ); virtual;
    // Draws a firey background
    procedure DrawFire; virtual;
    // Renders a nine-patch window
    procedure RenderWindow( aSize, aPos : TIOPoint ); virtual;
    // Draws a firey background
    procedure RenderBG(); virtual;
    // Sends missile
    procedure SendMissile( const aSource, aTarget : TCoord2D; aType : Byte; aSequence : DWord ); virtual; abstract;
    // Draws target X
    procedure Target( Where : TCoord2D; color : Byte); virtual; abstract;
    // Renders a breath weapon attack
    procedure Breath( aWhere : TCoord2D; aDirection : TDirection; aColor : byte; aRange : byte; aDrawDelay : Word ); virtual; abstract;
    // Resolve sound ID
    function ResolveSoundID( const aID, aSound : AnsiString ) : AnsiString;
    // Plays the sound bound to the given being and event
    procedure PlayBeingSound( const aID, aSound : AnsiString; const aWhere : TCoord2D );
    procedure PlayMusic( const aMusicID : AnsiString );
    // The being with the given UID in the current Session, if any.
    function BeingByUID( aUID : TUID ) : TBeing;
    // Register API
    procedure RegisterLuaAPI( aLua : TLua );
  private
    function GetPlayer : TPlayer;
    function GetLevel : TLevel;
  protected
    FConfiguration : TBerserkConfiguration;
    FAudio         : TSound;
    FLua           : TLua;
    FHelpPath      : AnsiString;
    FQuitRequested : Boolean;
    FStatusVisible : Boolean;
  public
    // Non-owning reference to Runtime's audio service.
    property Audio         : TSound  read FAudio write FAudio;
    // Non-owning reference to Runtime's Lua generation.
    property Lua           : TLua    read FLua write FLua;
    property HelpPath      : AnsiString read FHelpPath;
    // The Session's player and level, borrowed; nil outside a Session.
    property Player        : TPlayer read GetPlayer;
    property Level         : TLevel  read GetLevel;
    property QuitRequested : Boolean read FQuitRequested;
    property StatusVisible : Boolean read FStatusVisible write FStatusVisible;
  end;


// Layers reach their IO through their owner, which is set when they are pushed.
type TBerserkLayerHelper = class helper for TIOLayer
  function UI : TBerserkUI;
end;

implementation

uses sysutils, dateutils, variants, math,
     vtigstyle, vtig, vluagamestack, vlualibrary,
     bruiscreens, brsettingsview;

const MESSAGE_BUFFER = 100;

function TBerserkLayerHelper.UI : TBerserkUI;
begin
  Exit( TBerserkUI( Owner ) );
end;

{ TBerserkUI }

constructor TBerserkUI.Create( aConfiguration : TBerserkConfiguration; const aDataPath : AnsiString );
var iConsole : TIOConsoleRenderer;
begin
  // Initialize takes the renderer on success; retain it locally until then.
  iConsole := FConsole;
  FConsole := nil;
  try
    inherited Create( FIODriver, nil );
    Initialize( iConsole );
    iConsole := nil;
  finally
    iConsole.Free;
  end;
  FConfiguration := aConfiguration;
  FHelpPath := aDataPath + 'help' + PathDelim;
  Configure( aConfiguration.LuaConfig );
  VTIGDefaultStyle.Color[ VTIG_INPUT_TEXT_COLOR ]          := White;
  VTIGDefaultStyle.Color[ VTIG_INPUT_BACKGROUND_COLOR ]    := Black;
  VTIGDefaultStyle.Color[ VTIG_SELECTED_BACKGROUND_COLOR ] := Black;
  VTIGDefaultStyle.Color[ VTIG_SELECTED_DISABLED_COLOR ]   := LightRed;
  VTIGDefaultStyle.Color[ VTIG_DISABLED_COLOR ]            := Red;

  VTIGDefaultStyle.Frame[ VTIG_BORDER_FRAME ] := '';
  VTIGDefaultStyle.Frame[ VTIG_GROUP_FRAME ]  := '';
  VTIGDefaultStyle.Padding[ VTIG_WINDOW_PADDING ]     := Point( 2,1 );
  VTIGDefaultStyle.Padding[ VTIG_SELECTABLE_PADDING ] := Point( 0,0 );

  FMessages := TMessages.Create( 8, 28, nil, MESSAGE_BUFFER );
  FStatusVisible := False;

  FIODriver.SetTitle('Berserk!','Berserk!');

  Reconfigure;

  if Config.TableExists( 'Messages' ) then
    Config.EntryFeed( 'Messages', @FMessages.AddHighlightCallback );

  Screen := Menu;

  Msg('Berserk!');
  Msg('Press {^'+GetKeybinding(COMMAND_HELP)+'} for help.');
end;

procedure TBerserkUI.Reconfigure;
var iCommand : Byte;
    iKey : TIOKeyCode;
begin
  if FAudio <> nil then
  begin
    if FAudio.SoundEnabled and not FConfiguration.GetBoolean( 'sound_enabled' ) then
      FAudio.StopSound;
    FAudio.SoundEnabled := FConfiguration.GetBoolean( 'sound_enabled' );
    FAudio.SetSoundVolume( FConfiguration.GetInteger( 'volume_sound' ) );
    // Keep track changes while muted, so unmuting resumes the appropriate music.
    if FConfiguration.GetBoolean( 'music_enabled' ) then
      FAudio.SetMusicVolume( FConfiguration.GetInteger( 'volume_music' ) )
    else
      FAudio.SetMusicVolume( 0 );
  end;
  GameBindings.Clear;
  GameBindings.LoadKeys( FConfiguration.GameKeyBindings );
  if GodMode then FConfiguration.LuaConfig.LoadGodKeys( GameBindings );
  for iCommand in COMMAND_SKILLS do
  begin
    iKey := GameBindings.GetKey( iCommand );
    if iKey = 0 then Continue;
    iKey := iKey or IOKeyCodeShiftMask;
    if GameBindings.ResolveKey( iKey ) = BINDING_NONE then
      GameBindings.BindKey( iKey, iCommand + COMMAND_SKILLALTSHIFT );
  end;
  UIBindings.Clear;
  UIBindings.LoadKeys( FConfiguration.UIKeyBindings );
end;

procedure TBerserkUI.PostUpdate;
begin
  inherited PostUpdate;
  if not FLayers.IsEmpty then
    if FLayers.Top is TBerserkSettingsView then
      TBerserkSettingsView( FLayers.Top ).ApplyPending;
end;

procedure TBerserkUI.ShowSettingsError( const aError : AnsiString );
begin
  if FLayers.IsEmpty or not ( FLayers.Top is TBerserkSettingsView ) then ShowSettings;
  TBerserkSettingsView( FLayers.Top ).ReportError( aError );
end;

procedure TBerserkUI.ShowSettings( aRecoverInput : Boolean = False );
var iView : TBerserkSettingsView;
begin
  Screen := Menu;
  FStatusVisible := False;
  FConsole.Clear;
  iView := TBerserkSettingsView.Create( FConfiguration, @Reconfigure );
  PushLayer( iView );
  if aRecoverInput then iView.RecoverUIBindings;
end;

function TBerserkUI.GetKeybinding( aCommand : Byte ) : AnsiString;
var iKey : TIOKeyCode;
begin
  iKey := GameBindings.GetKey( aCommand );
  if iKey = 0 then Exit( 'Unbound' );
  Result := IOKeyCodeToString( iKey );
end;

function TBerserkUI.GetUIKeybinding( aAction : TBindingAction ) : AnsiString;
var iKey : TIOKeyCode;
begin
  iKey := UIBindings.GetKey( aAction );
  if iKey = 0 then Exit( 'Unbound' );
  Result := IOKeyCodeToString( iKey );
end;

procedure TBerserkUI.DrawStatus;
const SX = 50; // status panel X offset
var iCt     : Word;

  function GetSkillString( aSkillSlot : Byte ) : AnsiString;
  var iSkill  : DWord;
      iAmmo   : Byte;
  begin
    iSkill  := Player.FSkillSlots[ iCt ];
    Result  := '{^'+GetKeybinding( COMMAND_SKILL1-1+aSkillSlot ) + '}:' + Player.Context.Lua.Get(['skills',iSkill,'name_short']);
    iAmmo   := Player.Context.Lua.Get(['skills',iSkill,'ammo_slot']);
    if iAmmo <> 0 then
    begin
      Result  += ' {^'+IntToStr( Player.FAmmo[ iAmmo ] )+'}';
      iAmmo   := Player.Context.Lua.Get(['skills',iSkill,'quiver_slot']);
      if iAmmo <> 0 then Result += '/{^'+IntToStr( Player.FAmmo[ iAmmo ] )+'}';
    end;
  end;

  procedure DrawBar( aMax, aCur : Integer; aRow : Byte; aColor : Byte; aSpec : Word = 0; aColorSpec : Byte = 0 );
  var iFull, iFull2, iCount : Byte;
      iCharColor : Byte;
  begin
    iFull  := math.Max(Round(aCur*28/aMax),0);
    iFull2 := math.Max(Round(aSpec*28/aMax),0);
    for iCount := 1 to 28 do
    begin
      if (aColorSpec <> 0) and (iCount <= iFull2)
        then iCharColor := aColorSpec
        else iCharColor := aColor;
      if iCount <= iFull
        then VTIG_FreeChar( '#', Point(SX+iCount, aRow), iCharColor )
        else VTIG_FreeChar( '-', Point(SX+iCount, aRow), iCharColor );
    end;
  end;

var iCount    : Integer;
    iMsgStart : Integer;
begin
  with Player do
  begin
    VTIG_FreeLabel( Name+', the Berserker', Point(SX+1,0), Yellow );
    VTIG_FreeLabel( Format('Str:{^%d} Dex:{^%d} End:{^%d} Wil:{^%d}',[ST,DX,EN,WP]), Point(SX+1,1), DarkGray );

    VTIG_FreeLabel( Format('Health : {R%d}{d/%d}',[FHP,FHPMax]), Point(SX+1,3), DarkGray );
    DrawBar( FHPMax, FHP, 4, LightRed, FHealthMark, Red );
    VTIG_FreeLabel( Format('Energy : {Y%d}{d/%d}',[FEN,FENMax]), Point(SX+1,5), DarkGray );
    DrawBar( FENMax, FEN, 6, Yellow );

    for iCt := Low( FSkillSlots ) to 5 do
      if FSkillSlots[ iCt ] <> 0 then
        VTIG_FreeLabel( GetSkillString( iCt ), Point(SX+1,7+iCt), DarkGray );
    for iCt := 6 to High( FSkillSlots ) do
      if FSkillSlots[ iCt ] <> 0 then
        VTIG_FreeLabel( GetSkillString( iCt ), Point(SX+18,7+iCt-5), DarkGray );

    if isBerserk   then VTIG_FreeLabel( 'BERSERK', Point(SX+21,13), Red );
    if isRunning   then VTIG_FreeLabel( 'RUNNING', Point(SX+1,13), Yellow );

    if FPain > 0    then
      VTIG_FreeLabel( Format('Pain ({^-%d})',[FPain]), Point(SX+1,14), Red );
    if FFreeze > 0  then
      VTIG_FreeLabel( Format('Frz ({^-%d})',[FFreeze]), Point(SX+12,14), LightBlue );
    if isBerserk then
      if EnemiesAround div 2 > 0 then
        VTIG_FreeLabel( Format('Brk ({^+%d})',[EnemiesAround div 2]), Point(SX+21,14), Red );

    VTIG_FreeLabel( '---------------------------', Point(SX+1,15), DarkGray );
    if FMode <> MODE_MASSACRE then
    begin
      iCt := Max(Min(Round((Level.FTickCount/NIGHTDURATION)*28),28),1);
      VTIG_FreeChar( '=', Point(SX+iCt,15), LightGray );
      if iCt < 14
        then VTIG_FreeLabel( Format(' Night %d ',[Player.FNight]), Point(SX+18,15), DarkGray )
        else VTIG_FreeLabel( Format(' Night %d ',[Player.FNight]), Point(SX+2,15), DarkGray );
    end;

    // Messages area (rows 16-23)
    if FMessages <> nil then
    begin
      iMsgStart := FMessages.Content.Size - 8;
      if iMsgStart < 0 then iMsgStart := 0;
      for iCount := 0 to 7 do
        if iMsgStart + iCount < Integer(FMessages.Content.Size) then
          if iMsgStart + iCount >= Integer(FMessages.Content.Size) - Integer(FMessages.Active)
            then VTIG_FreeLabel( FMessages.Content[ iMsgStart + iCount - Integer(FMessages.Content.Size) ], Point(SX+1,16+iCount), LightGray )
            else VTIG_FreeLabel( FMessages.Content[ iMsgStart + iCount - Integer(FMessages.Content.Size) ], Point(SX+1,16+iCount), DarkGray );
    end;

    if FConfiguration.GetBoolean( 'kill_count' ) then
      VTIG_FreeLabel( Format('[{r%d}]',[Player.GetKills]), Point(SX+20,24), DarkGray );
  end;
end;

procedure TBerserkUI.RunLayer( aLayer : TIOLayer );
var iOverlay : Boolean;
begin
  if FQuitRequested then
  begin
    aLayer.Free;
    Exit;
  end;
  iOverlay := aLayer is TInGameMenuLayer;
  if iOverlay then
    Draw
  else
  begin
    FStatusVisible := False;
    FConsole.Clear;
  end;
  FConsole.HideCursor;
  inherited RunLayer( aLayer );
  if iOverlay then Draw;
end;

function TBerserkUI.OnEvent( const aEvent : TIOEvent ) : Boolean;
var iLayer : TIOLayer;
begin
  if ( aEvent.EType = VEVENT_SYSTEM ) and ( aEvent.System.Code = VIO_SYSEVENT_QUIT ) then
  begin
    FQuitRequested := True;
    for iLayer in FLayers do iLayer.Finish;
    BreakKeyLoop;
    Exit( False );
  end;
  Result := inherited OnEvent( aEvent );
end;

procedure TBerserkUI.Clear;
begin
  inherited Clear;
  FTIGConsoleView := nil;
  ClearAnimations;
  FStatusVisible := False;
  Screen := Menu;
end;

procedure TBerserkUI.ResetSession;
const Windows : array[0..5] of AnsiString = ( 'mode', 'arena', 'name', 'stats', 'skill', 'night' );
var i : Integer;
begin
  Clear;
  MsgClear;
  MarkClear;
  if FTMap <> nil then FTMap.Shift := Point( 0, 0 );
  Console.Clear;
  Console.HideCursor;
  for i := Low( Windows ) to High( Windows ) do VTIG_Reset( Windows[i] );
end;

function TBerserkUI.ResolveSoundID(const aID, aSound: AnsiString): AnsiString;
begin
  if FLua = nil then Exit('');
  if aSound = '' then Exit( FLua.Get( ['sounds',aID], '' ) );
  if FLua.Defined( ['sounds',aID,aSound] ) then Exit( FLua.Get( ['sounds',aID,aSound] ) );
  Exit( FLua.Get( ['sounds',aSound], '' ) );
end;

procedure TBerserkUI.PlayBeingSound( const aID, aSound : AnsiString; const aWhere : TCoord2D );
var iSound : AnsiString;
begin
  if FAudio = nil then Exit;
  iSound := ResolveSoundID( aID, aSound );
  if iSound <> '' then FAudio.PlaySample( iSound, aWhere );
end;

function TBerserkUI.GetPlayer : TPlayer;
begin
  Exit( TPlayer( FPlayer ) );
end;

function TBerserkUI.GetLevel : TLevel;
begin
  Exit( TLevel( FLevel ) );
end;

function TBerserkUI.BeingByUID( aUID : TUID ) : TBeing;
begin
  if FLevel = nil then Exit( nil );
  Exit( FLevel.Context.UIDs.Get( aUID ) as TBeing );
end;

procedure TBerserkUI.PlayMusic( const aMusicID : AnsiString );
begin
  if FAudio <> nil then FAudio.PlayMusic( aMusicID );
end;

procedure TBerserkUI.MsgCoord ( Coord : TCoord2D ) ;
begin
  MsgKill;
  if Level.Vision.isVisible( Coord ) then
    if Level.Being[ Coord ] <> nil then
      Msg(Level.Being[ Coord ].LookDescribe)
    else
      Msg(Level.Terrain[ Coord ].Name)
  else
    Msg('nothing');
end;

function TBerserkUI.GetCommand( Valid : TCommandSet ) : Byte;
var iEvent : TIOEvent;
    iAction : TBindingAction;
    iValue : Variant;
begin
  if FQuitRequested then Exit( COMMAND_SYSQUIT );
  if FAudio <> nil then FAudio.Listener := Player.Position;
  FStatusVisible := True;
  repeat
    if not WaitForKeyEvent( iEvent ) then Exit( 0 );
    if FQuitRequested then Exit( COMMAND_SYSQUIT );
    if IsModal then Continue;
    FKeyCode := IOKeyEventToIOKeyCode( iEvent.Key );
    iAction := GameBindings.ResolveKey( FKeyCode );
    if iAction = BINDING_FORWARD_LUA then
    begin
      if Player.Died then Continue;
      iValue := FConfiguration.LuaConfig.RunGodKey( FKeyCode );
      if VarIsOrdinal( iValue ) and not VarIsType( iValue, varBoolean )
        then iAction := Integer( iValue )
        else Continue;
    end;
    if ( iAction <= 0 ) or ( iAction > High( Byte ) ) then Continue;
    if ( Valid = [] ) or ( Byte( iAction ) in Valid ) then Exit( Byte( iAction ) );
  until False;
end;

function TBerserkUI.ChooseTarget( aTargetMode : Byte; aFireCmd : Byte ) : Boolean;
var iDir     : TDirection;
    iKey     : Byte;
    iTargets : TAutoTarget;
    iTarget  : TCoord2D;
    iOrigin  : TCoord2D;
    iRadius  : Byte;
    iX, iY   : Integer;
    iAISet   : TAITypeSet;
begin
  Msg('--------------------');
  iOrigin  := Player.Position;
  iRadius  := Player.LightRadius;
  iTargets := TAutoTarget.Create( iOrigin );

  if Player.isBerserk then iAISet := [AI_MONSTER,AI_CIVILIAN,AI_ALLY]
                      else iAISet := [AI_MONSTER];

  for iX := Max(1,iOrigin.x-iRadius-1) to Min(MAP_MAXX,iOrigin.x+iRadius+1) do
    for iY := Max(1,iOrigin.y-iRadius-1) to Min(MAP_MAXY,iOrigin.y+iRadius+1) do
    begin
      iTarget := NewCoord2D( iX,iY );
      if Level.Being[ iTarget ] <> nil then
        if Level.Being[ iTarget ].FAI in iAISet then
         if Player.isInLOS( iTarget ) then
           iTargets.AddTarget( iTarget );
    end;

  if aTargetMode in [TM_FIRE,TM_THROW] then
    if Player.FTarget <> nil then
      iTargets.PriorityTarget( Player.FTarget.Position );

  iTarget := iTargets.Current;

  repeat
    if aTargetMode = TM_FIRE then
      Target(iTarget,RED);
    if aTargetMode = TM_THROW then
    begin
      if Distance(iOrigin,iTarget) > BOMBDISTANCE
        then Target(iTarget,DarkGray)
        else Target(iTarget,Red);
    end;
    Focus(iTarget);
    MsgCoord(iTarget);

    if aTargetMode in [TM_FIRE,TM_THROW] then
      iKey := GetCommand(COMMANDS_MOVE+[COMMAND_ESCAPE,COMMAND_RUNNING, aFireCmd ])
    else
      iKey := GetCommand(COMMANDS_MOVE+[COMMAND_ESCAPE,COMMAND_RUNNING]);
    if FQuitRequested or ( iKey = COMMAND_ESCAPE ) then begin iTarget := ZeroCoord2D; Break; end;
    if iKey = COMMAND_RUNNING then iTarget := iTargets.Next;
    if iKey in COMMANDS_MOVE then
    begin
      iDir := CommandDirection(iKey);
      if Level.isProperCoord(iTarget + iDir) then
        iTarget += iDir;
    end;
  until iKey in [aFireCmd];
  Target(iTarget,BLACK);
  Player.FTargetCoord := iTarget;

  FreeAndNil(iTargets);

  if iTarget.x = 0 then Exit(False);
  if Level.Being[ iTarget ] <> nil then Player.FTarget := Level.Being[ iTarget ];
  Exit(True);
end;

function TBerserkUI.ChooseDirection : TDirection;
begin
  Exit(CommandDirection(GetCommand(COMMANDS_MOVE+[COMMAND_ESCAPE])));
end;

procedure TBerserkUI.Draw;
begin
  FConsole.Clear;
  if Screen <> Game then Exit;
  Focus(Player.Position);
  Level.Vision.Run(Player.Position,Player.LightRadius);
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

procedure TBerserkUI.CenterCamera( const aWhere : TCoord2D );
begin
end;

procedure TBerserkUI.AddMove(aWho: TUID; const aFrom, aTo: TCoord2D);
begin

end;

procedure TBerserkUI.AddAttack(aWho: TUID; aHit: Boolean; const aFrom, aTo: TCoord2D);
begin
end;

procedure TBerserkUI.DrawFire;
begin

end;

procedure TBerserkUI.RenderWindow( aSize, aPos : TIOPoint );
begin

end;

procedure TBerserkUI.RenderBG;
begin

end;

procedure TBerserkUI.PressEnter;
begin
  GetCommand([COMMAND_OK]);
end;

function lua_ui( L : PLua_State ) : TBerserkUI;
begin
  Exit( TBerserkUI( lua_touserdata( L, lua_upvalueindex( 1 ) ) ) );
end;

function lua_ui_msg(L: Plua_State): Integer; cdecl;
var State : TLuaGameStack;
begin
  State.Init(L);
  if State.StackSize = 0 then Exit(0);
  lua_ui( L ).Msg(State.ToString(1));
  Result := 0;
end;

function lua_ui_msg_kill(L: Plua_State): Integer; cdecl;
begin
  lua_ui( L ).MsgKill;
  Result := 0;
end;

function lua_ui_blink(L: Plua_State): Integer; cdecl;
var State : TLuaGameStack;
begin
  State.Init(L);
  lua_ui( L ).Blink( State.ToInteger( 1 ), State.ToInteger( 2, 50 ), State.ToInteger( 3, 0 ) );
  Result := 0;
end;

function lua_ui_choose_dir(L: Plua_State): Integer; cdecl;
var State : TLuaGameStack;
    Dir   : TDirection;
begin
  State.Init(L);
  Dir := lua_ui( L ).ChooseDirection;
  if Dir.code = 0
    then State.PushNil
    else State.PushCoord( Dir.ToCoord );
  Result := 1;
end;

function lua_ui_enter(L: Plua_State): Integer; cdecl;
begin
  lua_ui( L ).PressEnter;
  Result := 0;
end;

function lua_ui_resolve_sound_id(L: Plua_State): Integer; cdecl;
var iState   : TLuaGameStack;
begin
  iState.Init(L);
  iState.Push( lua_ui( L ).ResolveSoundID( iState.ToString(1), iState.ToString(2,'') ) );
  Result := 1;
end;

function lua_ui_get_keybinding(L: Plua_State): Integer; cdecl;
var iState   : TLuaGameStack;
begin
  iState.Init(L);
  iState.Push( lua_ui( L ).GetKeybinding( iState.ToInteger(1) ) );
  Result := 1;
end;

const lua_ui_lib : array[0..7] of luaL_Reg = (
  ( name : 'msg';               func: @lua_ui_msg),
  ( name : 'msg_kill';          func: @lua_ui_msg_kill),
  ( name : 'blink';             func: @lua_ui_blink),
  ( name : 'choose_dir';        func: @lua_ui_choose_dir),
  ( name : 'enter';             func: @lua_ui_enter),
  ( name : 'resolve_sound_id';  func: @lua_ui_resolve_sound_id),
  ( name : 'get_keybinding';    func: @lua_ui_get_keybinding),
  ( name : nil;          func: nil; )
);

// Register API
procedure TBerserkUI.RegisterLuaAPI( aLua : TLua );
begin
  lua_pushlightuserdata( aLua.Raw, Self );
  aLua.Register( 'ui', lua_ui_lib, 1 );
end;


end.
