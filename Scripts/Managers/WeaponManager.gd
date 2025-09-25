extends Node
class_name weapon_node

@export var controller:CharacterBody3D
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
  ROCKET_LAUNCHER
}

@export var current_weapon:weapons
@export var is_player:bool = false
@export var weapon_stats:weapon_base = MELEE

const DB_SHOTGUN = preload("res://Weapon Resources/DBShotgun.tres")
const MELEE = preload("res://Weapon Resources/Melee.tres")
const REPEATING_SHOTGUN = preload("res://Weapon Resources/RepeatingShotgun.tres")
const REVOLVER = preload("res://Weapon Resources/Revolver.tres")
const RIFLE = preload("res://Weapon Resources/Rifle.tres")
const ROCKET_LAUNCHER = preload("res://Weapon Resources/RocketLauncher.tres")
const SMG = preload("res://Weapon Resources/SMG.tres")
const AUTO_PISTOL = preload("res://Weapon Resources/AutoPistol.tres")

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
    weapons.DB_SHOTGUN: weapon_stats = DB_SHOTGUN
    weapons.ROCKET_LAUNCHER: weapon_stats = ROCKET_LAUNCHER
    
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
  weapon_stats.on_shoot()

func enable_shoot():
  weapon_stats.re_enable_shoot()
  timer.stop()
