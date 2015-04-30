open HolKernel Parse boolLib bossLib; val _ = new_theory "closLang";

open pred_setTheory arithmeticTheory pairTheory listTheory combinTheory;
open finite_mapTheory sumTheory relationTheory stringTheory optionTheory;
open lcsymtacs bvlTheory;

(* ClosLang -- compilation from this lanugage removes closures, gets to BVL *)

(* --- Syntax of ClosLang --- *)

(* ClosLang uses De Bruijn indices so there is no need for a variable
   name in the let-expression. *)

val max_app_def = Define `
  max_app = 15:num`;

val _ = Datatype `
  clos_exp = Var num
           | If clos_exp clos_exp clos_exp
           | Let (clos_exp list) clos_exp
           | Raise clos_exp
           | Handle clos_exp clos_exp
           | Tick clos_exp
           | Call num (clos_exp list)
           | App (num option) clos_exp (clos_exp list)
           | Fn num (num list) num clos_exp
           | Letrec num (num list) ((num # clos_exp) list) clos_exp
           | Op bvl_op (clos_exp list) `

(* --- Semantics of ClosLang --- *)

val _ = Datatype `
  clos_val =
    Number int
  | Block num (clos_val list)
  | RefPtr num
  | Closure num (clos_val list) (clos_val list) num clos_exp
  | Recclosure num (clos_val list) (clos_val list) ((num # clos_exp) list) num`

val _ = Datatype `
  clos_res = Result 'a
           | Exception clos_val
           | TimeOut
           | Error `

val _ = Datatype `
  clos_ref = ValueArray (clos_val list)
           | ByteArray (word8 list)`

val _ = Datatype `
  clos_state =
    <| globals : (clos_val option) list
     ; refs    : num |-> clos_ref
     ; clock   : num
     ; code    : num |-> (num # clos_exp)
     ; output  : string
     ; restrict_envs : bool |> `

(* helper functions *)

val get_global_def = Define `
  get_global n globals =
    if n < LENGTH globals then SOME (EL n globals) else NONE`

val bool_to_val_def = Define `
  (bool_to_val T = Block 10 []) /\
  (bool_to_val F = Block 11 [])`;

val clos_equal_def = tDefine "clos_equal" `
  (clos_equal x y =
     case x of
     | Number i =>
         (case y of
          | Number j => Eq_val (i = j)
          | _ => Eq_val F)
     | Block t1 xs =>
         (case y of
          | Block t2 ys => if (t1 = t2) /\ (LENGTH xs = LENGTH ys) then
                             clos_equal_list xs ys
                           else Eq_val F
          | Number _ => Eq_val F
          | RefPtr _ => Eq_val F
          | _ => Eq_closure)
     | RefPtr i =>
         (case y of
          | RefPtr j => Eq_val (i = j)
          | _ => Eq_val F)
     | _ =>
         (case y of
          | Number _ => Eq_val F
          | RefPtr _ => Eq_val F
          | _ => Eq_closure)) /\
  (clos_equal_list [] [] = Eq_val T) /\
  (clos_equal_list (x::xs) (y::ys) =
     case clos_equal x y of
     | Eq_val T => clos_equal_list xs ys
     | res => res) /\
  (clos_equal_list _ _ = Eq_val F)`
 (WF_REL_TAC `measure (\x. case x of INL (v,_) => clos_val_size v
                                   | INR (vs,_) => clos_val1_size vs)`)

val clos_to_chars_def = Define `
  (clos_to_chars [] ac = SOME (REVERSE ac)) /\
  (clos_to_chars (((Number i):clos_val)::vs) ac =
     if 0 <= i /\ i < 256 then
       clos_to_chars vs (STRING (CHR (Num (ABS i))) ac)
     else NONE) /\
  (clos_to_chars _ _ = NONE)`

val clos_to_string_def = Define `
  (clos_to_string (Number i) = SOME (int_to_string i)) /\
  (clos_to_string (Block n vs) =
   (if n = 0 then SOME "false"
    else if n = 1 then SOME "true"
    else if n = 2 then SOME "()"
    else if n = 4 then SOME "<vector>"
    else if n = 3 then
      case clos_to_chars vs "" of
        NONE => NONE
      | SOME cs => SOME (string_to_string (IMPLODE cs))
    else SOME "<constructor>")) /\
  (clos_to_string ((RefPtr v0) : clos_val) = SOME "<ref>") /\
  (clos_to_string _ = SOME "<fn>")`;

