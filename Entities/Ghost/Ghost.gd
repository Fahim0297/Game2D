extends KinematicBody2D

var player;
var rng = RandomNumberGenerator.new();

# Ghost Movement
const FLOOR_NORMAL: = Vector2.UP;
var _velocity: = Vector2.ZERO;
export var gravity: = 800.0;
export var speed: = Vector2(20.0, 200.0);
var direction: = Vector2.ZERO;
var last_direction_x = 0;
var bounce_countdown = 0;
var animation_playing = false;

# Ghost Stats
var health = 100;
var health_max = 100;
var health_regen = 1;
signal death;

# Ghost Attack
var attack_damage = 10;
var attack_cooldown_time = 1500;
var next_attack_time = 0;

func _process(delta):
	health = min(health + health_regen * delta, health_max);
	
	var now = OS.get_ticks_msec();
	if now >= next_attack_time:
		var target = $RayCast2D.get_collider();
		if target != null and target.name == "Player" and player.health > 0:
			animation_playing = true;
			_velocity.x *= 0.1;
			if _velocity.x == 0:
				if last_direction_x > 0:
					$Sprite.play("AttackRight");
				else:
					$Sprite.play("AttackLeft");
			elif _velocity.x > 0:
				$Sprite.play("AttackRight");
			elif _velocity.x < 0:
				$Sprite.play("AttackLeft");
			next_attack_time = now + attack_cooldown_time;


func _ready():
	player = get_tree().root.get_node("Root/Player");
	rng.randomize();
	_velocity.x = -speed.x;
	


func _on_Timer_timeout():
	var player_relative_pos = player.position.x - position.x;
	
	if abs(player_relative_pos) <= 16:
		last_direction_x = _velocity.x;
		_velocity.x = 0;
		
	elif abs(player_relative_pos) <= 100 and bounce_countdown == 0:
		if player_relative_pos > 0:
			_velocity.x = speed.x;
		else:
			_velocity.x = -speed.x;
		
#	elif bounce_countdown == 0:
#		var rand = rng.randf();
#		if rand < 0.05:
#			_velocity.x = 0;
#		elif rand < 0.1:
#			var r = rng.randf();
#			if r >= 0.5:
#				direction.x = 1;
#			else:
#				direction.x = -1;
##			direction.x = abs(rng.randf() - 1);
	
	if bounce_countdown > 0:
		bounce_countdown -= 1;


func _physics_process(delta):
	_velocity.y += gravity * delta;
#	print(_velocity);
	if is_on_wall():
		_velocity.x *= -1;
		bounce_countdown = rng.randi_range(2, 5);
		
	_velocity.y = move_and_slide(_velocity, FLOOR_NORMAL).y;
	
	if not animation_playing:
		animates_ghost(_velocity);
		$AnimationPlayer.play("Float");
		_velocity.x = last_direction_x;
	
	if _velocity != Vector2.ZERO:
		if last_direction_x > 0 :
			$RayCast2D.cast_to.x = 20;
		else:
			$RayCast2D.cast_to.x = -20;
		$RayCast2D.cast_to.y = -0.1;


func animates_ghost(velocity: Vector2):
	if velocity.x == 0:
		if last_direction_x > 0:
			$Sprite.play("RightIdle");
		else:
			$Sprite.play("Left");
	elif velocity.x > 0:
		$Sprite.play("RightIdle");
		last_direction_x = velocity.x;
	elif velocity.x < 0:
		$Sprite.play("Left");
		last_direction_x = velocity.x;
#
#func arise():
#	animation_playing = true;
#	$Sprite.play("Spawn");
#
#func _on_AnimatedSprite_animation_finished() -> void:
#	if $Sprite.animation == "Spawn":
#		$Sprite.animation = "RightIdle";
#		$Timer.start();
#	animation_playing = false;


func _on_Sprite_animation_finished() -> void:
	if $Sprite.animation == 'Death':
		get_tree().queue_delete(self);
	animation_playing = false;


func hit(damage):
	health -= damage;
	if health > 0:
#		$AnimationPlayer.stop();
		$AnimationPlayer.play("Hit");
#		$AnimationPlayer.play("Float");
	else:
		$Timer.stop();
		_velocity = Vector2.ZERO;
		set_process(false);
		animation_playing = true;
		$Sprite.play("Death");
		emit_signal("death");
		


func _on_Sprite_frame_changed():
	if $Sprite.animation.begins_with("Attack") and $Sprite.frame == 4:
		var target = $RayCast2D.get_collider();
		if target != null and target.name == "Player" and player.health > 0:
			player.hit(attack_damage);
