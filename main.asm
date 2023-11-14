;nasm -f elf64 main.asm
section	.data
	ICANON:		equ	1<<1
	msg		dw	"msg", 10, 0
	;test string
	ten		db	10, 0
	zero		dw	48, 0
	;ascii value for 0 char
	newl		dw	10, 0
	;ascii value for newline char
	blank		dw	32, 0
	;ascii value for whitespace char
	printbuf	times 256	dw	0
	;printbuffer
	inph		dq	1
	;size of input box
	contl		dw	"╔", 0
	contr		dw	"╗", 0
	conbl		dw	"╚", 0
	conbr		dw	"╝", 0
	conh		dw	"═", 0
	conv		dw	"║", 0
	conjl		dw	"╠", 0
	conjr		dw	"╣", 0
	;^^^connectors for window^^^
	setcur		dw	13, 27, 91, 49, 67, 27, 91, 48, 65, 27, 91, 49, 59, 51, 53, 109, "Send Message - ", 27, 91, 48, 109, 0
	;cursor set + message prompt, word for height offset is at word[setcur+14]
	curhome		dw	27, 91, 72, 0
	;move cursor to home position
	c_reset		dw	27, 91, 48, 109, 0
	c_bold		dw	27, 91, 49, 109, 0
	c_white		dw	27, 91, 49, 59, 57, 55, 109, 0
	;^^^colours / extra formatting^^^
	inppos		dw	0
	inpposraw	dw	0
	linlen		dw	30
	;position in input buffer and count of chars on line (used in IPROC)
	llen		dw	15
	;length of current input line (used in IPROC)
	linenum		dw	-1
	;line count
	clear		dw	27, 91, 74, 0
	;clear escape
	tboxc		dw	27, 91, 72, 27, 91, 48, 48, 48, 66, 27, 91, 48, 48, 48, 67, 0
	;position to move cursor to to start drawing window
	tbox		dw	"╔═════════════════╗", 27, 91, 49, 66, 27, 91, 49, 57, 68, "║ I will be a -   ║", 27, 91, 49, 66, 27, 91, 49, 57, 68, "║ ", 27, 91, 49, 109, "(C)", 27, 91, 48, 109, "lient        ║", 27, 91, 49, 66, 27, 91, 49, 57, 68, "║ ", 27, 91, 49, 109, "(S)", 27, 91, 48, 109, "erver        ║", 27, 91, 49, 66, 27, 91, 49, 57, 68, "╚═════════════════╝", 27, 91, 72, 0
	cbox		dw	"╔═════════════════╗", 27, 91, 49, 66, 27, 91, 49, 57, 68, "║ Enter server IP ║", 27, 91, 49, 66, 27, 91, 49, 57, 68, "║                 ║", 27, 91, 49, 66, 27, 91, 49, 57, 68, "║                 ║", 27, 91, 49, 66, 27, 91, 49, 57, 68, "╚═════════════════╝", 27, 91, 49, 65, 27, 91, 49, 56, 68, 0
	dbox		dw	"╔═════════════════╗", 27, 91, 49, 66, 27, 91, 49, 57, 68, "║ Enter your name ║", 27, 91, 49, 66, 27, 91, 49, 57, 68, "║                 ║", 27, 91, 49, 66, 27, 91, 49, 57, 68, "║                 ║", 27, 91, 49, 66, 27, 91, 49, 57, 68, "╚═════════════════╝", 27, 91, 49, 65, 27, 91, 49, 56, 68, 0
	;initialisation windows
	init		db	1
	;is program being initialised
	hostmode	db	2
	;if the program is a client or server
	savecur		dw	27, 55, 0
	loadcur		dw	27, 56, 0
	;self explanatory
	msgcur		dw	27, 91, 72, 27, 91, 49, 66, 0
	;cursor position to move to top
	msgplace	dw	2
	;place in message log
section	.bss
	ws:		resw	8	;buffer for terminal dimensions
	timev:
		tv_sec	resq	1	;buffer for time to sleep, in seconds
		tv_usec	resq	1	;time in nanoseconds
	termios:
		c_iflag	resd	1	;current terminal info buffer
		c_oflag	resd	1	;.....
		c_cflag	resd	1	;....
		c_lflag	resd	1	;...
		c_line	resb	1	;..
		c_cc	resb	1	;.
	ibuf:		resw	8	;input buffer, used to store singular chars
	inpbuf:		resw	356	;buffer for inputed characters, extra 100 words for newl esc sequences
	inpbufraw:	resw	256	;raw version of inp buf, doesnt include any escapes
	pipefd:		resd	2	;buffer to store pipe file descriptor in
	pipebuf:	resw	260	;buffer to put contents of pipe command
	lineends:	resw	8	;buffer to store how many characters are at the end of inputed lines
	ipbuf:		resw	16	;buffer to store ip
	octet:		resw	4	;buffer to store octets in IP
	octetint:	resw	1	;buffer to store integer version of string octet
	ipaddr:		resd	1	;buffer to store little endian IP
	dispname:	resw	17	;buffer to store display name for this PC
	conname:	resw	17	;buffer to store connection name from peer
	msglog:		resq	2048	;buffer to store all messages sent (huge massive 2048 quads)
	displen:	resw	1	;length of display name (dynamically calculated)
	conlen:		resw	1	;length of connection name (guess what)
	msgheight:	resw	1	;height of current msg log
	havailable:	resw	1	;available height in area for showing messages
	msgscroll:	resw	1	;scroll position for message log
	EOSpos:		resw	1	;position of EOS inserted for message scrolling
	updates:	resb	4	;buffer for what things should be updated after recieving pipe message
section	.text
	global	_start
_start:
	mov	rax, 16				;system call for sys_ioctl
	mov	rdi, 1				;file descriptor for stdout
	mov	rsi, 21523			;denary value for TIOCGWINSZ (terminal size)
	mov	rdx, ws				;memory to store result in
	syscall
	mov	rax, 16				;system call for sys_ioctl
	mov	rdi, 1				;file descriptor for stdout
	mov	rsi, 21505			;ioctl command for TCGETS (get term info)
	mov	rdx, termios			;buffer to store terminal info in
	syscall
	and	dword[c_lflag], ~ICANON		;clears canonical flag
	mov	rax, 16				;system call for sys_ioctl
	mov	rdi, 1				;file descriptor for stdout
	mov	rsi, 21506			;ioctl command for TCSETS (set term info)
	mov	rdx, termios			;modified terminal info buffer
	syscall
	mov	rax, 22				;system call for sys_pipe
	mov	rdi, pipefd			;moves into rdi buffer to store returned fd
	syscall
	;code for initialisation
	movzx	rax, word[ws]			;moves terminal height into rax, clearing old bytes
	mov	word[havailable], ax		;moves terminal height into available height var
	sub	word[havailable], 3		;subtracts 3 (line counts, excludes inph bc thats calculated dynamically)
	xor	rdx, rdx			;resets rdx register for idiv later
	shr	rax, 1				;logical shift rax right 1 (divide by 2)
	sub	rax, 2				;subtracts half of win height from rax
	mov	rcx, 14				;moves position of least significant cursor Y position byte into rcx
	mov	rbx, 10				;moves value to divide by in idiv into rbx
.loop:
	idiv	rbx				;divides rax by rbx
	add	dx, 48				;adds ASCII value for '0' into rdx
	mov	word[tboxc+rcx], dx		;moves rdx into current byte for cursor position
	sub	rcx, 2				;goes to next sinificant byte
	cmp	rax, 10				;checks if quotient is 10 or above
	jae	.loop				;if yes, loop over
	add	ax, 48				;adds ASCII value for '0' into rax (quotient)
	mov	word[tboxc+rcx], ax		;moves ASCII quotient into most significant [used] byte of cursor position
	movzx	rax, word[ws+2]			;same operations as above, but using terminal width instead
	xor	rdx, rdx			;resets rdx for some reason or another
	shr	rax, 1				;divide rax by 2
	sub	rax, 9				;half of win width instead of win height
	mov	rcx, 26				;uses position of least significant byte of cursor X position
	mov	rbx, 10				;value to use in division (what a helpful comment ♥)