val clos_from_list_def = Define`
  (clos_from_list (Block tag []) =
     if tag = nil_tag + block_tag then SOME [] else NONE) ∧
  (clos_from_list (Block tag [h;bt]) =
     if tag = cons_tag + block_tag then
       (case clos_from_list bt of
        | SOME t => SOME (h::t)
        | _ => NONE )
     else NONE) ∧
  (clos_from_list _ = NONE)`

val clos_to_list_def = Define`
  (clos_to_list [] = Block (nil_tag + block_tag) []) ∧
  (clos_to_list (h::t) = Block (cons_tag + block_tag) [h;clos_to_list t])`

val cEvalOp_def = Define `
  cEvalOp (op:bvl_op) (vs:clos_val list) (s:clos_state) =
    case (op,vs) of
    | (Global n,[]:clos_val list) =>
        (case get_global n s.globals of
         | SOME (SOME v) => SOME (v,s)
         | _ => NONE)
    | (SetGlobal n,[v]) =>
        (case get_global n s.globals of
         | SOME NONE => SOME (Number 0,
             s with globals := (LUPDATE (SOME v) n s.globals))
         | _ => NONE)
    | (AllocGlobal,[]) =>
        SOME (Number 0, s with globals := s.globals ++ [NONE])
    | (Const i,[]) => SOME (Number i, s)
    | (Cons tag,xs) => SOME (Block tag xs, s)
    | (El,[Block tag xs;Number i]) =>
        if 0 ≤ i ∧ Num i < LENGTH xs then SOME (EL (Num i) xs, s) else NONE
    | (LengthBlock,[Block tag xs]) =>
        SOME (Number (&LENGTH xs), s)
    | (Length,[RefPtr ptr]) =>
        (case FLOOKUP s.refs ptr of
          | SOME (ValueArray xs) =>
              SOME (Number (&LENGTH xs), s)
          | _ => NONE)
    | (LengthByte,[RefPtr ptr]) =>
        (case FLOOKUP s.refs ptr of
          | SOME (ByteArray xs) =>
              SOME (Number (&LENGTH xs), s)
          | _ => NONE)
    | (RefByte,[Number i;Number b]) =>
         if 0 ≤ i ∧ 0 ≤ b ∧ b < 256 then
           let ptr = (LEAST ptr. ¬(ptr IN FDOM s.refs)) in
             SOME (RefPtr ptr, s with refs := s.refs |+
               (ptr,ByteArray (REPLICATE (Num i) (n2w (Num b)))))
         else NONE
    | (RefArray,[Number i;v]) =>
        if 0 ≤ i then
          let ptr = (LEAST ptr. ¬(ptr IN FDOM s.refs)) in
            SOME (RefPtr ptr, s with refs := s.refs |+
              (ptr,ValueArray (REPLICATE (Num i) v)))
         else NONE
    | (DerefByte,[RefPtr ptr; Number i]) =>
        (case FLOOKUP s.refs ptr of
         | SOME (ByteArray ws) =>
            (if 0 ≤ i ∧ i < &LENGTH ws
             then SOME (Number (&(w2n (EL (Num i) ws))),s)
             else NONE)
         | _ => NONE)
    | (UpdateByte,[RefPtr ptr; Number i; Number b]) =>
        (case FLOOKUP s.refs ptr of
         | SOME (ByteArray bs) =>
            (if 0 ≤ i ∧ i < &LENGTH bs ∧ 0 ≤ b ∧ b < 256
             then
               (SOME (Number b, s with refs := s.refs |+
                 (ptr, ByteArray (LUPDATE (n2w (Num b)) (Num i) bs))))
             else NONE)
         | _ => NONE)
    | (FromList n,[lv]) =>
        (case clos_from_list lv of
         | SOME vs => SOME (Block n vs, s)
         | _ => NONE)
    | (ToList,[Block tag xs]) =>
        SOME (clos_to_list xs, s)
    | (TagEq n,[Block tag xs]) =>
        SOME (bool_to_val (tag = n),s)
    | (Equal,[x1;x2]) =>
        (case clos_equal x1 x2 of
         | Eq_val b => SOME (bool_to_val b, s)
         | Eq_closure => SOME (Number 0, s)
         | _ => NONE)
    | (IsBlock,[Number i]) => SOME (bool_to_val F, s)
    | (IsBlock,[RefPtr ptr]) => SOME (bool_to_val F, s)
    | (IsBlock,[Block tag ys]) => SOME (bool_to_val T, s)
    | (Ref,xs) =>
        let ptr = (LEAST ptr. ~(ptr IN FDOM s.refs)) in
          SOME (RefPtr ptr, s with refs := s.refs |+ (ptr,ValueArray xs))
    | (Deref,[RefPtr ptr; Number i]) =>
        (case FLOOKUP s.refs ptr of
         | SOME (ValueArray xs) =>
            (if 0 <= i /\ i < & (LENGTH xs)
             then SOME (EL (Num i) xs, s)
             else NONE)
         | _ => NONE)
    | (Update,[RefPtr ptr; Number i; x]) =>
        (case FLOOKUP s.refs ptr of
         | SOME (ValueArray xs) =>
            (if 0 <= i /\ i < & (LENGTH xs)
             then SOME (x, s with refs := s.refs |+
                    (ptr,ValueArray (LUPDATE x (Num i) xs)))
             else NONE)
         | _ => NONE)
    | (Add,[Number n1; Number n2]) => SOME (Number (n1 + n2),s)
    | (Sub,[Number n1; Number n2]) => SOME (Number (n1 - n2),s)
    | (Mult,[Number n1; Number n2]) => SOME (Number (n1 * n2),s)
    | (Div,[Number n1; Number n2]) =>
         if n2 = 0 then NONE else SOME (Number (n1 / n2),s)
    | (Mod,[Number n1; Number n2]) =>
         if n2 = 0 then NONE else SOME (Number (n1 % n2),s)
    | (Less,[Number n1; Number n2]) =>
         SOME (bool_to_val (n1 < n2),s)
    | (Print, [x]) =>
        (case clos_to_string x of
         | SOME str => SOME (x, s with output := s.output ++ str)
         | NONE => NONE)
    | (PrintC c, []) =>
          SOME (Number 0, s with output := s.output ++ [c])
    | _ => NONE`

