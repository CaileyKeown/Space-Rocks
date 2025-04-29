extends RigidBody2D

signal lives_changed
signal dead
signal shield_changed

@export var max_shield = 100.0
@export var shield_regen = 5.0
var shield = 0: set = set_shield
func set_shield(value):
	value = min(value, max_shield)
	shield = value
	shield_changed.emit(shield / max_shield)
	if shield <= 0:
		lives -= 1
		explode()

#export var max_shield = 100.0
#@export var shield_regen = 5.0
#var shield = 0: set = set_shield

var reset_pos = false
var lives = 0: set = set_lives

# Enum "enumeration" (creates a set of constants)
enum {INIT, ALIVE, INVULNERABLE, DEAD}
var state = INIT

var screensize = Vector2.ZERO

# Player controls
@export var engine_power = 500
@export var spin_power = 8000
var thrust = Vector2.ZERO
var rotation_dir = 0

@export var bullet_scene : PackedScene
@export var fire_rate = 0.25
var can_shoot = true

func set_lives(value):
	lives = value
	lives_changed.emit(lives)
	if lives <= 0:
		change_state(DEAD)
	else:
		change_state(INVULNERABLE)
	shield = max_shield


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
			$Sprite2D.modulate.a = 0.5
		ALIVE:
			$CollisionShape2D.set_deferred("disabled", false)
			$Sprite2D.modulate.a = 1.0
		INVULNERABLE:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.modulate.a = 0.5
			$InvulnerabilityTimer.start()
		DEAD:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.hide()
			linear_velocity = Vector2.ZERO
			dead.emit()
	state = new_state

func _on_invulnerability_timer_timeout():
	change_state(ALIVE)

# Detect the input and move the ship
func _process(delta):  # Prefix the unused delta to suppress warnings
	if state == DEAD or state == INIT:
		return
	
	get_input()
	
	#shield regeneration
	if shield < max_shield:
		set_shield(shield + shield_regen * delta)


func get_input():
	$Exhaust.emitting = false
	thrust = Vector2.ZERO
	if state in [DEAD, INIT]:
		return
	
	# Apply thrust only when "thrust" action is pressed
	if Input.is_action_pressed("thrust"):
		thrust = transform.x * engine_power
		$Exhaust.emitting = true
		if not $EngineSound.playing:
			$EngineSound.play()
	else:
		$EngineSound.stop()
		
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


func shoot():
	if state == INVULNERABLE:
		return
	can_shoot = false
	$GunCooldown.start()
	var b = bullet_scene.instantiate()
	get_tree().root.add_child(b)
	b.start($Muzzle.global_transform)
	$LaserSound.play()

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

func _on_body_entered(body: Node) -> void:
	print("Shooting an object:")
	print(body)
	if body.is_in_group("rocks"):
		print("Ran into a rock")
		set_shield(shield - body.size * 25)
		body.explode()
	elif body.is_in_group("enemies"):
		print("Ran into an enemy")
		take_damage(1)
		body.die()
		

		
func explode():
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")
	await $Explosion/AnimationPlayer.animation_finished
	$Explosion.hide()

func take_damage(amount):
	if state != DEAD:
		set_shield(shield - amount * 25)
