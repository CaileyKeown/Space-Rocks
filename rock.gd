extends RigidBody2D

signal exploded  # Signal to emit when the rock explodes

var screensize = Vector2.ZERO
var size
var radius
var scale_factor = 0.2

func _ready():
	# Initialize screen size
	screensize = get_viewport_rect().size

func start(_position, _velocity, _size):
	# Set position, size, and other initial properties
	position = _position
	size = _size
	mass = 1.5 * size  # Adjust mass based on size
	gravity_scale = 0
	$Sprite2D.scale = Vector2.ONE * scale_factor * size  # Scale sprite based on size
	$Explosion.scale = Vector2.ONE * 0.75 * size  # Scale explosion to match rock

	# Calculate radius for collision shape
	radius = int($Sprite2D.texture.get_size().x / 2 * $Sprite2D.scale.x)

	# Set up the collision shape
	var shape = CircleShape2D.new()
	shape.radius = radius
	$CollisionShape2D.shape = shape

	# Set initial velocities
	linear_velocity = _velocity
	angular_velocity = randf_range(-PI, PI)

func _integrate_forces(physics_state):
	# Wrap the rock's position when it goes out of bounds
	var xform = physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, -radius, screensize.x + radius)
	xform.origin.y = wrapf(xform.origin.y, -radius, screensize.y + radius)
	physics_state.transform = xform

func explode():
	# Disable collision shape and hide sprite during explosion
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.hide()
	
	# Play the explosion animation
	$Explosion/AnimationPlayer.play("explosion")
	$Explosion.show()  # Make explosion visible
	
	# Emit the exploded signal with relevant data
	exploded.emit(size, radius, position, linear_velocity)
	
	# Stop movement and wait for the animation to finish
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	
	# Wait until the explosion animation finishes
	await $Explosion/AnimationPlayer.animation_finished
	
	# Free this rock instance
	queue_free()
