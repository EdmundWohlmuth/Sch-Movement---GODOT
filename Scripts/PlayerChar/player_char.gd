class_name player_char
extends CharacterBody3D

# === consts === #
const COYOTE_TIME:float = 0.15

# === movement === #
var direction:Vector3 = Vector3.ZERO
var run_speed_cap:float = 8.0
var max_sprint_speed:float = 10.0

var slide_speed_boost:float = 30.0
var slide_slope_boost:float = 40.0

var ground_accel:float = 8.0
var ground_deccel:float = 4.0

var norm_deccel:float = 13.0
var slide_deccel:float = 4.0

var air_accel:float = 4.0

var look_speed:float = 0.01

# speed cap #
var wall_speed_cap:float = 20.0
var speed_cap:float
var no_speed_cap:float = 1000.0
var crouch_speed_cap:float = 5.0

# === jumps === #
var jump_velocity:float = 12.0
var fall_acceleration:float = 3.0
var base_fall_accel:float = 3.0
var slide_fall_accel:float = 10.0
var total_jumps:int = 1
var available_jumps:int = 1
var wall_normal:Vector3 = Vector3.ZERO
var ground_normal:Vector3 = Vector3.ZERO

# === state bools === # --TO BE REPLACED WITH ENUM SYSTEM--
var is_sliding:bool = false
var on_wall:bool = false
var has_gravity:bool = false

# align with floors & slopes --MAY BE REMOVED--
var xform:Transform3D
var is_down_slope:bool = false
var slide_up_deccel:float = 60.0

# === juice === #
var wallrun_tilt_angle:float = 15

# === raycasts === #
@onready var grapple_cast = $Head/Camera3D/RayCast3D
@onready var wallrun_shape_cast = $WallRunShapeCast
@onready var grounding_ray: RayCast3D = $GroundingRayCast3D
@onready var wall_left_cast: RayCast3D = $Head/WallLeftCast # fuck it
@onready var wall_right_cast: RayCast3D = $Head/WallRightCast # see above

var last_y:float = 0.0

# === Objects === #
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var coyote_timer = $CoyoteTimer
@onready var slide_cooldown_timer = $SlideCooldownTimer
@onready var bullet_origin: Node3D = $Head/Camera3D/Bullet_Origin
@onready var grapple_origin: Node3D = $Head/Camera3D/Grapple_Origin

#NODES
@export var weapon_manager:Node3D
@export var health:Node
@export var hurt_box:Node
@export var special_traverse:Node
@export var animation_control:Node

# STATES
enum states
{
  IDLE,
  RUNNING,
  WALL_RUNNING,
  CROUCH_MOVE,
  SLIDING,
  AIRBORNE,
  DEAD
}
@export var current_state:states = states.IDLE

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
  weapon_manager.is_player = true
  weapon_manager.controller = self
  weapon_manager.bullet_origin = bullet_origin
  up_direction = Vector3.UP

# Handles the mouse looking and specific Key Inputs
func _input(event):
  manage_input()
  
  if event is InputEventMouseMotion || event is InputEventJoypadMotion:
    head.rotate_y(-event.relative.x * look_speed)
    camera.rotate_x(-event.relative.y * look_speed)
    camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(85))
  
  if event is InputEventKey || event is InputEventJoypadButton:
    if event.is_action_pressed("slide"): 
      set_state(states.SLIDING)
      crouch_slide()
    if event.is_action_released("slide"): 
      end_slide() 
      if direction > Vector3.ZERO && current_state != states.AIRBORNE: set_state(states.IDLE)
      else: set_state(states.RUNNING)
    if event.is_action_pressed("jump"): 
      handle_jump()
    
