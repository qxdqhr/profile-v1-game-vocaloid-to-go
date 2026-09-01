extends Control
## Stage-C: practice/challenge, accuracy, high score, menu.

const WORDS := ["みく", "に", "して", "あげる", "うた", "おと", "ほし", "そら", "ゆめ", "あい", "とき", "こえ"]
const CHOICES := 4
const ROUNDS := 12
const ROUND_TIME := 4.0

@onready var _hud: Label = $UI/HUD
@onready var _prompt: Label = $Center/VBox/Prompt
@onready var _choices: VBoxContainer = $Center/VBox/Choices
@onready var _overlay: ColorRect = $UI/Overlay
@onready var _over_msg: Label = $UI/Overlay/VBox/Msg
@onready var _retry: Button = $UI/Overlay/VBox/Retry

var _score: int = 0
var _combo: int = 0
var _round: int = 0
var _correct: int = 0
var _answered: int = 0
var _target: String = ""
var _time_left: float = ROUND_TIME
var _alive: bool = false
var _in_menu: bool = true
var _practice: bool = false
var _rng := RandomNumberGenerator.new()
var _menu: ColorRect
var _to_menu: Button

func _ready() -> void:
	_rng.randomize()
	_retry.pressed.connect(_restart_play)
	_build_shell()
	_show_menu()

func _build_shell() -> void:
	_menu = ColorRect.new()
	_menu.color = Color(0.1, 0.12, 0.18, 1)
	_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.offset_left = -140
	vb.offset_top = -130
	vb.offset_right = 140
	vb.offset_bottom = 130
	vb.add_theme_constant_override("separation", 12)
	var title := Label.new()
	title.text = "Vocaloid to GO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vb.add_child(title)
	var hi := Label.new()
	hi.name = "High"
	hi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(hi)
	var p := Button.new()
	p.text = "练习模式（不限时）"
	p.custom_minimum_size = Vector2(260, 42)
	p.pressed.connect(func() -> void: _start_mode(true))
	vb.add_child(p)
	var c := Button.new()
	c.text = "挑战模式（限时）"
	c.custom_minimum_size = Vector2(260, 42)
	c.pressed.connect(func() -> void: _start_mode(false))
	vb.add_child(c)
	_menu.add_child(vb)
	$UI.add_child(_menu)
	_to_menu = Button.new()
	_to_menu.text = "返回菜单"
	_to_menu.pressed.connect(_show_menu)
	$UI/Overlay/VBox.add_child(_to_menu)

func _show_menu() -> void:
	_alive = false
	_in_menu = true
	_overlay.visible = false
	_menu.visible = true
	$Center.visible = false
	(_menu.get_node("VBoxContainer/High") as Label).text = "最高分 %d" % SaveData.high_score
	_hud.text = "假名词点选"

func _start_mode(practice: bool) -> void:
	_practice = practice
	_in_menu = false
	_menu.visible = false
	$Center.visible = true
	_restart_play()

func _restart_play() -> void:
	_score = 0
	_combo = 0
	_round = 0
	_correct = 0
	_answered = 0
	_alive = true
	_overlay.visible = false
	_next_round()

func _process(delta: float) -> void:
	if not _alive or _in_menu or _practice:
		return
	_time_left -= delta
	_update_hud()
	if _time_left <= 0.0:
		_combo = 0
		_answered += 1
		_advance()

func _next_round() -> void:
	_round += 1
	if _round > ROUNDS:
		_end()
		return
	_time_left = ROUND_TIME
	_target = WORDS[_rng.randi_range(0, WORDS.size() - 1)]
	_prompt.text = "点选：%s" % _target
	for c in _choices.get_children():
		c.queue_free()
	var opts: Array[String] = [_target]
	while opts.size() < CHOICES:
		var w: String = WORDS[_rng.randi_range(0, WORDS.size() - 1)]
		if not opts.has(w):
			opts.append(w)
	opts.shuffle()
	for w in opts:
		var b := Button.new()
		b.text = w
		b.custom_minimum_size = Vector2(220, 48)
		var word := w
		b.pressed.connect(func() -> void: _pick(word))
		_choices.add_child(b)
	_update_hud()

func _pick(word: String) -> void:
	if not _alive or _in_menu:
		return
	_answered += 1
	if word == _target:
		_combo += 1
		_correct += 1
		_score += 50 + mini(_combo, 10) * 5
	else:
		_combo = 0
	_advance()

func _advance() -> void:
	_next_round()

func _update_hud() -> void:
	var mode := "练习" if _practice else "挑战"
	var t := "—" if _practice else ("%.1fs" % maxf(0.0, _time_left))
	_hud.text = "[%s] 得分 %d  最高 %d\n连击 %d  第 %d/%d  剩余 %s" % [
		mode, _score, SaveData.high_score, _combo, mini(_round, ROUNDS), ROUNDS, t
	]

func _end() -> void:
	_alive = false
	var acc := 0
	if _answered > 0:
		acc = int(round(100.0 * float(_correct) / float(_answered)))
	var best: int = SaveData.record(_score)
	_over_msg.text = "冲关结束\n得分 %d\n准确率 %d%%\n最高 %d" % [_score, acc, best]
	_overlay.visible = true
