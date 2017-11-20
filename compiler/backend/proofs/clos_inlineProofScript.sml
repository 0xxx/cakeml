open preamble closPropsTheory clos_inlineTheory closSemTheory;
open closLangTheory;
open backendPropsTheory;

val _ = new_theory "clos_inlineProof";

(* More than one resolution of overloading was possible? *)

val LENGTH_remove_ticks = store_thm("LENGTH_remove_ticks",
  ``!(es:closLang$exp list). LENGTH (remove_ticks es) = LENGTH es``,
  recInduct remove_ticks_ind \\ fs [remove_ticks_def]);

val remove_ticks_IMP_LENGTH = store_thm("remove_ticks_LENGTH_imp",
  ``!(es:closLang$exp list) xs. xs = remove_ticks es ==> LENGTH es = LENGTH xs``,
  fs [LENGTH_remove_ticks]);

(* code relation *)

val code_rel_def = Define `
  code_rel e1 e2 <=>
    e2 = remove_ticks e1`;

val code_rel_IMP_LENGTH = store_thm("code_rel_IMP_LENGTH",
  ``!xs ys. code_rel xs ys ==> LENGTH xs = LENGTH ys``,
  fs [code_rel_def, LENGTH_remove_ticks]);

val remove_ticks_sing = store_thm("remove_ticks_sing",
  ``!e. ?e'. remove_ticks [e] = [e']``,
  Induct \\ fs [remove_ticks_def]);

val remove_ticks_cons = store_thm("remove_ticks_cons",
  ``!es e. remove_ticks (e::es) = HD (remove_ticks [e])::remove_ticks es``,
  Induct_on `es` \\ Induct_on `e` \\ fs [remove_ticks_def]);

val code_rel_CONS = store_thm("code_rel_CONS",
  ``!x xs y y ys. code_rel (x::xs) (y::ys) <=>
                  code_rel [x] [y] /\ code_rel xs ys``,
  fs [code_rel_def]
  \\ rpt strip_tac
  \\ `?x'. remove_ticks [x] = [x']` by metis_tac [remove_ticks_sing]
  \\ rw [Once remove_ticks_cons]);

val code_rel_CONS_CONS = store_thm("code_rel_CONS_CONS",
  ``!x1 x2 xs y1 y2 ys. code_rel (x1::x2::xs) (y1::y2::ys) <=>
                        code_rel [x1] [y1] /\ code_rel (x2::xs) (y2::ys)``,
  fs [code_rel_def]
  \\ rpt strip_tac
  \\ `?t1. remove_ticks [x1] = [t1]` by metis_tac [remove_ticks_sing]
  \\ `?t2. remove_ticks [x2] = [t2]` by metis_tac [remove_ticks_sing]
  \\ rw [remove_ticks_cons]);

(* value relation *)

val f_rel_def = Define `
  f_rel (a1, e1) (a2, e2) <=>
     a1 = a2 /\ code_rel [e1] [e2]`;

val (v_rel_rules, v_rel_ind, v_rel_cases) = Hol_reln `
  (!i. v_rel (Number i) (Number i)) /\
  (!w. v_rel (Word64 w) (Word64 w)) /\
  (!w. v_rel (ByteVector w) (ByteVector w)) /\
  (!n. v_rel (RefPtr n) (RefPtr n)) /\
  (!tag xs ys.
     LIST_REL v_rel xs ys ==>
       v_rel (Block tag xs) (Block tag ys)) /\
  (!loc args1 args2 env1 env2 num_args e1 e2.
     LIST_REL v_rel env1 env2 /\
     LIST_REL v_rel args1 args2 /\
     code_rel [e1] [e2] ==>
       v_rel (Closure loc args1 env1 num_args e1) (Closure loc args2 env2 num_args e2)) /\
  (!loc args1 args2 env1 env2 k.
     LIST_REL v_rel env1 env2 /\
     LIST_REL v_rel args1 args2 /\
     LIST_REL f_rel funs1 funs2 ==>
       v_rel (Recclosure loc args1 env1 funs1 k) (Recclosure loc args2 env2 funs2 k))`;

val v_rel_simps = save_thm("v_rel_simps[simp]",LIST_CONJ [
  SIMP_CONV (srw_ss()) [v_rel_cases] ``v_rel x (Number n)``,
  SIMP_CONV (srw_ss()) [v_rel_cases] ``v_rel x (Block n p)``,
  SIMP_CONV (srw_ss()) [v_rel_cases] ``v_rel x (Word64 p)``,
  SIMP_CONV (srw_ss()) [v_rel_cases] ``v_rel x (ByteVector p)``,
  SIMP_CONV (srw_ss()) [v_rel_cases] ``v_rel x (RefPtr p)``,
  SIMP_CONV (srw_ss()) [v_rel_cases] ``v_rel x (Closure x1 x2 x3 x4 x5)``,
  SIMP_CONV (srw_ss()) [v_rel_cases] ``v_rel x (Recclosure y1 y2 y3 y4 y5)``,
  prove(``v_rel x (Boolv b) <=> x = Boolv b``,
        Cases_on `b` \\ fs [Boolv_def,Once v_rel_cases]),
  prove(``v_rel x Unit <=> x = Unit``,
        fs [closSemTheory.Unit_def,Once v_rel_cases])])

