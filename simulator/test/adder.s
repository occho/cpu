.init_heap_size	0
adder.11:
	ld	%g4, %g30, 4
	add	%g3, %g4, %g3
	return
make_adder.5:
	mov	%g4, %g2
	addi	%g2, %g2, 8
	setL %g5, adder.11
	st	%g5, %g4, 0
	st	%g3, %g4, 4
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
	mov	%g30, %g3
	mvhi	%g3, 0
	mvlo	%g3, 7
	st	%g31, %g1, 4
	ld	%g29, %g30, 0
	subi	%g1, %g1, 8
	call	%g29
	addi	%g1, %g1, 8
	ld	%g31, %g1, 4
	output	%g3
	halt