val dec_clock_def = Define `
  dec_clock n (s:clos_state) = s with clock := s.clock - n`;

val find_code_def = Define `
  find_code p args code =
    case FLOOKUP code p of
    | NONE => NONE
    | SOME (arity,exp) => if LENGTH args = arity then SOME (args,exp)
                                                 else NONE`

(* The evaluation is defined as a clocked functional version of
   a conventional big-step operational semantics. *)

(* Proving termination of the evaluator directly is tricky. We make
   our life simpler by forcing the clock to stay good using
   check_clock. At the bottom of this file, we remove all occurrences
   of check_clock. *)

val check_clock_def = Define `
  check_clock s1 s2 =
    if s1.clock <= s2.clock then s1 else s1 with clock := s2.clock`;

val check_clock_thm = prove(
  ``(check_clock s1 s2).clock <= s2.clock /\
    (s1.clock <= s2.clock ==> (check_clock s1 s2 = s1))``,
  SRW_TAC [] [check_clock_def])

val check_clock_lemma = prove(
  ``b ==> ((check_clock s1 s).clock < s.clock \/
          ((check_clock s1 s).clock = s.clock) /\ b)``,
  SRW_TAC [] [check_clock_def] \\ DECIDE_TAC);

(* The semantics of expression evaluation is defined next. For
   convenience of subsequent proofs, the evaluation function is
   defined to evaluate a list of clos_exp expressions. *)

val lookup_vars_def = Define `
  (lookup_vars [] env = SOME []) /\
  (lookup_vars (v::vs) env =
     if v < LENGTH env then
       case lookup_vars vs env of
       | SOME xs => SOME (EL v env :: xs)
       | NONE => NONE
     else NONE)`

