(* Emitの出力を加工して、無駄な部分を省く *)

type t =
	| Comment of string
	| Label of Id.t
	| Data of Id.t * float * int32
	| SetL of Id.t * Id.t
	| Mvhi of Id.t * int
	| Mvlo of Id.t * int
	| Mov of Id.t * Id.t
	| FMov of Id.t * Id.t
	| FNeg of Id.t * Id.t
	| Add of Id.t * Id.t * Id.t
	| Sub of Id.t * Id.t * Id.t
	| Mul of Id.t * Id.t * Id.t
	| Div of Id.t * Id.t * Id.t
	| SLL of Id.t * Id.t * Id.t
	| Addi of Id.t * Id.t * int
	| Subi of Id.t * Id.t * int
	| Muli of Id.t * Id.t * int
	| Divi of Id.t * Id.t * int
	| SLLi of Id.t * Id.t * int
	| SRLi of Id.t * Id.t * int
	| FAdd of Id.t * Id.t * Id.t
	| FSub of Id.t * Id.t * Id.t
	| FMul of Id.t * Id.t * Id.t
	| FDiv of Id.t * Id.t * Id.t
	| FSqrt of Id.t * Id.t
	| FAbs of Id.t * Id.t
	| Ld of Id.t * Id.t * Id.t
	| St of Id.t * Id.t * Id.t
	| Ldi of Id.t * Id.t * int
	| Sti of Id.t * Id.t * int
	| LdF of Id.t * Id.t * Id.t
	| StF of Id.t * Id.t * Id.t
	| LdFi of Id.t * Id.t * int
	| StFi of Id.t * Id.t * int
	| Input of Id.t
	| InputW of Id.t
	| InputF of Id.t
	| Output of Id.t
	| OutputW of Id.t
	| OutputF of Id.t
	| B of Id.t
	| Jmp of Id.t
	| JCmp of Id.t * Id.t * Id.t * Id.t
	| Call of Id.t
	| CallR of Id.t
	| Return
	| Halt

type state = Exist | Vanish
	
type stmt = {
	inst : t;
	mutable state : state
}

let prog = ref []
let add_stmt inst = prog := {inst = inst; state = Exist} :: !prog

(* %g1の無駄な増減を削除 *)
let get_some x = match x with Some a -> a | _ -> assert false
let eliminate_sp_calc ls =
	List.fold_left (
		fun target stmt ->
			match stmt.inst with
				| Addi (x, y, n) when target <> None && x = Asm.reg_sp && y = Asm.reg_sp ->
					(match (get_some target).inst with
						| Subi (x2, y2, n2) when n = n2 ->
							(get_some target).state <- Vanish;
							stmt.state <- Vanish;
							None
						| _ -> None
					)
				| Subi (x, y, n) when target <> None && x = Asm.reg_sp && y = Asm.reg_sp -> 
					(match (get_some target).inst with
						| Addi (x2, y2, n2) when n = n2 ->
							(get_some target).state <- Vanish;
							stmt.state <- Vanish;
							None
						| _ -> None
					)
				| Addi (x, y, n) when x = Asm.reg_sp && y = Asm.reg_sp -> Some stmt
				| Subi (x, y, n) when x = Asm.reg_sp && y = Asm.reg_sp -> Some stmt
				| Label _
				| B _
				| Jmp _
				| JCmp _
				| Call _
				| CallR _
				| Return
				| Halt -> None
				| Ld (x, y, _) 
				| St (x, y, _)
				| Ldi (x, y, _) 
				| Sti (x, y, _)
				| LdF (x, y, _)
				| StF (x, y, _)
				| LdFi (x, y, _)
				| StFi (x, y, _) when x = Asm.reg_sp || y = Asm.reg_sp -> None
				| _ -> target
	) None ls
	

(* 最適化 *)
let optimize () = eliminate_sp_calc !prog

