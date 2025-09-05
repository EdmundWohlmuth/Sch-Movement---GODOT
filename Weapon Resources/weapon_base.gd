extends Node3D
class_name weapon_base

var weapon_name:String
@export var weapon_type:WeaponManager
@export var damage:int
@export var is_full_auto:bool

@export var projectile_num:int
@export var shot_cooldown_time:float
@export var base_projectile_spread:float
@export var current_projectile_spread:float
@export var max_projectile_spread:float
enum projectile_types { hit_scan, projectile }
@export var projectile_type:projectile_types

@export var total_ammo:int
@export var current_ammo:int

func set_full_ammo():
  current_ammo = total_ammo

func on_shoot():
  pass
  
func on_no_ammo():
  pass