val check_loc_opt_def = Define `
  (check_loc NONE loc num_params num_args so_far ⇔ num_args ≤ max_app) /\
  (check_loc (SOME p) loc num_params num_args so_far ⇔ 
    (num_params = num_args) ∧ (so_far = 0:num) ∧ (p = loc))`;

val _ = Datatype `
  app_kind =
    | Partial_app clos_val
    | Full_app clos_exp (clos_val list) (clos_val list)`;

val dest_closure_def = Define `
  dest_closure loc_opt f args =
    case f of
    | Closure loc arg_env clo_env num_args exp =>
        if check_loc loc_opt loc num_args (LENGTH args) (LENGTH arg_env) ∧ LENGTH arg_env < num_args then
          if ¬(LENGTH args + LENGTH arg_env < num_args) then
            SOME (Full_app exp
                           (REVERSE (TAKE (num_args - LENGTH arg_env) (REVERSE args))++
                            arg_env++clo_env)
                           (REVERSE (DROP (num_args - LENGTH arg_env) (REVERSE args))))
          else
            SOME (Partial_app (Closure loc (args++arg_env) clo_env num_args exp))
        else
          NONE
    | Recclosure loc arg_env clo_env fns i =>
        let (num_args,exp) = EL i fns in
          if LENGTH fns <= i \/ 
             ~(check_loc loc_opt (loc+i) num_args (LENGTH args) (LENGTH arg_env)) ∨
             ¬(LENGTH arg_env < num_args) then NONE else
            let rs = GENLIST (Recclosure loc [] clo_env fns) (LENGTH fns) in
              if ¬(LENGTH args + LENGTH arg_env < num_args) then
                SOME (Full_app exp
                               (REVERSE (TAKE (num_args - LENGTH arg_env) (REVERSE args))++
                                arg_env++rs++clo_env)
                               (REVERSE (DROP (num_args - LENGTH arg_env) (REVERSE args))))
              else
                SOME (Partial_app (Recclosure loc (args++arg_env) clo_env fns i))
    | _ => NONE`;

val dest_closure_length = Q.prove (
`!loc_opt f args exp args1 args2 so_far.
  dest_closure loc_opt f args = SOME (Full_app exp args1 args2)
  ⇒
  LENGTH args2 < LENGTH args`,
 rw [dest_closure_def] >>
 BasicProvers.EVERY_CASE_TAC >>
 fs [] >>
 rw [] >>
 TRY decide_tac >>
 Cases_on `EL n l1` >>
 fs [LET_THM] >>
 Cases_on `LENGTH args + LENGTH l < q` >>
 fs [] >>
 rw [] >>
 decide_tac);

val clos_env_def = Define `
  clos_env restrict names env =
    if restrict then lookup_vars names env else SOME env`

val build_recc_def = Define `
  build_recc restrict loc env names fns =
    case clos_env restrict names env of
    | SOME env1 => SOME (GENLIST (Recclosure loc [] env1 fns) (LENGTH fns))
    | NONE => NONE`

