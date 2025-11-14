extends Node
class_name weapon_node

@export var controller:CharacterBody3D
@export var bullet_origin:Node3D
@onready var timer: Timer = $Timer

enum weapons
{
  MELEE,
  AUTO_PISTOL,
  REVOLVER,
  SMG,
  RIFLE,
  REPEATING_SHOTGUN,
  DB_SHOTGUN,
  ROCKET_LAUNCHER,
  TEST
}

@export var current_weapon:weapons
@export var is_player:bool = false
@export var weapon_stats:weapon_base

const DOUBLE_B_SHOTGUN = preload("res://Weapon Resources/DoubleBShotgun.tres")
const MELEE = preload("res://Weapon Resources/Melee.tres")
const REPEATING_SHOTGUN = preload("res://Weapon Resources/RepeatingShotgun.tres")
const REVOLVER = preload("res://Weapon Resources/Revolver.tres")
const RIFLE = preload("res://Weapon Resources/Rifle.tres")
const ROCKET_LAUNCHER = preload("res://Weapon Resources/RocketLauncher.tres")
const SMG = preload("res://Weapon Resources/SMG.tres")
const AUTO_PISTOL = preload("res://Weapon Resources/AutoPistol.tres")
const TEST_WEAPON = preload("res://Weapon Resources/TestWeapon.tres")

var end_cooldown:Callable = Callable(enable_shoot)

func _ready() -> void:
  set_weapon(current_weapon)
  timer.connect("timeout", end_cooldown)
  
func set_weapon(weapon:weapons, is_stolen:bool = false) -> void:
  match weapon:
    weapons.MELEE: weapon_stats = MELEE
    weapons.AUTO_PISTOL: weapon_stats = AUTO_PISTOL
    weapons.REVOLVER: weapon_stats = REVOLVER
    weapons.SMG: weapon_stats = SMG
    weapons.RIFLE: weapon_stats = RIFLE
    weapons.REPEATING_SHOTGUN: weapon_stats = REPEATING_SHOTGUN
    weapons.DB_SHOTGUN: weapon_stats = DOUBLE_B_SHOTGUN
    weapons.ROCKET_LAUNCHER: weapon_stats = ROCKET_LAUNCHER
    weapons.TEST: weapon_stats = TEST_WEAPON
    
  current_weapon = weapon
  
  if is_player:
    SignalManager.emit_signal("update_weapon_data", weapon_stats.current_ammo, weapon_stats.total_ammo, true)
    weapon_stats.can_shoot = true
  elif !is_player && is_stolen:
    print("my gun!")
  elif !is_player && !is_stolen:
    print("rearmed!")

func discard_weapon():
  if !is_player: return
  # Drop 'weapon' with weapon type on it
  set_weapon(weapons.MELEE)
  
func shoot():
  if timer.is_stopped(): timer.start(weapon_stats.shot_cooldown_time)
  match weapon_stats.projectile_type:
    weapon_stats.projectile_types.hit_scan: on_shoot()
    weapon_stats.projectile_types.projectile: on_shoot_proj()
    weapon_stats.projectile_types.melee: on_melee()

func enable_shoot():
  weapon_stats.re_enable_shoot()
  timer.stop()

func on_shoot():
  if !weapon_stats.can_shoot: return
  
  if weapon_stats.projectile_type != weapon_stats.projectile_types.melee: 
    if weapon_stats.current_ammo > 0: # Shoot the Gun
      weapon_stats.current_ammo -= 1
      SignalManager.emit_signal("update_weapon_data", weapon_stats.current_ammo, weapon_stats.total_ammo, true)
      #draw_hit_scan()
      weapon_stats.can_shoot = false
      if weapon_stats.raycast.get_collider() == null:return
      if weapon_stats.raycast.get_collider().is_class("CharacterBody3D"): 
        weapon_stats.raycast.get_collider().hurt_box.on_hit(weapon_stats.damage, 0)
      
      if weapon_stats.current_ammo <= 0: weapon_stats.on_no_ammo()
      
    elif weapon_stats.current_ammo <= 0: weapon_stats.on_no_ammo()

func on_shoot_proj():
  if !weapon_stats.can_shoot: return
  if weapon_stats.projectile_type != weapon_stats.projectile_types.melee: 
    if weapon_stats.current_ammo > 0: # Shoot the Gun
      weapon_stats.current_ammo -= 1
      SignalManager.emit_signal("update_weapon_data", weapon_stats.current_ammo, weapon_stats.total_ammo, true)
      
      # CREATE PROJECTILE
      var proj = load(weapon_stats.projectile_node)
      var instance = proj.instantiate()
      
      instance.speed = weapon_stats.projectile_speed
      instance.has_gravity = weapon_stats.does_projectile_drop
      instance.is_grappleable = weapon_stats.is_grappleable
      instance.damage = weapon_stats.damage
      
      instance.position = bullet_origin.global_position
      instance.transform.basis = bullet_origin.global_transform.basis
      get_parent().get_parent().add_child(instance)
      
      weapon_stats.can_shoot = false
      
      if weapon_stats.current_ammo <= 0: weapon_stats.on_no_ammo()
      
    elif weapon_stats.current_ammo <= 0: weapon_stats.on_no_ammo()

func on_melee():
  pass
