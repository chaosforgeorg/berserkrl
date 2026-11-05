// @abstract(BerserkRL -- Main Application class)
// @author(Kornel Kisielewicz <admin@chaosforge.org>)
// @created(Oct 16, 2006)
// @lastmod(Oct 22, 2006)
//
// Runtime services and one-playthrough ownership for BerserkRL.
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
unit brmain;
interface

uses sysutils,
     vapp, vrlapp, viorl, vlua, vuid, vnode, vsound,
     brlua, brconfiguration, brdata, brlevel, brplayer, brpersistence, brui, bruiscreens;

type TBerserkSessionResult = ( BSR_RUNNING, BSR_CANCELLED, BSR_SAVED,
       BSR_ABANDONED, BSR_DEAD, BSR_LOAD_FAILED, BSR_QUIT );

     TBerserkSession = class;

     TBerserkRuntime = class( TRLRuntime )
     private
       FSession     : TBerserkSession;
       FSound       : TSound;
       FPersistence : TPersistence;
       function GetUI : TBerserkUI;
       procedure LoadAudio;
       property UI : TBerserkUI read GetUI;
     protected
       function CreateIO : TIORL; override;
       function CreateLua : TLua; override;
       function PrepareGameData : Boolean; override;
       procedure InitializeGameData; override;
       function RunGame : TVRunResult; override;
       procedure ShutdownGameData; override;
     public
       destructor Destroy; override;
       procedure HandleGameException( aException : Exception ); override;
     end;

     TBerserkSession = class
     private
       FRuntime     : TBerserkRuntime;
       FPlayer      : TPlayer;
       FLevel       : TLevel;
       FUIDStore    : TUIDStore;
       FContext     : TNodeContext;
       FSaveWritten : Boolean;
       FOutcome     : TBerserkSessionResult;
       FArena       : Byte;
       function GetFinished : Boolean;
       function GetUI : TBerserkUI;
       function NightActive : Boolean;
       procedure ReleasePlayer;
       procedure AttachPlayer;
       procedure CreateCharacter( aQuick : Boolean );
       procedure AdvancePlayer;
       procedure PlayerTurn;
       procedure ExecuteCommand( aCommand : Byte );
       function WaitForCommand : Byte;
       procedure PresentDeath;
       procedure SaveAndExit;
       procedure CancelCreation;
       procedure AbandonRun;
       procedure SetArena( aArena : Byte );
       function RunCreationLayer( aLayer : TCreationLayer ) : Boolean;
       procedure Save;
       procedure Load;
       function CanCrashSave : Boolean;
       procedure Finish( aOutcome : TBerserkSessionResult );
       property Finished : Boolean read GetFinished;
       property UI : TBerserkUI read GetUI;
     public
       constructor Create( aRuntime : TBerserkRuntime );
       destructor Destroy; override;
       function Run( aContinue, aQuick : Boolean ) : TBerserkSessionResult;
     end;

implementation

uses zstream,
     vrltools, vrandom, vioevent, vsdlsound, vfmodsound, vutil, vdebug, vluatools,
     brgui, brtextui;

function TBerserkRuntime.GetUI : TBerserkUI;
begin
  Exit( TBerserkUI( IO ) );
end;

function TBerserkRuntime.CreateIO : TIORL;
var iConfiguration : TBerserkConfiguration;
begin
  iConfiguration := TBerserkConfiguration( Configuration );
  if iConfiguration.GraphicsMode then
    Result := TBerserkGUI.Create( iConfiguration, Paths )
  else
    Result := TBerserkTextUI.Create( iConfiguration, Paths.DataPath );
end;

function TBerserkRuntime.CreateLua : TLua;
begin
  Result := TBerserkLua.Create( TBerserkUI( IO ) );
end;

function TBerserkRuntime.PrepareGameData : Boolean;
var iConfiguration : TBerserkConfiguration;
begin
  Result := True;
  iConfiguration := TBerserkConfiguration( Configuration );
  if iConfiguration.AudioDriver <> 'NONE' then
  begin
    if iConfiguration.AudioDriver = 'FMOD' then
      FSound := TFMODSound.Create
    else
      FSound := TSDLSound.Create( IO.VisualRNG );
    Sound := FSound;
    FSound.PosMinVolume := 30;
    FSound.PosFadeDist  := 24;
    UI.Audio := FSound;
    UI.Reconfigure;
    LoadAudio;
    FSound.PlayMusic( 'menu' );
  end;
end;

