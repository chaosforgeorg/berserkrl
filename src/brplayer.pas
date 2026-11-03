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
uses sysutils, classes, vnode, vrltools, vlua, brbeing, brdata;

type

// The Berserk player object. The Session owns it. TPlayer is a descendant of
// TBeing, and overrides it's methods where needed.

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

  // Set by Die; the Session ends the run. Not saved.
  FDied        : Boolean;

  // Creates a new player. It automaticaly sets the id and nid of the player
  // reference to the Player.
  constructor Create( aContext : TNodeContext; pos : TCoord2D );
  // Initialize temporary stats
  procedure Init;
  // Sets the derived stats and fills health and energy after character creation.
  procedure FinishCreation;
  // Applies the chosen advancement and resets the player for a new night.
  procedure ApplyAdvancement;
  // Writes a post mortem to the given file.
  procedure WriteMortem( const aFileName, aVersion : AnsiString );
  // Overriden Die procedure. Contrary to TBeing.Die, the players Die procedure
  // DOES NOT free the player object!
  procedure Die; override;
  // What happens when the player's turn comes.
  procedure BeginTurn;
  // What happens before each command of a turn.
  procedure BeginCommand;
  // Whether the player loses footing instead of getting a command.
  function Slips : Boolean;
  // Slips in a random direction.
  procedure ActionSlip;
  // Moves, or attacks a being in the way.
  procedure ActionMove( const aDirection : TDirection );
  // Waits a turn.
  procedure ActionWait;
  // Starts or stops running.
  procedure ActionToggleRun;
  // What happens when the player's turn ends.
  procedure EndTurn;
  // Returns True.
  function IsPlayer : Boolean; override;
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
  constructor CreateFromStream( Stream : TStream; aContext : TNodeContext ); override;
  // Write to stream
  procedure WriteToStream( Stream : TStream ); override;
  class procedure RegisterLuaAPI( aLua : TLua );
private
  // Recalculates the stats derived from attributes.
  procedure RecalculateStats;
public
  property Died : Boolean read FDied;
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

implementation
uses math, vutil, vluastack, vluatable, brlevel;

{ TPlayer }

constructor TPlayer.Create( aContext : TNodeContext; pos : TCoord2D );
var i : DWord;
begin
  inherited Create( aContext, 'yourself', pos );
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
end;

procedure TPlayer.Init;
var i : DWord;
begin
  FDied       := False;
  FLastEnemy  := '';
  FDefBonus   := 0;
  FHealthMark := 0;
  FEnergyMark := 0;

  for i := Low( FSkills ) to High( FSkills ) do FSkills[ i ] := 0;
end;

procedure TPlayer.RecalculateStats;
begin
  FHPMax  := 100 + (EN-10)*5 + FBonus[ BONUS_HP ];
  FENMax  := 100 + (EN-10)*5 + (WP-10)*5;
  FSpeed  := 95+DX;
  FWeight := EN;
end;

procedure TPlayer.FinishCreation;
begin
  RecalculateStats;
  FHP := FHPMax;
  FEN := FENMax;
end;

procedure TPlayer.ApplyAdvancement;
begin
  RecalculateStats;

  // Update current stats.
  FEN := FENMax;
  FHP := Min(FHPMax,FHP+EN*5);

  FContext.Lua.ProtectedCall( ['klasses',FKlass,'OnAdvance'], [Self, FMode]);

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

procedure TPlayer.WriteMortem( const aFileName, aVersion : AnsiString );
var Mortem  : Text;
    iAmount : DWord;
    iFound  : Boolean;
    Count   : byte;
    Count2  : byte;
    iLevel  : TLevel;
