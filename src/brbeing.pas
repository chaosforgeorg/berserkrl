// @abstract(BerserkRL -- TBeing class unit)
// @author(Kornel Kisielewicz <admin@chaosforge.org>)
// @created(Oct 16, 2006)
// @lastmod(Oct 22, 2006)
//
// This unit just holds the TBeing class -- a class representing the creatures
// you fight in Berserk. It is also a base class for the TPlayer class, that
// can be found in brplayer.pas.
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
unit brbeing;
interface
uses SysUtils, Classes, vutil, vnode, vmath, vluastate, vluaentitynode, vrltools, brdata, brui;


const Hook_OnCreate = 1;
      Hook_OnAction = 2;
      Hook_OnDie    = 3;
      Hooks_All     = [ Hook_OnCreate..Hook_OnDie ];
const HookNames : array[ 0..3 ] of AnsiString = ( '', 'OnCreate', 'OnAction', 'OnDie' );

type

// The TBeing class represents all beings in the Berserk game. By itself it is
// a class representing monsters, but it also is the Parent class for TPlayer,
// the Player class.

{ TBeing }

TBeing = class(TLuaEntityNode)
  // Speed is the amount that SpeedCount is increased each Tick.
  FSpeed     : Word;
  
  // AI Type of the being
  FAI        : Word;
  
  FStats     : array[0..3] of Word;

  // HP is Hit Points. It's the amount of damage a being can take before it dies.
  FHP        : Integer;
  // HPMax represents the initial and maximum value of HP.
  FHPMax     : Word;
  // EN is Energy -- it represents how much stanima you have for heavy tasks like
  // special attacks.
  FEN        : Integer;
  // ENMax represents the initial and maximum value of EN. The being regenerates
  // EN up to this value.
  FENMax     : Word;

  // Used to calculate Knockback values.
  FWeight    : Word;
  
  // Reduces the damage by given amount.
  FArmor     : Word;

  // Visual representation data (sprite, ascii, color, overlay, etc)
  FVisual    : TVisual;

