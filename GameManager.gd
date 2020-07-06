extends Node2D
class_name GameManager

const DEFAULT_HEALTH = 30
# NODE REFERENCES
onready var card_prefab = preload("res://Scenes/Card.tscn")
onready var world = $"/root/World"
onready var card_container = $"/root/World/CardContainer"
onready var delay_timer = $"/root/World/CombatWaveTimer"
onready var player_health_label = $"/root/World/UI/PlayerHealth/Label"
onready var enemy_health_label = $"/root/World/UI/EnemyHealth/Label"
onready var game_over_label = $"/root/World/UI/GameOverText"
onready var new_game_button = $"/root/World/NewGameButton"
onready var tutorial_button = $"/root/World/HowToPlayButton"
onready var next_turn_button = $"/root/World/StrategyPhaseButton"
onready var tutorial_hint = $"/root/World/Tutorial/Control"

# card sprites references to set up enemy turret combat hints
var sprite_attack_t1 = preload("res://Sprites/card_attack_t1.png")
var sprite_attack_t2 = preload("res://Sprites/card_attack_t2.png")
var sprite_attack_t3 = preload("res://Sprites/card_attack_t3.png")

var sprite_block_t1 = preload("res://Sprites/card_block_t1.png")
var sprite_block_t2 = preload("res://Sprites/card_block_t2.png")
var sprite_block_t3 = preload("res://Sprites/card_block_t3.png")

var wait_time_combat_wave = 0.6
var wait_time_phase_display = 1.4

var player_turrets = []
var enemy_turrets = []

var player_health
var enemy_health
var current_round = 0

enum GAME_PHASE {STRATEGY = 0, COMBAT = 1}
var current_game_phase = GAME_PHASE.STRATEGY

var selected_card
var last_played_card

var combat_phase_complete = false

var combat_ready_turret_count = 0

# find the turret objects
func _ready():
	var player_turrets_parent = $"/root/World/Player_side"
	var enemy_turrets_parent = $"/root/World/Enemy_side"
	for i in range(player_turrets_parent.get_child_count()):
		player_turrets.append(player_turrets_parent.get_child(i))
		enemy_turrets.append(enemy_turrets_parent.get_child(i))

func generate_cards():
	for _i in range(5):
		create_card()

# create cards, very sophisticated and inteligent generator 
# it's just random
func create_card(tier_override = -1):
	randomize()
	var type = round(rand_range(0, 10))
	var tier = tier_override
	if type < 5:
		type = 0
	else:
		type = 1
	if tier == -1:
		tier = round(rand_range(1,3))
	var new_card = card_prefab.instance()
#	print("CREATED NEW CARD. TYPE = %s , TIER = %s" % [type, tier])
	new_card.setup_card(type,tier)
	card_container.call_deferred("add_child", new_card)


func generate_enemy_actions():
	randomize()
	var enemy_action = -1
	var enemy_value = 0
	for i in range(enemy_turrets.size()):
		enemy_action = round(rand_range(0, 10))
		if enemy_action < 5:
			enemy_action = 0
		else:
			enemy_action = 1
		enemy_value = round(rand_range(1,3))
		var action_sprite
		enemy_action = enemy_action as int
		enemy_value = enemy_value as int
		match (enemy_action):
			0:
				match (enemy_value):
					1:
						action_sprite = sprite_block_t1
					2:
						action_sprite = sprite_block_t2
					3:
						action_sprite = sprite_block_t3
			1:
				match (enemy_value):
					1:
						action_sprite = sprite_attack_t1
					2:
						action_sprite = sprite_attack_t2
					3:
						action_sprite = sprite_attack_t3
		enemy_turrets[i].set_combat_action_and_values(enemy_action, enemy_value, action_sprite, true)
		

func start_strategy_phase():
	next_turn_button.visible = false
	tutorial_button.visible = false
	new_game_button.visible = false
	current_round += 1
	current_game_phase = GAME_PHASE.STRATEGY
	game_over_label.set_text("Round %s \nSTRATEGY" % current_round)
	delay_timer.wait_time = wait_time_phase_display
	delay_timer.start()
	yield(delay_timer, "timeout")
	game_over_label.set_text("")
	delay_timer.stop()
	
	for i in range(player_turrets.size()):
		player_turrets[i].reset()
		enemy_turrets[i].reset()
	generate_enemy_actions()
	combat_ready_turret_count = 0
	combat_phase_complete = false
	if last_played_card != null:
		last_played_card.queue_free()
	generate_cards()

