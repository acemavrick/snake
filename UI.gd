extends Control

@onready var main = get_parent()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_main_died() -> void:
	visible = true


func _on_play_button_pressed() -> void:
	print("pressed")
	visible = false
