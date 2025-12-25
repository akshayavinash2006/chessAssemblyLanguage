.model small
.stack 100h
JUMPS

.data
; ================= BOARD =================
board db  'r','n','b','q','k','b','n','r', \
          'p','p','p','p','p','p','p','p', \
          '.','.','.','.','.','.','.','.', \
          '.','.','.','.','.','.','.','.', \
          '.','.','.','.','.','.','.','.', \
          '.','.','.','.','.','.','.','.', \
          'P','P','P','P','P','P','P','P', \
          'R','N','B','Q','K','B','N','R'

nl        db 13,10,'$'
white_msg db 13,10,'WHITE TURN$'
black_msg db 13,10,'BLACK TURN$'
invalid_m db 13,10,'INVALID MOVE$'
check_msg db 13,10,'CHECK FROM $'
mate_msg  db 13,10,'CHECKMATE! GAME OVER$'

promo_msg db 13,10,'Pawn Promotion!',13,10, \
              '1. Queen',13,10, \
              '2. Rook',13,10, \
              '3. Bishop',13,10, \
              '4. Knight',13,10, \
              'Choice: $'

src_i     db ?
dst_i     db ?
turn      db 0        ; 0 = white, 1 = black

check_src db ?
save_a    db ?
save_b    db ?

.code
main:
    mov ax,@data
    mov ds,ax

    ; mouse init
    mov ax,0
    int 33h
    mov ax,1
    int 33h

game_loop:
    call draw_board

    cmp turn,0
    jne blk
    lea dx,white_msg
    jmp show
blk:
    lea dx,black_msg
show:
    mov ah,09h
    int 21h

    call mouse_click
    mov src_i,al
    call mouse_click
    mov dst_i,al

    call validate_move
    jc invalid

    call simulate_and_check
    jc invalid

    call do_move
    call pawn_promotion

    call is_check
    jc show_check

    xor turn,1
    jmp game_loop

show_check:
    mov ah,09h
    lea dx,check_msg
    int 21h

    mov si,check_src
    mov dl,board[si]
    mov ah,02h
    int 21h

    call is_checkmate
    jc mate

    xor turn,1
    jmp game_loop

mate:
    mov ah,09h
    lea dx,mate_msg
    int 21h
    mov ax,4C00h
    int 21h

invalid:
    mov ah,09h
    lea dx,invalid_m
    int 21h
    jmp game_loop

; ================= DRAW BOARD =================
draw_board proc
    mov si,0
    mov bh,8
rloop:
    mov dl,bh
    add dl,'0'
    mov ah,02h
    int 21h
    mov dl,' '
    int 21h

    mov cx,8
cloop:
    mov dl,board[si]
    mov ah,02h
    int 21h
    mov dl,' '
    int 21h
    inc si
    loop cloop

    mov ah,09h
    lea dx,nl
    int 21h
    dec bh
    jnz rloop
    ret
draw_board endp

; ================= MOUSE INPUT =================
mouse_click proc
wait:
    mov ax,3
    int 33h
    test bx,1
    jz wait

    mov ax,dx
    mov bl,8
    div bl
    mov bh,al

    mov ax,cx
    div bl

    mov al,bh
    mov ah,0
    mov cl,8
    mul cl
    add al,ah
    ret
mouse_click endp

; ================= MOVE VALIDATION =================
validate_move proc
    mov si,src_i
    mov di,dst_i

    mov al,board[si]
    cmp al,'.'
    je bad

    cmp turn,0
    jne black_chk
    cmp al,'A'
    jb bad
    cmp al,'Z'
    ja bad
    jmp piece
black_chk:
    cmp al,'a'
    jb bad
    cmp al,'z'
    ja bad

piece:
    call validate_piece
    jc bad
    clc
    ret
bad:
    stc
    ret
validate_move endp

; ================= PIECE DISPATCH =================
validate_piece proc
    mov al,board[si]

    cmp al,'P' je pawn
    cmp al,'p' je pawn
    cmp al,'R' je rook
    cmp al,'r' je rook
    cmp al,'B' je bishop
    cmp al,'b' je bishop
    cmp al,'N' je knight
    cmp al,'n' je knight
    cmp al,'Q' je queen
    cmp al,'q' je queen
    cmp al,'K' je king
    cmp al,'k' je king
    stc
    ret

pawn:   call pawn_logic   ret
rook:   call rook_logic   ret
bishop: call bishop_logic ret
knight: call knight_logic ret
queen:  call rook_logic
        jnc okq
        call bishop_logic
        ret
okq:    clc ret
king:   call king_logic   ret
validate_piece endp

; ================= PIECE LOGIC =================
pawn_logic proc
    mov al,si
    sub al,di
    cmp turn,0
    jne bp
    cmp al,8 je fwd
    cmp al,7 je cap
    cmp al,9 je cap
    stc ret
