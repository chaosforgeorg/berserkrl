// @abstract(BerserkRL -- Main Application class)
// @author(Kornel Kisielewicz <admin@chaosforge.org>)
// @created(Oct 16, 2006)
// @lastmod(Oct 22, 2006)
//
// This unit just holds the TBerserk class -- the application framework
// for BerserkRL.
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

uses vsystem, brlua, brconfig,brlevel, brplayer,brdata,zstream,
     brgui,brtextui,brpersistence;


type
// Main application class.
// TBerserk is responsible initialization, running, and cleaning up afterwards
TBerserk = class(TSystem)
       // If set to true, means that the player requested a quit action.
       Escape      : Boolean;
       // Holds id number of the arena on which the player plays -- temporary
       Arena       : Byte;
       // Holds the berserk lua state
       Lua         : TBerserkLua;
       // Configuration
       Config      : TGameConfig;
       // Persistence
       Persistence : TPersistence;
       // Initialization of all data.
       constructor Create; override;
       // Saves the data after night is over
       procedure Save;
       // Loads the data
       procedure Load;
       // Checks wether a save file exists
       function SaveExists : Boolean;
       // Running the program -- main application loop is here.
       procedure   Run;
       // Cleaning up everything that was initialized in TBerserk.Create.
       destructor  Destroy; override;
       // Load audio
       procedure LoadAudio;
     end;

var Berserk : TBerserk = nil;

implementation

uses SysUtils, vmath, vuid, vioevent, vsound, vsdlsound, vfmodsound,
     vluasystem, vutil, vsystems, vparams, vrltools,
     brui, brviews;

{ TBerserk }

constructor TBerserk.Create;
var CP : TParams;
begin
  inherited Create;
  Berserk := Self;
  Version := ReadVersion(DataPath+'version.txt');
  CP := TParams.Create;
  if CP.isSet('god')  then GodMode := True;
  if CP.isSet('quick') then QuickStart := True;

  Config := TGameConfig.Create(ConfigurationPath+'config.lua');
  GraphicsMode := Config.Configure('GraphicsMode',True);
  if CP.isSet('console')  then GraphicsMode := False;
  if CP.isSet('graphics') then GraphicsMode := True;
  if GraphicsMode then
    UI := TBerserkGUI.Create(CP.isSet('fullscreen'))
  else
    UI := TBerserkTextUI.Create;
  if Config.Configure( 'audio.driver', 'SDL' ) = 'FMOD'
    then Sound := TFMODSound.Create( Config )
    else Sound := TSDLSound.Create( Config );
  Sound.Configure( Config );
  LoadAudio;
  Sound.PlayMusic('menu');
  UIDs := Systems.Add( TUIDStore.Create ) as TUIDStore;


  Lua := TBerserkLua.Create;
  LuaSystem := Systems.Add( Lua ) as TLuaSystem;
  Lua.Load();
  Persistence := TPersistence.Create;

  UI.Screen := Menu;

  FreeAndNil(CP);

  if GodMode then
    UI.RegisterDebugConsole( VKEY_BQUOTE );

  Level  := TLevel.Create;
  Escape := False;
  Player := TPlayer.Create( NewCoord2D( 1,1 ) );
  Arena     := 1;
  Player.FNight     := 0;
  UI.SetLevel( Level );
  UI.SetPlayer( Player );
  UI.Configure( Config );
end;

procedure TBerserk.Save;
var SaveFile  : TGZFileStream;
begin
  Dec(Player.FNight);
  SaveFile := TGZFileStream.Create(SaveFilePath+'berserk.sav',gzOpenWrite);
  UIDs.WriteToStream( SaveFile );
  Player.WriteToStream( SaveFile );
  SaveFile.Destroy;
end;

procedure TBerserk.Load;
var SaveFile : TGZFileStream;
begin
  FreeAndNil( Player );
  FreeAndNil( UIDs );
  SaveFile := TGZFileStream.Create(SaveFilePath+'berserk.sav',gzOpenRead);
  UIDs   := Systems.Add( TUIDStore.CreateFromStream( SaveFile ) ) as TUIDStore;
  Player := TPlayer.CreateFromStream( SaveFile );
  SaveFile.Destroy;
  DeleteFile(SaveFilePath+'berserk.sav');
end;

function TBerserk.SaveExists: Boolean;
begin
  Exit(FileExists(SaveFilePath+'berserk.sav'));
end;

procedure TBerserk.Run;
begin
//  UI.RunUILoop( TUIIntroScreen.Create( UI.Root ) );
  UI.RunUILoop( 'ui_intro_screen' );

  if SaveExists then Load
                else Player.CreateCharacter;
  
  repeat
    Inc(Player.FNight);
    Player.Detach;
    Level.Clear;
    case Player.FMode of
      mode_Massacre : Level.Generate(Arena,Player.FMode,1);
      mode_Endless  : begin
          if Player.FNight > 1 then
          begin
            UI.RunUILoop( 'ui_night_screen' );
            if SaveExists then Break;
            Player.Advance;
          end;
          Level.Generate(1,Player.FMode,Player.FNight);
        end;
    end;
    UI.Screen := Game;
    UI.Shift := Clamp( Player.Position.x-11, 0, MAP_MAXX-21 ) * 24;
    Sound.PlayMusic('passive');
    repeat
      Level.Tick;
    until Escape or Level.Flags[ LF_CLEARED ];
    Sound.PlayMusic('menu');
    UI.Screen := Menu;
  until Escape;
  if not SaveExists then UI.RunUILoop( 'ui_hof_screen' );
  UIDs := nil;

  UI.RunUILoop( 'ui_outro_screen' );
end;

destructor TBerserk.Destroy;
begin
  FreeAndNil(Sound);
  FreeAndNil(Persistence);
  FreeAndNil(Config);
  FreeAndNil(Level);
  FreeAndNil(Player);
  inherited Destroy;
end;

procedure TBerserk.LoadAudio;
var iSearchRec : TSearchRec;
    iName      : AnsiString;
    iExt       : AnsiString;
begin
  if FindFirst(DataPath+'sound' + PathDelim + '*.*',faAnyFile,iSearchRec) = 0 then
  repeat
    iName := iSearchRec.Name;
    iExt := ExtractFileExt( iName );
    if (iExt = '.mp3') or (iExt = '.wav') or (iExt = '.ogg') then
    begin
      Delete(iName,Length(iName)-3,4);
      Sound.RegisterSample(DataPath+'sound' + PathDelim + iSearchRec.Name,iName);
    end;
  until (FindNext(iSearchRec) <> 0);

  if FindFirst(DataPath+'music' + PathDelim + '*.*',faAnyFile,iSearchRec) = 0 then
  repeat
    iName := iSearchRec.Name;
    iExt := ExtractFileExt( iName );
    if (iExt = '.mp3') or (iExt = '.wav') or (iExt = '.ogg') or (iExt = '.mod') then
    begin
      Delete(iName,Length(iName)-3,4);
      Sound.RegisterMusic(DataPath+'music' + PathDelim + iSearchRec.Name,iName);
    end;
  until (FindNext(iSearchRec) <> 0);
end;

finalization

  if (ExitCode <> 0) then
  begin
    Writeln('Abnormal program termination! Please write down the above');
    Writeln('to help get rid Berserk! of all those bugs! You only need');
    Writeln('to write down the filenames and linenumbers.');
    if (Player <> nil) and (Player.FMode <> Mode_Massacre) then Berserk.Save;
    Readln;
  end;
end.

