// @abstract(BerserkRL -- TLevel class unit)
// @author(Kornel Kisielewicz <admin@chaosforge.org>)
// @created(Oct 16, 2006)
// @lastmod(Oct 22, 2006)

// This unit holds the TLevel class -- the singleton class to represent
// the Berserk levels. It also holds additional data structures used by TLevel.

//  @html <div class="license">
//  This file is part of BerserkRL.

//  BerserkRL is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.

//  BerserkRL is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with BerserkRL; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//  @html </div>
{$INCLUDE brinclude.inc}
unit brlevel;

interface

uses SysUtils,
     vluamapnode, vnode, vmath, vutil, vvision, vrltools, vmaparea, vdungen,
     brdata, brbeing;

type
  // Data record on a single Map Cell on the map.
  TMapCell = record
    // Information on the original terrain. Used only in graphics mode for overlays.
    TerrainB : Word;
    Rotation : Byte;
  end;
  // The map array, used by TLevel
  TMap = array[1..MAP_MAXX, 1..MAP_MAXY] of TMapCell;

  // Specialization of the enumerator for TLevel
  TLevelEnumerator = specialize TGNodeEnumerator<TBeing>;

  // Level class. Berserk doesn't take advantage of Valkyries Node and Event
  // system, because of simplicity issues. That's why TLevel inherits only
  // TVObject. Also, that means that TLevel is a singleton, accessible from
  // the whole program. Creating and Destroying TLevel is a responsibility
  // of TBerserk.

  { TLevel }

  TLevel = class( TLuaMapNode )
    // Our level map object. Instead of holding pointers to TBeing's it holds
    // indexes to the Beings array. Cleaned by the method TLevel.Clear.
    FMap :     TMap;
    // Describes the level of spawning -- the higher, the more often and worse
    // monsters appear.
    FSpawnLevel : Word;
    // The game mode of the level.
    FMode :    Byte;
    // The type of the level.
    FArena :   Byte;
    // Count of ticks passed. Based on each speed incrementation.
    FTickCount : DWord;
    // Currently only used in the graphical version. Stores a random value for
    // each level.
    FSeed :    Word;

    // Used to decide on the base sprite for overlays
    FSpriteBase : Word;

    // Creates the TLevel object. A TLevel should be created once -- to enter
    // another Level use Clear and fill the map anew. Remember to remove the
    // Player from the Beings list tough!
    constructor Create;
    // Generates the level using vdungen.
    procedure Generate( nArena : byte; nMode : Byte; nSpawnLevel : Word );
    // Clears the map and being array and Destroys all Beings. To preserve the
    // Player, you need to remove him from the Beings array.
    procedure Clear;
    // A single level Tick. Calls Tick on each being in the Beings array. Also
    // handles Respawn, and all Level time scheduled operations.
    procedure Tick;
    // Handeles bleeding -- amount is the information for greater
    // recursive blood flow.
    procedure Bleed( const Coord : TCoord2D; amount : byte = 1 );
    // function needed for the vvision interface
    function blocksVision( const Coord : TCoord2D ) : boolean; override;
    // unimplemented as yet
    function isPassable( const coord : TCoord2D ) : Boolean; override;
    // Creates and places the being at the given coordinate. Demonlevel is optional
    // and used only if the summoned creature is a demon.
    function Summon( const aid : AnsiString; Coord : TCoord2D; demonlevel : byte = 0 ) : TBeing;
    // Damages the tile
    procedure DamageTile( const aCoord : TCoord2D; aDamage : Word );
    // Renders and calculates an explosion.
    function isVisible( const aCoord : TCoord2D ) : boolean; override;
    //
    procedure Explosion( Where : TCoord2D; Color : byte; Range : byte; Strength : byte;
      DrawDelay : Word; DamageType : Byte; aSequence : Word );
    // Renders and calculates a breath weapon/cannon shot.
    procedure Breath( Where : TCoord2D; Direction : TDirection; Color : byte; Range : byte;
      Strength : byte; DrawDelay : Word = 50 );
    // Runs a hook on the given cell (if present)
    function RunCellHook( const aWhere : TCoord2D; aHook : Byte; const aParams : array of Const ) : Variant;
    // Overriden remove - makes sure that removed monsters will clean up
    // their pointer in the map
    procedure Remove( aNode : TNode ); override;
    // Ease of iteration -- Enumerator support
    function GetEnumerator : TLevelEnumerator;
    // Disposes of all alocated structures, and the level itself. If you want to
    // keep the player, remove it from the Beings array beforehand.
    destructor Destroy; override;
    // Register API
    class procedure RegisterLuaAPI();

  private
    // Stores TerrainB values.
    procedure StoreTerrain;
    // Function returning being at given coord.
    function getTerrain( Coord : TCoord2D ) : TTerrainData;
    // Function returning the T at given coord.
    function getBeing( const Coord : TCoord2D ) : TBeing;
  public
    // Alias for TerraData[Map[x,y].Terrain].Flags
    function getFlags( Coord : TCoord2D ) : TFlags;
    // Alias for TerraData[Map[x,y].Terrain].MoveCost
    function getMoveCost( Coord : TCoord2D ) : Byte;
    // numeric to string ID conversion
    function CellToID( const aCell : Byte ) : AnsiString; override;
  private
    // Holds the next iterated node, so if removed does not access it
    FIterate   : TNode;
  public
    // Property for Cell terrain information access.
    property Terrain[Index : TCoord2D] : TTerrainData read getTerrain;
    // Property for Being access.
    property Being[Index : TCoord2D] : TBeing read getBeing;
  published
    property tick_count  : DWord read FTickCount  write FTickCount;
    property mode        : Byte  read FMode       write FMode;
    property arena       : Byte  read FArena      write FArena;
    property spawn_level : Word  read FSpawnLevel write FSpawnLevel;
    property sprite_base : Word  read FSpriteBase write FSpriteBase;
  end;

