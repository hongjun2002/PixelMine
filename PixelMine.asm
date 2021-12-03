# bitmap:
#	16x16 unit pixels
#	512 x 512 display size
#	base address: heap


.eqv	GREEN	0x0000FF00
.eqv	RED	0x00FF0000
.eqv	YELLOW	0x00FFFF00


.eqv 	WIDTH	32	#width of the screen
.eqv	HEIGHT	32	#height of the screen


.data
	trapMsg:	.asciiz	"You had fell into a trap!\nWould you like to play again?"
	gameoverMsg:	.asciiz	"GAME OVER\nWould you like to play again?"
	startMsg:	.asciiz "Capture 15 red pixels while\navoiding traps and yellow bar.\nPress OK to start!"
	wonMsg:		.asciiz "\tCongratulation!\nYou had beat the game!\nWould you like to play again?"
	
	numWins:	.asciiz "Wins: "
	
	curX:	.word	0
	curY:	.word	0
	
	RedcurX:	.word	0
	RedcurY:	.word	0
	
	LineCurX:	.word	0
	LineCurY:	.word	0
	
	pointer: .word	0
	
	.align 2
	dangerX: .space 80
	.align 2
	dangerX2: .space 40
	.align 2
	dangerAddress: .space 80
	
	
.text

	li	$v0, 9
	li	$a0, 2048	#allocate 1024 bytes of dynamic memory
	syscall
	
	sw	$v0, pointer	#store the address of the allocated memory to pointer


#When calling functions:
#a0 = X coordinate
#a1 = Y coordinate
#a2 = color of the pixel

