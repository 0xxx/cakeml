open HolKernel Parse boolLib bossLib; val _ = new_theory "bvp_space";

open pred_setTheory arithmeticTheory pairTheory listTheory combinTheory;
open finite_mapTheory sumTheory relationTheory stringTheory optionTheory;
open bytecodeTheory bvlTheory bvpTheory bvp_lemmasTheory;
open sptreeTheory lcsymtacs;

(* BVP optimisation that lumps together MakeSpace operations. *)

val pMakeSpace_def = Define `
  (pMakeSpace (INL c) = c) /\
  (pMakeSpace (INR (k,names,c)) = Seq (MakeSpace k names) c)`;

val pSpace_def = Define `
  (pSpace (MakeSpace k names) = INR (k,names,Skip)) /\
  (pSpace (Seq c1 c2) =
     let d1 = pMakeSpace (pSpace c1) in
     let x2 = pSpace c2 in
       case x2 of
       | INL c4 =>
          (case c1 of
           | MakeSpace k names => INR (k,names,c4)
           | Skip => INL c4
           | _ => INL (Seq d1 c4))
       | INR (k,names,c4) =>
          (case c1 of
           | Skip => INR (k,names,c4)
           | MakeSpace k2 names2 => INR (k+k2,inter names names2,c4)
           | Move dest src =>
               INR (k,insert src () (delete dest names),
                    Seq (Move dest src) c4)
           | Assign dest op args NONE =>
               INR (k,list_insert args (delete dest names),
                    Seq (Assign dest op args NONE) c4)
           | Cut names2 => INR (k,inter names names2,c4)
           | _ => INL (Seq d1 (pMakeSpace x2)))) /\
  (pSpace (Handle ns1 c1 n1 n2 ns2 c2) =
     INL (Handle ns1 (pMakeSpace (pSpace c1)) n1 n2 ns2
                     (pMakeSpace (pSpace c2)))) /\
  (pSpace (If c1 n c2 c3) =
     INL (If (pMakeSpace (pSpace c1)) n (pMakeSpace (pSpace c2))
                                        (pMakeSpace (pSpace c3)))) /\
  (pSpace c = INL c)`;

val pSpaceOpt_def = Define `
  pSpaceOpt c = pMakeSpace (pSpace c)`;

val union_assoc = prove(
  ``!t1 t2 t3. union t1 (union t2 t3) = union (union t1 t2) t3``,
  Induct \\ Cases_on `t2` \\ Cases_on `t3` \\ fs [union_def]);

val pEvalOp_SOME_IMP = prove(
  ``(pEvalOp op x s = SOME (q,r)) ==>
    (pEvalOp op x (s with locals := extra) =
       SOME (q,r with locals := extra))``,
  fs [pEvalOp_def,pEvalOpSpace_def,consume_space_def,bvp_to_bvl_def]
  \\ REPEAT (BasicProvers.CASE_TAC \\ fs []) \\ SRW_TAC [] []
  \\ fs [bvl_to_bvp_def,bvp_state_explode]);

val push_exc_with_locals = prove(
  ``((push_exc env1 env2 (s with locals := xs)) = push_exc env1 env2 s) /\
    ((s with locals := s.locals) = s) /\
    ((push_exc env1 env2 s).locals = env1)``,
  fs [push_exc_def,bvp_state_explode]);

val Seq_Skip = prove(
  ``pEval (Seq c Skip,s) = pEval (c,s)``,
  fs [pEval_def] \\ Cases_on `pEval (c,s)` \\ fs [LET_DEF] \\ SRW_TAC [] []);

val locals_ok_def = Define `
  locals_ok l1 l2 =
    !v x. (lookup v l1 = SOME x) ==> (lookup v l2 = SOME x)`;

val locals_ok_IMP = prove(
  ``locals_ok l1 l2 ==> domain l1 SUBSET domain l2``,
  fs [locals_ok_def,SUBSET_DEF,domain_lookup] \\ METIS_TAC []);

val locals_ok_id = prove(
  ``!l. locals_ok l l``,
  fs [locals_ok_def]);

