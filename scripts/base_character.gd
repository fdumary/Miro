class_name BaseCharacter
extends CharacterBody2D

## Health is counted in half hearts: 6 is three full hearts.
@export var health: int = 6
@export var movement_speed: float = 140.0
var is_dead: bool = false
var invulnerability_left: float = 0.0

func take_damage(amount: int, ignore_recovery := false) -> void:
	if is_dead or (invulnerability_left > 0.0 and not ignore_recovery):
		return
	health = maxi(0, health - amount)
	invulnerability_left = 0.8
	if health == 0:
		die()

func die() -> void:
	is_dead = true
