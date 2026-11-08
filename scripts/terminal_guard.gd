extends IntroGuard
class_name TerminalGuard
## A Keeper posted at a terminal: he never wanders more than a few steps from it, and walks
## straight back after any chase or search. Otherwise he is an ordinary Keeper.
const POST_RADIUS := 34.0
var post_x := 0.0

func post_at(x: float) -> void:
	post_x = x
	patrol_left = x - POST_RADIUS
	patrol_right = x + POST_RADIUS
