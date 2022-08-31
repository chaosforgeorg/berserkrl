// @abstract(BerserkRL)
// @author(Kornel Kisielewicz <admin@chaosforge.org>)
//
// This is the program file for BerserkRL. The program is written in FreePascal,
// ( http://www.freepascal.org/ ), you'll need a copy of it to compile it manualy.
// Program has been tested to compile under 2.6.0 version of FreePascal, cant
// guarantee it will compile under older versions. You will also need the
// Valkyrie library, that is available at ( http://valkyrie.chaosforge.org/ )
// You can get a binary copy of BerserkRL at it's website
// ( http://berserk.chaosforge.org/ ).
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
program berserkrl;
uses
  {$ifdef HEAPTRACE} heaptrc, {$endif}
  SysUtils, vsystems, vos, vlog, vutil, vparams, vdebug,
  brdata, brconfig, brmain, brui;
  
var RootPath : AnsiString = '';
    Config   : TGameConfig;
    CmdLine  : TParams;

begin
  Randomize;

  {$IFDEF Darwin}
  {$IFDEF OSX_APP_BUNDLE}
  RootPath := GetResourcesPath();
  DataPath          := RootPath;
  ConfigurationPath := RootPath + 'config.lua';
  WritePath         := RootPath;
  {$ENDIF}
  {$ENDIF}

  {$IFDEF Windows}
  RootPath := ExtractFilePath( ParamStr(0) );
  DataPath          := RootPath;
  ConfigurationPath := RootPath + 'config.lua';
  WritePath         := RootPath;
  {$ENDIF}

  Logger.AddSink( TTextFileLogSink.Create( LOGDEBUG, WritePath + 'log.txt', False ) );
  LogSystemInfo();
  Logger.Log( LOGINFO, 'Log path set to - '+WritePath );

  {$IFDEF HEAPTRACE}
  SetHeapTraceOutput( WritePath + 'heap.txt' );
  {$ENDIF}

  Version := ReadVersion( DataPath + 'version.txt' );

  CmdLine := TParams.Create;
  if CmdLine.isSet('god')  then GodMode := True;
  if CmdLine.isSet('quick') then QuickStart := True;
  if CmdLine.isSet('config') then 
    ConfigurationPath := CmdLine.get('config');

  Config  := TGameConfig.Create( ConfigurationPath );
  GraphicsMode := Config.Configure( 'GraphicsMode',True );
  HighASCII    := Config.Configure( 'HighASCII', True );
  AudioDriver  := Config.Configure( 'audio.driver', 'SDL' );
  DataPath     := Config.Configure( 'DataPath', DataPath );
  WritePath    := Config.Configure( 'WritePath', WritePath );
  ScorePath    := Config.Configure( 'ScorePath', ScorePath );
  
  if CmdLine.isSet('nosound')    then AudioDriver  := 'NONE';
  if CmdLine.isSet('console')    then GraphicsMode := False;
  if CmdLine.isSet('graphics')   then GraphicsMode := True;
  if CmdLine.isSet('lowascii')   then HighASCII    := False;
  if CmdLine.isSet('fullscreen') then FullScreen   := True;

  if CmdLine.isSet('datapath')   then DataPath          := CmdLine.get('datapath');
  if CmdLine.isSet('writepath')  then DataPath          := CmdLine.get('writepath');
  if CmdLine.isSet('scorepath')  then DataPath          := CmdLine.get('scorepath');
  if CmdLine.isSet('name')       then Option_AlwaysName := CmdLine.get('name');

  FreeAndNil( CmdLine );

  if ScorePath = '' then ScorePath := WritePath;
  ErrorLogFileName := WritePath + 'error.log';

  Berserk := TBerserk.Create( Config );
  try
    Berserk.Run;
  finally
    FreeAndNil( Berserk );
  end;
end.

