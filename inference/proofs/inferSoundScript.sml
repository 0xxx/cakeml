open preamble;
open rich_listTheory;
open miscTheory;
open libTheory typeSystemTheory astTheory semanticPrimitivesTheory terminationTheory inferTheory unifyTheory;
open libPropsTheory astPropsTheory;
open initialEnvTheory;
open inferPropsTheory;
open typeSysPropsTheory;

val o_f_id = Q.prove (
`!m. (\x.x) o_f m = m`,
rw [fmap_EXT]);

val _ = new_theory "inferSound";

(* ---------- Converting infer types and envs to type system ones ---------- *)

val convert_t_def = tDefine "convert_t" `
(convert_t (Infer_Tvar_db n) = Tvar_db n) ∧
(convert_t (Infer_Tapp ts tc) = Tapp (MAP convert_t ts) tc)`
(WF_REL_TAC `measure infer_t_size` >>
 rw [] >>
 induct_on `ts` >>
 rw [infer_t_size_def] >>
 res_tac >>
 decide_tac);

val convert_menv_def = Define `
convert_menv menv = 
  MAP (\(mn,env). (mn, MAP (\(x,(tvs,t)). (x,(tvs,convert_t t))) env)) menv`;

val convert_env_def = Define `
convert_env s env = MAP (\(x,t). (x, convert_t (t_walkstar s t))) env`;

val check_convert_freevars = Q.prove (
`(!tvs uvs t. check_t tvs uvs t ⇒ (uvs = {}) ⇒ check_freevars tvs [] (convert_t t))`,
ho_match_mp_tac check_t_ind >>
rw [check_freevars_def, check_t_def, convert_t_def] >>
fs [EVERY_MEM, MEM_MAP] >>
metis_tac []);

val check_t_to_check_freevars = Q.store_thm ("check_t_to_check_freevars",
`!tvs (n:num set) t. check_t tvs {} t ⇒ check_freevars tvs [] (convert_t t)`,
ho_match_mp_tac check_t_ind >>
rw [check_t_def, check_freevars_def, convert_t_def, EVERY_MAP] >>
fs [EVERY_MEM]);

val convert_inc = Q.prove (
`!t tvs tvs'. 
  check_t tvs' {} t
  ⇒
  (convert_t (infer_deBruijn_inc tvs t) = deBruijn_inc 0 tvs (convert_t t))`,
ho_match_mp_tac (fetch "-" "convert_t_ind") >>
rw [check_t_def, convert_t_def, infer_deBruijn_inc_def, deBruijn_inc_def] >>
induct_on `ts` >>
fs [] >>
metis_tac []);

val db_subst_infer_subst_swap = Q.prove (
`(!t s tvs uvar n.
  t_wfs s ∧
  count (uvar + tvs) ⊆ FDOM s ∧
  (!uv. uv ∈ FDOM s ⇒ check_t n {} (t_walkstar s (Infer_Tuvar uv))) ∧
  check_t tvs (FDOM s) t
  ⇒
  (convert_t
    (t_walkstar s
       (infer_deBruijn_subst
          (MAP (λn. Infer_Tuvar (uvar + n)) (COUNT_LIST tvs))
          t)) =
   deBruijn_subst 0
    (MAP (convert_t o t_walkstar s)
       (MAP (λn. Infer_Tuvar (uvar + n)) (COUNT_LIST tvs)))
    (convert_t (t_walkstar (infer_deBruijn_inc tvs o_f s) t)))) ∧
 (!ts s tvs uvar n.
  t_wfs s ∧
  count (uvar + tvs) ⊆ FDOM s ∧
  (!uv. uv ∈ FDOM s ⇒ check_t n {} (t_walkstar s (Infer_Tuvar uv))) ∧
  EVERY (\t. check_t tvs (FDOM s) t) ts ⇒
  (MAP (convert_t o
       t_walkstar s o
       infer_deBruijn_subst (MAP (λn. Infer_Tuvar (uvar + n)) (COUNT_LIST tvs)))
      ts =
   MAP (deBruijn_subst 0 (MAP (convert_t o t_walkstar s) (MAP (λn. Infer_Tuvar (uvar + n)) (COUNT_LIST tvs))) o
       convert_t o 
       t_walkstar (infer_deBruijn_inc tvs o_f s))
      ts))`,
ho_match_mp_tac infer_t_induction >>
rw [convert_t_def, deBruijn_subst_def, EL_MAP, t_walkstar_eqn1,
    infer_deBruijn_subst_def, MAP_MAP_o, combinTheory.o_DEF, check_t_def,
    LENGTH_COUNT_LIST] >|
[`t_wfs (infer_deBruijn_inc tvs o_f s)` by metis_tac [inc_wfs] >>
     fs [t_walkstar_eqn1, convert_t_def, deBruijn_subst_def,
         LENGTH_COUNT_LIST] >>
     fs [LENGTH_MAP, el_map_count, EL_COUNT_LIST],
 `t_wfs (infer_deBruijn_inc tvs o_f s)` by metis_tac [inc_wfs] >>
     fs [t_walkstar_eqn1, convert_t_def, deBruijn_subst_def, MAP_MAP_o, 
         combinTheory.o_DEF] >>
     metis_tac [],
 res_tac >>
     imp_res_tac convert_inc >>
     rw [walkstar_inc2] >>
     metis_tac [subst_inc_cancel, arithmeticTheory.ADD,
                deBruijn_inc0,
                LENGTH_COUNT_LIST, LENGTH_MAP],
 metis_tac [],
 metis_tac []]);

val inc_convert_t = Q.prove (
`(!t tvs' tvs. check_t tvs' {} t ⇒ (deBruijn_inc tvs' tvs (convert_t t) = convert_t t)) ∧
 (!ts tvs' tvs. EVERY (check_t tvs' {}) ts ⇒ (MAP (deBruijn_inc tvs' tvs o convert_t) ts = MAP convert_t ts))`,
ho_match_mp_tac infer_t_induction >>
rw [check_t_def, convert_t_def, deBruijn_inc_def] >>
metis_tac [MAP_MAP_o]);

val convert_t_subst = Q.prove (
`(!t tvs ts'. 
    (LENGTH tvs = LENGTH ts') ∧
    check_freevars 0 tvs t ⇒
    convert_t (infer_type_subst (ZIP (tvs,ts')) t) = 
    type_subst (ZIP (tvs, MAP convert_t ts')) t) ∧
 (!ts tvs ts'. 
    (LENGTH tvs = LENGTH ts') ∧
    EVERY (check_freevars 0 tvs) ts ⇒
    MAP convert_t (MAP (infer_type_subst (ZIP (tvs,ts'))) ts) = 
    MAP (type_subst (ZIP (tvs, MAP convert_t ts'))) ts)`,
ho_match_mp_tac t_induction >>
rw [check_freevars_def, convert_t_def, type_subst_def, infer_type_subst_def] >|
[full_case_tac >>
     full_case_tac >>
     fs [lookup_notin] >>
     imp_res_tac lookup_in2 >>
     REPEAT (pop_assum mp_tac) >>
     rw [MAP_ZIP] >>
     REPEAT (pop_assum mp_tac) >>
     Q.SPEC_TAC (`tvs`,`tvs`) >>
     induct_on `ts'` >>
     rw [] >>
     cases_on `tvs` >>
     fs [] >>
     metis_tac [optionTheory.SOME_11],
 metis_tac []]);

(* ---------- tenv_inv, the invariant relating inference and type system * environments ---------- *)

val tenv_inv_def = Define `
tenv_inv s env tenv =
  (!x tvs t.
   (lookup x env = SOME (tvs,t)) ⇒
   ((lookup_tenv x 0 tenv = 
     SOME (tvs, convert_t (t_walkstar (infer_deBruijn_inc tvs o_f s) t)))))`;

val tenv_inv_empty_to = Q.prove (
`!s env tenv.
  t_wfs s ∧ check_env {} env ∧ tenv_inv FEMPTY env tenv 
  ⇒ 
  tenv_inv s env tenv`,
induct_on `env` >>
rw [tenv_inv_def] >>
imp_res_tac check_env_lookup >>
PairCases_on `h` >>
fs [] >>
cases_on `h0 = x` >>
fs [] >>
rw [GSYM check_t_subst] >>
metis_tac [t_walkstar_FEMPTY]);

val tenv_inv_extend = Q.prove (
`!s x tvs t env t' tenv.
  tenv_inv s env tenv 
  ⇒
  tenv_inv s ((x,tvs,t)::env) (bind_tenv x tvs (convert_t (t_walkstar (infer_deBruijn_inc tvs o_f s) t)) tenv)`,
rw [tenv_inv_def] >>
every_case_tac >>
rw [] >>
rw [lookup_tenv_def, bind_tenv_def, deBruijn_inc0] >>
metis_tac []);

val tenv_inv_extend0 = Q.prove (
`!s x t env tenv.
  tenv_inv s env tenv 
  ⇒
  tenv_inv s ((x,0,t)::env) (bind_tenv x 0 (convert_t (t_walkstar s t)) tenv)`,
rw [] >>
`infer_deBruijn_inc 0 o_f s = s` by rw [GSYM fmap_EQ_THM, infer_deBruijn_inc0] >>
metis_tac [tenv_inv_extend]);

val tenv_inv_extend_tvar_empty_subst = Q.prove (
`!env tvs tenv.
  check_env {} env ∧ tenv_inv FEMPTY env tenv ⇒ tenv_inv FEMPTY env (bind_tvar tvs tenv)`,
induct_on `env` >>
fs [tenv_inv_def] >>
rw [] >>
PairCases_on `h` >>
rw [bind_tvar_def, lookup_tenv_def] >>
fs [t_walkstar_FEMPTY] >>
res_tac >>
imp_res_tac lookup_tenv_inc >>
fs [] >>
`check_t h1 {} h2 ∧ check_env {} env` by fs [check_env_def] >>
cases_on `h0 = x` >>
fs [] >>
rw [] >>
imp_res_tac check_env_lookup >>
metis_tac [inc_convert_t]);

val tenv_inv_letrec_merge = Q.prove (
`!funs tenv' env tenv st s.
  tenv_inv s env tenv 
  ⇒
  tenv_inv s (merge (MAP2 (λ(f,x,e) uvar. (f,0,uvar)) funs (MAP (λn. Infer_Tuvar (st.next_uvar + n)) (COUNT_LIST (LENGTH funs)))) env)
             (bind_var_list 0 (MAP2 (λ(f,x,e) t. (f,t)) funs (MAP (λn. convert_t (t_walkstar s (Infer_Tuvar (st.next_uvar + n)))) (COUNT_LIST (LENGTH funs)))) tenv)`,
induct_on `funs` >>
rw [COUNT_LIST_def, merge_def, bind_var_list_def] >>
PairCases_on `h` >>
rw [bind_var_list_def] >>
match_mp_tac tenv_inv_extend0 >>
fs [merge_def] >>
rw [check_t_def] >>
res_tac >>
pop_assum (mp_tac o Q.SPEC `st with next_uvar := st.next_uvar + 1`) >>
strip_tac >>
fs [] >>
metis_tac [MAP_MAP_o, combinTheory.o_DEF, DECIDE ``x + SUC y = x + 1 + y``]);

