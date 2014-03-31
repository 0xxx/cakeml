open preamble;
open alistTheory optionTheory rich_listTheory;
open miscTheory;
open libTheory astTheory semanticPrimitivesTheory bigStepTheory initialEnvTheory terminationTheory;
open libPropsTheory;
open bigClockTheory;
open intLang1Theory;
open evalPropsTheory;
open compilerTerminationTheory;

val _ = new_theory "toIntLang1Proof";

val FST_triple = Q.prove (
`(\(x,y,z). x) = FST`,
rw [FUN_EQ_THM] >>
PairCases_on `x` >>
rw []);

val find_recfun_thm = Q.prove (
`!n funs f x e.
  (find_recfun n [] = NONE) ∧
  (find_recfun n ((f,x,e)::funs) = 
    if f = n then SOME (x,e) else find_recfun n funs)`,
rw [] >>
rw [Once find_recfun_def]);

val find_recfun_lookup = Q.store_thm ("find_recfun_lookup",
`!n funs. find_recfun n funs = lookup n funs`,
 induct_on `funs` >>
 rw [find_recfun_thm] >>
 PairCases_on `h` >>
 rw [find_recfun_thm]);

val lookup_reverse = Q.prove (
`!env x.
  ALL_DISTINCT (MAP FST env)
  ⇒
  lookup x (REVERSE env) = lookup x env`,
induct_on `env` >>
rw [] >>
cases_on `h` >>
rw [lookup_append] >>
every_case_tac >>
fs [] >>
imp_res_tac lookup_in2);

val LUPDATE_MAP = Q.prove (
`!x n l f. MAP f (LUPDATE x n l) = LUPDATE (f x) n (MAP f l)`,
 induct_on `l` >>
 rw [LUPDATE_def] >>
 cases_on `n` >>
 fs [LUPDATE_def]);

val fupdate_list_foldr = Q.prove (
`!m l. FOLDR (λ(k,v) env. env |+ (k,v)) m l = m |++ REVERSE l`,
 induct_on `l` >>
 rw [FUPDATE_LIST] >>
 PairCases_on `h` >>
 rw [FOLDL_APPEND]);

val fupdate_list_foldl = Q.prove (
`!m l. FOLDL (λenv (k,v). env |+ (k,v)) m l = m |++ l`,
 induct_on `l` >>
 rw [FUPDATE_LIST] >>
 PairCases_on `h` >>
 rw []);

val disjoint_drestrict = Q.prove (
`!s m. DISJOINT s (FDOM m) ⇒ DRESTRICT m (COMPL s) = m`,
 rw [fmap_eq_flookup, FLOOKUP_DRESTRICT] >>
 cases_on `k ∉ s` >>
 rw [] >>
 fs [DISJOINT_DEF, EXTENSION, FLOOKUP_DEF] >>
 metis_tac []);

val compl_insert = Q.prove (
`!s x. COMPL (x INSERT s) = COMPL s DELETE x`,
 rw [EXTENSION] >>
 metis_tac []);

val drestrict_iter_list = Q.prove (
`!m l. FOLDR (\k m. m \\ k) m l = DRESTRICT m (COMPL (set l))`,
 induct_on `l` >>
 rw [DRESTRICT_UNIV, compl_insert, DRESTRICT_DOMSUB]);

val pat_bindings_accum = Q.store_thm ("pat_bindings_accum",
`(!p acc. pat_bindings p acc = pat_bindings p [] ++ acc) ∧
 (!ps acc. pats_bindings ps acc = pats_bindings ps [] ++ acc)`,
 Induct >>
 rw []
 >- rw [pat_bindings_def]
 >- rw [pat_bindings_def]
 >- metis_tac [APPEND_ASSOC, pat_bindings_def]
 >- metis_tac [APPEND_ASSOC, pat_bindings_def]
 >- rw [pat_bindings_def]
 >- metis_tac [APPEND_ASSOC, pat_bindings_def]);

val pmatch_extend = Q.prove (
`(!cenv s p v env env' env''.
  pmatch cenv s p v env = Match env'
  ⇒
  ?env''. env' = env'' ++ env ∧ MAP FST env'' = pat_bindings p []) ∧
 (!cenv s ps vs env env' env''.
  pmatch_list cenv s ps vs env = Match env'
  ⇒
  ?env''. env' = env'' ++ env ∧ MAP FST env'' = pats_bindings ps [])`,
 ho_match_mp_tac pmatch_ind >>
 rw [pat_bindings_def, pmatch_def, bind_def] >>
 every_case_tac >>
 fs [] >>
 rw [] >>
 res_tac >>
 qexists_tac `env'''++env''` >>
 rw [] >>
 metis_tac [pat_bindings_accum]);

val pmatch_i1_extend = Q.prove (
`(!cenv s p v env env' env''.
  pmatch_i1 cenv s p v env = Match env'
  ⇒
  ?env''. env' = env'' ++ env ∧ MAP FST env'' = pat_bindings p []) ∧
 (!cenv s ps vs env env' env''.
  pmatch_list_i1 cenv s ps vs env = Match env'
  ⇒
  ?env''. env' = env'' ++ env ∧ MAP FST env'' = pats_bindings ps [])`,
 ho_match_mp_tac pmatch_i1_ind >>
 rw [pat_bindings_def, pmatch_i1_def, bind_def] >>
 every_case_tac >>
 fs [] >>
 rw [] >>
 res_tac >>
 qexists_tac `env'''++env''` >>
 rw [] >>
 metis_tac [pat_bindings_accum]);

val (v_to_i1_rules, v_to_i1_ind, v_to_i1_cases) = Hol_reln `
(!genv lit.
  v_to_i1 genv (Litv lit) (Litv_i1 lit)) ∧
(!genv cn vs vs'.
  vs_to_i1 genv vs vs'
  ⇒ 
  v_to_i1 genv (Conv cn vs) (Conv_i1 cn vs')) ∧
(!genv mods tops menv cenv env x e env' env_i1.
  env_to_i1 genv env env_i1 ∧
  set (MAP FST env') DIFF set (MAP FST env) ⊆ FDOM tops ∧
  global_env_inv genv mods tops menv (set (MAP FST env_i1)) env'
  ⇒ 
  v_to_i1 genv (Closure (menv,cenv,env++env') x e) 
               (Closure_i1 (cenv, env_i1) x (exp_to_i1 mods (DRESTRICT tops (COMPL (set (MAP FST env_i1))) \\ x) e))) ∧
(* For expression level let recs *)
(!genv mods tops menv cenv env funs x env' env_i1.
  env_to_i1 genv env env_i1 ∧
  set (MAP FST env') DIFF set (MAP FST env) ⊆ FDOM tops ∧
  global_env_inv genv mods tops menv (set (MAP FST env_i1)) env'
  ⇒
  v_to_i1 genv (Recclosure (menv,cenv,env++env') funs x) 
               (Recclosure_i1 (cenv,env_i1) (funs_to_i1 mods (DRESTRICT tops (COMPL (set (MAP FST env_i1) ∪ set (MAP FST funs)))) funs) x)) ∧
(* For top-level let recs *)
(!genv mods tops menv cenv env funs x y e tops'.
  set (MAP FST env) ⊆ FDOM tops ∧
  global_env_inv genv mods tops menv {} env ∧
  MAP FST (REVERSE tops') = MAP FST funs ∧
  find_recfun x funs = SOME (y,e) ∧
  (* A syntactic way of relating the recursive function environment, rather 
   * than saying that they build v_to_i1 related environments, which looks to 
   * require step-indexing *)
  (!x. x ∈ set (MAP FST funs) ⇒ 
       ?n y e. 
         FLOOKUP (FEMPTY |++ tops') x = SOME n ∧ 
         n < LENGTH genv ∧ 
         find_recfun x funs = SOME (y,e) ∧
         EL n genv = SOME (Closure_i1 (cenv,[]) y (exp_to_i1 mods ((tops |++ tops') \\ y) e)))
  ⇒
  v_to_i1 genv (Recclosure (menv,cenv,env) funs x) 
               (Closure_i1 (cenv,[]) y (exp_to_i1 mods ((tops |++ tops') \\ y) e))) ∧
(!genv loc.
  v_to_i1 genv (Loc loc) (Loc_i1 loc)) ∧
(!genv.
  vs_to_i1 genv [] []) ∧
(!genv v vs v' vs'.
  v_to_i1 genv v v' ∧
  vs_to_i1 genv vs vs'
  ⇒
  vs_to_i1 genv (v::vs) (v'::vs')) ∧
(!genv.
  env_to_i1 genv [] []) ∧
(!genv x v env env' v'. 
  env_to_i1 genv env env' ∧
  v_to_i1 genv v v'
  ⇒ 
  env_to_i1 genv ((x,v)::env) ((x,v')::env')) ∧
(!genv map shadowers env.
  (!x v.
     x ∉ shadowers ∧
     lookup x env = SOME v
     ⇒
     ?n v_i1.
       FLOOKUP map x = SOME n ∧
       n < LENGTH genv ∧
       EL n genv = SOME v_i1 ∧
       v_to_i1 genv v v_i1)
  ⇒ 
  global_env_inv_flat genv map shadowers env) ∧
(!genv mods tops menv shadowers env.
  global_env_inv_flat genv tops shadowers env ∧
  (!mn env'.
    lookup mn menv = SOME env'
    ⇒
    ?map.
      FLOOKUP mods mn = SOME map ∧
      global_env_inv_flat genv map {} env')
  ⇒
  global_env_inv genv mods tops menv shadowers env)`;

val v_to_i1_eqns = Q.prove (
`(!genv l v.
  v_to_i1 genv (Litv l) v ⇔ 
    (v = Litv_i1 l)) ∧
 (!genv cn vs v.
  v_to_i1 genv (Conv cn vs) v ⇔ 
    ?vs'. vs_to_i1 genv vs vs' ∧ (v = Conv_i1 cn vs')) ∧
 (!genv l v.
  v_to_i1 genv (Loc l) v ⇔ 
    (v = Loc_i1 l)) ∧
 (!genv vs.
  vs_to_i1 genv [] vs ⇔ 
    (vs = [])) ∧
 (!genv l v vs vs'.
  vs_to_i1 genv (v::vs) vs' ⇔ 
    ?v' vs''. v_to_i1 genv v v' ∧ vs_to_i1 genv vs vs'' ∧ vs' = v'::vs'') ∧
 (!genv env'.
  env_to_i1 genv [] env' ⇔
    env' = []) ∧
 (!genv x v env env'.
  env_to_i1 genv ((x,v)::env) env' ⇔
    ?v' env''. v_to_i1 genv v v' ∧ env_to_i1 genv env env'' ∧ env' = ((x,v')::env'')) ∧
 (!genv map shadowers env genv.
  global_env_inv_flat genv map shadowers env ⇔
    (!x v.
      x ∉ shadowers ∧
      lookup x env = SOME v
      ⇒
      ?n v_i1.
        FLOOKUP map x = SOME n ∧
        n < LENGTH genv ∧
        EL n genv = SOME v_i1 ∧
        v_to_i1 genv v v_i1)) ∧
(!genv mods tops menv shadowers env genv.
  global_env_inv genv mods tops menv shadowers env ⇔
    global_env_inv_flat genv tops shadowers env ∧
    (!mn env'.
      lookup mn menv = SOME env'
      ⇒
      ?map.
        FLOOKUP mods mn = SOME map ∧
        global_env_inv_flat genv map {} env'))`,
rw [] >>
rw [Once v_to_i1_cases] >>
metis_tac []);

val v_to_i1_weakening = Q.prove (
`(!genv v v_i1.
  v_to_i1 genv v v_i1
  ⇒
  ∀l. v_to_i1 (genv++l) v v_i1) ∧
 (!genv vs vs_i1.
  vs_to_i1 genv vs vs_i1
  ⇒
  !l. vs_to_i1 (genv++l) vs vs_i1) ∧
 (!genv env env_i1.
  env_to_i1 genv env env_i1
  ⇒
  !l. env_to_i1 (genv++l) env env_i1) ∧
 (!genv map shadowers env.
  global_env_inv_flat genv map shadowers env
  ⇒
  !l. global_env_inv_flat (genv++l) map shadowers env) ∧
 (!genv mods tops menv shadowers env.
  global_env_inv genv mods tops menv shadowers env
  ⇒
  !l.global_env_inv (genv++l) mods tops menv shadowers env)`,
 ho_match_mp_tac v_to_i1_ind >>
 rw [v_to_i1_eqns]
 >- (rw [Once v_to_i1_cases] >>
     MAP_EVERY qexists_tac [`mods`, `tops`, `env`, `env'`] >>
     fs [FDOM_FUPDATE_LIST, SUBSET_DEF, v_to_i1_eqns])
 >- (rw [Once v_to_i1_cases] >>
     MAP_EVERY qexists_tac [`mods`, `tops`, `env`, `env'`] >>
     fs [FDOM_FUPDATE_LIST, SUBSET_DEF, v_to_i1_eqns])
 >- (rw [Once v_to_i1_cases] >>
     MAP_EVERY qexists_tac [`mods`, `tops`, `tops'`] >>
     fs [FDOM_FUPDATE_LIST, SUBSET_DEF, v_to_i1_eqns, EL_APPEND1] >>
     rw [] >>
     res_tac >>
     qexists_tac `n` >>
     rw [EL_APPEND1] >>
     decide_tac)
 >- metis_tac [DECIDE ``x < y ⇒ x < y + l:num``, EL_APPEND1]
 >- metis_tac []);

