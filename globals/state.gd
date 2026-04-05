class_name GameState
extends Node

const LEVEL_COUNT: int = 4
const LEVEL_SCENES: Dictionary = {
	1: "res://scenes/levels/tutorial/tutorial-level.tscn",
	2: "res://scenes/levels/level1.tscn",
	3: "res://scenes/levels/level2.tscn",
	4: "res://scenes/enemies/enemies-level.tscn",
}
const _NOT_STARTED_TICK: int = -1

var current_level: int = 1
var _stars_by_level: Array[int] = [0, 0, 0, 0]
var _time_by_level_seconds: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _start_tick_by_level: Array[int] = [_NOT_STARTED_TICK, _NOT_STARTED_TICK, _NOT_STARTED_TICK, _NOT_STARTED_TICK]

func get_current_level_scene() -> String:
	return LEVEL_SCENES.get(current_level, "")


func _is_valid_level(level: int) -> bool:
	return level >= 1 and level <= LEVEL_COUNT


func _to_index(level: int) -> int:
	return level - 1


func start_level(level: int = -1) -> void:
	if level == -1:
		level = current_level

	if not _is_valid_level(level):
		push_warning("start_level: level must be between 1 and %d" % LEVEL_COUNT)
		return

	_start_tick_by_level[_to_index(level)] = Time.get_ticks_msec()


func end_level() -> float:
	var index: int = _to_index(current_level)
	var start_tick: int = _start_tick_by_level[index]
	var elapsed_seconds: float = (Time.get_ticks_msec() - start_tick) / 1000.0
	_set_level_time_seconds(current_level, elapsed_seconds)
	_start_tick_by_level[index] = _NOT_STARTED_TICK
	current_level += 1
	return elapsed_seconds


func record_star() -> void:
	_stars_by_level[_to_index(current_level)] += 1

func get_level_stars(level: int = -1) -> int:
	if level == -1:
		level = current_level

	if not _is_valid_level(level):
		push_warning("get_level_stars: level must be between 1 and %d" % LEVEL_COUNT)
		return 0

	return _stars_by_level[_to_index(level)]


func _set_level_time_seconds(level: int, time_seconds: float) -> void:
	if not _is_valid_level(level):
		push_warning("_set_level_time_seconds: level must be between 1 and %d" % LEVEL_COUNT)
		return

	_time_by_level_seconds[_to_index(level)] = max(0.0, time_seconds)


func get_level_time_seconds(level: int = -1) -> float:
	if level == -1:
		level = current_level

	if not _is_valid_level(level):
		push_warning("get_level_time_seconds: level must be between 1 and %d" % LEVEL_COUNT)
		return 0.0

	return _time_by_level_seconds[_to_index(level)]


func get_level_result(level: int = -1) -> Dictionary:
	if level == -1:
		level = current_level

	return {
		"stars": get_level_stars(level),
		"time_seconds": get_level_time_seconds(level)
	}


func get_total_stars() -> int:
	var total: int = 0
	for stars: int in _stars_by_level:
		total += stars
	return total


func reset_progress() -> void:
	current_level = 1
	_stars_by_level = [0, 0, 0, 0]
	_time_by_level_seconds = [0.0, 0.0, 0.0, 0.0]
	_start_tick_by_level = [_NOT_STARTED_TICK, _NOT_STARTED_TICK, _NOT_STARTED_TICK, _NOT_STARTED_TICK]

func reset_current_level() -> void:
	_stars_by_level[_to_index(current_level)] = 0
	start_level(current_level)
