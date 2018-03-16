# EDD31
# Elizabeth DeCaprio

.include "convenience.asm"
.include "display.asm"

.eqv GAME_TICK_MS 16
.eqv MAX_BULLETS 10 #how many bullets onscreen at a time

.data
# don't get rid of these, they're used by wait_for_next_frame.
last_frame_time:  .word 0
frame_counter:    .word 0
# my data 
#data for rocket ship & lives left image
dot_x: .word 32
dot_y: .word 32
dot_x1:.word 32
dot_y1:.word 32
player_image: .byte 
 	0   0   5   0   0
 	0   5   7   5   0
 	5   7   7   7   5
 	5   5   5   5   5
 	5   0   2   0   5
#data for shot(s) remaining
shots_left: .word 50
#data for bullets 
bullet_x: .byte 0:MAX_BULLETS #replaces dot_x1
bullet_y: .byte 0:MAX_BULLETS #replaces dot_y1
bullet_active: .byte 0:MAX_BULLETS
#data for frame counter 
next_bullet: .word 0
#enemy
enemy_x: .word 10
enemy_y: .word 2
enemy_left_right: .word 0
test_x: .word 32
test_y: .word 32
enemy_image: .byte
	6   0   2   0   6
 	6   6   6   6   6
 	6   7   7   7   6
 	0   6   7   6   0
 	0   0   6   0   0
#end screen
game_over: .word 0	
pat_G pat_A pat_M pat_E 
game_over1: .word 0
pat_O pat_V pat_E pat_R pat_bang 

#test
screen_width: .word 64
screen_height: .word 64
background_color: .word 0x000000


.text

# --------------------------------------------------------------------------------------------------

.globl main
main:
	# set up anything you need to here,
	# and wait for the user to press a key to start.
	jal draw_beginning_screen
	# if user presses B enter the main loop
	jal input_get_keys
	print_int s3
	beq s3, KEY_B, _main_loop


_main_loop:
	# check for input,
	# update everything,
	# then draw everything.

	jal check_input
	jal check_input_bullet
	jal move_enemies
	jal move_bullets
	jal draw_spaceship
	jal draw_lives
	jal draw_shots_left
	jal draw_bullets
	jal draw_enemies
	#what he had:
	jal	display_update_and_clear
	jal	wait_for_next_frame
	b	_main_loop 

_game_over:
	jal exit_screen
	exit


# --------------------------------------------------------------------------------------------------
# call once per main loop to keep the game running at 60FPS.
# if your code is too slow (longer than 16ms per frame), the framerate will drop.
# otherwise, this will account for different lengths of processing per frame.

wait_for_next_frame: 
enter	s0
	lw	s0, last_frame_time
_wait_next_frame_loop: 
	# while (sys_time() - last_frame_time) < GAME_TICK_MS {}
	li	v0, 30
	syscall # why does this return a value in a0 instead of v0????????????
	sub	t1, a0, s0
	bltu	t1, GAME_TICK_MS, _wait_next_frame_loop

	# save the time
	sw	a0, last_frame_time

	# frame_counter++
	lw	t0, frame_counter
	inc	t0
	sw	t0, frame_counter
leave	s0

# --------------------------------------------------------------------------------------------------
# .....and here's where all the rest of your code goes :D

draw_beginning_screen: #function
	push ra

	li a0, 0
	li a1, 0
	li a2, 64
	li a3, 64
	li v1, 7
	jal display_fill_rect


	pop ra
	jr ra

exit_screen:	#function
	push ra

	li a0 30
	li a1 30
	lw a2, game_over
	jal display_draw_text

	li a0 30
	li a1 40
	lw a2, game_over1
	jal display_draw_text

	pop ra
	jr ra

