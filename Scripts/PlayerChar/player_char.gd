class_name player_char
extends CharacterBody3D

# === consts === #
const COYOTE_TIME:float = 0.25

# === movement === #
var direction:Vector3 = Vector3.ZERO
var max_run_speed:float = 5.0
var max_sprint_speed:float = 8.0
var max_wall_speed:float = 8.0
var slide_speed_boost:float = 30.0

var ground_accel:float = 14.0
var ground_deccel:float = 13.0

var norm_deccel:float = 13.0
var slide_deccel:float = 18.0

var air_accel:float = 4.0
var air_speed = 28.0

var look_speed:float = 0.01

# === grapple === #
@onready var grapple_cooldown_timer = $GrappleCooldownTimer

var grapple_distance:float = 20.0
var grapple_cooldown_time:float = 0.5
var grapple_speed:float = 200.0
var can_grapple:bool = true
var grapple_vector:Vector3 = Vector3.ZERO
var grapple_point:Vector3 = Vector3.ZERO

# === jumps === #
var jump_velocity:float = 12.0
var fall_acceleration:float = 3.0
var total_jumps:int = 1
var available_jumps:int = 1
var wall_normal:Vector3 = Vector3.ZERO
var ground_normal:Vector3 = Vector3.ZERO
# === state bools === #
var is_sliding:bool = false
var is_on_wall:bool = false
var is_grappling:bool = false
var is_crouched:bool = false

# === juice === #
var wallrun_tilt_angle:float = 25

# === raycasts === #
@onready var grapple_cast = $Head/Camera3D/RayCast3D
@onready var wallrun_shape_cast = $WallRunShapeCast
@onready var grounding_ray: RayCast3D = $GroundingRayCast3D

# === Objects === #
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var coyote_timer = $CoyoteTimer
@onready var slide_cooldown_timer = $SlideCooldownTimer

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Handles the mouse looking
func _input(event):
  if event is InputEventMouseMotion:
    head.rotate_y(-event.relative.x * look_speed)
    camera.rotate_x(-event.relative.y * look_speed)
    camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(85))

func _physics_process(delta): 
  manage_input()
  on_wall_check()
  
  # Apply ground movement
  if is_on_floor() || is_on_wall: 
    if available_jumps != total_jumps: available_jumps = total_jumps
    
    if wallrun_shape_cast.is_colliding(): press_to_wall(delta) ## ADD SLIDING DOWN WALL WHENNOT MOVING
    
    if !is_on_wall:
      crouch_slide(delta)
      slope_stick(delta) 
    
    handle_movement(delta)
  elif !is_on_floor() || !is_on_wall:
    handle_air_strafe(delta)
    apply_gravity(delta) # Add the gravity.
   
  if Input.is_action_just_pressed("grapple") && can_grapple: set_grapple()
  
  if Input.is_action_pressed("grapple") && can_grapple && is_grappling: grapple_pull(delta)
  elif Input.is_action_just_released("grapple") && is_grappling: grapple_end()
    
  handle_jump()
  #juice()
  if Input.is_action_just_released("slide"):
    ground_deccel = norm_deccel
    crouch_char(false)
    slide_cooldown_timer.start()
    
  move_and_slide()

func apply_gravity(delta):
  if !is_on_floor() && !is_on_wall:
    if velocity.y < 0: velocity.y -= (fall_acceleration + gravity) * delta
    else: velocity.y -= gravity * delta
    
# Allows players to slide down slodes
func slope_stick(delta):
  var _normal = grounding_ray.get_collision_normal()
  if _normal.y == 1.0: 
    up_direction = Vector3.UP
    return # don't need to stick if surface is flat
  up_direction = _normal
  self.velocity += _normal * 10 * delta
  #var transform:Transform3D = global_transform
    
# Handles jump input and physics
func handle_jump():
  if Input.is_action_just_pressed("jump") && available_jumps > 0 && is_on_floor():
    available_jumps -= 1
    velocity.y += jump_velocity
  elif Input.is_action_just_pressed("jump") && is_on_wall:
    velocity += wall_normal * jump_velocity
    velocity.y += jump_velocity

