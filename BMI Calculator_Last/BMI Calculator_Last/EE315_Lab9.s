;EE315_Lab9.s
; these are the EQU directives. They are for using labels instead of 
; actual hexadecimal memory locatons.
GPIO_PORTF_DATA_R  	EQU 0x400253FC
GPIO_PORTF_DIR_R   	EQU 0x40025400
GPIO_PORTF_AFSEL_R 	EQU 0x40025420
GPIO_PORTF_PUR_R   	EQU 0x40025510
GPIO_PORTF_DEN_R   	EQU 0x4002551C
GPIO_PORTF_AMSEL_R 	EQU 0x40025528
GPIO_PORTF_PCTL_R  	EQU 0x4002552C
PF1                	EQU 0x40025008
PF2                	EQU 0x40025010
PF3                	EQU 0x40025020
SYSCTL_RCGCGPIO_R  	EQU 0x400FE608
Seed				EQU 123456789

	; THUMB mean we are going to be using THUMB type ARM language. It is the language
	; we learn in this course
	THUMB
	; AREA reserves a memory location for us. 
	; "Processor please reserve a memory location for me. It will be a data memory,
	; i.e. I will put data in it (no code). 
	; And make a data alignmen for 2^2=4 bytes.
	; i.e. write my data starting from an adress location which is factor of 4. 
	AREA    |.data|, DATA, READWRITE, ALIGN=4
	; Create a global variable M. anybody, including the subroutines can reach it.
	; Red, Green, Blue will point the starting address of this memory location. 
	; and reserve 4 bytes for each.
	EXPORT Red [DATA,SIZE=4];
	EXPORT Green [DATA,SIZE=4];	
	EXPORT Blue [DATA,SIZE=4];
	; then we clear these global variable (make them zeros)
Red 	SPACE 4
Green 	SPACE 4
Blue 	SPACE 4
	
	; reserve another AREA for me, in the CODE space (i.e. Instruction memory)
	; so what I will write after this point will be instructions, not data
	; make it read only so that no body writes over it. 
	; make data alignment of 2^2=4. Start wrting my code from a memory location, 
	; which is a factor of 4
  	AREA    |.text|, CODE, READONLY, ALIGN=2
	; make Start label, which is the beginning memory location of my instructions.
	; so that I may call it from another file, or subroutine, (again make it global)
    EXPORT  Start

Start

	BL  PortF_LED_Init      ; go jump to where we prepare the leds for action        

	MOV R9,#185 ;BOY
	MOV R10,#2000 ;KILO
	MOV R11,#10000 ;Çarpma Katsayisi
	MUL R9,R9 ; BOY^2
	MUL R10,R11 ;
	UDIV R10,R9 ; R10=BMI
	CMP R10,#30
	BGE obez
	CMP R10,#25
	BGE sisman
	CMP R10,#18
	BGT normal
	CMP R10,#18
	BLE zayif
	

obez
	; turn the red on
	BL SSR_R_On
	BL Delay
	BL SSR_Off
	BL SSR_G_On
	BL Delay
	BL SSR_Off
	BL SSR_B_On
	BL Delay
	BL SSR_Off
	B obez

sisman

	BL SSR_R_On
	BL Delay
	BL SSR_Off
	B sisman
	
normal

	BL SSR_G_On
	BL Delay
	BL SSR_Off
	B normal

zayif
	
	BL SSR_R_On
	BL Delay
	BL SSR_Off
	BL SSR_G_On
	BL Delay
	BL SSR_Off
	B zayif


	
TheEnd	
	B TheEnd
