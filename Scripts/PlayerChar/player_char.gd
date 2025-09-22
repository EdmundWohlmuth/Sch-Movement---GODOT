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
var grapple_speed:float = 150.0
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
#var is_crouched:bool = false

# === juice === #
var wallrun_tilt_angle:float = 10

# === raycasts === #
@onready var grapple_cast = $Head/Camera3D/RayCast3D
@onready var wallrun_shape_cast = $WallRunShapeCast
@onready var grounding_ray: RayCast3D = $GroundingRayCast3D

# === Objects === #
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var coyote_timer = $CoyoteTimer
@onready var slide_cooldown_timer = $SlideCooldownTimer

#NODES
@onready var weapon_manager:weapon_node = $WeaponManager

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
  weapon_manager.is_player = true
  weapon_manager.node_owner = self
  weapon_manager.is_player = true
  up_direction = Vector3.UP

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
    
    if wallrun_shape_cast.is_colliding(): press_to_wall(delta) ## ADD SLIDING DOWN WALL WHEN NOT MOVING
    
    if !is_on_wall:
      crouch_slide(delta)
    
    handle_movement(delta)
  elif !is_on_floor() || !is_on_wall:
    handle_air_strafe(delta)
    apply_gravity(delta) # Add the gravity.
   
  if Input.is_action_just_pressed("grapple") && can_grapple: check_grapple_type()
  
  if Input.is_action_pressed("grapple") && can_grapple && is_grappling: grapple_pull(delta)
  elif Input.is_action_just_released("grapple") && is_grappling: grapple_end()
  
  set_crosshair_juice()
    
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
    ground_deccel = 0
    wallrun_juice()
  elif !wallrun_shape_cast.is_colliding() && is_on_wall:
    is_on_wall = false
    wall_normal = Vector3.ZERO
    ground_deccel = norm_deccel
    wallrun_juice()

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
  #if is_on_wall: return ##
  var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back") 
  direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()


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
  self.velocity -= wall_normal * max_wall_speed * delta

# reduces the size of the player and grants a small speed boost with high friction 
func crouch_slide(_delta):
  if Input.is_action_just_pressed("slide") && !is_sliding:
    is_sliding = true
    crouch_char()
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

    is_grappling = true

# Emit signal to UI for crosshair colors and juice
func set_crosshair_juice():
  if grapple_cast.is_colliding() && can_grapple: 
    SignalManager.emit_signal("send_dist_info", self.position.distance_to(grapple_cast.get_collision_point()))
    if grapple_cast.get_collider().collision_layer == 1: SignalManager.emit_signal("update_crosshair", 2)
    else: SignalManager.emit_signal("update_crosshair", 1)
  elif grapple_cast.is_colliding() && can_grapple: 
    SignalManager.emit_signal("update_crosshair", 3)
  else: 
    SignalManager.emit_signal("out_of_range_text")
    if can_grapple: SignalManager.emit_signal("update_crosshair", 0)
    else: SignalManager.emit_signal("update_crosshair", 3)

# determines what function is played when the grapple connects with a collision
func check_grapple_type():
    if !grapple_cast.is_colliding(): return
    
    if grapple_cast.get_collider().collision_layer == 1: set_grapple()
    elif grapple_cast.get_collider().collision_layer == 2: weapon_steal()

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
  
func weapon_steal():
  var cast_target = grapple_cast.get_collider()
  if cast_target.weapon_manager.current_weapon == weapon_manager.weapons.MELEE: return #or pull
  
  weapon_manager.change_weapon(cast_target.weapon_manager.current_weapon)
  cast_target.weapon_manager.change_weapon(weapon_manager.weapons.MELEE, true)

# Change the camera tilt based on the camera's rotation and the wall normal to determine to which side
func wallrun_juice():
  if is_on_wall && !is_on_floor(): 
    if wallrun_shape_cast.get_collision_normal(0).x > 0 || wallrun_shape_cast.get_collision_normal(0).z > 0:
      if head.rotation.y < 0: camera.rotation_degrees.z = -wallrun_tilt_angle
      else: camera.rotation_degrees.z = wallrun_tilt_angle
    elif wallrun_shape_cast.get_collision_normal(0).x < 0 || wallrun_shape_cast.get_collision_normal(0).z < 0:
      if head.rotation.y > 0: camera.rotation_degrees.z = -wallrun_tilt_angle
      else: camera.rotation_degrees.z = wallrun_tilt_angle
    
  else: camera.rotation = Vector3.ZERO
  
func crouch_char(_is_crouched:bool = true):
  if _is_crouched: scale.y = 0.5
  else: scale.y = 1

# === timers === #
func _on_slide_cooldown_timer_timeout():
  is_sliding = false
  slide_cooldown_timer.stop()

func _on_grapple_cooldown_timer_timeout():
  can_grapple = true
  grapple_cooldown_timer.stop()
