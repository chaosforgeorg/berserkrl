{$INCLUDE brinclude.inc}
unit brconfiguration;
interface

uses vconfiguration, vbindings, brconfig, brbindings;

const GAME_CONFIGURATION_GROUP_DISPLAY  = 'display';
      GAME_CONFIGURATION_GROUP_GAMEPLAY = 'gameplay';
      GAME_CONFIGURATION_GROUP_AUDIO    = 'audio';

type TBerserkConfiguration = class( TConfigurationManager )
  // Transfers the retained Lua config; nil permits offline settings inspection.
  // Construction neither reads/writes settings nor applies values to the game.
  constructor Create( var aLuaConfig : TGameConfig );
  destructor Destroy; override;
  procedure ResetValues;
  procedure ResetGroup( const aGroupID : AnsiString );
  function ReadSettings( const aFileName : AnsiString ) : Boolean;
private
  FLuaConfig       : TGameConfig;
  FGameKeyBindings : TBindingCatalog;
  FUIKeyBindings   : TBindingCatalog;
  function CatalogForEntry( const aID : AnsiString ) : TBindingCatalog;
public
  // Effective launch choices, populated before Runtime's virtual IO factory.
  GraphicsMode : Boolean;
  FullScreen   : Boolean;
  AudioDriver  : AnsiString;
  property LuaConfig       : TGameConfig read FLuaConfig;
  property GameKeyBindings : TBindingCatalog read FGameKeyBindings;
  property UIKeyBindings   : TBindingCatalog read FUIKeyBindings;
end;

implementation

uses SysUtils;

constructor TBerserkConfiguration.Create( var aLuaConfig : TGameConfig );
var iGroup : TConfigurationGroup;
begin
  inherited Create;
  FLuaConfig := aLuaConfig;
  aLuaConfig := nil;

  iGroup := AddGroup( GAME_CONFIGURATION_GROUP_DISPLAY );
  iGroup.AddToggle( 'graphics_mode', True )
    .SetName( 'Graphics mode' )
    .SetDescription( 'Use graphics instead of the text console. Requires restart; --console and --graphics override it for that process.' );
  iGroup.AddToggle( 'high_ascii', True )
    .SetName( 'Extended ASCII' )
    .SetDescription( 'Use the extended block glyph for text effects. Applies immediately in console mode; --lowascii overrides it.' );

  iGroup := AddGroup( GAME_CONFIGURATION_GROUP_GAMEPLAY );
  iGroup.AddToggle( 'always_random_name', False )
    .SetName( 'Random player name' )
    .SetDescription( 'Choose a random name for the next character. A nonempty default name or --name takes precedence.' );
  iGroup.AddString( 'always_name', '' )
    .SetName( 'Default player name' )
    .SetDescription( 'Name for the next character, up to 16 bytes. Empty asks for a name unless random naming is enabled; --name overrides it.' );

  iGroup := AddGroup( GAME_CONFIGURATION_GROUP_AUDIO );
  iGroup.AddToggle( 'sound_enabled', True )
    .SetName( 'Sound effects' )
    .SetDescription( 'Mute or enable sound effects immediately while retaining the selected volume. Unavailable when the audio driver is NONE.' );
  iGroup.AddToggle( 'music_enabled', True )
    .SetName( 'Music' )
    .SetDescription( 'Stop or resume music immediately while retaining the selected volume. Unavailable when the audio driver is NONE.' );
  iGroup.AddInteger( 'volume_sound', 80 ).SetRange( 0, 100, 5 )
    .SetName( 'Sound volume' )
    .SetDescription( 'Sound effect volume from 0 to 100. Applies immediately when audio is available.' );
  iGroup.AddInteger( 'volume_music', 80 ).SetRange( 0, 100, 5 )
    .SetName( 'Music volume' )
    .SetDescription( 'Music volume from 0 to 100. Applies immediately, including the current track, when audio is available.' );

  FGameKeyBindings := TBindingCatalog.Create( GameKeyBindingInfo );
  FGameKeyBindings.RegisterGroup( AddGroup( GAME_BINDING_GROUP_MOVEMENT ), GAME_BINDING_GROUP_MOVEMENT );
  FGameKeyBindings.RegisterGroup( AddGroup( GAME_BINDING_GROUP_ACTIONS ), GAME_BINDING_GROUP_ACTIONS );
  FGameKeyBindings.RegisterGroup( AddGroup( GAME_BINDING_GROUP_SKILLS ), GAME_BINDING_GROUP_SKILLS );
  FGameKeyBindings.ValidateRegistration;
  FUIKeyBindings := TBindingCatalog.Create( UIKeyBindingInfo );
  FUIKeyBindings.RegisterGroup( AddGroup( UI_KEY_BINDING_GROUP ), UI_KEY_BINDING_GROUP );
  FUIKeyBindings.ValidateRegistration;
end;

destructor TBerserkConfiguration.Destroy;
begin
  FreeAndNil( FUIKeyBindings );
  FreeAndNil( FGameKeyBindings );
  FreeAndNil( FLuaConfig );
  inherited Destroy;
end;

function TBerserkConfiguration.CatalogForEntry( const aID : AnsiString ) : TBindingCatalog;
begin
  if FGameKeyBindings.ActionForID( aID ) <> BINDING_NONE then Exit( FGameKeyBindings );
  if FUIKeyBindings.ActionForID( aID ) <> BINDING_NONE then Exit( FUIKeyBindings );
  Result := nil;
end;

procedure TBerserkConfiguration.ResetValues;
var iGroup : TConfigurationGroup;
    iEntry : TConfigurationEntry;
begin
  for iGroup in Groups do
    for iEntry in iGroup.Entries do iEntry.Reset;
end;

procedure TBerserkConfiguration.ResetGroup( const aGroupID : AnsiString );
var iGroup   : TConfigurationGroup;
    iEntry   : TConfigurationEntry;
    iCatalog : TBindingCatalog;
begin
  iGroup := Group[ aGroupID ];
  if iGroup = nil then raise Exception.Create( 'Unknown settings group: ' + aGroupID );
  for iEntry in iGroup.Entries do
  begin
    iCatalog := CatalogForEntry( iEntry.ID );
    if iCatalog = nil then
      iEntry.Reset
    else
      iCatalog.SetKey( iCatalog.ActionForID( iEntry.ID ),
        TIntegerConfigurationEntry( iEntry ).Default );
  end;
end;

function TBerserkConfiguration.ReadSettings( const aFileName : AnsiString ) : Boolean;
begin
  ResetValues;
  Result := True;
  if FileExists( aFileName ) then Result := inherited Read( aFileName );
  if not Result then ResetValues;
end;

end.