val tenv_inv_merge = Q.prove (
`!s x uv env env' tenv. 
  tenv_inv s env tenv
  ⇒
  tenv_inv s (merge (MAP (λ(n,t). (n,0,t)) env') env) (bind_var_list 0 (convert_env s env') tenv)`,
induct_on `env'` >>
rw [merge_def, convert_env_def, bind_var_list_def] >>
res_tac >>
fs [tenv_inv_def] >>
rw [] >>
PairCases_on `h` >>
fs [] >>
cases_on `h0 = x` >>
fs [] >>
rw [bind_var_list_def, bind_tenv_def, lookup_def, lookup_tenv_def,
    deBruijn_inc0, infer_deBruijn_inc0_id, o_f_id] >>
fs [merge_def] >>
res_tac >>
metis_tac [convert_env_def]);
val tenv_inv_merge2 = Q.prove (
`!env tenv env'' s tvs.
  tenv_inv FEMPTY env tenv 
  ⇒
  tenv_inv FEMPTY
    (merge (MAP (λx. (FST x,tvs,t_walkstar s (SND x))) env'') env)
    (bind_var_list2 (MAP (λx. (FST x,tvs, convert_t (t_walkstar s (SND x)))) env'') tenv)`,
induct_on `env''` >>
rw [bind_var_list2_def, merge_def] >>
PairCases_on `h` >>
rw [bind_var_list2_def, merge_def] >>
res_tac >>
fs [merge_def, tenv_inv_def, bind_tenv_def, lookup_tenv_def] >>
rw [deBruijn_inc0, t_walkstar_FEMPTY] >>
metis_tac [t_walkstar_FEMPTY]);

val tenv_inv_merge3 = Q.prove (
`!l l' env tenv s tvs.
(LENGTH l = LENGTH l') ∧
tenv_inv FEMPTY env tenv
⇒
tenv_inv FEMPTY
  (merge
     (MAP2 (λ(f,x,e) t. (f,tvs,t)) l
        (MAP (λx. t_walkstar s (Infer_Tuvar x))
           l')) env)
  (bind_var_list2
     (MAP (λ(x,tvs,t). (x,tvs,convert_t t))
        (MAP2 (λ(f,x,e) t. (f,tvs,t)) l
           (MAP (λx. t_walkstar s (Infer_Tuvar x))
              l'))) tenv)`,
induct_on `l` >>
rw [] >>
cases_on `l'` >>
rw [merge_def, bind_var_list2_def] >>
fs [] >>
PairCases_on `h` >>
fs [merge_def, bind_var_list2_def] >>
fs [merge_def, tenv_inv_def, bind_tenv_def, lookup_tenv_def] >>
rw [deBruijn_inc0, t_walkstar_FEMPTY] >>
fs [t_walkstar_FEMPTY] >>
res_tac >>
metis_tac []);

(* ---------- sub_completion ---------- *)

val sub_completion_unify = Q.prove (
`!st t1 t2 s1 n ts s2 n.
  (t_unify st.subst t1 t2 = SOME s1) ∧
  sub_completion n (st.next_uvar + 1) s1 ts s2
  ⇒
  sub_completion n st.next_uvar st.subst ((t1,t2)::ts) s2`,
rw [sub_completion_def, pure_add_constraints_def] >>
full_simp_tac (srw_ss()++ARITH_ss) [SUBSET_DEF, count_add1]);

val sub_completion_unify2 = Q.prove (
`!st t1 t2 s1 n ts s2 n s3 next_uvar.
  (t_unify s1 t1 t2 = SOME s2) ∧
  sub_completion n next_uvar s2 ts s3
  ⇒
  sub_completion n next_uvar s1 ((t1,t2)::ts) s3`,
rw [sub_completion_def, pure_add_constraints_def]);

val sub_completion_infer = Q.prove (
`!menv cenv env e st1 t st2 n ts2 s.
  (infer_e menv cenv env e st1 = (Success t, st2)) ∧
  sub_completion n st2.next_uvar st2.subst ts2 s
  ⇒
  ?ts1. sub_completion n st1.next_uvar st1.subst (ts1 ++ ts2) s`,
rw [sub_completion_def, pure_add_constraints_append] >>
imp_res_tac infer_e_constraints >>
imp_res_tac infer_e_next_uvar_mono >>
qexists_tac `ts` >>
rw [] >|
[qexists_tac `st2.subst` >>
     rw [],
 full_simp_tac (srw_ss()++ARITH_ss) [SUBSET_DEF]]);

val sub_completion_add_constraints = Q.prove (
`!s1 ts1 s2 n next_uvar s2 s3 ts2.
  pure_add_constraints s1 ts1 s2 ∧
  sub_completion n next_uvar s2 ts2 s3
  ⇒
  sub_completion n next_uvar s1 (ts1++ts2) s3`,
induct_on `ts1` >>
rw [pure_add_constraints_def] >>
Cases_on `h` >>
fs [pure_add_constraints_def] >>
res_tac >>
fs [sub_completion_def] >>
rw [] >>
fs [pure_add_constraints_def, pure_add_constraints_append] >>
metis_tac []);

val sub_completion_more_vars = Q.prove (
`!m n1 n2 s1 ts s2.
  sub_completion m (n1 + n2) s1 ts s2 ⇒ sub_completion m n1 s1 ts s2`,
rw [sub_completion_def] >>
rw [] >>
full_simp_tac (srw_ss()++ARITH_ss) [SUBSET_DEF]);

val sub_completion_infer_es = Q.prove (
`!menv cenv env es st1 t st2 n ts2 s.
  (infer_es menv cenv env es st1 = (Success t, st2)) ∧
  sub_completion n st2.next_uvar st2.subst ts2 s
  ⇒
  ?ts1. sub_completion n st1.next_uvar st1.subst (ts1 ++ ts2) s`,
induct_on `es` >>
rw [infer_e_def, success_eqns] >-
metis_tac [APPEND] >>
res_tac >>
imp_res_tac sub_completion_infer >>
metis_tac [APPEND_ASSOC]);

val sub_completion_infer_p = Q.prove (
`(!cenv p st t env st' tvs extra_constraints s.
    (infer_p cenv p st = (Success (t,env), st')) ∧
    sub_completion tvs st'.next_uvar st'.subst extra_constraints s
    ⇒
    ?ts. sub_completion tvs st.next_uvar st.subst (ts++extra_constraints) s) ∧
 (!cenv ps st ts env st' tvs extra_constraints s.
    (infer_ps cenv ps st = (Success (ts,env), st')) ∧
    sub_completion tvs st'.next_uvar st'.subst extra_constraints s
    ⇒
    ?ts. sub_completion tvs st.next_uvar st.subst (ts++extra_constraints) s)`,
ho_match_mp_tac infer_p_ind >>
rw [infer_p_def, success_eqns, remove_pair_lem] >>
fs [] >|
[metis_tac [APPEND, sub_completion_more_vars],
 metis_tac [APPEND, sub_completion_more_vars],
 metis_tac [APPEND, sub_completion_more_vars],
 metis_tac [APPEND, sub_completion_more_vars],
 metis_tac [APPEND, sub_completion_more_vars],
 PairCases_on `v'` >>
     fs [] >>
     metis_tac [APPEND_ASSOC, APPEND, sub_completion_more_vars],
 imp_res_tac sub_completion_add_constraints >>
     PairCases_on `v''` >>
     fs [] >>
     metis_tac [APPEND_ASSOC, APPEND, sub_completion_more_vars],
 PairCases_on `v'` >>
     fs [] >>
     metis_tac [APPEND_ASSOC, APPEND, sub_completion_more_vars],
 metis_tac [APPEND, sub_completion_more_vars],
 PairCases_on `v'` >>
     PairCases_on `v''` >>
     fs [] >>
     metis_tac [APPEND_ASSOC]]);

val sub_completion_infer_pes = Q.prove (
`!menv cenv env pes t1 t2 st1 t st2 n ts2 s.
  (infer_pes menv cenv env pes t1 t2 st1 = (Success (), st2)) ∧
  sub_completion n st2.next_uvar st2.subst ts2 s
  ⇒
  ?ts1. sub_completion n st1.next_uvar st1.subst (ts1 ++ ts2) s`,
induct_on `pes` >>
rw [infer_e_def, success_eqns] >-
metis_tac [APPEND] >>
PairCases_on `h` >>
fs [infer_e_def, success_eqns] >>
PairCases_on `v'` >>
fs [infer_e_def, success_eqns] >>
rw [] >>
res_tac >>
fs [] >>
imp_res_tac sub_completion_unify2 >>
imp_res_tac sub_completion_infer >>
fs [] >>
imp_res_tac sub_completion_unify2 >>
imp_res_tac sub_completion_infer_p >>
fs [] >>
metis_tac [APPEND, APPEND_ASSOC]);

val sub_completion_infer_funs = Q.prove (
`!menv cenv env funs st1 t st2 n ts2 s.
  (infer_funs menv cenv env funs st1 = (Success t, st2)) ∧
  sub_completion n st2.next_uvar st2.subst ts2 s
  ⇒
  ?ts1. sub_completion n st1.next_uvar st1.subst (ts1 ++ ts2) s`,
induct_on `funs` >>
rw [infer_e_def, success_eqns] >-
metis_tac [APPEND] >>
PairCases_on `h` >>
fs [infer_e_def, success_eqns] >>
res_tac >>
imp_res_tac sub_completion_infer >>
fs [] >>
metis_tac [sub_completion_more_vars, APPEND_ASSOC]);

val sub_completion_apply = Q.prove (
`!n uvars s1 ts s2 t1 t2.
  t_wfs s1 ∧
  (t_walkstar s1 t1 = t_walkstar s1 t2) ∧
  sub_completion n uvars s1 ts s2 
  ⇒
  (t_walkstar s2 t1 = t_walkstar s2 t2)`,
rw [sub_completion_def] >>
pop_assum (fn _ => all_tac) >>
pop_assum (fn _ => all_tac) >>
pop_assum mp_tac >>
pop_assum mp_tac >>
pop_assum mp_tac >>
Q.SPEC_TAC (`s1`, `s1`) >>
induct_on `ts` >>
rw [pure_add_constraints_def] >-
metis_tac [] >>
cases_on `h` >>
fs [pure_add_constraints_def] >>
fs [] >>
metis_tac [t_unify_apply2, t_unify_wfs]);

val sub_completion_apply_list = Q.prove (
`!n uvars s1 ts s2 ts1 ts2.
  t_wfs s1 ∧
  (MAP (t_walkstar s1) ts1 = MAP (t_walkstar s1) ts2) ∧
  sub_completion n uvars s1 ts s2 
  ⇒
  (MAP (t_walkstar s2) ts1 = MAP (t_walkstar s2) ts2)`,
induct_on `ts1` >>
rw [] >>
cases_on `ts2` >>
fs [] >>
metis_tac [sub_completion_apply]);

