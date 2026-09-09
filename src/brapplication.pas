{$INCLUDE brinclude.inc}
unit brapplication;
interface

uses SysUtils, vapp, vrlapp;

type TBerserkApplication = class( TRLApplication )
protected
  procedure DefineOptions; override;
  procedure DiscoverPaths( var aPaths : TGamePaths ); override;
  procedure BeforeConfiguration( var aPaths : TGamePaths ); override;
  function CreateConfiguration( var aPaths : TGamePaths ) : TObject; override;
  procedure ApplyOptions; override;
  procedure BeforeDiagnostics; override;
  function CreateRuntime( const aPaths : TGamePaths;
    var aConfiguration : TObject ) : TRLRuntime; override;
end;

implementation

uses vos, vutil, brconfig, brconfiguration, brmain, brdata, brui;

procedure TBerserkApplication.DefineOptions;
begin
  AddFlag( 'god', #0, 'Enable god mode and the debug console.' );
  AddFlag( 'quick', #0, 'Use quick character creation after mode selection.' );
  AddFlag( 'nosound', #0, 'Disable the audio backend.' );
  AddFlag( 'console', #0, 'Use the text console.' );
  AddFlag( 'graphics', #0, 'Use graphics; takes precedence over --console.' );
  AddFlag( 'lowascii', #0, 'Use basic ASCII characters.' );
  AddFlag( 'fullscreen', #0, 'Start graphics in fullscreen.' );
  AddValueOption( 'name', #0, 'PLAYER_NAME', 'Override the default player name.' );
end;

procedure TBerserkApplication.DiscoverPaths( var aPaths : TGamePaths );
begin
  // Preserve the game's platform roots; shared resolution applies overrides.
  aPaths.ExecutablePath := ExtractFilePath( ExeName );
  aPaths.ResourcePath := '';
  {$IFDEF DARWIN}
  {$IFDEF OSX_APP_BUNDLE}
  aPaths.ResourcePath := GetResourcesPath;
  {$ENDIF}
  {$ENDIF}
  {$IFDEF WINDOWS}
  aPaths.ResourcePath := aPaths.ExecutablePath;
  {$ENDIF}
  aPaths.ConfigurationPath := aPaths.ResourcePath + 'config.lua';
  aPaths.DataPath := aPaths.ResourcePath;
  aPaths.WritePath := aPaths.ResourcePath;
  aPaths.ScorePath := '';
end;

procedure TBerserkApplication.BeforeConfiguration( var aPaths : TGamePaths );
begin
  GodMode := HasOption( 'god' );
  QuickStart := HasOption( 'quick' );
  ConfigurationPath := aPaths.ConfigurationPath;
end;

function TBerserkApplication.CreateConfiguration( var aPaths : TGamePaths ) : TObject;
var iLua : TGameConfig;
begin
  iLua := TGameConfig.Create( aPaths.ConfigurationPath );
  try
    AudioDriver      := iLua.Configure( 'audio.driver', 'SDL' );
    aPaths.DataPath  := iLua.Configure( 'DataPath', aPaths.DataPath );
    aPaths.WritePath := iLua.Configure( 'WritePath', aPaths.WritePath );
    aPaths.ScorePath := iLua.Configure( 'ScorePath', aPaths.ScorePath );
    Result := TBerserkConfiguration.Create( iLua );
  finally
    iLua.Free;
  end;
end;

procedure TBerserkApplication.ApplyOptions;
var iConfiguration : TBerserkConfiguration;
begin
  if HasOption( 'nosound' ) then AudioDriver := 'NONE';
  FullScreen := HasOption( 'fullscreen' );
  if FPaths.ScorePath = '' then FPaths.ScorePath := FPaths.WritePath;
  FPaths.SettingsPath := FPaths.WritePath + 'settings.lua';
  DataPath := FPaths.DataPath;
  WritePath := FPaths.WritePath;
  ScorePath := FPaths.ScorePath;
  iConfiguration := TBerserkConfiguration( Configuration );
  iConfiguration.LowASCIIOverride := HasOption( 'lowascii' );
  iConfiguration.HasNameOverride := HasOption( 'name' );
  if iConfiguration.HasNameOverride then
    iConfiguration.NameOverride := GetOptionValue( 'name' );
  iConfiguration.FullScreen := FullScreen;
  iConfiguration.AudioDriver := AudioDriver;
end;

procedure TBerserkApplication.BeforeDiagnostics;
begin
  FPaths.LogPath := FPaths.WritePath + 'log.txt';
end;

function TBerserkApplication.CreateRuntime( const aPaths : TGamePaths;
  var aConfiguration : TObject ) : TRLRuntime;
var iConfiguration : TBerserkConfiguration;
begin
  // Diagnostics are ready before version/resource reads or Runtime creation.
  iConfiguration := TBerserkConfiguration( aConfiguration );
  iConfiguration.ReadSettings( aPaths.SettingsPath );
  GraphicsMode := iConfiguration.GetBoolean( 'graphics_mode' );
  if HasOption( 'console' )  then GraphicsMode := False;
  if HasOption( 'graphics' ) then GraphicsMode := True;
  iConfiguration.GraphicsMode := GraphicsMode;
  Version := ReadVersion( aPaths.DataPath + 'version.txt' );
  Result := TBerserkRuntime.Create( aPaths, aConfiguration );
end;

end.
