extends CharacterBody2D
class_name Enemy

@export var speed: float = 100.0
@export var waypoints: Array[Vector2] = []  # Set in inspector or generate
@export var player: Node2D  # Reference to the player
@export var collide_with_walls: bool = false
@export_range(1, 32, 1) var wall_collision_layer: int = 1
@export var show_vision_debug: bool = true
@export var vision_range: float = 300.0
@export var overhead_vision_horizontal_tolerance: float = 64.0
@export var overhead_vision_vertical_tolerance: float = 120.0
@export var face_player_turn_threshold: float = 6.0

@onready var ray_cast: RayCast2D = $RayCast2D  # For vision
@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

var current_waypoint_index: int = 0
var is_patrolling: bool = true
var sees_player_now: bool = false
var facing_direction_x: int = 1

const DEFAULT_WAYPOINT_DISTANCE: int = 30

func _ready() -> void:
	if waypoints.is_empty():
		push_warning("Waypoints not set for enemy: %s" % name)
		waypoints.append(global_position - Vector2(DEFAULT_WAYPOINT_DISTANCE, 0)) 
		waypoints.append(global_position + Vector2(DEFAULT_WAYPOINT_DISTANCE, 0)) 

	set_collision_mask_value(wall_collision_layer, collide_with_walls)

	if ray_cast:
		ray_cast.enabled = true

	if anim:
		anim.play("walk")

func _physics_process(delta: float) -> void:
	_update_facing_for_overhead_player()
	sees_player_now = can_see_player()

	if is_patrolling:
		patrol()
	else:
		attack()  # Override in subclasses

	update_facing_direction()
	move_and_slide()

func _process(delta: float) -> void:
	queue_redraw()

func patrol() -> void:
	if waypoints.is_empty():
		velocity = Vector2.ZERO
		return

	var target = waypoints[current_waypoint_index]
	var direction = (target - global_position).normalized()
	velocity = direction * speed
	
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
	if anim:
		anim.flip_h = facing_direction_x > 0

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
	if anim:
		anim.flip_h = facing_direction_x > 0

func attack() -> void:
	pass  