// Temporary statistics
  // Used by explosions and the like to see if they have been already affected.
  FAffected   : Boolean;

  // Counts the number of Attacks against a being.
  FAttackCount: Word;

  // WillCount determinates the speed of Willpower based regenerations (Pain
  // and Energy). Each turn a amount based on Willpower is added, and when
  // the count reaches WILLLIMIT then regeneration takes place.
  FWillCount  : Word;

  // Pain represents the way that damage dealt to the being affects it chances
  // to do actions. It is deducted from most "skill" rolls like attack or defense.
  FPain       : Word;

  // Ice based attacks cause freezing. Freezing reduces overall speed.
  FFreeze     : Word;

  // Target coord - used by targeting code
  FTargetCoord : TCoord2D;

  // SpeedCount is a part of Berserks speed system. Each Tick, the SpeedCount is
  // increased by the value of Speed. If it reaches SPEEDLIMIT then the being
  // is allowed to take an action.
  FSpeedCount : Word;

  // Bonuses
  FBonus     : array[0..BONUS_MAX] of Integer;

  // Creates a new being. aid is the nid value of the being. It MUST be equal to
  // the TLevel.Beings index where the being was initialized. mid is the id value
  // of the creature, and index to the BeingData array. posX and posY are the
  // coordinates of the being on the map. This coordinate MUST be free of beings.
  constructor Create( const mid : AnsiString; pos : TCoord2D; lvl : Byte = 0 );

  // Initializes the temporary statistics
  procedure Init;
  
  // Chooses a suitable target based on the given AI set. Target is stored in tid,tx,ty.
  function ClosestTarget(AISet : TAITypeSet; Radius : Byte) : TBeing;
  
  // Sets the beings stats based on the id. In a bigger game this should be read
  // from a file, but for the scope of Berserk! it's just fine.
  procedure ApplyTemplate( const bid : AnsiString; lvl : byte );
  
  // The death method. Handles being death accordingly then runs Free/Destroy,
  // and destroys the being.
  procedure Die; virtual;
  
  // Action method -- called by Tick if enough SpeedCount is accumulated.
  procedure Action; virtual;
  
  // Tick method -- called by TLevel.Tick. Processes SpeedCount accumulation and
  // regeneration rates is applicable.
  procedure Tick;
  
  // Melee Attack against the Target being
  procedure Attack(aTarget : TBeing; aFlags : TFlags = []);
  
  // Attacks given square. Flags as in TBeing.Attack
  procedure Attack(aCoord : TCoord2D; aFlags : TFlags = []);
  
  // Applies damage to the being. DR and other resistances are applied here.
  procedure ApplyDamage(Amount : Word; DType : Byte); virtual;
  
  // Scans the mx,my coordinates for a potential move. Returns the ScanCode (see
  // brdata.pas for values). Also returns 0 if move possible, or being.nid if
  // a being is on the target coord.
  function tryMove( NewCoord : TCoord2D ) : Byte;
  
  // Moves the Being to the given coords. No error checking, so run TryMove
  // first.
  procedure Displace( const NewCoord : TCoord2D ); override;
  
  // Returns true if the being is the player, false otherwise.
  function isPlayer : Boolean; virtual;
  
  // Returns wether lx,ly is in LOS. For the player it uses visibility map, for
  // the monsters it runs isEyeContact.
  function isInLOS( Coord : TCoord2D ) : Boolean;
  
  // Returns Dodge value
  function getDodge : Byte;
  
  // Returns beings name
  function getName : string;
  
  // Returns Parry value
  function getParry : Byte;
  
  // Returns damage dice based on Strength
  function getDamageDice : Byte; virtual;
  
  // Returns damage mod based on Strength
  function getDamageMod : ShortInt;
  
  // Knockes back the being in the given direction with the given strength.
  // Checks wether possible, so safe to call.
  procedure Knockback( Direction : TDirection;  Damage : Integer );
  
  // Sends a missile of type mtype towards the target.
  procedure SendMissile( Target : TCoord2D; mtype : Byte; aSequence : Word );
  
  // Returns the string shown in look mode and targeting.
  function LookDescribe : string;

  // Play a sound
  procedure PlaySound( const aSoundID : AnsiString );
  
  // Frees all allocated data. Also removes the being refrence from TLevel.Map
  // and TLevel.Beings structires.
  destructor Destroy; override;

  // Function for getting custom properties in Lua.
  // Should push given property to the passed state
  function GetProperty( L : PLua_State; const aPropertyName : AnsiString ) : Integer; override;

  // Stream constructor, reads UID, and ID from stream, should be overriden.
  constructor CreateFromStream( Stream : TStream ); override;
  // Write Node to stream (UID and ID) should be overriden.
  procedure WriteToStream( Stream : TStream ); override;

  // Register API
  class procedure RegisterLuaAPI();

  protected
  procedure UpdateFacing(NewX : Word);

  published

  property visible     : Boolean read isVisible;

  // Strength represents the Beings physical strenght. Mainly it affects damamge.
  property st : Word read FStats[STAT_STR] write FStats[STAT_STR];
  // Dexterity affects the beings chances to hit in combat, and to defend.
  property dx : Word read FStats[STAT_DEX] write FStats[STAT_DEX];
  // Endurance represents the Beings strudiness. If affects how the being
  // recovers from damage.
  property en : Word read FStats[STAT_END] write FStats[STAT_END];
  // Willpower affects mainly the player -- it affects the chances of berserking,
  // and the psychical defence.
  property wp : Word read FStats[STAT_WIL] write FStats[STAT_WIL];

  // Entity name
  property name : AnsiString read FName write FName;

  property target_x    : Integer read FTargetCoord.X;
  property target_y    : Integer read FTargetCoord.Y;

  property speed_count : Word read FSpeedCount write FSpeedCount;
  property speed       : Word read FSpeed      write FSpeed;
  property pain        : Word read FPain       write FPain;
  property freeze      : Word read FFreeze     write FFreeze;
  property weight      : Word read FWeight     write FWeight;
  property armor       : Word read FArmor      write FArmor;

  property sprite      : Word read FVisual.Sprite     write FVisual.Sprite;

  property overlay_r   : Real read FVisual.Overlay[1] write FVisual.Overlay[1];
  property overlay_g   : Real read FVisual.Overlay[2] write FVisual.Overlay[2];
  property overlay_b   : Real read FVisual.Overlay[3] write FVisual.Overlay[3];

  property hp          : Integer read FHP write FHP;
  property energy      : Integer read FEN write FEN;

  property hp_max      : Word read FHPMax write FHPMax;
  property energy_max  : Word read FENMax write FENMax;

  property ai          : Word read FAI    write FAI;

  property hp_bonus       : Integer read FBonus[ BONUS_HP ]      write FBonus[ BONUS_HP ];
  property run_bonus      : Integer read FBonus[ BONUS_RUN ]     write FBonus[ BONUS_RUN ];
  property survive_bonus  : Integer read FBonus[ BONUS_SURVIVE ] write FBonus[ BONUS_SURVIVE ];

