extends CanvasLayer
## HUD: score, wave, health bar, skill buttons, Game Over screen.
## Buttons only emit signals - game.gd does the actual gameplay.
##
## Styling is done here in code (not in the .tscn) so the look is
## self-contained: Mobile Legends style — a dark semi-transparent
## top bar, big outlined labels, a green/orange/red HP bar, and large
## circular coloured skill buttons with a visible cooldown state
## (dimmed + seconds remaining) and press feedback.

signal attack_pressed
signal dash_pressed
signal burst_pressed
signal restart_pressed
signal ascii_toggled

const COL_ATTACK := Color(0.95, 0.45, 0.08)
const COL_DASH := Color(0.12, 0.5, 0.95)
const COL_BURST := Color(0.62, 0.28, 0.92)
const COL_RESTART := Color(0.15, 0.7, 0.3)
const COL_ASCII := Color(0.08, 0.35, 0.4)

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
@onready var title_label: Label = $GameOverPanel/VBox/TitleLabel

var _hp_fill: StyleBoxFlat = null


func _round_box(bg: Color, radius: int, border: Color = Color(1, 1, 1, 0.85), border_width: int = 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(border_width)
	s.border_color = border
	s.content_margin_left = 8.0
	s.content_margin_right = 8.0
	s.content_margin_top = 4.0
	s.content_margin_bottom = 4.0
	return s


func _style_skill_button(btn: Button, base: Color) -> void:
	# Circular (100x100 in the scene, radius 50), bold white text.
	btn.add_theme_stylebox_override("normal", _round_box(base, 50))
	btn.add_theme_stylebox_override("hover", _round_box(base.lightened(0.15), 50))
	btn.add_theme_stylebox_override("pressed", _round_box(base.darkened(0.25), 50))
	btn.add_theme_stylebox_override("disabled", _round_box(Color(0.25, 0.25, 0.25, 0.9), 50))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	btn.add_theme_constant_override("outline_size", 6)
	# Press feedback: dim briefly while held.
	btn.button_down.connect(func() -> void: btn.modulate = Color(0.82, 0.82, 0.82))
	btn.button_up.connect(func() -> void: btn.modulate = Color.WHITE)


func _style_label(lbl: Label, font_size: int) -> void:
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)


func _ready() -> void:
	attack_button.pressed.connect(func() -> void: attack_pressed.emit())
	dash_button.pressed.connect(func() -> void: dash_pressed.emit())
	burst_button.pressed.connect(func() -> void: burst_pressed.emit())
	restart_button.pressed.connect(func() -> void: restart_pressed.emit())
	ascii_button.pressed.connect(func() -> void: ascii_toggled.emit())
	game_over_panel.visible = false

	# --- Top bar: dark semi-transparent panel behind the labels. ---
	var top_bar: Control = $TopBar
	var panel := ColorRect.new()
	panel.name = "TopBarPanel"
	panel.color = Color(0, 0, 0, 0.55)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(panel)
	top_bar.move_child(panel, 0)

	_style_label(score_label, 30)
	_style_label(wave_label, 30)
	_style_label(health_label, 28)

	# --- HP bar: dark track, coloured fill, white border. ---
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0, 0, 0, 0.65)
	hp_bg.set_corner_radius_all(8)
	hp_bg.set_border_width_all(2)
	hp_bg.border_color = Color(1, 1, 1, 0.7)
	health_bar.add_theme_stylebox_override("background", hp_bg)
	_hp_fill = StyleBoxFlat.new()
	_hp_fill.bg_color = Color(0.2, 0.85, 0.3)
	_hp_fill.set_corner_radius_all(8)
	health_bar.add_theme_stylebox_override("fill", _hp_fill)

	# --- Skill buttons: big circular MLBB-style buttons. ---
	_style_skill_button(attack_button, COL_ATTACK)
	_style_skill_button(dash_button, COL_DASH)
	_style_skill_button(burst_button, COL_BURST)

	# --- ASCII toggle: clearly labelled, tappable, top-right. ---
	ascii_button.add_theme_stylebox_override("normal", _round_box(COL_ASCII, 10))
	ascii_button.add_theme_stylebox_override("hover", _round_box(COL_ASCII.lightened(0.15), 10))
	ascii_button.add_theme_stylebox_override("pressed", _round_box(COL_ASCII.darkened(0.25), 10))
	ascii_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	ascii_button.add_theme_color_override("font_color", Color.WHITE)
	ascii_button.add_theme_font_size_override("font_size", 20)
	ascii_button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	ascii_button.add_theme_constant_override("outline_size", 5)

	# --- Game Over: dark full-screen overlay behind the text. ---
	var overlay := ColorRect.new()
	overlay.name = "GameOverOverlay"
	overlay.color = Color(0, 0, 0, 0.72)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over_panel.add_child(overlay)
	game_over_panel.move_child(overlay, 0)
	_style_label(title_label, 56)
	_style_label(final_score_label, 30)
	_style_skill_button(restart_button, COL_RESTART)
	restart_button.add_theme_font_size_override("font_size", 28)
	restart_button.custom_minimum_size = Vector2(240, 72)


func update_score(score: int, wave: int, enemy_count: int) -> void:
	score_label.text = "SCORE  %d" % score
	wave_label.text = "WAVE %d    ENEMIES %d" % [wave, enemy_count]


func update_health(health: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	health_label.text = "HP %d" % int(health)
	if _hp_fill != null:
		var frac: float = health / maxf(max_health, 1.0)
		if frac > 0.5:
			_hp_fill.bg_color = Color(0.2, 0.85, 0.3)
		elif frac > 0.25:
			_hp_fill.bg_color = Color(0.95, 0.6, 0.1)
		else:
			_hp_fill.bg_color = Color(0.9, 0.15, 0.1)


func update_cooldowns(attack_cd: float, dash_cd: float, burst_cd: float) -> void:
	attack_button.text = "ATTACK" if attack_cd <= 0.0 else "ATK %.0f" % attack_cd
	dash_button.text = "DASH" if dash_cd <= 0.0 else "DASH %.0fs" % dash_cd
	burst_button.text = "BURST" if burst_cd <= 0.0 else "BURST %.0fs" % burst_cd
	# Cooldown state: dim the button (and its text) while it recharges.
	attack_button.modulate = Color(0.5, 0.5, 0.5) if attack_cd > 0.0 else Color.WHITE
	dash_button.modulate = Color(0.5, 0.5, 0.5) if dash_cd > 0.0 else Color.WHITE
	burst_button.modulate = Color(0.5, 0.5, 0.5) if burst_cd > 0.0 else Color.WHITE


func set_ascii_button(enabled: bool) -> void:
	ascii_button.text = "ASCII: ON" if enabled else "ASCII: OFF"


func show_game_over(score: int) -> void:
	final_score_label.text = "SCORE: %d" % score
	game_over_panel.visible = true


func hide_game_over() -> void:
	game_over_panel.visible = false
