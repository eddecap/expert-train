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
enemy_x: .word 32
enemy_y: .word 32
enemy_image: .byte
	6   0   2   0   6
 	6   6   6   6   6
 	6   7   7   7   6
 	0   6   7   6   0
 	0   0   6   0   0



.text

# --------------------------------------------------------------------------------------------------

.globl main
main:
	# set up anything you need to here,
	# and wait for the user to press a key to start.

	li  v0, 32 
	syscall
	

_main_loop:
	# check for input,
	# update everything,
	# then draw everything.

	jal check_input
	jal check_input_bullet
	jal move_bullets
	jal draw_spaceship
	jal draw_lives
	jal draw_shots_left
	jal draw_enemies
	jal draw_bullets
	#what he had:
	jal	display_update_and_clear
	jal	wait_for_next_frame
	b	_main_loop 

_game_over:
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
# git hub test
# .....and here's where all the rest of your code goes :D

check_input: #if  function 	
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

	li a0 1
	li a1 58
	li a2 50
	jal display_draw_int 

	pop ra
	jr ra #end function

draw_bullets: #function
	push ra
	
	#bge v0, MAX_BULLETS, _exit_draw_bullets #no bullets to draw
	#only active 
	lbu a0, bullet_x
	lbu a1, bullet_y
	li a2, COLOR_WHITE
	jal display_set_pixel

	_exit_draw_bullets:
	pop ra
	jr ra #end function

draw_enemies1: #function
	push ra

	#column 1
	li a0, 50
	li a1, 2

	lw a0, enemy_x
	lw a1, enemy_y
	la a2, enemy_image
	jal display_blit_5x5
	#beq a1, 23, _exit_draw_enemies
	add a1, a1, 7
	#b _draw_col1

	#column 1
	li a0 10  #x
	li a1 2   #y
	la a2 enemy_image
	jal display_blit_5x5

	li a0 10
	li a1 9
	la a2 enemy_image
	jal display_blit_5x5

	li a0 10
	li a1 16
	la a2 enemy_image
	jal display_blit_5x5

	li a0 10
	li a1 23
	la a2 enemy_image
	jal display_blit_5x5

	#column 2
	li a0 20  #y
	li a1 2   #x
	la a2 enemy_image
	jal display_blit_5x5

	li a0 20
	li a1 9
	la a2 enemy_image
	jal display_blit_5x5

	li a0 20
	li a1 16
	la a2 enemy_image
	jal display_blit_5x5

	li a0 20
	li a1 23
	la a2 enemy_image
	jal display_blit_5x5

	#column 3
	li a0 30  #y
	li a1 2   #x
	la a2 enemy_image
	jal display_blit_5x5

	li a0 30
	li a1 9
	la a2 enemy_image
	jal display_blit_5x5

	li a0 30
	li a1 16
	la a2 enemy_image
	jal display_blit_5x5

	li a0 30
	li a1 23
	la a2 enemy_image
	jal display_blit_5x5

	#column 4
	li a0 40  #y
	li a1 2   #x
	la a2 enemy_image
	jal display_blit_5x5

	li a0 40
	li a1 9
	la a2 enemy_image
	jal display_blit_5x5

	li a0 40
	li a1 16
	la a2 enemy_image
	jal display_blit_5x5

	li a0 40
	li a1 23
	la a2 enemy_image
	jal display_blit_5x5

	#column 5
	li a0 50  #y
	li a1 2   #x
	la a2 enemy_image
	jal display_blit_5x5

	li a0 50
	li a1 9
	la a2 enemy_image
	jal display_blit_5x5

	li a0 50
	li a1 16
	la a2 enemy_image
	jal display_blit_5x5

	li a0 50
	li a1 23
	la a2 enemy_image
	jal display_blit_5x5


	pop ra
	jr ra #end function

