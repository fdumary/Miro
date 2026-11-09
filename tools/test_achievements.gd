extends "res://tools/test_intro.gd"
## Achievement event mappings, persistent-in-session artwork and the two-tab menu.
func run() -> void:
	var campaign = root.get_node("Campaign")
	campaign.session_unlocks = []
	campaign.achievements_earned.clear()
	campaign.achievement_events.clear()
	campaign.viewed_art.clear()
	campaign.record_event("strangle")
	check(campaign.has_achievement("strangle_1"), "Strangle event earns its achievement")
	check(campaign.unlocked_tracks().has("birthday_melody"), "Strangle achievement unlocks its beat")
	for index in range(3):
		campaign.record_event("c4_kill")
	check(campaign.has_achievement("c4_spree"), "C4 events count to their threshold")
	check(campaign.unlocked_tracks().has("project_dancehall_hard_af_2"), "C4 achievement unlocks its beat")
	campaign.view_art("A01")
	check(campaign.has_viewed_art("A01") and not campaign.has_viewed_art("A02"), "Viewed art is tracked separately")
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames(3)
	check(menu.page.find_child("AchievementsButton", true, false) != null, "Title calls the screen Achievements")
	menu.show_screen("achievements")
	await frames(2)
	var tabs: TabContainer = menu.page.find_child("Achievements", true, false)
	check(tabs != null and tabs.get_tab_title(0) == "Beats" and tabs.get_tab_title(1) == "Artwork", "Achievements has Beats and Artwork tabs")
	check(tabs.get_node("Artwork").get_child(0).get_child_count() == 27, "Artwork tab lists all 27 catalog works")
	menu.queue_free()
	print("ACHIEVEMENTS_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