val sub_completion_wfs = Q.prove (
`!n uvars s1 ts s2.
  t_wfs s1 ∧
  sub_completion n uvars s1 ts s2 
  ⇒
  t_wfs s2`,
rw [sub_completion_def] >>
pop_assum (fn _ => all_tac) >>
pop_assum (fn _ => all_tac) >>
pop_assum mp_tac >>
pop_assum mp_tac >>
Q.SPEC_TAC (`s1`, `s1`) >>
induct_on `ts` >>
rw [pure_add_constraints_def] >-
metis_tac [] >>
PairCases_on `h` >>
fs [pure_add_constraints_def] >>
metis_tac [t_unify_wfs]);

val sub_completion_check = Q.prove (
`!tvs m s uvar s' extra_constraints.
sub_completion m (uvar + tvs) s' extra_constraints s
⇒
EVERY (λn. check_freevars m [] (convert_t (t_walkstar s (Infer_Tuvar (uvar + n))))) (COUNT_LIST tvs)`,
induct_on `tvs` >>
rw [sub_completion_def, COUNT_LIST_SNOC, EVERY_SNOC] >>
fs [sub_completion_def] >|
[qpat_assum `!m' s. P m' s` match_mp_tac >>
     rw [] >>
     qexists_tac `s'` >>
     qexists_tac `extra_constraints` >>
     rw [] >>
     full_simp_tac (srw_ss()++ARITH_ss) [SUBSET_DEF],
 fs [SUBSET_DEF] >>
     `uvar+tvs < uvar + SUC tvs`
            by full_simp_tac (srw_ss()++ARITH_ss) [SUBSET_DEF] >>
     metis_tac [check_t_to_check_freevars]]);

(* ---------- Soundness ---------- *)

val type_pes_def = Define `
type_pes menv cenv tenv pes t1 t2 =
  ∀x::set pes.
    (λ(p,e).
       ∃tenv'.
         ALL_DISTINCT (pat_bindings p []) ∧
         type_p (num_tvs tenv) cenv p t1 tenv' ∧
         type_e menv cenv (bind_var_list 0 tenv' tenv) e t2) x`;

val type_pes_cons = Q.prove (
`!menv cenv tenv p e pes t1 t2.
  type_pes menv cenv tenv ((p,e)::pes) t1 t2 =
  (ALL_DISTINCT (pat_bindings p []) ∧
   (?tenv'.
       type_p (num_tvs tenv) cenv p t1 tenv' ∧
       type_e menv cenv (bind_var_list 0 tenv' tenv) e t2) ∧
   type_pes menv cenv tenv pes t1 t2)`,
rw [type_pes_def, RES_FORALL] >>
eq_tac >>
rw [] >>
rw [] >|
[pop_assum (mp_tac o Q.SPEC `(p,e)`) >>
     rw [],
 pop_assum (mp_tac o Q.SPEC `(p,e)`) >>
     rw [] >>
     metis_tac [],
 metis_tac []]);

val infer_p_sound = Q.prove (
`(!cenv p st t env st' tvs extra_constraints s.
    (infer_p cenv p st = (Success (t,env), st')) ∧
    t_wfs st.subst ∧
    check_cenv cenv ∧
    sub_completion tvs st'.next_uvar st'.subst extra_constraints s
    ⇒
    type_p tvs cenv p (convert_t (t_walkstar s t)) (convert_env s env)) ∧
 (!cenv ps st ts env st' tvs extra_constraints s.
    (infer_ps cenv ps st = (Success (ts,env), st')) ∧
    t_wfs st.subst ∧
    check_cenv cenv ∧
    sub_completion tvs st'.next_uvar st'.subst extra_constraints s
    ⇒
    type_ps tvs cenv ps (MAP (convert_t o t_walkstar s) ts) (convert_env s env))`,
ho_match_mp_tac infer_p_ind >>
rw [infer_p_def, success_eqns, remove_pair_lem] >>
rw [Once type_p_cases, convert_env_def] >>
imp_res_tac sub_completion_wfs >>
fs [] >>
rw [t_walkstar_eqn1, convert_t_def, Tbool_def, Tint_def, Tstring_def, Tunit_def] >|
[match_mp_tac check_t_to_check_freevars >>
     rw [] >>
     fs [sub_completion_def] >>
     qpat_assum `!uv. uv ∈ FDOM s ⇒ P uv` match_mp_tac >>
     fs [count_def, SUBSET_DEF],
 `?ts env. v' = (ts,env)` by (PairCases_on `v'` >> metis_tac []) >>
     `t_wfs s` by metis_tac [infer_p_wfs] >>
     rw [t_walkstar_eqn1, convert_t_def, Tref_def] >>
     fs [convert_env_def] >>
     metis_tac [MAP_MAP_o],
 `?ts env. v'' = (ts,env)` by (PairCases_on `v''` >> metis_tac []) >>
     `?tvs ts tn. v' = (tvs,ts,tn)` by (PairCases_on `v'` >> metis_tac []) >>
     rw [] >>
     `type_ps tvs cenv ps (MAP (convert_t o t_walkstar s) ts) (convert_env s env)` 
               by metis_tac [sub_completion_add_constraints, sub_completion_more_vars] >>
     rw [] >>
     `t_wfs s` by metis_tac [sub_completion_wfs, infer_p_wfs, pure_add_constraints_wfs] >>
     rw [convert_t_def, t_walkstar_eqn1, MAP_MAP_o, combinTheory.o_DEF,
         EVERY_MAP, LENGTH_COUNT_LIST] >>
     fs [] >-
     metis_tac [sub_completion_check] >>
     `t_wfs st'''.subst` by metis_tac [infer_p_wfs] >>
     imp_res_tac pure_add_constraints_apply >>
     pop_assum (fn _ => all_tac) >>
     pop_assum (fn _ => all_tac) >>
     pop_assum mp_tac >>
     rw [MAP_ZIP] >>
     `t_wfs st'.subst` by metis_tac [pure_add_constraints_wfs] >>
     imp_res_tac sub_completion_apply_list >>
     NTAC 6 (pop_assum (fn _ => all_tac)) >>
     pop_assum mp_tac >>
     rw [subst_infer_subst_swap] >>
     `EVERY (check_freevars 0 tvs') ts'` by metis_tac [check_cenv_lookup] >>
     rw [] >>
     fs [convert_env_def] >>
     metis_tac [convert_t_subst, LENGTH_COUNT_LIST, LENGTH_MAP,
                MAP_MAP_o, combinTheory.o_DEF],
 `?ts env. v' = (ts,env)` by (PairCases_on `v'` >> metis_tac []) >>
     `t_wfs s` by metis_tac [infer_p_wfs] >>
     rw [t_walkstar_eqn1, convert_t_def, Tref_def] >>
     fs [convert_env_def] >>
     metis_tac [],
 `?t env. v' = (t,env)` by (PairCases_on `v'` >> metis_tac []) >>
     `?ts' env'. v'' = (ts',env')` by (PairCases_on `v''` >> metis_tac []) >>
     rw [] >>
     `t_wfs st''.subst` by metis_tac [infer_p_wfs] >>
     `?ts. sub_completion tvs st''.next_uvar st''.subst ts s` by metis_tac [sub_completion_infer_p] >>
     fs [convert_env_def] >>
     metis_tac []]);

val letrec_lemma = Q.prove (
`!funs funs_ts s st. 
  (MAP (λn. convert_t (t_walkstar s (Infer_Tuvar (st.next_uvar + n)))) (COUNT_LIST (LENGTH funs)) =
   MAP (\t. convert_t (t_walkstar s t)) funs_ts)
  ⇒
  (MAP2 (λ(f,x,e) t. (f,t)) funs (MAP (λn. convert_t (t_walkstar s (Infer_Tuvar (st.next_uvar + n)))) (COUNT_LIST (LENGTH funs))) =
   MAP2 (λ(x,y,z) t. (x,convert_t (t_walkstar s t))) funs funs_ts)`,
induct_on `funs` >>
rw [] >>
cases_on `funs_ts` >>
fs [COUNT_LIST_def] >>
rw [] >|
[PairCases_on `h` >>
     rw [],
 qpat_assum `!x. P x` match_mp_tac >>
     qexists_tac `st with next_uvar := st.next_uvar + 1` >>
     fs [MAP_MAP_o, combinTheory.o_DEF, DECIDE ``x + SUC y = x + 1 + y``]]);

val map_zip_lem = Q.prove (
`!funs ts. 
  (LENGTH funs = LENGTH ts)
  ⇒
  (MAP (λx. FST ((λ((x',y,z),t). (x',convert_t (t_walkstar s t))) x)) (ZIP (funs,ts))
   =
   MAP FST funs)`,
induct_on `funs` >>
rw [] >>
cases_on `ts` >>
fs [] >>
PairCases_on `h` >>
rw []);

val binop_tac =
imp_res_tac infer_e_wfs >>
imp_res_tac t_unify_wfs >>
fs [] >>
imp_res_tac sub_completion_unify2 >>
imp_res_tac sub_completion_infer >>
fs [] >>
res_tac >>
fs [] >>
imp_res_tac t_unify_apply >>
imp_res_tac sub_completion_apply >>
imp_res_tac t_unify_wfs >>
imp_res_tac sub_completion_wfs >>
fs [t_walkstar_eqn, t_walk_eqn, convert_t_def, deBruijn_inc_def, check_t_def] >>
rw [type_op_cases, Tint_def, Tstring_def, Tbool_def, Tref_def, Tfn_def, Tunit_def, Texn_def] >>
metis_tac [MAP, infer_e_next_uvar_mono, check_env_more];

