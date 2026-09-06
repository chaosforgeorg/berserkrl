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

uses SysUtils, vapp, vrlapp, viorl, vluasystem, vuid, vsound,
     brlua, brconfiguration, brdata, brlevel, brplayer, brpersistence;

type TBerserkSessionResult = ( BSR_RUNNING, BSR_CANCELLED, BSR_SAVED,
       BSR_ABANDONED, BSR_DEAD, BSR_LOAD_FAILED, BSR_QUIT );

     TBerserkSession = class;

     TBerserkRuntime = class( TRLRuntime )
     private
       FSession     : TBerserkSession;
       FTerrainData : TTerrainDataArray;
       FSound       : TSound;
       FPersistence : TPersistence;
       procedure LoadAudio;
     protected
       function CreateIO : TIORL; override;
       function CreateLua : TLuaSystem; override;
       procedure PrepareGameData; override;
       procedure InitializeGameData; override;
       function RunGame : TVRunResult; override;
       procedure ShutdownGameData; override;
     public
       destructor Destroy; override;
       procedure HandleGameException( aException : Exception ); override;
       property Persistence : TPersistence read FPersistence;
       property Session : TBerserkSession read FSession;
     end;

     TBerserkSession = class
     private
       FRuntime     : TBerserkRuntime;
       FPlayer      : TPlayer;
       FLevel       : TLevel;
       FUIDStore    : TUIDStore;
       FSaveWritten : Boolean;
       FOutcome     : TBerserkSessionResult;
       FCreating    : Boolean;
       function GetFinished : Boolean;
       procedure ReleasePlayer;
       procedure AttachPlayer;
     public
       Arena  : Byte;
       constructor Create( aRuntime : TBerserkRuntime );
       destructor Destroy; override;
       procedure Save;
       procedure Load;
       function CanCrashSave : Boolean;
       function Run( aContinue, aQuick : Boolean ) : TBerserkSessionResult;
       procedure Finish( aOutcome : TBerserkSessionResult );
       property Finished : Boolean read GetFinished;
       property Creating : Boolean read FCreating;
       property Runtime : TBerserkRuntime read FRuntime;
     end;

// Non-owning compatibility alias for active playthrough consumers.
var Berserk : TBerserkSession = nil;

implementation

uses zstream, vmath, vrltools, vrandom, vioevent, vsdlsound, vfmodsound, vutil, vdebug,
     brui, brgui, brtextui, bruiscreens;

function TBerserkRuntime.CreateIO : TIORL;
var iConfiguration : TBerserkConfiguration;
begin
  iConfiguration := TBerserkConfiguration( Configuration );
  if iConfiguration.GraphicsMode then
    Result := TBerserkGUI.Create( iConfiguration, Paths )
  else
    Result := TBerserkTextUI.Create( iConfiguration );
end;

function TBerserkRuntime.CreateLua : TLuaSystem;
begin
  Result := TBerserkLua.Create;
end;

procedure TBerserkRuntime.PrepareGameData;
var iConfiguration : TBerserkConfiguration;
begin
  iConfiguration := TBerserkConfiguration( Configuration );
  if iConfiguration.AudioDriver <> 'NONE' then
  begin
    if iConfiguration.AudioDriver = 'FMOD' then
      FSound := TFMODSound.Create
    else
      FSound := TSDLSound.Create( IO.VisualRNG );
    Sound := FSound;
    FSound.Configure( iConfiguration.LuaConfig );
    LoadAudio;
    FSound.PlayMusic( 'menu' );
  end;
end;

procedure TBerserkRuntime.InitializeGameData;
begin
  TBerserkLua( Lua ).Load( Paths.DataPath, FTerrainData );
  TerraData := FTerrainData;
  FPersistence := TPersistence.Create( Paths.ScorePath );
  if GodMode then IO.RegisterDebugConsole( VKEY_BQUOTE );
end;

function TBerserkRuntime.RunGame : TVRunResult;
var iChoice : TMainMenuResult;
    iQuick, iLaunch, iUseQuick : Boolean;
    iOutcome : TBerserkSessionResult;
    iSavePath : AnsiString;