main:
	li	$v0, 55		# prompt that tells user
	la	$a0, startMsg	# what is their goal in
	li	$a1, 1		# this game
	syscall			#(capture 15 red pixels)

	add	$a0, $0, WIDTH
	add	$a1, $0, HEIGHT	#start at the origin
	sra	$a0, $a0, 1	#with X = width / 2
	sra	$a1, $a1, 1	# Y = height / 2
	add	$a2, $0, GREEN	#color = green
	
	sw	$a0, curX	#save the current X coordinate of green pixel
	sw	$a1, curY	#save the current Y coordinate of the green pixel
	
	jal	draw_pixel	#draw the green pixel at the center
	
	jal	generateRandom	#generate an random X and Y coordinates
	
	lw	$a1, ($sp)	
	addi	$sp, $sp, 4	#retrieve the random Y coordinate from stack
	sw	$a1, RedcurY	#store Y coordinate in RedcurY
	
	lw	$a0, ($sp)	
	addi	$sp, $sp, 4	#retrieve the random X coordinate from stack
	sw	$a0, RedcurX	#store X coordinate in RedcurX
	
	add	$a2, $0, RED	#set color to Red
	jal	draw_pixel	#draw a red pixel at a random X and Y coordinate
	
	
	jal	generateRandomX	#generate random number, it will be stored in $a0
	addi	$a0, $a0, 1
	li	$a1, 0		#set Y coordinate to 0
	sw	$a0, LineCurX	#store the starting X coordinate
	sw	$a1, LineCurY	#store the Y coordinate
	add	$a2, $0, YELLOW	#color is yellow
	jal	drawLine	#draw the yellow bar
	
	
	jal	generateRandomX	#generate a random number
	move	$t8, $a0	#store the number number in t8
	li	$t9, 0		#used for loop1 counter
	la	$t7, dangerAddress	#used to store the places that are dangerous
	
	addi	$t8, $t8, -6	#decrease t8 by 6 to make sure there isn't too much traps
	
	li	$s3, 0		#used to count the points
	
	loop1:
		bge	$t9, $t8, exitLoop1	#if end of the loop, branch
		jal	generateRandom	#generate an random X and Y coordinates
	
		lw	$a1, ($sp)	
		addi	$sp, $sp, 4	#retrieve the random Y coordinate from stack
	
		lw	$a0, ($sp)	
		addi	$sp, $sp, 4	#retrieve the random X coordinate from stack
	
		jal	calcAddress	#calculate the address of XY coordinate
		
		sw	$v0, ($t7)	#store the address of the dangerous spot
		addi	$t7, $t7, 4	#go to the next index of dangerAddress
		addi	$t9, $t9, 1	#add 1 to loop counter
		
		j	loop1
		
	exitLoop1:
	li	$t7, 5		#initialize to 0, used for dropping the yellow bar	
	
	loop:
		lw	$t1, curX		#load current X coordinate of green pixel
		lw	$t2, RedcurX		#load current X coordinate of red pixel
		bne	$t1, $t2, skip		# branch to skip if not equal, go to next line if equal
		
		lw	$t1, curY		# load current Y coordinate of green pixel
		lw	$t2, RedcurY		#load current Y coordinate of red pixel
		beq	$t1, $t2, points	#branch if they are equal 
		
		skip:
		
		beqz	$t7, dropping		#branch if t7 is zero
		
		addi	$t7, $t7, -1		#decrease t7 by 1
		jal	pause			#pause for 50 ms
		
		la	$a0, dangerX		#load address of dangerX
		lw	$a1, curX		#load the current X coordinate of green pixel
		
		jal	contains		#check if the X coordinate of the green pixel is in danger zone
		
		beqz	$v0, skip1		#branch if X coordinate of green pixel is not in danger zone
		
		lw	$t1, LineCurY		#load the current Y coordinate of the yellow bar
		addi	$t1, $t1, 1		#go the the Y coordinate below that
		lw	$t2, curY		#load the current Y coordinate of the green pixel
		beq	$t1, $t2, exit 		#branch(game over) if it is right below the yellow bar
		
		
		skip1:
		
		la	$a0, dangerX		#load address of arrays of X coordinates of the yellow bar
		lw	$a1, RedcurX		#load X coordinates of red pixel
		jal	contains		#check if X coordinate of red pixel is of yellow bar
		beqz	$v0, skip2		#branch if it is not
		
		lw	$t1, LineCurY		#load current Y coordinate of the line
		addi	$t1, $t1, -1		
		lw	$t2, RedcurY
						
		beq	$t1, $t2, DrawRed	#branch if just touched the yello bar
						#it will redraw the red pixel to make it not disappear
		
		skip2:
		
		la	$a0, dangerX2		
		lw	$a1, curX
		
		jal	contains		#check if it is at the edge of the line
		
		beqz	$v0, skip3
		lw	$t1, LineCurY
		lw	$t2, curY		
		beq	$t1, $t2, exit #maybe add some visual effects
		
		skip3:
		
		lw	$a0, curX
		lw	$a1, curY
		jal	calcAddress
		
		la	$a0, dangerAddress	#check if it steps on the trap
		move	$a1, $v0		
		
		jal	contains
		bnez	$v0, trap #add some visual effects
		
		
		lw	$t0, 0xffff0000		#check if input available
		beqz	$t0, loop		#keep looping if no input
		
		lw	$s1, 0xffff0004		#get user input
		beq	$s1, 119, up		#branch to up if entered w
		beq	$s1, 115, down		#branch to down if entered s
		beq	$s1, 97, left		#branch to left if entered a
		beq	$s1, 100, right		#branch to right if entered d
		
		#beqz	$t7, dropping
		#addi	$t7, $t7, -1
		
		j	loop			#back to loop
		
		points:
			jal	generateRandom
	
			lw	$a1, ($sp)
			addi	$sp, $sp, 4
			sw	$a1, RedcurY
			
			lw	$a0, ($sp)
			addi	$sp, $sp, 4
			sw	$a0, RedcurX
			
			add	$a2, $0, RED
	
			jal	draw_pixel
			
			addi	$s3, $s3, 1
			
			bge	$s3, 15, won		#branch to won if the player reached 15 points
			
			j	loop
			
			
		DrawRed:
			lw	$a0, RedcurX
			lw	$a1, RedcurY
			add	$a2, $0, RED	
			jal	draw_pixel
			
			j	loop
			
		dropping:
			
			lw	$a0, LineCurX
			lw	$a1, LineCurY
			jal	drawBlackLine
			
			addi	$a1, $a1, 1
			bge	$a1, 32, resetLine

			sw	$a1, LineCurY
			add	$a2, $0, YELLOW	
			
			la	$t0, dangerX2
			addi	$t1, $a0, -1
			addi	$t2, $a0, 4		#store the edge of the line into dangerX2
			sw	$t1, ($t0)
			sw	$t2, 4($t0)
			
			jal	drawLine
			
			
			
			li	$t7, 5
			j	loop
			
			
		resetLine:
			jal	generateRandomX
			addi	$a0, $a0, 1
			li	$a1, 0
			sw	$a0, LineCurX
			sw	$a1, LineCurY
			add	$a2, $0, YELLOW
			jal	drawLine
			
			li	$t7, 5
			j	loop
		up:
			lw	$a0, curX
			lw	$a1, curY
			jal	drawBlackPixel		#blacken out the current green pixel
			
			addi	$a1, $a1, -1		#decrease the Y coordinate by 1 (will shift the square up)
			sw	$a1, curY
			
			add	$a2, $0, GREEN		#draw another green pixel
			jal	draw_pixel
			
			j	loop			#back to loop
			
		down:
			lw	$a0, curX
			lw	$a1, curY		#blacken out the current pixel
			jal	drawBlackPixel
			
			addi	$a1, $a1, 1		#increase the Y coordinate by 1 (will shift the square down)
			sw	$a1, curY
			
			add	$a2, $0, GREEN		#draw another green pixel
			jal	draw_pixel
			
			j	loop			#back to loop
			
			
		left:
			lw	$a0, curX
			lw	$a1, curY		#blacken out the current green pixel
			jal	drawBlackPixel
			
			addi	$a0, $a0, -1		#decrease X coordinate by 1 (will shift the square to the left)
			sw	$a0, curX
			
			add	$a2, $0, GREEN		#draw another green pixel
			jal	draw_pixel
			
			j	loop			# back to loop
			
		right:
			lw	$a0, curX
			lw	$a1, curY
			jal	drawBlackPixel
			
			addi	$a0, $a0, 1		#increase X coordinate by 1 (shift right)
			sw	$a0, curX
			
			add	$a2, $0, GREEN		#draw another green pixel
			jal	draw_pixel
			
			j	loop			#back to loop
	
	
