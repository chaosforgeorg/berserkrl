// @abstract(BerserkRL -- TPlayer class unit)
// @author(Kornel Kisielewicz <admin@chaosforge.org>)
// @created(Oct 16, 2006)
// @lastmod(Oct 22, 2006)
//
// This unit just holds the TPlayer class -- a class representing the Player in
// Berserk. It is a descendant of TBeing (brbeing.pas) and overrides several
// it's methods to allow proper usage.
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
unit brplayer;
interface
uses SysUtils, Classes, vrltools, brbeing, brdata, brui;

type

// The Berserk player object. Should be only one, and always referenced by the
// Player pointer. TPlayer is a descendant of TBeing, and overrides it's methods
// where needed.

{ TPlayer }

TPlayer = class(TBeing)
  // Klass ID
  FKlass       : Byte;

  // Ammo counts
  FAmmo        : TPlayerAmmo;

  // The kills tables.
  FKills       : TKillTable;
  
  // The *S*kills table.
  FSkills      : TSkills;

  // Skill slots
  FSkillSlots  : array[1..SKILL_SLOTS] of Byte;

  // Count of turns passed. Based on actions of the player.
  FTurnCount   : DWord;

  // Defines the game mode - Massacre, Nights or Campaign
  FMode        : Byte;

  // Holds the night number for Endless mode.
  FNight       : Word;

  // Unused character generation points.
  FPoints      : Word;

// Temporary stats

  // Bonus to defense. Applicable when moving, or waiting.
  FDefBonus    : Byte;

  // Holds the the last attacker, used to check who killed the player.
  FLastEnemy   : AnsiString;

  // Marker on health bar
  FHealthMark  : Word;

  // Marker on energy bar
  FEnergyMark  : Word;

  // Target being nid - used by targeting code
  FTarget      : TBeing;

  // Creates a new player. It automaticaly sets the id and nid of the player
  // reference to the Player.
  constructor Create( pos : TCoord2D );
  // Initialize temporary stats
  procedure Init;
  // Handles character creation. Should be called after Create.
  procedure CreateCharacter;
  // Resets the player for a new day, and runs advancement.
  procedure Advance;
  // Writes a post mortem and shows it on the screen.
  procedure WriteMortem;
  // Overriden Die procedure. Contrary to TBeing.Die, the players Die procedure
  // DOES NOT free the player object!
  procedure Die; override;
  // Overriden action procedure -- handles Input parsing, and acting accordingly.
  procedure Action; override;
  // Returns True.
  function IsPlayer : Boolean; override;
  // Interface function for choosing target. Returns true when in Fire mode
  // target is accepted.
  function ChooseTarget( aTargetMode : Byte; aFireCmd : Byte ) : boolean;
  // Returns damage dice based on Strength + Berserk!
  function getDamageDice : Byte; override;
  // Ampplies damage to the player.
  procedure ApplyDamage(Amount : Word; DType : Byte); override;
  // Returns the number of adjacent to the player
  function enemiesAround : byte;
  // Increase skill
  procedure IncSkill( aSkillID : DWord );
  // Use skill
  function UseSkill( aSkillID : DWord; aCommand : Byte; aAlt : Boolean = False ) : Boolean;
  // Returns wether the given skill requirement is met.
  function ReqMet( const aID : AnsiString; aReqValue : DWord ) : Boolean;
  // Returns wether the given skill requirement is met.
  function ReqsMet( aSkillID : DWord ) : Boolean;
  // Returns name of requirement
  function ReqToString( const aID : AnsiString; aReqValue : DWord ) : AnsiString;
  // Frees all player data.
  destructor Destroy; override;
  // Returns the current light radius based on the players status.
  function LightRadius : Byte;
  // Returns status of BF_RUNNING flag - wether the player is running
  function isRunning : boolean;
  // Returns status of BF_BERSERK flag - wether the player is in berserk mode
  function isBerserk : boolean;
  // Return kill total -- TODO : remove and use a common TKillTable API!
  function GetKills : DWord;
  // Stream constructor
  constructor CreateFromStream( Stream : TStream ); override;
  // Write to stream
  procedure WriteToStream( Stream : TStream ); override;
  class procedure RegisterLuaAPI();
