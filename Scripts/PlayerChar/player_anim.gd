extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func play_anim(state):
  match state:
    player_char.states.IDLE:pass
    player_char.states.RUNNING:pass
    player_char.states.CROUCH_MOVE:pass
    player_char.states.SLIDING:pass
    player_char.states.AIRBORNE:pass
    player_char.states.DEAD:pass
