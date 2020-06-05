bits 16
org 0x7c00
 
cursorX: db 0
cursorY: db 0
playerTurn: db 0
entities: dw 'xo'
 
%macro draw_cursor 0
    mov cl, 0xff
    call draw_or_clear_cursor
%endmacro
 
%macro clear_cursor 0
    mov cl, 0x0f
    call draw_or_clear_cursor
%endmacro
 
%macro check_lines_vertical 0
    mov dh, 0
    call check_lines
%endmacro
 
%macro check_lines_horizontal 0
    mov dh, 1
    call check_lines
%endmacro
 
%macro check_lines_diagonal_1 0
    mov dh, 2
    call check_lines
%endmacro
 
%macro check_lines_diagonal_2 0
    mov dh, 3
    call check_lines
%endmacro
 
reset:
    xor ax, ax
    int 10h
 
    mov ah, 1
    mov cx, 0x2607
    int 10h
 
    mov byte [cursorX], 0
    mov byte [cursorY], 0
    mov byte [playerTurn], 0
 
    call update_cursor_position
    draw_cursor
 
mainLoop:
    mov ah, 0x00
    int 16h
 
    cmp al, 'h'
    je cursor_left
 
    cmp al, 'j'
    je cursor_down
 
    cmp al, 'k'
    je cursor_up
 
    cmp al, 'l'
    je cursor_right
 
    cmp al, 'p'
    je player_move
 
    jmp mainLoop
 
    cursor_up:
    dec byte [cursorY]
    jmp end
 
    cursor_down:
    inc byte [cursorY]
    jmp end
 
    cursor_right:
    inc byte [cursorX]
    jmp end
 
    cursor_left:
    dec byte [cursorX]
    jmp end
 
    player_move:
    call make_a_move
    jmp end
 
    end:
    clear_cursor
    call update_cursor_position
    draw_cursor
 
    check_lines_vertical
    check_lines_horizontal
    check_lines_diagonal_1
    check_lines_diagonal_2
 
    jmp mainLoop
 
make_a_move:
    mov ah, 0x09
    mov bh, 0
    mov bl, 0x01
    add bl, [playerTurn]
    mov ecx, 0
    mov cl, [playerTurn]
    mov al, [entities + ecx]
    mov cx, 1
    int 10h
 
    xor byte [playerTurn], 1
 
    ret
 
update_cursor_position:
    mov ah, 0x02
    mov bh, 0
    mov dl, [cursorX]
    mov dh, [cursorY]
    int 10h
 
    ret
 
draw_or_clear_cursor:
    mov ah, 0x08
    mov bh, 0
    int 10h
 
    mov bl, ah
 
    and bl, 0x0f
    or bl, 0xf0
    and bl, cl
 
    mov ah, 0x09
    mov bh, 0
    mov cx, 1
    int 10h
 
    ret
 
check_lines:
    push word [cursorX]
 
    mov cl, 0
    mov ch, 0
    mov dl, 0
    loopLines:
        cmp dh, 2
        jge loopCharacters
 
        mov ch, 0
        mov dl, 0
        loopCharacters:
            pusha
            cmp dh, 3
            je diagonal_mode_2
            jmp check_swap
 
            diagonal_mode_2:
            mov ah, 2
            sub ah, cl
            mov cl, ah
 
            check_swap:
            xor eax, eax
            mov al, ch
 
            cmp dh, 1
            je swap
            jmp set_position
 
            swap:
            xchg cl, ch
 
            set_position:
            mov word [highlighted_squares + eax * 2], cx
 
            mov [cursorX], cl
            mov [cursorY], ch
            call update_cursor_position
            popa
 
            mov ah, 0x08
            mov bh, 0
            int 10h
 
            cmp ch, 0
            je first_iteration
           
            jmp check
 
            first_iteration:
            mov dl, al
 
            check:
            cmp dl, al
            jne next
            cmp al, ' '
            je next
 
            mov dl, al
 
            inc ch
 
            cmp dh, 2
            jge diagonal_mode
 
            cmp ch, 3
            jl loopCharacters
            jmp line_crossed
 
            diagonal_mode:
            cmp ch, 3
            jl loopLines
            jmp line_crossed
 
            line_crossed:
            jmp highlight
            ret
       
        next:
 
        inc cl
        cmp cl, 3
        jl loopLines
 
    pop ax
    mov [cursorX], al
    mov [cursorY], ah
    call update_cursor_position
 
    ret
 
highlighted_squares: dw 0x0000, 0x0001, 0x0002
highlight:
    clear_cursor
 
    mov ecx, 0
    loopSquares:
        mov ah, 0x02
        mov bh, 0
        mov dx, [highlighted_squares + ecx * 2]
        int 10h
 
        pusha
        mov ah, 0x08
        mov bh, 0
        int 10h
 
        mov bl, ah
 
        and bl, 0x0f
        or bl, 0xf0
 
        mov ah, 0x09
        mov bh, 0
        mov cx, 1
        int 10h
        popa
 
        inc ecx
        cmp ecx, 3
        jl loopSquares
   
    mov ah, 0
    int 16h
 
    jmp reset
 
times 446 - ($-$$) db 0
 
db 0x80
db 0x00, 0x01, 0x00
db 0x17
db 0x00, 0x02, 0x00
db 0x00, 0x00, 0x00, 0x00
db 0x02, 0x00, 0x00, 0x00
 
times 510 - ($-$$) db 0
 
dw 0xaa55
