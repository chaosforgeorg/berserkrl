// @abstract(BerserkRL -- User Interface screens)
// @author(Kornel Kisielewicz <admin@chaosforge.org>)
// @created(Apr 8, 2024)
// @lastmod(Apr 8, 2024)
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
unit bruiscreens;
interface
uses vioevent, viotypes, vtigstyle, brpersistence;

type TScreenLayer = class( TIOLayer )
  constructor Create;
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  function IsModal : Boolean; override;
end;

type TMenuLayer = class( TScreenLayer )
  constructor Create( const aID : AnsiString );
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
protected
  FID : AnsiString;
  procedure BeginMenu( aHeight : Integer ); virtual;
  procedure DrawMenu; virtual; abstract;
end;

type TLogoMenuLayer = class( TMenuLayer )
protected
  procedure BeginMenu( aHeight : Integer ); override;
end;

type TMainMenuResult = ( MMR_QUIT, MMR_NEW_GAME, MMR_CONTINUE );

type TMainMenuLayer = class( TLogoMenuLayer )
  constructor Create( aPersistence : TPersistence; const aSavePath : AnsiString;
    var aResult : TMainMenuResult );
protected
  procedure DrawMenu; override;
private
  FPersistence : TPersistence;
  FSavePath : AnsiString;
  FHasSave, FNewGame : Boolean;
  FResult : ^TMainMenuResult;
end;

type THighscoreMenuLayer = class( TLogoMenuLayer )
  constructor Create( aPersistence : TPersistence );
protected
  procedure DrawMenu; override;
private
  FPersistence : TPersistence;
end;

type TNewGameMenuLayer = class( TLogoMenuLayer )
  constructor Create( const aSavePath : AnsiString; var aConfirmed : Boolean );
protected
  procedure DrawMenu; override;
private
  FSavePath : AnsiString;
  FConfirmed : ^Boolean;
  FRemoveFailed : Boolean;
end;

type TLoadErrorLayer = class( TLogoMenuLayer )
  constructor Create( const aError : AnsiString );
protected
  procedure DrawMenu; override;
private
  FError : AnsiString;
end;

type TInGameMenuLayer = class( TMenuLayer )
  constructor Create;
protected
  procedure DrawMenu; override;
end;

type TAbandonRunLayer = class( TMenuLayer )
  constructor Create;
protected
  procedure DrawMenu; override;
end;

type TCreationLayer = class( TScreenLayer )
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
end;

type TIntroLayer = class( TScreenLayer )
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
end;

type TOutroLayer = class( TScreenLayer )
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
end;

type TNightLayer = class( TScreenLayer )
  constructor Create;
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
protected
  FQuote  : Ansistring;
  FError  : AnsiString;
end;

type TGameModeLayer = class( TCreationLayer )
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
end;

type TGameArenaLayer = class( TCreationLayer )
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
end;

type TGameNameLayer = class( TCreationLayer )
  constructor Create;
  destructor Destroy; override;
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
protected
  FName : array[0..32] of Char;
end;

type TGameStatsLayer = class( TCreationLayer )
  constructor Create;
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
protected
  FInitial  : array[0..3] of Integer;
  FText     : Ansistring;
  FDoneText : Ansistring;
end;

type TGameSkillInfo = record
  Name  : Ansistring;
  Entry : Ansistring;
  Desc  : Ansistring;
  Max   : Integer;
  Reqs  : Ansistring;
  Pic   : Ansistring;
  Allow : Boolean;
  Index : Integer;
end;

type TGameSkillsLayer = class( TCreationLayer )
  constructor Create;
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
protected
  FSkillData : array of TGameSkillInfo;
end;

type TGamePlayerLayer = class( TScreenLayer )
  constructor Create;
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
protected
  FStyle  : TTIGStyle;
  FAmmo   : Ansistring;
  FSkills : Ansistring;
end;

type TFullScreenLayer = class( TIOLayer )
  constructor Create;
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  function IsModal : Boolean; override;
protected
  FHeader   : Ansistring;
  FFooter   : Ansistring;
end;

type TScrollingLayer = class( TFullScreenLayer )
  constructor Create( aContent : TIOStringArray );
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  destructor Destroy; override;
protected
  FContent    : TIOStringArray;
  FScrollDown : Boolean;
  FStyle      : TTIGStyle;
end;

type TMortemLayer = class( TScrollingLayer )
  constructor Create;
end;

type TMessagesLayer = class( TScrollingLayer )
  constructor Create;
end;

type THOFLayer = class( TScrollingLayer )
  constructor Create( aPersistence : TPersistence; aMode : Byte; aHighlight : Boolean = False );
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
protected
  FCurrent : Integer;
end;

type THelpLayer = class( TScrollingLayer )
  constructor Create;
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  destructor Destroy; override;
protected
  FKeys  : TIOStringArray;
//  FStyle : TTIGStyle;
end;

implementation

uses sysutils, vutil, vtig, vtigio, vluasystem, vluatable, vxmldata,
     brdata, brui, brplayer, brmain;

constructor TScreenLayer.Create;
begin
  VTIG_EventClear;
end;

