extends CharacterBody3D

@export var speed:float = 5.0
@export var rotation_speed:float = 5.0
const JUMP_VELOCITY:float = 4.5

@export var weapon_manager:weapon_node
var current_weapon:weapon_base

@export var weapon:weapon_node.weapons

var has_target_pos:bool = true
var target_pos

@export var player:CharacterBody3D

# ==== NODES ==== #
@onready var health: health_node = $Health
@onready var hurt_box: hurtbox_node = $hurt_box
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
  weapon_manager.set_weapon(weapon)

func _physics_process(delta: float) -> void:
  # Add the gravity.
  if not is_on_floor():
    velocity += get_gravity() * delta

  # Handle jump.
  #if Input.is_action_just_pressed("ui_accept") and is_on_floor():
    #velocity.y = JUMP_VELOCITY
    
  if has_target_pos:
      # Move to target position
      nav_agent.target_position = player.position
      var path_pos = nav_agent.get_next_path_position()
      var dir = global_position.direction_to(path_pos)
      
      velocity = dir * speed
      
      # rotate towards movement
      var rotate_towards = dir.signed_angle_to(Vector3.MODEL_FRONT, Vector3.DOWN)
      rotation.y = move_toward(rotation.y, rotate_towards, delta * rotation_speed)

  #move_and_slide()
  
func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
  velocity = velocity.move_toward(safe_velocity, 1)
  move_and_slide()
