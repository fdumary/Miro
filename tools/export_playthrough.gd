extends Node
# QA-only exported runner. Executes actual scene transitions without changing player/guard positions.
var level
var failures: Array[String] = []
var checks := 0

func _ready() -> void:
 call_deferred("run")

func frames(count: int = 1) -> void:
 for i in range(count):
  await get_tree().physics_frame
  await get_tree().process_frame

func check(condition: bool, description: String) -> void:
 checks += 1
 if not condition:
  failures.append(description)
  push_error("FAIL: " + description)

func descend(count: int) -> void:
 Input.action_press("climb_down")
 await frames(count)
 Input.action_release("climb_down")

func next_floor(number: int) -> void:
 var press := InputEventAction.new()
 press.action = "advance"
 press.pressed = true
 Input.parse_input_event(press)
 await frames(4)
 press = InputEventAction.new()
 press.action = "advance"
 press.pressed = false
 Input.parse_input_event(press)
 level = get_tree().current_scene
 check(get_node("/root/Campaign").current_floor == number, "Enter advances to floor %d" % number)

func run() -> void:
 await frames(4)
 level = get_tree().current_scene
 level.finish_dialogue()
 level.interact()
 level.finish_dialogue()
 check(await move_to(240), "Reach cell lock")
 level.plant_c4()
 await frames(3)
 check(await move_to(385, 650, true), "Escape cell")
 check(await move_to(655, 650, true), "Reach brother voice")
 level.interact()
 level.finish_dialogue()
 check(await move_to(728, 300, true), "Reach first ladder")
 await descend(160)
 check(await move_to(308, 650, true), "Reach second ladder")
 await descend(190)
 check(await move_to(620, 650, true), "Reach first sigil")
 level.interact()
 level.finish_dialogue()
 check(await move_to(1030, 650, true), "Reach first exit")
 level.interact()
 check(level.completed and not level.player.is_dead, "Floor 1 completed alive")
 for number in range(2, 6):
  await next_floor(number)
  level.finish_dialogue()
  if number == 5:
   await foundation_run()
   check(level.completed and not level.player.is_dead, "Floor 5 completed alive")
   continue
  for station in level.definition.stations:
   if level.milestones.has(station.id):
    continue
   var point := Vector2(station.position[0], station.position[1])
   if point.y > 300 and level.player.position.y < 300:
    check(await move_to(level.get_node("Interactables/FirstLadder").position.x, 800, true), "Reach first ladder")
    await descend(170)
   if point.y >= 550 and level.player.position.y < 550:
    check(await move_to(308, 800, true), "Reach second ladder")
    await descend(190)
   check(await move_to(point.x, 800, true), "Reach " + station.id)
   await frames(10)
   level.interact()
   if station.id == "RemoteTerminal":
    level.world_features.submit_password("root")
    await frames(65)
   if station.id == "BrotherEncounter":
    await fight_brother()
   if station.id == "ForestViewpoint":
    await frames(850)
   else:
    level.finish_dialogue()
   check(level.milestones.has(station.id), "Complete " + station.id)
  if number < 5:
   check(await move_to(1030, 800, true), "Reach exit")
   level.interact()
  check(level.completed and not level.player.is_dead, "Floor %d completed alive" % number)
 var campaign = get_node("/root/Campaign")
 check(campaign.completed_sigils.size() == 5, "All five sigils committed")
 check(campaign.boss_defeated and campaign.ending_complete, "Boss and watched ending completed")
 print("EXPORTED_PLAYTHROUGH_RESULT: ", checks - failures.size(), "/", checks, " passed")
 get_tree().quit(0 if failures.is_empty() else 1)

