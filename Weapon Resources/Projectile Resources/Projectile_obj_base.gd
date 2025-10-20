extends RigidBody3D

var speed:float = 0.0
var has_gravity:bool = false
var is_grappleable:bool = false

@export var projectile_stats:weapon_base
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  if !has_gravity: gravity_scale = 0
  if is_grappleable: set_collision_layer_value(1, true)
  apply_impulse(transform.basis * Vector3(0, 0, -speed * 10)) # NEED THIS TO GO TOWARDS RAYCAST POINT
  
func _on_body_entered(body: Node) -> void:
  if body == CharacterBody3D: print("BODY HIT")
  else: print("OTHER HIT")

  queue_free()
