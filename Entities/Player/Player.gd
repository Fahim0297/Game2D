extends KinematicBody2D

# Player Stats
var health = 100;
var max_health = 100;
var health_regen = 1;
var mana = 100;
var max_mana = 100;
var mana_regen = 2;

signal player_stats_changed;

# Player Movement
const FLOOR_NORMAL: = Vector2.UP;
var _velocity: = Vector2.ZERO;
export var gravity: = 800.0;
export var speed: = Vector2(40.0, 200.0);
var last_direction_x = 0;

# Player Attack
var attack_cooldown_time = 1000;
var next_attack_time = 0;
var attack_damage = 35;
var sword_attack_playing = false;

# Shield Toss
var shield_damage = 100;
var shield_cooldown = 2000;
var next_shield = 0;
var shield_toss_playing = false;
var shield_scene = preload("res://Entities/Shield/Shield.tscn");

func _ready():
	emit_signal("player_stats_changed", self);


func _process(delta):
	# Mana regen
	var new_mana = min(mana + mana_regen * delta, max_mana);
	if new_mana != mana:
		mana = new_mana;
		emit_signal("player_stats_changed", self);
	
	# Health regen
	var new_health = min(health + health_regen * delta, max_health);
	if new_health != health:
		health = new_health;
		emit_signal("player_stats_changed", self);


func _physics_process(delta: float) -> void:
	var is_jump_interrupted: = Input.is_action_just_released("ui_up") and _velocity.y < 0.0
	var direction: = get_direction();

	_velocity = calculate_move_velocity(_velocity, direction, speed, is_jump_interrupted);
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL);
	
	if not sword_attack_playing and not shield_toss_playing:
		animates_player(direction);
		
	if direction != Vector2.ZERO:
		$RayCast2D.cast_to.x = last_direction_x * 20;
		$RayCast2D.cast_to.y = -0.01;
#		print(last_direction_x);


func get_direction() -> Vector2:
	return Vector2(
	Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
	-1.0 if Input.is_action_just_pressed("ui_up") and is_on_floor() else 1.0);


func calculate_move_velocity(linear_velocity: Vector2, direction: Vector2, speed: Vector2, is_jump_interrupted: bool) -> Vector2:
	var new_velocity: = linear_velocity;
	new_velocity.x = speed.x * direction.x;
	new_velocity.y += gravity * get_physics_process_delta_time();
	
	if direction.y == -1.0:
		new_velocity.y = speed.y * direction.y;
		
	if is_jump_interrupted:
		new_velocity.y = 0.0;
		
	if sword_attack_playing:
		new_velocity.x *= 0.2;
	
	if shield_toss_playing:
		new_velocity.x *= 0.02;
		
	return new_velocity;


func animates_player(direction: Vector2):
	if direction.x == 0:
		$Sprite.play("Player_Idle");
	elif direction.x > 0:
		$Sprite.play("Walk_Right");
		last_direction_x = direction.x;
	elif direction.x < 0:
		$Sprite.play("Walk_Left");
		last_direction_x = direction.x;
#	else:
#		$Sprite.play("Walk_Right");


func _input(event):
	if event.is_action_pressed("attack"):
		var now = OS.get_ticks_msec();
		
		if now >= next_attack_time:
			var target = $RayCast2D.get_collider();
			
			if target != null:
				if target.name.find("Ghost") >= 0:
					target.hit(attack_damage);
			sword_attack_playing = true;
			
			if last_direction_x > 0:
				$Sprite.play("Attack_Right");
			elif last_direction_x < 0:
				$Sprite.play("Attack_Left");
			next_attack_time = now + attack_cooldown_time;
	
	elif event.is_action_pressed("shield"):
		var now = OS.get_ticks_msec();
		
		if mana >= 25 and now >= next_shield:
			mana = mana - 25;
			emit_signal("player_stats_changed", self);
			shield_toss_playing = true;
			
			if last_direction_x > 0:
				$Sprite.play("ShieldToss_Right");
			else:
				$Sprite.play("ShieldToss_Left");
			
			next_shield = now + shield_cooldown;


func _on_Sprite_animation_finished():
	sword_attack_playing = false;
	shield_toss_playing = false;
	if $Sprite.animation.begins_with("Fly"):
		var shield = shield_scene.instance();
		shield.attack_damage = shield_damage;
		shield.direction.x = last_direction_x;
		shield.position = position + last_direction_x * 8;
		get_tree().root.get_node("Root").add_child(shield);


func hit(damage):
	health -= damage;
	emit_signal("player_stats_changed", self);
	if health <= 0:
		set_process(false);
		$AnimationPlayer.play("Game Over");
	else:
		$AnimationPlayer.play("Hit");
