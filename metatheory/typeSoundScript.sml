open preamble;
open pairTheory optionTheory alistTheory;
open miscTheory;
open libTheory astTheory typeSystemTheory semanticPrimitivesTheory;
open smallStepTheory bigStepTheory replTheory;
open terminationTheory;
open libPropsTheory;
open weakeningTheory typeSysPropsTheory bigSmallEquivTheory;
open typeSoundInvariantsTheory evalPropsTheory;

val _ = new_theory "typeSound";

val union_decls_empty = Q.store_thm ("union_decls_empty",
`!decls. union_decls empty_decls decls = decls`,
 rw [] >>
 PairCases_on `decls` >>
 rw [union_decls_def, empty_decls_def]);

val union_decls_assoc = Q.store_thm ("union_decls_assoc",
`!decls1 decls2 decls3.
  union_decls decls1 (union_decls decls2 decls3)
  =
  union_decls (union_decls decls1 decls2) decls3`,
 rw [] >>
 PairCases_on `decls1` >>
 PairCases_on `decls2` >>
 PairCases_on `decls3` >>
 rw [union_decls_def] >>
 metis_tac [UNION_ASSOC]);

val type_v_cases_eqn = SIMP_RULE (srw_ss()) [] (List.nth (CONJUNCTS type_v_cases, 0));
val type_vs_cases_eqn = SIMP_RULE (srw_ss()) [] (List.nth (CONJUNCTS type_v_cases, 1));
val type_env_cases = SIMP_RULE (srw_ss()) [] (List.nth (CONJUNCTS type_v_cases, 2));
val consistent_mod_cases = SIMP_RULE (srw_ss()) [] (List.nth (CONJUNCTS type_v_cases, 3));

val tid_exn_not = Q.prove (
`(!tn. tid_exn_to_tc tn ≠ TC_bool) ∧
 (!tn. tid_exn_to_tc tn ≠ TC_int) ∧
 (!tn. tid_exn_to_tc tn ≠ TC_string) ∧
 (!tn. tid_exn_to_tc tn ≠ TC_ref) ∧
 (!tn. tid_exn_to_tc tn ≠ TC_unit) ∧
 (!tn. tid_exn_to_tc tn ≠ TC_tup) ∧
 (!tn. tid_exn_to_tc tn ≠ TC_fn)`,
 rw [] >>
 cases_on `tn` >>
 fs [tid_exn_to_tc_def] >>
 metis_tac []);

(* Classifying values of basic types *)
val canonical_values_thm = Q.prove (
`∀tvs tenvC tenvS v t1 t2.
  (type_v tvs tenvC tenvS v (Tref t1) ⇒ (∃n. v = Loc n)) ∧
  (type_v tvs tenvC tenvS v Tint ⇒ (∃n. v = Litv (IntLit n))) ∧
  (type_v tvs tenvC tenvS v Tstring ⇒ (∃s. v = Litv (StrLit s))) ∧
  (type_v tvs tenvC tenvS v Tbool ⇒ (∃n. v = Litv (Bool n))) ∧
  (type_v tvs tenvC tenvS v Tunit ⇒ (∃n. v = Litv Unit)) ∧
  (type_v tvs tenvC tenvS v (Tfn t1 t2) ⇒
    (∃env n topt e. v = Closure env n e) ∨
    (∃env funs n. v = Recclosure env funs n))`,
rw [] >>
fs [Once type_v_cases, deBruijn_subst_def] >>
fs [] >>
rw [] >>
TRY (Cases_on `tn`) >>
fs [tid_exn_to_tc_def] >>
imp_res_tac type_funs_Tfn >>
fs []);

val tac =
fs [Once type_v_cases, Once type_p_cases, lit_same_type_def] >>
rw [] >>
fs [deBruijn_subst_def, tid_exn_not] >>
imp_res_tac type_funs_Tfn >>
fs [] >>
metis_tac [tid_exn_not];

(* Well-typed pattern matches either match or not, but they don't raise type
 * errors *)
val pmatch_type_progress = Q.prove (
`(∀cenv st p v env t tenv tenvS tvs tvs'' tenvC ctMap.
  consistent_con_env ctMap cenv tenvC ∧
  type_p tvs'' tenvC p t tenv ∧
  type_v tvs ctMap tenvS v t ∧
  type_s ctMap tenvS st
  ⇒
  (pmatch cenv st p v env = No_match) ∨
  (∃env'. pmatch cenv st p v env = Match env')) ∧
 (∀cenv st ps vs env ts tenv tenvS tvs tvs'' tenvC ctMap.
  consistent_con_env ctMap cenv tenvC ∧
  type_ps tvs'' tenvC ps ts tenv ∧
  type_vs tvs ctMap tenvS vs ts ∧
  type_s ctMap tenvS st
  ⇒
  (pmatch_list cenv st ps vs env = No_match) ∨
  (∃env'. pmatch_list cenv st ps vs env = Match env'))`,
 ho_match_mp_tac pmatch_ind >>
 rw [] >>
 rw [pmatch_def] >>
 fs [lit_same_type_def] 
 >- (fs [Once type_v_cases, Once type_p_cases, lit_same_type_def] >>
     rw [] >>
     fs [])
 >- (fs [Once type_v_cases_eqn, Once (hd (CONJUNCTS type_p_cases))] >>
     rw [] >>
     cases_on `lookup_con_id n cenv` >>
     rw [] 
     >- (fs [consistent_con_env_def] >>
         metis_tac [NOT_SOME_NONE]) >>
     PairCases_on `x` >>
     fs [] >>
     `∃tvs ts. lookup_con_id n tenvC = SOME (tvs,ts,x1) ∧
               FLOOKUP ctMap (id_to_n n, x1) = SOME (tvs,ts)` by metis_tac [consistent_con_env_def] >>
     fs [tid_exn_to_tc_11] >>
     rw [] >>
     fs [] >>
     imp_res_tac same_ctor_and_same_tid >>
     rw [] >>
     fs []
     >- metis_tac []
     >- metis_tac [same_tid_sym]
     >- (fs [consistent_con_env_def] >>
         metis_tac [type_ps_length, type_vs_length, LENGTH_MAP, SOME_11, PAIR_EQ]))
 >- (qpat_assum `type_v b c d e f` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
     qpat_assum `type_p b0 a b c d` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_p_cases]) >>
     every_case_tac >>
     rw [] >>
     metis_tac [])
 >- (fs [Once type_p_cases, Once type_v_cases] >>
     rw [] >>
     imp_res_tac type_ps_length >>
     imp_res_tac type_vs_length >>
     fs [] >>
     cases_on `ts` >>
     fs [])
 >- (qpat_assum `type_v b c d e f` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
     qpat_assum `type_p b0 a b c d` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_p_cases]) >>
     every_case_tac >>
     rw [] >>
     fs [type_s_def] >>
     res_tac >>
     fs [] >>
     rw [] >>
     metis_tac [])
 >- tac
 >- tac
 >- tac
 >- tac
 >- tac
 >- tac
 >- tac
 >- tac
 >- tac
 >- tac
 >- tac
 >- tac
 >- tac
 >- tac
 >- (qpat_assum `type_ps tvs tenvC (p::ps) ts tenv`
         (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_p_cases]) >>
     qpat_assum `type_vs tvs ctMap tenvS (v::vs) ts`
         (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
     fs [] >>
     rw [] >>
     res_tac >>
     fs [] >>
     metis_tac [])
 >- (imp_res_tac type_ps_length >>
     imp_res_tac type_vs_length >>
     fs [] >>
     cases_on `ts` >>
     fs [])
 >- (imp_res_tac type_ps_length >> imp_res_tac type_vs_length >>
     fs [] >>
     cases_on `ts` >>
     fs []));

val final_state_def = Define `
  (final_state (env,st,Val v,[]) = T) ∧
  (final_state (env,st,Val v,[(Craise (), err)]) = T) ∧
  (final_state _ = F)`;

val not_final_state = Q.prove (
`!menv cenv st env e c.
  ¬final_state (env,st,Exp e,c) =
    ((?x y. c = x::y) ∨
     (?e1. e = Raise e1) ∨
     (?e1 pes. e = Handle e1 pes) ∨
     (?l. e = Lit l) ∨
     (?cn es. e = Con cn es) ∨
     (?v. e = Var v) ∨
     (?x e'. e = Fun x e') \/
     (?op e1 e2. e = App op e1 e2) ∨
     (?uop e1. e = Uapp uop e1) ∨
     (?op e1 e2. e = Log op e1 e2) ∨
     (?e1 e2 e3. e = If e1 e2 e3) ∨
     (?e' pes. e = Mat e' pes) ∨
     (?n e1 e2. e = Let n e1 e2) ∨
     (?funs e'. e = Letrec funs e'))`,
rw [] >>
cases_on `e` >>
cases_on `c` >>
rw [final_state_def]);

val eq_same_type = Q.prove (
`(!v1 v2 tvs ctMap cns tenvS t.
  type_v tvs ctMap tenvS v1 t ∧
  type_v tvs ctMap tenvS v2 t 
  ⇒
  do_eq v1 v2 ≠ Eq_type_error) ∧
(!vs1 vs2 tvs ctMap cns tenvS ts.
  type_vs tvs ctMap tenvS vs1 ts ∧
  type_vs tvs ctMap tenvS vs2 ts 
  ⇒
  do_eq_list vs1 vs2 ≠ Eq_type_error)`,
 ho_match_mp_tac do_eq_ind >>
 rw [do_eq_def] >>
 rw [type_v_cases_eqn] >>
 rw [] >>
 CCONTR_TAC >>
 fs [] >>
 rw [] >>
 imp_res_tac type_funs_Tfn >>
 fs [] 
 >- (fs [type_v_cases_eqn] >>
     rw [] >>
     fs [] >>
     metis_tac []) >>
 fs [Once type_vs_cases_eqn] >>
 rw [] >>
 cases_on `do_eq v1 v2` >>
 fs [tid_exn_not]
 >- (cases_on `b` >>
     fs [] >>
     qpat_assum `!x. P x` (mp_tac o Q.SPECL [`tvs`, `ctMap`, `tenvS`, `ts'`]) >>
     rw [METIS_PROVE [] ``(a ∨ b) = (~a ⇒ b)``] >>
     cases_on `vs1` >>
     fs [] >-
     fs [Once type_vs_cases_eqn] >>
     cases_on `ts'` >>
     fs [] >>
     fs [Once type_vs_cases_eqn])
 >- metis_tac []);

val consistent_con_env_thm = Q.prove (
`∀ctMap cenv tenvC.
     consistent_con_env ctMap cenv tenvC ⇒
     ∀cn tvs ts tn.
       (lookup_con_id cn tenvC = SOME (tvs,ts,tn) ⇒
        lookup_con_id cn cenv = SOME (LENGTH ts,tn) ∧
        FLOOKUP ctMap (id_to_n cn,tn) = SOME (tvs, ts)) ∧
       (lookup_con_id cn tenvC = NONE ⇒ lookup_con_id cn cenv = NONE)`,
 rw [consistent_con_env_def] >>
 cases_on `lookup_con_id cn cenv` >>
 rw []
 >- metis_tac [NOT_SOME_NONE]
 >- (PairCases_on `x` >>
     fs [] >>
     metis_tac [PAIR_EQ, SOME_11])
 >> metis_tac [pair_CASES, SOME_11, PAIR_EQ, NOT_SOME_NONE]);

(* A well-typed expression state is either a value with no continuation, or it
 * can step to another state, or it steps to a BindError. *)
