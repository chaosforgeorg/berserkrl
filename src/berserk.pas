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
  SysUtils, vos, vlog, vutil,
  vsystems, vglquadbuffer,
  brdata, brmain;
  
var RootPath : AnsiString = '';

begin
  Randomize;

  {$IFDEF Darwin}
  {$IFDEF OSX_APP_BUNDLE}
  RootPath := GetResourcesPath();
  DataPath          := RootPath;
  ConfigurationPath := RootPath;
  SaveFilePath      := RootPath;
  {$ENDIF}
  {$ENDIF}

  {$IFDEF Windows}
  RootPath := ExtractFilePath( ParamStr(0) );
  DataPath          := RootPath;
  ConfigurationPath := RootPath;
  SaveFilePath      := RootPath;
  {$ENDIF}

  Logger.AddSink( TTextFileLogSink.Create( LOGDEBUG, RootPath+'log.txt', False ) );
  LogSystemInfo();
  Logger.Log( LOGINFO, 'Root path set to - '+RootPath );

  {$ifdef HEAPTRACE} SetHeapTraceOutput('heap.txt'); {$endif}
  Berserk := TBerserk.Create;
  try
    Berserk.Run;
  finally
    FreeAndNil( Berserk );
  end;
end.