procedure TBerserkRuntime.InitializeGameData;
begin
  UI.Lua := FLua;
  TBerserkLua( FLua ).Load( Paths.DataPath );
  FPersistence := TPersistence.Create( Paths.ScorePath );
  if GodMode then RegisterDebugConsole( VKEY_BQUOTE );
end;

function TBerserkRuntime.RunGame : TVRunResult;
var iChoice : TMainMenuResult;
    iQuick, iLaunch, iUseQuick : Boolean;
    iOutcome : TBerserkSessionResult;
    iSavePath : AnsiString;
begin
  iQuick := TBerserkConfiguration( Configuration ).QuickStart;
  iLaunch := iQuick;
  iSavePath := Paths.WritePath + 'berserk.sav';
  UI.ResetSession;
  UI.RunLayer( TIntroLayer.Create );
  while not UI.QuitRequested do
  begin
    UI.ResetSession;
    if iLaunch then
    begin
      if FileExists( iSavePath ) then iChoice := MMR_CONTINUE else iChoice := MMR_NEW_GAME;
    end
    else
      UI.RunLayer( TMainMenuLayer.Create( FPersistence, iSavePath, @iChoice ) );
    iLaunch := False;
    if UI.QuitRequested then Break;
    case iChoice of
      MMR_NEW_GAME, MMR_CONTINUE :
        begin
          iUseQuick := iQuick and ( iChoice = MMR_NEW_GAME );
          if iChoice = MMR_NEW_GAME then iQuick := False;
          FSession := TBerserkSession.Create( Self );
          try
            try
              iOutcome := FSession.Run( iChoice = MMR_CONTINUE, iUseQuick );
            except
              on E : Exception do
              begin
                // The shared exception notification happens after RunGame unwinds.
                // Crash-save while this Session is still owned and alive.
                HandleGameException( E );
                raise;
              end;
            end;
          finally
            FreeAndNil( FSession );
          end;
          if iOutcome = BSR_QUIT then Break;
        end;
      MMR_QUIT :
        begin
          UI.RunLayer( TOutroLayer.Create );
          Break;
        end;
    end;
  end;
  Result := VRR_QUIT;
end;

procedure TBerserkRuntime.ShutdownGameData;
begin
  FreeAndNil( FSession );
  // Initialization can fail before a Session has acquired the IO layers.
  if IO <> nil then
  begin
    IO.Clear;
    TBerserkUI( IO ).Audio := nil;
    TBerserkUI( IO ).Lua := nil;
  end;
  Sound := nil;
  FreeAndNil( FSound );
  FreeAndNil( FPersistence );
end;

destructor TBerserkRuntime.Destroy;
begin
  // Also covers direct destruction and partially constructed runtimes.
  ShutdownGameData;
  inherited Destroy;
end;

procedure TBerserkRuntime.HandleGameException( aException : Exception );
begin
  if ( FSession = nil ) or not FSession.CanCrashSave then Exit;
  try
    FSession.Save;
  except
    on E : Exception do
      vdebug.Log( LOGERROR, 'Crash save failed: ' + E.Message );
  end;
end;

constructor TBerserkSession.Create( aRuntime : TBerserkRuntime );
begin
  inherited Create;
  FRuntime := aRuntime;
  FContext := TNodeContext.Create( aRuntime.Lua, nil );
  FRuntime.GameRNG.Randomize;
  FUIDStore := TUIDStore.Create;
  FContext.BindUIDs( FUIDStore );
  FContext.Lua.Context.BindUIDs( FUIDStore );
  FLevel := TLevel.Create( FContext, aRuntime.GameRNG, TBerserkUI( aRuntime.IO ), TBerserkLua( aRuntime.Lua ).Terrain );
  FPlayer := TPlayer.Create( FContext, NewCoord2D( 1, 1 ) );
  FArena := 1;
  FPlayer.FNight := 0;
  AttachPlayer;
end;

procedure TBerserkSession.AttachPlayer;
begin
  FLevel.Player := FPlayer;
  FRuntime.Lua.SetValue( 'player', FPlayer );
  FRuntime.Lua.SetValue( 'level', FLevel );
  RegisterKillsClass( FRuntime.Lua.Raw, FPlayer.FKills );
  FRuntime.IO.SetLevel( FLevel );
  FRuntime.IO.SetPlayer( FPlayer );
end;

procedure TBerserkSession.ReleasePlayer;
begin
  if FRuntime.IO <> nil then FRuntime.IO.SetPlayer( nil );
  if FPlayer <> nil then FPlayer.Detach;
  if FLevel <> nil then FLevel.Player := nil;
  FreeAndNil( FPlayer );
end;

