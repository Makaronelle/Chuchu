extends ReferenceRect

signal catched
signal grapReady
signal moved(quantity)

const CASE_WIDTH = 32
const LONG_PRESS_DELAY = .3
const COOLDOWN_LENGTH = 1
const MAX_GRAPPLING_LENGTH = 242
const GRAPPLING_TIME_SPEED = 1
const BOX_MARGIN = 8

export var _player := @""
onready var player := get_node(_player) as KinematicBody2D
onready var numberOfCase = ceil(self.rect_size[0]/CASE_WIDTH)
onready var tween = player.get_node('Tween')
onready var longPressTimer = player.get_node('Timer')
onready var cooldownTimer = player.get_node('Cooldown')
onready var grappling = player.get_node('Grappling')
onready var grapTween = grappling.get_node('Tween')
onready var defaultGrapplingHeight = grappling.get_position()[1]
onready var animation = grappling.get_node('AnimatedSprite')

var blue = preload('res://scene/objects/blue.tscn')
var red = preload('res://scene/objects/red.tscn')

var current = null
var operating = false
var trunkedBox = null
var decoy = null
var cooled = true
var justTaken = false

var lastXPos = null

var needsToClose = false
var goingUpFull = false

func longPress():
	longPressTimer.stop()
	
	var currentPosition = grappling.get_position()
	grapTween.interpolate_property(grappling, 'position',
		Vector2(currentPosition[0], currentPosition[1]),
		Vector2(currentPosition[0], MAX_GRAPPLING_LENGTH),
		GRAPPLING_TIME_SPEED,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT
	)
	grapTween.start()
	operating = true
	if trunkedBox == null: 
		animation.play('emptyOpening')
	
func cooledDown():
	cooled = true
	cooldownTimer.stop()

func grapTweenCompleted(object, key):
	if goingUpFull:
		goingUpFull = false
		emit_signal('grapReady')
	if operating:
		if !justTaken:
			detachBox()
	else:
		justTaken = false
		
func grapAnimationCompleted():
	#if trunkedBox and justTaken:
	#	operating = true
	#	justTaken = false
	if needsToClose:
		animation.play('emptyClosing')
		needsToClose = false
		
func onMovingStuffMove(object, key, elapsed, value):
	var moved = player.position[0] - lastXPos
	if moved < 0:
		moved = lastXPos - player.position[0]
	emit_signal('moved', moved)
	lastXPos = player.position[0]

func _ready():
	longPressTimer.connect('timeout', self, 'longPress')
	cooldownTimer.connect('timeout', self, 'cooledDown')
	
	tween.connect('tween_step', self, 'onMovingStuffMove')
	grapTween.connect('tween_completed', self, 'grapTweenCompleted')
	animation.connect('animation_finished', self, 'grapAnimationCompleted')

func _input(event):
	if event.is_action_pressed('move') and !goingUpFull:
		current = ceil(event.position[0]/CASE_WIDTH)
		if current > 0 and current <= numberOfCase:
			lastXPos = player.position[0]
			tween.remove(player)
			tween.interpolate_property(player, 'position',
				Vector2(player.position[0], player.position[1]),
				Vector2(((current -1) * CASE_WIDTH) + 16, player.position[1]),
				1,
				Tween.TRANS_SINE,
				Tween.EASE_IN_OUT
			)
			tween.start()
		if longPressTimer.is_stopped(): longPressTimer.start(LONG_PRESS_DELAY)
	elif event.is_action_released('move'):
		longPressTimer.stop()
		if operating:
			if grapTween.is_active():
				grapTween.remove(grappling)
			operating = false
			var currentPosition = grappling.get_position()
			grapTween.interpolate_property(grappling, 'position',
				Vector2(currentPosition[0], currentPosition[1]),
				Vector2(currentPosition[0], defaultGrapplingHeight),
				GRAPPLING_TIME_SPEED,
				Tween.TRANS_LINEAR,
				Tween.EASE_IN_OUT
			)
			grapTween.start()
			
			if trunkedBox == null:
				animation.play('emptyClosing')
				needsToClose = false
			else:
				emit_signal('catched')
				goingUpFull = true
			

func _on_Grappling_body_entered(body):
	if body.get_name() != 'LevelLimits':
		attachBox(body)

func attachBox(body):
	if trunkedBox == null and cooled:
		# we make the original body dis a pear
		var grappling = player.get_node('Grappling')
		body.set_collision_layer_bit(0, false)
		body.visible = false
		decoy = Sprite.new()
		decoy.texture = body.get_node('Sprite').texture
		decoy.position[1] = BOX_MARGIN
		grappling.add_child(decoy)
		grappling.move_child(decoy, 0)
		trunkedBox = body
		cooled = false
		justTaken = true
		animation.play('fullClosing')

func detachBox():
	if trunkedBox:
		var grappling = player.get_node('Grappling')
		
		var newBox = null
		if trunkedBox.get_groups().has('blue_box'):
			newBox = blue.instance()
		else:
			newBox = red.instance()
		
		newBox.set_position(Vector2(player.get_global_position()[0], grappling.get_global_position()[1] + BOX_MARGIN))
		player.get_parent().add_child(newBox)
		
		decoy.visible = false
		decoy.queue_free()
		
		trunkedBox.queue_free()
		
		trunkedBox = null
		
		if !cooled and cooldownTimer.is_stopped():
			cooldownTimer.start(COOLDOWN_LENGTH)
		
		animation.play('fullOpening')
		needsToClose = true
	
