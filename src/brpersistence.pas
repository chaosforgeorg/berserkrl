// @abstract(BerserkRL)
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
//  @html </div>
{$INCLUDE brinclude.inc}
unit brpersistence;
interface
uses DOM, vxml, vuitypes, vxmldata;

const MAX_SCORE_ENTRIES = 500;
const SCORE_FILE_NAME   = 'score.dat';

type

{ TPersistence }

TPersistence = class
  constructor Create;
  procedure Add( aScore : LongInt; const aName : AnsiString; aMode, aKlass, aKills, aTurns, aNights, aResult : DWord );
  function Get( aId : DWord ) : TScoreEntry;
  function GetCurrent : DWord;
  destructor Destroy; override;
private
  FScoreFile : TScoreFile;
public
end;

implementation
uses SysUtils, Classes, vutil, brdata;

{ TPersistence }

constructor TPersistence.Create;
begin
  FScoreFile := TScoreFile.Create( ScorePath + SCORE_FILE_NAME, MAX_SCORE_ENTRIES );
  FScoreFile.Lock;
  try
    FScoreFile.Load;
  finally
    FScoreFile.Unlock;
  end;
end;

procedure TPersistence.Add( aScore : LongInt; const aName : AnsiString; aMode, aKlass, aKills, aTurns, aNights, aResult : DWord );
var iEntry   : TScoreEntry;
begin
  FScoreFile.Lock;
  try
    FScoreFile.Load;
    iEntry := FScoreFile.Add( aScore );
    if iEntry <> nil then 
    begin
      iEntry.SetAttribute('name',  aName );
      iEntry.SetAttribute('mode',  IntToStr(aMode) );
      iEntry.SetAttribute('klass', IntToStr(aKlass) );
      iEntry.SetAttribute('kills', IntToStr(aKills) );
      iEntry.SetAttribute('turns', IntToStr(aTurns) );
      iEntry.SetAttribute('nights', IntToStr(aNights) );
      iEntry.SetAttribute('result', IntToStr(aResult) );
      FScoreFile.Save;
    end;
  finally
    FScoreFile.Unlock;
  end;
end;

function TPersistence.Get(aId: DWord): TScoreEntry;
begin
  Exit( FScoreFile.GetEntry( aId ) );
end;

function TPersistence.GetCurrent: DWord;
begin
  Exit( FScoreFile.LastEntry );
end;

destructor TPersistence.Destroy;
begin
  FreeAndNil( FScoreFile );
end;

end.