val exp_type_progress = Q.prove (
`∀dec_tvs tenvC st e t menv cenv env c tenvS.
  type_state dec_tvs tenvC tenvS ((menv,cenv,env), st, e, c) t ∧
  ¬(final_state ((menv,cenv,env), st, e, c))
  ⇒
  (∃menv' cenv' env' st' e' c'. e_step ((menv,cenv,env), st, e, c) = Estep ((menv',cenv',env'), st', e', c'))`,
 rw [] >>
 rw [e_step_def] >>
 fs [type_state_cases, push_def, return_def] >>
 rw []
 >- (fs [Once type_e_cases] >>
     rw [] >>
     fs [not_final_state, all_env_to_cenv_def, all_env_to_menv_def] >|
     [rw [] >>
          every_case_tac >>
          fs [return_def] >>
          imp_res_tac type_es_length >>
          fs [] >>
          metis_tac [do_con_check_build_conv, NOT_SOME_NONE],
      fs [do_con_check_def] >>
          rw [] >>
          fs [] >>
          imp_res_tac consistent_con_env_thm >>
          fs [] >>
          imp_res_tac type_es_length >>
          fs [],
      fs [do_con_check_def] >>
          rw [] >>
          fs [] >>
          imp_res_tac consistent_con_env_thm >>
          rw [] >>
          every_case_tac >>
          fs [return_def] >>
          imp_res_tac type_es_length >>
          fs [build_conv_def],
      fs [do_con_check_def] >>
          rw [] >>
          fs [] >>
          imp_res_tac consistent_con_env_thm >>
          rw [] >>
          fs [] >>
          metis_tac [type_es_length, LENGTH_MAP],
      imp_res_tac type_lookup_id >>
          fs [] >>
          every_case_tac >>
          metis_tac [NOT_SOME_NONE],
      metis_tac [type_funs_distinct]])
 >- (rw [continue_def] >>
     fs [Once type_ctxts_cases, type_ctxt_cases, return_def, push_def] >>
     rw [] >>
     fs [final_state_def] >>
     fs [] >>
     fs [type_op_cases] >>
     rw [] >>
     imp_res_tac (SIMP_RULE (srw_ss()) [] canonical_values_thm) >>
     fs [] >>
     rw [] >>
     fs [do_app_def, do_if_def, do_log_def] >|
     [every_case_tac >>
          rw [] >>
          fs [is_ccon_def] >>
          fs [Once context_invariant_cases, final_state_def],
      rw [do_uapp_def] >>
          every_case_tac >>
          rw [store_alloc_def] >>
          fs [Once type_v_cases] >>
          rw [] >>
          fs [type_uop_cases] >>
          fs [type_s_def] >>
          rw [] >>
          imp_res_tac type_funs_Tfn >>
          fs [tid_exn_not] >>
          metis_tac [optionTheory.NOT_SOME_NONE],
      every_case_tac >>
          fs [exn_env_def],
      every_case_tac >>
          fs [] >>
          qpat_assum `type_v a tenvC senv (Recclosure x2 x3 x4) tpat`
                (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
          fs [] >>
          imp_res_tac type_funs_find_recfun >>
          fs [],
      every_case_tac >>
          fs [] >>
          qpat_assum `type_v a tenvC senv (Recclosure x2 x3 x4) tpat`
                (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
          fs [] >>
          imp_res_tac type_funs_find_recfun >>
          fs [],
      cases_on `do_eq v' v` >>
          fs [Once context_invariant_cases] >>
          srw_tac [ARITH_ss] [exn_env_def] >> 
          metis_tac [eq_same_type],
      qpat_assum `type_v a tenvC senv (Loc n) z` 
              (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
          fs [type_s_def] >>
          res_tac >>
          fs [store_assign_def, store_lookup_def],
      every_case_tac >>
          fs [],
      every_case_tac >>
          fs [],
      every_case_tac >>
          fs [RES_FORALL] >>
          rw [] >>
          qpat_assum `∀x. (x = (q,r)) ∨ P x ⇒ Q x`
                   (MP_TAC o Q.SPEC `(q,r)`) >>
          rw [] >>
          CCONTR_TAC >>
          fs [] >>
          metis_tac [pmatch_type_progress, match_result_distinct],
      imp_res_tac consistent_con_env_thm >>
          fs [do_con_check_def, all_env_to_cenv_def] >>
          fs [] >>
          imp_res_tac type_es_length >>
          imp_res_tac type_vs_length >>
          full_simp_tac (srw_ss()++ARITH_ss) [do_con_check_def,lookup_def, build_conv_def] >>
          `LENGTH ts2 = 0` by decide_tac >>
          cases_on `es` >>
          fs [],
      fs [all_env_to_cenv_def] >>
          every_case_tac >>
          fs [] >>
          imp_res_tac consistent_con_env_thm >>
          imp_res_tac type_es_length >>
          imp_res_tac type_vs_length >>
          full_simp_tac (srw_ss()++ARITH_ss) [do_con_check_def,lookup_def],
      every_case_tac >>
          fs [] >>
          imp_res_tac consistent_con_env_thm >>
          imp_res_tac type_es_length >>
          imp_res_tac type_vs_length >>
          full_simp_tac (srw_ss()++ARITH_ss) [do_con_check_def,lookup_def, build_conv_def],
      every_case_tac >>
          fs [] >>
          imp_res_tac consistent_con_env_thm >>
          imp_res_tac type_es_length >>
          imp_res_tac type_vs_length >>
          full_simp_tac (srw_ss()++ARITH_ss) [do_con_check_def,lookup_def, build_conv_def]]));

(* A successful pattern match gives a binding environment with the type given by
* the pattern type checker *)
val pmatch_type_preservation = Q.prove (
`(∀(cenv : envC) st p v env env' (tenvC:tenvC) ctMap tenv t tenv' tenvS tvs.
  (pmatch cenv st p v env = Match env') ∧
  consistent_con_env ctMap cenv tenvC ∧
  type_v tvs ctMap tenvS v t ∧
  type_p tvs tenvC p t tenv' ∧
  type_s ctMap tenvS st ∧
  type_env ctMap tenvS env tenv ⇒
  type_env ctMap tenvS env' (bind_var_list tvs tenv' tenv)) ∧
 (∀(cenv : envC) st ps vs env env' (tenvC:tenvC) ctMap tenv tenv' ts tenvS tvs.
  (pmatch_list cenv st ps vs env = Match env') ∧
  consistent_con_env ctMap cenv tenvC ∧
  type_vs tvs ctMap tenvS vs ts ∧
  type_ps tvs tenvC ps ts tenv' ∧
  type_s ctMap tenvS st ∧
  type_env ctMap tenvS env tenv ⇒
  type_env ctMap tenvS env' (bind_var_list tvs tenv' tenv))`,
 ho_match_mp_tac pmatch_ind >>
 rw [pmatch_def]
 >- (fs [Once type_p_cases, bind_var_list_def, bind_def] >>
     rw [] >>
     rw [Once type_v_cases] >>
     rw [emp_def, bind_def, bind_tenv_def])
 >- fs [Once type_p_cases, bind_var_list_def]
 >- (cases_on `lookup_con_id n cenv` >>
     fs [] >>
     PairCases_on `x` >>
     fs [] >>
     every_case_tac >>
     fs [] >>
     fs [] >>
     FIRST_X_ASSUM match_mp_tac >>
     rw [] >>
     fs [Once type_v_cases_eqn, Once (hd (CONJUNCTS type_p_cases))] >>
     rw [] >>
     fs [] >>
     rw [] >>
     fs [tid_exn_to_tc_11, consistent_con_env_def] >>
     res_tac >>
     fs [] >>
     rw [] >>
     imp_res_tac same_ctor_and_same_tid >>
     rw [] >>
     fs [] >>
     metis_tac [])
 >- (cases_on `(LENGTH ps = x0) ∧ (LENGTH vs = x0)` >>
     fs [] >>
     fs [] >>
     qpat_assum `type_v tvs ctMap senv vpat t`
             (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
     fs [Once type_p_cases] >>
     rw [] >>
     fs [] >>
     rw [] >>
     cases_on `ps` >>
     fs [] >>
     qpat_assum `type_ps a0 a c d e`
             (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_p_cases]) >>
     fs [] >>
     metis_tac [])
 >- (fs [store_lookup_def] >>
     every_case_tac >>
     fs [] >>
     qpat_assum `type_p x1 x2 x3 x4 x5` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_p_cases]) >>
     qpat_assum `type_v x1 x2 x3 x4 x5` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
     fs [] >>
     rw [] >>
     fs [type_s_def, store_lookup_def] >>
     `type_v tvs ctMap tenvS (EL lnum st) t'` by
                 metis_tac [consistent_con_env_def, type_v_weakening, weakCT_refl, weakS_refl, weakM_refl] >>
     metis_tac [])
 >- fs [Once type_p_cases, bind_var_list_def]
 >- (every_case_tac >>
     fs [] >>
     qpat_assum `type_vs tva ctMap senv (v::vs) ts`
             (ASSUME_TAC o SIMP_RULE (srw_ss ()) [Once type_v_cases]) >>
     fs [] >>
     qpat_assum `type_ps a0 a1 c d e`
             (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_p_cases]) >>
     fs [] >>
     rw [bind_var_list_append] >>
     metis_tac []));

val type_env2_def = Define `
(type_env2 tenvC tenvS tvs [] [] = T) ∧
(type_env2 tenvC tenvS tvs ((x,v)::env) ((x',t) ::tenv) = 
  (check_freevars tvs [] t ∧ 
   (x = x') ∧ 
   type_v tvs tenvC tenvS v t ∧ 
   type_env2 tenvC tenvS tvs env tenv)) ∧
(type_env2 tenvC tenvS tvs _ _ = F)`;

val type_env2_to_type_env = Q.prove (
`!tenvC tenvS tvs env tenv.
  type_env2 tenvC tenvS tvs env tenv ⇒
  type_env tenvC tenvS env (bind_var_list tvs tenv Empty)`,
ho_match_mp_tac (fetch "-" "type_env2_ind") >>
rw [type_env2_def] >>
rw [Once type_v_cases, bind_var_list_def, emp_def, bind_def, bind_tenv_def]);

val type_env_merge_lem1 = Q.prove (
`∀tenvC env env' tenv tenv' tvs tenvS.
  type_env2 tenvC tenvS tvs env' tenv' ∧ type_env tenvC tenvS env tenv
  ⇒
  type_env tenvC tenvS (merge env' env) (bind_var_list tvs tenv' tenv) ∧ (LENGTH env' = LENGTH tenv')`,
Induct_on `tenv'` >>
rw [merge_def] >>
cases_on `env'` >>
rw [bind_var_list_def] >>
fs [type_env2_def] >|
[PairCases_on `h` >>
     rw [bind_var_list_def] >>
     PairCases_on `h'` >>
     fs [] >>
     fs [type_env2_def] >>
     rw [] >>
     rw [Once type_v_cases, bind_def, emp_def, bind_tenv_def] >>
     metis_tac [merge_def],
 PairCases_on `h` >>
     rw [bind_var_list_def] >>
     PairCases_on `h'` >>
     fs [] >>
     fs [type_env2_def] >>
     rw [] >>
     rw [Once type_v_cases, bind_def, emp_def, bind_tenv_def] >>
     metis_tac [merge_def]]);

val type_env_merge_lem2 = Q.prove (
`∀tenvC env env' tenv tenv' tvs tenvS.
  type_env tenvC tenvS (merge env' env) (bind_var_list tvs tenv' tenv) ∧
  (LENGTH env' = LENGTH tenv')
  ⇒
  type_env2 tenvC tenvS tvs env' tenv' ∧ type_env tenvC tenvS env tenv`,
Induct_on `env'` >>
rw [merge_def] >>
cases_on `tenv'` >>
fs [bind_var_list_def] >>
rw [type_env2_def] >>
qpat_assum `type_env x0 x1 x2 x3` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
PairCases_on `h` >>
PairCases_on `h'` >>
rw [type_env2_def] >>
fs [emp_def, bind_def, bind_var_list_def, bind_tenv_def, merge_def] >>
rw [type_env2_def] >>
metis_tac [type_v_freevars]);

val type_env_merge = Q.prove (
`∀tenvC env env' tenv tenv' tvs tenvS.
  ((type_env tenvC tenvS (merge env' env) (bind_var_list tvs tenv' tenv) ∧
    (LENGTH env' = LENGTH tenv'))
   =
   (type_env2 tenvC tenvS tvs env' tenv' ∧ type_env tenvC tenvS env tenv))`,
metis_tac [type_env_merge_lem1, type_env_merge_lem2]);