(*
val LIST_REL_f_rel_IMP = prove(
  ``!fns funs1. LIST_REL (f_rel) funs1 fns ==> !x. ~(MEM (0,x) fns)``,
  Induct \\ fs [PULL_EXISTS] \\ rw [] \\ res_tac
  \\ res_tac \\ fs []
  \\ Cases_on `x` \\ Cases_on `h` \\ fs [f_rel_def, code_rel_def]);
*)

(* state relation *)

val v_rel_opt_def = Define `
  (v_rel_opt NONE NONE <=> T) /\
  (v_rel_opt (SOME x) (SOME y) <=> v_rel x y) /\
  (v_rel_opt _ _ = F)`;

val (ref_rel_rules, ref_rel_ind, ref_rel_cases) = Hol_reln `
  (!b bs. ref_rel (ByteArray b bs) (ByteArray b bs)) /\
  (!xs ys.
    LIST_REL v_rel xs ys ==>
    ref_rel (ValueArray xs) (ValueArray ys))`

val FMAP_REL_def = Define `
  FMAP_REL r f1 f2 <=>
    FDOM f1 = FDOM f2 /\
    !k v. FLOOKUP f1 k = SOME v ==>
          ?v2. FLOOKUP f2 k = SOME v2 /\ r v v2`;

val compile_inc_def = Define `
  compile_inc (e, xs) = (HD (remove_ticks [e]), [])`;

val state_rel_def = Define `
  state_rel (s:('c, 'ffi) closSem$state) (t:('c, 'ffi) closSem$state) <=>
    (!n. SND (SND (s.compile_oracle n)) = []) /\
    s.code = FEMPTY /\ t.code = FEMPTY /\
    t.max_app = s.max_app /\ 1 <= s.max_app /\
    t.clock = s.clock /\
    t.ffi = s.ffi /\
    LIST_REL v_rel_opt s.globals t.globals /\
    FMAP_REL ref_rel s.refs t.refs /\
    s.compile = pure_cc compile_inc t.compile /\
    t.compile_oracle = pure_co compile_inc o s.compile_oracle`;


(* eval remove ticks *)

val mk_Ticks_def = Define `
  (mk_Ticks [] (e : closLang$exp) = e) /\
  (mk_Ticks (t::tr) e = Tick t (mk_Ticks tr e))`;

val HD_remove_ticks_SING = store_thm("HD_remove_ticks_SING[simp]",
  ``!x. [HD (remove_ticks [x])] = remove_ticks [x]``,
  gen_tac \\ strip_assume_tac (Q.SPEC `x` remove_ticks_sing) \\ fs []);

val remove_ticks_Tick = store_thm("remove_ticks_Tick",
  ``!x t e. ~([Tick t e] = remove_ticks [x])``,
  Induct \\ fs [remove_ticks_def]);

val qexistsl_tac = map_every qexists_tac;

val remove_ticks_Var_IMP_mk_Ticks = store_thm("remove_ticks_IMP_mk_Ticks",
  ``(!x tr n. [Var tr n] = remove_ticks [x] ==> ?ts. x = mk_Ticks ts (Var tr n))``,
  Induct \\ fs [remove_ticks_def] \\ metis_tac [mk_Ticks_def]);

val remove_ticks_If_IMP_mk_Ticks = store_thm("remove_ticks_If_IMP_mk_Ticks",
  ``!x tr e1' e2' e3'.
      [If tr e1' e2' e3'] = remove_ticks [x] ==>
        ?ts e1 e2 e3. x = mk_Ticks ts (If tr e1 e2 e3) /\
                      e1' = HD (remove_ticks [e1]) /\
                      e2' = HD (remove_ticks [e2]) /\
                      e3' = HD (remove_ticks [e3])``,
  Induct \\ fs [remove_ticks_def] \\ rpt strip_tac
  THEN1 (qexistsl_tac [`[]`, `x`, `x'`, `x''`] \\ fs [mk_Ticks_def])
  \\ res_tac \\ qexistsl_tac [`t::ts`, `e1`, `e2`, `e3`] \\ fs [mk_Ticks_def]);
 
val remove_ticks_Let_IMP_mk_Ticks = store_thm("remove_ticks_Let_IMP_mk_Ticks",
  ``!x t l e. [Let t l e] = remove_ticks [x] ==>
              (?ts l' e'. x = mk_Ticks ts (Let t l' e') /\
               l = remove_ticks l' /\
               [e] = remove_ticks [e'])``,
  Induct \\ fs [remove_ticks_def] \\ rpt strip_tac
  THEN1 (qexistsl_tac [`[]`, `l`, `x`] \\ fs [mk_Ticks_def])
  \\ res_tac
  \\ qexistsl_tac [`t::ts`, `l'`, `e'`]
  \\ fs [mk_Ticks_def]);

