extends Control
var ocfg
var cfg
var changed
@onready var main = self.owner
@onready var dcfg = main.getdefcfg()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# refresh the configuration every time the visibility changes
	connect("visibility_changed", _on_vis_changed)
	%crt.connect("toggled", _crt_change)
	%reset.connect("pressed", _reset_defaults)
	%clearall.connect("pressed", _clear_all_hs)
	%clearlvl.connect("pressed", _clear_lvl_hs)

func _crt_change(on):
	%crt.text = "CRT " + ("ON" if on else "OFF")
	changeCfg("crt", on)

func _clear_all_hs():
	main.update_high_scores(-3)
	
func _clear_lvl_hs():
	main.update_high_scores(-2)

func _reset_defaults():
	for k in cfg.keys():
		if k != "topscores":
			changeCfg(k, dcfg[k])

func _on_vis_changed():
	if not visible:
		return

	# refresh config
	ocfg = main.exportCfg()
	cfg = ocfg.duplicate(true)
	
	refreshThings()
	set_change(false)

func refreshThings():
	var scoresBlank = cfg["topscores"][cfg["speed"]] == [0, 0, 0, 0, 0]
	%clearall.disabled = scoresBlank && len(cfg.keys()) == 1
	%clearlvl.disabled = scoresBlank
	
	# set up settings
	%crt.button_pressed = cfg["crt"]
	_on_speed_value_changed(cfg["speed"], 1)
	_on_size_changed(cfg["size"], 1)

func set_change(val):
	if changed == val:
		return
	changed = val
	%cancel.text = "Cancel" if changed else "Back"
	%save.visible = changed

func changeCfg(key, val):
	if cfg[key] != val:
		set_change(true)
		cfg[key] = val
		main.sendCfg(cfg)
		refreshThings()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_cancel_pressed() -> void:
	if changed:
		main.sendCfg(ocfg)
		set_change(false)
	%UI.setScene("main")


func _on_save_pressed() -> void:
	main.sendCfg(cfg, true)
	set_change(false)


func _on_speed_value_changed(value, c=0) -> void:
	value = snappedf(max(min(%speedSlider.max_value, float(value)), %speedSlider.min_value), .01)
	%speed.text = "%.2f" % value
	%speedSlider.set_value_no_signal(float(value))
	if c == 0:
		changeCfg("speed", value)


func _on_size_changed(value, c=0) -> void:
	value = snappedf(max(min(%sizeSlider.max_value, float(value)), %sizeSlider.min_value), .01)
	%size.text = "%.2f" % value
	%sizeSlider.set_value_no_signal(float(value))
	if c == 0:
		changeCfg("size", value)