val cEval_def = tDefine "cEval" `
  (cEval ([],env:clos_val list,s:clos_state) = (Result [],s)) /\
  (cEval (x::y::xs,env,s) =
     case cEval ([x],env,s) of
     | (Result v1,s1) =>
         (case cEval (y::xs,env,check_clock s1 s) of
          | (Result vs,s2) => (Result (HD v1::vs),s2)
          | res => res)
     | res => res) /\
  (cEval ([Var n],env,s) =
     if n < LENGTH env then (Result [EL n env],s) else (Error,s)) /\
  (cEval ([If x1 x2 x3],env,s) =
     case cEval ([x1],env,s) of
     | (Result vs,s1) =>
          if Block 10 [] = HD vs then cEval ([x2],env,check_clock s1 s) else
          if Block 11 [] = HD vs then cEval ([x3],env,check_clock s1 s) else
            (Error,s1)
     | res => res) /\
  (cEval ([Let xs x2],env,s) =
     case cEval (xs,env,s) of
     | (Result vs,s1) => cEval ([x2],vs++env,check_clock s1 s)
     | res => res) /\
  (cEval ([Raise x1],env,s) =
     case cEval ([x1],env,s) of
     | (Result vs,s) => (Exception (HD vs),s)
     | res => res) /\
  (cEval ([Handle x1 x2],env,s1) =
     case cEval ([x1],env,s1) of
     | (Exception v,s) => cEval ([x2],v::env,check_clock s s1)
     | res => res) /\
  (cEval ([Op op xs],env,s) =
     case cEval (xs,env,s) of
     | (Result vs,s) => (case cEvalOp op (REVERSE vs) s of
                          | NONE => (Error,s)
                          | SOME (v,s) => (Result [v],s))
     | res => res) /\
  (cEval ([Fn loc vs num_args exp],env,s) =
     if num_args ≤ max_app ∧ num_args ≠ 0 then
       case clos_env s.restrict_envs vs env of
       | NONE => (Error,s)
       | SOME env' => (Result [Closure loc [] env' num_args exp], s)
     else
       (Error, s)) /\
  (cEval ([Letrec loc names fns exp],env,s) =
     if EVERY (\(num_args,e). num_args ≤ max_app ∧ num_args ≠ 0) fns then
       case build_recc s.restrict_envs loc env names fns of
       | NONE => (Error,s)
       | SOME rs => cEval ([exp],rs ++ env,s)
     else
       (Error, s)) /\
  (cEval ([App loc_opt x1 args],env,s) =
     if LENGTH args > 0 then
       (case cEval (args,env,s) of
        | (Result y2,s1) =>
          (case cEval ([x1],env,check_clock s1 s) of
           | (Result y1,s2) => cEvalApp loc_opt (HD y1) y2 (check_clock s2 s)
           | res => res)
        | res => res)
     else
       (Error, s)) /\
  (cEval ([Tick x],env,s) =
     if s.clock = 0 then (TimeOut,s) else cEval ([x],env,dec_clock 1 s)) /\
  (cEval ([Call dest xs],env,s1) =
     case cEval (xs,env,s1) of
     | (Result vs,s) =>
         (case find_code dest vs s.code of
          | NONE => (Error,s)
          | SOME (args,exp) =>
              if (s.clock = 0) \/ (s1.clock = 0) then (TimeOut,s) else
                  cEval ([exp],args,dec_clock 1 (check_clock s s1)))
     | res => res) ∧
  (cEvalApp loc_opt f [] s = (Result [f], s)) ∧
  (cEvalApp loc_opt f args s =
     case dest_closure loc_opt f args of
     | NONE => (Error,s)
     | SOME (Partial_app v) => 
         if s.clock < LENGTH args
         then (TimeOut,s with clock := 0)
         else (Result [v], dec_clock (LENGTH args) s)
     | SOME (Full_app exp env rest_args) =>
         if s.clock < (LENGTH args - LENGTH rest_args)
         then (TimeOut,s with clock := 0)
         else
           case cEval ([exp],env,dec_clock (LENGTH args - LENGTH rest_args) s) of
           | (Result [v], s1) =>
               cEvalApp loc_opt v rest_args (check_clock s1 s)
           | res => res)`
 (WF_REL_TAC `(inv_image (measure I LEX measure I LEX measure I)
               (\x. case x of INL (xs,env,s) => (s.clock,clos_exp3_size xs,0)
                              | INR (l,f,args,s) => (s.clock,0,LENGTH args)))`
  \\ REPEAT STRIP_TAC \\ TRY DECIDE_TAC
  \\ TRY (MATCH_MP_TAC check_clock_lemma \\ DECIDE_TAC)
  \\ EVAL_TAC \\ Cases_on `s.clock <= s1.clock`
  \\ Cases_on `s.clock <= s2.clock`
  \\ FULL_SIMP_TAC (srw_ss()) []
  \\ SRW_TAC [] []
  \\ TRY DECIDE_TAC >>
  imp_res_tac dest_closure_length >>
  full_simp_tac (srw_ss()++ARITH_ss) [])

(* We prove that the clock never increases. *)

val check_clock_IMP = prove(
  ``n <= (check_clock r s).clock ==> n <= s.clock``,
  SRW_TAC [] [check_clock_def] \\ DECIDE_TAC);