func on_wall_check():
  if wallrun_shape_cast.is_colliding() && !is_on_wall && !is_on_ceiling():
    is_on_wall = true
    wall_normal = wallrun_shape_cast.get_collision_normal(0)
  elif !wallrun_shape_cast.is_colliding() && is_on_wall:
    is_on_wall = false
    wall_normal = Vector3.ZERO

# Gets the desired speed of the character
func get_movement_speed() -> float:
  if Input.is_action_pressed("sprint") && (is_on_floor() || is_on_wall): 
    return max_sprint_speed
  elif !Input.is_action_pressed("sprint") && (is_on_floor() || is_on_wall): 
    #current_move_speed = lerp(sprint_speed, move_speed, 0.5)
    return max_run_speed
  else: return max_run_speed
  
# Manage player input by checking the current input and setting the direction for later use
func manage_input():
  var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back") 
  if !is_on_wall:
    direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
  elif is_on_wall:
    direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    #direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    #var cross = direction.cross(wall_normal)
    #direction = cross

# This adds mommentmum to the character gradually to keep true to the original build that uses a Rigidbody
func handle_movement(delta):
  var speed_cap = get_movement_speed()
  if speed_cap > 0:
    var accel_speed = ground_accel * delta * get_movement_speed()
    accel_speed = min(accel_speed, speed_cap)
    #else: accel_speed = min(accel_speed, speed_cap) * 2
    self.velocity += accel_speed * direction
    
  # This adds friction to the character to slow them down while on the ground
  var control = max(self.velocity.length(), ground_deccel)
  var drop = control * delta
  var real_speed = max(self.velocity.length() - drop * 4, 0)
  if self.velocity.length() > 0:
    real_speed /= self.velocity.length()
  self.velocity *= real_speed

# allows for steering while in the air for more floaty air movement
func handle_air_strafe(delta):
  self.velocity += air_accel * direction * delta

# keeps the player moving toward the wall to allow wallrunning
func press_to_wall(delta):
  self.velocity += wall_normal * 2 * delta
 
# reduces the size of the player and grants a small speed boost with high friction 
func crouch_slide(delta):
  if Input.is_action_just_pressed("slide") && !is_sliding:
    is_sliding = true
    crouch_char()
    ground_deccel = slide_deccel
    velocity += slide_speed_boost * direction
    max(self.velocity.length(), ground_deccel)
    
  elif Input.is_action_just_released("slide"):
    ground_deccel = norm_deccel
    crouch_char(false)
    slide_cooldown_timer.start()

# kills a lot of x / z momentum and drastically increases downward momentum
func ground_pound(delta):
  if Input.is_action_just_pressed("slide") && !is_sliding && !is_on_floor():
    pass # change for special movement

# gets and sets initial point of grapple
func set_grapple():
  if grapple_cast.is_colliding():
    grapple_point = grapple_cast.get_collision_point()
    var grapple_dir = (grapple_point - self.position).normalized()
    var grapple_target_speed = grapple_dir * grapple_speed
  
    is_grappling = true

# determines what function is played when the grapple connects with a collision
func check_grapple_type():
  pass

# pulls player towards collision area
func grapple_pull(delta):
    var grapple_dir = (grapple_point - self.position).normalized()
    var grapple_target_speed = grapple_dir * grapple_speed
    grapple_vector = (grapple_target_speed - self.velocity)
    
    velocity += grapple_vector * delta

func grapple_end():
  can_grapple = false
  is_grappling = false
  grapple_cooldown_timer.start(grapple_cooldown_time)

func wallrun_juice():
  if is_on_wall: camera.rotation = Vector3(wallrun_tilt_angle, 0, wallrun_tilt_angle) * wall_normal
  else: camera.rotation = Vector3.ZERO
  
func crouch_char(is_crouched:bool = true):
  if is_crouched: scale.y = 0.5
  else: scale.y = 1

# === timers === #
func _on_slide_cooldown_timer_timeout():
  is_sliding = false
  slide_cooldown_timer.stop()

func _on_grapple_cooldown_timer_timeout():
  can_grapple = true
  grapple_cooldown_timer.stop()