procedure TScreenLayer.Update( aDTime : Integer; aActive : Boolean );
begin
  UI.DrawFire;
  UI.RenderBG();
end;

function TScreenLayer.IsModal : Boolean;
begin
  Exit( True );
end;

constructor TMenuLayer.Create( const aID : AnsiString );
begin
  inherited Create;
  FID := aID;
  VTIG_Reset( FID );
  VTIG_ResetSelect( FID );
end;

procedure TMenuLayer.Update( aDTime : Integer; aActive : Boolean );
begin
  if aActive then DrawMenu;
end;

procedure TMenuLayer.BeginMenu( aHeight : Integer );
var iSize, iPosition : TIOPoint;
begin
  iSize := Point( 32, aHeight );
  iPosition := Point( (50-iSize.X) div 2 + 1, (25-iSize.Y) div 2 + 1 );
  UI.RenderWindow( iSize, iPosition );
  VTIG_Begin( FID, iSize, iPosition );
  VTIG_BringToTop( FID );
end;

procedure TLogoMenuLayer.BeginMenu( aHeight : Integer );
begin
  UI.DrawFire;
  UI.RenderBG;
  UI.RenderWindow( Point( 49, 8 ), Point( 17, 6 ) );
  VTIG_Begin( 'title', Point( 49, 8 ), Point( 17, 6 ) );
  VTIG_Text('{R   #####  ### #####   #  ### ##### #  #   ##}');
  VTIG_Text('{R   #  #  ##   #  #   #  ##   #  #  #  #   ##}');
  VTIG_Text('{R   ####  # ## ####  #   # ## ####  ###    ##}');
  VTIG_Text('{R    # ## ##    # # #### ##    # #   # #   #}');
  VTIG_Text('{R    # #   ###  # #  #    ###  # #   #  #}');
  VTIG_Text('{R    ##    #   #  # #     #   #  #   #  #  #}');
  VTIG_End;
  UI.RenderWindow( Point( 49, aHeight ), Point( 17, 15 ) );
  VTIG_Begin( FID, Point( 49, aHeight ), Point( 17, 15 ) );
  VTIG_BringToTop( FID );
end;

constructor TMainMenuLayer.Create( aPersistence : TPersistence;
  const aSavePath : AnsiString; var aResult : TMainMenuResult );
begin
  inherited Create( 'main_menu' );
  FPersistence := aPersistence;
  FSavePath := aSavePath;
  FHasSave := FileExists( FSavePath );
  FResult := @aResult;
  aResult := MMR_QUIT;
end;

procedure TMainMenuLayer.DrawMenu;
begin
  if FNewGame then
  begin
    FResult^ := MMR_NEW_GAME;
    FFinished := True;
    Exit;
  end;
  BeginMenu( 7 );
  if VTIG_Selectable( 'New Game' ) then
    if FHasSave
      then UI.PushLayer( TNewGameMenuLayer.Create( FSavePath, FNewGame ) )
      else begin FResult^ := MMR_NEW_GAME; FFinished := True; end;
  if VTIG_Selectable( 'Continue', FHasSave ) then
  begin
    FResult^ := MMR_CONTINUE;
    FFinished := True;
  end;
  if VTIG_Selectable( 'Hall of Fame' ) then UI.PushLayer( THighscoreMenuLayer.Create( FPersistence ) );
  if VTIG_Selectable( 'Help' ) then UI.PushLayer( THelpLayer.Create );
  if VTIG_Selectable( 'Quit' ) or VTIG_EventCancel then FFinished := True;
  VTIG_End;
end;

constructor THighscoreMenuLayer.Create( aPersistence : TPersistence );
begin
  inherited Create( 'highscore_menu' );
  FPersistence := aPersistence;
end;

procedure THighscoreMenuLayer.DrawMenu;
begin
  BeginMenu( 5 );
  if VTIG_Selectable( 'Endless' ) then UI.PushLayer( THOFLayer.Create( FPersistence, mode_Endless ) );
  if VTIG_Selectable( 'Massacre' ) then UI.PushLayer( THOFLayer.Create( FPersistence, mode_Massacre ) );
  if VTIG_Selectable( 'Back' ) or VTIG_EventCancel then FFinished := True;
  VTIG_End;
end;

constructor TNewGameMenuLayer.Create( const aSavePath : AnsiString; var aConfirmed : Boolean );
begin
  inherited Create( 'new_game_menu' );
  FSavePath := aSavePath;
  FConfirmed := @aConfirmed;
  aConfirmed := False;
end;

procedure TNewGameMenuLayer.DrawMenu;
begin
  if FRemoveFailed then
  begin
    BeginMenu( 7 );
    VTIG_Text( '{RNew Game}' );
    VTIG_Text( '' );
    VTIG_Text( 'Could not remove the saved run.' );
    VTIG_Text( '' );
    if VTIG_Selectable( 'Return' ) or VTIG_EventCancel then FFinished := True;
  end
  else
  begin
    BeginMenu( 8 );
    VTIG_Text( '{RNew Game}' );
    VTIG_Text( '' );
    VTIG_Text( 'Discard the saved run and start a new game?' );
    VTIG_Text( '' );
    if VTIG_Selectable( 'Keep saved run' ) or VTIG_EventCancel then FFinished := True;
    if VTIG_Selectable( 'Discard saved run' ) then
    begin
      if DeleteFile( FSavePath ) then
      begin
        FConfirmed^ := True;
        FFinished := True;
      end
      else
      begin
        FRemoveFailed := True;
        VTIG_ResetSelect( FID );
      end;
    end;
  end;
  VTIG_End;