published
  property turn_count     : DWord    read FTurnCount;
  property mode           : Byte     read FMode       write FMode;
  property klass          : Byte     read FKlass      write FKlass;
  property health_mark    : Word     read FHealthMark write FHealthMark;
  property energy_mark    : Word     read FEnergyMark write FEnergyMark;
  property night          : Word     read FNight;
  property points         : Word     read FPoints     write FPoints;
  property def_bonus      : Byte     read FDefBonus   write FDefBonus;
  property dmg_dice       : Byte     read getDamageDice;
  property dmg_mod        : ShortInt read getDamageMod;
  property enemies_around : Byte     read enemiesAround;
end;

var Player : TPlayer = nil;


implementation
uses vutil, vluastate, vluasystem, vluatable, brviews, brmain, brlevel, vsound, math;


{ TPlayer }

constructor TPlayer.Create( pos : TCoord2D );
var i : DWord;
begin
  inherited Create('yourself', pos);
  Init;
  FTurnCount := 0;
  for i := Low( FSkillSlots ) to High( FSkillSlots ) do FSkillSlots[i] := 0;
  for i := Low( FStats )      to High( FStats )      do FStats[i]      := 10;
  for i := Low( FAmmo )       to High( FAmmo )       do FAmmo[i]       := 0;
  FPoints := 0;
  FHPMax  := 100;
  FHP     := FHPMax;
  FArmor  := 0;
  FKlass  := 1;

  FKills := TKillTable.Create;
  Player := Self;
  Berserk.Lua.RegisterPlayer;
end;

procedure TPlayer.Init;
var i : DWord;
begin
  FLastEnemy  := '';
  FDefBonus   := 0;
  FHealthMark := 0;
  FEnergyMark := 0;

  for i := Low( FSkills ) to High( FSkills ) do FSkills[ i ] := 0;
end;

procedure TPlayer.CreateCharacter;
var ModeNum     : Byte;
begin

  UI.RunUILoop( 'ui_mode_screen' );
  // Choose klass
  LuaSystem.ProtectedCall( ['klasses',FKlass,'OnCreate'], [Self, FMode]);

  if FMode = mode_Massacre
    then FPoints := 14
    else FPoints := 8;

  if QuickStart then
  begin
    FName         := 'Epyon';
    Berserk.Arena := ARENA_TOWN;
    FPoints       := 0;
    LuaSystem.ProtectedCall( ['klasses',FKlass,'OnQuick'], [Self, FMode]);
  end
  else
  begin
    FName := '';
    if not Option_AlwaysRandomName then
      UI.RunUILoop( 'ui_name_screen' );
    UI.Console.HideCursor;
    if FName = '' then
    case Random(8) of
      0..1 : FName := 'Guts';
      2    : FName := 'Glowie';
      3    : FName := 'Turgor';
      4    : FName := 'Fingerzam';
      5    : FName := 'Malek';
      6    : FName := 'Jorge';
      7    : FName := 'Thomas';
    end;

    UI.RunUILoop( 'ui_stats_screen' );

    if FMode = mode_Massacre then
    begin
      UI.RunUILoop( 'ui_arena_screen' );
      UI.RunUILoop( 'ui_skills_screen' );
      UI.RunUILoop( 'ui_skills_screen' );
      UI.RunUILoop( 'ui_skills_screen' );
    end
    else
      UI.RunUILoop( 'ui_skills_screen' );
  end;

  FHPMax  := 100 + (En-10)*5 + FBonus[ BONUS_HP ];
  FENMax  := 100 + (En-10)*5 + (WP-10)*5;
  FSpeed  := 95+DX;
  FWeight := EN;

  FHP := FHPMax;
  FEN := FENMax;
