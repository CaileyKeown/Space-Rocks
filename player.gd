extends RigidBody2D

signal lives_changed
signal dead

var reset_pos = false
var lives = 0: set = set_lives


func set_lives(value):
	lives = value
	lives_changed.emit(lives)
	if lives <= 0:
		change_state(DEAD)
	else:
		change_state(INVULNERABLE)


var screensize = Vector2.ZERO

# Player controls
@export var engine_power = 500
@export var spin_power = 8000
var thrust = Vector2.ZERO
var rotation_dir = 0

# Enum "enumeration" (creates a set of constants)
enum {INIT, ALIVE, INVULNERABLE, DEAD}
var state = INIT

func _ready():
	# Get the screen size for wrapping
	screensize = get_viewport_rect().size
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	change_state(ALIVE)
	$GunCooldown.wait_time = fire_rate

func change_state(new_state):
	match new_state:
		INIT:
			$CollisionShape2D.set_deferred("disabled", true)
		ALIVE:
			$CollisionShape2D.set_deferred("disabled", false)
		INVULNERABLE:
			$CollisionShape2D.set_deferred("disabled", true)
		DEAD:
			$CollisionShape2D.set_deferred("disabled", true)
	
	state = new_state

# Detect the input and move the ship
func _process(_delta):  # Prefix the unused delta to suppress warnings
	get_input()

func get_input():
	thrust = Vector2.ZERO
	if state in [DEAD, INIT]:
		return
	
	# Apply thrust only when "thrust" action is pressed
	if Input.is_action_pressed("thrust"):
		thrust = transform.x * engine_power
	
	rotation_dir = Input.get_axis("rotate_left", "rotate_right")

	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()

func _physics_process(_delta):  # Prefix the unused delta to suppress warnings
	# Apply thrust only if there's any thrust input
	if thrust != Vector2.ZERO:
		#apply_central_impulse(thrust)
		#print("Applying thrust")
		apply_central_force(thrust)
	
	# Apply rotation based on the direction
	if rotation_dir != 0:
		apply_torque(rotation_dir * spin_power)

func _integrate_forces(physics_state):
	# Handle screen wrap by changing the position when it goes out of bounds
	var xform = physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, -31, screensize.x + 31)
	xform.origin.y = wrapf(xform.origin.y, -31, screensize.y + 31)
	physics_state.transform = xform
	if reset_pos:
		physics_state.transform.origin = screensize / 2
		reset_pos = false

@export var bullet_scene : PackedScene
@export var fire_rate = 0.25
var can_shoot = true

func shoot():
	if state == INVULNERABLE:
		return
	can_shoot = false
	$GunCooldown.start()
	var b = bullet_scene.instantiate()
	get_tree().root.add_child(b)
	b.start($Muzzle.global_transform)

func _on_gun_cooldown_timeout() -> void:
	can_shoot = true

func reset():
	reset_pos = true
	$Sprite2D.show()
	lives = 3
	change_state(ALIVE)
	#position = get_parent().screensize / 2
	#linear_velocity = Vector2.ZERO
	#rotation = 0