val infer_e_sound = Q.prove (
`(!menv cenv env e st st' tenv t extra_constraints s.
    (infer_e menv cenv env e st = (Success t, st')) ∧
    t_wfs st.subst ∧
    check_menv menv ∧
    check_cenv cenv ∧
    check_env (count st.next_uvar) env ∧
    sub_completion (num_tvs tenv) st'.next_uvar st'.subst extra_constraints s ∧
    tenv_inv s env tenv
    ⇒
    type_e (convert_menv menv) cenv tenv e 
           (convert_t (t_walkstar s t))) ∧
 (!menv cenv env es st st' tenv ts extra_constraints s.
    (infer_es menv cenv env es st = (Success ts, st')) ∧
    t_wfs st.subst ∧
    check_menv menv ∧
    check_cenv cenv ∧
    check_env (count st.next_uvar) env ∧
    sub_completion (num_tvs tenv) st'.next_uvar st'.subst extra_constraints s ∧
    tenv_inv s env tenv
    ⇒
    type_es (convert_menv menv) cenv tenv es 
            (MAP (convert_t o t_walkstar s) ts)) ∧
 (!menv cenv env pes t1 t2 st st' tenv extra_constraints s.
    (infer_pes menv cenv env pes t1 t2 st = (Success (), st')) ∧
    t_wfs st.subst ∧
    check_menv menv ∧
    check_cenv cenv ∧
    check_env (count st.next_uvar) env ∧
    sub_completion (num_tvs tenv) st'.next_uvar st'.subst extra_constraints s ∧
    tenv_inv s env tenv
    ⇒
    type_pes (convert_menv menv) cenv tenv pes (convert_t (t_walkstar s t1)) (convert_t (t_walkstar s t2))) ∧
 (!menv cenv env funs st st' tenv extra_constraints s ts.
    (infer_funs menv cenv env funs st = (Success ts, st')) ∧
    t_wfs st.subst ∧
    check_menv menv ∧
    check_cenv cenv ∧
    check_env (count st.next_uvar) env ∧
    sub_completion (num_tvs tenv) st'.next_uvar st'.subst extra_constraints s ∧
    tenv_inv s env tenv ∧
    ALL_DISTINCT (MAP FST funs)
    ⇒
    type_funs (convert_menv menv) cenv tenv funs (MAP2 (\(x,y,z) t. (x, (convert_t o t_walkstar s) t)) funs ts))`,
ho_match_mp_tac infer_e_ind >>
rw [infer_e_def, success_eqns, remove_pair_lem] >>
rw [check_t_def] >>
fs [bind_def, check_t_def, check_env_bind, check_env_merge] >>
ONCE_REWRITE_TAC [type_e_cases] >>
rw [Tbool_def, Tint_def, Tunit_def] >|
[(* Raise *)
     fs [sub_completion_def, flookup_thm, count_add1, SUBSET_DEF] >>
     `st''.next_uvar < st''.next_uvar + 1` by decide_tac >>
     metis_tac [IN_INSERT, check_convert_freevars, prim_recTheory.LESS_REFL],
 (* Raise *)
     imp_res_tac sub_completion_unify >>
     `type_e (convert_menv menv) cenv tenv e (convert_t (t_walkstar s t2))` by metis_tac [] >>
     `t_wfs st''.subst` by metis_tac [infer_e_wfs] >>
     imp_res_tac t_unify_apply >>
     imp_res_tac sub_completion_apply >>
     imp_res_tac t_unify_wfs >>
     fs [] >>
     rw [] >>
     imp_res_tac sub_completion_wfs >>
     fs [t_walkstar_eqn1, convert_t_def, Texn_def],
 `?ts. sub_completion (num_tvs tenv) st''.next_uvar st''.subst  ts s` 
              by (imp_res_tac sub_completion_infer_pes >>
                  fs [] >>
                  metis_tac [sub_completion_more_vars]) >>
     metis_tac [],
 `?ts. sub_completion (num_tvs tenv) st''.next_uvar st''.subst  ts s` 
              by (imp_res_tac sub_completion_infer_pes >>
                  fs [] >>
                  metis_tac [sub_completion_more_vars]) >>
     rw [RES_FORALL] >>
     `?p e. x = (p,e)` by (PairCases_on `x` >> metis_tac []) >>
     rw [] >>
     `t_wfs st''.subst` by metis_tac [infer_e_wfs] >>
     `st.next_uvar ≤ st''.next_uvar` by metis_tac [infer_e_next_uvar_mono] >>
     `check_env (count st''.next_uvar) env` by metis_tac [check_env_more] >>
     `type_pes (convert_menv menv) cenv tenv pes (convert_t (t_walkstar s (Infer_Tapp [] TC_exn))) (convert_t (t_walkstar s t))`
              by metis_tac [] >>
     fs [type_pes_def, RES_FORALL] >>
     pop_assum (mp_tac o Q.SPEC `(p,e')`) >>
     rw [Texn_def] >>
     imp_res_tac sub_completion_wfs >>
     fs [t_walkstar_eqn1, convert_t_def, Texn_def] >>
     metis_tac [],
 (* Lit bool *)
     binop_tac,
 (* Lit int *)
     binop_tac,
 (* Lit string *)
     binop_tac,
 (* Lit unit *)
     binop_tac,
 (* Var short *)
     rw [t_lookup_var_id_def] >>
     `?tvs t. v' = (tvs, t)` 
                by (PairCases_on `v'` >>
                    rw []) >>
     rw [] >>
     qexists_tac `convert_t (t_walkstar (infer_deBruijn_inc tvs o_f s) t)` >>
     qexists_tac `MAP (convert_t o t_walkstar s) (MAP (λn. Infer_Tuvar (st.next_uvar + n)) (COUNT_LIST tvs))` >>
     rw [] >|
     [fs [sub_completion_def] >>
          rw [] >>
          `count st.next_uvar ⊆ FDOM s`
                  by (fs [count_def, SUBSET_DEF] >>
                      rw [] >>
                      metis_tac [DECIDE ``x < y ⇒ x < y + z:num``]) >>
          `check_t tvs (FDOM s) t`
                     by metis_tac [check_env_lookup, check_t_more5] >>
          metis_tac [db_subst_infer_subst_swap, pure_add_constraints_wfs],
      rw [EVERY_MAP] >>
          metis_tac [sub_completion_check, FST],
      rw [LENGTH_COUNT_LIST] >>
          metis_tac [tenv_inv_def]],
 (* Var long *)
     rw [t_lookup_var_id_def] >>
     `?tvs t. v' = (tvs, t)` 
                by (PairCases_on `v'` >>
                    rw []) >>
     rw [] >>
     qexists_tac `convert_t (t_walkstar (infer_deBruijn_inc tvs o_f s) t)` >>
     qexists_tac `MAP (convert_t o t_walkstar s) (MAP (λn. Infer_Tuvar (st.next_uvar + n)) (COUNT_LIST tvs))` >>
     rw [] >|
     [fs [sub_completion_def] >>
          rw [] >>
          `check_t tvs (FDOM s) t` by 
                     (metis_tac [check_menv_lookup, check_t_more]) >>
          metis_tac [db_subst_infer_subst_swap, pure_add_constraints_wfs],
      rw [EVERY_MAP] >>
          metis_tac [sub_completion_check, FST],
      rw [LENGTH_COUNT_LIST] >>
          fs [convert_menv_def, check_menv_def] >>
          `lookup mn (MAP (λ(mn,env). (mn,MAP (λ(x,tvs,t). (x,tvs,convert_t t)) env)) menv) =
           SOME (MAP (λ(x,tvs,t). (x,tvs,convert_t t)) env')`
                    by metis_tac [lookup_map] >>
          rw [] >>
          `lookup n (MAP (λ(x,y). (x,(\z. FST z,convert_t (SND z)) y)) env') =
           SOME ((\y. FST y,convert_t (SND y)) (tvs,t))`
                    by (match_mp_tac lookup_map >>
                        rw[]) >>
          fs [LAMBDA_PROD] >>
          `check_t tvs {} t`
                    by (imp_res_tac lookup_in >>
                        fs [MEM_MAP, EVERY_MEM] >>
                        rw [] >>
                        PairCases_on `y'` >>
                        PairCases_on `y''''` >>
                        PairCases_on `y'''` >>
                        PairCases_on `y'''''` >>
                        fs [] >>
                        rw [] >>
                        res_tac >>
                        fs [] >>
                        res_tac >>
                        fs []) >>
          metis_tac [check_t_subst, sub_completion_wfs]],
 (* Tup *)
     `?ts env. v' = (ts,env)` by (PairCases_on `v'` >> metis_tac []) >>
     `t_wfs s` by metis_tac [sub_completion_wfs, infer_e_wfs, pure_add_constraints_wfs] >>
     rw [t_walkstar_eqn1, convert_t_def, Tref_def] >>
     metis_tac [MAP_MAP_o],
 (* Con *)
     `?tvs ts t. v' = (tvs, ts, t)` by (PairCases_on `v'` >> rw []) >>
     rw [] >>
     fs [] >>
     `t_wfs s` by metis_tac [sub_completion_wfs, infer_e_wfs, pure_add_constraints_wfs] >>
     rw [convert_t_def, t_walkstar_eqn1, MAP_MAP_o, combinTheory.o_DEF,
         EVERY_MAP, LENGTH_COUNT_LIST] >-
     metis_tac [sub_completion_check] >>
     `type_es (convert_menv menv) cenv tenv es (MAP (convert_t o t_walkstar s) ts'')`
             by (imp_res_tac sub_completion_add_constraints >>
                 `sub_completion (num_tvs tenv) st'''.next_uvar st'''.subst
                        (ZIP
                           (ts'',
                            MAP
                              (infer_type_subst
                                 (ZIP
                                    (tvs,
                                     MAP (λn. Infer_Tuvar (st'''.next_uvar + n))
                                       (COUNT_LIST (LENGTH tvs))))) ts) ++
                         extra_constraints) s`
                                   by metis_tac [sub_completion_more_vars] >>
                 imp_res_tac sub_completion_infer_es >>
                 metis_tac []) >>
     `t_wfs st'''.subst` by metis_tac [infer_e_wfs] >>
     imp_res_tac pure_add_constraints_apply >>
     pop_assum (fn _ => all_tac) >>
     pop_assum (fn _ => all_tac) >>
     pop_assum mp_tac >>
     rw [MAP_ZIP] >>
     `t_wfs st'.subst` by metis_tac [pure_add_constraints_wfs] >>
     `MAP (t_walkstar s) ts'' =
       MAP (t_walkstar s)
         (MAP
            (infer_type_subst
               (ZIP
                  (tvs,
                   MAP (λn. Infer_Tuvar (st'''.next_uvar + n))
                     (COUNT_LIST (LENGTH tvs))))) ts)`
                 by metis_tac [sub_completion_apply_list] >>
     pop_assum mp_tac >>
     rw [subst_infer_subst_swap] >>
     `EVERY (check_freevars 0 tvs) ts` by metis_tac [check_cenv_lookup] >>
     metis_tac [convert_t_subst, LENGTH_COUNT_LIST, LENGTH_MAP,
                MAP_MAP_o, combinTheory.o_DEF],
 (* Fun *)
     `t_wfs s ∧ t_wfs st'.subst` by metis_tac [infer_st_rewrs,sub_completion_wfs, infer_e_wfs] >>
     rw [t_walkstar_eqn1, convert_t_def, Tfn_def] >>
     imp_res_tac infer_e_next_uvar_mono >>
     fs [] >>
     `st.next_uvar < st'.next_uvar` by decide_tac >|
     [fs [sub_completion_def, SUBSET_DEF] >>
          metis_tac [check_t_to_check_freevars],
      `tenv_inv s
                 ((x,0,Infer_Tuvar st.next_uvar)::env) 
                 (bind_tenv x 0 
                            (convert_t (t_walkstar s (Infer_Tuvar st.next_uvar))) 
                            tenv)`
             by (match_mp_tac tenv_inv_extend0 >>
                 fs []) >>
          fs [bind_tenv_def] >>
          `check_t 0 (count (st with next_uvar := st.next_uvar + 1).next_uvar) (Infer_Tuvar st.next_uvar)`
                     by rw [check_t_def] >>
          `check_env (count (st with next_uvar := st.next_uvar + 1).next_uvar) env`
                     by (rw [] >>
                         metis_tac [check_env_more, DECIDE ``x ≤ x + 1:num``]) >>
          metis_tac [num_tvs_def, infer_st_rewrs, bind_tenv_def]],
 (* Opref *)
     rw [type_uop_cases, Tref_def] >>
     binop_tac,
 (* Opderef *)
     rw [type_uop_cases, Tref_def] >>
     `t_wfs st''.subst` by metis_tac [infer_e_wfs] >>
     imp_res_tac t_unify_apply >>
     imp_res_tac sub_completion_unify >>
     `t_wfs s'` by metis_tac [t_unify_wfs] >>
     imp_res_tac sub_completion_apply >>
     `t_wfs s` by metis_tac [sub_completion_wfs, infer_e_wfs] >>
     fs [t_walkstar_eqn1] >>
     `type_e (convert_menv menv) cenv tenv e (convert_t (t_walkstar s t'))`
                by metis_tac [] >>
     metis_tac [convert_t_def, MAP],
 (* Opn *)
     binop_tac,
 (* Opb *)
     binop_tac,
 (* Equality *)
     binop_tac, 
 (* Opapp *)
     `t_wfs st''.subst` by metis_tac [infer_e_wfs] >>
     imp_res_tac sub_completion_unify >>
     imp_res_tac sub_completion_infer >>
     fs [] >>
     res_tac >>
     fs [] >>
     rw [type_op_cases, Tint_def, Tbool_def, Tref_def, Tfn_def, Tunit_def] >>
     qexists_tac `convert_t (t_walkstar s t2)` >>
     rw [] >>
     `t_wfs st'''.subst` by metis_tac [infer_e_wfs] >>
     imp_res_tac t_unify_apply >>
     imp_res_tac sub_completion_apply >>
     imp_res_tac t_unify_wfs >>
     imp_res_tac sub_completion_wfs >>
     fs [t_walkstar_eqn, t_walk_eqn, convert_t_def] >>
     metis_tac [check_env_more, infer_e_next_uvar_mono],
 (* Opassign *) 
     binop_tac, 
 (* Log *)
     binop_tac,
 (* Log *)
     binop_tac,
 (* If *)
     binop_tac,
 (* If *)
     imp_res_tac sub_completion_unify2 >>
     imp_res_tac sub_completion_infer >>
     imp_res_tac sub_completion_infer >>
     fs [] >>
     imp_res_tac sub_completion_unify2 >>
     `type_e (convert_menv menv) cenv tenv e (convert_t (t_walkstar s t1))`
             by metis_tac [] >>
     `t_wfs st''.subst` by metis_tac [infer_e_wfs] >>
     imp_res_tac t_unify_apply >>
     `t_wfs s'`  by metis_tac [t_unify_wfs] >>
     imp_res_tac sub_completion_apply >>
     `t_wfs s` by metis_tac [sub_completion_wfs] >>
     fs [t_walkstar_eqn, t_walk_eqn, convert_t_def],
 (* If *)
     `t_wfs (st'' with subst := s').subst` 
                by (rw [] >>
                    metis_tac [t_unify_wfs, infer_e_wfs]) >>
     `st.next_uvar ≤ (st'' with subst := s').next_uvar` 
                by (imp_res_tac infer_e_next_uvar_mono >>
                    fs [] >>
                    decide_tac) >>
     `check_env (count (st'' with subst := s').next_uvar) env` 
                by (metis_tac [check_env_more]) >>
     `?ts. sub_completion (num_tvs tenv) st'''''.next_uvar st'''''.subst ts s` 
               by metis_tac [sub_completion_unify2] >>
     imp_res_tac sub_completion_infer >>
     metis_tac [],
 (* If *)
     `t_wfs (st'' with subst := s').subst` 
                by (rw [] >>
                    metis_tac [t_unify_wfs, infer_e_wfs]) >>
     `t_wfs st''''.subst ∧ t_wfs st'''''.subst ∧ t_wfs st''.subst` by metis_tac [infer_e_wfs] >>
     `st.next_uvar ≤ st''''.next_uvar` 
                by (imp_res_tac infer_e_next_uvar_mono >>
                    fs [] >>
                    decide_tac) >>
     `check_env (count st''''.next_uvar) env` by metis_tac [check_env_more] >>
     `?ts. sub_completion (num_tvs tenv) st'''''.next_uvar st'''''.subst ts s` 
               by metis_tac [sub_completion_unify2] >>
     `type_e (convert_menv menv) cenv tenv e'' (convert_t (t_walkstar s t3))` by metis_tac [] >>
     imp_res_tac t_unify_apply >>
     `t_wfs s''` by metis_tac [t_unify_wfs] >>
     imp_res_tac sub_completion_apply >>
     metis_tac [],
 (* Match *)
     `?ts. sub_completion (num_tvs tenv) st''.next_uvar st''.subst  ts s` 
              by (imp_res_tac sub_completion_infer_pes >>
                  fs [] >>
                  metis_tac [sub_completion_more_vars]) >>
     `type_e (convert_menv menv) cenv tenv e (convert_t (t_walkstar s t1))` by metis_tac [] >>
     qexists_tac `convert_t (t_walkstar s t1)` >>
     rw [RES_FORALL] >>
     `?p e. x = (p,e)` by (PairCases_on `x` >> metis_tac []) >>
     rw [] >>
     `t_wfs (st'' with next_uvar := st''.next_uvar + 1).subst`
              by (rw [] >>
                  metis_tac [infer_e_wfs]) >>
     `st.next_uvar ≤ (st'' with next_uvar := st''.next_uvar + 1).next_uvar`
              by (rw [] >>
                  imp_res_tac infer_e_next_uvar_mono >>
                  fs [] >>
                  decide_tac) >>
     `check_env (count (st'' with next_uvar := st''.next_uvar + 1).next_uvar) env` by metis_tac [check_env_more] >>
     `type_pes (convert_menv menv) cenv tenv pes (convert_t (t_walkstar s t1)) (convert_t (t_walkstar s (Infer_Tuvar st''.next_uvar)))`
              by metis_tac [] >>
     fs [type_pes_def, RES_FORALL] >>
     pop_assum (mp_tac o Q.SPEC `(p,e')`) >>
     rw [],
 (* Let *)
     disj2_tac >>
     imp_res_tac sub_completion_infer >>
     fs [] >>
     imp_res_tac sub_completion_unify >>
     qexists_tac `convert_t (t_walkstar s t1)` >>
     rw [] >-
     metis_tac [] >>
     `t_wfs st''.subst` by metis_tac [infer_e_wfs] >>
     imp_res_tac t_unify_wfs >>
     `tenv_inv s ((x,0,t1)::env) 
                 (bind_tenv x 0 (convert_t (t_walkstar s t1)) tenv)` 
            by (match_mp_tac tenv_inv_extend0 >>
                rw [] >>
                fs []) >>
     `num_tvs (bind_tenv x 0 (convert_t (t_walkstar s t1)) tenv) = num_tvs tenv` 
            by (rw [num_tvs_def, bind_tenv_def]) >>
     `check_t 0 (count st''.next_uvar) t1` by metis_tac [infer_e_check_t] >>
     `check_env (count st''.next_uvar) env` by metis_tac [infer_e_next_uvar_mono, check_env_more] >>
     metis_tac [],
 (* Letrec *)
     `t_wfs (st with next_uvar := st.next_uvar + LENGTH funs).subst`
               by rw [] >>
     Q.ABBREV_TAC `env' = MAP2 (λ(f,x,e) uvar. (f,0:num,uvar)) funs (MAP (λn. Infer_Tuvar (st.next_uvar + n)) (COUNT_LIST (LENGTH funs)))` >>
     Q.ABBREV_TAC `tenv' = MAP2 (λ(f,x,e) t. (f,t)) funs (MAP (λn. convert_t (t_walkstar s (Infer_Tuvar (st.next_uvar + n)))) (COUNT_LIST (LENGTH funs)))` >>
     `sub_completion (num_tvs (bind_var_list 0 tenv' tenv)) st'.next_uvar st'.subst extra_constraints s`
                 by metis_tac [num_tvs_bind_var_list] >>
     `?constraints1. sub_completion (num_tvs (bind_var_list 0 tenv' tenv)) st''''.next_uvar st''''.subst constraints1 s`
                 by metis_tac [sub_completion_infer] >>
     `?constraints2. sub_completion (num_tvs (bind_var_list 0 tenv' tenv)) st'''.next_uvar st'''.subst constraints2 s`
                 by metis_tac [sub_completion_add_constraints] >>
     `tenv_inv s (merge env' env) (bind_var_list 0 tenv' tenv)` 
                 by (UNABBREV_ALL_TAC >>
                     match_mp_tac tenv_inv_letrec_merge >>
                     rw []) >>
     `check_env (count (st with next_uvar := st.next_uvar + LENGTH funs).next_uvar) (merge env' env)`
                 by (rw [check_env_merge] >|
                     [Q.UNABBREV_TAC `env'` >>
                          rw [check_env_letrec_lem],
                      metis_tac [check_env_more, DECIDE ``x ≤ x+y:num``]]) >>
     `type_funs (convert_menv menv) cenv (bind_var_list 0 tenv' tenv) funs 
                (MAP2 (\(x,y,z) t. (x, convert_t (t_walkstar s t))) funs funs_ts)`
                 by metis_tac [] >>
     `t_wfs st''''.subst` by metis_tac [infer_e_wfs, pure_add_constraints_wfs] >>
     `st.next_uvar + LENGTH funs ≤ st''''.next_uvar`
                 by (fs [] >>
                     imp_res_tac infer_e_next_uvar_mono >>
                     fs [] >>
                     metis_tac []) >>
     fs [] >>
     `type_e (convert_menv menv) cenv (bind_var_list 0 tenv' tenv) e (convert_t (t_walkstar s t))`
                 by metis_tac [check_env_more] >>
     qexists_tac `tenv'` >>
     qexists_tac `0` >>
     rw [bind_tvar_def] >>
     `tenv' = MAP2 (λ(x,y,z) t. (x,convert_t (t_walkstar s t))) funs funs_ts`
                 by (Q.UNABBREV_TAC `tenv'` >>
                     match_mp_tac letrec_lemma >>
                     imp_res_tac infer_e_wfs >>
                     imp_res_tac pure_add_constraints_apply >>
                     `LENGTH funs = LENGTH funs_ts` by metis_tac [LENGTH_COUNT_LIST] >>
                     fs [GSYM MAP_MAP_o, MAP_ZIP, LENGTH_COUNT_LIST, LENGTH_MAP] >>
                     metis_tac [MAP_MAP_o, combinTheory.o_DEF, sub_completion_apply_list]) >>
     rw [],
 metis_tac [sub_completion_infer_es],
 metis_tac [infer_e_wfs, infer_e_next_uvar_mono, check_env_more],
 rw [type_pes_def, RES_FORALL],
 `?t env. v' = (t,env)` by (PairCases_on `v'` >> metis_tac []) >>
     rw [] >>
     `∃ts. sub_completion (num_tvs tenv) (st'''' with subst:= s'').next_uvar (st'''' with subst:= s'').subst ts s` 
                   by metis_tac [sub_completion_infer_pes] >>
     fs [] >>
     `∃ts. sub_completion (num_tvs tenv) st''''.next_uvar st''''.subst ts s` 
              by metis_tac [sub_completion_unify2] >>
     `∃ts. sub_completion (num_tvs tenv) (st'' with subst := s').next_uvar (st'' with subst := s').subst ts s` 
              by metis_tac [sub_completion_infer] >>
     fs [] >>
     `∃ts. sub_completion (num_tvs tenv) st''.next_uvar st''.subst ts s` 
              by metis_tac [sub_completion_unify2] >>
     `type_p (num_tvs tenv) cenv p (convert_t (t_walkstar s t)) (convert_env s env')`
              by metis_tac [infer_p_sound] >>
     `t_wfs (st'' with subst := s').subst`
           by (rw [] >>
               metis_tac [infer_p_wfs, t_unify_wfs]) >>
     imp_res_tac infer_p_check_t >>
     `check_env (count (st'' with subst:=s').next_uvar) (merge (MAP (λ(n,t). (n,0,t)) (SND (t,env'))) env)`
           by (rw [check_env_merge] >|
               [rw [check_env_def, EVERY_MAP, remove_pair_lem] >>
                    fs [EVERY_MEM] >>
                    rw [] >>
                    PairCases_on `x` >>
                    fs [] >>
                    res_tac >>
                    fs [],
                metis_tac [infer_p_next_uvar_mono, check_env_more]]) >>
     `tenv_inv s (merge (MAP (λ(n,t). (n,0,t)) env') env) (bind_var_list 0 (convert_env s env') tenv)` 
              by (metis_tac [tenv_inv_merge]) >>
     `type_e (convert_menv menv) cenv (bind_var_list 0 (convert_env s env') tenv) e (convert_t (t_walkstar s t2'))`
               by metis_tac [check_env_merge, SND, num_tvs_bind_var_list] >>
     rw [type_pes_cons] >|
     [imp_res_tac infer_p_bindings >>
          metis_tac [APPEND_NIL],
      qexists_tac `(convert_env s env')` >>
           rw [] >>
           imp_res_tac infer_p_wfs >>
           imp_res_tac infer_e_wfs >>
           imp_res_tac t_unify_apply >>
           metis_tac [t_unify_wfs, sub_completion_apply],
      `t_wfs (st'''' with subst := s'').subst`
           by (rw [] >>
               metis_tac [t_unify_wfs, infer_e_wfs]) >>
          `(st.next_uvar ≤ (st'''' with subst := s'').next_uvar)` 
                  by (fs [] >>
                      imp_res_tac infer_p_next_uvar_mono >>
                      imp_res_tac infer_e_next_uvar_mono >>
                      fs [] >>
                      decide_tac) >>
          `check_env (count (st'''' with subst := s'').next_uvar) env` by metis_tac [check_env_more] >>
          metis_tac []],
 `t_wfs st'''.subst ∧ t_wfs (st with next_uvar := st.next_uvar + 1).subst` by metis_tac [infer_e_wfs, infer_st_rewrs] >>
     imp_res_tac sub_completion_infer_funs >>
     `tenv_inv s ((x,0,Infer_Tuvar st.next_uvar)::env) (bind_tenv x 0 (convert_t (t_walkstar s (Infer_Tuvar st.next_uvar))) tenv)`
              by (match_mp_tac tenv_inv_extend0 >>
                  rw []) >>
     `num_tvs (bind_tenv x 0 (convert_t (t_walkstar s (Infer_Tuvar st.next_uvar))) tenv) = num_tvs tenv`
              by fs [num_tvs_def, bind_tenv_def] >>
     `check_env (count (st with next_uvar := st.next_uvar + 1).next_uvar) env ∧
      check_t 0 (count (st with next_uvar := st.next_uvar + 1).next_uvar) (Infer_Tuvar st.next_uvar)`
                by (rw [check_t_def] >>
                    metis_tac [check_env_more, DECIDE ``x ≤ x + 1:num``]) >>
     `type_e (convert_menv menv) cenv (bind_tenv x 0 (convert_t (t_walkstar s (Infer_Tuvar st.next_uvar))) tenv)
             e (convert_t (t_walkstar s t))`
                 by metis_tac [] >>
     `check_env (count st'''.next_uvar) env`
                 by (metis_tac [check_env_more, infer_e_next_uvar_mono]) >>
     `type_funs (convert_menv menv) cenv tenv funs (MAP2 (\(x,y,z) t. (x, convert_t (t_walkstar s t))) funs ts')`
               by metis_tac [] >>
     `t_wfs s` by metis_tac [sub_completion_wfs] >>
     rw [t_walkstar_eqn1, convert_t_def, Tfn_def] >|
     [rw [check_freevars_def] >>
          match_mp_tac check_t_to_check_freevars >>
          rw [] >>
          fs [sub_completion_def] >|
          [`st.next_uvar < st'''.next_uvar`
                    by (imp_res_tac infer_e_next_uvar_mono >>
                        fs [] >>
                        decide_tac) >>
               `st.next_uvar ∈ FDOM s`
                    by fs [count_def, SUBSET_DEF] >>
               metis_tac [],
           match_mp_tac (hd (CONJUNCTS check_t_walkstar)) >>
               rw [] >>
               `check_t 0 (count (st'''.next_uvar)) t`
                         by (imp_res_tac infer_e_check_t >>
                             fs [GSYM bind_def, check_env_bind]) >>
               metis_tac [check_t_more5]],
      imp_res_tac infer_funs_length >>
          rw [lookup_notin, MAP2_MAP, LENGTH_MAP2, MAP_MAP_o, combinTheory.o_DEF, map_zip_lem]]]);