exit:	

	lw	$a0, curX
	lw	$a1, curY
	jal	drawBlackPixel		#blacken out the green pixel
	
	lw	$a0, RedcurX
	lw	$a1, RedcurY		#blacken out the red pixel
	jal	drawBlackPixel
	
	lw	$a0, LineCurX
	lw	$a1, LineCurY		#blacken out the line
	jal	drawBlackLine
	
	
	add	$a2, $0, RED	#color = red
	jal	game_over
	
	
	li	$v0, 50			#prompt a winning message
	la	$a0, gameoverMsg		#and ask if they want to play again
	syscall
	
	bnez	$a0, noContinue	#check if user wants to play again
	
	li	$a2, 0			#color black
	jal	game_over		#blacken out the screen
	j	main			#return to main
	
	noContinue:
	
	li	$v0, 10			#exit the program
	syscall
	
	
won:
	
	lw	$a0, curX
	lw	$a1, curY
	jal	drawBlackPixel		#blacken out the green pixel
	
	lw	$a0, RedcurX
	lw	$a1, RedcurY		#blacken out the red pixel
	jal	drawBlackPixel
	
	lw	$a0, LineCurX
	lw	$a1, LineCurY		#blacken out the line
	jal	drawBlackLine
	
	
	add	$a2, $0, GREEN		#color = green
	jal	game_over		#draw game over on the screen
	
	li	$v0, 50			#prompt a winning message
	la	$a0, wonMsg		#and ask if they want to play again
	syscall
	
	bnez	$a0, noContinue1	#check if user wants to play again
	
	li	$a2, 0			#color black
	jal	game_over		#blacken out the screen
	j	main			#return to main
	
	noContinue1:
	
	li	$v0, 10			#exit the program
	syscall
	

