extends SceneTree

class SavedCampaign:
	extends "res://scripts/campaign.gd"
	func can_persist() -> bool:
		return true
	func progress_path() -> String:
		return "res://tmp/completion-regression.cfg"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var path := "res://tmp/completion-regression.cfg"
	DirAccess.make_dir_recursive_absolute("res://tmp")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var first := SavedCampaign.new()
	root.add_child(first)
	first.played_from_start = false
	first.complete_floor(5, true, {"BrotherEncounter": true})
	assert(not first.game_completed(), "Boss alone must not complete the ending")
	first.complete_floor(5, true, {"BrotherEncounter": true, "ForestViewpoint": true})
	assert(first.level_completed(5), "Resumed finale must mark Level 5 complete")
	first.free()
	var relaunched := SavedCampaign.new()
	root.add_child(relaunched)
	assert(relaunched.game_completed(), "Completion must survive a fresh campaign instance")
	assert(relaunched.level_completed(5), "Level 5 checkmark must survive relaunch")
	assert(relaunched.highest_level() == 5, "Level unlocks must remain intact")
	relaunched.free()
	DirAccess.remove_absolute(path)
	print("COMPLETION_PERSISTENCE_RESULT: 5/5 passed")
	quit()