.loopb:
	idiv	rbx				;........
	add	dx, 48				;.......
	mov	word[tboxc+rcx], dx		;......
	sub	rcx, 2				;.....
	cmp	rax, 10				;....
	jae	.loopb				;...
	add	ax, 48				;..
	mov	word[tboxc+rcx], ax		;.
.modeinp:
	call	f_rsetwin			;once window center char has been correctly created, print window
	mov	rax, 0				;system call for sys_read
	mov	rdi, 1				;file descriptor for stdin
	mov	rsi, ibuf			;moves input buffer into rsi
	mov	rdx, 2				;length to read
	syscall
	cmp	byte[ibuf], 27			;checks if esc key (or ctrl, left, right keys pressed)
	jz	f_kill				;if yes, kill the program
	cmp	byte[ibuf], 99			;checks if input was equal to ASCII value for 'c' (client opt)
	jz	.finishmode			;if yes, jump to finish
	cmp	byte[ibuf], 115			;checks if input was equal to ASCII value for 's' (server opt)
	jnz	.modeinp			;if no, then input wasnt valid, ask input again
	mov	byte[hostmode], 3		;if yes, moves 3 into the host mode
.finishmode:
	sub	byte[hostmode], 2		;subtracts 2 from host mode to get correct values
	;higher values are initially used for host mode to prevent client / server wins being displayed before choice is made
	call	f_rsetwin			;prints the window again
	cmp	byte[hostmode], 1		;checks if the hostmode value is 1 (server)
	jz	.askdisp			;if yes, jump to ask for server name
	jl	.inputIP			;if lower, (0, client) jump to ask for server IP
.startchat:
	mov	byte[init], 0			;resets all init windows
	mov	byte[hostmode], 2		;and this too
	mov	rax, 57				;system call for sys_fork
	syscall
	cmp	rax, 0				;child process returns 0 into rax
	jz	m_iproc				;child process jumps to seperate subroutine
	mov	r14, rax
	xor	r15, r15			;xor r15 (line offset register)
.set:
	call	f_rsetwin			;reset window
	call	f_checkpipe			;check pipe
	jmp	.set				;loops over
.inputIP:
	xor	rax, rax			;system call for sys_read
	mov	rdi, 1				;file descriptor for stdin
	mov	rsi, ibuf			;character buffer into rsi
	mov	rdx, 2				;length to read (1 word)
	syscall
	movzx	rax, word[inppos]		;moves input position into rax
	xor	bx, bx				;resets rbx register
	cmp	byte[ibuf], 27			;checks if current char is escape key
	jnz	.contnorm			;if no, continue as normal
.rset:
	mov	word[inppos], 0			;else, reset input position
	mov	qword[ipbuf], 0			;and ip buffer
	mov	qword[ipbuf+8], 0		;...
	mov	qword[ipbuf+16], 0		;..
	mov	qword[ipbuf+24], 0		;.
	mov	byte[hostmode], 2		;and hostmode
	jmp	_start				;start again
.contnorm:
	cmp	byte[ibuf], 10			;checks if the current byte is newl char (enter pressed)
	jnz	.contcheck			;if not jumps to intermediate before buffering input again
	mov	word[ipbuf+rax+2], 0		;add EOS delimiter to end of ip string
	xor	rbx, rbx			;value for input position is 0
	xor	rcx, rcx			;value for octet position is 0
	xor	r13, r13			;value for current octet is 0
	jmp	.convLE				;jumps to conversion to little endian
.contcheck:
	cmp	byte[ibuf], 127			;checks if byte sent is backspace
	jnz	.inputIPCont			;if not, continue as normal
	mov	word[inppos], 0			;if yes, resets input position to 0
	call	f_rsetwin			;resets window
	mov	qword[ipbuf], 0			;clearing the ip buffer
	mov	qword[ipbuf+8], 0		;in unrolled loop
	mov	qword[ipbuf+16], 0		;..
	mov	qword[ipbuf+24], 0		;.
	jmp	.inputIP			;jumps back to ask for input
.inputIPCont:
	mov	bl, byte[ibuf]			;moves the character into lower 8 bytes of rbx
	mov	word[ipbuf+rax], bx		;moves that char into ip buffer at position [rax] (inppos)
	add	word[inppos], 2			;adds one word to input position
	cmp	word[inppos], 30		;checks if input position is at limit for IP input
	jnz	.inputIP			;if no, ask for ip input again
	mov	word[ipbuf+rax+2], 0		;add EOS delimiter to end of ip string
	xor	rbx, rbx			;value for input position is 0
	xor	rcx, rcx			;value for octet position is 0
	xor	r13, r13			;value for current octet is 0
	jmp	.convLE				;start conversion to little endian
.convLE:
	;get the current octet, using rbx as octet start
	mov	dx, word[ipbuf+rbx]		;moves the start (or middle) of the octet into rdx
	cmp	dx, 46				;checks if octet char is 46 (ASCII value for .)
	jz	.octint				;if yes, start converting the octet to int
	cmp	dx, 0				;checks if next octet char is 0 (EOL delimiter)
	jz	.octint				;if yes, same as above
	mov	word[octet+rcx], dx		;moves current char into the octet to opperate on
	add	rcx, 2				;adds 2 to rcx and rbx to go onto next word
	add	rbx, 2				;(rbx = ip buffer position, rcx = octet position, which does reset)
	jmp	.convLE				;loops over to get next char
.octint:
	cmp	rcx, 0				;checks if rcx is 0 (empty octet somehow this works perfectly for validating ip)
	jz	.rset				;if yes, reset program
	push	rbx				;pushes last position in ip addr so can identify position of next octet
	mov	word[octet+rcx+2], 0		;moves 0 into the end of the octet str
	sub	rcx, 2				;subtracts 2 from octet position (next most significant bit)
	mov	r11, 1				;moves 1 into multiplier
	mov	r10, 10				;moves 10 into multiplier for multiplier
.octintloop:
	sub	word[octet+rcx], 48		;subtracts 48 from current octet value (ASCII value for 0)
	xor	rax, rax			;resets rax value to clear unused bits
	mov	ax, word[octet+rcx]		;moves current octet bit into rax
	mul	r11				;multiplies that value by multiplier
	add	word[octetint], ax		;then adds it to int value of current octet
	mov	rax, r11			;moves r11 into rax for multiplication
	mul	r10				;multiplies it by 10
	mov	r11, rax			;moves that back into r11
	cmp	rcx, 0				;checks if at end of string
	jz	.octintexit			;if yes, exit converting to int
	sub	rcx, 2				;go to next most significant bit
	jmp	.octintloop			;loop over
.octintexit:
	mov	r11, 1				;resets r11
	xor	rcx, rcx			;resets rcx
	mov	bl, byte[octetint]		;moves int for the octet into rbx
	mov	byte[ipaddr+r13], bl		;moves int into the ip addr byte sequence
	pop	rbx				;pops back old value for position in ip string
	add	rbx, 2				;adds 2 to that value to skip the .
	mov	word[octetint], 0		;resets octet int val
	mov	qword[octet], 0			;resets octet
	cmp	r13, 3				;checks if r13 (value for counting octets) is 0
	jz	.askdisp			;if yes, go to ask for display name
	inc	r13				;decrease octet count
	jmp	.convLE				;loop back to next octet
.askdisp:
	inc	byte[init]			;increases initialisation mode
	call	f_rsetwin			;resets the window to show next window
	xor	rcx, rcx			;xors rcx because its used in next section
.askinp:
	xor	rax, rax			;xor rax for system call 0
	mov	rdi, 1				;moves stdin into rdi
	mov	rsi, ibuf			;moves input buffer into rsi
	mov	rdx, 4				;input length (2 words)
	push	rcx				;pushes rcx because of syscall
	syscall
	pop	rcx				;pops back rcx
	cmp	rcx, 32				;checks if rcx is equal to limit for input
	jz	.connect			;if yes, connect
	mov	ax, word[ibuf]			;moves character inputed into rax
	cmp	al, 27				;checks if current char is escape
	jnz	.contnormb			;if no, continue as normal PART 2 THE SEQUEL