val cEvalOp_const = store_thm("cEvalOp_const",
  ``(cEvalOp op args s1 = SOME (res,s2)) ==>
    (s2.clock = s1.clock) /\
    (s2.code = s1.code) /\
    (s2.restrict_envs = s1.restrict_envs)``,
  SIMP_TAC std_ss [cEvalOp_def]
  \\ BasicProvers.EVERY_CASE_TAC
  \\ fs [LET_DEF] \\ SRW_TAC [] [] \\ fs []);

val cEval_clock_help = prove (
  ``(!tup vs s2.
      (cEval tup = (vs,s2)) ==> s2.clock <= (SND (SND tup)).clock) ∧
    (!loc_opt f args s1 vs s2.
      (cEvalApp loc_opt f args s1 = (vs,s2)) ==> s2.clock <= s1.clock)``,
  ho_match_mp_tac (fetch "-" "cEval_ind") \\ REPEAT STRIP_TAC
  \\ POP_ASSUM MP_TAC \\ ONCE_REWRITE_TAC [cEval_def]
  \\ FULL_SIMP_TAC std_ss [] \\ BasicProvers.EVERY_CASE_TAC
  \\ REPEAT STRIP_TAC \\ SRW_TAC [] [check_clock_def]
  \\ RES_TAC \\ IMP_RES_TAC check_clock_IMP
  \\ FULL_SIMP_TAC std_ss [PULL_FORALL] \\ RES_TAC
  \\ IMP_RES_TAC check_clock_IMP
  \\ IMP_RES_TAC cEvalOp_const
  \\ FULL_SIMP_TAC (srw_ss()) [dec_clock_def] \\ TRY DECIDE_TAC
  \\ POP_ASSUM MP_TAC
  \\ TRY (REPEAT (POP_ASSUM (K ALL_TAC))
          \\ SRW_TAC [] [check_clock_def] \\ DECIDE_TAC)
  \\ rfs [] \\ fs [] \\ rfs [check_clock_def]);

val cEval_clock = store_thm("cEval_clock",
``(!xs env s1 vs s2.
      (cEval (xs,env,s1) = (vs,s2)) ==> s2.clock <= s1.clock)``,
 metis_tac [cEval_clock_help, SND]);

val cEval_check_clock = prove(
  ``!xs env s1 vs s2.
      (cEval (xs,env,s1) = (vs,s2)) ==> (check_clock s2 s1 = s2)``,
  METIS_TAC [cEval_clock,check_clock_thm]);

(* Finally, we remove check_clock from the induction and definition theorems. *)

fun sub f tm = f tm handle HOL_ERR _ =>
  let val (v,t) = dest_abs tm in mk_abs (v, sub f t) end
  handle HOL_ERR _ =>
  let val (t1,t2) = dest_comb tm in mk_comb (sub f t1, sub f t2) end
  handle HOL_ERR _ => tm

val pat = ``check_clock s1 s2``
val remove_check_clock = sub (fn tm =>
  if can (match_term pat) tm
  then tm |> rator |> rand else fail())

val remove_disj = sub (fn tm => if is_disj tm then tm |> rator |> rand else fail())

val cEval_ind = save_thm("cEval_ind",let
  val raw_ind = fetch "-" "cEval_ind"
  val goal = raw_ind |> concl |> remove_check_clock |> remove_disj
  (* set_goal([],goal) *)
  val ind = prove(goal,
    NTAC 3 STRIP_TAC \\ MATCH_MP_TAC raw_ind
    \\ Tactical.REVERSE (REPEAT STRIP_TAC) \\ ASM_REWRITE_TAC []
    \\ TRY
     (FIRST_X_ASSUM (MATCH_MP_TAC) \\ REPEAT STRIP_TAC \\ fs []
      \\ IMP_RES_TAC cEval_clock
      \\ IMP_RES_TAC check_clock_thm \\ fs []
      \\ `s1.clock <= s.clock` by (fs [dec_clock_def] \\ DECIDE_TAC)
      \\ IMP_RES_TAC check_clock_thm \\ fs [])
    \\ TRY
     (FIRST_X_ASSUM (MATCH_MP_TAC)
      \\ ASM_REWRITE_TAC [] \\ REPEAT STRIP_TAC \\ fs []
      \\ IMP_RES_TAC cEval_clock
      \\ IMP_RES_TAC check_clock_thm \\ fs []
      \\ FIRST_X_ASSUM (MATCH_MP_TAC)
      \\ DECIDE_TAC)
    \\ TRY
     (FIRST_X_ASSUM (MATCH_MP_TAC)
      \\ ASM_REWRITE_TAC [] \\ REPEAT STRIP_TAC \\ fs []
      \\ IMP_RES_TAC cEval_clock \\ IMP_RES_TAC LESS_EQ_TRANS
      \\ IMP_RES_TAC check_clock_thm \\ fs []
      \\ FIRST_X_ASSUM (MATCH_MP_TAC)
      \\ DECIDE_TAC)
   \\ TRY
     (IMP_RES_TAC cEval_clock
      \\ fs [dec_clock_def]
      \\ IMP_RES_TAC (DECIDE ``n <= m - k:num ==> n <= m``)
      \\ IMP_RES_TAC LESS_EQ_TRANS
      \\ IMP_RES_TAC check_clock_thm \\ fs []))
  in ind end);

