extends Area2D

var tilemap;
var speed = 80;
var direction : Vector2;
var attack_damage;

func _ready():
	tilemap = get_tree().root.get_node("Root/FloorBack");


func _process(delta):
	position = position + speed * delta * direction;


func _on_Shield_body_entered(body):
	if body.name == "Player":
		return;
	
	if body.name == "FloorBack":
		var cell_coord = tilemap.world_to_map(position);
		var cell_type_id = tilemap.get_cellv(cell_coord);
		if cell_type_id == tilemap.tile_set.find_tile_by_name("FloorTop"):
			return;
	
	if body.name.find("Ghost") >= 0:
		body.hit(attack_damage);
	
	direction = -direction;
	$AnimatedSprite.play("FlyBack");


func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "FlyBack":
		get_tree().queue_delete(self);


func _on_Timer_timeout():
	$AnimatedSprite.play("FlyBack");