end;

constructor TLoadErrorLayer.Create( const aError : AnsiString );
begin
  inherited Create( 'load_error' );
  FError := aError;
end;

procedure TLoadErrorLayer.DrawMenu;
begin
  BeginMenu( 10 );
  VTIG_Text( '{RLoad failed}' );
  VTIG_Text( '' );
  VTIG_Text( FError );
  VTIG_Scrollbar;
  VTIG_End( ' {lEnter} or {lEscape} to return ' );
  if VTIG_EventConfirm or VTIG_EventCancel then FFinished := True;
end;

constructor TInGameMenuLayer.Create;
begin
  inherited Create( 'in_game_menu' );
end;

procedure TInGameMenuLayer.DrawMenu;
begin
  if Berserk.Finished then
  begin
    FFinished := True;
    Exit;
  end;
  if UI.Screen = Menu then
  begin
    UI.Screen := Game;
    UI.StatusVisible := True;
    UI.Draw;
  end;
  BeginMenu( 5 );
  if VTIG_Selectable( 'Continue' ) or VTIG_EventCancel then FFinished := True;
  if VTIG_Selectable( 'Help' ) then
  begin
    UI.Screen := Menu;
    UI.StatusVisible := False;
    UI.Console.Clear;
    UI.PushLayer( THelpLayer.Create );
  end;
  if VTIG_Selectable( 'Abandon run' ) then UI.PushLayer( TAbandonRunLayer.Create );
  VTIG_End;
end;

constructor TAbandonRunLayer.Create;
begin
  inherited Create( 'abandon_run' );
end;

procedure TAbandonRunLayer.DrawMenu;
begin
  BeginMenu( 8 );
  VTIG_Text( '{RAbandon run}' );
  VTIG_Text( '' );
  VTIG_Text( 'End this run without saving?' );
  VTIG_Text( '' );
  if VTIG_Selectable( 'Keep playing' ) or VTIG_EventCancel then FFinished := True;
  if VTIG_Selectable( 'Abandon run' ) then
  begin
    Berserk.Finish( BSR_ABANDONED );
    FFinished := True;
  end;
  VTIG_End;
end;

procedure TCreationLayer.Update( aDTime : Integer; aActive : Boolean );
begin
  inherited Update( aDTime, aActive );
  if aActive and Berserk.Creating and VTIG_EventCancel then
  begin
    Berserk.Finish( BSR_CANCELLED );
    FFinished := True;
  end;
end;

constructor TFullScreenLayer.Create;
begin
  VTIG_EventClear;
  FHeader   := '';
  FFooter   := ' Use {!arrows}, {!PgUp}, {!PgDown} to scroll, {!Escape} or {!Enter} to exit.';
end;

procedure TFullScreenLayer.Update( aDTime : Integer; aActive : Boolean );
begin
  UI.RenderBG();
end;

function TFullScreenLayer.IsModal : Boolean;
begin
  Exit( True );
end;

constructor TScrollingLayer.Create( aContent : TIOStringArray );
begin
  inherited Create;
  VTIG_ResetScroll( 'scrolling_view' );
  FContent := aContent;
  FScrollDown := False;
  FStyle    := VTIGDefaultStyle;
  FStyle.Padding[ VTIG_WINDOW_PADDING ] := Point( 1,1 );
  FStyle.Frame[ VTIG_BORDER_FRAME ]     := #196+#196+'  '+#196+#196+#196+#196;
end;

procedure TScrollingLayer.Update( aDTime : Integer; aActive : Boolean );
var i : Integer;
begin
  VTIG_PushStyle( @FStyle );
  VTIG_BeginWindow( FHeader, 'scrolling_view', VTIG_GetIOState.Size );
  if FContent.Size > 0 then
    for i := 0 to FContent.Size-1 do
      VTIG_Text( FContent[i] );
  if FContent.Size > 22 then
    VTIG_Scrollbar( FScrollDown );
  FScrollDown := False;
  VTIG_End( FFooter );
  VTIG_PopStyle;
  if VTIG_EventConfirm or VTIG_EventCancel then FFinished := True;
  inherited Update( aDTime, aActive );
end;

destructor TScrollingLayer.Destroy;
begin
  FreeAndNil( FContent );
  inherited Destroy;
end;

constructor TMortemLayer.Create;
begin
  inherited Create( TextFileToIOStringArray( WritePath + 'mortem.txt' ) );
  FHeader := ' {!Berserk!} Post Mortem (mortem.txt)';
end;

constructor TMessagesLayer.Create;
var iMsg    : AnsiString;
begin
  inherited Create( nil );
  FHeader := ' {!Berserk!} Previous messages';
  FContent := TIOStringArray.Create;
  for iMsg in UI.Messages.Content do
    FContent.Push( iMsg );
  FScrollDown := True;
