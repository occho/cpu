(* 浮動小数基本演算1 *)
let rec fequal a b = a = b in
let rec fless a b = (a < b) in

let rec fispos a = (a > 0.0) in
let rec fisneg a = (a < 0.0) in
let rec fiszero a = (a = 0.0) in

(* bool系 *)
let rec xor a b = a <> b in

(* 浮動小数基本演算2 *)
let rec fabs a =
	if a < 0.0 then -. a
	else a
in
let rec abs_float x = fabs x in
let rec fneg a = -. a in
let rec fhalf a = a *. 0.5 in
let rec fsqr a = a *. a in

(* floor, int_of_float, float_of_int はlib_asm.sで定義 *)

(* 算術関数 *)
let pi = 3.14159265358979323846264 in
let pi2 = pi *. 2.0 in
let pih = pi *. 0.5 in

(* atan *)
let rec atan_sub i xx y =
	if i < 0.5 then y
	else atan_sub (i -. 1.0) xx ((i *. i *. xx) /. (i +. i +. 1.0 +. y))
in
let rec atan x =
	let sgn =
		if x > 1.0 then 1
		else if x < -1.0 then -1
		else 0
	in
	let x =
		if sgn <> 0 then 1.0 /. x
		else x
	in
	let a = atan_sub 11.0 (x *. x) 0.0 in
	let b = x /. (1.0 +. a) in
	if sgn > 0 then pi /. 2.0 -. b
	else if sgn < 0 then -. pi /. 2.0 -. b
	else b
	in

(* tan *)
let rec tan x = (* -pi/4 <= x <= pi/4 *)
	let rec tan_sub i xx y =
		if i < 2.5 then y
			else tan_sub (i -. 2.) xx (xx /. (i -. y))
	in
	x /. (1. -. (tan_sub 9. (x *. x) 0.0))
in

(* sin *)
let rec sin_sub x = 
	let pi2 = pi *. 2.0 in
	if x > pi2 then sin_sub (x -. pi2)
	else if x < 0.0 then sin_sub (x +. pi2)
	else x in
let rec sin x =
	let pi = 3.14159265358979323846264 in
	let pi2 = pi *. 2.0 in
	let pih = pi *. 0.5 in
	(* tan *)
	let s1 = x > 0.0 in
	let x0 = fabs x in
	let x1 = sin_sub x0 in
	let s2 = if x1 > pi then not s1 else s1 in
	let x2 = if x1 > pi then pi2 -. x1 else x1 in
	let x3 = if x2 > pih then pi -. x2 else x2 in
	let t = tan (x3 *. 0.5) in
	let ans = 2. *. t /. (1. +. t *. t) in
	if s2 then ans else fneg ans in

(* cos *)
let rec cos x = 
	let pih = pi *. 0.5 in
	sin (pih -. x) in

(* create_array系はコンパイル時にコードを生成。compiler/emit.ml参照 *)
let rec mul10 x = x * 8 + x * 2 in

(* read_int *)
let read_int_ans = Array.create 1 0 in
let read_int_s = Array.create 1 0 in
let rec read_int_token in_token prev =
	let c = input_char () in
	let flg = 
		if c < 48 then true
		else if c > 57 then true
		else false in
	if flg then
		(if in_token then (if read_int_s.(0) = 1 then read_int_ans.(0) else (-read_int_ans.(0))) else read_int_token false c)
	else
		((if read_int_s.(0) = 0 then
			(* prev == '-' *)
			(if prev = 45 then read_int_s.(0) <- (-1) else read_int_s.(0) <- (1));
		else
			());
		read_int_ans.(0) <- mul10 read_int_ans.(0) + (c - 48);
		read_int_token true c) in
let rec read_int _ = 
	read_int_ans.(0) <- 0;
	read_int_s.(0) <- 0;
	read_int_token false 32 in