// The Level singleton, for access by other units of the program. Initialized
// and disposed of by the TBerserk singleton.
var
  Level : TLevel = nil;


implementation

uses vluasystem, vluagamestate, vluatools, brmain, brlua, brui, brplayer;

{ TLevel }


constructor TLevel.Create;
begin
  inherited Create('default', MAP_MAXX, MAP_MAXY, 15 );
  Clear;
  FSpawnLevel := 1;
  FMode := mode_Massacre;
  FArena := 1;
  FTickCount := 0;
  FSeed := Random( $FFFF );
end;

procedure TLevel.Generate( nArena : byte; nMode : Byte; nSpawnLevel : Word );
var
  PlayerPosition, c : TCoord2D;

  function FluidFlag( c : TCoord2D; aSet : Byte; aValue : Byte ) : Byte;
  begin
    if not isProperCoord( c ) then Exit(0);
    with Terrain[ c ] do
      if (not (TF_EDGES in Flags)) or (EdgeSet <> aSet) then Exit( aValue );
    Exit( 0 );
  end;

begin
  FArena := nArena;
  FSpawnLevel := nSpawnLevel;
  FMode := nMode;

  if FMode = mode_Endless then
    FArena := Random( 4 ) + 1;

  LuaSystem.ProtectedCall(['generator','run'],[]);

  StoreTerrain;

  Add( Player );
  repeat
    PlayerPosition.Create( Random( 20 ) + 15, Random( 10 ) + 5 );
  until Player.TryMove( PlayerPosition ) = Move_Ok;
  Player.Displace( PlayerPosition );
  for c in FArea do
    HitPoints[c] := TerraData[ getCell(c) ].DR;
  LuaSystem.ProtectedCall(['generator','start'],[]);

  for c in FArea do
    with Terrain[c] do
    if TF_EDGES in Flags then
      FMap[c.x,c.y].Rotation :=
        FluidFlag( c.ifInc( 0,-1), EdgeSet, 1 ) +
        FluidFlag( c.ifInc( 0,+1), EdgeSet, 2 ) +
        FluidFlag( c.ifInc(-1, 0), EdgeSet, 4 ) +
        FluidFlag( c.ifInc(+1, 0), EdgeSet, 8 );
 end;

procedure TLevel.StoreTerrain;
var
  c : TCoord2D;
begin
  for c in FArea do
    with FMap[c.X, c.Y] do
      TerrainB := GetCell(c);
end;

function TLevel.getTerrain( Coord : TCoord2D ) : TTerrainData;
begin
  Exit( TerraData[GetCell(Coord)] );
end;

function TLevel.getBeing( const Coord : TCoord2D ) : TBeing;
begin
  Exit( inherited getBeing( Coord ) as TBeing )
end;

function TLevel.getFlags( Coord : TCoord2D ) : TFlags;
begin
  Exit( TerraData[GetCell(Coord)].Flags );
end;

function TLevel.getMoveCost( Coord : TCoord2D ) : Byte;
begin
  Exit( TerraData[GetCell(Coord)].MoveCost );
end;

function TLevel.CellToID ( const aCell : Byte ) : AnsiString;
begin
  Exit( TerraData[ aCell ].ID );
end;

procedure TLevel.Clear;
var iCoord : TCoord2D;
begin
  DestroyChildren;
  ClearAll(1, [vlfExplored]);
  for iCoord in FArea do
    with FMap[iCoord.X, iCoord.Y] do
      begin
        TerrainB := 1;
        Rotation := 0;
      end;
  FIterate   := nil;
  FFlags     := [];
  FTickCount := 0;