begin
  iLevel := TLevel( Parent );
  Assign(Mortem, aFileName );
  Rewrite(Mortem);
  FFlags := []; // reset berserk and running
  Writeln(Mortem,Padded('-- Berserk! ('+aVersion+') Post Mortem ',70,'-'));
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
        if iLevel.Being[ NewCoord2D(Count,Count2) ] <> nil then Write(Mortem,iLevel.Being[ NewCoord2D(Count,Count2) ].Picture)
                                                           else Write(Mortem,Chr(iLevel.Terrain[ NewCoord2D(Count,Count2) ].Picture mod 256));

    Writeln(Mortem,'');
  end;
    Writeln(Mortem,'');
  Writeln(Mortem,Padded('-- Inventory left ',70,'-'));
  Writeln(Mortem,'');
  iFound := False;
  for Count := 1 to MAXSKILLS do
    if FSkills[Count] > 0 then
    begin
      Count2 := FContext.Lua.Get(['skills',Count,'ammo_slot']);
      if (Count2 <> 0) and (FAmmo[ Count2 ] > 0) then
      begin
        Write(Mortem,'  ',FContext.Lua.Get(['skills',Count,'name']),' (',FAmmo[ Count2 ],')');
        iFound := True;
      end;
    end;
  if not iFound then Writeln(Mortem,'  Nothing');
  Writeln(Mortem,'');
  Writeln(Mortem,Padded('-- Kills ('+IntToStr(FKills.Count)+') ',70,'-'));
  Writeln(Mortem,'');
  Count2 := FContext.Lua.Get(['beings','__counter']);
  for Count := 1 to Count2 do
  begin
    iAmount := FKills.Get( FContext.Lua.Get(['beings',Count,'id']) );
    if iAmount <> 0 then
      if iAmount = 1 then Writeln(Mortem,'  1 ',FContext.Lua.Get(['beings',Count,'name']))
                     else Writeln(Mortem,'  ',iAmount,' ',FContext.Lua.Get(['beings',Count,'namep']));
  end;
  Writeln(Mortem,'');
  Count2 := 0;
  for Count := 1 to MAXSKILLS do
    Count2 += FSkills[Count];
  Writeln(Mortem,Padded('-- Skills ('+IntToStr(Count2)+') ',70,'-'));
  Writeln(Mortem,'');
  for Count := 1 to MAXSKILLS do
    if FSkills[Count] > 0 then
      if FContext.Lua.Get(['skills',Count,'pickable']) then
        Writeln(Mortem,'  ',FContext.Lua.Get(['skills',Count,'name']),' (level ',FSkills[Count],')');
  Writeln(Mortem,'');
  Writeln(Mortem,Padded('-- Messages ',70,'-'));
  Writeln(Mortem,'');
  iLevel.Presentation.MsgDump(Mortem,10);
  Writeln(Mortem,'');
  Writeln(Mortem,Padded('-- Achievements ',70,'-'));
  Writeln(Mortem,'');
  Writeln(Mortem,'  Max kills in one turn    : ',FKills.BestTurn);
  Writeln(Mortem,'  Longest killing sequence : ',FKills.BestSequence,' kills in ',FKills.BestSequenceLength,' turns.');
  Writeln(Mortem,'  Max kills without damage : ',FKills.BestNoDamageSequence);
  Writeln(Mortem,'  Survived for             : ',FTurnCount,' turns');
  Writeln(Mortem,'  Died on                  : ',ArenaToString(iLevel.FArena));
  Write  (Mortem,'  Reason of death          : ');
  if FLastEnemy = 'player' then Writeln(Mortem,'suicide')
    else if (FLastEnemy <> '') then Writeln(Mortem,'killed by a ',FContext.Lua.Get(['beings',FLastEnemy,'name']))
    else Writeln(Mortem,'unknown');
  Writeln(Mortem,'');
  Close(Mortem);
end;

procedure TPlayer.Die;
begin
  FKills.Update(FTurnCount);
  FKills.Update(FTurnCount);
  FDied := True;
end;

function TPlayer.UseSkill( aSkillID : DWord; aCommand : Byte; aAlt : Boolean ) : Boolean;
var iPresentation : IBerserkPresentation;
begin
  iPresentation := TLevel( Parent ).Presentation;
  if aSkillID = 0 then
  begin
    iPresentation.Msg('You don''t have a skill or item in this slot!');
    Exit( False );
  end;
  if FSkills[aSkillID] = 0 then
  begin
    iPresentation.Msg('You don''t have the '+FContext.Lua.Get(['skills',aSkillID,'name'])+' skill!');
    Exit( False );
  end;
  if aAlt then
  begin
    if FContext.Lua.Defined(['skills',aSkillID,'OnAltUse']) then
      Exit( FContext.Lua.ProtectedCall(['skills',aSkillID,'OnAltUse'],[Self,FSkills[aSkillID], aCommand ] ) );
    iPresentation.Msg( 'What?' );
    Exit( False );
  end
  else
    Exit( FContext.Lua.ProtectedCall(['skills',aSkillID,'OnUse'],[Self,FSkills[aSkillID], aCommand ] ) );
