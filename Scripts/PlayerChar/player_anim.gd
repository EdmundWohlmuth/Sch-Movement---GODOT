extends Node3D

# ANIMATRION NODE #
@onready var animation_player: AnimationPlayer = $Character_View_Model/AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree

# VIEW MODEL PARTS #
@onready var arm_left: MeshInstance3D = $Character_View_Model/MainCharRig/Skeleton3D/MainCharArmLeft
@onready var arm_right: MeshInstance3D = $Character_View_Model/MainCharRig/Skeleton3D/MainCharArmRight
@onready var leg_left: MeshInstance3D = $Character_View_Model/MainCharRig/Skeleton3D/MainCharLegLeft
@onready var leg_right: MeshInstance3D = $Character_View_Model/MainCharRig/Skeleton3D/MainCharLegRight

func _ready() -> void:
  animation_tree.set("active", true)
  leg_left.visible = false
  leg_right.visible = false

func play_anim(state):
  match state:
    player_char.states.IDLE:
      leg_left.visible = false
      leg_right.visible = false
      arm_left.visible = true
      arm_right.visible = true

      animation_tree.set("parameters/conditions/is_running", false)
      animation_tree.set("parameters/conditions/is_idle", true)
      animation_tree.set("parameters/conditions/is_airborne", false) 
    
    player_char.states.RUNNING:
      leg_left.visible = false
      leg_right.visible = false
      arm_left.visible = true
      arm_right.visible = true
      
      animation_tree.set("parameters/conditions/is_running", true)
      animation_tree.set("parameters/conditions/is_idle", false)
      animation_tree.set("parameters/conditions/is_airborne", false) 
      
    player_char.states.CROUCH_MOVE:pass
    
    player_char.states.SLIDING:
      leg_left.visible = true
      leg_right.visible = true
      arm_left.visible = false ## TEMP
      arm_right.visible = false ## TEMP
    player_char.states.AIRBORNE:
      leg_left.visible = true
      leg_right.visible = true
      arm_left.visible = true
      arm_right.visible = true
    
      animation_tree.set("parameters/conditions/is_airborne", true)
      animation_tree.set("parameters/conditions/is_idle", false)    
      animation_tree.set("parameters/conditions/is_running", false) 
    
    player_char.states.DEAD:
      leg_left.visible = true
      leg_right.visible = true
      arm_left.visible = true
      arm_right.visible = true
    
func anim_on_shoot_gun():
  animation_player.play("Pistol_Shoot")
  leg_left.visible = false
  leg_right.visible = false
  arm_left.visible = true
  arm_right.visible = true

func anim_on_melee():
  pass