begin
  iQuick := QuickStart;
  iLaunch := iQuick;
  QuickStart := False;
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
      UI.RunLayer( TMainMenuLayer.Create( FPersistence, iSavePath, iChoice ) );
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
  if IO <> nil then IO.Clear;
  TerraData := nil;
  FTerrainData := nil;
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
  // Entity construction uses the active Session RNG through this alias.
  // The destructor clears it if any subsequent acquisition fails.
  Berserk := Self;
  FRuntime.GameRNG.Randomize;
  FUIDStore := TUIDStore.Create;
  UIDs := FUIDStore;
  FLevel := TLevel.Create;
  Level := FLevel;
  FPlayer := TPlayer.Create( NewCoord2D( 1, 1 ) );
  Arena := 1;
  FPlayer.FNight := 0;
  AttachPlayer;
end;

procedure TBerserkSession.AttachPlayer;
begin
  Player := FPlayer;
  TBerserkLua( FRuntime.Lua ).RegisterPlayer( FPlayer, FLevel );
  FRuntime.IO.SetLevel( FLevel );
  FRuntime.IO.SetPlayer( FPlayer );
end;

procedure TBerserkSession.ReleasePlayer;
begin
  if FRuntime.IO <> nil then FRuntime.IO.SetPlayer( nil );
  if FPlayer <> nil then FPlayer.Detach;
  Player := nil;
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
  Level := nil;
  FreeAndNil( FLevel );
  UIDs := nil;
  FreeAndNil( FUIDStore );
  Berserk := nil;
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
    FreeAndNil( FUIDStore );
    FUIDStore := TUIDStore.CreateFromStream( iSaveFile );
    UIDs := FUIDStore;
    // The arena is not serialized; keep its identity in the replacement store.
    FUIDStore.Register( FLevel, FLevel.UID );
    FPlayer := TPlayer.CreateFromStream( iSaveFile );
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
            not FSaveWritten and not Finished;
end;

function TBerserkSession.GetFinished : Boolean;
begin
  Result := FOutcome <> BSR_RUNNING;
end;

procedure TBerserkSession.Finish( aOutcome : TBerserkSessionResult );
begin
  FOutcome := aOutcome;
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
  begin
    FCreating := True;
    try
      Player.CreateCharacter( aQuick );
    finally
      FCreating := False;
    end;
  end;

  if not Finished and not UI.QuitRequested then
  begin
    UI.Msg( 'Berserk!' );
    UI.Msg( 'Press {^'+UI.Config.GetKeybinding( COMMAND_HELP )+'} for help.' );
  end;
  while not Finished and not UI.QuitRequested do
  begin
    Inc( Player.FNight );
    Player.Detach;
    Level.Clear;
    case Player.FMode of
      mode_Massacre : Level.Generate( Arena, Player.FMode, 1 );
      mode_Endless :
        begin
          if Player.FNight > 1 then
          begin
            UI.RunLayer( TNightLayer.Create );
            if Finished or UI.QuitRequested then Break;
            Player.Advance;
            if UI.QuitRequested then Break;
          end;
          Level.Generate( 1, Player.FMode, Player.FNight );
        end;
    end;
    UI.Screen := Game;
    UI.Shift := Clamp( Player.Position.x-11, 0, MAP_MAXX-21 ) * 24;
    if Assigned( Sound ) then Sound.PlayMusic( 'passive' );
    repeat
      Level.Tick;
    until Finished or UI.QuitRequested or Level.Flags[ LF_CLEARED ];
    if Assigned( Sound ) then Sound.PlayMusic( 'menu' );
    UI.Screen := Menu;
  end;
  UI.Screen := Menu;
  if UI.QuitRequested then Exit( BSR_QUIT );
  if FOutcome in [BSR_DEAD, BSR_ABANDONED] then
    UI.RunLayer( THOFLayer.Create( FRuntime.Persistence, Player.Mode, FOutcome = BSR_DEAD ) );
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
