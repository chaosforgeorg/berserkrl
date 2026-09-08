{$INCLUDE brinclude.inc}
unit brsettingsview;
interface

uses viotypes, vioevent, vbindings, vconfiguration, brconfiguration;

type TBerserkSettingsApply = procedure of object;
     TBerserkSettingsState = ( BSS_GENERAL, BSS_INPUT, BSS_UI,
       BSS_MOVEMENT, BSS_GAMEPLAY, BSS_SKILLS );

     TBerserkSettingsView = class( TIOLayer )
       constructor Create( aConfiguration : TBerserkConfiguration;
         aOnApply : TBerserkSettingsApply );
       destructor Destroy; override;
       procedure Update( aDTime : Integer; aActive : Boolean ); override;
       function HandleEvent( const aEvent : TIOEvent ) : Boolean; override;
       function IsModal : Boolean; override;
       procedure RecoverUIBindings;
     private
       FConfiguration : TBerserkConfiguration;
       FOriginalValues : TConfigurationValueMap;
       FOnApply : TBerserkSettingsApply;
       FState : TBerserkSettingsState;
       FCapture : Boolean;
       FRecovery : Boolean;
       FCaptureAction : TBindingAction;
       FCaptureMessage, FError : AnsiString;
       procedure SetState( aState : TBerserkSettingsState );
       function BindingCatalog : TBindingCatalog;
       procedure ResetPage;
       procedure ApplySettings;
     end;

implementation

uses SysUtils, vutil, vtig, vtigio, brbindings, brui;

const CStates : array[ TBerserkSettingsState ] of record
        Title, Group : AnsiString;
        Parent : TBerserkSettingsState;
      end = (
        ( Title: 'Settings'; Group: ''; Parent: BSS_GENERAL ),
        ( Title: 'Settings (Input)'; Group: ''; Parent: BSS_GENERAL ),
        ( Title: 'Settings (Input - UI)'; Group: UI_KEY_BINDING_GROUP; Parent: BSS_INPUT ),
        ( Title: 'Settings (Input - Movement)'; Group: GAME_BINDING_GROUP_MOVEMENT; Parent: BSS_INPUT ),
        ( Title: 'Settings (Input - Gameplay)'; Group: GAME_BINDING_GROUP_ACTIONS; Parent: BSS_INPUT ),
        ( Title: 'Settings (Input - Skills)'; Group: GAME_BINDING_GROUP_SKILLS; Parent: BSS_INPUT )
      );
      CSub : array[0..4] of record
        State : TBerserkSettingsState;
        Name, Description : AnsiString;
      end = (
        ( State: BSS_INPUT; Name: 'Input'; Description: 'Configure keyboard input.' ),
        ( State: BSS_UI; Name: 'UI'; Description: 'Menu and dialog keys. Only unmodified keys are supported.' ),
        ( State: BSS_MOVEMENT; Name: 'Movement'; Description: 'Movement and waiting keys.' ),
        ( State: BSS_GAMEPLAY; Name: 'Gameplay'; Description: 'Gameplay actions and screens.' ),
        ( State: BSS_SKILLS; Name: 'Skills'; Description: 'Skill slots. Shift shortcuts are derived from these bindings.' )
      );

constructor TBerserkSettingsView.Create( aConfiguration : TBerserkConfiguration;
  aOnApply : TBerserkSettingsApply );
begin
  inherited Create;
  FConfiguration := aConfiguration;
  FOnApply := aOnApply;
  FOriginalValues := FConfiguration.SnapshotValues;
  SetState( BSS_GENERAL );
  VTIG_EventClear;
end;

destructor TBerserkSettingsView.Destroy;
begin
  if FOriginalValues <> nil then
  begin
    FConfiguration.RestoreValues( FOriginalValues );
    FOriginalValues.Free;
  end;
  inherited Destroy;
end;

procedure TBerserkSettingsView.SetState( aState : TBerserkSettingsState );
begin
  FState := aState;
  VTIG_ResetSelect( 'settings' );
end;

function TBerserkSettingsView.BindingCatalog : TBindingCatalog;
begin
  if FState = BSS_UI
    then Result := FConfiguration.UIKeyBindings
    else Result := FConfiguration.GameKeyBindings;
end;