val locals_ok_cut_env = prove(
  ``locals_ok l1 l2 /\
    (cut_env names l1 = SOME x) ==>
    (cut_env names l2 = SOME x)``,
  fs [cut_env_def] \\ SRW_TAC [] []
  THEN1 (IMP_RES_TAC locals_ok_IMP \\ IMP_RES_TAC SUBSET_TRANS)
  \\ fs [lookup_inter_alt] \\ SRW_TAC [] []
  \\ fs [locals_ok_def,domain_lookup,SUBSET_DEF,PULL_EXISTS]
  \\ fs [oneTheory.one] \\ RES_TAC \\ RES_TAC \\ fs []);

val locals_ok_get_var = prove(
  ``locals_ok s.locals l /\
    (get_var x s = SOME w) ==>
    (get_var x (s with locals := l) = SOME w)``,
  fs [locals_ok_def,get_var_def]);

val locals_ok_get_vars = prove(
  ``!x w.
      locals_ok s.locals l /\
      (get_vars x s = SOME w) ==>
      (get_vars x (s with locals := l) = SOME w)``,
  Induct \\ fs [get_vars_def] \\ REPEAT STRIP_TAC
  \\ Cases_on `get_var h s` \\ fs []
  \\ Cases_on `get_vars x s` \\ fs []
  \\ IMP_RES_TAC locals_ok_get_var \\ fs []);