destructor TBerserkSession.Destroy;
begin
  if FRuntime <> nil then
  begin
    if FRuntime.IO <> nil then
    begin
      FRuntime.IO.Clear;
      FRuntime.IO.SetLevel( nil );
    end;
    ReleasePlayer;
  end;
  FreeAndNil( FLevel );
  FContext.Lua.Context.BindUIDs( nil );
  FreeAndNil( FUIDStore );
  FreeAndNil( FContext );
  inherited Destroy;
end;

procedure TBerserkSession.Save;
var iSaveFile : TGZFileStream;
    iNight    : Word;
begin
  iNight := FPlayer.FNight;
  Dec( FPlayer.FNight );
  try
    iSaveFile := TGZFileStream.Create( FRuntime.Paths.WritePath + 'berserk.sav', gzOpenWrite );
    try
      FUIDStore.WriteToStream( iSaveFile );
      FPlayer.WriteToStream( iSaveFile );
    finally
      iSaveFile.Free;
    end;
    FSaveWritten := True;
  except
    FPlayer.FNight := iNight;
    raise;
  end;
end;

procedure TBerserkSession.Load;
var iSaveFile : TGZFileStream;
begin
  iSaveFile := TGZFileStream.Create( FRuntime.Paths.WritePath + 'berserk.sav', gzOpenRead );
  try
    ReleasePlayer;
    FLevel.Clear;
    FContext.BindUIDs( nil );
    FContext.Lua.Context.BindUIDs( nil );
    FreeAndNil( FUIDStore );
    FUIDStore := TUIDStore.CreateFromStream( iSaveFile );
    FContext.BindUIDs( FUIDStore );
    FContext.Lua.Context.BindUIDs( FUIDStore );
    // The arena is not serialized; keep its identity in the replacement store.
    FUIDStore.Register( FLevel, FLevel.UID );
    FPlayer := TPlayer.CreateFromStream( iSaveFile, FContext );
    AttachPlayer;
  finally
    iSaveFile.Free;
  end;
  FSaveWritten := False;
  DeleteFile( FRuntime.Paths.WritePath + 'berserk.sav' );
end;

function TBerserkSession.CanCrashSave : Boolean;
begin
  Result := ( FPlayer <> nil ) and ( FPlayer.FMode <> mode_Massacre ) and
            ( FPlayer.FNight > 0 ) and
            not FSaveWritten and not Finished and not FPlayer.Died;
end;

function TBerserkSession.GetUI : TBerserkUI;
begin
  Exit( FRuntime.UI );
end;

function TBerserkSession.GetFinished : Boolean;
begin
  Result := FOutcome <> BSR_RUNNING;
end;

procedure TBerserkSession.Finish( aOutcome : TBerserkSessionResult );
begin
  FOutcome := aOutcome;
end;

function TBerserkSession.NightActive : Boolean;
begin
  Result := ( not Finished ) and ( not UI.QuitRequested ) and ( not FPlayer.Died ) and
            ( not FLevel.Flags[ LF_CLEARED ] );
end;

procedure TBerserkSession.CreateCharacter( aQuick : Boolean );
var i, iSkills : Integer;
    iConfiguration : TBerserkConfiguration;
begin
  iConfiguration := TBerserkConfiguration( FRuntime.Configuration );
  if not RunCreationLayer( TGameModeLayer.Create( @CancelCreation ) ) then Exit;
  // Choose klass
  FContext.Lua.ProtectedCall( ['klasses',FPlayer.FKlass,'OnCreate'], [FPlayer, FPlayer.FMode]);

  if FPlayer.FMode = mode_Massacre
    then FPlayer.FPoints := 14
    else FPlayer.FPoints := 8;

  if aQuick then
  begin
    FPlayer.Name    := 'Epyon';
    FArena           := ARENA_TOWN;
    FPlayer.FPoints := 0;
    FContext.Lua.ProtectedCall( ['klasses',FPlayer.FKlass,'OnQuick'], [FPlayer, FPlayer.FMode]);
  end
  else
  begin
    FPlayer.Name := iConfiguration.FixedPlayerName;
    if (FPlayer.Name = '') and (not iConfiguration.GetBoolean( 'always_random_name' )) then
      if not RunCreationLayer( TGameNameLayer.Create( @CancelCreation ) ) then Exit;
    UI.Console.HideCursor;
    if FPlayer.Name = '' then
    case FRuntime.GameRNG.RLongInt(8) of
      0..1 : FPlayer.Name := 'Guts';
      2    : FPlayer.Name := 'Glowie';
      3    : FPlayer.Name := 'Turgor';
      4    : FPlayer.Name := 'Fingerzam';
      5    : FPlayer.Name := 'Malek';
      6    : FPlayer.Name := 'Jorge';
      7    : FPlayer.Name := 'Thomas';
    end;

    if not RunCreationLayer( TGameStatsLayer.Create( @CancelCreation ) ) then Exit;

    iSkills := 1;
    if FPlayer.FMode = mode_Massacre then
    begin
      if not RunCreationLayer( TGameArenaLayer.Create( @CancelCreation, @SetArena ) ) then Exit;
      iSkills := 3;
    end;
    for i := 1 to iSkills do
      if not RunCreationLayer( TGameSkillsLayer.Create( @CancelCreation ) ) then Exit;
  end;

  FPlayer.FinishCreation;