end;

constructor THOFLayer.Create( aPersistence : TPersistence; aMode : Byte; aHighlight : Boolean );
var i, iR  : DWord;
    iEntry : TScoreEntry;
    iMode  : Ansistring;
    iT, iK : Ansistring;
    iName  : Ansistring;
    iLine  : Ansistring;
    iMaxB  : Integer;
begin
  inherited Create( nil );
  FContent := TIOStringArray.Create;
  FCurrent := -1;
  if aHighlight then FCurrent := Integer( aPersistence.GetCurrent );
  i := 0;
  iMode := IntToStr( aMode );
  iMaxB := LuaSystem.Get(['beings','__counter']);
  repeat
    Inc( i );
    iEntry := aPersistence.Get( i );
    if iEntry = nil then Break;
    if iEntry.GetAttribute('mode') = iMode then
    begin
      iName := iEntry.GetAttribute('name');
      iT    := iEntry.GetAttribute('turns');
      iK    := iEntry.GetAttribute('kills');
      iR    := StrToInt( iEntry.GetAttribute('result') );
      iLine := Padded('{!'+iName+'}',17)+' '+Padded('survived {!'+iT+'} turns', 25) + ' ' + Padded('{!'+iK+'} kills',15)+' ';
      if ( iR > 1 ) and ( iR <= iMaxB )
        then iLine += 'killed by {!'+LuaSystem.Get(['beings',iR,'name'])+'}'
        else iLine += 'commited suicide';
      if i = FCurrent then iLine := '{y'+iLine+'}';
      FContent.Push( iLine );
    end;
  until False;

  FHeader := ' {!Berserk!} Hall of Fame : {!'+ModeToString( aMode )+'}';
end;

procedure THOFLayer.Update( aDTime : Integer; aActive : Boolean );
begin
  inherited Update( aDTime, aActive );
  if FCurrent >= 0 then
  begin
    VTIG_ResetScroll( 'scrolling_view', FCurrent - 10 );
    FCurrent := -1;
  end;
end;

type THelpInfo = record
  Name     : Ansistring;
  Filename : Ansistring;
end;

const HelpData : array[0..4] of THelpInfo = (
  ( Name : '  Getting Started'; Filename : 'start.hlp'; ),
  ( Name : '  Tips and Tricks'; Filename : 'tips.hlp'; ),
  ( Name : '  Feedback';        Filename : 'feedback.hlp'; ),
  ( Name : '  Credits';         Filename : 'credits.hlp'; ),
  ( Name : '  Disclaimer';      Filename : 'disclaim.hlp'; ) );

type TKeyInfo = record
  Entry   : Ansistring;
  Command : Byte;
end;

const KeyData : array[0..5] of TKeyInfo = (
  ( Entry : 'Wait a turn';      Command : COMMAND_WAIT; ),
  ( Entry : 'Look mode';        Command : COMMAND_LOOK; ),
  ( Entry : 'Run mode';         Command : COMMAND_RUNNING; ),
  ( Entry : 'Character screen'; Command : COMMAND_PLAYERINFO; ),
  ( Entry : 'Game menu';        Command : COMMAND_QUIT; ),
  ( Entry : 'Help';             Command : COMMAND_HELP; ) );

constructor THelpLayer.Create;
var i, iSid : Integer;
begin
  inherited Create( nil );
  FKeys := TIOStringArray.Create;
  for i := 0 to High( KeyData ) do
    FKeys.Push( Padded( KeyData[i].Entry, 17 ) +' {!' + UI.Config.GetKeybinding( KeyData[i].Command ) + '}' );
  if Player <> nil then
    for i := 1 to SKILL_SLOTS do
    begin
      iSid := Player.FSkillSlots[ i ];
      if ( iSid > 0 ) and ( Player.FSkills[ i ] > 0 ) then
      with LuaSystem.GetTable( ['skills', iSid] ) do
      try
        if IsFunction('OnUse')    then FKeys.Push( Padded( GetString('name_use'), 17 ) +' {!' + UI.Config.GetKeybinding( COMMAND_SKILL1-1+i ) + '}' );
        if IsFunction('OnAltUse') then FKeys.Push( Padded( GetString('name_altuse'), 17 ) +' {!' + UI.Config.GetKeybinding( COMMAND_SKILLALT1-1+i ) + '}' );
      finally
        Free;
      end;
    end;
  FStyle.Padding[ VTIG_WINDOW_PADDING ] := Point(0,1);
end;