procedure TBerserkSettingsView.RecoverUIBindings;
begin
  FConfiguration.ResetGroup( UI_KEY_BINDING_GROUP );
  SetState( BSS_UI );
  FRecovery := True;
  VTIG_EventClear;
end;

procedure TBerserkSettingsView.ResetPage;
var iState : TBerserkSettingsState;
begin
  if CStates[ FState ].Group <> '' then
    FConfiguration.ResetGroup( CStates[ FState ].Group )
  else
    for iState := BSS_UI to BSS_SKILLS do
      FConfiguration.ResetGroup( CStates[ iState ].Group );
end;

procedure TBerserkSettingsView.ApplySettings;
begin
  FRecovery := False;
  FOnApply;
  FreeAndNil( FOriginalValues );
  FOriginalValues := FConfiguration.SnapshotValues;
  if not FConfiguration.WriteSettings then
  begin
    FError := 'Could not save settings. Your changes remain active for this process.';
    VTIG_EventClear;
    Exit;
  end;
  if FState = BSS_GENERAL
    then FFinished := True
    else SetState( CStates[ FState ].Parent );
end;

procedure TBerserkSettingsView.Update( aDTime : Integer; aActive : Boolean );
var iGroup : TConfigurationGroup;
    iEntry, iHover : TConfigurationEntry;
    iCatalog : TBindingCatalog;
    iIndex, iSub, iCount, iSelected : Integer;
    iKey : TIOKeyCode;
    iValue, iDescription, iBackLabel : AnsiString;
    iNext : TBerserkSettingsState;
    iHasNext, iReset, iApply, iBack : Boolean;