end;

procedure TPlayer.Advance;
begin
  Inc( FPoints );
  // Run advancement screens
  UI.RunUILoop( 'ui_stats_screen' );

  // Choose skill
  UI.RunUILoop( 'ui_skills_screen' );


  // Recalculate stats
  FHPMax  := 100 + (EN-10)*5 + FBonus[ BONUS_HP ];
  FENMax  := 100 + (EN-10)*5 + (WP-10) * 5;
  FSpeed  := 95+DX;
  FWeight := EN;

  // Update current stats.
  FEN := FENMax;
  FHP := Min(FHPMax,FHP+EN*5);

  LuaSystem.ProtectedCall( ['klasses',FKlass,'OnAdvance'], [Self, FMode]);

  // Game stats reset
  FTarget      := nil;
  FTargetCoord := ZeroCoord2D;
  FLastEnemy   := '';
  FFlags       := [];
  FHealthMark  := 0;
  FEnergyMark  := 0;
  FDefBonus    := 0;
  
  FPain        := 0;
  FFreeze      := 0;
end;

procedure TPlayer.WriteMortem;
var Mortem  : Text;
    iAmount : DWord;
    iFound  : Boolean;
    Count   : byte;
    Count2  : byte;
begin
  Assign(Mortem,SaveFilePath+'mortem.txt');
  Rewrite(Mortem);
  FFlags := []; // reset berserk and running
  Writeln(Mortem,Padded('-- Berserk! ('+Version+') Post Mortem ',70,'-'));
  Writeln(Mortem,'');
  Writeln(Mortem,'  Character name  : '+FName);
  Writeln(Mortem,'  Game type       : '+ModeToString(FMode));
  if FMode <> mode_Massacre then
  Writeln(Mortem,'  Nights survived : '+IntToStr(FNight));
  Writeln(Mortem,'  Monsters killed : '+IntToStr(FKills.Count));

  Writeln(Mortem,'');
  Writeln(Mortem,'  STR: ',ST, '  DEX: ',DX,'  END: ',EN,'  WIL: ',WP);
  Writeln(Mortem,'  Speed: ',FSpeed,'  HP: ',FHP,'/',FHPMax,'  EN: ',FEN,'/',FENMax);
  Writeln(Mortem,'  Base damage: ',getDamageDice,'d6+',getDamageMod+5,'  Weight: ',FWeight);
  Writeln(Mortem,'');
  Writeln(Mortem,Padded('-- Graveyard ',70,'-'));
  Writeln(Mortem,'');
  for Count2 := 1 to MAP_MAXY do
  begin
    Write(Mortem,'  ');
    for Count := 1 to MAP_MAXX do
        if Level.Being[ NewCoord2D(Count,Count2) ] <> nil then Write(Mortem,Level.Being[ NewCoord2D(Count,Count2) ].Picture)
                                                          else Write(Mortem,Chr(Level.Terrain[ NewCoord2D(Count,Count2) ].Picture mod 256));

    Writeln(Mortem,'');
  end;
    Writeln(Mortem,'');
  Writeln(Mortem,Padded('-- Inventory left ',70,'-'));
  Writeln(Mortem,'');
  iFound := False;
  for Count := 1 to MAXSKILLS do
    if FSkills[Count] > 0 then
    begin
      Count2 := LuaSystem.Get(['skills',Count,'ammo_slot']);
      if (Count2 <> 0) and (FAmmo[ Count2 ] > 0) then
      begin
        Write(Mortem,'  ',LuaSystem.Get(['skills',Count,'name']),' (',FAmmo[ Count2 ],')');
        iFound := True;
      end;
    end;
  if not iFound then Writeln(Mortem,'  Nothing');
  Writeln(Mortem,'');
  Writeln(Mortem,Padded('-- Kills ('+IntToStr(FKills.Count)+') ',70,'-'));
  Writeln(Mortem,'');
  Count2 := LuaSystem.Get(['beings','__counter']);
  for Count := 1 to Count2 do
  begin
    iAmount := FKills.Get( LuaSystem.Get(['beings',Count,'id']) );
    if iAmount <> 0 then
      if iAmount = 1 then Writeln(Mortem,'  1 ',LuaSystem.Get(['beings',Count,'name']))
                     else Writeln(Mortem,'  ',iAmount,' ',LuaSystem.Get(['beings',Count,'namep']));
  end;
  Writeln(Mortem,'');
  Count2 := 0;
  for Count := 1 to MAXSKILLS do
    Count2 += FSkills[Count];
  Writeln(Mortem,Padded('-- Skills ('+IntToStr(Count2)+') ',70,'-'));
  Writeln(Mortem,'');
  for Count := 1 to MAXSKILLS do
    if FSkills[Count] > 0 then
      if LuaSystem.Get(['skills',Count,'pickable']) then
        Writeln(Mortem,'  ',LuaSystem.Get(['skills',Count,'name']),' (level ',FSkills[Count],')');
  Writeln(Mortem,'');
  Writeln(Mortem,Padded('-- Messages ',70,'-'));
  Writeln(Mortem,'');
  UI.MsgDump(Mortem);
  Writeln(Mortem,'');
  Writeln(Mortem,Padded('-- Achievements ',70,'-'));
  Writeln(Mortem,'');
  Writeln(Mortem,'  Max kills in one turn    : ',FKills.BestTurn);
  Writeln(Mortem,'  Longest killing sequence : ',FKills.BestSequence,' kills in ',FKills.BestSequenceLength,' turns.');
  Writeln(Mortem,'  Max kills without damage : ',FKills.BestNoDamageSequence);
  Writeln(Mortem,'  Survived for             : ',FTurnCount,' turns');
  Writeln(Mortem,'  Died on                  : ',ArenaToString(Level.FArena));
  Write  (Mortem,'  Reason of death          : ');
  if FLastEnemy = 'player' then Writeln(Mortem,'suicide')
    else if (FLastEnemy <> '') then Writeln(Mortem,'killed by a ',LuaSystem.Get(['beings',FLastEnemy,'name']))
    else Writeln(Mortem,'unknown');
  Writeln(Mortem,'');
  Close(Mortem);
  UI.RunUILoop( 'ui_mortem_screen' );