check_input: #function 	
	push ra
	jal input_get_keys

	and t2, v0, KEY_L
	beq t2, KEY_L, _check_input_subx
	_exit_left:
	and t2, v0, KEY_R
	beq t2, KEY_R, _check_input_addx
	_exit_right:
	and t2, v0, KEY_U
	beq t2, KEY_U, _check_input_suby
	_exit_up:
	and t2, v0, KEY_D
	beq t2, KEY_D, _check_input_addy
	_exit_down:
	b _check_input_exit

	_check_input_subx: #left key
	lw t0, dot_x
	sub t0, t0, 1
	sw t0, dot_x
	b _exit_left

	_check_input_addx: #right key
	lw t0, dot_x
	add t0, t0, 1
	sw t0, dot_x
	b _exit_right

	_check_input_suby: #up key
	lw t0, dot_y
	sub t0, t0, 1
	sw t0, dot_y
	b _exit_up

	_check_input_addy: #down Key
	lw t0, dot_y
	add t0, t0, 1
	sw t0, dot_y
	b _exit_down

	_check_input_exit: #}

	# dot_x = dot_x & 63;
	# dot_y = dot_y & 63;
	# $rd = $rs & $rt
	# and $rd, $rs, $rt
	lw t0 dot_x
	lw t1 dot_y

	#and t0, t0, 63
	#and t1, t1, 63

	_out_of_bounds:
	blt t0, 2, _x_less_than
	bgt t0, 57, _x_more_than
	blt t1, 46, _y_less_than
	bgt t1, 52, _y_more_than
	b _store_dot

	_x_less_than:
	add t0, zero, 2
	b _out_of_bounds
	_x_more_than:
	add t0, zero, 57
	b _out_of_bounds
	_y_less_than:
	add t1, zero 46
	b _out_of_bounds
	_y_more_than:
	add t1, zero 52
	b _out_of_bounds

	_store_dot:			
	sw t0, dot_x
	sw t1, dot_y

	pop ra 
	jr ra #end function

draw_spaceship: #function
	push ra


	lw a0, dot_x
	lw a1, dot_y
	la a2, player_image
	jal display_blit_5x5



	pop ra
	jr ra #end function

draw_lives: #function
	push ra

	li a0 58
	li a1 58
	la a2 player_image
	jal display_blit_5x5

	li a0 52
	li a1 58
	la a2 player_image
	jal display_blit_5x5

	li a0 46
	li a1 58
	la a2 player_image
	jal display_blit_5x5

	pop ra 
	jr ra #end function

draw_shots_left: #function
	push ra

	li a0 1						# a0 = 1
	li a1 58					# a1 = 58
	lw a2, shots_left 			#Loads shots_left in a2
	sub a2, a2, t7				# a2 = a2 - t7 (# of times B is pressed)
	beq a2, 0, _game_over		# fix this
	sw a2, shots_left			#stores shots_left in a2		
	jal display_draw_int 

	pop ra
	jr ra #end function

draw_enemies:
	push ra
	push s0
	push s1

	lw t5, enemy_x
	lw t6, enemy_y

	li s0, 0 			#s0 = 0 counter for inner loop
	li s1, 0			#s1 = 0 counter for outer loop 

	
		_draw_col: 
		move a0, t5
		move a1, t6
		la a2, enemy_image	#draw enemy	
		jal display_blit_5x5
		addi t6, t6, 7 		#increment t1 by 7 > t1 = t1 + 7
		inc s0
		blt s0, 4, _draw_col #if s0 < 4 loop again
	 
	 addi t5, t5, 10 		#increment by 10 > t0 = t0 + 10	
	 inc s1					#s1++
	 blt s1, 5, _update_y	#if s1<5, update y coordinates back to 2:
	 beq s1, 5, _exit_draw_enemies
	 _update_y:
	 lw t6, enemy_y		#reset y position to 2
	 li s0, 0				#reset counter
	 b _draw_col			#loop _draw_col
	_exit_draw_enemies: 
	pop s1
	pop s0
	pop ra
	jr ra 

move_bullets:
	push ra
	push s0
	#only active 0 - MAX_BULLETS
	#bge v0, MAX_BULLETS, _exit_move_bullets

	#loop bullet_active
	la t0, bullet_active
	li s0, 0
	_loop_move_bullets:					#sees what is in bullet_active[i] 
	lb t1, bullet_active(s0)
	beq t1, 1, _loop_move_bullets1		# if 1, move bullet
	beq t1, 0, _inc 					# if 0, increment 

	_loop_move_bullets1: 
	lb t3, bullet_y(s0)
	sub t3, t3, 1
	blt t3, 0, _make_into_zero
	sb t3, bullet_y(s0)
	#blt t3, 0, _make_into_zero
	#sb t3, bullet_y(s0)

	_inc:
	inc s0										#i++
	beq s0, MAX_BULLETS, _exit_move_bullets		# if s0==MAX_BULLETS, exit
	b _loop_move_bullets 						# Loop again to find bullet_active[i]=1

	#bge t3, 0, _exit_move_bullets

	# here, the bullet has gone off the screen
	# so, do something??
	_make_into_zero:
	#add t3, t3, 1 #?
	sb zero, bullet_active(s0) #store zero
	b _inc