end;

implementation
uses variants, vluasystem, vsound, vluaext, vvision, vlualibrary, brlevel,brmain, brplayer;


{ TBeing }

constructor TBeing.Create( const mid : AnsiString; pos : TCoord2D; lvl : Byte = 0 );
begin
  inherited Create(mid);
  FEntityID := ENTITY_BEING;
  Init;
  FPosition := Pos;

  FVisual.Mirror := True;

  FName := '';

  ApplyTemplate(mid,lvl);
  Displace( FPosition );
  PlaySound('appear');
end;

procedure TBeing.Init;
var i : DWord;
begin
  FAffected    := False;
  FSpeedCount   := 4000 + Random(500);
  FWillCount    := 0;
  FAttackCount  := 0;
  FTargetCoord  := ZeroCoord2D;
  FPain        := 0;
  FFreeze      := 0;
  for i := Low( FBonus ) to High( FBonus ) do
    FBonus[i] := 0;
  FVisual.AnimCount := 0;
end;

procedure TBeing.ApplyTemplate( const bid : AnsiString; lvl : byte );
var Hook : Byte;
begin
  with LuaSystem.GetTable( ['beings', bid] ) do
  try
    FGylph.ASCII   := GetChar('picture');
    FGylph.Color   := GetInteger('color');
    FVisual.Sprite := GetInteger('sprite');

    FName      := GetString('name');
    ST         := GetInteger('st');
    DX         := GetInteger('dx');
    WP         := GetInteger('wp');
    EN         := GetInteger('en');

    FAI        := GetInteger('ai');

    FHPMax     := GetInteger('hp');
    FHP        := FHPMax;
    FENMax     := GetInteger('energy');
    FEN        := FENMax;
    FSpeed     := GetInteger('speed');
    FArmor     := GetInteger('armor');
    FWeight    := GetInteger('weight');
  finally
    Free
  end;
  FVisual.Overlay := NOCOLOROVERLAY;
  RunHook( Hook_OnCreate, [lvl] );
end;

function TBeing.ClosestTarget(AISet: TAITypeSet; Radius : Byte) : TBeing;
var iRange, i : Word;
    iTarget   : TCoord2D;
begin
  iRange := 1000;
  Result := nil;
  for iTarget in NewArea( FPosition, Radius+1 ).Clamped( Level.Area ) do
    if Level.Being[ iTarget ] <> nil then
       if Level.Being[ iTarget ].FAI in AISet then
         if isInLOS( iTarget ) then
         begin
           i := Distance( iTarget, FPosition );
           if i <= iRange then
           begin
             FTargetCoord := iTarget;
             iRange := i;
             Result := Level.Being[ iTarget ];
           end;
        end;
  if iRange = 1000 then
  begin
    FTargetCoord := FPosition;
    Result := nil;
  end;
end;


procedure TBeing.Die;
begin
  if Player.FTarget = Self then Player.FTarget := nil;
  
  if FHP <= 0 then
  begin
    Player.FKills.Add(FID);
    if isVisible then UI.Msg('The '+getName+' dies!');
    PlaySound('die');
  end else FHP := 0;

  RunHook( Hook_OnDie, [] );
  
  if (BF_DEFILED in FFlags) and (FEN = FENMAX) then
    Level.Explosion(FPosition,Green,2,3,50,DAMAGE_SPORE,0);

  if (not (TF_NOCORPSE in Level.getFlags( FPosition ))) and (not (BF_NOCORPSE in FFlags)) then
  begin
    Level.Bleed( FPosition, 2 );
    Level.Cell[ FPosition ] := LuaSystem.Defines['bloody_corpse'];
  end;
  Free;
end;

procedure TBeing.Action;
var mx, my     : Integer;
    MoveResult : Byte;
    TargetDist : Word;
    TargetVis  : Boolean;
    Count      : Word;
    MoveCoord  : TCoord2D;
    WCoord     : TCoord2D;
    Direction  : TDirection;
    Being      : TBeing;