val letrec_lemma2 = Q.prove (
`!funs_ts l l' s s'.
 (!t1 t2. t_walkstar s t1 = t_walkstar s t2 ⇒  t_walkstar s' t1 = t_walkstar s' t2) ∧
 (LENGTH funs_ts = LENGTH l) ∧
 (LENGTH funs_ts = LENGTH l') ∧
 MAP (λn. t_walkstar s (Infer_Tuvar n)) l' = MAP (t_walkstar s) funs_ts
 ⇒
 (MAP2 (λ(f,x,e) t. (f,t)) l (MAP (λn. convert_t (t_walkstar s' (Infer_Tuvar n))) l')
  =
  MAP2 (λ(x,y,z) t. (x,convert_t (t_walkstar s' t))) l funs_ts)`,
induct_on `funs_ts` >>
cases_on `l` >>
cases_on `l'` >>
rw [] >>
fs [] >|
[PairCases_on `h` >>
     rw [] >>
     metis_tac [],
 metis_tac []]);

val convert_env2_def = Define `
convert_env2 env = MAP (λ(x,tvs,t). (x,tvs,convert_t t)) env`;

val tenv_inv_convert_env2 = Q.prove (
`!env. tenv_inv FEMPTY env (bind_var_list2 (convert_env2 env) Empty)`,
Induct >>
rw [convert_env2_def, bind_var_list2_def, tenv_inv_def] >>
PairCases_on `h` >>
fs [lookup_def] >>
every_case_tac >>
fs [] >>
rw [t_walkstar_FEMPTY, deBruijn_inc0, lookup_tenv_def, bind_tenv_def, lookup_def, bind_var_list2_def] >>
fs [tenv_inv_def] >>
res_tac >>
fs [t_walkstar_FEMPTY] >>
metis_tac [convert_env2_def]);

