extends Node

const POINTS_ENEMY_JUMP: int    = 10
const POINTS_ENEMY_PUNCH: int   = 15
const POINTS_BOSS: int          = 100
const POINTS_COIN: int          = 1
const POINTS_SPECIAL_BLOCK: int = 5
const POINTS_LEVEL_COMPLETE: int   = 50
const POINTS_LEVEL_NO_DAMAGE: int  = 25

var current_score: int = 0
var coin_count: int = 0
var took_damage_this_level: bool = false

signal score_changed(new_score: int)
signal coin_collected(total_coins: int)

func add_points(amount: int) -> void:
	current_score += amount
	score_changed.emit(current_score)

func add_coin() -> int:
	coin_count += 1
	add_points(POINTS_COIN)
	coin_collected.emit(coin_count)
	return coin_count

func register_damage() -> void:
	took_damage_this_level = true

func finalize_level() -> int:
	var bonus := 0
	if not took_damage_this_level:
		bonus = POINTS_LEVEL_NO_DAMAGE
		add_points(POINTS_LEVEL_COMPLETE + bonus)
	else:
		add_points(POINTS_LEVEL_COMPLETE)
	return current_score

func reset_level() -> void:
	current_score = 0
	coin_count = 0
	took_damage_this_level = false