begin
  FAttackCount := 0;

  case FAI of
    AI_CIVILIAN :
      begin
        Being := ClosestTarget( [AI_MONSTER], 4 );
        if Being = nil then
          FTargetCoord := Level.Area.Center
        else
          FTargetCoord := FPosition + NewDirection( FTargetCoord, FPosition );
      end;
    AI_ALLY :
      begin
        Being := ClosestTarget([AI_MONSTER],6);
        if Being = nil then
        begin
          FTargetCoord := Player.Position;
          if Distance( FTargetCoord, FPosition ) < 3 then FTargetCoord := FPosition;
        end;
      end;
    AI_MONSTER :
      begin
        Being := ClosestTarget([AI_Civilian,AI_Ally,AI_Player],2);
        if Being = nil then
        begin
          Being := Player;
          FTargetCoord := Player.Position;
        end;
      end;
  end;

  TargetDist  := Distance( FPosition, FTargetCoord );
  TargetVis   := Level.isEyeContact( FPosition, FTargetCoord );

  if Hook_OnAction in FHooks then
    if RunHook( Hook_OnAction, [TargetVis,TargetDist] ) then Exit;


  if BF_DEFILED in FFlags then
  begin
    case FEN of
      1..4  : FGylph.Color := Green;
      5..10 : FGylph.Color := LightGreen;
    end;
    if GraphicsMode then
    begin
      FVisual.Overlay[1] := 1.0 * (12-FEN) / 12;
      FVisual.Overlay[3] := 1.0 * (12-FEN) / 12;
    end;
  end;

   // Impale attack
  if (BF_IMPALE in FFlags) and (FEN > 20) and (TargetDist = 2) then
    if ((FTargetCoord.x-FPosition.x) mod 2 = 0) and ((FTargetCoord.y-FPosition.y) mod 2 = 0) then
    begin
      MoveCoord := FPosition + NewDirection( FPosition, FTargetCoord );
      if tryMove( MoveCoord ) = Move_Ok then
      begin
        FEN -= 20;
        if isVisible then UI.Msg('The '+getName+' charges!');
        UI.AddMove( UID, FPosition, MoveCoord );
        Displace( MoveCoord );
        Attack(Level.Being[FTargetCoord],[AF_IMPALE]);
        FSpeedCount -= 1500;
        Exit;
      end;
    end;

  // BF_REGEN regeneration.
  if (BF_REGEN in FFlags) and (FHP < FHPMax) and (FEN > 2) then
  begin
    FEN -= 2;
    Inc(FHP);
  end;
  
  
  mx := Sgn(FTargetCoord.x-FPosition.x);
  my := Sgn(FTargetCoord.y-FPosition.y);
  MoveCoord.Create( FPosition.X + mx, FPosition.Y + my );
  WCoord := ZeroCoord2D;
  MoveResult := TryMove( MoveCoord );
  
  if MoveResult = Move_Block then WCoord := MoveCoord;
  if (MoveResult <> Move_Ok) and (not ( (MoveResult = Move_Being) and ( Level.Being[MoveCoord] = Being) ) ) then
  begin
    if mx = 0 then
    begin
      MoveCoord.x := FPosition.x+(Random(2)*2-1);
      MoveCoord.y := FPosition.y+my;
      MoveResult := TryMove( MoveCoord );
    end
    else
    begin
      MoveCoord.x := FPosition.x+mx;
      MoveCoord.y := FPosition.y;
      MoveResult := TryMove( MoveCoord );
    end;
  end;
  if (MoveResult = Move_Block) and (WCoord.X = 0) then WCoord := MoveCoord;
  if (MoveResult <> Move_Ok) and (not ( (MoveResult = Move_Being) and ( Level.Being[MoveCoord] = Being) ) ) then
  begin
    if my = 0 then
    begin
      MoveCoord.x := FPosition.x+mx;
      MoveCoord.y := FPosition.y+(Random(2)*2-1);
      MoveResult := TryMove( MoveCoord );
    end
    else
    begin
      MoveCoord.x := FPosition.x;
      MoveCoord.y := FPosition.y+my;
      MoveResult := TryMove( MoveCoord );
    end;
  end;
  if (MoveResult = Move_Block) and (WCoord.X = 0) then WCoord := MoveCoord;
  if MoveResult = Move_Ok then
  begin
    UI.AddMove( UID, FPosition, MoveCoord );
    Displace( MoveCoord )
  end
  else
    if FAI <> AI_Civilian then
    begin
      if (MoveResult = Move_Being) and ( Level.Being[MoveCoord] = Being) then Attack(Being)
      else if (WCoord.X <> 0) and (FAI = AI_MONSTER) then Attack(WCoord);
    end;
  FSpeedCount -= 1000; //TEMPORARY
