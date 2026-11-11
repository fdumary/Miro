extends SceneTree
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_:String) -> void:
 checks+=1
 if not ok:failures.append(label_);push_error("FAIL: "+label_)
func frames(n:=3) -> void:
 for i in range(n):await process_frame
func mouse(at:Vector2,down:bool) -> void:
 var e:=InputEventMouseButton.new();e.position=at;e.global_position=at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0;root.push_input(e,true);await frames()
func motion(at:Vector2,relative:Vector2,held:bool) -> void:
 var e:=InputEventMouseMotion.new();e.position=at;e.global_position=at;e.relative=relative;e.button_mask=MOUSE_BUTTON_MASK_LEFT if held else 0;root.push_input(e,true);await frames()
func drag(from:Control,to:Vector2) -> void:
 var start:=from.get_global_rect().get_center();await motion(start,Vector2(10,0),false);await mouse(start,true);await motion(start+Vector2(15,0),Vector2(15,0),true);print("DRAG_STATE start=",start," target=",to," dragging=",root.gui_is_dragging()," hover=",root.gui_get_hovered_control())
 await motion(to,to-start-Vector2(15,0),true);await mouse(to,false);await frames()
func run() -> void:
 var campaign=root.get_node("Campaign");var bindings=root.get_node("InputBindings");var previous:Dictionary=bindings.custom.duplicate(true)
 var level=load("res://scenes/levels/level_03.tscn").instantiate();root.add_child(level);current_scene=level;await frames(8);level.finish_dialogue();level.player.set_physics_process(false);level.world_features.set_process(false)
 for g in level.guards():g.set_physics_process(false)
 var c=level.player.controls;level.player.guns.assign(["pistol","smg"]);level.player.has_gun=true;c.has_remote=true;c.layout.assign(["pistol","c4","smg"]);c.sync_slots();c.show_inventory();await frames()
 check(c.buttons.size()==4 and c.buttons.all(func(b):return b.get_script()==load("res://scripts/inventory_slot.gd")),"Only the four weapon buttons accept inventory drags")
 await drag(c.buttons[1],c.buttons[2].get_global_rect().get_center())
 check(c.slots[2]=="c4" and c.slots[1]=="smg","Actual mouse drag swaps C4 into slot 3")
 await drag(c.buttons[1],c.buttons[0].get_global_rect().get_center())
 check(c.slots[0]=="smg" and c.slots[2]=="c4","Actual mouse drag puts SMG on slot 1")
 var before:Array=Array(c.layout)
 await drag(c.buttons[2],c.inventory_title.get_global_rect().get_center())
 check(Array(c.layout)==before,"Dropping outside equipment slots leaves layout intact")
 check(not c.buttons[0]._can_drop_data(Vector2.ZERO,{"miro_inventory_owner":c.get_instance_id(),"slot":5}),"Dedicated blanket/guitar slot cannot enter equipment drag data")
 check(not c.layout.has("blanket") and not c.layout.has("guitar"),"Direct actions stay outside the three movable weapon slots")
 campaign.checkpoint={"floor":3,"player":{"layout":Array(c.layout)}};c.buttons[0].pressed.emit();c.buttons[1].pressed.emit();await frames()
 check(c.slots[1]=="smg" and Array(c.layout)==campaign.checkpoint.player.layout,"Controller/click swapping still works after dragging and updates checkpoint layout")
 bindings.custom={"slot_1":["key",KEY_J],"blanket":["key",KEY_K]};bindings.apply();c.refresh_slots()
 check(c.buttons[0].text.begins_with("J\n") and "K blanket" in c.inventory_title.text,"Inventory displays rebound slot and blanket keys")
 c.close_panels();var e:=InputEventKey.new();e.physical_keycode=KEY_J;e.keycode=KEY_J;e.pressed=true;root.push_input(e,true);await frames();e=e.duplicate();e.pressed=false;root.push_input(e,true);await frames()
 check(c.active==c.slots[0],"Rebound key equips the item in its rearranged slot")
 c.show_inventory();c.buttons[0].grab_focus();await frames()
 var first:String=c.layout[0];var second:String=c.layout[1]
 for code in [JOY_BUTTON_A,JOY_BUTTON_RIGHT_SHOULDER,JOY_BUTTON_A]:
  var pad:=InputEventJoypadButton.new();pad.button_index=code;pad.pressed=true;Input.parse_input_event(pad);await frames();pad=pad.duplicate();pad.pressed=false;Input.parse_input_event(pad);await frames()
 check(c.layout[1]==first and c.layout[0]==second,"Actual Cross, R1, Cross events pick/navigate/swap controller inventory")
 c.handle_inventory_button(JOY_BUTTON_DPAD_LEFT);check(root.gui_get_focus_owner()==c.buttons[0],"D-pad navigates inventory without changing music")
 c.handle_inventory_button(JOY_BUTTON_A);check(c.swap_from==0,"Cross keeps source slot selected before destination choice")
 c.handle_inventory_button(JOY_BUTTON_DPAD_DOWN);c.handle_inventory_button(JOY_BUTTON_A);check(c.swap_from==-1,"D-pad Down navigates destination and Cross finishes swap inside inventory")
 c.close_panels()
 bindings.custom=previous;bindings.apply();campaign.checkpoint.clear();level.queue_free();await frames(8)
 print("INVENTORY_DRAG_DROP_RESULT: ",checks-failures.size(),"/",checks," passed")
 quit(0 if failures.is_empty() else 1)