end;

procedure TLevel.Tick;
var iScan : TBeing;
begin
  iScan := Child as TBeing;
  if iScan <> nil then
  repeat
    FIterate := iScan.Next;
    iScan.Tick;
    iScan := FIterate as TBeing;
  until (iScan = nil) or (iScan = Child) or Berserk.Escape;

  Inc( FTickCount );
  LuaSystem.ProtectedCall( ['generator','tick'],[] );
end;


procedure TLevel.Bleed( const Coord : TCoord2D; amount : byte = 1 );
var
  Shift : TCoord2D;
  Count : Byte;
  Terra : Byte;
begin
  with FMap[Coord.x, Coord.y] do
  begin
    if TerraData[GetCell(Coord)].BloodID = 0 then Exit;
    PutCell( Coord, TerraData[GetCell(Coord)].BloodID );
    if TF_NOMOVE in TerraData[GetCell(Coord)].Flags then
      Exit;
    if Amount > 1 then
      for Count := 1 to Amount do
      begin
        Shift.x := Random( 3 ) - 1;
        Shift.y := Random( 3 ) - 1;
        if isproperCoord( Coord + Shift ) then
          Bleed( Coord + Shift, Amount - 1 );
      end;
  end;
end;

function TLevel.blocksVision( const Coord : TCoord2D ) : boolean;
begin
  if not isProperCoord( Coord ) then
    Exit( True );
  if TF_NOSIGHT in getFlags( Coord ) then
    Exit( True );
  Exit( False );
end;

function TLevel.isPassable( const coord : TCoord2D ) : Boolean;
begin
  Exit( not ( TF_NOMOVE in getFlags( Coord ) ) );
end;

function TLevel.Summon( const aid : AnsiString; Coord : TCoord2D; demonlevel : byte = 0 ) : TBeing;
var
  c :    TCoord2D;
  iBeing : TBeing;
begin
  if Being[Coord] <> nil then
  begin
    if TF_NOMOVE in getFlags( Coord ) then
      Exit( nil );
    for c in NewArea( Coord, 1 ) do
      if Being[c] = nil then
        Break;
    if Being[c] <> nil then
      Exit( nil );
    Coord := c;
  end;
  iBeing := TBeing.Create( aid, Coord, demonlevel );
  Add( iBeing );
  Exit( iBeing );
end;

procedure TLevel.DamageTile( const aCoord : TCoord2D; aDamage : Word );
var iTerra : Byte;
begin
  iTerra := GetCell(aCoord);
  if TerraData[ iTerra ].DR = 0 then Exit;
  HitPoints[ aCoord ] := Max( 0, HitPoints[ aCoord ] - aDamage );
  if HitPoints[ aCoord ] = 0 then
    if not RunCellHook( aCoord, TileHook_OnDestroy, [] ) then
    begin
      PutCell( aCoord, TerraData[ iTerra ].DestroyID );
      FMap[ aCoord.x, aCoord.y ].TerrainB := TerraData[ iTerra ].DestroyID;
    end;
end;

function TLevel.isVisible(const aCoord: TCoord2D): boolean;
begin
  Exit( not BlocksVision( aCoord ) );;
end;

procedure TLevel.Explosion( Where : TCoord2D; Color : byte; Range : byte; Strength : byte;
  DrawDelay : Word; DamageType : Byte; aSequence : Word );
var
  cn :     Byte;
  Damage : Integer;
  Coord :  TCoord2D;
  iNode : TNode;
begin
  if Strength <> 0 then
    for iNode in Self do
      with iNode as TBeing do
        FAffected := False;

  UI.AddExplosion( Where, Color, Range, cn, DrawDelay, aSequence );
  for cn := 1 to Range do
  begin
    if Strength <> 0 then
      for Coord in NewArea( Where, Range ).Clamped( FArea ) do
        if Distance( Coord, Where ) < cn then
        begin
          if not Level.isEyeContact( Coord, Where ) then
            Continue;
          Damage := Dice( Strength, 6 ) div Max( 1, Distance( Coord, Where ) div 2 );
          if Being[Coord] <> nil then
            with Being[Coord] do
            begin
              if FAffected then
                Continue;
              if FHP <= 0 then
                Continue;
              Knockback( NewDirection( Where, Coord ), Damage );
              FAffected := True;
              ApplyDamage( Damage, DamageType );
            end;
          DamageTile( Coord, Damage );
        end;
  end;
end;

procedure TLevel.Breath( Where : TCoord2D; Direction : TDirection; Color : byte; Range : byte;
  Strength : byte; DrawDelay : Word = 50 );
var
  cn :     Byte;
  d :      Byte;
  Damage : Integer;
  Angle :  Real;
  Coord :  TCoord2D;
  iNode : TNode;
