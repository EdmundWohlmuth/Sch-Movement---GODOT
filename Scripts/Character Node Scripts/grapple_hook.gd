extends Node

@onready var grapple_cooldown_timer: Timer = $grapple_cooldown_timer

@export var weapon_manager:Node3D

@export var max_grapple_dist:float
@export var grapple_speed:float
@export var grapple_cooldown_time:float

@export var grapple_cast:RayCast3D

var grapple_point

var is_grappling:bool = false
var can_grapple:bool = true

func start_special_move(delta):
  grapple(delta)

# handle grapple mechanic
func grapple(delta):
  if Input.is_action_just_pressed("grapple") && can_grapple: check_grapple_type()
  
  if Input.is_action_pressed("grapple") && can_grapple && is_grappling: grapple_pull(delta)
  elif Input.is_action_just_released("grapple") && is_grappling: grapple_end()
  
  set_crosshair_juice()

func is_in_grapple_range(there) -> bool:
  var here = grapple_cast.global_transform.origin
  var distance = here.distance_to(there)
  
  if distance > max_grapple_dist: return false
  else: return true

# gets and sets initial point of grapple
func set_grapple():
  if grapple_cast.is_colliding():
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
func grapple_pull(delta):
    var grapple_vector
    var grapple_dir = (grapple_point - get_parent().position).normalized()
    var grapple_target_speed = grapple_dir * grapple_speed
    grapple_vector = (grapple_target_speed - get_parent().velocity)
    
    get_parent().velocity += grapple_vector * delta

func grapple_end():
  can_grapple = false
  is_grappling = false
  grapple_cooldown_timer.start(grapple_cooldown_time)
  
func weapon_steal():
  var cast_target = grapple_cast.get_collider()
  if cast_target.weapon_manager.current_weapon == weapon_manager.weapons.MELEE: return #or pull
  
  weapon_manager.set_weapon(cast_target.weapon_manager.current_weapon)
  cast_target.weapon_manager.set_weapon(weapon_manager.weapons.MELEE, true)
  weapon_manager.weapon_stats.raycast = grapple_cast
  SignalManager.emit_signal("update_weapon_data", weapon_manager.weapon_stats.current_ammo, weapon_manager.weapon_stats.total_ammo, true)

func _on_grapple_cooldown_timer_timeout():
  can_grapple = true
  grapple_cooldown_timer.stop()
