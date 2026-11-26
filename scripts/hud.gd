extends CanvasLayer
## HUD: score, wave, health bar, skill buttons, Game Over screen.
## Buttons only emit signals - game.gd does the actual gameplay.

signal attack_pressed
signal dash_pressed
signal burst_pressed
signal restart_pressed
signal ascii_toggled

@onready var score_label: Label = $TopBar/ScoreLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var health_bar: ProgressBar = $TopBar/HealthBar
@onready var health_label: Label = $TopBar/HealthLabel
@onready var ascii_button: Button = $TopBar/AsciiButton
@onready var attack_button: Button = $Controls/AttackButton
@onready var dash_button: Button = $Controls/DashButton
@onready var burst_button: Button = $Controls/BurstButton
@onready var game_over_panel: Control = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/VBox/FinalScoreLabel
@onready var restart_button: Button = $GameOverPanel/VBox/RestartButton


func _ready() -> void:
	attack_button.pressed.connect(func() -> void: attack_pressed.emit())
	dash_button.pressed.connect(func() -> void: dash_pressed.emit())
	burst_button.pressed.connect(func() -> void: burst_pressed.emit())
	restart_button.pressed.connect(func() -> void: restart_pressed.emit())
	ascii_button.pressed.connect(func() -> void: ascii_toggled.emit())
	game_over_panel.visible = false


func update_score(score: int, wave: int, enemy_count: int) -> void:
	score_label.text = "SCORE  %d" % score
	wave_label.text = "WAVE %d    ENEMIES %d" % [wave, enemy_count]


func update_health(health: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	health_label.text = "HP %d" % int(health)


func update_cooldowns(attack_cd: float, dash_cd: float, burst_cd: float) -> void:
	attack_button.text = "ATTACK" if attack_cd <= 0.0 else "ATK %.0f" % attack_cd
	dash_button.text = "DASH" if dash_cd <= 0.0 else "DASH %.0fs" % dash_cd
	burst_button.text = "BURST" if burst_cd <= 0.0 else "BURST %.0fs" % burst_cd


func set_ascii_button(enabled: bool) -> void:
	ascii_button.text = "ASCII: ON" if enabled else "ASCII: OFF"


func show_game_over(score: int) -> void:
	final_score_label.text = "SCORE: %d" % score
	game_over_panel.visible = true


func hide_game_over() -> void:
	game_over_panel.visible = false