end;

procedure TPlayer.Die;
var iLast : DWord;
begin
  FKills.Update(FTurnCount);
  FKills.Update(FTurnCount);
  UI.Blink(Red,200,0);
  UI.Msg('You die!...');
  UI.Msg('Press <@<Enter@>>');
  UI.Draw;
  UI.PressEnter;
  Berserk.Escape := True;
  UI.Screen := Menu;
  iLast := LuaSystem.Get(['beings',FLastEnemy,'nid']);
  Berserk.Persistence.Add(FKills.Count, FName, FMode,  FKlass, FKills.Count, FTurnCount, FNight, iLast );
  WriteMortem;
end;

function TPlayer.UseSkill( aSkillID : DWord; aCommand : Byte; aAlt : Boolean ) : Boolean;
begin
  if aSkillID = 0 then
  begin
    UI.Msg('You don''t have a skill or item in this slot!');
    Exit( False );
  end;
  if FSkills[aSkillID] = 0 then
  begin
    UI.Msg('You don''t have the '+LuaSystem.Get(['skills',aSkillID,'name'])+' skill!');
    Exit( False );
  end;
  if aAlt then
  begin
    if LuaSystem.Defined(['skills',aSkillID,'OnAltUse']) then
      Exit( LuaSystem.ProtectedCall(['skills',aSkillID,'OnAltUse'],[Player,FSkills[aSkillID], aCommand ] ) );
    UI.Msg( 'What?' );
    Exit( False );
  end
  else
    Exit( LuaSystem.ProtectedCall(['skills',aSkillID,'OnUse'],[Player,FSkills[aSkillID], aCommand ] ) );