end;

function TBerserkSession.RunCreationLayer( aLayer : TCreationLayer ) : Boolean;
begin
  UI.RunLayer( aLayer );
  Result := not Finished and not UI.QuitRequested;
end;

procedure TBerserkSession.SaveAndExit;
begin
  Save;
  Finish( BSR_SAVED );
end;

procedure TBerserkSession.CancelCreation;
begin
  Finish( BSR_CANCELLED );
end;

procedure TBerserkSession.AbandonRun;
begin
  Finish( BSR_ABANDONED );
end;

procedure TBerserkSession.SetArena( aArena : Byte );
begin
  FArena := aArena;
end;

procedure TBerserkSession.AdvancePlayer;
begin
  Inc( FPlayer.FPoints );
  if not RunCreationLayer( TGameStatsLayer.Create ) then Exit;
  if not RunCreationLayer( TGameSkillsLayer.Create ) then Exit;
  FPlayer.ApplyAdvancement;
end;

function TBerserkSession.WaitForCommand : Byte;
begin
  repeat
    Result := UI.GetCommand;
    if Finished or UI.QuitRequested then Exit;
    if Result in [COMMAND_ESCAPE, COMMAND_QUIT] then
    begin
      UI.RunLayer( TInGameMenuLayer.Create( @AbandonRun ) );
      if Finished or UI.QuitRequested then Exit;
    end;
  until not ( Result in [COMMAND_ESCAPE, COMMAND_QUIT] );
end;

procedure TBerserkSession.ExecuteCommand( aCommand : Byte );
begin
  case aCommand of
    COMMAND_WALKNORTH..COMMAND_WALKSW : FPlayer.ActionMove( UI.CommandDirection( aCommand ) );
    COMMAND_WAIT    : FPlayer.ActionWait;
    COMMAND_RUNNING : FPlayer.ActionToggleRun;
    COMMAND_LOOK :
      begin
        UI.Msg('Look mode, <{^Esc}> to exit.');
        UI.Msg('You see:');
        UI.ChooseTarget( TM_LOOK, COMMAND_LOOK );
      end;
    COMMAND_HELP       : UI.RunLayer( THelpLayer.Create );
    COMMAND_PLAYERINFO : UI.RunLayer( TGamePlayerLayer.Create );
    COMMAND_MESSAGES   : UI.RunLayer( TMessagesLayer.Create );
    COMMAND_SKILL1   ..COMMAND_SKILL0    : FPlayer.UseSkill( FPlayer.FSkillSlots[aCommand-COMMAND_SKILL1+1], aCommand );
    COMMAND_SKILLALT1..COMMAND_SKILLALT0 : FPlayer.UseSkill( FPlayer.FSkillSlots[aCommand-COMMAND_SKILLALT1+1], aCommand, True );
  end;
end;

procedure TBerserkSession.PlayerTurn;
var iCommand : Byte;
begin
  FPlayer.BeginTurn;
  repeat
    FPlayer.BeginCommand;
    if not NightActive then Exit;
    if FPlayer.Slips then
      FPlayer.ActionSlip
    else
    begin
      iCommand := WaitForCommand;
      if not NightActive then Exit;
      UI.MsgUpdate;
      ExecuteCommand( iCommand );
    end;
    if not NightActive then Exit;
  until FPlayer.FSpeedCount <= SPEEDLIMIT;
  FPlayer.EndTurn;
end;

procedure TBerserkSession.PresentDeath;
var iLast     : DWord;
    iFileName : AnsiString;
begin
  UI.Blink(Red,200,0);
  UI.Msg('You die!...');
  UI.Msg('Press <{^'+UI.GetKeybinding(COMMAND_OK)+'}>...');
  UI.Draw;
  UI.PressEnter;
  UI.Screen := Menu;
  iLast := FContext.Lua.Get(['beings',FPlayer.FLastEnemy,'nid'],0);
  FRuntime.FPersistence.Add( FPlayer.GetKills, FPlayer.Name, FPlayer.FMode, FPlayer.FKlass, FPlayer.GetKills, FPlayer.FTurnCount, FPlayer.FNight, iLast );
  iFileName := FRuntime.Paths.WritePath + 'mortem.txt';
  FPlayer.WriteMortem( iFileName, TBerserkConfiguration( FRuntime.Configuration ).Version );
  UI.RunLayer( TMortemLayer.Create( iFileName ) );
