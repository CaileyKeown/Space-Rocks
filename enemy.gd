extends CharacterBody2D

@export var bullet_scene : PackedScene
@export var speed = 150
@export var rotation_speed = 120
@export var health = 3
@export var enemy_bullet_scene: PackedScene
@export var enemy_fire_rate = 2.0
@export var bullet_spread = 0.2

var enemy_gun_cooldown = 0.0
var target = null

var follow = PathFollow2D.new()

func _ready():
	$Sprite2D.frame = randi() % 3  # Randomly choose a saucer frame.
	var path = $EnemyPaths.get_children()[randi() % $EnemyPaths.get_child_count()]
	path.add_child(follow)
	follow.loop = false  # Do not loop the path.

func _physics_process(delta):
	rotation += deg_to_rad(rotation_speed) * delta
	follow.progress += speed * delta
	position = follow.global_position

	enemy_gun_cooldown -= delta
	if enemy_gun_cooldown <= 0:
		shoot_enemy_bullet()
		enemy_gun_cooldown = enemy_fire_rate

	if follow.progress_ratio >= 1:
		queue_free()  # Remove enemy once it reaches the end of the path.

# Example for taking damage (called when hit by bullets).
func take_damage(amount):
	health -= amount
	if health <= 0:
		die()  # Trigger the death sequence.

# Enemy death - trigger explosion and remove the enemy.
func die():
	# Disable collision shape and hide sprite during explosion
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.hide()
	
	# Play the explosion animation
	$Explosion/AnimationPlayer.play("explosion")
	$Explosion.show()  # Make explosion visible
	
	# Wait until the explosion animation finishes
	await $Explosion/AnimationPlayer.animation_finished
	
	# Free this rock instance
	queue_free()

func shoot_enemy_bullet():
	var bullet = enemy_bullet_scene.instantiate()
	bullet.position = position
	get_parent().add_child(bullet)
