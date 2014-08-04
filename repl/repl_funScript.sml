open HolKernel Parse boolLib bossLib lcsymtacs
open lexer_implTheory cmlParseTheory astTheory inferTheory compilerTheory
     compilerTerminationTheory bytecodeEvalTheory replTheory
     initialProgramTheory;
open listTheory arithmeticTheory relationTheory;
open bytecodeLabelsTheory bytecodeTheory;

val _ = new_theory "repl_fun";

val _ = type_abbrev ("inferencer_state",
  ``:(modN list # conN id list # varN id list) #
     tenvT #
     (modN, (varN, num # infer_t) env) env #
     tenvC #
     (varN, num # infer_t) env``);

val infertype_top_def = Define `
infertype_top ((decls, type_name_env, module_type_env, constructor_type_env, type_env) :inferencer_state) ast_top =
  case FST (infer_top decls type_name_env module_type_env constructor_type_env type_env ast_top infer$init_infer_state) of
     | Failure _ => Failure "<type error>"
     | Success (new_decls, new_type_name_env, new_module_type_env, new_constructor_type_env, new_type_env) =>
        Success ((append_decls new_decls decls,
                  merge_tenvT new_type_name_env type_name_env,
                  new_module_type_env ++ module_type_env,
                  merge_tenvC new_constructor_type_env constructor_type_env,
                  new_type_env ++ type_env),
                 new_type_env)`;

val _ = Hol_datatype`repl_fun_state = <|
  rinferencer_state : inferencer_state;
  rcompiler_state  : compiler_state |>`;

val update_state_def = Define`
  update_state s is cs =
  s with <| rinferencer_state := is
          ; rcompiler_state   := cs
          |>`;

val update_state_err_def = Define`
  update_state_err s is cs =
  s with <| rinferencer_state :=
              (FST is, FST (SND s.rinferencer_state), FST (SND (SND s.rinferencer_state)), SND (SND (SND s.rinferencer_state)))
          ; rcompiler_state   := cs
          |>`;

val parse_infertype_compile_def = Define `
  parse_infertype_compile tokens s =
    case parse_top tokens of
      (* case: parse error *)
      NONE => Failure "<parse error>\n"
    | (* case: top produced *)
      SOME top =>
        case infertype_top s.rinferencer_state top of
          (* type inference failed to find type *)
        | Failure _ => Failure "<type error>\n"
          (* type found, type safe! *)
        | Success (is,types) =>
           let (css,csf,code) = compile_top (SOME types) s.rcompiler_state top in
             Success (code,update_state s is css,update_state_err s is csf)`;

(* simple_repl_fun is a definition of the repl that follows the structure of
   the repl semantics. It produces an assertion that we prove is always true.
   This is the version of the repl that is directly proved to implement the
   semantics (repl).  *)

val tac = (WF_REL_TAC `measure (LENGTH o SND)` \\ REPEAT STRIP_TAC
           \\ IMP_RES_TAC lex_until_toplevel_semicolon_LESS);

val simple_main_loop_def = tDefine "simple_main_loop" `
  simple_main_loop (bs,s) input =
   case lex_until_toplevel_semicolon input of
   | NONE => (Terminate,T)
   | SOME (tokens,rest_of_input) =>
     case parse_infertype_compile tokens s of
     | Success (code,s',s_exc) =>
       let code_assert = code_labels_ok bs.code in
       let s1 = install_code code bs in
       let code_assert = (code_assert /\ code_executes_ok s1) in
       (case bc_eval s1 of
        | NONE => (Diverge,code_assert)
        | SOME new_bs =>
          (case bc_fetch new_bs of
           | SOME (Stop success) =>
             let new_s = if success then s' else s_exc in
             let (res,assert) = simple_main_loop (new_bs,new_s) rest_of_input in
               (Result (new_bs.output) res, assert /\ code_assert)
           | _ => (ARB,F)))
     | Failure error_msg =>
         let (res,assert) = simple_main_loop (bs,s) rest_of_input in
           (Result error_msg res, assert)` tac

val initial_bc_state_side_def = Define `
  initial_bc_state_side initial =
    let bs1 = empty_bc_state in
    let bs2 = install_code initial bs1 in
     ?bs3. (bc_eval bs2 = SOME bs3) /\
           (bc_fetch bs3 = SOME (Stop T))`;

val simple_repl_fun_def = Define `
  simple_repl_fun initial input =
    let a1 = initial_bc_state_side (SND initial) in
    let (res,a2) = simple_main_loop (THE (bc_eval (install_code (SND initial) (empty_bc_state))),FST initial) input in
      (res,a1 /\ a2)`;

(* The remainder of the file makes definitions of a REPL function that get
   progressively closer to a specification suitable for implementation in
   machine-code. The first step is unrolling (some of) the first iteration of
   the loop, and packaging up iterations in a function called repl_step. *)

val labelled_repl_step_def = Define `
  labelled_repl_step state =
    case state of
    | INL (initial,code) => (* first time around *)
       INL (code,initial,initial)
    | INR (tokens,success,s,s_exc) => (* received some input *)
        let s = if success then s else s_exc in
        case parse_infertype_compile tokens s of
        | Success (code,s,s_exc) => INL (code,s,s_exc)
        | Failure error_msg => INR (error_msg,(F,s,s))`;

val tac = (WF_REL_TAC `measure (LENGTH o SND o SND)` \\ REPEAT STRIP_TAC
           \\ IMP_RES_TAC lex_until_toplevel_semicolon_LESS);

val unrolled_main_loop_def = tDefine "unrolled_main_loop" `
  unrolled_main_loop s bs input =
  case labelled_repl_step s of
    | INR (error_msg,x) =>
      Result error_msg
       (case lex_until_toplevel_semicolon input of
        | NONE => Terminate
        | SOME (ts,rest) =>
            (unrolled_main_loop (INR (ts,x)) bs rest))
    | INL (code,new_states) =>
      case bc_eval (install_code code bs) of
      | NONE => Diverge
      | SOME new_bs =>
          let success = (bc_fetch new_bs = SOME (Stop T)) in
            case lex_until_toplevel_semicolon input of
             | NONE => Terminate
             | SOME (ts,rest) =>
                 (unrolled_main_loop (INR (ts,success,new_states)) new_bs rest)`
  tac;

val unrolled_repl_fun_def = Define `
  unrolled_repl_fun initial input =
    unrolled_main_loop (INL initial) empty_bc_state input`

(* The next step does label removal and moves to more concrete types, in
   particular bytecode instructions are encoded as numbers and tokens are
   mapped from symbols. *)

val unlabelled_repl_step_def = Define `
  unlabelled_repl_step state =
    case state of
    | INL (initial,code) =>
       let code = REVERSE code in
       let labs = collect_labels code 0 real_inst_length in
       let len = code_length real_inst_length code in
       let code = inst_labels labs code in
       INL (MAP bc_num code,len,labs,initial,initial)
    | INR (symbols,success,len,labs,s,s_exc) =>
        let s = if success then s else s_exc in
        case parse_infertype_compile (MAP token_of_sym symbols) s of
        | Success (code,s,s_exc) =>
            let code = REVERSE code in
            let labs = FUNION labs (collect_labels code len real_inst_length) in
            let len = len + code_length real_inst_length code in
            let code = inst_labels labs code in
              INL (MAP bc_num code,len,labs,s,s_exc)
        | Failure error_msg => INR (error_msg,(F,len,labs,s,s))`;

val install_bc_lists_def = Define `
  install_bc_lists code bs =
    install_code (REVERSE (MAP num_bc code)) bs`;

val tac = (WF_REL_TAC `measure (LENGTH o SND o SND)` \\ REPEAT STRIP_TAC
           \\ IMP_RES_TAC lex_until_top_semicolon_alt_LESS);

val unlabelled_main_loop_def = tDefine "unlabelled_main_loop" `
  unlabelled_main_loop s bs input =
  case unlabelled_repl_step s of
    | INR (error_msg,x) =>
      Result error_msg
       (case lex_until_top_semicolon_alt input of
        | NONE => Terminate
        | SOME (ts,rest) =>
            (unlabelled_main_loop (INR (ts,x)) bs rest))
    | INL (code,new_states) =>
      case bc_eval (install_bc_lists code bs) of
      | NONE => Diverge
      | SOME new_bs =>
          let success = (bc_fetch new_bs = SOME (Stop T)) in
            case lex_until_top_semicolon_alt input of
             | NONE => Terminate
             | SOME (syms,rest) =>
                 (unlabelled_main_loop (INR (syms,success,new_states)) new_bs rest)`
  tac;

val unlabelled_repl_fun_def = Define`
  unlabelled_repl_fun initial input =
    unlabelled_main_loop (INL initial) empty_bc_state input`

(* The last step introduces the actual initial repl state (obtained by running
   the semantics on the initial program). *)

val basis_state_def = Define`
  basis_state =
  let e = FST (THE basis_env) in
  let rf =
       <| rinferencer_state := ((e.inf_mdecls, e.inf_tdecls, e.inf_edecls),
                                 e.inf_tenvT,
                                 e.inf_tenvM,
                                 e.inf_tenvC,
                                 e.inf_tenvE);
           rcompiler_state := e.comp_rs |> in
  (rf,Stop T :: SND (THE basis_env) ++ SND (THE prim_env) ++ REVERSE (empty_bc_state.code))`

val basis_repl_step_def = Define `
  (basis_repl_step NONE = unlabelled_repl_step (INL basis_state)) ∧
  (basis_repl_step (SOME x) = unlabelled_repl_step (INR x))`

val tac = (WF_REL_TAC `measure (LENGTH o SND o SND)` \\ REPEAT STRIP_TAC
           \\ IMP_RES_TAC lex_until_top_semicolon_alt_LESS);

val basis_main_loop_def = tDefine "basis_main_loop" `
  basis_main_loop s bs input =
  case basis_repl_step s of
    | INR (error_msg,x) =>
      Result error_msg
       (case lex_until_top_semicolon_alt input of
        | NONE => Terminate
        | SOME (ts,rest) =>
            (basis_main_loop (SOME (ts,x)) bs rest))
    | INL (code,new_states) =>
      case bc_eval (install_bc_lists code bs) of
      | NONE => Diverge
      | SOME new_bs =>
          let success = (bc_fetch new_bs = SOME (Stop T)) in
            case lex_until_top_semicolon_alt input of
             | NONE => Terminate
             | SOME (syms,rest) =>
                 (basis_main_loop (SOME (syms,success,new_states)) new_bs rest)`
  tac;

val basis_repl_fun_def = Define`
  basis_repl_fun input =
    basis_main_loop NONE (empty_bc_state with code := []) input`

val basis_repl_env_def = Define`
  basis_repl_env =
  let e = FST (THE basis_env) in
    <| tdecs := convert_decls (e.inf_mdecls, e.inf_tdecls, e.inf_edecls);
       tenvT := e.inf_tenvT;
       tenvM := convert_menv e.inf_tenvM;
       tenvC := e.inf_tenvC;
       tenv := bind_var_list2 (convert_env2 e.inf_tenvE) Empty;
       sem_env := THE basis_sem_env |>`

(* proof aim:
∀input output.
  repl basis_repl_env (get_type_error_mask output) input output
  ⇔
  basis_repl_fun input = (output,T)
*)

(*
x86 will provide:
  ∀input output. basis_repl_fun input = (output,T) ⇒
                 x86_implementation on (encode input) behaves as output
  or, equivalently,
  ∀input output.
    SND (basis_repl_fun input) (* this should be discharged *) ⇒
    x86_implementation on (encode input) behaves as (FST(basis_repl_fun input))
*)

val _ = export_theory()
