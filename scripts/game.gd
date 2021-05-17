extends Node2D

const TIME_TO_RESET = 2
const MOVE_HEAT = 1.5
const COOLDOWN_QUANTITY = 10
const TIME_UNTIL_DEATH = 5
const DEFAULT_LIFE = 5

onready var timer = self.get_node('UI/Timer')
onready var kyumi = self.get_node('UI/AnimatedSprite')
onready var label = self.get_node('UI/Says')
onready var cooldown = self.get_node('UI/CoolingDown')
onready var dedtimer = self.get_node('UI/Ded')
onready var heatBar = self.get_node('UI/TextureProgress')
onready var particle = self.get_node('UI/Particles2D')
onready var player = self.get_node('Player')
onready var playerPart = player.get_node('Particles2D')
onready var litScreen = self.get_node('ScreenLit')
onready var tween = self.get_node('UI/Tween')
onready var gameOver = self.get_node('GameOver')
onready var gameOverAnim = gameOver.get_node('AnimationPlayer')
onready var mistakeLabel = self.get_node('UI/MistakeLeft')

var heat = 0
var maxHeat = 1000
var life = DEFAULT_LIFE

var skipCooling = false
var dead = false

func resetTimer():
	if !dead:
		kyumi.play('Idle')
		label.text = ''
		label.visible = false
	
func coolingDown():
	if !skipCooling:
		if !dead:
			heat -= COOLDOWN_QUANTITY
			if heat < 0:
				heat = 0
			updateHeatBar()
	else:
		skipCooling = false
		
func died():
	gameOverAnim.play('GameOver')
	dead = true
	kyumi.play('NotGood')
	label.text = 'Big sad'
	label.visible = true
	dedtimer.stop()
	
func fired():
	gameOverAnim.play('Fired')
	mistakeLabel.visible = false
	dead = true
	kyumi.play('NotGood')
	label.text = 'Woops'
	label.visible = true
	dedtimer.stop()
	
func _ready():
	timer.connect('timeout', self, 'resetTimer')
	dedtimer.connect('timeout', self, 'died')
	cooldown.connect('timeout', self, 'coolingDown')
	updateMistakeLeft()

func _on_right_box_sorted():
	kyumi.play('Good')
	label.visible = true
	label.text = 'Good!'
	timer.stop()
	timer.start(TIME_TO_RESET)


func _on_wrong_box_sorted():
	kyumi.play('NotGood')
	label.visible = true
	label.text = 'Nooo!'
	timer.stop()
	timer.start(TIME_TO_RESET)
	life -= 1
	if life < 0:
		life = 0
		fired()
	updateMistakeLeft()


func _on_catched():
	kyumi.play('Reloading')
	label.visible = true
	label.text = 'Got one!'


func _on_grapReady():
	resetTimer()


func _on_moved(quantity):
	heat += MOVE_HEAT * quantity
	if heat > maxHeat:
		heat = maxHeat
	updateHeatBar()
	skipCooling = true
	
func updateHeatBar():
	if !dead:
		heatBar.value = (heat+0.01)/maxHeat
		if heatBar.value > .8:
			kyumi.play('NotGood')
			label.visible = true
			label.text = 'Hot hot!'
			timer.stop()
			timer.start(TIME_TO_RESET)
			particle.emitting = true
			playerPart.emitting = true
			if dedtimer.is_stopped(): 
				dedtimer.start(TIME_UNTIL_DEATH)
				tween.remove(litScreen)
				tween.interpolate_property(litScreen, 'modulate',
					litScreen.modulate, Color(1, 1, 1, .8),
					TIME_UNTIL_DEATH,
					Tween.TRANS_LINEAR, Tween.EASE_IN
				)
				tween.start()
				
		else:
			particle.emitting = false
			playerPart.emitting = false
			if !dedtimer.is_stopped():
				tween.remove(litScreen)
				tween.interpolate_property(litScreen, 'modulate',
					litScreen.modulate, Color(1, 1, 1, 0),
					TIME_UNTIL_DEATH,
					Tween.TRANS_LINEAR, Tween.EASE_IN
				)
				tween.start()
				dedtimer.stop()

func updateMistakeLeft():
	mistakeLabel.text = 'Mistake'
	if life > 1:
		mistakeLabel.text += 's'
	mistakeLabel.text += ' left: ' + str(life)