.rsetname:
	dec	byte[init]			;undoes increment on initialisation var
	mov	byte[hostmode], 2		;sets hostmode back to 2
	mov	qword[dispname], 0		;reset all bytes of display name
	mov	qword[dispname+8], 0		;...
	mov	qword[dispname+16], 0		;..
	mov	qword[dispname+24], 0		;.
	cmp	byte[hostmode], 1		;checks if hostmode is 1 (server)
	jz	.serverback			;if yes, jump to other bit
	mov	word[inppos], 0			;resets input position
	mov	qword[ipbuf], 0			;resets all bytes of ipbuf
	mov	qword[ipbuf+8], 0		;...
	mov	qword[ipbuf+16], 0		;..
	mov	qword[ipbuf+24], 0		;.
.serverback:
	jmp	_start				;go back to start
.contnormb:
	cmp	al, 127				;compares char with backspace
	jnz	.askcont			;if no backspace, go to cont point
	mov	qword[dispname], 0		;else, reset all bytes of display name
	mov	qword[dispname+8], 0		;...
	mov	qword[dispname+16], 0		;..
	mov	qword[dispname+24], 0		;.
	call	f_rsetwin			;then reset window
	xor	rcx, rcx			;and reset character count
	jmp	.askinp				;then loop over
.askcont:
	cmp	al, 10				;is input newline (enter)
	jz	.connect			;if yes, connect to server
	mov	word[dispname+rcx], ax		;else, move the sent char into the display name
	add	rcx, 2				;add 1 word to char count
	jmp	.askinp				;then ask for input again
.connect:
	cmp	byte[hostmode], 1		;checks if in server mode
	jz	.servstart			;if yes, start the server
	mov	rax, 41				;system call for sys_socket
	mov	rdi, 2				;domain is 2 (AF_INET)
	mov	rsi, 1				;type is 1 (SO_STREAM)
	xor	rdx, rdx			;protocol is 0 (TCP)
	syscall
	mov	r15, rax			;moves new file descriptor to r15 
	mov	rax, 42				;system call for sys_connect
	mov	r10, [ipaddr]			;moves little endian IP into r10
	push	r10				;pushes IP to stack
	push	word	0x2923			;pushes port number to stack
	push	word	2			;pushes length to stack
	mov	rsi, rsp			;moves stack pointer into rsi (IP + port)
	mov	rdi, r15			;moves fd for created socket into rdi
	mov	rdx, 16				;moves length of IP + port into rdx
	syscall
	cmp	rax, 0				;checks if connect yields anything other than 0
	jz	.contconnect			;if successfully connected, everything is fine
	jmp	.rsetname			;otherwise, reset client
.contconnect:
	mov	qword[inpbuf], 0		;only first 4 quad words need to be reset bc of ip addr limit
	mov	qword[inpbuf+8], 0		;...
	mov	qword[inpbuf+16], 0		;..
	mov	qword[inpbuf+24], 0		;.
	mov	word[inppos], 0			;resets input position
	mov	rax, 1				;system call for sys_write
	mov	rdi, r15			;socket fd for write
	mov	rsi, dispname			;client display name
	mov	rdx, 34				;max length of display name
	syscall
	xor	rax, rax			;system call for sys_read
	mov	rdi, r15			;socket fd for read
	mov	rsi, conname			;recieved will be display name of server
	mov	rdx, 34				;max length of display name
	syscall
	call	f_print.len			;gets length of conections name into rdx
	add	dx, 6				;increase rdx by 3 words (square brackets + space)
	mov	word[conlen], dx		;saves that into connection name length var
	mov	rsi, dispname			;moves display name into rsi
	call	f_print.len			;gets length of display name into rdx
	add	dx, 6				;increase rdx by 3 words (square brackets + space)
	mov	word[displen], dx		;saves that into display name length var
	jmp	.startchat			;starts coms
.servstart:
	mov	rax, 41				;system call for sys_socket
	mov	rdi, 2				;domain is 2 (AF_INET)
	mov	rsi, 1				;type is 1 (SO_STREAM)
	mov	rdx, 0				;protocol is 0 (TCP)
	syscall
	mov	rdi, rax			;move new fd into rdi
	push	dword	0x00000000		;use ip
	push	word	0x2923			;port to bind to
	push	word	2
	mov	r13, rdi			;moves fd into r13
	mov	rsi, rsp			;moves stack values into rsi
	add	rdx, 16				;rdx is 16 (length of struct)
	mov	rax, 49				;system call for sys_bind
	syscall
	mov	rax, 50				;system call for sys_listen
	mov	rsi, 100			;backlog
	syscall
	xor	rsi, rsi			;resets rsi
	mov	rdi, r13			;moves created socket fd into rdi
	mov	rdx, rsi			;moves NOTHING into rdx
	mov	rax, 43				;system call for sys_accept
	syscall
	mov	r15, rax			;moves accepted fd into r15, so it can work with NPROC
	mov	rax, 1				;system call for sys_write
	mov	rdi, r15			;socket fd to write
	mov	rsi, dispname			;sends display name
	mov	rdx, 34				;max display name length
	syscall
	xor	rax, rax			;system call for sys_read
	mov	rdi, r15			;socket fd for read
	mov	rsi, conname			;recieved will be name of client
	mov	rdx, 34				;max display name length
	syscall
	call	f_print.len			;gets length of conections name into rdx
	add	dx, 6				;increase rdx by 3 words (square brackets + space)
	mov	word[conlen], dx		;saves that into connection name length var
	mov	rsi, dispname			;moves display name into rsi
	call	f_print.len			;gets length of display name into rdx
	add	dx, 6				;increase rdx by 3 words (square brackets + space)
	mov	word[displen], dx		;saves that into display name length var
	jmp	.startchat			;start talking

;		#-----------------------------------------------#
;		|           main for network process		|
;		#-----------------------------------------------#

m_nproc_init:
	sub	word[ws+2], 2			;subtract 2 from terminal width (screen edges)
	movzx	r8, word[ws+2]			;moves terminal width into r8
	shl	r8, 1				;doubles r8 to match word size
m_nproc:
	mov	word[msgheight], 1		;reset msg height (cant be <1)
	xor	rax, rax			;read operation
	mov	rdi, r15			;file descriptor for client socket
	mov	rsi, inpbuf			;store value in input buffer
	mov	rdx, 512			;maximum message length
	syscall
	cmp	word[inpbuf], 255		;checks if first char is 255 (killcode)
	jz	.kill				;if yes, go to kill
	xor	rcx, rcx			;reset rcx and rbx for operations
	xor	rbx, rbx			;.
.copyloop:
	mov	cx, word[inpbuf+rbx]		;moves current inpbuf char into rcx
	mov	word[inpbufraw+rbx], cx		;moves that into inpbufraw
	add	rbx, 2				;increase position counter
	cmp	cx, 0				;check if current char is EOS delimiter
	jnz	.copyloop			;if no, loop over
	xor	r9, r9				;reset r9 and rbx
	xor	rbx, rbx			;.
	cmp	word[inpbuf+504], 1		;check if ACK packet
	jnz	.cont				;if no, go to continuation point
	add	bx, word[displen]		;if yes, add length of display name to rbx
	jmp	.loop				;then continue
.cont:
	add	bx, word[conlen]		;add length of connection name to rbx
.loop:
	cmp	word[inpbuf+r9], 0		;check if current char is EOS delimiter
	jz	.done				;if yes, finished formatting msg
	cmp	rbx, r8				;otherwise, check if position is at EOL
	jz	.checkspace			;if yes, go to check for last space char
	add	rbx, 2				;increase position counter
	add	r9, 2				;both of them
	jmp	.loop				;loop over
.checkspace:
	mov	dx, word[inpbuf+r9]		;moves current char into rdx
	cmp	dx, 32				;checks if current char is 32
	jnz	.contcheck			;if no, continue checking
	mov	r10, r9				;if yes, move r9 (space pos) into r10
	jmp	.getend				;get end of string pos