end;

procedure TPlayer.Action;
var Command    : Byte;
    MoveCoord  : TCoord2D;
    MoveResult : Byte;
    Direction  : TDirection;
    Amount     : Word;
    dxa,dya    : Word;
    dxv,dyv    : ShortInt;
    AFlags     : TFlags;
    Cost       : Word;
    Slip       : Boolean;
begin
  Inc(FTurnCount);
  FDefBonus  := 0;
  LuaSystem.ProtectedCall(['klasses',FKlass,'OnTick'],[Self]);
  if FKills.ThisTurn > 5 then UI.Msg(IntToStr(FKills.ThisTurn)+' kills!');
  FKills.Update(FTurnCount);

repeat
  if FEN < 10 then Exclude(FFlags,BF_RUNNING);
  Command := 0;
  UI.Draw;
  FAttackCount := 0;

  Level.RunCellHook( FPosition, TileHook_OnStanding, [Self] );

  Slip := False;
  
  if ( TF_ICE in Level.getFlags( FPosition ) ) and (Dice(3,6) > DX) then
    Slip := True;

  if not Slip then
  begin
    Command := UI.GetCommand;
    UI.MsgUpdate;
    if Command = 0 then UI.Msg('Press @<'+Berserk.Config.GetKeybinding(COMMAND_HELP)+'@> for help.');
  end;
  
  if (Command in COMMANDS_MOVE) or Slip then
  begin
    if Slip then
    begin
      Direction.Create( Random(9)+1 );
      UI.Msg('You slip!');
      FSpeedCount -= 500;
    end
    else Direction := UI.CommandDirection(Command);
    MoveCoord := FPosition + Direction;
    MoveResult := TryMove( MoveCoord );
    if (MoveResult = Move_Ok) or (MoveCoord = FPosition) then
    begin
      UI.AddMove( UID, FPosition, MoveCoord );
      Displace( MoveCoord );
      FDefBonus  := Max(1,FDefBonus);
      if isRunning then
      begin
        Dec(FEN,10-FBonus[BONUS_RUN]);
        Cost := 750-FBonus[BONUS_RUN] * 50;
        FDefBonus  := Max(2,FDefBonus);
      end else Cost := 1000;
      FSpeedCount -= Round((Cost / 200)*(Level.getMoveCost( FPosition )+Level.getMoveCost( MoveCoord )));
    end
    else
    if (MoveResult = Move_Being) then
    begin
      if (Level.Being[ MoveCoord ].FAI <> AI_MONSTER) and (not isBerserk) then UI.Msg('Let them live... a little longer.')
      else
      begin
        Attack(Level.Being[ MoveCoord ]);
        FSpeedCount -= 1000;
      end;
    end;
     // TEMPORARY
  end;
  
  case Command of
    COMMAND_WAIT : begin FSpeedCount -= 1000; FDefBonus := Max(3,FDefBonus); end;
    COMMAND_LOOK : begin
        UI.Msg('Look mode, @<ESC@> to exit.');
        UI.Msg('You see:');
        ChooseTarget( TM_LOOK, COMMAND_LOOK );
      end;

    COMMAND_RUNNING :
      if FEN < 10   then UI.Msg('You''re to exhausted to run!') else
      if isRunning  then Exclude(FFlags,BF_RUNNING)
                    else Include(FFlags,BF_RUNNING);

    COMMAND_HELP      : UI.RunUILoop( 'ui_help_screen' );
    COMMAND_PLAYERINFO: UI.RunUILoop( 'ui_char_screen' );
    COMMAND_MESSAGES  : UI.MsgPast;

    COMMAND_QUIT      : begin
        Berserk.Escape := True;
        FSpeedCount -= 1000;
      end;
      
    COMMAND_SKILL1   ..COMMAND_SKILL0    : UseSkill( FSkillSlots[Command-COMMAND_SKILL1+1], Command );
    COMMAND_SKILLALT1..COMMAND_SKILLALT0 : UseSkill( FSkillSlots[Command-COMMAND_SKILLALT1+1], Command, True );

  end;