val infer_d_sound = Q.prove (
`!mn menv cenv env d st1 st2 cenv' env' tenv.
  infer_d mn menv cenv env d st1 = (Success (cenv',env'), st2) ∧
  check_menv menv ∧
  check_cenv cenv ∧
  check_env {} env
  ⇒
  type_d mn (convert_menv menv) cenv (bind_var_list2 (convert_env2 env) Empty) d cenv' (convert_env2 env')`,
cases_on `d` >>
REPEAT GEN_TAC >>
STRIP_TAC >>
fs [infer_d_def, success_eqns, type_d_cases] >>
fs [emp_def] >|
[`?t env. v' = (t,env)` by (PairCases_on `v'` >> metis_tac []) >>
     fs [success_eqns] >>
     `?tvs s ts. generalise_list st''.next_uvar 0 FEMPTY (MAP (t_walkstar st'''''.subst) (MAP SND env'')) = (tvs,s,ts)`
                 by (cases_on `generalise_list st''.next_uvar 0 FEMPTY (MAP (t_walkstar st'''''.subst) (MAP SND env''))` >>
                     rw [] >>
                     cases_on `r` >>
                     metis_tac []) >>
     fs [METIS_PROVE [] ``!x. (x = 0:num ∨ is_value e) = (x<>0 ⇒ is_value e)``] >>
     rw [] >>
     fs [success_eqns] >>
     Q.ABBREV_TAC `tenv' = bind_tvar tvs (bind_var_list2 (convert_env2 env) Empty)` >>
     fs [init_state_def] >>
     `t_wfs init_infer_state.subst` by rw [init_infer_state_def, t_wfs_def] >>
     `init_infer_state.next_uvar = 0` 
                 by (fs [init_infer_state_def] >> rw []) >>
     `check_t 0 (count st'''.next_uvar) t1` by metis_tac [infer_e_check_t, COUNT_ZERO] >>
     `t_wfs st'''.subst` by metis_tac [infer_e_wfs] >>
     fs [] >>
     rw [] >>
     fs [] >>
     imp_res_tac infer_p_check_t >>
     fs [every_shim] >>
     `t_wfs s` by metis_tac [t_unify_wfs, infer_p_wfs] >>
     `?last_sub ec1. sub_completion tvs st''''.next_uvar s ec1 last_sub ∧
                     t_wfs last_sub ∧
                     (ts = MAP (t_walkstar last_sub) (MAP SND env''))`
                          by metis_tac [generalise_complete, infer_d_check_s_helper1] >>
     `num_tvs tenv' = tvs` 
                  by (Q.UNABBREV_TAC `tenv'` >>
                      fs [bind_tvar_def] >> 
                      full_case_tac >>
                      rw [num_tvs_def, num_tvs_bvl2]) >>
     imp_res_tac sub_completion_unify2 >>
     `?ec2. sub_completion (num_tvs tenv') st'''.next_uvar st'''.subst (ec2++((t1,t)::ec1)) last_sub` 
               by metis_tac [sub_completion_infer_p] >>
     rw [] >>
     `(init_infer_state:(num |-> infer_t) infer_st).subst = FEMPTY` by fs [init_infer_state_def] >>
     `tenv_inv FEMPTY env (bind_var_list2 (convert_env2 env) Empty)` by metis_tac [tenv_inv_convert_env2] >>
     `tenv_inv FEMPTY env tenv'` by metis_tac [tenv_inv_extend_tvar_empty_subst] >>
     `tenv_inv last_sub env tenv'` by metis_tac [tenv_inv_empty_to] >>
     `type_e (convert_menv menv) cenv tenv' e (convert_t (t_walkstar last_sub t1))`
             by metis_tac [infer_e_sound, COUNT_ZERO] >>
     `type_p (num_tvs tenv') cenv p (convert_t (t_walkstar last_sub t)) (convert_env last_sub env'')`
             by metis_tac [infer_p_sound] >>
     `t_walkstar last_sub t = t_walkstar last_sub t1`
             by (imp_res_tac infer_e_wfs >>
                 imp_res_tac infer_p_wfs >>
                 imp_res_tac t_unify_wfs >>
                 metis_tac [sub_completion_apply, t_unify_apply]) >>
     cases_on `num_tvs tenv' = 0` >>
     rw [] >|
     [disj2_tac >>
          qexists_tac `convert_t (t_walkstar last_sub t)` >>
          qexists_tac `(convert_env last_sub env'')` >>
          rw [] >|
          [rw [ZIP_MAP, MAP_MAP_o, combinTheory.o_DEF] >>
               REPEAT (pop_assum (fn _ => all_tac)) >> 
               induct_on `env''` >>
               rw [convert_env2_def, tenv_add_tvs_def, convert_env_def] >-
               (PairCases_on `h` >>
                    rw []) >>
               rw [MAP_MAP_o, combinTheory.o_DEF, remove_pair_lem],
           imp_res_tac infer_p_bindings >>
               fs [],
           metis_tac [],
           fs [bind_tvar_def]],
      disj1_tac >>
          qexists_tac `num_tvs tenv'` >>
          qexists_tac `convert_t (t_walkstar last_sub t)` >>
          qexists_tac `(convert_env last_sub env'')` >>
          rw [] >|
          [rw [ZIP_MAP, MAP_MAP_o, combinTheory.o_DEF] >>
               REPEAT (pop_assum (fn _ => all_tac)) >> 
               induct_on `env''` >>
               rw [convert_env2_def, tenv_add_tvs_def, convert_env_def] >-
               (PairCases_on `h` >>
                    rw []) >>
               rw [MAP_MAP_o, combinTheory.o_DEF, remove_pair_lem],
           imp_res_tac infer_p_bindings >>
               fs []]],
 fs [success_eqns] >>
     `?tvs s ts. generalise_list st'''.next_uvar 0 FEMPTY (MAP (t_walkstar st'''''.subst) (MAP (λn. Infer_Tuvar (st'''.next_uvar + n)) (COUNT_LIST (LENGTH l)))) = (tvs,s,ts)`
                 by (cases_on `generalise_list st'''.next_uvar 0 FEMPTY (MAP (t_walkstar st'''''.subst) (MAP (λn. Infer_Tuvar (st'''.next_uvar + n)) (COUNT_LIST (LENGTH l))))` >>
                     rw [] >>
                     cases_on `r` >>
                     metis_tac []) >>
     fs [] >>
     rw [] >>
     fs [success_eqns] >>
     Q.ABBREV_TAC `tenv' = bind_tvar tvs (bind_var_list2 (convert_env2 env) Empty)` >>
     fs [init_state_def] >>
     rw [] >>
     `t_wfs init_infer_state.subst` by rw [init_infer_state_def, t_wfs_def] >>
     `init_infer_state.next_uvar = 0` 
                 by (fs [init_infer_state_def] >> rw []) >>
     fs [] >>
     rw [] >>
     fs [] >>
     `EVERY (\t. check_t 0 (count st''''.next_uvar) t) (MAP (λn. Infer_Tuvar n) (COUNT_LIST (LENGTH l)))`
                 by (rw [EVERY_MAP, check_t_def] >>
                     rw [EVERY_MEM, MEM_COUNT_LIST] >>
                     imp_res_tac infer_e_next_uvar_mono >>
                     fs [] >>
                     decide_tac) >>
     `t_wfs st'''''.subst` by metis_tac [pure_add_constraints_wfs, infer_e_wfs, infer_st_rewrs] >>
     `?last_sub ec1. sub_completion tvs st''''.next_uvar st'''''.subst ec1 last_sub ∧
                     t_wfs last_sub ∧
                     (ts = MAP (t_walkstar last_sub) (MAP (λn. Infer_Tuvar n) (COUNT_LIST (LENGTH l))))`
                          by metis_tac [generalise_complete, infer_d_check_s_helper2, LENGTH_COUNT_LIST] >>
     imp_res_tac sub_completion_add_constraints >>
     rw [] >>
     `(init_infer_state:(num |-> infer_t) infer_st).subst = FEMPTY` by fs [init_infer_state_def] >>
     `tenv_inv FEMPTY env (bind_var_list2 (convert_env2 env) Empty)` by metis_tac [tenv_inv_convert_env2] >>
     `tenv_inv FEMPTY env tenv'` by metis_tac [tenv_inv_extend_tvar_empty_subst] >>
     `tenv_inv last_sub env tenv'` by metis_tac [tenv_inv_empty_to] >>
     Q.ABBREV_TAC `tenv'' = 
                   bind_var_list 0 (MAP2 (λ(f,x,e) t. (f,t)) l (MAP (λn. convert_t (t_walkstar last_sub (Infer_Tuvar (0 + n)))) (COUNT_LIST (LENGTH l)))) 
                                 tenv'` >> 
     Q.ABBREV_TAC `env'' = merge (MAP2 (λ(f,x,e) uvar. (f,0,uvar)) l (MAP (λn. Infer_Tuvar (0 + n)) (COUNT_LIST (LENGTH l)))) env` >>
     `tenv_inv last_sub env'' tenv''` by metis_tac [tenv_inv_letrec_merge] >>
     fs [] >>
     `check_env (count (LENGTH l)) env''` 
                 by (Q.UNABBREV_TAC `env''` >>
                     rw [MAP2_MAP, check_env_merge, check_env_letrec] >>
                     metis_tac [check_env_more, COUNT_ZERO, DECIDE ``0<=x:num``]) >> 
     `num_tvs tenv'' = tvs`
                 by  (Q.UNABBREV_TAC `tenv''` >>
                      rw [num_tvs_bind_var_list] >>
                      Q.UNABBREV_TAC `tenv'` >>
                      fs [bind_tvar_rewrites, num_tvs_bvl2, num_tvs_def]) >>
     `type_funs (convert_menv menv) cenv tenv'' l (MAP2 (λ(x,y,z) t. (x,(convert_t o t_walkstar last_sub) t)) l funs_ts)`
             by (match_mp_tac (List.nth (CONJUNCTS infer_e_sound, 3)) >>
                 rw [] >>
                 qexists_tac `env''` >>
                 qexists_tac `init_infer_state with next_uvar := LENGTH l` >>
                 rw [] >>
                 metis_tac [num_tvs_bind_var_list]) >>
     `t_wfs (init_infer_state with next_uvar := LENGTH l).subst` by rw [] >>
     `t_wfs st''''.subst` by metis_tac [infer_e_wfs] >>
     imp_res_tac pure_add_constraints_apply >>
     qexists_tac `(MAP2 (λ(f,x,e) t. (f,t)) l (MAP (λn. convert_t (t_walkstar last_sub (Infer_Tuvar (0 + n)))) (COUNT_LIST (LENGTH l))))` >>
     qexists_tac `tvs` >>
     rw [] >|
     [rw [LENGTH_MAP, LENGTH_COUNT_LIST, MAP2_MAP, MAP_MAP_o, combinTheory.o_DEF] >>
          REPEAT (pop_assum (fn _ => all_tac)) >> 
          induct_on `l` >>
          rw [COUNT_LIST_def, tenv_add_tvs_def, convert_env_def, convert_env2_def] >-
          (PairCases_on `h` >> rw []) >>
          rw [MAP_MAP_o, MAP2_MAP, ZIP_MAP, LENGTH_COUNT_LIST, combinTheory.o_DEF, remove_pair_lem],
      `LENGTH l = LENGTH funs_ts` by fs [LENGTH_COUNT_LIST] >>
          fs [MAP_ZIP, LENGTH_COUNT_LIST, MAP_MAP_o, combinTheory.o_DEF] >>
          metis_tac [letrec_lemma2, LENGTH_COUNT_LIST, LENGTH_MAP, 
                     pure_add_constraints_wfs, sub_completion_apply]],
 full_case_tac >>
     fs [success_eqns] >>
     rw [convert_env2_def, bind_var_list2_def, merge_def],
 full_case_tac >>
     fs [success_eqns] >>
     rw [convert_env2_def]]);

