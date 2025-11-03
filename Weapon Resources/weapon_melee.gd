extends weapon_base

@export var damage_box:String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  projectile_type = projectile_types.melee