# Sets Players current state and the values for those states
func set_state(state:states):
  if current_state == state: return
  on_state_end()
  
  match state:
    states.IDLE:
      current_state = states.IDLE
      speed_cap = 0
    states.RUNNING:
      current_state = states.RUNNING
      speed_cap = run_speed_cap
    states.WALL_RUNNING:
      current_state = states.WALL_RUNNING
    states.CROUCH_MOVE:
      current_state = states.CROUCH_MOVE
      speed_cap = crouch_speed_cap
    states.SLIDING:
      current_state = states.SLIDING
      speed_cap = run_speed_cap
    states.AIRBORNE:
      current_state = states.AIRBORNE
      speed_cap = run_speed_cap
      coyote_timer.start(COYOTE_TIME)
    states.DEAD:
      current_state = states.DEAD
   
  animation_control.play_anim(current_state)   
  #print(str(states.keys()[current_state]))
 
# Runs before changing the current state of the player 
func on_state_end():
  match current_state:
    states.IDLE:pass
    states.RUNNING:pass
    states.WALL_RUNNING:
      has_gravity = true
    states.CROUCH_MOVE:pass
    states.SLIDING:pass
    states.AIRBORNE: 
      #print("air end")
      has_gravity = false
    states.DEAD: pass

func _physics_process(delta):
  if Input.is_action_pressed("shoot"): handle_attack()
  on_wall_check()

  if !is_on_floor() && (current_state != states.AIRBORNE || (current_state != states.WALL_RUNNING)): set_state(states.AIRBORNE)
  
  # Grapple Hook movement
  special_traverse.start_special_move(delta) ##
  
  # Determines values to use in character movement based on players state
  match current_state:
    states.IDLE: deceleration(ground_deccel, delta)
    states.RUNNING: movement(delta)
    states.CROUCH_MOVE: movement(delta)
    states.SLIDING: movement(delta)
    states.AIRBORNE: 
      movement(delta)
      handle_air_strafe(delta)
      apply_gravity(delta)
    states.DEAD:pass
  
  move_and_slide()

# Makes it so the player 'sticks' to the ground
func align_to_floor():
  var floor_normal
  if !is_on_floor_only(): floor_normal = Vector3.UP
  else: floor_normal = grounding_ray.get_collision_normal()
  
  xform = global_transform
  xform.basis.y = floor_normal
  xform.basis.x = -xform.basis.z.cross(floor_normal)
  xform.basis = xform.basis.orthonormalized()
  
  if global_transform != xform: global_transform = global_transform.interpolate_with(xform, 0.15).orthonormalized()

# Apply ground movement
func movement(delta):
  if (is_on_floor() || on_wall): 
    if available_jumps != total_jumps: available_jumps = total_jumps
    
    if wallrun_shape_cast.is_colliding() && !is_on_floor(): press_to_wall(delta) ## ADD SLIDING DOWN WALL WHEN NOT MOVING
    
    handle_movement(delta)
  #elif !is_on_floor() || !on_wall:
    #handle_air_strafe(delta)
    #apply_gravity(delta) # Add the gravity.
  
  if is_ground_slope(): last_y = global_position.y

# Checks to see if Sliding has ended
func end_slide():
  if Input.is_action_just_released("slide"):
    ground_deccel = norm_deccel
    crouch_char(false)
    slide_cooldown_timer.start()

func apply_gravity(delta):
  if (!is_on_floor() && !on_wall) && has_gravity:
    if velocity.y < 0: velocity.y -= (fall_acceleration + gravity) * delta
    else: velocity.y -= gravity * delta
    
func handle_attack():    
  if Input.is_action_pressed("shoot") && weapon_manager.weapon_stats.is_full_auto && weapon_manager.weapon_stats.current_ammo > 0 && weapon_manager.weapon_stats.can_shoot: 
    weapon_manager.shoot()
    weapon_knockback()
  elif Input.is_action_just_pressed("shoot") && !weapon_manager.weapon_stats.is_full_auto && weapon_manager.weapon_stats.current_ammo > 0 && weapon_manager.weapon_stats.can_shoot:
    weapon_manager.shoot() 
    weapon_knockback()
    