.contcheck:
	sub	r9, 2				;decrease r9 by 1 word
	jmp	.checkspace			;go loop over
.getend:
	cmp	word[inpbuf+r9], 0		;check if at EOS
	jz	.shiftmsg			;if yes, shift message chars over
	add	r9, 2				;increase r9 by 1 word
	jmp	.getend				;loop over
.shiftmsg:
	mov	dx, word[inpbuf+r9]		;moves current char into rdx
	mov	word[inpbuf+r9+8], dx		;moves it 4 words ahead in input buffer (reserve space for newl)
	cmp	r9, r10				;checks if position counter is at position of newl
	jz	.insertwrap			;if yes, insert a wrap now
	sub	r9, 2				;else, decrease r9
	jmp	.shiftmsg			;loop over
.insertwrap:
	inc	word[msgheight]			;increases msg height (duh)
	mov	word[inpbuf+r9], 10		;moves ansi escape sequence into empty space where space char was
	mov	word[inpbuf+r9+2], 27		;....
	mov	word[inpbuf+r9+4], 91		;...
	mov	word[inpbuf+r9+6], 49		;..
	mov	word[inpbuf+r9+8], 67		;.
	xor	rbx, rbx			;reset rbx
	add	r9, 10				;adds on offset from newl sequence
	jmp	.loop				;loop over
.done:
	xor	rcx, rcx			;rcx modified after syscalls
	xor	rbx, rbx			;rbx and rdx also will have old values
	xor	rdx, rdx			;.
	mov	word[pipebuf], 1		;moves 1 (append operation) into PPROC command
	mov	word[pipebuf+2], 2		;moves 2 (set value msglog) into PPROC command
	movzx	rdx, word[msgplace]		;moves the message place into rdx
	sub	rdx, 2				;take away 2 from the msg place, otherwise messages divided by EOS
	mov	word[pipebuf+4], dx		;moves value of message place into pipe buffer (position to start append)
	mov	ax, word[msgheight]		;moves msg height into ax
	mov	word[pipebuf+6], ax		;moves that val into pipe buffer to be appended in main process
	call	f_fmtmsg			;call msg formatting subprocess
	mov	dword[pipebuf+256], 0		;clear update settings
	mov	byte[pipebuf+256], 1		;update scroll position
	mov	word[msgplace], dx		;then store mgsplace again
	mov	rax, 1				;system call for sys_write
	mov	edi, dword[pipefd+4]		;moves pipe's write file descriptor into rdi
	mov	rsi, pipebuf			;moves PPROC command into rsi
	mov	rdx, 520			;length to write (258 words, full PPROC command)
	syscall
	cmp	word[inpbuf+504], 1		;is this an ACK packet?
	jz	m_nproc				;if yes, jump back to start
	mov	rax, 1				;else, system call for sys_write
	mov	rdi, r15			;file descriptor to send packet to
	mov	rsi, inpbufraw			;recieved packet
	mov	rdx, 512			;length to write
	mov	word[inpbufraw+504], 1		;adds ACK packet marker to end of input buffer so it doesnt loop infinitely
	syscall
	jmp	m_nproc				;loop over
.kill:
	mov	word[pipebuf], 255		;moves 255 into first char of pipebuf
	mov	rax, 1				;system call for sys_write
	mov	edi, dword[pipefd+4]		;pipe fd
	mov	rsi, pipebuf			;moves pipebuf to be sent
	mov	rdx, 520			;total length (is weird if u go for lower vals)
	syscall
	call	f_kill

;		#-----------------------------------------------#
;		|             main for input process		|
;		#-----------------------------------------------#

m_iproc:
	mov	rax, 57				;system call for sys_fork
	syscall
	cmp	rax, 0				;checks if return is 0
	jz	m_nproc_init			;if yes, child process, jumps to network process
	mov	r14, rax			;store PID of created process so it can be killed later
	sub	word[ws+2], 2			;subtracts 2 from terminal width
	mov	ax, word[ws+2]			;moves terminal width into rax to be multiplied
	shl	ax, 1				;doubles rax
	mov	cx, ax				;moves rax into rcx
.iproc_loop:
	;STRUCTURE OF PIPE COMMAND
	;word[0] - operation type
	;word[1] - value to operate on
	;word[2-END] - what to use in command
	mov	dword[ibuf], 0			;resets ibuf just in case (prob not necasary)
	xor	rax, rax			;system call for sys_read (0)
	mov	rdi, 1				;read from stdout
	mov	rsi, ibuf			;moves input buffer for singular char into rsi
	mov	rdx, 4				;moves read length into rdx (1 word)
	push	rcx				;rcx modified by syscall
	syscall
	pop	rcx				;pop back rcx
	cmp	word[ibuf], 23323		;start of escape sequence for arrow keys
	jz	.checkesc			;if yes, go and check esc key
	cmp	word[ibuf], 10			;checks if current input is 10 (return)
	jz	.sendmsg			;if yes, send the current input buffer
	cmp	word[ibuf], 127			;checks if current input is backspace character
	jnz	.cont_char			;if no, jumps to continue for standard chars
	cmp	word[inppos], 0			;checks if the input position is 0
	jz	.write				;if yes, write (clear input from backspace chars)
	movzx	rbx, word[inpposraw]		;moves raw input position into rbx
	mov	word[inpbufraw+rbx], 0		;clears current char in raw
	sub	word[inpposraw], 2		;decreases raw input position by 2
	movzx	rax, word[linenum]		;resets bits of rax and moves in line char number
	mov	bx, word[linlen]		;moves line length into rbx
	cmp	word[linenum], -1		;checks if the number of lines is -1 (no previous line)
	jz	.uwrap_cont			;if yes, continue unwrapping
	cmp	word[lineends+rax], bx		;check if line end is equal to current line end
	jz	.uwrap				;if yes, unwrap
.uwrap_cont:
	xor	ax, ax				;moves 0 into rax register
	sub	word[inppos], 2			;subtracts 2 from input buffer position
	sub	word[linlen], 2			;and length of text on current line
	mov	bx, word[inppos]		;moves input position into rbx
	mov	word[inpbuf+rbx], ax		;moves 0 (EOS delimiter) into last ibuffer place with char
	mov	word[pipebuf], 0		;moves 0 (set code) into opcode section of pipe buffer
	mov	word[pipebuf+2], 0		;moves 0 (code for input buffer) into memory addr section of pbuf
	mov	rax, 4				;moves word offset for replacement array into rax
	jmp	.loop				;continues as normal
.cont_char:
	cmp	word[inpposraw], 512		;check if input limit has been reached
	jz	.write				;if yes, write nothing and p much loop over whilst clearing input
	mov	ax, word[ibuf]			;moves word read from input into rax
	mov	bx, word[inpposraw]		;moves the raw input position into rbx
	mov	word[inpbufraw+rbx], ax		;moves the current char into raw input buffer
	mov	bx, word[inppos]		;moves current input buffer position into rbx
	mov	word[inpbuf+rbx], ax		;moves word read into input buffer
	mov	word[inpbuf+rbx+2], 0		;and sets next char as 0
	add	word[inppos], 2			;increases input buffer position by 2
	add	word[inpposraw], 2		;and raw text input position by 2
	add	word[linlen], 2			;and length of text on current line
	cmp	word[linlen], cx		;checks if line needs to be wrapped
	jz	.lwrap				;if yes, go to line wrap subprocess
.cont:
	mov	word[pipebuf], 0		;code for set operation
	mov	word[pipebuf+2], 0		;code to set input buffer
	mov	rax, 4				;offset used for input buffer in pipe buffer
