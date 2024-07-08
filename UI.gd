extends Control

@onready var main = get_parent()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setScene("main")
	pass # Replace with function body.

func _on_main_died() -> void:
	visib(true)

func _on_play_button_pressed() -> void:
	visib(false)

func visib(c):
	visible = c
	setScene("main")

func setScene(n):
	var found = false
	for node in get_children():
		if not node.get_class() == "Control":
			continue
		if node.name == n:
			node.show()
			found = true
		else:
			node.hide()
	if not found:
		print("no scene found for " + n)

func update_highs(scores, speed):
	%HScores.text = """\
	High Scores (""" + str(speed) + """)
	1 - %d
	2 - %d
	3 - %d
	4 - %d
	5 - %d
	(Clear scores in Settings)""" % scores[speed]