end;

procedure TBeing.Tick;
begin
  if FFreeze > FSpeed-10 then FFreeze := FSpeed - 10;
  if Random(1000) = 0 then PlaySound('passive');
  FSpeedCount += FSpeed - FFreeze;
  while FSpeedCount > SPEEDLIMIT do Action;
  if (FPain > 0) or (FFreeze > 0) or (FEN < FENMAX) then
  begin
    FWillCount += WP*WP;
    while FWillCount > WILLLIMIT do
    begin
      Dec(FWillCount,WILLLIMIT);
      if FPain > 0   then Dec(FPain);
      if FFreeze > 0 then Dec(FFreeze);
      if FEN < FENMax then Inc(FEN);
    end;
  end
  else FWillCount := 0;
end;

procedure TBeing.Attack(aTarget : TBeing; AFlags : TFlags = []);
var ToHit   : Integer;
    ToWound : Integer;
    Defense : Integer;
    Damage  : Integer;
begin
  if aTarget = nil then Exit;
  UpdateFacing(aTarget.FPosition.X);
  if aTarget.isPlayer then Player.FLastEnemy := FID;
  ToHit := RollDice;

  if (TF_WATER in Level.getFlags(FPosition)) and (not (BF_WATER in FFlags)) then Inc(ToHit,3);
  
  if BF_BERSERK in FFlags then Dec(ToHit,3);

  if AF_SWEEP   in AFlags then Inc(ToHit,3);
  if AF_IMPALE  in AFlags then Dec(ToHit,1);

  if ToHit > DX+3-FPain then
  begin
    if IsPlayer then UI.Msg('You miss the '+aTarget.getName+'.')
                else if aTarget.isPlayer then UI.Msg('The '+getName+' misses you.');
    UI.AddAttack( UID, False, FPosition, aTarget.Position );
    Exit;
  end;
  
  Defense := 0;
  Defense := aTarget.getParry;

  if Defense = 0 then Defense := aTarget.getDodge;
  
  if aTarget.isPlayer then Defense += Player.FDefBonus;

  ToWound := RollDice;

  if ToWound <= Defense-(aTarget.FPain div 2 + aTarget.FFreeze div 5)-aTarget.FAttackCount then
  begin
    if IsPlayer then UI.Msg('The '+aTarget.getName+' evades your blow.')
                else if aTarget.isPlayer then UI.Msg('You evade.');
    UI.AddAttack( UID, False, FPosition, aTarget.Position );
    Exit;
  end;
  
//  msg.add('Dice('+IntToStr(getDamageDice)+',6)'+'+'+IntToStr(getDamageMod+2));

  Damage := Dice(getDamageDice,6)+getDamageMod+2; // The +1 represents the weapon
  if isPlayer then Damage += 3;                   // The +3 represents the Dragonslayer
  
  if AF_SWEEP  in AFlags then Damage -= 2;
  if AF_IMPALE in AFlags then Damage := Round(Damage * 1.5);

  if ToHit < 0 then Damage *= 2; // Critical Hit

  if ToHit < 0 then
    if aTarget.IsPlayer then UI.Msg('The '+getName+' critically hits you! '+GodStr('D:'+IntToStr(Damage)))
                        else if isPlayer then UI.Msg('You critically hit the '+aTarget.getName+'! '+GodStr('D:'+IntToStr(Damage)))
                                         else UI.Msg(getName+' critically hits the '+aTarget.getName+'. '+GodStr('D:'+IntToStr(Damage)))
  else
  if aTarget.IsPlayer then UI.Msg('The '+getName+' hits you! '+GodStr('D:'+IntToStr(Damage)))
                      else if isPlayer then UI.Msg('You hit the '+aTarget.getName+'! '+GodStr('D:'+IntToStr(Damage)))
                                       else if isVisible then UI.Msg('The '+getName+' hits the '+aTarget.getName+'. '+GodStr('D:'+IntToStr(Damage)));

  UI.AddAttack( UID, True, FPosition, aTarget.Position );

  if not (AF_NOKNOCKBACK in AFlags) then
    if AF_DKNOCKBACK in AFlags
      then aTarget.Knockback( NewDirection( FPosition, aTarget.FPosition ),2*Damage)
      else aTarget.Knockback( NewDirection( FPosition, aTarget.FPosition ),Damage);
  aTarget.ApplyDamage(Damage,DAMAGE_SLASH);
end;