.loop:
	mov	bx, word[inpbuf+rax-4]		;moves next value of input buffer into rbx
	mov	word[pipebuf+rax], bx		;moves that value into pipe buffer
	add	rax, 2				;increases rax by 1 word
	cmp	bx, 0				;checks if rbx is 0 (EOS delimiter
	jnz	.loop				;if no, loop over
.write:
	call	m_iproc_send
	jmp	.iproc_loop			;start over
.lwrap:
	push	rax				;pop used values
	push	rbx				;..
	push	rcx				;.
	mov	word[linlen], -2		;offset for smth that cant remember
	movzx	rbx, word[inppos]		;moves the input buffer position into rbx
.lloop:
	mov	cx, word[inpbuf+rbx]		;moves the the current character into rcx
	mov	word[inpbuf+rbx+8], cx		;moves current character 4 words ahead in input buffer
	cmp	cx, 32				;checks if rcx is equal to 32 (ascii value for a space)
	jz	.wrapinsert			;if yes, inserts line wrap
	sub	rbx, 2				;else, decrease rbx by one word to view previous char
	add	word[linlen], 2			;increase length of current line by 2 (last word length added)
	jmp	.lloop				;loop over
.wrapinsert:
	mov	ax, word[linlen]		;moves line length into rax
	xor	rcx, rcx			;resets rcx
	add	word[linenum], 2		;go to next line (increase previous line count)
	mov	cx, word[linenum]		;moves that value into rcx
	mov	word[lineends+rcx], ax		;moves current line length into line end struct
	mov	word[inpbuf+rbx], 10		;moves ansi escape sequence into empty space where space was
	mov	word[inpbuf+rbx+2], 27		;....
	mov	word[inpbuf+rbx+4], 91		;...
	mov	word[inpbuf+rbx+6], 49		;..
	mov	word[inpbuf+rbx+8], 67		;.
	inc	word[inph]			;increases input box height
	mov	cx, word[inph]			;moves input box height into rcx
	mov	word[pipebuf], 0		;code for set operation
	mov	word[pipebuf+2], 1		;code for operating on inph var
	mov	word[pipebuf+4], cx		;value to change inph to in parent process
	mov	word[pipebuf+6], 0		;EOS delimiter
	mov	dword[pipebuf+256], 0		;clear update settings
	mov	byte[pipebuf+256], 1		;update scroll position
	call	m_iproc_send
	add	word[inppos], 8			;adds 4 words to input position (length of ansi seq)
	pop	rcx				;pops back used values
	pop	rbx				;..
	pop	rax				;.
	jmp	.cont				;continue where left off
.uwrap:
	push	rcx				;pushes syscall return value
	movzx	rbx, word[linlen]		;moves current line length into rbx
	movzx	rax, word[inppos]		;moves current input position into rax
	sub	rax, rbx			;subtract line length from input pos (position of newl sequence end)
	mov	word[inpbuf+rax-10], 32		;moves a space char into beginning of newl sequence
.uwrap_loop:
	cmp	rbx, 0				;checks if line length is 0
	jz	.end				;if yes, done
	sub	rbx, 2				;decrease line length by 2 (word value)
	mov	cx, word[inpbuf+rax]		;moves x value on new line into rcx
	add	rax, 2				;increases rax by 1 word (next char on new line)
	mov	word[inpbuf+rax-10], cx		;moves x value on new line back to overwrite newl seq
	jmp	.uwrap_loop			;loops over
.end:
	sub	word[inppos], 8			;takes away length of newl seq from input position
	mov	ax, word[ws+2]			;moves terminal width into rax
	shl	ax, 1				;multiples rax by 2 so value is correct in words rather than bytes
	mov	word[linlen], ax		;moves doubled terminal length into line length, bc now at end of previous line
	dec	word[inph]			;decreases input box height
	mov	cx, word[inph]			;moves input box height into rcx
	mov	word[pipebuf], 0		;code for set operation
	mov	word[pipebuf+2], 1		;code for operating on inph var
	mov	word[pipebuf+4], cx		;value to change inph to in parent process
	mov	word[pipebuf+6], 0		;EOS delimiter
	call	m_iproc_send
	sub	word[linenum], 2		;line number is now previous line
	pop	rcx				;pop back rcx from syscall
	jmp	.uwrap_cont			;continue
.sendmsg:
	cmp	qword[inpbufraw], 7405601	;checks if input is !q
	jz	.kill				;if yes, kill
	cmp	qword[inpbufraw], 6553633	;checks if input is !d
	jz	.disconnect
	movzx	rbx, word[inpposraw]		;moves raw input pos into rbx
	mov	word[inpbufraw+rbx], 10		;moves EOS delimiter into input buffer
	mov	rax, 1				;system call for sys_write
	mov	rdi, r15			;file descriptor for server / client
	mov	rsi, inpbufraw			;message to send
	mov	rdx, 512			;length of message
	syscall
	xor	rax, rax			;resets rax, used to reset inpbuf
.sendloop:
	mov	qword[inpbuf+rax], 0		;resets current quad word of inpbuf
	mov	qword[inpbufraw+rax], 0		;and current qword of raw inpbuf
	add	rax, 8				;increases rax by qword val in bytes
	cmp	rax, 512			;checks if rax is at end of inpbuf
	jnz	.sendloop			;if no, keep going
	mov	word[inppos], 0			;moves 0 into input position
	mov	word[inpposraw], 0		;and input position for raw text
	mov	word[linenum], -1		;moves -1 into line number (no previous line)
	mov	word[linlen], 30		;moves 30 into the line length (send message text len)
	mov	qword[inph], 1			;moves 1 into input box height
	mov	cx, word[inph]			;moves that into rcx
	mov	word[pipebuf], 0		;moves 0 into first pipebuf word (value for set operation)
	mov	word[pipebuf+2], 1		;moves 1 into second pipebuf word (value to set input height)
	mov	word[pipebuf+4], cx		;moves cx (inph) into 4th pipebuf word
	mov	word[pipebuf+6], 0		;EOS delimiter
	call	m_iproc_send
	mov	word[pipebuf+2], 0		;moves value to set inpbuf into pipebuf
	mov	word[pipebuf+4], 0		;value to set inpbuf to (nil)
	mov	rax, 1				;system call for sys_write (rax is modified after a syscall with ret values)
	syscall
	mov	ax, word[ws+2]			;moves terminal width into rax to be multiplied
	shl	ax, 1				;doubles rax
	mov	cx, ax				;moves rax into rcx
	jmp	.iproc_loop			;loop over
.checkesc:
	mov	word[pipebuf+4], 1		;moves value to add into pipebuf
	cmp	word[ibuf+2], 65		;up key, sequence ends in A
	jz	.sendscroll			;if up key, send the scroll command
	mov	word[pipebuf+4], -1		;otherwise, set scroll value to -1
.sendscroll:
	mov	word[pipebuf], 2		;operation value for math operation
	mov	word[pipebuf+2], 3		;value to use msgscroll
	mov	word[pipebuf+6], 0		;EOS delimiter
	mov	dword[pipebuf+256], 0		;clear update settings
	mov	byte[pipebuf+256], 1		;update scroll position
	jmp	.write				;send to output process
.disconnect:
	mov	rax, 62				;system call for sys_kill
	mov	rdi, r14			;PID of forked process
	mov	rsi, 9				;signal here is 9 for SIGKILL
	syscall
	mov	word[pipebuf], 255		;moves kill code into pipebuf
	mov	word[pipebuf+2], 254		;and self kill code into second byte
	mov	rax, 1				;system call for sys_write
	mov	rdi, r15			;send this to peer to notify them of client disconnection
	mov	rsi, pipebuf			;moves pipebuf into rsi
	mov	rdx, 512			;length to write
	syscall
	mov	word[pipebuf+2], 0		;resets self kill section in pipebuf
	mov	rax, 1				;system call for sys_write
	mov	edi, dword[pipefd+4]		;pipe fd
	mov	rsi, pipebuf			;moves pipe buffer into rsi
	mov	rdx, 512			;length to write
	syscall
	call	f_kill
.kill:
	mov	rax, 62				;system call for sys_kill
	mov	rdi, r14			;PID of forked process
	mov	rsi, 9				;signal here is 9 for SIGKILL
	syscall
	mov	word[pipebuf], 255		;moves kill code into pipebuf
	mov	word[pipebuf+2], 254		;and self kill code into second byte
	mov	rax, 1				;system call for sys_write
	mov	rdi, r15			;send this to peer to notify them of client disconnection
	mov	rsi, pipebuf			;moves pipebuf into rsi
	mov	rdx, 512			;length to write
	syscall
	mov	rax, 1				;you know the drill
	mov	edi, dword[pipefd+4]		;pipe fd
	mov	rsi, pipebuf			;yep
	mov	rdx, 512			;uh huh
	syscall
	call	f_kill
m_iproc_send:
	mov	rax, 1				;system call for sys_write
	mov	edi, dword[pipefd+4]		;moves pipe fd into rdi
	mov	rsi, pipebuf			;moves pipe command buffer into rsi
	mov	rdx, 520			;length of full PPROC command
	push	rcx
	syscall
	pop	rcx
	ret

;		#-----------------------------------------------#
;		|useful subroutines for use in main program body|
;		#-----------------------------------------------#

f_kill:
	or	dword[c_lflag], ICANON		;restores canonical flag
	mov	rax, 16				;system call for sys_ioctl
	mov	rdi, 1				;file descriptor for stdout
	mov	rsi, 21506			;ioctl command for TCSETS (set term info)
	mov	rdx, termios			;modified terminal info buffer
	syscall
	mov	rsi, curhome			;home escape
	call	f_bprint			;moves cursor to home pos
	mov	rsi, clear			;clear sequence
	call	f_bprint			;clears terminal
	call	f_flushbuf
	mov	rax, 60				;system call sys_exit
	mov	rdi, 1				;exit code
	syscall
f_printnl:
	call	f_print				;assumes that msg is currently in rsi
	push	rsi				;pushes rsi to stack
	mov	rsi, newl			;moves newl value (10) to rsi register
	call	f_print				;calls to print again
	pop	rsi				;pops newl value back
	ret
f_print:
	push	rax				;pushes registers used
	push	rdx				;..
	push	rdi				;.
	push	rcx				;and rcx bc syscalls return into rcx
	mov	rax, 1				;system call for sys_write
	mov	rdi, 1				;file descriptor for stdout
	call	.len				;call string length calculator, returns into rdx
	syscall
	pop	rcx				;reset returned value to previous value
	pop	rdi				;and pop back used values
	pop	rdx				;..
	pop	rax				;.
	ret
.len:
	mov	rcx, rsi			;copy string in rsi to both rcx (aux) and rdx
	mov	rdx, rsi			;.
.loop:
	cmp	word[rdx], 0			;check if current byte is EOS delimiter
	jz	.end				;if the current byte is EOS delimiter
	add	rdx, 2				;increase value of rdx to view next byte
	jmp	.loop				;start again
.end:
	sub	rdx, rcx			;subtract last byte of string from first byte to get length
	ret
f_bprint:
	push	rax				;pushes used registers
	push	rbx				;.
	xor	rbx, rbx			;set rbx to 0
.loop:
	mov	ax, word[rsi+rbx]		;bc this converts single letters, the value to convert will always be in first 8 bytes
	cmp	ax, 0				;checks if the value in rax is EOS delimiter
	jz	.end				;if yes, finished writing string, jump to end
	mov	word[printbuf+r12], ax		;moves the value in first 8 bytes of ra into current print buffer pos
	add	rbx, 2				;increases rbx (string offset)
	add	r12, 2				;and r12 (print buffer place)
	call	f_checkflush			;checks if the buffer is full, flushes if yes
	jmp	.loop				;loop over
.end:
	pop	rbx				;pop rbx and rax back
	pop	rax				;.
	ret
f_intchar:
	add	ax, 48				;add 48 (ascii val for 0) to lowest 16 bits of rax
	add	word[printbuf+r12], ax		;adds ax value to current buffer position
	ret
f_iprint:
	push	rax				;pushes used registers to stack
	push	rbx				;....
	push	rdx				;...
	push	rdi				;..
	push	rsi				;.
	mov	rax, rsi			;moves the int stored in rsi to rax for idiv
	mov	rbx, 10				;moves divisor value into rbx
	xor	rdi, rdi			;zeroes the rdi register
.div:
	xor	rdx, rdx			;zeroes the rdx register bc its used in idiv
	idiv	rbx				;signed division on value in rax by divisor rbx
	cmp	rax, 10				;checks if quotient is 10 or above
	jae	.inter				;if yes, jump to intermediate subroutine
	call	f_intchar			;if not, convert quotient to ascii value and store in buffer
.loop:
	mov	rax, rdx			;move remainder into rax
	add	r12, 2				;increases buffer position
	call	f_checkflush			;checks if buffer is full, flushes if yes
	call	f_intchar			;convert rax (rdx) to ascii value and store in buffer
	cmp	rdi, 0				;check if counter for divide iterations is 0
	jz	.end				;if yes, jump to end subroutine
	dec	rdi				;else, decrease the divide iteration counter
	pop	rdx				;and pop previous value of rdx off of stack
	jmp	.loop				;loop over
.inter:
	push	rdx				;pushes current remainder to stack for use later
	inc	rdi				;increases division iteration counter
	jmp	.div				;jumps back to divide function
.end:
	add	r12, 2				;moves to last place in buffer
	call	f_checkflush			;checks if buffer is full, flushes if yes
	mov	word[printbuf+r12], 10		;and inserts newl char
	add	r12, 2				;increases buffer position
	call	f_checkflush			;checks if buffer is full, flushes if yes
	pop	rsi				;pop used values back into correct registers
	pop	rdi				;....
	pop	rdx				;...
	pop	rbx				;..
	pop	rax				;.
	ret
f_flushbuf:
	xor	r12, r12			;resets buffer position to 0
	push	rax				;pushes used values
	push	rsi				;.
	mov	rsi, printbuf			;moves print buffer into rsi to print
	call	f_print				;prints print buffer
	xor	rax, rax			;resets rax
.loop:
	mov	qword[printbuf+rax], 0		;sets the 8 bytes in printbuffer starting at [rax] to 0
	cmp	rax, 504			;checks if rax is at end of print buffer
	jz	.end				;if yes, print buffer has been emptied so go to end
	add	rax, 8				;increases rax by 8 (size of qword in bytes)
	jmp	.loop				;loop over
.end:
	pop	rsi				;pops used values back
	pop	rax				;.
	ret
f_checkflush:
	cmp	r12, 510			;compares buffer position to 256 (buffer size in bytes)
	jz	.empty				;if yes, flush the buffer
	ret
.empty:
	call	f_flushbuf			;flushes buffer
	ret
f_rsetwin:
	push	rax				;push all registers used
	push	rbx				;......
	push	rcx				;.....
	push	rdx				;....
	push	rsi				;...
	push	rdi				;..
	push	r13				;.
	mov	word[setcur+14], 48		;reset cursor pos
	mov	rsi, c_white			;moves escape for bright white colour
	call	f_bprint			;prints ansi escape to buffer
	mov	rsi, curhome			;moves escape for cursor to home position
	call	f_bprint			;.
	mov	rax, contl			;top left connector
	mov	rbx, conh			;horizontal connector
	mov	rcx, contr			;top right connector
	mov	dx, word[ws+2]			;moves terminal width into lowest 16 bits of rdx
	call	f_genline			;generates new line into buffer
	movzx	rdi, word[ws]			;moves terminal height into rdi
	mov	r13, 3				;moves end height goal into r13
	add	r13, qword[inph]		;adds input box height to r13
	mov	rax, conv			;vertical connector
	mov	rbx, blank			;whitespace
	mov	rcx, conv			;vertical connector
.loop:
	cmp	rdi, r13			;compares terminal height to r13
	jz	.end				;if yes, jump to end
	dec	rdi				;decrease THC
	call	f_genline			;generates new line
	jmp	.loop				;loops over
.end:
	mov	rax, conjl			;left junction connector
	mov	rbx, conh			;horizontal connector
	mov	rcx, conjr			;right junction connector
	call	f_genline			;generates new line into buffer
	xor	r13, r13			;resets r13 register
	mov	rax, conv			;vertical connector
	mov	rbx, blank			;whitespace
	mov	rcx, conv			;vertical connector
.loopb:
	cmp	r13, qword[inph]		;checks if r13 is at input box height
	jz	.endb				;if yes, done
	call	f_genline			;generates new line into buffer
	inc	r13				;increase r13
	jmp	.loopb				;loop over
.endb:
	mov	rax, conbl			;bottom left connector
	mov	rbx, conh			;horizontal connector
	mov	rcx, conbr			;bottom right connector
	call	f_genline			;generates new line into buffer
	mov	ax, word[inph]			;moves input box height into lowest 16 bits of rax
	add	word[setcur+14], ax		;adds that value to setcur byte that defines row
	mov	rsi, setcur			;ansi escape to move cursor to msg box
	call	f_bprint			;moves ansi escape into print buffer
	mov	rsi, savecur			;saves cursor position
	call	f_bprint			;.
	mov	rsi, msgcur			;moves cursor to top to print msg log
	call	f_bprint			;.
	mov	rsi, msglog			;prints the msg log
	cmp	byte[updates], 1
	jnz	.nooffsetcalc
	call	f_calcoffset			;calculate offset for messages, return offset in r15
.nooffsetcalc:
	add	rsi, r15			;adds value for line offset (if not enough space on screen for all msgs)
	call	f_bprint			;.
	mov	rsi, loadcur			;loads cursor position
	call	f_bprint			;.
	mov	rsi, inpbuf			;moves input cursor offset into rsi
	call	f_bprint			;prints to buffer
	cmp	byte[init], 1			;check if in initialisation mode
	jl	.popback			;if no, go as normal
	mov	rsi, tboxc			;otherwise, print escape to move cursor to correct pos
	call	f_bprint			;then print to buffer
	cmp	byte[hostmode], 1		;check if the host mode is 0 (client) or 1 (server)
	ja	.initwin			;if no, initialise host mode selection win
	jz	.hostask			;else, go to ask for host name
	cmp	byte[init], 2			;checks if initialisation mode is 2
	jnz	.ipask				;if no, ask for ip
	mov	rsi, dbox			;if yes, moves hostname box into rsi
	call	f_bprint			;then print to buffer
	jmp	.popback			;continue as normal
.hostask:
	mov	rsi, dbox			;moves hostname ask into rsi
	call	f_bprint			;print to buffer
	jmp	.popback			;pop back values
.ipask:
	mov	rsi, cbox			;if yes, moves box for client mode to be printed
	call	f_bprint			;print buffer
	jmp	.popback			;jumps back to popping all values
.initwin:
	mov	rsi, tbox			;moves host mode selection win into rsi
	call	f_bprint			;prints buffer
.popback:
	pop	r13				;pops back used values
	pop	rdi				;......
	pop	rsi				;.....
	pop	rdx				;....
	pop	rcx				;...
	pop	rbx				;..
	pop	rax				;.
	call	f_flushbuf			;flushes values still in buffer
	ret
f_genline:
	push	rsi				;push used registers
	push	rdx				;.
	mov	rsi, rax			;moves first connector into rsi to print to buffer
	call	f_bprint			;prints to buffer
	mov	rsi, rbx			;moves second connector into rsi
.loop:
	cmp	dx, 2				;compares lowest 16 bytes of rdx with 2
	jz	.end				;if yes go to end
	dec	dx				;decreases TWC (or THC)
	call	f_bprint			;prints to buffer
	jmp	.loop				;loop over
.end:
	mov	rsi, rcx			;moves last connector into rsi
	call	f_bprint			;prints to buffer
	pop	rdx				;pops back used registers
	pop	rsi				;.
	ret
f_sleepms:
	push	rax				;pushes used values and rcx
	push	rcx				;...
	push	rdi				;..
	push	rsi				;.
	mov	ecx, 1000000			;moves value of 1 million into lower 32bits of rcx
	mul	ecx				;multiply rax by ecx to convert ms to ns
	mov	qword[tv_usec], rax		;moves the result into buffer for time sleep in ns
	mov	rax, 35				;system call for sys_nanosleep
	mov	rdi, timev			;moves time buffer into rsi
	xor	rsi, rsi			;resets register used for returns
	syscall
	pop	rsi				;pop back used valyes + rcx
	pop	rdi				;...
	pop	rcx				;..
	pop	rax				;.
	ret
f_checkpipe:
	push	rax				;push used values
	push	rbx				;.....
	push	rcx				;....
	push	rdx				;...
	push	rdi				;..
	push	rsi				;.
	xor	rax, rax			;sets rax to 0
	mov	edi, dword[pipefd]		;moves pipe read file descriptor into rdi
	mov	rsi, pipebuf			;moves buffer to store resulting command into rsi
	mov	rdx, 520			;moves length of command to read (258 words)
	syscall
	cmp	word[pipebuf], 255		;checks if pipe buffer starts with 255 (kill code)
	jz	.kill				;if yes, go to kill
	mov	edx, dword[pipebuf+256]		;moves last 4 bytes of pipebuf (update conf) into rdx
	mov	dword[updates], edx		;moves those bytes into update config
	cmp	word[pipebuf], 0		;checks if first word is 0 (value for set operation)
	jz	.set				;if yes, jumps to set operation section
	cmp	word[pipebuf], 1		;checks if second word is 1 (value for append operation)
	jz	.append				;if yes, jumps to append operation section
	cmp	word[pipebuf], 2		;checks if third word is 2 (value for math operation)
	jz	.math				;if yes, jumps to math operation section
.math:
	cmp	word[pipebuf+2], 3		;checks if second word is 3 (value to edit message scroll)
	jnz	.m_conta			;if not, continue checking values
	lea	rax, [msgscroll]		;if yes, load effective address of message scroll into rax
	jmp	.m_end				;start operation
.m_conta:
	;other checks, none for now
.m_end:
	cmp	word[msgscroll], 0		;checks if msg scroll is 0
	jnz	.m_cont				;if no, jump to continuation point
	cmp	word[pipebuf+4], -1		;check if adding value is -1, (bad scroll)
	jnz	.m_cont				;if no, jump to continuation point
	jmp	.end				;if yes, do nothing go to end
.m_cont:
	mov	bx, word[pipebuf+4]		;moves the value to add into rbx
	add	word[rax], bx			;adds value to add to register with effective address
	jmp	.end				;go to end
.append:
	cmp	word[pipebuf+2], 2		;checks if second word is 2 (value to edit message log)
	jnz	.a_conta			;if no, continue checks
	lea	rax, [msglog]			;if yes, loads effective address of input buffer into rax
	jmp	.a_end				;start operation
.a_conta:
	;other checks, none for now
.a_end:
	movzx	rbx, word[pipebuf+6]		;moves value used to store height of msg into rbx (specific for msglog appends)
	add	word[msgheight], bx		;adds that to msg height in this process
	movzx	rbx, word[pipebuf+4]		;moves value of which to start appending into rbx
	xor	rcx, rcx			;reset rcx
.a_loop:
	mov	dx, word[pipebuf+rcx+8]		;moves current pipebuf char into rdx
	mov	word[rax+rbx], dx		;moves that char into rax (operation value)
	add	rcx, 2				;increase rcx by 2 (1 word)
	add	rbx, 2				;and rbx
	cmp	dx, 0				;checks if current pipebuf char is 0 (EOS delimiter)
	jnz	.a_loop				;if no, continue
	jmp	.end				;end operation
.set:
	cmp	word[pipebuf+2], 0		;checks if second word is 0 (value to edit input buffer)
	jnz	.s_conta			;if not, jump to continuation point
	lea	rax, [inpbuf]			;if yes, load effective address of input buffer into rax
	jmp	.s_end				;start operation
.s_conta:
	cmp	word[pipebuf+2], 1		;checks if second word is 1 (value to edit input box height)
	jnz	.s_contb			;if not, continue checking values
	lea	rax, [inph]			;if yes, load effective address of input height into rax
	jmp	.s_end				;start operation
.s_contb:
	cmp	word[pipebuf+2], 2		;checks if second word is 2 (value to edit message log)
	jnz	.s_contc			;if not, continue checking values
	lea	rax, [msglog]			;if yes, load effective address of message log into rax
	jmp	.s_end				;start operation
.s_contc:
	;other checks, none for now
.s_end:
	mov	rdx, 4				;offset used for pipe buffer array storage
.s_loop:
	mov	bx, word[pipebuf+rdx]		;moves value to move into index into rbx
	mov	word[rax+rdx-4], bx		;moves value to move into operating value at index
	cmp	word[pipebuf+rdx], 0		;checks if next value is 0 (EOS delimiter)
	jz	.end				;if yes, go to end
	add	rdx, 2				;increases rdx by one word
	jmp	.s_loop				;else, loop over
.end:
	pop	rsi				;pop back values
	pop	rdi				;.....
	pop	rdx				;....
	pop	rcx				;...
	pop	rbx				;..
	pop	rax				;.
	ret
.kill:
	mov	byte[init], 1			;resets p much everything
	mov	byte[hostmode], 2		;...................
	mov	word[inppos], 0			;..................
	mov	word[inpposraw], 0		;.................
	mov	word[linlen], 30		;................
	mov	word[llen], 15			;...............
	mov	word[linenum], -1		;..............
	mov	word[msgplace], 2		;.............
	mov	qword[msglog], 0		;............
	mov	qword[ipbuf], 0			;...........
	mov	qword[ipbuf+8], 0		;..........
	mov	qword[ipbuf+16], 0		;.........
	mov	qword[ipbuf+24], 0		;........
	mov	qword[octet], 0			;.......
	mov	dword[ipaddr], 0		;......
	mov	word[msgheight], 0		;.....
	mov	word[havailable], 0		;....
	mov	word[msgscroll], 0		;...
	mov	word[EOSpos], 0			;..
	mov	dword[updates], 4		;.
	mov	rax, 62				;system call for sys_kill
	mov	rdi, r14			;PID of forked process
	mov	rsi, 9				;code for SIGKILL
	syscall
	call	f_rsetwin			;resets window
	mov	rax, 3				;system call for sys_close
	mov	rdi, r15			;fd for socket
	syscall
	cmp	word[pipebuf+2], 254		;checks if next char is 254 (end this process also)
	jnz	_start				;if no, start program again
	call	f_kill				;if yes, kill
f_fmtmsg:
	mov	word[pipebuf+8], 27		;moves escape seq bytes into the message log
	mov	word[pipebuf+10], 91		;........
	mov	word[pipebuf+12], 49		;.......	
	mov	word[pipebuf+14], 67		;......
	mov	word[pipebuf+16], 27		;.....
	mov	word[pipebuf+18], 91		;....
	mov	word[pipebuf+20], 55		;...
	mov	word[pipebuf+22], 59		;..
	mov	word[pipebuf+24], 51		;.
	cmp	word[inpbuf+504], 1		;checks if ACK packet being processed (own message)
	jnz	.recieved			;if no, its a newly recieved message
	mov	word[pipebuf+26], 53		;if yes, colour for own msg
	lea	r13, [dispname]			;and put own display name into r13
	jmp	.cont				;continuation point
.recieved:
	mov	word[pipebuf+26], 54		;colour for other msg
	lea	r13, [conname]			;and put other display name into r13
.cont:
	mov	word[pipebuf+28], 109		;more escape sequences at end
	mov	word[pipebuf+30], 91		;.
	mov	rbx, 32				;offset of the start of input message
	add	rdx, 24				;4 word offset created by adding all escape seq bytes
.loopn:
	mov	cx, word[r13+rbx-32]		;move display name into rcx
	cmp	cx, 0				;check if char is EOS
	jz	.loopnend			;if yes, go to end of loop
	mov	word[pipebuf+rbx], cx		;else, insert char into pipe buf
	add	rbx, 2				;add 2 to rbx and rdx
	add	rdx, 2				;.
	jmp	.loopn				;loop over
.loopnend:
	mov	word[pipebuf+rbx], 93		;add end of username bytes at end of message
	mov	word[pipebuf+rbx+2], 27		;.....
	mov	word[pipebuf+rbx+4], 91		;....
	mov	word[pipebuf+rbx+6], 48		;...
	mov	word[pipebuf+rbx+8], 109	;..
	mov	word[pipebuf+rbx+10], 32	;.
	add	rbx, 12				;what should have been increased inbetween escape chars
	add	rdx, 12				;same here
	xor	r14, r14			;reset r14 for input buffer position
.loopi:
	mov	cx, word[inpbuf+r14]		;moves char in input buffer into rcx
	mov	word[pipebuf+rbx], cx		;moves that char into current pipe buffer place
	add	rbx, 2				;increases rbx by 2
	add	r14, 2				;and r14
	add	rdx, 2				;and rdx
	cmp	cx, 0				;checks if char is EOS (0)
	jnz	.loopi				;if no, continue looping
	mov	word[pipebuf+rbx], 0		;if yes, add EOS delimiter at end of pipe buffer
	ret
f_calcoffset:
	push	rax				;push used registers
	push	rbx				;...
	push	rcx				;..
	push	rdx				;.
	movzx	r15, word[EOSpos]		;moves EOSpos into r15
	mov	word[msglog+r15], 27		;moves esc char into position that previously had EOS delimiter
	movzx	rax, word[havailable]		;moves the amount of available space into rax
	sub	ax, word[inph]			;takes away input box height
	cmp	ax, word[msgheight]		;checks that against the height of the message log
	jae	.end				;if there is still space available, go to end
	movzx	rdx, word[msgheight]		;moves the height of the message log into rdx
	sub	rdx, rax			;subtracts rax, gets overlapping space
	cmp	word[msgscroll], dx		;checks if msg scroll is equal to overlapping area
	jle	.notover			;if its below or equal, dont decrease scroll
	dec	word[msgscroll]			;if its bad value, decrease it
.notover:
	sub	dx, word[msgscroll]		;subtracts the message scroll from rdx
	xor	rcx, rcx			;reset rcx
.loop:
	cmp	word[msglog+rcx], 27		;checks if current char is 27 (start of escape seq)
	jz	.checkesc			;if yes, check for the rest of newl sequence (not colour sequence)
.cont:
	add	rcx, 2				;if no, increase rcx by 2
	jmp	.loop				;loop over
.checkesc:
	cmp	word[msglog+rcx+6], 67		;checks end of seq for capital letter C
	jnz	.cont				;if no, colour escape, continue as normal
	dec	rdx				;if yes, decrease overlapping line count
	cmp	rdx, -1				;check if no overlapping lines remain
	jnz	.cont				;if overlapping lines remain, go find next newl
	mov	r15, rcx			;if no overlap remains, move position to start msg log at into r15
	cmp	word[msgscroll], 0		;checks if the scroll position is 0
	jz	.end				;if yes, dont calculate where to put EOS delimiter
	movzx	rbx, word[msgscroll]		;moves the msg scroll into rbx
.getend:
	cmp	word[msglog+rcx], 0		;checks if current position has 0 char
	jz	.checkback			;if yes, check if one after is 0
.contend:
	add	rcx, 2				;if no, increase rcx by 2
	jmp	.getend				;loop over
.checkback:
	sub	rcx, 2				;if yes, at end of log, decrease rcx by 1 word
	cmp	word[msglog+rcx], 27		;checks if char is 27
	jnz	.checkback			;if no, loop over
.checkescb:
	cmp	word[msglog+rcx+6], 67		;if yes, check if is newl escape sequence
	jnz	.checkback			;if no, color escape, keep checking
	dec	bx				;if yes, decrease bx (msg scroll counter)
	cmp	bx, 0				;and check if its 0
	jnz	.checkback			;if no, keep looking for newl sequences
.addEOS:
	mov	word[msglog+rcx], 0		;if yes, add EOS delimiter at current pos
	mov	word[EOSpos], cx		;store current pos in EOSpos so can reset EOS later
.end:
	pop	rdx				;pop back used values
	pop	rcx				;...
	pop	rbx				;..
	pop	rax				;.
	ret
f_test:
	push	rsi
	mov	rsi, msg			;moves 'msg' into rsi to print
	call	f_print
	pop	rsi
	ret
