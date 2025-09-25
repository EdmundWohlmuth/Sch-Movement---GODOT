extends weapon_base

@export var projectile_speed:float
@export var does_projectile_drop:bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  projectile_type = projectile_types.projectile


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
  pass