(* read_float *)
let read_float_i = Array.create 1 0 in
let read_float_f = Array.create 1 0 in
let read_float_exp = Array.create 1 1 in
let read_float_s = Array.create 1 0 in
let rec read_float_token1 in_token prev =
	let c = input_char () in
	let flg =
		if c < 48 then true
		else if c > 57 then true
		else false in
	if flg then
		(if in_token then c else read_float_token1 false c)
	else
		((if read_float_s.(0) = 0 then
			(* prev == '-' *)
			(if prev = 45 then read_float_s.(0) <- (-1) else read_float_s.(0) <- (1));

		else
			());
		read_float_i.(0) <- mul10 read_float_i.(0) + (c - 48);
		read_float_token1 true c) in
let rec read_float_token2 in_token =
	let c = input_char () in
	let flg =
		if c < 48 then true
		else if c > 57 then true
		else false in
	if flg then
		(if in_token then () else read_float_token2 false)
	else
		(read_float_f.(0) <- mul10 read_float_f.(0) + (c - 48);
		read_float_exp.(0) <- mul10 read_float_exp.(0);
		read_float_token2 true) in
let rec read_float _ = 
	read_float_i.(0) <- 0;
	read_float_f.(0) <- 0;
	read_float_exp.(0) <- 1;
	read_float_s.(0) <- 0;
	let nextch = read_float_token1 false 32 in
	let ans =
		if nextch = 46 then (* nextch = '.' *)
			(read_float_token2 false;
			(float_of_int read_float_i.(0)) +. (float_of_int read_float_f.(0)) /. (float_of_int read_float_exp.(0)))
		else
			float_of_int read_float_i.(0) in
	if read_float_s.(0) = 1 then
		ans
	else
		-. ans in
(*
(* print_int *)
let print_int_data = Array.create 10 0 in (* int型の値は３２bitなのでせいぜい10桁 *)
let print_int_x = Array.create 1 0 in
let rec print_int_get_digits digits =
	if print_int_x.(0) <= 0 then digits - 1
	else
		let nx = print_int_x.(0) / 10 in
		print_int_data.(digits) <- print_int_x.(0) - nx * 10; (* print_int_data[digits] <- print_int_x % 10 *)
		print_int_x.(0) <- nx; (* print_int_x = print_int_x / 10 *)
		print_int_get_digits (digits + 1) in
let rec print_int_print_digits digits =
	if digits < 0 then
		()
	else
		let c = (print_int_data.(digits) + 48) in
		print_char c;
		print_int_print_digits (digits - 1) in
let rec print_int n =
	print_int_x.(0) <- (if n >= 0 then n else -n);
	let digits = print_int_get_digits 0 in
	(if n < 0 then print_char 45 else ());
	if digits < 0 then
		print_char 48
	else
		print_int_print_digits digits in
*)

let rec div_binary_search a b left right =
(*	Printf.printf "(%d, %d, %d, %d)\n" a b left right;*)
	let mid = (left + right) / 2 in
	let x = mid * b in
	if right - left <= 1 then
		left
	else
		if x < a then
			div_binary_search a b mid right
		else if x = a then
			mid
		else
			div_binary_search a b left mid in

(* print_int div命令を使わない版 *)
(* 0 から 9999 までを出力 *)
let rec print_int x =
	if x >= 1000 then ()
	else if x < 0 then
		(print_char 45; print_int (-x))
	else
		(* 100の位を表示 *)
		let tx = div_binary_search x 100 0 10 in
		let dx = tx * 100 in
		let x = x - dx in
		let flg = 
			if tx <= 0 then false
			else (print_char (48 + tx); true) in
		(* 10の位を表示 *)
		let tx = div_binary_search x 10 0 10 in
		let dx = tx * 10 in
		let x = x - dx in
		let flg = 
			if tx <= 0 then
				(if flg then
					(print_char (48 + tx); true)
				else
					false)
			else
				(print_char (48 + tx); true) in
		(* 1の位を表示 *)
		print_char (48 + x) in