until FSpeedCount <= SPEEDLIMIT;
  if FHP <= FHPMax div 10 then FDefBonus += FBonus[ BONUS_SURVIVE ];
end;


function TPlayer.IsPlayer : Boolean;
begin
  Exit(True);
end;

function TPlayer.ChooseTarget( aTargetMode : Byte; aFireCmd : Byte ) : boolean;
var Dir     : TDirection;
    Key     : Byte;
    Targets : TAutoTarget;
    Target  : TCoord2D;
    scx,scy : Integer;
    AISet   : TAITypeSet;
begin
  UI.Msg('--------------------');
  Targets := TAutoTarget.Create( FPosition );
  
  if isBerserk then AISet := [AI_MONSTER,AI_CIVILIAN,AI_ALLY]
               else AISet := [AI_MONSTER];
               
  for scx := Max(1,FPosition.x-LightRadius-1) to Min(MAP_MAXX,FPosition.x+LightRadius+1) do
    for scy := Max(1,FPosition.y-LightRadius-1) to Min(MAP_MAXY,FPosition.y+LightRadius+1) do
    begin
      Target := NewCoord2D( scx,scy );
      if Level.Being[ Target ] <> nil then
        if Level.Being[ Target ].FAI in AISet then
         if isInLOS( Target ) then
           Targets.AddTarget( Target );
    end;

  if aTargetMode in [TM_FIRE,TM_THROW] then
    if FTarget <> nil then
      with FTarget do
        Targets.PriorityTarget( FPosition );

  Target := Targets.Current;
  
  repeat
    if aTargetMode = TM_FIRE then
      UI.Target(Target,RED);
    if aTargetMode = TM_THROW then
    begin
      if Distance(FPosition,Target) > BOMBDISTANCE
        then UI.Target(Target,DarkGray)
        else UI.Target(Target,Red);
    end;
    UI.Focus(Target);
    UI.MsgCoord(Target);

    if aTargetMode  in [TM_FIRE,TM_THROW] then
      Key := UI.GetCommand(COMMANDS_MOVE+[COMMAND_ESCAPE,COMMAND_RUNNING, aFireCmd ])
    else
      Key := UI.GetCommand(COMMANDS_MOVE+[COMMAND_ESCAPE,COMMAND_RUNNING]);
    if Key = COMMAND_ESCAPE   then begin Target := ZeroCoord2D; Break; end;
    if Key = COMMAND_RUNNING  then Target := Targets.Next;
    if (Key in COMMANDS_MOVE) then
    begin
      Dir := UI.CommandDirection(Key);
      if Level.isProperCoord(Target + Dir) then
        Target += Dir;
    end;
  until Key in [aFireCmd];
  UI.Target(Target,BLACK);
  FTargetCoord := Target;

  FreeAndNil(Targets);

  if FTargetCoord.x = 0 then Exit(False);
  if Level.Being[ FTargetCoord ] <> nil then FTarget := Level.Being[ FTargetCoord ];
  Exit(True);
end;


function TPlayer.getDamageDice : Byte;
begin
  if isBerserk then Exit(2* inherited getDamageDice)
               else Exit(inherited getDamageDice);
end;

procedure TPlayer.ApplyDamage(Amount : Word; DType : Byte);
begin
  if isBerserk then Amount := Amount div 2;
  if FHP <= FHPMax div 10 then Amount := Max( 1, Amount - FBonus[ BONUS_SURVIVE ] * 2 );
  FKills.DamageTaken;
  inherited ApplyDamage(Amount,DType);
