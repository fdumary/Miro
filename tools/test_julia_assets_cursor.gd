extends SceneTree
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_:String) -> void:
 checks+=1
 print("PASS: " if ok else "FAIL: ",label_)
 if not ok:failures.append(label_)
func mode_ok(c,want:int) -> bool:
 return c.cursor_hidden==(want==Input.MOUSE_MODE_HIDDEN) and (DisplayServer.get_name()=="headless" or Input.mouse_mode==want)
func frames(n:=4) -> void:
 for i in range(n):await process_frame
func run() -> void:
 var art=load("res://scripts/weapon_art.gd")
 check(art.TEXTURES.shank.resource_path=="res://assets/weapons/julia_knife.png","HUD and equipped knife share Julia's blade texture")
 var knife:Image=art.TEXTURES.shank.get_image();check(knife.get_size()==Vector2i(12,12),"Knife retains native pixel dimensions")
 var allowed:bool=true;var opaque:=0
 for y in range(12):
  for x in range(12):
   var color:Color=knife.get_pixel(x,y)
   if color.a>0:
    opaque+=1
    allowed=allowed and color.to_html() in ["0e0d16ff","888691ff","a9a9acff"]
 check(allowed and opaque==50,"Julia knife contains only its 50 original edge/metal pixels, no body pixels")
 var original:Image=load("res://assets/characters/miro_attack.png").get_image();original.convert(Image.FORMAT_RGBA8)
 for y in range(original.get_height()):
  for x in range(original.get_width()):
   if original.get_pixel(x,y).a==0:original.set_pixel(x,y,Color(0,0,0,0))
 var context:=HashingContext.new();context.start(HashingContext.HASH_SHA256);context.update(original.get_data())
 check(context.finish().hex_encode()=="06436376bf59b4c1b9458f4510fdd20c8d2b9f1f3ff9e0687b7f8ffc4b70e4f9","Original Julia attack pixels remain identical after import/export")
 var tiles:TileSet=load("res://assets/environment/prison_tiles.tres")
 for entry in [[0,"standard_tile.png"],[1,"cracked_tile.png"],[2,"connector.png"]]:
  check(tiles.get_source(entry[0]).texture.resource_path.ends_with(entry[1]),"Gameplay tiles use Julia's "+entry[1])
 var level=load("res://scenes/levels/level_02.tscn").instantiate();root.add_child(level);current_scene=level;await frames(8);level.finish_dialogue()
 for g in level.guards():g.set_physics_process(false)
 level.player.set_physics_process(false);var c=level.player.controls
 if DisplayServer.get_name()=="headless":
  level.queue_free();await frames(8);print("JULIA_ASSETS_CURSOR_RESULT: ",checks-failures.size(),"/",checks," passed (asset checks; cursor checks require native Windows)");quit(0 if failures.is_empty() else 1);return
 if DisplayServer.get_name()!="headless":
  DisplayServer.window_move_to_foreground();await create_timer(.5).timeout
 c.update_mouse_cursor();check(mode_ok(c,Input.MOUSE_MODE_HIDDEN),"Gameplay hides pointer without requiring aim")
 level.start_dialogue([["MIRO","Dialogue cursor regression."]]);c.update_mouse_cursor();check(mode_ok(c,Input.MOUSE_MODE_HIDDEN),"Spoken gameplay dialogue keeps pointer hidden")
 level.player.in_hiding_spot=true;c.update_mouse_cursor();check(mode_ok(c,Input.MOUSE_MODE_HIDDEN),"Hiding inside a crate keeps pointer hidden");level.player.in_hiding_spot=false
 c.show_inventory();c.update_mouse_cursor();check(mode_ok(c,Input.MOUSE_MODE_VISIBLE),"Interactive inventory restores pointer");c.close_panels()
 c.has_remote=true;c.show_console(false);c.update_mouse_cursor();check(mode_ok(c,Input.MOUSE_MODE_VISIBLE),"Interactive terminal restores pointer");c.close_panels()
 var bindings=root.get_node("InputBindings");bindings.open();c.update_mouse_cursor();check(mode_ok(c,Input.MOUSE_MODE_VISIBLE),"Binding settings restore pointer");bindings.close();await frames()
 level.paused=true;c.update_mouse_cursor();check(mode_ok(c,Input.MOUSE_MODE_VISIBLE),"Pause restores pointer");level.paused=false
 c.cursor_hidden=true;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;c.update_mouse_cursor();check(mode_ok(c,Input.MOUSE_MODE_HIDDEN),"Cursor policy repairs a stale mode after window changes")
 if DisplayServer.get_name()!="headless":
  for window_mode in [DisplayServer.WINDOW_MODE_WINDOWED,DisplayServer.WINDOW_MODE_FULLSCREEN]:
   DisplayServer.window_set_mode(window_mode);DisplayServer.window_move_to_foreground();await create_timer(.4).timeout;c.update_mouse_cursor()
   check(mode_ok(c,Input.MOUSE_MODE_HIDDEN),"Native dialogue hides pointer in window mode "+str(window_mode))
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
  if is_instance_valid(level.card):level.card.finish()
  level.finish_dialogue();level.player.update_visual(.016);level.player.queue_redraw();await frames(4);await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("C:/Users/ethan/Miro/tmp/julia-assets-fix/knife-native.png")
 level.queue_free();await frames(8);print("JULIA_ASSETS_CURSOR_RESULT: ",checks-failures.size(),"/",checks," passed");quit(0 if failures.is_empty() else 1)
