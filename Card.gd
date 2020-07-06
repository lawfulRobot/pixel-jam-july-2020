extends Control
class_name Card

# NODE REFERENCES
onready var sprite_renderer = $"sprite"
onready var game_manager = $"/root/World/GameManager"
onready var world = $"/root/World"
onready var default_parent = $"/root/World/CardContainer"
onready var audio_stream_player = $"AudioStreamPlayer"


# CARD SPRITES 
var sprite_attack_t1 = preload("res://Sprites/card_attack_t1.png")
var sprite_attack_t2 = preload("res://Sprites/card_attack_t2.png")
var sprite_attack_t3 = preload("res://Sprites/card_attack_t3.png")

var sprite_block_t1 = preload("res://Sprites/card_block_t1.png")
var sprite_block_t2 = preload("res://Sprites/card_block_t2.png")
var sprite_block_t3 = preload("res://Sprites/card_block_t3.png")
var selected_sprite

# SOUNDS
var hover_card_sound = preload("res://Sound/rollover3.ogg")
var drop_card_sound = preload("res://Sound/switch2.ogg")
var pick_card_sound = preload("res://Sound/rollover1.ogg")

var dragging = false
var position_on_begin_drag
var drag_position_offset
var potential_target
var overlap_areas = 0

# 0 - BLOCK, 1 - ATTACK
var type = -1 # type is used to set the card sprite and turret combat action
var tier = 1 # tier is also used to set the card sprite and the turret value for the combat action

# setup_card is called from the game manager when it spawns the cards
# the card sprite, type and tier are set up
func setup_card(card_type, card_tier):
	if sprite_renderer == null:
		sprite_renderer = $"sprite"
	type = card_type as int
	tier = card_tier as int
	match (type):
		0: # BLOCK
			match (tier):
				1:
					sprite_renderer.texture = sprite_block_t1
				2:
					sprite_renderer.texture = sprite_block_t2
				3:
					sprite_renderer.texture = sprite_block_t3
		1: # ATTACK
			match (tier):
				1:
					sprite_renderer.texture = sprite_attack_t1
				2:
					sprite_renderer.texture = sprite_attack_t2
				3:
					sprite_renderer.texture = sprite_attack_t3
	selected_sprite = sprite_renderer.texture

# target is the ally unit that gets the effect of the card
# this is called when we let go of the card over a friendly turret
func played_on(target):
	target.set_combat_action_and_values(type, tier, selected_sprite)

func _process(delta):
	if dragging:
		set_position(get_global_mouse_position() + drag_position_offset)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		game_manager.selected_card = self
		game_manager.last_played_card = self
		position_on_begin_drag = get_position()
		drag_position_offset = get_position() - get_global_mouse_position()
		dragging = true
		audio_stream_player.stream = pick_card_sound
		audio_stream_player.play(0)
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and !event.pressed:
		if potential_target != null:
			audio_stream_player.stream = drop_card_sound
			audio_stream_player.play(0)
			played_on(potential_target)
			visible = false
		game_manager.selected_card = null
		set_position(position_on_begin_drag)
		dragging = false

func _on_Card_mouse_entered():
	audio_stream_player.stream = hover_card_sound
	audio_stream_player.play(0)
	set_scale(Vector2(1.2, 1.2))


func _on_Card_mouse_exited():
	set_scale(Vector2(1, 1))

# we use this to determine when the card overlaps a turret
# we set potential_target to the turret
# we then use potential_target when we let go of the card to play it on the turret
# overlap_areas is used to avoid potential errors if the card overlaps multiple turrets at once
func _on_area_entered(area):
	if area.get_parent().is_in_group("PlayerTurret"):
		if !area.get_parent().is_combat_ready:
			potential_target = area.get_parent()
		overlap_areas += 1

# here we check overlap_areas to check if the turret(area) we exited was the last/only 
# area overlapped and if so set potential_target to null
# which leads to the card being moved back to it's original position when let go
func _on_area_exited(area):
	if area.get_parent().is_in_group("PlayerTurret"):
		overlap_areas -= 1
		if overlap_areas == 0:
			potential_target = null