func move_to(x: float, limit: int = 500, fight: bool = false) -> bool:
 var p = level.player
 var count := 0
 while absf(p.position.x - x) > 5 and count < limit and not p.is_dead:
  var right: bool = x > p.position.x
  Input.action_press("move_right" if right else "move_left")
  Input.action_release("move_left" if right else "move_right")
  if (p.is_on_wall() and p.is_on_floor()) or (p.is_on_wall() and not p.is_on_floor() and p.jumps_used == 1 and p.velocity.y > -20):
   Input.action_press("jump")
  else:
   Input.action_release("jump")
  if fight:
   for g in level.guards():
    if not g.is_dead and p.position.distance_to(g.position) < 44:
     p.facing = signf(g.position.x - p.position.x)
     p.shank()
  await frames(1)
  count += 1
 Input.action_release("move_left")
 Input.action_release("move_right")
 Input.action_release("jump")
 for i in range(40):
  if p.is_on_floor() or p.climbing:
   break
  await frames(1)
 await frames(2)
 print("MOVE target=", x, " actual=", p.position, " hp=", p.health)
 return absf(p.position.x - x) <= 8

func fight_brother(until_retreat := false) -> void:
 var boss = level.brother
 level.player.controls.select_item("shank")
 for tick in range(2400):
  if not is_instance_valid(boss) or boss.is_dead or level.player.is_dead or (until_retreat and boss.current_phase == boss.Phase.RETREAT):
   break
  var offset: float = boss.position.x - level.player.position.x
  Input.action_release("move_left")
  Input.action_release("move_right")
  if boss.is_vulnerable:
   if absf(offset) > 32:
    Input.action_press("move_right" if offset > 0 else "move_left")
   level.player.facing = signf(offset)
   level.player.shank()
  else:
   if absf(offset) < 75:
    Input.action_press("move_left" if offset > 0 else "move_right")
   if boss.current_phase == boss.Phase.RUSH and absf(offset) < 80:
    Input.action_press("jump")
  if boss.projectile_live and boss.projectile.distance_to(level.player.position) < 100:
   Input.action_press("jump")
  await frames(1)
  Input.action_release("jump")
 Input.action_release("move_left")
 Input.action_release("move_right")
 check(not level.player.is_dead and (until_retreat or boss.is_dead), "Beat Niro back using movement and shank")

## Level 5: guitar > waves > Niro x3 > final fight, with real movement, ladders and shank.
func foundation_run() -> void:
 var flow = level.flow
 check(await move_to(300, 600, true), "Reach the final sigil")
 level.interact()
 level.finish_dialogue()
 check(await move_to(190, 300, true), "Reach the guitar")
 level.interact()
 level.finish_dialogue()
 check(level.player.controls.has_guitar, "Guitar taken")
 var ladders := [[728, 170], [308, 190], [952, 200]]
 for engagement in range(1, 5):
  for wait in range(400):
   if is_instance_valid(level.brother) and not level.brother.is_dead and level.brother.engagement >= engagement:
    break
   if flow.step == flow.Step.WAVE:
    for guard in flow.wave_guards:
     if is_instance_valid(guard) and not guard.is_dead and not guard.asleep:
      level.player.position.x = guard.position.x - 40
      level.player.controls.strum_cooldown = 0
      level.player.controls.select_item("guitar")
      level.player.controls.strum()
   await frames(1)
  check(is_instance_valid(level.brother), "Niro meeting %d" % engagement)
  level.finish_dialogue()
  await fight_brother(engagement < 4)
  if engagement < 4:
   await frames(70)
   var ladder: Array = ladders[engagement - 1]
   check(await move_to(ladder[0], 900, true), "Reach hatch %d" % engagement)
   Input.action_press("climb_down")
   await frames(ladder[1])
   Input.action_release("climb_down")
   await frames(30)
 level.finish_dialogue()
 check(level.milestones.has("DefeatExchange"), "Complete DefeatExchange")
 check(await move_to(880, 800, true), "Reach ForestViewpoint")
 level.interact()
 await frames(850)
 check(level.milestones.has("ForestViewpoint"), "Complete ForestViewpoint")
