extends Node2D

@onready var PPU = $"../PictureProccessingUnit"
@onready var MEMORY = $"../Memory"
@onready var IOHANDLER = $"../IOHandler"

# Determines how fast the interpreter runs/executes it's cycles in hz.
# This is irrelevant to the timer registers which always decrement at 60hz
@export var mclock_speed: float

var last_time = 0
var current_time = Time.get_ticks_msec()

# Registers are just PackedByteArrays and works perfectly for this.
var iregister: PackedByteArray = PackedByteArray()
var vregsiters: PackedByteArray = PackedByteArray()
var pc: int = 0x200
var stack: Array = []

func initialize():
	#Each byte in the PackedByteArray represents 1 Register, and each is initialized to 0.
	iregister.resize(2)
	iregister.fill(0)
	vregsiters.resize(16)
	vregsiters.fill(0)

# The main clock, utilizing a fetch, decode, execude cycle.
func _process(_delta):
	current_time = Time.get_ticks_msec()
	if current_time - last_time < mclock_speed: return
	last_time = current_time
	
	# fetch part of the cycle, stupidly simple to implement
	var instruction: PackedByteArray = MEMORY.get_instruction(pc)
	pc += 2
	
	decode(instruction)
	#if instruction == 0x00e0:
		#PPU.clear_screen()
	#elif instruction[0] in range(0x1000, 0x1fff):
		#pass
	

# Decodes the instruction and executes it.
func decode(instruction):
	var nibble_instruction = get_nibble_array(instruction)
	match nibble_instruction[0]:
		0x0:
			var byte = combine_nibbles(nibble_instruction.slice(2))
			match byte:
				0xE0: #clear screen instruction
					PPU.clear_screen()
				0xEE: #return from subroutine instruction
					if stack.is_empty(): return
					pc = stack.pop_back()
		0x1: # jump instruction
			pc = combine_nibbles(nibble_instruction.slice(1))
		0x2: # start subroutine instruction
			pc = combine_nibbles(nibble_instruction.slice(1))
		0x3: # skip if vx is = nn
			var x = vregsiters[nibble_instruction[1]]
			if x == combine_nibbles(nibble_instruction.slice(2)): pc  += 2
		0x4: #skip if vx is != nn
			var x = vregsiters[nibble_instruction[1]]
			if x != combine_nibbles(nibble_instruction.slice(2)): pc  += 2
		0x5: #skip if vx is = vy
			var x = vregsiters[nibble_instruction[1]]
			var y = vregsiters[nibble_instruction[2]]
			if x == y: pc += 2
		0x6: # set vregister instruction
			vregsiters[nibble_instruction[1]] = combine_nibbles(nibble_instruction.slice(2))
		0x7: # add to vregister instruction
			vregsiters[nibble_instruction[1]] = vregsiters[nibble_instruction[1]] + combine_nibbles(nibble_instruction.slice(2))
		0x8:
			match nibble_instruction[3]:
				0x0: # set vx to vy
					vregsiters[nibble_instruction[1]] = vregsiters[nibble_instruction[2]]
				0x1: # do binary or
					vregsiters[nibble_instruction[1]] |= vregsiters[nibble_instruction[2]]
				0x2: # do binary and
					vregsiters[nibble_instruction[1]] &= vregsiters[nibble_instruction[2]]
				0x3: #do binary xor
					vregsiters[nibble_instruction[1]] ^= vregsiters[nibble_instruction[2]]
				0x4: #add vx and vy
					var x = vregsiters[nibble_instruction[1]]
					var y = vregsiters[nibble_instruction[2]]
					x =+ y
					if x > 0xff: vregsiters[0xf] = 1
					else: vregsiters[0xf] = 0
					vregsiters[nibble_instruction[1]] = x
				0x5: #subtract vx - vy
					var x = vregsiters[nibble_instruction[1]]
					var y = vregsiters[nibble_instruction[2]]
					x = x - y
					if x > y: vregsiters[0xf] = 1
					else: vregsiters[0xf] = 0
				0x6: # vx = vy, shift vx right
					vregsiters[nibble_instruction[1]] = vregsiters[nibble_instruction[2]]
					var bits = get_bitflag_array(vregsiters.slice(nibble_instruction[1], nibble_instruction[1] + 1))
					vregsiters[0xf] = bits[7]
					vregsiters[nibble_instruction[1]]>>1
				0x7: #subtract vy - vx
					var x = vregsiters[nibble_instruction[1]]
					var y = vregsiters[nibble_instruction[2]]
					x = y - x
					if y > x: vregsiters[0xf] = 1
					else: vregsiters[0xf] = 0
				0xE:
					vregsiters[nibble_instruction[1]] = vregsiters[nibble_instruction[2]]
					var bits = get_bitflag_array(vregsiters.slice(nibble_instruction[1], nibble_instruction[1] + 1))
					vregsiters[0xf] = bits[0]
					vregsiters[nibble_instruction[1]]<<1
		0x9: #skip if vx is != vy
			var x = vregsiters[nibble_instruction[1]]
			var y = vregsiters[nibble_instruction[2]]
			if x != y: 
				pc += 2
		0xA: # set iregister instruction
			var new_value: PackedByteArray = PackedByteArray()
			new_value.resize(2)
			new_value.encode_u16(0, combine_nibbles(nibble_instruction.slice(1)))
			iregister = new_value
		0xB: #jump with offset
			pc = combine_nibbles(nibble_instruction.slice(1)) + vregsiters[0x0]
		0xC: #generate random number and, and it.
			vregsiters[nibble_instruction[1]] = (randi() % 255) + combine_nibbles(nibble_instruction.slice(2))
		0xD: # draw instruction
			var x = vregsiters[nibble_instruction[1]] % 64
			var y = vregsiters[nibble_instruction[2]] % 32
			vregsiters[0xF] = 0
			for n in range(nibble_instruction[3]):
				if y + n > 32: break
				var packed_sprite_data: PackedByteArray = MEMORY.memory.slice(iregister.decode_u16(0) + n, iregister.decode_u16(0) + n + 1)
				var sprite_data = get_bitflag_array(packed_sprite_data)
				for bit in range(sprite_data.size()):
					if x + bit > 64: break
					if sprite_data[bit]:
						if PPU.change_pixel(x + int(bit), y + n): vregsiters[0xf] = 1
			PPU.draw_buffer()
		0xE:
			match combine_nibbles(nibble_instruction[2]):
				0x9E: # Skip if key vx is pressed
					if vregsiters[nibble_instruction[1]] == IOHANDLER.last_key_pressed: pc += 2
				0xA1:
					if vregsiters[nibble_instruction[1]] != IOHANDLER.last_key_pressed: pc += 2

