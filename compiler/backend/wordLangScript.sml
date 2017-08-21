open preamble asmTheory stackLangTheory;

val _ = new_theory "wordLang";

(* word lang = structured program with words, stack and memory *)

val _ = Parse.type_abbrev("shift",``:ast$shift``);

val _ = Datatype `
  num_exp = Nat num
          | Add num_exp num_exp
          | Sub num_exp num_exp
          | Div2 num_exp
          | Exp2 num_exp
          | WordWidth ('a word)`

val _ = Datatype `
  exp = Const ('a word)
      | Var num
      | Lookup store_name
      | Load exp
      | Op binop (exp list)
      | Shift shift exp ('a num_exp)`

val MEM_IMP_exp_size = Q.store_thm("MEM_IMP_exp_size",
  `!xs a. MEM a xs ==> (exp_size l a < exp1_size l xs)`,
  Induct \\ FULL_SIMP_TAC (srw_ss()) []
  \\ REPEAT STRIP_TAC \\ SRW_TAC [] [definition"exp_size_def"]
  \\ RES_TAC \\ DECIDE_TAC);

val _ = Datatype `
  prog = Skip
       | Move num ((num # num) list)
       | Inst ('a inst)
       | Assign num ('a exp)
       | Get num store_name
       | Set store_name ('a exp)
       | Store ('a exp) num
       | MustTerminate wordLang$prog
       | Call ((num # num_set # wordLang$prog # num # num) option)
              (* return var, cut-set, return-handler code, labels l1,l2*)
              (num option) (* target of call *)
              (num list) (* arguments *)
              ((num # wordLang$prog # num # num) option)
              (* handler: varname, exception-handler code, labels l1,l2*)
       | Seq wordLang$prog wordLang$prog
       | If cmp num ('a reg_imm) wordLang$prog wordLang$prog
       | Alloc num num_set
       | Raise num
       | Return num num
       | Tick
       | LocValue num num        (* assign v1 := Loc v2 0 *)
       | Install num num num num num_set (* code buffer start, length of new code,
                                      data buffer start, length of new data, cut-set *)
       | CodeBufferWrite num num (* code buffer address, byte to write *)
       | DataBufferWrite num num (* data buffer address, word to write *)
       | FFI string num num num_set (* FFI index, array_ptr, array_len, cut-set *) `;

val raise_stub_location_def = Define`
  raise_stub_location = word_num_stubs - 1`;
val raise_stub_location_eq = save_thm("raise_stub_location_eq",
  EVAL``raise_stub_location``);

(* wordLang uses syntactic invariants compared to stackLang that uses semantic flags
   Some of these are also used to EVAL (e.g. for the oracle)
*)

(* Recursors for variables *)
val every_var_exp_def = tDefine "every_var_exp" `
  (every_var_exp P (Var num) = P num) ∧
  (every_var_exp P (Load exp) = every_var_exp P exp) ∧
  (every_var_exp P (Op wop ls) = EVERY (every_var_exp P) ls) ∧
  (every_var_exp P (Shift sh exp nexp) = every_var_exp P exp) ∧
  (every_var_exp P expr = T)`
(WF_REL_TAC `measure (exp_size ARB o SND)`
  \\ REPEAT STRIP_TAC \\ IMP_RES_TAC MEM_IMP_exp_size
  \\ TRY (FIRST_X_ASSUM (ASSUME_TAC o Q.SPEC `ARB`))
  \\ DECIDE_TAC);

val every_var_imm_def = Define`
  (every_var_imm P (Reg r) = P r) ∧
  (every_var_imm P _ = T)`

val every_var_inst_def = Define`
  (every_var_inst P (Const reg w) = P reg) ∧
  (every_var_inst P (Arith (Binop bop r1 r2 ri)) =
    (P r1 ∧ P r2 ∧ every_var_imm P ri)) ∧
  (every_var_inst P (Arith (Shift shift r1 r2 n)) = (P r1 ∧ P r2)) ∧
  (every_var_inst P (Arith (Div r1 r2 r3)) = (P r1 ∧ P r2 ∧ P r3)) ∧
  (every_var_inst P (Arith (AddCarry r1 r2 r3 r4)) = (P r1 ∧ P r2 ∧ P r3 ∧ P r4)) ∧
  (every_var_inst P (Arith (AddOverflow r1 r2 r3 r4)) = (P r1 ∧ P r2 ∧ P r3 ∧ P r4)) ∧
  (every_var_inst P (Arith (SubOverflow r1 r2 r3 r4)) = (P r1 ∧ P r2 ∧ P r3 ∧ P r4)) ∧
  (every_var_inst P (Arith (LongMul r1 r2 r3 r4)) = (P r1 ∧ P r2 ∧ P r3 ∧ P r4)) ∧
  (every_var_inst P (Arith (LongDiv r1 r2 r3 r4 r5)) = (P r1 ∧ P r2 ∧ P r3 ∧ P r4 ∧ P r5)) ∧
  (every_var_inst P (Mem Load r (Addr a w)) = (P r ∧ P a)) ∧
  (every_var_inst P (Mem Store r (Addr a w)) = (P r ∧ P a)) ∧
  (every_var_inst P (Mem Load8 r (Addr a w)) = (P r ∧ P a)) ∧
  (every_var_inst P (Mem Store8 r (Addr a w)) = (P r ∧ P a)) ∧
  (every_var_inst P inst = T)` (*catchall*)

