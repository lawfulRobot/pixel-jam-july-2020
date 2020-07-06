extends Node2D

# NOTE : Player and Enemy turret scenes are different they could be the same 
# and use is_enemy to setup their sprites and stuff but I was lazy :)

# NODE REFERENCES
onready var game_manager = $"/root/World/GameManager"
onready var combat_action_hint = $"CombatActionHint"
onready var shield_sprite = $"Shield"
onready var muzzle_flash = $"Muzzle"
onready var mystery_overlay = $"CombatActionHint/MysteryOverlay"
onready var audio_stream_player = $"AudioStreamPlayer"

var attack_sounds = [preload("res://Sound/Explosion31.ogg"), preload("res://Sound/Explosion32.ogg"), preload("res://Sound/Explosion33.ogg")]

export(bool)var is_enemy = false
# combat_action and combat_value are set from the cards these determine what the turret will do during combat
var combat_action = -1
var combat_value = 0
# is_combat_ready is used to prevent multiple cards being played on a single turret
var is_combat_ready = false

# combat_ready signal is used to notify the game manager that a turret is ready
# when all turrets are ready the game manager proceeds to combat phase
signal combat_ready

func _ready():
	connect("combat_ready", game_manager, "turret_combat_ready")

# called when a card is dropped on the turret on player owned turrets
# called from the game manager on enemy turrets
# hidden is used to hide the action of the enemy turret in strategy phase
func set_combat_action_and_values(action, value, sprite, hidden = false):
	combat_action = action
	combat_value = value
	if hidden:
		mystery_overlay.visible = true
	combat_action_hint.texture = sprite
#	if sprite != null:
	is_combat_ready = true
	if !is_enemy:
		emit_signal("combat_ready")
	if combat_action == 0 && !hidden:
		shield_sprite.visible = true

# reset turret values
func reset():
	combat_action_hint.texture = null
	combat_action = -1
	combat_value = 0
	is_combat_ready = false
	shield_sprite.visible = false

# attack
func attack():
	audio_stream_player.stream = attack_sounds[rand_range(0,3)]
	audio_stream_player.play(0)
	muzzle_flash.frame = 0
	muzzle_flash.play()

# this is called on enemy turrets when combat phase begins
# to reveal the turret action that we hide earlier
func hide_mystery_overlay():
	mystery_overlay.visible = false
	if combat_action == 0:
		shield_sprite.visible = true