procedure TBeing.Attack( aCoord : TCoord2D; AFlags : TFlags = [] );
begin
  UpdateFacing( aCoord.x );
  if not Level.isProperCoord( aCoord ) then Exit;
  Level.DamageTile( aCoord, Dice(getDamageDice,6)+getDamageMod);
  if Level.Being[ aCoord ] = nil then Exit;
  Attack(Level.Being[ aCoord ], AFlags );
end;

procedure TBeing.Knockback( Direction : TDirection; Damage : Integer);
var Str   : Word;
    Coord : TCoord2D;
begin
  if Damage < 3 then Exit;
  Str := Max(Round(Int((Damage / KNOCKBACKVALUE) / (FWeight / 10))),0);
  
  Coord := FPosition;

  while Str > 0 do
  begin
    if TryMove( Coord + Direction ) <> Move_Ok then Break;
    Coord += Direction;
    Dec(Str);
  end;
  UI.AddMove( UID, FPosition, Coord );
  Displace( Coord );
  UpdateFacing( (Coord + Direction.Reversed).X );
end;

// NOTE: Stray hits (hits that hit not the intended target) happen on a flat
// rate of 40% if the missile flies through that square.
//
// Hitting the target from range 4 always succeeds.
procedure TBeing.SendMissile( Target : TCoord2D; MType : Byte; aSequence : Word);
const HITDELAY  = 50;
var Dist : byte;
    Roll : integer;
    Ray  : TVisionRay;
    Scan      : Byte;
    DrawDelay : Word;
    Tgt  : TBeing;
begin
  UpdateFacing(FTargetCoord.X);
  Player.FLastEnemy := FID;
  Dist := Distance(FPosition,Target);
  DrawDelay := 10;
  case mtype of
    MTBOLT  : DrawDelay := 10;
    MTKNIFE : DrawDelay := 20;
    MTBOMB  : DrawDelay := 50;
    MTENERGY: DrawDelay := 20;
    MTICE   : DrawDelay := 30;
    MTSPORE : DrawDelay := 80;
  end;


  if Dist > 4 then
  begin
    Roll := RollDice;
    if Roll > DX-((Dist-5) div 3) then
      if Dist < 9 then
        Target.RandomShift(1)
      else
        Target.RandomShift(2);
  end;

  Ray.Init(Level,FPosition,Target);
  repeat
    Ray.Next;
    if not Level.isProperCoord(Ray.GetC) then Exit;

    Scan := TryMove(Ray.GetC);
    if Scan in [Move_Block, Move_Invalid] then // Missile hits non-passable feature
    begin
      UI.SendMissile(FPosition,Ray.GetC,mtype,aSequence);
      Break;
    end;
    if Scan = Move_Being then // Missile hits Being
    begin
      Tgt := Level.Being[Ray.GetC];
      if (not (BF_RUNNING in Tgt.FFlags)) or (Random(10) < 5) then
      if (Ray.GetC = FTargetCoord) or (Dice(1,10) > 6) then
      begin
        UI.SendMissile(FPosition,Ray.GetC,mtype,aSequence);
        if isPlayer then begin if isVisible then UI.Msg('You hit the '+Tgt.getName+'!') end
                    else if (Ray.GetC = Player.Position) then UI.Msg('You''re hit!');
        case mtype of
          MTBOLT   : Tgt.ApplyDamage(Dice(2,4),DAMAGE_PIERCE);
          MTKNIFE  : Tgt.ApplyDamage(Dice(getDamageDice,6)+getDamageMod+1,DAMAGE_PIERCE);
          MTENERGY : Tgt.ApplyDamage(Dice(1,6),DAMAGE_ENERGY);
          MTICE    : Tgt.ApplyDamage(Dice(2,5)+2,DAMAGE_FREEZE);
          MTSPORE  : if Tgt.isPlayer then
                       Tgt.ApplyDamage(Dice(3,6),DAMAGE_SPORE)
                     else
                       if not (BF_SPORERES in Tgt.FFlags) then
                       begin
                         Tgt.FENMAX := 5;
                         Tgt.FEN    := 0;
                         Include(Tgt.FFlags,BF_DEFILED);
                       end;
        end;
        Break;
      end;
    end;

    if (mtype in [MTBOMB,MTSPORE]) then
      if Ray.Done then
      begin
        UI.SendMissile(FPosition,Ray.GetC,mtype,aSequence);
        Break;
      end;
  until False;
  if mtype = MTBOMB then Level.Explosion(Ray.GetC,Red,4,6,50,DAMAGE_FIRE,aSequence + 25 * (Ray.GetC - FPosition).LargerLength );
  if (mtype = MTSPORE) and (Level.Being[Ray.GetC] = nil) then
    Level.Summon('spore',Ray.GetC);
