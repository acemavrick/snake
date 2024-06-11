extends Node2D

# directions [dx, dy]
enum DIRS {N, E, S, W}
const DIRMAP = {DIRS.N:[0,-1], DIRS.E:[1,0], DIRS.S:[0,1], DIRS.W:[-1, 0]}

# size (NxN) of grid
var NSQUARES = max(16, 5)

# time between frames (T = period) (sec)
var T = .1

# colors
var BGCOLOR
var APPLECOLOR
var HEADCOLOR

# default polygon definitions
var DEFPOLY = PackedVector2Array([Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)])

# whether game is on or not
static var gameOn = false
# width of squares. Recalculated every frame
var squareWidth = 0
# body (list of parts)
var body = []
# apple location
var appleLoc = Vector2i(-1, -1)
# whether the body can move
var bodyCanMove = false

# current facing direction
var cDir = null
var targetDir = null
#paused
var paused = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# reset all vars
	BGCOLOR = Color.DARK_CYAN
	APPLECOLOR = Color.DARK_RED
	HEADCOLOR = Color.DARK_ORCHID
	gameOn = false
	squareWidth = 0
	body = []
	appleLoc = Vector2i(-1, -1)
	bodyCanMove = false
	cDir = null
	targetDir = null
	paused = false
	
	update_score(0)
	init_nodes()
	refresh_width()
	if not (get_viewport().size_changed.is_connected(refresh_width)):
		get_viewport().size_changed.connect(refresh_width)
	reset_bod()
	reset_apple()
	paint_body()
	gameOn = true
	bodyCanMove = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	parse_input()
	
	# if its time to check
	if gameOn and bodyCanMove and not paused:
		# dir not set (beginning of a game)
		if targetDir == null: return
		cDir = targetDir
		
		# move body
		var head = body[0]
		var nx = head.x + DIRMAP[cDir][0]
		var ny = head.y + DIRMAP[cDir][1]
		
		if not cellValid(Vector2i(nx, ny)): 
			game_over()
			return
		
		# check if it ate an apple
		var ate = (nx == appleLoc.x and ny == appleLoc.y)
		reset_apple()
		body.insert(0, Vector2i(nx, ny))
		if !ate:
			# delete the last
			var todel = body.pop_back()
			set_color(todel.x, todel.y, BGCOLOR)
		
		update_score(len(body)-1)
		
		bodyCanMove = false
		await wait_for_frame()
		bodyCanMove = true

func update_score(x):
	%Score.text = "Score: " + str(x)

func game_over():
	gameOn = false
	print("Score = " + str(len(body)))
	HEADCOLOR = Color.INDIAN_RED
	BGCOLOR = Color.PALE_VIOLET_RED
	appleLoc = Vector2i(-1, -1)
	refresh_bg()

func parse_input():
	if Input.is_action_just_pressed("reset"):
		gameOn = false
		await destroy_nodes()
		_ready()
		return
	if Input.is_action_just_pressed("pause"):
		paused = !paused
		return
	var actdir = targetDir
	if Input.is_action_pressed("right"):
		actdir = DIRS.E
	if Input.is_action_pressed("left"):
		actdir = DIRS.W
	if Input.is_action_pressed("up"):
		actdir = DIRS.N
	if Input.is_action_pressed("down"):
		actdir = DIRS.S
		
	if !same_dirline(actdir):
		targetDir = actdir
		# make dir opposite dir 10% of the time
		#if (randint(0, 10) == 2):
			#targetDir = DIRS.values()[(DIRS.values().find(targetDir)+2)%4]

func same_dirline(dir):
	"""Checks to see if 'dir' is in the same horizontal/vertical line as cDir"""
	return cDir == dir || cDir == DIRS.values()[(DIRS.values().find(dir)+2)%4]

func reset_apple():
	"""Generates an 'apple' at a random unoccupied location"""
	while not cellValid(appleLoc):
		appleLoc = Vector2i(randint(0, NSQUARES), randint(0, NSQUARES))
	set_color(appleLoc.x, appleLoc.y, APPLECOLOR)

