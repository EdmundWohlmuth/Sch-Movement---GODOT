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
@export var is_player:bool

func _ready() -> void:
  pass
  
func set_weapon() -> void:
  #if is_player:
  pass
  