end;


function TBeing.LookDescribe : string;
var Wounds : string;
begin
  case Round(FHP*100/FHPMax) of
    -20..10  : Wounds := '@ralmost dead';
    11..30   : Wounds := '@rmortally wounded';
    31..50   : Wounds := '@Rseverely wounded';
    51..70   : Wounds := '@ywounded';
    71..90   : Wounds := '@ybruised';
    91..99   : Wounds := '@lscratched';
    100      : Wounds := '@Lunhurt';
    101..1000: Wounds := '@Bboosted';
  end;
  Exit(getName + ' (' +Wounds+'@>)');
end;

procedure TBeing.PlaySound(const aSoundID: AnsiString);
var iSound : AnsiString;
begin
  iSound := UI.ResolveSoundID( FID, aSoundID );
  if iSound <> '' then Sound.PlaySample( iSound, FPosition );
end;

procedure TBeing.ApplyDamage(Amount : Word; DType : Byte);
begin
  if FHP <= 0 then Exit;
  Amount := Max(1,Amount-FArmor);
  if (BF_FLAMABLE in FFlags) and (DType = DAMAGE_FIRE) then Amount *= 2;
  if BF_SKELETAL in FFlags then
  begin
    if DType = DAMAGE_PIERCE then Amount := Amount div 3;
    if DType = DAMAGE_SPORE  then Exit;
  end;
  if DType = DAMAGE_FREEZE then
  begin
    FFreeze += Amount;
    Amount := Amount div 2;
    if GraphicsMode then
    begin
      if FFreeze = 0 then FVisual.Overlay := NOCOLOROVERLAY else
      begin
        FVisual.Overlay[1] := 0.01*(100-FFreeze);
        FVisual.Overlay[2] := 0.01*(100-FFreeze);
      end;
    end;
  end;
  FHP -= Amount;
  if DType = DAMAGE_FIRE   then FFreeze := Max(0,FFreeze-2*Amount);
  FPain += Amount div 2;
  if not (BF_SKELETAL in FFlags) then
    Level.Bleed(FPosition);
  if FHP <= 0 then Die else PlaySound('pain');
end;

function TBeing.TryMove( NewCoord : TCoord2D ) : Byte;
begin
  TryMove := Move_Ok;
  if not Level.isProperCoord( NewCoord ) then Exit( Move_Invalid );
  if Level.being[ NewCoord ] <> nil then Exit( Move_Being );
  if not Level.Area.Shrinked.Contains( NewCoord ) then Exit( Move_Block );
  if TF_NOMOVE in Level.getFlags( NewCoord ) then TryMove := Move_Block;
end;

procedure TBeing.Displace( const NewCoord : TCoord2D );
begin
  if Level.Being[ NewCoord ] <> nil then Exit;
  UpdateFacing( NewCoord.X );
  inherited Displace( NewCoord );
end;

function TBeing.isPlayer : Boolean;
begin
  Exit(False);
end;

function TBeing.isInLOS( Coord : TCoord2D ): Boolean;
begin
  if isPlayer then Exit(Level.Vision.isVisible(Coord)) else Exit(Level.isEyeContact(FPosition,Coord));
end;

function TBeing.getDodge : Byte;
begin
  if isPlayer then Exit((DX+EN) div 4+4)
              else Exit((DX+EN) div 4+2);
end;

function TBeing.getName: string;
begin
  Exit(FName);
end;

function TBeing.getParry : Byte;
begin
  if isPlayer then Exit(((DX+3) div 2)+4)
              else Exit(0);
end;

function TBeing.getDamageDice : Byte;
begin
  case ST of
     0..12 : Exit(1);
    13..16 : Exit(2);
  else Exit(((ST-13) div 4) + 2);
  end;
end;

function TBeing.getDamageMod : ShortInt;
begin
  case ST of
    0..8 : Exit(-2);
    9 : Exit(-1);
    10: Exit(0);
    11: Exit(1);
    else Exit(((ST-9) mod 4) - 1);
  end;
end;

destructor TBeing.Destroy;
begin
  inherited Destroy;
end;

function TBeing.GetProperty( L : PLua_State; const aPropertyName: AnsiString
  ): Integer;