val infer_ds_sound = Q.prove (
`!mn menv cenv env ds st1 cenv' env' st2 tenv.
  infer_ds mn menv cenv env ds st1 = (Success (cenv',env'), st2) ∧
  check_menv menv ∧
  check_cenv cenv ∧
  check_env {} env
  ⇒
  type_ds mn (convert_menv menv) cenv (bind_var_list2 (convert_env2 env) Empty) ds cenv' (convert_env2 env')`,
 induct_on `ds` >>
 rw [infer_ds_def, success_eqns]
 >- rw [convert_env2_def, Once type_ds_cases, emp_def] >>
 PairCases_on `v'` >>
 fs [success_eqns] >>
 PairCases_on `v'` >>
 fs [success_eqns] >>
 rw [Once type_ds_cases] >>
 fs [init_infer_state_def] >>
 imp_res_tac infer_d_check >>
 `check_cenv (merge_tenvC ([],v'0) cenv)` 
          by (PairCases_on `cenv` >>
              fs [merge_tenvC_def, check_cenv_def, emp_def, merge_def,
                  check_flat_cenv_def]) >>
 `check_env {} (v'1 ++ env)` 
                 by fs [check_env_def, init_infer_state_def] >>
 imp_res_tac infer_d_sound >>
 res_tac >>
 fs [convert_env2_def, emp_def, merge_def, bvl2_append] >>
 metis_tac []);

val db_subst_infer_subst_swap2 = Q.prove (
`(!t s tvs uvar n.
  t_wfs s ∧
  check_t tvs {} t
  ⇒
  (convert_t
    (t_walkstar s
       (infer_deBruijn_subst
          (MAP (λn. Infer_Tuvar n) (COUNT_LIST tvs))
          t)) =
   deBruijn_subst 0
    (MAP (convert_t o t_walkstar s)
       (MAP (λn. Infer_Tuvar n) (COUNT_LIST tvs)))
    (convert_t t))) ∧
 (!ts s tvs uvar n.
  t_wfs s ∧
  EVERY (\t. check_t tvs {} t) ts ⇒
  (MAP (convert_t o
       t_walkstar s o
       infer_deBruijn_subst (MAP (λn. Infer_Tuvar n) (COUNT_LIST tvs)))
      ts =
   MAP (deBruijn_subst 0 (MAP (convert_t o t_walkstar s) (MAP (λn. Infer_Tuvar n) (COUNT_LIST tvs))) o
       convert_t)
      ts))`,
ho_match_mp_tac infer_t_induction >>
rw [convert_t_def, deBruijn_subst_def, EL_MAP, t_walkstar_eqn1,
    infer_deBruijn_subst_def, MAP_MAP_o, combinTheory.o_DEF, check_t_def,
    LENGTH_COUNT_LIST]);

