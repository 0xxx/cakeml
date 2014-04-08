(*Generated by Lem from decLang.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasivesTheory libTheory astTheory semanticPrimitivesTheory lem_list_extraTheory bigStepTheory conLangTheory;

val _ = numLib.prefer_num();



val _ = new_theory "decLang"

(* The third intermediate language (IL3). Removes declarations.
 *
 * The AST of IL3 differs from IL2 in that there is no declarations level, the
 * program is represented by a sequence of expressions.
 *
 * The values of IL3 are the same as IL2.
 *
 * The semantics of IL3 differ in that the global environment is now store-like
 * rather than environment-like. The expressions for extending and initialising
 * it modify the global environment (instread of just rasing a type error).
 *
 * The translator to IL3 maps a declaration to an expression that sets of the
 * global environment in the right way. If evaluating the expression results in
 * an exception, then the exception is handled, and a SOME containing the
 * exception is returned. Otherwise, a NONE is returned.
 *
 *)

(*open import Pervasives*)
(*open import Lib*)
(*open import Ast*)
(*open import SemanticPrimitives*)
(*open import List_extra*)
(*open import BigStep*)
(*open import ConLang*)

(*val init_globals : list varN -> nat -> exp_i2*)
 val _ = Define `
 (init_globals [] idx = (Lit_i2 Unit))
/\ (init_globals (x::vars) idx =  
(Let_i2 NONE (Uapp_i2 (Init_global_var_i2 idx) (Var_local_i2 x)) (init_globals vars (idx + 1))))`;


(*val init_global_funs : nat -> list (varN * varN * exp_i2) -> exp_i2*)
 val _ = Define `
 (init_global_funs next [] = (Lit_i2 Unit))
/\ (init_global_funs next ((f,x,e)::funs) =  
(Let_i2 NONE (Uapp_i2 (Init_global_var_i2 next) (Fun_i2 x e)) (init_global_funs (next+ 1) funs)))`;


(*val decs_to_i3 : nat -> list dec_i2 -> exp_i2*)
 val _ = Define `
 (decs_to_i3 next [] = (Lit_i2 Unit))
/\ (decs_to_i3 next (d::ds) =  
((case d of
      Dlet_i2 n e =>
        let vars = (GENLIST (\ n .   STRCAT"x" (num_to_dec_string n)) n) in
          Let_i2 NONE (Mat_i2 e [(Pcon_i2 (tuple_tag,NONE) (MAP Pvar_i2 vars), init_globals vars next)]) (decs_to_i3 (next+n) ds)
    | Dletrec_i2 funs =>
        let n = (LENGTH funs) in
          Let_i2 NONE (init_global_funs next funs) (decs_to_i3 (next+n) ds)
  )))`;


(*val prompt_to_i3 : (nat * maybe tid_or_exn) -> (nat * maybe tid_or_exn) -> nat -> prompt_i2 -> nat * exp_i2*)
val _ = Define `
 (prompt_to_i3 none_tag some_tag next prompt =  
((case prompt of
      Prompt_i2 ds =>
        let n = (num_defs ds) in
          ((next+n), Let_i2 NONE (Extend_global_i2 n) (Handle_i2 (Let_i2 NONE (decs_to_i3 next ds) (Con_i2 none_tag [])) [(Pvar_i2 "x", Con_i2 some_tag [Var_local_i2 "x"])]))
  )))`;


(*val prog_to_i3 : (nat * maybe tid_or_exn) -> (nat * maybe tid_or_exn) -> nat -> list prompt_i2 -> nat * exp_i2*)
 val prog_to_i3_defn = Hol_defn "prog_to_i3" `
 
(prog_to_i3 none_tag some_tag next [] = (next, Con_i2 none_tag [])) 
/\ 
(prog_to_i3 none_tag some_tag next (p::ps) =  
 (let (next',p') = (prompt_to_i3 none_tag some_tag next p) in
  let (next'',ps') = (prog_to_i3 none_tag some_tag next' ps) in
    (next'',Mat_i2 p' [(Pcon_i2 none_tag [], ps'); (Pvar_i2 "x", Var_local_i2 "x")])))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn prog_to_i3_defn;

(*val do_uapp_i3 : store v_i2 * list (maybe v_i2) -> uop_i2 -> v_i2 -> maybe ((store v_i2 * list (maybe v_i2)) * v_i2)*)
val _ = Define `
 (do_uapp_i3 (s,genv) uop v =  
((case uop of
      Opderef_i2 =>
        (case v of
            Loc_i2 n =>
              (case store_lookup n s of
                  SOME v => SOME ((s,genv),v)
                | NONE => NONE
              )
          | _ => NONE
        )
    | Opref_i2 =>
        let (s',n) = (store_alloc v s) in
          SOME ((s',genv), Loc_i2 n)
    | Init_global_var_i2 idx =>
        if idx < LENGTH genv then
          (case EL idx genv of
              NONE => SOME ((s, LUPDATE (SOME v) idx genv), Litv_i2 Unit)
            | SOME x => NONE
          )
        else
          NONE
  )))`;


val _ = type_abbrev((*  'a *) "count_store_genv" , ``: 'a count_store # ( 'a option) list``);

val _ = type_abbrev( "all_env_i3" , ``: exh_ctors_env # (varN, v_i2) env``);

val _ = Hol_reln ` (! ck env l s.
T
==>
evaluate_i3 ck env s (Lit_i2 l) (s, Rval (Litv_i2 l)))

/\ (! ck env e s1 s2 v.
(evaluate_i3 ck s1 env e (s2, Rval v))
==>
evaluate_i3 ck s1 env (Raise_i2 e) (s2, Rerr (Rraise v)))

/\ (! ck env e s1 s2 err.
(evaluate_i3 ck s1 env e (s2, Rerr err))
==>
evaluate_i3 ck s1 env (Raise_i2 e) (s2, Rerr err))

/\ (! ck s1 s2 env e v pes.
(evaluate_i3 ck s1 env e (s2, Rval v))
==>
evaluate_i3 ck s1 env (Handle_i2 e pes) (s2, Rval v))

/\ (! ck s1 s2 env e pes v bv.
(evaluate_i3 ck env s1 e (s2, Rerr (Rraise v)) /\
evaluate_match_i3 ck env s2 v pes v bv)
==>
evaluate_i3 ck env s1 (Handle_i2 e pes) bv)

/\ (! ck s1 s2 env e pes err.
(evaluate_i3 ck env s1 e (s2, Rerr err) /\
((err = Rtimeout_error) \/ (err = Rtype_error)))
==>
evaluate_i3 ck env s1 (Handle_i2 e pes) (s2, Rerr err))

/\ (! ck env tag es vs s s'.
(evaluate_list_i3 ck env s es (s', Rval vs))
==>
evaluate_i3 ck env s (Con_i2 tag es) (s', Rval (Conv_i2 tag vs)))

/\ (! ck env tag es err s s'.
(evaluate_list_i3 ck env s es (s', Rerr err))
==>
evaluate_i3 ck env s (Con_i2 tag es) (s', Rerr err))

/\ (! ck exh env n v s.
(lookup n env = SOME v)
==>
evaluate_i3 ck (exh,env) s (Var_local_i2 n) (s, Rval v))

/\ (! ck exh env n s.
(lookup n env = NONE)
==>
evaluate_i3 ck (exh,env) s (Var_local_i2 n) (s, Rerr Rtype_error))

/\ (! ck env n v s genv.
((LENGTH genv > n) /\
(EL n genv = SOME v))
==>
evaluate_i3 ck env (s,genv) (Var_global_i2 n) ((s,genv), Rval v))

/\ (! ck env n s genv.
((LENGTH genv > n) /\
(EL n genv = NONE))
==>
evaluate_i3 ck env (s,genv) (Var_global_i2 n) ((s,genv), Rerr Rtype_error))

/\ (! ck env n s genv.
(~ (LENGTH genv > n))
==>
evaluate_i3 ck env (s,genv) (Var_global_i2 n) ((s,genv), Rerr Rtype_error))

/\ (! ck exh env n e s.
T
==>
evaluate_i3 ck (exh,env) s (Fun_i2 n e) (s, Rval (Closure_i2 env n e)))

/\ (! ck env uop e v v' s1 s2 count s3 genv2 genv3.
(evaluate_i3 ck env s1 e (((count,s2),genv2), Rval v) /\
(do_uapp_i3 (s2,genv2) uop v = SOME ((s3,genv3),v')))
==>
evaluate_i3 ck env s1 (Uapp_i2 uop e) (((count,s3),genv3), Rval v'))

/\ (! ck env uop e v s1 s2 count genv2.
(evaluate_i3 ck env s1 e (((count,s2),genv2), Rval v) /\
(do_uapp_i3 (s2,genv2) uop v = NONE))
==>
evaluate_i3 ck env s1 (Uapp_i2 uop e) (((count,s2),genv2), Rerr Rtype_error))

/\ (! ck env uop e err s s'.
(evaluate_i3 ck env s e (s', Rerr err))
==>
evaluate_i3 ck env s (Uapp_i2 uop e) (s', Rerr err))

/\ (! ck exh env op e1 e2 v1 v2 env' e3 bv s1 s2 s3 count s4 genv3.
(evaluate_i3 ck (exh,env) s1 e1 (s2, Rval v1) /\
(evaluate_i3 ck (exh,env) s2 e2 (((count,s3),genv3), Rval v2) /\
((do_app_i2 env s3 op v1 v2 = SOME (env', s4, e3)) /\
(((ck /\ (op = Opapp)) ==> ~ (count =( 0))) /\
evaluate_i3 ck (exh,env') (((if ck then dec_count op count else count),s4),genv3) e3 bv))))
==>
evaluate_i3 ck (exh,env) s1 (App_i2 op e1 e2) bv)

/\ (! ck exh env op e1 e2 v1 v2 env' e3 s1 s2 s3 count s4 genv3.
(evaluate_i3 ck (exh,env) s1 e1 (s2, Rval v1) /\
(evaluate_i3 ck (exh,env) s2 e2 (((count,s3),genv3), Rval v2) /\
((do_app_i2 env s3 op v1 v2 = SOME (env', s4, e3)) /\
((count = 0) /\
((op = Opapp) /\
ck)))))
==>
evaluate_i3 ck (exh,env) s1 (App_i2 op e1 e2) ((( 0,s4),genv3),Rerr Rtimeout_error))

/\ (! ck exh env op e1 e2 v1 v2 s1 s2 s3 count genv3.
(evaluate_i3 ck (exh,env) s1 e1 (s2, Rval v1) /\
(evaluate_i3 ck (exh,env) s2 e2 (((count,s3),genv3),Rval v2) /\
(do_app_i2 env s3 op v1 v2 = NONE)))
==>
evaluate_i3 ck (exh,env) s1 (App_i2 op e1 e2) (((count,s3),genv3), Rerr Rtype_error))

/\ (! ck env op e1 e2 v1 err s1 s2 s3.
(evaluate_i3 ck env s1 e1 (s2, Rval v1) /\
evaluate_i3 ck env s2 e2 (s3, Rerr err))
==>
evaluate_i3 ck env s1 (App_i2 op e1 e2) (s3, Rerr err))

/\ (! ck env op e1 e2 err s s'.
(evaluate_i3 ck env s e1 (s', Rerr err))
==>
evaluate_i3 ck env s (App_i2 op e1 e2) (s', Rerr err))

/\ (! ck env e1 e2 e3 v e' bv s1 s2.
(evaluate_i3 ck env s1 e1 (s2, Rval v) /\
((do_if_i2 v e2 e3 = SOME e') /\
evaluate_i3 ck env s2 e' bv))
==>
evaluate_i3 ck env s1 (If_i2 e1 e2 e3) bv)

/\ (! ck env e1 e2 e3 v s1 s2.
(evaluate_i3 ck env s1 e1 (s2, Rval v) /\
(do_if_i2 v e2 e3 = NONE))
==>
evaluate_i3 ck env s1 (If_i2 e1 e2 e3) (s2, Rerr Rtype_error))

/\ (! ck env e1 e2 e3 err s s'.
(evaluate_i3 ck env s e1 (s', Rerr err))
==>
evaluate_i3 ck env s (If_i2 e1 e2 e3) (s', Rerr err))

/\ (! ck env e pes v bv s1 s2.
(evaluate_i3 ck env s1 e (s2, Rval v) /\
evaluate_match_i3 ck env s2 v pes (Conv_i2 (bind_tag, SOME (TypeExn (Short "Bind"))) []) bv)
==>
evaluate_i3 ck env s1 (Mat_i2 e pes) bv)

/\ (! ck env e pes err s s'.
(evaluate_i3 ck env s e (s', Rerr err))
==>
evaluate_i3 ck env s (Mat_i2 e pes) (s', Rerr err))

/\ (! ck exh env n e1 e2 v bv s1 s2.
(evaluate_i3 ck (exh,env) s1 e1 (s2, Rval v) /\
evaluate_i3 ck (exh,opt_bind n v env) s2 e2 bv)
==>
evaluate_i3 ck (exh,env) s1 (Let_i2 n e1 e2) bv)

/\ (! ck env n e1 e2 err s s'.
(evaluate_i3 ck env s e1 (s', Rerr err))
==>
evaluate_i3 ck env s (Let_i2 n e1 e2) (s', Rerr err))

/\ (! ck exh env funs e bv s.
(ALL_DISTINCT (MAP (\ (x,y,z) .  x) funs) /\
evaluate_i3 ck (exh,build_rec_env_i2 funs env env) s e bv)
==>
evaluate_i3 ck (exh,env) s (Letrec_i2 funs e) bv)

/\ (! ck env funs e s.
(~ (ALL_DISTINCT (MAP (\ (x,y,z) .  x) funs)))
==>
evaluate_i3 ck env s (Letrec_i2 funs e) (s, Rerr Rtype_error))

/\ (! ck env n s genv.
T
==>
evaluate_i3 ck env (s,genv) (Extend_global_i2 n) ((s,(genv++GENLIST (\ x .  NONE) n)), Rval (Litv_i2 Unit)))

/\ (! ck env s.
T
==>
evaluate_list_i3 ck env s [] (s, Rval []))

/\ (! ck env e es v vs s1 s2 s3.
(evaluate_i3 ck env s1 e (s2, Rval v) /\
evaluate_list_i3 ck env s2 es (s3, Rval vs))
==>
evaluate_list_i3 ck env s1 (e::es) (s3, Rval (v::vs)))

/\ (! ck env e es err s s'.
(evaluate_i3 ck env s e (s', Rerr err))
==>
evaluate_list_i3 ck env s (e::es) (s', Rerr err))

/\ (! ck env e es v err s1 s2 s3.
(evaluate_i3 ck env s1 e (s2, Rval v) /\
evaluate_list_i3 ck env s2 es (s3, Rerr err))
==>
evaluate_list_i3 ck env s1 (e::es) (s3, Rerr err))

/\ (! ck env v s err_v.
T
==>
evaluate_match_i3 ck env s v [] err_v (s, Rerr (Rraise err_v)))

/\ (! ck exh env env' v p pes e bv s count genv err_v.
(ALL_DISTINCT (pat_bindings_i2 p []) /\
((pmatch_i2 exh s p v env = Match env') /\
evaluate_i3 ck (exh,env') ((count,s),genv) e bv))
==>
evaluate_match_i3 ck (exh,env) ((count,s),genv) v ((p,e)::pes) err_v bv)

/\ (! ck exh genv env v p e pes bv s count err_v.
(ALL_DISTINCT (pat_bindings_i2 p []) /\
((pmatch_i2 exh s p v env = No_match) /\
evaluate_match_i3 ck (exh,env) ((count,s),genv) v pes err_v bv))
==>
evaluate_match_i3 ck (exh,env) ((count,s),genv) v ((p,e)::pes) err_v bv)

/\ (! ck exh genv env v p e pes s count err_v.
(pmatch_i2 exh s p v env = Match_type_error)
==>
evaluate_match_i3 ck (exh,env) ((count,s),genv) v ((p,e)::pes) err_v (((count,s),genv), Rerr Rtype_error))

/\ (! ck env v p e pes s err_v.
(~ (ALL_DISTINCT (pat_bindings_i2 p [])))
==>
evaluate_match_i3 ck env s v ((p,e)::pes) err_v (s, Rerr Rtype_error))`;
val _ = export_theory()

