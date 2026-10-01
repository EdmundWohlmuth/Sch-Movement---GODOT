extends Node3D

@export var line_mesh:MeshInstance3D
@onready var line_visial_end
var line_end:Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  pass # Replace with function body.

func extend_from_to(source_position: Vector3, target_position: Vector3, target_normal: Vector3) -> void:
  line_end = target_position
  #_align_hook_end_with_surface(target_normal)
  
   #global_position = source_position
  
  var distance_to_target = global_position.distance_to(target_position)
  
  line_mesh.mesh.height = distance_to_target
  line_mesh.position.z = -distance_to_target / 2
  
  look_at(target_position)


func _on_timer_timeout() -> void:
  queue_free()
