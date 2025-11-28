extends weapon_base

@export var damage_box_path:String
@export var num_of_combos:int
@export var atk_range:float
var combo_count:int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  projectile_type = projectile_types.melee