procedure THelpLayer.Update( aDTime : Integer; aActive : Boolean );
var i : Integer;
begin
  if FContent = nil then
  begin
    VTIG_PushStyle( @FStyle );
    VTIG_BeginWindow( ' {!Berserk!} Help System', 'help_view', VTIG_GetIOState.Size );
    for i := 0 to High(HelpData) do
      if VTIG_Selectable( HelpData[i].Name ) then
      begin
        VTIG_ResetScroll( 'scrolling_view' );
        FContent := TextFileToIOStringArray( DataPath + 'help' + PathDelim + HelpData[i].Filename );
        FHeader  := ' {!Berserk!} Help : {!' + HelpData[i].Name +'}';
      end;
    if VTIG_Selectable( '  Quit help' ) then
      FFinished := True;

    VTIG_FreeLabel( '{!Keybindings}', Point( 38, 0 ) );
    for i := 0 to FKeys.Size - 1 do
      VTIG_FreeLabel( FKeys[i], Point( 40, 1 + i ) );

    VTIG_End( FFooter );
    VTIG_PopStyle;
    if VTIG_EventCancel then FFinished := True;
    UI.RenderBG();
    Exit;
  end;

  inherited Update( aDTime, aActive );
  if FFinished then
  begin
    FFinished := False;
    FreeAndNil( FContent );
  end;
end;

destructor THelpLayer.Destroy;
begin
  FreeAndNil( FKeys );
  inherited Destroy;
end;

procedure TIntroLayer.Update( aDTime : Integer; aActive : Boolean );
begin
  UI.RenderWindow( Point( 49, 15 ), Point( 17, 3 ) );
  VTIG_Begin( 'intro', Point( 49, 15 ), Point( 17, 3 ) );
  VTIG_Text('{R   #####  ### #####   #  ### ##### #  #   ##}');
  VTIG_Text('{R   #  #  ##   #  #   #  ##   #  #  #  #   ##}');
  VTIG_Text('{R   ####  # ## ####  #   # ## ####  ###    ##}');
  VTIG_Text('{R    # ## ##    # # #### ##    # #   # #   #}');
  VTIG_Text('{R    # #   ###  # #  #    ###  # #   #  #}');
  VTIG_Text('{R    ##    #   #  # #     #   #  #   #  #  #}');
  VTIG_Text('');
  VTIG_Text('{R   Berserk! - a game of tactical bloodshed}');
  VTIG_Text('{R            by Kornel Kisielewicz}');
  VTIG_Text('{R            graphics by Derek Yu}');
  VTIG_Text('');
  VTIG_Text('{l  Based loosely on the Berserk universe by}');
  VTIG_Text('               {!Kentaro Miura}');
  VTIG_End;
  UI.RenderWindow( Point( 49, 6 ), Point( 17, 19 ) );
  VTIG_Begin( 'intro_sub', Point( 49, 6 ), Point( 17, 19 ) );
  VTIG_Text('  Thanks to {!Turgor}, {!Glowie}, {!Jorge}, {!Thomas},');
  VTIG_Text('  {!Malek} and {!Fingerzam} for beta testing.');
  VTIG_Text('');
  VTIG_Text('          Press <{!Enter}> to begin...' );

  VTIG_End;
  inherited Update( aDTime, aActive );
  if VTIG_EventConfirm or VTIG_EventCancel then FFinished := True;
end;

procedure TOutroLayer.Update( aDTime : Integer; aActive : Boolean );
begin
  UI.RenderWindow( Point( 49, 20 ), Point( 17, 3 ) );
  VTIG_Begin( 'outro', Point( 49, 20 ), Point( 17, 3 ) );
  VTIG_Text(' Thank you for playing {!Berserk!} This game');
  VTIG_Text(' is far from finished. There are plenty of');
  VTIG_Text(' features that might be implemented, with');
  VTIG_Text(' the greatest one being the {!Campaign Mode}.');
  VTIG_Text('');
  VTIG_Text(' If you wish to support the continued deve-');
  VTIG_Text(' lopment of {!Berserk!} then drop me a mail at');
  VTIG_Text(' {!epyon@chaosforge.org}, or visit the {!Berserk!}');
  VTIG_Text(' forum accessible from the games website,');
  VTIG_Text(' and tell me what you think!');
  VTIG_Text('');
  VTIG_Text(' Further releases, information and source');
  VTIG_Text(' code available on the website:');
  VTIG_Text('');
  VTIG_Text('{L   http://berserk.chaosforge.org/}');
  VTIG_Text('');
  VTIG_Text('                      Thanks again!');
  VTIG_Text('                      Kornel Kisielewicz');
  VTIG_End;
  inherited Update( aDTime, aActive );
  if VTIG_EventConfirm or VTIG_EventCancel then FFinished := True;
end;

constructor TNightLayer.Create;
var i : Integer;
begin
  inherited Create;
  i := LuaSystem.GetTableSize('quotes');
  i := UI.VisualRNG.RLongInt( i ) + 1;
  FQuote  := LuaSystem.Get( ['quotes', i, 'text'] ) +
             #10+'                        {d-- }'+
             LuaSystem.Get( ['quotes', i, 'author'] );
end;

