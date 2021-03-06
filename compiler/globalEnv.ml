(* グローバル変数（トップレベルのlet式で定義された変数）の集合を取得してenvに入れる *)
open KNormal

let env = ref M.empty
let direct_env = ref M.empty (* 配列・タプル型のグローバル変数。グローバル変数用の領域に直接中身のデータを入れる *)
let offsets = ref M.empty
let offset = ref 0

let add_offset x n =
	let n = n * 4 in
	if not (M.mem x !offsets) then (
		offset := n + !offset;
		offsets := M.add x !offset !offsets
	)

let check_type = function
	| Type.Tuple _
	| Type.Array _ -> true
	| _ -> false

(* let x = a in let y = b in exp のexpの部分を取り出す *)
let rec get_ans = function
	| Let (_, _, e2)
	| LetTuple (_, _, e2)
	| LetRec (_, e2) -> get_ans e2
	| e -> e

let memi x env =
  try (match M.find x env with Int(_) -> true | _ -> false)
  with Not_found -> false

let findi x env = (match M.find x env with Int i -> i | _ -> raise Not_found)

let rec g envi = function
  | Let((x, t), e, e2) ->
  	  let ch = int_of_char x.[0] in
  	  (if int_of_char 'a' <= ch && ch <= int_of_char 'z' && check_type t then (
  	  	match get_ans e with
  	  		| Tuple xs -> 
  	  			Printf.printf "Tuple %s\n" x;
  	  			env := M.add x t !env;
  	  			direct_env := M.add x t !direct_env;
				add_offset x (List.length xs)
			| ExtFunApp (name, [z; _]) when memi z envi && (name = "create_array" || name = "create_float_array") -> 
				(* min-rtのdummyとかは配列長が０だったりするけど、そういうものにも正のオフセットを与える *)
				env := M.add x t !env;
  	  			direct_env := M.add x t !direct_env;
				add_offset x (max 1 (findi z envi))
			| _ -> 
				env := M.add x t !env;
				add_offset x 1
  	  ));
      g (M.add x e envi) e2
  | LetRec(_, e2) ->
      g envi e2
  | LetTuple(xts, _, e) ->
      List.iter (fun (x, t) -> env := M.add x t !env) xts;
	  g envi e
  | _ -> ()

let f e =
	g M.empty e;
	(*print_string "globalEnv.env(globalEnv.ml) = \n\t";
	M.iter (fun x y -> Printf.printf "%s " x) !env;
	print_newline ();
	
	M.print "GlobalEnv.offsets : " !offsets string_of_int;
	*)
	e
