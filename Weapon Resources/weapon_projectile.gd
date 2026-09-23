extends weapon_base

## How fast the projectile moves
@export var projectile_speed:float
## Weather or not the projectile has gravity
@export var does_projectile_drop:bool
## Weather or not the projectile can be grappled onto
@export var is_grappleable:bool
## How long the projectile lasts in seconds before being freed
@export var projectile_life:float

@export var projectile_node:String


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  projectile_type = projectile_types.projectile
