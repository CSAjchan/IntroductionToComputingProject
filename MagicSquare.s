;
; CS1022 Introduction to Computing II 2018/2019
; Magic Square
;

	AREA	RESET, CODE, READONLY
	ENTRY

	; initialize system stack pointer (SP)
	LDR	SP, =0x40010000

	LDR	R0, =arr1				;loading the first array
	LDR	R4, =size1
	LDR	R1, [R4]
	LDR R3, =1					;if r3 = 1 is magic square if r3 = 0 isn't magic square
	LDR R2, =0					;x - what the sum equals to
	BL magicSumNumber			;start of the subroutine
	
	
	LDR	R0, =arr2				;loading the second array(this array is not a magic square and is 
	LDR	R4, =size2				;added as a test measure ot check that it outputs 0 in R3)
	LDR	R1, [R4]
	LDR R3, =1					;if r3 = 1 is magic square if r3 = 0 isn't magic square
	LDR R2, =0					;x - what the sum equals to
	BL magicSumNumber			;start of the subroutine
	
	
	LDR	R0, =arr3				;loading the third array(this array is a 4x4 
	LDR	R4, =size3				;array and is added to test if it works for all sizes)
	LDR	R1, [R4]
	LDR R3, =1					;if r3 = 1 is magic square if r3 = 0 isn't magic square
	LDR R2, =0					;x - what the sum equals to
	BL magicSumNumber			;start of the subroutine

stop	B	stop


;
;magicSumNumber
;finds the magic square sum and calls other subroutines
;parameters:
;	r0 - address of magic square
;	r1 - size of magic square
;result:
;	r2 - magic square sum
;	r3 - if r3 = 1 rows are magic if r3 = 0 it is not a magic square
;
magicSumNumber

	PUSH {R4-R6, LR}
	
	LDR R5, =0					;j(column number) = 0
forloop1						;(for(j = 0; j < r1; j++))
	CMP R5, R1					
	BEQ endforloop1				
	LDR R6, =4
	MUL R6, R5, R6				;index in bytes(index*4)
	LDR R4, [R0, R6]			;z = arr1[0,j]
	ADD R2, R2, R4				;x = x + z
	ADD R5, R5, #1				;j = j + 1
	B forloop1
endforloop1

	BL checkIfRowsMagic			;this subroutine checks if rows are magic
	CMP R3, #0
	BEQ endtheprogram
	
	BL checkIfColumnsMagic		;this subroutine checks if columns are magic
	CMP R3, #0
	BEQ endtheprogram
	
	BL checkIfDiagonal1Magic	;this subroutine checks if diagonal 1 is magic
	CMP R3, #0
	BEQ endtheprogram
	
	BL checkIfDiagonal2Magic	;this subroutine checks if diagonal 2 is magic

endtheprogram

	POP {R4-R6, PC}


;
;checkIfRowsMagic
;this subroutine checks if rows are magic
;parameters:
;	r0 - address of magic square
;	r1 - size of magic square
;	r2 - magic square sum
;result:
;	r3 - if r3 = 1 rows are magic if r3 = 0 it is not a magic square
;
checkIfRowsMagic
	
	PUSH {R4-R8, LR}
	
	LDR R4, =1					;i(row number) = 0
	
forloop2						;(for(i = 0; i < r1; i++))
	CMP R4, R1
	BEQ endforloop2
	LDR R5, =0					;j(column number) = 0
	LDR R8, =0					;y - the number which is going to get checked agaisnt x(r2)
forloop3						;(for(j = 0; j < r1; j++))
	CMP R5, R1
	BEQ endforloop3				
	MUL R6, R4, R1				;index = i * r1
	ADD R6, R6, R5				;index = index + j
	LDR R7, =4					
	MUL R6, R7, R6				;index in bytes(index*4)
	LDR R7, [R0, R6]			;z = arr1[i,j] 
	ADD R8, R8, R7				;y = y + z
	
	ADD R5, R5, #1
	B forloop3
	
endforloop3
	CMP R8, R2					;if(x(r2)!=y(r8))
	BNE endwith0				;go to endwith
	
	ADD R4, R4, #1
	B forloop2
	
endforloop2						;if(x=y) leave 1 in r3
	B not0

endwith0
	LDR R3, =0					;put 0 in r3 if x!=y
	
not0							

	POP {R4-R8, PC}
	
	
;
;checkIfColumnsMagic
;this subroutine checks if columns are magic
;parameters:
;	r0 - address of magic square
;	r1 - size of magic square
;	r2 - magic square sum
;result:
;	r3 - if r3 = 1 columns are magic if r3 = 0 it is not a magic square
;
checkIfColumnsMagic

	PUSH {R4-R8, LR}
	
	LDR R4, =0					;i(row number) = 0
	
