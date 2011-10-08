.init_heap_size	0
	jmp	min_caml_start

!#####################################################################
! * ここからライブラリ関数
!#####################################################################

! * create_array
min_caml_create_array:
	add %g5, %g3, %g2
	mov %g3, %g2
CREATE_ARRAY_LOOP:
	jlt %g5, %g2, CREATE_ARRAY_END
	st %g4, %g2, 0
	addi %g2, %g2, 4
	jmp CREATE_ARRAY_LOOP
CREATE_ARRAY_END:
	return

! * create_float_array
min_caml_create_float_array:
	add %g4, %g3, %g2
	mov %g3, %g2
CREATE_FLOAT_ARRAY_LOOP:
	jlt %g4, %g2, CREATE_FLOAT_ARRAY_END
	st %f0, %g2, 0
	addi %g2, %g2, 4
	jmp CREATE_FLOAT_ARRAY_LOOP
CREATE_FLOAT_ARRAY_END:
	return

!#####################################################################
! * ここまでライブラリ関数
!#####################################################################

f.10:
	mvhi	%g3, 0
	mvlo	%g3, 123
	return
g.12:
	mvhi	%g3, 0
	mvlo	%g3, 456
	return
h.14:
	mvhi	%g3, 0
	mvlo	%g3, 789
	return
min_caml_start:
	st	%g31, %g1, 4
	subi	%g1, %g1, 8
	call	f.10
	addi	%g1, %g1, 8
	ld	%g31, %g1, 4
	mvhi	%g4, 0
	mvlo	%g4, 0
	st	%g3, %g1, 0
	jlt	%g4, %g3, jle_else.27
	st	%g31, %g1, 4
	subi	%g1, %g1, 8
	call	g.12
	addi	%g1, %g1, 8
	ld	%g31, %g1, 4
	jmp	jle_cont.28
jle_else.27:
	st	%g31, %g1, 4
	subi	%g1, %g1, 8
	call	h.14
	addi	%g1, %g1, 8
	ld	%g31, %g1, 4
jle_cont.28:
	ld	%g4, %g1, 0
	add	%g3, %g3, %g4
	output	%g3
	halt
