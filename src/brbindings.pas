{$INCLUDE brinclude.inc}
unit brbindings;
interface

uses vbindings, vioevent, vtigio, brdata;

const GAME_BINDING_GROUP_MOVEMENT = 'keybindings_movement';
      GAME_BINDING_GROUP_ACTIONS  = 'keybindings_actions';
      GAME_BINDING_GROUP_SKILLS   = 'keybindings_skills';
      UI_KEY_BINDING_GROUP        = 'ui_bindings_keyboard';

const GameKeyBindingInfo : array[0..26] of TBindingInfo = (
  ( Action: COMMAND_WALKWEST; ID: 'input_walk_west'; Group: GAME_BINDING_GROUP_MOVEMENT; Default: VKEY_LEFT; Name: 'Walk west'; Description: 'Move west.' ),
  ( Action: COMMAND_WALKEAST; ID: 'input_walk_east'; Group: GAME_BINDING_GROUP_MOVEMENT; Default: VKEY_RIGHT; Name: 'Walk east'; Description: 'Move east.' ),
  ( Action: COMMAND_WALKNORTH; ID: 'input_walk_north'; Group: GAME_BINDING_GROUP_MOVEMENT; Default: VKEY_UP; Name: 'Walk north'; Description: 'Move north.' ),
  ( Action: COMMAND_WALKSOUTH; ID: 'input_walk_south'; Group: GAME_BINDING_GROUP_MOVEMENT; Default: VKEY_DOWN; Name: 'Walk south'; Description: 'Move south.' ),
  ( Action: COMMAND_WALKNE; ID: 'input_walk_ne'; Group: GAME_BINDING_GROUP_MOVEMENT; Default: VKEY_PGUP; Name: 'Walk northeast'; Description: 'Move northeast.' ),
  ( Action: COMMAND_WALKSE; ID: 'input_walk_se'; Group: GAME_BINDING_GROUP_MOVEMENT; Default: VKEY_PGDOWN; Name: 'Walk southeast'; Description: 'Move southeast.' ),
  ( Action: COMMAND_WALKNW; ID: 'input_walk_nw'; Group: GAME_BINDING_GROUP_MOVEMENT; Default: VKEY_HOME; Name: 'Walk northwest'; Description: 'Move northwest.' ),
  ( Action: COMMAND_WALKSW; ID: 'input_walk_sw'; Group: GAME_BINDING_GROUP_MOVEMENT; Default: VKEY_END; Name: 'Walk southwest'; Description: 'Move southwest.' ),
  ( Action: COMMAND_WAIT; ID: 'input_wait'; Group: GAME_BINDING_GROUP_MOVEMENT; Default: VKEY_PERIOD; Name: 'Wait'; Description: 'Wait one turn.' ),
  ( Action: COMMAND_QUIT; ID: 'input_quit'; Group: GAME_BINDING_GROUP_ACTIONS; Default: VKEY_Q or IOKeyCodeShiftMask; Name: 'Abandon game'; Description: 'Abandon the current run without saving.' ),
  ( Action: COMMAND_ESCAPE; ID: 'input_escape'; Group: GAME_BINDING_GROUP_ACTIONS; Default: VKEY_ESCAPE; Name: 'Cancel / game menu'; Description: 'Cancel targeting; open the game menu during play.' ),
  ( Action: COMMAND_OK; ID: 'input_ok'; Group: GAME_BINDING_GROUP_ACTIONS; Default: VKEY_ENTER; Name: 'Confirm'; Description: 'Confirm a gameplay prompt.' ),
  ( Action: COMMAND_LOOK; ID: 'input_look'; Group: GAME_BINDING_GROUP_ACTIONS; Default: VKEY_L; Name: 'Look'; Description: 'Inspect the surroundings.' ),
  ( Action: COMMAND_RUNNING; ID: 'input_running'; Group: GAME_BINDING_GROUP_ACTIONS; Default: VKEY_TAB; Name: 'Run / next target'; Description: 'Toggle running; cycle targets while targeting.' ),
  ( Action: COMMAND_HELP; ID: 'input_help'; Group: GAME_BINDING_GROUP_ACTIONS; Default: VKEY_H; Name: 'Help'; Description: 'Show gameplay help and current skill keys.' ),
  ( Action: COMMAND_MESSAGES; ID: 'input_messages'; Group: GAME_BINDING_GROUP_ACTIONS; Default: VKEY_P or IOKeyCodeShiftMask; Name: 'Message history'; Description: 'Show previous messages.' ),
  ( Action: COMMAND_PLAYERINFO; ID: 'input_player_info'; Group: GAME_BINDING_GROUP_ACTIONS; Default: VKEY_C or IOKeyCodeShiftMask; Name: 'Character'; Description: 'Show character information.' ),
  ( Action: COMMAND_SKILL1; ID: 'input_skill_1'; Group: GAME_BINDING_GROUP_SKILLS; Default: VKEY_1; Name: 'Skill 1'; Description: 'Use skill slot 1. Hold Shift for alternate use.' ),
  ( Action: COMMAND_SKILL2; ID: 'input_skill_2'; Group: GAME_BINDING_GROUP_SKILLS; Default: VKEY_2; Name: 'Skill 2'; Description: 'Use skill slot 2. Hold Shift for alternate use.' ),
  ( Action: COMMAND_SKILL3; ID: 'input_skill_3'; Group: GAME_BINDING_GROUP_SKILLS; Default: VKEY_3; Name: 'Skill 3'; Description: 'Use skill slot 3. Hold Shift for alternate use.' ),
  ( Action: COMMAND_SKILL4; ID: 'input_skill_4'; Group: GAME_BINDING_GROUP_SKILLS; Default: VKEY_4; Name: 'Skill 4'; Description: 'Use skill slot 4. Hold Shift for alternate use.' ),
  ( Action: COMMAND_SKILL5; ID: 'input_skill_5'; Group: GAME_BINDING_GROUP_SKILLS; Default: VKEY_5; Name: 'Skill 5'; Description: 'Use skill slot 5. Hold Shift for alternate use.' ),
  ( Action: COMMAND_SKILL6; ID: 'input_skill_6'; Group: GAME_BINDING_GROUP_SKILLS; Default: VKEY_6; Name: 'Skill 6'; Description: 'Use skill slot 6. Hold Shift for alternate use.' ),
  ( Action: COMMAND_SKILL7; ID: 'input_skill_7'; Group: GAME_BINDING_GROUP_SKILLS; Default: VKEY_7; Name: 'Skill 7'; Description: 'Use skill slot 7. Hold Shift for alternate use.' ),
  ( Action: COMMAND_SKILL8; ID: 'input_skill_8'; Group: GAME_BINDING_GROUP_SKILLS; Default: VKEY_8; Name: 'Skill 8'; Description: 'Use skill slot 8. Hold Shift for alternate use.' ),
  ( Action: COMMAND_SKILL9; ID: 'input_skill_9'; Group: GAME_BINDING_GROUP_SKILLS; Default: VKEY_9; Name: 'Skill 9'; Description: 'Use skill slot 9. Hold Shift for alternate use.' ),
  ( Action: COMMAND_SKILL0; ID: 'input_skill_0'; Group: GAME_BINDING_GROUP_SKILLS; Default: VKEY_0; Name: 'Skill 0'; Description: 'Use skill slot 0. Hold Shift for alternate use.' )
);

