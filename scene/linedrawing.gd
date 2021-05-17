extends KinematicBody2D

onready var grappling = self.get_node('Grappling')
onready var rope = self.get_node('Rope')

var globalPosition = null

func _process(delta):
	rope.points = []
	rope.add_point(Vector2(0, 0))
	rope.add_point(Vector2(0, grappling.position[1] - 16))