_exit_move_bullets:
	pop s0
	pop ra
	jr ra #end function

move_enemies: #function
	push ra

	lw a0, frame_counter			#load frame_counter in a0
	li t4, 30						# t2 = 30
	rem t3, a0, t4					# t3 is the remaindr a0/t2 
	bne t3, 0, _move_enemies_exit	# if t3 == 0, exit

	lw t1, enemy_left_right

	beq t1, 0, _move_enemy_right
	beq t1, 1, _move_enemies_left

	_move_enemy_right:
	lw t0, enemy_x					#load enemy_x into t0
	addi t0, t0, 1					#t0 = t0 + 1
	bge t0, 18, _move_enemies_down	# if t0 >= 60 exit			
	sw t0, enemy_x
	b _move_enemies_exit
	
	_move_enemies_down:
	xor t1, t1, 1
	sw t1, enemy_left_right
	lw t0, enemy_y
	addi t0, t0, 1
	bge t0, 10, _move_enemies_exit
	sw t0, enemy_y
	b _move_enemies_exit
	
	_move_enemies_left:
	lw t0, enemy_x
	sub t0, t0, 1
	blt t0, 2, _move_enemies_down
	sw t0, enemy_x
	b _move_enemies_exit

	_move_enemies_exit:
	pop ra
	jr ra #end function

check_input_bullet: #function

	push ra
	push s2

	#li s2, 0 #counter to check if hitting b

	li t7, 0

	lw t0, next_bullet
	lw t1, frame_counter
	bgt t0, t1, _check_input_bullet_exit #if next_bullet frame > frame counter > don't fire bullet
	
	jal input_get_keys
	and t1, v0, KEY_B
	bne t1, KEY_B, _check_input_bullet_exit #not equal to KEY_B

	#_inc_B:
	inc t7		#keeps track how many times b is hit

	#move a0, t7
	#la a0, frame_counter
	#li v0, 1
	#syscall
	# we're firing a bullet here, make it

	lw t0, frame_counter
	addi t0, t0, 20 #add 20, 20 frames from now bgt condition wont be true
	sw t0, next_bullet

	jal search_unused_slot

	beq v0, MAX_BULLETS, _check_input_bullet_exit #no active bullets found

	# if we found an unused slot, (if v0 < MAX_BULLETS)

	#li t0, 1
	#sb t0, bullet_active(v0)

	
	#	fill in its x and y and active.
	lw t0, dot_y
	sub t0, t0, 5
	sb t0, bullet_y(v0) # bullet_y[v0] = dot_y - 5

	lw t2, dot_x
	add t2, t2, 2
	sb t2, bullet_x(v0)


	li t0, 1
	sb t0, bullet_active(v0)

_check_input_bullet_exit:
	pop s2
	pop ra
	jr ra #end function

draw_bullets: #function
	push ra
	push s1
	
	la t0, bullet_active
	li s1, 0
	#bge v0, MAX_BULLETS, _exit_draw_bullets #no bullets to draw
	#only active 

	_loop_draw_bullet:
	lb t1, bullet_active(s1)
	beq t1, 1, _draw_bullet
	
	b _inc_draw

	_draw_bullet: 
	lbu a0, bullet_x(s1)
	lbu a1, bullet_y(s1)
	li a2, COLOR_WHITE
	jal display_set_pixel
	

	_inc_draw:
	inc s1
	beq s1, MAX_BULLETS, _exit_draw_bullets
	b _loop_draw_bullet

_exit_draw_bullets:
	pop s1
	pop ra
	jr ra #end function

search_unused_slot: #function
	push ra
	push s0

	la t0, bullet_active #load address of array in t0
	li s0, 0 
 	_loop_search_slot:
 	lb t1, bullet_active(s0)
 	beq t1, 0, _exit_search_unused_slot #Can draw
 	inc s0 
 	blt s0, MAX_BULLETS, _loop_search_slot
 	#b _exit_draw_bullets

_exit_search_unused_slot:
	move v0, s0  

	pop s0
	pop ra
	jr ra #end function

#end 

