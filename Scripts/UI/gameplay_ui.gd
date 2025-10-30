extends Control

@onready var color_rect: ColorRect = $AspectRatioContainer/ColorRect
@onready var dist_label: RichTextLabel = $AspectRatioContainer/ColorRect/RichTextLabel
@onready var weapon_label: Label = $VBoxContainer/WeaponLabel

@export var out_of_range_color:Color
@export var enemy_color:Color
@export var in_range_color:Color
@export var grapple_recharge_color:Color

var set_range:Callable = Callable(set_dist_text)
var oor_text:Callable = Callable(set_out_of_range)
var change_crosshair:Callable = Callable(set_crosshair_color)
var update_wep_ui:Callable = Callable(set_weapon_label)

func _ready() -> void:
  SignalManager.connect("send_dist_info", set_range)
  SignalManager.connect("out_of_range_text", oor_text)
  SignalManager.connect("update_crosshair", change_crosshair)
  SignalManager.connect("update_weapon_data", update_wep_ui)

func set_dist_text(distance:float) -> void:
  dist_label.text = str("%0.2f" % distance)

func set_out_of_range() -> void:
  dist_label.text = "---"
  
func set_crosshair_color(state:int) -> void:
  match state:
    0: color_rect.color = out_of_range_color
    1: color_rect.color = enemy_color
    2: color_rect.color = in_range_color
    3: color_rect.color = grapple_recharge_color

func set_weapon_label(current_ammo:int, max_ammo:int, has_ammo:bool = true):
  if has_ammo: weapon_label.text = str(current_ammo) + " / " + str(max_ammo)
  else: weapon_label.text = " "
