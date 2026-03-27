extends MeshInstance3D

@export var has_gravity:bool = false
@export var do_points_update:bool = false
@export_range(2,20) var num_of_points:int = 2

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# LINE VALUES #
var line_length:float
var point_spacing:float
var cur_point:Vector3
var iterations = 4

# POINT ARRAYS #
var current_points:Array[Vector3]
var previous_points:Array[Vector3]
var index_array:Array
var vertex_array:Array

func _ready() -> void:
  pass

func _physics_process(delta: float) -> void:
  pass

func set_points(originPos:Vector3, endPos:Vector3):
  current_points.clear()
  previous_points.clear()
  
  current_points.append(lerp(originPos, endPos, num_of_points - 1))
  previous_points.append(current_points)

func update_point_spacing(originPos:Vector3, endPos:Vector3):
  line_length = (originPos - endPos).length()
  point_spacing = line_length / num_of_points - 1

func update_points(originPos:Vector3, endPos:Vector3, delta):
  current_points[0] = originPos
  current_points[num_of_points - 1] = endPos
  
  update_point_spacing(originPos, endPos)
  
  for point in range(1, num_of_points - 1):
    current_points[point] = current_points[point] + current_points[point] - previous_points[point]
    if has_gravity:
      current_points[point] += (Vector3.DOWN * gravity * delta)
    previous_points[point] = current_points[point]

  for i in range(iterations):
    constraint_connections()

func constraint_connections():
  for i in range(num_of_points - 1):
    var centre:Vector3 = (current_points[i+1] + current_points[i]) / 2
    var offset:Vector3 = current_points[i+1] - current_points[i]
    var length:float = offset.length()
    var dir:Vector3 = offset.normalized()
    
    var d = length - point_spacing
    
    if i != 0:
      current_points[i] += dir * d * 0.5
    if i + 1 != num_of_points -1:
      current_points[i] -= dir * d * 0.5

func draw_line(originPos:Vector3, endPos:Vector3):
  mesh.clear_surfaces()
  mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
  
  for i in range(index_array.size() / 3):
    var p1 = vertex_array[index_array[3*i]]
    var p2 = vertex_array[index_array[3*i+1]]
    var p3 = vertex_array[index_array[3*i+2]]
    
    var tangent = Plane(p1,p2,p3)
    var normal = tangent.normal
    
    mesh.surface_set_tangent(tangent)
    mesh.surface_set_normal(tangent)
    mesh.surface_add_vertex(p1)
    
    mesh.surface_set_tangent(tangent)
    mesh.surface_set_normal(tangent)
    mesh.surface_add_vertex(p2)
    
    mesh.surface_set_tangent(tangent)
    mesh.surface_set_normal(tangent)
    mesh.surface_add_vertex(p3)
  
  mesh.surface_end()

func remove_line():
  pass