func cellValid(vect):
	return 0 <= vect.x and vect.x < NSQUARES \
		and 0 <= vect.y and vect.y < NSQUARES \
		and not body_contains_XY(vect.x, vect.y)
		
func reset_bod():
	'''Resets the body, placing the start at a random location.'''
	body = [Vector2i(randint(2,NSQUARES-3), randint(2, NSQUARES-3))]
	# add two in a random dir
	var dir = DIRMAP[randint(0, 3)]
	for x in range(2):
		body.append(body[0] + Vector2i(dir[0], dir[1])*(x+1))

func init_nodes():
	'''Initializes all the nodes'''
	for x in NSQUARES:
		for y in NSQUARES:
			make_node(x,y)

func paint_body():
	if len(body) == 0: 
		return false
	var ccol = HEADCOLOR
	var d = min(1.0/len(body), .1)
	for v in body:
		set_color(v.x, v.y, ccol)
		ccol = ccol.lightened(d)
	return true

func make_node(x, y):
	'''Instantiates a Polygon2D node and adds it to the tree'''
	var node = Polygon2D.new()
	node.name = gen_idstr(x, y)
	node.polygon = DEFPOLY
	add_child(node)
	set_color(x,y,Color.TRANSPARENT)

func set_color(x,y,col):
	'''Sets the square at (x,y) to color "col"'''
	retrieve_node(x, y).color = col

func refresh_bg():
	var wason = false
	if (bodyCanMove): 
		wason = true
		bodyCanMove = false
	for x in NSQUARES:
		for y in NSQUARES:
			var node = retrieve_node(x,y)
			node.scale = Vector2i(1, 1)*squareWidth
			node.position = Vector2i(x, y)*squareWidth
			node.color = BGCOLOR
	
	if cellValid(appleLoc):
		set_color(appleLoc.x, appleLoc.y, APPLECOLOR)
	paint_body()
	if (wason): bodyCanMove = true

# animation
func paint_row(x):
	for y in NSQUARES:
		#var node = retrieve_node(x, y)
		#node.color = Color.LIGHT_GREEN
		#node.scale = Vector2i(1, 1)*squareWidth
		#node.position = Vector2i(x, y)*squareWidth
		await delay(.01)

func destroy_nodes():
	'''Removes all nodes from the tree'''
	for x in NSQUARES:
		for y in NSQUARES:
			retrieve_node(x,y).free()

func retrieve_node(x,y):
	if (get_node(gen_idstr(x,y)) == null):
		print(gen_idstr(x,y))
		print(get_children())
	return get_node(gen_idstr(x,y))

func refresh_width():
	'''Recalculate the width based on the viewport dimensions.'''
	gameOn = false
	var viewportSize = get_viewport_rect().size
	var minDimension = min(viewportSize.x, viewportSize.y)
	squareWidth = minDimension/NSQUARES
	%monitor.size = viewportSize #+ Vector2(40, 40)
	#%monitor.position = Vector2(-20,-20)
	refresh_bg()
	gameOn = true

func delay(sec):
	'''Delays for "sec" seconds'''
	await get_tree().create_timer(sec).timeout

func gen_idstr(x, y):
	'''Generates the name of the node at position (x, y)'''
	return str(x) + "," + str(y)

func body_contains_XY(x, y):
	'''Checks to see whether the body has a "cell" at the position (x,y)'''
	var temp = Vector2i(x,y)
	for v in body:
		if temp == v:
			return true
	return false

func randint(lb, ub):
	"Generates and returns a random number in the range [lb, ub]"
	randomize()
	return randi_range(lb, ub)

## simultaneous async
signal all_done

var i: int:
	set(val):
		i = val
		if i == 2:
			all_done.emit()

func delay_wrapper():
	await delay(T)
	i += 1

func paint_body_wrapper():
	await paint_body()
	if i == 1:
		print("paint too long")
	i += 1

func wait_for_frame():
	i = 0
	delay_wrapper()
	paint_body_wrapper()
	await all_done
