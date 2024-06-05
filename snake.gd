extends Node2D

# Highest: 43, Raul

# directions [dx, dy]
enum DIRS {N, E, S, W}
const DIRMAP = {DIRS.N:[0,-1], DIRS.E:[1,0], DIRS.S:[0,1], DIRS.W:[-1, 0]}

# size (NxN) of grid
const NSQUARES = 16

# time between frames (T = period) (sec)
const T = .1

# colors
var BGCOLOR = Color.DARK_CYAN
var BODYCOLOR = Color.ORCHID
var APPLECOLOR = Color.DARK_RED
var HEADCOLOR = BODYCOLOR.darkened(.1)

# default polygon definitions
static var DEFPOLY = PackedVector2Array([Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)])

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
# color change registry
var changes = {BGCOLOR:[], BODYCOLOR:[], APPLECOLOR:[]}
#paused
var paused = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# reset all vars
	BGCOLOR = Color.DARK_CYAN
	BODYCOLOR = Color.ORCHID
	APPLECOLOR = Color.DARK_RED
	HEADCOLOR = BODYCOLOR.darkened(.1)
	gameOn = false
	squareWidth = 0
	body = []
	appleLoc = Vector2i(-1, -1)
	bodyCanMove = false
	cDir = null
	targetDir = null
	changes = {BGCOLOR:[], BODYCOLOR:[], APPLECOLOR:[]}
	paused = false
	
	update_score(0)
	init_nodes()
	refresh_width()
	if not (get_viewport().size_changed.is_connected(refresh_width)): get_viewport().size_changed.connect(refresh_width)
	reset_bod()
	reset_apple()
	repaint()
	gameOn = true
	bodyCanMove = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	parse_input()
	if !gameOn: return
	
	# if its time to check
	if bodyCanMove and not paused:
		if targetDir == null: return
		cDir = targetDir
		
		# move body
		var head = body[0]
		var nx = head.x + DIRMAP[cDir][0]
		var ny = head.y + DIRMAP[cDir][1]
		
		if !cellValid(Vector2i(nx, ny)): 
			game_over()
			return
		
		# check if it ate an apple
		var ate = nx == appleLoc.x and ny == appleLoc.y
		reset_apple()
		body.insert(0, Vector2i(nx, ny))
		#set_color(nx, ny, HEADCOLOR)
		#set_color(head.x, head.y, BODYCOLOR)
		if !ate:
			# delete the last
			var todel = body.pop_back()	
			set_color(todel.x, todel.y, BGCOLOR)
		update_score(len(body)-1)
		paint_body()
		
		bodyCanMove = false
		await delay(T)
		bodyCanMove = true

func update_score(x):
	%Score.text = "Score: " + str(x)

func game_over():
	gameOn = false
	print("Score = " + str(len(body)))
	BODYCOLOR = Color.INDIAN_RED
	BGCOLOR = Color.PALE_VIOLET_RED
	appleLoc = Vector2i(-1, -1)
	refresh_bg()

func repaint():
	'''Repaints everything in the "changes" dictionary'''
	for color in changes:
		for n in changes[color]:
			set_color(n.x, n.y, color)
			changes[color].remove_at(0)

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
	changes[BGCOLOR].append_array(body)
	body = [Vector2i(randint(2,NSQUARES-2), randint(2, NSQUARES-2))]
	changes[BODYCOLOR].append(body[0])

func init_nodes():
	'''Initializes all the nodes'''
	for x in NSQUARES:
		for y in NSQUARES:
			make_node(x,y)

func paint_body():
	if len(body) == 0: return
	var ccol = BODYCOLOR.darkened(.5)
	var d = 1.0/len(body)
	for v in body:
		set_color(v.x, v.y, ccol)
		ccol = ccol.lightened(d)

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