(* 一文を出力 *)
let output_stmt oc stmt =
	if stmt.state = Vanish then ()
	else (
		(match stmt.state with
			| Exist -> ()
			| Vanish -> Printf.fprintf oc "! ";
		);
		match stmt.inst with
			| Comment comment -> Printf.fprintf oc "%s\n" comment
			| Label label -> Printf.fprintf oc "%s:\n" label
			| Data (label, f, b) ->
				Printf.fprintf oc "%s:\t! %f\n" label f;
				Printf.fprintf oc "\t.long\t0x%lx\n" b
			| SetL (dst, label) -> 	Printf.fprintf oc "\tsetL %s, %s\n" dst label (* ラベルのコピー *)
			| Mvhi (dst, n) -> Printf.fprintf oc "\tmvhi\t%s, %d\n" dst n
			| Mvlo (dst, n) -> Printf.fprintf oc "\tmvlo\t%s, %d\n" dst n
			| Mov (dst, src) -> Printf.fprintf oc "\tmov\t%s, %s\n" dst src
			| FMov (dst, src) -> Printf.fprintf oc "\tfmov\t%s, %s\n" dst src
			| FNeg (dst, src) -> Printf.fprintf oc "\tfneg\t%s, %s\n" dst src
			| Add (dst, x, y) -> Printf.fprintf oc "\tadd\t%s, %s, %s\n" dst x y
			| Sub (dst, x, y) -> Printf.fprintf oc "\tsub\t%s, %s, %s\n" dst x y
			| Mul (dst, x, y) -> Printf.fprintf oc "\tmul\t%s, %s, %s\n" dst x y
			| Div (dst, x, y) -> Printf.fprintf oc "\tdiv\t%s, %s, %s\n" dst x y
			| SLL (dst, x, y) -> Printf.fprintf oc "\tsll\t%s, %s, %s\n" dst x y
			| Addi (dst, x, y) -> Printf.fprintf oc "\taddi\t%s, %s, %d\n" dst x y
			| Subi (dst, x, y) -> Printf.fprintf oc "\tsubi\t%s, %s, %d\n" dst x y
			| Muli (dst, x, y) -> Printf.fprintf oc "\tmuli\t%s, %s, %d\n" dst x y
			| Divi (dst, x, y) -> Printf.fprintf oc "\tdivi\t%s, %s, %d\n" dst x y
			| SLLi (dst, x, y) -> Printf.fprintf oc "\tslli\t%s, %s, %d\n" dst x y
			| SRLi (dst, x, y) -> Printf.fprintf oc "\tsrli\t%s, %s, %d\n" dst x y
			| FAdd (dst, x, y) -> Printf.fprintf oc "\tfadd\t%s, %s, %s\n" dst x y
			| FSub (dst, x, y) -> Printf.fprintf oc "\tfsub\t%s, %s, %s\n" dst x y
			| FMul (dst, x, y) -> Printf.fprintf oc "\tfmul\t%s, %s, %s\n" dst x y
			| FDiv (dst, x, y) -> Printf.fprintf oc "\tfdiv\t%s, %s, %s\n" dst x y
			| FSqrt (dst, src) -> Printf.fprintf oc "\tfsqrt\t%s, %s\n" dst src
			| FAbs (dst, src) -> Printf.fprintf oc "\tfabs\t%s, %s\n" dst src

			| Ld (dst, src, index) -> Printf.fprintf oc "\tld\t%s, %s, %s\n" dst src index;
			| Ldi (dst, src, index) -> Printf.fprintf oc "\tldi\t%s, %s, %d\n" dst src index;
			| LdF (dst, src, index) -> Printf.fprintf oc "\tfld\t%s, %s, %s\n" dst src index;
			| LdFi (dst, src, index) -> Printf.fprintf oc "\tfldi\t%s, %s, %d\n" dst src index;

			| St (src, target, index) -> Printf.fprintf oc "\tst\t%s, %s, %s\n" src target index;
			| Sti (src, target, index) -> Printf.fprintf oc "\tsti\t%s, %s, %d\n" src target index;
			| StF (src, target, index) -> Printf.fprintf oc "\tfst\t%s, %s, %s\n" src target index;
			| StFi (src, target, index) -> Printf.fprintf oc "\tfsti\t%s, %s, %d\n" src target index;

			| Input src -> 	Printf.fprintf oc "\tinput\t%s\n" src;
			| InputW src -> 	Printf.fprintf oc "\tinputw\t%s\n" src;
			| InputF src -> 	Printf.fprintf oc "\tinputf\t%s\n" src;
			
			| Output dst -> Printf.fprintf oc "\toutput\t%s\n" dst;
			| OutputW dst -> Printf.fprintf oc "\toutputw\t%s\n" dst;
			| OutputF dst -> Printf.fprintf oc "\toutputf\t%s\n" dst;
			
			| B reg -> Printf.fprintf oc "\tb\t%s\n" reg;
			| Jmp label -> Printf.fprintf oc "\tjmp\t%s\n" label;
			| JCmp (typ, x, y, label) -> Printf.fprintf oc "\t%s\t%s, %s, %s\n" typ x y label
			| Call label -> Printf.fprintf oc "\tcall\t%s\n" label
			| CallR cls -> Printf.fprintf oc "\tcallR\t%s\n" cls
			| Return -> Printf.fprintf oc "\treturn\n"
			| Halt -> Printf.fprintf oc "\thalt\n"
	)

(* 出力 *)
let output oc = List.iter (output_stmt oc) (List.rev !prog)
