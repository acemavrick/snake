extends Control
var ocfg
var cfg
var changed
@onready var main = self.owner

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# refresh the configuration every time the visibility changes
	connect("visibility_changed", _on_vis_changed)
	%crt.connect("toggled", _crt_change)

func _crt_change(on):
	%crt.text = "CRT " + ("ON" if on else "OFF")
	changeCfg("crt", on)
	
func _on_vis_changed():
	if not visible:
		return

	# refresh config
	ocfg = main.exportCfg()
	cfg = ocfg.duplicate(true)
	
	# set up settings
	%crt.button_pressed = cfg["crt"]
	set_change(false)

func set_change(val):
	if changed == val:
		return
	changed = val
	%cancel.text = "Cancel" if changed else "Back"
	%save.visible = changed

func changeCfg(key, val):
	set_change(true)
	cfg[key] = val
	main.sendCfg(cfg)

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