forloop4						;(for(i = 0; i < r1; i++))
	CMP R4, R1
	BEQ endforloop4
	LDR R5, =0					;i(row number) = 0
	LDR R8, =0					;y - the number which is going to get checked agaisnt x(r2)
forloop5
	CMP R5, R1					;(for(i = 0; i < r1; i++))
	BEQ endforloop5
	MUL R6, R5, R1				;index = j * r1
	ADD R6, R6, R4				;index = index + i
	LDR R7, =4
	MUL R6, R7, R6				;index in bytes(index*4)
	LDR R7, [R0, R6]			;z = arr1[i,j] 
	ADD R8, R8, R7				;y = y + z
	
	ADD R5, R5, #1
	B forloop5
	
endforloop5
	CMP R8, R2					;if(x!=y)
	BNE endwith0in2
	
	ADD R4, R4, #1
	B forloop4
	
endforloop4						;if(x=y)
	B not0in2

endwith0in2						;put 0 into r3
	LDR R3, =0
	
not0in2							;leave the 0 in r3
	
	POP {R4-R8, PC}
	
;
;checkIfDiagonal1Magic
;this subroutine checks if diagonal 1 is magic
;parameters:
;	r0 - address of magic square
;	r1 - size of magic square
;	r2 - magic square sum
;result:
;	r3 - if r3 = 1 diagonal 1 is magic if r3 = 0 it is not a magic square
;
checkIfDiagonal1Magic

	PUSH {R4-R8, LR}
	
	LDR R4, =0					;i(row number) = 0
	LDR R5, =0					;j(column number) = 0
	LDR R8, =0					;y - the number which is going to get checked agaisnt x(r2)
forloop6						;(for(i = 0, j = 0; i < r1 && j < r1; i++, j++))
	CMP R4, R1
	BEQ endforloop6
	
	MUL R6, R4, R1				;index = i * r1
	ADD R6, R6, R5				;index = index + j
	LDR R7, =4
	MUL R6, R7, R6				;index in bytes(index*4)
	LDR R7, [R0, R6]			;z = arr1[i,j] 
	ADD R8, R8, R7				;y = y + z
	
	ADD R4, R4, #1				
	ADD R5, R5, #1
	B forloop6
endforloop6

	CMP R8, R2					;if(x!=y)
	BNE endwith0in3	
	B not0in3					;if(x=y)
	
endwith0in3						
	LDR R3, =0					;put 0 into r3
not0in3							;leave 1 in r3

	POP {R4-R8, PC}
	
	
;
;checkIfDiagonal2Magic
;this subroutine checks if diagonal 2 is magic
;parameters:
;	r0 - address of magic square
;	r1 - size of magic square
;	r2 - magic square sum
;result:
;	r3 - if r3 = 1 diagonal 2 is magic if r3 = 0 it is not a magic square
;
checkIfDiagonal2Magic

	PUSH {R4-R8, LR}
	
	MOV R4, R1					;j(column number) = r1
	SUB R4, R4, #1				;i = i - 1
	LDR R8, =0					;
	LDR R5, =0					;i(row number) = 0
forloop7						;(for(i = 0, j = r1 - 1; i < r1 && j > 0; i++, j--))
	CMP R5, R1
	BEQ endforloop7
	
	MUL R6, R5, R1				;index = i * r1
	ADD R6, R6, R4				;index = index + j
	LDR R7, =4
	MUL R6, R7, R6				;index in bytes(index*4)
	LDR R7, [R0, R6]			;z = arr1[i,j] 
	ADD R8, R8, R7				;y = y + z
	
	SUB R4, R4, #1
	ADD R5, R5, #1
	B forloop7
endforloop7

	CMP R8, R2					;if(x!=y)
	BNE endwith0in4
	B not0in4					;if(x=y)
	
endwith0in4
	LDR R3, =0					;put 0 into r3 
not0in4							;leave 1 in r3

	POP {R4-R8, PC}
	

size1	DCD	3					;a 3x3 array
arr1	DCD	2,7,6				;the array
	DCD	9,5,1
	DCD	4,3,8
		
		
size2	DCD	3					;a 3x3 array
arr2	DCD	8,1,6				;the array which is not square
	DCD	3,6,7
	DCD	4,9,2
		
		
size3	DCD	4					;a 4x4 array
arr3	DCD	16,3,2,13			;the array
	DCD	5,10,11,8
	DCD	9,6,7,12
	DCD 4,15,14,1
		

	END
