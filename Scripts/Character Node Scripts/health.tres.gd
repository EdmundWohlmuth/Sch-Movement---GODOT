extends Node
class_name health_node

@export var total_health:int
@export var current_health:int

func _ready() -> void:
  current_health = total_health

# subtract damage from current health
func take_damage(damage:int):
  current_health -= damage
  if current_health <= 0: 
    current_health = 0
    # on_zero_health check
  
# add health to character
func heal(healing:int):
  take_damage(-healing)
  if current_health > total_health: current_health = total_health
