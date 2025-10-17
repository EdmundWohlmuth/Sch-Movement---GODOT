extends Resource
class_name weapon_base

var weapon_name:String
@export var damage:int
@export var is_full_auto:bool

@export var bullet_num:int
@export var shot_cooldown_time:float
@export var base_bullet_spread:float
@export var current_bullet_spread:float
@export var max_bullet_spread:float
@export var knock_back:float
enum projectile_types { hit_scan, projectile, melee}

@export var projectile_type:projectile_types

@export var total_ammo:int
@export var current_ammo:int

var raycast:RayCast3D
var can_shoot:bool = true

func _ready() -> void:
  #weapon_name = str(current_weapon_type) # I don't think that's how this works, but you get the idea
  pass

func set_full_ammo():
  current_ammo = total_ammo

func on_shoot():
  if !can_shoot: return
  if projectile_type != projectile_types.melee: 
    if current_ammo > 0: # Shoot the Gun
      current_ammo -= 1
      SignalManager.emit_signal("update_weapon_data", current_ammo, total_ammo, true)
      #draw_hit_scan()
      can_shoot = false
      if raycast.get_collider().is_class("CharacterBody3D"): 
        raycast.get_collider().hurt_box.on_hit(damage, 0)
      
      if current_ammo <= 0: on_no_ammo()
      
    elif current_ammo <= 0: on_no_ammo()
  
# if player loose the gun, else wait for reload
func on_no_ammo():
  print("discard")
  SignalManager.emit_signal("update_weapon_data", current_ammo, total_ammo, false)

# allow weapon to fire again
func re_enable_shoot():
  can_shoot = true

func draw_hit_scan(pos:Vector3, radius:float = 0.05, color:Color = Color.WHITE) -> MeshInstance3D:
  var mesh_instance := MeshInstance3D.new()
  var material := ORMMaterial3D.new()
  
  return