bp:
    cmp al,-8 je fwd
    cmp al,-7 je cap
    cmp al,-9 je cap
    stc ret
fwd:
    cmp board[di],'.'
    jne bad
    clc ret
cap:
    cmp board[di],'.'
    je bad
    clc ret
bad:
    stc ret
pawn_logic endp

rook_logic proc
    mov ax,si
    sub ax,di
    jz bad

    mov bx,ax
    cmp bx,8 je vert
    cmp bx,-8 je vert

    mov ax,si
    xor dx,dx
    mov bl,8
    div bl
    mov bh,al
    mov ax,di
    div bl
    cmp bh,al
    jne bad
    mov bl,1
    jmp scan
vert:
    mov bl,8
scan:
    mov cx,si
step:
    add cx,bl
    cmp cx,di
    je ok
    cmp board[cx],'.'
    jne bad
    jmp step
ok: clc ret
bad: stc ret
rook_logic endp

bishop_logic proc
    mov ax,si
    sub ax,di
    cmp ax,7 je d7
    cmp ax,-7 je d7
    cmp ax,9 je d9
    cmp ax,-9 je d9
    stc ret
d7: mov bl,7 jmp scan
d9: mov bl,9
scan:
    mov cx,si
next:
    add cx,bl
    cmp cx,di
    je ok
    cmp board[cx],'.'
    jne bad
    jmp next
ok: clc ret
bad: stc ret
bishop_logic endp

knight_logic proc
    mov al,si
    sub al,di
    cmp al,6 je ok
    cmp al,-6 je ok
    cmp al,10 je ok
    cmp al,-10 je ok
    cmp al,15 je ok
    cmp al,-15 je ok
    cmp al,17 je ok
    cmp al,-17 je ok
    stc ret
ok: clc ret
knight_logic endp

king_logic proc
    mov al,si
    sub al,di
    cmp al,1 jbe ok
    cmp al,7 jbe ok
    cmp al,8 jbe ok
    cmp al,9 jbe ok
    stc ret
ok: clc ret
king_logic endp

; ================= MOVE =================
do_move proc
    mov al,board[si]
    mov board[di],al
    mov byte ptr board[si],'.'
    ret
do_move endp

simulate_and_check proc
    mov save_a,board[si]
    mov save_b,board[di]
    mov board[di],save_a
    mov board[si],'.'
    call is_check
    mov board[si],save_a
    mov board[di],save_b
    ret
simulate_and_check endp

; ================= PAWN PROMOTION =================
pawn_promotion proc
    mov al,board[di]
    cmp al,'P'
    jne chk_black
    cmp di,7
    jbe promote
    ret
chk_black:
    cmp al,'p'
    jne done
    cmp di,56
    jb done
promote:
    mov ah,09h
    lea dx,promo_msg
    int 21h
getc:
    mov ah,01h
    int 21h
    cmp al,'1' je q
    cmp al,'2' je r
    cmp al,'3' je b
    cmp al,'4' je n
    jmp getc
q: mov al,'Q' jmp place
r: mov al,'R' jmp place
b: mov al,'B' jmp place
n: mov al,'N'
place:
    cmp turn,0
    je white
    add al,32
white:
    mov board[di],al
done:
    ret
pawn_promotion endp

; ================= CHECK (FIXED) =================
is_check proc
    mov cx,64
    mov si,0
findk:
    mov al,board[si]
    cmp turn,0
    jne bk
    cmp al,'K' je found
    jmp nx
bk:
    cmp al,'k' je found
nx:
    inc si
    loop findk
    clc ret
found:
    mov di,si
    mov cx,64
    mov si,0
scan:
    mov al,board[si]
    cmp al,'.'
    je skip
    cmp turn,0
    jne white_attacker
    cmp al,'a'
    jb skip
    cmp al,'z'
    ja skip
    jmp test
white_attacker:
    cmp al,'A'
    jb skip
    cmp al,'Z'
    ja skip
test:
    mov src_i,si
    mov dst_i,di
    call validate_piece
    jc skip
    mov check_src,si
    stc ret
skip:
    inc si
    loop scan
    clc ret
is_check endp

; ================= CHECKMATE =================
is_checkmate proc
    mov cx,64
    mov si,0
pl:
    mov al,board[si]
    cmp al,'.'
    je np
    mov src_i,si
    mov di,0
sl:
    mov dst_i,di
    call validate_piece
    jc ns
    call simulate_and_check
    jnc escape
ns:
    inc di
    cmp di,64
    jb sl
np:
    inc si
    loop pl
    stc ret
escape:
    clc ret
is_checkmate endp

end main
  