const UIKeyBindingInfo : array[0..10] of TBindingInfo = (
  ( Action: VTIG_IE_UP; ID: 'ui_keyboard_up'; Group: UI_KEY_BINDING_GROUP; Default: VKEY_UP; Name: 'Up'; Description: 'Use up in menus and other UI screens.' ),
  ( Action: VTIG_IE_DOWN; ID: 'ui_keyboard_down'; Group: UI_KEY_BINDING_GROUP; Default: VKEY_DOWN; Name: 'Down'; Description: 'Use down in menus and other UI screens.' ),
  ( Action: VTIG_IE_LEFT; ID: 'ui_keyboard_left'; Group: UI_KEY_BINDING_GROUP; Default: VKEY_LEFT; Name: 'Left'; Description: 'Use left in menus and other UI screens.' ),
  ( Action: VTIG_IE_RIGHT; ID: 'ui_keyboard_right'; Group: UI_KEY_BINDING_GROUP; Default: VKEY_RIGHT; Name: 'Right'; Description: 'Use right in menus and other UI screens.' ),
  ( Action: VTIG_IE_HOME; ID: 'ui_keyboard_home'; Group: UI_KEY_BINDING_GROUP; Default: VKEY_HOME; Name: 'Home'; Description: 'Use home in menus and other UI screens.' ),
  ( Action: VTIG_IE_END; ID: 'ui_keyboard_end'; Group: UI_KEY_BINDING_GROUP; Default: VKEY_END; Name: 'End'; Description: 'Use end in menus and other UI screens.' ),
  ( Action: VTIG_IE_PGUP; ID: 'ui_keyboard_page_up'; Group: UI_KEY_BINDING_GROUP; Default: VKEY_PGUP; Name: 'Page up'; Description: 'Use page up in menus and other UI screens.' ),
  ( Action: VTIG_IE_PGDOWN; ID: 'ui_keyboard_page_down'; Group: UI_KEY_BINDING_GROUP; Default: VKEY_PGDOWN; Name: 'Page down'; Description: 'Use page down in menus and other UI screens.' ),
  ( Action: VTIG_IE_CANCEL; ID: 'ui_keyboard_cancel'; Group: UI_KEY_BINDING_GROUP; Default: VKEY_ESCAPE; Name: 'Cancel'; Description: 'Use cancel in menus and other UI screens.' ),
  ( Action: VTIG_IE_CONFIRM; ID: 'ui_keyboard_confirm'; Group: UI_KEY_BINDING_GROUP; Default: VKEY_ENTER; Name: 'Confirm'; Description: 'Use confirm in menus and other UI screens.' ),
  ( Action: VTIG_IE_SELECT; ID: 'ui_keyboard_select'; Group: UI_KEY_BINDING_GROUP; Default: VKEY_SPACE; Name: 'Select'; Description: 'Use select in menus and other UI screens.' )
);

implementation

end.
