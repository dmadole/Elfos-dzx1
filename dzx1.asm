
;  Copyright 2023, David S. Madole <david@madole.net>
;
;  This program is free software: you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation, either version 3 of the License, or
;  (at your option) any later version.
;
;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with this program.  If not, see <https://www.gnu.org/licenses/>.


          ; Definition files

          #include include/bios.inc
          #include include/kernel.inc


          ; Unpublished kernel vector points

d_ideread:  equ   0447h
d_idewrite: equ   044ah


; r7 - single bit buffer
; r8 - holding for address
; r9 - temp pointer
; ra - output filename
; rb - copy offset
; rc - block length
; rd - destination pointer
; rf - source pointer


          ; Executable header block

            org   1ffah
            dw    begin
            dw    end-begin
            dw    begin

begin:      br    start

            db    7+80h
            db    29
            dw    2023
            dw    1

            db    'See github/dmadole/Elfos-dzx1 for more information',0


start:      lda   ra
            lbz   dousage
            sdi   ' '
            lbdf  start

            ghi   ra
            phi   rf
            glo   ra
            plo   rf
            dec   rf

skipinp:    lda   ra
            lbz   dousage
            sdi   ' '
            lbnf  skipinp

            dec   ra
            ldi   0
            str   ra
            inc   ra

skipspc:    lda   ra
            lbz   dousage
            sdi   ' '
            lbdf  skipspc

            ghi   ra
            phi   rd
            glo   ra
            plo   rd
            dec   ra

skipout:    lda   rd
            lbz   endargs
            sdi   ' '
            lbnf  skipout

            dec   rd
            ldi   0
            str   rd





endargs:    ldi   fildes.1
            phi   rd
            ldi   fildes.0
            plo   rd

            ldi   0
            plo   r7

            sep   scall
            dw    o_open
            lbdf  inpfail



            ldi   0
            phi   r8
            plo   r8
            phi   r7
            plo   r7

            ldi   2
            plo   rc

            sep   scall
            dw    o_seek



            ldi   k_heap.1
            phi   r8
            ldi   k_heap.0
            plo   r8

            glo   r7
            str   r2
            lda   r8
            sm
            plo   rb
            plo   rf

            ghi   r7
            str   r2
            lda   r8
            smb
            phi   rb
            phi   rf




            ldi   0
            phi   r8
            plo   r8
            phi   r7
            plo   r7

            ldi   0
            plo   rc

            sep   scall
            dw    o_seek

 

            ldi   65535.1
            phi   rc
            ldi   65535.0
            plo   rc

            sep   scall
            dw    o_read

            sep   scall
            dw    o_close





            ghi   rb
            phi   rf
            glo   rb
            plo   rf

            ldi   end.1
            phi   rd
            ldi   end.0
            plo   rd


          ; The algorithm is that from Einar Saukas's standard Z80 ZX1
          ; decompressor, but is completely rewriten due to how vastly
          ; different the 1802 instruction set and architeture is.

decompr:    ldi   -1                    ; last offset defaults to one
            phi   rb
            plo   rb

            ldi   80h                   ; prime the pump for elias
            plo   r7


          ; The first block in a stream is always a literal block so the type
          ; bit is not even sent, and we can jump in right at that point.

literal:    sep   scall                 ; get the length of the block
            dw    elias

copylit:    lda   rf                    ; copy byte from input stream
            str   rd
            inc   rd

            dec   rc                    ; loop until all bytes copied
            glo   rc
            lbnz  copylit
            ghi   rc
            lbnz  copylit


          ; After a literal block must be a copy block and the next bit
          ; indicates if is is from a new offset or the same offset as last.

            glo   r7                    ; get next bit, see if new offset
            shl
            plo   r7
            lbdf  newoffs


          ; Next block is from the same offset as last block.

            sep   scall                 ; same offset so just get length
            dw    elias

copyblk:    glo   rb                    ; offset plus position is source
            str   r2
            glo   rd
            add
            plo   r9
            ghi   rb
            str   r2
            ghi   rd
            adc
            phi   r9

copyoff:    lda   r9                     ; copy byte from source
            str   rd
            inc   rd

            dec   rc                     ; repeat for all bytes
            glo   rc
            lbnz  copyoff
            ghi   rc
            lbnz  copyoff


          ; After a copy from same offset, the next block must be either a
          ; literal or a copy from new offset, the next bit indicates which.

            glo   r7                     ; check if literal next
            shl
            plo   r7
            lbnf  literal


          ; Next block is to be coped from a new offset value.

newoffs:    ldi   -1                     ; msb for one-byte offset
            phi   rb

            lda   rf                     ; get lsb of offset, drop low bit
            shrc                         ;  while setting highest bit to 1
            plo   rb

            lbnf  msbskip                ; if offset is only one byte

            lda   rf                     ; get msb of offset, drop low bit
            shrc                         ;  while seting highest bit to 1
            phi   rb

            glo   rb                     ; replace lowest bit from msb into
            shlc                         ;  the lowest bit of lsb
            plo   rb

            ghi   rb                     ; high byte is offset by one
            adi   1
            phi   rb

            lbz   endfile                ; if not end of file marker

msbskip:    sep   scall                  ; get length of block
            dw    elias

            inc   rc                     ; new offset is one less

            lbr   copyblk                ; do the copy




endfile:    glo   rd
            smi   end.0
            plo   rc
            ghi   rd
            smbi  end.1
            phi   rc






            ldi   fildes.1
            phi   rd
            ldi   fildes.0
            plo   rd

            ghi   ra
            phi   rf
            glo   ra
            plo   rf

            ldi   1+2                   ; create and truncate
            plo   r7

            sep   scall
            dw    o_open
            lbdf  outfail




            ldi   end.1
            phi   rf
            ldi   end.0
            plo   rf

            sep   scall
            dw    o_write

            sep   scall
            dw    o_close

            sep   sret





          ; Subroutine to read an interlaced Elias gamma coded number from
          ; the bit input stream. This keeps a one-byte buffer in R7.0 and
          ; reads from the input pointed to by RF as needed, returning the
          ; resulting decoded number in RC.

elias:      ldi   1                     ; set start value at one
            plo   rc
            shr

eliloop:    phi   rc                    ; save result msb of value

            glo   r7                    ; get control bit from buffer
            shl

            lbnz  eliskip               ; if buffer is not empty

            lda   rf                    ; else get another byte
            shlc

eliskip:    lbnf  return                ; if bit is zero then end

            shl                         ; get a data bit from buffer
            plo   r7

            glo   rc                    ; shift data bit into result
            shlc
            plo   rc
            ghi   rc
            shlc

            lbr   eliloop               ; repeat until done

return:     plo   r7                    ; save back to buffer

            sep   sret                  ; return


          ; Help message output when argument syntax is incorrect.

dousage:    sep   scall
            dw    o_inmsg
            db    'USAGE: dzx1 input output',13,1,0

            sep   sret


          ; Failure message output when input file can't be opened.

inpfail:    sep   scall
            dw    o_inmsg
            db    'ERROR: Can not open input file.',13,1,0

            sep   sret


          ; Failure message output when output file can't be opened.

outfail:    sep   scall
            dw    o_inmsg
            db    'ERROR: Can not open output file.',13,1,0

            sep   sret


          ; File descriptor used for both intput and output files.

fildes:     db    0,0,0,0
            dw    dta
            db    0,0,0,0,0,0,0,0,0,0,0,0,0


          ; Data transfer area that is included in executable header size
          ; but not actually included in executable.

dta:        ds    512

end:        end    begin
