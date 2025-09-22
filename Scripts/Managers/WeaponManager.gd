extends Node
class_name weapon_node

@export var controller:CharacterBody3D

enum weapons
{
  MELEE,
  AUTO_PISTOL,
  REVOLVER,
  SUB_MACHINE_GUN,
  RIFLE,
  REPEATING_SHOTGUN,
  DOUBLE_BARREL_SHOTGUN,
  ROCKET_LAUNCHER
}

@export var current_weapon:weapons
@export var is_player:bool = false
var node_owner:CharacterBody3D

@onready var firerate_timer: Timer = $FirerateTimer

func _ready() -> void:
  pass
  
func change_weapon(weapon:weapons, is_stolen:bool = false) -> void:
  current_weapon = weapon
  
  if is_player:
    print("new gun")
  elif is_player && is_stolen:
    pass
  elif !is_player && is_stolen:
    print("my gun!") # set state to weaponless
  elif !is_player && !is_stolen:
    print("rearmed!")
  
func set_weapon_stats():
  pass
  
func create_dropped_weapon():
  pass
