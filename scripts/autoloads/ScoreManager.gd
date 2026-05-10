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
var _play_score: int = 0

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
	_play_score = current_score
	var bonus := POINTS_LEVEL_COMPLETE
	if not took_damage_this_level:
		bonus += POINTS_LEVEL_NO_DAMAGE
	add_points(bonus)
	return current_score

func get_level_breakdown() -> Dictionary:
	return {
		"play": _play_score,
		"complete_bonus": POINTS_LEVEL_COMPLETE,
		"no_damage_bonus": (0 if took_damage_this_level else POINTS_LEVEL_NO_DAMAGE),
		"total": current_score,
	}

func reset_level() -> void:
	current_score = 0
	coin_count = 0
	took_damage_this_level = false
	_play_score = 0
