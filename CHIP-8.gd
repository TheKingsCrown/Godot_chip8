extends Node2D

@onready var PPU = $PictureProccessingUnit
@onready var CPU = $CentralProccessingUnit
@onready var MEMORY = $Memory

func _ready():
	MEMORY.initialize()
	CPU.initialize()
	PPU.initialize()
	
	MEMORY.load_rom()