trap:	
	
	lw	$a0, curX
	lw	$a1, curY
	jal	drawBlackPixel		#blacken out the green pixel
	
	lw	$a0, RedcurX
	lw	$a1, RedcurY		#blacken out the red pixel
	jal	drawBlackPixel
	
	lw	$a0, LineCurX
	lw	$a1, LineCurY		#blacken out the line
	jal	drawBlackLine
	
	
	add	$a2, $0, RED		#color = red
	jal	game_over
	
	
	li	$v0, 50			#prompt a winning message
	la	$a0, trapMsg		#and ask if they want to play again
	syscall
	
	bnez	$a0, noContinue2	#check if user wants to play again
	
	li	$a2, 0			#color black
	jal	game_over		#blacken out the screen
	j	main			#return to main
	
	noContinue2:
	
	li	$v0, 10			#exit the program
	syscall
	
	

#a0 = X coordinate
#a1 = Y coordinate
#a2 = color of the pixel
draw_pixel:
	mul	$t1, $a1, WIDTH		# Multiply Y coordinate by WIDTH
	add	$t1, $t1, $a0		# add X
	mul	$t1, $t1, 4		# Multiply by 4
	lw	$t2, pointer
	add	$t1, $t1, $t2		# add to MEMORY address
	sw	$a2, 0($t1)		# write the color the the address
	
	jr	$ra			# return to main program
	
	
generateRandom:
	li	$v0, 42
	li	$a0, 0			# generate random number between 1 and 63
	li	$a1, 31			# will be used for width
	syscall
	
	addi	$sp, $sp, -4
	sw	$a0, ($sp)		#store the number in the stack
	
	li	$v0, 42
	li	$a0, 0			#generate another randome number between 1 and 63
	li	$a1, 31			#used for height
	syscall
	
	addi	$sp, $sp, -4		#store the number in the stack
	sw	$a0, ($sp)
	
	jr	$ra
	
	
generateRandomX:
	li	$v0, 42
	li	$a0, 0			# generate random number between 0 and 27
	li	$a1, 26		
	syscall
	
	jr	$ra
	
drawBlackPixel:
	mul	$t1, $a1, WIDTH		# Multiply Y coordinate by WIDTH
	add	$t1, $t1, $a0		# add X
	mul	$t1, $t1, 4		# Multiply by 4
	lw	$t2, pointer
	add	$t1, $t1, $t2		# add to MEMORY address
	li	$a2, 0
	sw	$a2, 0($t1)		# write the color the the address
	
	jr	$ra			# return to main program
	
#a0 = starting X coordinate
#a1 = y coordinate
#a2 = color

drawLine:
	mul	$t1, $a1, WIDTH		# Multiply Y coordinate by WIDTH
	add	$t1, $t1, $a0		# add X
	mul	$t1, $t1, 4		# Multiply by 4
	lw	$t2, pointer
	add	$t1, $t1, $t2		# add to MEMORY address
	
	sw	$a2, 0($t1)		# write the color of the address
	sw	$a2, 4($t1)
	sw	$a2, 8($t1)
	sw	$a2, 12($t1)
	
	la	$t6, dangerX
	add	$t5, $a0, $zero
	
	sw	$t5, 0($t6)
	
	addi	$t5, $t5, 1
	sw	$t5, 4($t6)		# store the dangerous x 
	
	addi	$t5, $t5, 1
	sw	$t5, 8($t6)		# coordinates
	
	addi	$t5, $t5, 1
	sw	$t5, 12($t6)
	
	jr	$ra			#back to main program
	
#a0 = starting X coordinate
#a1 = y coordinate

drawBlackLine:
	mul	$t1, $a1, WIDTH		# Multiply Y coordinate by WIDTH
	add	$t1, $t1, $a0		# add X
	mul	$t1, $t1, 4		# Multiply by 4
	lw	$t2, pointer
	add	$t1, $t1, $t2		# add to MEMORY address
	
	li	$t3, 0
	sw	$t3, 0($t1)		# write the color to the address
	sw	$t3, 4($t1)
	sw	$t3, 8($t1)
	sw	$t3, 12($t1)
	
	jr	$ra			#return to main program
	
