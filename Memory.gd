extends Node2D

# technically not necessary but, eh it looks cool and gives me soome freedom so, whatever.
const MEMORY_SIZE: int = 4096 # number in bytes

var memory: PackedByteArray = PackedByteArray()

func initialize() -> void:
	memory.resize(MEMORY_SIZE)
	memory.fill(0)

func load_rom() -> void:
	if not FileAccess.file_exists("res://roms/test_roms/1-chip8-logo.ch8"): print("ERROR: File not Found")
	
	var rom_file = FileAccess.open("res://roms/test_roms/1-chip8-logo.ch8", FileAccess.READ)
	while rom_file.get_position() < rom_file.get_length():
		memory[0x200 + rom_file.get_position() - 1] = rom_file.get_8()
	rom_file.close()
	

func get_instruction(address: int) -> PackedByteArray:
	return memory.slice(address, address + 2)