procedure TNightLayer.Update( aDTime : Integer; aActive : Boolean );
begin
  UI.RenderWindow( Point( 61, 20 ), Point( 10, 3 ) );
  VTIG_Begin( 'night', Point( 61, 20 ), Point( 10, 3 ) );
  VTIG_Text('');
  VTIG_Text('');
  VTIG_Text('                   {RBERSERK!} {rNight }{R{0}}', [Player.Night] );
  VTIG_Text('');
  VTIG_Text('');
  VTIG_Text('');
  VTIG_Text('');
  VTIG_Text('');
  VTIG_Text('');
  VTIG_Text('');
  VTIG_Text('');
  VTIG_Text('');
  VTIG_Text('{R                {0} kills and counting...}', [Player.FKills.Count] );
  VTIG_Text('');
  if VTIG_Selectable('       Continue')      then FFinished := True;
  if VTIG_Selectable('       Save and Exit') then
  begin
    try
      Berserk.Save;
      Berserk.Finish( BSR_SAVED );
      FFinished := True;
    except
      on E : Exception do FError := 'Save failed: '+E.Message;
    end;
  end;
  VTIG_FreeLabel( FQuote, Rectangle( 10, 4, 40, 6 ) );
  if FError <> '' then VTIG_FreeLabel( FError, Rectangle( 2, 17, 57, 2 ) );
  VTIG_End;
  inherited Update( aDTime, aActive );
end;

procedure TGameModeLayer.Update( aDTime : Integer; aActive : Boolean );
begin
  UI.RenderWindow( Point( 51, 7 ), Point( 10, 10 ) );
  VTIG_Begin( 'mode_desc', Point( 51, 7 ), Point( 10, 10 ) );
  VTIG_Text('Please choose game mode. {!Endless} is a mode where you fight waves of monsters each night, gaining experience after each survived arena. {!Massacre} is just what it says -- pure bloodshed without any distractions.');
  VTIG_End;
  UI.RenderWindow( Point( 12, 5 ), Point( 65, 10 ) );
  VTIG_Begin( 'mode', Point( 12, 5 ), Point( 65, 10 ) );
  if VTIG_Selectable('Endless')  then begin Player.Mode := Mode_Endless;  FFinished := True; end;
  if VTIG_Selectable('Massacre') then begin Player.Mode := Mode_Massacre; FFinished := True; end;
  VTIG_End;
  inherited Update( aDTime, aActive );
end;

const ArenaData : array[0..3] of Ansistring = ('Fields','Forest','Town','Snow');

procedure TGameArenaLayer.Update( aDTime : Integer; aActive : Boolean );
var i : Integer;
begin
  UI.RenderWindow( Point( 51, 6 ), Point( 10, 11 ) );
  VTIG_Begin( 'arena_desc', Point( 51, 6 ), Point( 10, 11 ) );
  VTIG_Text('Choose your the arena you want to fight on. Fields are empty, with only a few rocks for cover. The forest has trees, The city has lots of cover.');
  VTIG_End;
  UI.RenderWindow( Point( 13, 9 ), Point( 65, 11 ) );
  VTIG_Begin( 'arena', Point( 13, 9 ), Point( 65, 11 ) );
  for i := 0 to 3 do
    if VTIG_Selectable(ArenaData[i]) then
    begin
      Berserk.Arena := i+1;
      FFinished := True;
    end;
  VTIG_End;
  inherited Update( aDTime, aActive );
end;

constructor TGameNameLayer.Create;
begin
  inherited Create;
  FName[0] := #0;
  UI.Driver.StartTextInput;
  UI.Console.ShowCursor;
end;

procedure TGameNameLayer.Update( aDTime : Integer; aActive : Boolean );
begin
  UI.RenderWindow( Point( 21, 4 ), Point( 30, 11 ) );
  VTIG_Begin( 'name', Point( 21, 4 ), Point( 30, 11 ) );
  VTIG_Text('What''s your name?');
  if VTIG_Input( @FName[0], 16 ) then
  begin
    Player.Name := AnsiString(FName);
    FFinished := True;
  end;
  VTIG_End;
  inherited Update( aDTime, aActive );
end;

destructor TGameNameLayer.Destroy;
begin
  UI.Driver.StopTextInput;
  UI.Console.HideCursor;
  inherited Destroy;
end;

type TStatsInfo = record
  Name : Ansistring;
  Cost : Integer;
  Desc : Ansistring;
end;