var iState : TLuaState;
begin
  iState.Init(L);
  if aPropertyName = 'target'    then begin iState.Push( Level.Being[FTargetCoord] ); Exit( 1 ); end;
  if aPropertyName = 'tposition' then begin iState.PushCoord( FTargetCoord ); Exit( 1 ); end;
  Result:=inherited GetProperty(L, aPropertyName);
end;

constructor TBeing.CreateFromStream ( Stream : TStream ) ;
begin
  inherited CreateFromStream ( Stream ) ;

  Init;

  FSpeed := Stream.ReadWord;
  Stream.Read( FStats,    SizeOf( FStats ) );
  Stream.Read( FVisual,   SizeOf( FVisual ) );
  Stream.Read( FBonus,    SizeOf( FBonus ) );

  FAI    := Stream.ReadWord;
  FHP    := Stream.ReadWord;
  FHPMax := Stream.ReadWord;
  FEN    := Stream.ReadWord;
  FENMax := Stream.ReadWord;
  FWeight:= Stream.ReadWord;
  FArmor := Stream.ReadWord;
end;

procedure TBeing.WriteToStream ( Stream : TStream ) ;
begin
  inherited WriteToStream ( Stream ) ;

  Stream.WriteWord( FSpeed );
  Stream.Write( FStats,    SizeOf( FStats ) );
  Stream.Write( FVisual,   SizeOf( FVisual ) );
  Stream.Write( FBonus,    SizeOf( FBonus ) );

  Stream.WriteWord( FAI );
  Stream.WriteWord( FHP );
  Stream.WriteWord( FHPMax );
  Stream.WriteWord( FEN );
  Stream.WriteWord( FENMax );
  Stream.WriteWord( FWeight );
  Stream.WriteWord( FArmor );
end;

procedure TBeing.UpdateFacing(NewX: Word);
begin
  if NewX > FPosition.X then FVisual.Mirror := False;
  if NewX < FPosition.X then FVisual.Mirror := True;
end;

function lua_being_die(L: Plua_State): Integer; cdecl;
var State : TLuaState;
    Being : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  Being.Die;
  Result := 0;
end;

function lua_being_send_missile(L: Plua_State): Integer; cdecl;
var State : TLuaState;
    Being : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  Being.SendMissile(State.ToCoord(2),State.ToInteger(3),State.ToInteger(4,0));
  Result := 0;
end;

function lua_being_attack(L: Plua_State): Integer; cdecl;
var State : TLuaState;
    Being : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  Being.Attack(State.ToCoord(2),State.ToFlags(3));
  Result := 0;
end;

function lua_being_try_move(L: Plua_State): Integer; cdecl;
var State : TLuaState;
    Being : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  State.Push( Being.TryMove( State.ToCoord(2) ) );
  Result := 1;
end;

function lua_being_apply_damage(L: Plua_State): Integer; cdecl;
var State : TLuaState;
    Being : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  Being.ApplyDamage(State.ToInteger(2),State.ToInteger(3,0));
  Result := 0;
end;

function lua_being_breath(L: Plua_State): Integer; cdecl;
var State : TLuaState;
    Being : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  Level.Breath( Being.Position,
    NewDirection( State.ToCoord( 2 ) ),
    State.ToInteger( 3 ),
    State.ToInteger( 4 ),
    State.ToInteger( 5 ),
    State.ToInteger( 6, 50 ));
  Result := 0;
end;

function lua_being_knockback(L: Plua_State): Integer; cdecl;
var State : TLuaState;
    Being : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  if State.ToBoolean( 4, False )
    then Being.Knockback( NewDirection( State.ToCoord(2) ), State.ToInteger(3) )
    else Being.Knockback( NewDirection( State.ToCoord(2) ).Reversed, State.ToInteger(3) );
  Result := 0;
end;

const lua_being_lib : array[0..7] of luaL_Reg = (
  ( name : 'die';          func: @lua_being_die),
  ( name : 'attack';       func: @lua_being_attack),
  ( name : 'try_move';     func: @lua_being_try_move),
  ( name : 'send_missile'; func: @lua_being_send_missile),
  ( name : 'apply_damage'; func: @lua_being_apply_damage),
  ( name : 'breath';       func: @lua_being_breath),
  ( name : 'knockback';    func: @lua_being_knockback),
  ( name : nil;            func: nil; )
);

// Register API
class procedure TBeing.RegisterLuaAPI();
begin
  LuaSystem.Register( 'being', lua_being_lib );
end;

end.