# a0 = array address(words)
# a1 = value we want to find

# if contains $v0 is set to 1, if not, $v0 is 0
contains:
	move	$t1, $a0	#move a0 to t1
	li	$v0, 0		#initialize v0 to 0
	conLoop:
		lb	$t2, ($t1)
		beqz	$t2, conLoopDone	#branch if end of the array
		
		lw	$t3, ($t1)		#load the content of array[i]
		addi	$t1, $t1, 4		#go to the next array index
		beq	$t3, $a1, con		#branch if the array contains the number
		
		j	conLoop			#keep looping
	con:
		li	$v0, 1			#set v0 to 1 if it contains
	conLoopDone:
		jr	$ra			#back to the main program
		
		
pause:
	
	li	$v0, 32			
	li	$a0, 50			#pause for 50 ms
	syscall
	
	jr	$ra			#back to main program
	
# a0 = X coordinate
# a1 = Y coordinate
calcAddress:
	mul	$t1, $a1, WIDTH		# Multiply Y coordinate by WIDTH
	add	$t1, $t1, $a0		# add X
	mul	$t1, $t1, 4		# Multiply by 4
	lw	$t2, pointer		
	add	$t1, $t1, $t2		#add the memory address of the heap to it
	
	move	$v0, $t1		#store the address in v0
	jr	$ra			#back to the main program
	