end;

function TBerserkSession.Run( aContinue, aQuick : Boolean ) : TBerserkSessionResult;
begin
  if aContinue then
  begin
    try
      Load;
    except
      on E : Exception do
      begin
        Finish( BSR_LOAD_FAILED );
        UI.RunLayer( TLoadErrorLayer.Create( E.Message ) );
      end;
    end;
  end
  else
    CreateCharacter( aQuick );

  if not Finished and not UI.QuitRequested then
  begin
    UI.Msg( 'Berserk!' );
    UI.Msg( 'Press {^'+UI.GetKeybinding( COMMAND_HELP )+'} for help.' );
  end;
  while not Finished and not UI.QuitRequested do
  begin
    Inc( FPlayer.FNight );
    FPlayer.Detach;
    FLevel.Clear;
    case FPlayer.FMode of
      mode_Massacre : FLevel.Generate( FArena, FPlayer.FMode, 1 );
      mode_Endless :
        begin
          if FPlayer.FNight > 1 then
          begin
            UI.RunLayer( TNightLayer.Create( @SaveAndExit ) );
            if Finished or UI.QuitRequested then Break;
            AdvancePlayer;
            if UI.QuitRequested then Break;
          end;
          FLevel.Generate( 1, FPlayer.FMode, FPlayer.FNight );
        end;
    end;
    UI.Screen := Game;
    UI.CenterCamera( FPlayer.Position );
    UI.PlayMusic( 'passive' );
    repeat
      FLevel.Tick;
      if NightActive and ( FPlayer.FSpeedCount > SPEEDLIMIT ) then PlayerTurn;
      // No callback is running between steps.
      FContext.FlushDestroyed;
    until not NightActive;
    if FPlayer.Died then
    begin
      Finish( BSR_DEAD );
      PresentDeath;
    end;
    UI.PlayMusic( 'menu' );
    UI.Screen := Menu;
  end;
  UI.Screen := Menu;
  if UI.QuitRequested then Exit( BSR_QUIT );
  if FOutcome in [BSR_DEAD, BSR_ABANDONED] then
    UI.RunLayer( THOFLayer.Create( FRuntime.Lua, FRuntime.FPersistence, FPlayer.Mode, FOutcome = BSR_DEAD ) );
  if UI.QuitRequested then Exit( BSR_QUIT );
  Result := FOutcome;
end;

procedure TBerserkRuntime.LoadAudio;
var iSearchRec : TSearchRec;
    iName      : AnsiString;
    iExt       : AnsiString;
begin
  if not Assigned( FSound ) then Exit;

  if FindFirst(Paths.DataPath+'sound' + PathDelim + '*.*',faAnyFile,iSearchRec) = 0 then
  try
    repeat
      iName := iSearchRec.Name;
      iExt := ExtractFileExt( iName );
      if (iExt = '.mp3') or (iExt = '.wav') or (iExt = '.ogg') then
      begin
        Delete(iName,Length(iName)-3,4);
        FSound.RegisterSample(Paths.DataPath+'sound' + PathDelim + iSearchRec.Name,iName);
      end;
    until (FindNext(iSearchRec) <> 0);
  finally
    FindClose( iSearchRec );
  end;

  if FindFirst(Paths.DataPath+'music' + PathDelim + '*.*',faAnyFile,iSearchRec) = 0 then
  try
    repeat
      iName := iSearchRec.Name;
      iExt := ExtractFileExt( iName );
      if (iExt = '.mp3') or (iExt = '.wav') or (iExt = '.ogg') or (iExt = '.mod') then
      begin
        Delete(iName,Length(iName)-3,4);
        FSound.RegisterMusic( Paths.DataPath+'music' + PathDelim + iSearchRec.Name, iName );
      end;
    until (FindNext(iSearchRec) <> 0);
  finally
    FindClose( iSearchRec );
  end;
end;

finalization

  if (ExitCode <> 0) then
  begin
    Writeln('Abnormal program termination! Please write down the above');
    Writeln('to help get rid Berserk! of all those bugs! You only need');
    Writeln('to write down the filenames and linenumbers.');
    {$IFNDEF UNIX}
    Readln;
    {$ENDIF}
  end;
end.