val remove_ticks_Raise_IMP_mk_Ticks = store_thm(
  "remove_ticks_Raise_IMP_mk_Ticks",
  ``!x t e. [Raise t e] = remove_ticks [x] ==>
            (?ts e'. x = mk_Ticks ts (Raise t e') /\ [e] = remove_ticks [e'])``,
  Induct \\ fs [remove_ticks_def] \\ rpt strip_tac
  THEN1 (qexistsl_tac [`[]`, `x`] \\ fs [mk_Ticks_def])
  \\ res_tac
  \\ qexistsl_tac [`t::ts`, `e'`]
  \\ fs [mk_Ticks_def]);

val remove_ticks_Handle_IMP_mk_Ticks = store_thm(
  "remove_ticks_Handle_IMP_mk_Ticks",
  ``!x t e1' e2'. [Handle t e1' e2'] = remove_ticks [x] ==>
                  (?ts e1 e2. x = mk_Ticks ts (Handle t e1 e2) /\
                   [e1'] = remove_ticks [e1] /\ [e2'] = remove_ticks [e2])``,
  Induct \\ fs [remove_ticks_def] \\ rpt strip_tac
  THEN1 (qexistsl_tac [`[]`, `x`, `x'`] \\ fs [mk_Ticks_def])
  \\ res_tac
  \\ qexistsl_tac [`t::ts`, `e1`, `e2`]
  \\ fs [mk_Ticks_def]);

val remove_ticks_Op_IMP_mk_Ticks = store_thm("remove_ticks_Op_IMP_mk_Ticks",
  ``!x tr op es'. [Op tr op es'] = remove_ticks [x] ==>
      ?ts es. x = mk_Ticks ts (Op tr op es) /\ es' = remove_ticks es``,
  reverse (Induct \\ fs [remove_ticks_def]) \\ rpt strip_tac
  THEN1 (qexistsl_tac [`[]`, `l`] \\ fs [mk_Ticks_def])
  \\ res_tac  \\ qexistsl_tac [`t::ts`, `es`] \\ fs [mk_Ticks_def]);