val check_weakE_sound = Q.prove (
`!tenv1 tenv2 st st2.
  check_env {} tenv1 ∧
  check_env {} tenv2 ∧
  (check_weakE tenv1 tenv2 st = (Success (), st2))
  ⇒
  weakE (convert_env2 tenv1) (convert_env2 tenv2)`,
ho_match_mp_tac check_weakE_ind >>
rw [convert_env2_def, check_weakE_def, weakE_def, success_eqns, 
    SIMP_RULE (srw_ss()) [bind_def] check_env_bind] >>
cases_on `lookup n tenv1` >>
fs [success_eqns] >>
`?tvs_impl t_impl. x' = (tvs_impl,t_impl)` by (PairCases_on `x'` >> metis_tac []) >>
rw [] >>
fs [success_eqns] >>
rw [] >>
`lookup n (MAP (λ(x,y). (x,(λ(tvs,t). (tvs, convert_t t)) y)) tenv1) = SOME ((λ(tvs,t). (tvs, convert_t t)) (tvs_impl,t_impl))`
        by metis_tac [lookup_map] >>
fs [remove_pair_lem] >>
`(λ(x,y). (x,FST y,convert_t (SND y))) = (λ(x,tvs:num,t). (x,tvs,convert_t t))`
                by (rw [FUN_EQ_THM] >>
                    PairCases_on `y` >>
                    rw []) >>
rw [] >>
fs [init_state_def, init_infer_state_def] >>
rw [] >|
[fs [] >>
     `t_wfs FEMPTY` by rw [t_wfs_def] >>
     imp_res_tac t_unify_wfs >>
     imp_res_tac t_unify_apply >>
     imp_res_tac check_env_lookup >>
     `?s'. ALL_DISTINCT (MAP FST s') ∧ (FEMPTY |++ s' = FUN_FMAP (\x. Infer_Tapp [] TC_unit) (count tvs_impl DIFF FDOM s))`
                   by metis_tac [fmap_to_list] >>
     `FINITE (count tvs_impl DIFF FDOM s)` by metis_tac [FINITE_COUNT, FINITE_DIFF] >>
     `t_wfs (s |++ s')`
               by (`t_vR s = t_vR (s |++ s')`
                            by (rw [t_vR_eqn, FUN_EQ_THM] >>
                                cases_on `FLOOKUP (s |++ s') x'` >>
                                fs [flookup_update_list_none, flookup_update_list_some] >>
                                cases_on `FLOOKUP s x'` >>
                                fs [flookup_update_list_none, flookup_update_list_some] >>
                                `FLOOKUP (FEMPTY |++ s') x' = SOME x''` by rw [flookup_update_list_some] >>
                                pop_assum mp_tac >>
                                rw [FLOOKUP_FUN_FMAP, t_vars_eqn] >>
                                rw [FLOOKUP_FUN_FMAP, t_vars_eqn] >>
                                fs [FLOOKUP_DEF]) >>
                   fs [t_wfs_eqn]) >>
     `check_s tvs_spec (count tvs_impl) s`
                by (match_mp_tac t_unify_check_s >>
                    MAP_EVERY qexists_tac [`FEMPTY`, `t_spec`, 
                                           `(infer_deBruijn_subst (MAP (λn.  Infer_Tuvar n) (COUNT_LIST tvs_impl)) t_impl)`] >>
                    rw [check_s_def, check_t_infer_db_subst2] >>
                    metis_tac [check_t_more, check_t_more2, arithmeticTheory.ADD_0]) >>
     qexists_tac `MAP (\n. convert_t (t_walkstar (s |++ s') (Infer_Tuvar n))) (COUNT_LIST tvs_impl)` >>
     rw [LENGTH_COUNT_LIST, check_t_to_check_freevars, EVERY_MAP] >|
     [rw [EVERY_MEM] >>
          `FDOM (FEMPTY |++ s') = count tvs_impl DIFF FDOM s` by metis_tac [FDOM_FMAP] >>
          `check_t tvs_spec {} (t_walkstar (s |++ s') (Infer_Tuvar n'))`
                     by (rw [check_t_def] >>
                         match_mp_tac t_walkstar_check >>
                         rw [check_t_def, FDOM_FUPDATE_LIST] >|
                         [fs [check_s_def, fdom_fupdate_list2] >>
                              rw [] >>
                              rw [FUPDATE_LIST_APPLY_NOT_MEM] >>
                              `count tvs_impl ⊆ FDOM s ∪ set (MAP FST s')` by rw [SUBSET_DEF] >|
                              [metis_tac [check_t_more5],
                               metis_tac [check_t_more5],
                               `FLOOKUP (s |++ s') uv = SOME ((s |++ s') ' uv)`
                                           by (rw [FLOOKUP_DEF, FDOM_FUPDATE_LIST]) >>
                                   fs [flookup_update_list_some] >|
                                   [imp_res_tac lookup_in >>
                                        fs [MEM_MAP] >>
                                        rw [] >>
                                        PairCases_on `y` >>
                                        imp_res_tac mem_to_flookup >>
                                        pop_assum mp_tac >>
                                        rw [FLOOKUP_FUN_FMAP] >>
                                        rw [check_t_def],
                                    pop_assum mp_tac >>
                                        rw [FLOOKUP_DEF]]],
                          fs [EXTENSION, MEM_COUNT_LIST] >>
                              res_tac >>
                              fs [FDOM_FUPDATE_LIST]]) >>
          rw [check_t_to_check_freevars],
       imp_res_tac t_walkstar_no_vars >>
          fs [] >>
          rw [SIMP_RULE (srw_ss()) [MAP_MAP_o, combinTheory.o_DEF] (GSYM db_subst_infer_subst_swap2)] >>
          match_mp_tac (METIS_PROVE [] ``x = y ⇒ f x = f y``) >>
          match_mp_tac (SIMP_RULE (srw_ss()) [GSYM RIGHT_FORALL_IMP_THM,AND_IMP_INTRO] no_vars_extend_subst) >>
          rw [] >|
          [rw [DISJOINT_DEF, EXTENSION] >>
               metis_tac [],
           imp_res_tac check_t_t_vars  >>
               fs [EXTENSION, SUBSET_DEF]]],
 metis_tac[]]);

val check_flat_weakC_sound = Q.prove (
`!tenvC1 tenvC2.
  check_flat_weakC tenvC1 tenvC2
  ⇒
  flat_weakC tenvC1 tenvC2`,
induct_on `tenvC2` >>
fs [check_flat_weakC_def, flat_weakC_def, success_eqns] >>
rw [] >>
PairCases_on `h` >>
fs [] >>
rw [] >>
cases_on `lookup cn tenvC1` >>
fs []);

val check_freevars_more = Q.prove (
`(!t x fvs1 fvs2.
  check_freevars x fvs1 t ⇒
  check_freevars x (fvs2++fvs1) t ∧
  check_freevars x (fvs1++fvs2) t) ∧
 (!ts x fvs1 fvs2.
  EVERY (check_freevars x fvs1) ts ⇒
  EVERY (check_freevars x (fvs2++fvs1)) ts ∧
  EVERY (check_freevars x (fvs1++fvs2)) ts)`,
Induct >>
rw [check_freevars_def] >>
metis_tac []);

val t_to_freevars_check = Q.prove (
`(!t st fvs st'.
   (t_to_freevars t (st:'a) = (Success fvs, st'))
   ⇒
   check_freevars 0 fvs t) ∧
 (!ts st fvs st'.
   (ts_to_freevars ts (st:'a) = (Success fvs, st'))
   ⇒
   EVERY (check_freevars 0 fvs) ts)`,
Induct >>
rw [t_to_freevars_def, success_eqns, check_freevars_def] >>
rw [] >>
metis_tac [check_freevars_more]);

val check_freevars_nub = Q.prove (
`(!t x fvs.
  check_freevars x fvs t ⇒
  check_freevars x (nub fvs) t) ∧
 (!ts x fvs.
  EVERY (check_freevars x fvs) ts ⇒
  EVERY (check_freevars x (nub fvs)) ts)`,
Induct >>
rw [check_freevars_def, GSYM nub_set] >>
metis_tac []);

val check_specs_sound = Q.prove (
`!mn cenv env specs st cenv' env' st'.
  (check_specs mn cenv env specs st = (Success (cenv',env'), st'))
  ⇒
  type_specs mn cenv (convert_env2 env) specs cenv' (convert_env2 env')`,
ho_match_mp_tac check_specs_ind >>
rw [check_specs_def, success_eqns] >|
[rw [Once type_specs_cases],
 rw [Once type_specs_cases] >>
     res_tac >>
     `check_freevars 0 fvs t` by metis_tac [t_to_freevars_check] >>
     `check_freevars 0 (nub fvs) t` by metis_tac [check_freevars_nub] >>
     qexists_tac `nub fvs` >>
     rw [] >>
     fs [LENGTH_MAP, convert_t_subst, bind_def, convert_env2_def,
         LENGTH_COUNT_LIST,LENGTH_GENLIST] >>
     fs [MAP_MAP_o, combinTheory.o_DEF, convert_t_def] >>
     metis_tac [COUNT_LIST_GENLIST, combinTheory.I_DEF],
 rw [Once type_specs_cases] >>
     metis_tac [],
 rw [Once type_specs_cases] >>
     fs [bind_def, emp_def] >>
     metis_tac [],
 rw [Once type_specs_cases] >|
     [fs [EVERY_MEM] >>
          rw [] >>
          PairCases_on `p` >>
          rw [] >>
          res_tac >>
          fs [],
      metis_tac []]]);

val infer_top_sound = Q.store_thm ("infer_top_sound",
`!menv cenv env top st1 menv' cenv' env' st2.
  (infer_top menv cenv env top st1 = (Success (menv', cenv', env'), st2)) ∧
  check_menv menv ∧
  check_cenv cenv ∧
  check_env {} env
  ⇒
  type_top (convert_menv menv) cenv (bind_var_list2 (convert_env2 env) Empty) top (convert_menv menv') cenv' (convert_env2 env')`,
cases_on `top` >>
rw [infer_top_def, success_eqns, type_top_cases] >>
PairCases_on `v'` >>
fs [success_eqns] >>
rw [emp_def] >|
[PairCases_on `v'` >>
     fs [success_eqns] >>
     rw [emp_def, convert_menv_def, convert_env2_def] >>
     `type_ds (SOME s) (convert_menv menv) cenv (bind_var_list2 (convert_env2 env) Empty) l v'0 (convert_env2 v'1)`
             by metis_tac [infer_ds_sound] >>
     MAP_EVERY qexists_tac [`v'0`, `convert_env2 v'1`] >>
     rw [] >|
     [rw [MAP_MAP_o, combinTheory.o_DEF, remove_pair_lem] >>
          metis_tac [],
      metis_tac [convert_menv_def, convert_env2_def],
      cases_on `o'` >>
          rw [] >>
          fs [check_signature_cases, check_signature_def, success_eqns] >-
          rw [convert_env2_def] >>
          PairCases_on `v'` >>
          fs [success_eqns] >>
          rw [] >>
          `check_flat_cenv [] ∧ check_env {} ([]:(tvarN, num # infer_t) env)` 
                  by rw [check_flat_cenv_def, check_env_def, check_cenv_def] >>
          `check_env {} v'1 ∧ check_env {} v'1'` by metis_tac [infer_ds_check, check_specs_check] >-
          metis_tac [check_weakE_sound, convert_env2_def] >-
          metis_tac [check_flat_weakC_sound] >>
          imp_res_tac check_specs_sound >>
          fs [convert_env2_def, emp_def]],
 rw [convert_menv_def],
 metis_tac [infer_d_sound]]);

(* ---------- the initial type and inference environments correspond ---------- *)

val infer_init_thm = Q.store_thm ("infer_init_thm",
`check_menv [] ∧ check_cenv ([],[]) ∧ check_env {} init_type_env ∧
 (convert_menv [] = []) ∧
 (bind_var_list2 (convert_env2 init_type_env) Empty = init_tenv)`,
rw [check_t_def, check_menv_def, check_cenv_def, check_env_def, init_type_env_def,
    Infer_Tfn_def, Infer_Tint_def, Infer_Tbool_def, Infer_Tunit_def, 
    Infer_Tref_def, init_tenv_def, bind_var_list2_def, convert_env2_def,
    convert_t_def, convert_menv_def, bind_tenv_def, check_flat_cenv_def]);

val _ = export_theory ();
