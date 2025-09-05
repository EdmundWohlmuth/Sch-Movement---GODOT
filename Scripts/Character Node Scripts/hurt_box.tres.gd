extends Node
class_name hurtbox_node

@export var health:health_node
@export var hurtbox:CollisionShape3D

@export var can_take_damage:bool
@export var accept_bullet_damage:bool
@export var accept_explosive_damage:bool

func on_hit(damage:int, type):
  if !can_take_damage: return
  
  if type == 0 && accept_bullet_damage: # bullet
    health.take_damage(damage)
  elif type == 1 && accept_explosive_damage:  # explosive
    health.take_damage(damage)
