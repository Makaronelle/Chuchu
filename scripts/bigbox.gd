extends RigidBody2D


func _on_BigBox_body_entered(body):
	print('henlo')
	if body.get_name() == 'Back' or body.get_name() == 'Level':
		self.get_node('AnimationPlayer').play('Disapear')
