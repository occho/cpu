.init_heap_size	0
	jmp	min_caml_start

!#####################################################################
! * ここからライブラリ関数
!#####################################################################

! * create_array
min_caml_create_array:
	slli %g3, %g3, 2
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
	slli %g3, %g3, 2
	add %g4, %g3, %g2
	mov %g3, %g2
CREATE_FLOAT_ARRAY_LOOP:
	jlt %g4, %g2, CREATE_FLOAT_ARRAY_END
	fst %f0, %g2, 0
	addi %g2, %g2, 4
	jmp CREATE_FLOAT_ARRAY_LOOP
CREATE_FLOAT_ARRAY_END:
	return

!#####################################################################
! * ここまでライブラリ関数
!#####################################################################

adder.11:
	ld	%g4, %g29, -4
	add	%g3, %g4, %g3
	return
make_adder.5:
	mov	%g4, %g2
	addi	%g2, %g2, 8
	setL %g5, adder.11
	st	%g5, %g4, 0
	st	%g3, %g4, -4
	mov	%g3, %g4
	return
min_caml_start:
	mvhi	%g3, 0
	mvlo	%g3, 3
	st	%g31, %g1, 4
	subi	%g1, %g1, 8
	call	make_adder.5
	addi	%g1, %g1, 8
	ld	%g31, %g1, 4
	mov	%g29, %g3
	mvhi	%g3, 0
	mvlo	%g3, 7
	st	%g31, %g1, 4
	ld	%g28, %g29, 0
	subi	%g1, %g1, 8
	callR	%g28
	addi	%g1, %g1, 8
	ld	%g31, %g1, 4
	output	%g3
	halt