val every_name_def = Define`
  every_name P t ⇔
  EVERY P (MAP FST (toAList t))`

val every_var_def = Define `
  (every_var P (Skip:'a prog) ⇔ T) ∧
  (every_var P (Move pri ls) = (EVERY P (MAP FST ls) ∧ EVERY P (MAP SND ls))) ∧
  (every_var P (Inst i) = every_var_inst P i) ∧
  (every_var P (Assign num exp) = (P num ∧ every_var_exp P exp)) ∧
  (every_var P (Get num store) = P num) ∧
  (every_var P (Store exp num) = (P num ∧ every_var_exp P exp)) ∧
  (every_var P (LocValue r _) = P r) ∧
  (every_var P (Install r1 r2 r3 r4 names) = (P r1 ∧ P r2 ∧ P r3 ∧ P r4 ∧ every_name P names)) ∧
  (every_var P (CodeBufferWrite r1 r2) = (P r1 ∧ P r2)) ∧
  (every_var P (DataBufferWrite r1 r2) = (P r1 ∧ P r2)) ∧
  (every_var P (FFI ffi_index ptr len names) =
    (P ptr ∧ P len ∧ every_name P names)) ∧
  (every_var P (MustTerminate s1) = every_var P s1) ∧
  (every_var P (Call ret dest args h) =
    ((EVERY P args) ∧
    (case ret of
      NONE => T
    | SOME (v,cutset,ret_handler,l1,l2) =>
      (P v ∧ every_name P cutset ∧
      every_var P ret_handler ∧
      (case h of
        NONE => T
      | SOME (v,prog,l1,l2) =>
        (P v ∧
        every_var P prog)))))) ∧
  (every_var P (Seq s1 s2) = (every_var P s1 ∧ every_var P s2)) ∧
  (every_var P (If cmp r1 ri e2 e3) =
    (P r1 ∧ every_var_imm P ri ∧ every_var P e2 ∧ every_var P e3)) ∧
  (every_var P (Alloc num numset) =
    (P num ∧ every_name P numset)) ∧
  (every_var P (Raise num) = P num) ∧
  (every_var P (Return num1 num2) = (P num1 ∧ P num2)) ∧
  (every_var P Tick = T) ∧
  (every_var P (Set n exp) = every_var_exp P exp) ∧
  (every_var P p = T)`

(*Recursor for stack variables*)
val every_stack_var_def = Define `
  (every_stack_var P (FFI ffi_index ptr len names) =
    every_name P names) ∧
  (every_stack_var P (Call ret dest args h) =
    (case ret of
      NONE => T
    | SOME (v,cutset,ret_handler,l1,l2) =>
      every_name P cutset ∧
      every_stack_var P ret_handler ∧
    (case h of  (*Does not check the case where Calls are ill-formed*)
      NONE => T
    | SOME (v,prog,l1,l2) =>
      every_stack_var P prog))) ∧
  (every_stack_var P (Alloc num numset) =
    every_name P numset) ∧
  (every_stack_var P (MustTerminate s1) =
    every_stack_var P s1) ∧
  (every_stack_var P (Seq s1 s2) =
    (every_stack_var P s1 ∧ every_stack_var P s2)) ∧
  (every_stack_var P (If cmp r1 ri e2 e3) =
    (every_stack_var P e2 ∧ every_stack_var P e3)) ∧
  (every_stack_var P p = T)`

(*Moved from wordSem, because we use them to simplify constant expressions in word_inst*)
val num_exp_def = Define `
  (num_exp (Nat n) = n) /\
  (num_exp (Add x y) = num_exp x + num_exp y) /\
  (num_exp (Sub x y) = num_exp x - num_exp y) /\
  (num_exp (Div2 x) = num_exp x DIV 2) /\
  (num_exp (Exp2 x) = 2 ** (num_exp x)) /\
  (num_exp (WordWidth (w:'a word)) = dimindex (:'a))`

val word_op_def = Define `
  word_op op (ws:('a word) list) =
    case (op,ws) of
    | (And,ws) => SOME (FOLDR word_and (¬0w) ws)
    | (Add,ws) => SOME (FOLDR word_add 0w ws)
    | (Or,ws) => SOME (FOLDR word_or 0w ws)
    | (Xor,ws) => SOME (FOLDR word_xor 0w ws)
    | (Sub,[w1;w2]) => SOME (w1 - w2)
    | _ => NONE`;

val word_sh_def = Define `
  word_sh sh (w:'a word) n =
    if n <> 0 /\ n ≥ dimindex (:'a) then NONE else
      case sh of
      | Lsl => SOME (w << n)
      | Lsr => SOME (w >>> n)
      | Asr => SOME (w >> n)
      | Ror => SOME (word_ror w n)`;

val shift_def = Define `
  shift (:'a) = if dimindex (:'a) = 32 then 2 else 3n`;

val _ = export_theory();
