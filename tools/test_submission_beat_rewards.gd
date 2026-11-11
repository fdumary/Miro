extends SceneTree
const Saved=preload("res://scripts/campaign.gd")
class Session:
 extends Saved
 func can_persist() -> bool:return false
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+label_)
func run() -> void:
 var campaign=Session.new();root.add_child(campaign)
 var definitions=JSON.parse_string(FileAccess.get_file_as_string("res://data/achievements.json")).achievements
 var director=root.get_node("MusicDirector")
 for pair in [["ghost_1","pinkghost"],["guard_trapdoor","dancehall"]]:
  check(campaign.unlock_achievement(pair[0]),"Achievement earns once")
  check(campaign.unlocked_tracks().has(pair[1]),"Reward unlocks immediately")
  check(director.catalog.has(pair[1]) and load(director.catalog[pair[1]].stream) is AudioStream,"Reward audio is playable")
  var entry={"track":pair[1],"achievement_id":pair[0]}
  var label=load("res://scripts/menu_screens.gd").requirement(entry,definitions)
  check(label!="achievement" and label!=pair[1],"Menu describes specific achievement")
 campaign.session_unlocks.clear()
 check(campaign.unlocked_tracks().has("pinkghost") and campaign.unlocked_tracks().has("dancehall"),"Existing earned achievements repair missing rewards")
 print("SUBMISSION_BEAT_REWARDS_RESULT: ",checks-failures,"/",checks," passed")
 quit(0 if failures==0 else 1)