begin
  for iNode in Self do
    with iNode as TBeing do
      FAffected := False;

  UI.Breath( Where, Direction, Color, Range, cn, DrawDelay );
  for cn := 1 to Range + 4 do
  begin
    for Coord in NewArea( Where, Range ).Clamped( FArea ) do
    begin
      d := Distance( Coord, Where );
      if ( d = 0 ) or ( d > cn ) then
        Continue;

      if Direction.x <> 0 then
        if Sgn( Coord.x - Where.x ) = -Direction.x then
          Continue;
      if Direction.y <> 0 then
        if Sgn( Coord.y - Where.y ) = -Direction.y then
          Continue;
      if Direction.x = 0 then
      begin
        if Abs( Coord.y - Where.y ) < Abs( Coord.x - Where.x ) then
          Continue;
      end;
      if Direction.y = 0 then
      begin
        if Abs( Coord.x - Where.x ) < Abs( Coord.y - Where.y ) then
          Continue;
      end;


      angle := ( ( Coord.x - Where.x ) * Direction.x + ( Coord.y - Where.y ) * Direction.y ) /
        ( vmath.RealDistance( Where.x, Where.y, Coord.x, Coord.y ) * vmath.RealDistance(
        Where.x, Where.y, Where.x + Direction.x, Where.y + Direction.y ) );
      if angle < 0.76 + ( d * 0.02 ) then
        Continue;

      if not isEyeContact( Coord, Where ) then
        Continue;
      if d > Range then
        Continue;

      Damage := Round( Dice( Strength, 6 ) / Max( 1, d div 3 ) );

      if Being[Coord] <> nil then
        with Being[Coord] do
        begin
          if FAffected then
            Continue;
          if FHP <= 0 then
            Continue;
          Knockback( NewDirection( Where, Coord ), Damage );
          FAffected := True;
          ApplyDamage( Damage, DAMAGE_FIRE );
        end;

      DamageTile( Coord, Damage );
    end;
  end;
  UI.Draw;
end;

function TLevel.RunCellHook(const aWhere: TCoord2D; aHook: Byte;
  const aParams: array of const): Variant;
begin
  if aHook in TerraData[GetCell(aWhere)].Hooks then
    RunCellHook := LuaSystem.ProtectedCall(
      [ 'cells', GetCell(aWhere), TileHooks[ aHook ] ],
      ConcatConstArray( [LuaCoord( aWhere )], aParams )
    );
  Exit( False );
end;

procedure TLevel.Remove ( aNode : TNode ) ;
begin
  if FIterate = aNode then FIterate := FIterate.Next;
  if FIterate = aNode then FIterate := nil;
  inherited Remove ( aNode ) ;
end;

function TLevel.GetEnumerator : TLevelEnumerator;
begin
  GetEnumerator.Create( Self );
end;

destructor TLevel.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function lua_level_get_player(L: Plua_State): Integer; cdecl;
var State : TLuaGameState;
    Level : TLevel;
begin
  State.Init(L);
  Level := State.ToObject(1) as TLevel;
  State.Push( Player );
  Result := 1;
end;


function lua_level_summon(L: Plua_State): Integer; cdecl;
var State : TLuaGameState;
    Being : TBeing;
    Level : TLevel;
begin
  State.Init(L);
  if State.StackSize < 3 then Exit(0);
  Level := State.ToObject(1) as TLevel;
  Being := Level.Summon(State.ToString(2),State.ToCoord(3), State.ToInteger( 4, 0 ));
  State.Push( Being );
  Result := 1;
end;

function lua_level_explosion(L: Plua_State): Integer; cdecl;
var State : TLuaGameState;
    Level : TLevel;
begin
  State.Init(L);
  if State.StackSize < 3 then Exit(0);
  Level := State.ToObject(1) as TLevel;
  Level.Explosion(
    State.ToPosition( 2 ),
    State.ToInteger( 3, Red ), // color
    State.ToInteger( 4, 2 ),   // range
    State.ToInteger( 5, 0 ),   // strength
    State.ToInteger( 6, 50 ),  // draw delay
    State.ToInteger( 7, DAMAGE_FIRE ), // damage type
    0
  );
  Result := 0;
end;

const lua_level_lib : array[0..3] of luaL_Reg = (
  ( name : 'get_player'; func: @lua_level_get_player),
  ( name : 'summon';     func: @lua_level_summon),
  ( name : 'explosion';  func: @lua_level_explosion),
  ( name : nil;          func: nil; )
);

// Register API
class procedure TLevel.RegisterLuaAPI();
begin
  TLuaMapNode.RegisterLuaAPI( 'level' );
  LuaSystem.Register( 'level', lua_level_lib );
end;


end.