val pEval_locals = prove(
  ``!c s res s2 vars l.
      res <> SOME Error /\ (pEval (c,s) = (res,s2)) /\
      locals_ok s.locals l ==>
      ?w. (pEval (c, s with locals := l) =
             (res,if res = NONE then s2 with locals := w
                                else s2)) /\
          locals_ok s2.locals w``,
  recInduct pEval_ind \\ REPEAT STRIP_TAC \\ fs [pEval_def]
  THEN1 (* Skip *) (METIS_TAC [])
  THEN1 (* Move *)
   (Cases_on `get_var src s` \\ fs [] \\ SRW_TAC [] []
    \\ IMP_RES_TAC locals_ok_get_var \\ fs []
    \\ fs [get_var_def,lookup_union,set_var_def,locals_ok_def]
    \\ Q.EXISTS_TAC `insert dest x l` \\ fs [lookup_insert]
    \\ METIS_TAC [])
  THEN1 (* Assign *)
   (Cases_on `names_opt` \\ fs []
    \\ Cases_on `op_space_reset op` \\ fs [cut_state_opt_def] THEN1
     (Cases_on `get_vars args s` \\ fs [cut_state_opt_def]
      \\ IMP_RES_TAC locals_ok_get_vars \\ fs []
      \\ Cases_on `pEvalOp op x s` \\ fs []
      \\ Cases_on `x'` \\ fs [] \\ SRW_TAC [] []
      \\ IMP_RES_TAC pEvalOp_SOME_IMP \\ fs [set_var_def]
      \\ Q.EXISTS_TAC `insert dest q l`
      \\ fs [set_var_def,locals_ok_def,lookup_insert]
      \\ METIS_TAC [pEvalOp_IMP])
    \\ fs [cut_state_def]
    \\ Cases_on `cut_env x s.locals` \\ fs []
    \\ IMP_RES_TAC locals_ok_cut_env \\ fs []
    \\ Q.EXISTS_TAC `s2.locals` \\ fs [locals_ok_def]
    \\ SRW_TAC [] [bvp_state_explode])
  THEN1 (* Tick *)
   (Cases_on `s.clock = 0` \\ fs [] \\ SRW_TAC [] []
    \\ fs [locals_ok_def,call_env_def,EVAL ``fromList []``,lookup_def,
           dec_clock_def] \\ METIS_TAC [])
  THEN1 (* MakeSpace *)
   (Cases_on `cut_env names s.locals` \\ fs []
    \\ IMP_RES_TAC locals_ok_cut_env
    \\ fs [LET_DEF,add_space_def,bvp_state_explode,locals_ok_def])
  THEN1 (* Cut *)
   (Cases_on `cut_env names s.locals` \\ fs []
    \\ IMP_RES_TAC locals_ok_cut_env
    \\ fs [LET_DEF,add_space_def,bvp_state_explode,locals_ok_def])
  THEN1 (* Raise *)
   (Cases_on `get_var n s` \\ fs [] \\ SRW_TAC [] []
    \\ `jump_exc (s with locals := l) = jump_exc s` by
         fs [jump_exc_def] \\ Cases_on `jump_exc s` \\ fs []
    \\ `get_var n (s with locals := l) = SOME x` by
         fs [locals_ok_def,get_var_def] \\ fs []
    \\ srw_tac [] [] \\ Q.EXISTS_TAC `s2.locals`
    \\ fs [locals_ok_def])
  THEN1 (* Return *)
   (Cases_on `get_var n s` \\ fs [] \\ SRW_TAC [] []
    \\ `get_var n (s with locals := l) = SOME x` by
         fs [locals_ok_def,get_var_def] \\ fs []
    \\ srw_tac [] [call_env_def]
    \\ fs [locals_ok_def,call_env_def,EVAL ``fromList []``,lookup_def,
           dec_clock_def])
  THEN1 (* Seq *)
   (Cases_on `pEval (c1,s)` \\ fs [LET_DEF]
    \\ Cases_on `q = SOME Error` \\ fs []
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `l`) \\ fs []
    \\ REPEAT STRIP_TAC \\ fs []
    \\ Cases_on `q` \\ fs [] \\ SRW_TAC [] [] \\ METIS_TAC [])
  THEN1 (* Handle *)
   (Cases_on `cut_env ns1 s.locals` \\ fs []
    \\ Cases_on `cut_env ns2 s.locals` \\ fs []
    \\ IMP_RES_TAC locals_ok_cut_env
    \\ fs [] \\ `push_exc x x' (s with locals := union s.locals vars) =
                 push_exc x x' s` by fs [push_exc_def] \\ fs []
    \\ Cases_on `pEval (c1,push_exc x x' s)` \\ fs []
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `x`) \\ fs [union_LN]
    \\ fs [push_exc_with_locals,locals_ok_id]
    \\ Cases_on `q` \\ fs [] \\ REPEAT STRIP_TAC
    \\ fs [push_exc_with_locals]
    \\ `(push_exc x x' s with locals := x) = push_exc x x' s` by
         (fs [push_exc_def,bvp_state_explode] \\ NO_TAC) \\ fs []
    THEN1
     (Cases_on `get_var v r` \\ fs []
      \\ IMP_RES_TAC locals_ok_get_var \\ fs []
      \\ Cases_on `pop_exc r` \\ fs [] \\ SRW_TAC [] []
      \\ fs [pop_exc_def,set_var_def]
      \\ METIS_TAC [locals_ok_id])
    \\ REVERSE (Cases_on `x''`) \\ fs [push_exc_with_locals]
    \\ SRW_TAC [] [] THEN1 METIS_TAC [locals_ok_id]
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `(set_var n b r).locals`)
    \\ fs [push_exc_with_locals,locals_ok_id])
  THEN1 (* If *)
   (Cases_on `pEval (g,s)` \\ fs []
    \\ REVERSE (Cases_on `q`) \\ fs []
    \\ SRW_TAC [] [] \\ fs []
    \\ FIRST_X_ASSUM (STRIP_ASSUME_TAC o Q.SPEC `l`) \\ fs []
    \\ REV_FULL_SIMP_TAC (srw_ss()) []
    THEN1 METIS_TAC [locals_ok_def]
    \\ Cases_on `get_var n r` \\ fs []
    \\ IMP_RES_TAC locals_ok_get_var \\ fs []
    \\ Cases_on `x = bool_to_val T` \\ fs []
    \\ Cases_on `x = bool_to_val F` \\ fs [])
  THEN1 (* Call *)
   (Cases_on `s.clock = 0` \\ fs [] \\ SRW_TAC [] []
    THEN1 (fs [locals_ok_def,call_env_def,EVAL ``fromList []``,lookup_def,
             dec_clock_def] \\ METIS_TAC [])
    \\ Cases_on `get_vars args s` \\ fs []
    \\ IMP_RES_TAC locals_ok_get_vars \\ fs []
    \\ Cases_on `find_code dest x s.code` \\ fs []
    \\ Cases_on `x'` \\ fs []
    \\ Cases_on `ret` \\ fs [] THEN1
     (`call_env q (dec_clock (s with locals := l)) =
       call_env q (dec_clock s)` by
         fs [bvp_state_explode,dec_clock_def,call_env_def] \\ fs []
      \\ METIS_TAC [locals_ok_id,push_exc_with_locals])
    \\ Cases_on `x'` \\ fs []
    \\ Cases_on `cut_env r' s.locals` \\ fs []
    \\ IMP_RES_TAC locals_ok_cut_env \\ fs []
    \\ `call_env q (push_env x' (dec_clock (s with locals := l))) =
        call_env q (push_env x' (dec_clock s))` by ALL_TAC THEN1
     (fs [bvp_state_explode,dec_clock_def,call_env_def,push_env_def])
    \\ fs [] \\ METIS_TAC [locals_ok_id,push_exc_with_locals]));