# seperates the instruction into nibbles, I have no idea why godot doesn't have this natively.
func get_nibble_array(instruction) -> Array:
	var nibbles = []
	for i in range(2):
		for first in range(2):
			var nibble = instruction[i]
			if first == 0:
				nibble |= 0x0F
				nibble ^= 0x0F
				nibble %= 0xF
				nibbles.append(nibble)
			else:
				nibble |= 0xF0
				nibble ^= 0xF0
				nibbles.append(nibble)
	return nibbles

# combines a nibble array into a single number, again native implementation would be nice.
func combine_nibbles(nibble_array: Array) -> int:
	var place_value = 0x1
	var total = 0x0
	nibble_array.reverse()
	for nibble in nibble_array:
		total += nibble * place_value
		place_value *= 0x10
	nibble_array.reverse()
	return total

# converts a byte into a series of true/false's to act as bits and throws them into an array.
func get_bitflag_array(byte: PackedByteArray) -> Array:
	var decimal = byte.decode_u8(0) 
	var bitflag_array = []
	bitflag_array.resize(8)
	bitflag_array.fill(false)
	
	for i in range(8):
		if decimal % 2 == 1: bitflag_array[i] = true
		decimal /= 2
	
	bitflag_array.reverse()
	return bitflag_array

# Seperate cycle for the sound and delay timers which are decremented at a fixed rate of 60hz,
# because of that the _physics_process() function works perfectly for this.
func _physics_process(_delta):
	pass
