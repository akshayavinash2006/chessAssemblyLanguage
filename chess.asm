.model small
.stack 100h
.code
JUMPS

.data
board db  'r','n','b','q','k','b','n','r', \
          'p','p','p','p','p','p','p','p', \
          '.','.','.','.','.','.','.','.', \
          '.','.','.','.','.','.','.','.', \
          '.','.','.','.','.','.','.','.', \
          '.','.','.','.','.','.','.','.', \
          'P','P','P','P','P','P','P','P', \
          'R','N','B','Q','K','B','N','R'

newline   db 13,10,'$'
prompt    db 13,10,'Enter move: $'
white_msg db 13,10,'WHITE PLAY$'
black_msg db 13,10,'BLACK PLAY$'
invalid_m db 13,10,'Invalid move$'
exit_msg  db 13,10,'Exiting game...$'

src_col db ?
src_row db ?
dst_col db ?
dst_row db ?

src_i db ?
dst_i db ?

turn db 0        ; 0 = white, 1 = black

.code
main:
    mov ax, @data
    mov ds, ax

game_loop:

; ================= PRINT BOARD =================
    mov si, 0
    mov bh, 8
row_loop:
    mov dl, bh
    add dl, '0'
    mov ah, 02h
    int 21h

    mov dl, ' '
    int 21h

    mov cx, 8
col_loop:
    mov dl, board[si]
    mov ah, 02h
    int 21h
    mov dl, ' '
    int 21h
    inc si
    loop col_loop

    mov ah, 09h
    lea dx, newline
    int 21h

    dec bh
    jnz row_loop

    mov dl, ' '
    mov ah, 02h
    int 21h
    mov dl, ' '
    int 21h

    mov al, 'a'
    mov cx, 8
lbl_loop:
    mov dl, al
    mov ah, 02h
    int 21h
    mov dl, ' '
    int 21h
    inc al
    loop lbl_loop

    mov ah, 09h
    lea dx, newline
    int 21h

; ================= TURN DISPLAY =================
    cmp turn, 0
    jne short_show_black
    mov ah, 09h
    lea dx, white_msg
    int 21h
    jmp input
short_show_black:
    jmp show_black
show_black:
    mov ah, 09h
    lea dx, black_msg
    int 21h

; ================= INPUT =================
input:
    mov ah, 09h
    lea dx, prompt
    int 21h

    mov ah, 01h
    int 21h
    cmp al, 'q'
    je short_exit
    cmp al, 'Q'
    je short_exit
    mov src_col, al
    jmp read_rest
short_exit:
    jmp exit_game

read_rest:
    mov ah, 01h
    int 21h
    mov src_row, al

    mov ah, 01h
    int 21h

    mov ah, 01h
    int 21h
    mov dst_col, al

    mov ah, 01h
    int 21h
    mov dst_row, al

; ================= INDEX CALC =================
    mov al, src_col
    sub al, 'a'
    mov bl, al

    mov al, src_row
    sub al, '0'
    mov bh, 8
    sub bh, al

    mov al, bh
    mov ah, 0
    mov cl, 8
    mul cl
    add al, bl
    mov src_i, al

    mov al, dst_col
    sub al, 'a'
    mov bl, al

    mov al, dst_row
    sub al, '0'
    mov bh, 8
    sub bh, al

    mov al, bh
    mov ah, 0
    mov cl, 8
    mul cl
    add al, bl
    mov dst_i, al

; ================= SOURCE PIECE =================
    mov al, src_i
    mov ah, 0
    mov si, ax
    mov al, board[si]

    cmp al, '.'
    je short_invalid
    jmp check_turn
short_invalid:
    jmp invalid

check_turn:
    cmp turn, 0
    jne short_black_turn
    jmp white_turn
short_black_turn:
    jmp black_turn

white_turn:
    cmp al, 'A'
    jb short_invalid
    cmp al, 'Z'
    ja short_invalid
    cmp al, 'P'
    je short_white_pawn
    jmp generic_move
short_white_pawn:
    jmp white_pawn

black_turn:
    cmp al, 'a'
    jb short_invalid
    cmp al, 'z'
    ja short_invalid
    jmp generic_move

; ================= WHITE PAWN =================
white_pawn:
    mov al, src_i
    sub al, dst_i

    cmp al, 8
    je short_pawn_forward
    cmp al, 7
    je short_pawn_diag
    cmp al, 9
    je short_pawn_diag
    jmp invalid
short_pawn_forward:
    jmp pawn_forward
short_pawn_diag:
    jmp pawn_diag

pawn_forward:
    mov al, dst_i
    mov ah, 0
    mov di, ax
    cmp board[di], '.'
    jne short_invalid
    jmp do_move

pawn_diag:
    mov al, dst_i
    mov ah, 0
    mov di, ax
    mov bl, board[di]
    cmp bl, 'a'
    jb short_invalid
    cmp bl, 'z'
    ja short_invalid
    jmp do_move

; ================= GENERIC MOVE =================
generic_move:
    mov al, dst_i
    mov ah, 0
    mov di, ax
    mov bl, board[di]

    cmp bl, '.'
    je do_move

    cmp turn, 0
    jne short_blk_cap
    cmp bl, 'A'
    jb do_move
    cmp bl, 'Z'
    jbe short_invalid
    jmp do_move
short_blk_cap:
    cmp bl, 'a'
    jb do_move
    cmp bl, 'z'
    jbe short_invalid

; ================= EXECUTE MOVE =================
do_move:
    mov dl, board[si]
    mov board[di], dl
    mov byte ptr board[si], '.'
    xor turn, 1
    jmp game_loop

; ================= INVALID =================
invalid:
    mov ah, 09h
    lea dx, invalid_m
    int 21h
    jmp game_loop

; ================= EXIT =================
exit_game:
    mov ah, 09h
    lea dx, exit_msg
    int 21h
    mov ax, 4C00h
    int 21h

end main