val pEval_pSpaceOpt = prove(
  ``!c s res s2 vars l.
      res <> SOME Error /\ (pEval (c,s) = (res,s2)) /\
      locals_ok s.locals l ==>
      ?w. (pEval (pSpaceOpt c, s with locals := l) =
             (res,if res = NONE then s2 with locals := w
                                else s2)) /\
          locals_ok s2.locals w``,

  SIMP_TAC std_ss [pSpaceOpt_def]
  \\ recInduct pEval_ind \\ REPEAT STRIP_TAC
  \\ fs [pEval_def,pSpace_def,pMakeSpace_def]
  THEN1 (* Skip *)
   (fs [pEval_def] \\ METIS_TAC [])
  THEN1 (* Move *)
   (Cases_on `get_var src s` \\ fs [] \\ SRW_TAC [] []
    \\ fs [get_var_def,lookup_union,set_var_def,locals_ok_def]
    \\ RES_TAC \\ fs []
    \\ Q.EXISTS_TAC `insert dest x l` \\ fs [lookup_insert]
    \\ METIS_TAC [])
  THEN1 (* Assign *)
   (Cases_on `names_opt` \\ fs []
    \\ Cases_on `op_space_reset op` \\ fs [cut_state_opt_def] THEN1
     (Cases_on `get_vars args s` \\ fs [cut_state_opt_def]
      \\ `get_vars args (s with locals := l) =
          get_vars args s` by
       (MATCH_MP_TAC EVERY_get_vars
        \\ fs [EVERY_MEM,locals_ok_def]
        \\ REPEAT STRIP_TAC \\ IMP_RES_TAC get_vars_IMP_domain
        \\ fs [domain_lookup])
      \\ fs [] \\ Cases_on `pEvalOp op x s` \\ fs []
      \\ Cases_on `x'` \\ fs [] \\ SRW_TAC [] []
      \\ IMP_RES_TAC pEvalOp_SOME_IMP \\ fs [set_var_def]
      \\ Q.EXISTS_TAC `insert dest q l`
      \\ fs [set_var_def,locals_ok_def,lookup_insert]
      \\ METIS_TAC [pEvalOp_IMP])
    \\ `cut_state x (s with locals := l) = cut_state x s` by
     (fs [cut_state_def]
      \\ Cases_on `cut_env x s.locals` \\ fs []
      \\ IMP_RES_TAC locals_ok_cut_env \\ fs [] \\ NO_TAC)
    \\ fs [] \\ POP_ASSUM (K ALL_TAC)
    \\ fs [cut_state_def,cut_env_def]
    \\ Cases_on `domain x SUBSET domain s.locals` \\ fs []
    \\ Q.EXISTS_TAC `s2.locals` \\ fs [locals_ok_def]
    \\ SRW_TAC [] [bvp_state_explode])
  THEN1 (* Tick *)
   (Cases_on `s.clock = 0` \\ fs [] \\ SRW_TAC [] []
    \\ fs [locals_ok_def,call_env_def,EVAL ``fromList []``,lookup_def,
           dec_clock_def] \\ METIS_TAC [])
  THEN1 (* MakeSpace *)
   (Cases_on `cut_env names s.locals` \\ fs []
    \\ IMP_RES_TAC locals_ok_cut_env
    \\ fs [LET_DEF,add_space_def,bvp_state_explode,locals_ok_def])
  THEN1 (* Cut *)
   (Cases_on `cut_env names s.locals` \\ fs []
    \\ IMP_RES_TAC locals_ok_cut_env
    \\ fs [LET_DEF,add_space_def,bvp_state_explode,locals_ok_def])
  THEN1 (* Raise *)
   (Cases_on `get_var n s` \\ fs [] \\ SRW_TAC [] []
    \\ `jump_exc (s with locals := l) = jump_exc s` by
         fs [jump_exc_def] \\ Cases_on `jump_exc s` \\ fs []
    \\ `get_var n (s with locals := l) = SOME x` by
         fs [locals_ok_def,get_var_def] \\ fs []
    \\ srw_tac [] [] \\ Q.EXISTS_TAC `s2.locals`
    \\ fs [locals_ok_def])
  THEN1 (* Return *)
   (Cases_on `get_var n s` \\ fs [] \\ SRW_TAC [] []
    \\ `get_var n (s with locals := l) = SOME x` by
         fs [locals_ok_def,get_var_def] \\ fs []
    \\ srw_tac [] [call_env_def]
    \\ fs [locals_ok_def,call_env_def,EVAL ``fromList []``,lookup_def,
           dec_clock_def])

  THEN1 (* Seq *)

   (

    fs [LET_DEF] \\ Cases_on `pSpace c2` \\ fs [] THEN1
     (Cases_on `pEval (c1,s)` \\ fs []
      \\ Cases_on `c1` \\ fs [pMakeSpace_def]
      THEN1 (fs [pEval_def])
      \\ Cases_on `q = SOME Error` \\ fs []
      \\ SIMP_TAC std_ss [Once pEval_def] \\ fs [pSpace_def,pMakeSpace_def]
      \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `l`)
      \\ fs [] \\ REPEAT STRIP_TAC
      \\ fs [LET_DEF,Seq_Skip] \\ Cases_on `q` \\ fs [] \\ SRW_TAC [] []
      \\ Q.EXISTS_TAC `w` \\ fs [])
    \\ PairCases_on `y` \\ fs []
    \\ Cases_on `pEval (c1,s)` \\ fs []
    \\ REVERSE (Cases_on `c1`) \\ fs []
    \\ TRY (fs [pMakeSpace_def,pSpace_def]
      \\ SIMP_TAC std_ss [Once pEval_def,LET_DEF]
      \\ fs [] \\ SRW_TAC [] []
      \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `l`) \\ fs []
      \\ Cases_on `q = SOME Error` \\ fs [] \\ REPEAT STRIP_TAC
      \\ fs [] \\ Cases_on `q` \\ fs [] \\ SRW_TAC [] []
      \\ Q.EXISTS_TAC `w` \\ fs [] \\ NO_TAC)
    THEN1 (* Cut *)
     (fs [pMakeSpace_def,pSpace_def,Seq_Skip]
      \\ Cases_on `q = SOME Error` \\ fs []
      \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `l`) \\ fs []
      \\ SIMP_TAC std_ss [Once pEval_def] \\ fs []
      \\ Cases_on `cut_env s' l` \\ fs []
      \\ REPEAT STRIP_TAC \\ SRW_TAC [] [] \\ fs []
      \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `w`) \\ fs []
      \\ ONCE_REWRITE_TAC [pEval_def] \\ fs [LET_DEF]
      \\ fs [pEval_def] \\ Cases_on `cut_env y1 w` \\ fs []
      \\ REPEAT STRIP_TAC
      \\ `cut_env (inter y1 s') l = SOME x'` by
       (fs [cut_env_def] \\ SRW_TAC [] []
        \\ fs [bvp_state_explode,add_space_def] \\ SRW_TAC [] []
        \\ fs [SUBSET_DEF,domain_inter,lookup_inter_alt]
        \\ Cases_on `x IN domain y1` \\ fs []) \\ fs [] \\ fs []
      \\ `(add_space (s with locals := l) y0 with locals := x') =
          (add_space (r with locals := w) y0 with locals := x')` by
       (fs [bvp_state_explode,add_space_def] \\ SRW_TAC [] []
        \\ DECIDE_TAC)
      \\ fs [] \\ METIS_TAC [])
    THEN1 (* MakeSpace *)
     (fs [pMakeSpace_def,pSpace_def,Seq_Skip]
      \\ Cases_on `q = SOME Error` \\ fs []
      \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `l`) \\ fs []
      \\ SIMP_TAC std_ss [Once pEval_def] \\ fs []
      \\ Cases_on `cut_env s' l` \\ fs []
      \\ REPEAT STRIP_TAC \\ SRW_TAC [] [] \\ fs []
      \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `w`) \\ fs []
      \\ ONCE_REWRITE_TAC [pEval_def] \\ fs [LET_DEF]
      \\ fs [pEval_def] \\ Cases_on `cut_env y1 w` \\ fs []
      \\ REPEAT STRIP_TAC
      \\ `cut_env (inter y1 s') l = SOME x'` by
       (fs [cut_env_def] \\ SRW_TAC [] []
        \\ fs [bvp_state_explode,add_space_def] \\ SRW_TAC [] []
        \\ fs [SUBSET_DEF,domain_inter,lookup_inter_alt]
        \\ Cases_on `x IN domain y1` \\ fs []) \\ fs []
      \\ fs []
      \\ `(add_space (s with locals := l) (y0 + n) with locals := x') =
          (add_space (r with locals := w) y0 with locals := x')` by
       (fs [bvp_state_explode,add_space_def] \\ SRW_TAC [] []
        \\ DECIDE_TAC)
      \\ fs [] \\ METIS_TAC [])
    THEN1 (* Seq *)
     (fs [pMakeSpace_def]
      \\ SIMP_TAC std_ss [Once pEval_def,LET_DEF]
      \\ fs [] \\ SRW_TAC [] []
      \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `l`) \\ fs []
      \\ Cases_on `q = SOME Error` \\ fs [] \\ REPEAT STRIP_TAC
      \\ fs [] \\ Cases_on `q` \\ fs [] \\ SRW_TAC [] [] \\ METIS_TAC [])
    THEN1 (* Assign *)
     (fs [pMakeSpace_def,pSpace_def] \\ REVERSE (Cases_on `o'`)
      \\ fs [pEval_def,cut_state_opt_def] THEN1
       (fs [pMakeSpace_def,pSpace_def,pEval_def,cut_state_opt_def,cut_state_def]
        \\ Cases_on `cut_env x s.locals` \\ fs [] \\ SRW_TAC [] []
        \\ IMP_RES_TAC locals_ok_cut_env \\ fs []
        \\ Cases_on `get_vars l' (s with locals := x')` \\ fs []
        \\ SRW_TAC [] []
        \\ Cases_on `pEvalOp b x'' (s with locals := x')`
        \\ fs [] \\ SRW_TAC [] []
        \\ Cases_on `x'''` \\ fs [] \\ SRW_TAC [] []
        \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `l`) \\ fs []
        \\ REPEAT STRIP_TAC \\ fs []
        \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC
             `(set_var n q' r').locals`) \\ fs []
        \\ fs [locals_ok_id] \\ REPEAT STRIP_TAC
        \\ Cases_on `cut_env y1 (set_var n q' r').locals` \\ fs [LET_DEF]
        \\ Q.EXISTS_TAC `w'` \\ fs []
        \\ Q.PAT_ASSUM `pEval xxx = yyy` (fn th => SIMP_TAC std_ss [GSYM th])
        \\ AP_TERM_TAC \\ AP_TERM_TAC
        \\ fs [bvp_state_explode,add_space_def])
      \\ Cases_on `op_space_reset b` \\ fs [] \\ SRW_TAC [] []
      \\ Cases_on `get_vars l' s` \\ fs [] \\ SRW_TAC [] []
      \\ Cases_on `pEvalOp b x s` \\ fs [] \\ SRW_TAC [] []
      \\ Cases_on `x'` \\ fs [] \\ SRW_TAC [] []
      \\ fs [pMakeSpace_def,pSpace_def]
      \\ fs [pEval_def,cut_state_opt_def]
      \\ cheat (* provable *))
    THEN1 (* Move *)
     (fs [pMakeSpace_def,pSpace_def]
      \\ SIMP_TAC std_ss [Once pEval_def,LET_DEF]
      \\ SIMP_TAC std_ss [Once pEval_def,LET_DEF]
      \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `l`) \\ fs []
      \\ SIMP_TAC std_ss [Once pEval_def,LET_DEF]
      \\ POP_ASSUM MP_TAC
      \\ SIMP_TAC std_ss [Once pEval_def,LET_DEF]
      \\ REPEAT STRIP_TAC \\ Cases_on `get_var n0 s` \\ fs []
      \\ SRW_TAC [] []
      \\ IMP_RES_TAC locals_ok_get_var \\ fs []
      \\ Q.PAT_ASSUM `!ww.bb==>bbb` (MP_TAC o Q.SPEC `insert n x w`) \\ fs []
      \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1 cheat
      \\ fs [pEval_def]
      \\ Cases_on `cut_env y1 (insert n x w)` \\ fs [LET_DEF]
      \\ REPEAT STRIP_TAC
      \\ fs [bvp_state_explode,add_space_def,set_var_def] \\ SRW_TAC [] []
      \\ `cut_env (insert n0 () (delete n y1)) l =
             SOME (insert n0 x (delete n x'))` by ALL_TAC THEN1
       (fs [cut_env_def] \\ SRW_TAC [] [] \\ fs []
        \\ fs [lookup_insert,lookup_inter_alt,lookup_delete]
        THEN1 (fs [get_var_def,domain_lookup])
        THEN1 (fs [SUBSET_DEF] \\ METIS_TAC [])
        \\ Cases_on `x' = n0` THEN1 (fs [get_var_def]) \\ fs []
        \\ SRW_TAC [] [] \\ fs []) \\ fs []
      \\ SIMP_TAC (srw_ss()) [get_var_def]
      \\ Q.ABBREV_TAC `s4 = s with <|locals := x'; space := s.space + y0|>`
      \\ Q.ABBREV_TAC `ll = insert n x (insert n0 x (delete n x'))`
      \\ `s with <|locals := ll; space := s.space + y0|> =
          s4 with locals := ll` by ALL_TAC
      THEN1 (UNABBREV_ALL_TAC \\ fs [bvp_state_explode]) \\ fs []
      \\ `locals_ok s4.locals ll` by ALL_TAC THEN1
       (UNABBREV_ALL_TAC \\ fs [bvp_state_explode,locals_ok_def]
        \\ fs [lookup_insert,lookup_delete,cut_env_def]
        \\ Q.PAT_ASSUM `xxx = x'` (fn th => fs [GSYM th])
        \\ fs [lookup_insert,lookup_inter_alt,lookup_delete]
        \\ REPEAT STRIP_TAC \\ Cases_on `v=n` \\ fs []
        \\ Cases_on `v=n0` \\ fs []
        \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `n0`) \\ fs [])
       \\ MP_TAC (Q.SPECL [`y2`,`s4`] pEval_locals)
       \\ fs [] \\ REPEAT STRIP_TAC \\ RES_TAC \\ fs []
       \\ Cases_on `res` \\ fs []
       \\ fs [bvp_state_explode] \\ SRW_TAC [] []
       \\ METIS_TAC [locals_ok_def])
    THEN1 (* Skip *)
     (fs [pMakeSpace_def,pSpace_def]
      \\ SIMP_TAC std_ss [Once pEval_def,LET_DEF]
      \\ POP_ASSUM (ASSUME_TAC o REWRITE_RULE [pEval_def])
      \\ fs [] \\ SRW_TAC [] [] \\ POP_ASSUM (K ALL_TAC)
      \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `l`) \\ fs []
      \\ SIMP_TAC std_ss [Once pEval_def,LET_DEF]
      \\ REPEAT STRIP_TAC \\ fs [] \\ NO_TAC))
   THEN1 (* Handle *)
   (Cases_on `cut_env ns1 s.locals` \\ fs []
    \\ Cases_on `cut_env ns2 s.locals` \\ fs []
    \\ IMP_RES_TAC locals_ok_cut_env
    \\ fs [] \\ `push_exc x x' (s with locals := union s.locals vars) =
                 push_exc x x' s` by fs [push_exc_def] \\ fs []
    \\ Cases_on `pEval (c1,push_exc x x' s)` \\ fs []
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `x`) \\ fs [union_LN]
    \\ fs [push_exc_with_locals,locals_ok_id]
    \\ Cases_on `q` \\ fs [] \\ REPEAT STRIP_TAC
    \\ fs [push_exc_with_locals]
    \\ `(push_exc x x' s with locals := x) = push_exc x x' s` by
         (fs [push_exc_def,bvp_state_explode] \\ NO_TAC) \\ fs []
    THEN1
     (Cases_on `get_var v r` \\ fs []
      \\ IMP_RES_TAC locals_ok_get_var \\ fs []
      \\ Cases_on `pop_exc r` \\ fs [] \\ SRW_TAC [] []
      \\ fs [pop_exc_def,set_var_def]
      \\ METIS_TAC [locals_ok_id])
    \\ REVERSE (Cases_on `x''`) \\ fs [push_exc_with_locals]
    \\ SRW_TAC [] [] THEN1 METIS_TAC [locals_ok_id]
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `(set_var n b r).locals`)
    \\ fs [push_exc_with_locals,locals_ok_id])
  THEN1 (* If *)
   (Cases_on `pEval (g,s)` \\ fs []
    \\ REVERSE (Cases_on `q`) \\ fs []
    \\ SRW_TAC [] [] \\ fs []
    \\ FIRST_X_ASSUM (STRIP_ASSUME_TAC o Q.SPEC `l`) \\ fs []
    \\ REV_FULL_SIMP_TAC (srw_ss()) []
    THEN1 METIS_TAC [locals_ok_def]
    \\ Cases_on `get_var n r` \\ fs []
    \\ IMP_RES_TAC locals_ok_get_var \\ fs []
    \\ Cases_on `x = bool_to_val T` \\ fs []
    \\ Cases_on `x = bool_to_val F` \\ fs [])
  THEN1 (* Call *)
   (Cases_on `s.clock = 0` \\ fs [] \\ SRW_TAC [] []
    THEN1 (fs [locals_ok_def,call_env_def,EVAL ``fromList []``,lookup_def,
             dec_clock_def] \\ METIS_TAC [])
    \\ Cases_on `get_vars args s` \\ fs []
    \\ IMP_RES_TAC locals_ok_get_vars \\ fs []
    \\ Cases_on `find_code dest x s.code` \\ fs []
    \\ Cases_on `x'` \\ fs []
    \\ Cases_on `ret` \\ fs [] THEN1
     (`call_env q (dec_clock (s with locals := l)) =
       call_env q (dec_clock s)` by
         fs [bvp_state_explode,dec_clock_def,call_env_def] \\ fs []
      \\ METIS_TAC [locals_ok_id,push_exc_with_locals])
    \\ Cases_on `x'` \\ fs []
    \\ Cases_on `cut_env r' s.locals` \\ fs []
    \\ IMP_RES_TAC locals_ok_cut_env \\ fs []
    \\ `call_env q (push_env x' (dec_clock (s with locals := l))) =
        call_env q (push_env x' (dec_clock s))` by ALL_TAC THEN1
     (fs [bvp_state_explode,dec_clock_def,call_env_def,push_env_def])
    \\ fs [] \\ METIS_TAC [locals_ok_id,push_exc_with_locals]));

val pSpaceOpt = store_thm("pSpaceOpt_correct",
  ``!c s.
      FST (pEval (c,s)) <> NONE /\
      FST (pEval (c,s)) <> SOME Error ==>
      (pEval (pSpaceOpt c, s) = pEval (c,s))``,
  REPEAT STRIP_TAC \\ Cases_on `pEval (c,s)` \\ fs []
  \\ MP_TAC (Q.SPECL [`c`,`s`] pEval_pSpaceOpt)
  \\ fs [] \\ REPEAT STRIP_TAC
  \\ POP_ASSUM (MP_TAC o Q.SPECL [`s.locals`])
  \\ fs [locals_ok_id,push_exc_with_locals]
  \\ REPEAT STRIP_TAC \\ fs []);

val _ = export_theory();