; this is the subroutine for initializing the leds and swtiches. It is called once in the beginning of the main function  "Start"
PortF_LED_Init
    LDR R1, =SYSCTL_RCGCGPIO_R      	; SYSCTL_RCGCGPIO_R is for activating the clock for Port F. 
										; We do this activation here not for only the LED, but also for the switches
    LDR R0, [R1] 						; get the register vaue to r0.
    ORR R0, R0, #0x20					; set bit 5 (6th bit from left) to turn on clock of port F (all bits of F). (datasheet page 340 )
    STR R0, [R1]                  		; write it on the control register.
    NOP
    NOP
    NOP                             	; enabling the clock need 2 cyles to wait. so wait.

    LDR R1, =GPIO_PORTF_AMSEL_R     	; we disable the analog functionality using the control register Analog Mode SELecetion Register.
										; because LED is a digital device!
    LDR R0, [R1]                    	; get the register value to r0
    BIC R0, #0x0E                   	; clear bits 1-2-3 1110, which are the RGB leds.
    STR R0, [R1]                    	; write the value register. 
    
    ; this is the port control register. we have to change it to make a port F a GPIO (general purpose intput output) (datasheet p.688)
    LDR R1, =GPIO_PORTF_PCTL_R      	; r1 points to register address
    LDR R0, [R1]                    	; the value isat r0
    BIC R0, #0x000000F0             	; clear the 2nd, 3rd and 4th nibbles from left (bits 4-7, 8-11, 12-15). 
	BIC R0, #0x00000F00					; These nibbles control function of portF bits "1-2-3", the RGB Leds (datasheet page 689)
	BIC R0, #0x0000F000					;
    STR R0, [R1]                  		; write it on the register.

    
    LDR R1, =GPIO_PORTF_DIR_R       	; r1 points to port F direction register. 
    LDR R0, [R1]                    	; r0 has the register value.
    ORR R0,#0x0E                    	; port F bits 1-2-3, RGB LEDs are output,  because they are high -  1 now.
    STR R0, [R1]                    	; write the value to the register.
    
    LDR R1, =GPIO_PORTF_AFSEL_R     	; r1 points to the the alternative functions register
    LDR R0, [R1]                    	; r0 has the value of the register
    BIC R0, #0x0E                   	; clear bits 1-2-3. its AF is disabled now.
    STR R0, [R1]                    	; copy the value to the register.
    
    ; enabling the data register. 
    LDR R1, =GPIO_PORTF_DEN_R       	; r1 points the the control register
    LDR R0, [R1]                    	; ro has the register value
    ORR R0,#0x0E                    	; make the bits 1-2-3 high/1. So the RGB Leds are zero initiallf (off)
    STR R0, [R1]    					; I write the value to the registr.
    ; we are finished with the init. get out of this subroutine.
    BX  LR

; this subroutines make the led flash red	
SSR_R_On
	PUSH{r0-r1}
	LDR R1, =PF1                    ; PF1 is a label.  we reach the red led on it bit 1.
	MOV R0, #0x02                   ; write 00000010 to R0. so that bit 1 (2nd bit from left is 1)
	STR R0, [R1]                    ; copy r0 to PF1. so red led will be on.
	POP{r0-r1}
	BX  LR                          ; we are done
	
SSR_B_On
	PUSH{r0-r1}
	LDR R1, =PF2                    ; PF2 is a label.  we reach the blue led on it bit 2.
	MOV R0, #0x04                   ; write 00000100 to R0. so that bit 2 (3rd bit from left is 1)
	STR R0, [R1]                    ; copy r0 to PF2. so blue led will be on.
	POP{r0-r1}
	BX  LR                          ; we are done	
	
	
SSR_G_On
	PUSH{r0-r1}
	LDR R1, =PF3                    ; PF3 is a label.  we reach the green led on it bit 1.
	MOV R0, #0x08                   ; write 00001000 to R0. so that bit 1 (4th bit from left is 1)
	STR R0, [R1]                    ; copy r0 to PF3. so red led will be on.
	POP{r0-r1}
	BX  LR                          ; we are done	

; this subroutine turns all leds  (PF1-2-3) off
SSR_Off
	PUSH{r0-r1}
	LDR R1, =PF1                    ; PF2 is a label.  we reach the blue led on it bit 2.
	MOV R0, #0x00                   ; write 00000000 to R0. so that bit 2 (3rd bit from left is 1)
	STR R0, [R1]                    ; copy r0 to PF2. so blue led will be off
	LDR R1, =PF2                    ; PF2 is a label.  we reach the blue led on it bit 2.
	MOV R0, #0x00                   ; write 00000000 to R0. so that bit 2 (3rd bit from left is 1)
	STR R0, [R1]                    ; copy r0 to PF2. so blue led will be off
	LDR R1, =PF3                    ; PF2 is a label.  we reach the blue led on it bit 2.
	MOV R0, #0x00                   ; write 00000000 to R0. so that bit 2 (3rd bit from left is 1)
	STR R0, [R1]                    ; copy r0 to PF2. so blue led will be off
	POP{r0-r1}
	BX  LR                          ; we are done



Delay
	MOV R0,#0x4E20
waitS	
	MOV R4,#2
innerloop
	SUBS R4,#1
	BEQ outerloop
	B innerloop
outerloop
	SUBS R0,R0,#1		; subtract 1 from r0.
	CMP R0,#00			; after 2 million times, it will be zero
	BMI DelayEnd
	BNE waitS           ; not zero yet. keep looping.		
	POP {R0}			; zero. we are done yet. pop the value you've saved to R0.
DelayEnd
	BX  LR				; go back.

	ALIGN                           ; I wont write any ore code or data. but if I decide to write, you better stay aligned.
 	END				; we are really done this time. 