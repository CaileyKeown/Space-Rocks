extends Area2D

@export var speed = 1000
var velocity = Vector2.ZERO

# Start method to initialize the bullet's transform and velocity
func start(_transform):
	transform = _transform
	velocity = transform.x * speed
	add_to_group("bullet")  # Add bullet to "bullet" group for collision detection

# Update the bullet's position based on velocity
func _process(delta):
	position += velocity * delta

# When the bullet exits the screen, remove it from the scene
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

# Handle collision with other bodies
func _on_bullet_body_entered(body):
	print("Shooting an object:")
	print(body)
	if body.is_in_group("rocks"):  # If the bullet hits a rock
		body.explode()  # Assume rock has an explode method
		queue_free()  # Remove the bullet
	elif body.is_in_group("enemies"):  # If the bullet hits an enemy
		body.take_damage(1)  # Call the take_damage method of the enemy
		queue_free()  # Remove the bullet
