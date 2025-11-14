extends Node

@onready var grapple_cooldown_timer: Timer = $grapple_cooldown_timer

@export var weapon_manager:Node3D

@export var max_grapple_dist:float
@export var grapple_speed:float
@export var grapple_cooldown_time:float

@export var grapple_cast:RayCast3D

var grapple_point
var grapple_dist
var is_grappling:bool = false
var can_grapple:bool = true
var is_pulling:bool = false

func _physics_process(_delta: float) -> void:
  # end grappling early if hitting a wall
  if is_grappling && ((get_parent().is_on_floor() || get_parent().is_on_wall()) && !is_pulling): grapple_end()

# Generaic func name for player controller to call
func start_special_move(delta):
  grapple(delta)

# handle grapple mechanic
func grapple(delta):
  # what is grapple doing + setting the grapple to pos
  if Input.is_action_just_pressed("grapple") && can_grapple: check_grapple_type() ## need to keep checking if layer 4
  
  # for hanging on the grapple line
  if Input.is_action_just_released("grapple") && is_grappling: 
    grapple_dist = grapple_point.distance_to(get_parent().position)
    is_pulling = false
  if !Input.is_action_pressed("grapple") && is_grappling: grapple_hang(delta)
  
  # 'reeling' self in on grapple
  if Input.is_action_pressed("grapple") && can_grapple && is_grappling: 
    grapple_pull(delta, grapple_speed)
    is_pulling = true
  elif Input.is_action_just_pressed("jump") && is_grappling: # stop grappling
    grapple_end()
    get_parent().velocity.y += get_parent().jump_velocity # overriding jump here for game feel
  
  set_crosshair_juice()

func is_in_grapple_range(there) -> bool:
  var here = grapple_cast.global_transform.origin
  var distance = here.distance_to(there)
  
  if distance > max_grapple_dist: return false
  else: return true

# gets and sets initial point of grapple
func set_grapple():
  if grapple_cast.is_colliding():
    is_grappling = false
    
    grapple_point = grapple_cast.get_collision_point()
    
    var grapple_dir = (grapple_point - get_parent().position).normalized()
    var _grapple_target_speed = grapple_dir * grapple_speed

    is_grappling = true

# Emit signal to UI for crosshair colors and juice
func set_crosshair_juice():
  if grapple_cast.is_colliding() && can_grapple && is_in_grapple_range(grapple_cast.get_collision_point()): 
    if grapple_cast.get_collider() == null: return
    SignalManager.emit_signal("send_dist_info", get_parent().position.distance_to(grapple_cast.get_collision_point()))
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
  if !is_in_grapple_range(grapple_cast.get_collision_point()): return
    
  if grapple_cast.get_collider().collision_layer == 1: set_grapple()
  elif grapple_cast.get_collider().collision_layer == 2: weapon_steal()

# pulls player towards collision area
func grapple_pull(delta, speed):
  var grapple_vector
  var grapple_dir = (grapple_point - get_parent().position).normalized()
  var grapple_target_speed = grapple_dir * speed
  grapple_vector = (grapple_target_speed - get_parent().velocity)
    
  get_parent().velocity += grapple_vector * delta

# lets the player dangle at the distance they released the reel in option on the Grapple hook
func grapple_hang(delta):
  if grapple_dist == null: return
  
  if (grapple_point.distance_to(get_parent().position)) > grapple_dist: grapple_pull(delta, grapple_speed)
  else: grapple_pull(delta, 0)

func grapple_end():
  can_grapple = false
  is_grappling = false
  grapple_cooldown_timer.start(grapple_cooldown_time)
 
# Check enemies weapon and add it to the player's weapon slot 
func weapon_steal():
  if is_grappling: is_grappling = false
  
  var cast_target = grapple_cast.get_collider()
  if cast_target.weapon_manager.current_weapon == weapon_manager.weapons.MELEE: return #or pull
  
  weapon_manager.set_weapon(cast_target.weapon_manager.current_weapon)
  cast_target.weapon_manager.set_weapon(weapon_manager.weapons.MELEE, true)
  weapon_manager.weapon_stats.raycast = grapple_cast
  SignalManager.emit_signal("update_weapon_data", weapon_manager.weapon_stats.current_ammo, weapon_manager.weapon_stats.total_ammo, true)

func _on_grapple_cooldown_timer_timeout():
  can_grapple = true
  grapple_cooldown_timer.stop()
