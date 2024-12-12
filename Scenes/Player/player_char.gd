class_name player_char
extends CharacterBody3D

# === consts === #
const COYOTE_TIME:float = 0.25

# === movement === #
var current_move_speed:float = 5.0
var move_speed:float = 5.0
var sprint_speed:float = 10.0
var look_speed:float = 0.03
# === jumps === #
var jump_velocity:float = 4.5
var fall_acceleration:float = 2.0
var total_jumps:int = 1
var available_jumps:int = 1
# === state bools === #
var is_sliding:bool = false

@onready var head = $Head
@onready var camera = $Head/Camera3D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
  if event is InputEventMouseMotion:
    head.rotate_y(-event.relative.x * look_speed)
    camera.rotate_x(-event.relative.y * look_speed)
    camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(85))

func _physics_process(delta):
  # Add the gravity.
  if !is_on_floor():
    velocity.y -= gravity * delta

  # Handle jump.
  if Input.is_action_just_pressed("jump") && is_on_floor():
    velocity.y = jump_velocity
  
  if Input.is_action_pressed("sprint") && (is_on_floor() || is_on_wall_only()): current_move_speed = sprint_speed
  else: current_move_speed = move_speed

  # Get the input direction and handle the movement/deceleration.
  # As good practice, you should replace UI actions with custom gameplay actions.
  var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
  var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
  if direction:
    velocity.x = direction.x * current_move_speed
    velocity.z = direction.z * current_move_speed
  else:
    velocity.x = move_toward(velocity.x, 0, current_move_speed)
    velocity.z = move_toward(velocity.z, 0, current_move_speed)

  move_and_slide()