val (result_to_i1_rules, result_to_i1_ind, result_to_i1_cases) = Hol_reln `
(∀genv v v'. 
  f genv v v'
  ⇒
  result_to_i1 f genv (Rval v) (Rval v')) ∧
(∀genv v v'. 
  v_to_i1 genv v v'
  ⇒
  result_to_i1 f genv (Rerr (Rraise v)) (Rerr (Rraise v'))) ∧
(!genv.
  result_to_i1 f genv (Rerr Rtimeout_error) (Rerr Rtimeout_error)) ∧
(!genv.
  result_to_i1 f genv (Rerr Rtype_error) (Rerr Rtype_error))`;

val result_to_i1_eqns = Q.prove (
`(!genv v r.
  result_to_i1 f genv (Rval v) r ⇔ 
    ?v'. f genv v v' ∧ r = Rval v') ∧
 (!genv v r.
  result_to_i1 f genv (Rerr (Rraise v)) r ⇔ 
    ?v'. v_to_i1 genv v v' ∧ r = Rerr (Rraise v')) ∧
 (!genv v r.
  result_to_i1 f genv (Rerr Rtimeout_error) r ⇔ 
    r = Rerr Rtimeout_error) ∧
 (!genv v r.
  result_to_i1 f genv (Rerr Rtype_error) r ⇔ 
    r = Rerr Rtype_error)`,
rw [result_to_i1_cases] >>
metis_tac []);

