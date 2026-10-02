extends CharacterBody3D

@export var speed:float = 5.0
@export var rotation_speed:float = 5.0
const JUMP_VELOCITY:float = 4.5

@export var weapon_manager:weapon_node
var current_weapon:weapon_base

@export var weapon:weapon_node.weapons

var has_target_pos:bool = true
var target_pos
var can_see_player:bool = false

var first_shots:bool = true
var shot_count:int = 0

@onready var sightline_ray_cast: RayCast3D = $SightlineRayCast

@export var player:CharacterBody3D
var last_known_pos:Vector3

# ==== NODES ==== #
@onready var health: health_node = $Health
@onready var hurt_box: hurtbox_node = $hurt_box
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
  weapon_manager.set_weapon(weapon)

## PATHFINDING AND MOVEMENT
func _physics_process(delta: float) -> void:
  # Add the gravity.
  if !is_on_floor(): velocity += get_gravity() * delta
 
  sightline_check()
  move_character(delta)
  shoot_check()

## Cecks to see if the agent can see the player
func sightline_check():
  sightline_ray_cast.look_at(player.position)

  if sightline_ray_cast.is_colliding():
    var collider = sightline_ray_cast.get_collider()
    if collider == player: 
      if player.position.distance_to(self.position) <= 150:
        can_see_player = true
    else: 
      can_see_player = false
      first_shots = true
      shot_count = 0

## handle the agents movement
func move_character(delta:float):
  if has_target_pos && can_see_player:
    # Move to target position
    
    var path_pos = nav_agent.get_next_path_position()
    var dir = global_position.direction_to(path_pos)
    
    # if can see the player move to player, otherwise goto player's last know pos
    if can_see_player:   
      if global_position.distance_to(player.position) > weapon_manager.weapon_stats.prefered_distance: nav_agent.target_position = player.position
      else: nav_agent.target_position = global_position
      last_known_pos = player.position
    else:
      nav_agent.target_position = last_known_pos

    # rotate towards movement
    var rotate_towards = global_position.direction_to(player.position).signed_angle_to(Vector3.MODEL_FRONT, Vector3.DOWN)
    rotation.y = lerp_angle(rotation.y, rotate_towards, delta * rotation_speed) 
    
    nav_agent.set_velocity(dir * speed)
    
    weapon_manager.bullet_origin.look_at(player.position)

func shoot_check():
  if global_position.distance_to(player.position) < weapon_manager.weapon_stats.maximum_distance && weapon_manager.weapon_stats.can_shoot && can_see_player:
    if shot_count >= weapon_manager.weapon_stats.shots_until_accuracy: first_shots = false
    else: 
      shot_count += 1
    
    if first_shots:
      weapon_manager.shoot(0.1)
    else: weapon_manager.shoot()
    

func circle_player_movement(delta):
  Vector3(player.position.x, player.position.y, player.position.z)
  
## CHANGES VELOCITY TO AVOID COLLISIONS WITH OTHER AGENTS
func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
  velocity = velocity.move_toward(safe_velocity, 1)
  move_and_slide()
