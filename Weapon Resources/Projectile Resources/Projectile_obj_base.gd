extends RigidBody3D

var speed:float = 0.0
var damage:int = 0
var has_gravity:bool = false
var is_grappleable:bool = false

@export var projectile_stats:weapon_base

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var shape_cast_3d: ShapeCast3D = $ShapeCast3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  if !has_gravity: gravity_scale = 0
  if is_grappleable: set_collision_layer_value(4, true)
  apply_impulse(transform.basis * Vector3(0, 0, -speed * 10)) # NEED THIS TO GO TOWARDS RAYCAST POINT
  
func _physics_process(_delta: float) -> void:
   if shape_cast_3d.is_colliding(): 
    var collision = shape_cast_3d.get_collider(0)
    
    if collision.is_class("CharacterBody3D"):
      collision.hurt_box.on_hit(damage, 0)
    else: print("wall")
    queue_free()