val type_funs_fst = Q.prove (
`!tenvM tenvC tenv funs tenv'.
  type_funs tenvM tenvC tenv funs tenv'
  ⇒
  MAP (λ(f,x,e). f) funs = MAP FST tenv'`,
 induct_on `funs` >>
 rw [] >>
 pop_assum (mp_tac o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
 rw [] >>
 rw [] >>
 metis_tac []);

val type_recfun_env_help = Q.prove (
`∀fn funs funs' tenvM tenvC ctMap tenv tenv' tenv0 env tenvS tvs.
  ALL_DISTINCT (MAP (\(x,y,z). x) funs') ∧
  tenvM_ok tenvM ∧
  consistent_con_env ctMap cenv tenvC ∧
  consistent_mod_env tenvS ctMap menv tenvM ∧
  (!fn t. (lookup fn tenv = SOME t) ⇒ (lookup fn tenv' = SOME t)) ∧
  type_env ctMap tenvS env tenv0 ∧
  type_funs tenvM tenvC (bind_var_list 0 tenv' (bind_tvar tvs tenv0)) funs' tenv' ∧
  type_funs tenvM tenvC (bind_var_list 0 tenv' (bind_tvar tvs tenv0)) funs tenv
  ⇒
  type_env2 ctMap tenvS tvs (MAP (λ(fn,n,e). (fn,Recclosure (menv,cenv,env) funs' fn)) funs) tenv`,
induct_on `funs` >>
rw [] >>
pop_assum (ASSUME_TAC o SIMP_RULE (srw_ss ()) [Once type_e_cases]) >>
fs [emp_def] >>
rw [bind_def, Once type_v_cases, type_env2_def] >>
`type_env2 ctMap tenvS tvs (MAP (λ(fn,n,e). (fn,Recclosure (menv,cenv,env) funs' fn)) funs) env'`
              by metis_tac [optionTheory.NOT_SOME_NONE, lookup_def, bind_def] >>
rw [type_env2_def] >>
fs [] >>
`lookup fn tenv' = SOME (Tapp [t1;t2] TC_fn)` by metis_tac [lookup_def, bind_def] >|
[fs [num_tvs_bind_var_list, check_freevars_def] >>
     metis_tac [num_tvs_def, bind_tvar_def, arithmeticTheory.ADD, 
                arithmeticTheory.ADD_COMM, type_v_freevars],
 qexists_tac `tenvM` >>
     qexists_tac `tenvC` >>
     qexists_tac `tenv0` >>
     rw [] >>
     qexists_tac `tenv'` >>
     rw [] >>
     imp_res_tac lookup_in2 >>
     imp_res_tac type_funs_fst >>
     fs []]);

val type_recfun_env = Q.prove (
`∀fn funs tenvM tenvC ctMap tenvS tvs tenv tenv0 menv cenv env.
  tenvM_ok tenvM ∧
  consistent_con_env ctMap cenv tenvC ∧
  consistent_mod_env tenvS ctMap menv tenvM ∧
  type_env ctMap tenvS env tenv0 ∧
  type_funs tenvM tenvC (bind_var_list 0 tenv (bind_tvar tvs tenv0)) funs tenv ∧
  ALL_DISTINCT (MAP (\(x,y,z). x) funs)
  ⇒
  type_env2 ctMap tenvS tvs (MAP (λ(fn,n,e). (fn,Recclosure (menv,cenv,env) funs fn)) funs) tenv`,
metis_tac [type_recfun_env_help]);

val type_raise_eqn = Q.prove (
`!tenvM tenvC tenv r t. 
  type_e tenvM tenvC tenv (Raise r) t = (type_e tenvM tenvC tenv r Texn ∧ check_freevars (num_tvs tenv) [] t)`,
rw [Once type_e_cases] >>
metis_tac []);

val type_env_eqn = Q.prove (
`!ctMap tenvS. 
  (type_env ctMap tenvS emp Empty = T) ∧
  (!n tvs t v env tenv. 
      type_env ctMap tenvS (bind n v env) (bind_tenv n tvs t tenv) = 
      (type_v tvs ctMap tenvS v t ∧ check_freevars tvs [] t ∧ type_env ctMap tenvS env tenv))`,
rw [] >>
rw [Once type_v_cases] >>
fs [bind_def, emp_def, bind_tenv_def] >>
metis_tac [type_v_freevars]);

val ctxt_inv_not_poly = Q.prove (
`!dec_tvs c tvs.
  context_invariant dec_tvs c tvs ⇒ ¬poly_context c ⇒ (tvs = 0)`,
ho_match_mp_tac context_invariant_ind >>
rw [poly_context_def] >>
cases_on `c` >>
fs [] >-
metis_tac [NOT_EVERY] >>
PairCases_on `h` >>
fs [] >>
cases_on `h0` >>
fs [] >>
metis_tac [NOT_EVERY]);

val type_v_exn = SIMP_RULE (srw_ss()) [] (Q.prove (
`!tvs cenv senv.
  ctMap_has_exns cenv ⇒
  type_v tvs cenv senv (Conv (SOME ("Bind",TypeExn (Short "Bind"))) []) Texn ∧
  type_v tvs cenv senv (Conv (SOME ("Div",TypeExn (Short "Div"))) []) Texn ∧
  type_v tvs cenv senv (Conv (SOME ("Eq",TypeExn (Short "Eq"))) []) Texn`,
 ONCE_REWRITE_TAC [type_v_cases] >>
 rw [ctMap_has_exns_def, tid_exn_to_tc_def] >>
 metis_tac [type_v_rules]));

val exn_tenvC_def = Define `
exn_tenvC = (emp,MAP (λcn. (cn,[],[],TypeExn (Short cn))) ["Bind"; "Div"; "Eq"])`;

val type_e_exn = SIMP_RULE (srw_ss()) [] (Q.prove (
`!tenvM tenv.
  ctMap_ok ctMap ∧
  ctMap_has_exns ctMap ∧
  ((menv,cenv,env) = exn_env)
  ⇒
  type_e tenvM exn_tenvC tenv (Con (SOME (Short "Bind")) []) Texn ∧
  type_e tenvM exn_tenvC tenv (Con (SOME (Short "Div")) []) Texn ∧
  type_e tenvM exn_tenvC tenv (Con (SOME (Short "Eq")) []) Texn ∧
  consistent_con_env ctMap cenv exn_tenvC`,
 NTAC 2 (ONCE_REWRITE_TAC [type_e_cases]) >>
 rw [consistent_con_env_def, tid_exn_to_tc_def] >>
 fs [exn_env_def, exn_tenvC_def] >>
 res_tac >>
 fs [] >>
 rw [flat_tenvC_ok_def, tenvC_ok_def] >>
 fs [id_to_n_def, ctMap_has_exns_def, lookup_con_id_def, emp_def] >>
 every_case_tac >>
 fs []));

(* If a step can be taken from a well-typed state, the resulting state has the
* same type *)
val exp_type_preservation = Q.prove (
`∀dec_tvs ctMap menv cenv st env e c t menv' cenv' st' env' e' c' tenvS.
  ctMap_ok ctMap ∧
  ctMap_has_exns ctMap ∧
  type_state dec_tvs ctMap tenvS ((menv,cenv,env), st, e, c) t ∧
  (e_step ((menv,cenv,env), st, e, c) = Estep ((menv',cenv',env'), st', e', c'))
  ⇒
  ∃tenvS'. type_state dec_tvs ctMap tenvS' ((menv',cenv',env'), st', e', c') t ∧
          ((tenvS' = tenvS) ∨
           (?l t. (lookup l tenvS = NONE) ∧ (tenvS' = bind l t tenvS)))`,
 rw [type_state_cases] >>
 fs [e_step_def] >>
 `check_freevars tvs [] t ∧ check_freevars tvs [] t1` by metis_tac [type_ctxts_freevars]
 >- (cases_on `e''` >>
     fs [push_def, is_value_def] >>
     rw []
     >- (qpat_assum `type_e a0 a1 b1 c1 d1` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
         rw [Once type_ctxts_cases] >>
         rw [type_ctxt_cases] >>
         fs [bind_tvar_def] >>
         ONCE_REWRITE_TAC [context_invariant_cases] >>
         rw [] >>
         metis_tac [check_freevars_def, EVERY_DEF])
     >- (qpat_assum `type_e a0 a1 b1 c1 d1` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
         rw [Once type_ctxts_cases] >>
         rw [type_ctxt_cases] >>
         fs [bind_tvar_def] >>
         ONCE_REWRITE_TAC [context_invariant_cases] >>
         rw [] >>
         metis_tac [])
     >- (fs [return_def] >>
         rw [] >>
         qpat_assum `type_e tenvM tenvC tenv (Lit l) t1`
                   (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
         fs [] >>
         rw [] >>
         rw [Once type_v_cases_eqn] >>
         metis_tac [])
     >- (every_case_tac >>
         fs [return_def] >>
         rw [] >>
         qpat_assum `type_e tenvM tenvC tenv (Con s'' epat) t1`
                  (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
         rw [] >>
         qpat_assum `type_es tenvM tenvC tenv epat ts`
                  (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
         fs []
         >- metis_tac [do_con_check_build_conv, NOT_SOME_NONE]
         >- metis_tac [do_con_check_build_conv, NOT_SOME_NONE]
         >- (fs [build_conv_def, all_env_to_cenv_def] >>
             every_case_tac >>
             fs [] >>
             qexists_tac `tenvS` >>
             rw [] >>
             qexists_tac `Tapp ts' (tid_exn_to_tc tn)` >>
             rw [] >>
             rw [Once type_v_cases] >>
             rw [Once type_v_cases] >>
             imp_res_tac consistent_con_env_thm >>
             fs [check_freevars_def] >>
             metis_tac [check_freevars_def, consistent_con_env_def])
         >- (fs [build_conv_def, all_env_to_cenv_def] >>
             every_case_tac >>
             fs [] >>
             qexists_tac `tenvS` >>
             rw [] >>
             qexists_tac `Tapp [] TC_tup` >>
             rw [] >>
             rw [Once type_v_cases] >>
             rw [Once type_v_cases] >>
             metis_tac [check_freevars_def])
         >- (fs [build_conv_def, all_env_to_cenv_def] >>
             every_case_tac >>
             fs [] >>
             qexists_tac `tenvS` >>
             rw [] >>
             rw [Once type_ctxts_cases, type_ctxt_cases] >>
             qexists_tac `tenvM` >>
             qexists_tac `tenvC` >>
             qexists_tac `t''`>>
             ONCE_REWRITE_TAC [context_invariant_cases] >>
             rw [] >>
             qexists_tac `tenv` >>
             qexists_tac `tvs` >>
             rw [] >-
             metis_tac [] >>
             fs [is_ccon_def] >>
             imp_res_tac ctxt_inv_not_poly >>
             qexists_tac `tenvM` >>
             qexists_tac `tenvC` >>
             qexists_tac `tenv` >>
             qexists_tac `Tapp ts' (tid_exn_to_tc tn)`>>
             rw [] >>
             cases_on `ts` >>
             fs [] >>
             rw [] >>
             rw [] >>
             qexists_tac `[]` >>
             qexists_tac `t'''` >>
             rw [] >>
             metis_tac [type_v_rules, APPEND, check_freevars_def])
         >- (fs [build_conv_def, all_env_to_cenv_def] >>
             every_case_tac >>
             fs [] >>
             qexists_tac `tenvS` >>
             rw [] >>
             rw [Once type_ctxts_cases, type_ctxt_cases] >>
             qexists_tac `tenvM` >>
             qexists_tac `tenvC` >>
             qexists_tac `t''`>>
             qexists_tac `tenv`>>
             ONCE_REWRITE_TAC [context_invariant_cases] >>
             rw [] >>
             qexists_tac `tvs` >>
             rw [] >-
             metis_tac [] >>
             fs [is_ccon_def] >>
             imp_res_tac ctxt_inv_not_poly >>
             qexists_tac `tenvM` >>
             qexists_tac `tenvC` >>
             qexists_tac `tenv`>>
             qexists_tac `Tapp (t''::ts') TC_tup`>>
             rw [] >>
             qexists_tac `[]` >>
             qexists_tac `ts'` >>
             rw [] >>
             metis_tac [type_v_rules, EVERY_DEF, check_freevars_def]))
     >- (qexists_tac `tenvS` >>
         rw [] >>
         every_case_tac >>
         fs [return_def] >>
         rw [] >>
         qexists_tac `t1` >>
         rw [] >>
         qpat_assum `type_e tenvM tenvC tenv (Var i) t1`
                  (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
         fs [] >>
         rw [] >>
         qexists_tac `tvs` >>
         rw [] >>
         imp_res_tac type_v_freevars >>
         `num_tvs (bind_tvar tvs tenv) = tvs` 
                  by (fs [bind_tvar_def] >>
                      cases_on `tvs` >>
                      fs [num_tvs_def]) >>
         metis_tac [type_lookup_type_v])
     >- (fs [return_def] >>
         rw [] >>
         qpat_assum `type_e tenvM tenvC tenv (Fun s'' e'') t1`
                  (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
         rw [] >>
         rw [bind_tvar_def, Once type_v_cases_eqn] >>
         fs [bind_tvar_def, check_freevars_def] >>
         metis_tac [check_freevars_def])
     >- (qpat_assum `type_e x0 x1 x2 x3 x4` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
         fs [type_uop_cases] >>
         rw [Once type_ctxts_cases, type_ctxt_cases] >>
         rw [type_uop_cases] >>
         ONCE_REWRITE_TAC [context_invariant_cases] >>
         fs [bind_tvar_def, check_freevars_def] >-
         metis_tac [check_freevars_def] >>
         qexists_tac `tenvS` >>
         rw [] >>
         qexists_tac `tenvM` >>
         qexists_tac `tenvC` >>
         qexists_tac `Tapp [t1] TC_ref` >>
         rw [check_freevars_def] >>
         metis_tac [])
     >- (qpat_assum `type_e x0 x1 x2 x3 x4` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
         rw [Once type_ctxts_cases, type_ctxt_cases] >>
         ONCE_REWRITE_TAC [context_invariant_cases] >>
         fs [bind_tvar_def] >>
         metis_tac [type_e_freevars, type_v_freevars])
     >- (qpat_assum `type_e x0 x1 x2 x3 x4` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
         rw [Once type_ctxts_cases, type_ctxt_cases] >>
         ONCE_REWRITE_TAC [context_invariant_cases] >>
         fs [bind_tvar_def] >>
         metis_tac [type_e_freevars, type_v_freevars])
     >- (qpat_assum `type_e x0 x1 x2 x3 x4` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
         rw [Once type_ctxts_cases, type_ctxt_cases] >>
         ONCE_REWRITE_TAC [context_invariant_cases] >>
         fs [bind_tvar_def] >>
         metis_tac [])
     >- (qpat_assum `type_e x0 x1 x2 x3 x4` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
         rw [Once type_ctxts_cases, type_ctxt_cases] >>
         ONCE_REWRITE_TAC [context_invariant_cases] >>
         fs [bind_tvar_def] >>
         metis_tac [type_e_freevars, type_v_freevars, type_v_exn])
     >- (qpat_assum `type_e x0 x1 x2 x3 x4` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
         rw [Once type_ctxts_cases, type_ctxt_cases] >>
         ONCE_REWRITE_TAC [context_invariant_cases] >>
         fs [bind_tvar_def] >|
         [qexists_tac `tenvS` >>
              rw [] >>
              qexists_tac `tenvM` >>
              qexists_tac `tenvC` >>
              qexists_tac `t1'` >>
              qexists_tac `tenv` >>
              qexists_tac `tvs` >>
              rw [] >>
              qexists_tac `tenvM` >>
              qexists_tac `tenvC` >>
              qexists_tac `tenv` >>
              qexists_tac `t1` >>
              rw [] >-
              metis_tac [arithmeticTheory.ADD, arithmeticTheory.ADD_COMM,
                         num_tvs_def, type_v_freevars, tenv_ok_def,
                         type_e_freevars] >>
              fs [is_ccon_def] >>
              metis_tac [arithmeticTheory.ADD, arithmeticTheory.ADD_COMM,
                         num_tvs_def, type_v_freevars, tenv_ok_def,
                         type_e_freevars],
          qexists_tac `tenvS` >>
              rw [] >>
              qexists_tac `tenvM` >>
              qexists_tac `tenvC` >>
              qexists_tac `t1'` >>
              qexists_tac `tenv` >>
              rw [] >>
              qexists_tac `0` >>
              rw [] >>
              qexists_tac `tenvM` >>
              qexists_tac `tenvC` >>
              qexists_tac `tenv` >>
              qexists_tac `t1` >>
              rw [] >>
              metis_tac [arithmeticTheory.ADD, arithmeticTheory.ADD_COMM,
                         num_tvs_def, type_v_freevars, tenv_ok_def,
                         type_e_freevars]])
     >- (every_case_tac >>
         fs [] >>
         rw [] >>
         qpat_assum `type_e tenvM tenvC tenv epat t1`
             (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
         fs [] >>
         rw [build_rec_env_merge] >>
         qexists_tac `tenvS` >>
         rw [] >>
         qexists_tac `tenvM` >>
         qexists_tac `tenvC` >>
         qexists_tac `t1` >>
         qexists_tac `bind_var_list tvs tenv' tenv` >>
         rw [] >>
         fs [bind_tvar_def, all_env_to_cenv_def, all_env_to_menv_def, all_env_to_env_def] >>
         qexists_tac `0` >>
         rw [] >>
         metis_tac [type_recfun_env, type_env_merge, bind_tvar_def]))
 >- (fs [continue_def, push_def] >>
     cases_on `c` >>
     fs [] >>
     cases_on `h` >>
     fs [] >>
     cases_on `q` >>
     fs [] >>
     every_case_tac >>
     fs [return_def] >>
     rw [] >>
     qpat_assum `type_ctxts x1 x2 x3 x4 x5 x6` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_ctxts_cases]) >>
     fs [type_ctxt_cases] >>
     rw [] >>
     qpat_assum `context_invariant x0 x1 x2` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once context_invariant_cases]) >>
     fs [oneTheory.one]
     >- (fs [Once type_ctxts_cases, type_ctxt_cases, Once context_invariant_cases] >>
         metis_tac [])
     >- (fs [Once type_ctxts_cases, type_ctxt_cases, Once context_invariant_cases] >>
         metis_tac [type_e_freevars, type_v_freevars])
     >- (fs [Once type_ctxts_cases, type_ctxt_cases, Once context_invariant_cases] >>
         metis_tac [])
     >- (fs [Once type_ctxts_cases, type_ctxt_cases, Once context_invariant_cases] >>
         metis_tac [])
     >- (fs [Once type_ctxts_cases, type_ctxt_cases, Once context_invariant_cases] >>
         metis_tac [])
     >- (fs [Once type_ctxts_cases, type_ctxt_cases, Once context_invariant_cases] >>
         metis_tac [type_e_freevars, type_v_freevars])
     >- (fs [Once type_ctxts_cases, type_ctxt_cases, Once context_invariant_cases] >>
         cases_on `l` >>
         fs [RES_FORALL] >-
         metis_tac [] >>
         qpat_assum `!x. P x` (ASSUME_TAC o Q.SPEC `h`) >>
         fs [] >>
         PairCases_on `h` >>
         fs [] >>
         metis_tac [num_tvs_bind_var_list, type_e_freevars, type_v_freevars, tenv_ok_bind_var_list, type_p_freevars])
     >- (fs [Once type_ctxts_cases, type_ctxt_cases, Once context_invariant_cases, opt_bind_tenv_def] >>
         every_case_tac >>
         fs [] >>
         metis_tac [opt_bind_tenv_def, tenv_ok_def, arithmeticTheory.ADD_0, num_tvs_def, type_e_freevars, type_v_freevars])
     >- (fs [Once type_ctxts_cases, type_ctxt_cases, Once context_invariant_cases] >>
         metis_tac [bind_tvar_def, EVERY_DEF, type_e_freevars, type_v_freevars, check_freevars_def, EVERY_APPEND])
     >- (fs [Once type_ctxts_cases, type_ctxt_cases, Once context_invariant_cases] >>
         metis_tac [type_e_freevars, type_v_freevars])
     >- metis_tac []
     >- (rw [Once type_ctxts_cases, type_ctxt_cases] >>
         ONCE_REWRITE_TAC [context_invariant_cases] >>
         rw [bind_tvar_def] >>
         fs [bind_tvar_rewrites] >>
         metis_tac [type_v_freevars, type_e_freevars])
     >- (fs [is_ccon_def] >>
         fs [do_app_cases] >>
         rw [] >>
         fs [type_op_cases] >>
         rw [] >|
         [fs [type_v_cases_eqn] >>
              rw [] >>
              rw [Once type_e_cases] >>
              qexists_tac `tenvS` >>
              rw [] >>
              qexists_tac `[]` >>
              qexists_tac `exn_tenvC` >>
              qexists_tac `Tapp [] TC_int` >>
              rw [check_freevars_def] >>
              imp_res_tac type_e_exn >>
              qexists_tac `Empty` >>
              qexists_tac `0` >>
              fs [exn_env_def] >>
              rw [tenvM_ok_def, Once consistent_mod_cases, Once type_env_cases, emp_def],
          fs [type_v_cases_eqn] >>
              rw [] >>
              rw [Once type_e_cases] >>
              qexists_tac `tenvS` >>
              rw [] >>
              qexists_tac `[]` >>
              qexists_tac `exn_tenvC` >>
              qexists_tac `Tapp [] TC_int` >>
              rw [check_freevars_def] >>
              imp_res_tac type_e_exn >>
              qexists_tac `Empty` >>
              qexists_tac `0` >>
              fs [exn_env_def] >>
              rw [tenvM_ok_def, Once consistent_mod_cases, Once type_env_cases, emp_def],
          fs [type_v_cases_eqn] >>
              rw [] >>
              rw [Once type_e_cases] >>
              qexists_tac `tenvS` >>
              rw [] >>
              fs [] >>
              metis_tac [],
          fs [type_v_cases_eqn] >>
              rw [] >>
              rw [Once type_e_cases] >>
              qexists_tac `tenvS` >>
              rw [] >>
              fs [] >>
              metis_tac [],
          fs [type_v_cases_eqn] >>
              rw [] >>
              rw [Once type_e_cases] >>
              qexists_tac `tenvS` >>
              rw [] >>
              fs [] >>
              metis_tac [],
          fs [type_v_cases_eqn] >>
              rw [] >>
              rw [Once type_e_cases] >>
              qexists_tac `tenvS` >>
              rw [] >>
              fs [] >>
              metis_tac [],
          fs [] >>
              rw [] >>
              rw [Once type_e_cases] >>
              qexists_tac `tenvS` >>
              rw [] >>
              imp_res_tac type_e_exn >>
              MAP_EVERY qexists_tac [`[]`, `exn_tenvC`, `Tapp [] TC_bool`, `Empty`, `0`] >>
              fs [exn_env_def] >>
              rw [tenvM_ok_def, Once consistent_mod_cases, Once type_env_cases, emp_def] >>
              metis_tac [check_freevars_def, EVERY_DEF],
          qpat_assum `type_v a ctMap senv (Closure l s' e) t1'`
                    (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
              fs [] >>
              rw [] >>
              rw [Once type_env_cases] >>
              fs [bind_tvar_def] >>
              metis_tac [],
          qpat_assum `type_v a ctMap senv (Recclosure l l0 s') t1'`
               (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
              fs [] >>
              rw [] >>
              imp_res_tac type_recfun_lookup >>
              rw [] >>
              qexists_tac `tenvS` >>
              rw [] >>
              qexists_tac `menv` >>
              qexists_tac `tenvC'` >>
              qexists_tac `t2` >>
              qexists_tac `bind_tenv n'' 0 t1 (bind_var_list 0 tenv'' (bind_tvar 0 tenv'))` >>
              rw [] >>
              rw [Once type_env_cases, bind_def, bind_tenv_def] >>
              fs [check_freevars_def] >>
              rw [build_rec_env_merge] >>
              fs [bind_tvar_def] >>
              qexists_tac `0` >>
              rw [] >>
              fs [bind_tenv_def] >>
              metis_tac [bind_tvar_def, type_recfun_env, type_env_merge],
          fs [] >>
              rw [Once type_e_cases] >>
              qpat_assum `type_v x1 x2 x3 x4 x5` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
              rw [] >>
              fs [store_assign_def, type_s_def, store_lookup_def] >>
              rw [EL_LUPDATE] >>
              qexists_tac `tenvS` >>
              fs [] >> 
              rw [] >>
              qexists_tac `tenvM` >>
              qexists_tac `tenvC` >>
              qexists_tac `tenv` >>
              rw [] >>
              qexists_tac `0` >>
              rw [] >>
              metis_tac [check_freevars_def]])
     >- (fs [do_log_def] >>
         every_case_tac >>
         fs [] >>
         rw [] >>
         fs [Once type_v_cases_eqn] >>
         metis_tac [bind_tvar_def, SIMP_RULE (srw_ss()) [] type_e_rules])
     >- (fs [do_if_def] >>
         every_case_tac >>
         fs [] >>
         rw [] >>
         metis_tac [bind_tvar_def])
     >- (rw [Once type_ctxts_cases, type_ctxt_cases] >>
         ONCE_REWRITE_TAC [context_invariant_cases] >>
         rw [] >>
         fs [RES_FORALL] >>
         `check_freevars 0 [] t2` by metis_tac [type_ctxts_freevars] >>
         metis_tac [])
     >- (rw [Once type_ctxts_cases, type_ctxt_cases] >>
         ONCE_REWRITE_TAC [context_invariant_cases] >>
         rw [] >>
         fs [RES_FORALL] >>
         `check_freevars 0 [] t2` by metis_tac [type_ctxts_freevars] >>
         metis_tac [])
     >- (fs [RES_FORALL, FORALL_PROD] >>
         rw [] >>
         metis_tac [bind_tvar_def, pmatch_type_preservation])
     >- (fs [is_ccon_def] >>
         rw [Once type_env_cases, opt_bind_def] >>
         qexists_tac `tenvS` >>
         rw [] >>
         qexists_tac `tenvM` >>
         qexists_tac `tenvC` >>
         qexists_tac `t2` >>
         qexists_tac `opt_bind_tenv o' tvs t1 tenv` >>
         qexists_tac `0` >> 
         rw [emp_def, opt_bind_tenv_def] >>
         rw [bind_tvar_def] >>
         every_case_tac >>
         fs [bind_tenv_def, bind_def, opt_bind_tenv_def] >>
         qpat_assum `type_env x0 x1 x2 x3` (mp_tac o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
         rw [emp_def, bind_def, bind_tenv_def])
     >- metis_tac [do_con_check_build_conv, NOT_SOME_NONE]
     >- metis_tac [do_con_check_build_conv, NOT_SOME_NONE]
     >- metis_tac [do_con_check_build_conv, NOT_SOME_NONE]
     >- metis_tac [do_con_check_build_conv, NOT_SOME_NONE]
     >- (fs [all_env_to_cenv_def, build_conv_def] >>
         cases_on `lookup_con_id cn cenv'` >>
         fs [] >>
         PairCases_on `x'` >>
         fs [] >>
         rw [] >>
         imp_res_tac consistent_con_env_thm >>
         rw [Once type_v_cases_eqn] >>
         imp_res_tac type_es_length >>
         fs [] >>
         `ts2 = []` by
                 (cases_on `ts2` >>
                  fs []) >>
         fs [] >>
         rw [] >>
         rw [type_vs_end] >>
         fs [is_ccon_def] >>
         metis_tac [ctxt_inv_not_poly, rich_listTheory.MAP_REVERSE])
     >- (fs [all_env_to_cenv_def, build_conv_def] >>
         rw [Once type_v_cases_eqn] >>
         imp_res_tac type_es_length >>
         fs [] >>
         `ts2 = []` by
         (cases_on `ts2` >>
         fs []) >>
         fs [] >>
         rw [] >>
         rw [type_vs_end] >>
         fs [is_ccon_def] >>
         metis_tac [ctxt_inv_not_poly, rich_listTheory.MAP_REVERSE, type_vs_end])
     >- (fs [all_env_to_cenv_def, build_conv_def] >>
         cases_on `lookup_con_id cn cenv'` >>
         fs [] >>
         PairCases_on `x'` >>
         fs [] >>
         rw [] >>
         imp_res_tac consistent_con_env_thm >>
         qpat_assum `type_es tenvM tenvC tenv' (e'::t'') ts2`
               (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
         fs [] >>
         rw [type_ctxt_cases, Once type_ctxts_cases] >>
         ONCE_REWRITE_TAC [context_invariant_cases] >>
         rw [] >>
         qexists_tac `tenvS` >>
         rw [] >>
         qexists_tac `tenvM` >>
         qexists_tac `tenvC` >>
         qexists_tac `t''''` >>
         qexists_tac `tenv` >>
         qexists_tac `tvs` >>
         rw [] >>
         fs [is_ccon_def] >>
         qexists_tac `tenvM` >>
         qexists_tac `tenvC` >>
         qexists_tac `tenv` >>
         qexists_tac `Tapp ts' (tid_exn_to_tc tn)` >>
         rw [] >>
         cases_on `ts2` >>
         fs [] >>
         rw [] >>
         qexists_tac `ts1++[t''']` >>
         rw [] >>
         metis_tac [type_vs_end])
     >- (fs [all_env_to_cenv_def, build_conv_def] >>
         cases_on `lookup_con_id cn cenv'` >>
         fs [] >>
         qpat_assum `type_es tenvM tenvC tenv' (e'::t'') ts2`
               (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
         fs [] >>
         rw [type_ctxt_cases, Once type_ctxts_cases] >>
         ONCE_REWRITE_TAC [context_invariant_cases] >>
         rw [] >>
         qexists_tac `tenvS` >>
         rw [] >>
         qexists_tac `tenvM` >>
         qexists_tac `tenvC` >>
         qexists_tac `t'''` >>
         qexists_tac `tenv` >>
         qexists_tac `tvs` >>
         rw [] >>
         fs [is_ccon_def] >>
         qexists_tac `tenvM` >>
         qexists_tac `tenvC` >>
         qexists_tac `tenv` >>
         qexists_tac `Tapp (ts1 ++ [t1] ++ t'''::ts) TC_tup` >>
         rw [] >>
         qexists_tac `ts1++[t1]` >>
         rw [] >>
         `tenv_ok (bind_tvar tvs tenv) ∧ (num_tvs tenv = 0)` 
                        by (rw [bind_tvar_rewrites] >>
                            metis_tac [type_v_freevars]) >>
         `check_freevars (num_tvs (bind_tvar tvs tenv)) [] t'''` 
                     by metis_tac [type_e_freevars] >>
         fs [bind_tvar_rewrites] >>
         metis_tac [type_vs_end, arithmeticTheory.ADD_0])
     >- (fs [all_env_to_cenv_def, build_conv_def] >>
         cases_on `lookup_con_id cn cenv'` >>
         fs [] >>
         PairCases_on `x'` >>
         fs [] >>
         rw [] >>
         imp_res_tac consistent_con_env_thm >>
         qpat_assum `type_es tenvM tenvC tenv' (e'::t'') ts2`
                (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
         fs [] >>
         rw [type_ctxt_cases, Once type_ctxts_cases] >>
         ONCE_REWRITE_TAC [context_invariant_cases] >>
         rw [] >>
         qexists_tac `tenvS` >>
         rw [] >>
         qexists_tac `tenvM` >>
         qexists_tac `tenvC` >>
         qexists_tac `t''''` >>
         qexists_tac `tenv` >>
         qexists_tac `tvs` >>
         rw [] >>
         fs [is_ccon_def] >>
         qexists_tac `tenvM` >>
         qexists_tac `tenvC` >>
         qexists_tac `tenv` >>
         qexists_tac `Tapp ts' (tid_exn_to_tc tn)` >>
         rw [] >>
         cases_on `ts2` >>
         fs [] >>
         rw [] >>
         qexists_tac `ts1++[t''']` >>
         rw [] >>
         metis_tac [type_vs_end])
     >- (fs [all_env_to_cenv_def, build_conv_def] >>
         qpat_assum `type_es tenvM tenvC tenv' (e'::t'') ts2`
                (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
         fs [] >>
         rw [type_ctxt_cases, Once type_ctxts_cases] >>
         ONCE_REWRITE_TAC [context_invariant_cases] >>
         rw [] >>
         qexists_tac `tenvS` >>
         rw [] >>
         qexists_tac `tenvM` >>
         qexists_tac `tenvC` >>
         qexists_tac `t'''` >>
         qexists_tac `tenv` >>
         qexists_tac `tvs` >>
         rw [] >>
         fs [is_ccon_def] >>
         qexists_tac `tenvM` >>
         qexists_tac `tenvC` >>
         qexists_tac `tenv` >>
         qexists_tac `Tapp (ts1 ++ [t1] ++ t'''::ts) TC_tup` >>
         rw [] >>
         qexists_tac `ts1++[t1]` >>
         rw [] >>
         `tenv_ok (bind_tvar tvs tenv) ∧ (num_tvs tenv = 0)` 
                        by (rw [bind_tvar_rewrites] >>
                            metis_tac [type_v_freevars]) >>
         `check_freevars (num_tvs (bind_tvar tvs tenv)) [] t'''` 
                     by metis_tac [type_e_freevars] >>
         fs [bind_tvar_rewrites] >>
         metis_tac [type_vs_end, arithmeticTheory.ADD_0])
     >- (cases_on `u` >>
         fs [type_uop_cases, do_uapp_def, store_alloc_def, LET_THM] >>
         rw [] >|
         [rw [Once type_v_cases_eqn] >>
              qexists_tac `bind (LENGTH st) t1 tenvS` >>
              rw [] >|
              [qexists_tac `Tref t1` >>
                   qexists_tac `0` >>
                   rw [] >>
                   `lookup (LENGTH st) tenvS = NONE`
                           by (fs [type_s_def, store_lookup_def] >>
                               `~(LENGTH st < LENGTH st)` by decide_tac >>
                               `~(?t. lookup (LENGTH st) tenvS = SOME t)` by metis_tac [] >>
                               fs [] >>
                               cases_on `lookup (LENGTH st) tenvS` >>
                               fs []) >|
                   [metis_tac [type_ctxts_weakening, weakCT_refl, weakC_refl, weakM_refl, weakS_bind],
                    fs [type_s_def, lookup_def, bind_def, store_lookup_def] >>
                        rw [] >-
                        decide_tac >|
                        [rw [rich_listTheory.EL_LENGTH_APPEND] >>
                             metis_tac [bind_def, type_v_weakening, weakS_bind, weakC_refl, weakM_refl, weakCT_refl],
                         `l < LENGTH st` by decide_tac >>
                             rw [rich_listTheory.EL_APPEND1] >>
                             metis_tac [type_v_weakening, weakS_bind, weakCT_refl, weakC_refl, weakM_refl, bind_def]],
                    rw [lookup_def, bind_def]],
               disj2_tac >>
                   qexists_tac `LENGTH st` >>
                   qexists_tac `t1` >>
                   rw [] >>
                   fs [type_s_def, store_lookup_def] >>
                   `~(LENGTH st < LENGTH st)` by decide_tac >>
                   `!t. lookup (LENGTH st) tenvS ≠ SOME t` by metis_tac [] >>
                   cases_on `lookup (LENGTH st) tenvS` >>
                   fs []],
          cases_on `v` >>
              fs [store_lookup_def] >>
              cases_on `n < LENGTH st` >>
              fs [] >>
              rw [] >>
              qpat_assum `type_v a0 a1 b2 c3 d4`
                     (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
               fs [type_s_def, store_lookup_def] >>
               metis_tac []])));

val store_type_extension_def = Define `
store_type_extension tenvS1 tenvS2 = 
  ?tenvS'. (tenvS2 = merge tenvS' tenvS1) ∧ 
           (!l. (lookup l tenvS' = NONE) ∨ (lookup l tenvS1 = NONE))`;

val store_type_extension_weakS = Q.store_thm ("store_type_extension_weakS",
`!tenvS1 tenvS2.
  store_type_extension tenvS1 tenvS2 ⇒ weakS tenvS2 tenvS1`,
rw [store_type_extension_def, weakS_def, lookup_append, merge_def] >>
rw [lookup_append] >>
cases_on `lookup l tenvS'` >>
rw [] >>
metis_tac [optionTheory.NOT_SOME_NONE]);

val exp_type_soundness_help = Q.prove (
`!state1 state2. e_step_reln^* state1 state2 ⇒
  ∀ctMap tenvS st env e c st' env' e' c' t dec_tvs.
    (state1 = (env,st,e,c)) ∧
    (state2 = (env',st',e',c')) ∧
    ctMap_has_exns ctMap ∧
    ctMap_ok ctMap ∧
    type_state dec_tvs ctMap tenvS state1 t
    ⇒
    ?tenvS'. type_state dec_tvs ctMap tenvS' state2 t ∧
             store_type_extension tenvS tenvS'`,
 ho_match_mp_tac RTC_INDUCT >>
 rw [e_step_reln_def] >-
 (rw [store_type_extension_def] >>
      qexists_tac `tenvS` >>
      rw [merge_def]) >>
 `?menv1' cenv1' envE1' store1' ev1' ctxt1'. state1' = ((menv1',cenv1',envE1'),store1',ev1',ctxt1')` by (PairCases_on `state1'` >> metis_tac []) >>
 `?menv cenv envE. env = (menv,cenv,envE)` by (PairCases_on `env` >> metis_tac []) >>
 `?tenvS'. type_state dec_tvs ctMap tenvS' state1' t ∧
                ((tenvS' = tenvS) ∨
                 ?l t. (lookup l tenvS = NONE) ∧ (tenvS' = bind l t tenvS))`
                        by metis_tac [exp_type_preservation] >>
 fs [] >>
 `store_type_extension tenvS tenvS'`
          by (fs [store_type_extension_def, merge_def] >>
              metis_tac [APPEND, bind_def, lookup_def]) >>
 rw [] >>
 res_tac >>
 qexists_tac `tenvS'` >>
 fs [store_type_extension_def, merge_def, bind_def, lookup_def, lookup_append] >>
 rw [] 
 >- metis_tac [] >>
 full_case_tac >>
 metis_tac [NOT_SOME_NONE]);

val exp_type_soundness = Q.store_thm ("exp_type_soundness",
`!tenvM ctMap tenvC tenvS tenv st e t menv cenv env tvs.
  tenvM_ok tenvM ∧
  ctMap_has_exns ctMap ∧
  consistent_mod_env tenvS ctMap menv tenvM ∧
  consistent_con_env ctMap cenv tenvC ∧
  type_env ctMap tenvS env tenv ∧
  type_s ctMap tenvS st ∧
  (tvs ≠ 0 ⇒ is_value e) ∧
  type_e tenvM tenvC (bind_tvar tvs tenv) e t
  ⇒
  e_diverges (menv,cenv,env) st e ∨
  (?st' r. (r ≠ Rerr Rtype_error) ∧ 
          small_eval (menv,cenv,env) st e [] (st',r) ∧
          (?tenvS'.
            type_s ctMap tenvS' st' ∧
            store_type_extension tenvS tenvS' ∧
            (!v. (r = Rval v) ⇒ type_v tvs ctMap tenvS' v t)))`,
 rw [e_diverges_def, METIS_PROVE [] ``(x ∨ y) = (~x ⇒ y)``] >>
 `type_state tvs ctMap tenvS ((menv,cenv,env),st,Exp e,[]) t`
         by (rw [type_state_cases] >>
             qexists_tac `tenvM` >>
             qexists_tac `tenvC` >>
             qexists_tac `t` >>
             qexists_tac `tenv` >>
             qexists_tac `tvs` >>
             rw [] >|
             [rw [Once context_invariant_cases],
              rw [Once type_ctxts_cases] >>
                  `num_tvs tenv = 0` by metis_tac [type_v_freevars] >>
                  `num_tvs (bind_tvar tvs tenv) = tvs`
                             by rw [bind_tvar_rewrites] >>
                  metis_tac [bind_tvar_rewrites, type_v_freevars, type_e_freevars]]) >>
 `?tenvS'. type_state tvs ctMap tenvS' (env',s',e',c') t ∧ store_type_extension tenvS tenvS'`
         by metis_tac [exp_type_soundness_help, consistent_con_env_def] >>
 fs [e_step_reln_def] >>
 `final_state (env',s',e',c')` by (PairCases_on `env'` >> metis_tac [exp_type_progress]) >>
 Cases_on `e'` >>
 Cases_on `c'` >>
 TRY (Cases_on `e''`) >>
 fs [final_state_def] >>
 qexists_tac `s'` 
 >- (fs [small_eval_def] >>
     fs [type_state_cases] >>
     fs [Once context_invariant_cases, Once type_ctxts_cases] >>
     metis_tac [small_eval_def, result_distinct, result_11])
 >- (fs [small_eval_def] >>
     fs [type_state_cases] >>
     fs [Once context_invariant_cases, Once type_ctxts_cases] >>
     rw [] >>
     fs [final_state_def] >>
     cases_on `t'` >>
     fs [final_state_def, type_ctxt_cases] >>
     metis_tac [small_eval_def, result_distinct, result_11, error_result_distinct]));

val store_type_extension_refl = Q.prove (
`!s. store_type_extension s s`,
 rw [store_type_extension_def] >>
 qexists_tac `[]` >>
 rw [merge_def]);

val decs_type_sound_invariant_def = Define `
decs_type_sound_invariant mn tdecs1 tdecs2 ctMap tenvS tenvM tenvC tenv st menv cenv env ⇔
  tenvM_ok tenvM ∧
  ctMap_ok ctMap ∧
  ctMap_has_exns ctMap ∧
  consistent_con_env ctMap cenv tenvC ∧
  consistent_mod_env tenvS ctMap menv tenvM ∧
  type_env ctMap tenvS env tenv ∧
  type_s ctMap tenvS st ∧
  consistent_decls tdecs2 tdecs1 ∧
  consistent_ctMap tdecs1 ctMap ∧
  mn ∉ IMAGE SOME (FST tdecs1)`;

val dec_type_soundness = Q.store_thm ("dec_type_soundness",
`!mn tenvM tenvC tenv d tenvC' tenv' tenvS ck menv cenv env count st tdecs1 tdecs1' tdecs2 ctMap.
  type_d mn tdecs1 tenvM tenvC tenv d tdecs1' tenvC' tenv' ∧
  decs_type_sound_invariant mn tdecs1 tdecs2 ctMap tenvS tenvM tenvC tenv st menv cenv env
  ⇒
  dec_diverges (menv,cenv,env) (st,tdecs2) d ∨
  ?st' r tenvS' tdecs2'. 
     (r ≠ Rerr Rtype_error) ∧ 
     evaluate_dec F mn (menv,cenv,env) ((count,st),tdecs2) d (((count,st'),tdecs2'), r) ∧
     consistent_decls tdecs2' (union_decls tdecs1' tdecs1) ∧
     store_type_extension tenvS tenvS' ∧
     type_s ctMap tenvS' st' ∧
     (!cenv' env'. 
         (r = Rval (cenv',env')) ⇒
         (MAP FST cenv' = MAP FST tenvC') ∧
         consistent_ctMap (union_decls tdecs1' tdecs1) (FUNION (flat_to_ctMap tenvC') ctMap) ∧
         consistent_con_env (FUNION (flat_to_ctMap tenvC') ctMap) (merge_envC (emp,cenv') cenv) (merge_tenvC (emp,tenvC') tenvC) ∧
         type_env (FUNION (flat_to_ctMap tenvC') ctMap) tenvS' (env' ++ env) (bind_var_list2 tenv' tenv) ∧
         type_env (FUNION (flat_to_ctMap tenvC') ctMap) tenvS' env' (bind_var_list2 tenv' Empty))`,
 rw [decs_type_sound_invariant_def, METIS_PROVE [] ``(x ∨ y) = (~x ⇒ y)``] >>
 fs [type_d_cases] >>
 rw [] >>
 fs [dec_diverges_def, merge_def, emp_def, evaluate_dec_cases] >>
 fs [union_decls_empty]
 >- (`∃st2 r tenvS'. r ≠ Rerr Rtype_error ∧ small_eval (menv,cenv,env) st e [] (st2,r) ∧
                type_s ctMap tenvS' st2 ∧ 
                store_type_extension tenvS tenvS' ∧
                (!v. (r = Rval v) ==> type_v tvs ctMap tenvS' v t)`
                         by metis_tac [exp_type_soundness] >>
     cases_on `r` >>
     fs []
     >- (`(pmatch cenv st2 p a [] = No_match) ∨
          (?new_env. pmatch cenv st2 p a [] = Match new_env)`
                   by (metis_tac [pmatch_type_progress])
         >- (MAP_EVERY qexists_tac [`st2`, `Rerr (Rraise (Conv (SOME ("Bind", TypeExn (Short "Bind"))) []))`, 
                                    `tenvS'`,`tdecs2`] >>
             rw [] >>
             metis_tac [small_big_exp_equiv, all_env_to_cenv_def])
         >- (MAP_EVERY qexists_tac [`st2`, `Rval ([],new_env)`, `tenvS'`,`tdecs2`] >>
             `pmatch cenv st2 p a ([]++env) = Match (new_env++env)`
                      by metis_tac [pmatch_append] >>
             `type_env ctMap tenvS [] Empty` by metis_tac [type_v_rules, emp_def] >>
             `type_env ctMap tenvS' new_env (bind_var_list tvs tenv'' Empty) ∧
              type_env ctMap tenvS' (new_env ++ env) (bind_var_list tvs tenv'' tenv)` 
                          by (imp_res_tac pmatch_type_preservation >>
                              metis_tac [merge_def, APPEND, APPEND_NIL,type_v_weakening, weakM_refl, weakC_refl,
                                        store_type_extension_weakS, weakCT_refl, consistent_con_env_def]) >>
             rw []
             >- metis_tac [all_env_to_cenv_def, small_big_exp_equiv] >>
             rw [flat_to_ctMap_list_def, flat_to_ctMap_def, FUPDATE_LIST, FUNION_FEMPTY_1] >>
             PairCases_on `tenvC` >>
             PairCases_on `cenv` >>
             rw [flat_to_ctMap_def, merge_envC_def, merge_def, merge_tenvC_def] >>
             metis_tac [bvl2_to_bvl, small_big_exp_equiv, all_env_to_cenv_def]))
     >- (MAP_EVERY qexists_tac [`st2`,`Rerr e'`,`tenvS'`,`tdecs2`] >>
         rw [] >>
         rw [store_type_extension_def, merge_def] >>
         metis_tac [small_big_exp_equiv]))
 >- (`∃st2 r tenvS'. r ≠ Rerr Rtype_error ∧ small_eval (menv,cenv,env) st e [] (st2,r) ∧
                type_s ctMap tenvS' st2 ∧ 
                store_type_extension tenvS tenvS' ∧
                (!v. (r = Rval v) ==> type_v (0:num) ctMap tenvS' v t)`
                         by metis_tac [exp_type_soundness, bind_tvar_def] >>
     cases_on `r` >>
     fs []
     >- (`(pmatch cenv st2 p a [] = No_match) ∨
          (?new_env. pmatch cenv st2 p a [] = Match new_env)`
                    by (metis_tac [pmatch_type_progress])
         >- (MAP_EVERY qexists_tac [`st2`,`Rerr (Rraise (Conv (SOME ("Bind", TypeExn (Short "Bind"))) []))`, `tenvS'`, `tdecs2`] >>
             rw [] >>
             metis_tac [small_big_exp_equiv, all_env_to_cenv_def])
         >- (MAP_EVERY qexists_tac [`st2`,`Rval ([],new_env)`, `tenvS'`, `tdecs2`] >>
             `pmatch cenv st2 p a ([]++env) = Match (new_env++env)`
                        by metis_tac [pmatch_append] >>
             `type_p 0 tenvC p t tenv''` by metis_tac [] >>
             `type_env ctMap tenvS [] Empty` by metis_tac [type_v_rules, emp_def] >>
             `type_env ctMap tenvS' new_env (bind_var_list 0 tenv'' Empty) ∧
              type_env ctMap tenvS' (new_env ++ env) (bind_var_list 0 tenv'' tenv)`
                      by (imp_res_tac pmatch_type_preservation >>
                          metis_tac [merge_def, APPEND, APPEND_NIL, type_v_weakening, weakM_refl, weakC_refl,
                                    store_type_extension_weakS, weakCT_refl, consistent_con_env_def]) >>
             rw []
             >- metis_tac [all_env_to_cenv_def, small_big_exp_equiv] >>
             rw [flat_to_ctMap_list_def, flat_to_ctMap_def, FUPDATE_LIST, FUNION_FEMPTY_1] >>
             PairCases_on `tenvC` >>
             PairCases_on `cenv` >>
             rw [flat_to_ctMap_def, merge_envC_def, merge_def, merge_tenvC_def] >>
             metis_tac [bvl2_to_bvl, small_big_exp_equiv, all_env_to_cenv_def]))
     >- (MAP_EVERY qexists_tac [`st2`, `Rerr e'`,`tenvS'`, `tdecs2`] >>
         rw []
         >- (rw [store_type_extension_def, merge_def] >>
             metis_tac [small_big_exp_equiv])))
 >- (imp_res_tac type_funs_distinct >>
     `type_env2 ctMap tenvS tvs (MAP (\(fn,n,e). (fn, Recclosure (menv,cenv,env) funs fn)) funs) tenv''`
                  by metis_tac [type_recfun_env] >>
     imp_res_tac type_env_merge_lem1 >>
     MAP_EVERY qexists_tac [`st`, `Rval ([],build_rec_env funs (menv,cenv,env) [])`, `tenvS`, `tdecs2`] >>
     rw [] 
     >- metis_tac [store_type_extension_refl]
     >- (rw [flat_to_ctMap_list_def, flat_to_ctMap_def, FUPDATE_LIST, FUNION_FEMPTY_1] >>
         PairCases_on `tenvC` >>
         PairCases_on `cenv` >>
         rw [flat_to_ctMap_def, merge_envC_def, merge_def, merge_tenvC_def])
     >- (rw [flat_to_ctMap_list_def, flat_to_ctMap_def, FUPDATE_LIST, FUNION_FEMPTY_1] >>
         PairCases_on `tenvC` >>
         PairCases_on `cenv` >>
         rw [flat_to_ctMap_def, merge_envC_def, merge_def, merge_tenvC_def]) >>
     rw [flat_to_ctMap_list_def, flat_to_ctMap_def, FUPDATE_LIST, FUNION_FEMPTY_1] >>
     fs [flat_to_ctMap_def, build_rec_env_merge, merge_def, emp_def] >>
     rw [store_type_extension_def, merge_def] >>
     metis_tac [bvl2_to_bvl, type_env2_to_type_env])
 >- (MAP_EVERY qexists_tac [`st`,`Rval (build_tdefs mn tdefs,[])`,`tenvS`, `type_defs_to_new_tdecs mn tdefs ∪ tdecs2`] >>
     `DISJOINT (FDOM (flat_to_ctMap (build_ctor_tenv mn tdefs))) (FDOM ctMap)` 
                    by metis_tac [consistent_decls_disjoint] >>
     imp_res_tac extend_consistent_con >>
     fs [emp_def] >>
     rw []
     >- metis_tac [check_ctor_tenv_dups]
     >- (fs [RES_FORALL,SUBSET_DEF, DISJOINT_DEF, EXTENSION, consistent_decls_def] >>
         rw [] >>
         fs [type_defs_to_new_tdecs_def, MEM_MAP, FORALL_PROD] >>
         rw [] >>
         CCONTR_TAC >>
         fs [] >>
         rw [] >>
         res_tac >>
         every_case_tac >>
         fs [] >>
         rw [] >>
         cases_on `mn` >>
         fs [mk_id_def] >>
         rw [] >>
         metis_tac [])
     >- fs [check_ctor_tenv_def, LAMBDA_PROD]
     >- (fs [union_decls_def, consistent_decls_def, RES_FORALL] >>
         rw [] >>
         every_case_tac >>
         fs [MEM_MAP, type_defs_to_new_tdecs_def]
         >- (PairCases_on `y` >>
             fs [EXISTS_PROD] >>
             rw [] >>
             metis_tac [])
         >- (PairCases_on `y` >>
             fs [EXISTS_PROD] >>
             rw [] >>
             metis_tac [])
         >- (res_tac >>
             every_case_tac >>
             fs [])
         >- (res_tac >>
             every_case_tac >>
             fs []))
     >- metis_tac [store_type_extension_refl]
     >- (rpt (pop_assum (fn _ => all_tac)) >>
         rw [build_tdefs_def, build_ctor_tenv_def] >>
         induct_on `tdefs` >>
         rw [] >>
         PairCases_on `h` >>
         rw [] >>
         induct_on `h2` >>
         rw [] >>
         PairCases_on `h` >>
         rw [])
     >- (rw [union_decls_def] >>
         metis_tac [consistent_ctMap_extend])
     >- (rw [bind_var_list2_def] >>
         `weakCT (FUNION (flat_to_ctMap (build_ctor_tenv mn tdefs)) ctMap) ctMap`
                       by metis_tac [disjoint_env_weakCT, merge_def] >>
         metis_tac [type_v_weakening, weakM_refl, weakC_refl, merge_def,
                    consistent_con_env_def, weakS_refl, ctMap_ok_def])
     >- metis_tac [type_env_eqn, emp_def, bind_var_list2_def])
 >- (Q.LIST_EXISTS_TAC [`st`, `Rval (bind cn (LENGTH ts,TypeExn (mk_id mn cn)) [], [])`, `tenvS`, `{TypeExn (mk_id mn cn)} ∪ tdecs2`] >>
     `DISJOINT (FDOM (flat_to_ctMap (bind cn ([]:tvarN list,ts,TypeExn (mk_id mn cn)) []))) (FDOM ctMap)`
                 by metis_tac [emp_def, consistent_decls_disjoint_exn] >>
     rw []
     >- (fs [consistent_decls_def, RES_FORALL] >>
         CCONTR_TAC >>
         fs [] >>
         res_tac >>
         every_case_tac >>
         fs []
         >- metis_tac [] >>
         cases_on `mn` >>
         fs [mk_id_def])
     >- (fs [union_decls_def, consistent_decls_def, RES_FORALL] >>
         rw [] >>
         rw [] >>
         every_case_tac >>
         rw [] >>
         res_tac >>
         fs [])
     >- rw [store_type_extension_def, merge_def]
     >- rw [bind_def]
     >- (rw [union_decls_def] >>
         metis_tac [consistent_ctMap_extend_exn])
     >- (match_mp_tac (SIMP_RULE (srw_ss()) [emp_def] extend_consistent_con_exn) >>
         fs [DISJOINT_DEF, EXTENSION, flat_to_ctMap_def, flat_to_ctMap_list_def, bind_def,
             FDOM_FUPDATE_LIST])
     >- (rw [bind_var_list2_def] >>
         `weakCT (FUNION  (flat_to_ctMap (bind cn ([],ts,TypeExn (mk_id mn cn)) [])) ctMap) ctMap`
                       by metis_tac [disjoint_env_weakCT, merge_def] >>
         `ctMap_ok (FUNION (flat_to_ctMap (bind cn ([],ts,TypeExn (mk_id mn cn)) [])) ctMap)`
                       by (match_mp_tac ctMap_ok_merge_imp >>
                           fs [consistent_con_env_def] >>
                           rw [bind_def, flat_to_ctMap_def, flat_to_ctMap_list_def, ctMap_ok_def,
                               FEVERY_ALL_FLOOKUP, flookup_fupdate_list] >>
                           every_case_tac >>
                           fs [] >>
                           rw [] >>
                           fs [check_exn_tenv_def]) >>
         metis_tac [type_v_weakening, weakM_refl, weakC_refl, merge_def,
                    consistent_con_env_def, weakS_refl])
     >- metis_tac [type_env_eqn, emp_def, bind_var_list2_def]));

val store_type_extension_trans = Q.prove (
`!tenvS1 tenvS2 tenvS3.
  store_type_extension tenvS1 tenvS2 ∧
  store_type_extension tenvS2 tenvS3 ⇒
  store_type_extension tenvS1 tenvS3`,
rw [store_type_extension_def, merge_def, lookup_append] >>
qexists_tac `tenvS'' ++ tenvS'` >>
fs [lookup_append] >>
rw [] >>
full_case_tac >-
metis_tac [] >>
qpat_assum `!l. P l` (MP_TAC o Q.SPEC `l`) >>
rw [] >>
every_case_tac >>
fs []);

val still_has_exns = Q.prove (
`!ctMap1 ctMap2.
  (DISJOINT (FDOM ctMap1) (FDOM ctMap2) ∨ DISJOINT (FDOM ctMap2) (FDOM ctMap1)) ∧
  ctMap_has_exns ctMap1
  ⇒
  ctMap_has_exns (FUNION ctMap2 ctMap1)`,
 rw [FLOOKUP_FUNION, ctMap_has_exns_def] >>
 every_case_tac >>
 fs [] >>
 fs [FLOOKUP_DEF, DISJOINT_DEF, EXTENSION] >>
 metis_tac []);

val decs_type_soundness = Q.store_thm ("decs_type_soundness",
`!mn tdecs1 tenvM tenvC tenv ds tdecs1' tenvC' tenv'.
  type_ds mn tdecs1 tenvM tenvC tenv ds tdecs1' tenvC' tenv' ⇒
  ∀tenvS menv cenv env st tdecs2 ctMap count.
  decs_type_sound_invariant mn tdecs1 tdecs2 ctMap tenvS tenvM tenvC tenv st menv cenv env
  ⇒
  decs_diverges mn (menv,cenv,env) (st,tdecs2) ds ∨
  ?st' r cenv' tenvS' tdecs2'. 
     (r ≠ Rerr Rtype_error) ∧ 
     evaluate_decs F mn (menv,cenv,env) ((count,st),tdecs2) ds (((count,st'),tdecs2'), cenv', r) ∧
     consistent_decls tdecs2' (union_decls tdecs1' tdecs1) ∧
     store_type_extension tenvS tenvS' ∧
     (!err.
         (r = Rerr err) ⇒
         (?tenvC1 tenvC2. 
           (tenvC' = tenvC1++tenvC2) ∧
           type_s (FUNION (flat_to_ctMap tenvC2) ctMap) tenvS' st' ∧
           consistent_ctMap (union_decls tdecs1' tdecs1) (FUNION (flat_to_ctMap tenvC2) ctMap) ∧
           consistent_con_env (FUNION (flat_to_ctMap tenvC2) ctMap) (merge_envC (emp,cenv') cenv) (merge_tenvC (emp,tenvC2) tenvC))) ∧
     (!env'. 
         (r = Rval env') ⇒
         (MAP FST cenv' = MAP FST tenvC') ∧
         consistent_con_env (FUNION (flat_to_ctMap tenvC') ctMap) (merge_envC (emp,cenv') cenv) (merge_tenvC (emp,tenvC') tenvC) ∧
         consistent_ctMap (union_decls tdecs1' tdecs1) (FUNION (flat_to_ctMap tenvC') ctMap) ∧
         type_s (FUNION (flat_to_ctMap tenvC') ctMap) tenvS' st' ∧
         type_env (FUNION (flat_to_ctMap tenvC') ctMap) tenvS' env' (bind_var_list2 tenv' Empty) ∧
         type_env (FUNION (flat_to_ctMap tenvC') ctMap) tenvS' (env'++env) (bind_var_list2 tenv' tenv))`,
 ho_match_mp_tac type_ds_strongind >>
 rw [METIS_PROVE [] ``(x ∨ y) = (~x ⇒ y)``] >>
 rw [Once evaluate_decs_cases, bind_var_list2_def, emp_def] >>
 rw [] >>
 pop_assum (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once decs_diverges_cases]) >>
 fs [merge_def, emp_def, empty_to_ctMap]
 >- (fs [union_decls_empty, decs_type_sound_invariant_def] >>
     qexists_tac `tenvS` >>
     rw [store_type_extension_def]
     >- (qexists_tac `[]` >>
          rw [merge_def])
     >- (PairCases_on `cenv` >>
         PairCases_on `tenvC` >>
         fs [merge_envC_def, merge_tenvC_def, merge_def])
     >- metis_tac [type_v_rules, emp_def])
 >- (`?st' r tenvS' tdecs2'. 
        (r ≠ Rerr Rtype_error) ∧ 
        evaluate_dec F mn (menv,cenv,env) ((count',st),tdecs2) d (((count',st'),tdecs2'),r) ∧
        consistent_decls tdecs2' (union_decls decls' tdecs1) ∧
        store_type_extension tenvS tenvS' ∧
        type_s ctMap tenvS' st' ∧
        ∀cenv'' env''.
          (r = Rval (cenv'',env'')) ⇒
          (MAP FST cenv'' = MAP FST cenv') ∧
          consistent_ctMap (union_decls decls' tdecs1) (FUNION (flat_to_ctMap cenv') ctMap) ∧
          consistent_con_env (FUNION (flat_to_ctMap cenv') ctMap) (merge_envC (emp,cenv'') cenv) (merge_tenvC (emp,cenv') tenvC) ∧
          type_env (FUNION (flat_to_ctMap cenv') ctMap) tenvS' (env''++env) (bind_var_list2 tenv' tenv) ∧
          type_env (FUNION (flat_to_ctMap cenv') ctMap) tenvS' env'' (bind_var_list2 tenv' Empty)`
                     by metis_tac [dec_type_soundness] >>
     `(?cenv'' env''. (?err. r = Rerr err) ∨ r = Rval (cenv'',env''))` 
                   by (cases_on `r` >> metis_tac [pair_CASES]) >>
     fs [GSYM union_decls_assoc]
     >- (Q.LIST_EXISTS_TAC [`st'`, `Rerr err`, `[]`, `tenvS'`, `tdecs2'`] >>
         rw []
         >- metis_tac [consistent_decls_weakening, weak_decls_union2, type_ds_mod]
         >- (Q.LIST_EXISTS_TAC [`tenvC'++cenv'`, `[]`] >>
             rw [flat_to_ctMap_def, flat_to_ctMap_list_def, FUPDATE_LIST, FUNION_FEMPTY_1, merge_envC_empty] >>
             metis_tac [weak_decls_union2, type_d_mod, type_ds_mod, consistent_ctMap_weakening, decs_type_sound_invariant_def]))
     >- (`¬decs_diverges mn (menv, merge_envC ([],cenv'') cenv, env'' ++ env) (st',tdecs2') ds` by metis_tac [] >>
         `decs_type_sound_invariant mn (union_decls decls' tdecs1) tdecs2' (flat_to_ctMap cenv' ⊌ ctMap) tenvS' tenvM (merge_tenvC ([],cenv') tenvC) (bind_var_list2 tenv' tenv) st' menv (merge_envC ([],cenv'') cenv) (env'' ++ env)` 
                         by (fs [decs_type_sound_invariant_def, emp_def] >>
                             rw []
                             >- metis_tac [ctMap_ok_pres]
                             >- metis_tac [still_has_exns, type_d_ctMap_disjoint]
                             >- metis_tac [type_v_weakening, merge_def, store_type_extension_weakS, disjoint_env_weakCT,
                                           type_d_ctMap_disjoint, ctMap_ok_pres]
                             >- metis_tac [merge_def,type_d_ctMap_disjoint, disjoint_env_weakCT, weakM_refl, type_s_weakening, ctMap_ok_pres]
                             >- (PairCases_on `decls'` >>
                                 PairCases_on `tdecs1` >>
                                 imp_res_tac type_d_mod >>
                                 fs [union_decls_def])) >>
         res_tac >>
         pop_assum (qspecl_then [`count'`] strip_assume_tac) >>
         rw [] >>
         Q.LIST_EXISTS_TAC [`st''`, `combine_dec_result env'' r'`, `merge cenv''' cenv''`, `tenvS''`, `tdecs2''`] >>
         rw []
         >- (cases_on `r'` >>
             rw [combine_dec_result_def])
         >- metis_tac [merge_def]
         >- metis_tac [store_type_extension_trans]
         >- (cases_on `r'` >> 
             fs [combine_dec_result_def] >> 
             rw [] >>
             metis_tac [FUNION_ASSOC, merge_def, flat_to_ctMap_append, merge_envC_empty_assoc, 
                        merge_tenvC_empty_assoc, APPEND_ASSOC])
         >- (cases_on `r'` >>
             fs [merge_def, combine_dec_result_def])
         >- (cases_on `r'` >> 
             fs [combine_dec_result_def] >> 
             rw [] >>
             metis_tac [APPEND_ASSOC, merge_def, flat_to_ctMap_append, merge_envC_empty_assoc, 
                        merge_tenvC_empty_assoc, FUNION_ASSOC])
         >- (cases_on `r'` >> 
             fs [combine_dec_result_def, flat_to_ctMap_append] >> 
             rw [] >>
             metis_tac [FUNION_ASSOC])
         >- (cases_on `r'` >> 
             fs [combine_dec_result_def, flat_to_ctMap_append] >> 
             rw [] >>
             metis_tac [FUNION_ASSOC])
         >- (cases_on `r'` >> 
             fs [combine_dec_result_def] >> 
             rw [] >>
             `ctMap_ok (FUNION (flat_to_ctMap tenvC') (FUNION (flat_to_ctMap cenv') ctMap))` 
                             by metis_tac [consistent_con_env_def] >>
             fs [flat_to_ctMap_append] >>
             `DISJOINT (FDOM (flat_to_ctMap tenvC')) (FDOM (FUNION (flat_to_ctMap cenv') ctMap))`
                        by (rw [] >>
                            `DISJOINT (FDOM (flat_to_ctMap tenvC')) (FDOM (flat_to_ctMap cenv' ⊌ ctMap))`
                                             by metis_tac [type_ds_ctMap_disjoint] >>
                            fs []) >>
             metis_tac [type_env_merge_bvl2, type_v_weakening,store_type_extension_weakS, 
                        disjoint_env_weakCT, DISJOINT_SYM, APPEND_ASSOC, 
                        FUNION_ASSOC, merge_def, weakM_refl])
         >- (cases_on `r'` >> 
             fs [combine_dec_result_def] >> 
             rw [] >>
             metis_tac [FUNION_ASSOC, merge_def, bvl2_append, flat_to_ctMap_append]))));

val consistent_mod_env_dom = Q.prove (
`!tenvS ctMap menv tenvM.
  consistent_mod_env tenvS ctMap menv tenvM ⇒
  (MAP FST menv = MAP FST tenvM)`,
 induct_on `tenvM` >>
 rw [] >>
 cases_on `menv` >>
 fs [] >>
 pop_assum (assume_tac o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
 rw [] >>
 fs [] >>
 res_tac);

val type_env_eqn2 = Q.prove (
`(!tenvM tenvC tenvS.
   type_env tenvC tenvS [] Empty = T) ∧
 (!tenvM tenvC tenvS n v n' tvs t envE tenv.
   type_env tenvC tenvS ((n,v)::envE) (Bind_name n' tvs t tenv) = 
     ((n = n') ∧ type_v tvs tenvC tenvS v t ∧ 
      type_env tenvC tenvS envE tenv))`,
rw [] >-
rw [Once type_v_cases, emp_def] >>
rw [Once type_v_cases, bind_def, bind_tenv_def] >>
metis_tac []);

val type_ds_no_dup_types_helper = Q.prove (
`!mn mdecls tdecls edecls tenvM tenvC tenv ds mdecls' tdecls' edecls' tenvC' tenv'.
  type_ds mn (mdecls,tdecls,edecls) tenvM tenvC tenv ds (mdecls',tdecls',edecls') tenvC' tenv'
  ⇒
  DISJOINT tdecls tdecls' ∧
  tdecls' =  
  set (FLAT (MAP (λd.
                case d of
                  Dlet v6 v7 => []
                | Dletrec v8 => []
                | Dtype tds => MAP (λ(tvs,tn,ctors). mk_id mn tn) tds
                | Dexn v10 v11 => []) ds))`,
 induct_on `ds` >>
 rw [] >>
 pop_assum (assume_tac o SIMP_RULE (srw_ss()) [Once type_ds_cases]) >>
 fs [empty_decls_def] >>
 rw [] >>
 every_case_tac >>
 rw [] >>
 fs [type_d_cases] >>
 rw [] >>
 PairCases_on `decls''` >>
 fs [empty_decls_def, union_decls_def] >>
 rw []
 >- metis_tac []
 >- metis_tac []
 >- metis_tac [] >>
 res_tac >> 
 rw [] >>
 fs [DISJOINT_DEF, EXTENSION] >>
 metis_tac []);

val type_ds_no_dup_types = Q.prove (
`!mn decls tenvM tenvC tenv ds decls' tenvC' tenv'.
  type_ds mn decls tenvM tenvC tenv ds decls' tenvC' tenv'
  ⇒
  no_dup_types ds`,
 induct_on `ds` >>
 rw [no_dup_types_def] >>
 pop_assum (assume_tac o SIMP_RULE (srw_ss()) [Once type_ds_cases]) >>
 fs [] >>
 rw [] >>
 fs [no_dup_types_def, type_d_cases, decs_to_types_def] >>
 rw [ALL_DISTINCT_APPEND]
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- fs [check_ctor_tenv_def, LAMBDA_PROD]
 >- metis_tac []
 >- (fs [union_decls_def] >>
     PairCases_on `decls'''` >>
     imp_res_tac type_ds_no_dup_types_helper >>
     rw [] >>
     fs [DISJOINT_DEF, EXTENSION, METIS_PROVE [] ``P ∨ Q ⇔ ¬P ⇒ Q``] >>
     `MEM (mk_id mn e) (MAP (λ(tvs,tn,ctors). mk_id mn tn) tdefs)`
               by (fs [MEM_MAP] >>
                   qexists_tac `y` >>
                   rw [] >>
                   PairCases_on `y` >>
                   rw []) >>
     res_tac >>
     ntac 2 (pop_assum (fn _ => all_tac)) >>
     pop_assum mp_tac >>
     rpt (pop_assum (fn _ => all_tac)) >>
     rw [MEM_FLAT, MEM_MAP] >>
     CCONTR_TAC >>
     fs [] >>
     rw [] >>
     every_case_tac >>
     fs [MEM_MAP] >>
     rw [] >>
     FIRST_X_ASSUM (qspecl_then [`MAP (mk_id mn o FST o SND) l`] mp_tac) >>
     rw [] 
     >- (qexists_tac `Dtype l` >>
         rw [LAMBDA_PROD, combinTheory.o_DEF])
     >- (rw [combinTheory.o_DEF, MEM_MAP, EXISTS_PROD] >>
         rw [LAMBDA_PROD] >>
         PairCases_on `y` >>
         fs [] >>
         metis_tac []))
 >- metis_tac []);

val top_type_soundness = Q.store_thm ("top_type_soundness",
`!decls1 tenvM tenvC tenv envM envC envE count store1 decls1' tenvM' tenvC' tenv' top decls2.
  type_sound_invariants (decls1,tenvM,tenvC,tenv,decls2,envM,envC,envE,store1) ∧
  type_top decls1 tenvM tenvC tenv top decls1' tenvM' tenvC' tenv' ∧
  ¬top_diverges (envM, envC, envE) (store1,decls2, FST decls1) top ⇒
  ?r cenv2 store2 decls2'. 
    (r ≠ Rerr Rtype_error) ∧
    evaluate_top F (envM, envC, envE) ((count,store1),decls2,FST decls1) top (((count,store2),decls2',FST decls1' ∪ FST decls1),cenv2,r) ∧
    type_sound_invariants (update_type_sound_inv (decls1,tenvM,tenvC,tenv,decls2,envM,envC,envE,store1) decls1' tenvM' tenvC' tenv' store2 decls2' cenv2 r)`,
 rw [type_sound_invariants_def] >>
 `num_tvs tenv = 0` by metis_tac [type_v_freevars] >>
 fs [type_top_cases, top_diverges_cases] >>
 rw [evaluate_top_cases]
 >- (`weak_decls_other_mods NONE decls_no_sig decls1` 
              by (PairCases_on `decls_no_sig` >>
                  PairCases_on `decls1` >>
                  fs [weak_decls_other_mods_def, weak_decls_only_mods_def, mk_id_def] >>
                  metis_tac []) >>
     `type_d NONE decls_no_sig tenvM_no_sig tenvC_no_sig tenv d decls1' cenv' tenv'` 
                  by metis_tac [weak_decls_refl,weak_decls_other_mods_refl, type_d_weakening, consistent_con_env_def] >>
     `decs_type_sound_invariant NONE decls_no_sig decls2 ctMap tenvS tenvM_no_sig tenvC_no_sig tenv store1 envM envC envE` 
                  by (rw [decs_type_sound_invariant_def] >>
                      metis_tac [consistent_con_env_def]) >>
     `?r store2 tenvS' decls2'.
        r ≠ Rerr Rtype_error ∧
        evaluate_dec F NONE (envM, envC, envE) ((count',store1),decls2) d (((count',store2),decls2'),r) ∧
        consistent_decls decls2' (union_decls decls1' decls_no_sig) ∧
        store_type_extension tenvS tenvS' ∧
        type_s ctMap tenvS' store2 ∧
        ∀cenv1 env1.
         (r = Rval (cenv1,env1)) ⇒
         MAP FST cenv1 = MAP FST cenv' ∧
         consistent_ctMap (union_decls decls1' decls_no_sig) (flat_to_ctMap cenv' ⊌ ctMap) ∧
         consistent_con_env (FUNION (flat_to_ctMap cenv') ctMap) (merge_envC (emp,cenv1) envC) (merge_tenvC (emp,cenv') tenvC_no_sig) ∧
         type_env (FUNION (flat_to_ctMap cenv') ctMap) tenvS' (env1 ++ envE) (bind_var_list2 tenv' tenv) ∧
         type_env (FUNION (flat_to_ctMap cenv') ctMap) tenvS' env1 (bind_var_list2 tenv' Empty)`
                by metis_tac [dec_type_soundness] >>
     `(?err. r = Rerr err) ∨ (?cenv1 env1. r = Rval (cenv1,env1))` 
                by (cases_on `r` >> metis_tac [pair_CASES]) >>
     rw []
     >- (MAP_EVERY qexists_tac [`Rerr err`, `(emp,emp)`, `store2`, `decls2'`] >>
         rw [type_sound_invariants_def, update_type_sound_inv_def]
         >- (imp_res_tac type_d_mod >>
             fs []) >>
         MAP_EVERY qexists_tac [`ctMap`, `tenvS'`, `union_decls decls1' decls_no_sig`, `tenvM_no_sig`, `tenvC_no_sig`] >>
         rw [emp_def]
         >- metis_tac [consistent_ctMap_weakening, type_d_mod, weak_decls_union2]
         >- metis_tac [type_v_weakening, store_type_extension_weakS, weakCT_refl, consistent_con_env_def]
         >- metis_tac [type_v_weakening, store_type_extension_weakS, weakCT_refl, consistent_con_env_def]
         >- (imp_res_tac type_d_mod >>
             PairCases_on `decls1'` >>
             PairCases_on `decls_no_sig` >>
             fs [decls_ok_def, union_decls_def, decls_to_mods_def, SUBSET_DEF, EXTENSION] >>
             fs [GSPECIFICATION] >>
             metis_tac [])
         >- metis_tac [weak_decls_union]
         >- metis_tac [weak_decls_only_mods_union])
     >- (MAP_EVERY qexists_tac [`Rval (emp,env1)`,`(emp,cenv1)`, `store2`, `decls2'`] >>
         rw [type_sound_invariants_def, update_type_sound_inv_def]
         >- (imp_res_tac type_d_mod >>
             fs []) >>
         `weakCT (FUNION (flat_to_ctMap cenv') ctMap) ctMap`
                    by metis_tac [merge_def, disjoint_env_weakCT, type_d_ctMap_disjoint] >>
         MAP_EVERY qexists_tac [`FUNION (flat_to_ctMap cenv') ctMap`, `tenvS'`, `union_decls decls1' decls_no_sig`, `tenvM_no_sig`, `merge_tenvC ([],cenv') tenvC_no_sig`] >>
         rw [emp_def]
         >- metis_tac [still_has_exns, type_d_ctMap_disjoint]
         >- metis_tac [type_v_weakening, store_type_extension_weakS, consistent_con_env_def, weakCT_refl]
         >- metis_tac [emp_def]
         >- metis_tac [type_s_weakening, weakM_refl, consistent_con_env_def]
         >- metis_tac [weakC_merge]
         >- (imp_res_tac type_d_mod >>
             PairCases_on `decls1'` >>
             PairCases_on `decls_no_sig` >>
             fs [GSPECIFICATION, decls_ok_def, union_decls_def, decls_to_mods_def, SUBSET_DEF, EXTENSION] >>
             metis_tac [])
         >- metis_tac [weak_decls_union]
         >- metis_tac [weak_decls_only_mods_union]))
 >- metis_tac [type_ds_no_dup_types]
 >- (`weak_decls_other_mods (SOME mn) decls_no_sig (mdecls,tdecls,edecls)` 
                     by (PairCases_on `decls_no_sig` >>
                         fs [weak_decls_def, weak_decls_other_mods_def] >>
                         CCONTR_TAC >>
                         fs [decls_to_mods_def, decls_ok_def, mk_id_def, SUBSET_DEF, GSPECIFICATION] >>
                         metis_tac [NOT_SOME_NONE, SOME_11]) >>
     `type_ds (SOME mn) decls_no_sig tenvM_no_sig tenvC_no_sig tenv ds decls' cenv' tenv''`
                  by metis_tac [type_ds_weakening, consistent_con_env_def] >>
     `decs_type_sound_invariant (SOME mn) decls_no_sig decls2 ctMap tenvS tenvM_no_sig tenvC_no_sig tenv store1 envM envC envE` 
                  by (rw [decs_type_sound_invariant_def] >>
                      PairCases_on `decls_no_sig` >>
                      fs [weak_decls_def] >>
                      metis_tac [consistent_con_env_def]) >>
     `?store2 r cenv2 tenvS' tdecs2'.
        r ≠ Rerr Rtype_error ∧
        evaluate_decs F (SOME mn) (envM, envC, envE) ((count',store1),decls2) ds (((count',store2),tdecs2'),cenv2,r) ∧
        consistent_decls tdecs2' (union_decls decls' decls_no_sig) ∧
        store_type_extension tenvS tenvS' ∧
        (∀err.
           r = Rerr err ⇒
           ∃tenvC1 tenvC2.
             cenv' = tenvC1 ++ tenvC2 ∧
             type_s (FUNION (flat_to_ctMap tenvC2) ctMap) tenvS' store2 ∧
             consistent_ctMap (union_decls decls' decls_no_sig) (FUNION (flat_to_ctMap tenvC2) ctMap) ∧
             consistent_con_env (FUNION (flat_to_ctMap tenvC2) ctMap) (merge_envC (emp,cenv2) envC) (merge_tenvC (emp,tenvC2) tenvC_no_sig)) ∧
        (∀env'.
           r = Rval env' ⇒
           MAP FST cenv' = MAP FST cenv2 ∧
           type_s (FUNION (flat_to_ctMap cenv') ctMap) tenvS' store2 ∧
           consistent_ctMap (union_decls decls' decls_no_sig) (FUNION (flat_to_ctMap cenv') ctMap) ∧
           consistent_con_env (FUNION (flat_to_ctMap cenv') ctMap) (merge_envC (emp,cenv2) envC) (merge_tenvC (emp,cenv') tenvC_no_sig) ∧
           type_env (FUNION (flat_to_ctMap cenv') ctMap) tenvS' env' (bind_var_list2 tenv'' Empty) ∧
           type_env (FUNION (flat_to_ctMap cenv') ctMap) tenvS' (env' ++ envE) (bind_var_list2 tenv'' tenv))`
                      by metis_tac [decs_type_soundness] >>
     `(?err. r = Rerr err) ∨ (?env2. r = Rval env2)` 
                by (cases_on `r` >> metis_tac []) >>
     rw []
     >- (MAP_EVERY qexists_tac [`Rerr err`, `([(mn,cenv2)],emp)`, `store2`, `tdecs2'`] >>
         rw [type_sound_invariants_def, update_type_sound_inv_def] 
         >- (imp_res_tac type_ds_mod >>
             fs [check_signature_cases] >>
             imp_res_tac type_specs_no_mod >>
             rw [] >>
             fs []) >>
         `DISJOINT (FDOM (flat_to_ctMap (tenvC1++tenvC2))) (FDOM ctMap)`
                      by metis_tac [type_ds_ctMap_disjoint] >>
         `DISJOINT (FDOM (flat_to_ctMap tenvC2)) (FDOM ctMap)`
                      by (fs [flat_to_ctMap_append]) >>
         `weakCT (FUNION (flat_to_ctMap tenvC2) ctMap) ctMap` 
                      by (match_mp_tac disjoint_env_weakCT >>
                          rw [] >>
                          fs []) >>
         `flat_tenvC_ok tenvC2` by metis_tac [type_ds_tenvC_ok, flat_tenvC_ok_def, EVERY_APPEND, merge_def] >>
         `ctMap_ok (FUNION (flat_to_ctMap tenvC2) ctMap)` 
                    by (match_mp_tac ctMap_ok_merge_imp >>
                        metis_tac [flat_tenvC_ok_ctMap, consistent_con_env_def])
         >- metis_tac [type_ds_no_dup_types] >>
         MAP_EVERY qexists_tac [`FUNION (flat_to_ctMap tenvC2) ctMap`, `tenvS'`, `(union_decls (union_decls ({mn},{},{})decls') decls_no_sig)`,
                                `tenvM_no_sig`, `tenvC_no_sig`] >>
         rw []
         >- (rw [GSYM union_decls_assoc] >>
             `?x y z. union_decls decls' decls_no_sig = (x,y,z)` by metis_tac [pair_CASES] >>
             rw [union_decls_def] >>
             metis_tac [consistent_decls_add_mod])
         >- (PairCases_on `decls_no_sig` >>
             PairCases_on `decls'` >>
             fs [consistent_ctMap_def, union_decls_def])
         >- metis_tac [still_has_exns]
         >- metis_tac [type_v_weakening, store_type_extension_weakS]
         >- metis_tac [consistent_con_env_weakening]
         >- metis_tac [type_v_weakening, store_type_extension_weakS]
         >- (imp_res_tac type_ds_mod >>
             PairCases_on `decls'` >>
             PairCases_on `decls_no_sig` >>
             fs [GSPECIFICATION, decls_ok_def, union_decls_def, decls_to_mods_def, SUBSET_DEF, EXTENSION] >>
             metis_tac [])
         >- (PairCases_on `decls_no_sig` >>
             PairCases_on `decls'` >>
             fs [check_signature_cases, union_decls_def, weak_decls_def, SUBSET_DEF])
         >- (PairCases_on `decls_no_sig` >>
             PairCases_on `decls'` >>
             fs [weak_decls_def, check_signature_cases, union_decls_def, weak_decls_only_mods_def, SUBSET_DEF,
                 mk_id_def, weak_decls_other_mods_def]
             >- metis_tac [] >>
             imp_res_tac type_ds_mod >>
             fs [decls_to_mods_def, SUBSET_DEF, GSPECIFICATION] >>
             metis_tac [SOME_11, NOT_SOME_NONE]))
     >- (MAP_EVERY qexists_tac [`Rval ([(mn,env2)],emp)`, `([(mn,cenv2)],emp)`, `store2`, `tdecs2'`] >>
         rw [type_sound_invariants_def, update_type_sound_inv_def]
         >- (imp_res_tac type_ds_mod >>
             fs [check_signature_cases] >>
             imp_res_tac type_specs_no_mod >>
             rw [] >>
             fs []) >>
         `DISJOINT (FDOM (flat_to_ctMap cenv')) (FDOM ctMap)`
                      by metis_tac [type_ds_ctMap_disjoint] >>
         `weakCT (FUNION (flat_to_ctMap cenv') ctMap) ctMap` 
                      by (match_mp_tac disjoint_env_weakCT >>
                          rw [] >>
                          fs []) >>
         `flat_tenvC_ok cenv'` by metis_tac [type_ds_tenvC_ok, flat_tenvC_ok_def, EVERY_APPEND, merge_def] >>
         `ctMap_ok (FUNION (flat_to_ctMap cenv') ctMap)`
                    by (match_mp_tac ctMap_ok_merge_imp >>
                        metis_tac [flat_tenvC_ok_ctMap, consistent_con_env_def]) >>
         `tenvM_ok (bind mn tenv'' tenvM_no_sig)`
                   by metis_tac [tenvM_ok_pres, type_v_freevars] >>
         `tenv_ok (bind_var_list2 emp Empty)`
                      by (metis_tac [emp_def, tenv_ok_def, bind_var_list2_def]) >>
         `tenv_ok (bind_var_list2 tenv''' Empty)`
                      by (fs [check_signature_cases] >>
                          metis_tac [type_v_freevars, type_specs_tenv_ok])
         >- metis_tac [type_ds_no_dup_types] >>
         MAP_EVERY qexists_tac [`flat_to_ctMap cenv' ⊌ ctMap`, `tenvS'`, `(union_decls (union_decls ({mn},{},{})decls') decls_no_sig)`,
                                `(mn,tenv'')::tenvM_no_sig`, `merge_tenvC ([(mn,cenv')],emp) tenvC_no_sig`] >>
         rw []
         >- (rw [GSYM union_decls_assoc] >>
             `?x y z. union_decls decls' decls_no_sig = (x,y,z)` by metis_tac [pair_CASES] >>
             rw [union_decls_def] >>
             metis_tac [consistent_decls_add_mod])
         >- (PairCases_on `decls_no_sig` >>
             PairCases_on `decls'` >>
             fs [consistent_ctMap_def, union_decls_def])
         >- metis_tac [still_has_exns]
         >- metis_tac [tenvM_ok_pres, bind_def]
         >- metis_tac [tenvM_ok_pres, bind_def]
         >- (rw [bind_def, Once type_v_cases] >>
             metis_tac [type_v_weakening,store_type_extension_weakS, weakM_bind,
                        weakM_refl, bind_def, merge_def, disjoint_env_weakCT, DISJOINT_SYM])
         >- metis_tac [emp_def, consistent_con_env_to_mod, consistent_con_env_weakening]
         >- (rw [emp_def, bind_var_list2_def] >>
             metis_tac [merge_def, type_v_weakening,store_type_extension_weakS])
         >- (`weakE tenv'' tenv'''` by (fs [check_signature_cases] >> metis_tac [weakE_refl]) >>
             metis_tac [bind_def, weakM_bind'])
         >- (fs [check_signature_cases] >>
             metis_tac [weakC_merge_one_mod2, flat_weakC_refl, emp_def])
         >- (imp_res_tac type_ds_mod >>
             PairCases_on `decls'` >>
             PairCases_on `decls_no_sig` >>
             fs [GSPECIFICATION, decls_ok_def, union_decls_def, decls_to_mods_def, SUBSET_DEF, EXTENSION] >>
             metis_tac [])
         >- (PairCases_on `decls_no_sig` >>
             PairCases_on `decls'` >>
             fs [check_signature_cases, union_decls_def, weak_decls_def, SUBSET_DEF])
         >- (PairCases_on `decls_no_sig` >>
             PairCases_on `decls'` >>
             fs [weak_decls_def, check_signature_cases, union_decls_def, weak_decls_only_mods_def, SUBSET_DEF,
                 mk_id_def, weak_decls_other_mods_def]
             >- metis_tac [] >>
             imp_res_tac type_ds_mod >>
             fs [decls_to_mods_def, SUBSET_DEF, GSPECIFICATION] >>
             metis_tac [SOME_11, NOT_SOME_NONE]))));

val FST_union_decls = Q.prove (
`!d1 d2. FST (union_decls d1 d2) = FST d1 ∪ FST d2`,
 rw [] >>
 PairCases_on `d1` >>
 PairCases_on `d2` >>
 rw [union_decls_def]);

val prog_type_soundness = Q.store_thm ("prog_type_soundness",
`!decls1 tenvM tenvC tenv envM envC envE count store1 decls1' tenvM' tenvC' tenv' prog decls2.
  type_sound_invariants (decls1,tenvM,tenvC,tenv,decls2,envM,envC,envE,store1) ∧
  type_prog decls1 tenvM tenvC tenv prog decls1' tenvM' tenvC' tenv' ∧
  ¬prog_diverges (envM, envC, envE) (store1,decls2, FST decls1) prog ⇒
  ?cenv2 store2 decls2'. 
    (?envM2 envE2.
      evaluate_prog F (envM, envC, envE) ((count,store1),decls2,FST decls1) prog (((count,store2),decls2',FST decls1' ∪ FST decls1),cenv2,Rval (envM2,envE2)) ∧
      type_sound_invariants (update_type_sound_inv (decls1,tenvM,tenvC,tenv,decls2,envM,envC,envE,store1) decls1' tenvM' tenvC' tenv' store2 decls2' cenv2 (Rval (envM2,envE2)))) ∨
    (?err mods.
      err ≠ Rtype_error ∧
      mods ⊆ FST decls1' ∧
      evaluate_prog F (envM, envC, envE) ((count,store1),decls2,FST decls1) prog (((count,store2),decls2',mods ∪ FST decls1),cenv2,Rerr err))`,
 induct_on `prog` >>
 rw [] >>
 ONCE_REWRITE_TAC [evaluate_prog_cases] >>
 qpat_assum `type_prog x0 x1 x2 x3 x4 x5 x6 x7 x8` mp_tac  >>
 simp_tac (srw_ss()) [Once type_prog_cases, EXISTS_OR_THM]
 >- (rw [update_type_sound_inv_def, empty_decls_def, emp_def] >>
     PairCases_on `tenvC` >>
     PairCases_on `envC` >>
     PairCases_on `decls1` >>
     rw [union_decls_def, merge_tenvC_def,merge_envC_def, merge_def, bind_var_list2_def]) >>
 rw [] >>
 qpat_assum `~(prog_diverges x0 x1 x2)` mp_tac >>
 rw [Once prog_diverges_cases] >>
 `?r cenv2 store2 decls2'.
    r ≠ Rerr Rtype_error ∧
    evaluate_top F (envM,envC,envE) ((count',store1),decls2,FST decls1) h
        (((count',store2),decls2',FST decls' ∪ FST decls1),cenv2,r) ∧
    type_sound_invariants
        (update_type_sound_inv
           (decls1,tenvM,tenvC,tenv,decls2,envM,envC,envE,store1) decls'
           menv' cenv' tenv'' store2 decls2' cenv2 r)`
                 by metis_tac [top_type_soundness] >>
 pop_assum (mp_tac o SIMP_RULE (srw_ss()) [update_type_sound_inv_def]) >>
 rw [] >>
 `(?envM' env'. r = Rval (envM',env')) ∨ (?err. r = Rerr err)` 
            by (cases_on `r` >>
                fs [] >>
                cases_on `a` >>
                fs []) >>
 rw [] >>
 fs []
 >- (`∃cenv2' store2' decls2''.
        (∃envM2 envE2.
           evaluate_prog F
             (envM' ++ envM,merge_envC cenv2 envC,env' ++ envE)
             ((count',store2),decls2',FST (union_decls decls' decls1)) prog
             (((count',store2'),decls2'',
               FST decls'' ∪ FST (union_decls decls' decls1)),cenv2',
              Rval (envM2,envE2)) ∧
           type_sound_invariants
             (update_type_sound_inv
                (union_decls decls' decls1,menv' ++ tenvM,
                 merge_tenvC cenv' tenvC,bind_var_list2 tenv'' tenv,
                 decls2',envM' ++ envM,merge_envC cenv2 envC,
                 env' ++ envE,store2) decls'' menv'' cenv'' tenv'''
                store2' decls2'' cenv2' (Rval (envM2,envE2)))) ∨
        ∃err mods.
          err ≠ Rtype_error ∧ mods ⊆ FST decls'' ∧
          evaluate_prog F
            (envM' ++ envM,merge_envC cenv2 envC,env' ++ envE)
            ((count',store2),decls2',FST (union_decls decls' decls1)) prog
            (((count',store2'),decls2'',mods ∪ FST (union_decls decls' decls1)),
             cenv2',Rerr err)`
                 by metis_tac [merge_def, FST_union_decls]
     >- (disj1_tac >>
         Q.LIST_EXISTS_TAC [`merge_envC cenv2' cenv2`, `store2'`, `decls2''`, `merge envM2 envM'`, `merge envE2 env'`] >>
         rw [SUBSET_UNION] 
         >- (Q.LIST_EXISTS_TAC [`((count',store2),decls2',FST decls' ∪ FST decls1)`, `envM'`, `cenv2`, `cenv2'`, `env'`, `Rval (envM2, envE2)`] >>
             rw [combine_mod_result_def] >>
             metis_tac [UNION_ASSOC, merge_def, FST_union_decls])
         >- (fs [update_type_sound_inv_def] >>
             fs [combine_mod_result_def, merge_def, union_decls_assoc, merge_envC_assoc, merge_tenvC_assoc, bvl2_append]))
     >- (disj2_tac >>
         Q.LIST_EXISTS_TAC [`merge_envC cenv2' cenv2`, `store2'`, `decls2''`, `err`, `mods ∪ FST decls'`] >>
         rw [FST_union_decls]
         >- fs [SUBSET_DEF] >>
         disj1_tac >>
         Q.LIST_EXISTS_TAC [`((count',store2),decls2',FST decls' ∪ FST decls1)`, `envM'`, `cenv2`, `cenv2'`, `env'`, `Rerr err`] >>
         fs [combine_mod_result_def, merge_def, FST_union_decls, UNION_ASSOC]))
 >- (disj2_tac >>
     Q.LIST_EXISTS_TAC [`cenv2`, `store2`, `decls2'`, `err`] >>
     rw [] >>
     qexists_tac `FST decls'` >>
     rw [FST_union_decls]));

val type_no_dup_top_types_lem = Q.prove (
`!decls1 tenvM tenvC tenv prog decls1' tenvM' tenvC' tenv'.
  type_prog decls1 tenvM tenvC tenv prog decls1' tenvM' tenvC' tenv'
  ⇒
  ALL_DISTINCT (prog_to_top_types prog) ∧
  DISJOINT (FST (SND decls1)) (IMAGE (mk_id NONE) (set (prog_to_top_types prog)))`,
 ho_match_mp_tac type_prog_ind >>
 rw [prog_to_top_types_def] >>
 every_case_tac >>
 rw [] >>
 fs [type_top_cases] >>
 rw [ALL_DISTINCT_APPEND, empty_decls_def]
 >- (fs [type_d_cases, decs_to_types_def] >>
     rw [] >>
     fs [check_ctor_tenv_def] >>
     fs [LAMBDA_PROD])
 >- (`mk_id NONE e ∈ FST (SND decls')`
            by (fs [type_d_cases, decs_to_types_def] >>
                rw [] >>
                fs [mk_id_def] >>
                fs [MEM_MAP, LAMBDA_PROD, EXISTS_PROD] >>
                metis_tac []) >>
     PairCases_on `decls'` >>
     PairCases_on `decls1` >>
     fs [union_decls_def, DISJOINT_DEF, EXTENSION] >>
     metis_tac [])
 >- (rw [decs_to_types_def] >>
     fs [type_d_cases] >>
     rw [] >>
     fs [DISJOINT_DEF, EXTENSION] >>
     rw [] >>
     fs [MEM_MAP,LAMBDA_PROD, EXISTS_PROD, mk_id_def, FORALL_PROD] >>
     metis_tac [])
 >- (fs [union_decls_def, DISJOINT_DEF, EXTENSION] >>
     rw [] >>
     fs [MEM_MAP,LAMBDA_PROD, EXISTS_PROD, mk_id_def, FORALL_PROD] >>
     metis_tac [])
 >- (PairCases_on `decls1` >>
     fs [type_d_cases, empty_decls_def] >>
     rw [] >>
     fs [DISJOINT_DEF, EXTENSION, union_decls_def] >>
     rw [] >>
     fs [MEM_MAP,LAMBDA_PROD, EXISTS_PROD, mk_id_def, FORALL_PROD] >>
     metis_tac []));

val type_no_dup_top_types_lem2 = Q.prove (
`!decls1 tenvM tenvC tenv prog decls1' tenvM' tenvC' tenv'.
  type_prog decls1 tenvM tenvC tenv prog decls1' tenvM' tenvC' tenv'
  ⇒
  no_dup_top_types prog (x,IMAGE TypeId (FST (SND decls1)),y)`,
 rw [no_dup_top_types_def]
 >- metis_tac [type_no_dup_top_types_lem] >>
 imp_res_tac type_no_dup_top_types_lem >>
 fs [DISJOINT_DEF, EXTENSION] >>
 rw [] >>
 cases_on `x` >>
 rw [MEM_MAP] >>
 fs [mk_id_def] >>
 metis_tac []);

val type_no_dup_top_types = Q.prove (
`!decls1 tenvM tenvC tenv prog decls1' tenvM' tenvC' tenv'.
  type_prog decls1 tenvM tenvC tenv prog decls1' tenvM' tenvC' tenv' ∧
  consistent_decls decls2 decls_no_sig ∧
  weak_decls_only_mods decls_no_sig decls1
  ⇒
  no_dup_top_types prog (x,decls2,y)`,
 rw [] >>
 `no_dup_top_types prog (x,IMAGE TypeId (FST (SND decls1)),y)`
         by metis_tac [type_no_dup_top_types_lem2] >>
 fs [no_dup_top_types_def] >>
 PairCases_on `decls_no_sig` >>
 PairCases_on `decls1` >>
 fs [RES_FORALL, DISJOINT_DEF, SUBSET_DEF, EXTENSION, weak_decls_only_mods_def, consistent_decls_def] >>
 rw [] >>
 CCONTR_TAC >>
 fs [] >>
 res_tac >>
 every_case_tac >>
 fs [MEM_MAP] >>
 rw [] >>
 metis_tac [])

val type_no_dup_mods_lem = Q.prove (
`!decls1 tenvM tenvC tenv prog decls1' tenvM' tenvC' tenv'.
  type_prog decls1 tenvM tenvC tenv prog decls1' tenvM' tenvC' tenv'
  ⇒
  ALL_DISTINCT (prog_to_mods prog) ∧
  DISJOINT (FST decls1) (set (prog_to_mods prog))`,
 ho_match_mp_tac type_prog_ind >>
 rw [prog_to_mods_def] >>
 every_case_tac >>
 rw [] >>
 fs [type_top_cases] >>
 rw [ALL_DISTINCT_APPEND, empty_decls_def]
 >- (fs [union_decls_def, DISJOINT_DEF, EXTENSION] >>
     metis_tac [])
 >- (fs [union_decls_def, DISJOINT_DEF, EXTENSION] >>
     metis_tac [])
 >- (PairCases_on `decls'` >>
     PairCases_on `decls1` >>
     fs [union_decls_def, DISJOINT_DEF, EXTENSION] >>
     metis_tac []));

val type_no_dup_mods = Q.prove (
`!decls1 tenvM tenvC tenv prog decls1' tenvM' tenvC' tenv'.
  type_prog decls1 tenvM tenvC tenv prog decls1' tenvM' tenvC' tenv'
  ⇒
  no_dup_mods prog (x, y, FST decls1)`,
 rw [no_dup_mods_def] >>
 metis_tac [type_no_dup_mods_lem, DISJOINT_SYM]);

val whole_prog_type_soundness = Q.store_thm ("whole_prog_type_soundness",
`!decls1 tenvM tenvC tenv envM envC envE count store1 decls1' tenvM' tenvC' tenv' prog decls2.
  type_sound_invariants (decls1,tenvM,tenvC,tenv,decls2,envM,envC,envE,store1) ∧
  type_prog decls1 tenvM tenvC tenv prog decls1' tenvM' tenvC' tenv' ∧
  ¬prog_diverges (envM, envC, envE) (store1,decls2, FST decls1) prog ⇒
  ?cenv2 store2 decls2'. 
    (?envM2 envE2.
      evaluate_whole_prog F (envM, envC, envE) ((count,store1),decls2,FST decls1) prog (((count,store2),decls2',FST decls1' ∪ FST decls1),cenv2,Rval (envM2,envE2)) ∧
      type_sound_invariants (update_type_sound_inv (decls1,tenvM,tenvC,tenv,decls2,envM,envC,envE,store1) decls1' tenvM' tenvC' tenv' store2 decls2' cenv2 (Rval (envM2,envE2)))) ∨
    (?err mods.
      err ≠ Rtype_error ∧
      mods ⊆ FST decls1' ∧
      evaluate_prog F (envM, envC, envE) ((count,store1),decls2,FST decls1) prog (((count,store2),decls2',mods ∪ FST decls1),cenv2,Rerr err))`,
 rw [evaluate_whole_prog_def] >>
 imp_res_tac prog_type_soundness >>
 pop_assum (assume_tac o Q.SPEC `count'`) >>
 fs []
 >- metis_tac [type_no_dup_top_types, type_sound_invariants_def, type_no_dup_mods]
 >- metis_tac []);

val _ = export_theory ();