val cEval_def = save_thm("cEval_def",let
  val goal = cEval_def |> concl |> remove_check_clock |> remove_disj
  (* set_goal([],goal) *)
  val thm = prove(goal,
    REPEAT STRIP_TAC
    \\ SIMP_TAC std_ss [Once cEval_def]
    \\ BasicProvers.EVERY_CASE_TAC
    \\ IMP_RES_TAC cEval_check_clock \\ fs []
    \\ SRW_TAC [] []
    \\ IMP_RES_TAC cEval_clock
    \\ fs [check_clock_def,dec_clock_def]
    \\ TRY (`F` by DECIDE_TAC)
    \\ IMP_RES_TAC LESS_EQ_TRANS
    \\ fs [check_clock_def])
  in thm end);

(* lemmas *)

val cEval_LENGTH_ind =
  cEval_ind
  |> Q.SPEC `\(xs,s,env).
       (case cEval (xs,s,env) of (Result res,s1) => (LENGTH xs = LENGTH res)
            | _ => T)`
  |> Q.SPEC `\x1 x2 x3 x4.
       (case cEvalApp x1 x2 x3 x4 of (Result res,s1) => (LENGTH res = 1)
            | _ => T)`

val cEval_LENGTH = prove(cEval_LENGTH_ind |> concl |> rand,
  MATCH_MP_TAC cEval_LENGTH_ind
  \\ REPEAT STRIP_TAC \\ fs []
  \\ ONCE_REWRITE_TAC [cEval_def] \\ fs []
  \\ BasicProvers.EVERY_CASE_TAC \\ fs [] \\ rfs [] \\ fs [])
  |> SIMP_RULE std_ss [FORALL_PROD]

val _ = save_thm("cEval_LENGTH", cEval_LENGTH);

val cEval_IMP_LENGTH = store_thm("cEval_IMP_LENGTH",
  ``(cEval (xs,s,env) = (Result res,s1)) ==> (LENGTH xs = LENGTH res)``,
  REPEAT STRIP_TAC
  \\ MP_TAC (cEval_LENGTH |> CONJUNCT1 |> Q.SPECL [`xs`,`s`,`env`])
  \\ fs []);

val cEvalApp_IMP_LENGTH = store_thm("cEvalApp_IMP_LENGTH",
  ``(cEvalApp x1 x2 x3 x4 = (Result res,s1)) ==> (LENGTH res = 1)``,
  REPEAT STRIP_TAC
  \\ MP_TAC (cEval_LENGTH |> CONJUNCT2 |> Q.SPECL [`x1`,`x2`,`x3`,`x4`])
  \\ fs []);

val cEval_SING = store_thm("cEval_SING",
  ``(cEval ([x],s,env) = (Result r,s2)) ==> ?r1. r = [r1]``,
  REPEAT STRIP_TAC \\ IMP_RES_TAC cEval_IMP_LENGTH
  \\ Cases_on `r` \\ fs [] \\ Cases_on `t` \\ fs []);