const StatsData : array[0..3] of TStatsInfo = (
  ( Name : 'Strength '; Cost : 1; Desc : '-- affects damage'; ),
  ( Name : 'Dexterity'; Cost : 2; Desc : '-- affects hit chance'#10'-- affects accuracy'#10'-- affects dodge'#10'-- affects speed';  ),
  ( Name : 'Endurance'; Cost : 1; Desc : '-- increases hitpoints'#10'-- increases energy'#10'-- decreases knockback'; ),
  ( Name : 'Willpower'; Cost : 1; Desc : '-- increases energy'#10'-- quickens pain recovery'#10'-- quickens energy recovery'#10'-- affects berserking' ) );

constructor TGameStatsLayer.Create;
var i : Integer;
begin
  inherited Create;
  for i := 0 to 3 do
    FInitial[i] := Player.FStats[i];
  if Player.Mode = MODE_MASSACRE then
  begin
    FText     := 'Choose your basic statistics. Up and down to navigate, right to increase, and left lower.';
    FDoneText := 'Press {!Enter} to accept the chosen stats. Excess points will be lost.';
  end
  else
  begin
    if Player.Night < 2
      then FText := 'Choose your basic statistics. Up and down to navigate, right to increase, and left lower. Unspent points may be used in the next avancement.'
      else FText := 'Choose which statistics to upgrade. Up and down to navigate, right to increase, and left lower. Unspent points will be kept.';
      FDoneText := 'Press {!Enter} to accept the chosen stats. Excess points will be kept.';
  end;
end;

procedure TGameStatsLayer.Update( aDTime : Integer; aActive : Boolean );
var i : Integer;
   function Modify( aIndex : Integer; aValue : Integer ) : Boolean;
   var iCurrent : Integer;
       iCost    : Integer;
   begin
     iCurrent := Player.FStats[ aIndex ];
     iCost    := StatsData[ aIndex ].Cost * aValue;
     if ( aValue < 0 ) and ( iCurrent <= FInitial[ aIndex ] ) then Exit( False );
     if ( aValue > 0 ) and ( Player.Points < iCost )          then Exit( False );
     Player.Points := Player.Points - iCost;
     Player.FStats[ aIndex ] += aValue;
     Exit( True );
   end;
begin
  UI.RenderWindow( Point( 54, 13 ),     Point( 14, 5 ) );
  VTIG_Begin( 'stats', Point( 54, 13 ), Point( 14, 5 ) );
    VTIG_Text(FText);
    VTIG_Text( 'Points : {!{0}}',[Player.Points] );
    VTIG_Text('');

    VTIG_BeginGroup( 10, True );
      VTIG_BeginGroup( 20 );
        for i := 0 to 3 do
          if VTIG_Selectable(StatsData[i].Name+' [{L'+IntToStr( Player.FStats[i])+'}]')  then
            Modify( i, 1 );
        if VTIG_Selectable('Done') then
          FFinished := True;
      VTIG_EndGroup();

      VTIG_BeginGroup;
        i := VTIG_Selected;
        if i = 4 then
          VTIG_Text(FDoneText);
        if i in [0..3] then
        begin
          VTIG_Text('{!'+StatsData[i].Name+'} ( Cost : {!'+ IntToStr( StatsData[i].Cost )+'} )');
          VTIG_Text('');
          VTIG_Text(StatsData[i].Desc);
        end;
      VTIG_EndGroup();
    VTIG_EndGroup();
  VTIG_End;
  if i in [0..3] then
  begin
    if VTIG_Event( VTIG_IE_LEFT )  then Modify( i, -1 );
    if VTIG_Event( VTIG_IE_RIGHT ) then Modify( i, 1 );
  end;
  inherited Update( aDTime, aActive );
end;

constructor TGameSkillsLayer.Create;
var i, iMax, iV, iC : Integer;
    iReq            : Ansistring;
    iPair           : TLuaValuePair;
begin
  inherited Create;
  iMax := LuaSystem.Get(['skills','__counter']);
  SetLength( FSkillData, iMax );
  iC := 0;
  for i := 0 to iMax - 1 do
    with FSkillData[iC] do
      with LuaSystem.GetTable(['skills',i+1]) do
        try
          if GetBoolean('pickable',False) then
          begin
            Index := i+1;
            Name  := GetString( 'name' );
            Entry := Name;
            if Player.FSkills[ Index ] > 0 then
              Entry += ' ('+IntToStr( Player.FSkills[ Index ] + 1 )+')';
            Max   := GetInteger( 'max_level' );
            Desc  := GetString( 'description' );
            Pic   := GetString( 'picture' );
            Allow := Player.ReqsMet( Index );
            Reqs  := '';
            with LuaSystem.GetTable(['skills',Index,'reqs']) do
            try
              for iPair in Pairs do
              begin
                iReq := iPair.Key.ToString;
                iV   := iPair.Value.ToInteger;
                if Reqs <> '' then Reqs += '            ';
                if Player.ReqMet( iReq, iV )
                  then Reqs += '{g'
                  else Reqs += '{r';
                Reqs += Player.ReqToString( iReq, iV );
                Reqs += '}'#10;
              end;
            finally
              Free;
            end;
            if Reqs = '' then Reqs := '{gnothing}'#10;
            iC += 1;
          end;
        finally
          Free;
        end;
  SetLength( FSkillData, iC );
end;

procedure TGameSkillsLayer.Update( aDTime : Integer; aActive : Boolean );
var i : Integer;
begin
  UI.RenderWindow( Point( 20, 3 + High( FSkillData ) ), Point( 58, 2 ) );
  VTIG_Begin( 'skill', Point( 20, 3 + High( FSkillData ) ), Point( 58, 2 ) );
    for i := 0 to High( FSkillData ) do
      with FSkillData[i] do
        if VTIG_Selectable( Entry, Allow ) then
        begin
          Player.IncSkill( Index );
          FFinished := True;
        end;
    i := VTIG_Selected;

  VTIG_End;
  UI.RenderWindow( Point( 50, 21 ), Point( 4, 2 ) );
    VTIG_Begin( 'skill_desc', Point( 50, 21 ), Point( 4, 2 ) );
    VTIG_Text('Choose a skill you want to upgrade. Most skills offer some otherwise unattainable option in the game. Further levels increase that option''s effectiveness.');
    VTIG_Text('');
    if ( i >= 0 ) and ( i <= High( FSkillData ) ) then
      with FSkillData[i] do
      begin
        VTIG_Text('Name      : {!'+Name+'}');
        VTIG_Text('Max level : {!{0}}', [Max]);
        VTIG_Text('Requires  : '+Reqs);
        VTIG_Text(Desc);
        VTIG_FreeLabel( Pic, Point(35, 5) );
      end;
  VTIG_End;
  VTIG_BringToTop( 'skill' );
  inherited Update( aDTime, aActive );
end;

constructor TGamePlayerLayer.Create;
var i, iMax, iAmmo, iQs, iC : Integer;
begin
  inherited Create;
  FSkills := '';
  FAmmo   := '';
  iMax := LuaSystem.Get(['skills','__counter']);
  iC   := 0;
  for i := 1 to iMax do
    if Player.FSkills[ i ] > 0 then
    with LuaSystem.GetTable(['skills',i]) do
      try
        if GetBoolean('pickable',False) then
          FSkills += ' '+GetString( 'name' )+' (level {!'+IntToStr(Player.FSkills[ i ])+'})'#10;
        iAmmo := GetInteger('ammo_slot');
        if iAmmo > 0 then
        begin
          iQs := GetInteger('quiver_slot');
          if iC mod 2 = 0 then FAmmo += ' ';
          FAmmo += Padded( GetString( 'name' ), 10 );
          if iQs = 0
            then FAmmo += Padded( '{!'+IntToStr( Player.FAmmo[ iAmmo ] ) + '}', 9 )
            else FAmmo += Padded( '{!'+IntToStr( Player.FAmmo[ iAmmo ] ) + '}/{!'+IntToStr( Player.FAmmo[ iQs ] )+'}',12);
          if iC mod 2 = 1 then FAmmo += #10;
          Inc( iC );
        end;
      finally
        Free;
      end;
  FStyle := VTIGDefaultStyle;
  FStyle.Padding[ VTIG_WINDOW_PADDING ] := Point(1,0);
end;

procedure TGamePlayerLayer.Update( aDTime : Integer; aActive : Boolean );
  function BonusStr( aVal : Integer ) : Ansistring;
  begin
    if aVal = 0 then Exit('');
    if aVal > 0 then Exit('+{!'+IntToStr( aVal )+'}');
    Exit('-{!'+IntToStr( -aVal )+'}');
  end;
begin
  UI.RenderWindow( Point( 67, 21 ), Point( 7, 3 ) );
  VTIG_PushStyle( @FStyle );
  VTIG_Begin( 'player', Point( 67, 21 ), Point( 7, 3 ) );
    VTIG_Text( StringOfChar('-',65) );
    VTIG_Text('');
    VTIG_BeginGroup( 15, True );
      VTIG_BeginGroup( 31 );
        VTIG_Text(' Name     : {!{0}}', [Player.Name] );
        VTIG_Text(' Game type: {!{0}}', [ModeToString( Player.Mode )]);
        VTIG_Text(' Strength : {!{0}}  Dexterity: {!{1}}', [ Player.ST, Player.DX ] );
        VTIG_Text(' Endurance: {!{0}}  Willpower: {!{1}}', [ Player.EN, Player.WP ] );
        VTIG_Text(' Weight   : {!{0}}  Speed    : {!{1}}', [ Player.Weight, Player.Speed ] );
        VTIG_Text(' Base damage - {!{0}}d6{1}', [Player.dmg_dice,BonusStr(Player.dmg_mod)] );
        VTIG_Text('');
        VTIG_Text('-- {!Skills} '+StringOfChar('-',20));
        VTIG_Text('');
        VTIG_Text(FSkills);
      VTIG_EndGroup;
      VTIG_BeginGroup;
        VTIG_Text(' Monsters killed : {!{0}}', [Player.FKills.Count] );
        if Player.Mode <> MODE_MASSACRE
          then VTIG_Text(' Nights survived : {!{0}}', [Integer(Player.Night-1)] )
          else VTIG_Text('');
        VTIG_Text('');
        VTIG_Text(FAmmo);
        VTIG_Text('');
        VTIG_Text('-- {!Achievements} '+StringOfChar('-',16));
        VTIG_Text('');
        VTIG_Text(' Kills in 1 turn   : {!{0}}', [ Player.FKills.BestTurn ] );
        VTIG_Text(' Killing sequence  : {!{0}}', [ Player.FKills.BestSequence ] );
        VTIG_Text(' Sequence duration : {!{0}t}',[ Player.FKills.BestSequenceLength ] );
        VTIG_Text(' Kills w/o damage  : {!{0}}', [ Player.FKills.BestNoDamageSequence ] );
        VTIG_Text(' Survived for      : {!{0}t}',[ Player.turn_count ] );
      VTIG_EndGroup;
    VTIG_EndGroup;
    VTIG_FreeLabel( '-- Press <{!Enter}> to exit... '+StringOfChar('-',37), Point(0,20) );
  VTIG_End;
  VTIG_PopStyle;
  inherited Update( aDTime, aActive );
  if VTIG_EventConfirm or VTIG_EventCancel then FFinished := True;
end;

end.