end;

procedure TPlayer.BeginTurn;
begin
  Inc(FTurnCount);
  FDefBonus  := 0;
  FContext.Lua.ProtectedCall(['klasses',FKlass,'OnTick'],[Self]);
  if FKills.ThisTurn > 5 then TLevel( Parent ).Presentation.Msg(IntToStr(FKills.ThisTurn)+' kills!');
  FKills.Update(FTurnCount);
end;

procedure TPlayer.BeginCommand;
var iLevel : TLevel;
begin
  iLevel := TLevel( Parent );
  if FEN < 10 then Exclude(FFlags,BF_RUNNING);
  iLevel.Presentation.Draw;
  FAttackCount := 0;
  iLevel.RunCellHook( FPosition, TileHook_OnStanding, [Self] );
end;

function TPlayer.Slips : Boolean;
var iLevel : TLevel;
begin
  iLevel := TLevel( Parent );
  Exit( ( TF_ICE in iLevel.getFlags( FPosition ) ) and ( iLevel.GameRNG.Dice( 3, 6 ) > DX ) );
end;

procedure TPlayer.ActionSlip;
var iLevel     : TLevel;
    iDirection : TDirection;
begin
  iLevel := TLevel( Parent );
  iDirection.Create( iLevel.GameRNG.RLongInt( 9 ) + 1 );
  iLevel.Presentation.Msg('You slip!');
  FSpeedCount -= 500;
  ActionMove( iDirection );
end;

procedure TPlayer.ActionMove( const aDirection : TDirection );
var iLevel  : TLevel;
    iCoord  : TCoord2D;
    iResult : Byte;
    iCost   : Word;
begin
  iLevel  := TLevel( Parent );
  iCoord  := FPosition + aDirection;
  iResult := TryMove( iCoord );
  if (iResult = Move_Ok) or (iCoord = FPosition) then
  begin
    iLevel.Presentation.AddMove( UID, FPosition, iCoord );
    Displace( iCoord );
    FDefBonus  := Max(1,FDefBonus);
    if isRunning then
    begin
      Dec(FEN,10-FBonus[BONUS_RUN]);
      iCost := 750-FBonus[BONUS_RUN] * 50;
      FDefBonus  := Max(2,FDefBonus);
    end else iCost := 1000;
    FSpeedCount -= Round((iCost / 200)*(iLevel.getMoveCost( FPosition )+iLevel.getMoveCost( iCoord )));
  end
  else
  if iResult = Move_Being then
  begin
    if (iLevel.Being[ iCoord ].FAI <> AI_MONSTER) and (not isBerserk) then iLevel.Presentation.Msg('Let them live... a little longer.')
    else
    begin
      Attack(iLevel.Being[ iCoord ]);
      FSpeedCount -= 1000;
    end;
  end;
end;

procedure TPlayer.ActionWait;
begin
  FSpeedCount -= 1000;
  FDefBonus := Max(3,FDefBonus);
end;

procedure TPlayer.ActionToggleRun;
begin
  if FEN < 10   then TLevel( Parent ).Presentation.Msg('You''re to exhausted to run!') else
  if isRunning  then Exclude(FFlags,BF_RUNNING)
                else Include(FFlags,BF_RUNNING);
end;

procedure TPlayer.EndTurn;
begin
  if FHP <= FHPMax div 10 then FDefBonus += FBonus[ BONUS_SURVIVE ];
end;


function TPlayer.IsPlayer : Boolean;
begin
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
var sx,sy  : Byte;
    iLevel : TLevel;
begin
  iLevel := TLevel( Parent );
  enemiesAround := 0;
  for sx := FPosition.x-1 to FPosition.x+1 do
    for sy := FPosition.y-1 to FPosition.y+1 do
      if iLevel.Being[ NewCoord2D( sx,sy ) ] <> nil then Inc(enemiesAround);
  Dec( enemiesAround ); // Player
end;

