extends weapon_base

@export var projectile_speed:float
@export var does_projectile_drop:bool
@export var is_grappleable:bool

@export var projectile_node:String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  projectile_type = projectile_types.projectile