end;

function TPlayer.enemiesAround : byte;
var sx,sy : Byte;
begin
  enemiesAround := 0;
  for sx := FPosition.x-1 to FPosition.x+1 do
    for sy := FPosition.y-1 to FPosition.y+1 do
      if Level.Being[ NewCoord2D( sx,sy ) ] <> nil then Inc(enemiesAround);
  Dec( enemiesAround ); // Player
end;

procedure TPlayer.IncSkill(aSkillID: DWord);
var i : Byte;
begin
  if LuaSystem.Defined( ['skills', aSkillID, 'OnUse'] ) then
    if FSkills[ aSkillID ] = 0 then
      for i := Low( FSkillSlots ) to High( FSkillSlots ) do
        if FSkillSlots[i] = 0 then
        begin
          FSkillSlots[i] := aSkillID;
          Break;
        end;
  Inc( FSkills[ aSkillID ] );
  if LuaSystem.Defined( ['skills', aSkillID, 'OnPick'] ) then
    LuaSystem.ProtectedCall( ['skills', aSkillID, 'OnPick'], [ Self, FSkills[ aSkillID ] ] );
end;

function TPlayer.ReqMet(const aID: AnsiString; aReqValue: DWord): Boolean;
var iSkillID : DWord;
begin
  ReqMet := True;
  if aID = 'st' then Exit(ST >= aReqValue);
  if aID = 'dx' then Exit(DX >= aReqValue);
  if aID = 'wp' then Exit(WP >= aReqValue);
  if aID = 'en' then Exit(EN >= aReqValue);
  iSkillID := LuaSystem.Defines[ aID ];
  Exit( FSkills[ iSkillID ] >=  aReqValue );
end;

function TPlayer.ReqsMet(aSkillID: DWord): Boolean;
var iPair : TLuaValuePair;
begin
  ReqsMet := True;
  with LuaSystem.GetTable(['skills',aSkillID,'reqs']) do
  try
    for iPair in Pairs do
      if not ReqMet( iPair.Key.ToString, iPair.Value.ToInteger ) then Exit( False );
  finally
    Free;
  end;
end;

function TPlayer.ReqToString( const aID : AnsiString; aReqValue : DWord ) : AnsiString;
begin
  if aID = 'st' then Exit('Strength '+IntToStr(aReqValue));
  if aID = 'dx' then Exit('Dexterity '+IntToStr(aReqValue));
  if aID = 'wp' then Exit('Willpower '+IntToStr(aReqValue));
  if aID = 'en' then Exit('Endurance '+IntToStr(aReqValue));
  Exit( LuaSystem.Get(['skills',aID,'name'])+' level '+IntToStr(aReqValue) );
end;

function TPlayer.LightRadius : Byte;
begin
  if FHP < 1 then Exit(1);
  if FHP < (FHPMax div 5) then
    LightRadius := 1 + Round((FHP/FHPMax)*45)
  else Exit(10);
end;

function TPlayer.isRunning : boolean;
begin
  Exit(BF_RUNNING in FFlags);
end;

function TPlayer.isBerserk : boolean;
begin
  Exit(BF_BERSERK in FFlags);
end;

function TPlayer.GetKills: DWord;
begin
  Exit( FKills.Count );
end;

constructor TPlayer.CreateFromStream ( Stream : TStream ) ;
begin
  inherited CreateFromStream ( Stream ) ;
  Init;
  FKills := TKillTable.CreateFromStream( Stream );

  Stream.Read( FAmmo,       SizeOf( FAmmo ) );
  Stream.Read( FSkills,     SizeOf( FSkills ) );
  Stream.Read( FSkillSlots, SizeOf( FSkillSlots ) );

  FTurnCount := Stream.ReadDWord;
  FKlass     := Stream.ReadByte;
  FMode      := Stream.ReadWord;
  FNight     := Stream.ReadWord;
  FPoints    := Stream.ReadWord;

  Player := Self;
  Berserk.Lua.RegisterPlayer;
