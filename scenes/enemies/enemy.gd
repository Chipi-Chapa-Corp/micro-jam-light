extends CharacterBody2D
class_name Enemy

@export_group("Movement")
@export var speed: float = 100.0
@export_range(0, 6, 0.5) var waypoint_block_count_left: float = 0
@export_range(0, 6, 0.5) var waypoint_block_count_right: float = 0
@export var waypoint_block_size: float = 32.0 # 1 tile size
@export var default_face_right: bool = true

@export_group("Gameplay")
@export var player: Node2D  # Reference to the player
@export var collide_with_walls: bool = false
@export_range(1, 32, 1) var wall_collision_layer: int = 1

@export_group("Vision")
@export var show_vision_debug: bool = false
@export var vision_range: float = 352.0
@export var overhead_vision_horizontal_tolerance: float = 64.0
@export var overhead_vision_vertical_tolerance: float = 120.0
@export var face_player_turn_threshold: float = 6.0

@onready var ray_cast: RayCast2D = $RayCast2D  # For vision
@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

var stationary_can_turn_around: bool = true
var current_waypoint_index: int = 0
var is_patrolling: bool = true
var sees_player_now: bool = false
var facing_direction_x: int = 1
var waypoints: Array[Vector2] = [] 
var is_stationary: bool = true
var turn_timer: float = 0.0

const DEFAULT_WAYPOINT_DISTANCE: int = 30

func _ready() -> void:
	_initialize_waypoints()
	facing_direction_x = 1 if default_face_right else -1

	set_collision_mask_value(wall_collision_layer, collide_with_walls)

	if ray_cast:
		ray_cast.enabled = true

	if anim:
		_apply_facing_visual()
		anim.play("idle" if is_stationary else "walk")

func _initialize_waypoints() -> void:
	if waypoint_block_count_left == 0 and waypoint_block_count_right == 0:
		is_stationary = true
		return

	is_stationary = false
	_append_block_boundary_waypoints()

func _append_block_boundary_waypoints() -> void:
	if waypoint_block_count_left >= 0:
		var left_waypoint := global_position - Vector2(waypoint_block_count_left * waypoint_block_size, 0)
		if not waypoints.has(left_waypoint):
			waypoints.append(left_waypoint)

	if waypoint_block_count_right >= 0:
		var right_waypoint := global_position + Vector2(waypoint_block_count_right * waypoint_block_size, 0)
		if not waypoints.has(right_waypoint):
			waypoints.append(right_waypoint)

func _handle_stationary_behavior(delta: float) -> void:
	if anim:
		anim.play("idle")
	if not stationary_can_turn_around:
		return
	turn_timer += delta
	if turn_timer >= 3.0:
		facing_direction_x = -facing_direction_x
		_apply_facing_visual()
		turn_timer = 0.0

func _physics_process(_delta: float) -> void:
	if not is_stationary:
		_update_facing_for_overhead_player()
	sees_player_now = can_see_player()

	if is_stationary:
		_handle_stationary_behavior(_delta)

	if is_patrolling:
		patrol()
	else:
		attack()  # Override in subclasses

	update_facing_direction()
	move_and_slide()
	_check_player_collision()

func _check_player_collision() -> void:
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage()
			break

func _process(_delta: float) -> void:
	queue_redraw()

func patrol() -> void:	
	if is_stationary or waypoints.is_empty():
		velocity = Vector2.ZERO
		if anim:
			anim.play("idle")
		return

	var target = waypoints[current_waypoint_index]
	var direction = (target - global_position).normalized()
	velocity = direction * speed
	
	if anim:
		anim.play("walk")
	
	if global_position.distance_to(target) < 10:  
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()

func can_see_player() -> bool:
	var current_player := _get_player()
	if current_player == null or ray_cast == null:
		return false

	var to_player := current_player.global_position - global_position
	if to_player.length_squared() > vision_range * vision_range:
		return false

	var is_player_in_overhead_zone: bool = \
		abs(to_player.x) <= overhead_vision_horizontal_tolerance \
		and abs(to_player.y) <= overhead_vision_vertical_tolerance

	if not is_player_in_overhead_zone and abs(to_player.x) > 0.01 and sign(to_player.x) != facing_direction_x:
		return false

	ray_cast.target_position = ray_cast.to_local(current_player.global_position)
	ray_cast.force_raycast_update()

	if not ray_cast.is_colliding():
		return false

	return ray_cast.get_collider() == current_player

func _update_facing_for_overhead_player() -> void:
	var current_player := _get_player()
	if current_player == null:
		return

	var to_player := current_player.global_position - global_position
	var is_player_in_overhead_zone: bool = \
		abs(to_player.x) <= overhead_vision_horizontal_tolerance \
		and abs(to_player.y) <= overhead_vision_vertical_tolerance

	if not is_player_in_overhead_zone or abs(to_player.x) <= face_player_turn_threshold:
		return

	facing_direction_x = int(sign(to_player.x))
	_apply_facing_visual()

func _draw() -> void:
	if not show_vision_debug:
		return

	var current_player := _get_player()
	if current_player == null:
		return

	var player_local_pos := to_local(current_player.global_position)
	var line_color := Color.GREEN if sees_player_now else Color.RED
	draw_line(Vector2.ZERO, player_local_pos, line_color, 3.0)

func _get_player() -> Node2D:
	if is_instance_valid(player):
		return player

	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null

	player = players[0] as Node2D
	return player

func update_facing_direction() -> void:
	if abs(velocity.x) <= 0.01:
		return

	facing_direction_x = int(sign(velocity.x))
	_apply_facing_visual()

func attack() -> void:
	pass  

func _apply_facing_visual() -> void:
	if anim:
		# Source sprite faces left by default, so flip to look right.
		anim.flip_h = facing_direction_x > 0
