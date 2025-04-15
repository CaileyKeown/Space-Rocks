extends Node

@export var rock_scene : PackedScene  # Reference to the rock scene
var screensize = Vector2.ZERO  # Stores the screen size

var level = 0
var score = 0
var playing = false

func new_game():
	get_tree().call_group("rocks", "queue_free")
	level = 0
	score = 0
	$HUD.update_score(score)
	$HUD.show_message("Get Ready!")
	$Player.reset()
	await $HUD/Timer.timeout
	playing = true

func new_level():
	level += 1
	$HUD.show_message("Wave %s" % level)
	for i in level:
		spawn_rock(3)

func game_over():
	playing = false
	$HUD.game_over()


func _process(delta):
	if not playing:
		return
	if get_tree().get_nodes_in_group("rocks").size() == 0:
		new_level()

#everything needs to go above this
func _ready():
	# Initialize screen size
	screensize = get_viewport().get_visible_rect().size
	
	# Spawn 3 rocks at the start
	for i in range(3):  
		spawn_rock(3)

# Function to spawn a rock
func spawn_rock(size, pos = null, vel = null):
	if pos == null:
		# Randomly pick a point along the RockPath for spawn location
		$RockPath/RockSpawn.progress = randi()  # Set random progress on path
		pos = $RockPath/RockSpawn.position  # Get position from the PathFollow2D node
	if vel == null:
		# Set random velocity for the rock
		vel = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(50, 125)
	
	# Instantiate the rock scene
	var r = rock_scene.instantiate()
	
	# Pass the screen size to the rock
	r.screensize = screensize
	
	# Initialize the rock with its position, velocity, and size
	r.start(pos, vel, size)  
	
	# Connect the rock's explosion signal to the _on_rock_exploded function
	r.exploded.connect(self._on_rock_exploded) 
	
	# Add the rock as a child node after instancing
	call_deferred("add_child", r)

# Handles when a rock explodes and spawns two smaller rocks (if not size 1)
func _on_rock_exploded(size, radius, pos, vel):
	# Don't spawn smaller rocks if size is 1 (smallest size)
	if size <= 1:
		return
	
	# Spawn two smaller rocks in opposite directions
	for offset in [-1, 1]:
		# Calculate direction from player to the rock and get an orthogonal vector
		var dir = $Player.position.direction_to(pos).orthogonal() * offset
		
		# Calculate new position and velocity for the smaller rocks
		var newpos = pos + dir * radius
		var newvel = dir * vel.length() * 1.1
		
		# Spawn the new smaller rock
		spawn_rock(size - 1, newpos, newvel)