#a2 = color
game_over:
	add	$a0, $0, WIDTH
	add	$a1, $0, HEIGHT		#start at the origin
	sra	$a0, $a0, 1		#with X = width / 2
	sra	$a1, $a1, 1		# Y = height / 2
	
	
	addi	$a0, $a0, -10
	addi	$a1, $a1, -10			
	
	li	$t3, 0			#loop counter		
	loopG1:
		bge	$t3, 4, loopG1Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a0, $a0, -1		#X = X - 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopG1			#continue looping
		
	loopG1Done:
		li	$t3, 0			#initialize loop counter to 0
		
	loopG2:
		
		bge	$t3, 6, loopG2Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a1, $a1, 1		#Y = Y + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopG2			#continue looping
	
		
	loopG2Done:
		li	$t3, 0			#initialize loop counter to 0
		
	loopG3:
	
		bge	$t3, 4, loopG3Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a0, $a0, 1		#X = X + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopG3			#continue looping
		
		
	loopG3Done:
		li	$t3, 0
		
	loopG4:
		
		bge	$t3, 3, loopG4Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a1, $a1, -1		#Y = Y + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopG4			#continue looping
		
		
	loopG4Done:
		li	$t3, 0
	
	loopG5:
	
		bge	$t3, 2, loopG5Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a0, $a0, -1		#X = X - 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopG5			#continue looping
	
	
	loopG5Done:
	
		addi	$a1, $a1, 3		#Y = Y + 3
		addi	$a0, $a0, 5		# X = X + 5
		li	$t3, 0			#initialize loop counter to 0
	
	loopA1:
		bge	$t3, 6, loopA1Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a1, $a1, -1		#Y = Y + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopA1			#continue looping
		
		
	loopA1Done:
		li	$t3, 0			#initialize loop counter to 0
	
	loopA2:
	
		bge	$t3, 3, loopA2Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a0, $a0, 1		#X = X + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopA2			#continue looping
		
	
		
	loopA2Done:
		li	$t3, 0			#initialize loop counter to 0
	
	loopA3:
	
		bge	$t3, 7, loopA3Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a1, $a1, 1		#Y = Y + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopA3			#continue looping
		
	loopA3Done:
		li	$t3, 0			#initialize loop counter to 0
		addi	$a1, $a1, -4		#Y = Y - 4
		addi	$a0, $a0, -1		#X = X - 1
		
		
	loopA4:
	
	
		bge	$t3, 2, loopA4Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a0, $a0, -1		#X = X - 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopA4			#continue looping
		
	
	loopA4Done:
		addi	$a1, $a1, 3		#Y = Y + 3
		addi	$a0, $a0, 6		#X = X + 6
		li	$t3, 0			#initialize loop counter to 0
	
	loopM1:
		bge	$t3, 6, loopM1Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a1, $a1, -1		#Y = Y + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopM1			#continue looping
	
	

	loopM1Done:
		li	$t3, 0			#initialize loop counter to 0
	loopM2:
	
		bge	$t3, 3, loopM2Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a0, $a0, 1		#X = X + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopM2			#continue looping
		
		
	loopM2Done:
		li	$t3, 0			#initialize loop counter to 0
	
	loopM3:
	
		bge	$t3, 7, loopM3Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a1, $a1, 1		#Y = Y + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopM3			#continue looping
	
		
	loopM3Done:
		addi	$a1, $a1, -7		#Y = Y - 7
		addi	$a0, $a0, 1		#X = X + 1
		li	$t3, 0			#initialize loop counter to 0
		
	loopM4:
	
		bge	$t3, 2, loopM4Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a0, $a0, 1		#Y = Y - 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopM4			#continue looping
	
	loopM4Done:
		li	$t3, 0			#initialize loop counter to 0
	
	loopM5:
		
		bge	$t3, 7, loopM5Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a1, $a1, 1		#Y = Y + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopM5			#continue looping
	
	
	loopM5Done:
		li	$t3, 0			#initialize loop counter to 0
		addi	$a0, $a0, 3		#X = X + 3
		addi	$a1, $a1, -1		#Y = Y - 1
		
	loopE1:
	
		bge	$t3, 4, loopE1Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a0, $a0, 1		#X = X + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopE1			#continue looping
		
	
		
	loopE1Done:
		li	$t3, 0			#initialize loop counter to 0
		addi	$a0, $a0, -4		#X = X - 4
		addi	$a1, $a1, -1		#Y = Y - 1
		
	loopE2:
	
		bge	$t3, 2, loopE2Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a1, $a1, -1		#Y = Y - 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopE2			#continue looping
		
		
	loopE2Done:
		li	$t3, 0			#initialize loop counter to 0
		
	loopE3:
	
		bge	$t3, 4, loopE3Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a0, $a0, 1		#X = X + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopE3			#continue looping
	
	
	loopE3Done:
		li	$t3, 0
		addi	$a0, $a0, -4
		addi	$a1, $a1, -1
	
	loopE4:
		
		bge	$t3, 2, loopE4Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a1, $a1, -1		#Y = Y - 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopE4			#continue looping
		
		
		
	loopE4Done:
		li	$t3, 0		#initialize loop counter to 0
		
	loopE5:
	
	
		bge	$t3, 4, loopE5Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a0, $a0, 1		#X = X - 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopE5			#continue looping
		
	loopE5Done:
		add	$a0, $0, WIDTH
		add	$a1, $0, HEIGHT		#start at the origin
		sra	$a0, $a0, 1		#with X = width / 2
		sra	$a1, $a1, 1		# Y = height / 2
	
		addi	$a0, $a0, -8		#X = X - 8
		addi	$a1, $a1, 2		#Y = Y +2
	
		li	$t3, 0			#initialize loop counter to 0
		
	loopO1:
	
		bge	$t3, 5, loopO1Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a0, $a0, -1		#X = X - 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopO1			#continue looping
		
	
	loopO1Done:
		li	$t3, 0			#initialize loop counter to 0
		
	loopO2:
	
		bge	$t3, 6, loopO2Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a1, $a1, 1		#X = X - 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopO2			#continue looping
	
	loopO2Done:
		li	$t3, 0
		
	loopO3:
	
		bge	$t3, 5, loopO3Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a0, $a0, 1		#X = X + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopO3			#continue looping
	

	loopO3Done:
		li	$t3, 0		#initialize loop counter to 0
		
	loopO4:
	
	
		bge	$t3, 6, loopO4Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a1, $a1, -1		#Y = Y - 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopO4			#continue looping
	
	
	loopO4Done:
		addi	$a0, $a0, 3
		li	$t3, 0		
	loopV1:
	
		bge	$t3, 6, loopV1Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a1, $a1, 1		#Y = Y + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopV1			#continue looping
	
	
	loopV1Done:
		li	$t3, 0		#initialize loop counter to 0
	
	loopV2:
		
		
		bge	$t3, 3, loopV2Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a0, $a0, 1		#X = X + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopV2			#continue looping
		
	
	loopV2Done:
		li	$t3, 0		#initialize loop counter to 0
		
	loopV3:
	
	
		bge	$t3, 7, loopV3Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a1, $a1, -1		#Y = Y - 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopV3			#continue looping
	
	
	loopV3Done:
		li	$t3, 0		#intialize loop counter to 0
		addi	$a1, $a1, 7	# Y = Y + 7
		addi	$a0, $a0, 3	# X = X + 3
	
	
	loopE6:
		
		bge	$t3, 4, loopE6Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a0, $a0, 1		#Y = Y + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopE6			#continue looping
	
		
	loopE6Done:
		li	$t3, 0
		addi	$a0, $a0, -4
		addi	$a1, $a1, -1
		
	loopE7:
	
	
		bge	$t3, 2, loopE7Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a1, $a1, -1		#Y = Y + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopE7			#continue looping
	

	loopE7Done:
		li	$t3, 0		#initialize loop counter to 0
		
	loopE8:
	
	
		bge	$t3, 4, loopE8Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a0, $a0, 1		#Y = Y + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopE8			#continue looping
	
	
	
	loopE8Done:
		li	$t3, 0		#initialize loop counter to 0
		addi	$a0, $a0, -4	#X = X - 4
		addi	$a1, $a1, -1	#Y = Y - 1
	
	loopE9:
	
		
		bge	$t3, 2, loopE9Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a1, $a1, -1		#Y = Y + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopE9			#continue looping
	

	loopE9Done:
		li	$t3, 0
		
	loopE10:
	
	
		bge	$t3, 4, loopE10Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a0, $a0, 1		#Y = Y + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopE10			#continue looping
		
	
	loopE10Done:		
		li	$t3, 0			#initialize loop counter to 0
		addi	$a1, $a1, 6		#Y = Y + 6
		addi	$a0, $a0, 2		# X = X + 2
		
	loopR1:
		bge	$t3, 6, loopR1Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a1, $a1, -1		#Y = Y + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopR1			#continue looping
	
		
	loopR1Done:
		li	$t3, 0		#initialize loop counter to 0
	
	loopR2:
	
	
		bge	$t3, 4, loopR2Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a0, $a0, 1		#Y = Y + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopR2			#continue looping
		
		
	loopR2Done:
		li	$t3, 0
	
	loopR3:
		
		bge	$t3, 3, loopR3Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a1, $a1, 1		#Y = Y + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopR3			#continue looping
		
		
		
		
	loopR3Done:
		li	$t3, 0
		
	loopR4:
		
		bge	$t3, 4, loopR4Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a0, $a0, -1		#Y = Y - 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopR4			#continue looping
		
		
	loopR4Done:
		li	$t3, 0
		addi	$a1, $a1, 1
		addi	$a0, $a0, 3
	
	
	loopR5:
	
		
		bge	$t3, 3, loopR5Done	#branch if loop counter reached
		
		addi	$sp, $sp, -4		
		sw	$ra, ($sp)		#store the return address in stack
		
		jal	draw_pixel		#draw pixel
		
		lw	$ra, ($sp)
		addi	$sp, $sp, 4		#restore the return address
		
		addi	$a1, $a1, 1		#Y = Y + 1
		
		addi	$t3, $t3, 1		#increase the loop counter
		j	loopR5			#continue looping
	
		
	loopR5Done:
		li	$t3, 0	#initialize to 0
		
		addi	$a0, $a0, 1	#X = X + 1
		addi	$a1, $a1, -1	#Y = Y - 1
		addi	$sp, $sp, -4
		sw	$ra, ($sp)	#store the return address in the stack
		
		jal	draw_pixel	#draw pixel
		
		lw	$ra, ($sp)	#retrieve the return address from the stack
		addi	$sp, $sp, 4
		
	jr	$ra	#return to main program
