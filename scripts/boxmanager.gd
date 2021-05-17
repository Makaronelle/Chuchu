extends Node2D

signal right_box_sorted
signal wrong_box_sorted

onready var ownGroups = self.get_groups()
var ownType = null

func _ready():
	if ownGroups.has('blue_exit'):
		ownType = 'blue'
	elif ownGroups.has('red_exit'):
		ownType = 'red'

func _on_Area2D_body_entered(body):
	var groups = body.get_groups()
	if groups.has('box'):
		if groups.has('red_box') and ownType == 'red':
			emit_signal('right_box_sorted')
		elif groups.has('blue_box') and ownType == 'blue':
			emit_signal('right_box_sorted')
		else:
			emit_signal('wrong_box_sorted')
		body.queue_free()