func start_combat_phase():
	for i in range(enemy_turrets.size()):
		enemy_turrets[i].hide_mystery_overlay()
	game_over_label.set_text("Round %s \nCOMBAT" % current_round)
	delay_timer.wait_time = wait_time_phase_display
	delay_timer.start()
	yield(delay_timer, "timeout")
	game_over_label.set_text("")
	delay_timer.stop()
	current_game_phase = GAME_PHASE.COMBAT
	var combat_waves_completed = 0
	var current_combat_wave = 0
	
	while combat_waves_completed < 5:
		var player_turret = player_turrets[current_combat_wave]
		var enemy_turret = enemy_turrets[current_combat_wave]
		delay_timer.wait_time = wait_time_combat_wave
		delay_timer.start()
		yield(delay_timer, "timeout")
		print("\n")
		print("COMBAT WAVE %s" % current_combat_wave)
		
		if player_turret.combat_action == 0: # PLAYER BLOCKS
			var player_block_amount = player_turret.combat_value
			if enemy_turret.combat_action == 0: # ENEMY BLOCKS
				print("BOTH PLAYERS BLOCKED")
			elif enemy_turret.combat_action == 1: # ENEMY ATTACKS
				enemy_turret.attack()
				var damage = enemy_turret.combat_value - player_block_amount
				if damage > 0:
					deal_damage_to_player(damage)
				else:
					print("ENEMY ATTACKED BUT WAS FULLY BLOCKED")
		elif player_turret.combat_action == 1: # PLAYER ATTACKS
			player_turret.attack()
			var player_damage =  player_turret.combat_value
			if enemy_turret.combat_action == 0: # ENEMY BLOCKS
				var damage = player_damage - enemy_turret.combat_value
				if damage > 0:
					deal_damage_to_enemy(damage)
				else:
					print("PLAYER ATTACKED BUT WAS FULLY BLOCKED")
			elif enemy_turret.combat_action == 1: # ENEMY ATTACKS
				deal_damage_to_enemy(player_turret.combat_value)
				deal_damage_to_player(enemy_turret.combat_value)
				enemy_turret.attack()
		
		combat_waves_completed += 1
		current_combat_wave += 1
		if player_health <= 0 && enemy_health <= 0:
			game_over(2)
			return
		elif player_health <= 0:
			game_over(0)
			return
		elif enemy_health <= 0:
			game_over(1)
			return
	yield(delay_timer, "timeout")
	delay_timer.stop()
	combat_phase_complete = true
	next_turn_button.visible = true

func deal_damage_to_player(dmg):
	player_health -= dmg
	if player_health < 0:
		player_health = 0
	player_health_label.set_text("%s" % player_health)
#	print("player took %s damage" % dmg)

func deal_damage_to_enemy(dmg):
	enemy_health -= dmg
	if enemy_health < 0:
		enemy_health = 0
	enemy_health_label.set_text("%s" % enemy_health)
#	print("enemy took %s damage" % dmg)

func game_over(result):
	match (result):
		0: #LOSS
			game_over_label.set_text("YOU LOSE")
		1: #WIN
			game_over_label.set_text("YOU WIN")
		2: #DRAW
			game_over_label.set_text("DRAW")
	current_round = 0
	delay_timer.wait_time = wait_time_phase_display
	delay_timer.start()
	yield(delay_timer, "timeout")
	delay_timer.stop()
	for i in range(player_turrets.size()):
		player_turrets[i].reset()
		enemy_turrets[i].reset()
	game_over_label.set_text("")
	new_game_button.visible = true
	tutorial_button.visible = true
	next_turn_button.visible = false

func turret_combat_ready():
	combat_ready_turret_count += 1
#	print("COMBAT READY TURRETS : %s" % combat_ready_turret_count)
	if combat_ready_turret_count == 5:
		start_combat_phase()
	else:
		if last_played_card != null:
			last_played_card.queue_free()


func _on_NewGameButton_pressed():
	player_health = DEFAULT_HEALTH
	enemy_health = DEFAULT_HEALTH
	player_health_label.set_text("%s" % player_health)
	enemy_health_label.set_text("%s" % enemy_health)
	start_strategy_phase()


func _on_StrategyPhaseButton_pressed():
	start_strategy_phase()


func _on_HowToPlayButton_pressed():
	tutorial_hint.visible = !tutorial_hint.visible
	new_game_button.visible = !tutorial_hint.visible