val cEval_CONS = store_thm("cEval_CONS",
  ``cEval (x::xs,env,s) =
      case cEval ([x],env,s) of
      | (Result v,s2) =>
         (case cEval (xs,env,s2) of
          | (Result vs,s1) => (Result (HD v::vs),s1)
          | t => t)
      | t => t``,
  Cases_on `xs` \\ fs [cEval_def]
  \\ Cases_on `cEval ([x],env,s)` \\ fs [cEval_def]
  \\ Cases_on `q` \\ fs [cEval_def]
  \\ IMP_RES_TAC cEval_IMP_LENGTH
  \\ Cases_on `a` \\ fs []
  \\ Cases_on `t` \\ fs []);

val cEval_SNOC = store_thm("cEval_SNOC",
  ``!xs env s x.
      cEval (SNOC x xs,env,s) =
      case cEval (xs,env,s) of
      | (Result vs,s2) =>
         (case cEval ([x],env,s2) of
          | (Result v,s1) => (Result (vs ++ v),s1)
          | t => t)
      | t => t``,
  Induct THEN1
   (fs [SNOC_APPEND,cEval_def] \\ REPEAT STRIP_TAC
    \\ Cases_on `cEval ([x],env,s)` \\ Cases_on `q` \\ fs [])
  \\ fs [SNOC_APPEND,APPEND]
  \\ ONCE_REWRITE_TAC [cEval_CONS]
  \\ REPEAT STRIP_TAC
  \\ Cases_on `cEval ([h],env,s)` \\ Cases_on `q` \\ fs []
  \\ Cases_on `cEval (xs,env,r)` \\ Cases_on `q` \\ fs []
  \\ Cases_on `cEval ([x],env,r')` \\ Cases_on `q` \\ fs [cEval_def]
  \\ IMP_RES_TAC cEval_IMP_LENGTH
  \\ Cases_on `a''` \\ fs [LENGTH]
  \\ REV_FULL_SIMP_TAC std_ss [LENGTH_NIL] \\ fs []);

val cEvalOp_const = store_thm("cEvalOp_const",
  ``(cEvalOp op args s1 = SOME (res,s2)) ==>
    (s2.clock = s1.clock) /\
    (s2.code = s1.code) /\
    (s2.restrict_envs = s1.restrict_envs)``,
  SIMP_TAC std_ss [cEvalOp_def]
  \\ BasicProvers.EVERY_CASE_TAC
  \\ fs [LET_DEF] \\ SRW_TAC [] [] \\ fs []);

val cEval_const_ind =
  cEval_ind
  |> Q.SPEC `\(xs,env,s).
       (case cEval (xs,env,s) of (_,s1) =>
          (s1.restrict_envs = s.restrict_envs) /\
          (s1.code = s.code))`
  |> Q.SPEC `\x1 x2 x3 x4.
       (case cEvalApp x1 x2 x3 x4 of (_,s1) =>
          (s1.restrict_envs = x4.restrict_envs) /\
          (s1.code = x4.code))`

val cEval_const_lemma = prove(
  cEval_const_ind |> concl |> rand,
  MATCH_MP_TAC cEval_const_ind
  \\ REPEAT STRIP_TAC \\ fs []
  \\ ONCE_REWRITE_TAC [cEval_def] \\ fs []
  \\ BasicProvers.EVERY_CASE_TAC \\ fs [] \\ rfs []
  \\ BasicProvers.EVERY_CASE_TAC \\ fs [] \\ rfs []
  \\ IMP_RES_TAC cEvalOp_const \\ fs [dec_clock_def])
  |> SIMP_RULE std_ss [FORALL_PROD]

val cEval_const = store_thm("cEval_const",
  ``(cEval (xs,env,s) = (res,s1)) ==>
      (s1.restrict_envs = s.restrict_envs) /\
      (s1.code = s.code)``,
  REPEAT STRIP_TAC
  \\ MP_TAC (cEval_const_lemma |> CONJUNCT1 |> Q.SPECL [`xs`,`env`,`s`])
  \\ fs []);

val cEvalApp_const = store_thm("cEvalApp_const",
  ``(cEvalApp x1 x2 x3 x4 = (res,s1)) ==>
      (s1.restrict_envs = x4.restrict_envs) /\
      (s1.code = x4.code)``,
  REPEAT STRIP_TAC
  \\ MP_TAC (cEval_const_lemma |> CONJUNCT2 |> Q.SPECL [`x1`,`x2`,`x3`,`x4`])
  \\ fs []);

val _ = export_theory();
