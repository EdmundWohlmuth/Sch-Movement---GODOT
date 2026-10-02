extends Resource
class_name weapon_base

@export var weapon_name:String
## Damage each 'bulet' deals
@export var damage:int
## If the weapon shoots when held down or not
@export var is_full_auto:bool

## How many 'bullets' the gun shoots at a time
@export var bullet_num:int
## Time in seconds between one 'bullet' and the next
@export var shot_cooldown_time:float
## Random offset of the bullets
@export var base_bullet_spread:float
@export var current_bullet_spread:float
## The maximum ammount the 'bullets' can be offset by (usually after prolonged firing)
@export var max_bullet_spread:float
## How much the weapon pushes the player away from the direction of shooting
@export var knock_back:float
## What kind of weapon it is
enum projectile_types { hit_scan, projectile, melee}

## projectile to use
@export var projectile_type:projectile_types

## Maxium ammo weapon has
@export var total_ammo:int
## current ammount of ammo
@export var current_ammo:int

@export_category("AI variables")
@export var prefered_distance:float
@export var maximum_distance:float
@export var reload_time:float
@export var shots_until_accuracy:int

var raycast:RayCast3D
var can_shoot:bool = true

func _ready() -> void:
  #weapon_name = str(current_weapon_type) # I don't think that's how this works, but you get the idea
  pass

func set_full_ammo():
  current_ammo = total_ammo
  
## if player loose the gun, else wait for reload
func on_no_ammo(is_player:bool):
  if is_player:
    print("discard")
    SignalManager.emit_signal("update_weapon_data", current_ammo, total_ammo, false)
  else: 
    pass

## allow weapon to fire again
func re_enable_shoot():
  can_shoot = true

func draw_hit_scan(pos:Vector3, radius:float = 0.05, color:Color = Color.WHITE) -> MeshInstance3D:
  var mesh_instance := MeshInstance3D.new()
  var material := ORMMaterial3D.new()
  
  return