val remove_ticks_Fn_IMP_mk_Ticks = store_thm("remove_ticks_Fn_IMP_mk_Ticks",
  ``!x tr loc vsopt num_args e'.
      [Fn tr loc vsopt num_args e'] = remove_ticks [x] ==>
        ?ts e. x = mk_Ticks ts (Fn tr loc vsopt num_args e) /\ [e'] = remove_ticks [e]``,
  reverse (Induct \\ fs [remove_ticks_def]) \\ rpt strip_tac
  THEN1 (qexistsl_tac [`[]`, `x`] \\ fs [mk_Ticks_def])
  \\ res_tac \\ qexistsl_tac [`t::ts`, `e`] \\ fs [mk_Ticks_def]);

val remove_ticks_Letrec_IMP_mk_Ticks = store_thm(
  "remove_ticks_Letrec_IMP_mk_Ticks",
  ``!x tr loc vsopt fns' e'.
      [Letrec tr loc vsopt fns' e'] = remove_ticks [x] ==>
        ?ts fns e. x = mk_Ticks ts (Letrec tr loc vsopt fns e) /\
                   e' = HD (remove_ticks [e]) /\
                   fns' = MAP (\(num_args, x). (num_args, HD (remove_ticks [x]))) fns``,
  reverse (Induct \\ fs [remove_ticks_def]) \\ rpt strip_tac
  THEN1 (qexistsl_tac [`[]`, `l`, `x`] \\ fs [mk_Ticks_def])
  \\ res_tac \\ qexistsl_tac [`t::ts`, `fns`, `e`] \\ fs [mk_Ticks_def]);

val remove_ticks_App_IMP_mk_Ticks = store_thm("remove_ticks_App_IMP_mk_Ticks",
  ``!x tr loc_opt e1' es'.
      [App tr loc_opt e1' es'] = remove_ticks [x] ==>
        ?ts e1 es. x = mk_Ticks ts (App tr loc_opt e1 es) /\
                   e1' = HD (remove_ticks [e1]) /\
                   es' = remove_ticks es``,
  reverse (Induct \\ fs [remove_ticks_def]) \\ rpt strip_tac
  THEN1 (qexistsl_tac [`[]`, `x`, `l`] \\ fs [mk_Ticks_def])
  \\ res_tac \\ qexistsl_tac [`t::ts`, `e1`, `es`] \\ fs [mk_Ticks_def]);

val remove_ticks_Call_IMP_mk_Ticks = store_thm("remove_ticks_Call_IMP_mk_Ticks",
  ``!x tr ticks' dest es'. [Call tr ticks' dest es'] = remove_ticks [x] ==>
      ticks' = 0 /\
      ?ts ticks es. x = mk_Ticks ts (Call tr ticks dest es) /\
                    es' = remove_ticks es``,
  Induct \\ rw [remove_ticks_def] \\ metis_tac [mk_Ticks_def])

val remove_ticks_mk_Ticks = store_thm("remove_ticks_mk_Ticks",
  ``!tr e. remove_ticks [mk_Ticks tr e] = remove_ticks [e]``,
  Induct_on `tr` \\ fs [mk_Ticks_def, remove_ticks_def]);

val evaluate_mk_Ticks = store_thm("evaluate_mk_Ticks",
  ``!tr e env s1.
      evaluate ([mk_Ticks tr e], env, s1) =
        if s1.clock < LENGTH tr then (Rerr (Rabort Rtimeout_error), s1 with clock := 0)
                                else evaluate ([e], env, dec_clock (LENGTH tr) s1)``,
  Induct THEN1 simp [mk_Ticks_def, dec_clock_def]
  \\ rw []
  \\ fs [mk_Ticks_def, evaluate_def, dec_clock_def]
  THEN1 (IF_CASES_TAC \\ simp [state_component_equality])
  \\ fs [ADD1]);

val bump_assum = fn (pat) => qpat_x_assum pat assume_tac;

val do_app_lemma = prove(
  ``state_rel s t /\ LIST_REL v_rel xs ys ==>
    case do_app opp ys t of
      | Rerr err2 => ?err1. do_app opp xs s = Rerr err1 /\ exc_rel v_rel err1 err2
      | Rval (y, t1) => ?x s1. v_rel x y /\ state_rel s1 t1 /\ do_app opp xs s = Rval (x, s1)``,
  cheat);

val lookup_vars_lemma = store_thm("lookup_vars_lemma",
  ``!vs env1 env2. LIST_REL v_rel env1 env2 ==>
    case lookup_vars vs env2 of
      | NONE => lookup_vars vs env1 = NONE
      | SOME l2 => ?l1. LIST_REL v_rel l1 l2 /\ lookup_vars vs env1 = SOME l1``,
  Induct_on `vs` \\ fs [lookup_vars_def]
  \\ rpt strip_tac
  \\ imp_res_tac LIST_REL_LENGTH
  \\ rw []
  \\ res_tac
  \\ Cases_on `lookup_vars vs env2`
  \\ fs []
  \\ fs [LIST_REL_EL_EQN]);

val state_rel_IMP_max_app_EQ = store_thm("state_rel_IMP_max_app_EQ",
  ``!s t. state_rel s t ==> s.max_app = t.max_app``,
  fs [state_rel_def]);

val state_rel_IMP_code_FEMPTY = prove(
  ``!s t. state_rel s t ==> s.code = FEMPTY /\ t.code = FEMPTY``,
  fs [state_rel_def]);

val find_code_lemma = store_thm("find_code_lemma",
  ``!s t l1 l2. state_rel s t /\ LIST_REL v_rel l1 l2 ==>
      ((find_code dest l1 s.code = NONE) <=>
       (find_code dest l2 t.code = NONE))``,
  rpt strip_tac
  \\ `s.code = t.code` by fs [state_rel_def]
  \\ fs [find_code_def]
  \\ simp [case_eq_thms]
  \\ eq_tac \\ strip_tac \\ simp []
  \\ fs [pair_case_eq]
  \\ imp_res_tac LIST_REL_LENGTH
  \\ simp [])

val find_code_IMP = store_thm("find_code_NONE_IMP",
  ``!s t l1 l2 dest. state_rel s t /\ LIST_REL v_rel l1 l2 ==>
       (!v2. find_code dest l2 t.code = SOME v2 ==>
               ?args1 args2 exp1 exp2.
                 LIST_REL v_rel args1 args2 /\
                 code_rel [exp1] [exp2] /\
                 find_code dest l1 s.code = SOME (args1, exp2)) /\
       (find_code dest l2 t.code = NONE ==>
          find_code dest l1 s.code = NONE)``,
  rpt strip_tac
  THEN1
   (imp_res_tac LIST_REL_LENGTH
    \\ fs [find_code_def]
    \\ fs [case_eq_thms, pair_case_eq] \\
    \\ fs [state_rel_def]
    \\ qpat_x_assum `FMAP_REL _ s.code t.code` mp_tac
    \\ simp [FMAP_REL_def]
    \\ strip_tac
    \\ rfs [FLOOKUP_DEF]
    \\ res_tac
    \\ Cases_on `s.code ' dest`
    \\ rfs []
    \\ metis_tac []

val evaluate_remove_ticks = Q.store_thm("evaluate_remove_ticks",
  `(!ys env2 (t1:('c,'ffi) closSem$state) res2 t2 env1 s1 xs.
     (evaluate (ys,env2,t1) = (res2,t2)) /\
     LIST_REL v_rel env1 env2 /\
     state_rel s1 t1 /\ code_rel xs ys ==>
     ?ck res1 s2.
        (evaluate (xs,env1,s1 with clock := s1.clock + ck) = (res1,s2)) /\
        result_rel (LIST_REL v_rel) v_rel res1 res2 /\
        state_rel s2 t2) /\
   (!loc_opt f2 args2 (t1:('c,'ffi) closSem$state) res2 t2 f1 args1 s1.
     (evaluate_app loc_opt f2 args2 t1 = (res2,t2)) /\
     v_rel f1 f2 /\ LIST_REL v_rel args1 args2 /\
     state_rel s1 t1 (* /\ LENGTH args1 <= s1.max_app *) ==>
     ?ck res1 s2.
       (evaluate_app loc_opt f1 args1 (s1 with clock := s1.clock + ck) = (res1,s2)) /\
       result_rel (LIST_REL v_rel) v_rel res1 res2 /\
       state_rel s2 t2)`,
  (**)
  ho_match_mp_tac (evaluate_ind |> Q.SPEC `λ(x1,x2,x3). P0 x1 x2 x3`
                   |> Q.GEN `P0` |> SIMP_RULE std_ss [FORALL_PROD])
  \\ rpt strip_tac
  \\ TRY (drule code_rel_IMP_LENGTH \\ strip_tac)
  THEN1 (* NIL *)
   (fs [evaluate_def] \\ rveq \\ qexists_tac `0` \\ fs[])
  THEN1 (* CONS *)
   (fs [LENGTH_EQ_NUM] \\ rveq
    \\ fs [evaluate_def]
    \\ reverse (fs [closSemTheory.case_eq_thms, pair_case_eq])
    \\ rveq \\ fs []
    \\ first_x_assum drule \\ fs [code_rel_CONS_CONS]
    \\ disch_then drule \\ disch_then drule \\ strip_tac \\ fs []
    THEN1 (qexists_tac `ck` \\ fs[])
    \\ Cases_on `res1` \\ fs []
    \\ first_x_assum drule
    \\ disch_then drule \\ disch_then drule \\ strip_tac \\ fs []
    \\ Cases_on `res1` \\ fs []
    \\ imp_res_tac evaluate_clock \\ fs []
    \\ qexists_tac `ck + ck'` \\ fs []
    \\ qpat_x_assum `evaluate ([h], env1, _) = _` assume_tac (* move an asm to use with drule *)
    \\ drule evaluate_add_clock \\ fs []
    \\ disch_then kall_tac (* drop and ignore the precedent of an implication *)
    \\ imp_res_tac evaluate_SING
    \\ fs [])
  THEN1 (* Var *)
   (fs [LENGTH_EQ_NUM_compute] \\ rveq
    \\ fs [code_rel_def]
    \\ imp_res_tac remove_ticks_Var_IMP_mk_Ticks \\ rveq
    \\ fs [remove_ticks_mk_Ticks, remove_ticks_def]
    \\ simp [evaluate_mk_Ticks, dec_clock_def]
    \\ fs [evaluate_def]
    \\ qexists_tac `LENGTH ts`
    \\ imp_res_tac LIST_REL_LENGTH
    \\ rw [] \\ fs [] \\ rw [] \\ fs []
    \\ fs [LIST_REL_EL_EQN])
  THEN1 (* If *)
   (fs [LENGTH_EQ_NUM_compute] \\ rveq
    \\ fs [code_rel_def]
    \\ imp_res_tac remove_ticks_If_IMP_mk_Ticks \\ rveq
    \\ fs [remove_ticks_mk_Ticks, remove_ticks_def]
    \\ simp [evaluate_mk_Ticks]
    \\ fs [evaluate_def]
    \\ simp [dec_clock_def]
    \\ fs [pair_case_eq] \\ fs []
    \\ first_x_assum drule
    \\ disch_then drule
    \\ disch_then (mp_tac o Q.SPEC `[e1]`) \\ simp []
    \\ strip_tac
    \\ reverse (fs [case_eq_thms] \\ rveq \\ Cases_on `res1` \\ fs [])
    THEN1 (qexists_tac `ck + LENGTH ts` \\ fs [])
    \\ imp_res_tac evaluate_SING \\ fs [] \\ rveq
    \\ `(Boolv T = y <=> Boolv T = r1) /\
        (Boolv F = y <=> Boolv F = r1)` by
     (qpat_x_assum `v_rel _ _` mp_tac
      \\ rpt (pop_assum kall_tac)
      \\ simp [EVAL ``closSem$Boolv T``,EVAL ``closSem$Boolv F``]
      \\ rw [] \\ eq_tac \\ rw []
      \\ rpt (pop_assum mp_tac)
      \\ simp [Once v_rel_cases])
    \\ ntac 2 (pop_assum (fn th => fs [th]))
    \\ reverse (Cases_on `Boolv T = r1 \/ Boolv F = r1`) \\ fs [] \\ rveq \\ fs []
    THEN1 (qexists_tac `ck + LENGTH ts` \\ fs [])
    \\ TRY (rename1 `evaluate (remove_ticks [e_taken_branch], env2, _) = (res2, t2)`)
    \\ first_x_assum drule
    \\ disch_then drule
    \\ disch_then (qspec_then `[e_taken_branch]` mp_tac) \\ fs []
    \\ strip_tac
    \\ imp_res_tac evaluate_clock \\ fs []
    \\ qexists_tac `ck + ck' + LENGTH ts` \\ fs []
    \\ bump_assum `evaluate ([e1], _, _) = _`
    \\ drule evaluate_add_clock \\ fs [])
  THEN1 (* Let *)
   (fs [LENGTH_EQ_NUM_compute] \\ rveq
    \\ fs [code_rel_def]
    \\ imp_res_tac remove_ticks_Let_IMP_mk_Ticks \\ rveq
    \\ fs [remove_ticks_mk_Ticks]
    \\ fs [remove_ticks_def]
    \\ simp [evaluate_mk_Ticks]   
    \\ fs [evaluate_def]
    \\ simp [dec_clock_def]
    \\ Cases_on `evaluate (remove_ticks l', env2, t1')`
    \\ fs []
    \\ first_x_assum drule
    \\ disch_then drule
    \\ disch_then (mp_tac o Q.SPEC `l'`)
    \\ fs [] \\ strip_tac
    \\ reverse (Cases_on `q`) THEN1 (qexists_tac `ck + LENGTH ts` \\ fs [] \\ rw [])
    \\ fs []
    \\ Cases_on `res1` \\ fs []
    \\ drule (GEN_ALL EVERY2_APPEND_suff)
    \\ bump_assum `LIST_REL v_rel env1 env2`
    \\ disch_then drule 
    \\ strip_tac
    \\ first_x_assum drule
    \\ disch_then drule
    \\ disch_then (mp_tac o Q.SPEC `[e']`)
    \\ fs [] \\ strip_tac
    \\ imp_res_tac evaluate_clock \\ fs []
    \\ qexists_tac `ck + ck' + LENGTH ts` \\ fs []
    \\ bump_assum `evaluate (l', env1, _) = _`
    \\ drule evaluate_add_clock \\ fs [])
  THEN1 (* Raise *)
   (fs [LENGTH_EQ_NUM_compute] \\ rveq
    \\ fs [code_rel_def]
    \\ imp_res_tac remove_ticks_Raise_IMP_mk_Ticks \\ rveq
    \\ fs [remove_ticks_mk_Ticks, remove_ticks_def]
    \\ simp [evaluate_mk_Ticks, dec_clock_def]
    \\ fs [evaluate_def]
    \\ fs [pair_case_eq] \\ fs []
    \\ first_x_assum drule
    \\ disch_then drule
    \\ disch_then (mp_tac o Q.SPEC `[e']`)
    \\ fs [] \\ strip_tac
    \\ fs [case_eq_thms] \\ rveq
    \\ Cases_on `res1` \\ fs [] 
    \\ qexists_tac `ck + LENGTH ts`
    \\ fs []
    \\ imp_res_tac evaluate_SING \\ rveq
    \\ fs [LIST_REL_EL_EQN])
  THEN1 (* Handle *)
   (fs [LENGTH_EQ_NUM_compute] \\ rveq
    \\ fs [code_rel_def]
    \\ imp_res_tac remove_ticks_Handle_IMP_mk_Ticks \\ rveq
    \\ fs [remove_ticks_mk_Ticks, remove_ticks_def]
    \\ simp [evaluate_mk_Ticks, dec_clock_def]
    \\ fs [evaluate_def]
    \\ fs [pair_case_eq] \\ fs []
    \\ first_x_assum drule
    \\ disch_then drule
    \\ disch_then (mp_tac o Q.SPEC `[e1]`)
    \\ fs [] \\ strip_tac
    \\ fs [case_eq_thms] \\ rveq \\ Cases_on `res1` \\ fs []
    (* Close the Rval and Rerr Rabort cases using TRY *)
    \\ TRY (qexists_tac `ck + LENGTH ts` THEN1 fs [])
    \\ qpat_x_assum `!x. _` mp_tac
    \\ disch_then (mp_tac o Q.SPEC `v'::env1`) \\ fs []
    \\ disch_then drule
    \\ disch_then (mp_tac o Q.SPEC `[e2]`) \\ fs []
    \\ strip_tac
    \\ imp_res_tac evaluate_clock \\ fs []
    \\ qexists_tac `ck + ck' + LENGTH ts` \\ fs []
    \\ bump_assum `evaluate ([e1], _m _) = _`
    \\ drule evaluate_add_clock \\ fs [])
  THEN1 (* Op *)
   (fs [LENGTH_EQ_NUM_compute] \\ rveq
    \\ fs [code_rel_def]
    \\ imp_res_tac remove_ticks_Op_IMP_mk_Ticks \\ rveq
    \\ fs [remove_ticks_mk_Ticks, remove_ticks_def]
    \\ simp [evaluate_mk_Ticks, dec_clock_def]
    \\ fs [evaluate_def]
    \\ fs [pair_case_eq] \\ fs []
    \\ first_x_assum drule
    \\ disch_then drule
    \\ disch_then (mp_tac o Q.SPEC `es`) \\ simp []
    \\ strip_tac
    \\ reverse (fs [case_eq_thms]) \\ rveq
    \\ Cases_on `res1` \\ fs []
    THEN1 (qexists_tac `ck + LENGTH ts` \\ fs [])
    \\ reverse (Cases_on `op = Install`) \\ fs []
    THEN1 (* op /= Install *)
     (fs [case_eq_thms]
      \\ rw []
      \\ qexists_tac `ck + LENGTH ts`
      \\ fs []
      \\ drule (GEN_ALL do_app_lemma)
      \\ drule EVERY2_REVERSE \\ strip_tac
      \\ disch_then drule
      \\ disch_then (assume_tac o Q.SPEC `op`)
      \\ rfs []
      \\ PairCases_on `v1`
      \\ fs []
      \\ metis_tac [])
    THEN1 (* op = Install *)
     (cheat)
   )
  THEN1 (* Fn *)
   (fs [LENGTH_EQ_NUM_compute] \\ rveq
    \\ fs [code_rel_def]
    \\ imp_res_tac remove_ticks_Fn_IMP_mk_Ticks \\ rveq
    \\ fs [remove_ticks_mk_Ticks, remove_ticks_def]
    \\ simp [evaluate_mk_Ticks, dec_clock_def]
    \\ fs [evaluate_def]
    \\ qexists_tac `LENGTH ts` \\ fs []
    \\ imp_res_tac state_rel_IMP_max_app_EQ \\ fs []
    \\ IF_CASES_TAC \\ fs [] \\ rveq \\ fs []
    \\ Cases_on `vsopt` \\ fs [] \\ rveq \\ fs []
    \\ drule (Q.SPEC `x` lookup_vars_lemma) \\ strip_tac
    \\ Cases_on `lookup_vars x env2` \\ fs [] \\ rveq \\ fs []
    \\ fs [code_rel_def])
  THEN1 (* Letrec *)
   (fs [LENGTH_EQ_NUM_compute] \\ rveq
    \\ fs [code_rel_def]
    \\ imp_res_tac remove_ticks_Letrec_IMP_mk_Ticks \\ rveq
    \\ fs [remove_ticks_mk_Ticks, remove_ticks_def]
    \\ simp [evaluate_mk_Ticks, dec_clock_def]
    \\ fs [evaluate_def]
    \\ `EVERY (λ(num_args,e). num_args ≤ t1.max_app ∧ num_args ≠ 0)
             (MAP (λ(num_args,x). (num_args,HD (remove_ticks [x]))) fns') <=>
       EVERY (λ(num_args,e'). num_args ≤ s1.max_app ∧ num_args ≠ 0) fns'` by
     (imp_res_tac state_rel_IMP_max_app_EQ \\ fs []
      \\ rpt (pop_assum kall_tac)
      \\ eq_tac \\ spose_not_then strip_assume_tac
      \\ fs [EXISTS_MEM] \\ rename1 `MEM eee _`
      \\ TRY (CHANGED_TAC (fs [MEM_MAP]) \\ rename1 `MEM yyy _`)
      \\ fs [EVERY_MAP, EVERY_MEM]
      \\ res_tac
      \\ PairCases_on `eee`
      \\ TRY (PairCases_on `yyy`)
      \\ fs [])
    \\ pop_assum (fn (thm) => fs [thm])
    \\ qpat_x_assum `(if _ then _ else _) = _` mp_tac                               (* bättre sätt att göra detta? *)
    \\ reverse IF_CASES_TAC
    THEN1 (simp [] \\ strip_tac \\ rveq \\ qexists_tac `LENGTH ts` \\ fs [])
    \\ strip_tac \\ fs []
    \\ `!l1 l2. LIST_REL v_rel l1 l2 ==> LIST_REL v_rel
          (GENLIST (Recclosure loc [] l1 fns') (LENGTH fns') ++ env1)
          (GENLIST (Recclosure loc [] l2 (MAP (\(num_args, x). 
                                                (num_args, HD (remove_ticks [x]))) fns'))
                   (LENGTH fns') ++ env2)` by
     (qpat_x_assum `LIST_REL _ _ _` mp_tac
      \\ rpt (pop_assum kall_tac)
      \\ rpt strip_tac
      \\ match_mp_tac (EVERY2_APPEND_suff) \\ fs []
      \\ fs [LIST_REL_GENLIST]
      \\ `LIST_REL f_rel fns' (MAP (λ(num_args,x). (num_args,HD (remove_ticks [x]))) fns')` by
         (Induct_on `fns'` \\ fs [] \\ Cases_on `h` \\ fs [f_rel_def, code_rel_def])
      \\ fs [])
    \\ fs [case_eq_thms] \\ fs [] \\ rveq \\ fs []
    THEN1
     (qexists_tac `LENGTH ts` \\ fs []
      \\ drule lookup_vars_lemma
      \\ disch_then (qspec_then `names` assume_tac) \\ rfs [])
    \\ drule lookup_vars_lemma
    \\ disch_then (qspec_then `names` assume_tac) \\ rfs []
    \\ first_x_assum drule \\ strip_tac
    \\ first_x_assum drule
    \\ disch_then drule
    \\ disch_then (qspec_then `[e]` mp_tac) \\ fs []
    \\ strip_tac
    \\ qexists_tac `ck + LENGTH ts`
    \\ fs [])
  THEN1 (* App *)
   (fs [LENGTH_EQ_NUM_compute] \\ rveq
    \\ fs [code_rel_def]
    \\ imp_res_tac remove_ticks_App_IMP_mk_Ticks \\ rveq
    \\ fs [remove_ticks_mk_Ticks, remove_ticks_def]
    \\ simp [evaluate_mk_Ticks, dec_clock_def]
    \\ fs [evaluate_def]
    \\ fs [LENGTH_remove_ticks]
    \\ reverse (Cases_on `LENGTH es > 0`) \\ fs []
    THEN1 (qexists_tac `LENGTH ts` \\ rw [])
    \\ fs [pair_case_eq] \\ reverse (fs [case_eq_thms])
    \\ rveq \\ fs []
    \\ first_x_assum drule
    \\ disch_then drule
    \\ disch_then (qspec_then `es` mp_tac)
    \\ fs [] \\ strip_tac
    THEN1 (qexists_tac `ck + LENGTH ts` \\ fs [])
    \\ fs [pair_case_eq] \\ reverse (fs [case_eq_thms])
    \\ rveq \\ fs []
    \\ first_x_assum drule
    \\ disch_then drule
    \\ disch_then (qspec_then `[e1]` mp_tac)
    \\ fs [] \\ strip_tac \\ rveq \\ fs []
    THEN1 (qexists_tac `ck + ck' + LENGTH ts` \\ fs []
           \\ imp_res_tac evaluate_clock
           \\ bump_assum `evaluate (es, _, _) = _`
           \\ drule evaluate_add_clock
           \\ Cases_on `res1` \\ fs [])
    \\ ntac 2 (rename1 `result_rel (LIST_REL v_rel) v_rel rrr (Rval _)`
               \\ Cases_on `rrr` \\ fs [])
    \\ imp_res_tac evaluate_SING \\ rveq
    \\ fs [LIST_REL_LENGTH] \\ rveq \\ fs []
    \\ first_x_assum drule
    \\ ntac 2 (disch_then drule)
    \\ strip_tac
    \\ qexists_tac `ck + ck' + ck'' + LENGTH ts`
    \\ imp_res_tac evaluate_clock \\ fs []
    \\ bump_assum `evaluate (es, _, _) = _`
    \\ drule evaluate_add_clock \\ fs []
    \\ disch_then (qspec_then `ck' + ck''` assume_tac) \\ fs []
    \\ bump_assum `evaluate ([e1], _, _) = _`
    \\ drule evaluate_add_clock \\ fs [])
  THEN1 (* Tick *)
   (fs [LENGTH_EQ_NUM_compute] \\ rveq
    \\ fs [code_rel_def]
    \\ fs [remove_ticks_Tick])
  THEN1 (* Call *)
   (fs [LENGTH_EQ_NUM_compute] \\ rveq
    \\ fs [code_rel_def]
    \\ imp_res_tac remove_ticks_Call_IMP_mk_Ticks \\ rveq
    \\ fs [remove_ticks_mk_Ticks, remove_ticks_def]
    \\ simp [evaluate_mk_Ticks, dec_clock_def]
    \\ fs [evaluate_def]
    \\ fs [pair_case_eq]
    \\ first_x_assum drule
    \\ ntac 2 (disch_then drule)
    \\ disch_then (qspec_then `es` mp_tac)
    \\ fs [] \\ strip_tac
    \\ qexists_tac `ck + LENGTH ts` \\ fs []
    \\ drule state_rel_IMP_code_FEMPTY \\ strip_tac
    \\ fs [find_code_def]
    \\ fs [case_eq_thms] \\ rveq
    \\ Cases_on `res1` \\ fs [])
  THEN1 (* evaluate_app NIL *)
   (fs [evaluate_def] \\ rw [] \\ qexists_tac `0` \\ fs [state_component_equality])
  (* evaluate_app CONS *)
  \\ fs [evaluate_def]
  \\ fs [case_eq_thms] \\ fs [] \\ rveq
  THEN1 (* dest_closure returns NONE *)
   (fs [dest_closure_def]
    \\ fs [case_eq_thms] \\ rveq \\ fs []
    \\ qexists_tac `0` \\ simp []
    \\ imp_res_tac LIST_REL_LENGTH
    \\ imp_res_tac state_rel_IMP_max_app_EQ
    \\ fs []
    THEN1 (every_case_tac \\ fs [])
    \\ Cases_on `EL i fns` \\ fs []
    \\ fs [METIS_PROVE [] ``(if b then SOME x else SOME y) =
                             SOME (if b then x else y)``]
    \\ Cases_on `EL i funs1` \\ fs []
    \\ Cases_on `i < LENGTH fns` \\ fs []   
    \\ bump_assum `LIST_REL f_rel _ _`
    \\ drule (LIST_REL_EL_EQN |> SPEC_ALL |> EQ_IMP_RULE |> fst |> GEN_ALL)
    \\ fs [] \\ disch_then drule \\ fs [f_rel_def])
  THEN1 (* dest_closure returns Partial_app *)
   (imp_res_tac dest_closure_none_loc
    \\ drule dest_closure_SOME_IMP \\ strip_tac
    \\ fs [dest_closure_def]
    \\ imp_res_tac LIST_REL_LENGTH
    \\ imp_res_tac state_rel_IMP_max_app_EQ
    \\ `s1.clock = t1.clock` by fs [state_rel_def] 
    \\ qexists_tac `0`
    \\ fs []
    THEN1
     (IF_CASES_TAC \\ fs []
      \\ IF_CASES_TAC \\ fs [] \\ rveq
      \\ fs [state_rel_def]
      \\ fs [dec_clock_def, state_rel_def]
      \\ irule EVERY2_APPEND_suff \\ fs [])
    THEN1
     (Cases_on `EL i fns` \\ fs []
      \\ Cases_on `EL i funs1` \\ fs []
      \\ fs [METIS_PROVE [] ``(if b then SOME x else SOME y) =
                               SOME (if b then x else y)``]
      \\ Cases_on `i < LENGTH fns` \\ fs []   
      \\ bump_assum `LIST_REL f_rel _ _`
      \\ drule (LIST_REL_EL_EQN |> SPEC_ALL |> EQ_IMP_RULE |> fst |> GEN_ALL) \\ fs []
      \\ disch_then drule \\ simp [] \\ strip_tac
      \\ fs [f_rel_def] \\ rveq
      \\ IF_CASES_TAC
      \\ simp []
      \\ fs [] \\ rveq
      \\ IF_CASES_TAC
      \\ fs [] \\ rveq
      \\ fs [dec_clock_def, state_rel_def]
      \\ irule EVERY2_APPEND_suff \\ fs []))
  (* dest_closure returns Full_app *)
  \\ cheat
)


val remove_ticks_idem = store_thm("remove_ticks_idem",
  ``!xs. remove_ticks (remove_ticks xs) = remove_ticks xs``,
  recInduct remove_ticks_ind \\ rw [remove_ticks_def]
  THEN1 (qspecl_then [`xs`, `y`] strip_assume_tac remove_ticks_cons
         \\ fs [remove_ticks_def])
  \\ simp [MAP_MAP_o, o_DEF, UNCURRY]
  \\ simp [MAP_EQ_f]
  \\ rpt strip_tac
  \\ PairCases_on `x`
  \\ res_tac  \\ fs [])

val rm_call_lemma = prove(
  ``!xs. [Call tr ticks dest es'] = remove_ticks xs ==>
      (?es ticks. es' = remove_ticks es /\
                  (xs = [Call tr ticks dest es] \/
                   (?e t. ([Call tr ticks dest es] = remove_ticks [e]) /\
                          (xs = [Tick t e]))))``,
   recInduct remove_ticks_ind
   \\ rw [remove_ticks_def]
   THEN1 simp [LIST_EQ_REWRITE, LENGTH_remove_ticks]
   \\ res_tac \\ rveq
   \\ fs [Once remove_ticks_def]
   THEN1 simp [remove_ticks_idem]
   \\ metis_tac []);

val _ = export_theory();