val (s_to_i1'_rules, s_to_i1'_ind, s_to_i1'_cases) = Hol_reln `
(!genv s s'.
  vs_to_i1 genv s s'
  ⇒
  s_to_i1' genv s s')`;

val (s_to_i1_rules, s_to_i1_ind, s_to_i1_cases) = Hol_reln `
(!genv c s s'.
  s_to_i1' genv s s'
  ⇒
  s_to_i1 genv (c,s) (c,s'))`;

val (env_all_to_i1_rules, env_all_to_i1_ind, env_all_to_i1_cases) = Hol_reln `
(!genv mods tops menv cenv env env' env_i1 locals.
  locals = set (MAP FST env) ∧
  global_env_inv genv mods tops menv locals env' ∧
  env_to_i1 genv env env_i1
  ⇒
  env_all_to_i1 genv mods tops (menv,cenv,env++env') (genv,cenv,env_i1) locals)`;

val env_to_i1_append = Q.prove (
`!genv env1 env2 env1' env2'.
  env_to_i1 genv env1 env1' ∧
  env_to_i1 genv env2 env2' 
  ⇒
  env_to_i1 genv (env1++env2) (env1'++env2')`,
 induct_on `env1` >>
 rw [v_to_i1_eqns] >>
 PairCases_on `h` >>
 fs [v_to_i1_eqns]);

val env_to_i1_reverse = Q.prove (
`!genv env1 env2.
  env_to_i1 genv env1 env2
  ⇒
  env_to_i1 genv (REVERSE env1) (REVERSE env2)`,
 induct_on `env1` >>
 rw [v_to_i1_eqns] >>
 PairCases_on `h` >>
 fs [v_to_i1_eqns] >>
 match_mp_tac env_to_i1_append >>
 rw [v_to_i1_eqns]);

val do_con_check_i1 = Q.prove (
`!genv mods tops env cn es env_i1 locals. 
  do_con_check (all_env_to_cenv env) cn (LENGTH es) ∧
  env_all_to_i1 genv mods tops env env_i1 locals
  ⇒
  do_con_check (all_env_i1_to_cenv env_i1) cn (LENGTH (exps_to_i1 mods (DRESTRICT tops (COMPL locals)) es))`,
 rw [do_con_check_def] >>
 every_case_tac >>
 fs [env_all_to_i1_cases] >>
 rw [] >>
 fs [all_env_i1_to_cenv_def, all_env_to_cenv_def] >>
 rw [] >>
 ntac 3 (pop_assum (fn _ => all_tac)) >>
 induct_on `es` >>
 rw [exp_to_i1_def]);

val build_conv_i1 = Q.prove (
`!genv mods tops env cn vs v vs' env_i1 locals.
  (build_conv (all_env_to_cenv env) cn vs = SOME v) ∧
  env_all_to_i1 genv mods tops env env_i1 locals ∧
  vs_to_i1 genv vs vs'
  ⇒
  ∃v'.
    v_to_i1 genv v v' ∧
    build_conv_i1 (all_env_i1_to_cenv env_i1) cn vs' = SOME v'`,
 rw [build_conv_def, build_conv_i1_def] >>
 every_case_tac >>
 rw [Once v_to_i1_cases] >>
 fs [env_all_to_i1_cases] >>
 rw [] >>
 fs [all_env_i1_to_cenv_def, all_env_to_cenv_def]);

val global_env_inv_lookup_top = Q.prove (
`!genv mods tops menv shadowers env x v n.
  global_env_inv genv mods tops menv shadowers env ∧
  lookup x env = SOME v ∧
  x ∉ shadowers ∧
  FLOOKUP tops x = SOME n
  ⇒
  ?v_i1. LENGTH genv > n ∧ EL n genv = SOME v_i1 ∧ v_to_i1 genv v v_i1`,
 rw [v_to_i1_eqns] >>
 res_tac >>
 full_simp_tac (srw_ss()++ARITH_ss) [] >>
 metis_tac []);

val env_to_i1_lookup = Q.prove (
`!genv menv env genv x v env'.
  lookup x env = SOME v ∧
  env_to_i1 genv env env'
  ⇒
  ?v'.
    v_to_i1 genv v v' ∧
    lookup x env' = SOME v'`,
 induct_on `env` >>
 rw [] >>
 PairCases_on `h` >>
 fs [] >>
 cases_on `h0 = x` >>
 fs [] >>
 rw [] >>
 fs [v_to_i1_eqns]);

val global_env_inv_lookup_mod1 = Q.prove (
`!genv mods tops menv shadowers env genv mn n env'.
  global_env_inv genv mods tops menv shadowers env ∧
  lookup mn menv = SOME env'
  ⇒
  ?n. FLOOKUP mods mn = SOME n`,
 rw [] >>
 fs [v_to_i1_eqns] >>
 metis_tac []);

val global_env_inv_lookup_mod2 = Q.prove (
`!genv mods tops menv shadowers env genv mn n env' x v map.
  global_env_inv genv mods tops menv shadowers env ∧
  lookup mn menv = SOME env' ∧
  lookup x env' = SOME v ∧
  FLOOKUP mods mn = SOME map
  ⇒
  ?n. FLOOKUP map x = SOME n`,
 rw [] >>
 fs [v_to_i1_eqns] >>
 res_tac >>
 fs [] >>
 rw [] >>
 res_tac >>
 fs []);

val global_env_inv_lookup_mod3 = Q.prove (
`!genv mods tops menv shadowers env genv mn n env' x v map n.
  global_env_inv genv mods tops menv shadowers env ∧
  lookup mn menv = SOME env' ∧
  lookup x env' = SOME v ∧
  FLOOKUP mods mn = SOME map ∧
  FLOOKUP map x = SOME n
  ⇒
  LENGTH genv > n ∧ ?v_i1. EL n genv = SOME v_i1 ∧ v_to_i1 genv v v_i1`,
 rw [] >>
 fs [v_to_i1_eqns] >>
 res_tac >>
 fs [] >>
 rw [] >>
 res_tac >>
 full_simp_tac (srw_ss()++ARITH_ss) [] >>
 metis_tac []);

val global_env_inv_add_locals = Q.prove (
`!genv mods tops menv locals1 locals2 env.
  global_env_inv genv mods tops menv locals1 env
  ⇒
  global_env_inv genv mods tops menv (locals2 ∪ locals1) env`,
 rw [v_to_i1_eqns]);

val env_to_i1_dom = Q.prove (
`!genv env env_i1.
  env_to_i1 genv env env_i1
  ⇒
  MAP FST env = MAP FST env_i1`,
 induct_on `env` >>
 rw [v_to_i1_eqns] >>
 PairCases_on `h` >> 
 fs [v_to_i1_eqns] >>
 rw [] >>
 metis_tac []);

val vs_to_i1_append1 = Q.prove (
`!genv vs v vs' v'.
  vs_to_i1 genv (vs++[v]) (vs'++[v'])
  ⇔
  vs_to_i1 genv vs vs' ∧
  v_to_i1 genv v v'`,
 induct_on `vs` >>
 rw [] >>
 cases_on `vs'` >>
 rw [v_to_i1_eqns] 
 >- (cases_on `vs` >>
     rw [v_to_i1_eqns]) >>
 metis_tac []);

val length_env_to_i1 = Q.prove (
`!env genv env'. 
  env_to_i1 genv env env'
  ⇒
  LENGTH env = LENGTH env'`,
 induct_on `env` >>
 rw [v_to_i1_eqns] >>
 PairCases_on `h` >>
 fs [v_to_i1_eqns] >>
 metis_tac []);

val length_vs_to_i1 = Q.prove (
`!vs genv vs'. 
  vs_to_i1 genv vs vs'
  ⇒
  LENGTH vs = LENGTH vs'`,
 induct_on `vs` >>
 rw [v_to_i1_eqns] >>
 fs [] >>
 metis_tac []);

val store_lookup_vs_to_i1 = Q.prove (
`!genv vs vs_i1 v v_i1 n.
  vs_to_i1 genv vs vs_i1 ∧
  store_lookup n vs = SOME v ∧
  store_lookup n vs_i1 = SOME v_i1
  ⇒
  v_to_i1 genv v v_i1`,
 induct_on `vs` >>
 rw [v_to_i1_eqns] >>
 fs [store_lookup_def] >>
 cases_on `n` >>
 fs [] >>
 metis_tac []);

val do_uapp_i1 = Q.prove (
`!genv s1 s2 uop v1 v2 s1_i1 v1_i1. 
  do_uapp s1 uop v1 = SOME (s2, v2) ∧
  s_to_i1' genv s1 s1_i1 ∧
  v_to_i1 genv v1 v1_i1
  ⇒
  ∃v2_i1 s2_i1.
    s_to_i1' genv s2 s2_i1 ∧
    v_to_i1 genv v2 v2_i1 ∧
    do_uapp_i1 s1_i1 uop v1_i1 = SOME (s2_i1, v2_i1)`,
 rw [do_uapp_def, do_uapp_i1_def] >>
 every_case_tac >>
 fs [store_alloc_def, LET_THM] >>
 rw [] >>
 fs [v_to_i1_eqns, s_to_i1'_cases, vs_to_i1_append1] >>
 imp_res_tac length_vs_to_i1 >>
 rw []
 >- fs [store_lookup_def] >>
 metis_tac [store_lookup_vs_to_i1]);

val do_eq_i1 = Q.prove (
`(!v1 v2 genv r v1_i1 v2_i1.
  do_eq v1 v2 = r ∧
  v_to_i1 genv v1 v1_i1 ∧
  v_to_i1 genv v2 v2_i1
  ⇒ 
  do_eq_i1 v1_i1 v2_i1 = r) ∧
 (!vs1 vs2 genv r vs1_i1 vs2_i1.
  do_eq_list vs1 vs2 = r ∧
  vs_to_i1 genv vs1 vs1_i1 ∧
  vs_to_i1 genv vs2 vs2_i1
  ⇒ 
  do_eq_list_i1 vs1_i1 vs2_i1 = r)`,
 ho_match_mp_tac do_eq_ind >>
 rw [do_eq_i1_def, do_eq_def, v_to_i1_eqns] >>
 rw [] >>
 rw [do_eq_i1_def, do_eq_def, v_to_i1_eqns] >>
 imp_res_tac length_vs_to_i1 >>
 fs []
 >- metis_tac []
 >- (fs [Once v_to_i1_cases] >>
     rw [do_eq_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [do_eq_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [do_eq_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [do_eq_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [do_eq_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [do_eq_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [do_eq_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [do_eq_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [do_eq_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [do_eq_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [do_eq_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [do_eq_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [do_eq_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [do_eq_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [do_eq_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [do_eq_i1_def]) >>
 res_tac >>
 every_case_tac >>
 fs [] >>
 metis_tac []);

val env_all_to_i1_exn = Q.prove (
`!genv tops mods. env_all_to_i1 genv mods tops exn_env (exn_env_i1 genv) {}`,
 rw [exn_env_def, exn_env_i1_def, env_all_to_i1_cases, emp_def, v_to_i1_eqns]);

val vs_to_i1_lupdate = Q.prove (
`!genv v n s v_i1 n s_i1.
  vs_to_i1 genv s s_i1 ∧
  v_to_i1 genv v v_i1
  ⇒
  vs_to_i1 genv (LUPDATE v n s) (LUPDATE v_i1 n s_i1)`,
 induct_on `n` >>
 rw [v_to_i1_eqns, LUPDATE_def] >>
 cases_on `s` >>
 fs [v_to_i1_eqns, LUPDATE_def]);

val find_recfun_to_i1 = Q.prove (
`!x funs e mods tops y.
  find_recfun x funs = SOME (y,e)
  ⇒
  find_recfun x (funs_to_i1 mods tops funs) = SOME (y,exp_to_i1 mods (tops \\ y) e)`,
 induct_on `funs` >>
 rw [Once find_recfun_def, exp_to_i1_def] >>
 PairCases_on `h` >>
 fs [] >>
 every_case_tac >>
 fs [Once find_recfun_def, exp_to_i1_def]);

val build_rec_env_i1_help_lem = Q.prove (
`∀funs env funs'.
FOLDR (λ(f,x,e) env'. bind f (Recclosure_i1 env funs' f) env') env' funs =
merge (MAP (λ(fn,n,e). (fn, Recclosure_i1 env funs' fn)) funs) env'`,
Induct >>
rw [merge_def, bind_def] >>
PairCases_on `h` >>
rw []);

val funs_to_i1_dom = Q.prove (
`!funs.
  (MAP (λ(x,y,z). x) funs)
  =
  (MAP (λ(x,y,z). x) (funs_to_i1 mods tops funs))`,
 induct_on `funs` >>
 rw [exp_to_i1_def] >>
 PairCases_on `h` >>
 rw [exp_to_i1_def]);

val do_app_rec_help = Q.prove (
`!genv menv'' cenv'' env' funs env''' env_i1' mods' tops' funs'.
  env_to_i1 genv env' env_i1' ∧
  set (MAP FST env''') DIFF set (MAP FST env') ⊆ FDOM tops' ∧
  global_env_inv genv mods' tops' menv'' (set (MAP FST env_i1')) env'''
  ⇒
  env_to_i1 genv
  (MAP
     (λ(fn,n,e). (fn,Recclosure (menv'',cenv'',env' ++ env''') funs' fn))
     funs)
  (MAP
     (λ(fn,n,e).
        (fn,
         Recclosure_i1 (cenv'',env_i1')
           (funs_to_i1 mods'
              (DRESTRICT tops'
                 (COMPL (set (MAP FST env_i1') ∪ set (MAP FST funs'))))
              funs') fn))
     (funs_to_i1 mods'
        (DRESTRICT tops'
           (COMPL (set (MAP FST env_i1') ∪ set (MAP FST funs')))) funs))`,
 induct_on `funs` >>
 rw [v_to_i1_eqns, exp_to_i1_def] >>
 PairCases_on `h` >>
 rw [v_to_i1_eqns, exp_to_i1_def] >>
 rw [Once v_to_i1_cases] >>
 MAP_EVERY qexists_tac [`mods'`, `tops'`, `env'`, `env'''`] >>
 rw [] >>
 fs [v_to_i1_eqns]);

(* Alternate definition for build_rec_env_i1 *)
val build_rec_env_i1_merge = Q.store_thm ("build_rec_env_i1_merge",
`∀funs funs' env env'.
  build_rec_env_i1 funs env env' =
  merge (MAP (λ(fn,n,e). (fn, Recclosure_i1 env funs fn)) funs) env'`,
rw [build_rec_env_i1_def, build_rec_env_i1_help_lem]);

val global_env_inv_extend2 = Q.prove (
`!genv mods tops menv env tops' env' locals.
  MAP FST env' = REVERSE (MAP FST tops') ∧
  global_env_inv genv mods tops menv locals env ∧
  global_env_inv genv FEMPTY (FEMPTY |++ tops') [] locals env'
  ⇒
  global_env_inv genv mods (tops |++ tops') menv locals (env'++env)`,
 rw [v_to_i1_eqns, flookup_fupdate_list] >>
 full_case_tac >> 
 fs [lookup_append] >>
 full_case_tac >> 
 fs [] >>
 res_tac >>
 fs [] >>
 rpt (pop_assum mp_tac) >>
 rw [] >>
 imp_res_tac lookup_notin >>
 imp_res_tac ALOOKUP_MEM >>
 metis_tac [MEM_REVERSE, MEM_MAP, FST]);

val lookup_build_rec_env_lem = Q.prove (
`!x cl_env funs' funs.
  lookup x (MAP (λ(fn,n,e). (fn,Recclosure cl_env funs' fn)) funs) = SOME v
  ⇒
  v = Recclosure cl_env funs' x`,
 induct_on `funs` >>
 rw [] >>
 PairCases_on `h` >>
 fs [] >>
 every_case_tac >>
 fs []);

val do_app_i1 = Q.prove (
`!genv mods tops env s1 s2 op v1 v2 e env' env_i1 s1_i1 v1_i1 v2_i1 locals.
  do_app env s1 op v1 v2 = SOME (env', s2, e) ∧
  s_to_i1' genv s1 s1_i1 ∧
  v_to_i1 genv v1 v1_i1 ∧
  v_to_i1 genv v2 v2_i1 ∧
  env_all_to_i1 genv mods tops env env_i1 locals ∧
  genv = all_env_i1_to_genv env_i1
  ⇒
   ∃env'_i1 s2_i1 locals' mods' tops'.
     s_to_i1' genv s2 s2_i1 ∧
     env_all_to_i1 genv mods' tops' env' env'_i1 locals' ∧
     do_app_i1 env_i1 s1_i1 op v1_i1 v2_i1 = SOME (env'_i1, s2_i1, exp_to_i1 mods' (DRESTRICT tops' (COMPL locals')) e)`,
 rw [do_app_cases, do_app_i1_def] >>
 fs [v_to_i1_eqns, exp_to_i1_def]
 >- metis_tac [env_all_to_i1_exn]
 >- metis_tac [env_all_to_i1_exn]
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- (every_case_tac >>
     metis_tac [do_eq_i1, eq_result_11, eq_result_distinct])
 >- (every_case_tac >>
     metis_tac [do_eq_i1, eq_result_distinct, env_all_to_i1_exn])
 >- (qpat_assum `v_to_i1 genv (Closure (menv'',cenv'',env'') n e) v1_i1` mp_tac >>
     rw [Once v_to_i1_cases] >>
     rw [] >>
     qexists_tac `n INSERT set (MAP FST env_i1')` >>
     rw [DRESTRICT_DOMSUB, compl_insert, env_all_to_i1_cases] >>
     MAP_EVERY qexists_tac [`mods'`, `tops'`] >>
     rw [] >>
     MAP_EVERY qexists_tac [`bind n v2 env'`, `env'''`] >>
     rw [bind_def, v_to_i1_eqns]
     >- metis_tac [env_to_i1_dom] >>
     fs [v_to_i1_eqns])
 >- (qpat_assum `v_to_i1 genv (Recclosure (menv'',cenv'',env'') funs n') v1_i1` mp_tac >>
     rw [Once v_to_i1_cases] >>
     rw [] >>
     imp_res_tac find_recfun_to_i1 >>
     rw []
     >- (qexists_tac `n'' INSERT set (MAP FST env_i1') ∪ set (MAP FST funs)` >>
         rw [DRESTRICT_DOMSUB, compl_insert, env_all_to_i1_cases] >>
         MAP_EVERY qexists_tac [`mods'`, `tops'`] >>
         rw [] >>
         MAP_EVERY qexists_tac [`bind n'' v2 (build_rec_env funs (menv'',cenv'',env' ++ env''') env')`, `env'''`] >>
         rw [bind_def, build_rec_env_merge, merge_def, EXTENSION]
         >- (rw [MEM_MAP, EXISTS_PROD] >>
             imp_res_tac env_to_i1_dom >>
             metis_tac [pair_CASES, FST, MEM_MAP, EXISTS_PROD, LAMBDA_PROD])
         >- metis_tac [INSERT_SING_UNION, global_env_inv_add_locals, UNION_COMM]
         >- (fs [v_to_i1_eqns, build_rec_env_i1_merge, merge_def] >>
             match_mp_tac env_to_i1_append >>
             rw [] >>
             match_mp_tac do_app_rec_help >>
             rw [] >>
             fs [v_to_i1_eqns]))
     >- (qexists_tac `{n''}` >>
         rw [DRESTRICT_UNIV, GSYM DRESTRICT_DOMSUB, compl_insert, env_all_to_i1_cases] >>
         MAP_EVERY qexists_tac [`mods'`, `tops'|++tops''`] >>
         rw [] >>
         MAP_EVERY qexists_tac [`[(n'',v2)]`, `build_rec_env funs (menv'',cenv'',env'') env''`] >>
         rw [bind_def, build_rec_env_merge, merge_def, EXTENSION]
         >- (match_mp_tac global_env_inv_extend2 >>
             rw [MAP_MAP_o, combinTheory.o_DEF, LAMBDA_PROD, FST_triple, GSYM MAP_REVERSE]
             >- metis_tac [global_env_inv_add_locals, UNION_EMPTY] >>
             rw [v_to_i1_eqns] >>
             `MEM x (MAP FST funs)`
                       by (imp_res_tac lookup_in2 >>
                           fs [MEM_MAP] >>
                           PairCases_on `y'` >>
                           rw [] >>
                           metis_tac [FST]) >>
             res_tac >>
             qexists_tac `n` >>
             rw [] >>
             `v = Recclosure (menv'',cenv'',env'') funs x` by metis_tac [lookup_build_rec_env_lem] >>
             rw [Once v_to_i1_cases] >>
             MAP_EVERY qexists_tac [`mods'`, `tops'`, `tops''`] >>
             rw [find_recfun_lookup])
         >- fs [v_to_i1_eqns, build_rec_env_i1_merge, merge_def]))
 >- (every_case_tac >>
     fs [store_assign_def, s_to_i1'_cases]
     >- (metis_tac [length_vs_to_i1]) >>
     rw [] >>
     metis_tac [vs_to_i1_lupdate]));

val match_result_to_i1_def = Define 
`(match_result_to_i1 genv env' (Match env) (Match env_i1) = 
   ?env''. env = env'' ++ env' ∧ env_to_i1 genv env'' env_i1) ∧
 (match_result_to_i1 genv env' No_match No_match = T) ∧
 (match_result_to_i1 genv env' Match_type_error Match_type_error = T) ∧
 (match_result_to_i1 genv env' _ _ = F)`;

val pmatch_to_i1_correct = Q.prove (
`(!cenv s p v env r env' env'' genv env_i1 s_i1 v_i1.
  pmatch cenv s p v env = r ∧
  env = env' ++ env'' ∧
  s_to_i1' genv s s_i1 ∧
  v_to_i1 genv v v_i1 ∧
  env_to_i1 genv env' env_i1
  ⇒
  ?r_i1.
    pmatch_i1 cenv s_i1 p v_i1 env_i1 = r_i1 ∧
    match_result_to_i1 genv env'' r r_i1) ∧
 (!cenv s ps vs env r env' env'' genv env_i1 s_i1 vs_i1.
  pmatch_list cenv s ps vs env = r ∧
  env = env' ++ env'' ∧
  s_to_i1' genv s s_i1 ∧
  vs_to_i1 genv vs vs_i1 ∧
  env_to_i1 genv env' env_i1
  ⇒
  ?r_i1.
    pmatch_list_i1 cenv s_i1 ps vs_i1 env_i1 = r_i1 ∧
    match_result_to_i1 genv env'' r r_i1)`,
 ho_match_mp_tac pmatch_ind >>
 rw [pmatch_def, pmatch_i1_def] >>
 fs [match_result_to_i1_def, bind_def, pmatch_i1_def, v_to_i1_eqns]
 >- (every_case_tac >>
     fs [match_result_to_i1_def])
 >- (every_case_tac >>
     fs [match_result_to_i1_def] >>
     metis_tac [length_vs_to_i1])
 >- (every_case_tac >>
     fs [match_result_to_i1_def, s_to_i1'_cases]
     >- (fs [store_lookup_def] >>
         metis_tac [length_vs_to_i1])
     >- (fs [store_lookup_def] >>
         metis_tac [length_vs_to_i1])
     >- metis_tac [store_lookup_vs_to_i1])
 >- (fs [Once v_to_i1_cases] >>
     rw [pmatch_i1_def, match_result_to_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [pmatch_i1_def, match_result_to_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [pmatch_i1_def, match_result_to_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [pmatch_i1_def, match_result_to_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [pmatch_i1_def, match_result_to_i1_def])
 >- (fs [Once v_to_i1_cases] >>
     rw [pmatch_i1_def, match_result_to_i1_def])
 >- (every_case_tac >>
     fs [match_result_to_i1_def] >>
     rw [] >>
     pop_assum mp_tac >>
     pop_assum mp_tac >>
     res_tac >>
     rw [] >>
     CCONTR_TAC >>
     fs [match_result_to_i1_def] >>
     metis_tac [match_result_to_i1_def, match_result_distinct]));

val exp_to_i1_correct = Q.prove (
`(∀b env s e res. 
   evaluate b env s e res ⇒ 
   (SND res ≠ Rerr Rtype_error) ⇒
   !genv mods tops s' r env_i1 s_i1 e_i1 locals.
     (res = (s',r)) ∧
     env_all_to_i1 genv mods tops env env_i1 locals ∧
     s_to_i1 genv s s_i1 ∧
     (e_i1 = exp_to_i1 mods (DRESTRICT tops (COMPL locals)) e)
     ⇒
     ∃s'_i1 r_i1.
       result_to_i1 v_to_i1 genv r r_i1 ∧
       s_to_i1 genv s' s'_i1 ∧
       evaluate_i1 b env_i1 s_i1 e_i1 (s'_i1, r_i1)) ∧
 (∀b env s es res.
   evaluate_list b env s es res ⇒ 
   (SND res ≠ Rerr Rtype_error) ⇒
   !genv mods tops s' r env_i1 s_i1 es_i1 locals.
     (res = (s',r)) ∧
     env_all_to_i1 genv mods tops env env_i1 locals ∧
     s_to_i1 genv s s_i1 ∧
     (es_i1 = exps_to_i1 mods (DRESTRICT tops (COMPL locals)) es)
     ⇒
     ?s'_i1 r_i1.
       result_to_i1 vs_to_i1 genv r r_i1 ∧
       s_to_i1 genv s' s'_i1 ∧
       evaluate_list_i1 b env_i1 s_i1 es_i1 (s'_i1, r_i1)) ∧
 (∀b env s v pes err_v res. 
   evaluate_match b env s v pes err_v res ⇒ 
   (SND res ≠ Rerr Rtype_error) ⇒
   !genv mods tops s' r env_i1 s_i1 v_i1 pes_i1 err_v_i1 locals.
     (res = (s',r)) ∧
     env_all_to_i1 genv mods tops env env_i1 locals ∧
     s_to_i1 genv s s_i1 ∧
     v_to_i1 genv v v_i1 ∧
     (pes_i1 = pat_exp_to_i1 mods (DRESTRICT tops (COMPL locals)) pes) ∧
     v_to_i1 genv err_v err_v_i1
     ⇒
     ?s'_i1 r_i1.
       result_to_i1 v_to_i1 genv r r_i1 ∧
       s_to_i1 genv s' s'_i1 ∧
       evaluate_match_i1 b env_i1 s_i1 v_i1 pes_i1 err_v_i1 (s'_i1, r_i1))`,
 ho_match_mp_tac evaluate_ind >>
 rw [] >>
 rw [Once evaluate_i1_cases,exp_to_i1_def] >>
 TRY (Cases_on `err`) >>
 fs [result_to_i1_eqns, v_to_i1_eqns]
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- metis_tac [do_con_check_i1, build_conv_i1]
 >- metis_tac [do_con_check_i1]
 >- metis_tac [do_con_check_i1]
 >- (* Variable lookup *)
    (fs [env_all_to_i1_cases] >>
     cases_on `n` >>
     rw [exp_to_i1_def] >>
     fs [lookup_var_id_def] >>
     every_case_tac >>
     fs [lookup_append, all_env_i1_to_env_def, all_env_i1_to_genv_def] >>
     rw []
     >- (every_case_tac >>
         fs []
         >- (fs [v_to_i1_eqns, FLOOKUP_DRESTRICT] >>
             every_case_tac >>
             fs [] >>
             imp_res_tac lookup_notin >>
             res_tac >>
             every_case_tac >>
             fs [])
         >- metis_tac [env_to_i1_lookup])
     >- (every_case_tac >>
         fs [FLOOKUP_DRESTRICT]
         >- metis_tac [global_env_inv_lookup_top] >>
         imp_res_tac lookup_in2 >>
         fs [FLOOKUP_DEF, DISJOINT_DEF, EXTENSION] >>
         metis_tac [])
     >- metis_tac [NOT_SOME_NONE, global_env_inv_lookup_mod1]
     >- metis_tac [NOT_SOME_NONE, global_env_inv_lookup_mod2]
     >- metis_tac [global_env_inv_lookup_mod3])
 >- (* Closure creation *)
    (rw [Once v_to_i1_cases] >>
     fs [env_all_to_i1_cases, all_env_i1_to_cenv_def, all_env_i1_to_env_def] >>
     rw [] >>
     MAP_EVERY qexists_tac [`mods`, `tops`, `env'`, `env''`] >>
     imp_res_tac env_to_i1_dom >>
     rw []
     >- (fs [SUBSET_DEF, v_to_i1_eqns] >>
         rw [] >>
         `¬(lookup x env'' = NONE)` by metis_tac [lookup_notin] >>
         cases_on `lookup x env''` >>
         fs [] >>
         res_tac >>
         fs [FLOOKUP_DEF])
     >- (imp_res_tac global_env_inv_lookup_top >>
         fs [] >>
         imp_res_tac disjoint_drestrict >>
         rw []))
 >- (* Unary application *)
    (fs [s_to_i1_cases] >>
     rw [] >>
     res_tac >>
     fs [] >>
     rw [] >>
     imp_res_tac do_uapp_i1 >>
     metis_tac [])
 >- metis_tac []
 >- (* Application *)
    (LAST_X_ASSUM (qspecl_then [`genv`, `mods`, `tops`, `env_i1`, `s_i1`, `locals`] mp_tac) >>
     rw [] >>
     LAST_X_ASSUM (qspecl_then [`genv`, `mods`, `tops`, `env_i1`, `s'_i1`, `locals`] mp_tac) >>
     rw [] >>
     fs [s_to_i1_cases] >>
     rw [] >>
     (qspecl_then [`genv`, `mods`, `tops`, `env`, `s3`, `s4`, `op`, `v1`, `v2`, `e''`, `env'`,
                   `env_i1`, `s'''''''`, `v'`, `v''`, `locals`] mp_tac) do_app_i1 >>
     rw [] >>
     `genv = all_env_i1_to_genv env_i1` 
                by fs [all_env_i1_to_genv_def, env_all_to_i1_cases] >>
     fs [] >>
     metis_tac [])
 >- (* Application *)
    (LAST_X_ASSUM (qspecl_then [`genv`, `mods`, `tops`, `env_i1`, `s_i1`, `locals`] mp_tac) >>
     rw [] >>
     LAST_X_ASSUM (qspecl_then [`genv`, `mods`, `tops`, `env_i1`, `s'_i1`, `locals`] mp_tac) >>
     rw [] >>
     fs [s_to_i1_cases] >>
     rw [] >>
     (qspecl_then [`genv`, `mods`, `tops`, `env`, `s3`, `s4`, `op`, `v1`, `v2`, `e''`, `env'`,
                   `env_i1`, `s'''''''`, `v'`, `v''`, `locals`] mp_tac) do_app_i1 >>
     rw [] >>
     `genv = all_env_i1_to_genv env_i1` 
                by fs [all_env_i1_to_genv_def, env_all_to_i1_cases] >>
     fs [] >>
     metis_tac [])
 >- (* Application *)
    (LAST_X_ASSUM (qspecl_then [`genv`, `mods`, `tops`, `env_i1`, `s_i1`, `locals`] mp_tac) >>
     rw [] >>
     LAST_X_ASSUM (qspecl_then [`genv`, `mods`, `tops`, `env_i1`, `s'_i1`, `locals`] mp_tac) >>
     rw [] >>
     fs [s_to_i1_cases] >>
     rw [] >>
     (qspecl_then [`genv`, `mods`, `tops`, `env`, `s3`, `s4`, `Opapp`, `v1`, `v2`, `e3`, `env'`,
                   `env_i1`, `s''''''`, `v'`, `v''`, `locals`] mp_tac) do_app_i1 >>
     rw [] >>
     `genv = all_env_i1_to_genv env_i1` 
                by fs [all_env_i1_to_genv_def, env_all_to_i1_cases] >>
     fs [] >>
     metis_tac [])
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- (fs [do_log_def] >>
     every_case_tac >>
     fs [v_to_i1_eqns, exp_to_i1_def] >>
     rw [do_if_i1_def]
     >- metis_tac [] >>
     res_tac >>
     MAP_EVERY qexists_tac [`s'_i1''`, `r_i1`] >>
     rw []
     >- (disj1_tac >>
         qexists_tac `Litv_i1 (Bool F)` >>
         rw [] >>
         fs [exp_to_i1_def] >>
         metis_tac [])
     >- (disj1_tac >>
         qexists_tac `Litv_i1 (Bool T)` >>
         rw [] >>
         fs [exp_to_i1_def] >>
         metis_tac [])
     >- (disj1_tac >>
         qexists_tac `Litv_i1 (Bool F)` >>
         rw [] >>
         fs [exp_to_i1_def] >>
         metis_tac []))
 >- (cases_on `op` >> 
     rw [] >>
     metis_tac [])
 >- (cases_on `op` >> 
     rw [] >>
     metis_tac [])
  >- (fs [do_if_def, do_if_i1_def] >>
     every_case_tac >>
     rw [] >>
     res_tac >>
     rw [] >>
     res_tac >>
     rw [] >>
     MAP_EVERY qexists_tac [`s'_i1''`, `r_i1`] >>
     rw [] >>
     disj1_tac
     >- (qexists_tac `Litv_i1 (Bool F)` >>
         fs [v_to_i1_eqns, exp_to_i1_def] >>
         metis_tac [])
     >- (qexists_tac `Litv_i1 (Bool T)` >>
         fs [v_to_i1_eqns, exp_to_i1_def] >>
         metis_tac []))
 >- metis_tac []
 >- metis_tac []
 >- (fs [v_to_i1_eqns] >>
     metis_tac []) 
 >- metis_tac []
 >- metis_tac []
 >- (* Let *)
    (`?env'. env_i1 = (genv,cenv,env')` by fs [env_all_to_i1_cases] >>
     rw [] >>
     res_tac >>
     fs [] >>
     rw [] >>
     `env_all_to_i1 genv mods tops (menv,cenv,bind n v env) 
                    (genv, cenv, (n,v')::env') (n INSERT locals)`
                by (fs [env_all_to_i1_cases] >>
                    MAP_EVERY qexists_tac [`bind n v env''`, `env'''`] >>
                    fs [bind_def, v_to_i1_eqns] >>
                    rw []) >>
     metis_tac [compl_insert, DRESTRICT_DOMSUB, bind_def])
 >- metis_tac []
 >- metis_tac []
 >- (* Letrec *)
    (rw [markerTheory.Abbrev_def] >>
     pop_assum mp_tac >>
     rw [] >>
     `?env'. env_i1 = (genv,cenv,env')` by fs [env_all_to_i1_cases] >>
     rw [] >>
     `env_all_to_i1 genv mods tops (menv,cenv,build_rec_env funs (menv,cenv,env) env) 
                                   (genv,cenv,build_rec_env_i1 (funs_to_i1 mods (FOLDR (λk m. m \\ k) (DRESTRICT tops (COMPL locals)) (MAP FST funs)) funs) (cenv, env') env')
                                   (set (MAP FST funs) ∪ locals)`
                            by (fs [env_all_to_i1_cases] >>
                                MAP_EVERY qexists_tac [`build_rec_env funs (menv,cenv,env'' ++ env''') env''`, `env'''`] >>
                                rw [build_rec_env_merge, merge_def, EXTENSION]
                                >- (rw [MEM_MAP, EXISTS_PROD] >>
                                   imp_res_tac env_to_i1_dom >>
                                   metis_tac [pair_CASES, FST, MEM_MAP, EXISTS_PROD, LAMBDA_PROD])
                                >- metis_tac [INSERT_SING_UNION, global_env_inv_add_locals, UNION_COMM]
                                >- (fs [v_to_i1_eqns, build_rec_env_i1_merge, merge_def] >>
                                    match_mp_tac env_to_i1_append >>
                                    rw [drestrict_iter_list, GSYM COMPL_UNION] >>
                                    imp_res_tac env_to_i1_dom >>
                                    rw [] >>
                                    match_mp_tac do_app_rec_help >>
                                    rw [] >>
                                    fs [v_to_i1_eqns] >>
                                    rw [SUBSET_DEF] >>
                                    `¬(lookup x env''' = NONE)` by metis_tac [lookup_notin] >>
                                    cases_on `lookup x env'''` >>
                                    fs [] >>
                                    res_tac >>
                                    fs [FLOOKUP_DEF])) >>
      res_tac >>
      MAP_EVERY qexists_tac [`s'_i1'`, `r_i1'`] >>
      rw [] >>
      disj1_tac >>
      rw [] >>
      fs [drestrict_iter_list]
      >- metis_tac [funs_to_i1_dom]
      >- (`(\(x,y,z). x) = FST:tvarN # tvarN # exp -> tvarN` by (rw [FUN_EQ_THM] >>PairCases_on `x` >> rw []) >>
          rw [] >>
          fs [COMPL_UNION] >>
          metis_tac [INTER_COMM]))
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- (* Pattern matching *)
    (pop_assum mp_tac >>
     rw [] >>
     fs [s_to_i1_cases, env_all_to_i1_cases] >>
     rw [] >>
     `match_result_to_i1 genv env''' (Match env') (pmatch_i1 cenv s'' p v_i1 env_i1')`
                   by metis_tac [pmatch_to_i1_correct] >>
     cases_on `pmatch_i1 cenv s'' p v_i1 env_i1'` >>
     fs [match_result_to_i1_def] >>
     rw [] >>
     fs [METIS_PROVE [] ``(((?x. P x) ∧ R ⇒ Q) ⇔ !x. P x ∧ R ⇒ Q) ∧ ((R ∧ (?x. P x) ⇒ Q) ⇔ !x. R ∧ P x ⇒ Q) ``] >>
     FIRST_X_ASSUM (qspecl_then [`genv`, `mods`, `tops`, `env''''`, `env'''`, `a`, `s''`] mp_tac) >>
     rw [] >>
     fs [] >>
     imp_res_tac pmatch_extend >>
     fs [APPEND_11] >>
     rw [] >>
     imp_res_tac global_env_inv_add_locals >>
     fs [] >>
     rw [] >>
     MAP_EVERY qexists_tac [`(c,s'''')`, `r_i1`] >>
     rw [] >>
     fs [COMPL_UNION, drestrict_iter_list] >>
     metis_tac [INTER_COMM])
 >- (* Pattern matching *)
    (pop_assum mp_tac >>
     rw [] >>
     fs [s_to_i1_cases, env_all_to_i1_cases] >>
     rw [] >>
     `match_result_to_i1 genv env'' (No_match) (pmatch_i1 cenv s'' p v_i1 env_i1')`
                   by metis_tac [pmatch_to_i1_correct] >>
     cases_on `pmatch_i1 cenv s'' p v_i1 env_i1'` >>
     fs [match_result_to_i1_def] >>
     rw [] >>
     fs [METIS_PROVE [] ``(((?x. P x) ∧ R ⇒ Q) ⇔ !x. P x ∧ R ⇒ Q) ∧ ((R ∧ (?x. P x) ⇒ Q) ⇔ !x. R ∧ P x ⇒ Q) ``])); 

val evaluate_i1_con = Q.prove (
`evaluate_i1 a0 a1 a2 (Con_i1 cn es) a4 ⇔
      (∃vs s' v.
         a4 = (s',Rval v) ∧
         do_con_check (all_env_i1_to_cenv a1) cn (LENGTH es) ∧
         build_conv_i1 (all_env_i1_to_cenv a1) cn vs = SOME v ∧
         evaluate_list_i1 a0 a1 a2 es (s',Rval vs)) ∨
      (a4 = (a2,Rerr Rtype_error) ∧
       ¬do_con_check (all_env_i1_to_cenv a1) cn (LENGTH es)) ∨
      (∃err s'.
         a4 = (s',Rerr err) ∧
         do_con_check (all_env_i1_to_cenv a1) cn (LENGTH es) ∧
         evaluate_list_i1 a0 a1 a2 es (s',Rerr err))`,
rw [Once evaluate_i1_cases] >>
eq_tac >>
rw []);

val eval_list_i1_vars = Q.prove (
`!b genv cenv env c s env'.
  ALL_DISTINCT (MAP FST env) ∧
  DISJOINT (set (MAP FST env)) (set (MAP FST env'))
  ⇒
  evaluate_list_i1 b (genv,cenv,env'++env) (c,s)
    (MAP Var_local_i1 (MAP FST env)) ((c,s),Rval (MAP SND env))`,
 induct_on `env` >>
 rw [Once evaluate_i1_cases] >>
 rw [Once evaluate_i1_cases, all_env_i1_to_env_def]
 >- (PairCases_on `h` >>
     fs [lookup_append] >>
     full_case_tac >>
     imp_res_tac lookup_in2)
 >- (FIRST_X_ASSUM (qspecl_then [`b`, `genv`, `cenv`, `c`, `s`, `env'++[h]`] mp_tac) >>
     rw [] >>
     metis_tac [DISJOINT_SYM, APPEND, APPEND_ASSOC]));

val pmatch_i1_eval_list = Q.prove (
`(!cenv s p v env env'.
  pmatch_i1 cenv s p v env = Match env' ∧
  ALL_DISTINCT (pat_bindings p (MAP FST env))
  ⇒
  evaluate_list_i1 b (genv,cenv,env') (c,s) (MAP Var_local_i1 (pat_bindings p (MAP FST env))) ((c,s),Rval (MAP SND env'))) ∧
 (!cenv s ps vs env env'.
  pmatch_list_i1 cenv s ps vs env = Match env' ∧
  ALL_DISTINCT (pats_bindings ps (MAP FST env))
  ⇒
  evaluate_list_i1 b (genv,cenv,env') (c,s) (MAP Var_local_i1 (pats_bindings ps (MAP FST env))) ((c,s),Rval (MAP SND env')))`,
 ho_match_mp_tac pmatch_i1_ind >>
 rw [pat_bindings_def, pmatch_i1_def]
 >- (rw [Once evaluate_i1_cases] >>
     rw [Once evaluate_i1_cases, all_env_i1_to_env_def, bind_def] >>
     `DISJOINT (set (MAP FST env)) (set (MAP FST [(x,v)]))` 
                  by rw [DISJOINT_DEF, EXTENSION] >>
     metis_tac [eval_list_i1_vars, APPEND, APPEND_ASSOC])
 >- (`DISJOINT (set (MAP FST env)) (set (MAP FST ([]:(varN,v_i1) env)))` 
                  by rw [DISJOINT_DEF, EXTENSION] >>
     metis_tac [eval_list_i1_vars, APPEND, APPEND_ASSOC])
 >- (every_case_tac >>
     fs [])
 >- (every_case_tac >>
     fs [])
 >- (`DISJOINT (set (MAP FST env)) (set (MAP FST ([]:(varN,v_i1) env)))` 
                  by rw [DISJOINT_DEF, EXTENSION] >>
     metis_tac [eval_list_i1_vars, APPEND, APPEND_ASSOC])
 >- (every_case_tac >>
     fs [] >>
     `ALL_DISTINCT (pat_bindings p (MAP FST env))`
             by fs [Once pat_bindings_accum, ALL_DISTINCT_APPEND] >>
     `MAP FST a = pat_bindings p (MAP FST env)` 
                  by (imp_res_tac pmatch_i1_extend >>
                      rw [] >>
                      metis_tac [pat_bindings_accum]) >>
     metis_tac []));

val eval_list_i1_reverse = Q.prove (
`!b env s es s' vs.
  evaluate_list_i1 b env s (MAP Var_local_i1 es) (s, Rval vs)
  ⇒
  evaluate_list_i1 b env s (MAP Var_local_i1 (REVERSE es)) (s, Rval (REVERSE vs))`,
 induct_on `es` >>
 rw []
 >- fs [Once evaluate_i1_cases] >>
 pop_assum (mp_tac o SIMP_RULE (srw_ss()) [Once evaluate_i1_cases]) >>
 rw [] >>
 fs [Once (hd (CONJUNCTS evaluate_i1_cases))] >>
 rw [] >>
 res_tac >>
 pop_assum mp_tac >>
 pop_assum (fn _ => all_tac) >>
 pop_assum mp_tac >>
 pop_assum (fn _ => all_tac) >>
 Q.SPEC_TAC (`REVERSE vs'`, `vs`) >>
 Q.SPEC_TAC (`REVERSE es`, `es`) >>
 induct_on `es` >>
 rw []
 >- (ntac 3 (rw [Once evaluate_i1_cases]) >>
     fs [Once evaluate_i1_cases]) >>
 rw [] >>
 pop_assum (mp_tac o SIMP_RULE (srw_ss()) [Once evaluate_i1_cases]) >>
 rw [] >>
 fs [Once (hd (CONJUNCTS evaluate_i1_cases))] >>
 rw [] >>
 res_tac >>
 rw [Once evaluate_i1_cases] >>
 qexists_tac `s` >>
 rw [] >>
 rw [Once evaluate_i1_cases]);

val fst_alloc_defs = Q.prove (
`!next l. MAP FST (alloc_defs next l) = l`,
 induct_on `l` >>
 rw [alloc_defs_def]);

val alookup_alloc_defs_bounds = Q.prove (
`!next l x n.
  ALOOKUP (alloc_defs next l) x = SOME n
  ⇒
  next <= n ∧ n < next + LENGTH l`,
 induct_on `l` >>
 rw [alloc_defs_def]  >>
 res_tac >>
 DECIDE_TAC);

val alookup_alloc_defs_bounds_rev = Q.prove (
`!next l x n.
  ALOOKUP (REVERSE (alloc_defs next l)) x = SOME n
  ⇒
  next <= n ∧ n < next + LENGTH l`,
 induct_on `l` >>
 rw [alloc_defs_def]  >>
 fs [ALOOKUP_APPEND] >>
 every_case_tac >>
 fs [] >>
 rw [] >>
 res_tac >>
 DECIDE_TAC);

val global_env_inv_flat_extend_lem = Q.prove (
`!genv genv' env env_i1 x n v.
  env_to_i1 genv' env env_i1 ∧
  lookup x env = SOME v ∧
  ALOOKUP (alloc_defs (LENGTH genv) (MAP FST env)) x = SOME n
  ⇒
  ?v_i1.
    EL n (genv ++ MAP SOME (MAP SND env_i1)) = SOME v_i1 ∧
    v_to_i1 genv' v v_i1`,
 induct_on `env` >>
 rw [v_to_i1_eqns] >>
 PairCases_on `h` >>
 fs [alloc_defs_def] >>
 every_case_tac >>
 fs [] >>
 rw [] >>
 fs [v_to_i1_eqns] >>
 rw []
 >- metis_tac [EL_LENGTH_APPEND, NULL, HD]
 >- (FIRST_X_ASSUM (qspecl_then [`genv++[SOME v']`] mp_tac) >>
     rw [] >>
     metis_tac [APPEND, APPEND_ASSOC]));

val global_env_inv_extend = Q.prove (
`!genv mods tops menv env env' env_i1.
  ALL_DISTINCT (MAP FST env') ∧
  env_to_i1 genv env' env_i1
  ⇒
  global_env_inv (genv++MAP SOME (MAP SND (REVERSE env_i1))) FEMPTY (tops |++ alloc_defs (LENGTH genv) (REVERSE (MAP FST env'))) [] ∅ env'`,
 rw [v_to_i1_eqns, lookup_append] >>
 fs [flookup_fupdate_list, ALOOKUP_APPEND] >>
 every_case_tac >>
 rw [RIGHT_EXISTS_AND_THM]
 >- (imp_res_tac ALOOKUP_NONE >>
     metis_tac [NOT_SOME_NONE, lookup_notin, fst_alloc_defs, MAP_REVERSE, MEM_REVERSE])
 >- metis_tac [ALL_DISTINCT_REVERSE, LENGTH_REVERSE, fst_alloc_defs, alookup_distinct_reverse, 
               LENGTH_MAP, length_env_to_i1, alookup_alloc_defs_bounds]
 >- (match_mp_tac global_env_inv_flat_extend_lem >>
     MAP_EVERY qexists_tac [`(REVERSE env')`, `x`] >>
     rw []
     >- metis_tac [env_to_i1_reverse, v_to_i1_weakening]
     >- metis_tac [lookup_reverse]
     >- metis_tac [alookup_distinct_reverse, MAP_REVERSE, fst_alloc_defs, ALL_DISTINCT_REVERSE]));

val funs_to_i1_map = Q.prove (
`!mods tops funs.
  funs_to_i1 mods tops funs = MAP (\(f,x,e). (f,x,exp_to_i1 mods (tops\\x) e)) funs`,
 induct_on `funs` >>
 rw [exp_to_i1_def] >>
 PairCases_on `h` >>
 rw [exp_to_i1_def]);

val env_to_i1_el = Q.prove (
`!genv env env_i1. 
  env_to_i1 genv env env_i1 ⇔ 
  LENGTH env = LENGTH env_i1 ∧ !n. n < LENGTH env ⇒ (FST (EL n env) = FST (EL n env_i1)) ∧ v_to_i1 genv (SND (EL n env)) (SND (EL n env_i1))`,
 induct_on `env` >>
 rw [v_to_i1_eqns]
 >- (cases_on `env_i1` >>
     fs []) >>
 PairCases_on `h` >>
 rw [v_to_i1_eqns] >>
 eq_tac >>
 rw [] >>
 rw []
 >- (cases_on `n` >>
     fs [])
 >- (cases_on `n` >>
     fs [])
 >- (cases_on `env_i1` >>
     fs [] >>
     FIRST_ASSUM (qspecl_then [`0`] mp_tac) >>
     SIMP_TAC (srw_ss()) [] >>
     rw [] >>
     qexists_tac `SND h` >>
     rw [] >>
     FIRST_X_ASSUM (qspecl_then [`SUC n`] mp_tac) >>
     rw []));

val find_recfun_el = Q.prove (
`!f funs x e n.
  ALL_DISTINCT (MAP (\(f,x,e). f) funs) ∧
  n < LENGTH funs ∧
  EL n funs = (f,x,e)
  ⇒
  find_recfun f funs = SOME (x,e)`,
 induct_on `funs` >>
 rw [find_recfun_thm] >>
 cases_on `n` >>
 fs [find_recfun_thm] >>
 PairCases_on `h` >>
 fs [find_recfun_thm] >>
 rw [] >>
 res_tac >>
 fs [MEM_MAP, MEM_EL, FORALL_PROD] >>
 metis_tac []);

val global_env_inv_extend2 = Q.prove (
`!genv mods tops menv env tops' env'.
  MAP FST env' = REVERSE (MAP FST tops') ∧
  global_env_inv genv mods tops menv {} env ∧
  global_env_inv genv FEMPTY (FEMPTY |++ tops') [] {} env'
  ⇒
  global_env_inv genv mods (tops |++ tops') menv {} (env'++env)`,
 rw [v_to_i1_eqns, flookup_fupdate_list] >>
 full_case_tac >> 
 fs [lookup_append] >>
 full_case_tac >> 
 fs [] >>
 res_tac >>
 fs [] >>
 rpt (pop_assum mp_tac) >>
 rw [] >>
 imp_res_tac lookup_notin >>
 imp_res_tac ALOOKUP_MEM >>
 metis_tac [MEM_REVERSE, MEM_MAP, FST]);

val alloc_defs_append = Q.prove (
`!n l1 l2. alloc_defs n (l1++l2) = alloc_defs n l1 ++ alloc_defs (n + LENGTH l1) l2`,
 induct_on `l1` >>
 srw_tac [ARITH_ss] [alloc_defs_def, arithmeticTheory.ADD1]);

val letrec_global_env_lem = Q.prove (
`!funs funs' menv cenv env v x x' genv.
  lookup x (MAP (λ(fn,n,e). (fn,Recclosure (menv,cenv,env) funs' fn)) funs) = SOME v ∧
  ALOOKUP (REVERSE (alloc_defs (LENGTH genv) (REVERSE (MAP (λ(f,x,e). f) funs)))) x = SOME x'
  ⇒
  v = SND (EL (LENGTH funs + LENGTH genv - (SUC x')) (MAP (λ(fn,n,e). (fn,Recclosure (menv,cenv,env) funs' fn)) funs))`,
 induct_on `funs` >>
 rw [alloc_defs_append] >>
 PairCases_on `h` >>
 fs [REVERSE_APPEND, alloc_defs_def, ALOOKUP_APPEND] >>
 every_case_tac >>
 fs [] >>
 srw_tac [ARITH_ss] [arithmeticTheory.ADD1] >>
 res_tac >>
 rw [arithmeticTheory.ADD1] >>
 imp_res_tac alookup_alloc_defs_bounds_rev >>
 fs [] >>
 `LENGTH funs + LENGTH genv − x' = SUC (LENGTH funs + LENGTH genv − (x'+1))` by decide_tac >>
 rw []);

val letrec_global_env_lem2 = Q.prove (
`!funs x genv n.
  ALL_DISTINCT (MAP FST funs) ∧
  n < LENGTH funs ∧
  ALOOKUP (REVERSE (alloc_defs (LENGTH genv) (REVERSE (MAP (λ(f,x,e). f) funs)))) (EL n (MAP FST funs)) = SOME x
  ⇒ 
  x = LENGTH funs + LENGTH genv - (n + 1)`,
 induct_on `funs` >>
 rw [alloc_defs_def] >>
 PairCases_on `h` >>
 fs [alloc_defs_append, ALOOKUP_APPEND, REVERSE_APPEND] >>
 every_case_tac >>
 fs [alloc_defs_def] >>
 rw [] >>
 cases_on `n = 0` >>
 full_simp_tac (srw_ss()++ARITH_ss) [] >>
 `0 < n` by decide_tac >>
 fs [EL_CONS] >>
 `PRE n < LENGTH funs` by decide_tac >>
 res_tac >>
 srw_tac [ARITH_ss] [] >>
 fs [MEM_MAP, EL_MAP] >>
 LAST_X_ASSUM (qspecl_then [`EL (PRE n) funs`] mp_tac) >>
 rw [MEM_EL] >>
 metis_tac []);

val letrec_global_env_lem3 = Q.prove (
`!funs x genv cenv tops mods.
  ALL_DISTINCT (MAP (λ(x,y,z). x) funs) ∧
  MEM x (MAP FST funs)
  ⇒
  ∃n y e'.
    FLOOKUP (FEMPTY |++ alloc_defs (LENGTH genv) (REVERSE (MAP (λ(f,x,e). f) funs))) x =
        SOME n ∧ n < LENGTH genv + LENGTH funs ∧
    find_recfun x funs = SOME (y,e') ∧
    EL n (genv ++ MAP (λ(p1,p1',p2). 
                           SOME (Closure_i1 (cenv,[]) p1' 
                                      (exp_to_i1 mods ((tops |++ alloc_defs (LENGTH genv) (REVERSE (MAP (λ(f,x,e). f) funs))) \\ p1') p2)))
                      (REVERSE funs)) =
      SOME (Closure_i1 (cenv,[]) y (exp_to_i1 mods ((tops |++ alloc_defs (LENGTH genv) (REVERSE (MAP (λ(f,x,e). f) funs))) \\ y) e'))`,
 rw [] >>
 fs [MEM_EL] >>
 rw [] >>
 MAP_EVERY qexists_tac [`LENGTH genv + LENGTH funs - (n + 1)`, `FST (SND (EL n funs))`, `SND (SND (EL n funs))`] >>
 srw_tac [ARITH_ss] [EL_APPEND2, flookup_fupdate_list]
 >- (every_case_tac >>
     rw []
     >- (imp_res_tac ALOOKUP_NONE >>
         fs [MAP_REVERSE, fst_alloc_defs] >>
         fs [MEM_MAP, FST_triple] >>
         pop_assum mp_tac >>
         rw [EL_MAP] >>
         qexists_tac `EL n funs` >>
         rw [EL_MEM])
     >- metis_tac [FST_triple, letrec_global_env_lem2])
 >- (rw [find_recfun_lookup] >>
     rpt (pop_assum mp_tac) >>
     Q.SPEC_TAC (`n`, `n`) >>
     induct_on `funs` >>
     rw [] >>
     cases_on `0 < n` >>
     rw [EL_CONS] >>
     PairCases_on `h` >>
     fs []
     >- (every_case_tac >> 
         fs [] >>
         `PRE n < LENGTH funs` by decide_tac
         >- (fs [MEM_MAP, FST_triple] >>
             FIRST_X_ASSUM (qspecl_then [`EL (PRE n) funs`] mp_tac) >>
             rw [EL_MAP, EL_MEM])
         >- metis_tac [])
     >- (`n = 0` by decide_tac >>
         rw []))
 >- (`LENGTH funs - (n + 1) < LENGTH funs` by decide_tac >>
     `LENGTH funs - (n + 1) < LENGTH (REVERSE funs)` by metis_tac [LENGTH_REVERSE] >>
     srw_tac [ARITH_ss] [EL_MAP, EL_REVERSE] >>
     `PRE (n + 1) = n` by decide_tac >>
     fs [] >>
     `?f x e. EL n funs = (f,x,e)` by metis_tac [pair_CASES] >>
     rw []));

val letrec_global_env = Q.prove (
`!genv.
  ALL_DISTINCT (MAP (\(x,y,z). x) funs) ∧
  global_env_inv genv mods tops menv {} env
  ⇒
  global_env_inv (genv ++ (MAP (λ(p1,p1',p2). SOME (Closure_i1 (cenv,[]) p1' p2))
                               (funs_to_i1 mods (tops |++ alloc_defs (LENGTH genv) (REVERSE (MAP (λ(f,x,e). f) funs))) 
                                                (REVERSE funs))))
               FEMPTY
               (FEMPTY |++ alloc_defs (LENGTH genv) (REVERSE (MAP (λ(f,x,e). f) funs))) 
               [] 
               ∅ 
               (build_rec_env funs (menv,cenv,env) [])`,
 rw [build_rec_env_merge, merge_def] >>
 rw [v_to_i1_eqns, flookup_fupdate_list] >>
 every_case_tac >>
 rw [funs_to_i1_map, MAP_MAP_o, combinTheory.o_DEF, LAMBDA_PROD, RIGHT_EXISTS_AND_THM]
 >- (imp_res_tac ALOOKUP_NONE >>
     fs [MAP_REVERSE, fst_alloc_defs] >>
     imp_res_tac lookup_in2 >>
     fs [MEM_MAP] >>
     rw [] >>
     fs [LAMBDA_PROD, FORALL_PROD] >>
     PairCases_on `y'` >>
     fs [] >>
     metis_tac [])
 >- (imp_res_tac alookup_alloc_defs_bounds_rev >>
     fs [])
 >- (imp_res_tac letrec_global_env_lem >>
     imp_res_tac alookup_alloc_defs_bounds_rev >>
     rw [EL_APPEND2] >>
     fs [] >>
     srw_tac [ARITH_ss] [EL_MAP, EL_REVERSE] >>
     `(PRE (LENGTH funs + LENGTH genv − x')) = (LENGTH funs + LENGTH genv − SUC x')` by decide_tac >>
     rw [] >>
     `?f x e. EL (LENGTH funs + LENGTH genv − SUC x') funs = (f,x,e)` by metis_tac [pair_CASES] >>
     rw [Once v_to_i1_cases] >>
     MAP_EVERY qexists_tac [`mods`, 
                            `tops`,
                            `e`,
                            `alloc_defs (LENGTH genv) (REVERSE (MAP (λ(f,x,e). f) funs))`] >>
     rw []
     >- (fs [v_to_i1_eqns, SUBSET_DEF] >>
         rw [] >>
         `¬(lookup x''' env = NONE)` by metis_tac [lookup_notin] >>
         cases_on `lookup x''' env` >>
         fs [] >>
         res_tac >>
         fs [FLOOKUP_DEF])
     >- metis_tac [v_to_i1_weakening]
     >- rw [MAP_REVERSE, fst_alloc_defs, FST_triple]
     >- (`LENGTH funs + LENGTH genv − SUC x' < LENGTH funs` by decide_tac >>
         metis_tac [find_recfun_el])
     >- metis_tac [letrec_global_env_lem3]));

val dec_to_i1_correct = Q.prove (
`!ck mn mods tops d menv cenv env s s' r genv s_i1 next' tops' d_i1 tdecs tdecs'.
  r ≠ Rerr Rtype_error ∧
  evaluate_dec ck mn (menv,cenv,env) (s,tdecs) d ((s',tdecs'),r) ∧
  global_env_inv genv mods tops menv {} env ∧
  s_to_i1 genv s s_i1 ∧
  dec_to_i1 (LENGTH genv) mn mods tops d = (next',tops',d_i1)
  ⇒
  ?s'_i1 r_i1.
    evaluate_dec_i1 ck genv cenv (s_i1,tdecs) d_i1 ((s'_i1,tdecs'),r_i1) ∧
    (!cenv' env'.
      r = Rval (cenv',env')
      ⇒
      ?env'_i1.
        r_i1 = Rval (cenv', MAP SND env'_i1) ∧
        next' = LENGTH (genv ++ MAP SOME (MAP SND env'_i1)) ∧
        env_to_i1 (genv ++ MAP SOME (MAP SND env'_i1)) env' (REVERSE env'_i1) ∧
        s_to_i1 (genv ++ MAP SOME (MAP SND env'_i1)) s' s'_i1 ∧
        MAP FST env' = REVERSE (MAP FST tops') ∧
        global_env_inv (genv ++ MAP SOME (MAP SND env'_i1)) FEMPTY (FEMPTY |++ tops') [] {} env') ∧
    (!err.
      r = Rerr err
      ⇒
      ?err_i1.
        r_i1 = Rerr err_i1 ∧
        result_to_i1 (\a b c. T) genv (Rerr err) (Rerr err_i1) ∧
        s_to_i1 genv s' s'_i1)`,
 rw [evaluate_dec_cases, evaluate_dec_i1_cases, dec_to_i1_def] >>
 every_case_tac >>
 fs [LET_THM] >>
 rw [FUPDATE_LIST, result_to_i1_eqns, emp_def]
 >- (`env_all_to_i1 genv mods tops (menv,cenv,env) (genv,cenv,[]) {}`
           by fs [env_all_to_i1_cases, v_to_i1_eqns] >>
     imp_res_tac exp_to_i1_correct >>
     fs [] >>
     res_tac >>
     fs [] >>
     rw [] >>
     fs [DRESTRICT_UNIV, result_to_i1_cases, all_env_to_cenv_def] >>
     rw [] >>
     fs [s_to_i1_cases] >>
     rw [] >>
     pop_assum (fn _ => all_tac) >>
     `match_result_to_i1 genv [] (Match env') (pmatch_i1 cenv s''' p v'' [])`
             by metis_tac [emp_def, APPEND, pmatch_to_i1_correct, v_to_i1_eqns] >>
     cases_on `pmatch_i1 cenv s''' p v'' []` >>
     fs [match_result_to_i1_def] >>
     ONCE_REWRITE_TAC [evaluate_i1_cases] >>
     rw [] >>
     ONCE_REWRITE_TAC [hd (tl (tl (CONJUNCTS evaluate_i1_cases)))] >>
     rw [] >>
     ONCE_REWRITE_TAC [hd (tl (tl (CONJUNCTS evaluate_i1_cases)))] >>
     rw [evaluate_i1_con, do_con_check_def, build_conv_i1_def] >>
     imp_res_tac pmatch_i1_eval_list >>
     pop_assum mp_tac >>
     rw [] >>
     pop_assum (qspecl_then [`genv`, `count'`, `ck`] strip_assume_tac) >>
     MAP_EVERY qexists_tac [`(count',s''')`, `Rval ([], MAP SND (REVERSE a))`] >>
     rw [RIGHT_EXISTS_AND_THM] >>
     `pat_bindings p [] = MAP FST env'` 
            by (imp_res_tac pmatch_extend >>
                fs [emp_def] >>
                rw [] >>
                metis_tac [LENGTH_MAP, length_env_to_i1])
     >- metis_tac [length_env_to_i1, LENGTH_MAP]
     >- metis_tac [eval_list_i1_reverse, MAP_REVERSE, PAIR_EQ, big_unclocked]
     >- (qexists_tac `REVERSE a` >>
         rw []
         >- metis_tac [LENGTH_MAP, length_env_to_i1]
         >- metis_tac [s_to_i1'_cases, v_to_i1_weakening]
         >- metis_tac [s_to_i1'_cases, v_to_i1_weakening, MAP_REVERSE]
         >- rw [fst_alloc_defs]
         >- metis_tac [FUPDATE_LIST, global_env_inv_extend]))
 >- (`env_all_to_i1 genv mods tops (menv,cenv,env) (genv,cenv,[]) {}`
           by fs [env_all_to_i1_cases, v_to_i1_eqns] >>
     imp_res_tac exp_to_i1_correct >>
     fs [s_to_i1_cases] >>
     res_tac >>
     fs [] >>
     res_tac >>
     fs [] >>
     rw [] >>
     pop_assum (fn _ => all_tac) >>
     fs [DRESTRICT_UNIV, result_to_i1_cases, all_env_to_cenv_def] >>
     `match_result_to_i1 genv [] No_match (pmatch_i1 cenv s''' p v'' [])`
             by metis_tac [emp_def, APPEND, pmatch_to_i1_correct, v_to_i1_eqns] >>
     cases_on `pmatch_i1 cenv s''' p v'' []` >>
     fs [match_result_to_i1_def] >>
     rw [] >>
     MAP_EVERY qexists_tac [`s'''`, `Rerr (Rraise (Conv_i1 (SOME ("Bind",TypeExn (Short "Bind"))) []))`] >>
     rw []
     >- (ONCE_REWRITE_TAC [evaluate_i1_cases] >>
         rw [] >>
         ONCE_REWRITE_TAC [hd (tl (tl (CONJUNCTS evaluate_i1_cases)))] >>
         rw [] >>
         ONCE_REWRITE_TAC [hd (tl (tl (CONJUNCTS evaluate_i1_cases)))] >>
         rw [evaluate_i1_con, do_con_check_def, build_conv_i1_def] >>
         qexists_tac `0` >>
         rw [] >>
         metis_tac [big_unclocked])
     >- rw [v_to_i1_eqns])
 >- (`env_all_to_i1 genv mods tops (menv,cenv,env) (genv,cenv,[]) {}`
           by fs [env_all_to_i1_cases, v_to_i1_eqns] >>
     imp_res_tac exp_to_i1_correct >>
     fs [s_to_i1_cases] >>
     res_tac >>
     fs [] >>
     rw [] >>
     res_tac >>
     fs [] >>
     rw [] >>
     ntac 5 (pop_assum (fn _ => all_tac)) >>
     fs [DRESTRICT_UNIV, result_to_i1_cases, all_env_to_cenv_def] >>
     rw []
     >- (MAP_EVERY qexists_tac [`s'''`, `Rerr (Rraise v')`] >>
         rw [dec_to_dummy_env_def] >>
         ONCE_REWRITE_TAC [evaluate_i1_cases] >>
         rw [] >>
         ONCE_REWRITE_TAC [hd (tl (tl (CONJUNCTS evaluate_i1_cases)))] >>
         rw [] >>
         ONCE_REWRITE_TAC [hd (tl (tl (CONJUNCTS evaluate_i1_cases)))] >>
         rw [evaluate_i1_con, do_con_check_def, build_conv_i1_def] >>
         qexists_tac `0` >>
         rw [] >>
         metis_tac [big_unclocked])
     >- (qexists_tac `s'''` >>
         rw [dec_to_dummy_env_def] >>
         ONCE_REWRITE_TAC [evaluate_i1_cases] >>
         rw [] >>
         ONCE_REWRITE_TAC [hd (tl (tl (CONJUNCTS evaluate_i1_cases)))] >>
         rw [] >>
         ONCE_REWRITE_TAC [hd (tl (tl (CONJUNCTS evaluate_i1_cases)))] >>
         rw [evaluate_i1_con, do_con_check_def, build_conv_i1_def] >>
         qexists_tac `0` >>
         rw [] >>
         metis_tac [big_unclocked]))
 >- (rw [fupdate_list_foldl] >>
     Q.ABBREV_TAC `tops' = (tops |++ alloc_defs (LENGTH genv) (REVERSE (MAP (λ(f,x,e). f) funs)))` >>
     qexists_tac `MAP (λ(f,x,e). (f, Closure_i1 (cenv,[]) x e)) (funs_to_i1 mods tops' (REVERSE funs))` >>
     rw [GSYM funs_to_i1_dom, ALL_DISTINCT_REVERSE, MAP_REVERSE, MAP_MAP_o, combinTheory.o_DEF, LAMBDA_PROD,
         GSYM FUPDATE_LIST]
     >- rw [build_rec_env_i1_merge, merge_def, funs_to_i1_map]
     >- (rw [build_rec_env_merge,merge_def, MAP_REVERSE, MAP_MAP_o, combinTheory.o_DEF, LAMBDA_PROD,
             funs_to_i1_map, env_to_i1_el] >>
         rw [EL_MAP] >>
         `?f x e. EL n funs = (f,x,e)` by metis_tac [pair_CASES] >>
         rw [] >>
         rw [Once v_to_i1_cases] >>
         MAP_EVERY qexists_tac [`mods`, `tops`, `e`, `alloc_defs (LENGTH genv) (REVERSE (MAP (λ(f,x,e). f) funs))`] >>
         rw [] >>
         UNABBREV_ALL_TAC >>
         rw [SUBSET_DEF, FDOM_FUPDATE_LIST, FUPDATE_LIST_THM]
         >- (fs [v_to_i1_eqns] >>
             `~(lookup x' env = NONE)` by metis_tac [lookup_notin] >>
             cases_on `lookup x' env` >>
             fs [] >>
             res_tac >>
             fs [FLOOKUP_DEF])
         >- metis_tac [v_to_i1_weakening]
         >- rw [MAP_REVERSE, fst_alloc_defs, FST_triple]
         >- metis_tac [find_recfun_el]
         >- metis_tac [MAP_REVERSE, letrec_global_env_lem3])
     >- metis_tac [v_to_i1_weakening, s_to_i1'_cases]
     >- (rw [MAP_MAP_o, combinTheory.o_DEF, fst_alloc_defs, build_rec_env_merge, merge_def, MAP_EQ_f] >>
         PairCases_on `x` >>
         rw [])
     >- metis_tac [letrec_global_env])
 >- fs [v_to_i1_eqns]
 >- fs [v_to_i1_eqns]
 >- fs [v_to_i1_eqns]
 >- fs [v_to_i1_eqns]);

val dec_to_i1_num_bindings = Q.prove (
`!next mn mods tops d next' tops' d_i1.
  dec_to_i1 next mn mods tops d = (next',tops',d_i1)
  ⇒
  next' = next + dec_to_dummy_env d_i1`,
 rw [dec_to_i1_def] >>
 every_case_tac >>
 fs [LET_THM] >>
 rw [dec_to_dummy_env_def, funs_to_i1_map] >>
 metis_tac []); 

val decs_to_i1_num_bindings = Q.prove (
`!next mn mods tops ds next' tops' ds_i1.
  decs_to_i1 next mn mods tops ds = (next',tops',ds_i1)
  ⇒
  next' = next + decs_to_dummy_env ds_i1`,
 induct_on `ds` >>
 rw [decs_to_i1_def] >>
 rw [decs_to_dummy_env_def] >>
 fs [LET_THM] >>
 `?next'' tops'' ds_i1''. dec_to_i1 next mn mods tops h = (next'',tops'',ds_i1'')` by metis_tac [pair_CASES] >>
 fs [fupdate_list_foldl] >>
 `?next''' tops''' ds_i1'''. decs_to_i1 next'' mn mods (tops |++ tops'') ds = (next''',tops''',ds_i1''')` by metis_tac [pair_CASES] >>
 fs [] >>
 rw [decs_to_dummy_env_def] >>
 res_tac >>
 rw [] >>
 imp_res_tac dec_to_i1_num_bindings >>
 rw [] >>
 decide_tac);

val decs_to_i1_correct = Q.prove (
`!mn mods tops ds menv cenv env s s' r genv s_i1 tdecs s'_i1 tdecs' next' tops' ds_i1 cenv'.
  r ≠ Rerr Rtype_error ∧
  evaluate_decs mn (menv,cenv,env) (s,tdecs) ds ((s',tdecs'),cenv',r) ∧
  global_env_inv genv mods tops menv {} env ∧
  s_to_i1' genv s s_i1 ∧
  decs_to_i1 (LENGTH genv) mn mods tops ds = (next',tops',ds_i1)
  ⇒
  ∃s'_i1 new_genv new_genv' new_env' r_i1.
   new_genv' = MAP SND new_genv ∧
   evaluate_decs_i1 genv cenv (s_i1,tdecs) ds_i1 ((s'_i1,tdecs'),cenv',new_genv',r_i1) ∧
   s_to_i1' (genv ++ MAP SOME new_genv') s' s'_i1 ∧
   (!new_env.
     r = Rval new_env
     ⇒
     r_i1 = NONE ∧
     next' = LENGTH (genv ++ MAP SOME new_genv') ∧ 
     env_to_i1 (genv ++ MAP SOME new_genv') new_env (REVERSE new_genv) ∧
     MAP FST new_env = REVERSE (MAP FST tops') ∧
     global_env_inv (genv ++ MAP SOME new_genv') FEMPTY (FEMPTY |++ tops') [] {} new_env) ∧
   (!err.
     r = Rerr err
     ⇒
     ?err_i1 new_env.
       r_i1 = SOME err_i1 ∧
       next' ≥ LENGTH (genv++MAP SOME new_genv') ∧
       result_to_i1 (\a b c. T) (genv ++ MAP SOME new_genv') (Rerr err) (Rerr err_i1))`,
 induct_on `ds` >>
 rw [decs_to_i1_def] >>
 qpat_assum `evaluate_decs a b c d e` (mp_tac o SIMP_RULE (srw_ss()) [Once evaluate_decs_cases]) >>
 rw [Once evaluate_decs_i1_cases, emp_def, FUPDATE_LIST, result_to_i1_eqns]
 >- rw [v_to_i1_eqns] >>
 fs [LET_THM] >>
 `?next' tops' d_i1. dec_to_i1 (LENGTH genv) mn mods tops h = (next',tops',d_i1)` by metis_tac [pair_CASES] >>
 fs [] >>
 rw [] >>
 `?s2' tdecs2. s2 = (s2',tdecs2)` by metis_tac [pair_CASES] >>
 fs [] >>
 imp_res_tac dec_to_i1_correct >>
 pop_assum mp_tac >>
 rw [] >>
 fs [result_to_i1_eqns] >>
 `?envC' env'. v' = (envC',env')` by metis_tac [pair_CASES] >>
 rw [] >>
 fs [fupdate_list_foldl] >>
 rw []
 >- fs [v_to_i1_eqns]
 >- (`?next''' tops''' ds_i1. decs_to_i1 next'' mn mods (tops |++ tops'') ds = (next''',tops''',ds_i1)` 
                   by metis_tac [pair_CASES] >>
     fs [result_to_i1_cases] >>
     rw [] >>
     fs []
     >- (MAP_EVERY qexists_tac [`s'_i1`, `[]`, `SOME (Rraise v')`] >>
         rw [] >>
         imp_res_tac dec_to_i1_num_bindings >>
         imp_res_tac decs_to_i1_num_bindings >>
         decide_tac)
     >- (MAP_EVERY qexists_tac [`s'_i1`, `[]`] >>
         rw [] >>
         imp_res_tac dec_to_i1_num_bindings >>
         imp_res_tac decs_to_i1_num_bindings >>
         decide_tac))
 >- (`?next''' tops''' ds_i1. decs_to_i1 (LENGTH genv + LENGTH env'_i1) mn mods (tops |++ tops'') ds = (next''',tops''',ds_i1)` 
               by metis_tac [pair_CASES] >>
     fs [merge_def] >>
     rw [] >>
     `r' ≠ Rerr Rtype_error` 
               by (cases_on `r'` >>
                   fs [combine_dec_result_def]) >>
     `global_env_inv (genv ++ MAP SOME (MAP SND env'_i1)) mods (tops |++ tops'') menv ∅ (new_env ++ env)`
             by metis_tac [v_to_i1_weakening, global_env_inv_extend2] >>
     FIRST_X_ASSUM (qspecl_then [`mn`, `mods`, `tops |++ tops''`, `menv`, 
                                 `merge_envC ([],new_tds) cenv`, `new_env ++ env`,
                                 `s2'`, `s'`, `r'`, `genv ++ MAP SOME (MAP SND env'_i1)`, `s'_i1`,
                                 `tdecs2`, `tdecs'`, `next'`, `tops'''`, `ds_i1'`, `new_tds'`] mp_tac) >>
     rw [merge_def] >>
     MAP_EVERY qexists_tac [`s'_i1'`, `env'_i1++new_genv`, `r_i1`] >>
     rw []
     >- (disj2_tac >>
         MAP_EVERY qexists_tac [`(s'_i1,tdecs2)`, `new_tds'`, `new_tds`, `MAP SND env'_i1`, `MAP SND new_genv`] >>
         rw [combine_dec_result_def, merge_def, MAP_REVERSE])
     >- (cases_on `r'` >>
         fs [combine_dec_result_def])
     >- (cases_on `r'` >>
         full_simp_tac (srw_ss()++ARITH_ss) [combine_dec_result_def])
     >- (cases_on `r'` >>
         fs [combine_dec_result_def] >>
         rw [merge_def, REVERSE_APPEND] >>
         metis_tac [env_to_i1_append, v_to_i1_weakening, MAP_REVERSE])
     >- (cases_on `r'` >>
         full_simp_tac (srw_ss()++ARITH_ss) [combine_dec_result_def] >>
         rw [merge_def])
     >- (cases_on `r'` >>
         fs [combine_dec_result_def] >>
         rw [merge_def, REVERSE_APPEND] >>
         fs [MAP_REVERSE, GSYM FUPDATE_LIST, FUPDATE_LIST_APPEND] >>
         metis_tac [FUPDATE_LIST_APPEND, global_env_inv_extend2, APPEND_ASSOC, v_to_i1_weakening])
     >- (cases_on `r'` >>
         fs [combine_dec_result_def, MAP_REVERSE, GSYM FUPDATE_LIST, FUPDATE_LIST_APPEND,
             REVERSE_APPEND] >>
         rw [] >>
         imp_res_tac dec_to_i1_num_bindings >>
         imp_res_tac decs_to_i1_num_bindings >>
         decide_tac))); 

val global_env_inv_extend_mod = Q.prove (
`!genv new_genv mods tops tops' menv new_env env mn.
  global_env_inv genv mods tops menv ∅ env ∧
  global_env_inv (genv ++ MAP SOME (MAP SND new_genv)) FEMPTY (FEMPTY |++ tops') [] ∅ new_env
  ⇒
  global_env_inv (genv ++ MAP SOME (MAP SND new_genv)) (mods |+ (mn,FEMPTY |++ tops')) tops ((mn,new_env)::menv) ∅ env`,
 rw [last (CONJUNCTS v_to_i1_eqns)]
 >- metis_tac [v_to_i1_weakening] >>
 every_case_tac >>
 rw [FLOOKUP_UPDATE] >>
 fs [v_to_i1_eqns] >>
 res_tac >>
 qexists_tac `map` >>
 rw [] >>
 res_tac  >>
 qexists_tac `n` >>
 qexists_tac `v_i1` >>
 rw []
 >- decide_tac >>
 metis_tac [v_to_i1_weakening, EL_APPEND1]);

val global_env_inv_extend_mod_err = Q.prove (
`!genv new_genv mods tops tops' menv new_env env mn new_genv'.
  mn ∉ set (MAP FST menv) ∧
  global_env_inv genv mods tops menv ∅ env
  ⇒
  global_env_inv (genv ++ MAP SOME (MAP SND new_genv) ++ MAP SOME new_genv')
                 (mods |+ (mn,FEMPTY |++ tops')) tops menv ∅ env`,
 rw [last (CONJUNCTS v_to_i1_eqns)]
 >- metis_tac [v_to_i1_weakening] >>
 rw [FLOOKUP_UPDATE]
 >- metis_tac [lookup_in2] >>
 fs [v_to_i1_eqns] >>
 rw [] >>
 res_tac >>
 rw [] >>
 res_tac  >>
 qexists_tac `n` >>
 qexists_tac `v_i1` >>
 rw []
 >- decide_tac >>
 metis_tac [v_to_i1_weakening, EL_APPEND1, APPEND_ASSOC]);

val to_i1_invariant_def = Define `
to_i1_invariant genv mods tops menv env s s_i1 mod_names ⇔
  set (MAP FST menv) ⊆ mod_names ∧
  global_env_inv genv mods tops menv {} env ∧
  s_to_i1' genv s s_i1`;

val top_to_i1_correct = Q.store_thm ("top_to_i1_correct",
`!mods tops t menv cenv env s s' r genv s_i1 next' tops' mods' prompt_i1 cenv' tdecs tdecs' mod_names mod_names'.
  r ≠ Rerr Rtype_error ∧
  to_i1_invariant genv mods tops menv env s s_i1 mod_names ∧
  evaluate_top (menv,cenv,env) (s,tdecs,mod_names) t ((s',tdecs',mod_names'),cenv',r) ∧
  top_to_i1 (LENGTH genv) mods tops t = (next',mods',tops',prompt_i1)
  ⇒
  ∃s'_i1 new_genv r_i1.
   evaluate_prompt_i1 genv cenv (s_i1,tdecs,mod_names) prompt_i1 ((s'_i1,tdecs',mod_names'),cenv',new_genv,r_i1) ∧
   next' = LENGTH  (genv ++ MAP SOME new_genv) ∧
   (!new_menv new_env.
     r = Rval (new_menv, new_env)
     ⇒
     r_i1 = NONE ∧
     to_i1_invariant (genv ++ MAP SOME new_genv) mods' tops' (new_menv++menv) (new_env++env) s' s'_i1 mod_names') ∧
   (!err.
     r = Rerr err
     ⇒
     ?err_i1.
       r_i1 = SOME err_i1 ∧
       result_to_i1 (\a b c. T) (genv ++ MAP SOME new_genv) (Rerr err) (Rerr err_i1) ∧
       to_i1_invariant (genv ++ MAP SOME new_genv) mods' tops menv env s' s'_i1 mod_names')`,
 rw [evaluate_top_cases, evaluate_prompt_i1_cases, top_to_i1_def, LET_THM, to_i1_invariant_def] >>
 fs [] >>
 rw []
 >- (`?next'' tops'' d_i1. dec_to_i1 (LENGTH genv) NONE mods tops d = (next'',tops'',d_i1)` by metis_tac [pair_CASES] >>
     fs [] >>
     rw [] >>
     imp_res_tac dec_to_i1_correct >>
     fs [result_to_i1_cases] >>
     fs [fupdate_list_foldl] >>
     rw [] >>
     MAP_EVERY qexists_tac [`s'_i1`, `MAP SND env'_i1`] >>
     rw [emp_def, mod_cenv_def, update_mod_state_def] >>
     rw [Once evaluate_decs_i1_cases] >>
     rw [Once evaluate_decs_i1_cases, emp_def, merge_def] >>
     fs [] >>
     metis_tac [global_env_inv_extend2, v_to_i1_weakening])
 >- (`?next'' tops'' d_i1. dec_to_i1 (LENGTH genv) NONE mods tops d = (next'',tops'',d_i1)` by metis_tac [pair_CASES] >>
     fs [] >>
     rw [] >>
     imp_res_tac dec_to_i1_correct >>
     pop_assum mp_tac >>
     rw [] >>
     rw [mod_cenv_def, emp_def] >>
     fs [result_to_i1_cases] >>
     rw [] >>
     fs [fupdate_list_foldl] >>
     fs [] >>
     rw []
     >- (MAP_EVERY qexists_tac [`s'_i1`, `GENLIST (\n. Litv_i1 Unit) (decs_to_dummy_env [d_i1])`, `SOME (Rraise v')`] >>
         rw []
         >- (ONCE_REWRITE_TAC [evaluate_decs_i1_cases] >>
             rw [] >>
             ONCE_REWRITE_TAC [evaluate_decs_i1_cases] >>
             rw [] >>
             fs [] >>
             rw [emp_def, update_mod_state_def])
         >- (rw [decs_to_dummy_env_def] >>
             metis_tac [dec_to_i1_num_bindings])
         >- metis_tac [s_to_i1'_cases, v_to_i1_weakening]
         >- metis_tac [s_to_i1'_cases, v_to_i1_weakening]
         >- metis_tac [s_to_i1'_cases, v_to_i1_weakening])
     >- (MAP_EVERY qexists_tac [`s'_i1`, `GENLIST (\n. Litv_i1 Unit) (decs_to_dummy_env [d_i1])`] >>
         rw []
         >- (ONCE_REWRITE_TAC [evaluate_decs_i1_cases] >>
             rw [] >>
             ONCE_REWRITE_TAC [evaluate_decs_i1_cases] >>
             rw [] >>
             fs [evaluate_dec_i1_cases] >>
             rw [emp_def, update_mod_state_def])
         >- (rw [decs_to_dummy_env_def] >>
             metis_tac [dec_to_i1_num_bindings])
         >- metis_tac [s_to_i1'_cases, v_to_i1_weakening]
         >- metis_tac [s_to_i1'_cases, v_to_i1_weakening]))
 >- (`?next'' tops'' ds_i1. decs_to_i1 (LENGTH genv) (SOME mn) mods tops ds = (next'',tops'',ds_i1)` by metis_tac [pair_CASES] >>
     fs [] >>
     rw [] >>
     imp_res_tac decs_to_i1_correct >>
     fs [] >>
     rw [mod_cenv_def, emp_def] >>
     MAP_EVERY qexists_tac [`s'_i1`, `MAP SND new_genv`] >>
     rw [fupdate_list_foldl, update_mod_state_def] >>
     fs [SUBSET_DEF] >>
     metis_tac [global_env_inv_extend_mod])
 >- (`?next'' tops'' ds_i1. decs_to_i1 (LENGTH genv) (SOME mn) mods tops ds = (next'',tops'',ds_i1)` by metis_tac [pair_CASES] >>
     fs [] >>
     rw [] >>
     imp_res_tac decs_to_i1_correct >>
     pop_assum mp_tac >>
     rw [mod_cenv_def, emp_def] >>
     MAP_EVERY qexists_tac [`s'_i1`, 
                            `MAP SND new_genv ++ GENLIST (λn. Litv_i1 Unit) (decs_to_dummy_env ds_i1 − LENGTH (MAP SND new_genv))`, 
                            `SOME err_i1`] >>
     rw [] 
     >- (MAP_EVERY qexists_tac [`MAP SND new_genv`] >>
         rw [update_mod_state_def])
     >- (imp_res_tac decs_to_i1_num_bindings >>
         decide_tac)
     >- (fs [result_to_i1_cases] >>
         rw [] >>
         metis_tac [s_to_i1'_cases, v_to_i1_weakening])
     >- fs [SUBSET_DEF]
     >- (rw [fupdate_list_foldl] >>
         `mn ∉ set (MAP FST menv)` 
                    by (fs [SUBSET_DEF] >>
                        metis_tac []) >>
         metis_tac [global_env_inv_extend_mod_err])
     >- metis_tac [s_to_i1'_cases, v_to_i1_weakening]));

val prog_to_i1_correct = Q.store_thm ("prog_to_i1_correct",
`!mods tops menv cenv env s prog s' r genv s_i1 next' tops' mods'  cenv' prog_i1 tdecs mod_names tdecs' mod_names'.
  r ≠ Rerr Rtype_error ∧
  evaluate_prog (menv,cenv,env) (s,tdecs,mod_names) prog ((s',tdecs',mod_names'),cenv',r) ∧
  to_i1_invariant genv mods tops menv env s s_i1 mod_names ∧
  prog_to_i1 (LENGTH genv) mods tops prog = (next',mods',tops',prog_i1)
  ⇒
  ∃s'_i1 new_genv r_i1.
   evaluate_prog_i1 genv cenv (s_i1,tdecs,mod_names) prog_i1 ((s'_i1,tdecs',mod_names'),cenv',new_genv,r_i1) ∧
   (!new_menv new_env.
     r = Rval (new_menv, new_env)
     ⇒
     next' = LENGTH (genv ++ MAP SOME new_genv) ∧
     r_i1 = NONE ∧
     to_i1_invariant (genv ++ MAP SOME new_genv) mods' tops' (new_menv++menv) (new_env++env) s' s'_i1 mod_names') ∧
   (!err.
     r = Rerr err
     ⇒
     ?err_i1.
       r_i1 = SOME err_i1 ∧
       result_to_i1 (\a b c. T) (genv ++ MAP SOME new_genv) (Rerr err) (Rerr err_i1))`,
 induct_on `prog` >>
 rw [LET_THM, prog_to_i1_def]
 >- fs [Once evaluate_prog_cases, Once evaluate_prog_i1_cases, emp_def] >>
 `?next'' mods'' tops'' prompt_i1. top_to_i1 (LENGTH genv) mods tops h = (next'',mods'',tops'',prompt_i1)` by metis_tac [pair_CASES] >>
 fs [] >>
 `?next' mods' tops' prog_i1. prog_to_i1 next'' mods'' tops'' prog = (next',mods',tops',prog_i1)` by metis_tac [pair_CASES] >>
 fs [] >>
 rw [] >>
 qpat_assum `evaluate_prog a b c d` (mp_tac o SIMP_RULE (srw_ss()) [Once evaluate_prog_cases]) >>
 rw [] >>
 rw [Once evaluate_prog_i1_cases] >>
 `?s2' tdecs2' mod_names2'. s2 = (s2',tdecs2',mod_names2')` by metis_tac [pair_CASES] >>
 rw []
 >- (`∃s'_i1 new_genv.
      evaluate_prompt_i1 genv cenv (s_i1,tdecs,mod_names) prompt_i1
         ((s'_i1,tdecs2',mod_names2'),new_tds,new_genv,NONE) ∧
      next'' = LENGTH genv + LENGTH (MAP SOME new_genv) ∧
      to_i1_invariant (genv ++ MAP SOME new_genv) mods'' tops'' (new_mods ++ menv) (new_env ++ env) s2' s'_i1 mod_names2'`
                 by (imp_res_tac top_to_i1_correct >>
                     fs [] >>
                     metis_tac []) >>
     fs [merge_def] >>
     FIRST_X_ASSUM (qspecl_then [`mods''`, `tops''`, `new_mods ++ menv`, `merge_envC new_tds cenv`, `new_env ++ env`, `s2'`, `s'`, `r'`, `genv++MAP SOME new_genv`, `s'_i1`] mp_tac) >>
     rw [] >>
     FIRST_X_ASSUM (qspecl_then [`new_tds'`, `tdecs2'`, `mod_names2'`, `tdecs'`, `mod_names'`] mp_tac) >>
     rw [] >>
     `r' ≠ Rerr Rtype_error` 
            by (Cases_on `r'` >>
                fs [combine_mod_result_def]) >>
     rw [] >>
     cases_on `r'` >>
     fs [combine_mod_result_def]
     >- (`?menv' env'. a = (menv',env')` by metis_tac [pair_CASES] >>
         rw [] >>
         MAP_EVERY qexists_tac [`s'_i1'`, `new_genv++new_genv'`] >>
         srw_tac [ARITH_ss] [] >>
         fs [merge_def] >>
         metis_tac [])
     >- (fs [result_to_i1_cases] >>
         rw [] >>
         metis_tac [v_to_i1_weakening, APPEND_ASSOC, LENGTH_APPEND, MAP_APPEND]))
 >- (imp_res_tac top_to_i1_correct >>
     pop_assum mp_tac >>
     rw [] >>
     fs [result_to_i1_cases] >>
     rw [] >>
     metis_tac [v_to_i1_weakening, APPEND_ASSOC, LENGTH_APPEND]));

val init_mods_def = Define `
  init_mods = FEMPTY`;

val init_tops_def = Define `
  init_tops = FEMPTY |++ alloc_defs 0 (MAP FST init_env)`;

val init_genv_def = Define `
  init_genv =
    MAP (\(x,v).
           case v of 
             | Closure _ x e => SOME (Closure_i1 (init_envC,[]) x (exp_to_i1 init_mods (init_tops\\x) e)))
        init_env`;

val initial_i1_invariant = Q.prove (
`global_env_inv init_genv init_mods init_tops [] {} init_env ∧
 s_to_i1' init_genv [] []`,
 rw [last (CONJUNCTS v_to_i1_eqns)]
 >- (rw [v_to_i1_eqns, init_tops_def] >>
     fs [init_env_def, alloc_defs_def] >>
     rpt (full_case_tac
          >- (rw [] >>
              rw [flookup_fupdate_list] >>
              rw [init_genv_def, Once v_to_i1_cases] >>
              rw [v_to_i1_eqns] >>
              rw [init_env_def, DRESTRICT_UNIV] >>
              metis_tac [])) >>
     fs [])
 >- rw [v_to_i1_eqns, s_to_i1'_cases]);

val init_to_i1_invariant = Q.store_thm ("init_to_i1_invariant",
`to_i1_invariant init_genv init_mods init_tops [] init_env [] [] {}`,
 rw [to_i1_invariant_def] >>
 metis_tac [initial_i1_invariant]);

val _ = export_theory ();