# Handles jump input and physics
func handle_jump():
  has_gravity = true
  
  if Input.is_action_just_pressed("jump") && available_jumps > 0 && !on_wall && (is_on_floor() || has_gravity):
    available_jumps -= 1
    velocity.y += jump_velocity
  elif Input.is_action_just_pressed("jump") && on_wall:
    velocity += wall_normal * jump_velocity
    velocity.y += jump_velocity

func on_wall_check():
  if wallrun_shape_cast.is_colliding(): wall_normal = wallrun_shape_cast.get_collision_normal(0)
  
  if wallrun_shape_cast.is_colliding() && !on_wall && !is_on_ceiling():
    on_wall = true
    wall_normal = wallrun_shape_cast.get_collision_normal(0)
    ground_deccel = 0
    #wallrun_juice()
    set_state(states.WALL_RUNNING)
  elif !wallrun_shape_cast.is_colliding() && on_wall:
    on_wall = false
    wall_normal = Vector3.ZERO
    ground_deccel = norm_deccel
    #wallrun_juice()
  wallrun_juice()
  
# Manage player input by checking the current input and setting the direction for later use
func manage_input():
  var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back") 
  var floor_normal = grounding_ray.get_collision_normal()
  if input_dir != Vector2.ZERO && current_state != states.AIRBORNE: set_state(states.RUNNING)
  elif is_on_floor(): set_state(states.IDLE)
  
  direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

# This adds mommentmum to the character gradually to keep true to the original build that uses a Rigidbody
func handle_movement(delta):
  if speed_cap > 0:
    var accel_speed = ground_accel * delta * speed_cap
    
    accel_speed = min(accel_speed, speed_cap) 
    self.velocity += accel_speed * direction
  
    set_decceleration(delta)
 
# sets the value at which the character deccelerates 
func set_decceleration(delta):
  if is_ground_slope(): 
    if is_sliding && check_down_slope(): return
    elif is_sliding && !check_down_slope(): deceleration(slide_up_deccel, delta)
    else: deceleration(ground_deccel, delta)
  else: 
    if !is_sliding: deceleration(ground_deccel, delta)
    else: deceleration(slide_deccel, delta)
  
# This adds friction to the character to slow them down while on the ground
func deceleration(deccel:float, delta):
  var control = max(self.velocity.length(), deccel)
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
  self.velocity += (-wall_normal * 8) * delta

# reduces the size of the player and grants a small speed boost with high friction 
func crouch_slide():
  if Input.is_action_pressed("slide") && !is_sliding:
    is_sliding = true
    if !is_ground_slope(): velocity += slide_speed_boost * direction
    else: velocity += slide_slope_boost * direction

    crouch_char()

# kills a lot (if not all) of x / z momentum and drastically increases downward momentum
func ground_pound():
  if Input.is_action_just_pressed("slide") && !is_sliding && !is_on_floor():
    pass # change for special movement

func wallrun_juice():
  if on_wall && wall_right_cast.is_colliding():
    head.rotation_degrees.z = wallrun_tilt_angle
  elif on_wall && wall_left_cast.is_colliding():
    head.rotation_degrees.z = -wallrun_tilt_angle
  else:
    head.rotation_degrees.z = 0
 
# Should visually drop player to crouch / slide height (NOT WORKING) 
func crouch_char(crouched:bool = true):
  if crouched: 
    scale.y = 0.5
    position.y -= 0.5
  else:
    scale.y = 1
    position.y += 0.5

# Change velocity based on weapon knockback
func weapon_knockback():
  # only knockback while airborne
  if weapon_manager.weapon_stats.knock_back <= 0 || (is_on_floor() || is_on_wall()): return
  velocity += camera.get_global_transform().basis.z * weapon_manager.weapon_stats.knock_back

func is_ground_slope() -> bool:
  if grounding_ray.get_collision_normal() != Vector3.UP: return true
  else: return false

func check_down_slope() -> bool:
  if self.global_position.y > last_y: return false
  else: return true

# === timers === #
func _on_slide_cooldown_timer_timeout():
  is_sliding = false
  slide_cooldown_timer.stop()

func coyote_timer_timeout() -> void:
  has_gravity = true
  coyote_timer.stop()
