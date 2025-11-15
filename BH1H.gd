extends Control

@onready var enemy := preload("res://enemy.tscn")
@onready var explosion := preload("res://explosion.tscn")
@onready var rocket := preload("res://rocket.tscn")
@onready var projectile := preload("res://projectile.tscn")


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _input(event):
	if event is InputEventMouseMotion:
		%Player.position = event.position
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var instance = rocket.instantiate()
			instance.position = %Player.position
			instance.get_child(0).area_entered.connect(_hit)
			add_child(instance)


func _physics_process(_delta: float) -> void:
	for r:Node in get_tree().get_nodes_in_group("rocket"):
		r.position.y -= 10
	for p:Node in get_tree().get_nodes_in_group("projectile"):
		p.position.y += 5
	for e:Node in get_tree().get_nodes_in_group("enemy"):
		var ep = e.get_parent()
		if ep.position.y < 100:
			ep.position.y += 1
		if ep.position.y >= 100:
			ep.position.y += randi_range(-20,10)
		ep.position.x += randi_range(-10,10)


func _hit(area:Area2D):
	if !(area.is_in_group("enemy") or 
		area.is_in_group("player")):
		return
	area.set_meta("hp",area.get_meta("hp")-1)
	if area.get_meta("hp") > 0:
		return
	area.add_child(explosion.instantiate())
	if $Player/Area2D.get_meta("hp") == 0:
		get_tree().paused = true
		%GO.show()
		return
	area.remove_from_group("enemy")
	await get_tree().create_timer(1).timeout
	area.add_to_group("dead")


func _on_timer_timeout() -> void:
	var rect : Rect2 = %SpawnShape.shape.get_rect()
	var x:float = randf_range(rect.position.x, rect.position.x+rect.size.x*2)
	var y:float = randf_range(rect.position.y, rect.position.y+rect.size.y*2)
	var rand_point:Vector2 = global_position + Vector2(x,y)
	var instance = enemy.instantiate()
	instance.get_child(0).add_to_group("enemy")
	instance.get_child(0).set_meta("hp",5)
	instance.global_position = rand_point
	add_child(instance)
	if get_tree().get_node_count_in_group("enemy") > 0:
		instance = projectile.instantiate()
		instance.add_to_group("projectile")
		instance.position = get_tree().get_nodes_in_group("enemy").pick_random().get_parent().position
		instance.get_child(0).area_entered.connect(_hit)
		add_child(instance)
		
	if get_tree().get_node_count_in_group("dead") > 0:
		for node in get_tree().get_nodes_in_group("dead"):
			node.get_parent().queue_free()
