extends Resource
class_name weapon_base

var weapon_name:String
@export var damage:int
@export var is_full_auto:bool

@export var projectile_num:int
@export var shot_cooldown_time:float
@export var base_projectile_spread:float
@export var current_projectile_spread:float
@export var max_projectile_spread:float
@export var knock_back:float
enum projectile_types { hit_scan, projectile, melee}

@export var projectile_type:projectile_types
@export var projectile_speed:float
@export var does_projectile_drop:bool

@export var total_ammo:int
@export var current_ammo:int

func _ready() -> void:
  #weapon_name = str(current_weapon_type) # I don't think that's how this works, but you get the idea
  pass

func set_full_ammo():
  current_ammo = total_ammo

func on_shoot():
  if projectile_type != projectile_types.melee: 
    if current_ammo > 0: 
      current_ammo -= 1
      print(str(current_ammo)) 
      SignalManager.emit_signal("update_weapon_data", current_ammo, total_ammo, true)
      
    else: on_no_ammo()
  
func on_no_ammo():
  print("discard")
  SignalManager.emit_signal("update_weapon_data", current_ammo, total_ammo, false)