end;

procedure TPlayer.WriteToStream ( Stream : TStream ) ;
begin
  inherited WriteToStream ( Stream ) ;
  FKills.WriteToStream( Stream );

  Stream.Write( FAmmo,       SizeOf( FAmmo ) );
  Stream.Write( FSkills,     SizeOf( FSkills ) );
  Stream.Write( FSkillSlots, SizeOf( FSkillSlots ) );

  Stream.WriteDWord( FTurnCount );
  Stream.WriteByte( FKlass );
  Stream.WriteWord( Word( FMode ) );
  Stream.WriteWord( FNight );
  Stream.WriteWord( FPoints );
end;

destructor TPlayer.Destroy;
begin
  FreeAndNil( FKills );
  inherited Destroy;
  Player := nil;
end;

function lua_player_get_skill_slot(L: Plua_State): Integer; cdecl;
var State  : TLuaState;
    Player : TPlayer;
begin
  State.Init(L);
  Player := State.ToObject(1) as TPlayer;
  State.Push( Player.FSkillSlots[State.ToInteger(2)] );
  Result := 1;
end;

function lua_player_get_skill(L: Plua_State): Integer; cdecl;
var State  : TLuaState;
    Player : TPlayer;
begin
  State.Init(L);
  Player := State.ToObject(1) as TPlayer;
  if State.IsNumber(2)
    then State.Push( Player.FSkills[State.ToInteger(2)] )
    else State.Push( Player.FSkills[LuaSystem.Defines[State.ToString(2)]] );
  Result := 1;
end;

function lua_player_inc_skill(L: Plua_State): Integer; cdecl;
var State  : TLuaState;
    Player : TPlayer;
begin
  State.Init(L);
  Player := State.ToObject(1) as TPlayer;
  if State.IsNumber(2)
    then Player.IncSkill(State.ToInteger(2))
    else Player.IncSkill(LuaSystem.Defines[State.ToString(2)]);
  Result := 1;
end;

function lua_player_get_ammo(L: Plua_State): Integer; cdecl;
var State  : TLuaState;
    Player : TPlayer;
begin
  State.Init(L);
  Player := State.ToObject(1) as TPlayer;
  State.Push( Player.FAmmo[State.ToInteger(2)] );
  Result := 1;
end;

function lua_player_set_ammo(L: Plua_State): Integer; cdecl;
var State  : TLuaState;
    Player : TPlayer;
begin
  State.Init(L);
  Player := State.ToObject(1) as TPlayer;
  Player.FAmmo[State.ToInteger(2)] := State.ToInteger(3);
  Result := 0;
end;

function lua_player_choose_target(L: Plua_State): Integer; cdecl;
var State  : TLuaState;
    Player : TPlayer;
begin
  State.Init(L);
  Player := State.ToObject(1) as TPlayer;
  State.Push( Player.ChooseTarget( State.ToInteger( 2 ), State.ToInteger( 3 ) ) );
  Result := 1;
end;

const lua_player_lib : array[0..6] of luaL_Reg = (
  ( name : 'get_skill_slot';func : @lua_player_get_skill_slot),
  ( name : 'get_skill';     func : @lua_player_get_skill),
  ( name : 'inc_skill';     func : @lua_player_inc_skill),
  ( name : 'get_ammo';      func : @lua_player_get_ammo),
  ( name : 'set_ammo';      func : @lua_player_set_ammo),
  ( name : 'choose_target'; func : @lua_player_choose_target),
  ( name : nil;             func : nil; )
);

// Register API
class procedure TPlayer.RegisterLuaAPI();
begin
  LuaSystem.Register( 'player', lua_player_lib );
end;


end.