begin
  if not aActive then Exit;
  UI.DrawFire;
  UI.RenderBG;
  UI.RenderWindow( Point( 78, 23 ), Point( 2, 2 ) );
  if FError <> '' then
  begin
    VTIG_BeginWindow( 'Settings Error', 'settings_error', Point( 76, 21 ), Point( 3, 3 ) );
      VTIG_Text( FError );
      VTIG_Text( 'Settings file:' );
      VTIG_Text( FConfiguration.SettingsPath );
    VTIG_End( 'Enter/Escape: return to Settings' );
    Exit;
  end;
  if FCapture then
  begin
    VTIG_BeginWindow( 'Rebind Key', 'settings_capture', Point( 76, 21 ), Point( 3, 3 ) );
      if FState = BSS_UI
        then VTIG_Text( 'Press an unmodified key to bind.' )
        else VTIG_Text( 'Press a key or chord to bind.' );
      VTIG_Text( 'Backspace/Delete: unbind. Escape: cancel.' );
      VTIG_Text( FCaptureMessage );
    VTIG_End;
    Exit;
  end;

  iApply := FRecovery and VTIG_GetIOState.KeyState.Activated( VKEY_ENTER );
  iBack := VTIG_GetIOState.KeyState.Activated( VKEY_ESCAPE );
  if FRecovery or iBack then VTIG_EventClear;
  if iBack then FRecovery := False;
  iGroup := nil;
  if CStates[ FState ].Group <> '' then
    iGroup := FConfiguration.Group[ CStates[ FState ].Group ];
  iCatalog := BindingCatalog;
  iHover := nil;
  iCount := 0;
  iHasNext := False;
  VTIG_BeginWindow( CStates[ FState ].Title, 'settings', Point( 76, 21 ), Point( 3, 3 ) );
    if FRecovery then VTIG_ResetSelect( 'settings', iGroup.Entries.Size + 1 );
    VTIG_BeginGroup( 15, True );
      VTIG_BeginGroup( 42 );
        if iGroup = nil then
        begin
          for iSub := 0 to High( CSub ) do
            if CStates[ CSub[ iSub ].State ].Parent = FState then
            begin
              if VTIG_Selectable( CSub[ iSub ].Name ) then
              begin
                iNext := CSub[ iSub ].State;
                iHasNext := True;
              end;
              Inc( iCount );
            end;
        end
        else
          for iEntry in iGroup.Entries do
          begin
            if VTIG_Selectable( iEntry.Name ) then
            begin
              FCaptureAction := iCatalog.ActionForID( iEntry.ID );
              FCaptureMessage := '';
              FCapture := True;
              VTIG_EventClear;
            end;
            Inc( iCount );
          end;
        iReset := VTIG_Selectable( 'Reset to defaults' );
        iApply := VTIG_Selectable( 'Apply settings' ) or iApply;
        if FState = BSS_GENERAL
          then iBack := VTIG_Selectable( 'Discard changes' ) or iBack
          else iBack := VTIG_Selectable( 'Back' ) or iBack;
        iSelected := VTIG_Selected( 'settings' );
      VTIG_EndGroup;
      VTIG_BeginGroup;
        iIndex := 0;
        if iGroup <> nil then
          for iEntry in iGroup.Entries do
          begin
            iKey := TIOKeyCode( iCatalog.ConfigurationValue( iCatalog.ActionForID( iEntry.ID ) ) );
            if iKey = 0 then iValue := 'Unbound' else iValue := IOKeyCodeToStringShort( iKey );
            VTIG_InputField( iValue );
            if iIndex = iSelected then iHover := iEntry;
            Inc( iIndex );
          end;
      VTIG_EndGroup;
    VTIG_EndGroup( True );
    iDescription := '';
    if iGroup = nil then
    begin
      iIndex := 0;
      for iSub := 0 to High( CSub ) do
        if CStates[ CSub[ iSub ].State ].Parent = FState then
        begin
          if iIndex = iSelected then iDescription := CSub[ iSub ].Description;
          Inc( iIndex );
        end;
    end
    else if iHover <> nil then iDescription := iHover.Description;
    if iSelected = iCount then
      if iGroup = nil
        then iDescription := 'Reset all input bindings to defaults.'
        else iDescription := 'Reset this page. Conflicting bindings on other pages are unbound.';
    if iSelected = iCount + 1 then iDescription := 'Apply all pending settings, save them and return.';
    if iSelected = iCount + 2 then
      if FState = BSS_GENERAL
        then iDescription := 'Close Settings and discard changes since opening or the last Apply.'
        else iDescription := 'Return to the previous page. Edits remain pending until Apply or Discard.';
    VTIG_Text( iDescription );
    if FRecovery
      then VTIG_Text( 'UI defaults are pending. Use Apply settings to restore controls.' )
      else VTIG_Text( 'Edits take effect on Apply settings.' );
  if FState = BSS_GENERAL then iBackLabel := 'discard' else iBackLabel := 'back';
  if FRecovery then
    VTIG_End( 'Enter: Apply settings   Escape: back' )
  else
    VTIG_End( UI.GetUIKeybinding( VTIG_IE_UP ) + '/' + UI.GetUIKeybinding( VTIG_IE_DOWN ) +
      ': select   ' + UI.GetUIKeybinding( VTIG_IE_CONFIRM ) + ': choose   Escape: ' + iBackLabel );

  if iHasNext then SetState( iNext );
  if iReset then ResetPage;
  if iApply then ApplySettings
  else if iBack or VTIG_EventCancel then
    if FState = BSS_GENERAL then FFinished := True else SetState( CStates[ FState ].Parent );
end;

function TBerserkSettingsView.HandleEvent( const aEvent : TIOEvent ) : Boolean;
var iKey : TIOKeyCode;
begin
  if not UI.IsTopLayer( Self ) then Exit( False );
  if FError <> '' then
  begin
    if ( aEvent.EType = VEVENT_KEYDOWN ) and
       ( aEvent.Key.Code in [ VKEY_ENTER, VKEY_ESCAPE ] ) then FError := '';
    VTIG_EventClear;
    Exit( True );
  end;
  if not FCapture then Exit( True );
  if ( aEvent.EType = VEVENT_KEYDOWN ) and ( aEvent.Key.Code <> 0 ) then
  begin
    if aEvent.Key.Code = VKEY_ESCAPE then FCapture := False
    else
    begin
      iKey := IOKeyEventToIOKeyCode( aEvent.Key );
      if aEvent.Key.Code in [ VKEY_BACK, VKEY_DELETE ] then iKey := 0;
      if ( FState = BSS_UI ) and ( iKey and IOKeyCodeModMask <> 0 ) then
        FCaptureMessage := 'UI keys cannot use Shift, Ctrl or Alt. Press an unmodified key.'
      else
      begin
        BindingCatalog.SetKey( FCaptureAction, iKey );
        FCapture := False;
      end;
    end;
  end;
  VTIG_EventClear;
  Result := True;
end;

function TBerserkSettingsView.IsModal : Boolean;
begin
  Result := True;
end;

end.