draw_enemies: #function
	push ra

	#col1
	li t0, 0
	li t1, 2
	
	lw t2, enemy_x
	lw t3, enemy_y

	add t3, t1, 0
	_draw_enemy_col1:
	add t2, t0, 10

	_draw_enemy_loop1:
	sw t2, enemy_x
	sw t3, enemy_y
	lw a0 enemy_x
	lw a1 enemy_y
	la a2, enemy_image
	jal display_blit_5x5

	beq t3, 23, _draw_enemy_column2
	add t3, t3, 7
	b _draw_enemy_col1

	_draw_enemy_column2:
	li t1, 2
	add t3, t1, 0

	_draw_enemy_col2:
	add t2, t0, 20

	_draw_enemy_loop2:
	sw t2, enemy_x
	sw t3, enemy_y
	lw a0 enemy_x
	lw a1 enemy_y
	la a2, enemy_image
	jal display_blit_5x5

	beq t3, 23, _draw_enemy_column3
	add t3, t3, 7
	b _draw_enemy_col2

	_draw_enemy_column3:
	li t1, 2
	add t3, t1, 0

	_draw_enemy_col3:
	add t2, t0, 30

	_draw_enemy_loop3:
	sw t2, enemy_x
	sw t3, enemy_y
	lw a0 enemy_x
	lw a1 enemy_y
	la a2, enemy_image
	jal display_blit_5x5

	beq t3, 23, _draw_enemy_column4
	add t3, t3, 7
	b _draw_enemy_col3

	_draw_enemy_column4:
	li t1, 2
	add t3, t1, 0

	_draw_enemy_col4:
	add t2, t0, 40

	_draw_enemy_loop4:
	sw t2, enemy_x
	sw t3, enemy_y
	lw a0 enemy_x
	lw a1 enemy_y
	la a2, enemy_image
	jal display_blit_5x5

	beq t3, 23, _draw_enemy_column5
	add t3, t3, 7
	b _draw_enemy_col4

	_draw_enemy_column5:
	li t1, 2
	add t3, t1, 0

	_draw_enemy_col5:
	add t2, t0, 50

	_draw_enemy_loop5:
	sw t2, enemy_x
	sw t3, enemy_y
	lw a0 enemy_x
	lw a1 enemy_y
	la a2, enemy_image
	jal display_blit_5x5

	beq t3, 23, _exit_draw_enemies
	add t3, t3, 7
	b _draw_enemy_col5

	_exit_draw_enemies:
	pop ra
	jr ra


check_input_bullet: #function

	push ra

	lw t0, next_bullet
	lw t1, frame_counter
	bgt t0, t1, _check_input_bullet_exit #if next_bullet frame > frame counter > don't fire bullet
	
	jal input_get_keys
	and t1, v0, KEY_B
	bne t1, KEY_B, _check_input_bullet_exit #not equal to KEY_B

	# we're firing a bullet here, make it

	lw t0 frame_counter
	addi t0, t0, 20 #add 20, 20 frames from now bgt condition wont be true
	sw t0, next_bullet

	jal search_unused_slot

	# if we found an unused slot, (if v0 < MAX_BULLETS)

	beq v0, MAX_BULLETS, _check_input_bullet_exit #no active bullets found
	
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
	pop ra
	jr ra #end function


move_bullets: #function
	push ra
	push s0
	#only active 0 - MAX_BULLETS
	#bge v0, MAX_BULLETS, _exit_move_bullets

	#loop bullet_active
	la t0, bullet_active
	li s0, 0
	_loop_move_bullets:
	lb t1, bullet_active(s0)
	beq t1, 1, _loop_move_bullets1
	beq t1, 0, _inc

	_loop_move_bullets1: 
	lb t3, bullet_y(s0)
	sub t3, t3, 1
	sb t3, bullet_y(s0)
	blt t3, 0, _make_into_zero
	#sb t3, bullet_y(s0)

	_inc:
	inc s0
	beq s0, MAX_BULLETS, _exit_move_bullets
	b _loop_move_bullets

	#bge t3, 0, _exit_move_bullets

	# here, the bullet has gone off the screen
	# so, do something??
	_make_into_zero:
	sb zero, bullet_active(s0) #store zero
	b _inc


_exit_move_bullets:
	pop s0
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