procedure TPlayer.IncSkill(aSkillID: DWord);
var i : Byte;
begin
  if FContext.Lua.Defined( ['skills', aSkillID, 'OnUse'] ) then
    if FSkills[ aSkillID ] = 0 then
      for i := Low( FSkillSlots ) to High( FSkillSlots ) do
        if FSkillSlots[i] = 0 then
        begin
          FSkillSlots[i] := aSkillID;
          Break;
        end;
  Inc( FSkills[ aSkillID ] );
  if FContext.Lua.Defined( ['skills', aSkillID, 'OnPick'] ) then
    FContext.Lua.ProtectedCall( ['skills', aSkillID, 'OnPick'], [ Self, FSkills[ aSkillID ] ] );
end;

function TPlayer.ReqMet(const aID: AnsiString; aReqValue: DWord): Boolean;
var iSkillID : DWord;
begin
  ReqMet := True;
  if aID = 'st' then Exit(ST >= aReqValue);
  if aID = 'dx' then Exit(DX >= aReqValue);
  if aID = 'wp' then Exit(WP >= aReqValue);
  if aID = 'en' then Exit(EN >= aReqValue);
  iSkillID := FContext.Lua.Defines[ aID ];
  Exit( FSkills[ iSkillID ] >=  aReqValue );
end;

function TPlayer.ReqsMet(aSkillID: DWord): Boolean;
var iPair : TLuaValuePair;
begin
  ReqsMet := True;
  with FContext.Lua.GetTable(['skills',aSkillID,'reqs']) do
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
  Exit( FContext.Lua.Get(['skills',aID,'name'])+' level '+IntToStr(aReqValue) );
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

constructor TPlayer.CreateFromStream ( Stream : TStream; aContext : TNodeContext ) ;
begin
  inherited CreateFromStream ( Stream, aContext ) ;
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
end;

function lua_player_get_skill_slot(L: Plua_State): Integer; cdecl;
var State  : TLuaStack;
    Player : TPlayer;
begin
  State.Init(L);
  Player := State.ToObject(1) as TPlayer;
  State.Push( Player.FSkillSlots[State.ToInteger(2)] );
  Result := 1;
end;

function lua_player_get_skill( L : PLua_State ): Integer; cdecl;
var iState  : TLuaStack;
    iPlayer : TPlayer;
begin
  iState.Init(L);
  iPlayer := iState.ToObject(1) as TPlayer;
  if iState.IsNumber(2)
    then iState.Push( iPlayer.FSkills[iState.ToInteger(2)] )
    else iState.Push( iPlayer.FSkills[iPlayer.Context.Lua.Defines[iState.ToString(2)]] );
  Result := 1;
end;

function lua_player_inc_skill( L : PLua_State ): Integer; cdecl;
var iState  : TLuaStack;
    iPlayer : TPlayer;
begin
  iState.Init(L);
  iPlayer := iState.ToObject(1) as TPlayer;
  if iState.IsNumber(2)
    then iPlayer.IncSkill(iState.ToInteger(2))
    else iPlayer.IncSkill(iPlayer.Context.Lua.Defines[iState.ToString(2)]);
  Result := 1;
end;

function lua_player_get_ammo(L: Plua_State): Integer; cdecl;
var State  : TLuaStack;
    Player : TPlayer;
begin
  State.Init(L);
  Player := State.ToObject(1) as TPlayer;
  State.Push( Player.FAmmo[State.ToInteger(2)] );
  Result := 1;
end;

function lua_player_set_ammo(L: Plua_State): Integer; cdecl;
var State  : TLuaStack;
    Player : TPlayer;
begin
  State.Init(L);
  Player := State.ToObject(1) as TPlayer;
  Player.FAmmo[State.ToInteger(2)] := State.ToInteger(3);
  Result := 0;
end;

function lua_player_choose_target(L: Plua_State): Integer; cdecl;
var State  : TLuaStack;
    Player : TPlayer;
begin
  State.Init(L);
  Player := State.ToObject(1) as TPlayer;
  State.Push( TLevel( Player.Parent ).Presentation.ChooseTarget( State.ToInteger( 2 ), State.ToInteger( 3 ) ) );
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
class procedure TPlayer.RegisterLuaAPI( aLua : TLua );
begin
  aLua.Register( 'player', lua_player_lib );
end;


end.
