open preamble bvlSemTheory dataSemTheory dataPropsTheory copying_gcTheory
     int_bitwiseTheory data_to_wordPropsTheory finite_mapTheory
     data_to_wordTheory wordPropsTheory labPropsTheory whileTheory
     set_sepTheory semanticsPropsTheory word_to_wordProofTheory
     helperLib alignmentTheory blastLib word_bignumTheory wordLangTheory
     word_bignumProofTheory gen_gc_partialTheory gc_sharedTheory;
local open gen_gcTheory in end

val _ = new_theory "data_to_wordProof";

val _ = hide "next";

val _ = temp_overload_on("FALSE_CONST",``Const (n2w 18:'a word)``)
val _ = temp_overload_on("TRUE_CONST",``Const (n2w 2:'a word)``)

(* TODO: move *)
val _ = type_abbrev("state", ``:('a,'b)wordSem$state``)

fun op by1 (q,tac) = q by (tac \\ NO_TAC)
infix 8 by1

val LESS_EQ_IMP_APPEND_ALT = store_thm("LESS_EQ_IMP_APPEND_ALT",
  ``∀n xs. n ≤ LENGTH xs ⇒ ∃ys zs. xs = ys ++ zs ∧ LENGTH zs = n``,
  Induct \\ fs [LENGTH_NIL] \\ Cases_on `xs` \\ fs []
  \\ rw [] \\ res_tac \\ rveq
  \\ Cases_on `ys` \\ fs [] THEN1 (qexists_tac `[]` \\ fs [])
  \\ qexists_tac `BUTLAST (h::h'::t)` \\ fs []
  \\ qexists_tac `LAST (h::h'::t) :: zs` \\ fs []
  \\ fs [APPEND_FRONT_LAST]);

val word_asr_dimindex = store_thm("word_asr_dimindex",
  ``!w:'a word n. dimindex (:'a) <= n ==> (w >> n = w >> (dimindex (:'a) - 1))``,
  fs [word_asr_def,fcpTheory.CART_EQ,fcpTheory.FCP_BETA]
  \\ rw [] \\ Cases_on `i` \\ fs [] \\ rw [] \\ fs [word_msb_def]);

val WORD_MUL_BIT0 = Q.store_thm("WORD_MUL_BIT0",
  `!a b. (a * b) ' 0 <=> a ' 0 /\ b ' 0`,
  fs [word_mul_def,word_index,bitTheory.BIT0_ODD,ODD_MULT]
  \\ Cases \\ Cases \\ fs [word_index,bitTheory.BIT0_ODD]);

val word_lsl_index = Q.store_thm("word_lsl_index",
  `i < dimindex(:'a) ⇒
    (((w:'a word) << n) ' i ⇔ n ≤ i ∧ w ' (i-n))`,
  rw[word_lsl_def,fcpTheory.FCP_BETA]);

val word_lsr_index = Q.store_thm("word_lsr_index",
  `i < dimindex(:'a) ⇒
   (((w:'a word) >>> n) ' i ⇔ i + n < dimindex(:'a) ∧ w ' (i+n))`,
  rw[word_lsr_def,fcpTheory.FCP_BETA]);

val lsr_lsl = Q.store_thm("lsr_lsl",
  `∀w n. aligned n w ⇒ (w >>> n << n = w)`,
  simp [aligned_def, alignmentTheory.align_shift]);

val word_index_test = Q.store_thm("word_index_test",
  `n < dimindex (:'a) ==> (w ' n <=> ((w && n2w (2 ** n)) <> 0w:'a word))`,
  srw_tac [wordsLib.WORD_BIT_EQ_ss] [wordsTheory.word_index])

val word_and_one_eq_0_iff = Q.store_thm("word_and_one_eq_0_iff", (* same in stack_alloc *)
  `!w. ((w && 1w) = 0w) <=> ~(w ' 0)`,
  srw_tac [wordsLib.WORD_BIT_EQ_ss] [word_index])

val word_index_0 = Q.store_thm("word_index_0",
  `!w. w ' 0 <=> ~((1w && w) = 0w)`,
  metis_tac [word_and_one_eq_0_iff,WORD_AND_COMM]);

val ABS_w2n = Q.store_thm("ABS_w2n[simp]",
  `ABS (&w2n w) = &w2n w`,
  rw[integerTheory.INT_ABS_EQ_ID]);

val n2mw_w2n = Q.store_thm("n2mw_w2n",
  `∀w. n2mw (w2n w) = if w = 0w then [] else [w]`,
  simp[Once multiwordTheory.n2mw_def]
  \\ gen_tac \\ IF_CASES_TAC \\ fs[]
  \\ Q.ISPEC_THEN`w`mp_tac w2n_lt
  \\ simp[LESS_DIV_EQ_ZERO,multiwordTheory.n2mw_NIL]);

val get_var_set_var = Q.store_thm("get_var_set_var[simp]",
  `get_var n (set_var n w s) = SOME w`,
  full_simp_tac(srw_ss())[wordSemTheory.get_var_def,wordSemTheory.set_var_def]);

val set_var_set_var = Q.store_thm("set_var_set_var[simp]",
  `set_var n v (set_var n w s) = set_var n v s`,
  fs[wordSemTheory.state_component_equality,wordSemTheory.set_var_def,
      insert_shadow]);

val toAList_LN = Q.store_thm("toAList_LN[simp]",
  `toAList LN = []`,
  EVAL_TAC)

val adjust_set_LN = Q.store_thm("adjust_set_LN[simp]",
  `adjust_set LN = insert 0 () LN`,
  srw_tac[][adjust_set_def,fromAList_def]);

val push_env_termdep = store_thm("push_env_termdep",
  ``(push_env y opt t).termdep = t.termdep``,
  Cases_on `opt` \\ TRY (PairCases_on `x`)
  \\ fs [wordSemTheory.push_env_def]
  \\ pairarg_tac \\ fs []);

val ALOOKUP_SKIP_LEMMA = Q.prove(
  `¬MEM n (MAP FST xs) /\ d = e ==>
    ALOOKUP (xs ++ [(n,d)] ++ ys) n = SOME e`,
  full_simp_tac(srw_ss())[ALOOKUP_APPEND] \\ fs[GSYM ALOOKUP_NONE])

val LAST_EQ = Q.prove(
  `(LAST (x::xs) = if xs = [] then x else LAST xs) /\
    (FRONT (x::xs) = if xs = [] then [] else x::FRONT xs)`,
  Cases_on `xs` \\ full_simp_tac(srw_ss())[]);

val LASTN_LIST_REL_LEMMA = Q.prove(
  `!xs1 ys1 xs n y ys x P.
      LASTN n xs1 = x::xs /\ LIST_REL P xs1 ys1 ==>
      ?y ys. LASTN n ys1 = y::ys /\ P x y /\ LIST_REL P xs ys`,
  Induct \\ Cases_on `ys1` \\ full_simp_tac(srw_ss())[LASTN_ALT] \\ rpt strip_tac
  \\ imp_res_tac LIST_REL_LENGTH \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ `F` by decide_tac);

val LASTN_CONS_IMP_LENGTH = Q.store_thm("LASTN_CONS_IMP_LENGTH",
  `!xs n y ys.
      n <= LENGTH xs ==>
      (LASTN n xs = y::ys) ==> LENGTH (y::ys) = n`,
  Induct \\ full_simp_tac(srw_ss())[LASTN_ALT]
  \\ srw_tac[][] THEN1 decide_tac \\ full_simp_tac(srw_ss())[GSYM NOT_LESS]);

val LASTN_IMP_APPEND = Q.store_thm("LASTN_IMP_APPEND",
  `!xs n ys.
      n <= LENGTH xs /\ (LASTN n xs = ys) ==>
      ?zs. xs = zs ++ ys /\ LENGTH ys = n`,
  Induct \\ full_simp_tac(srw_ss())[LASTN_ALT] \\ srw_tac[][] THEN1 decide_tac
  \\ `n <= LENGTH xs` by decide_tac \\ res_tac \\ full_simp_tac(srw_ss())[]
  \\ qpat_x_assum `xs = zs ++ LASTN n xs` (fn th => simp [Once th]));

val NOT_NIL_IMP_LAST = Q.prove(
  `!xs x. xs <> [] ==> LAST (x::xs) = LAST xs`,
  Cases \\ full_simp_tac(srw_ss())[]);

val IS_SOME_IF = Q.prove(
  `IS_SOME (if b then x else y) = if b then IS_SOME x else IS_SOME y`,
  Cases_on `b` \\ full_simp_tac(srw_ss())[]);

val PERM_ALL_DISTINCT_MAP = Q.prove(
  `!xs ys. PERM xs ys ==>
            ALL_DISTINCT (MAP f xs) ==>
            ALL_DISTINCT (MAP f ys) /\ !x. MEM x ys <=> MEM x xs`,
  full_simp_tac(srw_ss())[MEM_PERM] \\ srw_tac[][]
  \\ `PERM (MAP f xs) (MAP f ys)` by full_simp_tac(srw_ss())[PERM_MAP]
  \\ metis_tac [ALL_DISTINCT_PERM])

val ALL_DISTINCT_MEM_IMP_ALOOKUP_SOME = Q.prove(
  `!xs x y. ALL_DISTINCT (MAP FST xs) /\ MEM (x,y) xs ==> ALOOKUP xs x = SOME y`,
  Induct \\ full_simp_tac(srw_ss())[]
  \\ Cases \\ full_simp_tac(srw_ss())[ALOOKUP_def] \\ srw_tac[][]
  \\ res_tac \\ full_simp_tac(srw_ss())[MEM_MAP,FORALL_PROD]
  \\ rev_full_simp_tac(srw_ss())[]) |> SPEC_ALL;

val IS_SOME_ALOOKUP_EQ = Q.prove(
  `!l x. IS_SOME (ALOOKUP l x) = MEM x (MAP FST l)`,
  Induct \\ full_simp_tac(srw_ss())[]
  \\ Cases \\ full_simp_tac(srw_ss())[ALOOKUP_def] \\ srw_tac[][]);

val MEM_IMP_IS_SOME_ALOOKUP = Q.prove(
  `!l x y. MEM (x,y) l ==> IS_SOME (ALOOKUP l x)`,
  full_simp_tac(srw_ss())[IS_SOME_ALOOKUP_EQ,MEM_MAP,EXISTS_PROD] \\ metis_tac []);

val SUBSET_INSERT_EQ_SUBSET = Q.prove(
  `~(x IN s) ==> (s SUBSET (x INSERT t) <=> s SUBSET t)`,
  full_simp_tac(srw_ss())[EXTENSION]);

val EVERY2_IMP_EL = Q.prove(
  `!xs ys P n. EVERY2 P xs ys /\ n < LENGTH ys ==> P (EL n xs) (EL n ys)`,
  Induct \\ Cases_on `ys` \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ Cases_on `n` \\ full_simp_tac(srw_ss())[]);

val FST_PAIR_EQ = Q.prove(
  `!x v. (FST x,v) = x <=> v = SND x`,
  Cases \\ full_simp_tac(srw_ss())[]);

val EVERY2_APPEND_IMP = Q.prove(
  `!xs1 xs2 zs P.
      EVERY2 P (xs1 ++ xs2) zs ==>
      ?zs1 zs2. zs = zs1 ++ zs2 /\ EVERY2 P xs1 zs1 /\ EVERY2 P xs2 zs2`,
  Induct \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ res_tac \\ full_simp_tac(srw_ss())[]
  \\ Q.LIST_EXISTS_TAC [`y::zs1`,`zs2`] \\ full_simp_tac(srw_ss())[]);

val ZIP_ID = Q.prove(
  `!xs. ZIP (MAP FST xs, MAP SND xs) = xs`,
  Induct \\ full_simp_tac(srw_ss())[]);

val write_bytearray_isWord = Q.store_thm("write_bytearray_isWord",
  `∀ls a m x.
   isWord (m x) ⇒
   isWord (write_bytearray a ls m dm be x)`,
  Induct \\ rw[wordSemTheory.write_bytearray_def]
  \\ rw[wordSemTheory.mem_store_byte_aux_def]
  \\ every_case_tac \\ fs[]
  \\ simp[APPLY_UPDATE_THM]
  \\ rw[isWord_def]);

val FOLDL_LENGTH_LEMMA = Q.prove(
  `!xs k l d q r.
      FOLDL (λ(i,t) a. (i + d,insert i a t)) (k,l) xs = (q,r) ==>
      q = LENGTH xs * d + k`,
  Induct \\ fs [FOLDL] \\ rw [] \\ res_tac \\ fs [MULT_CLAUSES]);

val fromList_SNOC = Q.store_thm("fromList_SNOC",
 `!xs y. fromList (SNOC y xs) = insert (LENGTH xs) y (fromList xs)`,
  fs [fromList_def,FOLDL_APPEND,SNOC_APPEND] \\ rw []
  \\ Cases_on `FOLDL (λ(i,t) a. (i + 1,insert i a t)) (0,LN) xs`
  \\ fs [] \\ imp_res_tac FOLDL_LENGTH_LEMMA \\ fs []);

val fromList2_SNOC = Q.store_thm("fromList2_SNOC",
 `!xs y. fromList2 (SNOC y xs) = insert (2 * LENGTH xs) y (fromList2 xs)`,
  fs [fromList2_def,FOLDL_APPEND,SNOC_APPEND] \\ rw []
  \\ Cases_on `FOLDL (λ(i,t) a. (i + 2,insert i a t)) (0,LN) xs`
  \\ fs [] \\ imp_res_tac FOLDL_LENGTH_LEMMA \\ fs []);

(* -- *)

(* -------------------------------------------------------
    word_ml_inv: definition and lemmas
   ------------------------------------------------------- *)

val join_env_def = Define `
  join_env env vs =
    MAP (\(n,v). (THE (lookup ((n-2) DIV 2) env), v))
      (FILTER (\(n,v). n <> 0 /\ EVEN n) vs)`

val flat_def = Define `
  (flat (Env env::xs) (StackFrame vs _::ys) =
     join_env env vs ++ flat xs ys) /\
  (flat (Exc env _::xs) (StackFrame vs _::ys) =
     join_env env vs ++ flat xs ys) /\
  (flat _ _ = [])`

val flat_APPEND = Q.prove(
  `!xs ys xs1 ys1.
      LENGTH xs = LENGTH ys ==>
      flat (xs ++ xs1) (ys ++ ys1) = flat xs ys ++ flat xs1 ys1`,
  Induct \\ Cases_on `ys` \\ full_simp_tac(srw_ss())[flat_def] \\ srw_tac[][]
  \\ Cases_on `h'` \\ Cases_on `h`
  \\ TRY (Cases_on `o'`) \\ full_simp_tac(srw_ss())[flat_def]);

val adjust_var_DIV_2 = Q.prove(
  `(adjust_var n - 2) DIV 2 = n`,
  full_simp_tac(srw_ss())[ONCE_REWRITE_RULE[MULT_COMM]adjust_var_def,MULT_DIV]);

val adjust_var_DIV_2_ANY = Q.prove(
  `(adjust_var n) DIV 2 = n + 1`,
  fs [adjust_var_def,ONCE_REWRITE_RULE[MULT_COMM]ADD_DIV_ADD_DIV]);

val EVEN_adjust_var = Q.prove(
  `EVEN (adjust_var n)`,
  full_simp_tac(srw_ss())[adjust_var_def,EVEN_MOD2,
    ONCE_REWRITE_RULE[MULT_COMM]MOD_TIMES]);

val adjust_var_NEQ_0 = Q.prove(
  `adjust_var n <> 0`,
  rpt strip_tac \\ full_simp_tac(srw_ss())[adjust_var_def]);

val adjust_var_NEQ_1 = Q.prove(
  `adjust_var n <> 1`,
  rpt strip_tac
  \\ `EVEN (adjust_var n) = EVEN 1` by full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[EVEN_adjust_var]);

val adjust_var_NEQ = Q.store_thm("adjust_var_NEQ[simp]",
  `adjust_var n <> 0 /\
    adjust_var n <> 1 /\
    adjust_var n <> 3 /\
    adjust_var n <> 5 /\
    adjust_var n <> 7 /\
    adjust_var n <> 9 /\
    adjust_var n <> 11 /\
    adjust_var n <> 13`,
  rpt strip_tac \\ fs [adjust_var_NEQ_0]
  \\ `EVEN (adjust_var n) = EVEN 1` by full_simp_tac(srw_ss())[]
  \\ `EVEN (adjust_var n) = EVEN 3` by full_simp_tac(srw_ss())[]
  \\ `EVEN (adjust_var n) = EVEN 5` by full_simp_tac(srw_ss())[]
  \\ `EVEN (adjust_var n) = EVEN 7` by full_simp_tac(srw_ss())[]
  \\ `EVEN (adjust_var n) = EVEN 9` by full_simp_tac(srw_ss())[]
  \\ `EVEN (adjust_var n) = EVEN 11` by full_simp_tac(srw_ss())[]
  \\ `EVEN (adjust_var n) = EVEN 13` by full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[EVEN_adjust_var]);

val unit_opt_eq = Q.prove(
  `(x = y:unit option) <=> (IS_SOME x <=> IS_SOME y)`,
  Cases_on `x` \\ Cases_on `y` \\ full_simp_tac(srw_ss())[]);

val adjust_var_11 = Q.prove(
  `(adjust_var n = adjust_var m) <=> n = m`,
  full_simp_tac(srw_ss())[adjust_var_def,EQ_MULT_LCANCEL]);

val lookup_adjust_var_adjust_set = Q.prove(
  `lookup (adjust_var n) (adjust_set s) = lookup n s`,
  full_simp_tac(srw_ss())[lookup_def,adjust_set_def,lookup_fromAList,unit_opt_eq,adjust_var_NEQ_0]
  \\ full_simp_tac(srw_ss())[IS_SOME_ALOOKUP_EQ,MEM_MAP,PULL_EXISTS,EXISTS_PROD,adjust_var_11]
  \\ full_simp_tac(srw_ss())[MEM_toAList] \\ Cases_on `lookup n s` \\ full_simp_tac(srw_ss())[]);

val adjust_var_IN_adjust_set = Q.store_thm("adjust_var_IN_adjust_set",
  `adjust_var n IN domain (adjust_set (s:num_set)) <=> n IN domain s`,
  fs [domain_lookup,lookup_adjust_var_adjust_set]);

val none_opt_eq = Q.prove(
  `((x = NONE) = (y = NONE)) <=> (IS_SOME x <=> IS_SOME y)`,
  Cases_on `x` \\ Cases_on `y` \\ full_simp_tac(srw_ss())[]);

val lookup_adjust_var_adjust_set_NONE = Q.prove(
  `lookup (adjust_var n) (adjust_set s) = NONE <=> lookup n s = NONE`,
  full_simp_tac(srw_ss())[lookup_def,adjust_set_def,lookup_fromAList,adjust_var_NEQ_0,none_opt_eq]
  \\ full_simp_tac(srw_ss())[IS_SOME_ALOOKUP_EQ,MEM_MAP,PULL_EXISTS,EXISTS_PROD,adjust_var_11]
  \\ full_simp_tac(srw_ss())[MEM_toAList] \\ Cases_on `lookup n s` \\ full_simp_tac(srw_ss())[]);

val lookup_adjust_var_adjust_set_SOME_UNIT = Q.prove(
  `lookup (adjust_var n) (adjust_set s) = SOME () <=> IS_SOME (lookup n s)`,
  Cases_on `lookup (adjust_var n) (adjust_set s) = NONE`
  \\ pop_assum (fn th => assume_tac th THEN
       assume_tac (SIMP_RULE std_ss [lookup_adjust_var_adjust_set_NONE] th))
  \\ full_simp_tac(srw_ss())[] \\ Cases_on `lookup n s`
  \\ Cases_on `lookup (adjust_var n) (adjust_set s)` \\ full_simp_tac(srw_ss())[]);

val word_ml_inv_lookup = Q.prove(
  `word_ml_inv (heap,be,a,sp,sp1,gens) limit c refs
      (ys ++ join_env l1 (toAList (inter l2 (adjust_set l1))) ++ xs) /\
    lookup n l1 = SOME x /\
    lookup (adjust_var n) l2 = SOME w ==>
    word_ml_inv (heap,be,a,sp,sp1,gens) limit c refs
      (ys ++ [(x,w)] ++ join_env l1 (toAList (inter l2 (adjust_set l1))) ++ xs)`,
  full_simp_tac(srw_ss())[toAList_def,foldi_def,LET_DEF]
  \\ full_simp_tac(srw_ss())[GSYM toAList_def] \\ srw_tac[][]
  \\ `MEM (x,w) (join_env l1 (toAList (inter l2 (adjust_set l1))))` by
   (full_simp_tac(srw_ss())[join_env_def,MEM_MAP,MEM_FILTER,EXISTS_PROD,MEM_toAList,lookup_inter]
    \\ qexists_tac `adjust_var n` \\ full_simp_tac(srw_ss())[adjust_var_DIV_2,EVEN_adjust_var]
    \\ full_simp_tac(srw_ss())[adjust_var_NEQ_0] \\ every_case_tac
    \\ full_simp_tac(srw_ss())[lookup_adjust_var_adjust_set_NONE])
  \\ full_simp_tac(srw_ss())[MEM_SPLIT] \\ full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[adjust_var_def]
  \\ qpat_x_assum `word_ml_inv yyy limit c refs xxx` mp_tac
  \\ match_mp_tac word_ml_inv_rearrange \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]);

val word_ml_inv_get_var_IMP = Q.store_thm("word_ml_inv_get_var_IMP",
  `word_ml_inv (heap,be,a,sp,sp1,gens) limit c refs
      (join_env s.locals (toAList (inter t.locals (adjust_set s.locals)))++envs) /\
    get_var n s.locals = SOME x /\
    get_var (adjust_var n) t = SOME w ==>
    word_ml_inv (heap,be,a,sp,sp1,gens) limit c refs
      ([(x,w)]++join_env s.locals
          (toAList (inter t.locals (adjust_set s.locals)))++envs)`,
  srw_tac[][] \\ match_mp_tac (word_ml_inv_lookup
             |> Q.INST [`ys`|->`[]`] |> SIMP_RULE std_ss [APPEND])
  \\ full_simp_tac(srw_ss())[get_var_def,wordSemTheory.get_var_def]);

val word_ml_inv_get_vars_IMP = Q.store_thm("word_ml_inv_get_vars_IMP",
  `!n x w envs.
      word_ml_inv (heap,be,a,sp,sp1,gens) limit c refs
        (join_env s.locals
           (toAList (inter t.locals (adjust_set s.locals)))++envs) /\
      get_vars n s.locals = SOME x /\
      get_vars (MAP adjust_var n) t = SOME w ==>
      word_ml_inv (heap,be,a,sp,sp1,gens) limit c refs
        (ZIP(x,w)++join_env s.locals
           (toAList (inter t.locals (adjust_set s.locals)))++envs)`,
  Induct \\ full_simp_tac(srw_ss())[get_vars_def,wordSemTheory.get_vars_def] \\ rpt strip_tac
  \\ every_case_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ imp_res_tac word_ml_inv_get_var_IMP
  \\ Q.MATCH_ASSUM_RENAME_TAC `dataSem$get_var h s.locals = SOME x7`
  \\ Q.MATCH_ASSUM_RENAME_TAC `_ (adjust_var h) _ = SOME x8`
  \\ `word_ml_inv (heap,be,a,sp,sp1,gens) limit c refs
        (join_env s.locals (toAList (inter t.locals (adjust_set s.locals))) ++
        (x7,x8)::envs)` by
   (pop_assum mp_tac \\ match_mp_tac word_ml_inv_rearrange
    \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[])
  \\ res_tac \\ pop_assum (K all_tac) \\ pop_assum mp_tac
  \\ match_mp_tac word_ml_inv_rearrange
  \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]) |> SPEC_ALL;

val IMP_adjust_var = Q.prove(
  `n <> 0 /\ EVEN n ==> adjust_var ((n - 2) DIV 2) = n`,
  full_simp_tac(srw_ss())[EVEN_EXISTS] \\ srw_tac[][] \\ Cases_on `m` \\ full_simp_tac(srw_ss())[MULT_CLAUSES]
  \\ once_rewrite_tac [MULT_COMM] \\ full_simp_tac(srw_ss())[MULT_DIV]
  \\ full_simp_tac(srw_ss())[adjust_var_def] \\ decide_tac);

val unit_some_eq_IS_SOME = Q.prove(
  `!x. (x = SOME ()) <=> IS_SOME x`,
  Cases \\ full_simp_tac(srw_ss())[]);

val word_ml_inv_insert = Q.store_thm("word_ml_inv_insert",
  `word_ml_inv (heap,be,a,sp,sp1,gens) limit c refs
      ([(x,w)]++join_env d (toAList (inter l (adjust_set d)))++xs) ==>
    word_ml_inv (heap,be,a,sp,sp1,gens) limit c refs
      (join_env (insert dest x d)
        (toAList (inter (insert (adjust_var dest) w l)
                           (adjust_set (insert dest x d))))++xs)`,
  match_mp_tac word_ml_inv_rearrange \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[join_env_def,MEM_MAP,MEM_FILTER,EXISTS_PROD]
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[MEM_toAList]
  \\ full_simp_tac(srw_ss())[lookup_insert,lookup_inter_alt]
  \\ Cases_on `dest = (p_1 - 2) DIV 2` \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[adjust_var_DIV_2]
  \\ imp_res_tac IMP_adjust_var \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[domain_lookup] \\ every_case_tac \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[adjust_var_11] \\ full_simp_tac(srw_ss())[]
  \\ disj1_tac \\ disj2_tac \\ qexists_tac `p_1` \\ full_simp_tac(srw_ss())[unit_some_eq_IS_SOME]
  \\ full_simp_tac(srw_ss())[adjust_set_def,lookup_fromAList] \\ rev_full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[IS_SOME_ALOOKUP_EQ,MEM_MAP,PULL_EXISTS,EXISTS_PROD,adjust_var_11]
  \\ full_simp_tac(srw_ss())[MEM_toAList,lookup_insert] \\ every_case_tac \\ full_simp_tac(srw_ss())[]);

(* -------------------------------------------------------
    definition and verification of GC functions
   ------------------------------------------------------- *)

val ptr_to_addr_def = Define `
  ptr_to_addr conf base (w:'a word) =
    base + ((w >>> (shift_length conf)) * bytes_in_word)`

val is_fwd_ptr_def = Define `
  (is_fwd_ptr (Word w) = ((w && 3w) = 0w)) /\
  (is_fwd_ptr _ = F)`;

val update_addr_def = Define `
  update_addr conf fwd_ptr (old_addr:'a word) =
    ((fwd_ptr << (shift_length conf)) ||
     ((small_shift_length conf - 1) -- 0) old_addr)`

val memcpy_def = Define `
  memcpy w a b m dm =
    if w = 0w then (b,m,T) else
      let (b1,m1,c1) = memcpy (w-1w) (a + bytes_in_word) (b + bytes_in_word)
                      ((b =+ m a) m) dm in
        (b1,m1,c1 /\ a IN dm /\ b IN dm)`

val word_gc_move_def = Define `
  (word_gc_move conf (Loc l1 l2,i,pa,old,m,dm) = (Loc l1 l2,i,pa,m,T)) /\
  (word_gc_move conf (Word w,i,pa,old,m,dm) =
     if (w && 1w) = 0w then (Word w,i,pa,m,T) else
       let c = (ptr_to_addr conf old w IN dm) in
       let v = m (ptr_to_addr conf old w) in
         if is_fwd_ptr v then
           (Word (update_addr conf (theWord v >>> 2) w),i,pa,m,c)
         else
           let header_addr = ptr_to_addr conf old w in
           let c = (c /\ header_addr IN dm /\ isWord (m header_addr)) in
           let len = decode_length conf (theWord (m header_addr)) in
           let v = i + len + 1w in
           let (pa1,m1,c1) = memcpy (len+1w) header_addr pa m dm in
           let c = (c /\ header_addr IN dm /\ c1) in
           let m1 = (header_addr =+ Word (i << 2)) m1 in
             (Word (update_addr conf i w),v,pa1,m1,c))`

val word_gen_gc_partial_move_def = Define `
  (word_gen_gc_partial_move conf (Loc l1 l2,i,pa,old,m,dm,gs,rs) = (Loc l1 l2,i,pa,m,T)) /\
  (word_gen_gc_partial_move conf (Word w,i,pa,old,m,dm,gs,rs) =
   if (w && 1w) = 0w then (Word w,i,pa,m,T) else
   let header_addr = ptr_to_addr conf old w in
     if header_addr <+ gs \/ rs <=+ header_addr then
         (Word w, i, pa, m, T)
       else
         let c = (ptr_to_addr conf old w IN dm) in
         let v = m (ptr_to_addr conf old w) in
           if is_fwd_ptr v then
             (Word (update_addr conf (theWord v >>> 2) w),i,pa,m,c)
           else
             let c = (c /\ header_addr IN dm /\ isWord (m header_addr)) in
             let len = decode_length conf (theWord (m header_addr)) in
             let v = i + len + 1w in
             let (pa1,m1,c1) = memcpy (len+1w) header_addr pa m dm in
             let c = (c /\ header_addr IN dm /\ c1) in
             let m1 = (header_addr =+ Word (i << 2)) m1 in
               (Word (update_addr conf i w),v,pa1,m1,c))`

val word_gc_move_roots_def = Define `
  (word_gc_move_roots conf ([],i,pa,old,m,dm) = ([],i,pa,m,T)) /\
  (word_gc_move_roots conf (w::ws,i,pa,old,m,dm) =
     let (w1,i1,pa1,m1,c1) = word_gc_move conf (w,i,pa,old,m,dm) in
     let (ws2,i2,pa2,m2,c2) = word_gc_move_roots conf (ws,i1,pa1,old,m1,dm) in
       (w1::ws2,i2,pa2,m2,c1 /\ c2))`

val word_gc_move_list_def = Define `
  word_gc_move_list conf (a:'a word,l:'a word,i,pa:'a word,old,m,dm) =
   if l = 0w then (a,i,pa,m,T) else
     let w = (m a):'a word_loc in
     let (w1,i1,pa1,m1,c1) = word_gc_move conf (w,i,pa,old,m,dm) in
     let m1 = (a =+ w1) m1 in
     let (a2,i2,pa2,m2,c2) = word_gc_move_list conf (a+bytes_in_word,l-1w,i1,pa1,old,m1,dm) in
       (a2,i2,pa2,m2,a IN dm /\ c1 /\ c2)`

val word_gen_gc_partial_move_roots_def = Define `
  (word_gen_gc_partial_move_roots conf ([],i,pa,old,m,dm,gs,rs) = ([],i,pa,m,T)) /\
  (word_gen_gc_partial_move_roots conf (w::ws,i,pa,old,m,dm,gs,rs) =
     let (w1,i1,pa1,m1,c1) = word_gen_gc_partial_move conf (w,i,pa,old,m,dm,gs,rs) in
     let (ws2,i2,pa2,m2,c2) = word_gen_gc_partial_move_roots conf (ws,i1,pa1,old,m1,dm,gs,rs) in
       (w1::ws2,i2,pa2,m2,c1 /\ c2))`

val word_gen_gc_partial_move_list_def = Define `
  word_gen_gc_partial_move_list conf (a:'a word,l:'a word,i,pa:'a word,old,m,dm,gs,rs) =
   if l = 0w then (a,i,pa,m,T) else
     let w = (m a):'a word_loc in
     let (w1,i1,pa1,m1,c1) = word_gen_gc_partial_move conf (w,i,pa,old,m,dm,gs,rs) in
     let m1 = (a =+ w1) m1 in
     let (a2,i2,pa2,m2,c2) = word_gen_gc_partial_move_list conf (a+bytes_in_word,l-1w,i1,pa1,old,m1,dm,gs,rs) in
       (a2,i2,pa2,m2,a IN dm /\ c1 /\ c2)`

val word_gen_gc_partial_move_list_zero = Q.prove(`
  word_gen_gc_partial_move_list conf (a,0w,i,pa,old,m,dm,gs,rs) = (a,i,pa,m,T)`,
  fs[Once word_gen_gc_partial_move_list_def]);

val word_gen_gc_partial_move_list_suc = Q.prove(`
  word_gen_gc_partial_move_list conf (a,(n2w(SUC l):'a word),i,pa,old,m,dm,gs,rs) =
   if n2w(SUC l) = (0w:'a word) then (a,i,pa,m,T) else
     let w = m a in
     let (w1,i1,pa1,m1,c1) = word_gen_gc_partial_move conf (w,i,pa,old,m,dm,gs,rs) in
     let m1 = (a =+ w1) m1 in
     let (a2,i2,pa2,m2,c2) = word_gen_gc_partial_move_list conf (a+bytes_in_word,n2w l,i1,pa1,old,m1,dm,gs,rs) in
       (a2,i2,pa2,m2,a IN dm /\ c1 /\ c2)`,
  CONV_TAC(RATOR_CONV(RAND_CONV(PURE_ONCE_REWRITE_CONV[word_gen_gc_partial_move_list_def])))
  >> fs[n2w_SUC]);

val word_gen_gc_partial_move_list_append = Q.prove(`
  !a l l' i pa old m dm gs rs conf.
  (l+l' < dimword (:'a)) ==> (
  word_gen_gc_partial_move_list conf (a,(n2w(l+l'):'a word),i,pa,old,m,dm,gs,rs) =
    let (a2,i2,pa2,m2,c2) = word_gen_gc_partial_move_list conf (a,n2w l,i,pa,old,m,dm,gs,rs) in
    let (a3,i3,pa3,m3,c3) = word_gen_gc_partial_move_list conf (a2,n2w l',i2,pa2,old,m2,dm,gs,rs) in
      (a3,i3,pa3,m3,(c2 /\ c3)))`,
  Induct_on `l`
  >> rpt strip_tac
  >> fs[]
  >> ntac 2 (pairarg_tac >> fs[])
  >- fs[word_gen_gc_partial_move_list_zero]
  >> fs[word_gen_gc_partial_move_list_suc,GSYM ADD_SUC]
  >> ntac 4 (pairarg_tac >> fs[])
  >> rfs[] >> metis_tac[])

val word_gc_move_loop_def = Define `
  word_gc_move_loop k conf (pb,i,pa,old,m,dm,c) =
    if pb = pa then (i,pa,m,c) else
    if k = 0 then (i,pa,m,F) else
      let w = m pb in
      let c = (c /\ pb IN dm /\ isWord w) in
      let len = decode_length conf (theWord w) in
        if word_bit 2 (theWord w) then
          let pb = pb + (len + 1w) * bytes_in_word in
            word_gc_move_loop (k-1n) conf (pb,i,pa,old,m,dm,c)
        else
          let pb = pb + bytes_in_word in
          let (pb,i1,pa1,m1,c1) = word_gc_move_list conf (pb,len,i,pa,old,m,dm) in
            word_gc_move_loop (k-1n) conf (pb,i1,pa1,old,m1,dm,c /\ c1)`

val word_full_gc_def = Define `
  word_full_gc conf (all_roots,new,old:'a word,m,dm) =
    let (rs,i1,pa1,m1,c1) = word_gc_move_roots conf (all_roots,0w,new,old,m,dm) in
    let (i1,pa1,m1,c2) =
          word_gc_move_loop (dimword(:'a)) conf (new,i1,pa1,old,m1,dm,c1)
    in (rs,i1,pa1,m1,c2)`

val word_gc_fun_assum_def = Define `
  word_gc_fun_assum (conf:data_to_word$config) (s:store_name |-> 'a word_loc) <=>
    {Globals; CurrHeap; OtherHeap; HeapLength} SUBSET FDOM s /\
    isWord (s ' OtherHeap) /\
    isWord (s ' CurrHeap) /\
    isWord (s ' HeapLength) /\
    good_dimindex (:'a) /\
    conf.len_size <> 0 /\
    conf.len_size + 2 < dimindex (:'a) /\
    shift_length conf < dimindex (:'a)`

val word_gc_fun_def = Define `
  (word_gc_fun (conf:data_to_word$config)):'a gc_fun_type = \(roots,m,dm,s).
     let c = word_gc_fun_assum conf s in
     let new = theWord (s ' OtherHeap) in
     let old = theWord (s ' CurrHeap) in
     let len = theWord (s ' HeapLength) in
     let all_roots = s ' Globals::roots in
     let (roots1,i1,pa1,m1,c2) = word_full_gc conf (all_roots,new,old,m,dm) in
     let s1 = s |++ [(CurrHeap, Word new);
                     (OtherHeap, Word old);
                     (NextFree, Word pa1);
                     (TriggerGC, Word (new + len));
                     (EndOfHeap, Word (new + len));
                     (Globals, HD roots1)] in
       if c /\ c2 then SOME (TL roots1,m1,s1) else NONE`

val one_and_or_1 = Q.prove(
  `(1w && (w || 1w)) = 1w`,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index])

val one_and_or_3 = Q.prove(
  `(3w && (w || 3w)) = 3w`,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index])

val ODD_not_zero = Q.prove(
  `ODD n ==> n2w n <> 0w`,
  CCONTR_TAC \\ full_simp_tac std_ss []
  \\ `((n2w n):'a word) ' 0 = (0w:'a word) ' 0` by metis_tac []
  \\ full_simp_tac(srw_ss())[wordsTheory.word_index,bitTheory.BIT_def,bitTheory.BITS_THM]
  \\ full_simp_tac(srw_ss())[dimword_def,bitTheory.ODD_MOD2_LEM])

val three_not_0 = Q.store_thm("three_not_0[simp]",
  `3w <> 0w`,
  match_mp_tac ODD_not_zero \\ full_simp_tac(srw_ss())[]);

val DISJ_EQ_IMP = METIS_PROVE [] ``(~b \/ c) <=> (b ==> c)``

val three_and_shift_2 = Q.prove(
  `(3w && (w << 2)) = 0w`,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index])

val shift_to_zero = Q.prove(
  `3w >>> 2 = 0w`,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index])

val shift_around_under_big_shift = Q.prove(
  `!w n k. n <= k ==> (w << n >>> n << k = w << k)`,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index])

val select_shift_out = Q.prove(
  `n <> 0 /\ n <= m ==> ((n - 1 -- 0) (w || v << m) = (n - 1 -- 0) w)`,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index]);

val shift_length_NOT_ZERO = Q.store_thm("shift_length_NOT_ZERO[simp]",
  `shift_length conf <> 0`,
  full_simp_tac(srw_ss())[shift_length_def] \\ decide_tac);

val get_addr_and_1_not_0 = Q.prove(
  `(1w && get_addr conf k a) <> 0w`,
  Cases_on `a` \\ full_simp_tac(srw_ss())[get_addr_def,get_lowerbits_def]
  \\ rewrite_tac [one_and_or_1,GSYM WORD_OR_ASSOC] \\ full_simp_tac(srw_ss())[]);

val one_lsr_shift_length = Q.prove(
  `1w >>> shift_length conf = 0w`,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss]
    [word_index, shift_length_def])

val ptr_to_addr_get_addr = Q.prove(
  `k * 2 ** shift_length conf < dimword (:'a) ==>
    ptr_to_addr conf curr (get_addr conf k a) =
    curr + n2w k * bytes_in_word:'a word`,
  strip_tac
  \\ full_simp_tac(srw_ss())[ptr_to_addr_def,bytes_in_word_def,WORD_MUL_LSL,get_addr_def]
  \\ simp_tac std_ss [Once WORD_MULT_COMM] \\ AP_THM_TAC \\ AP_TERM_TAC
  \\ full_simp_tac(srw_ss())[get_lowerbits_LSL_shift_length,word_mul_n2w]
  \\ once_rewrite_tac [GSYM w2n_11]
  \\ rewrite_tac [w2n_lsr] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[MULT_DIV]
  \\ Cases_on `2 ** shift_length conf` \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `n` \\ full_simp_tac(srw_ss())[MULT_CLAUSES]
  \\ decide_tac);

val is_fws_ptr_OR_3 = Q.prove(
  `is_fwd_ptr (Word (w << 2)) /\ ~is_fwd_ptr (Word (w || 3w))`,
  full_simp_tac(srw_ss())[is_fwd_ptr_def] \\ rewrite_tac [one_and_or_3,three_and_shift_2]
  \\ full_simp_tac(srw_ss())[]);

val is_fws_ptr_OR_15 = Q.prove(
  `~is_fwd_ptr (Word (w || 15w))`,
  full_simp_tac(srw_ss())[is_fwd_ptr_def]
  \\ srw_tac [wordsLib.WORD_BIT_EQ_ss] [word_index, get_lowerbits_def]
  \\ qexists_tac `0` \\ fs []);

val is_fws_ptr_OR_10111 = Q.prove(
  `~is_fwd_ptr (Word (w || 0b10111w))`,
  full_simp_tac(srw_ss())[is_fwd_ptr_def]
  \\ srw_tac [wordsLib.WORD_BIT_EQ_ss] [word_index, get_lowerbits_def]
  \\ qexists_tac `0` \\ fs []);

val is_fws_ptr_OR_7 = Q.prove(
  `~is_fwd_ptr (Word (w || 7w))`,
  full_simp_tac(srw_ss())[is_fwd_ptr_def]
  \\ srw_tac [wordsLib.WORD_BIT_EQ_ss] [word_index, get_lowerbits_def]
  \\ qexists_tac `0` \\ fs []);

val select_get_lowerbits = Q.prove(
  `(shift_length conf − 1 -- 0) (get_lowerbits conf a) =
   get_lowerbits conf a /\
   (small_shift_length conf − 1 -- 0) (get_lowerbits conf a) =
   get_lowerbits conf a`,
  Cases_on `a`
  \\ srw_tac [wordsLib.WORD_BIT_EQ_ss] [word_index, get_lowerbits_def,
              small_shift_length_def,shift_length_def]
  \\ eq_tac \\ rw [] \\ fs []);

val LE_DIV_LT_IMP = Q.prove(
  `n <= l DIV 2 ** m /\ k < n ==> k * 2 ** m < l`,
  srw_tac[][] \\ `k < l DIV 2 ** m` by decide_tac
  \\ full_simp_tac(srw_ss())[X_LT_DIV,MULT_CLAUSES,GSYM ADD1]
  \\ Cases_on `2 ** m` \\ full_simp_tac(srw_ss())[]
  \\ decide_tac);

val word_bits_eq_slice_shift = Q.store_thm("word_bits_eq_slice_shift",
  `((k -- n) w) = (((k '' n) w) >>> n)`,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index]
  \\ Cases_on `i + n < dimindex (:'a)`
  \\ fs []
  )

val word_slice_or = Q.prove(
  `(k '' n) (w || v) = ((k '' n) w || (k '' n) v)`,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index]
  \\ eq_tac
  \\ rw []
  \\ fs []
  )

val word_slice_lsl_eq_0 = Q.prove(
  `(k '' n) (w << (k + 1)) = 0w`,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index])

val word_slice_2_3_eq_0 = Q.prove(
  `(n '' 2) 3w = 0w`,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index])

val can_select_def = Define `
  can_select k n w <=> ((k - 1 -- n) (w << n) = w)`

val read_length_lemma = Q.prove(
  `can_select (n+2) 2 (n2w k :'a word) ==>
    (((n + 1 -- 2) (h ≪ (2 + n) ‖ n2w k ≪ 2 ‖ 3w)) = n2w k :'a word)`,
  full_simp_tac(srw_ss())[word_bits_eq_slice_shift,word_slice_or,can_select_def,DECIDE ``n+2-1=n+1n``]
  \\ full_simp_tac(srw_ss())[DECIDE ``2+n=n+1+1n``,word_slice_lsl_eq_0,word_slice_2_3_eq_0]);

val memcpy_thm = Q.prove(
  `!xs a:'a word c b m m1 dm b1 ys frame.
      memcpy (n2w (LENGTH xs):'a word) a b m dm = (b1,m1,c) /\
      (LENGTH ys = LENGTH xs) /\ LENGTH xs < dimword(:'a) /\
      (frame * word_list a xs * word_list b ys) (fun2set (m,dm)) ==>
      (frame * word_list a xs * word_list b xs) (fun2set (m1,dm)) /\
      b1 = b + n2w (LENGTH xs) * bytes_in_word /\ c`,
  Induct_on `xs` \\ Cases_on `ys`
  THEN1 (simp [LENGTH,Once memcpy_def,LENGTH])
  THEN1 (simp [LENGTH,Once memcpy_def,LENGTH])
  THEN1 (rpt strip_tac \\ full_simp_tac(srw_ss())[LENGTH])
  \\ rpt gen_tac \\ strip_tac
  \\ qpat_x_assum `_ = (b1,m1,c)`  mp_tac
  \\ once_rewrite_tac [memcpy_def]
  \\ asm_rewrite_tac [n2w_11]
  \\ drule LESS_MOD
  \\ simp_tac (srw_ss()) [ADD1,GSYM word_add_n2w]
  \\ pop_assum mp_tac
  \\ simp_tac (srw_ss()) [word_list_def,LET_THM]
  \\ pairarg_tac
  \\ first_x_assum drule
  \\ full_simp_tac(srw_ss())[] \\ NTAC 2 strip_tac
  \\ qpat_x_assum `_ = (b1',m1',c1)` mp_tac
  \\ SEP_W_TAC \\ SEP_F_TAC
  \\ full_simp_tac(srw_ss())[AC STAR_ASSOC STAR_COMM]
  \\ rpt (disch_then assume_tac)
  \\ full_simp_tac(srw_ss())[] \\ imp_res_tac (DECIDE ``n+1n<k ==> n<k``) \\ full_simp_tac(srw_ss())[]
  \\ rpt var_eq_tac \\ SEP_R_TAC \\ full_simp_tac(srw_ss())[WORD_LEFT_ADD_DISTRIB]);

val LESS_EQ_IMP_APPEND = Q.prove(
  `!n xs. n <= LENGTH xs ==> ?ys zs. xs = ys ++ zs /\ LENGTH ys = n`,
  Induct_on `xs` \\ full_simp_tac(srw_ss())[] \\ Cases_on `n` \\ full_simp_tac(srw_ss())[LENGTH_NIL]
  \\ srw_tac[][] \\ res_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ qexists_tac `h::ys` \\ full_simp_tac(srw_ss())[]);

val NOT_is_fwd_ptr = Q.prove(
  `word_payload addrs ll tag tt1 conf = (h,ts,c5) ==> ~is_fwd_ptr (Word h)`,
  Cases_on `tag` \\ fs [word_payload_def] \\ rw [make_byte_header_def]
  \\ full_simp_tac std_ss [GSYM WORD_OR_ASSOC,is_fws_ptr_OR_3,is_fws_ptr_OR_15,
      is_fws_ptr_OR_10111,is_fws_ptr_OR_7,isWord_def,theWord_def,make_header_def,LET_DEF]);

val word_gc_move_thm = Q.prove(
  `(copying_gc$gc_move (x,[],a,n,heap,T,limit) = (x1,h1,a1,n1,heap1,T)) /\
    heap_length heap <= dimword (:'a) DIV 2 ** shift_length conf /\
    (word_heap curr heap conf * word_list pa xs * frame) (fun2set (m,dm)) /\
    (word_gc_move conf (word_addr conf x,n2w a,pa,curr,m,dm) =
      (w:'a word_loc,i1,pa1,m1,c1)) /\
    LENGTH xs = n ==>
    ?xs1.
      (word_heap curr heap1 conf *
       word_heap pa h1 conf *
       word_list pa1 xs1 * frame) (fun2set (m1,dm)) /\
      (w = word_addr conf x1) /\
      heap_length heap1 = heap_length heap /\
      c1 /\ (i1 = n2w a1) /\ n1 = LENGTH xs1 /\
      pa1 = pa + bytes_in_word * n2w (heap_length h1)`,
  reverse (Cases_on `x`) \\ full_simp_tac(srw_ss())[copying_gcTheory.gc_move_def] THEN1
   (srw_tac[][] \\ full_simp_tac(srw_ss())[word_heap_def,SEP_CLAUSES]
    \\ Cases_on `a'` \\ full_simp_tac(srw_ss())[word_addr_def,word_gc_move_def]
    \\ qexists_tac `xs` \\ full_simp_tac(srw_ss())[heap_length_def])
  \\ CASE_TAC \\ full_simp_tac(srw_ss())[]
  \\ rename1 `heap_lookup k heap = SOME x`
  \\ Cases_on `x` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[word_addr_def]
  \\ pop_assum mp_tac \\ full_simp_tac(srw_ss())[word_gc_move_def,get_addr_and_1_not_0]
  \\ imp_res_tac heap_lookup_LESS
  \\ drule LE_DIV_LT_IMP \\ full_simp_tac(srw_ss())[] \\ strip_tac
  \\ full_simp_tac(srw_ss())[ptr_to_addr_get_addr,word_heap_def,SEP_CLAUSES]
  \\ imp_res_tac heap_lookup_SPLIT \\ full_simp_tac(srw_ss())[] \\ rpt var_eq_tac
  \\ full_simp_tac(srw_ss())[word_heap_APPEND,word_heap_def,word_el_def]
  \\ `small_shift_length conf <= shift_length conf /\
      small_shift_length conf <> 0` by (EVAL_TAC \\ fs [] \\ NO_TAC)
  THEN1
   (helperLib.SEP_R_TAC
    \\ full_simp_tac(srw_ss())[LET_THM,theWord_def,is_fws_ptr_OR_3]
    \\ srw_tac[][] \\ qexists_tac `xs` \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[update_addr_def,shift_to_zero]
    \\ `2 <= shift_length conf` by (fs[shift_length_def] \\ decide_tac)
    \\ full_simp_tac(srw_ss())[shift_around_under_big_shift]
    \\ full_simp_tac(srw_ss())[get_addr_def,select_shift_out]
    \\ full_simp_tac(srw_ss())[select_get_lowerbits,heap_length_def])
  \\ rename1 `_ = SOME (DataElement addrs ll tt)`
  \\ PairCases_on `tt`
  \\ full_simp_tac(srw_ss())[word_el_def]
  \\ `?h ts c5. word_payload addrs ll tt0 tt1 conf =
         (h:'a word,ts,c5)` by METIS_TAC [PAIR]
  \\ full_simp_tac(srw_ss())[LET_THM] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac bool_ss [word_list_def]
  \\ SEP_R_TAC
  \\ full_simp_tac bool_ss [GSYM word_list_def]
  \\ full_simp_tac std_ss [GSYM WORD_OR_ASSOC,is_fws_ptr_OR_3,isWord_def,theWord_def]
  \\ full_simp_tac (std_ss++sep_cond_ss) [cond_STAR,SEP_CLAUSES]
  \\ `~is_fwd_ptr (Word h)` by (imp_res_tac NOT_is_fwd_ptr \\ fs [])
  \\ fs []
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ `n2w (LENGTH ts) + 1w = n2w (LENGTH (Word h::ts)):'a word` by
        full_simp_tac(srw_ss())[LENGTH,ADD1,word_add_n2w]
  \\ full_simp_tac bool_ss []
  \\ drule memcpy_thm
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
  \\ full_simp_tac(srw_ss())[gc_forward_ptr_thm] \\ rev_full_simp_tac(srw_ss())[]
  \\ rpt var_eq_tac
  \\ full_simp_tac(srw_ss())[heap_length_def,el_length_def]
  \\ full_simp_tac(srw_ss())[GSYM heap_length_def]
  \\ imp_res_tac word_payload_IMP
  \\ rpt var_eq_tac
  \\ drule LESS_EQ_IMP_APPEND \\ strip_tac
  \\ full_simp_tac(srw_ss())[] \\ rpt var_eq_tac
  \\ full_simp_tac(srw_ss())[word_list_APPEND]
  \\ disch_then (qspec_then `ys` assume_tac)
  \\ SEP_F_TAC
  \\ impl_tac THEN1
   (full_simp_tac(srw_ss())[ADD1,SUM_APPEND,X_LE_DIV,RIGHT_ADD_DISTRIB]
    \\ Cases_on `2 ** shift_length conf` \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `n` \\ full_simp_tac(srw_ss())[MULT_CLAUSES]
    \\ Cases_on `n'` \\ full_simp_tac(srw_ss())[MULT_CLAUSES] \\ decide_tac)
  \\ rpt strip_tac
  \\ full_simp_tac(srw_ss())[word_addr_def,word_add_n2w,ADD_ASSOC] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[word_heap_APPEND,word_heap_def,
       SEP_CLAUSES,word_el_def,LET_THM]
  \\ full_simp_tac(srw_ss())[word_list_def]
  \\ SEP_W_TAC \\ qexists_tac `zs` \\ full_simp_tac(srw_ss())[]
  \\ reverse conj_tac THEN1
   (full_simp_tac(srw_ss())[update_addr_def,get_addr_def,
       select_shift_out,select_get_lowerbits,ADD1])
  \\ pop_assum mp_tac
  \\ full_simp_tac(srw_ss())[AC STAR_ASSOC STAR_COMM]
  \\ full_simp_tac(srw_ss())[heap_length_def,SUM_APPEND,el_length_def,ADD1]
  \\ full_simp_tac(srw_ss())[word_list_exists_def,SEP_CLAUSES,SEP_EXISTS_THM]
  \\ srw_tac[][] \\ qexists_tac `ts`
  \\ full_simp_tac(srw_ss())[AC STAR_ASSOC STAR_COMM,SEP_CLAUSES]);

val word_gc_move_roots_thm = Q.prove(
  `!x a n heap limit pa x1 h1 a1 n1 heap1 pa1 m m1 xs i1 c1 w frame.
      (gc_move_list (x,[],a,n,heap,T,limit) = (x1,h1,a1,n1,heap1,T)) /\
      heap_length heap <= dimword (:'a) DIV 2 ** shift_length conf /\
      (word_heap curr heap conf * word_list pa xs * frame) (fun2set (m,dm)) /\
      (word_gc_move_roots conf (MAP (word_addr conf) x,n2w a,pa,curr,m,dm) =
        (w:'a word_loc list,i1,pa1,m1,c1)) /\
      LENGTH xs = n ==>
      ?xs1.
        (word_heap curr heap1 conf *
         word_heap pa h1 conf *
         word_list pa1 xs1 * frame) (fun2set (m1,dm)) /\
        (w = MAP (word_addr conf) x1) /\
        heap_length heap1 = heap_length heap /\
        c1 /\ (i1 = n2w a1) /\ n1 = LENGTH xs1 /\
        pa1 = pa + n2w (heap_length h1) * bytes_in_word`,
  Induct THEN1
   (full_simp_tac(srw_ss())[copying_gcTheory.gc_move_list_def,word_gc_move_roots_def,word_heap_def,SEP_CLAUSES]
    \\ srw_tac[][] \\ qexists_tac `xs` \\ full_simp_tac(srw_ss())[heap_length_def])
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[copying_gcTheory.gc_move_list_def,LET_THM]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ pop_assum mp_tac
  \\ once_rewrite_tac [gc_move_list_ALT]
  \\ full_simp_tac(srw_ss())[LET_THM]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[word_gc_move_roots_def,LET_THM]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ `c'` by imp_res_tac copying_gcTheory.gc_move_list_ok \\ full_simp_tac(srw_ss())[]
  \\ drule (word_gc_move_thm |> GEN_ALL |> SIMP_RULE std_ss [])
  \\ once_rewrite_tac [CONJ_ASSOC]
  \\ once_rewrite_tac [CONJ_COMM]
  \\ disch_then drule \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ SEP_F_TAC \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ first_x_assum drule
  \\ once_rewrite_tac [CONJ_ASSOC]
  \\ once_rewrite_tac [CONJ_COMM]
  \\ disch_then drule \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ SEP_F_TAC \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ rename1 `_ = (xs7,xs8,a7,LENGTH xs9,heap7,T)`
  \\ qexists_tac `xs9` \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[word_heap_APPEND]
  \\ full_simp_tac(srw_ss())[AC STAR_COMM STAR_ASSOC]
  \\ full_simp_tac(srw_ss())[WORD_LEFT_ADD_DISTRIB,heap_length_def,SUM_APPEND,GSYM word_add_n2w]);

val word_gc_move_list_thm = Q.prove(
  `!x a n heap limit pa x1 h1 a1 n1 heap1 pa1 m m1 xs i1 c1 frame k k1.
      (copying_gc$gc_move_list (x,[],a,n,heap,T,limit) = (x1,h1,a1,n1,heap1,T)) /\
      heap_length heap <= dimword (:'a) DIV 2 ** shift_length conf /\
      (word_gc_move_list conf (k,n2w (LENGTH x),n2w a,pa,curr,m,dm) =
        (k1,i1,pa1,m1,c1)) /\
      (word_heap curr heap conf * word_list pa xs *
       word_list k (MAP (word_addr conf) x) * frame) (fun2set (m,dm)) /\
      LENGTH xs = n /\ LENGTH x < dimword (:'a) ==>
      ?xs1.
        (word_heap curr heap1 conf *
         word_heap (pa:'a word) h1 conf *
         word_list pa1 xs1 *
         word_list k (MAP (word_addr conf) x1) * frame) (fun2set (m1,dm)) /\
        heap_length heap1 = heap_length heap /\
        c1 /\ (i1 = n2w a1) /\ n1 = LENGTH xs1 /\
        k1 = k + n2w (LENGTH x) * bytes_in_word /\
        pa1 = pa + n2w (heap_length h1) * bytes_in_word`,
  Induct THEN1
   (full_simp_tac(srw_ss())[copying_gcTheory.gc_move_list_def,Once word_gc_move_list_def,word_heap_def,SEP_CLAUSES]
    \\ srw_tac[][] \\ qexists_tac `xs` \\ full_simp_tac(srw_ss())[heap_length_def])
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[copying_gcTheory.gc_move_list_def,LET_THM]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ pop_assum mp_tac
  \\ once_rewrite_tac [gc_move_list_ALT]
  \\ full_simp_tac(srw_ss())[LET_THM] \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ qpat_x_assum `word_gc_move_list conf _ = _` mp_tac
  \\ simp [Once word_gc_move_list_def,LET_THM] \\ full_simp_tac(srw_ss())[]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[GSYM word_add_n2w,ADD1]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ `c'` by imp_res_tac copying_gcTheory.gc_move_list_ok \\ full_simp_tac(srw_ss())[]
  \\ pop_assum kall_tac
  \\ NTAC 2 (pop_assum mp_tac)
  \\ full_simp_tac(srw_ss())[word_list_def] \\ SEP_R_TAC \\ rpt strip_tac
  \\ drule (word_gc_move_thm |> GEN_ALL |> SIMP_RULE std_ss [])
  \\ once_rewrite_tac [CONJ_ASSOC]
  \\ once_rewrite_tac [CONJ_COMM]
  \\ disch_then drule \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ SEP_F_TAC \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ first_x_assum drule
  \\ qpat_x_assum `word_gc_move_list conf _ = _` mp_tac
  \\ SEP_W_TAC \\ strip_tac
  \\ once_rewrite_tac [CONJ_ASSOC]
  \\ once_rewrite_tac [CONJ_COMM] \\ full_simp_tac(srw_ss())[]
  \\ disch_then imp_res_tac
  \\ `LENGTH x < dimword (:'a)` by decide_tac \\ full_simp_tac(srw_ss())[]
  \\ pop_assum kall_tac
  \\ SEP_F_TAC \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ rename1 `_ = (xs7,xs8,a7,LENGTH xs9,heap7,T)`
  \\ qexists_tac `xs9` \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[word_heap_APPEND]
  \\ full_simp_tac(srw_ss())[AC STAR_COMM STAR_ASSOC]
  \\ full_simp_tac(srw_ss())[WORD_LEFT_ADD_DISTRIB,heap_length_def,
        SUM_APPEND,GSYM word_add_n2w]);

val word_payload_swap = Q.prove(
  `word_payload l5 (LENGTH l5) tag r conf = (h,MAP (word_addr conf) l5,T) /\
    LENGTH xs' = LENGTH l5 ==>
    word_payload xs' (LENGTH l5) tag r conf = (h,MAP (word_addr conf) xs',T)`,
  Cases_on `tag` \\ full_simp_tac(srw_ss())[word_payload_def]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[LENGTH_NIL]);

val word_gc_move_loop_thm = Q.prove(
  `!h1 h2 a n heap c0 limit h11 a1 n1 heap1 i1 pa1 m1 c1 xs frame m k.
      (gc_move_loop (h1,h2,a,n,heap,c0,limit) = (h11,a1,n1,heap1,T)) /\ c0 /\
      heap_length heap <= dimword (:'a) DIV 2 ** shift_length conf /\
      heap_length heap * (dimindex (:'a) DIV 8) < dimword (:'a) /\
      conf.len_size + 2 < dimindex (:'a) /\
      (word_heap curr heap conf *
       word_heap new (h1 ++ h2) conf *
       word_list (new + n2w (heap_length (h1++h2)) * bytes_in_word) xs * frame)
         (fun2set (m,dm)) /\
      limit - heap_length h1 <= k /\
      limit = heap_length heap /\ good_dimindex (:'a) /\
      (word_gc_move_loop k conf (new + n2w (heap_length h1) * bytes_in_word,n2w a,
           new + n2w (heap_length (h1++h2)) * bytes_in_word,curr,m,dm,T) =
         (i1,pa1,m1,c1)) /\ LENGTH xs = n ==>
      ?xs1.
        (word_heap curr heap1 conf *
         word_heap (new:'a word) h11 conf *
         word_list pa1 xs1 * frame) (fun2set (m1,dm)) /\
        heap_length heap1 = heap_length heap /\
        c1 /\ (i1 = n2w a1) /\ n1 = LENGTH xs1 /\
        pa1 = new + bytes_in_word * n2w (heap_length h11)`,
  recInduct gc_move_loop_ind \\ rpt strip_tac
  THEN1
   (full_simp_tac(srw_ss())[gc_move_loop_def] \\ rpt var_eq_tac
    \\ full_simp_tac(srw_ss())[]
    \\ pop_assum mp_tac \\ once_rewrite_tac [word_gc_move_loop_def]
    \\ full_simp_tac(srw_ss())[]
    \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
    \\ qexists_tac `xs` \\ full_simp_tac(srw_ss())[AC STAR_COMM STAR_ASSOC])
  \\ qpat_x_assum `gc_move_loop _ = _` mp_tac
  \\ once_rewrite_tac [gc_move_loop_def]
  \\ IF_CASES_TAC \\ full_simp_tac(srw_ss())[]
  \\ CASE_TAC \\ full_simp_tac(srw_ss())[LET_THM]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac gc_move_loop_ok \\ full_simp_tac(srw_ss())[]
  \\ rename1 `HD h5 = DataElement l5 n5 b5`
  \\ Cases_on `h5` \\ full_simp_tac(srw_ss())[]
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ qpat_x_assum `word_gc_move_loop _ _ _ = _` mp_tac
  \\ once_rewrite_tac [word_gc_move_loop_def]
  \\ IF_CASES_TAC THEN1
   (`F` by all_tac
    \\ full_simp_tac(srw_ss())[heap_length_def,SUM_APPEND,el_length_def,
           WORD_LEFT_ADD_DISTRIB,GSYM word_add_n2w]
    \\ pop_assum mp_tac
    \\ Q.PAT_ABBREV_TAC `x = bytes_in_word * n2w (SUM (MAP el_length h1))`
    \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac std_ss [GSYM WORD_ADD_ASSOC,addressTheory.WORD_EQ_ADD_CANCEL]
    \\ full_simp_tac(srw_ss())[bytes_in_word_def,word_add_n2w,word_mul_n2w]
    \\ full_simp_tac(srw_ss())[NOT_LESS]
    \\ full_simp_tac(srw_ss())[GSYM heap_length_def]
    \\ qpat_x_assum `_ <= heap_length heap` mp_tac
    \\ qpat_x_assum `heap_length heap * _ < _ ` mp_tac
    \\ qpat_x_assum `good_dimindex (:'a)` mp_tac
    \\ rpt (pop_assum kall_tac) \\ srw_tac[][]
    \\ `dimindex (:α) DIV 8 + dimindex (:α) DIV 8 * n5 +
        dimindex (:α) DIV 8 * heap_length h2 < dimword (:α)` by all_tac
    \\ full_simp_tac(srw_ss())[]
    \\ rev_full_simp_tac(srw_ss())[good_dimindex_def,dimword_def]
    \\ rev_full_simp_tac(srw_ss())[good_dimindex_def,dimword_def] \\ decide_tac)
  \\ Cases_on `b5`
  \\ full_simp_tac(srw_ss())[word_heap_APPEND,word_heap_def,
       SEP_CLAUSES,STAR_ASSOC,word_el_def]
  \\ qpat_x_assum `_ (fun2set (m,dm))` assume_tac
  \\ full_simp_tac(srw_ss())[LET_THM]
  \\ pop_assum mp_tac
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ strip_tac
  \\ full_simp_tac (std_ss++sep_cond_ss) [cond_STAR] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac std_ss [word_list_def] \\ SEP_R_TAC
  \\ full_simp_tac(srw_ss())[isWord_def,theWord_def]
  \\ rev_full_simp_tac(srw_ss())[]
  \\ rename1 `word_payload _ _ tag _ conf = _`
  \\ drule word_payload_T_IMP
  \\ impl_tac THEN1 (fs []) \\ strip_tac
  \\ `k <> 0` by
   (fs [heap_length_APPEND,el_length_def,heap_length_def] \\ decide_tac)
  \\ full_simp_tac std_ss []
  \\ Cases_on `word_bit 2 h` \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[]
  THEN1
   (full_simp_tac(srw_ss())[copying_gcTheory.gc_move_list_def] \\ rpt var_eq_tac
    \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[heap_length_def,el_length_def,SUM_APPEND]
    \\ qpat_x_assum `!xx. nn` mp_tac
    \\ full_simp_tac(srw_ss())[GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
    \\ ntac 2 strip_tac \\ full_simp_tac(srw_ss())[SEP_CLAUSES]
    \\ first_x_assum match_mp_tac
    \\ qexists_tac `xs` \\ qexists_tac `m` \\ full_simp_tac(srw_ss())[]
    \\ qexists_tac `k - 1` \\ fs [])
  \\ qpat_x_assum `gc_move_list _ = _` mp_tac
  \\ once_rewrite_tac [gc_move_list_ALT] \\ strip_tac
  \\ full_simp_tac(srw_ss())[LET_THM]
  \\ pop_assum mp_tac
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ strip_tac
  \\ ntac 5 var_eq_tac
  \\ drule word_gc_move_list_thm \\ full_simp_tac(srw_ss())[]
  \\ ntac 2 strip_tac \\ full_simp_tac(srw_ss())[]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ first_x_assum drule
  \\ disch_then (qspec_then `xs` mp_tac)
  \\ fs [] \\ strip_tac \\ SEP_F_TAC
  \\ impl_tac THEN1
   (full_simp_tac(srw_ss())[NOT_LESS] \\ qpat_x_assum `_ <= heap_length heap` mp_tac
    \\ qpat_x_assum `heap_length heap <= _ ` mp_tac
    \\ qpat_x_assum `heap_length heap <= _ ` mp_tac
    \\ rpt (pop_assum kall_tac) \\ full_simp_tac(srw_ss())[X_LE_DIV]
    \\ full_simp_tac(srw_ss())[heap_length_APPEND,heap_length_def,el_length_def]
    \\ Cases_on `2 ** shift_length conf` \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `n` \\ full_simp_tac(srw_ss())[MULT_CLAUSES] \\ decide_tac)
  \\ strip_tac \\ fs []
  \\ ntac 5 var_eq_tac
  \\ `LENGTH xs' = LENGTH l5` by imp_res_tac gc_move_list_IMP_LENGTH
  \\ `word_payload xs' (LENGTH l5) tag r conf =
       (h,MAP (word_addr conf) xs',T)` by
         (match_mp_tac word_payload_swap \\ full_simp_tac(srw_ss())[])
  \\ full_simp_tac(srw_ss())[] \\ rev_full_simp_tac(srw_ss())[]
  \\ first_x_assum match_mp_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[heap_length_def,el_length_def,SUM_APPEND]
  \\ full_simp_tac(srw_ss())[GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB,SEP_CLAUSES]
  \\ qpat_x_assum `_ = (i1,pa1,m1,c1)` (fn th => full_simp_tac(srw_ss())[GSYM th])
  \\ qexists_tac `xs1'` \\ full_simp_tac(srw_ss())[]
  \\ qexists_tac `m1'` \\ full_simp_tac(srw_ss())[]
  \\ qexists_tac `k-1` \\ fs []
  \\ qpat_x_assum `_ (fun2set (m1',dm))` mp_tac
  \\ full_simp_tac(srw_ss())[word_heap_APPEND,heap_length_def,el_length_def,SUM_APPEND]
  \\ full_simp_tac(srw_ss())[GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB,SEP_CLAUSES]
  \\ full_simp_tac(srw_ss())[AC STAR_ASSOC STAR_COMM,word_heap_APPEND]);

val word_full_gc_thm = Q.prove(
  `(full_gc (roots,heap,limit) = (roots1,heap1,a1,T)) /\
    heap_length heap <= dimword (:'a) DIV 2 ** shift_length conf /\
    heap_length heap * (dimindex (:'a) DIV 8) < dimword (:'a) /\
    conf.len_size + 2 < dimindex (:'a) /\
    (word_heap (curr:'a word) heap conf *
     word_heap new (heap_expand limit) conf * frame) (fun2set (m,dm)) /\
    limit = heap_length heap /\ good_dimindex (:'a) /\
    (word_full_gc conf (MAP (word_addr conf) roots,new,curr,m,dm) =
       (rs1,i1,pa1,m1,c1)) ==>
    (word_heap new (heap1 ++ heap_expand (limit - a1)) conf *
     word_heap curr (heap_expand limit) conf * frame) (fun2set (m1,dm)) /\
    c1 /\ i1 = n2w a1 /\
    rs1 = MAP (word_addr conf) roots1 /\
    pa1 = new + bytes_in_word * n2w a1`,
  strip_tac \\ full_simp_tac(srw_ss())[full_gc_def,LET_THM]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[word_heap_def,word_el_def]
  \\ full_simp_tac(srw_ss())[SEP_CLAUSES]
  \\ imp_res_tac gc_move_loop_ok \\ full_simp_tac(srw_ss())[]
  \\ drule word_gc_move_roots_thm
  \\ full_simp_tac(srw_ss())[word_list_exists_def,SEP_CLAUSES,
       SEP_EXISTS_THM,word_heap_heap_expand]
  \\ full_simp_tac (std_ss++sep_cond_ss) [cond_STAR]
  \\ full_simp_tac(srw_ss())[word_full_gc_def,LET_THM]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ disch_then drule \\ full_simp_tac(srw_ss())[] \\ strip_tac
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ drule word_gc_move_loop_thm
  \\ full_simp_tac(srw_ss())[heap_length_def]
  \\ once_rewrite_tac [CONJ_COMM] \\ full_simp_tac(srw_ss())[GSYM CONJ_ASSOC]
  \\ `SUM (MAP el_length heap) <= dimword (:'a)` by
   (fs [X_LE_DIV] \\ Cases_on `2n ** shift_length conf` \\ fs [MULT_CLAUSES])
  \\ disch_then drule
  \\ disch_then drule
  \\ strip_tac \\ SEP_F_TAC
  \\ full_simp_tac(srw_ss())[AC STAR_ASSOC STAR_COMM]
  \\ strip_tac \\ rpt var_eq_tac
  \\ full_simp_tac(srw_ss())[word_heap_APPEND,word_heap_heap_expand]
  \\ pop_assum mp_tac
  \\ full_simp_tac(srw_ss())[STAR_ASSOC]
  \\ CONV_TAC ((RATOR_CONV o RAND_CONV) (RATOR_CONV
       (MOVE_OUT_CONV ``word_heap (curr:'a word) (temp:'a ml_heap)``)))
  \\ strip_tac \\ drule word_heap_IMP_word_list_exists
  \\ full_simp_tac(srw_ss())[word_heap_heap_expand]
  \\ full_simp_tac(srw_ss())[word_list_exists_def,SEP_CLAUSES,SEP_EXISTS_THM]
  \\ full_simp_tac (std_ss++sep_cond_ss) [cond_STAR] \\ strip_tac
  \\ rename1 `LENGTH ys = heap_length temp`
  \\ qexists_tac `ys` \\ full_simp_tac(srw_ss())[heap_length_def]
  \\ qexists_tac `xs1'` \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[AC STAR_ASSOC STAR_COMM]);

val LIST_REL_EQ_MAP = Q.store_thm("LIST_REL_EQ_MAP",
  `!vs ws f. LIST_REL (λv w. f v = w) vs ws <=> ws = MAP f vs`,
  Induct \\ full_simp_tac(srw_ss())[]);

val full_gc_IMP = Q.prove(
  `full_gc (xs,heap,limit) = (t,heap2,n,T) ==>
    n <= limit /\ limit = heap_length heap`,
  full_simp_tac(srw_ss())[full_gc_def,LET_THM]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]);

val word_gc_fun_lemma = Q.prove(
  `good_dimindex (:'a) /\
    heap_in_memory_store heap a sp sp1 gens c s m dm limit /\
    abs_ml_inv c (v::MAP FST stack) refs (hs,heap,be,a,sp,sp1,gens) limit /\
    LIST_REL (\v w. word_addr c v = w) hs (s ' Globals::MAP SND stack) /\
    full_gc (hs,heap,limit) = (roots2,heap2,heap_length heap2,T) ==>
    let heap1 = heap2 ++ heap_expand (limit - heap_length heap2) in
      ?stack1 m1 s1 a1 sp1.
        word_gc_fun c (MAP SND stack,m,dm,s) = SOME (stack1,m1,s1) /\
        heap_in_memory_store heap1 (heap_length heap2)
          (limit - heap_length heap2) 0 gens c s1 m1 dm limit /\
        LIST_REL (λv w. word_addr c v = (w:'a word_loc)) roots2
          (s1 ' Globals::MAP SND (ZIP (MAP FST stack,stack1))) /\
        LENGTH stack1 = LENGTH stack`,
  strip_tac
  \\ rewrite_tac [word_gc_fun_def] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[heap_in_memory_store_def,FLOOKUP_DEF,theWord_def,LET_THM]
  \\ pairarg_tac
  \\ full_simp_tac(srw_ss())[finite_mapTheory.FDOM_FUPDATE_LIST,FUPDATE_LIST,FAPPLY_FUPDATE_THM]
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ `s ' Globals::MAP SND stack = MAP (word_addr c) (v'::xs)` by
    (full_simp_tac(srw_ss())[LIST_REL_EQ_MAP] \\ CONV_TAC (DEPTH_CONV ETA_CONV) \\ full_simp_tac(srw_ss())[])
  \\ full_simp_tac std_ss [] \\ drule (GEN_ALL word_full_gc_thm)
  \\ rewrite_tac [CONJ_ASSOC]
  \\ once_rewrite_tac [CONJ_COMM]
  \\ disch_then drule
  \\ disch_then (qspec_then `emp` mp_tac)
  \\ full_simp_tac(srw_ss())[SEP_CLAUSES]
  \\ impl_tac
  THEN1 (imp_res_tac full_gc_IMP \\ fs [])
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac full_gc_IMP_LENGTH
  \\ Cases_on `roots2` \\ full_simp_tac(srw_ss())[]
  \\ `LENGTH xs = LENGTH stack` by metis_tac [LENGTH_MAP]
  \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[listTheory.MAP_ZIP]
  \\ full_simp_tac(srw_ss())[LIST_REL_EQ_MAP]
  \\ CONV_TAC (DEPTH_CONV ETA_CONV) \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac full_gc_IMP \\ full_simp_tac(srw_ss())[]
  \\ rev_full_simp_tac(srw_ss())[heap_length_APPEND,heap_length_heap_expand]
  \\ `heap_length heap2 + (heap_length heap - heap_length heap2) =
      heap_length heap` by decide_tac \\ full_simp_tac(srw_ss())[]
  \\ fs [word_gc_fun_assum_def,isWord_def]) |> GEN_ALL
  |> SIMP_RULE (srw_ss()) [LET_DEF,PULL_EXISTS,GSYM CONJ_ASSOC] |> SPEC_ALL;

val word_gc_fun_correct = Q.prove(
  `good_dimindex (:'a) /\
    heap_in_memory_store heap a sp sp1 gens c s m dm limit /\
    word_ml_inv (heap:'a ml_heap,be,a,sp,sp1,gens) limit c refs ((v,s ' Globals)::stack) ==>
    ?stack1 m1 s1 heap1 a1 sp1.
      word_gc_fun c (MAP SND stack,m,dm,s) = SOME (stack1,m1,s1) /\
      heap_in_memory_store heap1 a1 sp1 0 gens c s1 m1 dm limit /\
      word_ml_inv (heap1,be,a1,sp1,0,gens) limit c refs
        ((v,s1 ' Globals)::ZIP (MAP FST stack,stack1))`,
  full_simp_tac(srw_ss())[word_ml_inv_def] \\ srw_tac[][] \\ imp_res_tac full_gc_thm
  \\ full_simp_tac(srw_ss())[PULL_EXISTS] \\ srw_tac[][]
  \\ drule (GEN_ALL word_gc_fun_lemma |> ONCE_REWRITE_RULE [CONJ_COMM]
             |> REWRITE_RULE [GSYM CONJ_ASSOC])
  \\ rpt (disch_then drule) \\ strip_tac \\ fs []
  \\ once_rewrite_tac [CONJ_COMM] \\ fs [GSYM CONJ_ASSOC]
  \\ full_simp_tac(srw_ss())[MAP_ZIP]
  \\ asm_exists_tac \\ fs []);

val is_ref_header_def = Define `
  is_ref_header (v:'a word) <=> ((v && 0b11100w) = 0b01000w)`;

val word_gen_gc_move_def = Define `
  (word_gen_gc_move conf (Loc l1 l2,i,pa,ib,pb,old,m,dm) =
     (Loc l1 l2,i,pa,ib,pb,m,T)) /\
  (word_gen_gc_move conf (Word w,i,pa,ib,pb,old,m,dm) =
     if (1w && w) = 0w then (Word w,i,pa,ib,pb,m,T) else
       let c = (ptr_to_addr conf old w IN dm) in
       let v = m (ptr_to_addr conf old w) in
       let c = (c /\ isWord v) in
         if is_fwd_ptr v then
           (Word (update_addr conf (theWord v >>> 2) w),i,pa,ib,pb,m,c)
         else
           let header_addr = ptr_to_addr conf old w in
           let c = (c /\ header_addr IN dm /\ isWord (m header_addr)) in
           let len = decode_length conf (theWord (m header_addr)) in
             if is_ref_header (theWord v) then
               let v = ib - (len + 1w) in
               let pb1 = pb - (len + 1w) * bytes_in_word in
               let (_,m1,c1) = memcpy (len+1w) header_addr pb1 m dm in
               let c = (c /\ header_addr IN dm /\ c1) in
               let m1 = (header_addr =+ Word (v << 2)) m1 in
                 (Word (update_addr conf v w),i,pa,v,pb1,m1,c)
             else
              let v = i + len + 1w in
              let (pa1,m1,c1) = memcpy (len+1w) header_addr pa m dm in
              let c = (c /\ header_addr IN dm /\ c1) in
              let m1 = (header_addr =+ Word (i << 2)) m1 in
                (Word (update_addr conf i w),v,pa1,ib,pb,m1,c))`

val word_gen_gc_move_roots_def = Define `
  (word_gen_gc_move_roots conf ([],i,pa,ib,pb,old,m,dm) = ([],i,pa,ib,pb,m,T)) /\
  (word_gen_gc_move_roots conf (w::ws,i,pa,ib,pb,old,m,dm) =
     let (w1,i1,pa1,ib,pb,m1,c1) = word_gen_gc_move conf (w,i,pa,ib,pb,old,m,dm) in
     let (ws2,i2,pa2,ib,pb,m2,c2) = word_gen_gc_move_roots conf (ws,i1,pa1,ib,pb,old,m1,dm) in
       (w1::ws2,i2,pa2,ib,pb,m2,c1 /\ c2))`

val word_gen_gc_move_list_def = Define `
  word_gen_gc_move_list conf (a:'a word,l:'a word,i,pa:'a word,ib,pb,old,m,dm) =
   if l = 0w then (a,i,pa,ib,pb,m,T) else
     let w = (m a):'a word_loc in
     let (w1,i1,pa1,ib,pb,m1,c1) = word_gen_gc_move conf (w,i,pa,ib,pb,old,m,dm) in
     let m1 = (a =+ w1) m1 in
     let (a2,i2,pa2,ib,pb,m2,c2) = word_gen_gc_move_list conf (a+bytes_in_word,l-1w,i1,pa1,ib,pb,old,m1,dm) in
       (a2,i2,pa2,ib,pb,m2,a IN dm /\ c1 /\ c2)`

val is_ref_header_alt = prove(
  ``good_dimindex (:'a) ==>
    (is_ref_header (w:'a word) <=> ~(w ' 2) /\ (w ' 3) /\ ~(w ' 4))``,
  fs [is_ref_header_def,fcpTheory.CART_EQ,good_dimindex_def] \\ rw []
  \\ fs [word_and_def,word_index,fcpTheory.FCP_BETA]
  \\ rw [] \\ eq_tac \\ rw [] \\ fs []
  \\ TRY (qpat_x_assum `!x._`
       (fn th => qspec_then `2` mp_tac th
                 \\ qspec_then `3` mp_tac th
                 \\ qspec_then `4` mp_tac th ))
  \\ fs [] \\ Cases_on `i = 2`
  \\ fs [] \\ Cases_on `i = 3`
  \\ fs [] \\ Cases_on `i = 4` \\ fs []);

val is_ref_header_thm = prove(
  ``(word_payload addrs ll tt0 tt1 conf = (h,ts,c5)) /\ good_dimindex (:'a) /\
    conf.len_size + 5 <= dimindex (:'a) ==>
    (is_ref_header (h:'a word) ⇔ tt0 = RefTag)``,
  Cases_on `tt0` \\ fs [word_payload_def] \\ rw []
  \\ fs [make_header_def,make_byte_header_def,is_ref_header_alt]
  \\ fs [word_or_def,fcpTheory.FCP_BETA,good_dimindex_def,word_lsl_def,word_index]
  \\ rw []
  \\ fs [word_or_def,fcpTheory.FCP_BETA,good_dimindex_def,word_lsl_def,word_index]);

val is_Ref_def = Define `
  is_Ref is_ref_tag (DataElement xs l r) = is_ref_tag r /\
  is_Ref is_ref_tag _ = F`

val len_inv_def = Define `
  len_inv s <=>
    heap_length s.heap =
    heap_length (s.h1 ++ s.h2) + s.n + heap_length (s.r4 ++ s.r3 ++ s.r2 ++ s.r1)`;

val word_gen_gc_move_thm = Q.prove(
  `(gen_gc$gc_move gen_conf s x = (x1,s1)) /\ s1.ok /\ s.h2 = [] /\ s.r4 = [] /\
    heap_length s.heap <= dimword (:'a) DIV 2 ** shift_length conf /\
    (!t r. (gen_conf.isRef (t,r) <=> t = RefTag)) /\
    conf.len_size + 5 <= dimindex (:'a) /\
    (word_heap curr s.heap conf *
     word_list pa xs * frame) (fun2set (m,dm)) /\
    (word_gen_gc_move conf (word_addr conf x,n2w s.a,pa,
        n2w (s.a+s.n),pa + bytes_in_word * n2w s.n,curr,m,dm) =
      (w:'a word_loc,i1,pa1,ib1,pb1,m1,c1)) /\
    LENGTH xs = s.n /\ good_dimindex (:'a) /\
    EVERY (is_Ref gen_conf.isRef) (s.r4 ++ s.r3 ++ s.r2 ++ s.r1) ==>
    ?xs1.
      (word_heap curr s1.heap conf *
       word_heap pa s1.h2 conf *
       word_heap pb1 s1.r4 conf *
       word_list pa1 xs1 *
       frame) (fun2set (m1,dm)) /\
      (w = word_addr conf x1) /\
      heap_length s1.heap = heap_length s.heap /\ c1 /\
      (i1 = n2w s1.a) /\
      (ib1 = n2w (s1.a + s1.n)) /\
      s1.n = LENGTH xs1 /\
      s.n = heap_length s1.h2 + s1.n + heap_length s1.r4 /\
      pa1 = pa + bytes_in_word * n2w (heap_length s1.h2) /\
      pb1 = pa1 + bytes_in_word * n2w s1.n /\
      EVERY (is_Ref gen_conf.isRef) (s1.r4 ++ s1.r3 ++ s1.r2 ++ s1.r1)`,
  reverse (Cases_on `x`) \\ fs[gen_gcTheory.gc_move_def] THEN1
   (rw [] \\ full_simp_tac(srw_ss())[word_heap_def,SEP_CLAUSES]
    \\ Cases_on `a` \\ fs [word_addr_def,word_gen_gc_move_def]
    \\ rveq \\ fs [] \\ asm_exists_tac \\ fs [heap_length_def])
  \\ CASE_TAC \\ fs []
  \\ strip_tac \\ rveq \\ fs []
  \\ rename1 `heap_lookup k s.heap = SOME x`
  \\ Cases_on `x` \\ fs[] \\ srw_tac[][] \\ fs[word_addr_def]
  \\ qpat_x_assum `word_gen_gc_move conf _ = _` mp_tac
  \\ full_simp_tac std_ss [word_gen_gc_move_def,get_addr_and_1_not_0]
  \\ imp_res_tac heap_lookup_LESS
  \\ drule LE_DIV_LT_IMP
  \\ impl_tac \\ asm_rewrite_tac [] \\ strip_tac
  \\ asm_simp_tac std_ss [ptr_to_addr_get_addr]
  \\ imp_res_tac heap_lookup_SPLIT
  \\ full_simp_tac std_ss [word_heap_def,SEP_CLAUSES] \\ rveq
  \\ full_simp_tac std_ss [word_heap_APPEND,word_heap_def,word_el_def,
       AC WORD_MULT_ASSOC WORD_MULT_COMM]
  \\ `small_shift_length conf <= shift_length conf /\
      small_shift_length conf <> 0` by (EVAL_TAC \\ fs [] \\ NO_TAC)
  THEN1
   (helperLib.SEP_R_TAC
    \\ full_simp_tac(srw_ss())[LET_THM,theWord_def,is_fws_ptr_OR_3]
    \\ rw [] \\ qexists_tac `xs` \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[update_addr_def,shift_to_zero]
    \\ `2 <= shift_length conf` by (fs[shift_length_def] \\ decide_tac)
    \\ full_simp_tac(srw_ss())[shift_around_under_big_shift]
    \\ full_simp_tac(srw_ss())[get_addr_def,select_shift_out]
    \\ full_simp_tac(srw_ss())[select_get_lowerbits,heap_length_def,isWord_def])
  \\ rename1 `_ = SOME (DataElement addrs ll tt)`
  \\ PairCases_on `tt`
  \\ full_simp_tac(srw_ss())[word_el_def]
  \\ `?h ts c5. word_payload addrs ll tt0 tt1 conf =
         (h:'a word,ts,c5)` by METIS_TAC [PAIR]
  \\ full_simp_tac(srw_ss())[LET_THM] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac bool_ss [word_list_def]
  \\ SEP_R_TAC
  \\ full_simp_tac bool_ss [GSYM word_list_def,isWord_def]
  \\ full_simp_tac std_ss [GSYM WORD_OR_ASSOC,is_fws_ptr_OR_3,isWord_def,theWord_def]
  \\ full_simp_tac (std_ss++sep_cond_ss) [cond_STAR,SEP_CLAUSES]
  \\ `~is_fwd_ptr (Word h)` by (imp_res_tac NOT_is_fwd_ptr \\ fs [])
  \\ asm_rewrite_tac []
  \\ drule is_ref_header_thm
  \\ asm_simp_tac std_ss []
  \\ disch_then kall_tac
  \\ reverse (Cases_on `tt0 = RefTag`) \\ fs []
  THEN1
   (pairarg_tac \\ full_simp_tac(srw_ss())[]
    \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
    \\ `n2w (LENGTH ts) + 1w = n2w (LENGTH (Word h::ts)):'a word` by
          full_simp_tac(srw_ss())[LENGTH,ADD1,word_add_n2w]
    \\ full_simp_tac bool_ss []
    \\ drule memcpy_thm
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
    \\ full_simp_tac(srw_ss())[gc_forward_ptr_thm] \\ rev_full_simp_tac(srw_ss())[]
    \\ rpt var_eq_tac
    \\ full_simp_tac(srw_ss())[heap_length_def,el_length_def,SUM_APPEND]
    \\ full_simp_tac(srw_ss())[GSYM heap_length_def]
    \\ imp_res_tac word_payload_IMP
    \\ rpt var_eq_tac
    \\ qpat_x_assum `LENGTH xs = s.n` (assume_tac o GSYM)
    \\ fs []
    \\ drule LESS_EQ_IMP_APPEND \\ strip_tac
    \\ full_simp_tac(srw_ss())[] \\ rpt var_eq_tac
    \\ full_simp_tac(srw_ss())[word_list_APPEND]
    \\ disch_then (qspec_then `ys` assume_tac)
    \\ SEP_F_TAC
    \\ impl_tac THEN1
     (full_simp_tac(srw_ss())[ADD1,SUM_APPEND,X_LE_DIV,RIGHT_ADD_DISTRIB]
      \\ Cases_on `2 ** shift_length conf` \\ full_simp_tac(srw_ss())[]
      \\ Cases_on `n` \\ full_simp_tac(srw_ss())[MULT_CLAUSES]
      \\ Cases_on `n'` \\ full_simp_tac(srw_ss())[MULT_CLAUSES] \\ decide_tac)
    \\ rpt strip_tac
    \\ full_simp_tac(srw_ss())[word_addr_def,word_add_n2w,ADD_ASSOC] \\ srw_tac[][]
    \\ full_simp_tac(srw_ss())[word_heap_APPEND,word_heap_def,
         SEP_CLAUSES,word_el_def,LET_THM]
    \\ full_simp_tac(srw_ss())[word_list_def]
    \\ SEP_W_TAC \\ qexists_tac `zs` \\ full_simp_tac(srw_ss())[]
    \\ reverse conj_tac THEN1
     (full_simp_tac(srw_ss())[update_addr_def,get_addr_def,
         select_shift_out,select_get_lowerbits,ADD1]
      \\ fs [GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
      \\ rewrite_tac [GSYM APPEND_ASSOC,APPEND])
    \\ pop_assum mp_tac
    \\ full_simp_tac(srw_ss())[AC STAR_ASSOC STAR_COMM]
    \\ full_simp_tac(srw_ss())[heap_length_def,SUM_APPEND,el_length_def,ADD1]
    \\ full_simp_tac(srw_ss())[word_list_exists_def,SEP_CLAUSES,SEP_EXISTS_THM]
    \\ srw_tac[][] \\ qexists_tac `ts`
    \\ full_simp_tac(srw_ss())[AC STAR_ASSOC STAR_COMM,SEP_CLAUSES]
    \\ fs [GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB])
  THEN1
   (rveq
    \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
    \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
    \\ `n2w (LENGTH ts) + 1w = n2w (LENGTH (Word h::ts)):'a word` by
          full_simp_tac(srw_ss())[LENGTH,ADD1,word_add_n2w]
    \\ full_simp_tac bool_ss []
    \\ drule memcpy_thm
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
    \\ full_simp_tac(srw_ss())[gc_forward_ptr_thm] \\ rev_full_simp_tac(srw_ss())[]
    \\ rpt var_eq_tac
    \\ full_simp_tac(srw_ss())[heap_length_def,el_length_def,SUM_APPEND]
    \\ full_simp_tac(srw_ss())[GSYM heap_length_def]
    \\ imp_res_tac word_payload_IMP
    \\ rpt var_eq_tac
    \\ qpat_x_assum `LENGTH xs = s.n` (assume_tac o GSYM)
    \\ fs []
    \\ drule LESS_EQ_IMP_APPEND_ALT \\ strip_tac
    \\ full_simp_tac(srw_ss())[] \\ rpt var_eq_tac
    \\ full_simp_tac(srw_ss())[word_list_APPEND]
    \\ disch_then (qspec_then `zs` assume_tac)
    \\ fs [GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB,ADD1]
    \\ SEP_F_TAC
    \\ impl_tac THEN1
     (full_simp_tac(srw_ss())[ADD1,SUM_APPEND,X_LE_DIV,RIGHT_ADD_DISTRIB]
      \\ Cases_on `2 ** shift_length conf` \\ full_simp_tac(srw_ss())[]
      \\ Cases_on `n` \\ full_simp_tac(srw_ss())[MULT_CLAUSES]
      \\ Cases_on `n'` \\ full_simp_tac(srw_ss())[MULT_CLAUSES] \\ decide_tac)
    \\ rpt strip_tac
    \\ full_simp_tac(srw_ss())[word_addr_def,word_add_n2w,ADD_ASSOC] \\ srw_tac[][]
    \\ full_simp_tac(srw_ss())[word_heap_APPEND,word_heap_def,
         SEP_CLAUSES,word_el_def,LET_THM,is_Ref_def]
    \\ full_simp_tac(srw_ss())[word_list_def]
    \\ SEP_W_TAC \\ qexists_tac `ys` \\ full_simp_tac(srw_ss())[]
    \\ reverse conj_tac THEN1
     (full_simp_tac(srw_ss())[update_addr_def,get_addr_def,
         select_shift_out,select_get_lowerbits,ADD1]
      \\ fs [GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
      \\ rewrite_tac [GSYM APPEND_ASSOC,APPEND])
    \\ pop_assum mp_tac
    \\ full_simp_tac(srw_ss())[AC STAR_ASSOC STAR_COMM]
    \\ full_simp_tac(srw_ss())[heap_length_def,SUM_APPEND,el_length_def,ADD1]
    \\ full_simp_tac(srw_ss())[word_list_exists_def,SEP_CLAUSES,SEP_EXISTS_THM]
    \\ srw_tac[][] \\ qexists_tac `ts`
    \\ full_simp_tac(srw_ss())[AC STAR_ASSOC STAR_COMM,SEP_CLAUSES]
    \\ fs [GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
    \\ fs [WORD_MUL_LSL]));

val gc_move_with_NIL = store_thm("gc_move_with_NIL",
  ``!x s y t.
      gen_gc$gc_move gen_conf s x = (y,t) /\ t.ok ==>
      (let (y,s1) = gc_move gen_conf (s with <| h2 := []; r4 := [] |>) x in
        (y,s1 with <| h2 := s.h2 ++ s1.h2; r4 := s1.r4 ++ s.r4 |>)) = (y,t)``,
  Cases \\ fs [gen_gcTheory.gc_move_def] \\ rw []
  \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ CASE_TAC \\ fs []
  \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ CASE_TAC \\ fs []
  \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ CASE_TAC \\ fs []
  \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ rpt (pairarg_tac \\ fs []) \\ rveq \\ fs []
  \\ fs [gc_sharedTheory.gc_state_component_equality]);

val gc_move_with_NIL_LEMMA = store_thm("gc_move_with_NIL_LEMMA",
  ``!x s y t h2 r4 y1 t1.
      gen_gc$gc_move gen_conf s x = (y1,t1) /\ t1.ok ==>
      ?x1 x2.
        t1.h2 = s.h2 ++ x1 /\
        t1.r4 = x2 ++ s.r4 /\
        gen_gc$gc_move gen_conf (s with <| h2 := []; r4 := [] |>) x =
          (y1,t1 with <| h2 := x1; r4 := x2 |>)``,
  Cases \\ fs [gen_gcTheory.gc_move_def] \\ rw []
  \\ CASE_TAC \\ fs []
  \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ CASE_TAC \\ fs []
  \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ CASE_TAC \\ fs []
  \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ rpt (pairarg_tac \\ fs []) \\ rveq \\ fs []);

val gc_move_list_ok_irr = prove(
  ``!x s y1 y2 t1 t2 h2 r4.
      gen_gc$gc_move gen_conf s x = (y1,t1) /\
      gen_gc$gc_move gen_conf (s with <| h2 := h2 ; r4 := r4 |>) x = (y2,t2) ==>
      y1 = y2 /\ ?x1 x2. t2 = t1 with <| h2 := x1 ; r4 := x2 |>``,
  Cases \\ fs [gen_gcTheory.gc_move_def] \\ rw []
  \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ every_case_tac \\ fs []
  \\ rpt (pairarg_tac \\ fs []) \\ rveq \\ fs []);

val gc_move_list_ok_irr = prove(
  ``!x s y1 y2 t1 t2 h2 r4.
      gen_gc$gc_move_list gen_conf s x = (y1,t1) /\ t1.ok /\
      gen_gc$gc_move_list gen_conf (s with <| h2 := h2 ; r4 := r4 |>) x = (y2,t2) ==>
      t2.ok``,
  Induct \\ fs [gen_gcTheory.gc_move_list_def]
  \\ rw [] \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ rpt (pairarg_tac \\ fs []) \\ rveq \\ fs []
  \\ imp_res_tac gen_gcTheory.gc_move_list_ok
  \\ first_x_assum match_mp_tac
  \\ once_rewrite_tac [CONJ_COMM]
  \\ qpat_x_assum `_.ok` kall_tac
  \\ asm_exists_tac \\ fs []
  \\ once_rewrite_tac [CONJ_COMM]
  \\ asm_exists_tac \\ fs []
  \\ metis_tac [gc_move_list_ok_irr]);

val gc_move_list_with_NIL_LEMMA = store_thm("gc_move_list_with_NIL_LEMMA",
  ``!x s y t h2 r4 y1 t1.
      gen_gc$gc_move_list gen_conf s x = (y1,t1) /\ t1.ok ==>
      ?x1 x2.
        t1.h2 = s.h2 ++ x1 /\
        t1.r4 = x2 ++ s.r4 /\
        gen_gc$gc_move_list gen_conf (s with <| h2 := []; r4 := [] |>) x =
          (y1,t1 with <| h2 := x1; r4 := x2 |>)``,
  Induct \\ fs [gen_gcTheory.gc_move_list_def] \\ rw []
  \\ rpt (pairarg_tac \\ fs []) \\ rveq \\ fs []
  \\ rename1 `gc_move gen_conf s h = (x3,state3)`
  \\ rename1 `_ = (x4,state4)`
  \\ `state3.ok` by imp_res_tac gen_gcTheory.gc_move_list_ok
  \\ drule (SIMP_RULE std_ss [] gc_move_with_NIL_LEMMA) \\ fs []
  \\ strip_tac \\ fs [] \\ rveq
  \\ first_assum drule \\ asm_rewrite_tac []
  \\ `state''.ok` by imp_res_tac gc_move_list_ok_irr
  \\ qpat_x_assum `gc_move_list gen_conf state3 x = _` kall_tac
  \\ first_x_assum drule \\ asm_rewrite_tac []
  \\ fs [] \\ rw [] \\ fs []
  \\ fs [gc_sharedTheory.gc_state_component_equality]) |> SIMP_RULE std_ss [];

val gc_move_list_with_NIL = store_thm("gc_move_list_with_NIL",
  ``!x s y t.
      gen_gc$gc_move_list gen_conf s x = (y,t) /\ t.ok ==>
      (let (y,s1) = gc_move_list gen_conf (s with <| h2 := []; r4 := [] |>) x in
        (y,s1 with <| h2 := s.h2 ++ s1.h2; r4 := s1.r4 ++ s.r4 |>)) = (y,t)``,
  rw [] \\ drule gc_move_list_with_NIL_LEMMA \\ fs []
  \\ strip_tac \\ fs [] \\ fs [gc_sharedTheory.gc_state_component_equality]);

val word_gen_gc_move_roots_thm = Q.prove(
  `!x xs x1 w s1 s pb1 pa1 pa m1 m ib1 i1 frame dm curr c1.
    (gen_gc$gc_move_list gen_conf s x = (x1,s1)) /\ s1.ok /\ s.h2 = [] /\ s.r4 = [] /\
    heap_length s.heap <= dimword (:'a) DIV 2 ** shift_length conf /\
    (!t r. (gen_conf.isRef (t,r) <=> t = RefTag)) /\
    conf.len_size + 5 <= dimindex (:'a) /\
    (word_heap curr s.heap conf *
     word_list pa xs * frame) (fun2set (m,dm)) /\
    (word_gen_gc_move_roots conf (MAP (word_addr conf) x,n2w s.a,pa,
        n2w (s.a+s.n),pa + bytes_in_word * n2w s.n,curr,m,dm) =
      (w:'a word_loc list,i1,pa1,ib1,pb1,m1,c1)) /\
    EVERY (is_Ref gen_conf.isRef) (s.r4 ++ s.r3 ++ s.r2 ++ s.r1) /\
    LENGTH xs = s.n /\ good_dimindex (:'a) ==>
    ?xs1.
      (word_heap curr s1.heap conf *
       word_heap pa s1.h2 conf *
       word_heap pb1 s1.r4 conf *
       word_list pa1 xs1 *
       frame) (fun2set (m1,dm)) /\
      (w = MAP (word_addr conf) x1) /\
      heap_length s1.heap = heap_length s.heap /\
      c1 /\ (i1 = n2w s1.a) /\ (ib1 = n2w (s1.a + s1.n)) /\ s1.n = LENGTH xs1 /\
      s.n = heap_length s1.h2 + s1.n + heap_length s1.r4 /\
      pa1 = pa + bytes_in_word * n2w (heap_length s1.h2) /\
      pb1 = pa1 + bytes_in_word * n2w s1.n /\
      EVERY (is_Ref gen_conf.isRef) (s1.r4 ++ s1.r3 ++ s1.r2 ++ s1.r1)`,
  Induct
  THEN1
   (fs [gen_gcTheory.gc_move_list_def,word_gen_gc_move_roots_def] \\ rw []
    \\ fs [word_heap_def,SEP_CLAUSES] \\ asm_exists_tac \\ fs [])
  \\ fs [gen_gcTheory.gc_move_list_def,word_gen_gc_move_roots_def]
  \\ rw [] \\ ntac 4 (pairarg_tac \\ fs []) \\ rveq
  \\ fs [MAP]
  \\ drule (GEN_ALL word_gen_gc_move_thm) \\ fs []
  \\ `state'.ok` by imp_res_tac gen_gcTheory.gc_move_list_ok
  \\ rpt (disch_then drule)
  \\ strip_tac \\ rveq \\ fs []
  \\ drule gc_move_list_with_NIL
  \\ fs [] \\ pairarg_tac \\ fs []
  \\ strip_tac
  \\ rveq \\ fs []
  \\ first_x_assum drule \\ fs []
  \\ strip_tac \\ SEP_F_TAC \\ fs []
  \\ strip_tac \\ rveq \\ fs []
  \\ fs [heap_length_APPEND,GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
  \\ rename1 `s2.n = LENGTH xs2`
  \\ rfs []
  \\ qexists_tac `xs2` \\ fs []
  \\ fs [word_heap_APPEND]
  \\ fs [heap_length_APPEND,GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
  \\ fs [AC STAR_COMM STAR_ASSOC]);

val word_gen_gc_move_list_thm = Q.prove(
  `!x xs x1 w s1 s pb1 pa1 pa m1 m ib1 i1 frame dm curr c1 k k1.
    (gen_gc$gc_move_list gen_conf s x = (x1,s1)) /\ s1.ok /\ s.h2 = [] /\ s.r4 = [] /\
    heap_length s.heap <= dimword (:'a) DIV 2 ** shift_length conf /\
    (!t r. (gen_conf.isRef (t,r) <=> t = RefTag)) /\
    conf.len_size + 5 <= dimindex (:'a) /\
    (word_heap curr s.heap conf * word_list pa xs *
     word_list k (MAP (word_addr conf) x) * frame) (fun2set (m,dm)) /\
    (word_gen_gc_move_list conf (k,n2w (LENGTH x),n2w s.a,pa,
        n2w (s.a+s.n),pa + bytes_in_word * n2w s.n,curr:'a word,m,dm) =
      (k1,i1,pa1,ib1,pb1,m1,c1)) /\
    EVERY (is_Ref gen_conf.isRef) (s.r4 ++ s.r3 ++ s.r2 ++ s.r1) /\
    LENGTH xs = s.n /\ good_dimindex (:'a) /\ LENGTH x < dimword (:'a) ==>
    ?xs1.
      (word_heap curr s1.heap conf *
       word_heap pa s1.h2 conf *
       word_heap pb1 s1.r4 conf *
       word_list pa1 xs1 *
       word_list k (MAP (word_addr conf) x1) *
       frame) (fun2set (m1,dm)) /\
      heap_length s1.heap = heap_length s.heap /\
      c1 /\ (i1 = n2w s1.a) /\ (ib1 = n2w (s1.a + s1.n)) /\ s1.n = LENGTH xs1 /\
      s.n = heap_length s1.h2 + s1.n + heap_length s1.r4 /\
      k1 = k + n2w (LENGTH x) * bytes_in_word /\
      pa1 = pa + bytes_in_word * n2w (heap_length s1.h2) /\
      pb1 = pa1 + bytes_in_word * n2w s1.n /\
      EVERY (is_Ref gen_conf.isRef) (s1.r4 ++ s1.r3 ++ s1.r2 ++ s1.r1)`,
  Induct
  THEN1
   (fs [gen_gcTheory.gc_move_list_def,Once word_gen_gc_move_list_def] \\ rw []
    \\ fs [word_heap_def,SEP_CLAUSES] \\ asm_exists_tac \\ fs [])
  \\ fs [gen_gcTheory.gc_move_list_def]
  \\ once_rewrite_tac [word_gen_gc_move_list_def]
  \\ rpt strip_tac \\ fs []
  \\ rw [] \\ ntac 4 (pairarg_tac \\ fs []) \\ rveq
  \\ fs [ADD1,GSYM word_add_n2w,word_list_def]
  \\ ntac 4 (pop_assum mp_tac) \\ SEP_R_TAC \\ fs []
  \\ rpt strip_tac
  \\ drule (GEN_ALL word_gen_gc_move_thm) \\ fs []
  \\ `state'.ok` by imp_res_tac gen_gcTheory.gc_move_list_ok
  \\ fs [GSYM STAR_ASSOC]
  \\ rpt (disch_then drule)
  \\ fs [word_add_n2w]
  \\ strip_tac \\ rveq \\ fs []
  \\ drule gc_move_list_with_NIL
  \\ fs [] \\ pairarg_tac \\ fs []
  \\ strip_tac
  \\ rveq \\ fs []
  \\ first_x_assum drule \\ fs []
  \\ qpat_x_assum `word_gen_gc_move_list conf _ = _` mp_tac
  \\ SEP_W_TAC
  \\ rpt strip_tac
  \\ SEP_F_TAC \\ fs []
  \\ strip_tac \\ rveq \\ fs []
  \\ fs [heap_length_APPEND,GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
  \\ rename1 `s2.n = LENGTH xs2`
  \\ rfs []
  \\ qexists_tac `xs2` \\ fs []
  \\ fs [word_heap_APPEND]
  \\ fs [heap_length_APPEND,GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
  \\ fs [AC STAR_COMM STAR_ASSOC]) |> SIMP_RULE std_ss [];

val word_gen_gc_move_refs_def = Define `
  word_gen_gc_move_refs conf k
   (r2a:'a word,r1a:'a word,i,pa:'a word,ib,pb,old,m:'a word -> 'a word_loc,dm) =
    if r2a = r1a then (r2a,i,pa,ib,pb,m,T) else
    if k = 0n then (r2a,i,pa,ib,pb,m,F) else
      let c = (r2a IN dm) in
      let v = m r2a in
      let c = (c /\ isWord v) in
      let l = decode_length conf (theWord v) in
      let (r2a,i,pa,ib,pb,m,c1) = word_gen_gc_move_list conf
                                    (r2a+bytes_in_word,l,i,pa,ib,pb,old,m,dm) in
      let (r2a,i,pa,ib,pb,m,c2) = word_gen_gc_move_refs conf (k-1)
                                    (r2a,r1a,i,pa,ib,pb,old,m,dm) in
        (r2a,i,pa,ib,pb,m,c /\ c1 /\ c2)`

val word_heap_parts_def = Define `
  word_heap_parts conf p s xs =
    word_heap p (s.h1 ++ s.h2) conf *
    word_list (p + bytes_in_word * n2w (heap_length (s.h1 ++ s.h2))) xs *
    word_heap (p + bytes_in_word * n2w (heap_length (s.h1 ++ s.h2) + LENGTH xs))
      (s.r4 ++ s.r3 ++ s.r2 ++ s.r1) conf`

val gc_move_const = prove(
  ``!l s xs' s'.
      gen_gc$gc_move gen_conf s l = (xs',s') ==>
      s'.h1 = s.h1 /\ s'.r1 = s.r1 /\ s'.r2 = s.r2 /\ s'.r3 = s.r3``,
  Cases \\ fs [gen_gcTheory.gc_move_def] \\ rpt gen_tac
  \\ CASE_TAC \\ TRY (rw [] \\ fs [] \\ NO_TAC)
  \\ CASE_TAC \\ TRY (rw [] \\ fs [] \\ NO_TAC)
  \\ CASE_TAC \\ TRY (rw [] \\ fs [] \\ NO_TAC)
  \\ pairarg_tac \\ fs []
  \\ rpt strip_tac \\ rveq \\ fs []);

val gc_move_list_const = prove(
  ``!l s xs' s'.
      gen_gc$gc_move_list gen_conf s l = (xs',s') ==>
      s'.h1 = s.h1 /\ s'.r1 = s.r1 /\ s'.r2 = s.r2 /\ s'.r3 = s.r3``,
  Induct \\ fs [gen_gcTheory.gc_move_list_def]
  \\ rpt gen_tac \\ rpt (pairarg_tac \\ fs [])
  \\ fs [] \\ imp_res_tac gc_move_const \\ res_tac \\ fs []
  \\ strip_tac \\ rveq \\ fs []);

val gc_move_data_const = prove(
  ``!gen_conf s s'.
      gen_gc$gc_move_data gen_conf s = s' ==>
      s'.r1 = s.r1 /\ s'.r2 = s.r2 /\ s'.r3 = s.r3``,
  ho_match_mp_tac gen_gcTheory.gc_move_data_ind
  \\ rpt (gen_tac ORELSE disch_then assume_tac)
  \\ pop_assum mp_tac
  \\ once_rewrite_tac [gen_gcTheory.gc_move_data_def]
  \\ TOP_CASE_TAC \\ fs []
  \\ TOP_CASE_TAC \\ fs []
  \\ TRY (strip_tac \\ rveq \\ fs [] \\ NO_TAC)
  \\ TOP_CASE_TAC \\ fs []
  \\ TRY (strip_tac \\ rveq \\ fs [] \\ NO_TAC)
  \\ pairarg_tac \\ fs []
  \\ strip_tac \\ fs []
  \\ rfs [] \\ imp_res_tac gc_move_list_const \\ fs []);

val gc_move_refs_const = prove(
  ``!gen_conf s s'.
      gen_gc$gc_move_refs gen_conf s = s' ==>
      s'.h1 = s.h1``,
  ho_match_mp_tac gen_gcTheory.gc_move_refs_ind
  \\ rpt (gen_tac ORELSE disch_then assume_tac)
  \\ pop_assum mp_tac
  \\ once_rewrite_tac [gen_gcTheory.gc_move_refs_def]
  \\ TOP_CASE_TAC \\ fs []
  \\ TRY (strip_tac \\ rveq \\ fs [] \\ NO_TAC)
  \\ TOP_CASE_TAC \\ fs []
  \\ TRY (strip_tac \\ rveq \\ fs [] \\ NO_TAC)
  \\ pairarg_tac \\ fs []
  \\ strip_tac \\ fs []
  \\ rfs [] \\ imp_res_tac gc_move_list_const \\ fs []);

val heap_length_gc_forward_ptr = prove(
  ``!hs n k a ok heap.
      gc_forward_ptr n hs k a ok = (heap,T) ==>
      heap_length heap = heap_length hs /\ ok``,
  Induct \\ once_rewrite_tac [gc_forward_ptr_def] \\ rpt gen_tac
  THEN1 fs []
  \\ IF_CASES_TAC THEN1
   (strip_tac \\ rveq
    \\ qpat_x_assum `!x._` kall_tac
    \\ fs [] \\ rveq
    \\ fs [] \\ fs [heap_length_def,el_length_def,isDataElement_def])
  \\ IF_CASES_TAC THEN1 simp_tac std_ss []
  \\ simp_tac std_ss [LET_THM]
  \\ pairarg_tac \\ asm_rewrite_tac []
  \\ simp_tac std_ss [LET_THM]
  \\ strip_tac \\ rveq
  \\ first_x_assum drule \\ rw []
  \\ fs [heap_length_def]);

val gc_move_thm = prove(
  ``!l s l1 s1.
      gen_gc$gc_move gen_conf s l = (l1,s1) /\ s1.ok /\ len_inv s ==>
      len_inv s1``,
  Cases \\ fs [gen_gcTheory.gc_move_def] \\ rpt gen_tac
  \\ CASE_TAC \\ TRY (rw [] \\ fs [] \\ NO_TAC)
  \\ CASE_TAC \\ TRY (rw [] \\ fs [] \\ NO_TAC)
  \\ CASE_TAC \\ TRY (rw [] \\ fs [] \\ NO_TAC)
  \\ pairarg_tac \\ fs []
  \\ rpt strip_tac \\ rveq \\ fs []
  \\ fs [len_inv_def]
  \\ imp_res_tac heap_length_gc_forward_ptr
  \\ fs [heap_length_def,el_length_def,SUM_APPEND]);

val gc_move_list_thm = prove(
  ``!l s l1 s1.
      gen_gc$gc_move_list gen_conf s l = (l1,s1) /\ s1.ok /\ len_inv s ==>
      len_inv s1``,
  Induct \\ fs [gen_gcTheory.gc_move_list_def]
  \\ rpt gen_tac \\ rpt (pairarg_tac \\ fs [])
  \\ fs [] \\ imp_res_tac gc_move_const \\ res_tac \\ fs []
  \\ strip_tac \\ rveq \\ fs []
  \\ drule gen_gcTheory.gc_move_list_ok \\ fs [] \\ strip_tac
  \\ imp_res_tac gc_move_thm
  \\ fs []);

val word_list_IMP_limit = prove(
  ``(word_list (curr:'a word) hs * frame) (fun2set (m,dm)) /\
    good_dimindex (:'a) ==>
    LENGTH hs <= dimword (:'a) DIV (dimindex (:α) DIV 8)``,
  rw [] \\ CCONTR_TAC
  \\ rfs [good_dimindex_def] \\ rfs [dimword_def]
  \\ fs [GSYM NOT_LESS]
  \\ imp_res_tac LESS_LENGTH
  \\ fs [] \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
  \\ rveq \\ fs [word_list_APPEND]
  \\ fs [bytes_in_word_def,word_mul_n2w]
  \\ qmatch_asmsub_abbrev_tac `curr + ww`
  \\ Cases_on `ys1` \\ fs []
  \\ fs [word_list_def]
  \\ `curr <> curr + ww` by SEP_NEQ_TAC
  \\ pop_assum mp_tac \\ fs []
  \\ unabbrev_all_tac
  \\ once_rewrite_tac [GSYM n2w_mod]
  \\ fs [dimword_def]);

val word_el_eq_word_list = prove(
  ``!hs curr frame.
      (word_el (curr:'a word) hs conf * frame) (fun2set (m,dm)) ==>
      ?xs. (word_list curr xs * frame) (fun2set (m,dm)) /\
           el_length hs = LENGTH xs``,
  Cases \\ fs [word_el_def,el_length_def,word_list_exists_def]
  \\ fs [SEP_CLAUSES,SEP_EXISTS_THM]
  \\ full_simp_tac (std_ss++sep_cond_ss) [cond_STAR]
  THEN1 (rw [] \\ asm_exists_tac \\ fs [])
  THEN1 (rw [] \\ fs [GSYM word_list_def] \\ asm_exists_tac \\ fs [])
  \\ Cases_on `b` \\ fs [word_el_def]
  \\ rw [] \\ pairarg_tac \\ fs []
  \\ fs [SEP_CLAUSES,SEP_EXISTS_THM]
  \\ full_simp_tac (std_ss++sep_cond_ss) [cond_STAR]
  \\ asm_exists_tac \\ fs []
  \\ Cases_on `q` \\ fs [word_payload_def] \\ rfs [] \\ rveq \\ fs []);

val word_heap_eq_word_list = prove(
  ``!(hs:'a ml_heap) curr frame.
      (word_heap (curr:'a word) (hs:'a ml_heap) conf * frame) (fun2set (m,dm)) ==>
      ?xs. (word_list curr xs * frame) (fun2set (m,dm)) /\
           heap_length hs = LENGTH xs``,
  Induct
  THEN1 (rw [] \\ qexists_tac `[]` \\ fs [word_list_def,word_heap_def])
  \\ rw [] \\ fs [word_heap_def] \\ fs [GSYM STAR_ASSOC]
  \\ drule word_el_eq_word_list
  \\ strip_tac \\ SEP_F_TAC \\ strip_tac
  \\ qexists_tac `xs ++ xs'`
  \\ fs [word_list_APPEND,AC STAR_ASSOC STAR_COMM,heap_length_def] \\ rfs []);

val word_heap_IMP_limit = prove(
  ``(word_heap (curr:'a word) (hs:'a ml_heap) conf * frame) (fun2set (m,dm)) /\
    good_dimindex (:'a) ==>
    heap_length hs <= dimword (:'a) DIV (dimindex (:α) DIV 8)``,
  rpt strip_tac
  \\ drule word_heap_eq_word_list \\ strip_tac
  \\ drule word_list_IMP_limit \\ fs []  );

val word_gen_gc_move_refs_thm = Q.prove(
  `!k s m dm curr xs s1 pb1 pa1 m1 ib1 i1 frame c1 p1.
    (gen_gc$gc_move_refs gen_conf s = s1) /\ s1.ok /\
    heap_length s.heap <= dimword (:'a) DIV 2 ** shift_length conf /\
    heap_length s.heap * (dimindex (:'a) DIV 8) < dimword (:'a) /\
    (!t r. (gen_conf.isRef (t,r) <=> t = RefTag)) /\
    conf.len_size + 5 <= dimindex (:'a) /\
    (word_gen_gc_move_refs conf k
       ((* r2a *) p + bytes_in_word *
          n2w (heap_length (s.h1 ++ s.h2 ++ s.r4 ++ s.r3) + LENGTH xs),
        (* r1a *) p + bytes_in_word *
          n2w (heap_length (s.h1 ++ s.h2 ++ s.r4 ++ s.r3 ++ s.r2) + LENGTH xs),
        n2w s.a,
        (* pa *) p + bytes_in_word * n2w (heap_length (s.h1 ++ s.h2)),
        n2w (s.a+s.n),
        (* pb *) p + bytes_in_word * n2w (heap_length (s.h1 ++ s.h2) + s.n),
        curr:'a word,m,dm) =
      (p1,i1,pa1,ib1,pb1,m1,c1)) /\
    LENGTH s.r2 <= k /\ len_inv s /\
    (word_heap curr s.heap conf *
     word_heap_parts conf p s xs *
     frame) (fun2set (m,dm)) /\
    EVERY (is_Ref gen_conf.isRef) (s.r4 ++ s.r3 ++ s.r2 ++ s.r1) /\
    LENGTH xs = s.n /\ good_dimindex (:'a) ==>
    ?xs1.
      (word_heap curr s1.heap conf *
       word_heap_parts conf p s1 xs1 *
       frame) (fun2set (m1,dm)) /\ s1.r3 = [] /\ s1.r2 = [] /\
      heap_length s1.heap = heap_length s.heap /\
      c1 /\ (i1 = n2w s1.a) /\ (ib1 = n2w (s1.a + s1.n)) /\ s1.n = LENGTH xs1 /\
      heap_length s.h2 + s.n + heap_length s.r4 =
      heap_length s1.h2 + s1.n + heap_length s1.r4 /\
      pa1 = p + bytes_in_word * n2w (heap_length (s1.h1 ++ s1.h2)) /\
      pb1 = p + bytes_in_word * n2w (heap_length (s1.h1 ++ s1.h2) + s1.n) /\
      p1 = p + bytes_in_word * n2w (heap_length
              (s.h1 ++ s.h2 ++ s.r4 ++ s.r3 ++ s.r2) + LENGTH xs) /\ len_inv s1 /\
      EVERY (is_Ref gen_conf.isRef) (s1.r4 ++ s1.r3 ++ s1.r2 ++ s1.r1)`,
  completeInduct_on `k` \\ rpt strip_tac
  \\ fs [PULL_FORALL,AND_IMP_INTRO,GSYM CONJ_ASSOC]
  \\ qpat_x_assum `gc_move_refs gen_conf s = s1` mp_tac
  \\ once_rewrite_tac [gen_gcTheory.gc_move_refs_def]
  \\ CASE_TAC THEN1
   (rw [] \\ fs []
    \\ qpat_x_assum `word_gen_gc_move_refs conf k _ = _` mp_tac
    \\ once_rewrite_tac [word_gen_gc_move_refs_def]
    \\ fs [] \\ strip_tac \\ rveq
    \\ qexists_tac `xs`
    \\ fs [word_heap_parts_def]
    \\ fs [len_inv_def])
  \\ CASE_TAC
  THEN1 (strip_tac \\ rveq \\ fs [])
  THEN1 (strip_tac \\ rveq \\ fs [])
  \\ fs []
  \\ rpt (pairarg_tac \\ fs [])
  \\ rename1 `_ = (_,s3)`
  \\ strip_tac
  \\ `s3.ok` by (rveq \\ imp_res_tac gen_gcTheory.gc_move_refs_ok \\ fs [])
  \\ qmatch_asmsub_abbrev_tac `gc_move_refs gen_conf s4`
  \\ rveq
  \\ `len_inv s3` by (imp_res_tac gc_move_list_thm \\ fs [] \\ NO_TAC)
  \\ `s3.h1 = s.h1 /\ s3.r1 = s.r1 /\ s3.r2 = s.r2 /\ s3.r3 = s.r3` by
    (drule gc_move_list_const \\ fs [])
  \\ `len_inv s4` by
    (unabbrev_all_tac
     \\ fs [len_inv_def,heap_length_def,SUM_APPEND,el_length_def] \\ NO_TAC)
  \\ full_simp_tac std_ss [GSYM STAR_ASSOC]
  \\ drule word_heap_IMP_limit
  \\ full_simp_tac std_ss [STAR_ASSOC] \\ strip_tac
  \\ drule gc_move_list_with_NIL \\ fs []
  \\ pairarg_tac \\ fs []
  \\ strip_tac \\ rveq \\ fs []
  \\ PairCases_on `b`
  \\ rfs [is_Ref_def] \\ rveq
  \\ qpat_x_assum `word_gen_gc_move_refs conf k _ = _` mp_tac
  \\ once_rewrite_tac [word_gen_gc_move_refs_def]
  \\ IF_CASES_TAC THEN1
   (fs [heap_length_APPEND,GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
    \\ rewrite_tac [addressTheory.WORD_EQ_ADD_CANCEL,GSYM WORD_ADD_ASSOC]
    \\ qsuff_tac `F` \\ fs []
    \\ fs [heap_length_def,el_length_def]
    \\ full_simp_tac std_ss [addressTheory.WORD_EQ_ADD_CANCEL,GSYM WORD_ADD_ASSOC]
    \\ pop_assum mp_tac \\ fs [bytes_in_word_def,word_mul_n2w]
    \\ fs [RIGHT_ADD_DISTRIB]
    \\ qmatch_goalsub_abbrev_tac `nn MOD _`
    \\ qsuff_tac `nn < dimword (:α)`
    \\ fs [] \\ unabbrev_all_tac \\ rfs [good_dimindex_def]
    \\ rfs [dimword_def]
    \\ fs [len_inv_def,heap_length_def,el_length_def,SUM_APPEND] \\ rfs [])
  \\ simp [] \\ pop_assum kall_tac
  \\ rpt (pairarg_tac \\ fs [])
  \\ strip_tac \\ rveq
  \\ fs [heap_length_APPEND]
  \\ fs [heap_length_def,el_length_def]
  \\ fs [GSYM heap_length_def]
  \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
         heap_length_APPEND,word_payload_def,GSYM word_add_n2w,
         WORD_LEFT_ADD_DISTRIB,word_list_def]
  \\ full_simp_tac (std_ss++sep_cond_ss) [cond_STAR] \\ rfs [] \\ rveq
  \\ ntac 4 (pop_assum mp_tac)
  \\ SEP_R_TAC \\ fs [theWord_def,isWord_def]
  \\ qmatch_goalsub_abbrev_tac `word_gen_gc_move_list conf (newp,_)`
  \\ rpt strip_tac
  \\ drule word_gen_gc_move_list_thm \\ fs []
  \\ fs [is_Ref_def]
  \\ strip_tac
  \\ SEP_F_TAC \\ fs [GSYM word_add_n2w]
  \\ impl_tac THEN1
   (rfs [good_dimindex_def] \\ rfs [dimword_def]
    \\ fs [len_inv_def,heap_length_def,el_length_def,SUM_APPEND] \\ rfs [])
  \\ strip_tac \\ rveq
  \\ qpat_x_assum `s.n = _` (assume_tac o GSYM)
  \\ fs [el_length_def,heap_length_def]
  \\ fs [GSYM heap_length_def] \\ rfs []
  \\ qmatch_asmsub_abbrev_tac `word_gen_gc_move_refs conf _ input1 = _`
  \\ qpat_x_assum `!m:num. _`
       (qspecl_then [`k-1`,`s4`,`m'`,`dm`,`curr`,`xs1`] mp_tac) \\ fs []
  \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
         heap_length_APPEND,word_payload_def,GSYM word_add_n2w,
         WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
  \\ qmatch_goalsub_abbrev_tac `word_gen_gc_move_refs conf _ input2 = _`
  \\ `input1 = input2` by
   (unabbrev_all_tac \\ simp_tac std_ss [] \\ rpt strip_tac
    \\ fs [SUM_APPEND,el_length_def]
    \\ pop_assum (assume_tac o GSYM) \\ fs []
    \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
          heap_length_APPEND,word_payload_def,GSYM word_add_n2w,
          WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
    \\ NO_TAC)
  \\ fs []
  \\ disch_then (qspec_then `frame` mp_tac)
  \\ impl_tac THEN1
   (qunabbrev_tac `s4` \\ fs [is_Ref_def]
    \\ ntac 3 (pop_assum kall_tac)
    \\ qpat_x_assum `_ (fun2set (_,dm))` mp_tac
    \\ qpat_x_assum `_ = s.n` (assume_tac o GSYM) \\ fs []
    \\ `LENGTH xs' = LENGTH l` by
          (imp_res_tac gen_gcTheory.gc_move_list_length \\ fs [])
    \\ qunabbrev_tac `newp`
    \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
          heap_length_APPEND,word_payload_def,GSYM word_add_n2w,SUM_APPEND,
          WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
    \\ match_mp_tac (METIS_PROVE [] ``f = g ==> f x ==> g x``)
    \\ fs [AC STAR_ASSOC STAR_COMM,SEP_CLAUSES]
    \\ rpt (AP_TERM_TAC ORELSE AP_THM_TAC))
  \\ strip_tac
  \\ qexists_tac `xs1'` \\ fs []
  \\ qabbrev_tac `s5 = gc_move_refs gen_conf s4`
  \\ qunabbrev_tac `s4` \\ fs [is_Ref_def]
  \\ fs [el_length_def,SUM_APPEND]
  \\ qpat_x_assum `_ = s.n` (assume_tac o GSYM) \\ fs []
  \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
         heap_length_APPEND,word_payload_def,GSYM word_add_n2w,
         WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]);

val word_gen_gc_move_data_def = Define `
  word_gen_gc_move_data conf k
   (h2a:'a word,i,pa:'a word,ib,pb,old,m,dm) =
    if h2a = pa then (i,pa,ib,pb,m,T) else
    if k = 0n then (i,pa,ib,pb,m,F) else
      let c = (h2a IN dm) in
      let v = m h2a in
      let c = (c /\ isWord v) in
      let l = decode_length conf (theWord v) in
        if word_bit 2 (theWord v) then
          let h2a = h2a + (l + 1w) * bytes_in_word in
          let (i,pa,ib,pb,m,c2) = word_gen_gc_move_data conf (k-1)
                        (h2a,i,pa,ib,pb,old,m,dm) in
            (i,pa,ib,pb,m,c)
        else
          let (h2a,i,pa,ib,pb,m,c1) = word_gen_gc_move_list conf
                        (h2a+bytes_in_word,l,i,pa,ib,pb,old,m,dm) in
          let (i,pa,ib,pb,m,c2) = word_gen_gc_move_data conf (k-1)
                        (h2a,i,pa,ib,pb,old,m,dm) in
            (i,pa,ib,pb,m,c /\ c1 /\ c2)`

val word_gen_gc_move_data_thm = Q.prove(
  `!k s m dm curr xs s1 pb1 pa1 m1 ib1 i1 frame c1.
    (gen_gc$gc_move_data gen_conf s = s1) /\ s1.ok /\
    heap_length s.heap <= dimword (:'a) DIV 2 ** shift_length conf /\
    heap_length s.heap * (dimindex (:'a) DIV 8) < dimword (:'a) /\
    conf.len_size + 2 < dimindex (:α) /\
    (!t r. (gen_conf.isRef (t,r) <=> t = RefTag)) /\
    conf.len_size + 5 <= dimindex (:'a) /\
    (word_gen_gc_move_data conf k
       ((* h2a *) p + bytes_in_word * n2w (heap_length s.h1),
        n2w s.a,
        (* pa *) p + bytes_in_word * n2w (heap_length (s.h1 ++ s.h2)),
        n2w (s.a+s.n),
        (* pb *) p + bytes_in_word * n2w (heap_length (s.h1 ++ s.h2) + s.n),
        curr:'a word,m,dm) =
      (i1,pa1,ib1,pb1,m1,c1)) /\
    heap_length s.h2 + s.n + heap_length s.r4 <= k /\ len_inv s /\
    (word_heap curr s.heap conf *
     word_heap_parts conf p s xs *
     frame) (fun2set (m,dm)) /\
    EVERY (is_Ref gen_conf.isRef) (s.r4 ++ s.r3 ++ s.r2 ++ s.r1) /\
    LENGTH xs = s.n /\ good_dimindex (:'a) ==>
    ?xs1.
      (word_heap curr s1.heap conf *
       word_heap_parts conf p s1 xs1 *
       frame) (fun2set (m1,dm)) /\ s1.h2 = [] /\
      heap_length s1.heap = heap_length s.heap /\
      c1 /\ (i1 = n2w s1.a) /\ (ib1 = n2w (s1.a + s1.n)) /\
      s1.n = LENGTH xs1 /\ len_inv s1 /\
      heap_length (s1.h1 ++ s1.h2 ++ s1.r4) + s1.n =
      heap_length (s.h1 ++ s.h2 ++ s.r4) + s.n /\
      pa1 = p + bytes_in_word * n2w (heap_length (s1.h1 ++ s1.h2)) /\
      pb1 = p + bytes_in_word * n2w (heap_length (s1.h1 ++ s1.h2) + s1.n) /\
      EVERY (is_Ref gen_conf.isRef) (s1.r4 ++ s1.r3 ++ s1.r2 ++ s1.r1)`,
  completeInduct_on `k` \\ rpt strip_tac
  \\ fs [PULL_FORALL,AND_IMP_INTRO,GSYM CONJ_ASSOC]
  \\ qpat_x_assum `gc_move_data gen_conf s = s1` mp_tac
  \\ once_rewrite_tac [gen_gcTheory.gc_move_data_def]
  \\ CASE_TAC THEN1
   (rw [] \\ fs []
    \\ qpat_x_assum `word_gen_gc_move_data conf k _ = _` mp_tac
    \\ once_rewrite_tac [word_gen_gc_move_data_def]
    \\ fs [] \\ strip_tac \\ rveq
    \\ qexists_tac `xs`
    \\ fs [word_heap_parts_def]
    \\ fs [len_inv_def])
  \\ IF_CASES_TAC THEN1 (rw[] \\ fs [])
  \\ CASE_TAC
  THEN1 (strip_tac \\ rveq \\ fs [])
  THEN1 (strip_tac \\ rveq \\ fs [])
  \\ fs []
  \\ rpt (pairarg_tac \\ fs [])
  \\ rename1 `_ = (_,s3)`
  \\ strip_tac
  \\ `s3.ok` by (rveq \\ imp_res_tac gen_gcTheory.gc_move_data_ok \\ fs [])
  \\ qmatch_asmsub_abbrev_tac `gc_move_data gen_conf s4`
  \\ rveq
  \\ `len_inv s3` by (imp_res_tac gc_move_list_thm \\ fs [] \\ NO_TAC)
  \\ `s3.h1 = s.h1 /\ s3.r1 = s.r1 /\ s3.r2 = s.r2 /\ s3.r3 = s.r3` by
    (drule gc_move_list_const \\ fs [])
  \\ `len_inv s4` by
    (unabbrev_all_tac
     \\ fs [len_inv_def,heap_length_def,SUM_APPEND,el_length_def]
     \\ drule gc_move_list_with_NIL \\ fs []
     \\ pairarg_tac \\ fs []
     \\ strip_tac \\ rveq \\ fs [SUM_APPEND,el_length_def] \\ NO_TAC)
  \\ full_simp_tac std_ss [GSYM STAR_ASSOC]
  \\ drule word_heap_IMP_limit
  \\ full_simp_tac std_ss [STAR_ASSOC] \\ strip_tac
  \\ drule gc_move_list_with_NIL \\ fs []
  \\ pairarg_tac \\ fs []
  \\ strip_tac \\ rveq \\ fs []
  \\ PairCases_on `b`
  \\ rfs [is_Ref_def] \\ rveq
  \\ qpat_x_assum `word_gen_gc_move_data conf k _ = _` mp_tac
  \\ once_rewrite_tac [word_gen_gc_move_data_def]
  \\ IF_CASES_TAC THEN1
   (fs [heap_length_APPEND,GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
    \\ rewrite_tac [addressTheory.WORD_EQ_ADD_CANCEL,GSYM WORD_ADD_ASSOC]
    \\ qsuff_tac `F` \\ fs []
    \\ fs [heap_length_def,el_length_def]
    \\ full_simp_tac std_ss [addressTheory.WORD_EQ_ADD_CANCEL,GSYM WORD_ADD_ASSOC]
    \\ pop_assum mp_tac \\ fs [bytes_in_word_def,word_mul_n2w]
    \\ fs [RIGHT_ADD_DISTRIB]
    \\ qmatch_goalsub_abbrev_tac `nn MOD _`
    \\ qsuff_tac `nn < dimword (:α)`
    \\ fs [] \\ unabbrev_all_tac \\ rfs [good_dimindex_def]
    \\ rfs [dimword_def]
    \\ fs [len_inv_def,heap_length_def,el_length_def,SUM_APPEND] \\ rfs [])
  \\ simp [] \\ pop_assum kall_tac
  \\ rpt (pairarg_tac \\ fs [])
  \\ strip_tac \\ rveq
  \\ fs [heap_length_APPEND]
  \\ fs [heap_length_def,el_length_def]
  \\ fs [GSYM heap_length_def]
  \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
         heap_length_APPEND,word_payload_def,GSYM word_add_n2w,
         WORD_LEFT_ADD_DISTRIB,word_list_def]
  \\ pairarg_tac \\ fs []
  \\ full_simp_tac (std_ss++sep_cond_ss) [cond_STAR] \\ rfs [] \\ rveq
  \\ ntac 4 (pop_assum mp_tac)
  \\ SEP_R_TAC \\ fs [theWord_def,isWord_def]
  \\ Cases_on `word_bit 2 h` \\ fs []
  THEN1
   (rpt strip_tac \\ rveq
    \\ `l = []` by (imp_res_tac word_payload_T_IMP \\ rfs [] \\ NO_TAC)
    \\ rveq \\ fs [gen_gcTheory.gc_move_list_def] \\ rveq \\ fs []
    \\ qpat_x_assum `word_gen_gc_move_data conf (k − 1) _ = _` kall_tac
    \\ qpat_x_assum `word_gen_gc_move_list conf _ = _` kall_tac
    \\ rfs []
    \\ qpat_x_assum `!m:num. _`
         (qspecl_then [`k-1`,`s4`,`m`,`dm`,`curr`,`xs`] mp_tac) \\ fs []
    \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
           heap_length_APPEND,word_payload_def,GSYM word_add_n2w,
           WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
    \\ qmatch_asmsub_abbrev_tac `word_gen_gc_move_data conf _ input1 = _`
    \\ qmatch_goalsub_abbrev_tac `word_gen_gc_move_data conf _ input2 = _`
    \\ `input1 = input2` by
     (unabbrev_all_tac \\ simp_tac std_ss [] \\ rpt strip_tac
      \\ fs [SUM_APPEND,el_length_def]
      \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
            heap_length_APPEND,word_payload_def,GSYM word_add_n2w,
            WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
      \\ imp_res_tac word_payload_T_IMP \\ rfs [] \\ NO_TAC)
    \\ fs []
    \\ disch_then (qspec_then `frame` mp_tac)
    \\ impl_tac THEN1
     (qunabbrev_tac `s4` \\ fs [is_Ref_def]
      \\ qpat_x_assum `_ (fun2set (_,dm))` mp_tac
      \\ qpat_x_assum `_ = s.n` (assume_tac o GSYM) \\ fs []
      \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
            heap_length_APPEND,word_payload_def,GSYM word_add_n2w,SUM_APPEND,
            WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
      \\ match_mp_tac (METIS_PROVE [] ``f = g ==> f x ==> g x``)
      \\ fs [AC STAR_ASSOC STAR_COMM,SEP_CLAUSES])
    \\ strip_tac
    \\ qexists_tac `xs1` \\ fs [] \\ rpt strip_tac
    \\ qabbrev_tac `s5 = gc_move_data gen_conf s4`
    \\ qunabbrev_tac `s4`
    \\ fs [el_length_def,SUM_APPEND]
    \\ qpat_x_assum `_ = s.n` (assume_tac o GSYM)
    \\ pop_assum mp_tac \\ simp_tac std_ss []
    \\ CCONTR_TAC \\ fs [] \\ rfs [])
  \\ qmatch_goalsub_abbrev_tac `word_gen_gc_move_list conf (newp,_)`
  \\ rpt strip_tac \\ rveq
  \\ drule word_gen_gc_move_list_thm \\ fs []
  \\ drule word_payload_T_IMP
  \\ fs [] \\ strip_tac \\ rveq \\ fs []
  \\ fs [is_Ref_def]
  \\ strip_tac
  \\ SEP_F_TAC \\ fs [GSYM word_add_n2w]
  \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
            heap_length_APPEND,word_payload_def,GSYM word_add_n2w,SUM_APPEND,
            WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
  \\ impl_tac THEN1
   (rfs [good_dimindex_def] \\ rfs [dimword_def]
    \\ fs [len_inv_def,heap_length_def,el_length_def,SUM_APPEND] \\ rfs [])
  \\ strip_tac \\ rveq
  \\ qpat_x_assum `s.n = _` (assume_tac o GSYM)
  \\ fs [el_length_def,heap_length_def]
  \\ fs [GSYM heap_length_def] \\ rfs []
  \\ qmatch_asmsub_abbrev_tac `word_gen_gc_move_data conf _ input1 = _`
  \\ qpat_x_assum `!m:num. _`
       (qspecl_then [`k-1`,`s4`,`m''`,`dm`,`curr`,`xs1`] mp_tac) \\ fs []
  \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
         heap_length_APPEND,word_payload_def,GSYM word_add_n2w,
         WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
  \\ qmatch_goalsub_abbrev_tac `word_gen_gc_move_data conf _ input2 = _`
  \\ `input1 = input2` by
   (unabbrev_all_tac \\ simp_tac std_ss [] \\ rpt strip_tac
    \\ fs [SUM_APPEND,el_length_def]
    \\ pop_assum (assume_tac o GSYM) \\ fs []
    \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
          heap_length_APPEND,word_payload_def,GSYM word_add_n2w,
          WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
    \\ NO_TAC)
  \\ fs []
  \\ drule (GEN_ALL word_payload_swap)
  \\ drule gen_gcTheory.gc_move_list_length
  \\ strip_tac \\ disch_then drule \\ strip_tac
  \\ disch_then (qspec_then `frame` mp_tac)
  \\ impl_tac THEN1
   (qunabbrev_tac `s4` \\ fs [is_Ref_def]
    \\ qpat_x_assum `_ (fun2set (_,dm))` mp_tac
    \\ qpat_x_assum `_ = s.n` (assume_tac o GSYM) \\ fs []
    \\ qunabbrev_tac `newp`
    \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
          heap_length_APPEND,word_payload_def,GSYM word_add_n2w,SUM_APPEND,
          WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
    \\ fs [AC STAR_ASSOC STAR_COMM,SEP_CLAUSES])
  \\ strip_tac
  \\ qexists_tac `xs1'` \\ fs []
  \\ qabbrev_tac `s5 = gc_move_data gen_conf s4`
  \\ qunabbrev_tac `s4` \\ fs [is_Ref_def]
  \\ fs [el_length_def,SUM_APPEND]
  \\ qpat_x_assum `_ = s.n` (assume_tac o GSYM) \\ fs []
  \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
         heap_length_APPEND,word_payload_def,GSYM word_add_n2w,
         WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]);

val word_gen_gc_move_loop_def = Define `
  word_gen_gc_move_loop conf k
   (pax:'a word,i,pa:'a word,ib,pb,pbx,old,m,dm) =
    if pbx = pb then
      if pax = pa then
        (i,pa,ib,pb,m,T)
      else
        let (i,pa,ib,pb,m,c1) = word_gen_gc_move_data conf (dimword (:'a))
                                   (pax,i,pa,ib,pb,old,m,dm) in
          if k = 0 then (i,pa,ib,pb,m,F) else
            let (i,pa,ib,pb,m,c2) = word_gen_gc_move_loop conf (k-1)
                           (pa,i,pa,ib,pb,pbx,old,m,dm) in
              (i,pa,ib,pb,m,c1 /\ c2)
      else
        let (pbx,i,pa,ib,pb',m,c1) = word_gen_gc_move_refs conf (dimword (:'a))
                                   (pb,pbx,i,pa,ib,pb,old,m,dm) in
          if k = 0n then (i,pa,ib,pb,m,F) else
            let (i,pa,ib,pb,m,c2) = word_gen_gc_move_loop conf (k-1)
                           (pax,i,pa,ib,pb',pb,old,m,dm) in
              (i,pa,ib,pb,m,c1 /\ c2)`

val LENGTH_LESS_EQ_SUM_el_length = prove(
  ``!t. LENGTH t <= SUM (MAP el_length t)``,
  Induct \\ fs [] \\ Cases \\ fs [el_length_def]);

val word_gen_gc_move_loop_thm = Q.prove(
  `!k s m dm curr xs s1 pb1 pa1 m1 ib1 i1 frame c1.
    (gen_gc$gc_move_loop gen_conf s k = s1) /\ s1.ok /\
    heap_length s.heap <= dimword (:'a) DIV 2 ** shift_length conf /\
    heap_length s.heap * (dimindex (:'a) DIV 8) < dimword (:'a) /\
    conf.len_size + 2 < dimindex (:α) /\ s.r3 = [] /\ s.r2 = [] /\
    (!t r. (gen_conf.isRef (t,r) <=> t = RefTag)) /\
    conf.len_size + 5 <= dimindex (:'a) /\
    (word_gen_gc_move_loop conf k
       ((* pax *) p + bytes_in_word * n2w (heap_length s.h1),
        n2w s.a,
        (* pa *) p + bytes_in_word * n2w (heap_length (s.h1 ++ s.h2)),
        n2w (s.a+s.n),
        (* pb *) p + bytes_in_word * n2w (heap_length (s.h1 ++ s.h2) + s.n),
        (* pbx *) p + bytes_in_word * n2w (heap_length (s.h1 ++ s.h2 ++ s.r4) + s.n),
        curr:'a word,m,dm) =
      (i1,pa1,ib1,pb1,m1,c1)) /\ len_inv s /\
    (word_heap curr s.heap conf *
     word_heap_parts conf p s xs *
     frame) (fun2set (m,dm)) /\
    EVERY (is_Ref gen_conf.isRef) (s.r4 ++ s.r3 ++ s.r2 ++ s.r1) /\
    LENGTH xs = s.n /\ good_dimindex (:'a) ==>
    ?xs1.
      (word_heap curr s1.heap conf *
       word_heap_parts conf p s1 xs1 *
       frame) (fun2set (m1,dm)) /\
      s1.h2 = [] /\ s1.r4 = [] /\ s1.r3 = [] /\ s1.r2 = [] /\
      heap_length s1.heap = heap_length s.heap /\
      c1 /\ (i1 = n2w s1.a) /\ s1.n = LENGTH xs1 /\ len_inv s1 /\
      (ib1 = n2w (s1.a + s1.n)) /\
      EVERY (is_Ref gen_conf.isRef) s1.r1`,
  completeInduct_on `k` \\ rpt strip_tac
  \\ fs [PULL_FORALL,AND_IMP_INTRO,GSYM CONJ_ASSOC]
  \\ qpat_x_assum `gc_move_loop gen_conf s k = s1` mp_tac
  \\ once_rewrite_tac [gen_gcTheory.gc_move_loop_def]
  \\ TOP_CASE_TAC THEN1
   (TOP_CASE_TAC THEN1
     (rw [] \\ qexists_tac `xs` \\ fs []
      \\ pop_assum mp_tac \\ fs [Once word_gen_gc_move_loop_def]
      \\ rw [] \\ fs [])
    \\ strip_tac
    \\ `?s7. gen_gc$gc_move_data gen_conf s = s7` by fs [] \\ fs []
    \\ Cases_on `k = 0` \\ fs [] THEN1 (rveq \\ fs [])
    \\ drule word_gen_gc_move_data_thm
    \\ disch_then (qspecl_then [`dimword (:'a)`,`m`,`dm`,`curr`] mp_tac)
    \\ qpat_x_assum `word_gen_gc_move_loop conf k _ = _` mp_tac
    \\ once_rewrite_tac [word_gen_gc_move_loop_def] \\ fs []
    \\ IF_CASES_TAC THEN1
     (qsuff_tac `F` \\ fs [] \\ pop_assum mp_tac \\ fs []
      \\ fs [heap_length_APPEND,GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
      \\ rewrite_tac [addressTheory.WORD_EQ_ADD_CANCEL,GSYM WORD_ADD_ASSOC]
      \\ fs [heap_length_def,el_length_def]
      \\ fs [bytes_in_word_def,word_mul_n2w]
      \\ fs [RIGHT_ADD_DISTRIB]
      \\ qmatch_goalsub_abbrev_tac `nn MOD _`
      \\ qsuff_tac `nn < dimword (:α)`
      THEN1
       (fs [] \\ Cases_on `h` \\ fs [el_length_def]
        \\ fs [] \\ unabbrev_all_tac \\ rfs [good_dimindex_def]
        \\ rfs [dimword_def]
        \\ fs [len_inv_def,heap_length_def,el_length_def,SUM_APPEND] \\ rfs [])
      \\ fs [] \\ unabbrev_all_tac \\ rfs [good_dimindex_def]
      \\ rfs [dimword_def]
      \\ fs [len_inv_def,heap_length_def,el_length_def,SUM_APPEND] \\ rfs [])
    \\ rpt (pairarg_tac \\ fs [])
    \\ strip_tac \\ rveq
    \\ imp_res_tac gen_gcTheory.gc_move_loop_ok \\ fs []
    \\ strip_tac \\ SEP_F_TAC
    \\ impl_tac THEN1
     (fs [] \\ fs [el_length_def,heap_length_def]
      \\ fs [] \\ unabbrev_all_tac \\ rfs [good_dimindex_def]
      \\ rfs [dimword_def]
      \\ fs [len_inv_def,heap_length_def,el_length_def,SUM_APPEND] \\ rfs [])
    \\ strip_tac
    \\ qpat_x_assum `!m:num. _`
         (qspecl_then [`k-1`,`gc_move_data gen_conf s`,
                       `m'`,`dm`,`curr`,`xs1`] mp_tac) \\ fs []
    \\ rveq
    \\ fs [word_heap_APPEND,word_heap_def,word_el_def,
           heap_length_APPEND,word_payload_def,GSYM word_add_n2w,
           WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
    \\ strip_tac \\ SEP_F_TAC
    \\ impl_tac
    THEN1 (fs [] \\ rveq \\ fs [SIMP_RULE std_ss [] gc_move_data_const])
    \\ strip_tac
    \\ asm_exists_tac \\ fs [])
  \\ strip_tac
    \\ qmatch_asmsub_abbrev_tac `gc_move_refs gen_conf s2`
    \\ `?s7. gen_gc$gc_move_refs gen_conf s2 = s7` by fs [] \\ fs []
    \\ Cases_on `k = 0` \\ fs [] THEN1 (rveq \\ fs [])
    \\ drule word_gen_gc_move_refs_thm
    \\ disch_then (qspecl_then [`dimword (:'a)`,`m`,`dm`,`curr`,`xs`] mp_tac)
    \\ qpat_x_assum `word_gen_gc_move_loop conf k _ = _` mp_tac
    \\ once_rewrite_tac [word_gen_gc_move_loop_def] \\ fs []
    \\ IF_CASES_TAC THEN1
     (qsuff_tac `F` \\ fs [] \\ pop_assum mp_tac \\ fs []
      \\ fs [heap_length_APPEND,GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
      \\ rewrite_tac [addressTheory.WORD_EQ_ADD_CANCEL,GSYM WORD_ADD_ASSOC]
      \\ fs [heap_length_def,el_length_def]
      \\ fs [bytes_in_word_def,word_mul_n2w]
      \\ fs [RIGHT_ADD_DISTRIB]
      \\ qmatch_goalsub_abbrev_tac `nn MOD _`
      \\ qsuff_tac `nn < dimword (:α)`
      THEN1
       (fs [] \\ Cases_on `h` \\ fs [el_length_def]
        \\ fs [] \\ unabbrev_all_tac \\ rfs [good_dimindex_def]
        \\ rfs [dimword_def]
        \\ fs [len_inv_def,heap_length_def,el_length_def,SUM_APPEND] \\ rfs [])
      \\ fs [] \\ unabbrev_all_tac \\ rfs [good_dimindex_def]
      \\ rfs [dimword_def]
      \\ fs [len_inv_def,heap_length_def,el_length_def,SUM_APPEND] \\ rfs [])
    \\ rpt (pairarg_tac \\ fs [])
    \\ strip_tac \\ rveq
    \\ qunabbrev_tac `s2` \\ fs []
    \\ disch_then (qspec_then `frame` mp_tac)
    \\ impl_tac THEN1
     (imp_res_tac (SIMP_RULE std_ss [] gen_gcTheory.gc_move_loop_ok)
      \\ fs [word_heap_parts_def] \\ rfs []
      \\ fs [len_inv_def] \\ rfs []
      \\ fs [good_dimindex_def,dimword_def,heap_length_def,el_length_def,SUM_APPEND]
      \\ `LENGTH t <= SUM (MAP el_length t)` by fs [LENGTH_LESS_EQ_SUM_el_length]
      \\ rfs [] \\ fs [])
    \\ strip_tac \\ rveq
    \\ qpat_abbrev_tac `s6 = gc_move_refs gen_conf _`
    \\ qpat_x_assum `_ = s.n` (assume_tac o GSYM)
    \\ fs []
    \\ qpat_x_assum `!m:num. _`
         (qspecl_then [`k-1`,`s6`,`m'`,`dm`,`curr`,`xs1`] mp_tac) \\ fs []
    \\ rveq
    \\ fs [word_heap_APPEND,word_heap_def,word_el_def,
           heap_length_APPEND,word_payload_def,GSYM word_add_n2w,
           WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
    \\ qmatch_goalsub_abbrev_tac `word_gen_gc_move_loop conf _ input2 = _`
    \\ qmatch_asmsub_abbrev_tac `word_gen_gc_move_loop conf _ input1 = _`
    \\ qsuff_tac `input1 = input2`
    THEN1 (strip_tac \\ fs [])
    \\ rfs [] \\ unabbrev_all_tac
    \\ fs [SIMP_RULE std_ss [] gc_move_refs_const]
  \\ rewrite_tac [GSYM WORD_ADD_ASSOC,addressTheory.WORD_EQ_ADD_CANCEL]
  \\ fs [GSYM WORD_LEFT_ADD_DISTRIB,word_add_n2w]
  \\ AP_TERM_TAC \\ AP_TERM_TAC \\ fs []
  \\ qpat_abbrev_tac `n1 = SUM (MAP _ t)`
  \\ qpat_abbrev_tac `n2 = SUM (MAP _ s.h2)`
  \\ qpat_abbrev_tac `n3 = SUM (MAP _ s.h1)`
  \\ qpat_abbrev_tac `n6 = SUM (MAP _ _.h2)`
  \\ qpat_abbrev_tac `n7 = SUM (MAP _ _.r4)`
  \\ qpat_x_assum `LENGTH xs + n2 = _` (assume_tac o GSYM)
  \\ fs []);

val word_gen_gc_def = Define `
  word_gen_gc conf (roots,curr,new,len,m,dm) =
    let new_end = new + n2w len * bytes_in_word in
    let (roots,i,pa,ib,pb,m,c1) = word_gen_gc_move_roots conf
                    (roots,0w,new,n2w len,new_end,curr,m,dm) in
    let (i,pa,ib,pb,m,c2) = word_gen_gc_move_loop conf len
                                 (new,i,pa,ib,pb,new_end,curr,m,dm) in
      (roots,i,pa,ib,pb,m,c1 /\ c2)`

val word_gen_gc_thm = Q.prove(
  `!m dm curr s1 pb1 pa1 m1 ib1 i1 frame c1 roots heap roots1 roots1' new.
    (gen_gc$gen_gc gen_conf (roots,heap) = (roots1,s1)) /\ s1.ok /\
    heap_length heap <= dimword (:'a) DIV 2 ** shift_length conf /\
    heap_length heap * (dimindex (:'a) DIV 8) < dimword (:'a) /\
    conf.len_size + 2 < dimindex (:α) /\
    (!t r. (gen_conf.isRef (t,r) <=> t = RefTag)) /\
    conf.len_size + 5 <= dimindex (:'a) /\
    (word_gen_gc conf (MAP (word_addr conf) roots,curr,new,heap_length heap,m,dm) =
      (roots1',i1,pa1:'a word,ib1,pb1,m1,c1)) /\
    (word_heap curr heap conf *
     word_list_exists new (heap_length heap) *
     frame) (fun2set (m,dm)) /\ good_dimindex (:'a) ==>
    ?xs1.
      (word_heap curr s1.heap conf *
       word_heap_parts conf new s1 xs1 *
       frame) (fun2set (m1,dm)) /\
      s1.h2 = [] /\ s1.r4 = [] /\ s1.r3 = [] /\ s1.r2 = [] /\
      roots1' = MAP (word_addr conf) roots1 /\
      heap_length s1.heap = heap_length heap /\
      c1 /\ (i1 = n2w s1.a) /\ (ib1 = n2w (s1.a + s1.n)) /\
      s1.n = LENGTH xs1 /\ len_inv s1 /\
      EVERY (is_Ref gen_conf.isRef) s1.r1`,
  rpt gen_tac \\ once_rewrite_tac [gen_gcTheory.gen_gc_def]
  \\ fs [] \\ rpt (pairarg_tac \\ fs []) \\ strip_tac \\ fs []
  \\ drule (word_gen_gc_move_loop_thm |> Q.GEN `p`)
  \\ drule word_gen_gc_move_roots_thm
  \\ fs [empty_state_def]
  \\ fs [word_list_exists_def,SEP_CLAUSES,SEP_EXISTS_THM]
  \\ full_simp_tac (std_ss++sep_cond_ss) [cond_STAR]
  \\ strip_tac \\ SEP_F_TAC \\ fs []
  \\ `state'.ok` by (rveq \\ imp_res_tac gen_gcTheory.gc_move_loop_ok)
  \\ imp_res_tac gen_gcTheory.gc_move_list_ok \\ fs []
  \\ pop_assum kall_tac \\ pop_assum (assume_tac o GSYM) \\ fs []
  \\ qpat_x_assum `word_gen_gc conf _ = _` mp_tac
  \\ once_rewrite_tac [word_gen_gc_def] \\ fs []
  \\ rpt (pairarg_tac \\ fs []) \\ strip_tac \\ rveq
  \\ fs [] \\ strip_tac \\ rveq \\ fs []
  \\ qpat_abbrev_tac `s5 = gc_move_loop gen_conf state' _`
  \\ drule gc_move_list_const \\ strip_tac \\ fs []
  \\ simp [Once word_heap_parts_def]
  \\ fs [GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
  \\ disch_then (qspecl_then [`new`,`m'`,`dm`,`curr`] mp_tac)
  \\ fs [GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB,heap_length_APPEND]
  \\ strip_tac \\ SEP_F_TAC
  \\ impl_tac THEN1 fs [len_inv_def]
  \\ strip_tac \\ asm_exists_tac \\ fs []);

val gc_forward_ptr_APPEND = Q.prove(`
  !h1 n h2 a b ok.
  gc_forward_ptr n (h1 ++ h2) a b ok =
  if n < heap_length h1 then
    (λ(h,ok). (h++h2,ok)) (gc_forward_ptr n h1 a b ok)
  else
    (λ(h,ok). (h1++h,ok)) (gc_forward_ptr (n-heap_length h1) h2 a b ok)`,
  Induct
  >- fs[pairTheory.ELIM_UNCURRY]
  >> Cases >> rpt strip_tac >> fs[gc_forward_ptr_def]
  >> fs[el_length_def,heap_length_def]
  >> rw[] >> fs[]
  >> fs[pairTheory.ELIM_UNCURRY]);

val heap_split_APPEND = Q.store_thm("heap_split_APPEND",
  `heap_split (heap_length h1) (h1 ++ h2) = SOME(h1,h2)`,
  Induct_on `h1` >> fs[heap_split_def,heap_length_def]
  >- (Cases_on `h2` >> fs[heap_split_def]));

val heap_split_APPEND' = Q.store_thm("heap_split_APPEND'",
  `heap_split (SUM (MAP el_length h1)) (h1 ++ h2) = SOME(h1,h2)`,
  metis_tac[heap_split_APPEND,heap_length_def]);

val heap_drop_APPEND = Q.store_thm("heap_drop_APPEND",
  `heap_drop (heap_length h1) (h1 ++ h2) = h2`,
  rw[heap_drop_def,heap_split_APPEND]);

val heap_take_APPEND = Q.store_thm("heap_take_APPEND",
  `heap_take (heap_length h1) (h1 ++ h2) = h1`,
  rw[heap_take_def,heap_split_APPEND]);

val heap_drop_0 = Q.store_thm("heap_drop_0",
  `heap_drop 0 h = h`, Cases_on `h` >> fs[heap_drop_def,heap_split_def]);


val gc_forward_ptr_heap_split = Q.prove(
  `!h1 h2 n h3 l n' b ok ok1 heap a b'.
   (heap_lookup n (h1 ++ h2 ++ h3) = SOME (DataElement l n' b)) /\
   (gc_forward_ptr n (h1 ++ h2 ++ h3) a b' ok = (heap,ok1)) /\
   n >= heap_length h1 /\ n < heap_length(h1 ++ h2)
   ==> heap = h1 ++ heap_take (heap_length h2) (heap_drop (heap_length h1) heap) ++ h3`,
  rw[gc_forward_ptr_APPEND] >> ntac 2 (pairarg_tac >> fs[] >> rveq)
  >> drule gc_forward_ptr_heap_length >> strip_tac
  >> ASM_SIMP_TAC std_ss [heap_take_APPEND,heap_drop_APPEND,GSYM APPEND_ASSOC]);

val partial_gc_move_heap_split = Q.prove(
  `(gen_gc_partial$gc_move conf s x = (x1,s1)) 
   /\ heap_segment (conf.gen_start,conf.refs_start) s.heap = SOME (h1,h2,h3)
   /\ conf.gen_start <= conf.refs_start                                                             
   ==> s1.heap = h1 ++ heap_take (heap_length h2) (heap_drop (heap_length h1) s1.heap) ++ h3`,
  Cases_on `x` >> rw[gen_gc_partialTheory.gc_move_def]
  >> fs[]
  >> drule heap_segment_IMP >> strip_tac
  >> fs[] >> rfs[]
  >> qpat_x_assum `_ = s.heap` (assume_tac o GSYM)
  >> qpat_x_assum `_ = conf.gen_start` (assume_tac o GSYM)
  >> fs[]
  >> SIMP_TAC std_ss [GSYM APPEND_ASSOC,heap_take_APPEND,heap_drop_APPEND]
  >> every_case_tac >> fs[] >> rveq >> fs[]
  >> SIMP_TAC std_ss [GSYM APPEND_ASSOC,heap_take_APPEND,heap_drop_APPEND]
  >> pairarg_tac >> fs[] >> rveq >> fs[]
  >> drule gc_forward_ptr_heap_split >> disch_then drule >> fs[]);

val partial_gc_move_list_heap_split = Q.prove(
  `!x conf s x1 s1 h1 h2 h3.
   (gen_gc_partial$gc_move_list conf s x = (x1,s1)) 
   /\ heap_segment (conf.gen_start,conf.refs_start) s.heap = SOME (h1,h2,h3)
   /\ conf.gen_start <= conf.refs_start                                                             
   ==> s1.heap = h1 ++ heap_take (heap_length h2) (heap_drop (heap_length h1) s1.heap) ++ h3`,
  Induct >> rpt strip_tac >> fs[gen_gc_partialTheory.gc_move_list_def]
  >> drule heap_segment_IMP >> disch_then drule >> strip_tac
  >> rveq >> fs[]
  >> qpat_x_assum `_ = s.heap` (assume_tac o GSYM)
  >> qpat_x_assum `_ = conf.gen_start` (assume_tac o GSYM)
  >> qpat_x_assum `_ = conf.refs_start` (assume_tac o GSYM)  
  >- ASM_SIMP_TAC std_ss [heap_take_APPEND,heap_drop_APPEND,GSYM APPEND_ASSOC]
  >> ntac 2 (pairarg_tac >> fs[])
  >> drule partial_gc_move_heap_split >> fs[] >> strip_tac >> rveq >> fs[]
  >> drule gen_gc_partialTheory.gc_move_heap_length >> strip_tac
  >> rfs[] >> fs[]
  >> `heap_segment (conf.gen_start,conf.refs_start) (state'.heap)
      = SOME (h1,heap_take (heap_length h2) (heap_drop (heap_length h1) state'.heap),h3)`
       by(pop_assum mp_tac
          >> qpat_x_assum `state'.heap = _` (fn asm => PURE_ONCE_REWRITE_TAC[asm])
          >> fs[heap_length_APPEND]
          >> disch_then assume_tac
          >> fs[heap_length_APPEND]
          >> SIMP_TAC std_ss [heap_segment_def,heap_length_APPEND,heap_split_APPEND,GSYM APPEND_ASSOC]
          >> fs[]
          >> pop_assum (fn thm => rw[Once thm] >> assume_tac thm)
          >> fs[heap_split_APPEND,heap_drop_APPEND]
          >> SIMP_TAC std_ss [heap_drop_APPEND,GSYM APPEND_ASSOC]
          >> metis_tac[heap_take_APPEND])
  >> first_x_assum drule
  >> fs[]     
  >> disch_then (fn thm => rw[Once thm])
  >> qpat_x_assum `heap_length _ = heap_length _` mp_tac
  >> qpat_x_assum `state'.heap = _` (fn asm => PURE_ONCE_REWRITE_TAC[asm])
  >> fs[heap_length_APPEND]
  >> disch_then (fn thm => rw[Once thm] >> assume_tac thm)
  >> SIMP_TAC std_ss [GSYM APPEND_ASSOC,heap_drop_APPEND,heap_take_APPEND]
  >> pop_assum (fn thm => fs[GSYM thm]));

val word_gen_gc_partial_move_thm = Q.prove(
  `(gen_gc_partial$gc_move gc_conf gcstate x = (x1,gcstate1)) /\
    gcstate.h2 = [] /\ gcstate.r4 = [] /\ gcstate1.ok /\
    gc_conf.limit = heap_length gcstate.heap /\
    good_dimindex (:α) /\
    heap_length gcstate.heap <= dimword (:'a) DIV 2 ** shift_length conf /\
    gc_conf.gen_start <= gc_conf.refs_start /\
    gc_conf.refs_start <= heap_length gcstate.heap /\
    (heap_segment (gc_conf.gen_start,gc_conf.refs_start) gcstate.heap = SOME(old,current,refs)) /\
    w2n curr + heap_length gcstate.heap * (dimindex (:α) DIV 8) < dimword (:α) /\
    (word_heap (curr + bytes_in_word * n2w(heap_length old)) current conf * word_list pa xs * frame) (fun2set (m,dm)) /\
    (!t r. (gc_conf.isRef (t,r) <=> t = RefTag)) /\
    (word_gen_gc_partial_move conf (word_addr conf x,n2w gcstate.a,pa,curr,m,dm,
                                    curr + bytes_in_word * n2w gc_conf.gen_start,
                                    curr + bytes_in_word * n2w gc_conf.refs_start) =
      (w:'a word_loc,i1,pa1,m1,c1)) /\
    LENGTH xs = gcstate.n ==>
    ?xs1 current1.
      (word_heap (curr+ bytes_in_word * n2w(heap_length old)) current1 conf *
       word_heap pa gcstate1.h2 conf *
       word_list pa1 xs1 * frame) (fun2set (m1,dm)) /\
      (w = word_addr conf x1) /\
      heap_length gcstate1.heap = heap_length gcstate.heap /\
      (heap_segment (gc_conf.gen_start,gc_conf.refs_start) gcstate1.heap = SOME(old,current1,refs)) /\
      c1 /\ (i1 = n2w gcstate1.a) /\ gcstate1.n = LENGTH xs1 /\
      gcstate.n = heap_length gcstate1.h2 + gcstate1.n + heap_length gcstate1.r4 /\
      pa1 = pa + bytes_in_word * n2w (heap_length gcstate1.h2)`,
  reverse (Cases_on `x`) \\
  full_simp_tac(srw_ss())[gc_move_def]
  THEN1
   (srw_tac[][] \\ full_simp_tac(srw_ss())[word_heap_def,SEP_CLAUSES]
    \\ Cases_on `a` \\ full_simp_tac(srw_ss())[word_addr_def,word_gen_gc_partial_move_def]
    \\ qexists_tac `xs` \\ full_simp_tac(srw_ss())[heap_length_def])
  \\ rpt strip_tac
  \\ `n < heap_length gcstate.heap`
       by(every_case_tac >> fs[]
          >> qpat_x_assum `(x with ok := y) = z` (assume_tac o GSYM)
          >> fs[])
  \\ `curr + bytes_in_word * n2w n <₊ curr + bytes_in_word * n2w gc_conf.gen_start
       <=> n < gc_conf.gen_start` by
    (Cases_on `curr` \\ fs[bytes_in_word_def,word_add_n2w,word_mul_n2w,WORD_LO]
     \\ `n' + n * (dimindex (:α) DIV 8) <
         n' + heap_length gcstate.heap * (dimindex (:α) DIV 8)`
          by fs[good_dimindex_def]
     \\ `n' + gc_conf.gen_start * (dimindex (:α) DIV 8) <=
         n' + heap_length gcstate.heap * (dimindex (:α) DIV 8)`
          by fs[good_dimindex_def]
     \\ rw[LESS_MOD] \\ fs[good_dimindex_def])
  \\ `curr + bytes_in_word * n2w gc_conf.refs_start ≤₊ curr + bytes_in_word * n2w n
      <=> gc_conf.refs_start <= n` by
     (Cases_on `curr`
      \\ fs[bytes_in_word_def,word_add_n2w,word_mul_n2w,WORD_NOT_LOWER_EQUAL,WORD_LO]
      \\ `n' + n * (dimindex (:α) DIV 8) <
          n' + heap_length gcstate.heap * (dimindex (:α) DIV 8)`
           by fs[good_dimindex_def]
      \\ `n' + gc_conf.refs_start * (dimindex (:α) DIV 8) <=
          n' + heap_length gcstate.heap * (dimindex (:α) DIV 8)`
           by fs[good_dimindex_def]
      \\ rw[LESS_MOD]  \\ fs[good_dimindex_def] \\ rfs[] \\ fs[WORD_LS])
  \\ rpt (pop_assum MP_TAC)
  \\ PURE_ONCE_REWRITE_TAC [LET_THM] \\ BETA_TAC
  \\ IF_CASES_TAC THEN1
    (srw_tac[][]
     \\ full_simp_tac(srw_ss())[word_heap_def,SEP_CLAUSES]
     \\ full_simp_tac(srw_ss())[word_addr_def,word_gen_gc_partial_move_def,get_addr_and_1_not_0]
     \\ drule(GEN_ALL LE_DIV_LT_IMP)
     \\ disch_then drule
     \\ rpt strip_tac
     \\ fs [ptr_to_addr_get_addr]
     \\ rpt strip_tac
     \\ qexists_tac `xs`
     \\ fs[word_heap_def,heap_length_def,SEP_CLAUSES,word_addr_def])
  \\ CASE_TAC \\ fs []
  \\ strip_tac \\ rveq \\ fs []
  \\ rename1 `heap_lookup k s.heap = SOME x`
  \\ Cases_on `x` \\ fs[] \\ srw_tac[][] \\ fs[word_addr_def]
  \\ drule heap_segment_IMP \\ fs[] \\ disch_then (assume_tac o GSYM)
  \\ fs[heap_lookup_APPEND,heap_length_APPEND] \\ rfs[heap_lookup_APPEND,heap_length_APPEND]
  \\ qpat_x_assum `word_gen_gc_partial_move conf _ = _` mp_tac
  \\ full_simp_tac std_ss [word_gen_gc_partial_move_def,get_addr_and_1_not_0]
  \\ fs[get_addr_and_1_not_0]
  \\ imp_res_tac heap_lookup_LESS
  \\ drule LE_DIV_LT_IMP
  \\ impl_tac \\ fs[]
  \\ asm_rewrite_tac [] \\ strip_tac
  \\ asm_simp_tac std_ss [ptr_to_addr_get_addr]
  \\ imp_res_tac heap_lookup_SPLIT
  \\ full_simp_tac std_ss [word_heap_def,SEP_CLAUSES] \\ rveq
  \\ full_simp_tac std_ss [word_heap_APPEND,word_heap_def,word_el_def,
       AC WORD_MULT_ASSOC WORD_MULT_COMM]
  \\ `small_shift_length conf <= shift_length conf /\
      small_shift_length conf <> 0` by (EVAL_TAC \\ fs [] \\ NO_TAC)
  \\ qpat_x_assum `k − heap_length old = heap_length ha` (assume_tac o GSYM)
  \\ fs[heap_length_APPEND]
  \\ full_simp_tac std_ss [AC WORD_ADD_ASSOC WORD_ADD_COMM, GSYM WORD_LEFT_ADD_DISTRIB,
                           word_add_n2w,SUB_LEFT_ADD]
  \\ `(if k ≤ heap_length old then heap_length old else k) = k`
      by rw[]
  \\ fs[]
  THEN1
   (helperLib.SEP_R_TAC
    \\ full_simp_tac(srw_ss())[LET_THM,theWord_def,is_fws_ptr_OR_3]
    \\ rw [] \\ qexists_tac `xs` \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[update_addr_def,shift_to_zero]
    \\ `2 <= shift_length conf` by (fs[shift_length_def] \\ decide_tac)
    \\ full_simp_tac(srw_ss())[shift_around_under_big_shift]
    \\ full_simp_tac(srw_ss())[get_addr_def,select_shift_out]
    \\ full_simp_tac(srw_ss())[select_get_lowerbits,heap_length_def,isWord_def]
    \\ fs[]
   )
  \\ rename1 `_ = SOME (DataElement addrs ll tt)`
  \\ PairCases_on `tt`
  \\ full_simp_tac(srw_ss())[word_el_def]
  \\ `?h ts c5. word_payload addrs ll tt0 tt1 conf =
         (h:'a word,ts,c5)` by METIS_TAC [PAIR]
  \\ full_simp_tac(srw_ss())[LET_THM] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac bool_ss [word_list_def]
  \\ SEP_R_TAC
  \\ full_simp_tac bool_ss [GSYM word_list_def,isWord_def]
  \\ full_simp_tac std_ss [GSYM WORD_OR_ASSOC,is_fws_ptr_OR_3,isWord_def,theWord_def]
  \\ full_simp_tac (std_ss++sep_cond_ss) [cond_STAR,SEP_CLAUSES]
  \\ `~is_fwd_ptr (Word h)` by (imp_res_tac NOT_is_fwd_ptr \\ fs [])
  \\ asm_rewrite_tac []
  \\ drule is_ref_header_thm
  \\ asm_simp_tac std_ss []
  \\ disch_then kall_tac
  \\ reverse (Cases_on `tt0 = RefTag`) \\ fs []  
  THEN1
   (pairarg_tac \\ full_simp_tac(srw_ss())[]
    \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
    \\ `n2w (LENGTH ts) + 1w = n2w (LENGTH (Word h::ts)):'a word` by
          full_simp_tac(srw_ss())[LENGTH,ADD1,word_add_n2w]
    \\ full_simp_tac bool_ss []
    \\ drule memcpy_thm
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
    \\ full_simp_tac(srw_ss())[gc_forward_ptr_thm] \\ rev_full_simp_tac(srw_ss())[]
    \\ rpt var_eq_tac
    \\ full_simp_tac(srw_ss())[heap_length_def,el_length_def]
    \\ full_simp_tac(srw_ss())[GSYM heap_length_def]
    \\ imp_res_tac word_payload_IMP
    \\ rpt var_eq_tac
    \\ qpat_x_assum `LENGTH xs = s.n` (assume_tac o GSYM)
    \\ fs []
    \\ drule gc_forward_ptr_ok
    \\ fs[] \\ strip_tac    
    \\ drule LESS_EQ_IMP_APPEND \\ strip_tac
    \\ full_simp_tac(srw_ss())[] \\ rpt var_eq_tac
    \\ full_simp_tac(srw_ss())[word_list_APPEND]
    \\ disch_then (qspec_then `ys` assume_tac)
    \\ SEP_F_TAC
    \\ impl_tac THEN1
     (full_simp_tac(srw_ss())[ADD1,SUM_APPEND,X_LE_DIV,RIGHT_ADD_DISTRIB]
      \\ Cases_on `2 ** shift_length conf` \\ full_simp_tac(srw_ss())[]
      \\ Cases_on `n` \\ full_simp_tac(srw_ss())[MULT_CLAUSES]
      \\ Cases_on `n'` \\ full_simp_tac(srw_ss())[MULT_CLAUSES] \\ decide_tac)
    \\ rpt strip_tac
    \\ full_simp_tac(srw_ss())[word_addr_def,word_add_n2w,ADD_ASSOC] \\ srw_tac[][]
    \\ full_simp_tac(srw_ss())[word_heap_APPEND,word_heap_def,
         SEP_CLAUSES,word_el_def,LET_THM]
    \\ full_simp_tac(srw_ss())[word_list_def]
    \\ SEP_W_TAC
    \\ qpat_x_assum `heap_length _ = _ − heap_length _` (assume_tac o GSYM)
    \\ fs[] \\ `k  = heap_length ha + heap_length old` by fs[] \\ rveq \\ fs[]
    \\ `(if heap_length ha + heap_length old ≤ heap_length old then
                LENGTH ts + 1
        else LENGTH ts + (heap_length ha + 1)) = LENGTH ts + (heap_length ha + 1)`
         by (Cases_on `heap_length ha` >> fs[])
    \\ pop_assum (fn thm => fs[thm])
    \\ `gc_forward_ptr (heap_length(old ++ ha))
         ((old ++ ha) ++
          DataElement addrs (LENGTH ts) (tt0,tt1)::(hb ++ refs)) s.a a
         T = ((old ++ ha) ++ ForwardPointer s.a a (LENGTH ts)::(hb++refs),T)`
        by(metis_tac[gc_forward_ptr_thm])
    \\ fs[heap_length_APPEND]
    \\ qexists_tac `zs` \\ qexists_tac `ha++ForwardPointer s.a a (LENGTH ts)::hb` \\ full_simp_tac(srw_ss())[] \\ rveq \\ fs[]
    \\ reverse conj_tac THEN1
     (full_simp_tac(srw_ss())[update_addr_def,get_addr_def,
         select_shift_out,select_get_lowerbits,ADD1]
      \\ fs [GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB,heap_length_APPEND]
      \\ rewrite_tac [GSYM APPEND_ASSOC,APPEND]
      \\ fs[heap_length_def,SUM_APPEND,el_length_def]
      \\ fs[heap_segment_def]
      \\ full_simp_tac std_ss [heap_split_APPEND', GSYM APPEND_ASSOC]
      \\ fs[]
      \\ SIMP_TAC std_ss [GSYM APPEND_ASSOC_CONS]
      \\ `heap_length(ha ++ ForwardPointer s.a a (LENGTH ts)::hb) =
           LENGTH ts + (SUM (MAP el_length ha) + (SUM (MAP el_length hb) +
           (SUM (MAP el_length old) + 1))) − heap_length old`
           by fs[heap_length_def,SUM_APPEND,el_length_def]
      \\ pop_assum (fn asm => rw[GSYM asm])
      \\ fs[heap_split_APPEND])
    \\ fs[word_heap_def,word_heap_APPEND]
    \\ full_simp_tac(srw_ss())[AC STAR_ASSOC STAR_COMM,SEP_CLAUSES]
    \\ fs [GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
    \\ fs[word_el_def,word_list_exists_def,SEP_CLAUSES,SEP_EXISTS_THM,el_length_def]
    \\ qexists_tac `ts`
    \\ full_simp_tac(srw_ss())[AC STAR_ASSOC STAR_COMM,SEP_CLAUSES,GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB,heap_length_def,ADD1])
  THEN1
   (rveq
    \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
    \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
    \\ rveq \\ rfs[]
    \\ metis_tac[gc_forward_ptr_ok]));

val gc_partial_move_ok_irr = prove(
  ``!x s y1 y2 t1 t2 h2 r4.
      gen_gc_partial$gc_move gen_conf s x = (y1,t1) /\
      gen_gc_partial$gc_move gen_conf (s with <| h2 := h2 ; r4 := r4 |>) x = (y2,t2) ==>
      y1 = y2 /\ ?x1 x2. t2 = t1 with <| h2 := x1 ; r4 := x2 |>``,
  Cases \\ fs [gen_gc_partialTheory.gc_move_def] \\ rw []
  \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ every_case_tac \\ fs []
  \\ rpt (pairarg_tac \\ fs []) \\ rveq \\ fs []);

val gc_partial_move_ok_before = Q.store_thm("gc_partial_move_ok_before",
  `gen_gc_partial$gc_move gen_conf s x = (x1,s1) /\ s1.ok ==> s.ok`,
  Induct_on `x` >> rw[gen_gc_partialTheory.gc_move_def]
  >> fs[] >> every_case_tac >> fs[]
  >- (qpat_x_assum `s with ok := F = s1` (assume_tac o GSYM)
      >> fs[])
  >- (qpat_x_assum `s with ok := F = s1` (assume_tac o GSYM)
      >> fs[])
  >> pairarg_tac >> fs[]
  >> qpat_x_assum `_ = s1` (assume_tac o GSYM) >> fs[]
  >> `((s.ok ∧ n < heap_length s.heap) ∧ n' + 1 ≤ s.n ∧
        ¬gen_conf.isRef b)` by (match_mp_tac (GEN_ALL gc_forward_ptr_ok))
  >> qexists_tac `a` >> qexists_tac `s.heap`
  >> qexists_tac `n` >> qexists_tac `s.a` >> qexists_tac `heap`
  >> fs[]);
  
val gc_partial_move_list_ok_before = Q.store_thm("gc_partial_move_list_ok_before",
  `!x s x1 s1. gen_gc_partial$gc_move_list gen_conf s x = (x1,s1) /\ s1.ok ==> s.ok`,
  Induct_on `x` >> fs[gc_move_list_def] >> rpt strip_tac
  >> ntac 2 (pairarg_tac >> fs[]) >> metis_tac[gc_partial_move_ok_before]);

val gc_partial_move_ref_list_ok_before = Q.store_thm("gc_partial_move_ref_list_ok_before",
  `!x s x1 s1. gen_gc_partial$gc_move_ref_list gen_conf s x = (x1,s1) /\ s1.ok ==> s.ok`,
  Induct >> Cases >> fs[gc_move_ref_list_def] >> rpt strip_tac
  >> ntac 2 (pairarg_tac >> fs[]) >> metis_tac[gc_partial_move_list_ok_before]);

val gc_partial_move_data_ok_before = Q.store_thm("gc_partial_move_data_ok_before",
  `!gen_conf s s1. gen_gc_partial$gc_move_data gen_conf s = s1 /\ s1.ok ==> s.ok`,
  recInduct (fetch "gen_gc_partial" "gc_move_data_ind")
  \\ rw[] \\ pop_assum mp_tac \\ once_rewrite_tac [gc_move_data_def]
  \\ rpt (CASE_TAC \\ simp_tac (srw_ss()) [LET_THM])
  \\ pairarg_tac \\ fs [] \\ strip_tac \\ res_tac
  \\ imp_res_tac gc_partial_move_list_ok_before)

val gc_partial_move_list_ok_irr = prove(
  ``!x s y1 y2 t1 t2 h2 r4.
      gen_gc_partial$gc_move_list gen_conf s x = (y1,t1) /\ t1.ok /\
      gen_gc_partial$gc_move_list gen_conf (s with <| h2 := h2 ; r4 := r4 |>) x = (y2,t2)
      ==>
      t2.ok``,
  Induct \\ fs [gen_gc_partialTheory.gc_move_list_def]
  \\ rw [] \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ rpt (pairarg_tac \\ fs []) \\ rveq \\ fs []
  \\ drule gc_move_heap_length
  \\ drule gc_move_list_heap_length
  \\ `heap_length((s with <|h2 := h2; r4 := r4|>).heap) = heap_length state'.heap` by metis_tac[gc_move_heap_length]
  \\ `heap_length state'.heap = heap_length state''.heap` by metis_tac[gc_move_list_heap_length]
  \\ rpt DISCH_TAC
  \\ fs[]
  \\ imp_res_tac gc_partial_move_list_ok_before
  \\ first_x_assum match_mp_tac
  \\ once_rewrite_tac [CONJ_COMM]
  \\ qpat_x_assum `_.ok` kall_tac
  \\ asm_exists_tac \\ fs []
  \\ once_rewrite_tac [CONJ_COMM]
  \\ asm_exists_tac \\ fs []
  \\ metis_tac [gc_partial_move_ok_irr]);

val gc_partial_move_list_ok_irr' = prove(
  ``!x s y1 y2 t1 t2 h2 r4.
      gen_gc_partial$gc_move_list gen_conf s x = (y1,t1) /\
      gen_gc_partial$gc_move_list gen_conf (s with <| h2 := h2 ; r4 := r4 |>) x = (y2,t2) ==>
      y1 = y2 /\ ?x1 x2. t2 = t1 with <| h2 := x1 ; r4 := x2 |>``,
  Induct \\ fs [gen_gc_partialTheory.gc_move_list_def] \\ rw []
  \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ rpt (pairarg_tac \\ fs []) \\ rveq \\ fs []
  \\ drule gc_partial_move_ok_irr \\ disch_then drule
  \\ DISCH_TAC \\ fs[] \\ fs[]
  \\ first_x_assum drule \\ disch_then drule \\ fs[]);

val gc_partial_move_ref_list_ok_irr = prove(
  ``!x s y1 y2 t1 t2 h2 r4.
      gen_gc_partial$gc_move_ref_list gen_conf s x = (y1,t1) /\ t1.ok /\
      gen_gc_partial$gc_move_ref_list gen_conf (s with <| h2 := h2 ; r4 := r4 |>) x = (y2,t2)
      ==>
      t2.ok``,
  Induct \\ Cases \\ fs [gen_gc_partialTheory.gc_move_ref_list_def]
  \\ rw [] \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ rpt (pairarg_tac \\ fs []) \\ rveq \\ fs []
  \\ drule gc_move_list_heap_length
  \\ drule gc_move_ref_list_heap_length
  \\ `heap_length((s with <|h2 := h2; r4 := r4|>).heap) = heap_length state'.heap` by metis_tac[gc_move_list_heap_length]
  \\ `heap_length state'.heap = heap_length state''.heap` by metis_tac[gc_move_ref_list_heap_length]
  \\ rpt DISCH_TAC
  \\ fs[]
  \\ imp_res_tac gc_partial_move_ref_list_ok_before
  \\ first_x_assum match_mp_tac
  \\ once_rewrite_tac [CONJ_COMM]
  \\ qpat_x_assum `_.ok` kall_tac
  \\ asm_exists_tac \\ fs []
  \\ once_rewrite_tac [CONJ_COMM]
  \\ asm_exists_tac \\ fs []
  \\ metis_tac [gc_partial_move_list_ok_irr']);

val gc_partial_move_with_NIL = store_thm("gc_partial_move_with_NIL",
  ``!x s y t.
      gen_gc_partial$gc_move gen_conf s x = (y,t) /\ t.ok ==>
      (let (y,s1) = gc_move gen_conf (s with <| h2 := []; r4 := [] |>) x in
        (y,s1 with <| h2 := s.h2 ++ s1.h2; r4 := s1.r4 ++ s.r4 |>)) = (y,t)``,
  Cases \\ fs [gen_gc_partialTheory.gc_move_def] \\ rw []
  \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ CASE_TAC \\ fs []
  \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ CASE_TAC \\ fs []
  \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ rpt (pairarg_tac \\ fs []) \\ rveq \\ fs []
  \\ fs [gc_sharedTheory.gc_state_component_equality]);

val gc_partial_move_with_NIL_LEMMA = store_thm("gc_partial_move_with_NIL_LEMMA",
  ``!x s y t h2 r4 y1 t1.
      gen_gc_partial$gc_move gen_conf s x = (y1,t1) /\ t1.ok ==>
      ?x1 x2.
        t1.h2 = s.h2 ++ x1 /\
        t1.r4 = x2 ++ s.r4 /\
        gen_gc_partial$gc_move gen_conf (s with <| h2 := []; r4 := [] |>) x =
          (y1,t1 with <| h2 := x1; r4 := x2 |>)``,
  Cases \\ fs [gen_gc_partialTheory.gc_move_def] \\ rw []
  \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ CASE_TAC
  \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ CASE_TAC
  \\ fs [gc_sharedTheory.gc_state_component_equality]
  \\ rpt (pairarg_tac \\ fs []) \\ rveq \\ fs []);

val gc_partial_move_list_with_NIL_LEMMA = store_thm("gc_move_list_with_NIL_LEMMA",
  ``!x s y t h2 r4 y1 t1.
      gen_gc_partial$gc_move_list gen_conf s x = (y1,t1) /\ t1.ok ==>
      ?x1 x2.
        t1.h2 = s.h2 ++ x1 /\
        t1.r4 = x2 ++ s.r4 /\
        gen_gc_partial$gc_move_list gen_conf (s with <| h2 := []; r4 := [] |>) x =
          (y1,t1 with <| h2 := x1; r4 := x2 |>)``,
  Induct \\ fs [gen_gc_partialTheory.gc_move_list_def] \\ rw []
  \\ rpt (pairarg_tac \\ fs []) \\ rveq \\ fs []
  \\ rename1 `gc_move gen_conf s h = (x3,state3)`
  \\ rename1 `_ = (x4,state4)`
  \\ `state3.ok` by imp_res_tac gc_partial_move_list_ok_before
  \\ drule (SIMP_RULE std_ss [] gc_partial_move_with_NIL_LEMMA) \\ fs []
  \\ strip_tac \\ fs [] \\ rveq
  \\ first_assum drule \\ asm_rewrite_tac []
  \\ `state''.ok` by imp_res_tac gc_partial_move_list_ok_irr
  \\ qpat_x_assum `gc_move_list gen_conf state3 x = _` kall_tac
  \\ first_x_assum drule \\ asm_rewrite_tac []
  \\ fs [] \\ rw [] \\ fs []
  \\ fs [gc_sharedTheory.gc_state_component_equality]) |> SIMP_RULE std_ss [];

val gc_partial_move_list_with_NIL = Q.store_thm("gc_partial_move_list_with_NIL",
  `!x s y t.
      gen_gc_partial$gc_move_list gen_conf s x = (y,t) /\ t.ok ==>
      (let (y,s1) = gen_gc_partial$gc_move_list gen_conf (s with <| h2 := []; r4 := [] |>) x in
       (y,s1 with <| h2 := s.h2 ++ s1.h2; r4 := s1.r4 ++ s.r4 |>)) = (y,t)`,
  rw [] \\ drule gc_partial_move_list_with_NIL_LEMMA \\ fs []
  \\ strip_tac \\ fs [] \\ fs [gc_sharedTheory.gc_state_component_equality]);

val gc_partial_move_ref_list_with_NIL_LEMMA = store_thm("gc_move_ref_list_with_NIL_LEMMA",
  ``!x s y t h2 r4 y1 t1.
      gen_gc_partial$gc_move_ref_list gen_conf s x = (y1,t1) /\ t1.ok ==>
      ?x1 x2.
        t1.h2 = s.h2 ++ x1 /\
        t1.r4 = x2 ++ s.r4 /\
        gen_gc_partial$gc_move_ref_list gen_conf (s with <| h2 := []; r4 := [] |>) x =
          (y1,t1 with <| h2 := x1; r4 := x2 |>)``,
  Induct THEN1 fs [gen_gc_partialTheory.gc_move_ref_list_def]
  \\ Cases
  \\ fs [gen_gc_partialTheory.gc_move_ref_list_def] \\ rw []
  \\ rpt (pairarg_tac \\ fs []) \\ rveq \\ fs []
  \\ rename1 `gc_move_list gen_conf s h = (x3,state3)`
  \\ rename1 `_ = (x4,state4)`
  \\ `state3.ok` by imp_res_tac gc_partial_move_ref_list_ok_before
  \\ drule (SIMP_RULE std_ss [] gc_partial_move_list_with_NIL_LEMMA) \\ fs []
  \\ strip_tac \\ fs [] \\ rveq
  \\ first_assum drule \\ asm_rewrite_tac []
  \\ `state''.ok` by imp_res_tac gc_partial_move_ref_list_ok_irr
  \\ qpat_x_assum `gc_move_ref_list gen_conf state3 x = _` kall_tac
  \\ first_x_assum drule \\ asm_rewrite_tac []
  \\ fs [] \\ rw [] \\ fs []
  \\ fs [gc_sharedTheory.gc_state_component_equality]) |> SIMP_RULE std_ss [];

val gc_partial_move_ref_list_with_NIL = Q.store_thm("gc_partial_move_ref_list_with_NIL",
  `!x s y t.
      gen_gc_partial$gc_move_ref_list gen_conf s x = (y,t) /\ t.ok ==>
      (let (y,s1) = gen_gc_partial$gc_move_ref_list gen_conf (s with <| h2 := []; r4 := [] |>) x in
       (y,s1 with <| h2 := s.h2 ++ s1.h2; r4 := s1.r4 ++ s.r4 |>)) = (y,t)`,
  rw [] \\ drule gc_partial_move_ref_list_with_NIL_LEMMA \\ fs []
  \\ strip_tac \\ fs [] \\ fs [gc_sharedTheory.gc_state_component_equality]);

val word_gen_gc_partial_move_roots_thm = Q.prove(
  `!x xs x1 w s1 s pa1 pa m1 m i1 frame dm curr c1 old current refs.
    (gen_gc_partial$gc_move_list gen_conf s x = (x1,s1)) /\ s1.ok /\ s.h2 = [] /\ s.r4 = [] /\
    gen_conf.limit = heap_length s.heap /\
    heap_length s.heap <= dimword (:'a) DIV 2 ** shift_length conf /\
    gen_conf.gen_start <= gen_conf.refs_start /\  
    gen_conf.refs_start <= heap_length s.heap /\
    (heap_segment (gen_conf.gen_start,gen_conf.refs_start) s.heap = SOME(old,current,refs)) /\
    (!t r. (gen_conf.isRef (t,r) <=> t = RefTag)) /\
    w2n curr + heap_length s.heap * (dimindex (:α) DIV 8) < dimword (:α) /\
    (word_heap (curr + bytes_in_word * n2w(heap_length old)) current conf * word_list pa xs * frame) (fun2set (m,dm)) /\
    (word_gen_gc_partial_move_roots conf (MAP (word_addr conf) x,n2w s.a,pa,
                                         curr:'a word,m,dm,
                                         curr + bytes_in_word * n2w gen_conf.gen_start,
                                         curr + bytes_in_word * n2w gen_conf.refs_start) =
      (w:'a word_loc list,i1,pa1,m1,c1)) /\
    LENGTH xs = s.n /\ good_dimindex (:'a) /\ LENGTH x < dimword (:'a) ==>
    ?xs1 current1.
      (word_heap (curr + bytes_in_word * n2w(heap_length old)) current1 conf *
       word_heap pa s1.h2 conf *
       word_list pa1 xs1 * frame) (fun2set (m1,dm)) /\
      (w = MAP (word_addr conf) x1) /\
      heap_length s1.heap = heap_length s.heap /\
      (heap_segment (gen_conf.gen_start,gen_conf.refs_start) s1.heap = SOME(old,current1,refs)) /\
      c1 /\ (i1 = n2w s1.a) /\ s1.n = LENGTH xs1 /\
      s.n = heap_length s1.h2 + s1.n + heap_length s1.r4 /\
      pa1 = pa + bytes_in_word * n2w (heap_length s1.h2)`,
  Induct
  THEN1
   (fs [gen_gc_partialTheory.gc_move_list_def,Once word_gen_gc_partial_move_roots_def] \\ rw []
    \\ fs [word_heap_def,SEP_CLAUSES] \\ asm_exists_tac \\ fs [])
  \\ fs [gen_gc_partialTheory.gc_move_list_def]
  \\ once_rewrite_tac [word_gen_gc_partial_move_roots_def]
  \\ rpt strip_tac \\ fs []
  \\ rw [] \\ ntac 4 (pairarg_tac \\ fs []) \\ rveq
  \\ fs [ADD1,GSYM word_add_n2w,word_list_def]
  \\ ntac 4 (pop_assum mp_tac) \\ fs []
  \\ rpt strip_tac
  \\ drule (GEN_ALL word_gen_gc_partial_move_thm) \\ fs []
  \\ drule gc_move_heap_length \\ DISCH_TAC \\ fs[]
  \\ drule gc_move_list_heap_length \\ DISCH_TAC \\ fs[]
  \\ `state'.ok` by imp_res_tac gc_partial_move_list_ok_before
  \\ fs [GSYM STAR_ASSOC]
  \\ rpt (disch_then drule)
  \\ fs [word_add_n2w]
  \\ strip_tac \\ rveq \\ fs []
  \\ drule gc_partial_move_list_with_NIL
  \\ fs [] \\ pairarg_tac \\ fs []
  \\ strip_tac
  \\ rveq \\ fs []
  \\ first_x_assum drule \\ fs []
  \\ disch_then drule \\ fs[]
  \\ qpat_x_assum `word_gen_gc_partial_move_roots conf _ = _` mp_tac
  \\ SEP_W_TAC
  \\ rpt strip_tac
  \\ SEP_F_TAC \\ fs []
  \\ strip_tac \\ rveq \\ fs []
  \\ fs [heap_length_APPEND,GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
  \\ rename1 `s2.n = LENGTH xs2`
  \\ rfs []
  \\ qexists_tac `xs2` \\ fs []
  \\ fs [word_heap_APPEND]
  \\ fs [heap_length_APPEND,GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
  \\ fs [AC STAR_COMM STAR_ASSOC]
  \\ qpat_x_assum `LENGTH xs = s.n` (assume_tac o GSYM)
  \\ fs[]);

val word_gen_gc_partial_move_list_thm = Q.prove(
  `!x xs x1 s1 s pa1 pa m1 m i1 frame dm curr c1 k old current refs.
    (gen_gc_partial$gc_move_list gen_conf s x = (x1,s1)) /\ s1.ok /\ s.h2 = [] /\ s.r4 = [] /\
    gen_conf.limit = heap_length s.heap /\
    heap_length s.heap <= dimword (:'a) DIV 2 ** shift_length conf /\
    gen_conf.gen_start <= gen_conf.refs_start /\  
    gen_conf.refs_start <= heap_length s.heap /\
    (heap_segment (gen_conf.gen_start,gen_conf.refs_start) s.heap = SOME(old,current,refs)) /\
    (!t r. (gen_conf.isRef (t,r) <=> t = RefTag)) /\
    w2n curr + heap_length s.heap * (dimindex (:α) DIV 8) < dimword (:α) /\
    (word_heap (curr + bytes_in_word * n2w(heap_length old)) current conf * word_list pa xs *
     word_list k (MAP (word_addr conf) x) * frame) (fun2set (m,dm)) /\
    (word_gen_gc_partial_move_list conf (k,n2w (LENGTH x),n2w s.a,pa,
                                         curr:'a word,m,dm,
                                         curr + bytes_in_word * n2w gen_conf.gen_start,
                                         curr + bytes_in_word * n2w gen_conf.refs_start) =
      (k1,i1,pa1,m1,c1)) /\
    LENGTH xs = s.n /\ good_dimindex (:'a) /\ LENGTH x < dimword (:'a) ==>
    ?xs1 current1.
      (word_heap (curr + bytes_in_word * n2w(heap_length old)) current1 conf *
       word_heap pa s1.h2 conf *
       word_list pa1 xs1 *
       word_list k (MAP (word_addr conf) x1) *
       frame) (fun2set (m1,dm)) /\
      heap_length s1.heap = heap_length s.heap /\
      (heap_segment (gen_conf.gen_start,gen_conf.refs_start) s1.heap = SOME(old,current1,refs)) /\
      c1 /\ (i1 = n2w s1.a) /\ s1.n = LENGTH xs1 /\
      s.n = heap_length s1.h2 + s1.n + heap_length s1.r4 /\
      k1 = k + n2w (LENGTH x) * bytes_in_word /\
      pa1 = pa + bytes_in_word * n2w (heap_length s1.h2)`,
  Induct
  THEN1
   (fs [gen_gc_partialTheory.gc_move_list_def,Once word_gen_gc_partial_move_list_def] \\ rw []
    \\ fs [word_heap_def,SEP_CLAUSES] \\ asm_exists_tac \\ fs [])
  \\ fs [gen_gc_partialTheory.gc_move_list_def]
  \\ once_rewrite_tac [word_gen_gc_partial_move_list_def]
  \\ rpt strip_tac \\ fs []
  \\ rw [] \\ ntac 4 (pairarg_tac \\ fs []) \\ rveq
  \\ fs [ADD1,GSYM word_add_n2w,word_list_def]
  \\ ntac 4 (pop_assum mp_tac) \\ SEP_R_TAC \\ fs []
  \\ rpt strip_tac
  \\ drule (GEN_ALL word_gen_gc_partial_move_thm) \\ fs []
  \\ drule gc_move_heap_length \\ DISCH_TAC \\ fs[]
  \\ drule gc_move_list_heap_length \\ DISCH_TAC \\ fs[]
  \\ `state'.ok` by imp_res_tac gc_partial_move_list_ok_before
  \\ fs [GSYM STAR_ASSOC]
  \\ rpt (disch_then drule)
  \\ fs [word_add_n2w]
  \\ strip_tac \\ rveq \\ fs []
  \\ drule gc_partial_move_list_with_NIL
  \\ fs [] \\ pairarg_tac \\ fs []
  \\ strip_tac
  \\ rveq \\ fs []
  \\ first_x_assum drule \\ fs []
  \\ disch_then drule \\ fs[]
  \\ qpat_x_assum `word_gen_gc_partial_move_list conf _ = _` mp_tac
  \\ SEP_W_TAC
  \\ rpt strip_tac
  \\ SEP_F_TAC \\ fs []
  \\ strip_tac \\ rveq \\ fs []
  \\ fs [heap_length_APPEND,GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
  \\ rename1 `s2.n = LENGTH xs2`
  \\ rfs []
  \\ qexists_tac `xs2` \\ fs []
  \\ fs [word_heap_APPEND]
  \\ fs [heap_length_APPEND,GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
  \\ fs [AC STAR_COMM STAR_ASSOC]
  \\ qpat_x_assum `LENGTH xs = s.n` (assume_tac o GSYM)
  \\ fs[]);

val word_gen_gc_partial_move_data_def = Define `
  word_gen_gc_partial_move_data conf k
   (h2a:'a word,i,pa:'a word,old,m,dm,gs,rs) =
    if h2a = pa then (i,pa,m,T) else
    if k = 0n then (i,pa,m,F) else
      let c = (h2a IN dm) in
      let v = m h2a in
      let c = (c /\ isWord v) in
      let l = decode_length conf (theWord v) in
        if word_bit 2 (theWord v) then
          let h2a = h2a + (l + 1w) * bytes_in_word in
          let (i,pa,m,c2) = word_gen_gc_partial_move_data conf (k-1)
                        (h2a,i,pa,old,m,dm,gs,rs) in
            (i,pa,m,c)
        else
          let (h2a,i,pa,m,c1) = word_gen_gc_partial_move_list conf
                        (h2a+bytes_in_word,l,i,pa,old,m,dm,gs,rs) in
          let (i,pa,m,c2) = word_gen_gc_partial_move_data conf (k-1)
                        (h2a,i,pa,old,m,dm,gs,rs) in
            (i,pa,m,c /\ c1 /\ c2)`

val gc_partial_move_heap_lengths = Q.store_thm("gc_partial_move_heap_lengths",
  `gen_gc_partial$gc_move gen_conf s x = (x1,s1) /\ s1.ok ==>
    s.n + heap_length s.h2 = s1.n + heap_length s1.h2`,
  Cases_on `x` >> rw[gc_move_def]
  >> fs[] >> every_case_tac
  >> fs[]
  >- (qpat_x_assum `_ = s1` (assume_tac o GSYM)
      >> fs[])
  >- (qpat_x_assum `_ = s1` (assume_tac o GSYM)
      >> fs[])
  >> pairarg_tac >> fs[]
  >> qpat_x_assum `_ = s1` (assume_tac o GSYM)
  >> fs[heap_length_APPEND]
  >> fs[heap_length_def,el_length_def]
  >> `(s.ok ∧ n < SUM (MAP el_length s.heap)) ∧ n' + 1 ≤ s.n ∧
       ¬gen_conf.isRef b`
         by(match_mp_tac (GEN_ALL gc_forward_ptr_ok)
            >> qexists_tac `a` >> qexists_tac `s.heap` >> qexists_tac `n`
            >> qexists_tac `s.a` >> qexists_tac `heap` >> fs[])
  >> fs[]);

val gc_partial_move_list_heap_lengths = Q.store_thm("gc_partial_move_list_heap_lengths",
  `!x gen_conf s x1 s1. gen_gc_partial$gc_move_list gen_conf s x = (x1,s1) /\ s1.ok ==>
     s.n + heap_length s.h2 = s1.n + heap_length s1.h2`,
  Induct_on `x` >> rw[gen_gc_partialTheory.gc_move_list_def]
  >> ntac 2 (pairarg_tac >> fs[])
  >> metis_tac[gc_partial_move_heap_lengths,gc_partial_move_list_ok_before]);

val partial_len_inv_def = Define `
  partial_len_inv s <=>
    heap_length s.heap =
    heap_length (s.h1 ++ s.h2) + s.n + heap_length (s.r4 ++ s.r3 ++ s.r2 ++ s.r1 ++ s.old)`;

val word_gen_gc_partial_move_data_thm = Q.prove(
  `!k s m dm curr xs s1 pa1 m1 i1 frame c1 old current refs.
    (gen_gc_partial$gc_move_data gen_conf s = s1) /\ s1.ok /\
    gen_conf.limit = heap_length s.heap /\
    heap_length s.heap <= dimword (:'a) DIV 2 ** shift_length conf /\
    w2n curr + heap_length s.heap * (dimindex (:'a) DIV 8) < dimword (:'a) /\
    gen_conf.gen_start <= gen_conf.refs_start /\  
    gen_conf.refs_start <= heap_length s.heap /\
    (heap_segment (gen_conf.gen_start,gen_conf.refs_start) s.heap = SOME(old,current,refs)) /\
    conf.len_size + 2 < dimindex (:α) /\
    (!t r. (gen_conf.isRef (t,r) <=> t = RefTag)) /\
    (word_gen_gc_partial_move_data conf k
       ((* h2a *) p + bytes_in_word * n2w (heap_length s.h1),
        n2w s.a,
        (* pa *) p + bytes_in_word * n2w (heap_length (s.h1 ++ s.h2)),
        curr:'a word,m,dm,
        curr + bytes_in_word * n2w gen_conf.gen_start,
        curr + bytes_in_word * n2w gen_conf.refs_start) =
      (i1,pa1,m1,c1)) /\
    heap_length s.h2 + s.n <= k /\ partial_len_inv s /\
    (word_heap (curr + bytes_in_word * n2w(heap_length old)) current conf *
     word_heap p (s.h1 ++ s.h2) conf *
     word_list (p + bytes_in_word * n2w(heap_length(s.h1 ++ s.h2))) xs *
     frame) (fun2set (m,dm)) /\
    EVERY (is_Ref gen_conf.isRef) (s.r4 ++ s.r3 ++ s.r2 ++ s.r1) /\
    LENGTH xs = s.n /\ good_dimindex (:'a) ==>
    ?xs1 current1.
      (word_heap (curr + bytes_in_word * n2w(heap_length old)) current1 conf *
       word_heap p (s1.h1 ++ s1.h2) conf *
       word_list (p + bytes_in_word * n2w(heap_length(s1.h1 ++ s1.h2))) xs1 *
       frame) (fun2set (m1,dm)) /\ s1.h2 = [] /\
      heap_length s1.heap = heap_length s.heap /\
      (heap_segment (gen_conf.gen_start,gen_conf.refs_start) s1.heap = SOME(old,current1,refs)) /\
      c1 /\ (i1 = n2w s1.a) /\
      s1.n = LENGTH xs1 /\ partial_len_inv s1 /\
      heap_length (s1.h1 ++ s1.h2 ++ s1.r4) + s1.n =
      heap_length (s.h1 ++ s.h2 ++ s.r4) + s.n /\
      pa1 = p + bytes_in_word * n2w (heap_length (s1.h1 ++ s1.h2)) /\
      EVERY (is_Ref gen_conf.isRef) (s1.r4 ++ s1.r3 ++ s1.r2 ++ s1.r1)`,
  completeInduct_on `k` \\ rpt strip_tac
  \\ fs [PULL_FORALL,AND_IMP_INTRO,GSYM CONJ_ASSOC]
  \\ qpat_x_assum `gc_move_data gen_conf s = s1` mp_tac
  \\ once_rewrite_tac [gen_gc_partialTheory.gc_move_data_def]
  \\ CASE_TAC THEN1
   (rw [] \\ fs []
    \\ qpat_x_assum `word_gen_gc_partial_move_data conf k _ = _` mp_tac
    \\ once_rewrite_tac [word_gen_gc_partial_move_data_def]
    \\ fs [] \\ strip_tac \\ rveq
    \\ qexists_tac `xs`
    \\ fs []
    \\ fs [partial_len_inv_def])
  \\ IF_CASES_TAC THEN1 (rw[] \\ fs [])
  \\ CASE_TAC
  THEN1 (strip_tac \\ rveq \\ fs [])
  THEN1 (strip_tac \\ rveq \\ fs [])
  \\ fs []
  \\ rpt (pairarg_tac \\ fs [])
  \\ rename1 `_ = (_,s3)`
  \\ strip_tac
  \\ `s3.ok` by (drule gc_partial_move_data_ok_before >> fs[])
  \\ qmatch_asmsub_abbrev_tac `gc_move_data gen_conf s4`
  \\ rveq
  \\ `s3.h1 = s.h1 /\ s3.r1 = s.r1 /\ s3.r2 = s.r2 /\ s3.r3 = s.r3 /\ s3.r4 = s.r4` by
    (drule gc_move_list_IMP \\ fs [])
  \\ `partial_len_inv s3`
    by(fs [partial_len_inv_def,heap_length_def,SUM_APPEND,el_length_def]
       \\ drule gc_move_list_heap_length \\ disch_then (assume_tac o GSYM)
       \\ fs[heap_length_def,SUM_APPEND,el_length_def]
       \\ `s3.n + SUM(MAP el_length s3.h2) + SUM(MAP el_length s3.old) = n + SUM(MAP el_length t) + SUM(MAP el_length s.old) + s.n + 1` suffices_by fs[]
       \\ drule gc_partial_move_list_heap_lengths
       \\ DISCH_TAC \\ first_x_assum drule \\ disch_then (assume_tac o GSYM)
       \\ fs[heap_length_def,SUM_APPEND,el_length_def]
       \\ metis_tac [gc_move_list_IMP])
  \\ `partial_len_inv s4` by
    (unabbrev_all_tac
     \\ fs [partial_len_inv_def,heap_length_def,SUM_APPEND,el_length_def]
     \\ drule gc_partial_move_list_with_NIL \\ fs []
     \\ pairarg_tac \\ fs []
     \\ strip_tac \\ rveq \\ fs [SUM_APPEND,el_length_def] \\ NO_TAC)
  \\ full_simp_tac std_ss [GSYM STAR_ASSOC]
  \\ drule word_heap_IMP_limit
  \\ full_simp_tac std_ss [STAR_ASSOC] \\ strip_tac
  \\ drule gc_partial_move_list_with_NIL \\ fs []
  \\ pairarg_tac \\ fs []
  \\ strip_tac \\ rveq \\ fs []
  \\ PairCases_on `b`
  \\ rfs [is_Ref_def] \\ rveq
  \\ qpat_x_assum `word_gen_gc_partial_move_data conf k _ = _` mp_tac
  \\ once_rewrite_tac [word_gen_gc_partial_move_data_def]
  \\ IF_CASES_TAC THEN1
   (fs [heap_length_APPEND,GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
    \\ rewrite_tac [addressTheory.WORD_EQ_ADD_CANCEL,GSYM WORD_ADD_ASSOC]
    \\ qsuff_tac `F` \\ fs []
    \\ fs [heap_length_def,el_length_def]
    \\ full_simp_tac std_ss [addressTheory.WORD_EQ_ADD_CANCEL,GSYM WORD_ADD_ASSOC]
    \\ pop_assum mp_tac \\ fs [bytes_in_word_def,word_mul_n2w]
    \\ fs [RIGHT_ADD_DISTRIB]
    \\ qmatch_goalsub_abbrev_tac `nn MOD _`
    \\ qsuff_tac `nn < dimword (:α)`
    \\ fs [] \\ unabbrev_all_tac \\ rfs [good_dimindex_def]
    \\ rfs [dimword_def] \\ fs[])
  \\ simp [] \\ pop_assum kall_tac
  \\ rpt (pairarg_tac \\ fs [])
  \\ strip_tac \\ rveq
  \\ fs [heap_length_APPEND]
  \\ fs [heap_length_def,el_length_def]
  \\ fs [GSYM heap_length_def]
  \\ fs [word_heap_APPEND,word_heap_def,word_el_def,
         heap_length_APPEND,word_payload_def,GSYM word_add_n2w,
         WORD_LEFT_ADD_DISTRIB,word_list_def]
  \\ pairarg_tac \\ fs []
  \\ full_simp_tac (std_ss++sep_cond_ss) [cond_STAR] \\ rfs [] \\ rveq
  \\ ntac 4 (pop_assum mp_tac)
  \\ SEP_R_TAC \\ fs [theWord_def,isWord_def]
  \\ Cases_on `word_bit 2 h` \\ fs []
  THEN1
   (rpt strip_tac \\ rveq
    \\ `l = []` by (imp_res_tac word_payload_T_IMP \\ rfs [] \\ NO_TAC)
    \\ rveq \\ fs [gen_gc_partialTheory.gc_move_list_def] \\ rveq \\ fs []
    \\ qpat_x_assum `word_gen_gc_partial_move_data conf (k − 1) _ = _` kall_tac
    \\ qpat_x_assum `word_gen_gc_partial_move_list conf _ = _` kall_tac
    \\ rfs []
    \\ qpat_x_assum `!m:num. _`
         (qspecl_then [`k-1`,`s4`,`m`,`dm`,`curr`,`xs`] mp_tac) \\ fs []
    \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
           heap_length_APPEND,word_payload_def,GSYM word_add_n2w,
           WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
    \\ qmatch_asmsub_abbrev_tac `word_gen_gc_partial_move_data conf _ input1 = _`
    \\ qmatch_goalsub_abbrev_tac `word_gen_gc_partial_move_data conf _ input2 = _`
    \\ `input1 = input2` by
     (unabbrev_all_tac \\ simp_tac std_ss [] \\ rpt strip_tac
      \\ fs [SUM_APPEND,el_length_def]
      \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
            heap_length_APPEND,word_payload_def,GSYM word_add_n2w,
            WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
      \\ imp_res_tac word_payload_T_IMP \\ rfs [] \\ NO_TAC)
    \\ fs []
    \\ disch_then (qspecl_then [`frame`,`old`,`current`,`refs`] mp_tac)
    \\ impl_tac THEN1
     (qunabbrev_tac `s4` \\ fs [is_Ref_def]
      \\ qpat_x_assum `_ (fun2set (_,dm))` mp_tac
      \\ qpat_x_assum `_ = s.n` (assume_tac o GSYM) \\ fs []
      \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
            heap_length_APPEND,word_payload_def,GSYM word_add_n2w,SUM_APPEND,
            WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
      \\ match_mp_tac (METIS_PROVE [] ``f = g ==> f x ==> g x``)
      \\ fs [AC STAR_ASSOC STAR_COMM,SEP_CLAUSES])
    \\ strip_tac
    \\ qexists_tac `xs1` \\ fs [] \\ rpt strip_tac
    \\ qabbrev_tac `s5 = gc_move_data gen_conf s4`
    \\ qunabbrev_tac `s4`
    \\ fs [el_length_def,SUM_APPEND]
    \\ qpat_x_assum `_ = s.n` (assume_tac o GSYM)
    \\ pop_assum mp_tac \\ simp_tac std_ss []
    \\ CCONTR_TAC \\ fs [] \\ rfs [])
  \\ qmatch_goalsub_abbrev_tac `word_gen_gc_partial_move_list conf (newp,_)`
  \\ rpt strip_tac \\ rveq
  \\ drule (GEN_ALL word_gen_gc_partial_move_list_thm) \\ fs []
  \\ drule word_payload_T_IMP
  \\ fs [] \\ strip_tac \\ rveq \\ fs []
  \\ fs [is_Ref_def]
  \\ strip_tac
  \\ SEP_F_TAC \\ fs [GSYM word_add_n2w]
  \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
            heap_length_APPEND,word_payload_def,GSYM word_add_n2w,SUM_APPEND,
            WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
  \\ impl_tac THEN1
   (rfs [good_dimindex_def] \\ rfs [dimword_def]
    \\ fs [len_inv_def,heap_length_def,el_length_def,SUM_APPEND] \\ rfs [])
  \\ strip_tac \\ rveq
  \\ qpat_x_assum `s.n = _` (assume_tac o GSYM)
  \\ fs [el_length_def,heap_length_def]
  \\ fs [GSYM heap_length_def] \\ rfs []
  \\ qmatch_asmsub_abbrev_tac `word_gen_gc_partial_move_data conf _ input1 = _`
  \\ qpat_x_assum `!m:num. _`
       (qspecl_then [`k-1`,`s4`,`m''`,`dm`,`curr`,`xs1`] mp_tac) \\ fs []
  \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
         heap_length_APPEND,word_payload_def,GSYM word_add_n2w,
         WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
  \\ qmatch_goalsub_abbrev_tac `word_gen_gc_partial_move_data conf _ input2 = _`
  \\ `input1 = input2` by
   (unabbrev_all_tac \\ simp_tac std_ss [] \\ rpt strip_tac
    \\ fs [SUM_APPEND,el_length_def]
    \\ pop_assum (assume_tac o GSYM) \\ fs []
    \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
          heap_length_APPEND,word_payload_def,GSYM word_add_n2w,
          WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
    \\ NO_TAC)
  \\ fs []
  \\ drule (GEN_ALL word_payload_swap)
  \\ drule gen_gc_partialTheory.gc_move_list_length
  \\ strip_tac \\ disch_then drule \\ strip_tac
  \\ disch_then (qspecl_then [`frame`,`old`,`current1`,`refs`] mp_tac)
  \\ impl_tac THEN1
   (qunabbrev_tac `s4` \\ fs [is_Ref_def]
    \\ qpat_x_assum `_ (fun2set (_,dm))` mp_tac
    \\ qpat_x_assum `_ = s.n` (assume_tac o GSYM) \\ fs []
    \\ qunabbrev_tac `newp`
    \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
          heap_length_APPEND,word_payload_def,GSYM word_add_n2w,SUM_APPEND,
          WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]
    \\ fs [AC STAR_ASSOC STAR_COMM,SEP_CLAUSES])
  \\ strip_tac
  \\ qexists_tac `xs1'` \\ fs []
  \\ qabbrev_tac `s5 = gc_move_data gen_conf s4`
  \\ qunabbrev_tac `s4` \\ fs [is_Ref_def]
  \\ fs [el_length_def,SUM_APPEND]
  \\ qpat_x_assum `_ = s.n` (assume_tac o GSYM) \\ fs []
  \\ fs [word_heap_parts_def,word_heap_APPEND,word_heap_def,word_el_def,
         heap_length_APPEND,word_payload_def,GSYM word_add_n2w,
         WORD_LEFT_ADD_DISTRIB,word_list_def,el_length_def,heap_length_def]);

val refs_to_addresses_def = Define `
  (refs_to_addresses [] = []) /\
  (refs_to_addresses (DataElement ptrs _ _::refs) =
    ptrs ++ refs_to_addresses refs) /\
  (refs_to_addresses (_::refs) = refs_to_addresses refs)`;

val word_gen_gc_partial_move_ref_list_def = Define `
  word_gen_gc_partial_move_ref_list k conf (pb,i,pa,old,m,dm,c,gs,rs,re) =
    if pb = re then (i,pa,m,c) else
    if k = 0 then (i,pa,m,F) else
      let w = m pb in
      let c = (c /\ pb IN dm /\ isWord w) in
      let len = decode_length conf (theWord w) in
      let pb = pb + bytes_in_word in
      let (pb,i1,pa1,m1,c1) = word_gen_gc_partial_move_list conf (pb,len,i,pa,old,m,dm,gs,rs) in
        word_gen_gc_partial_move_ref_list (k-1n) conf (pb,i1,pa1,old,m1,dm,c /\ c1,gs,rs,re)`

val word_gen_gc_partial_move_ref_list_thm = Q.prove(
  `!x ck xs x1 s1 s pa1 pa m1 m i1 frame dm curr c1 k old current refs.
    (gen_gc_partial$gc_move_ref_list gen_conf s x = (x1,s1)) /\ s1.ok /\ s.h2 = [] /\ s.r4 = [] /\
    heap_length x <= ck /\
    gen_conf.limit = heap_length s.heap /\
    heap_length s.heap <= dimword (:'a) DIV 2 ** shift_length conf /\
    gen_conf.gen_start <= gen_conf.refs_start /\  
    gen_conf.refs_start <= heap_length s.heap /\
    heap_segment (gen_conf.gen_start,gen_conf.refs_start) s.heap = SOME(old,current,refs) /\
    heap_length x <= heap_length s.heap /\
    EVERY isRef x /\
    (!t r. (gen_conf.isRef (t,r) <=> t = RefTag)) /\
    w2n curr + heap_length s.heap * (dimindex (:α) DIV 8) < dimword (:α) /\
    (word_heap (curr+bytes_in_word * n2w(heap_length old)) current conf * word_list pa xs *
     word_heap k x conf * frame) (fun2set (m,dm)) /\
    (word_gen_gc_partial_move_ref_list ck conf (k,n2w s.a,pa,
                                         curr:'a word,m,dm,T,
                                         curr + bytes_in_word * n2w gen_conf.gen_start,
                                         curr + bytes_in_word * n2w gen_conf.refs_start,
                                         k + bytes_in_word * n2w(heap_length x)) =
      (i1,pa1,m1,c1)) /\
    LENGTH xs = s.n /\ good_dimindex (:'a) /\ LENGTH x < dimword (:'a) ==>
    ?xs1 current1.
      (word_heap (curr+bytes_in_word * n2w(heap_length old)) current1 conf *
       word_heap pa s1.h2 conf *
       word_list pa1 xs1 *
       word_heap k x1 conf *
       frame) (fun2set (m1,dm)) /\
      heap_segment (gen_conf.gen_start,gen_conf.refs_start) s1.heap = SOME(old,current1,refs) /\
      heap_length s1.heap = heap_length s.heap /\
      c1 /\ (i1 = n2w s1.a) /\ s1.n = LENGTH xs1 /\
      EVERY isRef x1 /\
      s.n = heap_length s1.h2 + s1.n + heap_length s1.r4 /\
  pa1 = pa + bytes_in_word * n2w (heap_length s1.h2)`,
  Induct
  THEN1
   (fs [gen_gc_partialTheory.gc_move_ref_list_def,Once word_gen_gc_partial_move_ref_list_def] \\ rw []
      \\ fs [word_heap_def,SEP_CLAUSES,refs_to_addresses_def] \\ asm_exists_tac \\ fs [])
  \\ Cases
  THEN1 fs [gen_gc_partialTheory.gc_move_ref_list_def]
  THEN1 fs [gen_gc_partialTheory.gc_move_ref_list_def]
  \\ fs [gen_gc_partialTheory.gc_move_ref_list_def]
  \\ rpt strip_tac \\ fs []
  \\ qpat_x_assum `word_gen_gc_partial_move_ref_list _ _ _ = _` mp_tac
  \\ simp[Once word_gen_gc_partial_move_ref_list_def]
  \\ rw [] \\ fs[heap_length_def,el_length_def]
  \\ `(n + (SUM (MAP el_length x) + 1)) * (dimindex (:α) DIV 8) < dimword (:α)`
       by (`SUM (MAP el_length s.heap) * (dimindex (:α) DIV 8) < dimword (:α)`
             suffices_by fs[good_dimindex_def,dimword_def]
           >> fs[])
  \\ `k <> k + bytes_in_word * n2w (n + (SUM (MAP el_length x) + 1))`
      by (CCONTR_TAC >> fs[bytes_in_word_def,addressTheory.WORD_EQ_ADD_CANCEL]
          >> fs[bytes_in_word_def,word_add_n2w,word_mul_n2w] >> fs[good_dimindex_def]
          >> rw[] >> rfs[])
  \\ fs[word_heap_def] \\ rfs[]
  \\ PairCases_on `b`
  \\ fs[word_el_def]
  \\ pairarg_tac \\ fs[isRef_def] \\ rveq \\ fs[word_payload_def]
  \\ full_simp_tac (std_ss++sep_cond_ss) [cond_STAR]
  \\ rveq \\ fs[word_list_def]
  \\ `m k = Word(make_header conf 2w (LENGTH l))` by SEP_R_TAC
  \\ fs[theWord_def,el_length_def]
  \\ ntac 2 (pairarg_tac \\ fs[])
  \\ drule(GEN_ALL word_gen_gc_partial_move_list_thm)
  \\ `state'.ok` by imp_res_tac gc_partial_move_ref_list_ok_before
  \\ fs[heap_length_def]
  \\ disch_then drule \\ disch_then drule
  \\ strip_tac \\ SEP_F_TAC \\ rfs[]
  \\ impl_tac THEN1 (fs[good_dimindex_def,dimword_def] >> rfs[])
  \\ strip_tac
  \\ rveq \\ fs[]
  \\ drule gc_partial_move_ref_list_with_NIL \\ disch_then drule
  \\ fs[] \\ pairarg_tac \\ fs[] \\ strip_tac \\ rveq \\ fs[]
  \\ first_x_assum drule \\ fs[]
  \\ `s1'.ok` by (rveq \\ fs[])
  \\ fs[]
  \\ strip_tac \\ SEP_F_TAC
  \\ fs[GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
  \\ `k ∈ dm` by SEP_R_TAC
  \\ fs[isWord_def]
  \\ disch_then (qspec_then `ck-1` mp_tac)
  \\ fs[]
  \\ strip_tac \\ rveq \\ fs[]
  \\ drule gen_gc_partialTheory.gc_move_list_length \\ strip_tac
  \\ fs[GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB,SUM_APPEND]
  \\ qexists_tac `xs1'` \\ fs[word_heap_APPEND,word_heap_def,word_el_def,el_length_def]
  \\ pairarg_tac \\ fs[] \\ fs[word_list_def]
  \\ fs[word_payload_def] \\ rveq \\ fs[]
  \\ fs[GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB,heap_length_def]
  \\ fs[AC STAR_ASSOC STAR_COMM]
  \\ fs[SEP_CLAUSES]
  \\ fs[isRef_def]);

val word_gen_gc_partial_def = Define `
  word_gen_gc_partial conf (roots,(curr:'a word),new,len,m,dm,gs,rs) =
    let new_end = curr + n2w len * bytes_in_word in
    let gen_start = (gs - curr) ⋙ shift (:α) in
    let (roots,i,pa,m,c1) = word_gen_gc_partial_move_roots conf
                    (roots,gen_start,new,curr,m,dm,gs,rs) in
    let (i,pa,m,c2) = word_gen_gc_partial_move_ref_list len conf
                                 (rs,i,pa,curr,m,dm,c1,gs,rs,new_end) in
    let (i,pa,m,c3) = word_gen_gc_partial_move_data conf len
                                 (new,i,pa,curr,m,dm,gs,rs) in
      (roots,i,pa,m,c2 /\ c3)`

val gc_move_ref_list_IMP = prove (
  ``!conf state refs state1 refs1.
    (gc_move_ref_list conf state refs = (refs1,state1)) ==>
    (state1.old = state.old) /\
    (state1.h1 = state.h1) /\
    (state1.r1 = state.r1) /\
    (state1.r2 = state.r2) /\
    (state1.r3 = state.r3) /\
    (state1.r4 = state.r4) /\
    (heap_length refs = heap_length refs1) /\
    (!ptr.
       isSomeDataElement (heap_lookup ptr refs) ==>
       isSomeDataElement (heap_lookup ptr refs1))
  ``,
  recInduct (fetch "gen_gc_partial" "gc_move_ref_list_ind")
  \\ once_rewrite_tac [gc_move_ref_list_def] \\ fs []
  \\ rpt gen_tac
  \\ strip_tac
  \\ rpt gen_tac
  \\ pairarg_tac \\ fs []
  \\ pairarg_tac \\ fs []
  \\ strip_tac \\ rveq
  \\ drule gc_move_list_IMP
  \\ strip_tac \\ rveq
  \\ fs []
  \\ fs [heap_length_def,el_length_def]
  \\ simp [heap_lookup_def]
  \\ strip_tac
  \\ IF_CASES_TAC \\ fs []
  >- simp [isSomeDataElement_def]
  \\ IF_CASES_TAC \\ fs [el_length_def]);

val heap_length_LENGTH = Q.prove(`LENGTH x <= heap_length x`,
  Induct_on `x` >- fs[LENGTH]
  >> Cases >> fs[LENGTH,heap_length_def,el_length_def]);

val partial_gc_move_ref_list_isRef = Q.prove(`
  !refs s refs' state'.
   gen_gc_partial$gc_move_ref_list gen_conf s refs = (refs',state')
   ==> EVERY (is_Ref gen_conf.isRef) refs' = EVERY (is_Ref gen_conf.isRef) refs`,
  Induct >- fs[gc_move_ref_list_def]
  >> Cases >> rpt strip_tac  
  >> fs[gc_move_ref_list_def]
  >> rveq >> fs[is_Ref_def]
  >> ntac 2 (pairarg_tac >> fs[])
  >> rveq >> fs[is_Ref_def]
  >> metis_tac[]);

val EVERY_is_Ref_isRef = Q.prove(
  `(∀t r. f (t,r) ⇔ t = RefTag) ==> EVERY (is_Ref f) refs = EVERY isRef refs`,
  Induct_on `refs` >- fs[] >> Cases >> rpt strip_tac >> fs[isRef_def,is_Ref_def]
  >> Cases_on `b` >> fs[isRef_def]);

val word_gen_gc_partial_thm = Q.prove(
  `!m dm curr s1 pa1 m1 i1 frame c1 roots heap roots1 roots1' new.
    (gen_gc_partial$partial_gc gen_conf (roots,heap) = (roots1,s1)) /\ s1.ok /\
    heap_length heap <= dimword (:'a) DIV 2 ** shift_length conf /\
    heap_length heap * (dimindex (:'a) DIV 8) < dimword (:'a) /\
    heap_gen_ok heap gen_conf /\
    gen_conf.limit = heap_length heap /\
    gen_conf.gen_start <= gen_conf.refs_start /\  
    gen_conf.refs_start <= heap_length heap /\
    w2n curr + heap_length heap * (dimindex (:α) DIV 8) < dimword (:α) /\
    conf.len_size + 2 < dimindex (:α) /\
    (!t r. (gen_conf.isRef (t,r) <=> t = RefTag)) /\
    LENGTH roots < dimword (:α) /\
    (word_gen_gc_partial conf (MAP (word_addr conf) roots,curr,new,heap_length heap,m,dm,
                               curr + bytes_in_word * n2w gen_conf.gen_start,
                               curr + bytes_in_word * n2w gen_conf.refs_start
                              ) = (roots1',i1,pa1:'a word,m1,c1)) /\
    (word_heap curr heap conf *
     word_list_exists new (gen_conf.refs_start - gen_conf.gen_start) *
     frame) (fun2set (m,dm)) /\ good_dimindex (:'a) ==>
    ?xs1 current1 refs1.
      (word_heap curr (s1.old ++ current1 ++ s1.r1) conf *
       word_heap new (s1.h1 ++ s1.h2) conf *
       word_list (new + bytes_in_word * n2w(heap_length(s1.h1 ++ s1.h2))) xs1 *
       frame) (fun2set (m1,dm)) /\
      s1.h2 = [] /\ s1.r4 = [] /\ s1.r3 = [] /\ s1.r2 = [] /\
      roots1' = MAP (word_addr conf) roots1 /\
      heap_length s1.heap = heap_length heap /\
      heap_segment (gen_conf.gen_start,gen_conf.refs_start) s1.heap = SOME(s1.old,current1,refs1) /\
      c1 /\ (i1 = n2w s1.a) /\
      s1.n = LENGTH xs1 /\ partial_len_inv s1 /\
      EVERY (is_Ref gen_conf.isRef) s1.r1`,
  rpt gen_tac \\ once_rewrite_tac [gen_gc_partialTheory.partial_gc_def]
  \\ fs [] \\ rpt (pairarg_tac \\ fs []) \\ strip_tac \\ fs []
  \\ every_case_tac THEN1 (fs[] \\ rveq \\ fs[])
  \\ ntac 2 (pairarg_tac \\ fs[])
  \\ drule heap_segment_IMP \\ impl_tac THEN1 fs[]
  \\ drule gc_partial_move_data_ok_before \\ disch_then drule \\ strip_tac
  \\ fs[]
  \\ drule gc_partial_move_ref_list_ok_before \\ disch_then drule \\ strip_tac
  \\ strip_tac
  \\ rveq \\ fs[]
  \\ drule (GEN_ALL word_gen_gc_partial_move_roots_thm)
  \\ fs[empty_state_def]
  \\ rpt(disch_then drule)
  \\ fs [word_list_exists_def,SEP_CLAUSES,SEP_EXISTS_THM]
  \\ full_simp_tac (std_ss++sep_cond_ss) [cond_STAR]
  \\ fs[word_heap_APPEND]
  \\ pop_assum(fn x => ntac 2(assume_tac x))
  \\ strip_tac \\ SEP_F_TAC \\ fs []
  \\ fs[word_gen_gc_partial_def]
  \\ ntac 3 (pairarg_tac \\ fs[])
  \\ rveq \\ fs[]
  \\ `((bytes_in_word:'a word) * n2w gen_conf.gen_start) ⋙ shift (:α) = n2w gen_conf.gen_start`
      by  (fs[bytes_in_word_mul_eq_shift]
           >> MATCH_MP_TAC lsl_lsr
           >> fs[w2n_n2w]
           >> rw[shift_def]
           >> fs[dimword_def,good_dimindex_def])
  \\ fs[]      
  \\ ntac 3 (qpat_x_assum `heap_length _ = _` (mp_tac o GSYM))
  \\ ntac 3 strip_tac
  \\ impl_tac THEN1 fs[heap_length_APPEND]
  \\ strip_tac
  \\ rveq \\ fs[]
  \\ drule gc_partial_move_ref_list_with_NIL \\ disch_then drule
  \\ fs[] \\ pairarg_tac \\ fs[] \\ strip_tac
  \\ qpat_x_assum `y = refs'` (fn thm => fs[thm])
  \\ rveq \\ fs[]
  \\ drule (GEN_ALL word_gen_gc_partial_move_ref_list_thm)
  \\ fs[gc_state_component_equality]
  \\ `heap_length r' <= heap_length (q ++ q' ++ r')` by fs[heap_length_APPEND]
  \\ rpt(disch_then drule)
  \\ rfs[]
  \\ `EVERY isRef r'`
     by(fs[EVERY_MEM,heap_gen_ok_def]
        \\ strip_tac
        \\ strip_tac
        \\ first_x_assum drule
        \\ Cases_on `e` \\ fs[isRef_def,isDataElement_def]
        \\ first_x_assum drule
        \\ Cases_on `b` \\fs[isRef_def] \\ NO_TAC)
  \\ fs[]
  \\ rpt(disch_then drule)
  \\ strip_tac \\ SEP_F_TAC
  \\ SIMP_TAC std_ss [GSYM WORD_LEFT_ADD_DISTRIB,GSYM WORD_ADD_ASSOC, word_add_n2w,
                      GSYM heap_length_APPEND]
  \\ rpt(disch_then drule)
  \\ impl_tac THEN1
     (`LENGTH r' <= heap_length r'` by metis_tac [heap_length_LENGTH]
      >> `heap_length r' < dimword(:'a)` suffices_by fs[]
      >> fs[heap_length_APPEND,good_dimindex_def] >> rfs[] >> fs[])
  \\ rpt(disch_then drule)
  \\ strip_tac
  \\ `gc_move_data gen_conf(s1 with <|h2 := state'.h2 ++ s1.h2;
                                      r4 := s1.r4 ++ state'.r4;
                                      r2 := []; r1 := refs'|>) =
      gc_move_data gen_conf(s1 with <|h2 := state'.h2 ++ s1.h2;
                            r4 := s1.r4 ++ state'.r4;
                            r2 := []; r1 := refs'|>)` by fs[]
  \\ drule (gc_move_data_IMP) \\ strip_tac
  \\ drule (GEN_ALL word_gen_gc_partial_move_data_thm)
  \\ rpt(disch_then drule)
  \\ fs[]
  \\ rpt(disch_then drule)
  \\ `s1.h1 = []`
     by (drule gen_gc_partialTheory.gc_move_list_IMP >> drule gc_move_ref_list_IMP >> fs[])
  \\ `s1.r3 = []`
     by (drule gen_gc_partialTheory.gc_move_list_IMP >> drule gc_move_ref_list_IMP >> fs[])
  \\ fs[]
  \\ rpt(disch_then drule)
  \\ rveq \\ fs[]
  \\ fs[heap_length_APPEND]
  \\ fs[partial_len_inv_def,heap_length_APPEND]
  \\ drule gc_move_ref_list_heap_length' \\ strip_tac
  \\ fs[]
  \\ drule gc_move_list_IMP \\ strip_tac
  \\ drule gc_move_ref_list_IMP \\ strip_tac
  \\ fs[word_heap_parts_def]
  \\ fs[word_heap_APPEND]
  \\ rveq \\ fs[heap_length_APPEND]
  \\ strip_tac \\ SEP_F_TAC
  \\ impl_tac THEN1 fs[EVERY_is_Ref_isRef]
  \\ strip_tac
  \\ fs[] \\ rveq \\ fs[]
  \\ qpat_abbrev_tac `a1 = gc_move_data _ _`
  \\ drule heap_segment_IMP \\ impl_tac THEN1 fs[]
  \\ disch_then (assume_tac o GSYM)
  \\ fs[heap_length_APPEND,word_heap_APPEND]
  \\ rfs[heap_length_APPEND,word_heap_APPEND]
  \\ fs[AC STAR_ASSOC STAR_COMM]
  \\ qexists_tac `xs1''` \\ fs[]
  \\ drule partial_gc_move_ref_list_isRef
  \\ fs[EVERY_is_Ref_isRef]);

(* -------------------------------------------------------
    definition of state relation
   ------------------------------------------------------- *)

val code_rel_def = Define `
  code_rel c s_code (t_code: (num # 'a wordLang$prog) num_map) <=>
    EVERY (\(n,x). lookup n t_code = SOME x) (stubs (:'a) c) /\
    !n arg_count prog.
      (lookup n s_code = SOME (arg_count:num,prog)) ==>
      (lookup n t_code = SOME (arg_count+1,FST (comp c n 1 prog)))`

val stack_rel_def = Define `
  (stack_rel (Env env) (StackFrame vs NONE) <=>
     EVERY (\(x1,x2). isWord x2 ==> x1 <> 0 /\ EVEN x1) vs /\
     !n. IS_SOME (lookup n env) <=>
         IS_SOME (lookup (adjust_var n) (fromAList vs))) /\
  (stack_rel (Exc env n) (StackFrame vs (SOME (x1,x2,x3))) <=>
     stack_rel (Env env) (StackFrame vs NONE) /\ (x1 = n)) /\
  (stack_rel _ _ <=> F)`

val the_global_def = Define `
  the_global g = the (Number 0) (OPTION_MAP RefPtr g)`;

val contains_loc_def = Define `
  contains_loc (StackFrame vs _) (l1,l2) = (ALOOKUP vs 0 = SOME (Loc l1 l2))`

val state_rel_thm = Define `
  state_rel c l1 l2 (s:'ffi dataSem$state) (t:('a,'ffi) wordSem$state) v1 locs <=>
    (* I/O, clock and handler are the same, GC is fixed, code is compiled *)
    (t.ffi = s.ffi) /\
    (t.clock = s.clock) /\
    (t.handler = s.handler) /\
    (t.gc_fun = word_gc_fun c) /\
    code_rel c s.code t.code /\
    good_dimindex (:'a) /\
    shift_length c < dimindex (:'a) /\
    (* the store *)
    EVERY (\n. n IN FDOM t.store) [Globals] /\
    (* every local is represented in word lang *)
    (v1 = [] ==> lookup 0 t.locals = SOME (Loc l1 l2)) /\
    (!n. IS_SOME (lookup n s.locals) ==>
         IS_SOME (lookup (adjust_var n) t.locals)) /\
    (* the stacks contain the same names, have same shape *)
    EVERY2 stack_rel s.stack t.stack /\
    EVERY2 contains_loc t.stack locs /\
    (* there exists some GC-compatible abstraction *)
    memory_rel c t.be s.refs s.space t.store t.memory t.mdomain
      (v1 ++
       join_env s.locals (toAList (inter t.locals (adjust_set s.locals))) ++
       [(the_global s.global,t.store ' Globals)] ++
       flat s.stack t.stack)`

val state_rel_def = state_rel_thm |> REWRITE_RULE [memory_rel_def]

val state_rel_with_clock = Q.store_thm("state_rel_with_clock",
  `state_rel a b c s1 s2 d e ⇒
   state_rel a b c (s1 with clock := k) (s2 with clock := k) d e`,
  srw_tac[][state_rel_def]);

(* -------------------------------------------------------
    init
   ------------------------------------------------------- *)

val flat_NIL = Q.prove(
  `flat [] xs = []`,
  Cases_on `xs` \\ fs [flat_def]);

val conf_ok_def = Define `
  conf_ok (:'a) c <=>
    shift_length c < dimindex (:α) ∧
    shift (:α) ≤ shift_length c ∧ c.len_size ≠ 0 ∧
    c.len_size + 7 < dimindex (:α)`

val init_store_ok_def = Define `
  init_store_ok c store m (dm:'a word set) <=>
    ?limit curr.
      limit <= max_heap_limit (:'a) c /\
      FLOOKUP store Globals = SOME (Word 0w) /\
      FLOOKUP store CurrHeap = SOME (Word curr) ∧
      FLOOKUP store OtherHeap = FLOOKUP store EndOfHeap ∧
      FLOOKUP store NextFree = SOME (Word curr) ∧
      FLOOKUP store EndOfHeap =
        SOME (Word (curr + bytes_in_word * n2w limit)) ∧
      FLOOKUP store TriggerGC =
        SOME (Word (curr + bytes_in_word * n2w limit)) ∧
      FLOOKUP store HeapLength =
        SOME (Word (bytes_in_word * n2w limit)) ∧
      (word_list_exists curr (limit + limit)) (fun2set (m,dm)) ∧
      byte_aligned curr`

val state_rel_init = Q.store_thm("state_rel_init",
  `t.ffi = ffi ∧ t.handler = 0 ∧ t.gc_fun = word_gc_fun c ∧
    code_rel c code t.code ∧
    good_dimindex (:α) ∧
    lookup 0 t.locals = SOME (Loc l1 l2) ∧
    t.stack = [] /\
    conf_ok (:'a) c /\
    init_store_ok c t.store t.memory t.mdomain ==>
    state_rel c l1 l2 (initial_state ffi code t.clock) (t:('a,'ffi) state) [] []`,
  simp_tac std_ss [word_list_exists_ADD,conf_ok_def,init_store_ok_def]
  \\ fs [state_rel_thm,dataSemTheory.initial_state_def,
    join_env_def,lookup_def,the_global_def,
    libTheory.the_def,flat_NIL,FLOOKUP_DEF] \\ strip_tac \\ fs []
  \\ qpat_abbrev_tac `fil = FILTER _ _`
  \\ `fil = []` by
   (fs [FILTER_EQ_NIL,Abbr `fil`] \\ fs [EVERY_MEM,MEM_toAList,FORALL_PROD]
    \\ fs [lookup_inter_alt]) \\ fs [max_heap_limit_def]
  \\ fs [GSYM (EVAL ``(Smallnum 0)``)]
  \\ match_mp_tac IMP_memory_rel_Number
  \\ fs [] \\ conj_tac
  THEN1 (EVAL_TAC \\ fs [labPropsTheory.good_dimindex_def,dimword_def])
  \\ fs [memory_rel_def]
  \\ rewrite_tac [CONJ_ASSOC]
  \\ once_rewrite_tac [CONJ_COMM]
  \\ `limit * (dimindex (:α) DIV 8) + 1 < dimword (:α)` by
   (fs [labPropsTheory.good_dimindex_def,dimword_def]
    \\ rfs [shift_def] \\ decide_tac)
  \\ asm_exists_tac \\ fs []
  \\ fs [word_ml_inv_def]
  \\ qexists_tac `heap_expand limit`
  \\ qexists_tac `0`
  \\ qexists_tac `limit`
  \\ qexists_tac `0`
  \\ qexists_tac `GenState 0 []`
  \\ reverse conj_tac THEN1
   (fs[abs_ml_inv_def,roots_ok_def,heap_ok_def,heap_length_heap_expand,
       unused_space_inv_def,bc_stack_ref_inv_def,FDOM_EQ_EMPTY]
    \\ fs [heap_expand_def,heap_lookup_def]
    \\ rw [] \\ fs [isForwardPointer_def,bc_ref_inv_def,reachable_refs_def,
                    gc_kind_inv_def] \\ CASE_TAC \\ fs [])
  \\ fs [heap_in_memory_store_def,heap_length_heap_expand,word_heap_heap_expand]
  \\ fs [FLOOKUP_DEF]
  \\ fs [byte_aligned_def,bytes_in_word_def,labPropsTheory.good_dimindex_def,
         word_mul_n2w]
  \\ simp_tac bool_ss [GSYM (EVAL ``2n**2``),GSYM (EVAL ``2n**3``)]
  \\ once_rewrite_tac [MULT_COMM]
  \\ simp_tac bool_ss [aligned_add_pow] \\ rfs []);

(* -------------------------------------------------------
    compiler proof
   ------------------------------------------------------- *)

val adjust_var_NOT_0 = Q.store_thm("adjust_var_NOT_0[simp]",
  `adjust_var n <> 0`,
  full_simp_tac(srw_ss())[adjust_var_def]);

val state_rel_get_var_IMP = Q.prove(
  `state_rel c l1 l2 s t v1 locs ==>
    (get_var n s.locals = SOME x) ==>
    ?w. get_var (adjust_var n) t = SOME w`,
  full_simp_tac(srw_ss())[dataSemTheory.get_var_def,wordSemTheory.get_var_def]
  \\ full_simp_tac(srw_ss())[state_rel_def] \\ rpt strip_tac
  \\ `IS_SOME (lookup n s.locals)` by full_simp_tac(srw_ss())[] \\ res_tac
  \\ Cases_on `lookup (adjust_var n) t.locals` \\ full_simp_tac(srw_ss())[]);

val state_rel_get_vars_IMP = Q.prove(
  `!n xs.
      state_rel c l1 l2 s t [] locs ==>
      (get_vars n s.locals = SOME xs) ==>
      ?ws. get_vars (MAP adjust_var n) t = SOME ws /\ (LENGTH xs = LENGTH ws)`,
  Induct \\ full_simp_tac(srw_ss())[dataSemTheory.get_vars_def,wordSemTheory.get_vars_def]
  \\ rpt strip_tac
  \\ Cases_on `get_var h s.locals` \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `get_vars n s.locals` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ imp_res_tac state_rel_get_var_IMP \\ full_simp_tac(srw_ss())[]);

val state_rel_0_get_vars_IMP = Q.prove(
  `state_rel c l1 l2 s t [] locs ==>
    (get_vars n s.locals = SOME xs) ==>
    ?ws. get_vars (0::MAP adjust_var n) t = SOME ((Loc l1 l2)::ws) /\
         (LENGTH xs = LENGTH ws)`,
  rpt strip_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ full_simp_tac(srw_ss())[wordSemTheory.get_vars_def]
  \\ full_simp_tac(srw_ss())[state_rel_def,wordSemTheory.get_var_def]);

val get_var_T_OR_F = Q.prove(
  `state_rel c l1 l2 s (t:('a,'ffi) state) [] locs /\
    get_var n s.locals = SOME x /\
    get_var (adjust_var n) t = SOME w ==>
    18 MOD dimword (:'a) <> 2 MOD dimword (:'a) /\
    ((x = Boolv T) ==> (w = Word 2w)) /\
    ((x = Boolv F) ==> (w = Word 18w))`,
  full_simp_tac(srw_ss())[state_rel_def,get_var_def,wordSemTheory.get_var_def]
  \\ strip_tac \\ strip_tac THEN1 (full_simp_tac(srw_ss())[good_dimindex_def] \\ full_simp_tac(srw_ss())[dimword_def])
  \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC]
  \\ imp_res_tac (word_ml_inv_lookup |> Q.INST [`ys`|->`[]`]
                    |> SIMP_RULE std_ss [APPEND])
  \\ pop_assum mp_tac
  \\ simp [word_ml_inv_def,toAList_def,foldi_def,word_ml_inv_def,PULL_EXISTS]
  \\ strip_tac \\ strip_tac
  \\ full_simp_tac(srw_ss())[abs_ml_inv_def,bc_stack_ref_inv_def]
  \\ pop_assum (fn th => full_simp_tac(srw_ss())[GSYM th])
  \\ full_simp_tac(srw_ss())[Boolv_def] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[v_inv_def] \\ full_simp_tac(srw_ss())[word_addr_def]
  \\ EVAL_TAC \\ full_simp_tac(srw_ss())[good_dimindex_def,dimword_def]);

val mk_loc_def = Define `
  mk_loc (SOME (t1,d1,d2)) = Loc d1 d2`;

val cut_env_IMP_cut_env = Q.prove(
  `state_rel c l1 l2 s t [] locs /\
    dataSem$cut_env r s.locals = SOME x ==>
    ?y. wordSem$cut_env (adjust_set r) t.locals = SOME y`,
  full_simp_tac(srw_ss())[dataSemTheory.cut_env_def,wordSemTheory.cut_env_def]
  \\ full_simp_tac(srw_ss())[adjust_set_def,domain_fromAList,SUBSET_DEF,MEM_MAP,
         PULL_EXISTS,sptreeTheory.domain_lookup,lookup_fromAList] \\ srw_tac[][]
  \\ Cases_on `x' = 0` \\ full_simp_tac(srw_ss())[] THEN1 full_simp_tac(srw_ss())[state_rel_def]
  \\ imp_res_tac alistTheory.ALOOKUP_MEM
  \\ full_simp_tac(srw_ss())[unit_some_eq_IS_SOME,IS_SOME_ALOOKUP_EQ,MEM_MAP]
  \\ Cases_on `y'` \\ Cases_on `y''`
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[adjust_var_11] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[state_rel_def] \\ res_tac
  \\ `IS_SOME (lookup q s.locals)` by full_simp_tac(srw_ss())[] \\ res_tac
  \\ Cases_on `lookup (adjust_var q) t.locals` \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[MEM_toAList,unit_some_eq_IS_SOME] \\ res_tac \\ full_simp_tac(srw_ss())[]);

val jump_exc_call_env = Q.prove(
  `wordSem$jump_exc (call_env x s) = jump_exc s`,
  full_simp_tac(srw_ss())[wordSemTheory.jump_exc_def,wordSemTheory.call_env_def]);

val jump_exc_dec_clock = Q.prove(
  `mk_loc (wordSem$jump_exc (dec_clock s)) = mk_loc (jump_exc s)`,
  full_simp_tac(srw_ss())[wordSemTheory.jump_exc_def,wordSemTheory.dec_clock_def]
  \\ srw_tac[][] \\ BasicProvers.EVERY_CASE_TAC \\ full_simp_tac(srw_ss())[mk_loc_def]);

val LASTN_ADD1 = LASTN_LENGTH_ID
  |> Q.SPEC `x::xs` |> SIMP_RULE (srw_ss()) [ADD1]

val jump_exc_push_env_NONE = Q.prove(
  `mk_loc (jump_exc (push_env y NONE s)) =
    mk_loc (jump_exc (s:('a,'b) wordSem$state))`,
  full_simp_tac(srw_ss())[wordSemTheory.push_env_def,wordSemTheory.jump_exc_def]
  \\ Cases_on `env_to_list y s.permute` \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ Cases_on `s.handler = LENGTH s.stack` \\ full_simp_tac(srw_ss())[LASTN_ADD1]
  \\ Cases_on `~(s.handler < LENGTH s.stack)` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  THEN1 (`F` by DECIDE_TAC)
  \\ `LASTN (s.handler + 1) (StackFrame q NONE::s.stack) =
      LASTN (s.handler + 1) s.stack` by
    (match_mp_tac LASTN_TL \\ decide_tac)
  \\ every_case_tac \\ srw_tac[][mk_loc_def]
  \\ `F` by decide_tac);

val state_rel_pop_env_IMP = Q.prove(
  `state_rel c q l s1 t1 xs locs /\
    pop_env s1 = SOME s2 ==>
    ?t2 l8 l9 ll.
      pop_env t1 = SOME t2 /\ locs = (l8,l9)::ll /\
      state_rel c l8 l9 s2 t2 xs ll`,
  full_simp_tac(srw_ss())[pop_env_def]
  \\ Cases_on `s1.stack` \\ full_simp_tac(srw_ss())[] \\ Cases_on `h` \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[state_rel_def]
  \\ TRY (Cases_on `y`) \\ full_simp_tac(srw_ss())[stack_rel_def]
  \\ full_simp_tac(srw_ss())[stack_rel_def,wordSemTheory.pop_env_def]
  \\ rev_full_simp_tac(srw_ss())[] \\ Cases_on `y` \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `o'` \\ full_simp_tac(srw_ss())[stack_rel_def,wordSemTheory.pop_env_def]
  \\ rev_full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ Cases_on `y` \\ full_simp_tac(srw_ss())[]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[]
  \\ TRY (Cases_on `r'`) \\ full_simp_tac(srw_ss())[stack_rel_def]
  \\ full_simp_tac(srw_ss())[lookup_fromAList,contains_loc_def]
  \\ asm_exists_tac \\ full_simp_tac(srw_ss())[]
  \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
  \\ full_simp_tac(srw_ss())[flat_def] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `x` \\ full_simp_tac(srw_ss())[join_env_def,MEM_MAP,MEM_FILTER,EXISTS_PROD]
  \\ full_simp_tac(srw_ss())[MEM_toAList,lookup_fromAList,lookup_inter_alt]
  \\ imp_res_tac alistTheory.ALOOKUP_MEM \\ metis_tac []);

val state_rel_pop_env_set_var_IMP = Q.prove(
  `state_rel c q l s1 t1 [(a,w)] locs /\
    pop_env s1 = SOME s2 ==>
    ?t2 l8 l9 ll.
      pop_env t1 = SOME t2 /\ locs = (l8,l9)::ll /\
      state_rel c l8 l9 (set_var q1 a s2) (set_var (adjust_var q1) w t2) [] ll`,
  full_simp_tac(srw_ss())[pop_env_def]
  \\ Cases_on `s1.stack` \\ full_simp_tac(srw_ss())[] \\ Cases_on `h` \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[state_rel_def,set_var_def,wordSemTheory.set_var_def]
  \\ rev_full_simp_tac(srw_ss())[] \\ Cases_on `y` \\ full_simp_tac(srw_ss())[stack_rel_def]
  \\ Cases_on `o'` \\ full_simp_tac(srw_ss())[stack_rel_def,wordSemTheory.pop_env_def]
  \\ full_simp_tac(srw_ss())[stack_rel_def,wordSemTheory.pop_env_def]
  \\ TRY (Cases_on `x` \\ full_simp_tac(srw_ss())[])
  \\ full_simp_tac(srw_ss())[lookup_insert,adjust_var_11]
  \\ rev_full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ Cases_on `y`
  \\ full_simp_tac(srw_ss())[contains_loc_def,lookup_fromAList] \\ srw_tac[][]
  \\ TRY (Cases_on `r` \\ full_simp_tac(srw_ss())[])
  \\ full_simp_tac(srw_ss())[stack_rel_def,wordSemTheory.pop_env_def] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[lookup_fromAList] \\ rev_full_simp_tac(srw_ss())[]
  \\ first_assum (match_exists_tac o concl) \\ full_simp_tac(srw_ss())[] (* asm_exists_tac *)
  \\ full_simp_tac(srw_ss())[flat_def]
  \\ `word_ml_inv (heap,t1.be,a',sp,sp1,gens) limit c s1.refs
       ((a,w)::(join_env s l ++
         [(the_global s1.global,t1.store ' Globals)] ++ flat t ys))` by
   (first_x_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
    \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[])
  \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC,APPEND]
  \\ match_mp_tac (word_ml_inv_insert
       |> SIMP_RULE std_ss [APPEND,GSYM APPEND_ASSOC])
  \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
  \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `x` \\ full_simp_tac(srw_ss())[join_env_def,MEM_MAP,MEM_FILTER,EXISTS_PROD]
  \\ full_simp_tac(srw_ss())[MEM_toAList,lookup_fromAList,lookup_inter_alt]
  \\ imp_res_tac alistTheory.ALOOKUP_MEM \\ metis_tac []);

val state_rel_jump_exc = Q.prove(
  `state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs /\
    get_var n s.locals = SOME x /\
    get_var (adjust_var n) t = SOME w /\
    jump_exc s = SOME s1 ==>
    ?t1 d1 d2 l5 l6 ll.
      jump_exc t = SOME (t1,d1,d2) /\
      LASTN (LENGTH s1.stack + 1) locs = (l5,l6)::ll /\
      !i. state_rel c l5 l6 (set_var i x s1) (set_var (adjust_var i) w t1) [] ll`,
  full_simp_tac(srw_ss())[jump_exc_def] \\ rpt CASE_TAC \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[state_rel_def]
  \\ full_simp_tac(srw_ss())[wordSemTheory.set_var_def,set_var_def]
  \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC]
  \\ imp_res_tac word_ml_inv_get_var_IMP
  \\ imp_res_tac LASTN_LIST_REL_LEMMA
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[wordSemTheory.jump_exc_def]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[stack_rel_def]
  \\ Cases_on `y'` \\ full_simp_tac(srw_ss())[contains_loc_def]
  \\ `s.handler + 1 <= LENGTH s.stack` by decide_tac
  \\ imp_res_tac LASTN_CONS_IMP_LENGTH \\ full_simp_tac(srw_ss())[ADD1]
  \\ imp_res_tac EVERY2_LENGTH \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[lookup_insert,adjust_var_11]
  \\ full_simp_tac(srw_ss())[contains_loc_def,lookup_fromAList] \\ srw_tac[][]
  \\ first_assum (match_exists_tac o concl) \\ full_simp_tac(srw_ss())[] (* asm_exists_tac *)
  \\ `s.handler + 1 <= LENGTH s.stack /\
      s.handler + 1 <= LENGTH t.stack` by decide_tac
  \\ imp_res_tac LASTN_IMP_APPEND \\ full_simp_tac(srw_ss())[ADD1]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[flat_APPEND,flat_def]
  \\ `word_ml_inv (heap,t.be,a,sp,sp1,gens) limit c s.refs
       ((x,w)::(join_env s' l ++
         [(the_global s.global,t.store ' Globals)] ++ flat t' ys))` by
   (first_x_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
    \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[])
  \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC,APPEND]
  \\ match_mp_tac (word_ml_inv_insert
       |> SIMP_RULE std_ss [APPEND,GSYM APPEND_ASSOC])
  \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
  \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `x'` \\ full_simp_tac(srw_ss())[join_env_def,MEM_MAP,MEM_FILTER,EXISTS_PROD]
  \\ full_simp_tac(srw_ss())[MEM_toAList,lookup_fromAList,lookup_inter_alt]
  \\ imp_res_tac alistTheory.ALOOKUP_MEM \\ metis_tac []);

val get_vars_IMP_LENGTH = Q.prove(
  `!x t s. dataSem$get_vars x s = SOME t ==> LENGTH x = LENGTH t`,
  Induct \\ full_simp_tac(srw_ss())[dataSemTheory.get_vars_def] \\ srw_tac[][]
  \\ every_case_tac \\ res_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]);

val lookup_adjust_var_fromList2 = Q.prove(
  `lookup (adjust_var n) (fromList2 (w::ws)) = lookup n (fromList ws)`,
  full_simp_tac(srw_ss())[lookup_fromList2,EVEN_adjust_var,lookup_fromList]
  \\ full_simp_tac(srw_ss())[adjust_var_def]
  \\ once_rewrite_tac [MULT_COMM]
  \\ full_simp_tac(srw_ss())[GSYM MULT_CLAUSES,MULT_DIV]);

val state_rel_call_env = Q.prove(
  `get_vars args s.locals = SOME q /\
    get_vars (MAP adjust_var args) (t:('a,'ffi) wordSem$state) = SOME ws /\
    state_rel c l5 l6 s t [] locs ==>
    state_rel c l1 l2 (call_env q (dec_clock s))
      (call_env (Loc l1 l2::ws) (dec_clock t)) [] locs`,
  full_simp_tac(srw_ss())[state_rel_def,call_env_def,wordSemTheory.call_env_def,
      dataSemTheory.dec_clock_def,wordSemTheory.dec_clock_def,lookup_adjust_var_fromList2]
  \\ srw_tac[][lookup_fromList2,lookup_fromList] \\ srw_tac[][]
  \\ imp_res_tac get_vars_IMP_LENGTH
  \\ imp_res_tac wordPropsTheory.get_vars_length_lemma \\ full_simp_tac(srw_ss())[]
  \\ first_assum (match_exists_tac o concl) \\ full_simp_tac(srw_ss())[] (* asm_exists_tac *)
  \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC]
  \\ imp_res_tac word_ml_inv_get_vars_IMP
  \\ first_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
  \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `x` \\ full_simp_tac(srw_ss())[join_env_def,MEM_MAP,MEM_FILTER]
  \\ Cases_on `y` \\ full_simp_tac(srw_ss())[MEM_toAList,lookup_inter_alt] \\ srw_tac[][MEM_ZIP]
  \\ full_simp_tac(srw_ss())[lookup_fromList2,lookup_fromList]
  \\ rpt disj1_tac
  \\ Q.MATCH_ASSUM_RENAME_TAC `EVEN k`
  \\ full_simp_tac(srw_ss())[DIV_LT_X]
  \\ `k < 2 + LENGTH q * 2 /\ 0 < LENGTH q * 2` by
   (rev_full_simp_tac(srw_ss())[] \\ Cases_on `q` \\ full_simp_tac(srw_ss())[]
    THEN1 (Cases_on `k` \\ full_simp_tac(srw_ss())[] \\ Cases_on `n` \\ full_simp_tac(srw_ss())[] \\ decide_tac)
    \\ full_simp_tac(srw_ss())[MULT_CLAUSES] \\ decide_tac)
  \\ full_simp_tac(srw_ss())[] \\ qexists_tac `(k - 2) DIV 2` \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[DIV_LT_X] \\ srw_tac[][]
  \\ Cases_on `k` \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `n` \\ full_simp_tac(srw_ss())[DECIDE ``SUC (SUC n) = n + 2``]
  \\ simp [MATCH_MP ADD_DIV_RWT (DECIDE ``0<2:num``)]
  \\ full_simp_tac(srw_ss())[GSYM ADD1,EL]);

val data_get_vars_SNOC_IMP = Q.prove(
  `!x2 x. dataSem$get_vars (SNOC x1 x2) s = SOME x ==>
           ?y1 y2. x = SNOC y1 y2 /\
                   dataSem$get_var x1 s = SOME y1 /\
                   dataSem$get_vars x2 s = SOME y2`,
  Induct \\ full_simp_tac(srw_ss())[dataSemTheory.get_vars_def]
  \\ srw_tac[][] \\ every_case_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]) |> SPEC_ALL;

val word_get_vars_SNOC_IMP = Q.prove(
  `!x2 x. wordSem$get_vars (SNOC x1 x2) s = SOME x ==>
           ?y1 y2. x = SNOC y1 y2 /\
              wordSem$get_var x1 s = SOME y1 /\
              wordSem$get_vars x2 s = SOME y2`,
  Induct \\ full_simp_tac(srw_ss())[wordSemTheory.get_vars_def]
  \\ srw_tac[][] \\ every_case_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]) |> SPEC_ALL;

val word_ml_inv_CodePtr = Q.prove(
  `word_ml_inv (heap,be,a,sp,sp1,gens) limit c s.refs ((CodePtr n,v)::xs) ==>
    (v = Loc n 0)`,
  full_simp_tac(srw_ss())[word_ml_inv_def,PULL_EXISTS] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[abs_ml_inv_def,bc_stack_ref_inv_def,v_inv_def]
  \\ srw_tac[][word_addr_def]);

val state_rel_CodePtr = Q.prove(
  `state_rel c l1 l2 s t [] locs /\
    get_vars args s.locals = SOME x /\
    get_vars (MAP adjust_var args) t = SOME y /\
    LAST x = CodePtr n /\ x <> [] ==>
    y <> [] /\ LAST y = Loc n 0`,
  rpt strip_tac
  \\ imp_res_tac wordPropsTheory.get_vars_length_lemma
  \\ imp_res_tac get_vars_IMP_LENGTH \\ full_simp_tac(srw_ss())[]
  THEN1 (srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ Cases_on `x` \\ full_simp_tac(srw_ss())[])
  \\ `args <> []` by (Cases_on `args` \\ full_simp_tac(srw_ss())[] \\ Cases_on `x` \\ full_simp_tac(srw_ss())[])
  \\ `?x1 x2. args = SNOC x1 x2` by metis_tac [SNOC_CASES]
  \\ full_simp_tac bool_ss [MAP_SNOC]
  \\ imp_res_tac data_get_vars_SNOC_IMP
  \\ imp_res_tac word_get_vars_SNOC_IMP \\ srw_tac[][]
  \\ full_simp_tac bool_ss [LAST_SNOC] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[state_rel_def]
  \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC]
  \\ imp_res_tac word_ml_inv_get_var_IMP \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac word_ml_inv_CodePtr);

val find_code_thm = Q.prove(
  `!(s:'ffi dataSem$state) (t:('a,'ffi)wordSem$state).
      state_rel c l1 l2 s t [] locs /\
      get_vars args s.locals = SOME x /\
      get_vars (0::MAP adjust_var args) t = SOME (Loc l1 l2::ws) /\
      find_code dest x s.code = SOME (q,r) ==>
      ?args1 n1 n2.
        find_code dest (Loc l1 l2::ws) t.code = SOME (args1,FST (comp c n1 n2 r)) /\
        state_rel c l1 l2 (call_env q (dec_clock s))
          (call_env args1 (dec_clock t)) [] locs`,
  Cases_on `dest` \\ srw_tac[][] \\ full_simp_tac(srw_ss())[find_code_def]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[wordSemTheory.find_code_def] \\ srw_tac[][]
  \\ `code_rel c s.code t.code` by full_simp_tac(srw_ss())[state_rel_def]
  \\ full_simp_tac(srw_ss())[code_rel_def] \\ res_tac \\ full_simp_tac(srw_ss())[ADD1]
  \\ imp_res_tac wordPropsTheory.get_vars_length_lemma
  \\ full_simp_tac(srw_ss())[wordSemTheory.get_vars_def]
  \\ Cases_on `get_var 0 t` \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `get_vars (MAP adjust_var args) t` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ TRY (imp_res_tac state_rel_CodePtr \\ full_simp_tac(srw_ss())[]
          \\ qpat_x_assum `ws <> []` (assume_tac)
          \\ imp_res_tac NOT_NIL_IMP_LAST \\ full_simp_tac(srw_ss())[])
  \\ imp_res_tac get_vars_IMP_LENGTH \\ full_simp_tac(srw_ss())[]
  THENL [Q.LIST_EXISTS_TAC [`n`,`1`],Q.LIST_EXISTS_TAC [`x'`,`1`]] \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac state_rel_call_env \\ full_simp_tac(srw_ss())[]
  \\ `args <> []` by (Cases_on `args` \\ full_simp_tac(srw_ss())[] \\ Cases_on `x` \\ full_simp_tac(srw_ss())[])
  \\ `?x1 x2. args = SNOC x1 x2` by metis_tac [SNOC_CASES] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[MAP_SNOC]
  \\ imp_res_tac data_get_vars_SNOC_IMP \\ srw_tac[][]
  \\ imp_res_tac word_get_vars_SNOC_IMP \\ srw_tac[][]
  \\ full_simp_tac bool_ss [GSYM SNOC |> CONJUNCT2]
  \\ full_simp_tac bool_ss [FRONT_SNOC]
  \\ `get_vars (0::MAP adjust_var x2) t = SOME (Loc l1 l2::y2')` by
        full_simp_tac(srw_ss())[wordSemTheory.get_vars_def]
  \\ imp_res_tac state_rel_call_env \\ full_simp_tac(srw_ss())[]) |> SPEC_ALL;

val env_to_list_lookup_equiv = Q.prove(
  `env_to_list y f = (q,r) ==>
    (!n. ALOOKUP q n = lookup n y) /\
    (!x1 x2. MEM (x1,x2) q ==> lookup x1 y = SOME x2)`,
  full_simp_tac(srw_ss())[wordSemTheory.env_to_list_def,LET_DEF] \\ srw_tac[][]
  \\ `ALL_DISTINCT (MAP FST (toAList y))` by full_simp_tac(srw_ss())[ALL_DISTINCT_MAP_FST_toAList]
  \\ imp_res_tac (MATCH_MP PERM_ALL_DISTINCT_MAP
        (QSORT_PERM |> Q.ISPEC `key_val_compare` |> SPEC_ALL))
  \\ `ALL_DISTINCT (QSORT key_val_compare (toAList y))`
        by imp_res_tac ALL_DISTINCT_MAP
  \\ pop_assum (assume_tac o Q.SPEC `f (0:num)` o MATCH_MP PERM_list_rearrange)
  \\ imp_res_tac PERM_ALL_DISTINCT_MAP
  \\ rpt (qpat_x_assum `!x. pp ==> qq` (K all_tac))
  \\ rpt (qpat_x_assum `!x y. pp ==> qq` (K all_tac)) \\ rev_full_simp_tac(srw_ss())[]
  \\ rpt (pop_assum (mp_tac o Q.GEN `x` o SPEC_ALL))
  \\ rpt (pop_assum (mp_tac o SPEC ``f:num->num->num``))
  \\ Q.ABBREV_TAC `xs =
       (list_rearrange (f 0) (QSORT key_val_compare (toAList y)))`
  \\ rpt strip_tac \\ rev_full_simp_tac(srw_ss())[MEM_toAList]
  \\ Cases_on `?i. MEM (n,i) xs` \\ full_simp_tac(srw_ss())[] THEN1
     (imp_res_tac ALL_DISTINCT_MEM_IMP_ALOOKUP_SOME \\ full_simp_tac(srw_ss())[]
      \\ UNABBREV_ALL_TAC \\ full_simp_tac(srw_ss())[] \\ rev_full_simp_tac(srw_ss())[MEM_toAList])
  \\ `~MEM n (MAP FST xs)` by rev_full_simp_tac(srw_ss())[MEM_MAP,FORALL_PROD]
  \\ full_simp_tac(srw_ss())[GSYM ALOOKUP_NONE]
  \\ UNABBREV_ALL_TAC \\ full_simp_tac(srw_ss())[] \\ rev_full_simp_tac(srw_ss())[MEM_toAList]
  \\ Cases_on `lookup n y` \\ full_simp_tac(srw_ss())[]);

val cut_env_adjust_set_lookup_0 = Q.prove(
  `wordSem$cut_env (adjust_set r) x = SOME y ==> lookup 0 y = lookup 0 x`,
  full_simp_tac(srw_ss())[wordSemTheory.cut_env_def,SUBSET_DEF,domain_lookup,adjust_set_def,
      lookup_fromAList] \\ srw_tac[][lookup_inter]
  \\ pop_assum (qspec_then `0` mp_tac) \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[lookup_fromAList,lookup_inter]);

val cut_env_IMP_MEM = Q.prove(
  `dataSem$cut_env s r = SOME x ==>
    (IS_SOME (lookup n x) <=> IS_SOME (lookup n s))`,
  full_simp_tac(srw_ss())[cut_env_def,SUBSET_DEF,domain_lookup]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[lookup_inter] \\ every_case_tac \\ full_simp_tac(srw_ss())[]
  \\ res_tac \\ full_simp_tac(srw_ss())[]);

val cut_env_IMP_lookup = Q.prove(
  `wordSem$cut_env s r = SOME x /\ lookup n x = SOME q ==>
    lookup n r = SOME q`,
  full_simp_tac(srw_ss())[wordSemTheory.cut_env_def,SUBSET_DEF,domain_lookup]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[lookup_inter] \\ every_case_tac \\ full_simp_tac(srw_ss())[]);

val cut_env_IMP_lookup_EQ = Q.prove(
  `dataSem$cut_env r y = SOME x /\ n IN domain r ==>
    lookup n x = lookup n y`,
  full_simp_tac(srw_ss())[dataSemTheory.cut_env_def,SUBSET_DEF,domain_lookup]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[lookup_inter] \\ every_case_tac \\ full_simp_tac(srw_ss())[]);

val cut_env_res_IS_SOME_IMP = Q.prove(
  `wordSem$cut_env r x = SOME y /\ IS_SOME (lookup k y) ==>
    IS_SOME (lookup k x) /\ IS_SOME (lookup k r)`,
  full_simp_tac(srw_ss())[wordSemTheory.cut_env_def,SUBSET_DEF,domain_lookup]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[lookup_inter] \\ every_case_tac \\ full_simp_tac(srw_ss())[]);

val adjust_var_cut_env_IMP_MEM = Q.prove(
  `wordSem$cut_env (adjust_set s) r = SOME x ==>
    domain x SUBSET EVEN /\
    (IS_SOME (lookup (adjust_var n) x) <=> IS_SOME (lookup n s))`,
  full_simp_tac(srw_ss())[wordSemTheory.cut_env_def,SUBSET_DEF,domain_lookup]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[lookup_inter_alt] THEN1
   (full_simp_tac(srw_ss())[domain_lookup,unit_some_eq_IS_SOME,adjust_set_def]
    \\ full_simp_tac(srw_ss())[IS_SOME_ALOOKUP_EQ,MEM_MAP,lookup_fromAList]
    \\ every_case_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[IN_DEF]
    \\ full_simp_tac(srw_ss())[IS_SOME_ALOOKUP_EQ,MEM_MAP,lookup_fromAList]
    \\ pairarg_tac \\ srw_tac[][] \\ full_simp_tac(srw_ss())[EVEN_adjust_var])
  \\ full_simp_tac(srw_ss())[domain_lookup,lookup_adjust_var_adjust_set_SOME_UNIT] \\ srw_tac[][]
  \\ metis_tac [lookup_adjust_var_adjust_set_SOME_UNIT,IS_SOME_DEF]);

val state_rel_call_env_push_env = Q.prove(
  `!opt:(num # 'a wordLang$prog # num # num) option.
      state_rel c l1 l2 s (t:('a,'ffi)wordSem$state) [] locs /\
      get_vars args s.locals = SOME xs /\
      get_vars (MAP adjust_var args) t = SOME ws /\
      dataSem$cut_env r s.locals = SOME x /\
      wordSem$cut_env (adjust_set r) t.locals = SOME y ==>
      state_rel c q l (call_env xs (push_env x (IS_SOME opt) (dec_clock s)))
       (call_env (Loc q l::ws) (push_env y opt (dec_clock t))) []
       ((l1,l2)::locs)`,
  Cases \\ TRY (PairCases_on `x'`) \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[state_rel_def,call_env_def,push_env_def,dataSemTheory.dec_clock_def,
         wordSemTheory.call_env_def,wordSemTheory.push_env_def,
         wordSemTheory.dec_clock_def]
  \\ Cases_on `env_to_list y t.permute` \\ full_simp_tac(srw_ss())[LET_DEF,stack_rel_def]
  \\ full_simp_tac(srw_ss())[lookup_adjust_var_fromList2,contains_loc_def] \\ strip_tac
  \\ full_simp_tac(srw_ss())[lookup_fromList,lookup_fromAList]
  \\ imp_res_tac get_vars_IMP_LENGTH \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac wordPropsTheory.get_vars_length_lemma \\ full_simp_tac(srw_ss())[IS_SOME_IF]
  \\ full_simp_tac(srw_ss())[lookup_fromList2,lookup_fromList]
  \\ imp_res_tac env_to_list_lookup_equiv \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac cut_env_adjust_set_lookup_0 \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac cut_env_IMP_MEM
  \\ imp_res_tac adjust_var_cut_env_IMP_MEM \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac EVERY2_LENGTH \\ full_simp_tac(srw_ss())[]
  \\ rpt strip_tac \\ TRY
   (imp_res_tac adjust_var_cut_env_IMP_MEM
    \\ full_simp_tac(srw_ss())[domain_lookup,SUBSET_DEF,PULL_EXISTS]
    \\ full_simp_tac(srw_ss())[EVERY_MEM,FORALL_PROD] \\ ntac 3 strip_tac
    \\ res_tac \\ res_tac \\ full_simp_tac(srw_ss())[IN_DEF] \\ srw_tac[][] \\ strip_tac
    \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ rev_full_simp_tac(srw_ss())[isWord_def] \\ NO_TAC)
  \\ first_assum (match_exists_tac o concl) \\ full_simp_tac(srw_ss())[] (* asm_exists_tac *)
  \\ full_simp_tac(srw_ss())[flat_def]
  \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC]
  \\ imp_res_tac word_ml_inv_get_vars_IMP
  \\ first_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
  \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ TRY (rpt disj1_tac
    \\ Cases_on `x'` \\ full_simp_tac(srw_ss())[join_env_def,MEM_MAP,MEM_FILTER,EXISTS_PROD]
    \\ full_simp_tac(srw_ss())[MEM_toAList] \\ srw_tac[][MEM_ZIP]
    \\ full_simp_tac(srw_ss())[lookup_fromList2,lookup_fromList,lookup_inter_alt]
    \\ Q.MATCH_ASSUM_RENAME_TAC `EVEN k`
    \\ full_simp_tac(srw_ss())[DIV_LT_X]
    \\ `k < 2 + LENGTH xs * 2 /\ 0 < LENGTH xs * 2` by
     (rev_full_simp_tac(srw_ss())[] \\ Cases_on `xs` \\ full_simp_tac(srw_ss())[]
      THEN1 (Cases_on `k` \\ full_simp_tac(srw_ss())[] \\ Cases_on `n` \\ full_simp_tac(srw_ss())[] \\ decide_tac)
      \\ full_simp_tac(srw_ss())[MULT_CLAUSES] \\ decide_tac)
    \\ full_simp_tac(srw_ss())[] \\ qexists_tac `(k - 2) DIV 2` \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[DIV_LT_X]
    \\ Cases_on `k` \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `n` \\ full_simp_tac(srw_ss())[DECIDE ``SUC (SUC n) = n + 2``]
    \\ full_simp_tac(srw_ss())[MATCH_MP ADD_DIV_RWT (DECIDE ``0<2:num``)]
    \\ full_simp_tac(srw_ss())[GSYM ADD1,EL] \\ NO_TAC)
  \\ full_simp_tac(srw_ss())[] \\ disj1_tac \\ disj2_tac
  \\ Cases_on `x'` \\ full_simp_tac(srw_ss())[join_env_def,MEM_MAP,MEM_FILTER,EXISTS_PROD]
  \\ full_simp_tac(srw_ss())[MEM_toAList] \\ srw_tac[][MEM_ZIP]
  \\ full_simp_tac(srw_ss())[lookup_fromList2,lookup_fromList,lookup_inter_alt]
  \\ Q.MATCH_ASSUM_RENAME_TAC `EVEN k`
  \\ qexists_tac `k` \\ full_simp_tac(srw_ss())[] \\ res_tac \\ srw_tac[][]
  \\ imp_res_tac cut_env_IMP_lookup \\ full_simp_tac(srw_ss())[]
  \\ TRY (AP_TERM_TAC \\ match_mp_tac cut_env_IMP_lookup_EQ) \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[domain_lookup] \\ imp_res_tac MEM_IMP_IS_SOME_ALOOKUP \\ rev_full_simp_tac(srw_ss())[]
  \\ imp_res_tac cut_env_res_IS_SOME_IMP
  \\ full_simp_tac(srw_ss())[IS_SOME_EXISTS]
  \\ full_simp_tac(srw_ss())[adjust_set_def,lookup_fromAList] \\ rev_full_simp_tac(srw_ss())[]
  \\ imp_res_tac alistTheory.ALOOKUP_MEM
  \\ full_simp_tac(srw_ss())[unit_some_eq_IS_SOME,IS_SOME_ALOOKUP_EQ,MEM_MAP,EXISTS_PROD]
  \\ srw_tac[][adjust_var_11,adjust_var_DIV_2]
  \\ imp_res_tac MEM_toAList \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[dataSemTheory.cut_env_def,SUBSET_DEF,domain_lookup]
  \\ res_tac \\ full_simp_tac(srw_ss())[MEM_toAList]);

val find_code_thm_ret = Q.prove(
  `!(s:'ffi dataSem$state) (t:('a,'ffi)wordSem$state).
      state_rel c l1 l2 s t [] locs /\
      get_vars args s.locals = SOME xs /\
      get_vars (MAP adjust_var args) t = SOME ws /\
      find_code dest xs s.code = SOME (ys,prog) /\
      dataSem$cut_env r s.locals = SOME x /\
      wordSem$cut_env (adjust_set r) t.locals = SOME y ==>
      ?args1 n1 n2.
        find_code dest (Loc q l::ws) t.code = SOME (args1,FST (comp c n1 n2 prog)) /\
        state_rel c q l (call_env ys (push_env x F (dec_clock s)))
          (call_env args1 (push_env y
             (NONE:(num # ('a wordLang$prog) # num # num) option)
          (dec_clock t))) [] ((l1,l2)::locs)`,
  reverse (Cases_on `dest`) \\ srw_tac[][] \\ full_simp_tac(srw_ss())[find_code_def]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[wordSemTheory.find_code_def] \\ srw_tac[][]
  \\ `code_rel c s.code t.code` by full_simp_tac(srw_ss())[state_rel_def]
  \\ full_simp_tac(srw_ss())[code_rel_def] \\ res_tac \\ full_simp_tac(srw_ss())[ADD1]
  \\ imp_res_tac wordPropsTheory.get_vars_length_lemma \\ full_simp_tac(srw_ss())[]
  \\ TRY (imp_res_tac state_rel_CodePtr \\ full_simp_tac(srw_ss())[]
          \\ qpat_x_assum `ws <> []` (assume_tac)
          \\ imp_res_tac NOT_NIL_IMP_LAST \\ full_simp_tac(srw_ss())[])
  \\ imp_res_tac get_vars_IMP_LENGTH \\ full_simp_tac(srw_ss())[]
  THEN1 (Q.LIST_EXISTS_TAC [`x'`,`1`] \\ full_simp_tac(srw_ss())[]
         \\ qspec_then `NONE` mp_tac state_rel_call_env_push_env \\ full_simp_tac(srw_ss())[])
  \\ Q.LIST_EXISTS_TAC [`n`,`1`] \\ full_simp_tac(srw_ss())[]
  \\ `args <> []` by (Cases_on `args` \\ full_simp_tac(srw_ss())[] \\ Cases_on `xs` \\ full_simp_tac(srw_ss())[])
  \\ `?x1 x2. args = SNOC x1 x2` by metis_tac [SNOC_CASES] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[MAP_SNOC]
  \\ imp_res_tac data_get_vars_SNOC_IMP \\ srw_tac[][]
  \\ imp_res_tac word_get_vars_SNOC_IMP \\ srw_tac[][]
  \\ full_simp_tac bool_ss [GSYM SNOC |> CONJUNCT2]
  \\ full_simp_tac bool_ss [FRONT_SNOC]
  \\ match_mp_tac (state_rel_call_env_push_env |> Q.SPEC `NONE`
                   |> SIMP_RULE std_ss [] |> GEN_ALL)
  \\ full_simp_tac(srw_ss())[] \\ metis_tac []) |> SPEC_ALL;

val find_code_thm_handler = Q.prove(
  `!(s:'ffi dataSem$state) (t:('a,'ffi)wordSem$state).
      state_rel c l1 l2 s t [] locs /\
      get_vars args s.locals = SOME xs /\
      get_vars (MAP adjust_var args) t = SOME ws /\
      find_code dest xs s.code = SOME (ys,prog) /\
      dataSem$cut_env r s.locals = SOME x /\
      wordSem$cut_env (adjust_set r) t.locals = SOME y ==>
      ?args1 n1 n2.
        find_code dest (Loc q l::ws) t.code = SOME (args1,FST (comp c n1 n2 prog)) /\
        state_rel c q l (call_env ys (push_env x T (dec_clock s)))
          (call_env args1 (push_env y
             (SOME (adjust_var x0,(prog1:'a wordLang$prog),nn,l + 1))
          (dec_clock t))) [] ((l1,l2)::locs)`,
  reverse (Cases_on `dest`) \\ srw_tac[][] \\ full_simp_tac(srw_ss())[find_code_def]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[wordSemTheory.find_code_def] \\ srw_tac[][]
  \\ `code_rel c s.code t.code` by full_simp_tac(srw_ss())[state_rel_def]
  \\ full_simp_tac(srw_ss())[code_rel_def] \\ res_tac \\ full_simp_tac(srw_ss())[ADD1]
  \\ imp_res_tac wordPropsTheory.get_vars_length_lemma \\ full_simp_tac(srw_ss())[]
  \\ TRY (imp_res_tac state_rel_CodePtr \\ full_simp_tac(srw_ss())[]
          \\ qpat_x_assum `ws <> []` (assume_tac)
          \\ imp_res_tac NOT_NIL_IMP_LAST \\ full_simp_tac(srw_ss())[])
  \\ imp_res_tac get_vars_IMP_LENGTH \\ full_simp_tac(srw_ss())[]
  THEN1 (Q.LIST_EXISTS_TAC [`x'`,`1`] \\ full_simp_tac(srw_ss())[]
         \\ match_mp_tac (state_rel_call_env_push_env |> Q.SPEC `SOME xx`
                   |> SIMP_RULE std_ss [] |> GEN_ALL) \\ full_simp_tac(srw_ss())[] \\ metis_tac [])
  \\ Q.LIST_EXISTS_TAC [`n`,`1`] \\ full_simp_tac(srw_ss())[]
  \\ `args <> []` by (Cases_on `args` \\ full_simp_tac(srw_ss())[] \\ Cases_on `xs` \\ full_simp_tac(srw_ss())[])
  \\ `?x1 x2. args = SNOC x1 x2` by metis_tac [SNOC_CASES] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[MAP_SNOC]
  \\ imp_res_tac data_get_vars_SNOC_IMP \\ srw_tac[][]
  \\ imp_res_tac word_get_vars_SNOC_IMP \\ srw_tac[][]
  \\ full_simp_tac bool_ss [GSYM SNOC |> CONJUNCT2]
  \\ full_simp_tac bool_ss [FRONT_SNOC]
  \\ match_mp_tac (state_rel_call_env_push_env |> Q.SPEC `SOME xx`
                   |> SIMP_RULE std_ss [] |> GEN_ALL)
  \\ full_simp_tac(srw_ss())[] \\ metis_tac []) |> SPEC_ALL;

val bvl_find_code = Q.store_thm("bvl_find_code",
  `bvlSem$find_code dest xs code = SOME(ys,prog) ⇒
  ¬bad_dest_args dest xs`,
  Cases_on`dest`>>
  full_simp_tac(srw_ss())[bvlSemTheory.find_code_def,wordSemTheory.bad_dest_args_def])

val s_key_eq_LENGTH = Q.prove(
  `!xs ys. s_key_eq xs ys ==> (LENGTH xs = LENGTH ys)`,
  Induct \\ Cases_on `ys` \\ full_simp_tac(srw_ss())[s_key_eq_def]);

val s_key_eq_LASTN = Q.prove(
  `!xs ys n. s_key_eq xs ys ==> s_key_eq (LASTN n xs) (LASTN n ys)`,
  Induct \\ Cases_on `ys` \\ full_simp_tac(srw_ss())[s_key_eq_def,LASTN_ALT]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[s_key_eq_def,LASTN_ALT] \\ res_tac
  \\ imp_res_tac s_key_eq_LENGTH \\ full_simp_tac(srw_ss())[] \\ `F` by decide_tac);

val evaluate_mk_loc_EQ = Q.prove(
  `evaluate (q,t) = (NONE,t1:('a,'b) state) ==>
    mk_loc (jump_exc t1) = ((mk_loc (jump_exc t)):'a word_loc)`,
  qspecl_then [`q`,`t`] mp_tac wordPropsTheory.evaluate_stack_swap \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[wordSemTheory.jump_exc_def]
  \\ imp_res_tac s_key_eq_LENGTH \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ imp_res_tac s_key_eq_LASTN
  \\ pop_assum (qspec_then `t.handler + 1` mp_tac)
  \\ every_case_tac \\ full_simp_tac(srw_ss())[s_key_eq_def,s_frame_key_eq_def,mk_loc_def])

val mk_loc_eq_push_env_exc_Exception = Q.prove(
  `evaluate
      (c:'a wordLang$prog, call_env args1
            (push_env y (SOME (x0,prog1:'a wordLang$prog,x1,l))
               (dec_clock t))) = (SOME (Exception xx w),(t1:('a,'b) state)) ==>
    mk_loc (jump_exc t1) = mk_loc (jump_exc t) :'a word_loc`,
  qspecl_then [`c`,`call_env args1
    (push_env y (SOME (x0,prog1:'a wordLang$prog,x1,l)) (dec_clock t))`]
       mp_tac wordPropsTheory.evaluate_stack_swap \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[wordSemTheory.call_env_def,wordSemTheory.push_env_def,
         wordSemTheory.dec_clock_def]
  \\ Cases_on `env_to_list y t.permute` \\ full_simp_tac(srw_ss())[LET_DEF,LASTN_ADD1]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[wordSemTheory.jump_exc_def]
  \\ first_assum (qspec_then `t1.stack` mp_tac)
  \\ imp_res_tac s_key_eq_LENGTH \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ imp_res_tac s_key_eq_LASTN
  \\ pop_assum (qspec_then `t.handler+1` mp_tac) \\ srw_tac[][]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[s_key_eq_def,s_frame_key_eq_def,mk_loc_def]);

val evaluate_IMP_domain_EQ = Q.prove(
  `evaluate (c,call_env (args1:'a word_loc list) (push_env y (opt:(num # ('a wordLang$prog) # num # num) option) (dec_clock t))) =
      (SOME (Result ll w),t1) /\ pop_env t1 = SOME t2 ==>
    domain t2.locals = domain y`,
  qspecl_then [`c`,`call_env args1 (push_env y opt (dec_clock t))`] mp_tac
      wordPropsTheory.evaluate_stack_swap \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[wordSemTheory.call_env_def]
  \\ Cases_on `opt` \\ full_simp_tac(srw_ss())[] \\ TRY (PairCases_on `x`)
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[wordSemTheory.pop_env_def,wordSemTheory.push_env_def]
  \\ Cases_on `env_to_list y (dec_clock t).permute` \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[s_key_eq_def] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[wordSemTheory.env_to_list_def,LET_DEF] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[s_frame_key_eq_def,domain_fromAList] \\ srw_tac[][]
  \\ qpat_x_assum `xxx = MAP FST l` (fn th => full_simp_tac(srw_ss())[GSYM th])
  \\ full_simp_tac(srw_ss())[EXTENSION,MEM_MAP,EXISTS_PROD,mem_list_rearrange,QSORT_MEM,
         domain_lookup,MEM_toAList]);

val evaluate_IMP_domain_EQ_Exc = Q.prove(
  `evaluate (c,call_env args1 (push_env y
      (SOME (x0,prog1:'a wordLang$prog,x1,l))
      (dec_clock (t:('a,'b) state)))) = (SOME (Exception ll w),t1) ==>
    domain t1.locals = domain y`,
  qspecl_then [`c`,`call_env args1
     (push_env y (SOME (x0,prog1:'a wordLang$prog,x1,l)) (dec_clock t))`]
     mp_tac wordPropsTheory.evaluate_stack_swap \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[wordSemTheory.call_env_def,wordSemTheory.push_env_def,
         wordSemTheory.dec_clock_def]
  \\ Cases_on `env_to_list y t.permute` \\ full_simp_tac(srw_ss())[LET_DEF,LASTN_ADD1] \\ srw_tac[][]
  \\ first_x_assum (qspec_then `t1.stack` mp_tac) \\ srw_tac[][]
  \\ imp_res_tac s_key_eq_LASTN \\ full_simp_tac(srw_ss())[]
  \\ first_x_assum (qspec_then `t.handler+1` mp_tac) \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[wordSemTheory.env_to_list_def,LET_DEF] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[s_frame_key_eq_def,domain_fromAList] \\ srw_tac[][]
  \\ qpat_x_assum `xxx = MAP FST lss` (fn th => full_simp_tac(srw_ss())[GSYM th])
  \\ full_simp_tac(srw_ss())[EXTENSION,MEM_MAP,EXISTS_PROD,mem_list_rearrange,QSORT_MEM,
         domain_lookup,MEM_toAList]);

val mk_loc_jump_exc = Q.prove(
  `mk_loc
       (jump_exc
          (call_env args1
             (push_env y (SOME (adjust_var n,prog1,x0,l))
                (dec_clock t)))) = Loc x0 l`,
  full_simp_tac(srw_ss())[wordSemTheory.push_env_def,wordSemTheory.call_env_def,
      wordSemTheory.jump_exc_def]
  \\ Cases_on `env_to_list y (dec_clock t).permute`
  \\ full_simp_tac(srw_ss())[LET_DEF,LASTN_ADD1,mk_loc_def]);

val inc_clock_def = Define `
  inc_clock n (t:('a,'ffi) wordSem$state) = t with clock := t.clock + n`;

val inc_clock_0 = Q.store_thm("inc_clock_0[simp]",
  `!t. inc_clock 0 t = t`,
  full_simp_tac(srw_ss())[inc_clock_def,wordSemTheory.state_component_equality]);

val inc_clock_inc_clock = Q.store_thm("inc_clock_inc_clock[simp]",
  `!t. inc_clock n (inc_clock m t) = inc_clock (n+m) t`,
  full_simp_tac(srw_ss())[inc_clock_def,wordSemTheory.state_component_equality,AC ADD_ASSOC ADD_COMM]);

val mk_loc_jmup_exc_inc_clock = Q.store_thm("mk_loc_jmup_exc_inc_clock[simp]",
  `mk_loc (jump_exc (inc_clock ck t)) = mk_loc (jump_exc t)`,
  full_simp_tac(srw_ss())[mk_loc_def,wordSemTheory.jump_exc_def,inc_clock_def]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[mk_loc_def]);

val jump_exc_inc_clock_EQ_NONE = Q.prove(
  `jump_exc (inc_clock n s) = NONE <=> jump_exc s = NONE`,
  full_simp_tac(srw_ss())[mk_loc_def,wordSemTheory.jump_exc_def,inc_clock_def]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[mk_loc_def]);

val state_rel_lookup_globals = Q.store_thm("state_rel_lookup_globals",
  `state_rel c l1 l2 s t v1 locs ∧ s.global = SOME g (* ∧
   FLOOKUP s.refs g = SOME (ValueArray gs) *)
   ⇒
   ∃x u.
   FLOOKUP t.store Globals = SOME (Word (get_addr c x u))`,
  rw[state_rel_def]
  \\ fs[the_global_def,libTheory.the_def]
  \\ qmatch_assum_abbrev_tac`word_ml_inv heapp limit c refs _`
  \\ qmatch_asmsub_abbrev_tac`[gg]`
  \\ `∃rest. word_ml_inv heapp limit c refs (gg::rest)`
  by (
    qmatch_asmsub_abbrev_tac`a1 ++ [gg] ++ a2`
    \\ qexists_tac`a1++a2`
    \\ simp[Abbr`heapp`]
    \\ match_mp_tac (GEN_ALL (MP_CANON word_ml_inv_rearrange))
    \\ ONCE_REWRITE_TAC[CONJ_COMM]
    \\ asm_exists_tac
    \\ simp[] \\ metis_tac[] )
  \\ fs[word_ml_inv_def,Abbr`heapp`]
  \\ fs[abs_ml_inv_def]
  \\ fs[bc_stack_ref_inv_def]
  \\ fs[Abbr`gg`,v_inv_def]
  \\ simp[FLOOKUP_DEF]
  \\ first_assum(CHANGED_TAC o SUBST1_TAC o SYM)
  \\ rveq
  \\ simp_tac(srw_ss())[word_addr_def]
  \\ metis_tac[]);

val state_rel_cut_env = Q.store_thm("state_rel_cut_env",
  `state_rel c l1 l2 s t [] locs /\
    dataSem$cut_env names s.locals = SOME x ==>
    state_rel c l1 l2 (s with locals := x) t [] locs`,
  full_simp_tac(srw_ss())[state_rel_def,dataSemTheory.cut_env_def] \\ srw_tac[][]
  THEN1 (full_simp_tac(srw_ss())[lookup_inter] \\ every_case_tac \\ full_simp_tac(srw_ss())[])
  \\ asm_exists_tac \\ full_simp_tac(srw_ss())[]
  \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ rpt disj1_tac
  \\ PairCases_on `x` \\ full_simp_tac(srw_ss())[join_env_def,MEM_MAP]
  \\ Cases_on `y` \\ full_simp_tac(srw_ss())[EXISTS_PROD,MEM_FILTER]
  \\ qexists_tac `q` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  THEN1
   (AP_TERM_TAC
    \\ full_simp_tac(srw_ss())[FUN_EQ_THM,lookup_inter_alt,MEM_toAList,domain_lookup]
    \\ full_simp_tac(srw_ss())[SUBSET_DEF,IN_DEF,domain_lookup] \\ srw_tac[][]
    \\ imp_res_tac IMP_adjust_var
    \\ `lookup (adjust_var ((q - 2) DIV 2))
           (adjust_set (inter s.locals names)) = NONE` by
     (simp [lookup_adjust_var_adjust_set_NONE,lookup_inter_alt]
      \\ full_simp_tac(srw_ss())[domain_lookup]) \\ rev_full_simp_tac(srw_ss())[])
  \\ full_simp_tac(srw_ss())[MEM_toAList,lookup_inter_alt]
  \\ full_simp_tac(srw_ss())[domain_lookup,unit_some_eq_IS_SOME,adjust_set_def,lookup_fromAList]
  \\ rev_full_simp_tac(srw_ss())[IS_SOME_ALOOKUP_EQ,MEM_MAP] \\ srw_tac[][]
  \\ Cases_on `y'` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][EXISTS_PROD,adjust_var_11]
  \\ full_simp_tac(srw_ss())[MEM_toAList,lookup_inter_alt]);

val state_rel_get_var_RefPtr = Q.store_thm("state_rel_get_var_RefPtr",
  `state_rel c l1 l2 s t v1 locs ∧
   get_var n s.locals = SOME (RefPtr p) ⇒
   ∃f u. get_var (adjust_var n) t = SOME (Word (get_addr c (FAPPLY f p) u))`,
  rw[]
  \\ imp_res_tac state_rel_get_var_IMP
  \\ fs[state_rel_def,wordSemTheory.get_var_def,dataSemTheory.get_var_def]
  \\ full_simp_tac std_ss [Once (GSYM APPEND_ASSOC)]
  \\ drule (GEN_ALL word_ml_inv_lookup)
  \\ disch_then drule
  \\ disch_then drule
  \\ REWRITE_TAC[GSYM APPEND_ASSOC]
  \\ qmatch_goalsub_abbrev_tac`v1 ++ (rr ++ ls)`
  \\ qmatch_abbrev_tac`P (v1 ++ (rr ++ ls)) ⇒ _`
  \\ strip_tac
  \\ `P (rr ++ v1 ++ ls)`
  by (
    unabbrev_all_tac
    \\ match_mp_tac (GEN_ALL (MP_CANON word_ml_inv_rearrange))
    \\ ONCE_REWRITE_TAC[CONJ_COMM]
    \\ asm_exists_tac
    \\ simp[] \\ metis_tac[] )
  \\ pop_assum mp_tac
  \\ pop_assum kall_tac
  \\ simp[Abbr`P`,Abbr`rr`,word_ml_inv_def]
  \\ strip_tac \\ rveq
  \\ fs[abs_ml_inv_def]
  \\ fs[bc_stack_ref_inv_def]
  \\ fs[v_inv_def]
  \\ simp[word_addr_def]
  \\ metis_tac[]);

val state_rel_get_var_Block = Q.store_thm("state_rel_get_var_Block",
  `state_rel c l1 l2 s t v1 locs ∧
   get_var n s.locals = SOME (Block tag vs) ⇒
   ∃w. get_var (adjust_var n) t = SOME (Word w)`,
  rw[]
  \\ imp_res_tac state_rel_get_var_IMP
  \\ fs[state_rel_def,wordSemTheory.get_var_def,dataSemTheory.get_var_def]
  \\ full_simp_tac std_ss [Once (GSYM APPEND_ASSOC)]
  \\ drule (GEN_ALL word_ml_inv_lookup)
  \\ disch_then drule
  \\ disch_then drule
  \\ REWRITE_TAC[GSYM APPEND_ASSOC]
  \\ qmatch_goalsub_abbrev_tac`v1 ++ (rr ++ ls)`
  \\ qmatch_abbrev_tac`P (v1 ++ (rr ++ ls)) ⇒ _`
  \\ strip_tac
  \\ `P (rr ++ v1 ++ ls)`
  by (
    unabbrev_all_tac
    \\ match_mp_tac (GEN_ALL (MP_CANON word_ml_inv_rearrange))
    \\ ONCE_REWRITE_TAC[CONJ_COMM]
    \\ asm_exists_tac
    \\ simp[] \\ metis_tac[] )
  \\ pop_assum mp_tac
  \\ pop_assum kall_tac
  \\ simp[Abbr`P`,Abbr`rr`,word_ml_inv_def]
  \\ strip_tac \\ rveq
  \\ fs[abs_ml_inv_def]
  \\ fs[bc_stack_ref_inv_def]
  \\ fs[v_inv_def]
  \\ qhdtm_x_assum`COND`mp_tac
  \\ IF_CASES_TAC \\ simp[word_addr_def]
  \\ strip_tac \\ rveq
  \\ simp[word_addr_def]);

val state_rel_cut_state_opt_get_var = Q.store_thm("state_rel_cut_state_opt_get_var",
  `state_rel c l1 l2 s t [] locs ∧
   cut_state_opt names_opt s = SOME x ∧
   get_var v x.locals = SOME w ⇒
   ∃s'. state_rel c l1 l2 s' t [] locs ∧
        get_var v s'.locals = SOME w`,
  rw[cut_state_opt_def]
  \\ every_case_tac \\ fs[] >- metis_tac[]
  \\ fs[cut_state_def]
  \\ every_case_tac \\ fs[]
  \\ imp_res_tac state_rel_cut_env
  \\ metis_tac[] );

val jump_exc_push_env_NONE_simp = Q.prove(
  `(jump_exc (dec_clock t) = NONE <=> jump_exc t = NONE) /\
    (jump_exc (push_env y NONE t) = NONE <=> jump_exc t = NONE) /\
    (jump_exc (call_env args s) = NONE <=> jump_exc s = NONE)`,
  full_simp_tac(srw_ss())[wordSemTheory.jump_exc_def,wordSemTheory.call_env_def,
      wordSemTheory.dec_clock_def] \\ srw_tac[][] THEN1 every_case_tac
  \\ full_simp_tac(srw_ss())[wordSemTheory.push_env_def]
  \\ Cases_on `env_to_list y t.permute` \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ Cases_on `t.handler = LENGTH t.stack` \\ full_simp_tac(srw_ss())[LASTN_ADD1]
  \\ Cases_on `~(t.handler < LENGTH t.stack)` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  THEN1 (`F` by DECIDE_TAC)
  \\ `LASTN (t.handler + 1) (StackFrame q NONE::t.stack) =
      LASTN (t.handler + 1) t.stack` by
    (match_mp_tac LASTN_TL \\ decide_tac) \\ full_simp_tac(srw_ss())[]
  \\ every_case_tac \\ CCONTR_TAC
  \\ full_simp_tac(srw_ss())[NOT_LESS]
  \\ `SUC (LENGTH t.stack) <= t.handler + 1` by decide_tac
  \\ imp_res_tac (LASTN_LENGTH_LESS_EQ |> Q.SPEC `x::xs`
       |> SIMP_RULE std_ss [LENGTH]) \\ full_simp_tac(srw_ss())[]);

val s_key_eq_handler_eq_IMP = Q.prove(
  `s_key_eq t.stack t1.stack /\ t.handler = t1.handler ==>
    (jump_exc t1 <> NONE <=> jump_exc t <> NONE)`,
  full_simp_tac(srw_ss())[wordSemTheory.jump_exc_def] \\ srw_tac[][]
  \\ imp_res_tac s_key_eq_LENGTH \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `t1.handler < LENGTH t1.stack` \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac s_key_eq_LASTN
  \\ pop_assum (qspec_then `t1.handler + 1` mp_tac)
  \\ every_case_tac \\ full_simp_tac(srw_ss())[s_key_eq_def,s_frame_key_eq_def]);

val eval_NONE_IMP_jump_exc_NONE_EQ = Q.prove(
  `evaluate (q,t) = (NONE,t1) ==> (jump_exc t1 = NONE <=> jump_exc t = NONE)`,
  srw_tac[][] \\ mp_tac (wordPropsTheory.evaluate_stack_swap |> Q.SPECL [`q`,`t`])
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ imp_res_tac s_key_eq_handler_eq_IMP \\ metis_tac []);

val jump_exc_push_env_SOME = Q.prove(
  `jump_exc (push_env y (SOME (x,prog1,l1,l2)) t) <> NONE`,
  full_simp_tac(srw_ss())[wordSemTheory.jump_exc_def,wordSemTheory.push_env_def]
  \\ Cases_on `env_to_list y t.permute` \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ full_simp_tac(srw_ss())[LASTN_ADD1]);

val eval_push_env_T_Raise_IMP_stack_length = Q.prove(
  `evaluate (p,call_env ys (push_env x T (dec_clock s))) =
       (SOME (Rerr (Rraise a)),r') ==>
    LENGTH r'.stack = LENGTH s.stack`,
  qspecl_then [`p`,`call_env ys (push_env x T (dec_clock s))`]
    mp_tac dataPropsTheory.evaluate_stack_swap
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[call_env_def,jump_exc_def,push_env_def,dataSemTheory.dec_clock_def,LASTN_ADD1]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]);

val eval_push_env_SOME_exc_IMP_s_key_eq = Q.prove(
  `evaluate (p, call_env args1 (push_env y (SOME (x1,x2,x3,x4)) (dec_clock t))) =
      (SOME (Exception l w),t1) ==>
    s_key_eq t1.stack t.stack /\ t.handler = t1.handler`,
  qspecl_then [`p`,`call_env args1 (push_env y (SOME (x1,x2,x3,x4)) (dec_clock t))`]
    mp_tac wordPropsTheory.evaluate_stack_swap
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[wordSemTheory.call_env_def,wordSemTheory.jump_exc_def,
         wordSemTheory.push_env_def,wordSemTheory.dec_clock_def,LASTN_ADD1]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `env_to_list y t.permute` \\ full_simp_tac(srw_ss())[LET_DEF,LASTN_ADD1]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]);

val eval_exc_stack_shorter = Q.prove(
  `evaluate (c,call_env ys (push_env x F (dec_clock s))) =
      (SOME (Rerr (Rraise a)),r') ==>
    LENGTH r'.stack < LENGTH s.stack`,
  srw_tac[][] \\ qspecl_then [`c`,`call_env ys (push_env x F (dec_clock s))`]
             mp_tac dataPropsTheory.evaluate_stack_swap
  \\ full_simp_tac(srw_ss())[] \\ once_rewrite_tac [EQ_SYM_EQ] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[dataSemTheory.jump_exc_def,call_env_def,push_env_def,dataSemTheory.dec_clock_def]
  \\ qpat_x_assum `xx = SOME s2` mp_tac
  \\ rpt (pop_assum (K all_tac))
  \\ full_simp_tac(srw_ss())[LASTN_ALT] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[ADD1]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ match_mp_tac LESS_LESS_EQ_TRANS
  \\ qexists_tac `LENGTH (LASTN (s.handler + 1) s.stack)`
  \\ full_simp_tac(srw_ss())[LENGTH_LASTN_LESS]);

val alloc_size_def = Define `
  alloc_size k = (if k * (dimindex (:'a) DIV 8) < dimword (:α) then
                    n2w (k * (dimindex (:'a) DIV 8))
                  else (-1w)):'a word`

val NOT_1_domain = Q.prove(
  `~(1 IN domain (adjust_set names))`,
  full_simp_tac(srw_ss())[domain_fromAList,adjust_set_def,MEM_MAP,MEM_toAList,
      FORALL_PROD,adjust_var_def] \\ CCONTR_TAC \\ full_simp_tac(srw_ss())[] \\ decide_tac)

val NOT_3_domain = Q.prove(
  `~(3 IN domain (adjust_set names))`,
  full_simp_tac(srw_ss())[domain_fromAList,adjust_set_def,MEM_MAP,MEM_toAList,
      FORALL_PROD,adjust_var_def] \\ CCONTR_TAC \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `p_1'` \\ fs [])

val cut_env_adjust_set_insert_1 = Q.prove(
  `cut_env (adjust_set names) (insert 1 w l) = cut_env (adjust_set names) l`,
  full_simp_tac(srw_ss())[wordSemTheory.cut_env_def,MATCH_MP SUBSET_INSERT_EQ_SUBSET NOT_1_domain]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[lookup_inter,lookup_insert]
  \\ Cases_on `x = 1` \\ full_simp_tac(srw_ss())[] \\ every_case_tac \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[SIMP_RULE std_ss [domain_lookup] NOT_1_domain]);

val cut_env_adjust_set_insert_3 = Q.prove(
  `cut_env (adjust_set names) (insert 3 w l) = cut_env (adjust_set names) l`,
  full_simp_tac(srw_ss())[wordSemTheory.cut_env_def,MATCH_MP SUBSET_INSERT_EQ_SUBSET NOT_3_domain]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[lookup_inter,lookup_insert]
  \\ Cases_on `x = 3` \\ full_simp_tac(srw_ss())[] \\ every_case_tac \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[SIMP_RULE std_ss [domain_lookup] NOT_3_domain]);

val case_EQ_SOME_IFF = Q.prove(
  `(case p of NONE => NONE | SOME x => g x) = SOME y <=>
    ?x. p = SOME x /\ g x = SOME y`,
  Cases_on `p` \\ full_simp_tac(srw_ss())[]);

val state_rel_set_store_AllocSize = Q.prove(
  `state_rel c l1 l2 s (set_store AllocSize (Word w) t) v locs =
    state_rel c l1 l2 s t v locs`,
  full_simp_tac(srw_ss())[state_rel_def,wordSemTheory.set_store_def]
  \\ eq_tac \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[heap_in_memory_store_def,FLOOKUP_DEF,FAPPLY_FUPDATE_THM]
  \\ metis_tac []);

val inter_insert = Q.store_thm("inter_insert",
  `inter (insert n x t1) t2 =
    if n IN domain t2 then insert n x (inter t1 t2) else inter t1 t2`,
  srw_tac[][] \\ full_simp_tac(srw_ss())[spt_eq_thm,wf_inter,wf_insert,lookup_inter_alt,lookup_insert]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]);

val lookup_0_adjust_set = Q.prove(
  `lookup 0 (adjust_set l) = SOME ()`,
  fs[adjust_set_def,lookup_fromAList,ALOOKUP_NONE,MEM_MAP,FORALL_PROD]);

val lookup_1_adjust_set = Q.prove(
  `lookup 1 (adjust_set l) = NONE`,
  full_simp_tac(srw_ss())[adjust_set_def,lookup_fromAList,ALOOKUP_NONE,MEM_MAP,FORALL_PROD]
  \\ full_simp_tac(srw_ss())[adjust_var_def] \\ CCONTR_TAC \\ full_simp_tac(srw_ss())[] \\ decide_tac);

val lookup_3_adjust_set = Q.prove(
  `lookup 3 (adjust_set l) = NONE`,
  full_simp_tac(srw_ss())[adjust_set_def,lookup_fromAList,ALOOKUP_NONE,MEM_MAP,FORALL_PROD]
  \\ full_simp_tac(srw_ss())[adjust_var_def] \\ CCONTR_TAC \\ full_simp_tac(srw_ss())[] \\ decide_tac);

val lookup_ODD_adjust_set = Q.prove(
  `ODD n ==> lookup n (adjust_set l) = NONE`,
  fs[adjust_set_def,lookup_fromAList,ALOOKUP_NONE,MEM_MAP,FORALL_PROD]
  \\ IF_CASES_TAC \\ fs [] \\ rw [] \\ fs []
  \\ fs[adjust_set_def,lookup_fromAList,ALOOKUP_NONE,MEM_MAP,FORALL_PROD]
  \\ CCONTR_TAC \\ fs [] \\ rveq
  \\ fs [EVEN_adjust_var,ODD_EVEN]);

val wf_adjust_set = Q.store_thm("wf_adjust_set",
  `wf (adjust_set s)`,
  fs [adjust_set_def,wf_fromAList]);

val lookup_adjust_set = Q.store_thm("lookup_adjust_set",
  `lookup n (adjust_set s) =
   if n = 0 then SOME () else
   if ODD n then NONE else
   if (n - 2) DIV 2 IN domain s then SOME () else NONE`,
  fs[adjust_set_def,lookup_fromAList,ALOOKUP_NONE,MEM_MAP,FORALL_PROD]
  \\ IF_CASES_TAC \\ fs [] \\ rw []
  \\ fs[adjust_set_def,lookup_fromAList,ALOOKUP_NONE,MEM_MAP,FORALL_PROD]
  \\ CCONTR_TAC \\ fs [] \\ rveq \\ fs [EVEN_adjust_var,ODD_EVEN]
  \\ fs [domain_lookup,MEM_toAList,adjust_var_DIV_2]
  \\ Cases_on `ALOOKUP (MAP (λ(n,k). (adjust_var n,())) (toAList s)) n`
  \\ fs []
  \\ fs[adjust_set_def,lookup_fromAList,ALOOKUP_NONE,MEM_MAP,FORALL_PROD]
  \\ pop_assum mp_tac \\ fs []
  \\ fs [domain_lookup,MEM_toAList,adjust_var_DIV_2]
  \\ qexists_tac `(n − 2) DIV 2` \\ fs []
  \\ fs [adjust_var_def]
  \\ imp_res_tac EVEN_ODD_EXISTS \\ rveq
  \\ Cases_on `m` \\ fs [MULT_CLAUSES]
  \\ fs [ONCE_REWRITE_RULE [MULT_COMM] MULT_DIV]);

val adjust_set_inter = Q.store_thm("adjust_set_inter",
  `adjust_set (inter t1 t2) = inter (adjust_set t1) (adjust_set t2)`,
  fs [wf_adjust_set,wf_inter,spt_eq_thm,lookup_inter_alt,domain_lookup]
  \\ strip_tac \\ Cases_on `ODD n` \\ fs [lookup_ODD_adjust_set]
  \\ Cases_on `n = 0` \\ fs [lookup_0_adjust_set]
  \\ fs [lookup_adjust_set]
  \\ fs [domain_inter] \\ rw [] \\ fs []);

val state_rel_insert_1 = Q.prove(
  `state_rel c l1 l2 s (t with locals := insert 1 x t.locals) v locs =
    state_rel c l1 l2 s t v locs`,
  full_simp_tac(srw_ss())[state_rel_def] \\ eq_tac \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[lookup_insert,adjust_var_NEQ_1]
  \\ full_simp_tac(srw_ss())[inter_insert,domain_lookup,lookup_1_adjust_set]
  \\ metis_tac []);

val state_rel_insert_3 = Q.prove(
  `state_rel c l1 l2 s (t with locals := insert 3 x t.locals) v locs =
    state_rel c l1 l2 s t v locs`,
  full_simp_tac(srw_ss())[state_rel_def] \\ eq_tac \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[lookup_insert,adjust_var_NEQ_1]
  \\ asm_exists_tac \\ fs []
  \\ full_simp_tac(srw_ss())[inter_insert,domain_lookup,lookup_3_adjust_set]);

val state_rel_insert_7 = Q.prove(
  `state_rel c l1 l2 s (t with locals := insert 7 x t.locals) v locs =
    state_rel c l1 l2 s t v locs`,
  full_simp_tac(srw_ss())[state_rel_def] \\ eq_tac \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[lookup_insert,adjust_var_NEQ_1]
  \\ asm_exists_tac \\ fs []
  \\ full_simp_tac(srw_ss())[inter_insert,domain_lookup,lookup_ODD_adjust_set]);

val state_rel_insert_3_1 = Q.prove(
  `state_rel c l1 l2 s (t with locals := insert 3 x (insert 1 y t.locals)) v locs =
    state_rel c l1 l2 s t v locs`,
  full_simp_tac(srw_ss())[state_rel_def] \\ eq_tac \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[lookup_insert,adjust_var_NEQ_1]
  \\ asm_exists_tac \\ fs []
  \\ full_simp_tac(srw_ss())[inter_insert,domain_lookup,
        lookup_3_adjust_set,lookup_1_adjust_set]);

val state_rel_inc_clock = Q.prove(
  `state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs ==>
    state_rel c l1 l2 (s with clock := s.clock + 1)
                      (t with clock := t.clock + 1) [] locs`,
  full_simp_tac(srw_ss())[state_rel_def]);

val dec_clock_inc_clock = Q.prove(
  `(dataSem$dec_clock (s with clock := s.clock + 1) = s) /\
    (wordSem$dec_clock (t with clock := t.clock + 1) = t)`,
  full_simp_tac(srw_ss())[dataSemTheory.dec_clock_def,wordSemTheory.dec_clock_def]
  \\ full_simp_tac(srw_ss())[dataSemTheory.state_component_equality]
  \\ full_simp_tac(srw_ss())[wordSemTheory.state_component_equality])

val word_gc_move_IMP_isWord = Q.prove(
  `word_gc_move c' (Word c,i,pa,old,m,dm) = (w1,i1,pa1,m1,c1) ==> isWord w1`,
  full_simp_tac(srw_ss())[word_gc_move_def,LET_DEF]
  \\ CONV_TAC (DEPTH_CONV PairRules.PBETA_CONV)
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[isWord_def]);

val word_gc_move_roots_IMP_FILTER = Q.prove(
  `!ws i pa old m dm ws2 i2 pa2 m2 c2 c.
      word_gc_move_roots c (ws,i,pa,old,m,dm) = (ws2,i2,pa2,m2,c2) ==>
      word_gc_move_roots c (FILTER isWord ws,i,pa,old,m,dm) =
                           (FILTER isWord ws2,i2,pa2,m2,c2)`,
  Induct \\ full_simp_tac(srw_ss())[word_gc_move_roots_def] \\ Cases \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[word_gc_move_roots_def]
  THEN1
   (srw_tac[][] \\ full_simp_tac(srw_ss())[LET_DEF] \\ imp_res_tac word_gc_move_IMP_isWord
    \\ Cases_on `word_gc_move_roots c' (ws,i1,pa1,old,m1,dm)` \\ full_simp_tac(srw_ss())[]
    \\ PairCases_on `r` \\ full_simp_tac(srw_ss())[] \\ res_tac \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ srw_tac[][])
  \\ full_simp_tac(srw_ss())[isWord_def,word_gc_move_def,LET_DEF]
  \\ Cases_on `word_gc_move_roots c (ws,i,pa,old,m,dm)`
  \\ PairCases_on `r` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[isWord_def]);

val IMP_EQ_DISJ = METIS_PROVE [] ``(b1 ==> b2) <=> ~b1 \/ b2``

val word_gc_fun_IMP_FILTER = Q.prove(
  `word_gc_fun c (xs,m,dm,s) = SOME (stack1,m1,s1) ==>
    word_gc_fun c (FILTER isWord xs,m,dm,s) = SOME (FILTER isWord stack1,m1,s1)`,
  full_simp_tac(srw_ss())[word_gc_fun_def,LET_THM,word_gc_fun_def,word_full_gc_def]
  \\ rpt (pairarg_tac \\ full_simp_tac(srw_ss())[])
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[word_gc_move_roots_def,LET_THM]
  \\ rpt (pairarg_tac \\ full_simp_tac(srw_ss())[])
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac word_gc_move_roots_IMP_FILTER
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ rev_full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[])

val loc_merge_def = Define `
  (loc_merge [] ys = []) /\
  (loc_merge (Loc l1 l2::xs) ys = Loc l1 l2::loc_merge xs ys) /\
  (loc_merge (Word w::xs) (y::ys) = y::loc_merge xs ys) /\
  (loc_merge (Word w::xs) [] = Word w::xs)`

val LENGTH_loc_merge = Q.prove(
  `!xs ys. LENGTH (loc_merge xs ys) = LENGTH xs`,
  Induct \\ Cases_on `ys` \\ full_simp_tac(srw_ss())[loc_merge_def]
  \\ Cases_on `h` \\ full_simp_tac(srw_ss())[loc_merge_def]
  \\ Cases_on `h'` \\ full_simp_tac(srw_ss())[loc_merge_def]);

val word_gc_move_roots_IMP_FILTER = Q.prove(
  `!ws i pa old m dm ws2 i2 pa2 m2 c2 c.
      word_gc_move_roots c (FILTER isWord ws,i,pa,old,m,dm) = (ws2,i2,pa2,m2,c2) ==>
      word_gc_move_roots c (ws,i,pa,old,m,dm) =
                           (loc_merge ws ws2,i2,pa2,m2,c2)`,
  Induct \\ full_simp_tac(srw_ss())[word_gc_move_roots_def,loc_merge_def]
  \\ reverse Cases \\ full_simp_tac(srw_ss())[isWord_def,loc_merge_def,LET_DEF]
  THEN1
   (full_simp_tac(srw_ss())[word_gc_move_def] \\ srw_tac[][]
    \\ Cases_on `word_gc_move_roots c (ws,i,pa,old,m,dm)` \\ full_simp_tac(srw_ss())[]
    \\ PairCases_on `r` \\ full_simp_tac(srw_ss())[] \\ res_tac \\ full_simp_tac(srw_ss())[])
  \\ full_simp_tac(srw_ss())[word_gc_move_roots_def,loc_merge_def] \\ srw_tac[][]
  \\ Cases_on `word_gc_move c' (Word c,i,pa,old,m,dm)`
  \\ PairCases_on `r` \\ full_simp_tac(srw_ss())[] \\ res_tac \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ Cases_on `word_gc_move_roots c' (FILTER isWord ws,r0,r1,old,r2,dm)`
  \\ PairCases_on `r` \\ full_simp_tac(srw_ss())[] \\ res_tac \\ full_simp_tac(srw_ss())[LET_DEF] \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[loc_merge_def]);

val word_gc_fun_loc_merge = Q.prove(
  `word_gc_fun c (FILTER isWord xs,m,dm,s) = SOME (ys,m1,s1) ==>
    word_gc_fun c (xs,m,dm,s) = SOME (loc_merge xs ys,m1,s1)`,
  full_simp_tac(srw_ss())[word_gc_fun_def,LET_THM,word_gc_fun_def,word_full_gc_def]
  \\ rpt (pairarg_tac \\ full_simp_tac(srw_ss())[])
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[word_gc_move_roots_def,LET_THM]
  \\ rpt (pairarg_tac \\ full_simp_tac(srw_ss())[])
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac word_gc_move_roots_IMP_FILTER
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ rev_full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[]);

val word_gc_fun_IMP = Q.prove(
  `word_gc_fun c (xs,m,dm,s) = SOME (ys,m1,s1) ==>
    FLOOKUP s1 AllocSize = FLOOKUP s AllocSize /\
    FLOOKUP s1 Handler = FLOOKUP s Handler /\
    Globals IN FDOM s1`,
  full_simp_tac(srw_ss())[IMP_EQ_DISJ,word_gc_fun_def] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[GSYM IMP_EQ_DISJ,word_gc_fun_def] \\ srw_tac[][]
  \\ UNABBREV_ALL_TAC \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ EVAL_TAC)

val word_gc_move_roots_IMP_EVERY2 = Q.prove(
  `!xs ys pa m i c1 m1 pa1 i1 old dm c.
      word_gc_move_roots c (xs,i,pa,old,m,dm) = (ys,i1,pa1,m1,c1) ==>
      EVERY2 (\x y. (isWord x <=> isWord y) /\
                    (is_gc_word_const x ==> x = y)) xs ys`,
  Induct \\ full_simp_tac(srw_ss())[word_gc_move_roots_def]
  \\ full_simp_tac(srw_ss())[IMP_EQ_DISJ,word_gc_fun_def] \\ srw_tac[][]
  \\ CCONTR_TAC \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[GSYM IMP_EQ_DISJ,word_gc_fun_def] \\ srw_tac[][] \\ res_tac
  \\ qpat_x_assum `word_gc_move c (h,i,pa,old,m,dm) = (w1,i1',pa1',m1',c1')` mp_tac
  \\ full_simp_tac(srw_ss())[] \\ Cases_on `h` \\ full_simp_tac(srw_ss())[word_gc_move_def] \\ srw_tac[][]
  \\ CCONTR_TAC \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[isWord_def]
  \\ UNABBREV_ALL_TAC \\ srw_tac[][] \\ pop_assum mp_tac \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ CCONTR_TAC \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ fs[isWord_def,word_simpProofTheory.is_gc_word_const_def,
        word_simpTheory.is_gc_const_def]);

val word_gc_IMP_EVERY2 = Q.prove(
  `word_gc_fun c (xs,m,dm,st) = SOME (ys,m1,s1) ==>
    EVERY2 (\x y. (isWord x <=> isWord y) /\ (is_gc_word_const x ==> x = y)) xs ys`,
  full_simp_tac(srw_ss())[word_gc_fun_def,LET_THM,word_gc_fun_def,word_full_gc_def]
  \\ rpt (pairarg_tac \\ full_simp_tac(srw_ss())[])
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[word_gc_move_roots_def,LET_THM]
  \\ rpt (pairarg_tac \\ full_simp_tac(srw_ss())[])
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac word_gc_move_roots_IMP_EVERY2);

val gc_fun_const_ok_word_gc_fun = Q.prove(
  `gc_fun_const_ok (word_gc_fun c)`,
  fs [word_simpProofTheory.gc_fun_const_ok_def] \\ rw []
  \\ PairCases_on `x` \\ fs [] \\ PairCases_on `y` \\ fs []
  \\ imp_res_tac word_gc_IMP_EVERY2
  \\ pop_assum mp_tac
  \\ match_mp_tac LIST_REL_mono \\ fs []);

val word_gc_fun_LENGTH = Q.store_thm("word_gc_fun_LENGTH",
  `word_gc_fun c (xs,m,dm,s) = SOME (zs,m1,s1) ==> LENGTH xs = LENGTH zs`,
  srw_tac[][] \\ drule word_gc_IMP_EVERY2 \\ srw_tac[][] \\ imp_res_tac EVERY2_LENGTH);

val gc_fun_ok_word_gc_fun = Q.store_thm("gc_fun_ok_word_gc_fun",
  `gc_fun_ok (word_gc_fun c1)`,
  fs [gc_fun_ok_def] \\ rpt gen_tac \\ strip_tac
  \\ imp_res_tac word_gc_fun_LENGTH \\ fs []
  \\ imp_res_tac word_gc_fun_IMP
  \\ fs [FLOOKUP_DEF]
  \\ fs [word_gc_fun_def]
  \\ pairarg_tac \\ fs []
  \\ fs [DOMSUB_FAPPLY_THM]
  \\ rpt var_eq_tac \\ fs []
  \\ fs [word_gc_fun_assum_def,DOMSUB_FAPPLY_THM]
  \\ fs [fmap_EXT,FUPDATE_LIST,EXTENSION]
  \\ conj_tac THEN1 metis_tac []
  \\ fs [FAPPLY_FUPDATE_THM,DOMSUB_FAPPLY_THM]
  \\ rw [] \\ fs []);

val word_gc_fun_APPEND_IMP = Q.prove(
  `word_gc_fun c (xs ++ ys,m,dm,s) = SOME (zs,m1,s1) ==>
    ?zs1 zs2. zs = zs1 ++ zs2 /\ LENGTH xs = LENGTH zs1 /\ LENGTH ys = LENGTH zs2`,
  srw_tac[][] \\ imp_res_tac word_gc_fun_LENGTH \\ full_simp_tac(srw_ss())[LENGTH_APPEND]
  \\ pop_assum mp_tac \\ pop_assum (K all_tac)
  \\ qspec_tac (`zs`,`zs`) \\ qspec_tac (`ys`,`ys`) \\ qspec_tac (`xs`,`xs`)
  \\ Induct \\ full_simp_tac(srw_ss())[] \\ Cases_on `zs` \\ full_simp_tac(srw_ss())[LENGTH_NIL] \\ srw_tac[][]
  \\ once_rewrite_tac [EQ_SYM_EQ] \\ full_simp_tac(srw_ss())[LENGTH_NIL]
  \\ full_simp_tac(srw_ss())[ADD_CLAUSES] \\ res_tac
  \\ full_simp_tac(srw_ss())[] \\ Q.LIST_EXISTS_TAC [`h::zs1`,`zs2`] \\ full_simp_tac(srw_ss())[]);

val IMP_loc_merge_APPEND = Q.prove(
  `!ts qs xs ys.
      LENGTH (FILTER isWord ts) = LENGTH qs ==>
      loc_merge (ts ++ xs) (qs ++ ys) = loc_merge ts qs ++ loc_merge xs ys`,
  Induct \\ full_simp_tac(srw_ss())[] THEN1 (Cases_on `qs` \\ full_simp_tac(srw_ss())[LENGTH,loc_merge_def])
  \\ Cases \\ full_simp_tac(srw_ss())[isWord_def,loc_merge_def]
  \\ Cases \\ full_simp_tac(srw_ss())[loc_merge_def]) |> SPEC_ALL;

val TAKE_DROP_loc_merge_APPEND = Q.prove(
  `TAKE (LENGTH q) (loc_merge (MAP SND q) xs ++ ys) = loc_merge (MAP SND q) xs /\
    DROP (LENGTH q) (loc_merge (MAP SND q) xs ++ ys) = ys`,
  `LENGTH q = LENGTH (loc_merge (MAP SND q) xs)` by full_simp_tac(srw_ss())[LENGTH_loc_merge]
  \\ full_simp_tac(srw_ss())[TAKE_LENGTH_APPEND,DROP_LENGTH_APPEND]);

val loc_merge_NIL = Q.prove(
  `!xs. loc_merge xs [] = xs`,
  Induct \\ full_simp_tac(srw_ss())[loc_merge_def] \\ Cases \\ full_simp_tac(srw_ss())[loc_merge_def]);

val loc_merge_APPEND = Q.prove(
  `!xs1 xs2 ys.
      ?zs1 zs2. loc_merge (xs1 ++ xs2) ys = zs1 ++ zs2 /\
                LENGTH zs1 = LENGTH xs1 /\ LENGTH xs2 = LENGTH xs2 /\
                ?ts. loc_merge xs2 ts = zs2`,
  Induct \\ full_simp_tac(srw_ss())[loc_merge_def,LENGTH_NIL,LENGTH_loc_merge] THEN1 (metis_tac [])
  \\ Cases THEN1
   (Cases_on `ys` \\ full_simp_tac(srw_ss())[loc_merge_def] \\ srw_tac[][]
    THEN1 (Q.LIST_EXISTS_TAC [`Word c::xs1`,`xs2`] \\ full_simp_tac(srw_ss())[]
           \\ qexists_tac `[]` \\ full_simp_tac(srw_ss())[loc_merge_NIL])
    \\ pop_assum (qspecl_then [`xs2`,`t`] strip_assume_tac)
    \\ full_simp_tac(srw_ss())[] \\ Q.LIST_EXISTS_TAC [`h::zs1`,`zs2`] \\ full_simp_tac(srw_ss())[] \\ metis_tac [])
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[loc_merge_def]
  \\ pop_assum (qspecl_then [`xs2`,`ys`] strip_assume_tac)
  \\ full_simp_tac(srw_ss())[] \\ Q.LIST_EXISTS_TAC [`Loc n n0::zs1`,`zs2`] \\ full_simp_tac(srw_ss())[] \\ metis_tac [])

val EVERY2_loc_merge = Q.prove(
  `!xs ys. EVERY2 (\x y. (isWord y ==> isWord x) /\
                          (~isWord x ==> x = y)) xs (loc_merge xs ys)`,
  Induct \\ full_simp_tac(srw_ss())[loc_merge_def,LENGTH_NIL,LENGTH_loc_merge] \\ Cases
  \\ full_simp_tac(srw_ss())[loc_merge_def] \\ Cases_on `ys`
  \\ full_simp_tac(srw_ss())[loc_merge_def,GSYM EVERY2_refl,isWord_def])

val dec_stack_loc_merge_enc_stack = Q.prove(
  `!xs ys. ?ss. dec_stack (loc_merge (enc_stack xs) ys) xs = SOME ss`,
  Induct \\ full_simp_tac(srw_ss())[wordSemTheory.enc_stack_def,
    loc_merge_def,wordSemTheory.dec_stack_def]
  \\ Cases \\ Cases_on `o'` \\ full_simp_tac(srw_ss())[] \\ TRY (PairCases_on `x`)
  \\ full_simp_tac(srw_ss())[wordSemTheory.enc_stack_def] \\ srw_tac[][]
  \\ qspecl_then [`MAP SND l`,`enc_stack xs`,`ys`] mp_tac loc_merge_APPEND
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[wordSemTheory.dec_stack_def]
  \\ pop_assum (fn th => full_simp_tac(srw_ss())[GSYM th])
  \\ full_simp_tac(srw_ss())[DROP_LENGTH_APPEND]
  \\ first_assum (qspec_then `ts` strip_assume_tac) \\ full_simp_tac(srw_ss())[]
  \\ decide_tac);

val ALOOKUP_ZIP = Q.prove(
  `!l zs1.
      ALOOKUP l (0:num) = SOME (Loc q r) /\
      LIST_REL (λx y. (isWord y ⇒ isWord x) ∧
        (¬isWord x ⇒ x = y)) (MAP SND l) zs1 ==>
      ALOOKUP (ZIP (MAP FST l,zs1)) 0 = SOME (Loc q r)`,
  Induct \\ full_simp_tac(srw_ss())[] \\ Cases \\ full_simp_tac(srw_ss())[ALOOKUP_def,PULL_EXISTS]
  \\ Cases_on `q' = 0` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[isWord_def] \\ srw_tac[][]);

val stack_rel_dec_stack_IMP_stack_rel = Q.prove(
  `!xs ys ts stack locs.
      LIST_REL stack_rel ts xs /\ LIST_REL contains_loc xs locs /\
      dec_stack (loc_merge (enc_stack xs) ys) xs = SOME stack ==>
      LIST_REL stack_rel ts stack /\ LIST_REL contains_loc stack locs`,
  Induct_on `ts` \\ Cases_on `xs` \\ full_simp_tac(srw_ss())[]
  THEN1 (full_simp_tac(srw_ss())[wordSemTheory.enc_stack_def,loc_merge_def,wordSemTheory.dec_stack_def])
  \\ full_simp_tac(srw_ss())[PULL_EXISTS] \\ srw_tac[][]
  \\ Cases_on `h` \\ Cases_on `o'` \\ TRY (PairCases_on `x`) \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[wordSemTheory.enc_stack_def,wordSemTheory.dec_stack_def]
  \\ qspecl_then [`MAP SND l`,`enc_stack t`,`ys`] mp_tac loc_merge_APPEND
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ pop_assum (fn th => full_simp_tac(srw_ss())[GSYM th] THEN assume_tac th)
  \\ full_simp_tac(srw_ss())[DROP_LENGTH_APPEND,TAKE_LENGTH_APPEND]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[]
  \\ pop_assum (fn th => full_simp_tac(srw_ss())[GSYM th])
  \\ res_tac \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `h'` \\ full_simp_tac(srw_ss())[stack_rel_def]
  \\ full_simp_tac(srw_ss())[lookup_fromAList,IS_SOME_ALOOKUP_EQ]
  \\ full_simp_tac(srw_ss())[EVERY_MEM,FORALL_PROD] \\ Cases_on `y`
  \\ full_simp_tac(srw_ss())[contains_loc_def]
  \\ qspecl_then [`MAP SND l ++ enc_stack t`,`ys`] mp_tac EVERY2_loc_merge
  \\ full_simp_tac(srw_ss())[] \\ strip_tac
  \\ `LENGTH (MAP SND l) = LENGTH zs1` by full_simp_tac(srw_ss())[]
  \\ imp_res_tac LIST_REL_APPEND_IMP \\ full_simp_tac(srw_ss())[MAP_ZIP]
  \\ full_simp_tac(srw_ss())[AND_IMP_INTRO]
  \\ `ALOOKUP (ZIP (MAP FST l,zs1)) 0 = SOME (Loc q r)` by
   (`LENGTH (MAP SND l) = LENGTH zs1` by full_simp_tac(srw_ss())[]
    \\ imp_res_tac LIST_REL_APPEND_IMP \\ full_simp_tac(srw_ss())[MAP_ZIP]
    \\ imp_res_tac ALOOKUP_ZIP \\ full_simp_tac(srw_ss())[] \\ NO_TAC)
  \\ full_simp_tac(srw_ss())[] \\ NTAC 3 strip_tac \\ first_x_assum match_mp_tac
  \\ rev_full_simp_tac(srw_ss())[MEM_ZIP] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[EL_MAP]
  \\ Q.MATCH_ASSUM_RENAME_TAC `isWord (EL k zs1)`
  \\ full_simp_tac(srw_ss())[MEM_EL,PULL_EXISTS] \\ asm_exists_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[FST_PAIR_EQ]
  \\ imp_res_tac EVERY2_IMP_EL \\ rev_full_simp_tac(srw_ss())[EL_MAP]);

val join_env_NIL = Q.prove(
  `join_env s [] = []`,
  full_simp_tac(srw_ss())[join_env_def]);

val join_env_CONS = Q.prove(
  `join_env s ((n,v)::xs) =
    if n <> 0 /\ EVEN n then
      (THE (lookup ((n - 2) DIV 2) s),v)::join_env s xs
    else join_env s xs`,
  full_simp_tac(srw_ss())[join_env_def] \\ srw_tac[][]);

val FILTER_enc_stack_lemma = Q.prove(
  `!xs ys.
      LIST_REL stack_rel xs ys ==>
      FILTER isWord (MAP SND (flat xs ys)) =
      FILTER isWord (enc_stack ys)`,
  Induct \\ Cases_on `ys`
  \\ full_simp_tac(srw_ss())[stack_rel_def,wordSemTheory.enc_stack_def,flat_def]
  \\ Cases \\ Cases_on `h` \\ full_simp_tac(srw_ss())[] \\ Cases_on `o'`
  \\ TRY (PairCases_on `x`) \\ full_simp_tac(srw_ss())[stack_rel_def] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[wordSemTheory.enc_stack_def,flat_def,FILTER_APPEND]
  \\ qpat_x_assum `EVERY (\(x1,x2). isWord x2 ==> x1 <> 0 /\ EVEN x1) l` mp_tac
  \\ rpt (pop_assum (K all_tac))
  \\ Induct_on `l` \\ full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[join_env_NIL]
  \\ Cases \\ full_simp_tac(srw_ss())[join_env_CONS] \\ srw_tac[][]);

val stack_rel_simp = Q.prove(
  `(stack_rel (Env s) y <=>
     ?vs. stack_rel (Env s) y /\ (y = StackFrame vs NONE)) /\
    (stack_rel (Exc s n) y <=>
     ?vs x1 x2 x3. stack_rel (Exc s n) y /\ (y = StackFrame vs (SOME (x1,x2,x3))))`,
  Cases_on `y` \\ full_simp_tac(srw_ss())[stack_rel_def] \\ Cases_on `o'`
  \\ full_simp_tac(srw_ss())[stack_rel_def] \\ PairCases_on `x`
  \\ full_simp_tac(srw_ss())[stack_rel_def,CONJ_ASSOC]);

val join_env_EQ_ZIP = Q.prove(
  `!vs s zs1.
      EVERY (\(x1,x2). isWord x2 ==> x1 <> 0 /\ EVEN x1) vs /\
      LENGTH (join_env s vs) = LENGTH zs1 /\
      LIST_REL (\x y. isWord x = isWord y /\ (~isWord x ==> x = y))
         (MAP SND (join_env s vs)) zs1 ==>
      join_env s
        (ZIP (MAP FST vs,loc_merge (MAP SND vs) (FILTER isWord zs1))) =
      ZIP (MAP FST (join_env s vs),zs1)`,
  Induct \\ simp [join_env_NIL,loc_merge_def] \\ rpt strip_tac
  \\ Cases_on `h` \\ simp [] \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `r` \\ full_simp_tac(srw_ss())[isWord_def]
  \\ full_simp_tac(srw_ss())[loc_merge_def] \\ full_simp_tac(srw_ss())[join_env_CONS] \\ rev_full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ rev_full_simp_tac(srw_ss())[isWord_def] \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `y` \\ full_simp_tac(srw_ss())[loc_merge_def,join_env_CONS,isWord_def]);

val LENGTH_MAP_SND_join_env_IMP = Q.prove(
  `!vs zs1 s.
      LIST_REL (\x y. (isWord x = isWord y) /\ (~isWord x ==> x = y))
        (MAP SND (join_env s vs)) zs1 /\
      EVERY (\(x1,x2). isWord x2 ==> x1 <> 0 /\ EVEN x1) vs /\
      LENGTH (join_env s vs) = LENGTH zs1 ==>
      LENGTH (FILTER isWord (MAP SND vs)) = LENGTH (FILTER isWord zs1)`,
  Induct \\ rpt strip_tac THEN1
   (pop_assum mp_tac \\ simp [join_env_NIL]
    \\ Cases_on `zs1` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][])
  \\ Cases_on `h` \\ full_simp_tac(srw_ss())[join_env_CONS] \\ srw_tac[][]
  THEN1 (full_simp_tac(srw_ss())[] \\ rev_full_simp_tac(srw_ss())[] \\ first_assum match_mp_tac \\ metis_tac[])
  \\ full_simp_tac(srw_ss())[] \\ Cases_on `q <> 0 /\ EVEN q`
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ metis_tac [])

val lemma1 = Q.prove(`(y1 = y2) /\ (x1 = x2) ==> (f x1 y1 = f x2 y2)`,full_simp_tac(srw_ss())[]);

val word_gc_fun_EL_lemma = Q.prove(
  `!xs ys stack1 m dm st m1 s1 stack.
      LIST_REL stack_rel xs stack /\
      EVERY2 (\x y. isWord x = isWord y /\ (~isWord x ==> x = y))
         (MAP SND (flat xs ys)) stack1 /\
      dec_stack (loc_merge (enc_stack ys) (FILTER isWord stack1)) ys =
        SOME stack /\ LIST_REL stack_rel xs ys ==>
      (flat xs stack =
       ZIP (MAP FST (flat xs ys),stack1))`,
  Induct THEN1 (EVAL_TAC \\ full_simp_tac(srw_ss())[] \\ EVAL_TAC \\ srw_tac[][] \\ srw_tac[][flat_def])
  \\ Cases_on `h` \\ full_simp_tac(srw_ss())[] \\ once_rewrite_tac [stack_rel_simp]
  \\ full_simp_tac(srw_ss())[PULL_EXISTS,stack_rel_def,flat_def,wordSemTheory.enc_stack_def]
  \\ srw_tac[][] \\ imp_res_tac EVERY2_APPEND_IMP \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[FILTER_APPEND]
  \\ `LENGTH (FILTER isWord (MAP SND vs')) = LENGTH (FILTER isWord zs1)` by
   (imp_res_tac EVERY2_LENGTH \\ full_simp_tac(srw_ss())[]
    \\ imp_res_tac LENGTH_MAP_SND_join_env_IMP)
  \\ imp_res_tac IMP_loc_merge_APPEND \\ full_simp_tac(srw_ss())[]
  \\ qpat_x_assum `dec_stack xx dd = SOME yy` mp_tac
  \\ full_simp_tac(srw_ss())[wordSemTheory.dec_stack_def]
  \\ full_simp_tac(srw_ss())[TAKE_DROP_loc_merge_APPEND,LENGTH_loc_merge,DECIDE ``~(n+m<n:num)``]
  \\ CASE_TAC \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[flat_def] \\ imp_res_tac EVERY2_LENGTH \\ full_simp_tac(srw_ss())[GSYM ZIP_APPEND]
  \\ match_mp_tac lemma1
  \\ rpt strip_tac \\ TRY (first_x_assum match_mp_tac \\ full_simp_tac(srw_ss())[])
  \\ TRY (match_mp_tac join_env_EQ_ZIP) \\ full_simp_tac(srw_ss())[]) |> SPEC_ALL;

val state_rel_gc = Q.prove(
  `state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs ==>
    FLOOKUP t.store AllocSize = SOME (Word (alloc_size k)) /\
    s.locals = LN /\
    t.locals = LS (Loc l1 l2) ==>
    ?t2 wl m st w1 w2 stack.
      t.gc_fun (enc_stack t.stack,t.memory,t.mdomain,t.store) =
        SOME (wl,m,st) /\
      dec_stack wl t.stack = SOME stack /\
      FLOOKUP st (Temp 29w) = FLOOKUP t.store (Temp 29w) /\
      FLOOKUP st AllocSize = SOME (Word (alloc_size k)) /\
      state_rel c l1 l2 (s with space := 0)
        (t with <|stack := stack; store := st; memory := m|>) [] locs`,
  full_simp_tac(srw_ss())[state_rel_def] \\ srw_tac[][] \\ rev_full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[] \\ rev_full_simp_tac(srw_ss())[lookup_def] \\ srw_tac[][]
  \\ qhdtm_x_assum `word_ml_inv` mp_tac
  \\ Q.PAT_ABBREV_TAC `pat = join_env LN _` \\ srw_tac[][]
  \\ `pat = []` by (UNABBREV_ALL_TAC \\ EVAL_TAC) \\ full_simp_tac(srw_ss())[]
  \\ rev_full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[] \\ pop_assum (K all_tac)
  \\ first_x_assum (fn th1 => first_x_assum (fn th2 => first_x_assum (fn th3 =>
       mp_tac (MATCH_MP word_gc_fun_correct (CONJ th1 (CONJ th2 th3))))))
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac word_gc_fun_IMP_FILTER
  \\ imp_res_tac FILTER_enc_stack_lemma \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac word_gc_fun_loc_merge \\ full_simp_tac(srw_ss())[FILTER_APPEND]
  \\ imp_res_tac word_gc_fun_IMP \\ full_simp_tac(srw_ss())[]
  \\ `?stack. dec_stack (loc_merge (enc_stack t.stack) (FILTER isWord stack1))
        t.stack = SOME stack` by metis_tac [dec_stack_loc_merge_enc_stack]
  \\ asm_exists_tac \\ full_simp_tac(srw_ss())[]
  \\ conj_tac
  THEN1 (fs [word_gc_fun_def] \\ pairarg_tac \\ fs [] \\ rveq \\ EVAL_TAC)
  \\ imp_res_tac stack_rel_dec_stack_IMP_stack_rel \\ full_simp_tac(srw_ss())[]
  \\ asm_exists_tac \\ full_simp_tac(srw_ss())[]
  \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
  \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ disj2_tac
  \\ pop_assum mp_tac
  \\ match_mp_tac (METIS_PROVE [] ``x=y==>(x==>y)``)
  \\ AP_TERM_TAC
  \\ AP_TERM_TAC
  \\ match_mp_tac (GEN_ALL word_gc_fun_EL_lemma)
  \\ imp_res_tac word_gc_IMP_EVERY2
  \\ full_simp_tac(srw_ss())[]
  \\ pop_assum mp_tac
  \\ match_mp_tac LIST_REL_mono
  \\ fs [] \\ Cases \\ fs []
  \\ fs [word_simpProofTheory.is_gc_word_const_def,isWord_def]);

val gc_lemma = Q.prove(
  `let t0 = call_env [Loc l1 l2] (push_env y
        (NONE:(num # 'a wordLang$prog # num # num) option) t) in
      dataSem$cut_env names (s:'ffi dataSem$state).locals = SOME x /\
      state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs /\
      FLOOKUP t.store AllocSize = SOME (Word (alloc_size k)) /\
      wordSem$cut_env (adjust_set names) t.locals = SOME y ==>
      ?t2 wl m st w1 w2 stack.
        t0.gc_fun (enc_stack t0.stack,t0.memory,t0.mdomain,t0.store) =
          SOME (wl,m,st) /\
        dec_stack wl t0.stack = SOME stack /\
        pop_env (t0 with <|stack := stack; store := st; memory := m|>) = SOME t2 /\
        FLOOKUP t2.store (Temp 29w) = FLOOKUP t.store (Temp 29w) ∧
        FLOOKUP t2.store AllocSize = SOME (Word (alloc_size k)) /\
        state_rel c l1 l2 (s with <| locals := x; space := 0 |>) t2 [] locs`,
  srw_tac[][] \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ Q.UNABBREV_TAC `t0` \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac (state_rel_call_env_push_env
      |> Q.SPEC `NONE` |> Q.INST [`args`|->`[]`] |> GEN_ALL
      |> SIMP_RULE std_ss [MAP,get_vars_def,wordSemTheory.get_vars_def]
      |> SPEC_ALL |> REWRITE_RULE [GSYM AND_IMP_INTRO]
      |> (fn th => MATCH_MP th (UNDISCH state_rel_inc_clock))
      |> SIMP_RULE (srw_ss()) [dec_clock_inc_clock] |> DISCH_ALL)
  \\ full_simp_tac(srw_ss())[]
  \\ pop_assum (qspecl_then [`l1`,`l2`] mp_tac) \\ srw_tac[][]
  \\ pop_assum (mp_tac o MATCH_MP state_rel_gc)
  \\ impl_tac THEN1
   (full_simp_tac(srw_ss())[wordSemTheory.call_env_def,call_env_def,
        wordSemTheory.push_env_def,fromList_def]
    \\ Cases_on `env_to_list y t.permute` \\ full_simp_tac(srw_ss())[LET_DEF]
    \\ full_simp_tac(srw_ss())[fromList2_def,Once insert_def])
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[wordSemTheory.call_env_def]
  \\ pop_assum (mp_tac o MATCH_MP
      (state_rel_pop_env_IMP |> REWRITE_RULE [GSYM AND_IMP_INTRO]
         |> Q.GEN `s2`)) \\ srw_tac[][]
  \\ pop_assum (qspec_then `s with <| locals := x ; space := 0 |>` mp_tac)
  \\ impl_tac THEN1
   (full_simp_tac(srw_ss())[pop_env_def,push_env_def,call_env_def,
      dataSemTheory.state_component_equality])
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[wordSemTheory.pop_env_def,wordSemTheory.push_env_def]
  \\ Cases_on `env_to_list y t.permute` \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]);

val gc_add_call_env = Q.prove(
  `(case gc (push_env y NONE t5) of
     | NONE => (SOME Error,x)
     | SOME s' => case pop_env s' of
                  | NONE => (SOME Error, call_env [] s')
                  | SOME s' => f s') = (res,t) ==>
    (case gc (call_env [Loc l1 l2] (push_env y NONE t5)) of
     | NONE => (SOME Error,x)
     | SOME s' => case pop_env s' of
                  | NONE => (SOME Error, call_env [] s')
                  | SOME s' => f s') = (res,t)`,
  full_simp_tac(srw_ss())[wordSemTheory.gc_def,wordSemTheory.call_env_def,LET_DEF,
      wordSemTheory.push_env_def]
  \\ Cases_on `env_to_list y t5.permute` \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[wordSemTheory.pop_env_def]);

val has_space_state_rel = Q.prove(
  `has_space (Word ((alloc_size k):'a word)) (r:('a,'ffi) state) = SOME T /\
    state_rel c l1 l2 s r [] locs ==>
    state_rel c l1 l2 (s with space := k) r [] locs`,
  full_simp_tac(srw_ss())[state_rel_def] \\ srw_tac[][]
  \\ asm_exists_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[heap_in_memory_store_def,wordSemTheory.has_space_def]
  \\ full_simp_tac(srw_ss())[GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
  \\ full_simp_tac(srw_ss())[alloc_size_def,bytes_in_word_def]
  \\ `(sp * (dimindex (:'a) DIV 8)) + 1 < dimword (:'a)` by
   (imp_res_tac word_ml_inv_SP_LIMIT
    \\ match_mp_tac LESS_EQ_LESS_TRANS
    \\ once_rewrite_tac [CONJ_COMM]
    \\ asm_exists_tac \\ full_simp_tac(srw_ss())[])
  \\ `(sp * (dimindex (:'a) DIV 8)) < dimword (:'a)` by decide_tac
  \\ every_case_tac \\ full_simp_tac(srw_ss())[word_mul_n2w]
  \\ full_simp_tac(srw_ss())[good_dimindex_def]
  \\ full_simp_tac(srw_ss())[w2n_minus1] \\ rev_full_simp_tac(srw_ss())[]
  \\ `F` by decide_tac);

val evaluate_IMP_inc_clock = Q.prove(
  `evaluate (q,t) = (NONE,t1) ==>
    evaluate (q,inc_clock ck t) = (NONE,inc_clock ck t1)`,
  srw_tac[][inc_clock_def] \\ match_mp_tac evaluate_add_clock
  \\ full_simp_tac(srw_ss())[]);

val evaluate_IMP_inc_clock_Ex = Q.prove(
  `evaluate (q,t) = (SOME (Exception x y),t1) ==>
    evaluate (q,inc_clock ck t) = (SOME (Exception x y),inc_clock ck t1)`,
  srw_tac[][inc_clock_def] \\ match_mp_tac evaluate_add_clock
  \\ full_simp_tac(srw_ss())[]);

val get_var_inc_clock = Q.prove(
  `get_var n (inc_clock k s) = get_var n s`,
  full_simp_tac(srw_ss())[wordSemTheory.get_var_def,inc_clock_def]);

val get_vars_inc_clock = Q.prove(
  `get_vars n (inc_clock k s) = get_vars n s`,
  Induct_on `n` \\ full_simp_tac(srw_ss())[wordSemTheory.get_vars_def]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[get_var_inc_clock]);

val set_var_inc_clock = Q.store_thm("set_var_inc_clock",
  `set_var n x (inc_clock ck t) = inc_clock ck (set_var n x t)`,
  full_simp_tac(srw_ss())[wordSemTheory.set_var_def,inc_clock_def]);

val do_app = LIST_CONJ [dataSemTheory.do_app_def,do_space_def,
  data_spaceTheory.op_space_req_def,
  bvi_to_dataTheory.op_space_reset_def, bviSemTheory.do_app_def,
  bviSemTheory.do_app_aux_def, bvlSemTheory.do_app_def]

val w2n_minus_1_LESS_EQ = Q.store_thm("w2n_minus_1_LESS_EQ",
  `(w2n (-1w:'a word) <= w2n (w:'a word)) <=> w + 1w = 0w`,
  fs [word_2comp_n2w]
  \\ Cases_on `w` \\ fs [word_add_n2w]
  \\ `n + 1 <= dimword (:'a)` by decide_tac
  \\ Cases_on `dimword (:'a) = n + 1` \\ fs []);

val bytes_in_word_ADD_1_NOT_ZERO = Q.prove(
  `good_dimindex (:'a) ==>
    bytes_in_word * w + 1w <> 0w:'a word`,
  rpt strip_tac
  \\ `(bytes_in_word * w + 1w) ' 0 = (0w:'a word) ' 0` by metis_tac []
  \\ fs [WORD_ADD_BIT0,word_index,WORD_MUL_BIT0]
  \\ rfs [bytes_in_word_def,EVAL ``good_dimindex (:α)``,word_index]
  \\ rfs [bytes_in_word_def,EVAL ``good_dimindex (:α)``,word_index]);

val alloc_lemma = Q.store_thm("alloc_lemma",
  `state_rel c l1 l2 s (t:('a,'ffi)wordSem$state) [] locs /\
    dataSem$cut_env names s.locals = SOME x /\
    alloc (alloc_size k) (adjust_set names)
        (t with locals := insert 1 (Word (alloc_size k)) t.locals) =
      ((q:'a result option),r) ==>
    (q = SOME NotEnoughSpace ⇒ r.ffi = s.ffi) ∧
    (q ≠ SOME NotEnoughSpace ⇒
     state_rel c l1 l2 (s with <|locals := x; space := k|>) r [] locs ∧
     alloc_size k <> -1w:'a word /\
     FLOOKUP r.store (Temp 29w) = FLOOKUP t.store (Temp 29w) /\
     q = NONE)`,
  strip_tac
  \\ full_simp_tac(srw_ss())[wordSemTheory.alloc_def,
       LET_DEF,addressTheory.CONTAINER_def]
  \\ Q.ABBREV_TAC `t5 = (set_store AllocSize (Word (alloc_size k))
               (t with locals := insert 1 (Word (alloc_size k)) t.locals))`
  \\ imp_res_tac cut_env_IMP_cut_env
  \\ full_simp_tac(srw_ss())[cut_env_adjust_set_insert_1]
  \\ first_x_assum (assume_tac o HO_MATCH_MP gc_add_call_env)
  \\ `FLOOKUP t5.store AllocSize = SOME (Word (alloc_size k)) /\
      cut_env (adjust_set names) t5.locals = SOME y /\
      state_rel c l1 l2 s t5 [] locs` by
   (UNABBREV_ALL_TAC \\ full_simp_tac(srw_ss())[state_rel_set_store_AllocSize]
    \\ full_simp_tac(srw_ss())[cut_env_adjust_set_insert_1,
         wordSemTheory.set_store_def] \\ srw_tac[][]
    \\ full_simp_tac(srw_ss())[SUBSET_DEF,state_rel_insert_1,FLOOKUP_DEF])
  \\ strip_tac
  \\ mp_tac (gc_lemma |> Q.INST [`t`|->`t5`] |> SIMP_RULE std_ss [LET_DEF])
  \\ full_simp_tac(srw_ss())[] \\ strip_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[wordSemTheory.gc_def,wordSemTheory.call_env_def,
         wordSemTheory.push_env_def]
  \\ Cases_on `env_to_list y t5.permute` \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ `IS_SOME (has_space (Word (alloc_size k):'a word_loc) t2)` by
       full_simp_tac(srw_ss())[wordSemTheory.has_space_def,
          state_rel_def,heap_in_memory_store_def]
  \\ Cases_on `has_space (Word (alloc_size k):'a word_loc) t2`
  \\ full_simp_tac(srw_ss())[]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[]
  \\ rev_full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ imp_res_tac has_space_state_rel \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac dataPropsTheory.pop_env_const \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac wordPropsTheory.pop_env_const \\ full_simp_tac(srw_ss())[]
  \\ UNABBREV_ALL_TAC
  \\ full_simp_tac(srw_ss())[wordSemTheory.set_store_def,state_rel_def]
  \\ qpat_assum `has_space (Word (alloc_size k)) r = SOME T` assume_tac
  \\ CCONTR_TAC \\ fs [wordSemTheory.has_space_def]
  \\ rfs [heap_in_memory_store_def,FLOOKUP_DEF,FAPPLY_FUPDATE_THM]
  \\ rfs [WORD_LEFT_ADD_DISTRIB,GSYM word_add_n2w,w2n_minus_1_LESS_EQ]
  \\ rfs [bytes_in_word_ADD_1_NOT_ZERO])

val evaluate_GiveUp = Q.store_thm("evaluate_GiveUp",
  `state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs ==>
    ?r. evaluate (GiveUp,t) = (SOME NotEnoughSpace,r) /\
        r.ffi = s.ffi /\ t.ffi = s.ffi`,
  fs [GiveUp_def,wordSemTheory.evaluate_def,wordSemTheory.word_exp_def]
  \\ strip_tac
  \\ Cases_on `alloc (-1w) (insert 0 () LN) (set_var 1 (Word (-1w)) t)
                  :'a result option # ('a,'ffi) wordSem$state`
  \\ fs [wordSemTheory.set_var_def]
  \\ `-1w = alloc_size (dimword (:'a)):'a word` by
   (fs [alloc_size_def,state_rel_def]
    \\ fs [labPropsTheory.good_dimindex_def,dimword_def] \\ rw [])
  \\ pop_assum (fn th => fs [th])
  \\ drule (alloc_lemma |> Q.INST [`names`|->`LN`,`k`|->`dimword(:'a)`] |> GEN_ALL)
  \\ fs [dataSemTheory.cut_env_def,set_var_def]
  \\ Cases_on `q = SOME NotEnoughSpace` \\ fs []
  \\ CCONTR_TAC \\ fs []
  \\ rpt var_eq_tac
  \\ fs [state_rel_def]
  \\ fs [word_ml_inv_def,abs_ml_inv_def,unused_space_inv_def,heap_ok_def]
  \\ imp_res_tac heap_lookup_SPLIT \\ fs [heap_length_APPEND]
  \\ fs [heap_length_def,el_length_def]
  \\ fs [labPropsTheory.good_dimindex_def,dimword_def] \\ rw []
  \\ rfs [] \\ fs []);

val state_rel_cut_IMP = Q.store_thm("state_rel_cut_IMP",
  `state_rel c l1 l2 s t [] locs /\ cut_state_opt names_opt s = SOME x ==>
    state_rel c l1 l2 x t [] locs`,
  Cases_on `names_opt` \\ fs [dataSemTheory.cut_state_opt_def]
  THEN1 (rw [] \\ fs [])
  \\ fs [dataSemTheory.cut_state_def]
  \\ every_case_tac \\ fs [] \\ rw [] \\ fs []
  \\ imp_res_tac state_rel_cut_env);

val get_vars_SING = Q.store_thm("get_vars_SING",
  `dataSem$get_vars args s = SOME [w] ==> ?y. args = [y]`,
  Cases_on `args` \\ fs [get_vars_def]
  \\ every_case_tac \\ fs [] \\ rw [] \\ fs []
  \\ Cases_on `t` \\ fs [get_vars_def]
  \\ every_case_tac \\ fs [] \\ rw [] \\ fs []);

val clean_tac = rpt var_eq_tac \\ rpt (qpat_x_assum `T` kall_tac)
fun rpt_drule th = drule (th |> GEN_ALL) \\ rpt (disch_then drule \\ fs [])

val eval_tac = fs [wordSemTheory.evaluate_def,
  wordSemTheory.word_exp_def, wordSemTheory.set_var_def, set_var_def,
  bvi_to_data_def, wordSemTheory.the_words_def,
  bviSemTheory.bvl_to_bvi_def, data_to_bvi_def,
  bviSemTheory.bvi_to_bvl_def,wordSemTheory.mem_load_def,
  wordLangTheory.word_op_def, wordLangTheory.word_sh_def,
  wordLangTheory.num_exp_def]

val INT_EQ_NUM_LEMMA = Q.store_thm("INT_EQ_NUM_LEMMA",
  `0 <= (i:int) <=> ?index. i = & index`,
  Cases_on `i` \\ fs []);

val get_vars_2_IMP = Q.store_thm("get_vars_2_IMP",
  `(wordSem$get_vars [x1;x2] s = SOME [v1;v2]) ==>
    get_var x1 s = SOME v1 /\
    get_var x2 s = SOME v2`,
  fs [wordSemTheory.get_vars_def] \\ every_case_tac \\ fs []);

val get_vars_3_IMP = Q.store_thm("get_vars_3_IMP",
  `(wordSem$get_vars [x1;x2;x3] s = SOME [v1;v2;v3]) ==>
    get_var x1 s = SOME v1 /\
    get_var x2 s = SOME v2 /\
    get_var x3 s = SOME v3`,
  fs [wordSemTheory.get_vars_def] \\ every_case_tac \\ fs []);

val memory_rel_get_vars_IMP = Q.prove(
  `memory_rel c be s.refs sp st m dm
     (join_env s.locals
        (toAList (inter t.locals (adjust_set s.locals))) ++ envs) ∧
    get_vars n (s:'ffi dataSem$state).locals = SOME x ∧
    get_vars (MAP adjust_var n) (t:('a,'ffi) wordSem$state) = SOME w ⇒
    memory_rel c be s.refs sp st m dm
      (ZIP (x,w) ++
       join_env s.locals
         (toAList (inter t.locals (adjust_set s.locals))) ++ envs)`,
  fs [memory_rel_def] \\ rw [] \\ asm_exists_tac \\ fs []
  \\ drule word_ml_inv_get_vars_IMP \\ fs []);

val memory_rel_insert = Q.prove(
  `memory_rel c be refs sp st m dm
     ([(x,w)] ++ join_env d (toAList (inter l (adjust_set d))) ++ xs) ⇒
    memory_rel c be refs sp st m dm
     (join_env (insert dest x d)
        (toAList
           (inter (insert (adjust_var dest) w l)
              (adjust_set (insert dest x d)))) ++ xs)`,
  fs [memory_rel_def] \\ rw [] \\ asm_exists_tac \\ fs []
  \\ match_mp_tac word_ml_inv_insert \\ fs []);

val get_real_addr_lemma = Q.store_thm("get_real_addr_lemma",
  `shift_length c < dimindex (:'a) /\
    good_dimindex (:'a) /\
    get_var v t = SOME (Word ptr_w) /\
    get_real_addr c t.store ptr_w = SOME x ==>
    word_exp t (real_addr c v) = SOME (Word (x:'a word))`,
  fs [get_real_addr_def] \\ every_case_tac \\ fs []
  \\ fs [wordSemTheory.get_var_def,real_addr_def]
  \\ eval_tac \\ fs [] \\ rw []
  \\ eval_tac \\ fs [] \\ rw [] \\ fs []
  \\ fs [labPropsTheory.good_dimindex_def,dimword_def] \\ rw []
  \\ rfs [shift_def] \\ fs []);

val get_real_offset_lemma = Q.store_thm("get_real_offset_lemma",
  `get_var v t = SOME (Word i_w) /\
    good_dimindex (:'a) /\
    get_real_offset i_w = SOME y ==>
    word_exp t (real_offset c v) = SOME (Word (y:'a word))`,
  fs [get_real_offset_def] \\ every_case_tac \\ fs []
  \\ fs [wordSemTheory.get_var_def,real_offset_def] \\ eval_tac \\ fs []
  \\ fs [labPropsTheory.good_dimindex_def,dimword_def] \\ rw []);

val get_real_byte_offset_lemma = Q.store_thm("get_real_byte_offset_lemma",
  `get_var v t = SOME (Word (w:α word)) ∧ good_dimindex (:α) ⇒
   word_exp t (real_byte_offset v) = SOME (Word (bytes_in_word + (w >>> 2)))`,
  rw[real_byte_offset_def,wordSemTheory.get_var_def]
  \\ eval_tac \\ fs[good_dimindex_def]);

val reorder_lemma = Q.prove(
  `memory_rel c be x.refs x.space t.store t.memory t.mdomain (x1::x2::x3::xs) ==>
    memory_rel c be x.refs x.space t.store t.memory t.mdomain (x3::x1::x2::xs)`,
  match_mp_tac memory_rel_rearrange \\ fs [] \\ rw [] \\ fs []);

val evaluate_StoreEach = Q.store_thm("evaluate_StoreEach",
  `!xs ys t offset m1.
      store_list (a + offset) ys t.memory t.mdomain = SOME m1 /\
      get_vars xs t = SOME ys /\
      get_var i t = SOME (Word a) ==>
      evaluate (StoreEach i xs offset, t) = (NONE,t with memory := m1)`,
  Induct
  \\ fs [store_list_def,StoreEach_def] \\ eval_tac
  \\ fs [wordSemTheory.state_component_equality,
           wordSemTheory.get_vars_def,store_list_def,
           wordSemTheory.get_var_def]
  \\ rw [] \\ fs [] \\ CASE_TAC \\ fs []
  \\ Cases_on `get_vars xs t` \\ fs [] \\ clean_tac
  \\ fs [store_list_def,wordSemTheory.mem_store_def]
  \\ `(t with memory := m1) =
      (t with memory := (a + offset =+ x) t.memory) with memory := m1` by
       (fs [wordSemTheory.state_component_equality] \\ NO_TAC)
  \\ pop_assum (fn th => rewrite_tac [th])
  \\ first_x_assum match_mp_tac \\ fs []
  \\ asm_exists_tac \\ fs []
  \\ rename1 `get_vars qs t = SOME ts`
  \\ pop_assum mp_tac
  \\ qspec_tac (`ts`,`ts`)
  \\ qspec_tac (`qs`,`qs`)
  \\ Induct \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def]
  \\ rw [] \\ every_case_tac \\ fs [])
  |> Q.SPECL [`xs`,`ys`,`t`,`0w`] |> SIMP_RULE (srw_ss()) [] |> GEN_ALL;

val domain_adjust_set_EVEN = Q.store_thm("domain_adjust_set_EVEN",
  `k IN domain (adjust_set s) ==> EVEN k`,
  fs [adjust_set_def,domain_lookup,lookup_fromAList] \\ rw [] \\ fs []
  \\ imp_res_tac ALOOKUP_MEM \\ fs [MEM_MAP]
  \\ pairarg_tac \\ fs [EVEN_adjust_var]);

val inter_insert_ODD_adjust_set = Q.store_thm("inter_insert_ODD_adjust_set",
  `!k. ODD k ==>
      inter (insert (adjust_var dest) w (insert k v s)) (adjust_set t) =
      inter (insert (adjust_var dest) w s) (adjust_set t)`,
  fs [spt_eq_thm,wf_inter,lookup_inter_alt,lookup_insert]
  \\ rw [] \\ rw [] \\ fs []
  \\ imp_res_tac domain_adjust_set_EVEN \\ fs [EVEN_ODD]);

val inter_insert_ODD_adjust_set_alt = Q.store_thm("inter_insert_ODD_adjust_set_alt",
  `!k. ODD k ==>
      inter (insert k v s) (adjust_set t) =
      inter s (adjust_set t)`,
  fs [spt_eq_thm,wf_inter,lookup_inter_alt,lookup_insert]
  \\ rw [] \\ rw [] \\ fs []
  \\ imp_res_tac domain_adjust_set_EVEN \\ fs [EVEN_ODD]);

val get_vars_adjust_var = Q.prove(
  `ODD k ==>
    get_vars (MAP adjust_var args) (t with locals := insert k w s) =
    get_vars (MAP adjust_var args) (t with locals := s)`,
  Induct_on `args`
  \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def,lookup_insert]
  \\ rw [] \\ fs [ODD_EVEN,EVEN_adjust_var]);

val get_vars_with_store = Q.store_thm("get_vars_with_store",
  `!args. get_vars args (t with <| locals := t.locals ; store := s |>) =
           get_vars args t`,
  Induct \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def]);

val word_less_lemma1 = Q.prove(
  `v2 < (v1:'a word) <=> ~(v1 <= v2)`,
  metis_tac [WORD_NOT_LESS]);

val heap_in_memory_store_IMP_UPDATE = Q.prove(
  `heap_in_memory_store heap a sp sp1 gens c st m dm l ==>
    heap_in_memory_store heap a sp sp1 gens c (st |+ (Globals,h)) m dm l`,
  fs [heap_in_memory_store_def,FLOOKUP_UPDATE]);

val get_vars_2_imp = Q.prove(
  `wordSem$get_vars [x1;x2] s = SOME [y1;y2] ==>
    wordSem$get_var x1 s = SOME y1 /\
    wordSem$get_var x2 s = SOME y2`,
  fs [wordSemTheory.get_vars_def] \\ every_case_tac \\ fs []);

val get_vars_1_imp = Q.prove(
  `wordSem$get_vars [x1] s = SOME [y1] ==>
    wordSem$get_var x1 s = SOME y1`,
  fs [wordSemTheory.get_vars_def] \\ every_case_tac \\ fs []);

val LESS_DIV_16_IMP = Q.prove(
  `n < k DIV 16 ==> 16 * n + 2 < k:num`,
  fs [X_LT_DIV]);

val word_exp_real_addr = Q.prove(
  `get_real_addr c t.store ptr_w = SOME a /\
    shift_length c < dimindex (:α) ∧ good_dimindex (:α) /\
    lookup (adjust_var a1) (t:('a,'ffi) wordSem$state).locals = SOME (Word ptr_w) ==>
    !w. word_exp (t with locals := insert 1 (Word (w:'a word)) t.locals)
          (real_addr c (adjust_var a1)) = SOME (Word a)`,
  rpt strip_tac \\ match_mp_tac (GEN_ALL get_real_addr_lemma)
  \\ fs [wordSemTheory.get_var_def,lookup_insert])

val word_exp_real_addr_2 = Q.prove(
  `get_real_addr c (t:('a,'ffi) wordSem$state).store ptr_w = SOME a /\
    shift_length c < dimindex (:α) ∧ good_dimindex (:α) /\
    lookup (adjust_var a1) t.locals = SOME (Word ptr_w) ==>
    !w1 w2.
      word_exp
        (t with locals := insert 3 (Word (w1:'a word)) (insert 1 (Word w2) t.locals))
        (real_addr c (adjust_var a1)) = SOME (Word a)`,
  rpt strip_tac \\ match_mp_tac (GEN_ALL get_real_addr_lemma)
  \\ fs [wordSemTheory.get_var_def,lookup_insert])

val encode_header_IMP_BIT0 = Q.prove(
  `encode_header c tag l = SOME w ==> w ' 0`,
  fs [encode_header_def,make_header_def] \\ rw []
  \\ fs [word_or_def,fcpTheory.FCP_BETA,word_index]);

val get_addr_inj = Q.store_thm("get_addr_inj",
  `p1 * 2 ** shift_length c < dimword (:'a) ∧
   p2 * 2 ** shift_length c < dimword (:'a) ∧
   get_addr c p1 (Word (0w:'a word)) = get_addr c p2 (Word 0w)
   ⇒ p1 = p2`,
  rw[get_addr_def,get_lowerbits_def]
  \\ `1 < 2 ** shift_length c` by (
    fs[ONE_LT_EXP,shift_length_NOT_ZERO,GSYM NOT_ZERO_LT_ZERO] )
  \\ `dimword (:'a) < dimword(:'a) * 2 ** shift_length c` by fs[]
  \\ `p1 < dimword (:'a) ∧ p2 < dimword (:'a)`
  by (
    imp_res_tac LESS_TRANS
    \\ fs[LT_MULT_LCANCEL])
  \\ `n2w p1 << shift_length c >>> shift_length c = n2w p1`
  by ( match_mp_tac lsl_lsr \\ fs[] )
  \\ `n2w p2 << shift_length c >>> shift_length c = n2w p2`
  by ( match_mp_tac lsl_lsr \\ fs[] )
  \\ qmatch_assum_abbrev_tac`(x || 1w) = (y || 1w)`
  \\ `x = y`
  by (
    unabbrev_all_tac
    \\ fsrw_tac[wordsLib.WORD_BIT_EQ_ss][]
    \\ rw[]
    \\ rfs[word_index]
    \\ Cases_on`i` \\ fs[]
    \\ last_x_assum(qspec_then`SUC n`mp_tac)
    \\ simp[] )
  \\ `n2w p1 = n2w p2` by metis_tac[]
  \\ imp_res_tac n2w_11
  \\ rfs[]);

val Word64Rep_inj = Q.store_thm("Word64Rep_inj",
  `good_dimindex(:'a) ⇒
   (Word64Rep (:'a) w1 = Word64Rep (:'a) w2 ⇔ w1 = w2)`,
  rw[good_dimindex_def,Word64Rep_def]
  \\ srw_tac[wordsLib.WORD_BIT_EQ_ss][Word64Rep_def,EQ_IMP_THM]);

val IMP_read_bytearray_GENLIST = Q.store_thm("IMP_read_bytearray_GENLIST",
  `∀ls len a. len = LENGTH ls ∧
   (∀i. i < len ⇒ g (a + n2w i) = SOME (EL i ls))
  ⇒ read_bytearray a len g = SOME ls`,
  Induct \\ rw[read_bytearray_def] \\ fs[]
  \\ last_x_assum(qspec_then`a + 1w`mp_tac)
  \\ impl_tac
  >- (
    rw[]
    \\ first_x_assum(qspec_then`SUC i`mp_tac)
    \\ simp[]
    \\ simp[ADD1,GSYM word_add_n2w] )
  \\ rw[]
  \\ first_x_assum(qspec_then`0`mp_tac)
  \\ simp[]);

val domain_adjust_set_NOT_EMPTY = Q.store_thm("domain_adjust_set_NOT_EMPTY[simp]",
  `domain (adjust_set s) <> EMPTY`,
  fs [EXTENSION,domain_lookup,adjust_set_def] \\ EVAL_TAC
  \\ fs [lookup_insert] \\ metis_tac []);

val get_vars_termdep = Q.store_thm("get_vars_termdep[simp]",
  `!xs. get_vars xs (t with termdep := t.termdep - 1) = get_vars xs t`,
  Induct \\ EVAL_TAC \\ rw [] \\ every_case_tac \\ fs []);

val lookup_RefByte_location = Q.prove(
  `state_rel c l1 l2 x t [] locs ==>
    lookup RefByte_location t.code = SOME (4,RefByte_code c) /\
    lookup RefArray_location t.code = SOME (3,RefArray_code c) /\
    lookup FromList_location t.code = SOME (4,FromList_code c) /\
    lookup Replicate_location t.code = SOME (5,Replicate_code) /\
    lookup AnyArith_location t.code = SOME (4,AnyArith_code c) /\
    lookup Add_location t.code = SOME (3,Add_code) /\
    lookup Sub_location t.code = SOME (3,Sub_code) /\
    lookup Mul_location t.code = SOME (3,Mul_code) /\
    lookup Div_location t.code = SOME (3,Div_code) /\
    lookup Mod_location t.code = SOME (3,Mod_code)`,
  fs [state_rel_def,code_rel_def,stubs_def]);

val word_exp_rw = LIST_CONJ
  [wordSemTheory.word_exp_def,
   wordLangTheory.word_op_def,
   wordLangTheory.word_sh_def,
   wordSemTheory.get_var_imm_def,
   wordLangTheory.num_exp_def,
   wordSemTheory.the_words_def,
   lookup_insert]

val get_vars_SOME_IFF_data = Q.prove(
  `(get_vars [] t = SOME [] <=> T) /\
    (get_vars (x::xs) t = SOME (y::ys) <=>
     dataSem$get_var x t = SOME y /\
     get_vars xs t = SOME ys)`,
  fs [dataSemTheory.get_vars_def] \\ every_case_tac \\ fs []);

val get_vars_SOME_IFF_data_eq = Q.prove(
  `((get_vars [] t = SOME z) <=> (z = [])) /\
    (get_vars (x::xs) t = SOME z <=>
    ?y ys. z = y::ys /\ dataSem$get_var x t = SOME y /\
           get_vars xs t = SOME ys)`,
  Cases_on `z` \\ fs [get_vars_SOME_IFF_data]
  \\ fs [dataSemTheory.get_vars_def] \\ every_case_tac \\ fs []);

val get_vars_SOME_IFF = Q.prove(
  `(get_vars [] t = SOME [] <=> T) /\
    (get_vars (x::xs) t = SOME (y::ys) <=>
     get_var x t = SOME y /\
     wordSem$get_vars xs t = SOME ys)`,
  fs [wordSemTheory.get_vars_def] \\ every_case_tac \\ fs []);

val get_vars_SOME_IFF_eq = Q.prove(
  `((get_vars [] t = SOME z) <=> (z = [])) /\
    (get_vars (x::xs) t = SOME z <=>
    ?y ys. z = y::ys /\ wordSem$get_var x t = SOME y /\
           get_vars xs t = SOME ys)`,
  Cases_on `z` \\ fs [get_vars_SOME_IFF]
  \\ fs [wordSemTheory.get_vars_def] \\ every_case_tac \\ fs []);

val memory_rel_get_var_IMP =
  memory_rel_get_vars_IMP |> Q.INST [`n`|->`[u]`] |> GEN_ALL
    |> SIMP_RULE std_ss [MAP,get_vars_SOME_IFF_eq,get_vars_SOME_IFF_data_eq,
         PULL_EXISTS,ZIP,APPEND]

val get_vars_sing = Q.store_thm("get_vars_sing",
  `get_vars [n] t = SOME x <=> ?x1. get_vars [n] t = SOME [x1] /\ x = [x1]`,
  fs [wordSemTheory.get_vars_def] \\ every_case_tac \\ fs [] \\ EQ_TAC \\ fs []);

val word_ml_inv_get_var_IMP = save_thm("word_ml_inv_get_var_IMP",
  word_ml_inv_get_vars_IMP
  |> Q.INST [`n`|->`[n1]`,`x`|->`[x1]`] |> GEN_ALL
  |> REWRITE_RULE [get_vars_SOME_IFF,get_vars_SOME_IFF_data,MAP]
  |> SIMP_RULE std_ss [Once get_vars_sing,PULL_EXISTS,get_vars_SOME_IFF,ZIP,APPEND]);

val get_var_set_var_thm = Q.store_thm("get_var_set_var_thm",
  `wordSem$get_var n (set_var m x y) = if n = m then SOME x else get_var n y`,
  fs[wordSemTheory.get_var_def,wordSemTheory.set_var_def,lookup_insert]);

val lookup_IMP_insert_EQ = Q.store_thm("lookup_IMP_insert_EQ",
  `!t x y. lookup x t = SOME y ==> insert x y t = t`,
  Induct \\ fs [lookup_def,Once insert_def] \\ rw []);

val alloc_alt =
  SPEC_ALL alloc_lemma
  |> ConseqConv.WEAKEN_CONSEQ_CONV_RULE
     (ConseqConv.CONSEQ_REWRITE_CONV
        ([],[],[prove(``alloc_size k ≠ -1w ==> T``,fs [])]))
  |> GEN_ALL

val insert_insert_3_1 = Q.prove(
  `insert 3 x (insert 1 y t) = insert 1 y (insert 3 x t)`,
  Cases_on `t` \\ EVAL_TAC \\ Cases_on `s0` \\ EVAL_TAC);

val alloc_size_dimword = Q.store_thm("alloc_size_dimword",
  `good_dimindex (:'a) ==>
    alloc_size (dimword (:'a)) = -1w:'a word`,
  fs [alloc_size_def,EVAL ``good_dimindex (:'a)``] \\ rw [] \\ fs []);

val alloc_fail = alloc_lemma
  |> Q.INST [`k`|->`dimword (:'a)`]
  |> SIMP_RULE std_ss [UNDISCH alloc_size_dimword]
  |> DISCH_ALL |> MP_CANON

val shift_lsl = Q.store_thm("shift_lsl",
  `good_dimindex (:'a) ==> w << shift (:'a) = w * bytes_in_word:'a word`,
  rw [labPropsTheory.good_dimindex_def,shift_def,bytes_in_word_def]
  \\ fs [WORD_MUL_LSL]);

val AllocVar_thm = Q.store_thm("AllocVar_thm",
  `state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs ∧
    dataSem$cut_env names s.locals = SOME x ∧
    get_var 1 t = SOME (Word w) /\
    evaluate (AllocVar limit names,t) = (q,r) /\
    limit < dimword (:'a) DIV 8 ==>
    (q = SOME NotEnoughSpace ⇒ r.ffi = s.ffi) ∧
    (q ≠ SOME NotEnoughSpace ⇒
      w2n w DIV 4 < limit /\
      state_rel c l1 l2 (s with <|locals := x; space := w2n w DIV 4 + 1|>) r [] locs ∧
      FLOOKUP r.store (Temp 29w) = FLOOKUP t.store (Temp 29w) /\
      q = NONE)`,
  fs [wordSemTheory.evaluate_def,AllocVar_def,list_Seq_def] \\ strip_tac
  \\ `limit < dimword (:'a)` by
        (rfs [EVAL ``good_dimindex (:'a)``,state_rel_def,dimword_def])
  \\ `?end next.
        FLOOKUP t.store TriggerGC = SOME (Word end) /\
        FLOOKUP t.store NextFree = SOME (Word next)` by
          full_simp_tac(srw_ss())[state_rel_def,heap_in_memory_store_def]
  \\ fs [word_exp_rw,get_var_set_var_thm] \\ rfs []
  \\ rfs [wordSemTheory.get_var_def]
  \\ `~(2 ≥ dimindex (:α))` by
         fs [state_rel_def,EVAL ``good_dimindex (:α)``,shift_def] \\ fs []
  \\ rfs [word_exp_rw,wordSemTheory.set_var_def,lookup_insert]
  \\ fs [asmTheory.word_cmp_def]
  \\ fs [WORD_LO,w2n_lsr] \\ rfs []
  \\ reverse (Cases_on `w2n w DIV 4 < limit`) \\ fs [] THEN1
   (rfs [word_exp_rw,wordSemTheory.set_var_def,lookup_insert]
    \\ reverse FULL_CASE_TAC
    \\ qpat_assum `state_rel c l1 l2 s t [] locs` mp_tac
    \\ rewrite_tac [state_rel_def] \\ strip_tac
    \\ fs [heap_in_memory_store_def] \\ fs []
    \\ fs [WORD_LEFT_ADD_DISTRIB,GSYM word_add_n2w]
    THEN1
     (rw [] \\ fs [] \\ rfs [] \\ fs [state_rel_def]
      \\ fs [WORD_LEFT_ADD_DISTRIB,GSYM word_add_n2w]
      \\ fs [NOT_LESS,w2n_minus_1_LESS_EQ,bytes_in_word_ADD_1_NOT_ZERO])
    \\ match_mp_tac (GEN_ALL alloc_fail) \\ fs []
    \\ `state_rel c l1 l2 s (t with locals :=
           insert 3 (Word (end + -1w * next)) t.locals) [] locs` by
          fs [state_rel_insert_3]
    \\ asm_exists_tac \\ fs []
    \\ asm_exists_tac \\ fs [insert_insert_3_1])
  \\ qpat_assum `_ = (q,r)` mp_tac
  \\ IF_CASES_TAC THEN1
    (fs [state_rel_def,EVAL ``good_dimindex (:α)``,shift_def])
  \\ pop_assum kall_tac \\ fs [lookup_insert]
  \\ `1w ≪ shift (:α) + w ⋙ 2 ≪ shift (:α) =
      alloc_size (w2n w DIV 4 + 1)` by
   (fs [alloc_size_def] \\ IF_CASES_TAC THEN1
     (`w >>> 2 = n2w (w2n w DIV 4)` by all_tac
      \\ fs [shift_lsl,state_rel_def,bytes_in_word_def,word_add_n2w,word_mul_n2w]
      \\ rewrite_tac [GSYM w2n_11,w2n_lsr] \\ fs [])
    \\ qsuff_tac `(w2n w DIV 4 + 1) * (dimindex (:α) DIV 8) < dimword (:'a)`
    THEN1 fs [] \\ pop_assum kall_tac
    \\ fs [EVAL ``good_dimindex (:'a)``,state_rel_def,dimword_def]
    \\ rfs [] \\ NO_TAC)
  \\ fs []
  \\ reverse IF_CASES_TAC
  THEN1
   (fs [] \\ strip_tac \\ rveq \\ fs []
    \\ match_mp_tac state_rel_cut_env \\ reverse (srw_tac[][]) \\ fs []
    \\ fs[state_rel_insert_3_1]
    \\ match_mp_tac has_space_state_rel \\ fs []
    \\ fs [wordSemTheory.has_space_def])
  \\ fs [] \\ strip_tac
  \\ match_mp_tac (alloc_alt |> SPEC_ALL
        |> DISCH ``(t:('a,'ffi) wordSem$state).store = st``
        |> SIMP_RULE std_ss [AND_IMP_INTRO] |> GEN_ALL)
  \\ qexists_tac `t with locals := insert 3 (Word (end + -1w * next)) t.locals`
  \\ fs [state_rel_insert_3]
  \\ asm_exists_tac \\ fs []
  \\ qpat_assum `_ = (q,r)` (fn th => fs [GSYM th])
  \\ simp [insert_insert_3_1]);

val set_vars_sing = Q.store_thm("set_vars_sing",
  `set_vars [n] [w] t = set_var n w t`,
  EVAL_TAC);

val memory_rel_lookup = Q.store_thm("memory_rel_lookup",
  `memory_rel c be refs s st m dm
      (join_env l1 (toAList (inter l2 (adjust_set l1))) ++ xs) ∧
    lookup n l1 = SOME x ∧ lookup (adjust_var n) l2 = SOME w ⇒
    memory_rel c be refs s st m dm
     ((x,w)::(join_env l1 (toAList (inter l2 (adjust_set l1))) ++ xs))`,
  fs [memory_rel_def] \\ rw [] \\ asm_exists_tac \\ fs []
  \\ rpt_drule (Q.INST [`ys`|->`[]`] word_ml_inv_lookup
        |> SIMP_RULE std_ss [APPEND]));

val Replicate_code_thm = Q.store_thm("Replicate_code_thm",
  `!n a r m1 a1 a2 a3 a4 a5.
      lookup Replicate_location r.code = SOME (5,Replicate_code) /\
      store_list (a + bytes_in_word) (REPLICATE n v)
        (r:('a,'ffi) wordSem$state).memory r.mdomain = SOME m1 /\
      get_var a1 r = SOME (Loc l1 l2) /\
      get_var a2 r = SOME (Word a) /\
      get_var a3 r = SOME v /\
      get_var a4 r = SOME (Word (n2w (4 * n))) /\
      get_var a5 (r:('a,'ffi) wordSem$state) = SOME ret_val /\
      4 * n < dimword (:'a) /\
      n < r.clock ==>
      evaluate (Call NONE (SOME Replicate_location) [a1;a2;a3;a4;a5] NONE,r) =
        (SOME (Result (Loc l1 l2) ret_val),
         r with <| memory := m1 ; clock := r.clock - n - 1; locals := LN |>)`,
  Induct \\ rw [] \\ simp [wordSemTheory.evaluate_def]
  \\ simp [wordSemTheory.get_vars_def,wordSemTheory.bad_dest_args_def,
        wordSemTheory.find_code_def,wordSemTheory.add_ret_loc_def]
  \\ rw [] \\ simp [Replicate_code_def]
  \\ simp [wordSemTheory.evaluate_def,wordSemTheory.call_env_def,
         wordSemTheory.get_var_def,word_exp_rw,fromList2_def,
         asmTheory.word_cmp_def,wordSemTheory.dec_clock_def]
  \\ fs [store_list_def,REPLICATE]
  THEN1 (rw [wordSemTheory.state_component_equality])
  \\ NTAC 3 (once_rewrite_tac [list_Seq_def])
  \\ simp [wordSemTheory.evaluate_def,wordSemTheory.call_env_def,
           wordSemTheory.get_var_def,word_exp_rw,fromList2_def,
           wordSemTheory.set_var_def,wordSemTheory.mem_store_def,
           asmTheory.word_cmp_def,wordSemTheory.dec_clock_def]
  \\ fs [list_Seq_def]
  \\ SEP_I_TAC "evaluate"
  \\ fs [wordSemTheory.call_env_def,
           wordSemTheory.get_var_def,word_exp_rw,fromList2_def,
           wordSemTheory.set_var_def,wordSemTheory.mem_store_def,
           asmTheory.word_cmp_def,wordSemTheory.dec_clock_def]
  \\ rfs [] \\ fs [MULT_CLAUSES,GSYM word_add_n2w] \\ fs [ADD1]);

val Replicate_code_alt_thm = Q.store_thm("Replicate_code_alt_thm",
  `!n a r m1 a1 a2 a3 a4 a5 var.
      lookup Replicate_location r.code = SOME (5,Replicate_code) /\
      store_list (a + bytes_in_word) (REPLICATE n v)
        (r:('a,'ffi) wordSem$state).memory r.mdomain = SOME m1 /\
      get_var a2 r = SOME (Word a) /\
      get_var a3 r = SOME v /\
      get_var a4 r = SOME (Word (n2w (4 * n))) /\
      get_var 0 (r:('a,'ffi) wordSem$state) = SOME ret_val /\
      4 * n < dimword (:'a) /\
      n < r.clock ==>
      evaluate (Call (SOME (0,fromList [()],Skip,l1,l2))
                  (SOME Replicate_location) [a2;a3;a4;0] NONE,r) =
        (NONE,
         r with <| memory := m1 ; clock := r.clock - n - 1;
                   locals := insert 0 ret_val LN ;
                   permute := (\n. r.permute (n+1)) |>)`,
  rw [] \\ fs [wordSemTheory.evaluate_def]
  \\ simp [wordSemTheory.get_vars_def,wordSemTheory.bad_dest_args_def,
        wordSemTheory.find_code_def,wordSemTheory.add_ret_loc_def]
  \\ fs [EVAL ``fromList [()]``]
  \\ fs [wordSemTheory.cut_env_def,wordSemTheory.get_var_def,domain_lookup]
  \\ rw [] \\ simp [Replicate_code_def]
  \\ Cases_on `n`
  \\ simp [wordSemTheory.evaluate_def,wordSemTheory.call_env_def,
         wordSemTheory.get_var_def,word_exp_rw,fromList2_def,
         asmTheory.word_cmp_def,wordSemTheory.dec_clock_def]
  \\ fs [store_list_def,REPLICATE]
  \\ `inter r.locals (LS ()) = insert 0 ret_val LN` by
    (fs [spt_eq_thm,wf_insert,wf_def]
     \\ fs [lookup_inter,lookup_def,lookup_insert]
     \\ rw [] \\ every_case_tac \\ fs [])
  \\ `env_to_list (insert 0 ret_val LN) r.permute =
        ([(0,ret_val)],\n. r.permute (n+1))` by
   (fs [wordSemTheory.env_to_list_def,wordSemTheory.list_rearrange_def]
    \\ fs [EVAL ``(QSORT key_val_compare (toAList (insert 0 ret_val LN)))``]
    \\ fs [EVAL ``count 1``] \\ rw []
    \\ fs [BIJ_DEF,SURJ_DEF]) \\ fs []
  THEN1
   (fs [wordSemTheory.pop_env_def,wordSemTheory.push_env_def]
    \\ fs [EVAL ``domain (fromAList [(0,ret_val)])``,wordSemTheory.set_var_def]
    \\ fs [fromAList_def,insert_shadow]
    \\ fs [wordSemTheory.state_component_equality])
  \\ NTAC 3 (once_rewrite_tac [list_Seq_def])
  \\ simp [wordSemTheory.evaluate_def,wordSemTheory.call_env_def,
           wordSemTheory.get_var_def,word_exp_rw,fromList2_def,
           wordSemTheory.set_var_def,wordSemTheory.mem_store_def,
           asmTheory.word_cmp_def,wordSemTheory.dec_clock_def]
  \\ fs [wordSemTheory.push_env_def]
  \\ fs [] \\ fs [lookup_insert]
  \\ fs [MULT_CLAUSES,GSYM word_add_n2w,list_Seq_def]
  \\ qmatch_goalsub_abbrev_tac`evaluate (Call NONE _ _ NONE,t5)`
  \\ qspecl_then [`n'`,`a + bytes_in_word`,`t5`] mp_tac Replicate_code_thm
  \\ disch_then (qspecl_then [`m1`,`0`,`2`,`4`,`6`,`8`] mp_tac)
  \\ impl_tac
  THEN1 (fs [wordSemTheory.get_var_def,lookup_insert,Abbr `t5`])
  \\ strip_tac \\ fs []
  \\ fs [wordSemTheory.pop_env_def,Abbr `t5`,
         EVAL ``domain (fromAList [(0,ret_val)])``]
  \\ fs [wordSemTheory.state_component_equality]
  \\ fs [fromAList_def,insert_shadow]);

val NONNEG_INT = Q.store_thm("NONNEG_INT",
  `0 <= (i:int) ==> ?j. i = & j`,
  Cases_on `i` \\ fs []);

val BIT_X_1 = Q.store_thm("BIT_X_1",
  `BIT i 1 = (i = 0)`,
  EQ_TAC \\ rw []);

val minus_2_word_and_id = Q.store_thm("minus_2_word_and_id",
  `~(w ' 0) ==> (-2w && w) = w`,
  fs [fcpTheory.CART_EQ,word_and_def,fcpTheory.FCP_BETA]
  \\ rewrite_tac [GSYM (SIMP_CONV (srw_ss()) [] ``~1w``)]
  \\ Cases_on `w`
  \\ simp_tac std_ss [word_1comp_def,fcpTheory.FCP_BETA,word_index,
        DIMINDEX_GT_0,BIT_X_1] \\ metis_tac []);

val FOUR_MUL_LSL = Q.store_thm("FOUR_MUL_LSL",
  `n2w (4 * i) << k = n2w i << (k + 2)`,
  fs [WORD_MUL_LSL,EXP_ADD,word_mul_n2w]);

val evaluate_BignumHalt = Q.store_thm("evaluate_BignumHalt",
  `state_rel c l1 l2 s t [] locs /\
    get_var reg t = SOME (Word w) ==>
    ∃r. (evaluate (BignumHalt reg,t) =
          if w ' 0 then (SOME NotEnoughSpace,r)
          else (NONE,t)) ∧ r.ffi = s.ffi ∧ t.ffi = s.ffi`,
  fs [BignumHalt_def,wordSemTheory.evaluate_def,word_exp_rw,
      asmTheory.word_cmp_def,word_and_one_eq_0_iff |> SIMP_RULE (srw_ss()) []]
  \\ IF_CASES_TAC \\ fs []
  THEN1 (rw [] \\ qexists_tac `t` \\ fs [state_rel_def])
  \\ rw [] \\ match_mp_tac evaluate_GiveUp \\ fs []);

val state_rel_get_var_Number_IMP_alt = Q.prove(
  `!k i. state_rel c l1 l2 s t [] locs /\
          get_var k s.locals = SOME (Number i) /\
          get_var (2 * k + 2) t = SOME a1 ==>
          ?w:'a word. a1 = Word w /\ w ' 0 = ~small_int (:'a) i`,
  fs [state_rel_thm] \\ rw []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule memory_rel_get_var_IMP
  \\ fs [adjust_var_def] \\ rw []
  \\ imp_res_tac memory_rel_any_Number_IMP \\ fs []);

val IMP_LESS_MustTerminate_limit = Q.store_thm("IMP_LESS_MustTerminate_limit[simp]",
  `i < dimword (:α) ==>
    i < MustTerminate_limit (:α) − 1`,
  rewrite_tac [wordSemTheory.MustTerminate_limit_def] \\ decide_tac);

val RefArray_thm = Q.store_thm("RefArray_thm",
  `state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs /\
    get_vars [0;1] s.locals = SOME vals /\
    t.clock = MustTerminate_limit (:'a) - 1 /\
    do_app RefArray vals s = Rval (v,s2) ==>
    ?q r new_c.
      evaluate (RefArray_code c,t) = (q,r) /\
      if q = SOME NotEnoughSpace then
        r.ffi = t.ffi
      else
        ?rv. q = SOME (Result (Loc l1 l2) rv) /\
             state_rel c r1 r2 (s2 with <| locals := LN; clock := new_c |>)
                r [(v,rv)] locs`,
  fs [RefArray_code_def]
  \\ fs [do_app_def,do_space_def,EVAL ``op_space_reset RefArray``,
         bviSemTheory.do_app_def,bvlSemTheory.do_app_def,
         bviSemTheory.do_app_aux_def]
  \\ Cases_on `vals` \\ fs []
  \\ Cases_on `t'` \\ fs []
  \\ Cases_on `h` \\ fs []
  \\ Cases_on `t''` \\ fs []
  \\ IF_CASES_TAC \\ fs [] \\ rw []
  \\ drule NONNEG_INT \\ strip_tac \\ rveq \\ fs []
  \\ rename1 `get_vars [0; 1] s.locals = SOME [Number (&i); el]`
  \\ qpat_abbrev_tac `s3 = bvi_to_data _ _`
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw]
  \\ rpt_drule state_rel_get_vars_IMP \\ strip_tac \\ fs [LENGTH_EQ_2]
  \\ rveq \\ fs [adjust_var_def,get_vars_SOME_IFF]
  \\ fs [get_vars_SOME_IFF_data]
  \\ drule (Q.SPEC `0` state_rel_get_var_Number_IMP_alt) \\ fs []
  \\ strip_tac \\ rveq
  \\ rpt_drule evaluate_BignumHalt
  \\ Cases_on `small_int (:α) (&i)` \\ fs [] \\ strip_tac \\ fs []
  \\ ntac 3 (pop_assum kall_tac)
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw]
  \\ fs [wordSemTheory.get_var_def]
  \\ `w = n2w (4 * i) /\ 4 * i < dimword (:'a)` by
   (fs [state_rel_def,get_vars_SOME_IFF_data]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,get_var_def]
    \\ rpt_drule word_ml_inv_get_var_IMP
    \\ fs [get_var_def,wordSemTheory.get_var_def,adjust_var_def]
    \\ qpat_assum `lookup 0 s.locals = SOME (Number (&i))` assume_tac
    \\ rpt (disch_then drule) \\ fs []
    \\ fs [word_ml_inv_def] \\ rw []
    \\ fs [abs_ml_inv_def,bc_stack_ref_inv_def,v_inv_def] \\ rfs []
    \\ rw [] \\ fs [word_addr_def,Smallnum_def] \\ rw []
    \\ fs [small_int_def,X_LT_DIV]
    \\ match_mp_tac minus_2_word_and_id
    \\ fs [word_index,word_mul_n2w,bitTheory.BIT0_ODD,ODD_MULT] \\ NO_TAC)
  \\ rveq \\ fs []
  \\ `2 < dimindex (:α)` by
       (fs [state_rel_def,EVAL ``good_dimindex (:α)``] \\ NO_TAC) \\ fs []
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw]
  \\ `state_rel c l1 l2 s (set_var 1 (Word (n2w (4 * i))) t) [] locs` by
        fs [wordSemTheory.set_var_def,state_rel_insert_1]
  \\ rpt_drule AllocVar_thm
  \\ `?x. dataSem$cut_env (fromList [();()]) s.locals = SOME x` by
    (fs [EVAL ``fromList [(); ()]``,cut_env_def,domain_lookup,
         get_var_def,get_vars_SOME_IFF_data] \\ NO_TAC)
  \\ disch_then drule
  \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def]
  \\ qabbrev_tac `limit = MIN (2 ** c.len_size) (dimword (:α) DIV 16)`
  \\ fs [get_var_set_var_thm]
  \\ Cases_on `evaluate
       (AllocVar limit (fromList [(); ()]),set_var 1 (Word (n2w (4 * i))) t)`
  \\ fs []
  \\ disch_then drule
  \\ impl_tac THEN1 (unabbrev_all_tac \\ fs []
                     \\ fs [state_rel_def,EVAL ``good_dimindex (:'a)``,dimword_def])
  \\ strip_tac \\ fs [set_vars_sing]
  \\ reverse IF_CASES_TAC \\ fs []
  \\ rveq \\ fs []
  \\ fs [bviSemTheory.bvl_to_bvi_def,
         bviSemTheory.bvi_to_bvl_def,
         dataSemTheory.bvi_to_data_def,
         dataSemTheory.call_env_def,
         dataSemTheory.data_to_bvi_def,push_env_def,
         dataSemTheory.set_var_def,wordSemTheory.set_var_def]
  \\ qabbrev_tac `new = LEAST ptr. ptr ∉ FDOM s.refs`
  \\ `new ∉ FDOM s.refs` by metis_tac [LEAST_NOTIN_FDOM]
  \\ fs [] \\ fs [list_Seq_def]
  \\ once_rewrite_tac [wordSemTheory.evaluate_def]
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ fs [word_exp_rw]
  \\ `(?trig1. FLOOKUP r.store TriggerGC = SOME (Word trig1)) /\
      (?eoh1. FLOOKUP r.store EndOfHeap = SOME (Word eoh1)) /\
      (?cur1. FLOOKUP r.store CurrHeap = SOME (Word cur1))` by
        (fs [state_rel_thm,memory_rel_def,heap_in_memory_store_def] \\ NO_TAC)
  \\ fs []
  \\ `lookup 2 r.locals = SOME (Word (n2w (4 * i)))` by
   (qabbrev_tac `s9 = s with <|locals := x; space := 4 * i DIV 4 + 1|>`
    \\ fs [state_rel_def,get_vars_SOME_IFF_data]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,get_var_def]
    \\ rpt_drule word_ml_inv_get_var_IMP
    \\ fs [get_var_def,wordSemTheory.get_var_def,adjust_var_def]
    \\ `lookup 0 s9.locals = SOME (Number (&i))` by
     (unabbrev_all_tac \\ fs [cut_env_def] \\ rveq
      \\ fs [lookup_inter_alt] \\ EVAL_TAC)
    \\ rpt (disch_then drule) \\ fs []
    \\ `IS_SOME (lookup 0 s9.locals)` by fs []
    \\ res_tac \\ Cases_on `lookup 2 r.locals` \\ fs []
    \\ fs [word_ml_inv_def] \\ rw []
    \\ fs [abs_ml_inv_def,bc_stack_ref_inv_def,v_inv_def]
    \\ rw [] \\ fs [word_addr_def,Smallnum_def] \\ rfs []
    \\ fs [small_int_def,X_LT_DIV,word_addr_def]
    \\ match_mp_tac minus_2_word_and_id
    \\ fs [word_index,word_mul_n2w,bitTheory.BIT0_ODD,ODD_MULT] \\ NO_TAC)
  \\ fs []
  \\ IF_CASES_TAC
  THEN1 (fs [shift_def,state_rel_def,EVAL ``good_dimindex (:'a)``])
  \\ asm_rewrite_tac [] \\ pop_assum kall_tac \\ fs []
  \\ once_rewrite_tac [wordSemTheory.evaluate_def]
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ fs [word_exp_rw]
  \\ simp [wordSemTheory.set_var_def,lookup_insert,wordSemTheory.set_store_def]
  \\ `n2w (4 * i) ⋙ 2 = n2w i` by
   (once_rewrite_tac [GSYM w2n_11] \\ rewrite_tac [w2n_lsr]
    \\ fs [ONCE_REWRITE_RULE[MULT_COMM]MULT_DIV])
  \\ fs [WORD_LEFT_ADD_DISTRIB]
  \\ `good_dimindex(:'a)` by fs [state_rel_def]
  \\ fs [shift_lsl]
  \\ once_rewrite_tac [wordSemTheory.evaluate_def]
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ fs [word_exp_rw,FLOOKUP_UPDATE,wordSemTheory.set_var_def,WORD_LEFT_ADD_DISTRIB]
  \\ qabbrev_tac `ww = eoh1 + -1w * bytes_in_word + -1w * (bytes_in_word * n2w i)`
  \\ qabbrev_tac `ww1 = trig1 + -1w * bytes_in_word + -1w * (bytes_in_word * n2w i)`
  \\ fs [Once insert_insert]
  \\ once_rewrite_tac [wordSemTheory.evaluate_def]
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ fs [word_exp_rw,wordSemTheory.set_var_def]
  \\ once_rewrite_tac [wordSemTheory.evaluate_def]
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ fs [word_exp_rw,wordSemTheory.set_var_def,wordSemTheory.set_store_def]
  \\ fs [FLOOKUP_DEF,FAPPLY_FUPDATE_THM]
  \\ IF_CASES_TAC
  THEN1 (fs [shift_def,state_rel_def,EVAL ``good_dimindex (:'a)``])
  \\ asm_rewrite_tac [] \\ pop_assum kall_tac \\ fs []
  \\ fs [wordSemTheory.set_var_def]
  \\ once_rewrite_tac [wordSemTheory.evaluate_def]
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ fs [word_exp_rw,wordSemTheory.set_var_def,lookup_insert]
  \\ once_rewrite_tac [wordSemTheory.evaluate_def]
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ fs [word_exp_rw,wordSemTheory.set_store_def,lookup_insert,
         wordSemTheory.get_var_def,wordSemTheory.mem_store_def]
  \\ qpat_assum `state_rel c l1 l2 _ _ _ _` mp_tac
  \\ simp_tac std_ss [Once state_rel_thm] \\ strip_tac \\ fs []
  \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule memory_rel_lookup
  \\ `lookup 1 x = SOME el` by
   (fs [cut_env_def] \\ rveq \\ fs []
    \\ fs [lookup_inter_alt,get_vars_SOME_IFF_data,get_var_def]
    \\ EVAL_TAC \\ NO_TAC)
  \\ `?w6. lookup (adjust_var 1) r.locals = SOME w6` by
   (`IS_SOME (lookup 1 x)` by fs [] \\ res_tac \\ fs []
    \\ Cases_on `lookup (adjust_var 1) r.locals` \\ fs [])
  \\ rpt (disch_then drule) \\ strip_tac
  \\ rpt_drule memory_rel_RefArray
  \\ `encode_header c 2 i = SOME (make_header c 2w i)` by
   (fs[encode_header_def,memory_rel_def,heap_in_memory_store_def]
    \\ reverse conj_tac THEN1
     (fs[encode_header_def,memory_rel_def,heap_in_memory_store_def,EXP_SUB]
      \\ unabbrev_all_tac \\ fs [ONCE_REWRITE_RULE [MULT_COMM] MULT_DIV]
      \\ rfs [labPropsTheory.good_dimindex_def,dimword_def])
    \\ `1 < dimindex (:α) − (c.len_size + 2)` by
     (qpat_assum `c.len_size + _ < dimindex (:α)` mp_tac
      \\ rpt (pop_assum kall_tac) \\ decide_tac)
    \\ Cases_on `dimindex (:α) − (c.len_size + 2)` \\ fs[]
    \\ Cases_on `n` \\ fs [EXP] \\ Cases_on `2 ** n'` \\ fs [])
  \\ rpt (disch_then drule)
  \\ impl_tac THEN1 (fs [ONCE_REWRITE_RULE[MULT_COMM]MULT_DIV])
  \\ strip_tac
  \\ fs [LET_THM]
  \\ `trig1 = trig /\ eoh1 = eoh /\ cur1 = curr` by
        (fs [FLOOKUP_DEF] \\ NO_TAC) \\ rveq \\ fs []
  \\ `eoh + -1w * (bytes_in_word * n2w (i + 1)) = ww` by
      (unabbrev_all_tac \\ fs [WORD_LEFT_ADD_DISTRIB,GSYM word_add_n2w] \\ NO_TAC)
  \\ fs [] \\ pop_assum kall_tac
  \\ fs [store_list_def,FOUR_MUL_LSL]
  \\ `(n2w i ≪ (dimindex (:α) − (c.len_size + 2) + 2) ‖ make_header c 2w 0) =
      make_header c 2w i:'a word` by
   (fs [make_header_def,WORD_MUL_LSL,word_mul_n2w,LEFT_ADD_DISTRIB]
    \\ rpt (AP_TERM_TAC ORELSE AP_THM_TAC)
    \\ fs [memory_rel_def,heap_in_memory_store_def] \\ NO_TAC) \\ fs []
  \\ `lookup Replicate_location r.code = SOME (5,Replicate_code)` by
         (imp_res_tac lookup_RefByte_location \\ NO_TAC)
  \\ assume_tac (GEN_ALL Replicate_code_thm)
  \\ SEP_I_TAC "evaluate"
  \\ fs [wordSemTheory.get_var_def,lookup_insert] \\ rfs []
  \\ pop_assum drule
  \\ impl_tac THEN1 (fs [adjust_var_def] \\ fs [state_rel_def]
                     \\ `i < dimword (:'a)` by decide_tac \\ fs [])
  \\ strip_tac \\ fs []
  \\ pop_assum mp_tac \\ fs []
  \\ strip_tac \\ fs []
  \\ simp [state_rel_thm]
  \\ qunabbrev_tac `s3` \\ fs []
  \\ fs [lookup_def]
  \\ qpat_assum `memory_rel _ _ _ _ _ _ _ _` mp_tac
  \\ fs [EVAL ``join_env LN []``]
  \\ drule memory_rel_zero_space
  \\ `EndOfHeap <> TriggerGC` by fs []
  \\ pop_assum (fn th => fs [MATCH_MP FUPDATE_COMMUTES th])
  \\ fs [GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB,Abbr`ww1`]
  \\ match_mp_tac memory_rel_rearrange
  \\ fs [] \\ rw [] \\ rw []
  \\ fs [FAPPLY_FUPDATE_THM]
  \\ disj1_tac
  \\ fs [make_ptr_def]
  \\ qunabbrev_tac `ww`
  \\ AP_THM_TAC \\ AP_TERM_TAC \\ fs []
  \\ fs [GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]);

val word_exp_SmallLsr = Q.store_thm("word_exp_SmallLsr",
  `word_exp s (SmallLsr e n) =
      if dimindex (:'a) <= n then NONE else
        case word_exp s e of
        | SOME (Word w) => SOME (Word ((w:'a word) >>> n))
        | res => (if n = 0 then res else NONE)`,
  rw [SmallLsr_def] \\ assume_tac DIMINDEX_GT_0
  \\ TRY (`F` by decide_tac \\ NO_TAC)
  THEN1
   (full_simp_tac std_ss [GSYM NOT_LESS]
    \\ Cases_on `word_exp s e` \\ fs []
    \\ Cases_on `x` \\ fs [])
  \\ fs [word_exp_rw] \\ every_case_tac \\ fs []  );

val evaluate_MakeBytes = Q.store_thm("evaluate_MakeBytes",
  `good_dimindex (:'a) ==>
    evaluate (MakeBytes n,s) =
      case get_var n s of
      | SOME (Word w) => (NONE,set_var n (Word (word_of_byte ((w:'a word) >>> 2))) s)
      | _ => (SOME Error,s)`,
  fs [MakeBytes_def,list_Seq_def,wordSemTheory.evaluate_def,word_exp_rw,
      wordSemTheory.get_var_def] \\ strip_tac
  \\ Cases_on `lookup n s.locals` \\ fs []
  \\ Cases_on `x` \\ fs [] \\ IF_CASES_TAC
  \\ fs [EVAL ``good_dimindex (:'a)``]
  \\ fs [wordSemTheory.set_var_def,lookup_insert,word_of_byte_def,
         insert_shadow,wordSemTheory.evaluate_def,word_exp_rw]);

val w2w_shift_shift = Q.store_thm("w2w_shift_shift",
  `good_dimindex (:'a) ==> ((w2w (w:word8) ≪ 2 ⋙ 2) : 'a word) = w2w w`,
  fs [labPropsTheory.good_dimindex_def,fcpTheory.CART_EQ,
      word_lsl_def,word_lsr_def,fcpTheory.FCP_BETA,w2w]
  \\ rw [] \\ fs [] \\ EQ_TAC \\ rw [] \\ rfs [fcpTheory.FCP_BETA,w2w]);

fun sort_tac n =
  CONV_TAC(PATH_CONV(String.concat(List.tabulate(n,(K "lr"))))(REWR_CONV set_byte_sort)) \\
  simp[labPropsTheory.good_dimindex_def]

val evaluate_WriteLastBytes = Q.store_thm("evaluate_WriteLastBytes",
  `good_dimindex(:'a) ∧ w2n n < dimindex(:'a) DIV 8 ∧
   get_vars [av;bv;nv] (s:('a,'ffi)state) = SOME [Word (a:'a word); Word b; Word n] ∧
   byte_aligned a ∧ a ∈ s.mdomain ∧ s.memory a = Word w
  ⇒
   evaluate (WriteLastBytes av bv nv,s) =
     (NONE, s with memory := (a =+ Word (last_bytes (w2n n) (w2w b) 0w w s.be)) s.memory)`,
  rw[labPropsTheory.good_dimindex_def]
  \\ fs[get_vars_SOME_IFF]
  \\ simp[WriteLastBytes_def]
  \\ simp[WriteLastByte_aux_def]
  \\ map_every (let
      val th = CONV_RULE(RESORT_FORALL_CONV(sort_vars["p","b"])) align_add_aligned
      val th = Q.SPEC`LOG2 (dimindex(:'a) DIV 8)`th
      val th2 = set_byte_change_a |> Q.GEN`b` |> Q.SPEC`w2w b` |> Q.GENL[`w`,`a'`,`a`,`be`]
      in (fn n =>
       let val nw = Int.toString n ^ "w" in
         qspecl_then([[QUOTE nw],`a`])mp_tac th \\
         qspecl_then([`s.be`,[QUOTE (nw^"+ byte_align a")], [QUOTE nw]])mp_tac th2
       end) end)
       (List.tabulate(8,I))
  \\ simp_tac std_ss [GSYM byte_align_def,GSYM byte_aligned_def]
  \\ fs[w2n_add_byte_align_lemma,labPropsTheory.good_dimindex_def]
  \\ fs[dimword_def]
  \\ rpt strip_tac
  \\ fs[wordSemTheory.evaluate_def,wordSemTheory.inst_def,
        wordSemTheory.get_var_imm_def,
        word_exp_rw, wordSemTheory.get_var_def,
        asmTheory.word_cmp_def,last_bytes_simp,
        wordSemTheory.mem_store_byte_aux_def,
        APPLY_UPDATE_THM]
  \\ rw[wordSemTheory.state_component_equality,
        FUN_EQ_THM,APPLY_UPDATE_THM,
        dimword_def, last_bytes_simp]
  \\ rw[] \\ rw[] \\ rfs[dimword_def]
  >- ( simp[Once set_byte_sort,labPropsTheory.good_dimindex_def] )
  >- ( map_every sort_tac [1,2,1])
  >- ( Cases_on`n` \\ fs[dimword_def] \\ rfs[] )
  >- ( simp[Once set_byte_sort,labPropsTheory.good_dimindex_def] )
  >- ( map_every sort_tac [1,2,1] )
  >- ( map_every sort_tac [1,2,3,2,1,2] )
  >- ( map_every sort_tac [1,2,3,4,3,2,1,2,3,2] )
  >- ( map_every sort_tac [1,2,3,4,5,4,3,2,1,2,3,4,3,2,3] )
  >- ( map_every sort_tac [1,2,3,4,5,6,5,4,3,2,1,2,3,4,5,4,3,2,3,4,5,4,3,4,3,4,5] )
  >- ( Cases_on`n` \\ fs[dimword_def] \\ rfs[] ));

val byte_aligned_bytes_in_word = prove(
  ``good_dimindex (:'a) ==>
    byte_aligned (w * bytes_in_word) /\
    byte_aligned (bytes_in_word * w:'a word)``,
  fs [byte_aligned_def,good_dimindex_def] \\ rw []
  \\ fs [bytes_in_word_def]
  \\ `aligned 2 (0w + w * n2w (2 ** 2)) /\
      aligned 3 (0w + w * n2w (2 ** 3))` by
    (Cases_on `w` \\ rewrite_tac [word_mul_n2w,aligned_add_pow,aligned_0])
  \\ fs []);

val RefByte_thm = Q.store_thm("RefByte_thm",
  `state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs /\
    get_vars [0;1;2] s.locals = SOME (vals ++ [Number &(if fl then 0 else 4)]) /\
    t.clock = MustTerminate_limit (:'a) - 1 /\
    do_app (RefByte fl) vals s = Rval (v,s2) ==>
    ?q r new_c.
      evaluate (RefByte_code c,t) = (q,r) /\
      if q = SOME NotEnoughSpace then
        r.ffi = t.ffi
      else
        ?rv. q = SOME (Result (Loc l1 l2) rv) /\
             state_rel c r1 r2 (s2 with <| locals := LN; clock := new_c |>)
                r [(v,rv)] locs`,
  qpat_abbrev_tac`tag = if fl then _ else _`
  \\ fs [RefByte_code_def]
  \\ fs [do_app_def,do_space_def,EVAL ``op_space_reset (RefByte fl)``,
         bviSemTheory.do_app_def,bvlSemTheory.do_app_def,
         bviSemTheory.do_app_aux_def]
  \\ Cases_on `vals` \\ fs []
  \\ Cases_on `t'` \\ fs []
  \\ Cases_on `h` \\ fs []
  \\ Cases_on `t''` \\ fs []
  \\ Cases_on `h'` \\ fs []
  \\ IF_CASES_TAC \\ fs [] \\ rw []
  \\ `good_dimindex (:'a)` by fs [state_rel_def]
  \\ drule NONNEG_INT \\ strip_tac \\ rveq \\ fs []
  \\ rename1 `get_vars [0; 1; 2] s.locals = SOME [Number (&i); Number (&w2n w); Number &tag]`
  \\ qpat_abbrev_tac `s3 = bvi_to_data _ _`
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw]
  \\ rpt_drule state_rel_get_vars_IMP \\ strip_tac \\ fs [LENGTH_EQ_NUM_compute]
  \\ rveq \\ fs [adjust_var_def,get_vars_SOME_IFF]
  \\ fs [get_vars_SOME_IFF_data]
  \\ drule (Q.GEN`a1`(Q.SPEC `0` state_rel_get_var_Number_IMP_alt)) \\ fs []
  \\ strip_tac \\ rveq
  \\ rpt_drule evaluate_BignumHalt
  \\ Cases_on `small_int (:α) (&i)` \\ fs [] \\ strip_tac \\ fs []
  \\ ntac 3 (pop_assum kall_tac)
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw]
  \\ rpt_drule state_rel_get_vars_IMP \\ strip_tac \\ fs [LENGTH_EQ_2]
  \\ rveq \\ fs [adjust_var_def,get_vars_SOME_IFF]
  \\ fs [wordSemTheory.get_var_def]
  \\ `w' = n2w (4 * i) /\ 4 * i < dimword (:'a)` by
   (fs [state_rel_thm]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ qpat_x_assum `get_var 0 s.locals = SOME (Number (&i))` assume_tac
    \\ rpt_drule memory_rel_get_var_IMP \\ fs [adjust_var_def]
    \\ fs [wordSemTheory.get_var_def]
    \\ strip_tac \\ imp_res_tac memory_rel_Number_IMP
    \\ fs [Smallnum_def] \\ fs [small_int_def] \\ fs [X_LT_DIV] \\ NO_TAC)
  \\ rveq \\ fs [word_exp_SmallLsr]
  \\ IF_CASES_TAC
  THEN1 (fs [shift_def,state_rel_def,
             EVAL ``good_dimindex (:'a)``] \\ rfs []) \\ fs []
  \\ pop_assum kall_tac
  \\ fs [word_exp_rw]
  \\ IF_CASES_TAC
  THEN1 (fs [shift_def,state_rel_def,
             EVAL ``good_dimindex (:'a)``] \\ rfs []) \\ fs []
  \\ pop_assum kall_tac
  \\ `n2w (4 * i) ⋙ 2 = (n2w i):'a word` by
   (rewrite_tac [GSYM w2n_11,w2n_lsr]
    \\ fs [ONCE_REWRITE_RULE [MULT_COMM] MULT_DIV] \\ NO_TAC) \\ fs []
  \\ qabbrev_tac `wA = ((bytes_in_word + n2w i + -1w)
        ⋙ (dimindex (:α) − 63)):'a word`
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw]
  \\ `state_rel c l1 l2 s (set_var 1 (Word wA) t) [] locs` by
        fs [wordSemTheory.set_var_def,state_rel_insert_1]
  \\ rpt_drule AllocVar_thm
  \\ `?x. dataSem$cut_env (fromList [();();()]) s.locals = SOME x` by
    (fs [EVAL ``fromList [(); (); ()]``,cut_env_def,domain_lookup,
         get_var_def,get_vars_SOME_IFF_data] \\ NO_TAC)
  \\ disch_then drule
  \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def]
  \\ qabbrev_tac `limit = MIN (2 ** c.len_size) (dimword (:α) DIV 16)`
  \\ fs [get_var_set_var_thm]
  \\ Cases_on `evaluate
       (AllocVar limit (fromList [(); (); ()]),set_var 1 (Word wA) t)` \\ fs []
  \\ disch_then drule
  \\ impl_tac THEN1 (unabbrev_all_tac \\ fs []
                     \\ fs [state_rel_def,EVAL ``good_dimindex (:'a)``,dimword_def])
  \\ strip_tac \\ fs [set_vars_sing]
  \\ reverse IF_CASES_TAC \\ fs []
  \\ rveq \\ fs []
  \\ fs [bviSemTheory.bvl_to_bvi_def,
         bviSemTheory.bvi_to_bvl_def,
         dataSemTheory.bvi_to_data_def,
         dataSemTheory.call_env_def,
         dataSemTheory.data_to_bvi_def,push_env_def,
         dataSemTheory.set_var_def,wordSemTheory.set_var_def]
  \\ qabbrev_tac `new = LEAST ptr. ptr ∉ FDOM s.refs`
  \\ `new ∉ FDOM s.refs` by metis_tac [LEAST_NOTIN_FDOM]
  \\ fs [] \\ once_rewrite_tac [list_Seq_def]
  \\ fs [] \\ once_rewrite_tac [list_Seq_def]
  \\ fs [] \\ once_rewrite_tac [list_Seq_def]
  \\ once_rewrite_tac [wordSemTheory.evaluate_def]
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ fs [word_exp_rw]
  \\ `lookup 2 r.locals = SOME (Word (n2w (4 * i)))` by
   (qabbrev_tac `s9 = s with <|locals := x; space := w2n wA DIV 4 + 1|>`
    \\ fs [state_rel_def,get_vars_SOME_IFF_data]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,get_var_def]
    \\ rpt_drule word_ml_inv_get_var_IMP
    \\ fs [get_var_def,wordSemTheory.get_var_def,adjust_var_def]
    \\ `lookup 0 s9.locals = SOME (Number (&i))` by
     (unabbrev_all_tac \\ fs [cut_env_def] \\ rveq
      \\ fs [lookup_inter_alt] \\ EVAL_TAC)
    \\ rpt (disch_then drule) \\ fs []
    \\ `IS_SOME (lookup 0 s9.locals)` by fs []
    \\ res_tac \\ Cases_on `lookup 2 r.locals` \\ fs []
    \\ fs [word_ml_inv_def] \\ rw []
    \\ fs [abs_ml_inv_def,bc_stack_ref_inv_def,v_inv_def] \\ rfs []
    \\ rw [] \\ fs [word_addr_def,Smallnum_def]
    \\ fs [small_int_def,X_LT_DIV]
    \\ match_mp_tac minus_2_word_and_id
    \\ fs [word_index,word_mul_n2w,bitTheory.BIT0_ODD,ODD_MULT] \\ NO_TAC)
  \\ `~(2 ≥ dimindex (:α))` by (fs [good_dimindex_def] \\ NO_TAC)
  \\ `shift (:α) ≠ 0 /\ ~(shift (:α) ≥ dimindex (:α))` by
        (rw [shift_def] \\ fs [good_dimindex_def] \\ NO_TAC)
  \\ simp []
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ fs [word_exp_rw]
  \\ `(?free. FLOOKUP r.store NextFree = SOME (Word free)) /\
      (?eoh1. FLOOKUP r.store EndOfHeap = SOME (Word eoh1)) /\
      (?cur1. FLOOKUP r.store CurrHeap = SOME (Word cur1))` by
        (fs [state_rel_thm,memory_rel_def,heap_in_memory_store_def] \\ NO_TAC)
  \\ fs []
  \\ `lookup 4 r.locals = SOME (Word (w2w w << 2))` by
   (qabbrev_tac `s9 = s with <|locals := x; space := w2n wA DIV 4 + 1|>`
    \\ fs [state_rel_def,get_vars_SOME_IFF_data]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,get_var_def]
    \\ rpt_drule word_ml_inv_get_var_IMP
    \\ fs [get_var_def,wordSemTheory.get_var_def,adjust_var_def]
    \\ `lookup 1 s9.locals = SOME (Number (&w2n w))` by
     (unabbrev_all_tac \\ fs [cut_env_def] \\ rveq
      \\ fs [lookup_inter_alt] \\ EVAL_TAC)
    \\ rpt (disch_then drule) \\ fs []
    \\ `IS_SOME (lookup 1 s9.locals)` by fs []
    \\ res_tac \\ Cases_on `lookup 4 r.locals` \\ fs []
    \\ fs [word_ml_inv_def] \\ rw []
    \\ fs [abs_ml_inv_def,bc_stack_ref_inv_def,v_inv_def] \\ rfs []
    \\ rw [] \\ fs [word_addr_def,Smallnum_def]
    \\ fs [word_mul_n2w,w2w_def,WORD_MUL_LSL]
    \\ fs [small_int_def,X_LT_DIV]
    \\ match_mp_tac minus_2_word_and_id
    \\ fs [word_index,word_mul_n2w,bitTheory.BIT0_ODD,ODD_MULT] \\ NO_TAC)
  \\ `lookup 6 r.locals = SOME (Word (n2w (4 * tag)))` by
   (qabbrev_tac `s9 = s with <|locals := x; space := w2n wA DIV 4 + 1|>`
    \\ fs [state_rel_def,get_vars_SOME_IFF_data]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,get_var_def]
    \\ rpt_drule word_ml_inv_get_var_IMP
    \\ fs [get_var_def,wordSemTheory.get_var_def,adjust_var_def]
    \\ `lookup 2 s9.locals = SOME (Number &tag)` by
     (unabbrev_all_tac \\ fs [cut_env_def] \\ rveq
      \\ fs [lookup_inter_alt] \\ EVAL_TAC)
    \\ rpt (disch_then drule) \\ fs []
    \\ `IS_SOME (lookup 2 s9.locals)` by fs []
    \\ res_tac \\ Cases_on `lookup 6 r.locals` \\ fs []
    \\ fs [word_ml_inv_def] \\ rw []
    \\ fs [abs_ml_inv_def,bc_stack_ref_inv_def,v_inv_def] \\ rfs []
    \\ `small_int (:'a) (&tag)`
    by (
      rw[small_int_def,Abbr`tag`]
      \\ fs[labPropsTheory.good_dimindex_def,dimword_def] )
    \\ fs[word_addr_def,Smallnum_def]
    \\ match_mp_tac minus_2_word_and_id
    \\ simp[word_index,bitTheory.BIT0_ODD,ODD_MULT]
    \\ NO_TAC)
  \\ fs [wordSemTheory.set_var_def,lookup_insert]
  \\ fs [] \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw,wordSemTheory.set_var_def]
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw,wordSemTheory.set_var_def,
         wordSemTheory.set_store_def]
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw,wordSemTheory.set_var_def,
         wordSemTheory.set_store_def,FLOOKUP_UPDATE]
  \\ IF_CASES_TAC
  THEN1 (fs [shift_def,shift_length_def,state_rel_def,
                 EVAL ``good_dimindex (:'a)``] \\ fs [])
  \\ pop_assum kall_tac \\ fs []
  \\ qabbrev_tac `var5 = (bytes_in_word + n2w i + -1w:'a word) ⋙ shift (:α)`
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw,wordSemTheory.set_var_def,
         wordSemTheory.set_store_def]
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw,wordSemTheory.set_var_def,
         wordSemTheory.set_store_def]
  \\ fs [evaluate_MakeBytes,word_exp_rw,wordSemTheory.set_var_def,
         lookup_insert,wordSemTheory.get_var_def,w2w_shift_shift]
  \\ qpat_assum `state_rel c l1 l2 _ _ _ _` mp_tac
  \\ simp_tac std_ss [Once state_rel_thm] \\ strip_tac \\ fs []
  \\ `w2n wA DIV 4 = byte_len (:'a) i` by
   (unabbrev_all_tac \\ fs [byte_len_def,bytes_in_word_def,w2n_lsr,
      labPropsTheory.good_dimindex_def,word_add_n2w,dimword_def] \\ rfs []
    \\ fs [GSYM word_add_n2w] \\ fs [word_add_n2w,dimword_def]
    \\ fs [DIV_DIV_DIV_MULT] \\ NO_TAC)
  \\ fs [wordSemTheory.set_var_def,lookup_insert]
  \\ rpt_drule memory_rel_RefByte_alt
  \\ disch_then (qspecl_then [`w`,`i`,`fl`] mp_tac) \\ fs []
  \\ impl_tac THEN1
   (unabbrev_all_tac \\ fs []
    \\ fs [labPropsTheory.good_dimindex_def,dimword_def] \\ rfs [])
  \\ strip_tac \\ fs [FLOOKUP_DEF] \\ rveq \\ clean_tac
  \\ `var5 = n2w (byte_len (:α) i)` by
   (unabbrev_all_tac
    \\ rewrite_tac [GSYM w2n_11,w2n_lsr,byte_len_def]
    \\ fs [bytes_in_word_def,shift_def,labPropsTheory.good_dimindex_def]
    \\ fs [word_add_n2w]
    THEN1
     (`i + 3 < dimword (:'a)` by all_tac
      \\ `i + 3 DIV 4 < dimword (:'a)` by all_tac \\ fs []
      \\ rfs [dimword_def] \\ fs [DIV_LT_X])
    THEN1
     (`i + 7 < dimword (:'a)` by all_tac
      \\ `i + 7 DIV 8 < dimword (:'a)` by all_tac \\ fs []
      \\ rfs [dimword_def] \\ fs [DIV_LT_X]) \\ NO_TAC)
  \\ fs [] \\ rveq
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw,wordSemTheory.set_var_def,
         wordSemTheory.set_store_def,wordSemTheory.get_var_def,lookup_insert,
         wordSemTheory.mem_store_def,store_list_def]
  \\ once_rewrite_tac [list_Seq_def]
  \\ simp[Once wordSemTheory.evaluate_def,
          wordSemTheory.get_var_def,lookup_insert,
          wordSemTheory.get_var_imm_def,
          asmTheory.word_cmp_def]
  \\ rfs [shift_lsl,GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
  \\ qpat_abbrev_tac `ppp = Word (_ || _:'a word)`
  \\ `ppp = Word (make_byte_header c fl i)` by
   (unabbrev_all_tac \\ fs [make_byte_header_def,bytes_in_word_def]
    \\ Cases_on`fl`
    \\ fs [labPropsTheory.good_dimindex_def,GSYM word_add_n2w,WORD_MUL_LSL]
    \\ fs [word_mul_n2w,word_add_n2w,shift_def,RIGHT_ADD_DISTRIB]
    \\ NO_TAC)
  \\ rveq \\ pop_assum kall_tac
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw,
         wordSemTheory.get_var_def,lookup_insert,
         wordSemTheory.mem_store_def,store_list_def]
  \\ IF_CASES_TAC
  >- (
    simp[Once wordSemTheory.evaluate_def,
         wordSemTheory.get_var_def,lookup_insert,
         wordSemTheory.call_env_def]
    \\ fs[state_rel_thm,Abbr`s3`,fromList2_def,lookup_def]
    \\ fs[make_ptr_def,join_env_NIL,FAPPLY_FUPDATE_THM]
    \\ fs[WORD_MUL_LSL,word_mul_n2w]
    \\ `4 * byte_len (:'a) i = 0`
    by (
      match_mp_tac (MP_CANON MOD_EQ_0_0)
      \\ qexists_tac`dimword(:'a)`
      \\ simp[]
      \\ rfs[Abbr`limit`,labPropsTheory.good_dimindex_def,dimword_def]
      \\ fs[] \\ NO_TAC)
    \\ fs[REPLICATE,LUPDATE_def,store_list_def]
    \\ rveq
    \\ qhdtm_x_assum`memory_rel`mp_tac
    \\ simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ qmatch_goalsub_abbrev_tac`(RefPtr new,val)::(ll++rest)`
    \\ fs[]
    \\ match_mp_tac memory_rel_rearrange
    \\ rpt (pop_assum kall_tac)
    \\ fs [] \\ rw [] \\ fs [])
  \\ once_rewrite_tac[list_Seq_def]
  \\ simp[wordSemTheory.evaluate_def,word_exp_rw]
  \\ simp[wordSemTheory.set_var_def]
  \\ once_rewrite_tac[list_Seq_def]
  \\ simp[wordSemTheory.evaluate_def,word_exp_rw,
          asmTheory.word_cmp_def,wordSemTheory.get_var_def]
  \\ `(bytes_in_word:'a word) + -1w = n2w (2 ** shift(:'a) - 1)`
  by ( fs[bytes_in_word_def,labPropsTheory.good_dimindex_def,shift_def] )
  \\ simp[WORD_AND_EXP_SUB1]
  \\ `i MOD 2 ** (shift(:'a)) < dimword(:'a)`
  by (
    match_mp_tac LESS_LESS_EQ_TRANS
    \\ qexists_tac`2 ** shift(:'a)`
    \\ simp[]
    \\ fs[labPropsTheory.good_dimindex_def,dimword_def,shift_def] )
  \\ simp[]
  \\ `2 ** shift(:'a) = dimindex(:'a) DIV 8`
    by ( fs[labPropsTheory.good_dimindex_def,dimword_def,shift_def] )
  \\ simp[]
  \\ IF_CASES_TAC \\ fs[]
  >- (
    simp[list_Seq_def]
    \\ `lookup Replicate_location r.code = SOME (5,Replicate_code)` by
           (imp_res_tac lookup_RefByte_location \\ NO_TAC)
    \\ assume_tac (GEN_ALL Replicate_code_thm)
    \\ SEP_I_TAC "evaluate"
    \\ fs[wordSemTheory.get_var_def,lookup_insert] \\ rfs[]
    \\ pop_assum mp_tac \\ disch_then drule
    \\ impl_tac THEN1
     (fs [WORD_MUL_LSL,word_mul_n2w,state_rel_def]
      \\ fs [labPropsTheory.good_dimindex_def,dimword_def] \\ rfs []
      \\ unabbrev_all_tac \\ fs []
      \\ `byte_len (:α) i < dimword (:'a)` by (fs [dimword_def])
      \\ fs [IMP_LESS_MustTerminate_limit])
    \\ fs [WORD_MUL_LSL,word_mul_n2w]
    \\ disch_then kall_tac
    \\ simp[state_rel_thm,Abbr`s3`,lookup_def]
    \\ fs[make_ptr_def,join_env_NIL,FAPPLY_FUPDATE_THM]
    \\ fs [WORD_MUL_LSL,word_mul_n2w]
    \\ qhdtm_x_assum`memory_rel`mp_tac
    \\ simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_rearrange
    \\ rpt (pop_assum kall_tac)
    \\ rw [] \\ fs [] \\ rw [])
  \\ simp[CONJUNCT2 (CONJUNCT2 list_Seq_def),
          wordSemTheory.evaluate_def,word_exp_rw,
          wordSemTheory.set_var_def,
          wordSemTheory.mem_store_def,
          wordSemTheory.get_var_def,lookup_insert]
  \\ reverse IF_CASES_TAC
  >- (
    `F` suffices_by rw[]
    \\ pop_assum mp_tac \\ simp []
    \\ imp_res_tac store_list_domain
    \\ fs[LENGTH_REPLICATE]
    \\ first_x_assum(qspec_then`byte_len(:'a) i-1`mp_tac)
    \\ simp[]
    \\ fs[WORD_MUL_LSL,word_mul_n2w]
    \\ Cases_on`byte_len(:'a) i = 0` \\ fs[]
    \\ Cases_on`byte_len(:'a) i` \\ fs[ADD1,GSYM word_add_n2w]
    \\ simp[WORD_MULT_CLAUSES,WORD_LEFT_ADD_DISTRIB]
    \\ NO_TAC)
  \\ fs[]
  \\ pairarg_tac \\ fs[]
  \\ pairarg_tac \\ fs[]
  \\ pop_assum mp_tac
  \\ assume_tac(GEN_ALL evaluate_WriteLastBytes)
  \\ SEP_I_TAC "evaluate"
  \\ pop_assum mp_tac
  \\ simp[wordSemTheory.get_vars_def,wordSemTheory.get_var_def,lookup_insert,APPLY_UPDATE_THM]
  \\ impl_tac
  >- (
    conj_tac >- fs[labPropsTheory.good_dimindex_def]
    \\ fs[memory_rel_def,heap_in_memory_store_def,FLOOKUP_UPDATE]
    \\ fs[FLOOKUP_DEF]
    \\ qpat_x_assum `free' + bytes_in_word + _ = _` mp_tac
    \\ simp_tac std_ss [WORD_ADD_EQ_SUB]
    \\ simp[aligned_add_sub] \\ rpt strip_tac \\ rveq
    \\ fs [byte_aligned_def]
    \\ rewrite_tac [GSYM WORD_ADD_ASSOC]
    \\ (alignmentTheory.aligned_add_sub_cor
          |> SPEC_ALL |> UNDISCH_ALL |> CONJUNCT1 |> DISCH_ALL |> match_mp_tac)
    \\ fs []
    \\ (alignmentTheory.aligned_add_sub_cor
          |> SPEC_ALL |> UNDISCH_ALL |> CONJUNCT1 |> DISCH_ALL |> match_mp_tac)
    \\ fs [GSYM byte_aligned_def]
    \\ fs [byte_aligned_bytes_in_word])
  \\ simp[] \\ disch_then kall_tac
  \\ strip_tac \\ fs[] \\ clean_tac \\ fs[]
  \\ pop_assum mp_tac \\ simp[list_Seq_def]
  \\ simp[Once wordSemTheory.evaluate_def,word_exp_rw,wordSemTheory.set_var_def]
  \\ strip_tac \\ clean_tac \\ fs[]
  \\ `lookup Replicate_location r.code = SOME (5,Replicate_code)` by
         (imp_res_tac lookup_RefByte_location \\ NO_TAC)
  \\ qmatch_asmsub_abbrev_tac`LUPDATE lw (len-1) ls`
  \\ qmatch_assum_abbrev_tac`Abbrev(ls = REPLICATE len rw)`
  \\ `0 < len` by ( Cases_on`len` \\ fs[] )
  \\ `ls = REPLICATE (len-1) rw ++ [rw] ++ []`
  by (
    simp[Abbr`ls`,LIST_EQ_REWRITE,EL_REPLICATE,LENGTH_REPLICATE]
    \\ qx_gen_tac`z` \\ strip_tac
    \\ Cases_on`z = len-1` \\ simp[EL_APPEND1,EL_APPEND2,EL_REPLICATE,LENGTH_REPLICATE] )
  \\ `LUPDATE lw (len-1) ls = REPLICATE (len-1) rw ++ [lw] ++ []` by metis_tac[lupdate_append2,LENGTH_REPLICATE]
  \\ pop_assum SUBST_ALL_TAC
  \\ pop_assum kall_tac \\ fs[]
  \\ imp_res_tac store_list_append_imp
  \\ assume_tac (GEN_ALL Replicate_code_thm)
  \\ SEP_I_TAC "evaluate"
  \\ pop_assum mp_tac \\ fs[wordSemTheory.get_var_def,lookup_insert]
  \\ simp[UPDATE_EQ]
  \\ qmatch_goalsub_abbrev_tac`(a' =+ v)`
  \\ qhdtm_x_assum`store_list`mp_tac
  \\ drule (Q.GEN`a'`store_list_update_m_outside)
  \\ disch_then(qspec_then`a'`mp_tac)
  \\ impl_tac
  >- (
    simp[Abbr`a'`,LENGTH_REPLICATE]
    \\ rewrite_tac[GSYM WORD_ADD_ASSOC]
    \\ simp[WORD_EQ_ADD_LCANCEL]
    \\ CONV_TAC(PATH_CONV"brrlrr"(REWR_CONV WORD_MULT_COMM))
    \\ rewrite_tac[GSYM WORD_MULT_ASSOC]
    \\ `len < dimword (:α) DIV 16` by
          (unabbrev_all_tac \\ fs [])
    \\ qpat_x_assum `good_dimindex (:'a)` mp_tac
    \\ pop_assum mp_tac
    \\ rpt (pop_assum kall_tac)
    \\ fs [good_dimindex_def] \\ rw [] \\ fs [bytes_in_word_def]
    \\ fs [word_add_n2w,word_mul_n2w,dimword_def])
  \\ ntac 2 strip_tac
  \\ disch_then drule
  \\ impl_tac THEN1 (
    simp[Abbr`len`,WORD_MUL_LSL,word_mul_n2w,LEFT_SUB_DISTRIB,n2w_sub]
    \\ fs [labPropsTheory.good_dimindex_def,dimword_def,state_rel_thm] \\ rfs []
    \\ unabbrev_all_tac \\ fs []
    \\ `byte_len (:α) i -1 < dimword (:'a)` by (fs [dimword_def])
    \\ imp_res_tac IMP_LESS_MustTerminate_limit \\ fs[])
  \\ simp[WORD_MUL_LSL,n2w_sub,GSYM word_mul_n2w,WORD_LEFT_ADD_DISTRIB]
  \\ disch_then kall_tac
  \\ simp [state_rel_thm]
  \\ qunabbrev_tac `s3` \\ fs []
  \\ fs [lookup_def]
  \\ qhdtm_x_assum `memory_rel` mp_tac
  \\ fs [EVAL ``join_env LN []``]
  \\ fs[store_list_def]
  \\ fs[Abbr`a'`,Abbr`v`,LENGTH_REPLICATE]
  \\ clean_tac
  \\ fs[make_ptr_def,WORD_MUL_LSL]
  \\ qmatch_abbrev_tac`P xx yy zz ⇒ P x' yy z'`
  \\ `xx = x'`
  by (
    simp[Abbr`xx`,Abbr`x'`,FUN_EQ_THM,APPLY_UPDATE_THM,Abbr`lw`]
    \\ simp[n2w_sub,WORD_LEFT_ADD_DISTRIB] \\ rw[]
    \\ simp[w2w_word_of_byte_w2w] )
  \\ rveq \\ qunabbrev_tac `P`
  \\ match_mp_tac memory_rel_rearrange
  \\ unabbrev_all_tac \\ rpt (pop_assum kall_tac)
  \\ fs[FAPPLY_FUPDATE_THM]
  \\ rw [] \\ fs []);

val FromList1_code_thm = Q.store_thm("Replicate_code_thm",
  `!k a b r x m1 a1 a2 a3 a4 a5 a6.
      lookup FromList1_location r.code = SOME (6,FromList1_code c) /\
      copy_list c r.store k (a,x,b,(r:('a,'ffi) wordSem$state).memory,
        r.mdomain) = SOME (b1,m1) /\
      shift_length c < dimindex (:'a) /\ good_dimindex (:'a) /\
      get_var a1 r = SOME (Loc l1 l2) /\
      get_var a2 r = SOME (Word (b:'a word)) /\
      get_var a3 r = SOME a /\
      get_var a4 r = SOME (Word (n2w (4 * k))) /\
      get_var a5 r = SOME ret_val /\
      get_var a6 r = SOME x /\
      4 * k < dimword (:'a) /\
      k < r.clock ==>
      evaluate (Call NONE (SOME FromList1_location) [a1;a2;a3;a4;a5;a6] NONE,r) =
        (SOME (Result (Loc l1 l2) ret_val),
         r with <| memory := m1 ; clock := r.clock - k - 1; locals := LN ;
                   store := r.store |+ (NextFree, Word b1) |>)`,
  Induct \\ rw [] \\ simp [wordSemTheory.evaluate_def]
  \\ simp [wordSemTheory.get_vars_def,wordSemTheory.bad_dest_args_def,
        wordSemTheory.find_code_def,wordSemTheory.add_ret_loc_def]
  \\ rw [] \\ simp [FromList1_code_def]
  \\ simp [Once list_Seq_def]
  \\ qpat_assum `_ = SOME (b1,m1)` mp_tac
  \\ once_rewrite_tac [copy_list_def] \\ fs []
  \\ strip_tac THEN1
   (rveq
    \\ simp [wordSemTheory.evaluate_def,wordSemTheory.call_env_def,
             wordSemTheory.get_var_def,word_exp_rw,fromList2_def,
             asmTheory.word_cmp_def,wordSemTheory.dec_clock_def,lookup_insert,
             wordSemTheory.mem_store_def,list_Seq_def,wordSemTheory.set_var_def,
             wordSemTheory.set_store_def])
  \\ Cases_on `a` \\ fs []
  \\ Cases_on `get_real_addr c r.store c'` \\ fs []
  \\ qabbrev_tac `m9 = (b =+ x) r.memory`
  \\ ntac 2 (simp [Once list_Seq_def])
  \\ simp [wordSemTheory.evaluate_def,word_exp_rw,wordSemTheory.call_env_def,
           wordSemTheory.get_var_def,word_exp_rw,fromList2_def,
           wordSemTheory.mem_store_def,wordSemTheory.dec_clock_def,lookup_insert,
           wordSemTheory.set_var_def,asmTheory.word_cmp_def]
  \\ ntac 4 (simp [Once list_Seq_def])
  \\ simp [wordSemTheory.evaluate_def,word_exp_rw,wordSemTheory.call_env_def,
           wordSemTheory.get_var_def,word_exp_rw,fromList2_def,
           wordSemTheory.mem_store_def,wordSemTheory.dec_clock_def,lookup_insert,
           wordSemTheory.set_var_def,asmTheory.word_cmp_def]
  \\ qpat_abbrev_tac `r3 =
          (r with
           <|locals :=
               insert 2 (Word (b + bytes_in_word)) _;
             memory := m9; clock := r.clock − 1|>)`
  \\ rename1 `get_real_addr c r.store c1 = SOME x1`
  \\ `get_real_addr c r3.store c1 = SOME x1` by (fs [Abbr `r3`])
  \\ rpt_drule (get_real_addr_lemma
        |> REWRITE_RULE [CONJ_ASSOC]
        |> ONCE_REWRITE_RULE [CONJ_COMM]) \\ fs []
  \\ disch_then (qspec_then `4` mp_tac)
  \\ impl_tac
  THEN1 (unabbrev_all_tac \\ fs [wordSemTheory.get_var_def,lookup_insert])
  \\ fs [wordSemTheory.mem_load_def,lookup_insert]
  \\ fs [list_Seq_def]
  \\ qpat_abbrev_tac `r7 =
       r with <|locals := insert 6 _ _ ; memory := m9 ; clock := _ |> `
  \\ first_x_assum (qspecl_then [`(m9 (x1 + 2w * bytes_in_word))`,
         `b + bytes_in_word`,`r7`,`m9 (x1 + bytes_in_word)`,`m1`,
         `0`,`2`,`4`,`6`,`8`,`10`] mp_tac)
  \\ reverse impl_tac THEN1
    (strip_tac \\ fs [] \\ rw [wordSemTheory.state_component_equality,Abbr `r7`])
  \\ unabbrev_all_tac \\ fs []
  \\ fs [wordSemTheory.get_var_def,lookup_insert]
  \\ fs [MULT_CLAUSES,GSYM word_add_n2w]);

val state_rel_IMP_test_zero = Q.store_thm("state_rel_IMP_test_zero",
  `state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) vs locs /\
    get_var i s.locals = SOME (Number n) ==>
    ?w. get_var (adjust_var i) t = SOME (Word w) /\ (w = 0w <=> (n = 0))`,
  strip_tac
  \\ rpt_drule state_rel_get_var_IMP
  \\ strip_tac \\ fs []
  \\ fs [state_rel_thm,get_vars_SOME_IFF_data] \\ rw []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,get_var_def]
  \\ drule memory_rel_drop \\ strip_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,get_var_def]
  \\ rpt_drule memory_rel_lookup
  \\ fs [wordSemTheory.get_var_def] \\ strip_tac
  \\ `small_int (:'a) 0` by
     (fs [labPropsTheory.good_dimindex_def,dimword_def,small_int_def] \\ NO_TAC)
  \\ rpt_drule (IMP_memory_rel_Number
        |> REWRITE_RULE [CONJ_ASSOC]
        |> ONCE_REWRITE_RULE [CONJ_COMM])
  \\ fs [] \\ strip_tac
  \\ drule memory_rel_Number_EQ \\ fs []
  \\ strip_tac \\ fs [Smallnum_def]
  \\ eq_tac \\ rw [] \\ fs []);

val state_rel_get_var_Number_IMP = Q.store_thm("state_rel_get_var_Number_IMP",
  `state_rel c l1 l2 s t vs locs /\
    get_var i s.locals = SOME (Number (&n)) /\ small_int (:'a) (&n) ==>
    ?w. get_var (adjust_var i) t = SOME (Word (Smallnum (&n):'a word))`,
  strip_tac
  \\ rpt_drule state_rel_get_var_IMP
  \\ strip_tac \\ fs []
  \\ fs [state_rel_thm,get_vars_SOME_IFF_data] \\ rw []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,get_var_def]
  \\ drule memory_rel_drop \\ strip_tac
  \\ fs [memory_rel_def]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,get_var_def]
  \\ rpt_drule word_ml_inv_get_var_IMP
  \\ fs [get_var_def,wordSemTheory.get_var_def,adjust_var_def]
  \\ qpat_assum `lookup i s.locals = SOME (Number (&n))` assume_tac
  \\ rpt (disch_then drule) \\ fs []
  \\ fs [word_ml_inv_def] \\ rw []
  \\ fs [abs_ml_inv_def,bc_stack_ref_inv_def,v_inv_def] \\ rfs []
  \\ rw [] \\ fs [word_addr_def,Smallnum_def]
  \\ match_mp_tac minus_2_word_and_id
  \\ fs [word_index,word_mul_n2w,bitTheory.BIT0_ODD,ODD_MULT]);

val EXP_LEMMA1 = Q.prove(
  `4n * n * (2 ** k) = n * 2 ** (k + 2)`,
  fs [EXP_ADD]);

val evaluate_Maxout_bits_code = Q.prove(
  `n_reg <> dest /\ n < dimword (:'a) /\ rep_len < dimindex (:α) /\
    k < dimindex (:'a) /\
    lookup n_reg (t:('a,'ffi) wordSem$state).locals = SOME (Word (n2w n:'a word)) ==>
    evaluate (Maxout_bits_code rep_len k dest n_reg,set_var dest (Word w) t) =
      (NONE,set_var dest (Word (w || maxout_bits n rep_len k)) t)`,
  fs [Maxout_bits_code_def,wordSemTheory.evaluate_def,wordSemTheory.get_var_def,
      wordSemTheory.set_var_def,wordSemTheory.get_var_imm_def,
      asmTheory.word_cmp_def,lookup_insert,WORD_LO,word_exp_rw,
      maxout_bits_def] \\ rw [] \\ fs [insert_shadow]
  \\ `2 ** rep_len < dimword (:α)` by all_tac \\ fs [] \\ fs [dimword_def]);

val Make_ptr_bits_thm = Q.store_thm("Make_ptr_bits_thm",
  `tag_reg ≠ dest ∧ tag1 < dimword (:α) ∧ c.tag_bits < dimindex (:α) ∧
    len_reg ≠ dest ∧ len1 < dimword (:α) ∧ c.len_bits < dimindex (:α) ∧
    c.len_bits + 1 < dimindex (:α) /\
    FLOOKUP (t:('a,'ffi) wordSem$state).store NextFree = SOME (Word f) /\
    FLOOKUP t.store CurrHeap = SOME (Word d) /\
    lookup tag_reg t.locals = SOME (Word (n2w tag1)) /\
    lookup len_reg t.locals = SOME (Word (n2w len1)) /\
    shift_length c < dimindex (:α) + shift (:α) ==>
    ?t1.
      evaluate (Make_ptr_bits_code c tag_reg len_reg dest,t) =
        (NONE,set_var dest (make_cons_ptr c (f-d) tag1 len1:'a word_loc) t)`,
  fs [Make_ptr_bits_code_def,list_Seq_def,wordSemTheory.evaluate_def,word_exp_rw]
  \\ fs [make_cons_ptr_thm] \\ strip_tac
  \\ pairarg_tac \\ fs []
  \\ pop_assum mp_tac
  \\ assume_tac (GEN_ALL evaluate_Maxout_bits_code)
  \\ SEP_I_TAC "evaluate"
  \\ pop_assum (qspec_then `tag1` mp_tac) \\ fs [] \\ rw []
  \\ assume_tac (GEN_ALL evaluate_Maxout_bits_code)
  \\ SEP_I_TAC "evaluate"
  \\ pop_assum (qspec_then `len1` mp_tac) \\ fs [] \\ rw []
  \\ fs [ptr_bits_def]);

val FromList_thm = Q.store_thm("FromList_thm",
  `state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs /\
    encode_header c (4 * tag) 0 <> (NONE:'a word option) /\
    get_vars [0; 1; 2] s.locals = SOME [v1; v2; Number (&(4 * tag))] /\
    t.clock = MustTerminate_limit (:'a) - 1 /\
    do_app (FromList tag) [v1; v2] s = Rval (v,s2) ==>
    ?q r new_c.
      evaluate (FromList_code c,t) = (q,r) /\
      if q = SOME NotEnoughSpace then
        r.ffi = t.ffi
      else
        ?rv. q = SOME (Result (Loc l1 l2) rv) /\
             state_rel c r1 r2 (s2 with <| locals := LN; clock := new_c |>)
                r [(v,rv)] locs`,
  fs [dataSemTheory.do_app_def,bviSemTheory.do_app_def,
      bviSemTheory.do_app_aux_def,dataSemTheory.do_space_def,
      bvi_to_dataTheory.op_space_reset_def]
  \\ CASE_TAC \\ fs []
  \\ Cases_on `v1 = Number (&LENGTH x)` \\ fs []
  \\ fs [LENGTH_NIL] \\ strip_tac \\ rveq \\ fs [FromList_code_def]
  \\ once_rewrite_tac [wordSemTheory.evaluate_def]
  \\ rpt_drule state_rel_get_vars_IMP
  \\ fs[wordSemTheory.get_var_imm_def,asmTheory.word_cmp_def]
  \\ rpt_drule state_rel_get_vars_IMP \\ strip_tac \\ fs [LENGTH_EQ_3]
  \\ rveq \\ fs [adjust_var_def,get_vars_SOME_IFF,get_vars_SOME_IFF_data]
  \\ qpat_assum `get_var 0 s.locals = SOME (Number (&LENGTH x))` assume_tac
  \\ rpt_drule state_rel_IMP_test_zero
  \\ fs [adjust_var_def] \\ strip_tac \\ fs [] \\ rveq
  \\ `small_int (:α) (&(4 * tag))` by
     (fs [encode_header_def,small_int_def,state_rel_thm,
          labPropsTheory.good_dimindex_def,dimword_def] \\ rfs [] \\ NO_TAC)
  \\ IF_CASES_TAC THEN1
   (qpat_assum `get_var 2 s.locals = SOME (Number (&(4*tag)))` assume_tac
    \\ rpt_drule state_rel_get_var_Number_IMP \\ fs []
    \\ fs [LENGTH_NIL] \\ rveq \\ rw []
    \\ fs [list_Seq_def,wordSemTheory.evaluate_def,word_exp_rw,
           wordSemTheory.get_var_def,adjust_var_def,wordSemTheory.set_var_def]
    \\ rveq \\ fs [lookup_insert]
    \\ `lookup 0 t.locals = SOME (Loc l1 l2)` by fs [state_rel_def] \\ fs []
    \\ fs [state_rel_thm,wordSemTheory.call_env_def,lookup_def]
    \\ fs [EVAL ``(toAList (inter (fromList2 []) (insert 0 () LN)))`` ]
    \\ fs [EVAL ``join_env LN []``,lookup_insert]
    \\ fs [BlockNil_def,Smallnum_def,WORD_MUL_LSL,word_mul_n2w]
    \\ `n2w (16 * tag) + 2w = BlockNil tag : 'a word` by
          fs [BlockNil_def,WORD_MUL_LSL,word_mul_n2w] \\ fs []
    \\ match_mp_tac memory_rel_Cons_empty
    \\ fs [encode_header_def]
    \\ drule memory_rel_zero_space
    \\ match_mp_tac memory_rel_rearrange
    \\ fs [] \\ rw [] \\ fs [])
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw]
  \\ rpt_drule state_rel_get_vars_IMP \\ strip_tac \\ fs [LENGTH_EQ_2]
  \\ rveq \\ fs [adjust_var_def,get_vars_SOME_IFF]
  \\ fs [get_vars_SOME_IFF_data]
  \\ rpt_drule state_rel_get_var_Number_IMP_alt \\ fs []
  \\ strip_tac \\ rveq
  \\ rpt_drule evaluate_BignumHalt
  \\ Cases_on `small_int (:α) (&(LENGTH x))` \\ fs [] \\ strip_tac \\ fs []
  \\ ntac 3 (pop_assum kall_tac)
  \\ fs []
  \\ ntac 2 (once_rewrite_tac [list_Seq_def])
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw,wordSemTheory.get_var_def]
  \\ pairarg_tac \\ fs []
  \\ `state_rel c l1 l2 s (set_var 1 (Word w) t) [] locs` by
        fs [wordSemTheory.set_var_def,state_rel_insert_1]
  \\ rpt_drule AllocVar_thm
  \\ `?x. dataSem$cut_env (fromList [();();()]) s.locals = SOME x` by
    (fs [EVAL ``fromList [();();()]``,cut_env_def,domain_lookup,
         get_var_def,get_vars_SOME_IFF_data] \\ NO_TAC)
  \\ disch_then drule
  \\ fs [get_var_set_var]
  \\ disch_then drule
  \\ impl_tac THEN1 (unabbrev_all_tac \\ fs []
                     \\ fs [state_rel_def,EVAL ``good_dimindex (:'a)``,dimword_def])
  \\ strip_tac \\ fs []
  \\ reverse (Cases_on `res`) \\ fs []
  \\ `?f cur. FLOOKUP s1.store NextFree = SOME (Word f) /\
              FLOOKUP s1.store CurrHeap = SOME (Word cur)` by
        (fs [state_rel_def,heap_in_memory_store_def] \\ NO_TAC)
  \\ ntac 5 (once_rewrite_tac [list_Seq_def])
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw,lookup_insert,
         wordSemTheory.set_var_def]
  \\ qabbrev_tac `s0 = s with <|locals := x'; space := w2n w DIV 4 + 1|>`
  \\ `get_var 0 s0.locals = SOME (Number (&LENGTH x)) /\
      get_var 1 s0.locals = SOME v2 /\
      get_var 2 s0.locals = SOME (Number (&(4 * tag)))` by
   (unabbrev_all_tac \\ fs [get_var_def,cut_env_def]
    \\ rveq \\ fs [lookup_inter_alt] \\ EVAL_TAC \\ NO_TAC)
  \\ qpat_assum `get_var 1 s0.locals = SOME v2` assume_tac
  \\ rpt_drule state_rel_get_var_IMP \\ strip_tac
  \\ qpat_assum `get_var 2 s0.locals = SOME (Number (&(4 * tag)))` assume_tac
  \\ rpt_drule state_rel_get_var_Number_IMP \\ strip_tac \\ fs []
  \\ `small_int (:'a) (&LENGTH x)` by (fs [] \\ NO_TAC)
  \\ qpat_assum `get_var 0 s0.locals = SOME (Number (&LENGTH x))` assume_tac
  \\ rpt_drule state_rel_get_var_Number_IMP \\ strip_tac \\ fs []
  \\ fs [adjust_var_def] \\ fs [wordSemTheory.get_var_def]
  \\ qpat_assum `get_var 1 s0.locals = SOME v2` assume_tac
  \\ fs [lookup_insert]
  \\ `~(2 ≥ dimindex (:α)) /\ ~(4 ≥ dimindex (:α))` by
       (fs [state_rel_def,labPropsTheory.good_dimindex_def] \\ NO_TAC)
  \\ fs [lookup_insert]
  \\ assume_tac (GEN_ALL Make_ptr_bits_thm)
  \\ SEP_I_TAC "evaluate"
  \\ fs [wordSemTheory.set_var_def,lookup_insert] \\ rfs []
  \\ pop_assum (qspecl_then [`tag`,`LENGTH x`] mp_tac)
  \\ match_mp_tac (METIS_PROVE [] ``a /\ (a /\ b ==> c) ==> ((a ==> b) ==> c)``)
  \\ `16 * tag < dimword (:'a) /\ 4 * LENGTH x < dimword (:'a)` by
   (fs [encode_header_def,X_LT_DIV,small_int_def] \\ NO_TAC)
  \\ conj_tac THEN1
   (fs [Smallnum_def,shift_length_def]
    \\ rewrite_tac [GSYM w2n_11,w2n_lsr]
    \\ fs [ONCE_REWRITE_RULE [MULT_COMM] MULT_DIV]
    \\ fs [state_rel_def,heap_in_memory_store_def,shift_length_def])
  \\ strip_tac \\ fs []
  \\ `w2n w = 4 * LENGTH x` by
   (qpat_assum `state_rel c l1 l2 s t [] locs` assume_tac
    \\ rpt_drule state_rel_get_var_Number_IMP
    \\ fs [adjust_var_def,wordSemTheory.get_var_def,Smallnum_def] \\ NO_TAC)
  \\ fs [state_rel_thm,get_var_def]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
  \\ rpt_drule memory_rel_lookup \\ fs [adjust_var_def]
  \\ qabbrev_tac `hd = (Smallnum (&(4 * tag)) || (3w:'a word) ||
                       (Smallnum (&LENGTH x) << (dimindex (:α) − c.len_size - 2)))`
  \\ fs [list_Seq_def]
  \\ strip_tac \\ fs [LENGTH_NIL]
  \\ assume_tac (GEN_ALL FromList1_code_thm)
  \\ SEP_I_TAC "evaluate"
  \\ pop_assum mp_tac
  \\ fs [wordSemTheory.set_var_def,wordSemTheory.get_var_def,lookup_insert]
  \\ `lookup FromList1_location s1.code = SOME (6,FromList1_code c)` by
       (fs [code_rel_def,stubs_def] \\ NO_TAC)
  \\ disch_then drule
  \\ `encode_header c (4 * tag) (LENGTH x) = SOME hd` by
   (fs [encode_header_def] \\ conj_tac THEN1
     (fs [encode_header_def,dimword_def,labPropsTheory.good_dimindex_def]
      \\ rfs [] \\ conj_tac \\ fs [] \\ rfs [DIV_LT_X]
      \\ fs [ONCE_REWRITE_RULE [MULT_COMM] MULT_DIV])
    \\ fs [make_header_def,Abbr`hd`]
    \\ fs [WORD_MUL_LSL,word_mul_n2w,Smallnum_def,EXP_LEMMA1]
    \\ rpt (AP_TERM_TAC ORELSE AP_THM_TAC)
    \\ fs [memory_rel_def,heap_in_memory_store_def]
    \\ fs [labPropsTheory.good_dimindex_def] \\ rfs [])
  \\ rpt_drule memory_rel_FromList
  \\ impl_tac THEN1
    (fs [Abbr `s0`,ONCE_REWRITE_RULE [MULT_COMM] MULT_DIV])
  \\ strip_tac
  \\ disch_then drule
  \\ impl_tac THEN1
   (fs [Abbr `s0`,ONCE_REWRITE_RULE [MULT_COMM] MULT_DIV]
    \\ fs [Smallnum_def,dimword_def,labPropsTheory.good_dimindex_def] \\ rfs [])
  \\ strip_tac \\ fs [lookup_def,EVAL ``join_env LN []``]
  \\ fs [Abbr`s0`]
  \\ fs [FAPPLY_FUPDATE_THM]
  \\ drule memory_rel_zero_space
  \\ match_mp_tac memory_rel_rearrange
  \\ fs [] \\ rw [] \\ fs []);

val MAP_FST_EQ_IMP_IS_SOME_ALOOKUP = Q.store_thm("MAP_FST_EQ_IMP_IS_SOME_ALOOKUP",
  `!xs ys.
      MAP FST xs = MAP FST ys ==>
      IS_SOME (ALOOKUP xs n) = IS_SOME (ALOOKUP ys n)`,
  Induct \\ fs [] \\ Cases \\ Cases_on `ys` \\ fs []
  \\ Cases_on `h` \\ fs [] \\ rw []);

val cut_env_adjust_set_insert_1 = Q.store_thm("cut_env_adjust_set_insert_1",
  `cut_env (adjust_set x) (insert 1 w l) =
    cut_env (adjust_set x) l`,
  fs [wordSemTheory.cut_env_def] \\ rw []
  \\ fs [lookup_inter_alt,lookup_insert]
  \\ rw [] \\ fs [SUBSET_DEF]
  \\ res_tac \\ fs [NOT_1_domain]);

val state_rel_IMP_Number_arg = Q.store_thm("state_rel_IMP_Number_arg",
  `state_rel c l1 l2 (call_env xs s) (call_env ys t) [] locs /\
    n < dimword (:'a) DIV 16 /\ LENGTH ys = LENGTH xs + 1 ==>
    state_rel c l1 l2
      (call_env (xs ++ [Number (& n)]) s)
      (call_env (ys ++ [Word (n2w (4 * n):'a word)]) t) [] locs`,
  fs [state_rel_thm,call_env_def,wordSemTheory.call_env_def] \\ rw []
  THEN1 (Cases_on `ys` \\ fs [lookup_fromList,lookup_fromList2])
  THEN1
   (fs [lookup_fromList,lookup_fromList2,EVEN_adjust_var]
    \\ POP_ASSUM MP_TAC \\ IF_CASES_TAC \\ fs []
    \\ rw [] \\ fs []
    \\ fs [adjust_var_def,adjust_var_DIV_2_ANY])
  \\ fs [fromList2_SNOC,fromList_SNOC,GSYM SNOC_APPEND]
  \\ fs [LEFT_ADD_DISTRIB,GSYM adjust_var_def]
  \\ full_simp_tac std_ss [SNOC_APPEND,GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert
  \\ simp_tac std_ss [APPEND]
  \\ `n2w (4 * n) = Smallnum (&n)` by
     (fs [labPropsTheory.good_dimindex_def,dimword_def,Smallnum_def] \\ NO_TAC)
  \\ fs [] \\ match_mp_tac IMP_memory_rel_Number
  \\ full_simp_tac std_ss [SNOC_APPEND,GSYM APPEND_ASSOC,APPEND]
  \\ fs [small_int_def,labPropsTheory.good_dimindex_def]
  \\ rfs [dimword_def]);

val get_var_get_real_addr_lemma =
    GEN_ALL(CONV_RULE(LAND_CONV(move_conj_left(
                                   same_const``wordSem$get_var`` o #1 o
                                   strip_comb o lhs)))
                     get_real_addr_lemma)

val evaluate_LoadWord64 = Q.store_thm("evaluate_LoadWord64",
  `memory_rel c be refs sp t.store t.memory t.mdomain ((Word64 w,v)::vars) ∧
   shift_length c < dimindex(:α) ∧ dimindex(:α) = 64 ∧
   get_var src (t:('a,'ffi) state) = SOME v
   ==>
   evaluate (LoadWord64 c dest src,t) = (NONE, set_var dest (Word (w2w w)) t)`,
  rw[LoadWord64_def] \\ eval_tac
  \\ rpt_drule memory_rel_Word64_IMP
  \\ impl_keep_tac >- fs[good_dimindex_def]
  \\ strip_tac \\ rfs[] \\ clean_tac
  \\ rpt_drule get_var_get_real_addr_lemma
  \\ simp[] \\ disch_then drule
  \\ simp[] \\ rw[]
  \\ rpt(AP_TERM_TAC ORELSE AP_THM_TAC)
  \\ simp[FUN_EQ_THM]
  \\ rw[WORD_w2w_EXTRACT]);

val join_env_locals_def = Define`
  join_env_locals sl tl =
    join_env sl (toAList (inter tl (adjust_set sl)))`;

val join_env_locals_insert_odd = Q.store_thm("join_env_locals_insert_odd[simp]",
  `ODD n ⇒ join_env_locals sl (insert n v ls) = join_env_locals sl ls`,
  rw[join_env_locals_def,inter_insert_ODD_adjust_set_alt]);

val join_env_locals_insert_dest_odd = Q.store_thm("join_env_locals_insert_dest_odd[simp]",
  `ODD n ⇒ join_env_locals sl (insert (adjust_var dest) w (insert n v ls)) = join_env_locals sl (insert (adjust_var dest) w ls)`,
  rw[join_env_locals_def,inter_insert_ODD_adjust_set]);

val evaluate_WriteWord64 = Q.store_thm("evaluate_WriteWord64",
  `memory_rel c be refs sp t.store t.memory t.mdomain
     (join_env_locals sl t.locals ++ vars) ∧
   get_var src (t:('a,'ffi) state) = SOME (Word w) ∧
   shift_length c < dimindex(:α) ∧
   src ≠ 1 ∧ 1 < sp ∧
   dimindex(:α) = 64 ∧
   encode_header c 3 1 = SOME header ∧
   (∀n. IS_SOME (lookup n sl) ⇒ IS_SOME (lookup (adjust_var n) t.locals))
   ==>
   ∃nf m' locals' v.
     evaluate (WriteWord64 c header dest src,t) =
       (NONE, t with <| store := t.store |+ (NextFree, nf);
                        memory := m'; locals := locals'|>) ∧
     memory_rel c be refs (sp-2) (t.store |+ (NextFree, nf)) m' t.mdomain
       (join_env_locals (insert dest (Word64 (w2w w)) sl) locals' ++ vars) ∧
     (∀n. IS_SOME (lookup n sl) ⇒ IS_SOME (lookup (adjust_var n) locals')) ∧
     IS_SOME (lookup (adjust_var dest) locals') ∧
     lookup 0 locals' = lookup 0 t.locals`,
  rw[WriteWord64_def,list_Seq_def,join_env_locals_def]
  \\ drule(GEN_ALL(memory_rel_Word64_alt |> Q.GEN`vs` |> Q.SPEC`[]` |> SIMP_RULE (srw_ss())[]))
  \\ disch_then(qspecl_then[`[Word w]`,`w2w w`]mp_tac)
  \\ simp[]
  \\ impl_tac >- (
    simp[good_dimindex_def] \\ EVAL_TAC \\ simp[WORD_w2w_EXTRACT]
    \\ srw_tac[wordsLib.WORD_BIT_EQ_ss][] )
  \\ strip_tac
  \\ eval_tac
  \\ fs[wordSemTheory.get_var_def,
        wordSemTheory.mem_store_def,
        lookup_insert,
        wordSemTheory.set_store_def,
        FLOOKUP_UPDATE,
        store_list_def]
  \\ simp[wordSemTheory.state_component_equality,lookup_insert]
  \\ qmatch_goalsub_abbrev_tac`(NextFree,next_free)`
  \\ qexists_tac`next_free` \\ simp[]
  \\ reverse conj_tac
  >- ( rw[] \\ fs[FLOOKUP_DEF,EXTENSION] \\ metis_tac[] )
  \\ full_simp_tac std_ss [APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert
  \\ fs[inter_insert_ODD_adjust_set_alt]
  \\ rw[] \\ fs[make_ptr_def]
  \\ qmatch_abbrev_tac`memory_rel c be refs sp' st' m' md vars'`
  \\ qmatch_assum_abbrev_tac`memory_rel c be refs sp' st' m'' md vars'`
  \\ `m' = m''` suffices_by simp[]
  \\ simp[Abbr`m'`,Abbr`m''`,FUN_EQ_THM,APPLY_UPDATE_THM]
  \\ rw[] \\ fs[]
  \\ fs [addressTheory.WORD_EQ_ADD_CANCEL]
  \\ pop_assum mp_tac \\ EVAL_TAC
  \\ fs [dimword_def]);

val evaluate_WriteWord64_on_32 = Q.store_thm("evaluate_WriteWord64_on_32",
  `memory_rel c be refs sp t.store t.memory t.mdomain
     (join_env_locals sl t.locals ++ vars) ∧
   get_var src1 (t:('a,'ffi) state) = SOME (Word ((31 >< 0) w)) ∧
   get_var src2 (t:('a,'ffi) state) = SOME (Word ((63 >< 32) w)) ∧
   shift_length c < dimindex(:α) ∧
   src1 ≠ 1 ∧ src2 ≠ 1 ∧ 2 < sp ∧
   dimindex(:α) = 32 ∧
   encode_header c 3 2 = SOME header ∧
   (∀n. IS_SOME (lookup n sl) ⇒ IS_SOME (lookup (adjust_var n) t.locals))
   ==>
   ∃nf m' locals' v.
     evaluate (WriteWord64_on_32 c header dest src1 src2,t) =
       (NONE, t with <| store := t.store |+ (NextFree, nf);
                        memory := m'; locals := locals'|>) ∧
     memory_rel c be refs (sp-3) (t.store |+ (NextFree, nf)) m' t.mdomain
       (join_env_locals (insert dest (Word64 w) sl) locals' ++ vars) ∧
     (∀n. IS_SOME (lookup n sl) ⇒ IS_SOME (lookup (adjust_var n) locals')) ∧
     IS_SOME (lookup (adjust_var dest) locals') ∧
     lookup 0 locals' = lookup 0 t.locals`,
  qpat_abbrev_tac `w1 = ((31 >< 0) w):'a word`
  \\ qpat_abbrev_tac `w2 = ((63 >< 32) w):'a word`
  \\ rw[WriteWord64_on_32_def,list_Seq_def,join_env_locals_def]
  \\ drule(GEN_ALL(memory_rel_Word64_alt |> Q.GEN`vs` |> Q.SPEC`[]` |> SIMP_RULE (srw_ss())[]))
  \\ disch_then(qspecl_then[`[Word w2;Word w1]`,`w`]mp_tac)
  \\ asm_rewrite_tac[Word64Rep_def]
  \\ simp_tac (srw_ss()) []
  \\ disch_then (qspec_then `header` mp_tac)
  \\ impl_tac >- (
    unabbrev_all_tac \\ fs []
    \\ simp[good_dimindex_def] \\ EVAL_TAC \\ simp[WORD_w2w_EXTRACT]
    \\ srw_tac[wordsLib.WORD_BIT_EQ_ss][])
  \\ strip_tac
  \\ eval_tac
  \\ fs[wordSemTheory.get_var_def,
        wordSemTheory.mem_store_def,
        lookup_insert,
        wordSemTheory.set_store_def,
        FLOOKUP_UPDATE,
        store_list_def]
  \\ simp[wordSemTheory.state_component_equality,lookup_insert]
  \\ qmatch_goalsub_abbrev_tac`(NextFree,next_free)`
  \\ qexists_tac`next_free` \\ simp[]
  \\ reverse conj_tac
  >- ( rw[] \\ fs[FLOOKUP_DEF,EXTENSION] \\ metis_tac[] )
  \\ rveq \\ fs []
  \\ full_simp_tac std_ss [APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert
  \\ fs[inter_insert_ODD_adjust_set_alt]
  \\ rw[] \\ fs[make_ptr_def]
  \\ qmatch_abbrev_tac`memory_rel c be refs sp' st' m' md vars'`
  \\ qmatch_assum_abbrev_tac`memory_rel c be refs sp' st' m'' md vars'`
  \\ `m' = m''` suffices_by simp[]
  \\ simp[Abbr`m'`,Abbr`m''`,FUN_EQ_THM,APPLY_UPDATE_THM]
  \\ rw[] \\ fs[]
  \\ fs [addressTheory.WORD_EQ_ADD_CANCEL]
  \\ pop_assum mp_tac \\ EVAL_TAC \\ fs [dimword_def]
  \\ pop_assum mp_tac \\ EVAL_TAC \\ fs [dimword_def]);

val evaluate_WriteWord64_bignum = Q.store_thm("evaluate_WriteWord64_bignum",
  `memory_rel c be refs sp t.store t.memory t.mdomain
     (join_env_locals sl t.locals ++ vars) ∧
   get_var src (t:('a,'ffi) state) = SOME (Word w) ∧
   shift_length c < dimindex(:α) ∧
   src ≠ 1 ∧ 1 < sp ∧
   dimindex(:α) = 64 ∧
   encode_header c 3 1 = SOME header ∧
   ¬small_int (:α) (&w2n w) ∧
   (∀n. IS_SOME (lookup n sl) ⇒ IS_SOME (lookup (adjust_var n) t.locals))
   ==>
   ∃nf m' locals' v.
     evaluate (WriteWord64 c header dest src,t) = (NONE, t with
       <| store := t.store |+ (NextFree, nf); memory := m'; locals := locals'|>) ∧
     memory_rel c be refs (sp-2) (t.store |+ (NextFree, nf)) m' t.mdomain
       (join_env_locals (insert dest (Number (&w2n w)) sl) locals' ++ vars) ∧
     (∀n. IS_SOME (lookup n sl) ⇒ IS_SOME (lookup (adjust_var n) locals')) ∧
     IS_SOME (lookup (adjust_var dest) locals') ∧
     lookup 0 locals' = lookup 0 t.locals`,
  rw[WriteWord64_def,list_Seq_def,join_env_locals_def]
  \\ drule(GEN_ALL(IMP_memory_rel_bignum_alt))
  \\ disch_then(qspecl_then[`[w]`,`F`,`&w2n w`,`header`]mp_tac)
  \\ simp[]
  \\ impl_tac >- (
    simp[good_dimindex_def]
    \\ conj_tac
    >- (
      rw[Bignum_def]
      \\ fs[multiwordTheory.i2mw_def]
      \\ simp[n2mw_w2n]
      \\ IF_CASES_TAC \\ fs[]
      \\ fs[small_int_def]
      \\ rfs[dimword_def] )
    \\ CONV_TAC(PATH_CONV"lrlr"EVAL)
    \\ simp[dimword_def])
  \\ strip_tac
  \\ eval_tac
  \\ fs[wordSemTheory.get_var_def,
        wordSemTheory.mem_store_def,
        lookup_insert,
        wordSemTheory.set_store_def,
        FLOOKUP_UPDATE,
        store_list_def]
  \\ simp[wordSemTheory.state_component_equality,lookup_insert]
  \\ qmatch_goalsub_abbrev_tac`(NextFree,next_free)`
  \\ qexists_tac`next_free` \\ simp[]
  \\ reverse conj_tac
  >- ( rw[] \\ fs[FLOOKUP_DEF,EXTENSION] \\ metis_tac[] )
  \\ full_simp_tac std_ss [APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert
  \\ fs[inter_insert_ODD_adjust_set_alt]
  \\ rw[] \\ fs[make_ptr_def]
  \\ qmatch_abbrev_tac`memory_rel c be refs sp' st' m' md vars'`
  \\ qmatch_assum_abbrev_tac`memory_rel c be refs sp' st' m'' md vars'`
  \\ `m' = m''` suffices_by simp[]
  \\ simp[Abbr`m'`,Abbr`m''`,FUN_EQ_THM,APPLY_UPDATE_THM]
  \\ rw[] \\ fs[]
  \\ fs [addressTheory.WORD_EQ_ADD_CANCEL]
  \\ pop_assum mp_tac \\ EVAL_TAC
  \\ fs [dimword_def]);

val evaluate_LoadBignum = Q.store_thm("evaluate_LoadBignum",
  `memory_rel c be refs sp t.store t.memory t.mdomain ((Number i,v)::vars) ∧
   ¬small_int (:α) i ∧ good_dimindex (:α) ∧ shift_length c < dimindex (:α) ∧
   get_var src (t:(α,'ffi) state) = SOME v ∧ header ≠ w1
   ⇒
   ∃h junk.
   evaluate (LoadBignum c header w1 src,t) =
     (NONE, set_vars [w1;header;w1]
                     [Word (n2w (Num (ABS i)));(Word h);junk] t) ∧
   ((16w && h) = 0w ⇔ 0 ≤ i)`,
  rw[LoadBignum_def,list_Seq_def] \\ eval_tac
  \\ rpt_drule memory_rel_Number_bignum_IMP
  \\ strip_tac \\ rfs[] \\ clean_tac
  \\ rpt_drule get_var_get_real_addr_lemma
  \\ simp[lookup_insert]
  \\ simp[wordSemTheory.set_vars_def,wordSemTheory.state_component_equality,alist_insert_def]
  \\ rw[] \\ metis_tac[]);

val assign_thm_goal =
  ``state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs /\
   (op_requires_names op ==> names_opt <> NONE) /\
   cut_state_opt names_opt s = SOME x /\
   get_vars args x.locals = SOME vals /\
   t.termdep > 1 /\
   do_app op vals x = Rval (v,s2) ==>
   ?q r.
     evaluate (FST (assign c n l dest op args names_opt),t) = (q,r) /\
     (q = SOME NotEnoughSpace ==> r.ffi = t.ffi) /\
     (q <> SOME NotEnoughSpace ==>
     state_rel c l1 l2 (set_var dest v s2) r [] locs /\ q = NONE)``;

val evaluate_Assign =
  SIMP_CONV(srw_ss())[wordSemTheory.evaluate_def]``evaluate (Assign _ _, _)``

val th = Q.store_thm("assign_WordToInt",
  `op = WordToInt ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH
  \\ fs[do_app]
  \\ every_case_tac \\ fs[]
  \\ clean_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs[LENGTH_EQ_NUM_compute] \\ clean_tac
  \\ fs[state_rel_thm] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac
  \\ fs[wordSemTheory.get_vars_def]
  \\ every_case_tac \\ fs[] \\ clean_tac
  \\ simp[assign_def]
  \\ reverse BasicProvers.TOP_CASE_TAC >- simp[]
  \\ BasicProvers.TOP_CASE_TAC >- simp[]
  \\ simp[list_Seq_def]
  \\ simp[Once wordSemTheory.evaluate_def]
  \\ rpt_drule evaluate_LoadWord64 \\ fs[]
  \\ disch_then kall_tac
  \\ simp[Once wordSemTheory.evaluate_def]
  \\ simp[evaluate_Assign,word_exp_rw,wordSemTheory.set_var_def]
  \\ simp[Once wordSemTheory.evaluate_def]
  \\ simp[evaluate_Assign,word_exp_rw,wordSemTheory.set_var_def]
  \\ simp[Once wordSemTheory.evaluate_def]
  \\ simp[wordSemTheory.get_var_def,lookup_insert,wordSemTheory.get_var_imm_def]
  \\ simp[asmTheory.word_cmp_def]
  \\ IF_CASES_TAC
  >- (
    simp[Once wordSemTheory.evaluate_def,lookup_insert]
    \\ fs[consume_space_def]
    \\ clean_tac \\ fs[]
    \\ conj_tac >- rw[]
    \\ simp[inter_insert_ODD_adjust_set]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert
    \\ qmatch_goalsub_abbrev_tac`Number i,Word sn`
    \\ `sn = Smallnum i ∧ small_int (:α) i` suffices_by (
      rw[]
      \\ match_mp_tac IMP_memory_rel_Number
      \\ simp[]
      \\ match_mp_tac (GEN_ALL memory_rel_less_space)
      \\ qexists_tac`x.space` \\ fs[] )
    \\ simp[Abbr`sn`,Abbr`i`]
    \\ reverse conj_tac
    >- (`c' >>> 61 = 0w`
        by (qpat_x_assum `w2w c' >>> 61 = 0w` mp_tac
            \\ srw_tac[wordsLib.WORD_BIT_EQ_ss][])
        \\ simp[small_int_def,wordsTheory.dimword_def]
        \\ wordsLib.n2w_INTRO_TAC 64
        \\ qpat_x_assum `c' >>> 61 = 0w` mp_tac
        \\ blastLib.BBLAST_TAC)
    \\ simp_tac(std_ss++wordsLib.WORD_MUL_LSL_ss)
         [Smallnum_i2w,GSYM integerTheory.INT_MUL,
          integer_wordTheory.i2w_w2n_w2w,GSYM integer_wordTheory.word_i2w_mul,
          EVAL ``i2w 4 : 'a word``])
  \\ assume_tac (GEN_ALL evaluate_WriteWord64_bignum)
  \\ SEP_I_TAC "evaluate" \\ fs[]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,GSYM join_env_locals_def]
  \\ first_x_assum drule
  \\ simp[wordSemTheory.get_var_def,lookup_insert]
  \\ fs[consume_space_def]
  \\ impl_tac
  >- (
    pop_assum mp_tac
    \\ fs[small_int_def]
    \\ simp[dimword_def]
    \\ simp[w2n_w2w]
    \\ qmatch_goalsub_rename_tac`w2n w`
    \\ srw_tac[wordsLib.WORD_BIT_EQ_ss][]
    \\ Cases_on`w` \\ fs[]
    \\ rfs[word_index]
    \\ imp_res_tac bitTheory.BIT_IMP_GE_TWOEXP
    \\ fs[])
  \\ strip_tac \\ fs[]
  \\ clean_tac \\ fs[]
  \\ conj_tac >- rw[]
  \\ fs[FAPPLY_FUPDATE_THM]
  \\ match_mp_tac (GEN_ALL memory_rel_less_space)
  \\ qexists_tac`x.space - 2` \\ fs[]
  \\ qmatch_goalsub_abbrev_tac`Number w1`
  \\ qmatch_asmsub_abbrev_tac`Number w2`
  \\ `w1 = w2` suffices_by simp[]
  \\ simp[Abbr`w1`,Abbr`w2`]
  \\ simp[w2n_w2w]);

val MustTerminate_limit_NOT_0 = Q.store_thm("MustTerminate_limit_NOT_0[simp]",
  `MustTerminate_limit (:'a) <> 0`,
  rewrite_tac [wordSemTheory.MustTerminate_limit_def] \\ fs [dimword_def]);

val th = Q.store_thm("assign_FromList",
  `(?tag. op = FromList tag) ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP
  \\ fs [assign_def] \\ rveq
  \\ fs [bvi_to_dataTheory.op_requires_names_def,
         bvi_to_dataTheory.op_space_reset_def,cut_state_opt_def]
  \\ Cases_on `names_opt` \\ fs []
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [do_app]
  \\ `?v vs. vals = [Number (&LENGTH vs); v] /\ v_to_list v = SOME vs` by
         (every_case_tac \\ fs [] \\ rw [] \\ NO_TAC)
  \\ clean_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_2] \\ clean_tac
  \\ clean_tac
  \\ drule lookup_RefByte_location \\ fs [get_names_def]
  \\ fs [wordSemTheory.evaluate_def,list_Seq_def,word_exp_rw,
         wordSemTheory.find_code_def,wordSemTheory.set_var_def]
  \\ fs [wordSemTheory.add_ret_loc_def,wordSemTheory.find_code_def]
  \\ fs [wordSemTheory.bad_dest_args_def,wordSemTheory.get_vars_def,
         wordSemTheory.get_var_def,lookup_insert]
  \\ disch_then kall_tac
  \\ fs [cut_state_opt_def,cut_state_def]
  \\ rename1 `state_rel c l1 l2 s1 t [] locs`
  \\ Cases_on `dataSem$cut_env x' s.locals` \\ fs []
  \\ clean_tac \\ fs []
  \\ qabbrev_tac `s1 = s with locals := x`
  \\ `?y. cut_env (adjust_set x') t.locals = SOME y` by
       (match_mp_tac (GEN_ALL cut_env_IMP_cut_env) \\ fs []
        \\ metis_tac []) \\ fs []
  \\ Cases_on `lookup (adjust_var a1) t.locals` \\ fs []
  \\ Cases_on `lookup (adjust_var a2) t.locals` \\ fs []
  \\ fs[cut_env_adjust_set_insert_1]
  \\ `dimword (:α) <> 0` by (assume_tac ZERO_LT_dimword \\ decide_tac)
  \\ fs [wordSemTheory.dec_clock_def,EVAL ``(data_to_bvi s).refs``]
  \\ Q.MATCH_GOALSUB_ABBREV_TAC `evaluate (FromList_code _,t4)`
  \\ rveq
  \\ `state_rel c l1 l2 (s1 with clock := MustTerminate_limit(:'a))
        (t with <| clock := MustTerminate_limit(:'a); termdep := t.termdep - 1 |>)
          [] locs` by (fs [state_rel_def] \\ asm_exists_tac \\ fs [] \\ NO_TAC)
  \\ rpt_drule state_rel_call_env_push_env \\ fs []
  \\ `dataSem$get_vars [a1; a2] s.locals = SOME [Number (&LENGTH vs); v']` by
    (fs [dataSemTheory.get_vars_def] \\ every_case_tac \\ fs [cut_env_def]
     \\ clean_tac \\ fs [lookup_inter_alt,get_var_def] \\ NO_TAC)
  \\ `s1.locals = x` by (unabbrev_all_tac \\ fs []) \\ fs []
  \\ disch_then drule \\ fs []
  \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def]
  \\ `dataSem$cut_env x' s1.locals = SOME s1.locals` by
   (unabbrev_all_tac \\ fs []
    \\ fs [cut_env_def] \\ clean_tac
    \\ fs [domain_inter] \\ fs [lookup_inter_alt] \\ NO_TAC)
  \\ fs [] \\ rfs []
  \\ disch_then drule \\ fs []
  \\ disch_then (qspecl_then [`n`,`l`,`NONE`] mp_tac) \\ fs []
  \\ strip_tac
  \\ `4 * tag < dimword (:'a) DIV 16` by (fs [encode_header_def] \\ NO_TAC)
  \\ rpt_drule state_rel_IMP_Number_arg
  \\ strip_tac
  \\ rpt_drule FromList_thm
  \\ simp [Once call_env_def,wordSemTheory.dec_clock_def,do_app_def,
           get_vars_def,get_var_def,lookup_insert,fromList_def,
           do_space_def,bvi_to_dataTheory.op_space_reset_def,
           bviSemTheory.do_app_def,do_app,call_env_def]
  \\ disch_then (qspecl_then [`l2`,`l1`] strip_assume_tac)
  \\ qmatch_assum_abbrev_tac
       `evaluate (FromList_code c,t5) = _`
  \\ `t5 = t4` by
   (unabbrev_all_tac \\ fs [wordSemTheory.call_env_def,
       wordSemTheory.push_env_def] \\ pairarg_tac \\ fs [] \\ NO_TAC)
  \\ fs [] \\ Cases_on `q = SOME NotEnoughSpace` THEN1 fs [] \\ fs []
  \\ rpt_drule state_rel_pop_env_IMP
  \\ simp [push_env_def,call_env_def,pop_env_def,dataSemTheory.dec_clock_def,
       Once dataSemTheory.bvi_to_data_def]
  \\ strip_tac \\ fs [] \\ clean_tac
  \\ `domain t2.locals = domain y` by
   (qspecl_then [`FromList_code c`,`t4`] mp_tac
         (wordPropsTheory.evaluate_stack_swap
            |> INST_TYPE [``:'b``|->``:'ffi``])
    \\ fs [] \\ fs [wordSemTheory.pop_env_def]
    \\ Cases_on `r'.stack` \\ fs [] \\ Cases_on `h` \\ fs []
    \\ rename1 `r2.stack = StackFrame ns opt::t'`
    \\ unabbrev_all_tac
    \\ fs [wordSemTheory.call_env_def,wordSemTheory.push_env_def]
    \\ pairarg_tac \\ Cases_on `opt`
    \\ fs [wordPropsTheory.s_key_eq_def,
          wordPropsTheory.s_frame_key_eq_def]
    \\ rw [] \\ drule env_to_list_lookup_equiv
    \\ fs [EXTENSION,domain_lookup,lookup_fromAList]
    \\ fs[GSYM IS_SOME_EXISTS]
    \\ imp_res_tac MAP_FST_EQ_IMP_IS_SOME_ALOOKUP \\ metis_tac []) \\ fs []
  \\ pop_assum mp_tac
  \\ pop_assum mp_tac
  \\ simp [state_rel_def]
  \\ fs [bviSemTheory.bvl_to_bvi_def,
         bviSemTheory.bvi_to_bvl_def,
         dataSemTheory.bvi_to_data_def,
         dataSemTheory.call_env_def,
         dataSemTheory.data_to_bvi_def,push_env_def,
         dataSemTheory.set_var_def,wordSemTheory.set_var_def]
  \\ fs [wordSemTheory.pop_env_def]
  \\ `t.clock = s.clock` by fs [state_rel_def] \\ fs []
  \\ unabbrev_all_tac \\ fs []
  \\ rpt (disch_then strip_assume_tac) \\ clean_tac \\ fs []
  \\ strip_tac THEN1
   (fs [lookup_insert,stack_rel_def,state_rel_def,contains_loc_def,
        wordSemTheory.pop_env_def] \\ rfs[] \\ clean_tac
    \\ every_case_tac \\ fs [] \\ clean_tac \\ fs [lookup_fromAList]
    \\ fs [wordSemTheory.push_env_def]
    \\ pairarg_tac \\ fs []
    \\ drule env_to_list_lookup_equiv
    \\ fs[contains_loc_def])
  \\ conj_tac THEN1 (fs [lookup_insert,adjust_var_11] \\ rw [])
  \\ asm_exists_tac \\ fs []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac word_ml_inv_insert \\ fs [flat_def]
  \\ first_x_assum (fn th => mp_tac th \\ match_mp_tac word_ml_inv_rearrange)
  \\ fs[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]);

val th = Q.store_thm("assign_RefByte",
  `(?fl. op = RefByte fl) ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP
  \\ fs [assign_def] \\ rveq
  \\ fs [bvi_to_dataTheory.op_requires_names_def,
         bvi_to_dataTheory.op_space_reset_def,cut_state_opt_def]
  \\ Cases_on `names_opt` \\ fs []
  \\ qmatch_goalsub_abbrev_tac`Const tag`
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [do_app]
  \\ `?i b. vals = [Number i; Number b]` by (every_case_tac \\ fs [] \\ NO_TAC)
  \\ clean_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_2] \\ clean_tac
  \\ Cases_on `0 <= i` \\ fs []
  \\ qpat_assum `_ = Rval (v,s2)` mp_tac
  \\ reverse IF_CASES_TAC \\ fs []
  \\ clean_tac \\ fs [wordSemTheory.evaluate_def]
  \\ simp[word_exp_rw,wordSemTheory.set_var_def]
  \\ fs [wordSemTheory.bad_dest_args_def]
  \\ fs [wordSemTheory.add_ret_loc_def,wordSemTheory.find_code_def]
  \\ drule lookup_RefByte_location \\ fs [get_names_def]
  \\ disch_then kall_tac
  \\ fs[get_vars_SOME_IFF]
  \\ simp[wordSemTheory.get_vars_def]
  \\ fs[wordSemTheory.get_var_def,lookup_insert]
  \\ fs [cut_state_opt_def,cut_state_def]
  \\ rename1 `state_rel c l1 l2 s1 t [] locs`
  \\ Cases_on `dataSem$cut_env x' s.locals` \\ fs []
  \\ clean_tac \\ fs []
  \\ qabbrev_tac `s1 = s with locals := x`
  \\ `?y. cut_env (adjust_set x') t.locals = SOME y` by
       (match_mp_tac (GEN_ALL cut_env_IMP_cut_env) \\ fs []
        \\ metis_tac []) \\ fs []
  \\ simp[cut_env_adjust_set_insert_1]
  \\ `dimword (:α) <> 0` by (assume_tac ZERO_LT_dimword \\ decide_tac)
  \\ fs [wordSemTheory.dec_clock_def,EVAL ``(data_to_bvi s).refs``]
  \\ qmatch_goalsub_abbrev_tac `RefByte_code c,t4`
  \\ rename1 `lookup (adjust_var a1) _ = SOME w1`
  \\ rename1 `lookup (adjust_var a2) _ = SOME w2`
  \\ rename1 `get_vars [a1; a2] x = SOME [Number i; Number (&w2n w)]`
  \\ `state_rel c l1 l2 (s1 with clock := MustTerminate_limit(:'a))
        (t with <| clock := MustTerminate_limit(:'a); termdep := t.termdep - 1 |>)
          [] locs` by (fs [state_rel_def] \\ asm_exists_tac \\ fs [] \\ NO_TAC)
  \\ rpt_drule state_rel_call_env_push_env \\ fs []
  \\ `get_vars [a1; a2] s.locals = SOME [Number i; Number (&w2n w)]` by
    (fs [dataSemTheory.get_vars_def] \\ every_case_tac \\ fs [cut_env_def]
     \\ clean_tac \\ fs [lookup_inter_alt,get_var_def] \\ NO_TAC)
  \\ `s1.locals = x` by (unabbrev_all_tac \\ fs []) \\ fs []
  \\ disch_then drule \\ fs []
  \\ simp[wordSemTheory.get_vars_def,wordSemTheory.get_var_def]
  \\ `dataSem$cut_env x' x = SOME x` by
   (unabbrev_all_tac \\ fs []
    \\ fs [cut_env_def] \\ clean_tac
    \\ fs [domain_inter] \\ fs [lookup_inter_alt])
  \\ disch_then drule \\ fs []
  \\ disch_then (qspecl_then [`n`,`l`,`NONE`] mp_tac) \\ fs []
  \\ strip_tac
  \\ `w2n (tag) DIV 4 < dimword (:'a) DIV 16`
  by (fs[Abbr`tag`,labPropsTheory.good_dimindex_def,state_rel_def] \\ rw[dimword_def] )
  \\ rpt_drule state_rel_IMP_Number_arg \\ strip_tac
  \\ rpt_drule RefByte_thm
  \\ simp [get_vars_def,call_env_def,get_var_def,lookup_fromList]
  \\ `w2n tag DIV 4 = if fl then 0 else 4`
  by (
    fs[Abbr`tag`] \\ rw[]
    \\ fs[state_rel_def,dimword_def,good_dimindex_def] )
  \\ `n2w (4 * if fl then 0 else 4) = tag`
  by (rw[Abbr`tag`] )
  \\ fs [do_app,EVAL ``(data_to_bvi s).refs``]
  \\ fs [EVAL ``get_var 0 (call_env [x1;x2;x3] y)``]
  \\ disch_then (qspecl_then [`l1`,`l2`,`fl`] mp_tac)
  \\ impl_tac THEN1 EVAL_TAC
  \\ qpat_abbrev_tac `t5 = call_env [Loc n l; w1; w2; _] _`
  \\ `t5 = t4` by
   (unabbrev_all_tac \\ fs [wordSemTheory.call_env_def,
       wordSemTheory.push_env_def] \\ pairarg_tac \\ fs []
    \\ fs [wordSemTheory.env_to_list_def,wordSemTheory.dec_clock_def] \\ NO_TAC)
  \\ pop_assum (fn th => fs [th]) \\ strip_tac \\ fs []
  \\ Cases_on `q = SOME NotEnoughSpace` THEN1 fs [] \\ fs []
  \\ rpt_drule state_rel_pop_env_IMP
  \\ simp [push_env_def,call_env_def,pop_env_def,dataSemTheory.dec_clock_def,
       Once dataSemTheory.bvi_to_data_def]
  \\ strip_tac \\ fs [] \\ clean_tac
  \\ `domain t2.locals = domain y` by
   (qspecl_then [`RefByte_code c`,`t4`] mp_tac
         (wordPropsTheory.evaluate_stack_swap
            |> INST_TYPE [``:'b``|->``:'ffi``])
    \\ fs [] \\ fs [wordSemTheory.pop_env_def]
    \\ Cases_on `r'.stack` \\ fs [] \\ Cases_on `h` \\ fs []
    \\ rename1 `r2.stack = StackFrame ns opt::t'`
    \\ unabbrev_all_tac
    \\ fs [wordSemTheory.call_env_def,wordSemTheory.push_env_def]
    \\ pairarg_tac \\ Cases_on `opt`
    \\ fs [wordPropsTheory.s_key_eq_def,
          wordPropsTheory.s_frame_key_eq_def]
    \\ rw [] \\ drule env_to_list_lookup_equiv
    \\ fs [EXTENSION,domain_lookup,lookup_fromAList]
    \\ fs[GSYM IS_SOME_EXISTS]
    \\ imp_res_tac MAP_FST_EQ_IMP_IS_SOME_ALOOKUP \\ metis_tac []) \\ fs []
  \\ pop_assum mp_tac
  \\ pop_assum mp_tac
  \\ simp [state_rel_def]
  \\ fs [bviSemTheory.bvl_to_bvi_def,
         bviSemTheory.bvi_to_bvl_def,
         dataSemTheory.bvi_to_data_def,
         dataSemTheory.call_env_def,
         dataSemTheory.data_to_bvi_def,push_env_def,
         dataSemTheory.set_var_def,wordSemTheory.set_var_def]
  \\ fs [wordSemTheory.pop_env_def]
  \\ `t.clock = s.clock` by fs [state_rel_def] \\ fs []
  \\ unabbrev_all_tac \\ fs []
  \\ rpt (disch_then strip_assume_tac) \\ clean_tac \\ fs []
  \\ strip_tac THEN1
   (fs [lookup_insert,stack_rel_def,state_rel_def,contains_loc_def,
        wordSemTheory.pop_env_def] \\ rfs[] \\ clean_tac
    \\ every_case_tac \\ fs [] \\ clean_tac \\ fs [lookup_fromAList]
    \\ fs [wordSemTheory.push_env_def]
    \\ pairarg_tac \\ fs []
    \\ drule env_to_list_lookup_equiv
    \\ fs[contains_loc_def])
  \\ conj_tac THEN1 (fs [lookup_insert,adjust_var_11] \\ rw [])
  \\ asm_exists_tac \\ fs []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac word_ml_inv_insert \\ fs [flat_def]
  \\ first_x_assum (fn th => mp_tac th \\ match_mp_tac word_ml_inv_rearrange)
  \\ fs[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]);

val th = Q.store_thm("assign_RefArray",
  `op = RefArray ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP
  \\ fs [assign_def] \\ rveq
  \\ fs [bvi_to_dataTheory.op_requires_names_def,
         bvi_to_dataTheory.op_space_reset_def,cut_state_opt_def]
  \\ Cases_on `names_opt` \\ fs []
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [do_app]
  \\ `?i w. vals = [Number i; w]` by (every_case_tac \\ fs [] \\ NO_TAC)
  \\ clean_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_2] \\ clean_tac
  \\ Cases_on `0 <= i` \\ fs []
  \\ clean_tac \\ fs [wordSemTheory.evaluate_def]
  \\ fs [wordSemTheory.bad_dest_args_def]
  \\ fs [wordSemTheory.add_ret_loc_def,wordSemTheory.find_code_def]
  \\ drule lookup_RefByte_location \\ fs [get_names_def]
  \\ disch_then kall_tac
  \\ fs [cut_state_opt_def,cut_state_def]
  \\ rename1 `state_rel c l1 l2 s1 t [] locs`
  \\ Cases_on `dataSem$cut_env x' s.locals` \\ fs []
  \\ clean_tac \\ fs []
  \\ qabbrev_tac `s1 = s with locals := x`
  \\ `?y. cut_env (adjust_set x') t.locals = SOME y` by
       (match_mp_tac (GEN_ALL cut_env_IMP_cut_env) \\ fs []
        \\ metis_tac []) \\ fs []
  \\ `dimword (:α) <> 0` by (assume_tac ZERO_LT_dimword \\ decide_tac)
  \\ fs [wordSemTheory.dec_clock_def,EVAL ``(data_to_bvi s).refs``]
  \\ qpat_abbrev_tac `t4 = wordSem$call_env [Loc n l; _; _] _ with clock := _`
  \\ rename1 `get_vars [adjust_var a1; adjust_var a2] t = SOME [w1;w2]`
  \\ rename1 `get_vars [a1; a2] x = SOME [Number i;v2]`
  \\ `state_rel c l1 l2 (s1 with clock := MustTerminate_limit(:'a))
        (t with <| clock := MustTerminate_limit(:'a); termdep := t.termdep - 1 |>)
          [] locs` by (fs [state_rel_def] \\ asm_exists_tac \\ fs [] \\ NO_TAC)
  \\ rpt_drule state_rel_call_env_push_env \\ fs []
  \\ `get_vars [a1; a2] s.locals = SOME [Number i; v2]` by
    (fs [dataSemTheory.get_vars_def] \\ every_case_tac \\ fs [cut_env_def]
     \\ clean_tac \\ fs [lookup_inter_alt,get_var_def] \\ NO_TAC)
  \\ `s1.locals = x` by (unabbrev_all_tac \\ fs []) \\ fs []
  \\ disch_then drule \\ fs []
  \\ `dataSem$cut_env x' x = SOME x` by
   (unabbrev_all_tac \\ fs []
    \\ fs [cut_env_def] \\ clean_tac
    \\ fs [domain_inter] \\ fs [lookup_inter_alt])
  \\ disch_then drule \\ fs []
  \\ disch_then (qspecl_then [`n`,`l`,`NONE`] mp_tac) \\ fs []
  \\ strip_tac
  \\ rpt_drule RefArray_thm
  \\ simp [get_vars_def,call_env_def,get_var_def,lookup_fromList]
  \\ fs [do_app,EVAL ``(data_to_bvi s).refs``]
  \\ fs [EVAL ``get_var 0 (call_env [x1;x2;x3] y)``]
  \\ disch_then (qspecl_then [`l1`,`l2`] mp_tac)
  \\ impl_tac THEN1 EVAL_TAC
  \\ qpat_abbrev_tac `t5 = call_env [Loc n l; w1; w2] _`
  \\ `t5 = t4` by
   (unabbrev_all_tac \\ fs [wordSemTheory.call_env_def,
       wordSemTheory.push_env_def] \\ pairarg_tac \\ fs []
    \\ fs [wordSemTheory.env_to_list_def,wordSemTheory.dec_clock_def] \\ NO_TAC)
  \\ pop_assum (fn th => fs [th]) \\ strip_tac \\ fs []
  \\ Cases_on `q = SOME NotEnoughSpace` THEN1 fs [] \\ fs []
  \\ rpt_drule state_rel_pop_env_IMP
  \\ simp [push_env_def,call_env_def,pop_env_def,dataSemTheory.dec_clock_def,
       Once dataSemTheory.bvi_to_data_def]
  \\ strip_tac \\ fs [] \\ clean_tac
  \\ `domain t2.locals = domain y` by
   (qspecl_then [`RefArray_code c`,`t4`] mp_tac
         (wordPropsTheory.evaluate_stack_swap
            |> INST_TYPE [``:'b``|->``:'ffi``])
    \\ fs [] \\ fs [wordSemTheory.pop_env_def]
    \\ Cases_on `r'.stack` \\ fs [] \\ Cases_on `h` \\ fs []
    \\ rename1 `r2.stack = StackFrame ns opt::t'`
    \\ unabbrev_all_tac
    \\ fs [wordSemTheory.call_env_def,wordSemTheory.push_env_def]
    \\ pairarg_tac \\ Cases_on `opt`
    \\ fs [wordPropsTheory.s_key_eq_def,
          wordPropsTheory.s_frame_key_eq_def]
    \\ rw [] \\ drule env_to_list_lookup_equiv
    \\ fs [EXTENSION,domain_lookup,lookup_fromAList]
    \\ fs[GSYM IS_SOME_EXISTS]
    \\ imp_res_tac MAP_FST_EQ_IMP_IS_SOME_ALOOKUP \\ metis_tac []) \\ fs []
  \\ pop_assum mp_tac
  \\ pop_assum mp_tac
  \\ simp [state_rel_def]
  \\ fs [bviSemTheory.bvl_to_bvi_def,
         bviSemTheory.bvi_to_bvl_def,
         dataSemTheory.bvi_to_data_def,
         dataSemTheory.call_env_def,
         dataSemTheory.data_to_bvi_def,push_env_def,
         dataSemTheory.set_var_def,wordSemTheory.set_var_def]
  \\ fs [wordSemTheory.pop_env_def]
  \\ `t.clock = s.clock` by fs [state_rel_def] \\ fs []
  \\ unabbrev_all_tac \\ fs []
  \\ rpt (disch_then strip_assume_tac) \\ clean_tac \\ fs []
  \\ strip_tac THEN1
   (fs [lookup_insert,stack_rel_def,state_rel_def,contains_loc_def,
        wordSemTheory.pop_env_def] \\ rfs[] \\ clean_tac
    \\ every_case_tac \\ fs [] \\ clean_tac \\ fs [lookup_fromAList]
    \\ fs [wordSemTheory.push_env_def]
    \\ pairarg_tac \\ fs []
    \\ drule env_to_list_lookup_equiv
    \\ fs[contains_loc_def])
  \\ conj_tac THEN1 (fs [lookup_insert,adjust_var_11] \\ rw [])
  \\ asm_exists_tac \\ fs []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac word_ml_inv_insert \\ fs [flat_def]
  \\ first_x_assum (fn th => mp_tac th \\ match_mp_tac word_ml_inv_rearrange)
  \\ fs[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]);

val th = Q.store_thm("assign_WordFromInt",
  `op = WordFromInt ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH
  \\ fs[do_app]
  \\ every_case_tac \\ fs[]
  \\ clean_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs[LENGTH_EQ_NUM_compute] \\ clean_tac
  \\ fs[state_rel_thm] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac
  \\ fs[wordSemTheory.get_vars_def]
  \\ every_case_tac \\ fs[] \\ clean_tac
  \\ simp[assign_def]
  \\ BasicProvers.TOP_CASE_TAC >- simp[]
  \\ reverse BasicProvers.TOP_CASE_TAC >- simp[]
  \\ simp[Once wordSemTheory.evaluate_def]
  \\ simp[Once wordSemTheory.evaluate_def,wordSemTheory.get_var_imm_def]
  \\ simp[asmTheory.word_cmp_def]
  \\ rpt_drule memory_rel_any_Number_IMP \\ strip_tac
  \\ simp[]
  \\ ONCE_REWRITE_TAC[WORD_AND_COMM]
  \\ simp[word_and_one_eq_0_iff]
  \\ IF_CASES_TAC
  >- (
    simp[Once wordSemTheory.evaluate_def]
    \\ simp[Once wordSemTheory.evaluate_def,wordSemTheory.get_var_imm_def,asmTheory.word_cmp_def]
    \\ simp[Once wordSemTheory.evaluate_def]
    \\ simp[evaluate_Assign]
    \\ simp[word_exp_rw |> CONJUNCTS |> first(can(find_term(same_const``wordLang$Shift``)) o concl)]
    \\ simp[word_exp_rw |> CONJUNCTS |> first(can(find_term(same_const``wordLang$Var``)) o concl)]
    \\ fs[wordSemTheory.get_var_def]
    \\ simp[wordLangTheory.word_sh_def,wordLangTheory.num_exp_def]
    \\ simp[wordSemTheory.set_var_def]
    \\ rpt_drule memory_rel_Number_IMP
    \\ strip_tac \\ clean_tac
    \\ assume_tac (GEN_ALL evaluate_WriteWord64)
    \\ SEP_I_TAC "evaluate" \\ fs[]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,GSYM join_env_locals_def]
    \\ first_x_assum drule
    \\ simp[wordSemTheory.get_var_def]
    \\ fs[consume_space_def]
    \\ rfs[good_dimindex_def] \\ rfs[lookup_insert]
    \\ strip_tac \\ fs[]
    \\ clean_tac \\ fs[]
    \\ conj_tac >- rw[]
    \\ match_mp_tac (GEN_ALL memory_rel_less_space)
    \\ qexists_tac`x.space - 2` \\ simp[]
    \\ fs[FAPPLY_FUPDATE_THM]
    \\ qmatch_asmsub_abbrev_tac`Word64 w1`
    \\ qmatch_goalsub_abbrev_tac`Word64 w2`
    \\ `w1 = w2` suffices_by (rw[] \\ fs[])
    \\ simp[Abbr`w1`,Abbr`w2`]
    \\ `INT_MIN (:'a) <= 4 * i /\ 4 * i <= INT_MAX (:'a)`
    by (rfs [small_int_def,wordsTheory.dimword_def,
             integer_wordTheory.INT_MIN_def,wordsTheory.INT_MAX_def,
             wordsTheory.INT_MIN_def]
        \\ intLib.ARITH_TAC)
    \\ simp[Smallnum_i2w,GSYM integer_wordTheory.i2w_DIV,
            integerTheory.INT_DIV_LMUL,integer_wordTheory.w2w_i2w] )
  \\ simp[Once wordSemTheory.evaluate_def]
  \\ drule (GEN_ALL evaluate_LoadBignum)
  \\ simp[] \\ clean_tac
  \\ disch_then drule
  \\ disch_then(qspecl_then[`3`,`1`]mp_tac)
  \\ simp[] \\ strip_tac
  \\ simp[]
  \\ simp[Once wordSemTheory.evaluate_def,wordSemTheory.set_vars_def,wordSemTheory.get_var_imm_def]
  \\ simp[wordSemTheory.get_var_def,alist_insert_def,lookup_insert,asmTheory.word_cmp_def]
  \\ IF_CASES_TAC
  >- (
    simp[Once wordSemTheory.evaluate_def]
    \\ assume_tac(GEN_ALL evaluate_WriteWord64)
    \\ SEP_I_TAC "evaluate" \\ fs[]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,GSYM join_env_locals_def]
    \\ first_x_assum drule
    \\ simp[wordSemTheory.get_var_def]
    \\ fs[lookup_insert,good_dimindex_def,consume_space_def]
    \\ strip_tac
    \\ clean_tac \\ fs[]
    \\ conj_tac >- rw[]
    \\ match_mp_tac (GEN_ALL memory_rel_less_space)
    \\ qexists_tac`x.space - 2`
    \\ simp[]
    \\ `(i2w i : word64) = n2w (Num i)` by1 (
      rw[integer_wordTheory.i2w_def]
      \\ `F` suffices_by rw[]
      \\ intLib.COOPER_TAC )
    \\ rfs[GSYM integerTheory.INT_ABS_EQ_ID]
    \\ rfs[w2w_n2w]
    \\ simp[FAPPLY_FUPDATE_THM] )
  \\ simp[Once wordSemTheory.evaluate_def]
  \\ simp[word_exp_rw,wordSemTheory.set_var_def]
  \\ assume_tac(GEN_ALL evaluate_WriteWord64)
  \\ SEP_I_TAC "evaluate" \\ fs[]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,GSYM join_env_locals_def]
  \\ first_x_assum drule
  \\ simp[wordSemTheory.get_var_def]
  \\ fs[lookup_insert,good_dimindex_def,consume_space_def]
  \\ strip_tac
  \\ clean_tac \\ fs[]
  \\ conj_tac >- rw[]
  \\ match_mp_tac (GEN_ALL memory_rel_less_space)
  \\ qexists_tac`x.space - 2`
  \\ simp[]
  \\ `(i2w i : word64) = -n2w (Num (-i))` by1 (
    simp_tac std_ss [integer_wordTheory.i2w_def]
    \\ IF_CASES_TAC  \\ simp[]
    \\ `F` suffices_by rw[]
    \\ intLib.COOPER_TAC )
  \\ pop_assum SUBST_ALL_TAC
  \\ `ABS i = -i`
  by (
    simp[integerTheory.INT_ABS]
    \\ rw[]
    \\ intLib.COOPER_TAC )
  \\ pop_assum SUBST_ALL_TAC
  \\ ONCE_REWRITE_TAC[WORD_NEG_MUL]
  \\ rfs[WORD_w2w_OVER_MUL,w2w_n2w]
  \\ qmatch_goalsub_abbrev_tac`insert dest w1`
  \\ qmatch_asmsub_abbrev_tac`insert dest w2`
  \\ `w1 = w2` suffices_by simp[FAPPLY_FUPDATE_THM]
  \\ simp[Abbr`w1`,Abbr`w2`]
  \\ simp[WORD_BITS_EXTRACT]
  \\ match_mp_tac EQ_SYM
  \\ `w2w (-1w:'a word) = (-1w:word64)`
  by1 ( EVAL_TAC \\ simp[w2w_n2w,dimword_def] )
  \\ pop_assum SUBST_ALL_TAC
  \\ simp[Once WORD_MULT_COMM,SimpLHS]
  \\ match_mp_tac WORD_EXTRACT_ID
  \\ qmatch_goalsub_abbrev_tac`w2n ww`
  \\ Q.ISPEC_THEN`ww`mp_tac w2n_lt
  \\ simp[dimword_def]);

val th = Q.store_thm("assign_TagEq",
  `(?tag. op = TagEq tag) ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
  \\ clean_tac \\ fs []
  \\ fs [Boolv_def] \\ rveq
  \\ fs [GSYM Boolv_def] \\ rveq
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_1] \\ clean_tac
  \\ qpat_x_assum `state_rel c l1 l2 x t [] locs` (fn th => NTAC 2 (mp_tac th))
  \\ strip_tac
  \\ simp_tac std_ss [state_rel_thm] \\ strip_tac \\ fs [] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac \\ fs []
  \\ fs [assign_def,list_Seq_def] \\ eval_tac
  \\ reverse IF_CASES_TAC THEN1
   (eval_tac
    \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ rename1 `get_vars [a1] x.locals = SOME [Block n5 l5]`
    \\ `n5 <> tag` by
     (strip_tac \\ clean_tac
      \\ rpt_drule memory_rel_Block_IMP \\ strip_tac \\ fs []
      \\ CCONTR_TAC \\ fs []
      \\ imp_res_tac encode_header_tag_mask \\ NO_TAC)
    \\ fs [] \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs [inter_insert_ODD_adjust_set_alt]
    \\ match_mp_tac memory_rel_Boolv_F \\ fs [])
  \\ imp_res_tac get_vars_1_imp
  \\ eval_tac \\ fs [wordSemTheory.get_var_def,asmTheory.word_cmp_def,
       wordSemTheory.get_var_imm_def,lookup_insert]
  \\ rpt_drule memory_rel_Block_IMP \\ strip_tac \\ fs []
  \\ fs [word_and_one_eq_0_iff |> SIMP_RULE (srw_ss()) []]
  \\ pop_assum mp_tac \\ IF_CASES_TAC \\ fs [] THEN1
   (fs [word_mul_n2w,word_add_n2w] \\ strip_tac
    \\ fs [LESS_DIV_16_IMP,DECIDE ``16 * n = 16 * m <=> n = m:num``]
    \\ IF_CASES_TAC \\ fs [lookup_insert]
    \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs [inter_insert_ODD_adjust_set_alt]
    \\ TRY (match_mp_tac memory_rel_Boolv_T)
    \\ TRY (match_mp_tac memory_rel_Boolv_F) \\ fs [])
  \\ strip_tac \\ fs []
  \\ `!w. word_exp (t with locals := insert 1 (Word w) t.locals)
        (real_addr c (adjust_var a1)) = SOME (Word a)` by
    (strip_tac \\ match_mp_tac (GEN_ALL get_real_addr_lemma)
     \\ fs [wordSemTheory.get_var_def,lookup_insert] \\ NO_TAC) \\ fs []
  \\ rpt_drule encode_header_tag_mask \\ fs []
  \\ fs [LESS_DIV_16_IMP,DECIDE ``16 * n = 16 * m <=> n = m:num``]
  \\ strip_tac \\ fs []
  \\ IF_CASES_TAC \\ fs []
  \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs [inter_insert_ODD_adjust_set_alt]
  \\ TRY (match_mp_tac memory_rel_Boolv_T)
  \\ TRY (match_mp_tac memory_rel_Boolv_F) \\ fs []);

val th = Q.store_thm("assign_TagLenEq",
  `(?tag len. op = TagLenEq tag len) ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
  \\ clean_tac \\ fs []
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [Boolv_def] \\ rveq
  \\ fs [GSYM Boolv_def] \\ rveq
  \\ fs [LENGTH_EQ_1] \\ clean_tac
  \\ fs [LENGTH_EQ_1] \\ clean_tac
  \\ qpat_x_assum `state_rel c l1 l2 x t [] locs` (fn th => NTAC 2 (mp_tac th))
  \\ strip_tac
  \\ simp_tac std_ss [state_rel_thm] \\ strip_tac \\ fs [] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac \\ fs []
  \\ fs [assign_def] \\ IF_CASES_TAC \\ fs [] \\ clean_tac
  THEN1
   (reverse IF_CASES_TAC
    \\ fs [LENGTH_NIL]
    \\ imp_res_tac get_vars_1_imp \\ eval_tac
    \\ fs [wordSemTheory.get_var_imm_def,asmTheory.word_cmp_def]
    THEN1
     (fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
      \\ imp_res_tac memory_rel_tag_limit
      \\ rpt_drule (DECIDE ``n < m /\ ~(k < m:num) ==> n <> k``) \\ fs []
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert \\ fs []
      \\ match_mp_tac memory_rel_Boolv_F \\ fs [])
    \\ rpt_drule memory_rel_test_nil_eq \\ strip_tac \\ fs []
    \\ IF_CASES_TAC \\ fs []
    \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ TRY (match_mp_tac memory_rel_Boolv_F) \\ fs []
    \\ TRY (match_mp_tac memory_rel_Boolv_T) \\ fs [])
  \\ CASE_TAC \\ fs [] THEN1
   (eval_tac \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ rpt_drule memory_rel_test_none_eq \\ strip_tac \\ fs []
    \\ match_mp_tac memory_rel_Boolv_F \\ fs [])
  \\ fs [list_Seq_def] \\ eval_tac \\ fs [wordSemTheory.get_var_imm_def]
  \\ imp_res_tac get_vars_1_imp \\ eval_tac
  \\ fs [wordSemTheory.get_var_def,lookup_insert,asmTheory.word_cmp_def]
  \\ rpt_drule memory_rel_Block_IMP \\ strip_tac \\ fs []
  \\ fs [word_and_one_eq_0_iff |> SIMP_RULE (srw_ss()) []]
  \\ IF_CASES_TAC \\ fs [] THEN1
   (IF_CASES_TAC \\ fs [] \\ drule encode_header_NEQ_0 \\ strip_tac \\ fs []
    \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ fs [inter_insert_ODD_adjust_set]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ match_mp_tac memory_rel_Boolv_F \\ fs [])
  \\ rename1 `get_vars [a8] x.locals = SOME [Block n8 l8]`
  \\ `word_exp (t with locals := insert 1 (Word 0w) t.locals)
        (real_addr c (adjust_var a8)) = SOME (Word a)` by
    (match_mp_tac (GEN_ALL get_real_addr_lemma)
     \\ fs [wordSemTheory.get_var_def,lookup_insert]) \\ fs []
  \\ drule (GEN_ALL encode_header_EQ)
  \\ qpat_x_assum `encode_header _ _ _ = _` (assume_tac o GSYM)
  \\ disch_then drule \\ fs [] \\ impl_tac
  \\ TRY (fs [memory_rel_def,heap_in_memory_store_def] \\ NO_TAC) \\ fs []
  \\ disch_then kall_tac \\ fs [DECIDE ``4 * k = 4 * l <=> k = l:num``]
  \\ rw [lookup_insert,adjust_var_11] \\ fs []
  \\ rw [lookup_insert,adjust_var_11] \\ fs []
  \\ fs [inter_insert_ODD_adjust_set]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs []
  \\ TRY (match_mp_tac memory_rel_Boolv_F) \\ fs []
  \\ TRY (match_mp_tac memory_rel_Boolv_T) \\ fs []);

val word_cmp_Test_1 = Q.store_thm("word_cmp_Test_1",
  `word_cmp Test w 1w <=> ~(word_bit 0 w)`,
  EVAL_TAC \\ fs [word_and_one_eq_0_iff,word_bit_def]);

val word_bit_if_1_0 = Q.store_thm("word_bit_if_1_0",
  `word_bit 0 (if b then 1w else 0w) <=> b`,
  Cases_on `b` \\ EVAL_TAC);

val int_op_def = Define `
  int_op op_index i j =
    if op_index = 0n then SOME (i + j) else
    if op_index = 1 then SOME (i - j) else
    if op_index = 4 then SOME (i * j) else
    if op_index = 5 /\ j <> 0 then SOME (i / j) else
    if op_index = 6 /\ j <> 0 then SOME (i % j) else NONE`

val eq_eval =
  LIST_CONJ [wordSemTheory.evaluate_def,wordSemTheory.get_var_def,
             lookup_insert,wordSemTheory.get_var_imm_def,asmTheory.word_cmp_def,
             wordSemTheory.word_exp_def,wordSemTheory.set_var_def,
             wordSemTheory.call_env_def,fromList2_def,wordSemTheory.mem_load_def,
             wordSemTheory.bad_dest_args_def,wordSemTheory.get_vars_def,
             wordSemTheory.find_code_def,wordSemTheory.add_ret_loc_def,
             list_insert_def,wordSemTheory.dec_clock_def,wordSemTheory.the_words_def,
             wordLangTheory.word_op_def];

val evaluate_AddNumSize = prove(
  ``!src c l1 l2 s t locs i w.
      state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs /\
      get_var src s.locals = SOME (Number i) ==>
      evaluate (AddNumSize c src,set_var 1 (Word w) t) =
        (NONE,set_var 1 (Word (w +
           n2w (4 * LENGTH ((SND (i2mw i):'a word list))))) t)``,
  fs [AddNumSize_def] \\ rpt strip_tac
  \\ imp_res_tac state_rel_get_var_IMP
  \\ fs [state_rel_thm,get_var_def,wordSemTheory.get_var_def]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ drule (GEN_ALL memory_rel_lookup)
  \\ rpt (disch_then drule) \\ fs [] \\ strip_tac
  \\ imp_res_tac memory_rel_any_Number_IMP
  \\ rveq \\ fs [] \\ rveq \\ fs []
  \\ rename1 `_ = SOME (Word w4)`
  \\ Cases_on `w4 = 0w` THEN1
   (fs [eq_eval,EVAL ``0w ' 0``]
    \\ imp_res_tac memory_rel_Number_const_test
    \\ pop_assum (qspec_then `i` assume_tac) \\ rfs []
    \\ `i = 0` by all_tac \\ fs [EVAL ``i2mw 0``]
    \\ fs [Smallnum_def,small_int_def,good_dimindex_def] \\ rfs [dimword_def]
    \\ Cases_on `i` \\ fs [] \\ rfs [dimword_def])
  \\ Cases_on `(w4 && 1w) = 0w` THEN1
   (fs [eq_eval]
    \\ imp_res_tac memory_rel_Number_const_test
    \\ pop_assum (qspec_then `i` assume_tac) \\ rfs []
    \\ fs [Smallnum_def]
    \\ `LENGTH (SND (i2mw i)) = 1` by all_tac \\ fs []
    \\ fs [word_index_test]
    \\ fs [multiwordTheory.i2mw_def,Once multiwordTheory.n2mw_def] \\ rfs []
    \\ rveq \\ fs [] \\ fs [small_int_def]
    \\ fs [good_dimindex_def] \\ rfs [dimword_def]
    \\ Cases_on `i` \\ fs [dimword_def] \\ rfs []
    \\ once_rewrite_tac [multiwordTheory.n2mw_def]
    \\ fs [DIV_EQ_X]
    \\ rw [] \\ fs []
    \\ `F` by intLib.COOPER_TAC)
  \\ fs [eq_eval]
  \\ fs [word_index_test]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ drule (GEN_ALL memory_rel_Number_bignum_IMP_ALT) \\ fs []
  \\ strip_tac
  \\ `word_exp (t with locals := insert 1 (Word w) t.locals)
            (real_addr c (adjust_var src)) = SOME (Word a)` by
    (match_mp_tac (GEN_ALL get_real_addr_lemma)
     \\ fs [wordSemTheory.get_var_def,lookup_insert] \\ NO_TAC) \\ fs []
  \\ fs [num_exp_def,word_sh_def,decode_length_def]
  \\ IF_CASES_TAC THEN1
   (rfs [memory_rel_def,heap_in_memory_store_def]
    \\ fs [good_dimindex_def]  \\ rfs [])
  \\ pop_assum kall_tac \\ fs []
  \\ IF_CASES_TAC THEN1
   (fs [good_dimindex_def] \\ rfs [])
  \\ pop_assum kall_tac \\ fs []
  \\ fs [WORD_MUL_LSL,GSYM word_mul_n2w,multiwordTheory.i2mw_def]);

val get_sign_word_lemma = prove(
  ``good_dimindex (:α) ⇒ (1w && x ⋙ 4) = if word_bit 4 x then 1w else 0w:'a word``,
  rw [] \\ fs [fcpTheory.CART_EQ,word_and_def,word_lsr_def,fcpTheory.FCP_BETA,
         good_dimindex_def,word_index]
  \\ rw [] \\ Cases_on `i = 0` \\ fs [word_bit_def]);

val AnyHeader_thm = prove(
  ``!t1 t2 t3 r.
      state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs /\
      get_var r s.locals = SOME (Number i) /\
      ALL_DISTINCT [t1;t2;t3] ==>
      ?a2 a3 temp.
        evaluate (AnyHeader c (adjust_var r) a t1 t2 t3,t) =
          (NONE, (set_store (Temp t1) (Word (mc_header (i2mw i)))
                 (set_store (Temp t2) (Word a2)
                 (set_store (Temp t3) (Word a3) (set_var 7 temp t))))) /\
        (i = 0i ==>
           small_int (:'a) 0i /\ i2mw i = (F,[]) /\
           a2 = 0w /\ a3 = 0w) /\
        (small_int (:'a) i /\ i <> 0 ==>
           i2mw i = (i < 0,[a3]) /\
           FLOOKUP t.store (if a then OtherHeap else NextFree) = SOME (Word a2)) /\
        (~small_int (:'a) i ==>
           ?w x. get_var (adjust_var r) t = SOME (Word w) /\
                 get_real_addr c t.store w = SOME x /\
                 a2 = x + bytes_in_word)``,
  rpt strip_tac
  \\ imp_res_tac state_rel_get_var_IMP
  \\ fs [state_rel_thm]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule memory_rel_get_var_IMP
  \\ fs [APPEND] \\ strip_tac
  \\ imp_res_tac memory_rel_any_Number_IMP
  \\ fs [] \\ fs [] \\ rveq \\ fs []
  \\ rename1 `w ' 0 ⇔ ¬small_int (:α) i`
  \\ `(w = 0w) <=> (i = 0)` by
   (rpt_drule memory_rel_Number_const_test
    \\ disch_then (qspec_then `i` mp_tac)
    \\ fs [] \\ Cases_on `w = 0w` \\ fs [EVAL ``0w ' 0``]
    \\ rw [] \\ fs [] \\ rpt strip_tac
    \\ fs [EVAL ``Smallnum 0``,EVAL ``small_int (:'a) 0``]
    \\ fs [small_int_def,Smallnum_def]
    \\ Cases_on `i` \\ fs []
    \\ rfs [good_dimindex_def,dimword_def]
    \\ rfs [good_dimindex_def,dimword_def])
  \\ Cases_on `i = 0` \\ fs []
  THEN1
   (fs [EVAL ``i2mw 0``] \\ fs [EVAL ``small_int (:α) 0``]
    \\ fs [EVAL ``mc_header (F,[])``,dimword_def]
    \\ `0n < 2 ** dimindex (:α) DIV 8` by fs [good_dimindex_def] \\ fs []
    \\ fs [AnyHeader_def]
    \\ fs [eq_eval,list_Seq_def,wordSemTheory.set_store_def,wordSemTheory.set_var_def]
    \\ fs [wordSemTheory.state_component_equality]
    \\ fs [GSYM fmap_EQ,FUN_EQ_THM,FAPPLY_FUPDATE_THM]
    \\ qexists_tac `Word 0w`
    \\ rw [] \\ fs [] \\ eq_tac \\ rw [] \\ fs [])
  \\ fs [word_bit,word_bit_test]
  \\ reverse (Cases_on `small_int (:'a) i`) \\ fs []
  THEN1
   (fs [AnyHeader_def,eq_eval]
    \\ fs [eq_eval,list_Seq_def,wordSemTheory.set_store_def]
    \\ rpt_drule memory_rel_Number_bignum_IMP_ALT
    \\ strip_tac
    \\ `word_exp t (real_addr c (adjust_var r)) = SOME (Word a)` by
     (match_mp_tac (GEN_ALL get_real_addr_lemma)
      \\ fs [wordSemTheory.get_var_def]) \\ fs []
    \\ fs [word_sh_def,num_exp_def]
    \\ IF_CASES_TAC
    THEN1 (rfs [memory_rel_def,heap_in_memory_store_def]
           \\ rfs [good_dimindex_def])
    \\ pop_assum kall_tac
    \\ `~(1 ≥ dimindex (:α)) /\ ~(4 ≥ dimindex (:α))` by
          (fs [good_dimindex_def] \\ fs [good_dimindex_def])
    \\ fs []
    \\ qexists_tac `0w` \\ fs []
    \\ qexists_tac `Word a` \\ fs []
    \\ fs [wordSemTheory.state_component_equality]
    \\ fs [GSYM fmap_EQ,FUN_EQ_THM,FAPPLY_FUPDATE_THM]
    \\ rw [] \\ fs [] \\ TRY (eq_tac \\ rw [] \\ fs [])
    \\ fs [decode_length_def,mc_multiwordTheory.mc_header_def,
           multiwordTheory.i2mw_def,WORD_MUL_LSL,word_mul_n2w]
    \\ qpat_assum `_ <=> i < 0i` (fn th => rewrite_tac [GSYM th])
    \\ qpat_assum `good_dimindex (:α)` mp_tac
    \\ fs [get_sign_word_lemma])
  \\ fs [AnyHeader_def,eq_eval]
  \\ Q.MATCH_ASMSUB_RENAME_TAC `(Number i,Word w)::vars` \\ rveq
  \\ `memory_rel c t.be s.refs s.space t.store t.memory t.mdomain
         ((Number 0,Word (Smallnum 0))::(Number i,Word w)::vars)` by
   (match_mp_tac IMP_memory_rel_Number
    \\ fs [] \\ EVAL_TAC \\ fs [good_dimindex_def,dimword_def])
  \\ imp_res_tac memory_rel_swap
  \\ drule memory_rel_Number_cmp \\ fs [EVAL ``word_bit 0 (Smallnum 0)``]
  \\ fs [word_bit_test,EVAL ``Smallnum 0``]
  \\ strip_tac \\ fs []
  \\ IF_CASES_TAC \\ fs []
  THEN1
   (`i2mw i = (F,[w >>> 2])` by
      (fs [multiwordTheory.i2mw_def]
       \\ Cases_on `i` \\ fs [intLib.COOPER_PROVE ``Num (ABS (&n)) = n``]
       \\ once_rewrite_tac [multiwordTheory.n2mw_def] \\ fs []
       \\ `n < dimword (:α)` by
            (ntac 2 (rfs [good_dimindex_def,small_int_def,dimword_def]))
       \\ once_rewrite_tac [multiwordTheory.n2mw_def] \\ fs []
       \\ fs [DIV_EQ_X]
       \\ imp_res_tac memory_rel_Number_IMP \\ fs []
       \\ fs [Smallnum_def]
       \\ rewrite_tac [GSYM w2n_11,w2n_lsr]
       \\ fs [] \\ rfs [good_dimindex_def,small_int_def,dimword_def]
       \\ fs [ONCE_REWRITE_RULE [MULT_COMM] MULT_DIV])
    \\ fs [] \\ fs [eq_eval,list_Seq_def,wordSemTheory.set_store_def]
    \\ Cases_on `a` \\ fs [FLOOKUP_UPDATE,heap_in_memory_store_def,memory_rel_def]
    \\ fs [word_sh_def,num_exp_def]
    \\ qexists_tac `Word 0w` \\ fs []
    \\ fs [wordSemTheory.state_component_equality]
    \\ fs [GSYM fmap_EQ,FUN_EQ_THM,FAPPLY_FUPDATE_THM]
    \\ rw [] \\ fs [] \\ TRY (eq_tac \\ rw [] \\ fs [])
    \\ EVAL_TAC \\ fs [n2w_mod])
  THEN1
   (`i2mw i = (T,[0w - (w >> 2)])` by
      (fs [multiwordTheory.i2mw_def]
       \\ Cases_on `i` \\ fs [intLib.COOPER_PROVE ``Num (ABS (-&n)) = n``]
       \\ once_rewrite_tac [multiwordTheory.n2mw_def] \\ fs []
       \\ `n < dimword (:α)` by
            (ntac 2 (rfs [good_dimindex_def,small_int_def,dimword_def]))
       \\ once_rewrite_tac [multiwordTheory.n2mw_def] \\ fs []
       \\ fs [DIV_EQ_X]
       \\ imp_res_tac memory_rel_Number_IMP \\ fs []
       \\ fs [small_int_def,Smallnum_def]
       \\ `-n2w (4 * n) = i2w (- & (4 * n))` by
            (fs [integer_wordTheory.i2w_def] \\ NO_TAC) \\ fs []
       \\ qspecl_then [`2`,`-&(4 * n)`] mp_tac (GSYM integer_wordTheory.i2w_DIV)
       \\ impl_tac THEN1
        (fs [wordsTheory.INT_MIN_def]
         \\ fs [EXP_SUB,X_LE_DIV,dimword_def]
         \\ rfs [good_dimindex_def])
       \\ fs [] \\ strip_tac
       \\ `-&(4 * n) / 4 = - & n` by
        (rewrite_tac [MATCH_MP (GSYM integerTheory.INT_DIV_NEG)
                         (intLib.COOPER_PROVE ``0 <> 4i``)]
         \\ fs [integerTheory.INT_DIV_CALCULATE]
         \\ fs [integerTheory.INT_EQ_NEG]
         \\ match_mp_tac integerTheory.INT_DIV_UNIQUE
         \\ fs [] \\ qexists_tac `0` \\ fs []
         \\ fs [integerTheory.INT_MUL_CALCULATE])
       \\ fs [] \\ fs [integer_wordTheory.i2w_def]
       \\ rewrite_tac [GSYM WORD_NEG_MUL] \\ fs [])
    \\ fs [] \\ fs [eq_eval,list_Seq_def,wordSemTheory.set_store_def]
    \\ Cases_on `a` \\ fs [FLOOKUP_UPDATE,heap_in_memory_store_def,memory_rel_def]
    \\ fs [word_sh_def,num_exp_def]
    \\ qexists_tac `Word 0w` \\ fs []
    \\ fs [wordSemTheory.state_component_equality]
    \\ fs [GSYM fmap_EQ,FUN_EQ_THM,FAPPLY_FUPDATE_THM]
    \\ rw [] \\ fs [] \\ TRY (eq_tac \\ rw [] \\ fs [])
    \\ EVAL_TAC \\ fs [n2w_mod]));

val word_exp_set_var_ShiftVar_lemma = store_thm("word_exp_set_var_ShiftVar_lemma",
  ``word_exp t (ShiftVar sow v n) =
    case lookup v t.locals of
    | SOME (Word w) =>
        lift Word (case sow of Lsl => SOME (w << n)
                             | Lsr => SOME (w >>> n)
                             | Asr => SOME (w >> n)
                             | Ror => SOME (word_ror w n))
    | _ => FAIL (word_exp t (ShiftVar sow v n)) "lookup failed"``,
  Cases_on `lookup v t.locals` \\ fs [] \\ rw [FAIL_DEF]
  \\ fs [ShiftVar_def]
  \\ IF_CASES_TAC \\ fs []
  THEN1
   (Cases_on `n < dimindex (:'a)` \\ fs []
    THEN1
     (Cases_on `n = 0` \\ fs []
      \\ eval_tac \\ every_case_tac \\ fs [])
    \\ eval_tac \\ every_case_tac \\ fs [] \\ eval_tac
    \\ qspec_then `n` assume_tac (MATCH_MP MOD_LESS DIMINDEX_GT_0)
    \\ simp [])
  \\ IF_CASES_TAC \\ fs []
  THEN1 (eval_tac \\ every_case_tac \\ fs [])
  \\ IF_CASES_TAC \\ fs []
  THEN1
   (drule word_asr_dimindex
    \\ IF_CASES_TAC \\ eval_tac
    \\ every_case_tac \\ eval_tac)
  \\ eval_tac \\ every_case_tac \\ fs [] \\ eval_tac);

val state_rel_set_store_Temp = prove(
  ``state_rel c l1 l2 s (set_store (Temp tmp) w t) vs locs =
    state_rel c l1 l2 s t vs locs``,
  fs [state_rel_def,wordSemTheory.set_store_def]
  \\ rw [] \\ eq_tac \\ rw []
  \\ fs [heap_in_memory_store_def,PULL_EXISTS,FLOOKUP_UPDATE,FAPPLY_FUPDATE_THM]
  \\ rpt (asm_exists_tac \\ fs []) \\ metis_tac []);

val state_rel_IMP_num_size_limit = prove(
  ``state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs /\
    get_var k s.locals = SOME (Number i) ==>
    LENGTH (SND (i2mw i):'a word list) < dimword (:'a) DIV 16``,
  rpt strip_tac
  \\ imp_res_tac state_rel_get_var_IMP
  \\ fs [state_rel_thm,get_var_def,wordSemTheory.get_var_def]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (GEN_ALL memory_rel_lookup)
  \\ Cases_on `small_int (:'a) i`
  THEN1
   (rw [] \\ simp [multiwordTheory.i2mw_def]
    \\ once_rewrite_tac [multiwordTheory.n2mw_def]
    \\ once_rewrite_tac [multiwordTheory.n2mw_def]
    \\ fs [good_dimindex_def,dimword_def] \\ rfs [DIV_EQ_X]
    \\ rw [] \\ fs [] \\ rfs [small_int_def,dimword_def]
    \\ `F` by intLib.COOPER_TAC)
  \\ strip_tac
  \\ rpt_drule memory_rel_Number_bignum_IMP_ALT
  \\ fs [multiwordTheory.i2mw_def] \\ rw [] \\ fs []
  \\ fs [good_dimindex_def,dimword_def] \\ rfs [EXP_SUB]);

val word_heap_non_empty_limit = prove(
  ``limit <> 0 ==>
      word_heap other (heap_expand limit) c =
      SEP_EXISTS w1. one (other,w1) *
        word_heap (other + bytes_in_word) (heap_expand (limit - 1)) c``,
  Cases_on `limit` \\ fs []
  \\ fs [heap_expand_def,word_heap_def,word_el_def]
  \\ once_rewrite_tac [ADD_COMM]
  \\ fs [word_list_exists_ADD]
  \\ fs [word_list_exists_def,SEP_CLAUSES,SEP_EXISTS_THM,FUN_EQ_THM]
  \\ rw [] \\ fs [LENGTH_NIL,LENGTH_EQ_1]
  \\ simp_tac (std_ss++sep_cond_ss) [cond_STAR,PULL_EXISTS,word_list_def,
       SEP_CLAUSES,word_list_def,word_heap_def,word_el_def]
  \\ fs [word_list_exists_def]
  \\ simp_tac (std_ss++sep_cond_ss) [cond_STAR,PULL_EXISTS,word_list_def,
       SEP_CLAUSES,word_list_def,word_heap_def,word_el_def,SEP_EXISTS_THM]
  \\ metis_tac []);

val word_list_store_list = prove(
  ``!xs a frame m dm.
      (word_list a xs * frame) (fun2set (m,dm)) ==>
      ?m2. (store_list a (REPLICATE (LENGTH xs) (Word 0w)) m dm = SOME m2) /\
           (word_list a (REPLICATE (LENGTH xs) (Word 0w)) * frame)
              (fun2set (m2,dm))``,
  Induct \\ fs [store_list_def,REPLICATE,word_list_def] \\ rw []
  \\ SEP_R_TAC \\ fs [] \\ SEP_W_TAC \\ SEP_F_TAC
  \\ strip_tac \\ fs [AC STAR_COMM STAR_ASSOC]);

val MustTerminate_limit_SUB_2 = prove(
  ``good_dimindex (:'a) ==> dimword (:'a) <= MustTerminate_limit (:α) − 2``,
  fs [wordSemTheory.MustTerminate_limit_def]
  \\ qpat_abbrev_tac `m = (_:num) ** _`
  \\ qpat_abbrev_tac `n = (_:num) ** _`
  \\ rpt (pop_assum kall_tac)
  \\ fs [good_dimindex_def] \\ rw [] \\ fs [dimword_def]);

val cut_env_fromList_sing = prove(
  ``cut_env (fromList [()]) (insert 0 (Loc l1 l2) LN) =
    SOME (insert 0 (Loc l1 l2) LN)``,
  EVAL_TAC);

val if_eq_b2w = prove(
  ``(if b then 1w else 0w) = b2w b``,
  Cases_on `b` \\ EVAL_TAC);

val LongDiv1_thm = prove(
  ``!k n1 n2 m i1 i2 (t2:('a,'ffi) wordSem$state)
        r1 r2 m1 is1 c:data_to_word$config.
      single_div_loop (n2w k,[n1;n2],m,[i1;i2]) = (m1,is1) /\
      lookup LongDiv1_location t2.code = SOME (7,LongDiv1_code c) /\
      lookup 0 t2.locals = SOME (Loc r1 r2) /\
      lookup 2 t2.locals = SOME (Word (n2w k)) /\
      lookup 4 t2.locals = SOME (Word n2) /\
      lookup 6 t2.locals = SOME (Word n1) /\
      lookup 8 t2.locals = SOME (Word m) /\
      lookup 10 t2.locals = SOME (Word i1) /\
      lookup 12 t2.locals = SOME (Word i2) /\
      k < dimword (:'a) /\ k < t2.clock /\ good_dimindex (:'a) /\ ~c.has_longdiv ==>
      ?j1 j2.
        is1 = [j1;j2] /\
        evaluate (LongDiv1_code c,t2) = (SOME (Result (Loc r1 r2) (Word m1)),
          t2 with <| clock := t2.clock - k;
                     locals := LN;
                     store := t2.store |+ (Temp 28w,Word (HD is1)) |>)``,
  Induct THEN1
   (fs [Once multiwordTheory.single_div_loop_def] \\ rw []
    \\ rewrite_tac [LongDiv1_code_def]
    \\ fs [eq_eval,wordSemTheory.set_store_def]
    \\ fs [wordSemTheory.state_component_equality])
  \\ once_rewrite_tac [multiwordTheory.single_div_loop_def]
  \\ rpt strip_tac \\ fs []
  \\ fs [multiwordTheory.mw_shift_def]
  \\ fs [ADD1,GSYM word_add_n2w]
  \\ qpat_x_assum `_ = (m1,is1)` mp_tac
  \\ once_rewrite_tac [multiwordTheory.mw_cmp_def] \\ fs []
  \\ once_rewrite_tac [multiwordTheory.mw_cmp_def] \\ fs []
  \\ once_rewrite_tac [multiwordTheory.mw_cmp_def] \\ fs []
  \\ qabbrev_tac `n2' = n2 ⋙ 1`
  \\ qabbrev_tac `n1' = (n2 ≪ (dimindex (:α) − 1) ‖ n1 ⋙ 1)`
  \\ rewrite_tac [LongDiv1_code_def]
  \\ fs [eq_eval,word_add_n2w]
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ fs []
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ fs [lookup_insert]
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ fs [lookup_insert]
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ fs [GSYM word_add_n2w]
  \\ Cases_on `i2 <+ n2'` \\ fs [WORD_LOWER_NOT_EQ] THEN1
   (strip_tac
    \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
    \\ qmatch_goalsub_abbrev_tac `evaluate (LongDiv1_code c,t3)`
    \\ first_x_assum drule
    \\ disch_then (qspecl_then [`t3`,`r1`,`r2`,`c`] mp_tac)
    \\ impl_tac THEN1 (unabbrev_all_tac \\ fs [lookup_insert])
    \\ strip_tac \\ fs []
    \\ unabbrev_all_tac \\ fs [wordSemTheory.state_component_equality])
  \\ Cases_on `i2 = n2' /\ i1 <+ n1'` \\ asm_rewrite_tac [] THEN1
   (fs [WORD_LOWER_NOT_EQ] \\ rveq \\ strip_tac
    \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
    \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
    \\ qmatch_goalsub_abbrev_tac `evaluate (LongDiv1_code c,t3)`
    \\ first_x_assum drule
    \\ disch_then (qspecl_then [`t3`,`r1`,`r2`,`c`] mp_tac)
    \\ impl_tac THEN1 (unabbrev_all_tac \\ fs [lookup_insert])
    \\ strip_tac \\ fs []
    \\ unabbrev_all_tac \\ fs [wordSemTheory.state_component_equality])
  \\ IF_CASES_TAC
  THEN1 (`F` by all_tac \\ pop_assum mp_tac \\ rfs [] \\ rfs [] \\ rw [])
  \\ pop_assum kall_tac
  \\ once_rewrite_tac [list_Seq_def] \\ simp [eq_eval]
  \\ once_rewrite_tac [list_Seq_def] \\ simp [eq_eval]
  \\ `i2 = n2' ==> ~(i1 <₊ n1')` by metis_tac []
  \\ simp [] \\ ntac 2 (pop_assum kall_tac)
  \\ once_rewrite_tac [list_Seq_def] \\ simp [eq_eval]
  \\ fs [multiwordTheory.mw_sub_def,multiwordTheory.single_sub_def]
  \\ pairarg_tac \\ fs []
  \\ rename1 `_ = (is2,r)`
  \\ rpt (pairarg_tac \\ fs []) \\ rveq
  \\ once_rewrite_tac [list_Seq_def] \\ simp [eq_eval]
  \\ once_rewrite_tac [list_Seq_def] \\ simp [eq_eval]
  \\ once_rewrite_tac [list_Seq_def] \\ simp [eq_eval]
  \\ once_rewrite_tac [list_Seq_def] \\ simp [eq_eval,wordSemTheory.inst_def]
  \\ fs [if_eq_b2w,GSYM word_add_n2w]
  \\ `i1 + ¬n1' + 1w = z /\ (dimword (:α) ≤ w2n i1 + (w2n (¬n1') + 1)) = c1` by1
   (fs [multiwordTheory.single_add_def] \\ rveq
    \\ fs [multiwordTheory.b2w_def,multiwordTheory.b2n_def])
  \\ fs [] \\ ntac 2 (pop_assum kall_tac)
  \\ once_rewrite_tac [list_Seq_def] \\ simp [eq_eval,wordSemTheory.inst_def]
  \\ fs [if_eq_b2w,GSYM word_add_n2w]
  \\ qmatch_goalsub_abbrev_tac `b2w new_c`
  \\ qmatch_goalsub_abbrev_tac `insert 12 (Word new_z)`
  \\ `z' = new_z /\ c1' = new_c` by
   (unabbrev_all_tac \\ pop_assum mp_tac
    \\ simp [multiwordTheory.single_add_def] \\ strip_tac \\ rveq
    \\ qpat_abbrev_tac `ppp = if b2w c1 = 0w then 0 else 1n`
    \\ qsuff_tac `ppp = b2n c1`
    THEN1 (fs [] \\ Cases_on `c1` \\ EVAL_TAC)
    \\ unabbrev_all_tac \\ Cases_on `c1` \\ EVAL_TAC \\ fs [] \\ NO_TAC)
  \\ fs [list_Seq_def,eq_eval]
  \\ qmatch_goalsub_abbrev_tac `evaluate (LongDiv1_code c,t3)`
  \\ strip_tac \\ first_x_assum drule
  \\ disch_then (qspecl_then [`t3`,`r1`,`r2`,`c`] mp_tac)
  \\ impl_tac THEN1 (unabbrev_all_tac \\ fs [lookup_insert])
  \\ strip_tac \\ fs []
  \\ unabbrev_all_tac \\ fs [wordSemTheory.state_component_equality]);

val single_div_pre_IMP_single_div_full = prove(
  ``single_div_pre x1 x2 y ==>
    single_div x1 x2 y = single_div_full x1 x2 y``,
  strip_tac
  \\ match_mp_tac (GSYM multiwordTheory.single_div_full_thm)
  \\ fs [mc_multiwordTheory.single_div_pre_def,multiwordTheory.mw2n_def]
  \\ Cases_on `y` \\ fs [] \\ rfs [DIV_LT_X]);

val evaluate_LongDiv_code = prove(
  ``!(t:('a,'ffi) wordSem$state) l1 l2 c w x1 x2 y d1 m1.
      single_div_pre x1 x2 y /\
      single_div x1 x2 y = (d1,m1:'a word) /\
      lookup LongDiv1_location t.code = SOME (7,LongDiv1_code c) /\
      lookup 0 t.locals = SOME (Loc l1 l2) /\
      lookup 2 t.locals = SOME (Word x1) /\
      lookup 4 t.locals = SOME (Word x2) /\
      lookup 6 t.locals = SOME (Word y) /\
      dimword (:'a) < t.clock /\ good_dimindex (:'a) ==>
      ?ck.
        evaluate (LongDiv_code c,t) =
          (SOME (Result (Loc l1 l2) (Word d1)),
           t with <| clock := ck; locals := LN;
                     store := t.store |+ (Temp 28w,Word m1) |>)``,
  rpt strip_tac
  \\ Cases_on `c.has_longdiv` \\ simp []
  \\ fs [LongDiv_code_def,eq_eval,wordSemTheory.push_env_def]
  THEN1 (* has_longdiv case *)
   (once_rewrite_tac [list_Seq_def] \\ fs [eq_eval,wordSemTheory.inst_def]
    \\ reverse IF_CASES_TAC THEN1
     (`F` by all_tac \\ pop_assum mp_tac \\ simp []
      \\ fs [mc_multiwordTheory.single_div_pre_def])
    \\ fs [list_Seq_def,eq_eval,wordSemTheory.set_store_def,lookup_insert]
    \\ fs [fromAList_def,wordSemTheory.state_component_equality]
    \\ fs [multiwordTheory.single_div_def])
  \\ `dimindex (:'a) + 5 < dimword (:'a)` by
        (fs [dimword_def,good_dimindex_def] \\ NO_TAC)
  \\ imp_res_tac IMP_LESS_MustTerminate_limit
  \\ qmatch_goalsub_abbrev_tac `evaluate (LongDiv1_code c,t2)`
  \\ rfs [single_div_pre_IMP_single_div_full]
  \\ fs [multiwordTheory.single_div_full_def]
  \\ Cases_on `(single_div_loop (n2w (dimindex (:α)),[0w; y],0w,[x2; x1]))`
  \\ fs [] \\ rveq
  \\ `lookup LongDiv1_location t2.code = SOME (7,LongDiv1_code c) /\
      lookup 0 t2.locals = SOME (Loc l1 l2)` by1
    (qunabbrev_tac `t2` \\ fs [lookup_insert])
  \\ rpt_drule LongDiv1_thm
  \\ impl_tac THEN1 (qunabbrev_tac `t2` \\ EVAL_TAC \\ fs [])
  \\ strip_tac \\ fs []
  \\ qunabbrev_tac `t2` \\ fs []
  \\ fs [FLOOKUP_UPDATE,wordSemTheory.set_store_def,
         wordSemTheory.state_component_equality,fromAList_def]);

val div_code_assum_thm = prove(
  ``state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs ==>
    div_code_assum (:'ffi) t.code``,
  fs [DivCode_def,div_code_assum_def,eq_eval] \\ rpt strip_tac
  \\ fs [state_rel_thm,code_rel_def,stubs_def]
  \\ fs [EVAL ``LongDiv_location``,div_location_def]
  \\ qpat_abbrev_tac `x = cut_env (LS ()) _`
  \\ `x = SOME (insert 0 ret_val LN)` by
   (unabbrev_all_tac \\ fs [wordSemTheory.cut_env_def,domain_lookup]
    \\ match_mp_tac (spt_eq_thm |> REWRITE_RULE [EQ_IMP_THM]
                       |> SPEC_ALL |> UNDISCH_ALL |> CONJUNCT2
                       |> DISCH_ALL |> MP_CANON |> GEN_ALL)
    \\ conj_tac THEN1 (rewrite_tac [wf_inter] \\ EVAL_TAC)
    \\ simp_tac std_ss [lookup_inter_alt,lookup_def,domain_lookup]
    \\ fs [lookup_insert,lookup_def] \\ NO_TAC)
  \\ fs [eq_eval,wordSemTheory.push_env_def]
  \\ `env_to_list (insert 0 ret_val LN) t1.permute =
        ([(0,ret_val)],\n. t1.permute (n+1))` by
   (fs [wordSemTheory.env_to_list_def,wordSemTheory.list_rearrange_def]
    \\ fs [EVAL ``(QSORT key_val_compare (toAList (insert 0 x LN)))``]
    \\ fs [EVAL ``count 1``] \\ rw []
    \\ fs [BIJ_DEF,SURJ_DEF]) \\ fs []
  \\ `dimindex (:'a) + 5 < dimword (:'a)` by
        (fs [dimword_def,good_dimindex_def] \\ NO_TAC)
  \\ qmatch_goalsub_abbrev_tac `evaluate (LongDiv_code c,t2)`
  \\ qspecl_then [`t2`,`n`,`l`,`c`] mp_tac evaluate_LongDiv_code
  \\ fs [Abbr `t2`,lookup_insert,multiwordTheory.single_div_def]
  \\ impl_tac THEN1 fs [wordSemTheory.MustTerminate_limit_def]
  \\ strip_tac \\ fs [] \\ pop_assum kall_tac
  \\ fs [wordSemTheory.pop_env_def,EVAL ``domain (fromAList [(0,ret_val)])``,
         FLOOKUP_UPDATE,wordSemTheory.set_store_def]
  \\ fs [fromAList_def,wordSemTheory.state_component_equality]
  \\ match_mp_tac (spt_eq_thm |> REWRITE_RULE [EQ_IMP_THM]
                     |> SPEC_ALL |> UNDISCH_ALL |> CONJUNCT2
                     |> DISCH_ALL |> MP_CANON |> GEN_ALL)
  \\ conj_tac THEN1 metis_tac [wf_def,wf_insert]
  \\ simp_tac std_ss [lookup_insert,lookup_def]
  \\ rpt strip_tac
  \\ rpt (IF_CASES_TAC \\ asm_rewrite_tac [])
  \\ rveq \\ qpat_x_assum `0 < 0n` mp_tac
  \\ simp_tac (srw_ss()) []);

val get_iop_def = Define `
  get_iop (n:num) =
    if n = 0 then multiword$Add else
    if n = 1 then multiword$Sub else
    if n = 4 then multiword$Mul else
    if n = 5 then multiword$Div else
                  multiword$Mod`;

val state_rel_imp_clock = prove(
  ``state_rel c l1 l2 s t [] locs ==> s.clock = t.clock``,
  fs [state_rel_def]);

val MustTerminate_limit_eq = prove(
  ``good_dimindex (:'a) ==>
    ?k. MustTerminate_limit (:α) =
        10 * dimword (:'a) * dimword (:'a) +
        10 * dimword (:'a) + 100 + k``,
  rewrite_tac [GSYM LESS_EQ_EXISTS]
  \\ fs [wordSemTheory.MustTerminate_limit_def] \\ rw []
  \\ match_mp_tac LESS_EQ_TRANS
  \\ qexists_tac `dimword (:α) ** dimword (:α)`
  \\ fs []
  \\ match_mp_tac LESS_EQ_TRANS
  \\ qexists_tac `12 * (dimword (:α))²`
  \\ `10 * dimword (:'a) <= (dimword (:α))² /\
      100 <= (dimword (:α))²` by
    (fs [dimword_def,good_dimindex_def] \\ NO_TAC)
  \\ fs []
  \\ match_mp_tac LESS_EQ_TRANS
  \\ qexists_tac `(dimword (:α)) * (dimword (:α))²` \\ fs []
  \\ fs [dimword_def,good_dimindex_def]);

val SND_i2mw_NIL = prove(
  ``SND (i2mw i) = [] <=> i = 0``,
  Cases_on `i` \\ fs []
  \\ fs [multiwordTheory.i2mw_def]
  \\ once_rewrite_tac [multiwordTheory.n2mw_def]
  \\ rw [] \\ intLib.COOPER_TAC);

val mc_header_i2mw_eq_0w = prove(
  ``2 * LENGTH (SND (i2mw i):'a word list) + 1 < dimword (:'a) ==>
    (mc_header (i2mw i:bool # 'a word list) = 0w:'a word <=> i = 0)``,
  Cases_on `i = 0`
  \\ fs [multiwordTheory.i2mw_def,mc_multiwordTheory.mc_header_def]
  \\ rw [] \\ fs [word_add_n2w] THEN1 EVAL_TAC
  \\ fs [LENGTH_NIL]
  \\ once_rewrite_tac [multiwordTheory.n2mw_def]
  \\ rw [] \\ intLib.COOPER_TAC);

val IMP_bignum_code_rel = prove(
  ``compile Bignum_location 1 1 (Bignum_location + 1,[])
             mc_iop_code = (xx1,xx2,xx3,xx4,xx5) /\
    state_rel c l1 l2 s t [] locs ==>
    code_rel (xx4,xx5) t.code``,
  fs [word_bignumProofTheory.code_rel_def,state_rel_def,code_rel_def,stubs_def]
  \\ rpt strip_tac
  \\ fs [generated_bignum_stubs_def] \\ rfs [] \\ fs [EVERY_MAP]
  \\ drule alistTheory.ALOOKUP_MEM \\ strip_tac
  \\ first_x_assum (drule o REWRITE_RULE [EVERY_MEM])
  \\ fs [] \\ strip_tac
  \\ imp_res_tac compile_NIL_IMP \\ fs []
  \\ asm_exists_tac \\ fs []);

val heap_lookup_Unused_Bignum = prove(
  ``heap_lookup a (Unused k::hb) = SOME (Bignum j) <=>
    k+1 <= a /\
    heap_lookup (a - (k+1)) hb = SOME (Bignum j)``,
  fs [heap_lookup_def,el_length_def]
  \\ rw [] \\ fs [Bignum_def]
  \\ pairarg_tac \\ fs []);

val push_env_insert_0 = prove(
  ``push_env (insert 0 x LN) NONE t =
    t with <| stack := StackFrame [(0,x)] NONE :: t.stack ;
              permute := \n. t.permute (n+1) |>``,
  fs [wordSemTheory.push_env_def]
  \\ fs [wordSemTheory.env_to_list_def]
  \\ EVAL_TAC \\ rw [] \\ fs []
  \\ fs [BIJ_DEF,INJ_DEF]);

val state_rel_Number_small_int = prove(
  ``state_rel c r1 r2 s t [x] locs /\ small_int (:'a) i ==>
    state_rel c r1 r2 s t [(Number i,Word (Smallnum i:'a word))] locs``,
  fs [state_rel_thm] \\ rw[]
  \\ match_mp_tac IMP_memory_rel_Number \\ fs []
  \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac memory_rel_rearrange)
  \\ fs []);

val i2mw_small_int_IMP_0 = prove(
  ``(∀v1. i2mw v ≠ (F,[v1:'a word])) /\ (∀v1. i2mw v ≠ (T,[v1:'a word])) /\
    small_int (:α) v /\ good_dimindex (:'a) ==> v = 0``,
  CCONTR_TAC \\ fs [] \\ Cases_on `v` \\ fs []
  \\ fs [multiwordTheory.i2mw_def,small_int_def]
  \\ qpat_x_assum `!x._` mp_tac \\ fs []
  \\ once_rewrite_tac [multiwordTheory.n2mw_def]
  \\ once_rewrite_tac [multiwordTheory.n2mw_def]
  \\ rw []
  \\ fs [good_dimindex_def,dimword_def]
  \\ fs [good_dimindex_def,dimword_def] \\ rfs [DIV_EQ_X]
  \\ intLib.COOPER_TAC);

val small_int_0 = prove(
  ``good_dimindex (:'a) ==> small_int (:α) 0``,
  fs [good_dimindex_def,small_int_def,dimword_def] \\ rw [] \\ fs []);

val state_rel_with_clock_0 = prove(
  ``state_rel c r1 r2 s t x locs ==>
    state_rel c r1 r2 (s with space := 0) t x locs``,
  fs [state_rel_thm] \\ rw [] \\ fs [memory_rel_def]
  \\ asm_exists_tac \\ fs []);

val word_list_IMP_store_list = prove(
  ``!xs a frame m dm.
      (word_list a xs * frame) (fun2set (m,dm)) ==>
      store_list a xs m dm = SOME m``,
  Induct \\ fs [store_list_def,word_list_def]
  \\ rw [] \\ SEP_R_TAC
  \\ `(a =+ h) m = m` by1
    (fs [FUN_EQ_THM,APPLY_UPDATE_THM] \\ rw [] \\ SEP_R_TAC \\ fs [])
  \\ fs [] \\ first_x_assum match_mp_tac
  \\ qexists_tac `frame * one (a,h)` \\ fs [AC STAR_COMM STAR_ASSOC]);

val AnyArith_thm = Q.store_thm("AnyArith_thm",
  `∀op_index i j v t s r2 r1 locs l2 l1 c.
     state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs /\
     get_vars [0;1;2] s.locals = SOME [Number i; Number j; Number (& op_index)] /\
     t.clock = MustTerminate_limit (:'a) - 2 /\ t.termdep <> 0 /\
     lookup 6 t.locals = SOME (Word (n2w (4 * op_index))) /\
     int_op op_index i j = SOME v ==>
     ?q r new_c.
       evaluate (AnyArith_code c,t) = (q,r) /\
       if q = SOME NotEnoughSpace then
         r.ffi = t.ffi
       else
         ?rv. q = SOME (Result (Loc l1 l2) rv) /\
              state_rel c r1 r2
                (s with <| locals := LN; clock := new_c; space := 0 |>) r
                [(Number v,rv)] locs`,
  rpt strip_tac \\ fs [AnyArith_code_def]
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,wordSemTheory.word_exp_def]
  \\ once_rewrite_tac [list_Seq_def]
  \\ `get_var 1 s.locals = SOME (Number j) /\
      get_var 0 s.locals = SOME (Number i)` by
        fs [get_vars_SOME_IFF_data]
  \\ fs [wordSemTheory.evaluate_def,wordSemTheory.word_exp_def]
  \\ rpt_drule (GEN_ALL evaluate_AddNumSize)
  \\ disch_then kall_tac
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,wordSemTheory.word_exp_def]
  \\ pop_assum kall_tac
  \\ rpt_drule (GEN_ALL evaluate_AddNumSize)
  \\ disch_then kall_tac
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [eq_eval]
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,wordSemTheory.word_exp_def]
  \\ fs [GSYM wordSemTheory.set_var_def]
  \\ Q.MATCH_GOALSUB_ABBREV_TAC `set_var 1 (Word w1)` \\ rveq
  \\ Q.MATCH_GOALSUB_ABBREV_TAC `evaluate (AllocVar _ _,t4)` \\ rveq
  \\ `state_rel c l1 l2 s t4 [] locs` by
   (unabbrev_all_tac
    \\ fs [wordSemTheory.set_var_def,state_rel_insert_1,state_rel_set_store_Temp]
    \\ NO_TAC)
  \\ `dataSem$cut_env (fromList [(); (); ()]) s.locals = SOME
         (fromList [Number i; Number j; Number (&op_index)])` by
   (fs [cut_env_def,SUBSET_DEF,domain_lookup,fromList_def,
        lookup_insert,lookup_def] \\ strip_tac \\ rw []
    \\ fs [get_vars_SOME_IFF_data,get_var_def]
    \\ fs [spt_eq_thm,wf_insert,wf_def,wf_inter]
    \\ fs [lookup_inter_alt,lookup_insert]
    \\ rw [lookup_def] \\ NO_TAC)
  \\ `get_var 1 t4 = SOME (Word w1)` by
   (unabbrev_all_tac \\ fs [wordSemTheory.get_var_def,
      lookup_insert,wordSemTheory.set_store_def,eq_eval] \\ NO_TAC)
  \\ pairarg_tac \\ fs []
  \\ `2 ** c.len_size < dimword (:α) DIV 8` by
   (fs [state_rel_thm,memory_rel_def,heap_in_memory_store_def]
    \\ fs [good_dimindex_def] \\ rfs [dimword_def]
    \\ rewrite_tac [MATCH_MP EXP_BASE_LT_MONO (DECIDE ``1<2n``),
         GSYM (EVAL ``2n**29``),GSYM (EVAL ``2n**61``)] \\ fs [])
  \\ rpt_drule AllocVar_thm
  \\ strip_tac \\ Cases_on `res = SOME NotEnoughSpace` \\ fs []
  THEN1 (fs [state_rel_def]) \\ fs []
  \\ qabbrev_tac `il = LENGTH ((SND (i2mw i)):'a word list)`
  \\ qabbrev_tac `jl = LENGTH ((SND (i2mw j)):'a word list)`
  \\ `w2n w1 DIV 4 + 1 = il + jl + 2` by
   (fs [word_add_n2w]
    \\ qsuff_tac `4 * il + (4 * jl) + 4 < dimword (:'a)`
    THEN1
     (qunabbrev_tac `w1` \\ fs []
      \\ qspecl_then [`4`,`il + jl + 1`] mp_tac MULT_DIV \\ fs [])
    \\ fs [get_vars_SOME_IFF_data]
    \\ imp_res_tac state_rel_IMP_num_size_limit \\ rfs []
    \\ fs [state_rel_def,good_dimindex_def] \\ rfs [dimword_def] \\ NO_TAC)
  \\ fs []
  \\ qabbrev_tac `s0 = (s with
          <|locals := fromList [Number i; Number j; Number (&op_index)];
            space := il + (jl + 2)|>)`
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ rpt_drule AnyHeader_thm
  \\ disch_then (qspecl_then [`i`,`F`,`0w`,`31w`,`12w`,`0`] mp_tac)
  \\ impl_tac THEN1
   (unabbrev_all_tac \\ fs [get_vars_SOME_IFF_data]
    \\ fs [fromList_def,get_var_def,lookup_insert])
  \\ fs [adjust_var_def] \\ strip_tac \\ fs []
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ qpat_abbrev_tac `s8 = set_store _ _ _`
  \\ `state_rel c l1 l2 s0 s8 [] locs` by
      (unabbrev_all_tac \\ fs [state_rel_set_store_Temp,state_rel_insert_7] \\ NO_TAC)
  \\ rpt_drule AnyHeader_thm
  \\ disch_then (qspecl_then [`j`,`T`,`1w`,`30w`,`11w`,`1`] mp_tac)
  \\ impl_tac THEN1
   (fs [get_vars_SOME_IFF_data,Abbr`s0`]
    \\ fs [fromList_def,get_var_def,lookup_insert])
  \\ fs [adjust_var_def] \\ strip_tac \\ fs []
  \\ qpat_abbrev_tac `s9 = set_store _ _ _`
  \\ `state_rel c l1 l2 s0 s9 [] locs` by
      (unabbrev_all_tac \\ fs [state_rel_set_store_Temp,
         wordSemTheory.set_var_def,state_rel_insert_7] \\ NO_TAC)
  \\ qunabbrev_tac `s8`
  \\ pop_assum mp_tac
  \\ simp [Once state_rel_thm,memory_rel_def]
  \\ fs [heap_in_memory_store_def]
  \\ strip_tac
  \\ `unused_space_inv a (sp+sp1) heap` by fs [word_ml_inv_def,abs_ml_inv_def]
  \\ fs [unused_space_inv_def]
  \\ `?k. sp + sp1 = il + jl + 2 + k` by
      (qexists_tac `(sp + sp1 - (il + jl + 2))`
       \\ unabbrev_all_tac \\ fs [] \\ NO_TAC)
  \\ fs []
  \\ rpt_drule heap_lookup_SPLIT
  \\ strip_tac
  \\ qpat_x_assum `(word_heap curr heap c * _) _` mp_tac
  \\ asm_rewrite_tac []
  \\ pop_assum (fn th => fs [th])
  \\ pop_assum (assume_tac o ONCE_REWRITE_RULE [GSYM markerTheory.Abbrev_def])
  \\ rveq
  \\ fs [word_heap_def,word_heap_APPEND,word_el_def]
  \\ `(il + (jl + (k + 2))) = 1 + (il + jl + 1) + k` by fs []
  \\ pop_assum (fn th => once_rewrite_tac [th])
  \\ once_rewrite_tac [word_list_exists_ADD]
  \\ once_rewrite_tac [word_list_exists_ADD]
  \\ simp [Once word_list_exists_def]
  \\ simp [Once word_list_exists_def]
  \\ fs [SEP_CLAUSES,SEP_EXISTS_THM]
  \\ simp_tac (std_ss++sep_cond_ss) [cond_STAR]
  \\ strip_tac
  \\ `?x1. xs = [x1]` by
       (Cases_on `xs` \\ fs [] \\ Cases_on `t'` \\ fs [] \\ NO_TAC)
  \\ rveq \\ fs []
  \\ rename1 `LENGTH xs = il + (jl + 1)`
  \\ fs [word_list_def,SEP_CLAUSES]
  \\ `limit <> 0` by
   (fs [abs_ml_inv_def,heap_ok_def,word_ml_inv_def]
    \\ rveq \\ fs [Abbr`heap`]
    \\ fs [heap_length_APPEND]
    \\ fs [heap_length_def,el_length_def] \\ NO_TAC)
  \\ fs [word_heap_non_empty_limit]
  \\ fs [SEP_CLAUSES,SEP_EXISTS_THM]
  \\ `FLOOKUP s9.store (Temp 11w) = SOME (Word a3') /\
      FLOOKUP s9.store (Temp 12w) = SOME (Word a3) /\
      FLOOKUP s9.store (Temp 29w) = SOME (Word w1) /\
      FLOOKUP s9.store (Temp 31w) = SOME (Word a2) /\
      FLOOKUP s9.store (Temp 30w) = SOME (Word a2')` by
        (fs [Abbr`s9`,wordSemTheory.set_store_def,FLOOKUP_UPDATE,
           wordSemTheory.set_var_def,Abbr `t4`] \\ NO_TAC)
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ fs [wordSemTheory.mem_store_def]
  \\ SEP_R_TAC \\ fs []
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ fs [wordSemTheory.mem_store_def]
  \\ SEP_R_TAC \\ fs []
  \\ ntac 5 (once_rewrite_tac [list_Seq_def] \\ fs [eq_eval])
  \\ simp [wordSemTheory.set_store_def]
  \\ once_rewrite_tac [list_Seq_def] \\ fs []
  \\ once_rewrite_tac [eq_eval]
  \\ qpat_abbrev_tac `m5 = (_ =+ _) _`
  \\ fs [lookup_insert]
  \\ `lookup 6 s9.locals = SOME (Word (n2w (4 * op_index)))` by
   (`lookup 6 s9.locals = lookup 6 s1.locals` by
     (qunabbrev_tac `s9` \\ fs [lookup_insert,wordSemTheory.set_store_def])
    \\ asm_rewrite_tac []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ qpat_x_assum `state_rel c l1 l2 s0 s1 [] locs` mp_tac
    \\ rewrite_tac [state_rel_thm] \\ fs [] \\ strip_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule memory_rel_get_vars_IMP
    \\ `get_var 2 s0.locals = SOME (Number (& op_index))` by
         (qunabbrev_tac `s0` \\ EVAL_TAC \\ NO_TAC)
    \\ rpt_drule state_rel_get_var_IMP
    \\ simp [wordSemTheory.set_store_def,wordSemTheory.get_var_def,
             EVAL ``adjust_var 2``,lookup_insert]
    \\ strip_tac
    \\ disch_then (qspecl_then [`[Number (&op_index)]`,`[w]`,`[2]`] mp_tac)
    \\ fs [EVAL ``MAP adjust_var [2]``]
    \\ fs [get_vars_def,wordSemTheory.get_vars_def,wordSemTheory.get_var_def]
    \\ strip_tac
    \\ `small_int (:α) (&op_index)` by
     (qpat_x_assum `good_dimindex (:'a)` mp_tac
      \\ qpat_x_assum `int_op _ _ _ = _` mp_tac
      \\ rpt (pop_assum kall_tac)
      \\ fs [good_dimindex_def,int_op_def]
      \\ every_case_tac \\ fs []
      \\ rw [] \\ fs [small_int_def,dimword_def] \\ NO_TAC)
    \\ rpt_drule (memory_rel_Number_IMP |> ONCE_REWRITE_RULE [CONJ_ASSOC]
                    |> ONCE_REWRITE_RULE [CONJ_COMM])
    \\ fs [Smallnum_def] \\ NO_TAC)
  \\ fs [lookup_insert]
  \\ fs [word_sh_def,num_exp_def]
  \\ Q.MATCH_GOALSUB_ABBREV_TAC `evaluate (_,t9)` \\ rveq
  \\ qabbrev_tac `dm = s9.mdomain`
  \\ qabbrev_tac `m = s9.memory`
  \\ qpat_x_assum `_ (fun2set (m,dm))` mp_tac
  \\ fs [el_length_def]
  \\ qpat_abbrev_tac `hb_heap = word_list_exists _ k`
  \\ qpat_abbrev_tac `hb_heap1 = word_heap _ hb c`
  \\ qpat_abbrev_tac `other_heap = word_heap _ (heap_expand _) c`
  \\ strip_tac
  \\ `(word_list
          (curr + bytes_in_word + bytes_in_word * n2w (heap_length ha))
          xs * (word_heap curr ha c *
        one (curr + bytes_in_word * n2w (heap_length ha),Word a3) *
        hb_heap * hb_heap1 * one (other,Word a3') * other_heap))
         (fun2set (m5,dm))` by
    (fs [Abbr`m5`] \\ SEP_W_TAC \\ fs [AC STAR_COMM STAR_ASSOC] \\ NO_TAC)
  \\ drule word_list_store_list
  \\ strip_tac \\ fs []
  \\ qspecl_then [`Word 0w`,`Loc l1 l2`,`1`,`AnyArith_location`,`LENGTH xs`,
       `curr + bytes_in_word * n2w (heap_length ha)`,`t9`,`m2`,
       `2`,`3`,`1`] mp_tac
         (GEN_ALL Replicate_code_alt_thm |> SIMP_RULE std_ss [])
  \\ impl_tac THEN1
    (fs [Abbr `t9`,wordSemTheory.get_var_def,lookup_insert] \\ rfs []
     \\ qunabbrev_tac `w1` \\ fs [word_mul_n2w,word_add_n2w]
     \\ conj_tac THEN1
       (unabbrev_all_tac
        \\ fs [wordSemTheory.set_store_def,code_rel_def,stubs_def])
     \\ `s0.clock = t.clock` by
       (unabbrev_all_tac
        \\ fs [wordSemTheory.set_store_def,code_rel_def,stubs_def,state_rel_def])
     \\ simp []
     \\ drule MustTerminate_limit_SUB_2 \\ fs []
     \\ `il + (jl + 1) < dimword (:α) DIV 8` by
          (imp_res_tac LESS_TRANS \\ fs [] \\ NO_TAC)
     \\ qpat_assum `good_dimindex _` mp_tac
     \\ ntac 2 (pop_assum mp_tac)
     \\ rpt (pop_assum kall_tac)
     \\ rw [good_dimindex_def,dimword_def] \\ fs [dimword_def]
     \\ rfs [] \\ fs [])
  \\ strip_tac \\ simp []
  \\ pop_assum kall_tac
  \\ `t9.code = t.code /\ t9.termdep = t.termdep /\
      t9.mdomain = t.mdomain /\ t9.be = t.be` by
   (imp_res_tac wordSemTheory.evaluate_clock
    \\ imp_res_tac evaluate_code_gc_fun_const
    \\ imp_res_tac evaluate_mdomain_const
    \\ imp_res_tac evaluate_be_const
    \\ unabbrev_all_tac
    \\ fs [wordSemTheory.set_store_def])
  \\ `FLOOKUP t9.store (Temp 29w) = SOME
        (Word (curr + bytes_in_word * n2w (heap_length ha)))` by1
     (qunabbrev_tac `t9` \\ fs [wordSemTheory.set_store_def,FLOOKUP_UPDATE]
      \\ qunabbrev_tac `s9` \\ fs [wordSemTheory.set_store_def,FLOOKUP_UPDATE])
  \\ once_rewrite_tac [list_Seq_def]
  \\ simp [eq_eval,cut_env_fromList_sing]
  \\ once_rewrite_tac [list_Seq_def]
  \\ simp [eq_eval,cut_env_fromList_sing,wordSemTheory.set_store_def]
  \\ `code_rel c s.code t.code` by (fs [state_rel_def] \\ NO_TAC)
  \\ pop_assum mp_tac
  \\ rewrite_tac [code_rel_def,stubs_def,generated_bignum_stubs_def,LET_THM]
  \\ Cases_on `compile Bignum_location 1 1 (Bignum_location + 1,[]) mc_iop_code`
  \\ PairCases_on `r`
  \\ simp_tac (srw_ss())[APPEND,EVERY_DEF,EVAL ``domain (fromList [()]) = ∅``]
  \\ strip_tac
  \\ `il + (jl + 1) < dimword (:α) DIV 8` by fs []
  \\ IF_CASES_TAC THEN1
   (`F` by all_tac
    \\ unabbrev_all_tac \\ fs [wordSemTheory.set_store_def]
    \\ rfs []
    \\ fs [DECIDE ``m + 1 = n + (k + 2:num) <=> m = n + k + 1``]
    \\ `s.clock = t.clock` by fs [state_rel_def] \\ rfs []
    \\ `LENGTH (SND (i2mw i):'a word list) +
       (LENGTH (SND (i2mw j):'a word list) + 1) < dimword (:α) DIV 8`
            by (imp_res_tac LESS_TRANS \\ fs [] \\ NO_TAC)
    \\ fs []
    \\ qpat_x_assum `_ <= _:num` mp_tac \\ simp[GSYM NOT_LESS]
    \\ fs [X_LT_DIV]
    \\ match_mp_tac LESS_TRANS
    \\ qexists_tac `2 * dimword (:'a)` \\ fs []
    \\ fs [wordSemTheory.MustTerminate_limit_def]
    \\ fs [dimword_def]
    \\ match_mp_tac (DECIDE ``n < k ==> n < k + l:num``)
    \\ rewrite_tac [prove(``n ** 2 = n * n:num``,fs []),ZERO_LESS_MULT]
    \\ fs [])
  \\ `t9.mdomain = dm` by1
        (qunabbrev_tac `dm` \\ qunabbrev_tac `t9` \\ fs [])
  \\ Q.MATCH_GOALSUB_ABBREV_TAC `evaluate (Seq q (Return 0 0),t3)` \\ rveq
  \\ qabbrev_tac `my_frame = word_heap curr ha c *
         one (curr + bytes_in_word * n2w (heap_length ha),Word a3) *
         hb_heap * hb_heap1 * one (other,Word a3') * other_heap`
  \\ qspecl_then [`i`,`j`,`1`,`my_frame`,`REPLICATE (LENGTH xs) 0w`,`t3`,
          `Loc AnyArith_location 2`,`Bignum_location`,`t3.clock`,
          `get_iop op_index`] mp_tac
       (evaluate_mc_iop |> INST_TYPE [``:'c``|->``:'ffi``])
  \\ asm_rewrite_tac [] \\ simp_tac std_ss [AND_IMP_INTRO]
  \\ impl_tac THEN1
   (simp [LENGTH_REPLICATE]
    \\ simp_tac (srw_ss()) [word_bignumProofTheory.state_rel_def,GSYM CONJ_ASSOC]
    \\ simp [mc_multiwordTheory.mc_div_max_def,LENGTH_REPLICATE]
    \\ fs [X_LT_DIV]
    \\ `get_iop op_index ≠ Lt ∧
        get_iop op_index ≠ Eq ∧
        get_iop op_index ≠ Dec /\
        (get_iop op_index = Div ∨ get_iop op_index = Mod ⇒ j ≠ 0)` by
     (qpat_x_assum `int_op op_index i j = SOME v` mp_tac
      \\ rpt (pop_assum kall_tac) \\ fs []
      \\ fs [int_op_def]
      \\ every_case_tac \\ fs [] \\ EVAL_TAC \\ NO_TAC)
    \\ fs [] \\ `t3.code = t.code /\ t3.termdep = t.termdep` by
     (qunabbrev_tac `t3` \\ fs [wordSemTheory.push_env_def]
      \\ pairarg_tac \\ fs [] \\ NO_TAC) \\ fs []
    \\ `div_code_assum (:'ffi) t.code` by metis_tac [div_code_assum_thm]
    \\ `get_var 0 t3 = SOME (Loc AnyArith_location 2)` by
          (qunabbrev_tac `t3` \\ fs [wordSemTheory.get_var_def] \\ NO_TAC)
    \\ simp []
    \\ imp_res_tac state_rel_imp_clock
    \\ `s9.clock = s1.clock` by
         (simp [Abbr`s9`,wordSemTheory.set_store_def] \\ NO_TAC)
    \\ `t3.clock = t9.clock − (il + (jl + 3))` by
         (simp [Abbr`t3`,wordSemTheory.set_store_def] \\ NO_TAC)
    \\ `t9.clock = s9.clock` by
         (simp [Abbr`t9`,wordSemTheory.set_store_def] \\ NO_TAC)
    \\ `s0.clock = s.clock` by
         (simp [Abbr`s0`,wordSemTheory.set_store_def] \\ fs [] \\ NO_TAC)
    \\ fs []
    \\ rewrite_tac [CONJ_ASSOC]
    \\ reverse conj_tac THEN1
     (match_mp_tac LESS_EQ_TRANS
      \\ qexists_tac `MustTerminate_limit (:α) - dimword (:'a) - dimword (:'a) - 5`
      \\ fs [LEFT_ADD_DISTRIB]
      \\ `il * jl <= dimword (:'a) * dimword (:'a)` by
           (match_mp_tac LESS_MONO_MULT2 \\ fs [])
      \\ `il * dimword (:α) <= dimword (:'a) * dimword (:'a)` by
           (match_mp_tac LESS_MONO_MULT2 \\ fs [])
      \\ `?k. MustTerminate_limit (:α) =
              10 * dimword (:'a) * dimword (:'a) +
              10 * dimword (:'a) + 100 + k` by metis_tac [MustTerminate_limit_eq]
      \\ qabbrev_tac `dd = dimword (:α) * dimword (:α)`
      \\ qabbrev_tac `ij = il * jl`
      \\ qabbrev_tac `id = il * dimword (:'a)`
      \\ `il < dimword (:'a) /\ jl < dimword (:'a)` by fs []
      \\ `dimindex (:'a) < dimword (:'a)` by
            (fs [good_dimindex_def] \\ simp [dimword_def])
      \\ fs [] \\ NO_TAC)
    \\ fs [SND_i2mw_NIL]
    \\ reverse conj_tac THEN1 (match_mp_tac mc_header_i2mw_eq_0w \\ fs [])
    \\ reverse conj_tac THEN1 (match_mp_tac mc_header_i2mw_eq_0w \\ fs [])
    \\ reverse conj_tac THEN1 metis_tac []
    \\ `t3.store = t9.store |+ (Temp 29w,
           Word (curr + bytes_in_word + bytes_in_word * n2w (heap_length ha))) /\
        t3.memory = m2 /\ t3.mdomain = t9.mdomain` by
     (qunabbrev_tac `t3` \\ simp_tac (srw_ss()) [wordSemTheory.push_env_def]
      \\ rw [] \\ pairarg_tac \\ asm_rewrite_tac []
      \\ simp_tac (srw_ss()) [] \\ asm_rewrite_tac [] \\ NO_TAC)
    \\ reverse conj_tac THEN1 (imp_res_tac IMP_bignum_code_rel \\ NO_TAC)
    \\ reverse conj_tac THEN1
     (qpat_x_assum `int_op op_index i j = SOME v` mp_tac
      \\ qpat_x_assum `good_dimindex (:'a)` mp_tac
      \\ asm_rewrite_tac [FLOOKUP_UPDATE]
      \\ rewrite_tac [FLOOKUP_DEF,FDOM_FEMPTY,NOT_IN_EMPTY]
      \\ qunabbrev_tac `t9`
      \\ qunabbrev_tac `s9`
      \\ simp_tac (srw_ss()) [wordSemTheory.set_store_def]
      \\ rpt (pop_assum kall_tac)
      \\ fs [FAPPLY_FUPDATE_THM]
      \\ rw [] \\ fs []
      \\ Cases_on `a = 0` \\ fs []
      \\ Cases_on `a = 1` \\ fs []
      \\ rveq \\ fs []
      \\ fs [int_op_def] \\ every_case_tac \\ fs []
      \\ rewrite_tac [GSYM w2n_11,w2n_lsr,w2n_n2w]
      \\ fs [good_dimindex_def,dimword_def]
      \\ EVAL_TAC \\ fs [dimword_def])
    \\ `FLOOKUP t9.store TempIn1 = SOME (Word a2) /\
        FLOOKUP t9.store TempIn2 = SOME (Word a2')` by1
     (qunabbrev_tac `t9` \\ fs [wordSemTheory.set_store_def,FLOOKUP_UPDATE,
         EVAL ``TempOut``,EVAL ``TempIn1``,EVAL ``TempIn2``]
      \\ qunabbrev_tac `s9` \\ fs [wordSemTheory.set_store_def,FLOOKUP_UPDATE])
    \\ asm_rewrite_tac [FLOOKUP_UPDATE]
    \\ simp_tac (srw_ss()) [array_rel_def,APPLY_UPDATE_THM,GSYM PULL_EXISTS,
          EVAL ``TempOut``,EVAL ``TempIn1``,EVAL ``TempIn2``]
    \\ reverse (rpt strip_tac)
    \\ qpat_x_assum `_ (fun2set (m2,dm))` mp_tac
    THEN1 (fs [map_replicate])
    THEN1
     (Cases_on `j = 0` THEN1
       (qunabbrev_tac `jl` \\ fs [EVAL ``i2mw 0``]
        \\ fs [word_list_def,SEP_CLAUSES,map_replicate]
        \\ strip_tac \\ asm_exists_tac \\ fs [])
      \\ Cases_on `small_int (:'a) j` \\ fs [] THEN1
       (qunabbrev_tac `my_frame`
        \\ qunabbrev_tac `t9`
        \\ qunabbrev_tac `s9` \\ fs []
        \\ fs [EVAL ``TempIn2``,EVAL ``TempIn1``,
               wordSemTheory.set_store_def,FLOOKUP_UPDATE]
        \\ rveq \\ fs [word_list_def,SEP_CLAUSES]
        \\ strip_tac
        \\ qexists_tac `word_heap curr ha c *
             one (curr + bytes_in_word * n2w (heap_length ha),Word a3) *
             hb_heap * hb_heap1 * other_heap`
        \\ pop_assum mp_tac
        \\ simp_tac std_ss [AC STAR_COMM STAR_ASSOC,map_replicate])
      \\ simp_tac std_ss [map_replicate]
      \\ qmatch_goalsub_rename_tac `repl_list * my_frame`
      \\ fs [wordSemTheory.set_store_def,lookup_insert] \\ rveq
      \\ qpat_x_assum `lookup 4 s1.locals = SOME (Word w)` assume_tac
      \\ `get_real_addr c s1.store w = SOME x` by1
            fs [get_real_addr_def,FLOOKUP_UPDATE]
      \\ qpat_x_assum `word_ml_inv _ _ _ _ _` assume_tac
      \\ `lookup 4 s9.locals = SOME (Word w)` by1
        (qunabbrev_tac `s9`
         \\ simp_tac (srw_ss()) [wordSemTheory.set_store_def,lookup_insert]
         \\ asm_rewrite_tac [])
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ rpt_drule word_ml_inv_get_var_IMP
      \\ disch_then (qspecl_then [`Number j`,`1`,`Word w`] mp_tac)
      \\ impl_tac THEN1
       (asm_rewrite_tac [EVAL ``adjust_var 0``,EVAL ``adjust_var 1``,
               wordSemTheory.get_var_def,get_var_def]
        \\ qunabbrev_tac `s0` \\ EVAL_TAC)
      \\ qmatch_goalsub_rename_tac `((Number j,Word w)::vars)`
      \\ asm_simp_tac (srw_ss()) [word_ml_inv_def,abs_ml_inv_def,
             bc_stack_ref_inv_def,PULL_EXISTS,v_inv_def,word_addr_def]
      \\ rpt strip_tac \\ rveq
      \\ `curr + bytes_in_word * n2w ptr = x` by1
       (rpt_drule get_real_addr_get_addr
        \\ qpat_x_assum `get_real_addr _ _ _ = _` mp_tac
        \\ `FLOOKUP s1.store CurrHeap = SOME (Word curr)` by1
         (unabbrev_all_tac \\ simp_tac (srw_ss()) []
          \\ fs [wordSemTheory.set_store_def,FLOOKUP_UPDATE])
        \\ asm_simp_tac (srw_ss()) [get_real_addr_def]
        \\ rpt strip_tac \\ fs [])
      \\ rveq
      \\ qunabbrev_tac `my_frame`
      \\ qunabbrev_tac `hb_heap1`
      \\ qunabbrev_tac `heap`
      \\ full_simp_tac std_ss [APPEND]
      \\ fs [heap_lookup_APPEND]
      \\ Cases_on `ptr < heap_length ha` \\ full_simp_tac std_ss []
      THEN1
       (drule heap_lookup_SPLIT
        \\ strip_tac \\ rveq
        \\ qpat_x_assum `_ (fun2set _)` mp_tac
        \\ simp_tac std_ss [word_heap_APPEND,word_heap_def,word_el_def,
              Bignum_def,LET_THM]
        \\ pairarg_tac
        \\ asm_simp_tac std_ss [word_el_def,word_payload_def,LET_THM,word_list_def]
        \\ strip_tac \\ fs []
        \\ qmatch_goalsub_rename_tac `a * repl_list`
        \\ qabbrev_tac `b = repl_list`
        \\ full_simp_tac std_ss [AC STAR_COMM STAR_ASSOC]
        \\ asm_exists_tac \\ asm_rewrite_tac [])
      \\ full_simp_tac std_ss [heap_lookup_Unused_Bignum]
      THEN1
       (drule heap_lookup_SPLIT
        \\ strip_tac \\ rveq
        \\ qpat_x_assum `_ (fun2set _)` mp_tac
        \\ simp_tac std_ss [word_heap_APPEND,word_heap_def,word_el_def,
              Bignum_def,LET_THM]
        \\ pairarg_tac
        \\ asm_simp_tac std_ss [word_el_def,word_payload_def,LET_THM,word_list_def]
        \\ `ptr = heap_length ha' + heap_length ha + (il + (jl + (k + 2)))`
              by decide_tac \\ rveq \\ fs []
        \\ fs [GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
        \\ strip_tac \\ fs []
        \\ qmatch_goalsub_rename_tac `a * repl_list`
        \\ qabbrev_tac `b = repl_list`
        \\ full_simp_tac std_ss [AC STAR_COMM STAR_ASSOC]
        \\ asm_exists_tac \\ asm_rewrite_tac []))
    THEN1
     (Cases_on `i = 0` THEN1
       (qunabbrev_tac `il` \\ fs [EVAL ``i2mw 0``]
        \\ fs [word_list_def,SEP_CLAUSES,map_replicate]
        \\ strip_tac \\ asm_exists_tac \\ fs [])
      \\ Cases_on `small_int (:'a) i` \\ fs [] THEN1
       (qunabbrev_tac `my_frame`
        \\ qunabbrev_tac `t9`
        \\ qunabbrev_tac `s9` \\ fs []
        \\ fs [EVAL ``TempIn2``,EVAL ``TempIn1``,
               wordSemTheory.set_store_def,FLOOKUP_UPDATE]
        \\ rveq \\ fs [word_list_def,SEP_CLAUSES]
        \\ strip_tac
        \\ qexists_tac `word_heap curr ha c *
             one (other,Word a3') * hb_heap * hb_heap1 * other_heap`
        \\ pop_assum mp_tac
        \\ simp_tac std_ss [AC STAR_COMM STAR_ASSOC,map_replicate])
      \\ simp_tac std_ss [map_replicate]
      \\ qmatch_goalsub_rename_tac `repl_list * my_frame`
      \\ fs [wordSemTheory.set_store_def,lookup_insert] \\ rveq
      \\ qpat_x_assum `lookup 2 s1.locals = SOME (Word w)` assume_tac
      \\ `get_real_addr c s1.store w = SOME x` by1
            fs [get_real_addr_def,FLOOKUP_UPDATE]
      \\ qpat_x_assum `word_ml_inv _ _ _ _ _` assume_tac
      \\ `lookup 2 s9.locals = SOME (Word w)` by1
        (qunabbrev_tac `s9`
         \\ simp_tac (srw_ss()) [wordSemTheory.set_store_def,lookup_insert]
         \\ asm_rewrite_tac [])
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ rpt_drule word_ml_inv_get_var_IMP
      \\ disch_then (qspecl_then [`Number i`,`0`,`Word w`] mp_tac)
      \\ impl_tac THEN1
       (asm_rewrite_tac [EVAL ``adjust_var 0``,EVAL ``adjust_var 1``,
               wordSemTheory.get_var_def,get_var_def]
        \\ qunabbrev_tac `s0` \\ EVAL_TAC)
      \\ qmatch_goalsub_rename_tac `((Number i,Word w)::vars)`
      \\ asm_simp_tac (srw_ss()) [word_ml_inv_def,abs_ml_inv_def,
             bc_stack_ref_inv_def,PULL_EXISTS,v_inv_def,word_addr_def]
      \\ rpt strip_tac \\ rveq
      \\ `curr + bytes_in_word * n2w ptr = x` by1
       (rpt_drule get_real_addr_get_addr
        \\ qpat_x_assum `get_real_addr _ _ _ = _` mp_tac
        \\ `FLOOKUP s1.store CurrHeap = SOME (Word curr)` by1
         (unabbrev_all_tac \\ simp_tac (srw_ss()) []
          \\ fs [wordSemTheory.set_store_def,FLOOKUP_UPDATE])
        \\ asm_simp_tac (srw_ss()) [get_real_addr_def]
        \\ rpt strip_tac \\ fs [])
      \\ rveq
      \\ qunabbrev_tac `my_frame`
      \\ qunabbrev_tac `hb_heap1`
      \\ qunabbrev_tac `heap`
      \\ full_simp_tac std_ss [APPEND]
      \\ fs [heap_lookup_APPEND]
      \\ Cases_on `ptr < heap_length ha` \\ full_simp_tac std_ss []
      THEN1
       (drule heap_lookup_SPLIT
        \\ strip_tac \\ rveq
        \\ qpat_x_assum `_ (fun2set _)` mp_tac
        \\ simp_tac std_ss [word_heap_APPEND,word_heap_def,word_el_def,
              Bignum_def,LET_THM]
        \\ pairarg_tac
        \\ asm_simp_tac std_ss [word_el_def,word_payload_def,LET_THM,word_list_def]
        \\ strip_tac \\ fs []
        \\ qmatch_goalsub_rename_tac `a * repl_list`
        \\ qabbrev_tac `b = repl_list`
        \\ full_simp_tac std_ss [AC STAR_COMM STAR_ASSOC]
        \\ asm_exists_tac \\ asm_rewrite_tac [])
      \\ full_simp_tac std_ss [heap_lookup_Unused_Bignum]
      THEN1
       (drule heap_lookup_SPLIT
        \\ strip_tac \\ rveq
        \\ qpat_x_assum `_ (fun2set _)` mp_tac
        \\ simp_tac std_ss [word_heap_APPEND,word_heap_def,word_el_def,
              Bignum_def,LET_THM]
        \\ pairarg_tac
        \\ asm_simp_tac std_ss [word_el_def,word_payload_def,LET_THM,word_list_def]
        \\ `ptr = heap_length ha' + heap_length ha + (il + (jl + (k + 2)))`
              by decide_tac \\ rveq \\ fs []
        \\ fs [GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
        \\ strip_tac \\ fs []
        \\ qmatch_goalsub_rename_tac `a * repl_list`
        \\ qabbrev_tac `b = repl_list`
        \\ full_simp_tac std_ss [AC STAR_COMM STAR_ASSOC]
        \\ asm_exists_tac \\ asm_rewrite_tac [])))
  \\ strip_tac \\ simp []
  \\ rewrite_tac [eq_eval]
  \\ fs [wordSemTheory.get_var_def,push_env_insert_0]
  \\ simp [Abbr `t3`,wordSemTheory.pop_env_def,
       EVAL ``domain (fromAList [(0,x)])``]
  \\ simp_tac std_ss [fromAList_def]
  \\ `int_op (get_iop op_index) i j = v` by1
   (qpat_x_assum `_ = SOME v` mp_tac
    \\ rpt (pop_assum kall_tac)
    \\ fs [int_op_def] \\ rw [] \\ EVAL_TAC)
  \\ full_simp_tac std_ss [] \\ pop_assum kall_tac
  \\ `FLOOKUP t2.store (Temp 10w) = SOME (Word (mc_header (i2mw v)))` by
   (qpat_x_assum `state_rel _ _ _ _ _` mp_tac
    \\ rpt (pop_assum kall_tac)
    \\ rewrite_tac [word_bignumProofTheory.state_rel_def]
    \\ rpt strip_tac
    \\ qpat_x_assum `∀a v. _ ==> _` mp_tac
    \\ simp_tac (srw_ss()) [FLOOKUP_UPDATE] \\ NO_TAC)
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval,insert_shadow]
  \\ `(mc_header (i2mw v) = 0w:'a word <=> v = 0) /\
      (mc_header (i2mw v) = 2w:'a word <=> ?v1. i2mw v = (F,[v1:'a word])) /\
      (mc_header (i2mw v) = 3w:'a word <=> ?v1. i2mw v = (T,[v1:'a word]))` by
   (fs [LENGTH_REPLICATE]
    \\ qpat_x_assum `LENGTH _ + LENGTH _ = _` (fn th => fs[GSYM th])
    \\ fs [multiwordTheory.i2mw_def]
    \\ Cases_on `v` \\ fs [mc_multiwordTheory.mc_header_def]
    \\ fs [X_LT_DIV,word_add_n2w]
    \\ once_rewrite_tac [multiwordTheory.n2mw_def]
    \\ rw [] \\ simp [GSYM LENGTH_NIL] \\ intLib.COOPER_TAC)
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ `t2.be = s1.be` by1
   (imp_res_tac evaluate_be_const
    \\ unabbrev_all_tac
    \\ fs [wordSemTheory.set_store_def] \\ asm_rewrite_tac []
    \\ qpat_x_assum `state_rel _ _ _ _ _` mp_tac
    \\ rewrite_tac [word_bignumProofTheory.state_rel_def]
    \\ simp_tac (srw_ss()) [])
  \\ `FLOOKUP t2.store CurrHeap = FLOOKUP s9.store CurrHeap /\
      FLOOKUP t2.store OtherHeap = FLOOKUP s9.store OtherHeap /\
      FLOOKUP t2.store NextFree = FLOOKUP s9.store NextFree /\
      FLOOKUP t2.store EndOfHeap = FLOOKUP s9.store EndOfHeap /\
      FLOOKUP t2.store Globals = FLOOKUP s9.store Globals` by1
   (qunabbrev_tac `s9` \\ qunabbrev_tac `t9`
    \\ qpat_x_assum `state_rel _ _ _ _ _` mp_tac
    \\ rpt (pop_assum kall_tac)
    \\ fs [wordSemTheory.set_store_def]
    \\ rewrite_tac [word_bignumProofTheory.state_rel_def]
    \\ rpt strip_tac \\ pop_assum mp_tac
    \\ simp_tac (srw_ss()) [FLOOKUP_UPDATE])
  \\ `Globals ∈ FDOM t2.store` by1
       (pop_assum mp_tac \\ fs [FLOOKUP_DEF])
  \\ `∃new_c.
        state_rel c r1 r2
          (s with <|locals := LN; clock := new_c; space := il + jl + 2|>)
          (t2 with <|locals := LN; stack := t9.stack|>)
             [(Number 0,Word 0w)] locs` by
   (qmatch_asmsub_abbrev_tac `clock_write new_clock_val`
    \\ qexists_tac `new_clock_val`
    \\ fs [Abbr `s9`,wordSemTheory.set_store_def]
    \\ simp_tac (srw_ss()) [state_rel_thm] \\ asm_rewrite_tac []
    \\ simp_tac (srw_ss()) [EVAL ``join_env LN []``]
    \\ qunabbrev_tac `t9` \\ asm_simp_tac (srw_ss()) [lookup_def]
    \\ qpat_x_assum `state_rel _ _ _ _ _` mp_tac
    \\ rewrite_tac [word_bignumProofTheory.state_rel_def]
    \\ simp_tac (srw_ss()) [FLOOKUP_UPDATE,TempOut_def]
    \\ qunabbrev_tac `s0` \\ full_simp_tac (srw_ss()) []
    \\ rpt strip_tac THEN1
     (qpat_x_assum `code_rel c s.code t.code` mp_tac
      \\ asm_rewrite_tac [])
    \\ rewrite_tac [GSYM (EVAL ``Smallnum 0``)]
    \\ match_mp_tac IMP_memory_rel_Number
    \\ imp_res_tac small_int_0
    \\ asm_rewrite_tac []
    \\ asm_simp_tac std_ss [memory_rel_def]
    \\ qexists_tac `heap`
    \\ qexists_tac `limit`
    \\ qexists_tac `heap_length ha`
    \\ qexists_tac `sp`
    \\ qexists_tac `sp1`
    \\ qexists_tac `gens`
    \\ reverse (rpt strip_tac)
    THEN1 (simp [])
    THEN1 asm_simp_tac std_ss []
    THEN1
     (qpat_x_assum `word_ml_inv _ _ _ _ _` mp_tac
      \\ match_mp_tac word_ml_inv_rearrange
      \\ fs [] \\ rpt strip_tac \\ asm_rewrite_tac []
      \\ full_simp_tac (srw_ss()) [FAPPLY_FUPDATE_THM,FLOOKUP_UPDATE]
      \\ full_simp_tac (srw_ss()) [FLOOKUP_DEF]
      \\ first_x_assum (qspec_then `Globals` mp_tac)
      \\ asm_simp_tac (srw_ss()) [FLOOKUP_DEF] \\ rfs [])
    \\ asm_simp_tac std_ss [heap_in_memory_store_def]
    \\ simp_tac (srw_ss()) [AC ADD_COMM ADD_ASSOC] \\ asm_rewrite_tac []
    \\ full_simp_tac (srw_ss()) [FLOOKUP_UPDATE]
    \\ full_simp_tac std_ss [array_rel_def]
    \\ qpat_x_assum `_ (fun2set _)` mp_tac
    \\ rpt (qpat_x_assum `_ (fun2set _)` kall_tac)
    \\ full_simp_tac (srw_ss()) [APPLY_UPDATE_THM] \\ rveq
    \\ asm_simp_tac (srw_ss()) [word_heap_non_empty_limit]
    \\ qunabbrev_tac `my_frame`
    \\ qunabbrev_tac `heap`
    \\ simp_tac std_ss [word_heap_APPEND,word_heap_def,heap_length_APPEND,
         SEP_CLAUSES,word_el_def]
    \\ simp_tac std_ss [EVAL ``heap_length [Unused k]``]
    \\ fs [GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
    \\ simp_tac std_ss [word_list_exists_def,SEP_CLAUSES,SEP_EXISTS_THM]
    \\ simp_tac (std_ss++sep_cond_ss) [cond_STAR]
    \\ qunabbrev_tac `hb_heap`
    \\ simp_tac std_ss [word_list_exists_def,SEP_CLAUSES,SEP_EXISTS_THM]
    \\ simp_tac (std_ss++sep_cond_ss) [cond_STAR]
    \\ strip_tac \\ rename1 `LENGTH leftover = k` \\ rveq
    \\ fs [GSYM WORD_LEFT_ADD_DISTRIB,word_add_n2w]
    \\ fs [WORD_LEFT_ADD_DISTRIB,GSYM word_add_n2w]
    \\ qexists_tac `Word a3'`
    \\ qexists_tac `Word a3 :: MAP Word (SND (i2mw v)) ++ MAP Word zs1 ++ leftover`
    \\ conj_tac THEN1 fs [LENGTH_REPLICATE,ADD1]
    \\ full_simp_tac std_ss [APPEND_ASSOC,APPEND]
    \\ qpat_abbrev_tac `ts = MAP Word (SND (i2mw v)) ++ MAP Word zs1`
    \\ fs [LENGTH_REPLICATE,ADD1,word_list_def,word_list_APPEND]
    \\ `LENGTH ts = il + (jl + 1)` by1 (qunabbrev_tac `ts` \\ fs [])
    \\ fs [GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
    \\ fs [AC STAR_ASSOC STAR_COMM] \\ NO_TAC)
  \\ IF_CASES_TAC \\ simp [] (* v = 0 *)
  THEN1
   (rveq \\ full_simp_tac std_ss []
    \\ drule state_rel_with_clock_0
    \\ simp_tac (srw_ss()) [] \\ strip_tac
    \\ asm_exists_tac \\ asm_rewrite_tac [])
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ `FLOOKUP t2.store NextFree =
        SOME (Word (curr + bytes_in_word * n2w (heap_length ha))) /\
      curr + bytes_in_word + bytes_in_word * n2w (heap_length ha) ∈
         t2.mdomain /\
      t2.memory (curr + bytes_in_word +
         bytes_in_word * n2w (heap_length ha)) = Word (HD (SND (i2mw v)))` by
   (fs [GSYM TempOut_def]
    \\ qpat_x_assum `v <> 0` mp_tac
    \\ asm_rewrite_tac []
    \\ qpat_x_assum `state_rel _ _ _ _ _` mp_tac
    \\ rpt (pop_assum kall_tac)
    \\ rewrite_tac [word_bignumProofTheory.state_rel_def]
    \\ strip_tac
    \\ qpat_x_assum `array_rel _ _ _ _ _ _ _` mp_tac
    \\ qpat_x_assum `_ = _` mp_tac
    \\ rpt (pop_assum kall_tac)
    \\ fs [array_rel_def,APPLY_UPDATE_THM,FLOOKUP_UPDATE]
    \\ rpt (disch_then strip_assume_tac)
    \\ `?x xs. SND (i2mw v):'a word list = x::xs` by
     (fs [multiwordTheory.i2mw_def]
      \\ once_rewrite_tac [multiwordTheory.n2mw_def]
      \\ rw [] \\ intLib.COOPER_TAC)
    \\ fs [word_list_def] \\ SEP_R_TAC \\ fs [] \\ NO_TAC)
  \\ simp []
  \\ qpat_abbrev_tac `if_stmt = wordLang$If _ _ _ _ _`
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ Cases_on `small_int (:'a) v`
  THEN1
   (qunabbrev_tac `if_stmt` \\ fs [eq_eval]
    \\ IF_CASES_TAC THEN1
     (fs [num_exp_def,word_sh_def,lookup_insert]
      \\ `v1 >>> (dimindex (:α) - 3) = 0w /\
          v1 << 2 = Smallnum v` by1
       (ntac 2 (pop_assum mp_tac)
        \\ qpat_x_assum `good_dimindex (:'a)` mp_tac
        \\ rpt (pop_assum kall_tac)
        \\ fs [multiwordTheory.i2mw_def]
        \\ Cases_on `v` \\ fs [EVAL ``n2mw 0``]
        \\ once_rewrite_tac [multiwordTheory.n2mw_def]
        \\ IF_CASES_TAC \\ fs []
        \\ once_rewrite_tac [multiwordTheory.n2mw_def]
        \\ IF_CASES_TAC \\ fs [] \\ rw []
        \\ `Num (ABS (&n)) = n` by intLib.COOPER_TAC
        \\ fs [DIV_EQ_X,Smallnum_def,WORD_MUL_LSL,word_mul_n2w]
        \\ rewrite_tac [GSYM w2n_11,w2n_lsr]
        \\ fs [] \\ fs [DIV_EQ_X]
        \\ rfs [good_dimindex_def,small_int_def,dimword_def]
        \\ rfs [good_dimindex_def,small_int_def,dimword_def])
      \\ fs []
      \\ drule state_rel_with_clock_0
      \\ simp_tac (srw_ss()) [] \\ strip_tac
      \\ rpt_drule state_rel_Number_small_int
      \\ strip_tac \\ asm_exists_tac \\ asm_rewrite_tac [])
    \\ IF_CASES_TAC THEN1
     (fs [num_exp_def,word_sh_def,lookup_insert]
      \\ `(v1 + -1w) >>> (dimindex (:α) - 3) = 0w /\
          -1w * v1 << 2 = Smallnum v` by
       (ntac 3 (pop_assum mp_tac)
        \\ qpat_x_assum `good_dimindex (:'a)` mp_tac
        \\ rpt (pop_assum kall_tac)
        \\ fs [multiwordTheory.i2mw_def]
        \\ Cases_on `v` \\ fs [EVAL ``n2mw 0``]
        \\ `Num (ABS (-&n)) = n` by intLib.COOPER_TAC \\ fs []
        \\ once_rewrite_tac [multiwordTheory.n2mw_def]
        \\ IF_CASES_TAC \\ fs []
        \\ once_rewrite_tac [multiwordTheory.n2mw_def]
        \\ IF_CASES_TAC \\ fs [] \\ rw []
        \\ fs [DIV_EQ_X,Smallnum_def,WORD_MUL_LSL,word_mul_n2w]
        \\ rewrite_tac [GSYM (SIMP_CONV (srw_ss()) [] ``-w:'a word``)]
        \\ Cases_on `n` \\ fs [ADD1,GSYM word_add_n2w]
        \\ rewrite_tac [GSYM w2n_11,w2n_lsr]
        \\ fs [] \\ fs [DIV_EQ_X]
        \\ rfs [good_dimindex_def,small_int_def,dimword_def]
        \\ rfs [good_dimindex_def,small_int_def,dimword_def])
      \\ fs []
      \\ drule state_rel_with_clock_0
      \\ simp_tac (srw_ss()) [] \\ strip_tac
      \\ rpt_drule state_rel_Number_small_int
      \\ strip_tac \\ asm_exists_tac \\ asm_rewrite_tac [])
    \\ `F` by all_tac \\ fs []
    \\ rpt_drule i2mw_small_int_IMP_0)
  \\ qmatch_goalsub_abbrev_tac `evaluate (if_stmt,t8)`
  \\ `?w. evaluate (if_stmt,t8) = (NONE, set_var 5 w t8)` by
   (qunabbrev_tac `t8` \\ qunabbrev_tac `if_stmt`
    \\ simp [eq_eval,word_sh_def,num_exp_def]
    \\ IF_CASES_TAC \\ simp [] THEN1
     (full_simp_tac std_ss [HD]
      \\ reverse IF_CASES_TAC \\ full_simp_tac std_ss []
      \\ simp_tac (srw_ss()) [wordSemTheory.state_component_equality]
      THEN1 metis_tac []
      \\ ntac 3 (pop_assum mp_tac)
      \\ qpat_x_assum `good_dimindex _` mp_tac
      \\ rpt (pop_assum kall_tac)
      \\ fs [multiwordTheory.i2mw_def]
      \\ once_rewrite_tac [multiwordTheory.n2mw_def]
      \\ rw [] \\ rewrite_tac [GSYM w2n_11,w2n_lsr]
      \\ Cases_on `v`
      \\ fs [small_int_def,good_dimindex_def,dimword_def,multiwordTheory.n2mw_NIL]
      \\ fs [DIV_EQ_X] \\ rfs []
      \\ fs [intLib.COOPER_PROVE ``Num (ABS (&n)) = n``])
    \\ IF_CASES_TAC \\ fs [] THEN1
     (full_simp_tac std_ss [HD]
      \\ reverse IF_CASES_TAC \\ full_simp_tac std_ss []
      \\ simp_tac (srw_ss()) [wordSemTheory.state_component_equality]
      THEN1 metis_tac []
      \\ ntac 4 (pop_assum mp_tac)
      \\ qpat_x_assum `good_dimindex _` mp_tac
      \\ qpat_x_assum `v <> 0` mp_tac
      \\ rpt (pop_assum kall_tac)
      \\ Cases_on `v`
      \\ fs [multiwordTheory.i2mw_def] \\ rfs []
      \\ once_rewrite_tac [multiwordTheory.n2mw_def]
      \\ rw [] \\ rewrite_tac [GSYM w2n_11,w2n_lsr]
      \\ fs [intLib.COOPER_PROVE ``Num (ABS (-&n)) = n``,n2w_mod]
      \\ Cases_on `n` \\ fs [GSYM word_add_n2w,ADD1]
      \\ fs [small_int_def,good_dimindex_def,dimword_def,multiwordTheory.n2mw_NIL]
      \\ fs [DIV_EQ_X] \\ rfs [])
    \\ simp_tac (srw_ss()) [wordSemTheory.state_component_equality]
    \\ metis_tac [])
  \\ asm_rewrite_tac [] \\ pop_assum kall_tac
  \\ simp_tac (srw_ss()) [wordSemTheory.set_var_def,Abbr `t8`]
  \\ qunabbrev_tac `if_stmt`
  \\ qpat_x_assum `SOME _ = _` (assume_tac o GSYM)
  \\ once_rewrite_tac [list_Seq_def] \\ simp [eq_eval]
  \\ once_rewrite_tac [list_Seq_def] \\ simp [eq_eval]
  \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ simp [eq_eval]
  \\ once_rewrite_tac [list_Seq_def] \\ simp [eq_eval]
  \\ once_rewrite_tac [list_Seq_def] \\ simp [eq_eval]
  \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ simp [eq_eval]
  \\ qpat_x_assum `word_bignumProof$state_rel _ _ _ _ _` mp_tac
  \\ full_simp_tac std_ss [array_rel_def,word_bignumProofTheory.state_rel_def]
  \\ simp_tac (srw_ss()) [FLOOKUP_UPDATE,TempOut_def,APPLY_UPDATE_THM]
  \\ asm_simp_tac std_ss []
  \\ strip_tac
  \\ qpat_x_assum `!a v. _` kall_tac \\ fs [] \\ rveq
  \\ qpat_x_assum `_ (fun2set _)` mp_tac
  \\ rpt (qpat_x_assum `_ (fun2set _)` kall_tac)
  \\ qunabbrev_tac `my_frame`
  \\ strip_tac
  \\ once_rewrite_tac [list_Seq_def]
  \\ simp [eq_eval,wordSemTheory.mem_store_def]
  \\ SEP_R_TAC \\ simp_tac (srw_ss()) []
  \\ qmatch_goalsub_abbrev_tac `next_addr =+ Word new_header`
  \\ qabbrev_tac `m22 = t2.memory`
  \\ qabbrev_tac `dm22 = t2.mdomain`
  \\ SEP_W_TAC \\ qpat_x_assum `_ (fun2set _)` mp_tac
  \\ rpt (qpat_x_assum `_ (fun2set _)` kall_tac)
  \\ strip_tac
  \\ once_rewrite_tac [list_Seq_def] \\ simp [eq_eval]
  \\ once_rewrite_tac [list_Seq_def] \\ simp [eq_eval]
  \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ simp [eq_eval]
  \\ qmatch_goalsub_abbrev_tac `insert 1 (Word new_ret_val)`
  \\ once_rewrite_tac [list_Seq_def] \\ simp [eq_eval]
  \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ simp [eq_eval]
  \\ once_rewrite_tac [list_Seq_def] \\ simp [eq_eval,wordSemTheory.set_store_def]
  \\ once_rewrite_tac [list_Seq_def] \\ simp [eq_eval]
  \\ simp [state_rel_thm,lookup_def,EVAL ``join_env LN []``,FAPPLY_FUPDATE_THM]
  \\ rewrite_tac [CONJ_ASSOC]
  \\ qpat_x_assum `state_rel c r1 r2 _ _ _ _` mp_tac
  \\ fs [state_rel_thm,EVAL ``join_env LN []``]
  \\ strip_tac
  \\ rpt_drule IMP_memory_rel_bignum_alt
  \\ fs [Bignum_def]
  \\ CONV_TAC (DEPTH_CONV PairRules.PBETA_CONV)
  \\ simp_tac (srw_ss()) []
  \\ `mc_header (i2mw v:bool # 'a word list) >>> 1 =
      n2w (LENGTH (SND (i2mw v):'a word list))` by
   (rewrite_tac [GSYM w2n_11,w2n_lsr,multiwordTheory.i2mw_def,SND,
          mc_multiwordTheory.mc_header_def] \\ rw [word_add_n2w]
    \\ `(2 * LENGTH (n2mw (Num (ABS v)):'a word list) + 1) < dimword (:α)` by1
          fs [LENGTH_REPLICATE,X_LT_DIV,multiwordTheory.i2mw_def]
    \\ simp [DIV_MULT |> ONCE_REWRITE_RULE [MULT_COMM]]
    \\ simp [MULT_DIV |> ONCE_REWRITE_RULE [MULT_COMM]] \\ NO_TAC)
  \\ disch_then (qspecl_then [`SND (i2mw v):'a word list`,`new_header`] mp_tac)
  \\ impl_tac THEN1
   (fs [LENGTH_REPLICATE]
    \\ full_simp_tac std_ss [encode_header_def,multiwordTheory.i2mw_def]
    \\ qunabbrev_tac `new_header`
    \\ fs [make_header_def]
    \\ qmatch_goalsub_abbrev_tac `mc_header hh`
    \\ `(mc_header hh ≪ 4 && 1w ≪ 4) = (b2w (v < 0) ≪ 4):'a word` by
     (rewrite_tac [LSL_BITWISE] \\ AP_THM_TAC \\ AP_TERM_TAC
      \\ qunabbrev_tac `hh`
      \\ simp_tac std_ss [mc_multiwordTheory.mc_header_AND_1]
      \\ Cases_on `v < 0i` \\ asm_rewrite_tac [] \\ EVAL_TAC \\ NO_TAC)
    \\ asm_rewrite_tac []
    \\ reverse conj_tac THEN1 simp [WORD_MUL_LSL]
    \\ rpt strip_tac THEN1
     (match_mp_tac LESS_LESS_EQ_TRANS
      \\ qexists_tac `2 ** 3` \\ simp []
      \\ qpat_x_assum `good_dimindex _` mp_tac
      \\ rpt (pop_assum kall_tac)
      \\ Cases_on `v < 0i` \\ simp [] \\ EVAL_TAC
      \\ rw [] \\ fs [dimword_def])
    THEN1
     (qpat_x_assum `good_dimindex _` mp_tac
      \\ rpt (pop_assum kall_tac)
      \\ Cases_on `v < 0i` \\ simp [] \\ EVAL_TAC
      \\ rw [] \\ fs [dimword_def])
    \\ match_mp_tac LESS_EQ_LESS_TRANS
    \\ qexists_tac `2 ** c.len_size` \\ fs [])
  \\ fs [store_list_def] \\ strip_tac
  \\ `(next_addr =+ Word new_header) m22 = m1` by1
   (`next_addr + bytes_in_word =
     curr + bytes_in_word + bytes_in_word * n2w (heap_length ha)` by1
      (qunabbrev_tac `next_addr` \\ simp [])
    \\ full_simp_tac std_ss [word_list_APPEND,GSYM STAR_ASSOC]
    \\ drule word_list_IMP_store_list \\ fs [])
  \\ fs [] \\ pop_assum kall_tac
  \\ fs [shift_lsl]
  \\ fs [GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
  \\ pop_assum mp_tac
  \\ qpat_abbrev_tac `other_new_ret = make_ptr _ _ _ _`
  \\ `other_new_ret = Word new_ret_val` by1
   (qunabbrev_tac `other_new_ret`
    \\ qunabbrev_tac `new_ret_val`
    \\ fs [make_ptr_def])
  \\ fs [] \\ pop_assum kall_tac
  \\ strip_tac
  \\ drule memory_rel_zero_space
  \\ match_mp_tac memory_rel_rearrange
  \\ rpt (pop_assum kall_tac)
  \\ fs [] \\ rw [] \\ fs []);

val TWO_LESS_MustTerminate_limit = store_thm("TWO_LESS_MustTerminate_limit[simp]",
  ``2 < MustTerminate_limit (:α) /\
    ~(MustTerminate_limit (:α) <= 1)``,
  fs [wordSemTheory.MustTerminate_limit_def,dimword_def]
  \\ Cases_on `dimindex (:'a)` \\ fs [dimword_def,MULT_CLAUSES,EXP]
  \\ Cases_on `n` \\ fs [EXP] \\ Cases_on `2 ** n'` \\ fs []);

val Arith_location_def = Define `
  Arith_location index =
    if index = 0n then Add_location else
    if index = 1n then Sub_location else
    if index = 4n then Mul_location else
    if index = 5n then Div_location else
    if index = 6n then Mod_location else ARB`;

val push_env_code = store_thm("push_env_code",
  ``(push_env y NONE t).code = t.code``,
  fs [wordSemTheory.push_env_def] \\ pairarg_tac \\ fs []);

val Arith_code_def = Define `
  Arith_code index =
    Seq (Assign 6 (Const (n2w (4 * index))))
      (Call NONE (SOME AnyArith_location) [0; 2; 4; 6] NONE)`;

val lookup_Arith_location = prove(
  ``state_rel c l1 l2 x t [] locs /\ int_op index i1 i2 = SOME r ==>
    lookup (Arith_location index) t.code = SOME (3,Arith_code index)``,
  rw [] \\ drule lookup_RefByte_location
  \\ fs [int_op_def] \\ every_case_tac \\ fs []
  \\ fs [Arith_location_def] \\ rw [] \\ EVAL_TAC);

val eval_Call_Arith = prove(
  ``!index r.
      state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs /\
      names_opt ≠ NONE /\ 1 < t.termdep /\
      get_vars [a1; a2] x.locals = SOME [Number i1; Number i2] /\
      cut_state_opt names_opt s = SOME x /\
      int_op index i1 i2 = SOME r ==>
      ∃q r'.
        (λ(res,s1).
           if res = NONE then
             evaluate (list_Seq [Move 2 [(adjust_var dest,1)]],s1)
           else (res,s1))
          (evaluate
            (MustTerminate
              (Call (SOME (1,adjust_set (get_names names_opt),Skip,n,l))
                (SOME (Arith_location index))
                [adjust_var a1; adjust_var a2] NONE),t)) = (q,r') ∧
        (q = SOME NotEnoughSpace ⇒ r'.ffi = s.ffi) ∧
        (q ≠ SOME NotEnoughSpace ⇒
         state_rel c l1 l2
           (x with
            <|locals := insert dest (Number r) x.locals;
              global := x.global; refs := x.refs; clock := x.clock;
              ffi := s.ffi; space := 0|>) r' [] locs ∧ q = NONE)``,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ imp_res_tac state_rel_cut_IMP
  \\ Cases_on `names_opt` \\ fs []
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ `get_vars [a1; a2] s.locals = SOME [Number i1; Number i2]` by
   (fs [cut_state_opt_def,cut_state_def,cut_env_def]
    \\ every_case_tac \\ fs [get_vars_def,get_var_def]
    \\ every_case_tac \\ fs [get_vars_def,get_var_def]
    \\ fs [] \\ rveq \\ fs [lookup_inter_alt] \\ NO_TAC)
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_2] \\ clean_tac \\ fs [] \\ clean_tac
  \\ rename1 `get_vars [adjust_var a1; adjust_var a2] t = SOME [x1; x2]`
  \\ imp_res_tac get_vars_2_IMP
  \\ fs [wordSemTheory.get_vars_def]
  \\ rpt_drule lookup_Arith_location \\ fs [get_names_def]
  \\ fs [wordSemTheory.evaluate_def,list_Seq_def,word_exp_rw,
         wordSemTheory.find_code_def,wordSemTheory.set_var_def]
  \\ fs [wordSemTheory.add_ret_loc_def,wordSemTheory.find_code_def]
  \\ fs [wordSemTheory.bad_dest_args_def,wordSemTheory.get_vars_def,
         wordSemTheory.get_var_def,lookup_insert]
  \\ disch_then kall_tac
  \\ fs [cut_state_opt_def,cut_state_def]
  \\ rename1 `state_rel c l1 l2 s1 t [] locs`
  \\ Cases_on `dataSem$cut_env x' s.locals` \\ fs []
  \\ clean_tac \\ fs []
  \\ qabbrev_tac `s1 = s with locals := x`
  \\ `?y. cut_env (adjust_set x') t.locals = SOME y` by
       (match_mp_tac (GEN_ALL cut_env_IMP_cut_env) \\ fs []
        \\ metis_tac []) \\ fs []
  \\ fs [wordSemTheory.dec_clock_def,EVAL ``(data_to_bvi s).refs``]
  \\ fs [Arith_code_def]
  \\ drule lookup_RefByte_location \\ fs [get_names_def]
  \\ fs [wordSemTheory.evaluate_def,list_Seq_def,word_exp_rw,push_env_code,
         wordSemTheory.find_code_def,wordSemTheory.set_var_def]
  \\ fs [wordSemTheory.add_ret_loc_def,wordSemTheory.find_code_def]
  \\ fs [wordSemTheory.bad_dest_args_def,wordSemTheory.get_vars_def,fromList2_def,
         wordSemTheory.get_var_def,lookup_insert,
         wordSemTheory.call_env_def,push_env_code]
  \\ disch_then kall_tac
  \\ Q.MATCH_GOALSUB_ABBREV_TAC `evaluate (AnyArith_code c,t4)` \\ rveq
  \\ `state_rel c l1 l2 (s1 with clock := MustTerminate_limit(:'a)-1)
        (t with <| clock := MustTerminate_limit(:'a)-1; termdep := t.termdep - 1 |>)
          [] locs` by (fs [state_rel_def] \\ asm_exists_tac \\ fs [] \\ NO_TAC)
  \\ rpt_drule state_rel_call_env_push_env \\ fs []
  \\ `dataSem$get_vars [a1; a2] s.locals = SOME [Number i1; Number i2]` by
    (fs [dataSemTheory.get_vars_def] \\ every_case_tac \\ fs [cut_env_def]
     \\ clean_tac \\ fs [lookup_inter_alt,get_var_def] \\ NO_TAC)
  \\ `s1.locals = x` by (unabbrev_all_tac \\ fs []) \\ fs []
  \\ disch_then drule \\ fs []
  \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def]
  \\ `dataSem$cut_env x' s1.locals = SOME s1.locals` by
   (unabbrev_all_tac \\ fs []
    \\ fs [cut_env_def] \\ clean_tac
    \\ fs [domain_inter] \\ fs [lookup_inter_alt] \\ NO_TAC)
  \\ fs [] \\ rfs []
  \\ disch_then drule \\ fs []
  \\ disch_then (qspecl_then [`n`,`l`,`NONE`] mp_tac) \\ fs []
  \\ strip_tac
  \\ `index < 7` by (fs [int_op_def] \\ every_case_tac \\ fs [] \\ NO_TAC)
  \\ `index < dimword (:'a) DIV 16` by
        (fs [labPropsTheory.good_dimindex_def,dimword_def,state_rel_def] \\ NO_TAC)
  \\ rpt_drule state_rel_IMP_Number_arg
  \\ strip_tac
  \\ rpt_drule AnyArith_thm
  \\ simp [Once call_env_def,wordSemTheory.dec_clock_def,do_app_def,
           get_vars_def,get_var_def,lookup_insert,fromList_def,push_env_termdep,
           do_space_def,bvi_to_dataTheory.op_space_reset_def,fromList2_def,
           bviSemTheory.do_app_def,do_app,call_env_def,wordSemTheory.call_env_def]
  \\ disch_then (qspecl_then [`l2`,`l1`] strip_assume_tac)
  \\ qmatch_assum_abbrev_tac `evaluate (AnyArith_code c,t5) = _`
  \\ `t5 = t4` by
   (unabbrev_all_tac \\ fs [wordSemTheory.call_env_def,
       wordSemTheory.push_env_def,wordSemTheory.dec_clock_def]
    \\ pairarg_tac \\ fs [] \\ NO_TAC)
  \\ fs [] \\ Cases_on `q = SOME NotEnoughSpace` THEN1 fs [] \\ fs []
  \\ rpt_drule state_rel_pop_env_IMP
  \\ simp [push_env_def,call_env_def,pop_env_def,dataSemTheory.dec_clock_def,
       Once dataSemTheory.bvi_to_data_def]
  \\ strip_tac \\ fs [] \\ clean_tac
  \\ `domain t2.locals = domain y` by
   (qspecl_then [`AnyArith_code c`,`t4`] mp_tac
         (wordPropsTheory.evaluate_stack_swap
            |> INST_TYPE [``:'b``|->``:'ffi``])
    \\ fs [] \\ fs [wordSemTheory.pop_env_def,wordSemTheory.dec_clock_def]
    \\ Cases_on `r''.stack` \\ fs [] \\ Cases_on `h` \\ fs []
    \\ rename1 `r2.stack = StackFrame ns opt::t'`
    \\ unabbrev_all_tac
    \\ fs [wordSemTheory.call_env_def,wordSemTheory.push_env_def]
    \\ pairarg_tac \\ Cases_on `opt`
    \\ fs [wordPropsTheory.s_key_eq_def,
          wordPropsTheory.s_frame_key_eq_def]
    \\ rw [] \\ drule env_to_list_lookup_equiv
    \\ fs [EXTENSION,domain_lookup,lookup_fromAList]
    \\ fs[GSYM IS_SOME_EXISTS]
    \\ imp_res_tac MAP_FST_EQ_IMP_IS_SOME_ALOOKUP \\ metis_tac []) \\ fs []
  \\ pop_assum mp_tac
  \\ pop_assum mp_tac
  \\ simp [state_rel_def]
  \\ fs [bviSemTheory.bvl_to_bvi_def,
         bviSemTheory.bvi_to_bvl_def,
         dataSemTheory.bvi_to_data_def,
         dataSemTheory.call_env_def,alist_insert_def,
         dataSemTheory.data_to_bvi_def,push_env_def,
         dataSemTheory.set_var_def,wordSemTheory.set_vars_def]
  \\ fs [wordSemTheory.pop_env_def]
  \\ `t.clock = s.clock` by fs [state_rel_def] \\ fs []
  \\ unabbrev_all_tac \\ fs []
  \\ rpt (disch_then strip_assume_tac) \\ clean_tac \\ fs []
  \\ strip_tac THEN1
   (fs [lookup_insert,stack_rel_def,state_rel_def,contains_loc_def,
        wordSemTheory.pop_env_def] \\ rfs[] \\ clean_tac
    \\ every_case_tac \\ fs [] \\ clean_tac \\ fs [lookup_fromAList]
    \\ fs [wordSemTheory.push_env_def]
    \\ pairarg_tac \\ fs []
    \\ drule env_to_list_lookup_equiv
    \\ fs[contains_loc_def])
  \\ conj_tac THEN1 (fs [lookup_insert,adjust_var_11] \\ rw [])
  \\ asm_exists_tac \\ fs []
  \\ fs [inter_insert_ODD_adjust_set]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac word_ml_inv_insert \\ fs [flat_def]
  \\ first_x_assum (fn th => mp_tac th \\ match_mp_tac word_ml_inv_rearrange)
  \\ fs[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]);

val eval_Call_Add = Q.SPEC `0` eval_Call_Arith
  |> SIMP_RULE std_ss [int_op_def,Arith_location_def]

val eval_Call_Sub = Q.SPEC `1` eval_Call_Arith
  |> SIMP_RULE std_ss [int_op_def,Arith_location_def]

val eval_Call_Mul = Q.SPEC `4` eval_Call_Arith
  |> SIMP_RULE std_ss [int_op_def,Arith_location_def]

val eval_Call_Div = Q.SPEC `5` eval_Call_Arith
  |> SIMP_RULE std_ss [int_op_def,Arith_location_def]

val eval_Call_Mod = Q.SPEC `6` eval_Call_Arith
  |> SIMP_RULE std_ss [int_op_def,Arith_location_def]

val th = Q.store_thm("assign_Add",
  `op = Add ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [EVAL ``op_requires_names Add``]
  \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs [] \\ rveq
  \\ rename1 `get_vars args x.locals = SOME [Number i1; Number i2]`
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_2] \\ clean_tac
  \\ fs [get_var_def]
  \\ qpat_x_assum `state_rel c l1 l2 x t [] locs` (fn th => NTAC 2 (mp_tac th))
  \\ strip_tac
  \\ simp_tac std_ss [Once state_rel_thm] \\ strip_tac \\ fs [] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac \\ fs []
  \\ rpt_drule memory_rel_Number_IMP_Word_2
  \\ strip_tac \\ clean_tac
  \\ rpt_drule memory_rel_Add \\ fs [] \\ strip_tac
  \\ fs [assign_def,Once list_Seq_def]
  \\ imp_res_tac get_vars_2_imp
  \\ eval_tac \\ fs [wordSemTheory.inst_def]
  \\ fs [assign_def,Once list_Seq_def]
  \\ eval_tac \\ fs [lookup_insert,wordSemTheory.get_var_def]
  \\ qabbrev_tac `mt = MustTerminate`
  \\ fs [assign_def,Once list_Seq_def]
  \\ eval_tac \\ fs [lookup_insert,wordSemTheory.get_var_def,
                     wordSemTheory.get_var_imm_def]
  \\ fs [word_cmp_Test_1,word_bit_or,word_bit_if_1_0]
  \\ IF_CASES_TAC THEN1
   (fs [list_Seq_def,state_rel_thm] \\ eval_tac
    \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def,lookup_insert,
           wordSemTheory.set_vars_def,wordSemTheory.set_var_def,alist_insert_def]
    \\ conj_tac THEN1 rw []
    \\ fs [lookup_insert,adjust_var_NEQ,adjust_var_11]
    \\ fs [inter_insert_ODD_adjust_set]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
    \\ drule memory_rel_zero_space \\ fs [])
  \\ unabbrev_all_tac
  \\ match_mp_tac eval_Call_Add
  \\ fs [state_rel_insert_3_1]);

val th = Q.store_thm("assign_Sub",
  `op = Sub ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [EVAL ``op_requires_names Sub``]
  \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs [] \\ rveq
  \\ rename1 `get_vars args x.locals = SOME [Number i1; Number i2]`
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_2] \\ clean_tac
  \\ fs [get_var_def]
  \\ qpat_x_assum `state_rel c l1 l2 x t [] locs` (fn th => NTAC 2 (mp_tac th))
  \\ strip_tac
  \\ simp_tac std_ss [Once state_rel_thm] \\ strip_tac \\ fs [] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac \\ fs []
  \\ rpt_drule memory_rel_Number_IMP_Word_2
  \\ strip_tac \\ clean_tac
  \\ rpt_drule memory_rel_Sub \\ fs [] \\ strip_tac
  \\ fs [assign_def,Once list_Seq_def]
  \\ imp_res_tac get_vars_2_imp
  \\ eval_tac \\ fs [wordSemTheory.inst_def]
  \\ fs [assign_def,Once list_Seq_def]
  \\ eval_tac \\ fs [lookup_insert,wordSemTheory.get_var_def]
  \\ qabbrev_tac `mt = MustTerminate`
  \\ fs [assign_def,Once list_Seq_def]
  \\ eval_tac \\ fs [lookup_insert,wordSemTheory.get_var_def,
                     wordSemTheory.get_var_imm_def]
  \\ fs [word_cmp_Test_1,word_bit_or,word_bit_if_1_0]
  \\ IF_CASES_TAC THEN1
   (fs [list_Seq_def,state_rel_thm] \\ eval_tac
    \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def,lookup_insert,
           wordSemTheory.set_vars_def,wordSemTheory.set_var_def,alist_insert_def]
    \\ conj_tac THEN1 rw []
    \\ fs [lookup_insert,adjust_var_NEQ,adjust_var_11]
    \\ fs [inter_insert_ODD_adjust_set]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
    \\ drule memory_rel_zero_space \\ fs [])
  \\ unabbrev_all_tac
  \\ match_mp_tac eval_Call_Sub
  \\ fs [state_rel_insert_3_1]);

val cut_state_opt_IMP_ffi = store_thm("cut_state_opt_IMP_ffi",
  ``dataSem$cut_state_opt names_opt s = SOME x ==> x.ffi = s.ffi``,
  fs [dataSemTheory.cut_state_opt_def,dataSemTheory.cut_state_def]
  \\ every_case_tac \\ fs [] \\ rw [] \\ fs []);

val th = Q.store_thm("assign_Mult",
  `op = Mult ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [EVAL ``op_requires_names Mult``]
  \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs [] \\ rveq
  \\ rename1 `get_vars args x.locals = SOME [Number i1; Number i2]`
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_2] \\ clean_tac
  \\ fs [assign_def]
  \\ fs [get_vars_SOME_IFF,get_vars_SOME_IFF_data]
  \\ pop_assum kall_tac
  \\ `(?w1. a1' = Word w1) /\ (?w2. a2' = Word w2)` by
         metis_tac [state_rel_get_var_Number_IMP_alt,adjust_var_def]
  \\ rveq \\ fs []
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ fs [eq_eval]
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval,wordSemTheory.inst_def]
  \\ `n2w (w2n w2 * w2n (w1 ⋙ 1)) = FST (single_mul w2 (w1 >>> 1) 0w) /\
      n2w (w2n w2 * w2n (w1 ⋙ 1) DIV dimword (:α)) =
        SND (single_mul w2 (w1 >>> 1) 0w)` by
    (fs [multiwordTheory.single_mul_def,GSYM word_mul_n2w] \\ NO_TAC) \\ fs []
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ fs [eq_eval]
  \\ rewrite_tac [list_Seq_def]
  \\ once_rewrite_tac [``list_Seq [MustTerminate x]``
       |> REWRITE_CONV [list_Seq_def] |> GSYM]
  \\ once_rewrite_tac [wordSemTheory.evaluate_def]
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ fs [wordSemTheory.get_var_def,wordSemTheory.get_var_imm_def,lookup_insert,
         asmTheory.word_cmp_def]
  \\ IF_CASES_TAC \\ fs []
  THEN1
   (fs [eq_eval,wordSemTheory.set_vars_def,alist_insert_def]
    \\ fs [bviSemTheory.bvl_to_bvi_def,
         bviSemTheory.bvi_to_bvl_def,
         dataSemTheory.bvi_to_data_def,
         dataSemTheory.call_env_def,alist_insert_def,
         dataSemTheory.data_to_bvi_def,push_env_def,
         dataSemTheory.set_var_def,wordSemTheory.set_vars_def]
    \\ fs [state_rel_thm,lookup_insert,adjust_var_11]
    \\ conj_tac THEN1 (rw [] \\ fs [])
    \\ fs [inter_insert_ODD_adjust_set]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert
    \\ fs [APPEND]
    \\ once_rewrite_tac [integerTheory.INT_MUL_COMM]
    \\ match_mp_tac (memory_rel_Number_single_mul
        |> SIMP_RULE std_ss [LET_THM,AND_IMP_INTRO]
        |> CONV_RULE (DEPTH_CONV PairRules.PBETA_CONV)
        |> SIMP_RULE std_ss [LET_THM,AND_IMP_INTRO])
    \\ fs []
    \\ imp_res_tac memory_rel_zero_space \\ fs []
    \\ pop_assum kall_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule memory_rel_get_vars_IMP
    \\ disch_then (qspecl_then [`[Number i2; Number i1]`,
         `[Word w2; Word w1]`,`[a2;a1]`] mp_tac)
    \\ reverse impl_tac THEN1 fs []
    \\ fs [get_vars_SOME_IFF,wordSemTheory.get_var_def,get_vars_def])
  \\ rewrite_tac [list_Seq_def]
  \\ fs [bviSemTheory.bvl_to_bvi_def,
         bviSemTheory.bvi_to_bvl_def,
         dataSemTheory.bvi_to_data_def,
         dataSemTheory.call_env_def,alist_insert_def,
         dataSemTheory.data_to_bvi_def,push_env_def,
         dataSemTheory.set_var_def,wordSemTheory.set_vars_def]
  \\ imp_res_tac cut_state_opt_IMP_ffi \\ fs []
  \\ match_mp_tac (eval_Call_Mul |> REWRITE_RULE [list_Seq_def])
  \\ fs []
  \\ fs [get_vars_def,get_var_def]
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` mp_tac
  \\ fs [state_rel_thm,lookup_insert]
  \\ fs [inter_insert_ODD_adjust_set_alt]);

val word_bit_test_0 = prove(
  ``(1w && w) = 0w <=> ~word_bit 0 w``,
  fs [word_bit_test]);

val word_bit_lsr_dimindex_1 = store_thm("word_bit_lsr_dimindex_1",
  ``word_bit 0 ((w1 ⋙ (dimindex (:'a) − 1)):'a word) <=> word_msb w1``,
  fs [word_bit_def,word_lsr_def,fcpTheory.FCP_BETA,word_msb_def]);

val state_rel_Number_IMP = store_thm("state_rel_Number_IMP",
  ``state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs /\
    get_var a1 s.locals = SOME (Number i1) /\
    lookup (adjust_var a1) t.locals = SOME v1 ==>
    ?w1. (v1 = Word w1) /\
         (~(word_bit 0 w1) <=> small_int (:'a) i1) /\
         (~(word_msb w1) /\ ~(word_bit 0 w1) ==> 0 <= i1 /\ w1 = n2w (4 * Num i1))``,
  fs [state_rel_thm] \\ rw []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
  \\ drule (GEN_ALL memory_rel_get_var_IMP)
  \\ disch_then (qspec_then `a1` mp_tac)
  \\ fs [get_var_def,wordSemTheory.get_var_def]
  \\ rw [] \\ rpt_drule memory_rel_any_Number_IMP \\ rw [] \\ fs []
  \\ fs [word_bit_def] \\ strip_tac
  \\ imp_res_tac memory_rel_Number_IMP \\ fs [] \\ rveq
  \\ rpt_drule memory_rel_Number_word_msb \\ fs []
  \\ Cases_on `i1` \\ fs [Smallnum_def]);

val memory_rel_Temp = store_thm("memory_rel_Temp[simp]",
  ``memory_rel c be refs sp (st |+ (Temp i,w)) m dm vars <=>
    memory_rel c be refs sp st m dm vars``,
  fs [memory_rel_def,heap_in_memory_store_def,FLOOKUP_UPDATE]);

val th = Q.store_thm("assign_Div",
  `op = Div ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [EVAL ``op_requires_names Div``]
  \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs [] \\ rveq
  \\ rename1 `get_vars args x.locals = SOME [Number i1; Number i2]`
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_2] \\ clean_tac
  \\ fs [assign_def]
  \\ fs [get_vars_SOME_IFF]
  \\ fs [get_vars_SOME_IFF_data]
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ rename1 `lookup (adjust_var a1) t.locals = SOME v1`
  \\ rename1 `lookup (adjust_var a2) t.locals = SOME v2`
  \\ `?w1. v1 = Word w1 /\
        (~(word_bit 0 w1) <=> small_int (:'a) i1) /\
        (~(word_msb w1) /\ ~(word_bit 0 w1) ==> 0 <= i1 /\ w1 = n2w (4 * Num i1))` by1
          (metis_tac [state_rel_Number_IMP])
  \\ `?w2. v2 = Word w2 /\
        (~(word_bit 0 w2) <=> small_int (:'a) i2) /\
        (~(word_msb w2) /\ ~(word_bit 0 w2) ==> 0 <= i2 /\ w2 = n2w (4 * Num i2))` by1
          (metis_tac [state_rel_Number_IMP])
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ fs [eq_eval]
  \\ simp [word_bit_test_0]
  \\ IF_CASES_TAC THEN1
   (fs [word_bit_or,word_bit_lsr_dimindex_1] \\ rveq
    \\ `?n1. i1 = & n1` by (Cases_on `i1` \\ fs [])
    \\ `?n2. i2 = & n2` by (Cases_on `i2` \\ fs [])
    \\ fs [] \\ rveq
    \\ `4 * n2 < dimword (:'a) /\ 4 * n1 < dimword (:'a)` by1
          fs [small_int_def,X_LT_DIV]
    \\ `n2w (4 * n2) <> 0w` by1 fs []
    \\ `small_int (:α) (&(n1 DIV n2))` by1
     (fs [small_int_def,DIV_LT_X]
      \\ rfs [good_dimindex_def,state_rel_thm,dimword_def] \\ rfs [])
    \\ Cases_on `c.has_div` \\ fs [] THEN1
     (fs [list_Seq_def,eq_eval,wordSemTheory.inst_def,insert_shadow]
      \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ fs [eq_eval]
      \\ fs [state_rel_thm,bviSemTheory.bvl_to_bvi_def,adjust_var_11,
           bviSemTheory.bvi_to_bvl_def,lookup_insert,
           dataSemTheory.bvi_to_data_def,
           dataSemTheory.call_env_def,alist_insert_def,
           dataSemTheory.data_to_bvi_def,push_env_def,
           dataSemTheory.set_var_def,wordSemTheory.set_vars_def]
      \\ conj_tac THEN1 (rw [] \\ fs [])
      \\ fs [inter_insert_ODD_adjust_set]
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
      \\ `(n2w (4 * n1) / n2w (4 * n2)) ≪ 2 = Smallnum (&(n1 DIV n2))` by
       (fs [wordsTheory.word_sdiv_def,word_div_def,Smallnum_def]
        \\ fs [WORD_MUL_LSL,word_mul_n2w,GSYM DIV_DIV_DIV_MULT,
               MULT_DIV |> ONCE_REWRITE_RULE [MULT_COMM]])
      \\ fs [] \\ match_mp_tac IMP_memory_rel_Number \\ fs []
      \\ imp_res_tac memory_rel_zero_space \\ fs [])
    \\ Cases_on `c.has_longdiv` \\ fs [] THEN1
     (fs [list_Seq_def,eq_eval,wordSemTheory.inst_def,insert_shadow]
      \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ fs [eq_eval]
      \\ reverse IF_CASES_TAC THEN1
       (`F` by all_tac \\ rfs [DIV_LT_X]
        \\ pop_assum mp_tac
        \\ Cases_on `n2` \\ fs [MULT_CLAUSES])
      \\ fs [state_rel_thm,bviSemTheory.bvl_to_bvi_def,adjust_var_11,
           bviSemTheory.bvi_to_bvl_def,lookup_insert,
           dataSemTheory.bvi_to_data_def,
           dataSemTheory.call_env_def,alist_insert_def,
           dataSemTheory.data_to_bvi_def,push_env_def,
           dataSemTheory.set_var_def,wordSemTheory.set_vars_def]
      \\ conj_tac THEN1 (rw [] \\ fs [])
      \\ fs [inter_insert_ODD_adjust_set]
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
      \\ `n2w (4 * n1 DIV (4 * n2)) ≪ 2 = Smallnum (&(n1 DIV n2))` by
       (fs [wordsTheory.word_sdiv_def,word_div_def,Smallnum_def]
        \\ fs [WORD_MUL_LSL,word_mul_n2w,GSYM DIV_DIV_DIV_MULT,
               MULT_DIV |> ONCE_REWRITE_RULE [MULT_COMM]] \\ NO_TAC)
      \\ fs [] \\ match_mp_tac IMP_memory_rel_Number \\ fs []
      \\ imp_res_tac memory_rel_zero_space \\ fs [])
    \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
    \\ once_rewrite_tac [list_Seq_def] \\ fs []
    \\ once_rewrite_tac [wordSemTheory.evaluate_def]
    \\ rewrite_tac [insert_shadow]
    \\ qpat_x_assum `state_rel c l1 l2 x t [] locs`
          (mp_tac o REWRITE_RULE [state_rel_thm])
    \\ fs [] \\ strip_tac
    \\ fs [eq_eval,code_rel_def,stubs_def,cut_env_adjust_set_insert_1]
    \\ Cases_on `names_opt` \\ fs [cut_state_opt_def,cut_state_def]
    \\ Cases_on `dataSem$cut_env x' s.locals` \\ fs []
    \\ imp_res_tac cut_env_IMP_cut_env
    \\ fs [get_names_def,wordSemTheory.push_env_def]
    \\ Cases_on `env_to_list y t.permute` \\ fs []
    \\ qmatch_goalsub_abbrev_tac `evaluate (LongDiv_code c,t2)`
    \\ qspecl_then [`t2`,`n`,`l+1`,`c`] mp_tac evaluate_LongDiv_code
    \\ fs [] \\ disch_then (qspecl_then [`0w`,`n2w (4 * n1)`,`n2w (4 * n2)`] mp_tac)
    \\ fs [multiwordTheory.single_div_def]
    \\ impl_tac THEN1
     (unabbrev_all_tac
      \\ fs [lookup_insert,wordSemTheory.MustTerminate_limit_def,
             mc_multiwordTheory.single_div_pre_def]
      \\ fs [DIV_LT_X] \\ Cases_on `n2` \\ fs [MULT_CLAUSES])
    \\ strip_tac \\ fs []
    \\ fs [wordSemTheory.pop_env_def,Abbr `t2`]
    \\ reverse IF_CASES_TAC THEN1
     (`F` by all_tac \\ fs [] \\ pop_assum mp_tac \\ fs []
      \\ drule env_to_list_lookup_equiv
      \\ fs [domain_lookup,EXTENSION,lookup_fromAList])
    \\ fs [list_Seq_def,eq_eval]
    \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ fs [lookup_insert]
    \\ fs [state_rel_thm,bviSemTheory.bvl_to_bvi_def,
         bviSemTheory.bvi_to_bvl_def,lookup_insert,
         dataSemTheory.bvi_to_data_def,adjust_var_11,
         dataSemTheory.call_env_def,alist_insert_def,
         dataSemTheory.data_to_bvi_def,push_env_def,
         dataSemTheory.set_var_def,wordSemTheory.set_vars_def]
    \\ rveq \\ fs []
    \\ conj_tac THEN1
     (drule env_to_list_lookup_equiv \\ fs []
      \\ drule cut_env_adjust_set_lookup_0 \\ fs [lookup_fromAList])
    \\ conj_tac THEN1
     (rw [] \\ fs []
      \\ drule env_to_list_lookup_equiv \\ fs []
      \\ drule cut_env_IMP_MEM \\ fs [lookup_fromAList]
      \\ drule (GEN_ALL adjust_var_cut_env_IMP_MEM) \\ fs []
      \\ drule (GEN_ALL cut_env_IMP_MEM) \\ fs []
      \\ strip_tac \\ fs [])
    \\ fs [inter_insert_ODD_adjust_set]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert
    \\ fs [FAPPLY_FUPDATE_THM,memory_rel_Temp]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
    \\ `n2w (4 * n1 DIV (4 * n2)) ≪ 2 = Smallnum (&(n1 DIV n2))` by
       (fs [wordsTheory.word_sdiv_def,word_div_def,Smallnum_def]
        \\ fs [WORD_MUL_LSL,word_mul_n2w,GSYM DIV_DIV_DIV_MULT,
               MULT_DIV |> ONCE_REWRITE_RULE [MULT_COMM]] \\ NO_TAC)
    \\ fs [] \\ match_mp_tac IMP_memory_rel_Number \\ fs []
    \\ imp_res_tac memory_rel_zero_space \\ fs [APPEND]
    \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac memory_rel_rearrange)
    \\ fs [] \\ rw [] \\ fs [] \\ disj1_tac
    \\ fs [join_env_def,MEM_MAP,MEM_FILTER]
    \\ Cases_on `y'` \\ fs []
    \\ rename1 `MEM (y1,y2) _`
    \\ qexists_tac `(y1,y2)` \\ fs [MEM_toAList]
    \\ fs [lookup_inter_alt]
    \\ fs [cut_env_def,wordSemTheory.cut_env_def] \\ rveq
    \\ fs [domain_lookup] \\ rfs [lookup_adjust_set]
    \\ fs [domain_lookup,lookup_inter_alt]
    \\ drule env_to_list_lookup_equiv
    \\ fs [lookup_fromAList] \\ strip_tac \\ fs [] \\ fs [lookup_inter_alt])
  \\ pop_assum kall_tac
  \\ fs [list_Seq_def]
  \\ once_rewrite_tac [wordSemTheory.evaluate_def] \\ fs []
  \\ fs [bviSemTheory.bvl_to_bvi_def,
         bviSemTheory.bvi_to_bvl_def,
         dataSemTheory.bvi_to_data_def,
         dataSemTheory.call_env_def,alist_insert_def,
         dataSemTheory.data_to_bvi_def,push_env_def,
         dataSemTheory.set_var_def,wordSemTheory.set_vars_def]
  \\ imp_res_tac cut_state_opt_IMP_ffi \\ fs []
  \\ match_mp_tac (eval_Call_Div |> REWRITE_RULE [list_Seq_def])
  \\ fs [get_vars_SOME_IFF_data,insert_shadow]
  \\ fs [GSYM wordSemTheory.set_var_def]
  \\ fs [wordSemTheory.set_var_def,state_rel_insert_1]);

val th = Q.store_thm("assign_Mod",
  `op = Mod ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [EVAL ``op_requires_names Mod``]
  \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs [] \\ rveq
  \\ rename1 `get_vars args x.locals = SOME [Number i1; Number i2]`
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_2] \\ clean_tac
  \\ fs [assign_def]
  \\ fs [get_vars_SOME_IFF]
  \\ fs [get_vars_SOME_IFF_data]
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ rename1 `lookup (adjust_var a1) t.locals = SOME v1`
  \\ rename1 `lookup (adjust_var a2) t.locals = SOME v2`
  \\ `?w1. v1 = Word w1 /\
        (~(word_bit 0 w1) <=> small_int (:'a) i1) /\
        (~(word_msb w1) /\ ~(word_bit 0 w1) ==> 0 <= i1 /\ w1 = n2w (4 * Num i1))` by1
          (metis_tac [state_rel_Number_IMP])
  \\ `?w2. v2 = Word w2 /\
        (~(word_bit 0 w2) <=> small_int (:'a) i2) /\
        (~(word_msb w2) /\ ~(word_bit 0 w2) ==> 0 <= i2 /\ w2 = n2w (4 * Num i2))` by1
          (metis_tac [state_rel_Number_IMP])
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
  \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ fs [eq_eval]
  \\ simp [word_bit_test_0]
  \\ IF_CASES_TAC THEN1
   (fs [word_bit_or,word_bit_lsr_dimindex_1] \\ rveq
    \\ `?n1. i1 = & n1` by (Cases_on `i1` \\ fs [])
    \\ `?n2. i2 = & n2` by (Cases_on `i2` \\ fs [])
    \\ fs [] \\ rveq
    \\ `4 * n2 < dimword (:'a) /\ 4 * n1 < dimword (:'a)` by1
          fs [small_int_def,X_LT_DIV]
    \\ `n2w (4 * n2) <> 0w` by1 fs []
    \\ `small_int (:α) (&(n1 MOD n2))` by
     (fs [small_int_def,DIV_LT_X]
      \\ match_mp_tac LESS_TRANS
      \\ qexists_tac `n2` \\ fs [])
    \\ Cases_on `c.has_div` \\ fs [] THEN1
     (fs [list_Seq_def,eq_eval,wordSemTheory.inst_def,insert_shadow]
      \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ fs [eq_eval]
      \\ fs [state_rel_thm,bviSemTheory.bvl_to_bvi_def,adjust_var_11,
           bviSemTheory.bvi_to_bvl_def,lookup_insert,
           dataSemTheory.bvi_to_data_def,
           dataSemTheory.call_env_def,alist_insert_def,
           dataSemTheory.data_to_bvi_def,push_env_def,
           dataSemTheory.set_var_def,wordSemTheory.set_vars_def]
      \\ conj_tac THEN1 (rw [] \\ fs [])
      \\ fs [inter_insert_ODD_adjust_set]
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
      \\ `(n2w (4 * n1) / n2w (4 * n2)) = n2w (n1 DIV n2)` by
       (fs [wordsTheory.word_sdiv_def,word_div_def,Smallnum_def]
        \\ fs [WORD_MUL_LSL,word_mul_n2w,GSYM DIV_DIV_DIV_MULT,
               MULT_DIV |> ONCE_REWRITE_RULE [MULT_COMM]])
      \\ fs [] \\ qmatch_goalsub_abbrev_tac `Word ww`
      \\ qsuff_tac `ww = Smallnum (&(n1 MOD n2))`
      THEN1 (rw [] \\ match_mp_tac IMP_memory_rel_Number \\ fs []
             \\ imp_res_tac memory_rel_zero_space \\ fs [])
      \\ fs [Abbr`ww`,Smallnum_def]
      \\ `(n1 DIV n2) < dimword (:α)` by
        (fs [DIV_LT_X] \\Cases_on `n2` \\ fs [MULT_CLAUSES] \\ NO_TAC)
      \\ fs [WORD_EQ_SUB_RADD |> SIMP_RULE (srw_ss()) []]
      \\ rewrite_tac [word_add_n2w] \\ AP_TERM_TAC
      \\ rewrite_tac [GSYM LEFT_ADD_DISTRIB] \\ AP_TERM_TAC
      \\ `0 < n2` by fs []
      \\ drule DIVISION
      \\ disch_then (qspec_then `n1` (fn th => simp [Once th])))
    \\ Cases_on `c.has_longdiv` \\ fs [] THEN1
     (fs [list_Seq_def,eq_eval,wordSemTheory.inst_def,insert_shadow]
      \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ fs [eq_eval]
      \\ reverse IF_CASES_TAC THEN1
       (`F` by all_tac \\ rfs [DIV_LT_X]
        \\ pop_assum mp_tac
        \\ Cases_on `n2` \\ fs [MULT_CLAUSES])
      \\ fs [state_rel_thm,bviSemTheory.bvl_to_bvi_def,adjust_var_11,
           bviSemTheory.bvi_to_bvl_def,lookup_insert,
           dataSemTheory.bvi_to_data_def,
           dataSemTheory.call_env_def,alist_insert_def,
           dataSemTheory.data_to_bvi_def,push_env_def,
           dataSemTheory.set_var_def,wordSemTheory.set_vars_def]
      \\ conj_tac THEN1 (rw [] \\ fs [])
      \\ fs [inter_insert_ODD_adjust_set]
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
      \\ `n2w ((4 * n1) MOD (4 * n2)) = Smallnum (&(n1 MOD n2))` by
       (fs [wordsTheory.word_sdiv_def,word_div_def,Smallnum_def]
        \\ fs [MOD_COMMON_FACTOR] \\ NO_TAC)
      \\ fs [] \\ match_mp_tac IMP_memory_rel_Number \\ fs []
      \\ imp_res_tac memory_rel_zero_space \\ fs [])
    \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
    \\ once_rewrite_tac [list_Seq_def] \\ fs []
    \\ once_rewrite_tac [wordSemTheory.evaluate_def]
    \\ rewrite_tac [insert_shadow]
    \\ qpat_x_assum `state_rel c l1 l2 x t [] locs`
          (mp_tac o REWRITE_RULE [state_rel_thm])
    \\ fs [] \\ strip_tac
    \\ fs [eq_eval,code_rel_def,stubs_def,cut_env_adjust_set_insert_1]
    \\ Cases_on `names_opt` \\ fs [cut_state_opt_def,cut_state_def]
    \\ Cases_on `dataSem$cut_env x' s.locals` \\ fs []
    \\ imp_res_tac cut_env_IMP_cut_env
    \\ fs [get_names_def,wordSemTheory.push_env_def]
    \\ Cases_on `env_to_list y t.permute` \\ fs []
    \\ qmatch_goalsub_abbrev_tac `evaluate (LongDiv_code c,t2)`
    \\ qspecl_then [`t2`,`n`,`l+1`,`c`] mp_tac evaluate_LongDiv_code
    \\ fs [] \\ disch_then (qspecl_then [`0w`,`n2w (4 * n1)`,`n2w (4 * n2)`] mp_tac)
    \\ fs [multiwordTheory.single_div_def]
    \\ impl_tac THEN1
     (unabbrev_all_tac
      \\ fs [lookup_insert,wordSemTheory.MustTerminate_limit_def,
             mc_multiwordTheory.single_div_pre_def]
      \\ fs [DIV_LT_X] \\ Cases_on `n2` \\ fs [MULT_CLAUSES])
    \\ strip_tac \\ fs []
    \\ fs [wordSemTheory.pop_env_def,Abbr `t2`]
    \\ reverse IF_CASES_TAC THEN1
     (`F` by all_tac \\ fs [] \\ pop_assum mp_tac \\ fs []
      \\ drule env_to_list_lookup_equiv
      \\ fs [domain_lookup,EXTENSION,lookup_fromAList])
    \\ fs [list_Seq_def,eq_eval,FLOOKUP_UPDATE]
    \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ fs [lookup_insert]
    \\ fs [state_rel_thm,bviSemTheory.bvl_to_bvi_def,
         bviSemTheory.bvi_to_bvl_def,lookup_insert,
         dataSemTheory.bvi_to_data_def,adjust_var_11,
         dataSemTheory.call_env_def,alist_insert_def,
         dataSemTheory.data_to_bvi_def,push_env_def,
         dataSemTheory.set_var_def,wordSemTheory.set_vars_def]
    \\ rveq \\ fs []
    \\ conj_tac THEN1
     (drule env_to_list_lookup_equiv \\ fs []
      \\ drule cut_env_adjust_set_lookup_0 \\ fs [lookup_fromAList])
    \\ conj_tac THEN1
     (rw [] \\ fs []
      \\ drule env_to_list_lookup_equiv \\ fs []
      \\ drule cut_env_IMP_MEM \\ fs [lookup_fromAList]
      \\ drule (GEN_ALL adjust_var_cut_env_IMP_MEM) \\ fs []
      \\ drule (GEN_ALL cut_env_IMP_MEM) \\ fs []
      \\ strip_tac \\ fs [])
    \\ fs [inter_insert_ODD_adjust_set]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert
    \\ fs [FAPPLY_FUPDATE_THM,memory_rel_Temp]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
    \\ `n2w ((4 * n1) MOD (4 * n2)) = Smallnum (&(n1 MOD n2))` by
       (fs [wordsTheory.word_sdiv_def,word_div_def,Smallnum_def]
        \\ fs [MOD_COMMON_FACTOR] \\ NO_TAC)
    \\ fs [] \\ match_mp_tac IMP_memory_rel_Number \\ fs []
    \\ imp_res_tac memory_rel_zero_space \\ fs [APPEND]
    \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac memory_rel_rearrange)
    \\ fs [] \\ rw [] \\ fs [] \\ disj1_tac
    \\ fs [join_env_def,MEM_MAP,MEM_FILTER]
    \\ Cases_on `y'` \\ fs []
    \\ rename1 `MEM (y1,y2) _`
    \\ qexists_tac `(y1,y2)` \\ fs [MEM_toAList]
    \\ fs [lookup_inter_alt]
    \\ fs [cut_env_def,wordSemTheory.cut_env_def] \\ rveq
    \\ fs [domain_lookup] \\ rfs [lookup_adjust_set]
    \\ fs [domain_lookup,lookup_inter_alt]
    \\ drule env_to_list_lookup_equiv
    \\ fs [lookup_fromAList] \\ strip_tac \\ fs [] \\ fs [lookup_inter_alt])
  \\ pop_assum kall_tac
  \\ fs [list_Seq_def]
  \\ once_rewrite_tac [wordSemTheory.evaluate_def] \\ fs []
  \\ fs [bviSemTheory.bvl_to_bvi_def,
         bviSemTheory.bvi_to_bvl_def,
         dataSemTheory.bvi_to_data_def,
         dataSemTheory.call_env_def,alist_insert_def,
         dataSemTheory.data_to_bvi_def,push_env_def,
         dataSemTheory.set_var_def,wordSemTheory.set_vars_def]
  \\ imp_res_tac cut_state_opt_IMP_ffi \\ fs []
  \\ match_mp_tac (eval_Call_Mod |> REWRITE_RULE [list_Seq_def])
  \\ fs [get_vars_SOME_IFF_data,insert_shadow]
  \\ fs [GSYM wordSemTheory.set_var_def]
  \\ fs [wordSemTheory.set_var_def,state_rel_insert_1]);

val th = Q.store_thm("assign_LengthByte",
  `op = LengthByte ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
  \\ clean_tac \\ fs []
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_1] \\ clean_tac
  \\ fs [get_var_def]
  \\ fs [state_rel_thm] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac
  \\ rpt_drule memory_rel_ByteArray_IMP \\ fs []
  \\ qpat_abbrev_tac`ttt = COND _ _ _`
  \\ rw []
  \\ fs [assign_def]
  \\ fs [wordSemTheory.get_vars_def]
  \\ Cases_on `get_var (adjust_var a1) t` \\ fs [] \\ clean_tac
  \\ eval_tac
  \\ fs [wordSemTheory.get_var_def,wordSemTheory.get_var_imm_def]
  \\ fs [asmTheory.word_cmp_def,word_and_one_eq_0_iff
           |> SIMP_RULE (srw_ss()) []]
  \\ `shift_length c < dimindex (:α)` by (fs [memory_rel_def] \\ NO_TAC)
  \\ `word_exp t (real_addr c (adjust_var a1)) = SOME (Word a)` by
       (match_mp_tac (GEN_ALL get_real_addr_lemma)
        \\ fs [wordSemTheory.get_var_def] \\ NO_TAC) \\ fs []
  \\ IF_CASES_TAC
  >- ( fs[good_dimindex_def] \\ rfs[shift_def] )
  \\ pop_assum kall_tac
  \\ simp[]
  \\ `2 < dimindex (:'a)` by
       (fs [labPropsTheory.good_dimindex_def] \\ fs [])
  \\ fs [] \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
  \\ fs [WORD_MUL_LSL,WORD_LEFT_ADD_DISTRIB,GSYM word_add_n2w]
  \\ fs [word_mul_n2w]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs []
  \\ fs[good_dimindex_def,markerTheory.Abbrev_def]
  \\ rfs[shift_def,bytes_in_word_def,WORD_LEFT_ADD_DISTRIB,word_mul_n2w]
  \\ match_mp_tac (IMP_memory_rel_Number_num3
       |> SIMP_RULE std_ss [WORD_MUL_LSL,word_mul_n2w]) \\ fs []
  \\ fs[good_dimindex_def]);

val th = Q.store_thm("assign_Length",
  `op = Length ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
  \\ clean_tac \\ fs []
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_1] \\ clean_tac
  \\ fs [get_var_def]
  \\ fs [state_rel_thm] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac
  \\ rpt_drule memory_rel_ValueArray_IMP \\ fs [] \\ rw []
  \\ fs [assign_def]
  \\ fs [wordSemTheory.get_vars_def]
  \\ Cases_on `get_var (adjust_var a1) t` \\ fs [] \\ clean_tac
  \\ eval_tac
  \\ fs [wordSemTheory.get_var_def,wordSemTheory.get_var_imm_def]
  \\ fs [asmTheory.word_cmp_def,word_and_one_eq_0_iff
           |> SIMP_RULE (srw_ss()) []]
  \\ `shift_length c < dimindex (:α)` by (fs [memory_rel_def] \\ NO_TAC)
  \\ `word_exp t (real_addr c (adjust_var a1)) = SOME (Word a)` by
       (match_mp_tac (GEN_ALL get_real_addr_lemma)
        \\ fs [wordSemTheory.get_var_def] \\ NO_TAC) \\ fs []
  \\ fs [GSYM NOT_LESS,GREATER_EQ]
  \\ `c.len_size <> 0` by
      (fs [memory_rel_def,heap_in_memory_store_def] \\ NO_TAC)
  \\ fs [NOT_LESS]
  \\ `~(dimindex (:α) <= 2)` by
         (fs [labPropsTheory.good_dimindex_def] \\ NO_TAC)
  \\ fs [] \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs []
  \\ fs [decode_length_def]
  \\ match_mp_tac IMP_memory_rel_Number_num \\ fs []);

val th = Q.store_thm("assign_LengthBlock",
  `op = LengthBlock ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
  \\ clean_tac \\ fs []
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_1] \\ clean_tac
  \\ fs [get_var_def]
  \\ fs [state_rel_thm] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac
  \\ drule memory_rel_Block_IMP \\ fs [] \\ rw []
  \\ fs [assign_def]
  \\ fs [wordSemTheory.get_vars_def]
  \\ Cases_on `get_var (adjust_var a1) t` \\ fs [] \\ clean_tac
  \\ eval_tac
  \\ fs [wordSemTheory.get_var_def,wordSemTheory.get_var_imm_def]
  \\ fs [asmTheory.word_cmp_def,word_and_one_eq_0_iff
           |> SIMP_RULE (srw_ss()) []]
  \\ reverse (Cases_on `w ' 0`) \\ fs [] THEN1
   (fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ match_mp_tac (IMP_memory_rel_Number |> Q.INST [`i`|->`0`]
          |> SIMP_RULE std_ss [EVAL ``Smallnum 0``])
    \\ fs [] \\ fs [labPropsTheory.good_dimindex_def,dimword_def]
    \\ EVAL_TAC \\ rw [labPropsTheory.good_dimindex_def,dimword_def])
  \\ `shift_length c < dimindex (:α)` by (fs [memory_rel_def] \\ NO_TAC)
  \\ `word_exp t (real_addr c (adjust_var a1)) = SOME (Word a)` by
       (match_mp_tac (GEN_ALL get_real_addr_lemma)
        \\ fs [wordSemTheory.get_var_def] \\ NO_TAC) \\ fs []
  \\ fs [GSYM NOT_LESS,GREATER_EQ]
  \\ `c.len_size <> 0` by
      (fs [memory_rel_def,heap_in_memory_store_def] \\ NO_TAC)
  \\ fs [NOT_LESS]
  \\ `~(dimindex (:α) <= 2)` by
         (fs [labPropsTheory.good_dimindex_def] \\ NO_TAC)
  \\ fs [] \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs []
  \\ fs [decode_length_def]
  \\ match_mp_tac IMP_memory_rel_Number_num \\ fs [])

val assign_BoundsCheckBlock = prove(
  ``assign c secn l dest BoundsCheckBlock args names =
      case args of
      | [v1;v2] => (list_Seq [If Test (adjust_var v1) (Imm 1w)
                               (Assign 1 (Const 0w))
                               (Assign 1
                                 (let addr = real_addr c (adjust_var v1) in
                                  let header = Load addr in
                                  let k = dimindex (:'a) - c.len_size in
                                    Shift Lsr header (Nat k)));
                              Assign 3 (ShiftVar Ror (adjust_var v2) 2);
                              If Lower 3 (Reg 1)
                               (Assign (adjust_var dest) TRUE_CONST)
                               (Assign (adjust_var dest) FALSE_CONST)],l)
      | _ => (Skip:'a wordLang$prog,l)``,
  fs [assign_def] \\ every_case_tac \\ fs []) ;

val th = Q.store_thm("assign_BoundsCheckBlock",
  `op = BoundsCheckBlock ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
  \\ clean_tac \\ fs []
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_2] \\ clean_tac
  \\ fs [get_var_def]
  \\ fs [state_rel_thm] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac
  \\ drule memory_rel_Block_IMP \\ fs [] \\ rw []
  \\ fs [assign_BoundsCheckBlock]
  \\ fs [get_vars_SOME_IFF_data,get_vars_SOME_IFF]
  \\ qmatch_asmsub_rename_tac `(Number i,w2)`
  \\ `?wi. w2 = Word wi` by
    (drule memory_rel_tl \\ strip_tac
     \\ imp_res_tac memory_rel_any_Number_IMP \\ simp [] \\ NO_TAC)
  \\ rveq
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [eq_eval]
  \\ reverse (Cases_on `w ' 0`) \\ fs [word_index_0] THEN1
   (fs [lookup_insert,adjust_var_11]
    \\ rw [] \\ fs []
    \\ fs [eq_eval,list_Seq_def]
    \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma]
    \\ fs [eq_eval,WORD_LO_word_0,adjust_var_11]
    \\ rw []
    \\ simp[inter_insert_ODD_adjust_set,GSYM Boolv_def]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ fs [intLib.COOPER_PROVE ``~(0<=i /\ i<0:int)``]
    \\ match_mp_tac memory_rel_Boolv_F \\ fs [])
  \\ `shift_length c < dimindex (:α)` by (fs [memory_rel_def] \\ NO_TAC)
  \\ `word_exp t (real_addr c (adjust_var a1)) = SOME (Word a)` by
       (match_mp_tac (GEN_ALL get_real_addr_lemma)
        \\ fs [wordSemTheory.get_var_def] \\ NO_TAC) \\ fs []
  \\ fs [eq_eval,word_sh_def,num_exp_def]
  \\ fs [list_Seq_def,eq_eval]
  \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma]
  \\ `c.len_size < dimindex (:α) /\
      ~(dimindex (:α) ≥ c.len_size + dimindex (:α))` by
         (fs [memory_rel_def,heap_in_memory_store_def] \\ NO_TAC)
  \\ fs [eq_eval,WORD_LO_word_0,adjust_var_11]
  \\ fs [decode_length_def]
  \\ drule memory_rel_tl \\ strip_tac
  \\ drule (GEN_ALL memory_rel_bounds_check)
  \\ disch_then (qspec_then `LENGTH l'` mp_tac)
  \\ impl_tac THEN1
    (fs [small_int_def,dimword_def,good_dimindex_def] \\ rfs [])
  \\ strip_tac \\ fs []
  \\ qpat_abbrev_tac `bool_res <=> 0 ≤ i ∧ i < &LENGTH _`
  \\ Cases_on `bool_res`
  \\ fs [] \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
  \\ simp[inter_insert_ODD_adjust_set,GSYM Boolv_def]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs []
  \\ TRY (match_mp_tac memory_rel_Boolv_T \\ fs [])
  \\ TRY (match_mp_tac memory_rel_Boolv_F \\ fs []));

val assign_BoundsCheckArray = prove(
  ``assign c secn l dest BoundsCheckArray args names =
      case args of
      | [v1;v2] => (list_Seq [Assign 1
                               (let addr = real_addr c (adjust_var v1) in
                                let header = Load addr in
                                let k = dimindex (:'a) - c.len_size in
                                  Shift Lsr header (Nat k));
                              Assign 3 (ShiftVar Ror (adjust_var v2) 2);
                              If Lower 3 (Reg 1)
                               (Assign (adjust_var dest) TRUE_CONST)
                               (Assign (adjust_var dest) FALSE_CONST)],l)
      | _ => (Skip:'a wordLang$prog,l)``,
  fs [assign_def] \\ every_case_tac \\ fs []) ;

val th = Q.store_thm("assign_BoundsCheckArray",
  `op = BoundsCheckArray ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
  \\ clean_tac \\ fs []
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_2] \\ clean_tac
  \\ fs [get_var_def]
  \\ fs [state_rel_thm] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac
  \\ drule (GEN_ALL memory_rel_ValueArray_IMP) \\ fs [] \\ rw []
  \\ fs [assign_BoundsCheckArray]
  \\ fs [get_vars_SOME_IFF_data,get_vars_SOME_IFF]
  \\ qmatch_asmsub_rename_tac `(Number i,w2)`
  \\ `?wi. w2 = Word wi` by
    (drule memory_rel_tl \\ strip_tac
     \\ imp_res_tac memory_rel_any_Number_IMP \\ simp [] \\ NO_TAC)
  \\ rveq
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [eq_eval]
  \\ `shift_length c < dimindex (:α)` by (fs [memory_rel_def] \\ NO_TAC)
  \\ `word_exp t (real_addr c (adjust_var a1)) = SOME (Word a)` by
       (match_mp_tac (GEN_ALL get_real_addr_lemma)
        \\ fs [wordSemTheory.get_var_def] \\ NO_TAC) \\ fs []
  \\ fs [eq_eval,word_sh_def,num_exp_def]
  \\ fs [list_Seq_def,eq_eval]
  \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma]
  \\ `c.len_size < dimindex (:α) /\
      ~(dimindex (:α) ≥ c.len_size + dimindex (:α))` by
         (fs [memory_rel_def,heap_in_memory_store_def] \\ NO_TAC)
  \\ fs [eq_eval,WORD_LO_word_0,adjust_var_11]
  \\ fs [decode_length_def]
  \\ drule memory_rel_tl \\ strip_tac
  \\ drule (GEN_ALL memory_rel_bounds_check)
  \\ disch_then (qspec_then `LENGTH l'` mp_tac)
  \\ impl_tac THEN1
    (fs [small_int_def,dimword_def,good_dimindex_def] \\ rfs [])
  \\ strip_tac \\ fs []
  \\ qpat_abbrev_tac `bool_res <=> 0 ≤ i ∧ i < &LENGTH _`
  \\ Cases_on `bool_res`
  \\ fs [] \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
  \\ simp[inter_insert_ODD_adjust_set,GSYM Boolv_def]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs []
  \\ TRY (match_mp_tac memory_rel_Boolv_T \\ fs [])
  \\ TRY (match_mp_tac memory_rel_Boolv_F \\ fs []));

val assign_BoundsCheckByte = prove(
  ``assign c secn l dest BoundsCheckByte args names =
      case args of
      | [v1;v2] => (list_Seq [Assign 1
                               (let addr = real_addr c (adjust_var v1) in
                                let header = Load addr in
                                let extra = (if dimindex (:'a) = 32 then 2 else 3) in
                                let k = dimindex (:'a) - c.len_size - extra in
                                let kk = (if dimindex (:'a) = 32 then 3w else 7w) in
                                  Op Sub [Shift Lsr header (Nat k); Const kk]);
                              Assign 3 (ShiftVar Ror (adjust_var v2) 2);
                              If Lower 3 (Reg 1)
                               (Assign (adjust_var dest) TRUE_CONST)
                               (Assign (adjust_var dest) FALSE_CONST)],l)
      | _ => (Skip:'a wordLang$prog,l)``,
  fs [assign_def] \\ every_case_tac \\ fs []) ;

val th = Q.store_thm("assign_BoundsCheckByte",
  `op = BoundsCheckByte ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
  \\ clean_tac \\ fs []
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_2] \\ clean_tac
  \\ fs [get_var_def]
  \\ fs [state_rel_thm] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac
  \\ drule (GEN_ALL memory_rel_ByteArray_IMP) \\ fs [] \\ rw []
  \\ fs [assign_BoundsCheckByte]
  \\ fs [get_vars_SOME_IFF_data,get_vars_SOME_IFF]
  \\ qmatch_asmsub_rename_tac `(Number i,w2)`
  \\ `?wi. w2 = Word wi` by
    (drule memory_rel_tl \\ strip_tac
     \\ imp_res_tac memory_rel_any_Number_IMP \\ simp [] \\ NO_TAC)
  \\ rveq
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [eq_eval]
  \\ `shift_length c < dimindex (:α)` by (fs [memory_rel_def] \\ NO_TAC)
  \\ `word_exp t (real_addr c (adjust_var a1)) = SOME (Word a)` by
       (match_mp_tac (GEN_ALL get_real_addr_lemma)
        \\ fs [wordSemTheory.get_var_def] \\ NO_TAC) \\ fs []
  \\ fs [eq_eval,word_sh_def,num_exp_def]
  \\ fs [list_Seq_def,eq_eval]
  \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma]
  \\ `c.len_size < dimindex (:α) /\
      ~(dimindex (:α) ≥ c.len_size + dimindex (:α))` by
         (fs [memory_rel_def,heap_in_memory_store_def] \\ NO_TAC)
  \\ fs [eq_eval,WORD_LO_word_0,adjust_var_11]
  \\ fs [good_dimindex_def] \\ rfs []
  \\ fs [decode_length_def]
  \\ drule memory_rel_tl \\ strip_tac
  \\ drule (GEN_ALL memory_rel_bounds_check)
  \\ disch_then (qspec_then `LENGTH l'` mp_tac)
  \\ impl_tac
  \\ TRY (fs [small_int_def,dimword_def,good_dimindex_def] \\ rfs [] \\ NO_TAC)
  \\ fs [GSYM word_add_n2w]
  \\ strip_tac \\ fs []
  \\ qpat_abbrev_tac `bool_res <=> 0 ≤ i ∧ i < &LENGTH _`
  \\ Cases_on `bool_res`
  \\ fs [] \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
  \\ simp[inter_insert_ODD_adjust_set,GSYM Boolv_def]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs []
  \\ TRY (match_mp_tac memory_rel_Boolv_T \\ fs [])
  \\ TRY (match_mp_tac memory_rel_Boolv_F \\ fs [])
  \\ fs [good_dimindex_def]);

val assign_LessConstSmall = prove(
  ``assign c secn l dest (LessConstSmall i) args names =
      case args of
      | [v1] => (If Less (adjust_var v1) (Imm (n2w (4 * i)))
                  (Assign (adjust_var dest) TRUE_CONST)
                  (Assign (adjust_var dest) FALSE_CONST),l)
      | _ => (Skip:'a wordLang$prog,l)``,
  fs [assign_def] \\ every_case_tac \\ fs []);

val th = Q.store_thm("assign_LessSmallConst",
  `(?i. op = LessConstSmall i) ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
  \\ clean_tac \\ fs []
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_1] \\ clean_tac
  \\ fs [get_var_def]
  \\ fs [state_rel_thm] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac
  \\ `?k. i' = &k` by (Cases_on `i'` \\ fs [] \\ NO_TAC) \\ rveq \\ fs []
  \\ `small_int (:'a) (&k)` by
       (fs [small_int_def,good_dimindex_def,dimword_def] \\ NO_TAC)
  \\ imp_res_tac memory_rel_Number_IMP \\ fs [] \\ rveq \\ fs []
  \\ fs [assign_LessConstSmall]
  \\ fs [get_vars_SOME_IFF_data,get_vars_SOME_IFF]
  \\ fs [eq_eval,WORD_LO_word_0,adjust_var_11]
  \\ fs [Smallnum_def]
  \\ `n2w (4 * k) < (n2w (4 * i):'a word) <=> k < i` by
    (fs [word_lt_n2w,bitTheory.BIT_def,bitTheory.BITS_THM]
     \\ fs [good_dimindex_def,LESS_DIV_EQ_ZERO,dimword_def] \\ NO_TAC)
  \\ fs []
  \\ qpat_abbrev_tac `bool_res <=> k < i`
  \\ Cases_on `bool_res`
  \\ fs [] \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
  \\ simp[inter_insert_ODD_adjust_set,GSYM Boolv_def]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs []
  \\ TRY (match_mp_tac memory_rel_Boolv_T \\ fs [])
  \\ TRY (match_mp_tac memory_rel_Boolv_F \\ fs []));

val Compare1_code_thm = store_thm("Compare1_code_thm",
  ``!l a1 a2 dm m res (t:('a,'b) wordSem$state).
      word_cmp_loop l a1 a2 dm m = SOME res /\
      dm = t.mdomain /\
      m = t.memory /\
      lookup Compare1_location t.code = SOME (4,Compare1_code) /\
      get_var 0 t = SOME (Loc l1 l2) /\
      get_var 2 t = SOME (Word l) /\
      get_var 4 t = SOME (Word a1) /\
      get_var 6 t = SOME (Word a2) /\
      w2n l <= t.clock ==>
      ?ck.
        evaluate (Compare1_code,t) =
          (SOME (Result (Loc l1 l2) (Word res)),
           t with <| clock := ck; locals := LN |>) /\
        t.clock <= w2n l + ck``,
  ho_match_mp_tac word_cmp_loop_ind \\ rw []
  \\ qpat_assum `_ = SOME res` mp_tac
  \\ once_rewrite_tac [word_cmp_loop_def,Compare1_code_def]
  \\ IF_CASES_TAC \\ fs [] \\ strip_tac \\ rveq
  THEN1
   (eval_tac \\ fs [wordSemTheory.get_var_imm_def,asmTheory.word_cmp_def,
      wordSemTheory.get_var_def,lookup_insert,wordSemTheory.call_env_def,
      fromList2_def,wordSemTheory.state_component_equality])
  \\ every_case_tac \\ fs [wordsTheory.WORD_LOWER_REFL] \\ rveq
  THEN1
   (fs [list_Seq_def]
    \\ eval_tac \\ fs [wordSemTheory.get_var_imm_def,asmTheory.word_cmp_def,
         wordSemTheory.get_var_def,lookup_insert,wordSemTheory.call_env_def,
         fromList2_def,wordSemTheory.state_component_equality])
  \\ `t.clock <> 0` by (Cases_on `l` \\ fs [] \\ NO_TAC)
  \\ fs [list_Seq_def]
  \\ eval_tac \\ fs [wordSemTheory.get_var_imm_def,asmTheory.word_cmp_def,
         wordSemTheory.get_var_def,lookup_insert,wordSemTheory.call_env_def,
         fromList2_def,wordSemTheory.state_component_equality,
         wordSemTheory.get_vars_def,wordSemTheory.bad_dest_args_def,
         wordSemTheory.add_ret_loc_def,wordSemTheory.find_code_def]
  \\ qpat_abbrev_tac `t1 = wordSem$dec_clock _ with locals := _`
  \\ rfs []
  \\ first_x_assum (qspec_then `t1` mp_tac)
  \\ impl_tac THEN1
   (unabbrev_all_tac
    \\ fs [wordSemTheory.dec_clock_def,lookup_insert]
    \\ Cases_on `l` \\ fs []
    \\ Cases_on `n` \\ fs [GSYM word_add_n2w,ADD1])
  \\ strip_tac \\ fs [wordSemTheory.state_component_equality]
  \\ unabbrev_all_tac \\ fs [wordSemTheory.dec_clock_def,lookup_insert]
  \\ Cases_on `l` \\ fs []
  \\ Cases_on `n` \\ fs [ADD1,GSYM word_add_n2w]);

val word_exp_insert = store_thm("word_exp_insert",
  ``(m <> n ==>
     (word_exp (t with locals := insert n w t.locals) (real_addr c m) =
      word_exp t (real_addr c m))) /\
    (~(m IN {n;n1}) ==>
     (word_exp (t with locals := insert n w (insert n1 w1 t.locals)) (real_addr c m) =
      word_exp t (real_addr c m)))``,
  fs [wordSemTheory.word_exp_def,real_addr_def]
  \\ IF_CASES_TAC \\ fs []
  \\ fs [wordSemTheory.word_exp_def,real_addr_def] \\ fs [lookup_insert]);

val Compare_code_thm = store_thm("Compare_code_thm",
  ``memory_rel c be refs sp st m dm
      ((Number i1,Word v1)::(Number i2,Word v2)::vars) /\
    dm = (t:('a,'b) wordSem$state).mdomain /\
    m = t.memory /\
    st = t.store /\
    (~word_bit 0 v1 ==> word_bit 0 v2) /\
    shift_length c < dimindex (:'a) /\
    lookup Compare1_location t.code = SOME (4,Compare1_code) /\
    get_var 0 t = SOME (Loc l1 l2) /\
    get_var 2 t = SOME (Word (v1:'a word)) /\
    get_var 4 t = SOME (Word (v2:'a word)) /\
    dimword (:'a) < t.clock /\
    c.len_size <> 0 /\
    c.len_size < dimindex (:α) /\
    good_dimindex (:'a) ==>
    ?ck.
      evaluate (Compare_code c,t) =
        (SOME (Result (Loc l1 l2) (Word (word_cmp_res i1 i2))),
         t with <| clock := ck; locals := LN |>)``,
  rw [] \\ drule memory_rel_Number_cmp
  \\ fs [] \\ strip_tac \\ fs []
  \\ pop_assum mp_tac
  \\ IF_CASES_TAC THEN1 fs []
  \\ pop_assum kall_tac
  \\ IF_CASES_TAC THEN1
   (fs [] \\ rw [] \\ fs [Compare_code_def]
    \\ rpt_drule get_real_addr_lemma \\ rw []
    \\ fs [list_Seq_def]
    \\ eval_tac \\ fs [wordSemTheory.get_var_imm_def,asmTheory.word_cmp_def,
         wordSemTheory.get_var_def,lookup_insert,wordSemTheory.call_env_def,
         fromList2_def,wordSemTheory.state_component_equality,word_bit_test])
  \\ pop_assum mp_tac \\ fs []
  \\ Cases_on `word_bit 0 v1` \\ fs []
  \\ reverse (Cases_on `word_bit 0 v2`) \\ fs []
  THEN1
   (`memory_rel c be refs sp t.store t.memory t.mdomain
        ((Number i2,Word v2)::(Number i1,Word v1)::vars)` by
     (first_x_assum (fn th => mp_tac th THEN match_mp_tac memory_rel_rearrange)
      \\ fs [] \\ rw [] \\ fs [])
    \\ drule memory_rel_Number_cmp
    \\ fs [] \\ strip_tac \\ fs []
    \\ `word_cmp_res i1 i2 = if (16w && x2) = 0w then 2w else 0w:'a word` by
     (fs [word_cmp_res_def] \\ rfs []
      \\ rw [] \\ fs []
      \\ Cases_on `i2 < i1` \\ fs [] \\ intLib.COOPER_TAC)
    \\ fs [] \\ pop_assum kall_tac \\ pop_assum kall_tac
    \\ qpat_assum `_ = SOME (Word v1)` assume_tac
    \\ fs [Compare_code_def]
    \\ rpt_drule get_real_addr_lemma \\ rw []
    \\ fs [list_Seq_def]
    \\ eval_tac \\ fs [wordSemTheory.get_var_imm_def,asmTheory.word_cmp_def,
         wordSemTheory.get_var_def,lookup_insert,wordSemTheory.call_env_def,
         fromList2_def,wordSemTheory.state_component_equality,word_bit_test])
  \\ `shift (:'a) <> 0 /\ shift (:'a) < dimindex (:'a)` by
          (fs [labPropsTheory.good_dimindex_def,shift_def] \\ NO_TAC)
  \\ strip_tac \\ fs []
  \\ Cases_on `x1 = x2` \\ fs [] \\ rveq
  THEN1
   (pop_assum mp_tac \\ IF_CASES_TAC \\ fs [] \\ strip_tac
    \\ rpt_drule get_real_addr_lemma \\ rw []
    \\ qpat_assum `_ = SOME (Word v1)` assume_tac
    \\ rpt_drule get_real_addr_lemma \\ rw []
    \\ fs [Compare_code_def]
    \\ fs [list_Seq_def]
    \\ eval_tac \\ fs [wordSemTheory.get_var_imm_def,asmTheory.word_cmp_def,
         wordSemTheory.get_var_def,lookup_insert,wordSemTheory.call_env_def,
         fromList2_def,wordSemTheory.state_component_equality,word_bit_test,
         word_exp_insert,wordSemTheory.get_vars_def,
         wordSemTheory.get_var_def,lookup_insert,wordSemTheory.call_env_def,
         fromList2_def,wordSemTheory.state_component_equality,
         wordSemTheory.get_vars_def,wordSemTheory.bad_dest_args_def,
         wordSemTheory.add_ret_loc_def,wordSemTheory.find_code_def]
    \\ qpat_abbrev_tac `t1 = wordSem$dec_clock _ with locals := _`
    \\ drule Compare1_code_thm
    \\ fs [GSYM decode_length_def]
    \\ disch_then (qspec_then `t1` mp_tac)
    \\ impl_tac
    \\ TRY
     (strip_tac \\ fs [] \\ unabbrev_all_tac
      \\ fs [wordSemTheory.state_component_equality,wordSemTheory.dec_clock_def]
      \\ NO_TAC)
    \\ fs [] \\ unabbrev_all_tac
    \\ fs [wordSemTheory.state_component_equality,wordSemTheory.dec_clock_def,
           wordSemTheory.get_var_def,lookup_insert,shift_lsl]
    \\ Cases_on `decode_length c x1` \\ fs [])
  \\ rpt_drule get_real_addr_lemma \\ rw []
  \\ qpat_assum `_ = SOME (Word v1)` assume_tac
  \\ rpt_drule get_real_addr_lemma \\ rw []
  \\ rpt IF_CASES_TAC
  \\ fs [Compare_code_def,list_Seq_def]
  \\ eval_tac \\ fs [wordSemTheory.get_var_imm_def,asmTheory.word_cmp_def,
       wordSemTheory.get_var_def,lookup_insert,wordSemTheory.call_env_def,
       fromList2_def,wordSemTheory.state_component_equality,word_bit_test,
       word_exp_insert,GSYM decode_length_def]);

val word_cmp_Less_word_cmp_res = prove(
  ``!i i'. good_dimindex (:'a) ==>
           (word_cmp Less (word_cmp_res i i') (1w:'a word) <=> i < i')``,
  rw [] \\ fs [labPropsTheory.good_dimindex_def]
  \\ fs [word_cmp_res_def,asmTheory.word_cmp_def]
  \\ rw [] \\ fs [WORD_LT] \\ fs [word_msb_def,word_index,dimword_def]);

val word_cmp_NotLess_word_cmp_res = prove(
  ``!i i'. good_dimindex (:'a) ==>
           (word_cmp NotLess (1w:'a word) (word_cmp_res i i') <=> (i <= i'))``,
  rw [] \\ fs [labPropsTheory.good_dimindex_def]
  \\ fs [word_cmp_res_def,asmTheory.word_cmp_def]
  \\ rw [] \\ fs [WORD_LT] \\ fs [word_msb_def,word_index,dimword_def]
  \\ intLib.COOPER_TAC);

val IMP_spt_eq = store_thm("IMP_spt_eq",
  ``wf t1 /\ wf t2 /\ (∀n. lookup n t1 = lookup n t2) ==> (t1 = t2)``,
  metis_tac [spt_eq_thm]);

val env_to_list_cut_env_IMP = prove(
  ``env_to_list x t.permute = (l,permute) /\ cut_env y s = SOME x ==>
    (fromAList l = x)``,
  strip_tac \\ match_mp_tac IMP_spt_eq
  \\ fs [wf_fromAList]
  \\ drule env_to_list_lookup_equiv
  \\ fs [lookup_fromAList]
  \\ fs [wordSemTheory.cut_env_def] \\ rveq \\ rw []);

val dimword_LESS_MustTerminate_limit = prove(
  ``good_dimindex (:'a) ==> dimword (:α) < MustTerminate_limit (:α) - 1``,
  strip_tac \\ fs [wordSemTheory.MustTerminate_limit_def,dimword_def]
  \\ match_mp_tac (DECIDE ``1 < n ==> n < (2 * n + k) - 1n``)
  \\ fs [labPropsTheory.good_dimindex_def]);

val th = Q.store_thm("assign_Less",
  `op = Less ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
  \\ clean_tac \\ fs []
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_2] \\ clean_tac
  \\ fs [get_var_def]
  \\ fs [Boolv_def] \\ rveq \\ fs [GSYM Boolv_def]
  \\ qpat_assum `state_rel c l1 l2 x t [] locs`
           (assume_tac o REWRITE_RULE [state_rel_thm])
  \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac
  \\ rpt_drule memory_rel_Number_cmp
  \\ strip_tac \\ fs [] \\ rveq
  \\ fs [get_vars_SOME_IFF_data,get_vars_SOME_IFF]
  \\ fs [wordSemTheory.get_var_def]
  \\ fs [assign_def,list_Seq_def] \\ eval_tac
  \\ fs [lookup_insert,wordSemTheory.get_var_def,wordSemTheory.get_var_imm_def,
         word_cmp_Test_1,word_bit_or]
  \\ IF_CASES_TAC THEN1
   (fs [lookup_insert,state_rel_thm]
    \\ fs [wordSemTheory.get_var_imm_def,asmTheory.word_cmp_def]
    \\ IF_CASES_TAC \\ fs []
    \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ simp[inter_insert_ODD_adjust_set,GSYM Boolv_def]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ TRY (match_mp_tac memory_rel_Boolv_T \\ fs [])
    \\ TRY (match_mp_tac memory_rel_Boolv_F \\ fs [])
    \\ match_mp_tac (GEN_ALL memory_rel_zero_space)
    \\ metis_tac [])
  \\ pop_assum mp_tac
  \\ rpt_drule (Compare_code_thm |> INST_TYPE [``:'b``|->``:'ffi``])
  \\ ho_match_mp_tac (METIS_PROVE []
         ``((!x1 x2 x3. (b2 ==> b0 x1 x2 x3) ==> b1 x1 x2 x3) ==> b3) ==>
           ((!x1 x2 x3. b0 x1 x2 x3 ==> b1 x1 x2 x3) ==> b2 ==> b3)``)
  \\ strip_tac
  \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def,lookup_insert,
         wordSemTheory.bad_dest_args_def,wordSemTheory.find_code_def]
  \\ `lookup Compare_location t.code = SOME (3,Compare_code c)` by
       (fs [state_rel_def,code_rel_def,stubs_def] \\ NO_TAC)
  \\ fs [wordSemTheory.add_ret_loc_def]
  \\ fs [bvi_to_dataTheory.op_requires_names_def,
         bvi_to_dataTheory.op_space_reset_def]
  \\ TOP_CASE_TAC THEN1
   (Cases_on `names_opt` \\ fs []
    \\ fs [cut_state_opt_def,cut_state_def]
    \\ Cases_on `dataSem$cut_env x' s.locals` \\ fs []
    \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` assume_tac
    \\ rpt_drule cut_env_IMP_cut_env
    \\ CCONTR_TAC \\ fs [get_names_def]
    \\ fs [wordSemTheory.cut_env_def,SUBSET_DEF])
  \\ fs []
  \\ qpat_abbrev_tac `t1 = wordSem$call_env _ _`
  \\ first_x_assum (qspecl_then [`t1`,`l`,`n`] mp_tac)
  \\ impl_tac THEN1
   (unabbrev_all_tac
    \\ fs [wordSemTheory.call_env_def,wordSemTheory.push_env_def,
           wordSemTheory.dec_clock_def]
    \\ pairarg_tac \\ fs []
    \\ fs [fromList2_def,lookup_insert]
    \\ fs [state_rel_def,code_rel_def,stubs_def]
    \\ fs [memory_rel_def,word_ml_inv_def,heap_in_memory_store_def]
    \\ fs [dimword_LESS_MustTerminate_limit]
    \\ rpt strip_tac \\ simp [] \\ NO_TAC)
  \\ strip_tac \\ fs []
  \\ `?t2. pop_env t1 = SOME t2 /\ domain t2.locals = domain x'` by
   (unabbrev_all_tac
    \\ fs [wordSemTheory.call_env_def,wordSemTheory.push_env_def,
           wordSemTheory.pop_env_def] \\ pairarg_tac \\ fs []
    \\ imp_res_tac env_to_list_lookup_equiv
    \\ fs [domain_lookup,EXTENSION,lookup_fromAList] \\ NO_TAC)
  \\ fs []
  \\ fs [lookup_insert,word_cmp_Less_word_cmp_res]
  \\ rw [] \\ fs []
  \\ unabbrev_all_tac
  \\ fs [wordSemTheory.pop_env_def,wordSemTheory.call_env_def,
         wordSemTheory.push_env_def,wordSemTheory.dec_clock_def]
  \\ pairarg_tac \\ fs [] \\ rveq \\ fs []
  \\ simp [state_rel_thm]
  \\ fs [lookup_insert]
  \\ rpt_drule env_to_list_cut_env_IMP \\ fs []
  \\ disch_then kall_tac
  \\ fs [lookup_insert,FAPPLY_FUPDATE_THM,adjust_var_11,FLOOKUP_UPDATE]
  \\ fs [inter_insert_ODD_adjust_set]
  \\ fs [wordSemTheory.cut_env_def] \\ rveq
  \\ conj_tac
  \\ TRY (fs [lookup_inter,lookup_insert,adjust_set_def,fromAList_def] \\ NO_TAC)
  \\ `domain (adjust_set (get_names names_opt)) SUBSET domain t.locals` by
   (Cases_on `names_opt` \\ fs [get_names_def]
    \\ fs [SUBSET_DEF,domain_lookup]
    \\ rw [] \\ res_tac \\ fs []
    \\ rveq \\ fs [lookup_ODD_adjust_set] \\ NO_TAC)
  \\ `domain (adjust_set x.locals) SUBSET
      domain (inter t.locals (adjust_set (get_names names_opt)))` by
   (fs [SUBSET_DEF,domain_lookup,lookup_inter_alt] \\ rw []
    \\ Cases_on `names_opt` \\ fs [get_names_def]
    \\ fs [SUBSET_DEF,domain_lookup]
    \\ fs [cut_state_opt_def,cut_state_def,cut_env_def]
    \\ qpat_x_assum `_ = SOME x` mp_tac
    \\ IF_CASES_TAC \\ fs [] \\ rw [] \\ fs [adjust_set_inter]
    \\ fs [lookup_inter_alt,domain_lookup] \\ NO_TAC)
  \\ `!n. IS_SOME (lookup n x.locals) ==>
          n ∈ domain (get_names names_opt) /\
          IS_SOME (lookup (adjust_var n) t.locals)` by
   (qx_gen_tac `k` \\ disch_then assume_tac
    \\ Cases_on `lookup k x.locals` \\ fs []
    \\ Cases_on `names_opt` \\ fs [get_names_def]
    \\ fs [SUBSET_DEF,domain_lookup]
    \\ fs [cut_state_opt_def,cut_state_def,cut_env_def]
    \\ qpat_x_assum `_ = SOME x` mp_tac
    \\ IF_CASES_TAC \\ fs [] \\ rw [] \\ fs [adjust_set_inter]
    \\ fs [lookup_inter_alt,domain_lookup] \\ NO_TAC)
  \\ conj_tac
  \\ TRY (rw [] \\ once_rewrite_tac [lookup_inter_alt]
          \\ fs [lookup_insert,adjust_var_IN_adjust_set] \\ NO_TAC)
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs [inter_insert_ODD_adjust_set_alt]
  \\ match_mp_tac (GEN_ALL memory_rel_zero_space)
  \\ qexists_tac `x.space`
  \\ TRY (match_mp_tac memory_rel_Boolv_T)
  \\ TRY (match_mp_tac memory_rel_Boolv_F) \\ fs []
  \\ qsuff_tac `inter (inter t.locals (adjust_set (get_names names_opt)))
                 (adjust_set x.locals) = inter t.locals (adjust_set x.locals)`
  \\ asm_simp_tac std_ss [] \\ fs []
  \\ fs [lookup_inter_alt,SUBSET_DEF]
  \\ rw [] \\ fs [domain_inter] \\ res_tac);

val th = Q.store_thm("assign_LessEq",
  `op = LessEq ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
  \\ clean_tac \\ fs []
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_2] \\ clean_tac
  \\ fs [get_var_def]
  \\ fs [Boolv_def] \\ rveq \\ fs [GSYM Boolv_def]
  \\ qpat_assum `state_rel c l1 l2 x t [] locs`
           (assume_tac o REWRITE_RULE [state_rel_thm])
  \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac
  \\ rpt_drule memory_rel_Number_cmp
  \\ strip_tac \\ fs [] \\ rveq
  \\ fs [get_vars_SOME_IFF_data,get_vars_SOME_IFF]
  \\ fs [wordSemTheory.get_var_def]
  \\ fs [assign_def,list_Seq_def] \\ eval_tac
  \\ fs [lookup_insert,wordSemTheory.get_var_def,wordSemTheory.get_var_imm_def,
         word_cmp_Test_1,word_bit_or]
  \\ IF_CASES_TAC THEN1
   (fs [lookup_insert,state_rel_thm]
    \\ fs [wordSemTheory.get_var_imm_def,asmTheory.word_cmp_def]
    \\ `i <= i' <=> w1 <= w2` by
          (fs [integerTheory.INT_LE_LT,WORD_LESS_OR_EQ] \\ NO_TAC)
    \\ fs [WORD_NOT_LESS,intLib.COOPER_PROVE ``~(i < j) <=> j <= i:int``]
    \\ simp [word_less_lemma1]
    \\ IF_CASES_TAC \\ fs []
    \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ simp[inter_insert_ODD_adjust_set,GSYM Boolv_def]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ TRY (match_mp_tac memory_rel_Boolv_T \\ fs [])
    \\ TRY (match_mp_tac memory_rel_Boolv_F \\ fs [])
    \\ match_mp_tac (GEN_ALL memory_rel_zero_space)
    \\ metis_tac [])
  \\ pop_assum mp_tac
  \\ rpt_drule (Compare_code_thm |> INST_TYPE [``:'b``|->``:'ffi``])
  \\ ho_match_mp_tac (METIS_PROVE []
         ``((!x1 x2 x3. (b2 ==> b0 x1 x2 x3) ==> b1 x1 x2 x3) ==> b3) ==>
           ((!x1 x2 x3. b0 x1 x2 x3 ==> b1 x1 x2 x3) ==> b2 ==> b3)``)
  \\ strip_tac
  \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def,lookup_insert,
         wordSemTheory.bad_dest_args_def,wordSemTheory.find_code_def]
  \\ `lookup Compare_location t.code = SOME (3,Compare_code c)` by
       (fs [state_rel_def,code_rel_def,stubs_def] \\ NO_TAC)
  \\ fs [wordSemTheory.add_ret_loc_def]
  \\ fs [bvi_to_dataTheory.op_requires_names_def,
         bvi_to_dataTheory.op_space_reset_def]
  \\ TOP_CASE_TAC THEN1
   (Cases_on `names_opt` \\ fs []
    \\ fs [cut_state_opt_def,cut_state_def]
    \\ Cases_on `dataSem$cut_env x' s.locals` \\ fs []
    \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` assume_tac
    \\ rpt_drule cut_env_IMP_cut_env
    \\ CCONTR_TAC \\ fs [get_names_def]
    \\ fs [wordSemTheory.cut_env_def,SUBSET_DEF])
  \\ fs []
  \\ qpat_abbrev_tac `t1 = wordSem$call_env _ _`
  \\ first_x_assum (qspecl_then [`t1`,`l`,`n`] mp_tac)
  \\ impl_tac THEN1
   (unabbrev_all_tac
    \\ fs [wordSemTheory.call_env_def,wordSemTheory.push_env_def,
           wordSemTheory.dec_clock_def]
    \\ pairarg_tac \\ fs []
    \\ fs [fromList2_def,lookup_insert]
    \\ fs [state_rel_def,code_rel_def,stubs_def]
    \\ fs [memory_rel_def,word_ml_inv_def,heap_in_memory_store_def]
    \\ fs [dimword_LESS_MustTerminate_limit]
    \\ rpt strip_tac \\ simp [] \\ NO_TAC)
  \\ strip_tac \\ fs []
  \\ `?t2. pop_env t1 = SOME t2 /\ domain t2.locals = domain x'` by
   (unabbrev_all_tac
    \\ fs [wordSemTheory.call_env_def,wordSemTheory.push_env_def,
           wordSemTheory.pop_env_def] \\ pairarg_tac \\ fs []
    \\ imp_res_tac env_to_list_lookup_equiv
    \\ fs [domain_lookup,EXTENSION,lookup_fromAList] \\ NO_TAC)
  \\ fs []
  \\ fs [lookup_insert,word_cmp_NotLess_word_cmp_res]
  \\ rw [] \\ fs []
  \\ unabbrev_all_tac
  \\ fs [wordSemTheory.pop_env_def,wordSemTheory.call_env_def,
         wordSemTheory.push_env_def,wordSemTheory.dec_clock_def]
  \\ pairarg_tac \\ fs [] \\ rveq \\ fs []
  \\ simp [state_rel_thm]
  \\ fs [lookup_insert]
  \\ rpt_drule env_to_list_cut_env_IMP \\ fs []
  \\ disch_then kall_tac
  \\ fs [lookup_insert,FAPPLY_FUPDATE_THM,adjust_var_11,FLOOKUP_UPDATE]
  \\ fs [inter_insert_ODD_adjust_set]
  \\ fs [wordSemTheory.cut_env_def] \\ rveq
  \\ conj_tac
  \\ TRY (fs [lookup_inter,lookup_insert,adjust_set_def,fromAList_def] \\ NO_TAC)
  \\ `domain (adjust_set (get_names names_opt)) SUBSET domain t.locals` by
   (Cases_on `names_opt` \\ fs [get_names_def]
    \\ fs [SUBSET_DEF,domain_lookup]
    \\ rw [] \\ res_tac \\ fs []
    \\ rveq \\ fs [lookup_ODD_adjust_set] \\ NO_TAC)
  \\ `domain (adjust_set x.locals) SUBSET
      domain (inter t.locals (adjust_set (get_names names_opt)))` by
   (fs [SUBSET_DEF,domain_lookup,lookup_inter_alt] \\ rw []
    \\ Cases_on `names_opt` \\ fs [get_names_def]
    \\ fs [SUBSET_DEF,domain_lookup]
    \\ fs [cut_state_opt_def,cut_state_def,cut_env_def]
    \\ qpat_x_assum `_ = SOME x` mp_tac
    \\ IF_CASES_TAC \\ fs [] \\ rw [] \\ fs [adjust_set_inter]
    \\ fs [lookup_inter_alt,domain_lookup] \\ NO_TAC)
  \\ `!n. IS_SOME (lookup n x.locals) ==>
          n ∈ domain (get_names names_opt) /\
          IS_SOME (lookup (adjust_var n) t.locals)` by
   (qx_gen_tac `k` \\ disch_then assume_tac
    \\ Cases_on `lookup k x.locals` \\ fs []
    \\ Cases_on `names_opt` \\ fs [get_names_def]
    \\ fs [SUBSET_DEF,domain_lookup]
    \\ fs [cut_state_opt_def,cut_state_def,cut_env_def]
    \\ qpat_x_assum `_ = SOME x` mp_tac
    \\ IF_CASES_TAC \\ fs [] \\ rw [] \\ fs [adjust_set_inter]
    \\ fs [lookup_inter_alt,domain_lookup] \\ NO_TAC)
  \\ conj_tac
  \\ TRY (rw [] \\ once_rewrite_tac [lookup_inter_alt]
          \\ fs [lookup_insert,adjust_var_IN_adjust_set] \\ NO_TAC)
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs [inter_insert_ODD_adjust_set_alt]
  \\ match_mp_tac (GEN_ALL memory_rel_zero_space)
  \\ qexists_tac `x.space`
  \\ TRY (match_mp_tac memory_rel_Boolv_T)
  \\ TRY (match_mp_tac memory_rel_Boolv_F) \\ fs []
  \\ qsuff_tac `inter (inter t.locals (adjust_set (get_names names_opt)))
                 (adjust_set x.locals) = inter t.locals (adjust_set x.locals)`
  \\ asm_simp_tac std_ss [] \\ fs []
  \\ fs [lookup_inter_alt,SUBSET_DEF]
  \\ rw [] \\ fs [domain_inter] \\ res_tac);

val cut_env_IMP_domain = prove(
  ``wordSem$cut_env x y = SOME t ==> domain t = domain x``,
  fs [wordSemTheory.cut_env_def] \\ rw []
  \\ fs [SUBSET_DEF,EXTENSION,domain_inter] \\ metis_tac []);

val word_exp_set_var_ShiftVar = store_thm("word_exp_set_var_ShiftVar",
  ``word_exp (set_var v (Word w) t) (ShiftVar sow v n) =
    lift Word (case sow of Lsl => SOME (w << n)
                         | Lsr => SOME (w >>> n)
                         | Asr => SOME (w >> n)
                         | Ror => SOME (word_ror w n))``,
  once_rewrite_tac [word_exp_set_var_ShiftVar_lemma]
  \\ eval_tac \\ fs [lookup_insert] \\ fs []);

val MemEqList_thm = prove(
  ``!offset t xs dm m b a.
      word_mem_eq (a + offset) xs dm m = SOME b /\
      get_var 3 t = SOME (Word a) /\ dm = t.mdomain /\ m = t.memory ==>
      ?x. evaluate (MemEqList offset xs,t) =
            (NONE,t with locals := ((if b then insert 1 (Word 2w) else I) o
                                    (if xs <> [] then insert 5 x else I)) t.locals)``,
  Induct_on `xs`
  THEN1 (fs [MemEqList_def,eq_eval,word_mem_eq_def])
  \\ fs [word_mem_eq_def]
  \\ rpt strip_tac
  \\ Cases_on `t.memory (a + offset)` \\ fs [isWord_def]
  \\ fs [MemEqList_def,eq_eval,word_mem_eq_def]
  \\ reverse IF_CASES_TAC
  THEN1 (fs [] \\ metis_tac [])
  \\ fs [] \\ rveq
  \\ full_simp_tac std_ss [GSYM WORD_ADD_ASSOC]
  \\ qmatch_goalsub_abbrev_tac `(MemEqList _ _, t6)`
  \\ first_x_assum (qspecl_then [`offset+bytes_in_word`,`t6`,`b`,`a`] mp_tac)
  \\ fs [Abbr`t6`,eq_eval]
  \\ strip_tac \\ fs []
  \\ Cases_on `b`
  \\ fs [wordSemTheory.state_component_equality]
  \\ rw [] \\ fs [insert_shadow]
  \\ metis_tac [])
  |> Q.SPEC `0w` |> SIMP_RULE std_ss [WORD_ADD_0];

val th = Q.store_thm("assign_EqualInt",
  `(?i. op = EqualInt i) ==> ^assign_thm_goal`,
  rpt strip_tac \\ rveq \\ fs []
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
  \\ clean_tac \\ fs []
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_1] \\ clean_tac
  \\ fs [get_var_def]
  \\ fs [Boolv_def] \\ rveq \\ fs [GSYM Boolv_def]
  \\ qpat_assum `state_rel c l1 l2 x t [] locs`
           (assume_tac o REWRITE_RULE [state_rel_thm])
  \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac
  \\ qmatch_asmsub_rename_tac `(Number j,a7)`
  \\ `?w. a7 = Word w` by
        (imp_res_tac memory_rel_any_Number_IMP \\ fs [] \\ NO_TAC)
  \\ rveq
  \\ rpt_drule memory_rel_Number_const_test
  \\ disch_then (qspec_then `i` mp_tac)
  \\ fs [assign_def,GSYM small_int_def]
  \\ IF_CASES_TAC THEN1
   (fs [get_vars_SOME_IFF_data,get_vars_SOME_IFF] \\ fs [eq_eval]
    \\ Cases_on `i = j` \\ fs [] \\ rveq \\ fs []
    \\ fs [lookup_insert,state_rel_thm] \\ rpt strip_tac
    \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ TRY (match_mp_tac memory_rel_Boolv_T \\ fs [])
    \\ TRY (match_mp_tac memory_rel_Boolv_F \\ fs []))
  \\ fs [] \\ TOP_CASE_TAC \\ fs []
  THEN1
   (fs [get_vars_SOME_IFF_data,get_vars_SOME_IFF] \\ fs [eq_eval]
    \\ fs [lookup_insert,state_rel_thm] \\ rpt strip_tac
    \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ TRY (match_mp_tac memory_rel_Boolv_T \\ fs [])
    \\ TRY (match_mp_tac memory_rel_Boolv_F \\ fs []))
  \\ fs [word_bit_test]
  \\ IF_CASES_TAC
  THEN1
   (fs [get_vars_SOME_IFF_data,get_vars_SOME_IFF] \\ fs [eq_eval]
    \\ fs [lookup_insert,state_rel_thm] \\ rpt strip_tac
    \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ TRY (match_mp_tac memory_rel_Boolv_T \\ fs [])
    \\ TRY (match_mp_tac memory_rel_Boolv_F \\ fs []))
  \\ strip_tac
  \\ fs [get_vars_SOME_IFF_data,get_vars_SOME_IFF]
  \\ fs [list_Seq_def,eq_eval]
  \\ rename1 `get_real_addr c t.store w = SOME a`
  \\ qmatch_goalsub_abbrev_tac `word_exp t6`
  \\ `get_real_addr c t6.store w = SOME a` by fs [Abbr`t6`]
  \\ drule (get_real_addr_lemma |> REWRITE_RULE [CONJ_ASSOC]
              |> ONCE_REWRITE_RULE [CONJ_COMM] |> GEN_ALL)
  \\ disch_then (qspec_then `(adjust_var a1)` mp_tac)
  \\ impl_tac THEN1 fs [Abbr `t6`,eq_eval]
  \\ strip_tac \\ fs []
  \\ qmatch_goalsub_abbrev_tac `(MemEqList 0w ws,t9)`
  \\ `word_mem_eq a ws t9.mdomain t9.memory = SOME (j = i)` by fs [Abbr`t9`,Abbr`ws`]
  \\ rpt_drule MemEqList_thm
  \\ impl_tac THEN1 fs [eq_eval,Abbr `t9`]
  \\ strip_tac \\ fs []
  \\ `ws <> []` by
     (fs [bignum_words_def,multiwordTheory.i2mw_def]
      \\ every_case_tac \\ fs [markerTheory.Abbrev_def] \\ fs [] \\ rveq \\ fs [])
  \\ fs []
  \\ IF_CASES_TAC \\ fs [] \\ rveq
  \\ unabbrev_all_tac
  \\ fs [lookup_insert,state_rel_thm] \\ rpt strip_tac
  \\ simp[inter_insert_ODD_adjust_set,GSYM Boolv_def]
  \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs []
  \\ TRY (match_mp_tac memory_rel_Boolv_T \\ fs [])
  \\ TRY (match_mp_tac memory_rel_Boolv_F \\ fs []));

val Equal_code_lemma = prove(
  ``(!c st dm m l v1 v2 t l1 l2 q1 q2 res l'.
      word_eq c st dm m l v1 v2 = SOME (res,l') /\
      dm = (t:('a,'b) wordSem$state).mdomain /\
      m = t.memory /\
      st = t.store /\
      l <= t.clock /\
      shift_length c < dimindex (:'a) /\
      lookup Equal_location t.code = SOME (3,Equal_code c) /\
      lookup Equal1_location t.code = SOME (4,Equal1_code) /\
      lookup Compare1_location t.code = SOME (4,Compare1_code) /\
      get_var 0 t = SOME (Loc l1 l2) /\
      get_var 2 t = SOME (Word (v1:'a word)) /\
      get_var 4 t = SOME (Word (v2:'a word)) /\
      c.len_size <> 0 /\
      c.len_size < dimindex (:α) /\
      good_dimindex (:'a) ==>
      ?ck new_p.
        evaluate (Equal_code c,t) =
          (SOME (Result (Loc l1 l2) (Word res)),
           t with <| clock := ck; locals := LN; permute := new_p |>) /\
        l' <= ck) /\
    (!c st dm m l w a1 a2 t l1 l2 res l'.
      word_eq_list c st dm m l w a1 a2 = SOME (res,l') /\
      dm = (t:('a,'b) wordSem$state).mdomain /\
      m = t.memory /\
      st = t.store /\
      l <= t.clock /\
      shift_length c < dimindex (:'a) /\
      lookup Equal_location t.code = SOME (3,Equal_code c) /\
      lookup Equal1_location t.code = SOME (4,Equal1_code) /\
      lookup Compare1_location t.code = SOME (4,Compare1_code) /\
      get_var 0 t = SOME (Loc l1 l2) /\
      get_var 2 t = SOME (Word (w:'a word)) /\
      get_var 4 t = SOME (Word (a1:'a word)) /\
      get_var 6 t = SOME (Word (a2:'a word)) /\
      c.len_size <> 0 /\
      c.len_size < dimindex (:α) /\
      good_dimindex (:'a) ==>
      ?ck new_p.
        evaluate (Equal1_code,t) =
          (SOME (Result (Loc l1 l2) (Word res)),
           t with <| clock := ck; locals := LN; permute := new_p |>) /\
        l' <= ck)``,
  ho_match_mp_tac word_eq_ind \\ reverse (rpt strip_tac) \\ rveq
  \\ qpat_x_assum `_ = SOME (res,_)` mp_tac
  \\ once_rewrite_tac [word_eq_def]
  THEN1
   (IF_CASES_TAC THEN1
     (fs [Equal1_code_def] \\ strip_tac \\ rveq
      \\ fs [eq_eval,list_Seq_def]
      \\ fs [wordSemTheory.state_component_equality])
    \\ IF_CASES_TAC \\ fs []
    \\ TOP_CASE_TAC \\ fs []
    \\ TOP_CASE_TAC \\ fs []
    \\ TOP_CASE_TAC \\ fs []
    \\ PairCases_on `x` \\ fs []
    \\ strip_tac
    \\ simp [Equal1_code_def]
    \\ ntac 4 (once_rewrite_tac [list_Seq_def])
    \\ fs [eq_eval]
    \\ TOP_CASE_TAC
    THEN1 (fs [wordSemTheory.cut_env_def,domain_lookup] \\ fs [])
    \\ qmatch_goalsub_abbrev_tac `(Equal_code c, t1)`
    \\ first_x_assum (qspecl_then [`t1`,`Equal1_location`,`1`] mp_tac)
    \\ impl_tac THEN1
     (unabbrev_all_tac \\ fs [lookup_insert,wordSemTheory.push_env_def]
      \\ pairarg_tac \\ fs [] \\ fs [eq_eval])
    \\ strip_tac \\ fs []
    \\ Cases_on `pop_env (t1 with <|permute := new_p; clock := ck|>)` \\ fs []
    THEN1
     (pop_assum mp_tac \\ unabbrev_all_tac
      \\ fs [eq_eval,
             wordSemTheory.push_env_def,
             wordSemTheory.pop_env_def]
      \\ pairarg_tac \\ fs [eq_eval])
    \\ rename1 `pop_env _ = SOME t2`
    \\ `t2.locals =
          (insert 0 (Loc l1 l2) o
           insert 2 (Word w) o
           insert 4 (Word a1) o
           insert 6 (Word a2)) LN` by
     (rveq \\ fs []
      \\ unabbrev_all_tac
      \\ fs [wordSemTheory.pop_env_def,wordSemTheory.push_env_def]
      \\ pairarg_tac \\ fs [] \\ rveq \\ fs []
      \\ imp_res_tac env_to_list_lookup_equiv
      \\ match_mp_tac IMP_spt_eq
      \\ fs [wf_fromAList,wf_insert,EVAL ``wf LN``]
      \\ fs [lookup_fromAList,lookup_insert,wordSemTheory.cut_env_def]
      \\ rveq \\ fs [lookup_inter_alt,lookup_insert]
      \\ rw [] \\ fs [lookup_def])
    \\ fs [] \\ imp_res_tac cut_env_IMP_domain \\ fs [eq_eval]
    \\ reverse IF_CASES_TAC THEN1
     (`F` by all_tac \\ fs [] \\ pop_assum mp_tac \\ fs []
      \\ fs [EXTENSION] \\ rw [] \\ EQ_TAC \\ rw [])
    \\ pop_assum kall_tac \\ fs []
    \\ once_rewrite_tac [list_Seq_def]
    \\ Cases_on `x0 ≠ 1w` \\ fs [eq_eval]
    THEN1
     (rveq \\ fs []
      \\ unabbrev_all_tac
      \\ fs [wordSemTheory.pop_env_def,wordSemTheory.push_env_def]
      \\ pairarg_tac \\ fs [] \\ rveq
      \\ fs [wordSemTheory.state_component_equality])
    \\ ntac 3 (once_rewrite_tac [list_Seq_def])
    \\ fs [eq_eval]
    \\ `t2.code = t.code /\ t2.clock = ck` by
     (unabbrev_all_tac
      \\ fs [wordSemTheory.pop_env_def,wordSemTheory.push_env_def]
      \\ pairarg_tac \\ fs [] \\ rveq
      \\ fs [wordSemTheory.state_component_equality,eq_eval])
    \\ rewrite_tac [list_Seq_def] \\ fs [eq_eval]
    \\ qmatch_goalsub_abbrev_tac `(Equal1_code, t5)`
    \\ first_x_assum (qspecl_then [`t5`,`l1`,`l2`] mp_tac)
    \\ impl_tac THEN1
     (unabbrev_all_tac
      \\ fs [wordSemTheory.pop_env_def,wordSemTheory.push_env_def]
      \\ pairarg_tac \\ fs [] \\ rveq
      \\ fs [wordSemTheory.state_component_equality,eq_eval])
    \\ strip_tac \\ fs []
    \\ rveq \\ fs []
    \\ unabbrev_all_tac
    \\ fs [wordSemTheory.pop_env_def,wordSemTheory.push_env_def]
    \\ pairarg_tac \\ fs [] \\ rveq
    \\ fs [wordSemTheory.state_component_equality])
  \\ rewrite_tac [Equal_code_def]
  \\ once_rewrite_tac [list_Seq_def]
  \\ Cases_on `v1 = v2` \\ fs []
  THEN1
   (strip_tac \\ rveq \\ fs [eq_eval]
    \\ fs [wordSemTheory.state_component_equality])
  \\ ntac 2 (once_rewrite_tac [list_Seq_def])
  \\ fs [eq_eval]
  \\ fs [GSYM (SIMP_CONV (srw_ss()) [word_bit_test] ``~word_bit 0 (w && w1)``)]
  \\ fs [word_bit_and]
  \\ IF_CASES_TAC
  THEN1 (fs [] \\ rw [] \\ fs [] \\ fs [wordSemTheory.state_component_equality])
  \\ fs [] \\ fs [word_header_def]
  \\ Cases_on `get_real_addr c t.store v1`
  \\ Cases_on `get_real_addr c t.store v2`
  \\ fs [] THEN1 (every_case_tac \\ fs [])
  \\ rename1 `get_real_addr c t.store v1 = SOME x1`
  \\ rename1 `get_real_addr c t.store v2 = SOME x2`
  \\ Cases_on `x1 IN t.mdomain` \\ fs []
  \\ Cases_on `t.memory x1` \\ fs []
  \\ Cases_on `x2 IN t.mdomain` \\ fs []
  \\ Cases_on `t.memory x2` \\ fs []
  \\ rename1 `t.memory x1 = Word c1`
  \\ rename1 `t.memory x2 = Word c2`
  (* first real_addr *)
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [eq_eval]
  \\ qmatch_goalsub_abbrev_tac `word_exp t6`
  \\ `get_real_addr c t6.store v1 = SOME x1` by fs [Abbr`t6`]
  \\ drule (get_real_addr_lemma |> REWRITE_RULE [CONJ_ASSOC]
              |> ONCE_REWRITE_RULE [CONJ_COMM] |> GEN_ALL)
  \\ disch_then (qspec_then `2` mp_tac)
  \\ impl_tac THEN1 fs [Abbr `t6`,eq_eval]
  \\ strip_tac \\ fs []
  (* second real_addr *)
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [eq_eval]
  \\ qmatch_goalsub_abbrev_tac `word_exp t7`
  \\ `get_real_addr c t7.store v2 = SOME x2` by fs [Abbr`t7`]
  \\ drule (get_real_addr_lemma |> REWRITE_RULE [CONJ_ASSOC]
              |> ONCE_REWRITE_RULE [CONJ_COMM] |> GEN_ALL)
  \\ disch_then (qspec_then `4` mp_tac)
  \\ impl_tac THEN1 fs [Abbr `t7`,eq_eval]
  \\ strip_tac \\ fs []
  (* -- *)
  \\ ntac 2 (once_rewrite_tac [list_Seq_def])
  \\ fs [eq_eval]
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [eq_eval]
  \\ reverse IF_CASES_TAC
  THEN1
   (pop_assum kall_tac \\ fs []
    \\ fs [] \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval]
    \\ IF_CASES_TAC THEN1
     (fs [] \\ strip_tac \\ rw [] \\ fs []
      \\ fs [wordSemTheory.state_component_equality])
    \\ fs [] \\ rveq
    \\ once_rewrite_tac [list_Seq_def] \\ fs [eq_eval,word_bit_test]
    \\ IF_CASES_TAC THEN1
     (fs [] \\ strip_tac \\ rw [] \\ fs []
      \\ fs [wordSemTheory.state_component_equality])
    \\ once_rewrite_tac [list_Seq_def]
    \\ once_rewrite_tac [list_Seq_def]
    \\ fs [eq_eval,word_bit_test]
    \\ qmatch_goalsub_abbrev_tac`COND test1`
    \\ `(24w && c1) = 16w ⇔ test1`
    by (
      simp[Abbr`test1`]
      \\ srw_tac[wordsLib.WORD_BIT_EQ_ss][]
      \\ rw[Once EQ_IMP_THM]
      >- (
        spose_not_then strip_assume_tac
        \\ first_x_assum(qspec_then`i`mp_tac)
        \\ simp[] \\ rfs[word_index] )
      >- (
        `4 < dimindex(:'a)` by fs[good_dimindex_def]
        \\ asm_exists_tac \\ fs[word_index]
        \\ metis_tac[] )
      >- (
        rfs[word_index]
        \\ `3 < dimindex(:'a)` by fs[good_dimindex_def]
        \\ metis_tac[] ))
    \\ pop_assum SUBST1_TAC \\ qunabbrev_tac`test1`
    \\ IF_CASES_TAC THEN1
     (fs [] \\ strip_tac \\ rw [] \\ fs []
      \\ fs [wordSemTheory.state_component_equality])
    \\ pop_assum kall_tac
    \\ fs [] \\ TOP_CASE_TAC \\ fs []
    \\ strip_tac \\ rveq \\ fs []
    \\ ntac 3 (once_rewrite_tac [list_Seq_def]) \\ fs [eq_eval]
    \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ fs [eq_eval]
    \\ fs [GSYM decode_length_def,shift_lsl]
    \\ ntac 3 (once_rewrite_tac [list_Seq_def]) \\ fs [eq_eval]
    \\ fs [GSYM NOT_LESS]
    \\ qmatch_goalsub_abbrev_tac `(Compare1_code, t9)`
    \\ drule Compare1_code_thm
    \\ disch_then (qspec_then `t9` mp_tac)
    \\ impl_tac THEN1 (fs [Abbr`t9`,eq_eval])
    \\ strip_tac \\ fs []
    \\ fs [wordSemTheory.state_component_equality,Abbr`t9`])
  \\ fs []
  \\ qpat_abbrev_tac `other_case = list_Seq _`
  \\ pop_assum kall_tac
  \\ fs [word_is_clos_def]
  \\ strip_tac
  \\ ntac 2 (once_rewrite_tac [list_Seq_def]) \\ fs [eq_eval]
  \\ IF_CASES_TAC
  THEN1 (fs [] \\ rveq \\ fs [wordSemTheory.state_component_equality])
  \\ ntac 1 (once_rewrite_tac [list_Seq_def]) \\ fs [eq_eval]
  \\ IF_CASES_TAC
  THEN1 (fs [] \\ rveq \\ fs [wordSemTheory.state_component_equality])
  \\ fs []
  \\ ntac 1 (once_rewrite_tac [list_Seq_def]) \\ fs [eq_eval]
  \\ reverse IF_CASES_TAC
  THEN1 (fs [] \\ rveq \\ fs [wordSemTheory.state_component_equality])
  \\ fs []
  \\ ntac 4 (once_rewrite_tac [list_Seq_def]) \\ fs [eq_eval]
  \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ fs [eq_eval]
  \\ fs [GSYM decode_length_def,shift_lsl]
  \\ qmatch_goalsub_abbrev_tac `(Equal1_code,t8)`
  \\ first_x_assum (qspecl_then [`t8`,`l1`,`l2`] mp_tac)
  \\ impl_tac THEN1 (unabbrev_all_tac \\ fs [eq_eval])
  \\ strip_tac \\ fs []
  \\ fs [Abbr`t8`,wordSemTheory.state_component_equality]);

val Equal_code_thm = store_thm("Equal_code_thm",
  ``memory_rel c be refs sp st m dm ((q1,Word v1)::(q2,Word v2)::vars) /\
    word_eq c st dm m l v1 v2 = SOME (res,l') /\
    dm = (t:('a,'b) wordSem$state).mdomain /\
    m = t.memory /\
    st = t.store /\
    l <= t.clock /\
    shift_length c < dimindex (:'a) /\
    lookup Equal_location t.code = SOME (3,Equal_code c) /\
    lookup Equal1_location t.code = SOME (4,Equal1_code) /\
    lookup Compare1_location t.code = SOME (4,Compare1_code) /\
    get_var 0 t = SOME (Loc l1 l2) /\
    get_var 2 t = SOME (Word (v1:'a word)) /\
    get_var 4 t = SOME (Word (v2:'a word)) /\
    c.len_size <> 0 /\
    c.len_size < dimindex (:α) /\
    good_dimindex (:'a) ==>
    ?ck new_p.
      evaluate (Equal_code c,t) =
        (SOME (Result (Loc l1 l2) (Word res)),
         t with <| clock := ck; locals := LN; permute := new_p |>) /\
      l' <= ck``,
  strip_tac
  \\ match_mp_tac (Equal_code_lemma |> CONJUNCT1)
  \\ fs [] \\ asm_exists_tac \\ fs []);

val th = Q.store_thm("assign_Equal" ,
  `op = Equal ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
  \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
  \\ clean_tac \\ fs []
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [LENGTH_EQ_2] \\ clean_tac
  \\ fs [get_var_def]
  \\ fs [Boolv_def] \\ rveq \\ fs [GSYM Boolv_def]
  \\ qpat_assum `state_rel c l1 l2 x t [] locs`
           (assume_tac o REWRITE_RULE [state_rel_thm])
  \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac
  \\ rename1 `memory_rel _ _ _ _ _ _ _ ((h_1,a_1)::(h_2,a_2)::_)`
  \\ rpt_drule memory_rel_simple_eq
  \\ strip_tac \\ rveq \\ fs []
  \\ fs [get_vars_SOME_IFF_data,get_vars_SOME_IFF]
  \\ fs [wordSemTheory.get_var_def]
  \\ fs [assign_def,list_Seq_def] \\ eval_tac
  \\ fs [lookup_insert,wordSemTheory.get_var_def,wordSemTheory.get_var_imm_def,
         word_cmp_Test_1,word_bit_and]
  \\ IF_CASES_TAC THEN1
   (first_x_assum drule \\ pop_assum kall_tac \\ strip_tac
    \\ fs [lookup_insert,wordSemTheory.get_var_imm_def,asmTheory.word_cmp_def]
    \\ IF_CASES_TAC \\ fs []
    \\ fs [state_rel_thm]
    \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ simp[inter_insert_ODD_adjust_set,GSYM Boolv_def]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ TRY (match_mp_tac memory_rel_Boolv_T \\ fs [])
    \\ TRY (match_mp_tac memory_rel_Boolv_F \\ fs [])
    \\ match_mp_tac (GEN_ALL memory_rel_zero_space)
    \\ metis_tac [])
  \\ IF_CASES_TAC THEN1
   (fs [lookup_insert,asmTheory.word_cmp_def]
    \\ rpt_drule memory_rel_ptr_eq \\ rw [] \\ rveq \\ fs []
    \\ fs [state_rel_thm]
    \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ simp[inter_insert_ODD_adjust_set,GSYM Boolv_def]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ TRY (match_mp_tac memory_rel_Boolv_T \\ fs [])
    \\ TRY (match_mp_tac memory_rel_Boolv_F \\ fs [])
    \\ match_mp_tac (GEN_ALL memory_rel_zero_space)
    \\ metis_tac [])
  \\ fs []
  \\ rpt_drule word_eq_thm
  \\ strip_tac
  \\ rpt_drule (Equal_code_thm |> INST_TYPE [``:'b``|->``:'ffi``])
  \\ strip_tac
  \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def,lookup_insert,
         wordSemTheory.bad_dest_args_def,wordSemTheory.find_code_def]
  \\ `lookup Equal_location t.code = SOME (3,Equal_code c)` by
       (fs [state_rel_def,code_rel_def,stubs_def] \\ NO_TAC)
  \\ fs [wordSemTheory.add_ret_loc_def]
  \\ fs [bvi_to_dataTheory.op_requires_names_def,
         bvi_to_dataTheory.op_space_reset_def]
  \\ TOP_CASE_TAC THEN1
   (Cases_on `names_opt` \\ fs []
    \\ fs [cut_state_opt_def,cut_state_def]
    \\ Cases_on `dataSem$cut_env x' s.locals` \\ fs []
    \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` assume_tac
    \\ rpt_drule cut_env_IMP_cut_env
    \\ CCONTR_TAC \\ fs [get_names_def]
    \\ fs [wordSemTheory.cut_env_def,SUBSET_DEF])
  \\ fs []
  \\ qpat_abbrev_tac `t1 = wordSem$call_env _ _`
  \\ first_x_assum (qspecl_then [`t1`,`l`,`n`] mp_tac)
  \\ impl_tac THEN1
   (unabbrev_all_tac
    \\ fs [wordSemTheory.call_env_def,wordSemTheory.push_env_def,
           wordSemTheory.dec_clock_def]
    \\ pairarg_tac \\ fs []
    \\ fs [fromList2_def,lookup_insert]
    \\ fs [state_rel_def,code_rel_def,stubs_def]
    \\ fs [memory_rel_def,word_ml_inv_def,heap_in_memory_store_def])
  \\ strip_tac \\ fs []
  \\ `?t2. pop_env (t1 with <|permute := new_p; clock := ck|>) = SOME t2 /\
           domain t2.locals = domain x'` by
   (unabbrev_all_tac
    \\ fs [wordSemTheory.call_env_def,wordSemTheory.push_env_def,
           wordSemTheory.pop_env_def] \\ pairarg_tac \\ fs []
    \\ imp_res_tac env_to_list_lookup_equiv
    \\ fs [domain_lookup,EXTENSION,lookup_fromAList] \\ NO_TAC)
  \\ fs []
  \\ fs [lookup_insert,asmTheory.word_cmp_def] \\ rveq
  \\ rw [] \\ fs []
  \\ unabbrev_all_tac
  \\ fs [wordSemTheory.pop_env_def,wordSemTheory.call_env_def,
         wordSemTheory.push_env_def,wordSemTheory.dec_clock_def]
  \\ pairarg_tac \\ fs [] \\ rveq \\ fs []
  \\ simp [state_rel_thm]
  \\ fs [lookup_insert]
  \\ rpt_drule env_to_list_cut_env_IMP \\ fs []
  \\ disch_then kall_tac
  \\ fs [lookup_insert,FAPPLY_FUPDATE_THM,adjust_var_11,FLOOKUP_UPDATE]
  \\ fs [inter_insert_ODD_adjust_set]
  \\ fs [wordSemTheory.cut_env_def] \\ rveq
  \\ conj_tac
  \\ TRY (fs [lookup_inter,lookup_insert,adjust_set_def,fromAList_def] \\ NO_TAC)
  \\ `domain (adjust_set (get_names names_opt)) SUBSET domain t.locals` by
   (Cases_on `names_opt` \\ fs [get_names_def]
    \\ fs [SUBSET_DEF,domain_lookup]
    \\ rw [] \\ res_tac \\ fs []
    \\ rveq \\ fs [lookup_ODD_adjust_set] \\ NO_TAC)
  \\ `domain (adjust_set x.locals) SUBSET
      domain (inter t.locals (adjust_set (get_names names_opt)))` by
   (fs [SUBSET_DEF,domain_lookup,lookup_inter_alt] \\ rw []
    \\ Cases_on `names_opt` \\ fs [get_names_def]
    \\ fs [SUBSET_DEF,domain_lookup]
    \\ fs [cut_state_opt_def,cut_state_def,cut_env_def]
    \\ qpat_x_assum `_ = SOME x` mp_tac
    \\ IF_CASES_TAC \\ fs [] \\ rw [] \\ fs [adjust_set_inter]
    \\ fs [lookup_inter_alt,domain_lookup] \\ NO_TAC)
  \\ `!n. IS_SOME (lookup n x.locals) ==>
          n ∈ domain (get_names names_opt) /\
          IS_SOME (lookup (adjust_var n) t.locals)` by
   (qx_gen_tac `k` \\ disch_then assume_tac
    \\ Cases_on `lookup k x.locals` \\ fs []
    \\ Cases_on `names_opt` \\ fs [get_names_def]
    \\ fs [SUBSET_DEF,domain_lookup]
    \\ fs [cut_state_opt_def,cut_state_def,cut_env_def]
    \\ qpat_x_assum `_ = SOME x` mp_tac
    \\ IF_CASES_TAC \\ fs [] \\ rw [] \\ fs [adjust_set_inter]
    \\ fs [lookup_inter_alt,domain_lookup] \\ NO_TAC)
  \\ conj_tac
  \\ TRY (rw [] \\ once_rewrite_tac [lookup_inter_alt]
          \\ fs [lookup_insert,adjust_var_IN_adjust_set] \\ NO_TAC)
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs [inter_insert_ODD_adjust_set_alt]
  \\ match_mp_tac (GEN_ALL memory_rel_zero_space)
  \\ qexists_tac `x.space`
  \\ TRY (match_mp_tac memory_rel_Boolv_T)
  \\ TRY (match_mp_tac memory_rel_Boolv_F) \\ fs []
  \\ qsuff_tac `inter (inter t.locals (adjust_set (get_names names_opt)))
                 (adjust_set x.locals) = inter t.locals (adjust_set x.locals)`
  \\ asm_simp_tac std_ss [] \\ fs []
  \\ fs [lookup_inter_alt,SUBSET_DEF]
  \\ rw [] \\ fs [domain_inter] \\ res_tac);

val th = Q.store_thm("assign_WordOpW8",
  `(?opw. op = WordOp W8 opw) ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH
  \\ fs[do_app]
  \\ every_case_tac \\ fs[]
  \\ clean_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_2]
  \\ clean_tac
  \\ fs[state_rel_thm] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac
  \\ qhdtm_x_assum`$some`mp_tac
  \\ DEEP_INTRO_TAC some_intro \\ fs[]
  \\ strip_tac \\ clean_tac
  \\ qmatch_asmsub_rename_tac`[Number (&w2n w1); Number (&w2n w2)]`
  \\ `small_int (:'a) (&w2n w1) ∧ small_int (:'a) (&w2n w2)`
  by1 ( simp[small_int_w2n] )
  \\ imp_res_tac memory_rel_Number_IMP
  \\ imp_res_tac memory_rel_tl
  \\ imp_res_tac memory_rel_Number_IMP
  \\ qhdtm_x_assum`memory_rel`kall_tac
  \\ ntac 2 (first_x_assum(qspec_then`ARB`kall_tac))
  \\ fs[wordSemTheory.get_vars_def]
  \\ every_case_tac \\ fs[] \\ clean_tac
  \\ simp[assign_def] \\ eval_tac
  \\ fs[wordSemTheory.get_var_def]
  \\ Cases_on`opw` \\ simp[] \\ eval_tac \\ fs[lookup_insert]
  \\ (conj_tac >- rw[])
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs[]
  >- ( match_mp_tac memory_rel_And \\ fs[] )
  >- ( match_mp_tac memory_rel_Or \\ fs[] )
  >- ( match_mp_tac memory_rel_Xor \\ fs[] )
  >- (
    qmatch_goalsub_abbrev_tac`Word w`
    \\ qmatch_goalsub_abbrev_tac`Number i`
    \\ `w = Smallnum i`
    by (
      unabbrev_all_tac
      \\ qmatch_goalsub_rename_tac`w2n (w1 + w2)`
      \\ simp[Smallnum_i2w,integer_wordTheory.i2w_def]
      \\ simp[WORD_MUL_LSL]
      \\ ONCE_REWRITE_TAC[GSYM n2w_w2n]
      \\ REWRITE_TAC[w2n_lsr]
      \\ simp[word_mul_n2w,word_add_n2w]
      \\ Cases_on`w1` \\ Cases_on`w2` \\ fs[word_add_n2w]
      \\ fs[good_dimindex_def,dimword_def,GSYM LEFT_ADD_DISTRIB]
      \\ qmatch_goalsub_abbrev_tac`(a * b) MOD f DIV d`
      \\ qspecl_then[`a * b`,`d`,`f DIV d`]mp_tac (GSYM DIV_MOD_MOD_DIV)
      \\ simp[Abbr`a`,Abbr`d`,Abbr`f`] \\ disch_then kall_tac
      \\ qmatch_goalsub_abbrev_tac`d * b DIV f`
      \\ `d * b = (b * (d DIV f)) * f`
      by simp[Abbr`d`,Abbr`f`]
      \\ pop_assum SUBST_ALL_TAC
      \\ qspecl_then[`f`,`b * (d DIV f)`]mp_tac MULT_DIV
      \\ (impl_tac >- simp[Abbr`f`])
      \\ disch_then SUBST_ALL_TAC
      \\ simp[Abbr`d`,Abbr`f`]
      \\ qmatch_goalsub_abbrev_tac`a * b MOD q`
      \\ qspecl_then[`a`,`b`,`q`]mp_tac MOD_COMMON_FACTOR
      \\ (impl_tac >- simp[Abbr`a`,Abbr`q`])
      \\ disch_then SUBST_ALL_TAC
      \\ simp[Abbr`a`,Abbr`q`])
    \\ pop_assum SUBST_ALL_TAC
    \\ match_mp_tac IMP_memory_rel_Number
    \\ fs[]
    \\ fs[Abbr`i`,small_int_def]
    \\ qmatch_goalsub_rename_tac`w2n w`
    \\ Q.ISPEC_THEN`w`mp_tac w2n_lt
    \\ fs[good_dimindex_def,dimword_def] )
  >- (
    qmatch_goalsub_abbrev_tac`Word w`
    \\ qmatch_goalsub_abbrev_tac`Number i`
    \\ `w = Smallnum i`
    by (
      unabbrev_all_tac
      \\ qmatch_goalsub_rename_tac`w2n (w1 + -1w * w2)`
      \\ simp[Smallnum_i2w,integer_wordTheory.i2w_def]
      \\ simp[WORD_MUL_LSL]
      \\ ONCE_REWRITE_TAC[GSYM n2w_w2n]
      \\ REWRITE_TAC[w2n_lsr]
      \\ simp[word_mul_n2w,word_add_n2w]
      \\ REWRITE_TAC[WORD_SUB_INTRO,WORD_MULT_CLAUSES]
      \\ Cases_on`w1` \\ Cases_on`w2`
      \\ REWRITE_TAC[addressTheory.word_arith_lemma2]
      \\ reverse(rw[]) \\ fs[NOT_LESS,GSYM LEFT_SUB_DISTRIB,GSYM RIGHT_SUB_DISTRIB]
      >- (
        qmatch_goalsub_abbrev_tac`(a * b) MOD f DIV d`
        \\ qspecl_then[`a * b`,`d`,`f DIV d`]mp_tac (GSYM DIV_MOD_MOD_DIV)
        \\ (impl_tac >- fs[Abbr`d`,Abbr`f`,good_dimindex_def,dimword_def])
        \\ `d * (f DIV d) = f` by fs[good_dimindex_def,Abbr`f`,Abbr`d`,dimword_def]
        \\ pop_assum SUBST_ALL_TAC
        \\ disch_then (CHANGED_TAC o SUBST_ALL_TAC)
        \\ unabbrev_all_tac
        \\ qmatch_goalsub_abbrev_tac`a * (b * d) DIV d`
        \\ `a * (b * d) DIV d = a * b`
        by (
          qspecl_then[`d`,`a * b`]mp_tac MULT_DIV
          \\ impl_tac >- simp[Abbr`d`]
          \\ simp[] )
        \\ pop_assum SUBST_ALL_TAC
        \\ fs[Abbr`a`,Abbr`d`,dimword_def,good_dimindex_def]
        \\ qmatch_goalsub_abbrev_tac`(a * b) MOD q`
        \\ qspecl_then[`a`,`b`,`q DIV a`](mp_tac o GSYM) MOD_COMMON_FACTOR
        \\ (impl_tac >- simp[Abbr`a`,Abbr`q`])
        \\ simp[Abbr`a`,Abbr`q`] \\ disch_then kall_tac
        \\ `b < 256` by simp[Abbr`b`]
        \\ simp[] )
      \\ simp[word_2comp_n2w]
      \\ qmatch_goalsub_abbrev_tac`(4 * (b * d)) MOD f`
      \\ qmatch_goalsub_abbrev_tac`f - y MOD f`
      \\ `f = d * 2**10`
      by (
        unabbrev_all_tac
        \\ fs[dimword_def,good_dimindex_def] )
      \\ qunabbrev_tac`f`
      \\ pop_assum SUBST_ALL_TAC
      \\ fs[]
      \\ qmatch_goalsub_abbrev_tac`m MOD (1024 * d) DIV d`
      \\ qspecl_then[`m`,`d`,`1024`]mp_tac DIV_MOD_MOD_DIV
      \\ impl_tac >- simp[Abbr`d`] \\ simp[]
      \\ disch_then(CHANGED_TAC o SUBST_ALL_TAC o SYM)
      \\ qspecl_then[`1024 * d`,`(m DIV d) MOD 1024`]mp_tac LESS_MOD
      \\ impl_tac
      >- (
        qspecl_then[`m DIV d`,`1024`]mp_tac MOD_LESS
        \\ impl_tac >- simp[]
        \\ `1024 < 1024 * d`
        by (
          simp[Abbr`d`,ONE_LT_EXP]
          \\ fs[good_dimindex_def] )
        \\ decide_tac )
      \\ disch_then (CHANGED_TAC o SUBST_ALL_TAC)
      \\ fs[Abbr`m`,Abbr`y`]
      \\ qspecl_then[`d`,`4 * b`,`1024`]mp_tac MOD_COMMON_FACTOR
      \\ impl_tac >- simp[Abbr`d`] \\ simp[]
      \\ disch_then(CHANGED_TAC o SUBST_ALL_TAC o SYM)
      \\ qmatch_assum_rename_tac`n2 < 256n`
      \\ `n2 <= 256` by simp[]
      \\ drule LESS_EQ_ADD_SUB
      \\ qmatch_assum_rename_tac`n1 < n2`
      \\ disch_then(qspec_then`n1`(CHANGED_TAC o SUBST_ALL_TAC))
      \\ REWRITE_TAC[LEFT_ADD_DISTRIB]
      \\ simp[LEFT_SUB_DISTRIB,Abbr`b`]
      \\ `4 * (d * n2) - 4 * (d * n1) = (4 * d) * (n2 - n1)` by simp[]
      \\ pop_assum (CHANGED_TAC o SUBST_ALL_TAC)
      \\ `1024 * d - 4 * d * (n2 - n1) = (1024 - 4 * (n2 - n1)) * d` by simp[]
      \\ pop_assum (CHANGED_TAC o SUBST_ALL_TAC)
      \\ `0 < d` by simp[Abbr`d`]
      \\ drule MULT_DIV
      \\ disch_then(CHANGED_TAC o (fn th => REWRITE_TAC[th]))
      \\ simp[])
    \\ pop_assum SUBST_ALL_TAC
    \\ match_mp_tac IMP_memory_rel_Number
    \\ fs[]
    \\ fs[Abbr`i`,small_int_def]
    \\ qmatch_goalsub_rename_tac`w2n w`
    \\ Q.ISPEC_THEN`w`mp_tac w2n_lt
    \\ fs[good_dimindex_def,dimword_def] ));

val assign_WordOp64 =
  ``assign c n l dest (WordOp W64 opw) [e1; e2] names_opt``
  |> SIMP_CONV (srw_ss()) [assign_def]

val mw2n_2_IMP = prove(
  ``mw2n [w1;w2:'a word] = n ==>
    w2 = n2w (n DIV dimword (:'a)) /\
    w1 = n2w n``,
  fs [multiwordTheory.mw2n_def] \\ rw []
  \\ Cases_on `w1` \\ Cases_on `w2` \\ fs []
  \\ once_rewrite_tac [ADD_COMM]
  \\ asm_simp_tac std_ss [DIV_MULT]);

val IMP_mw2n_2 = prove(
  ``Abbrev (x2 = (63 >< 32) (n2w n:word64)) /\
    Abbrev (x1 = (31 >< 0) (n2w n:word64)) /\
    n < dimword (:64) /\ dimindex (:'a) = 32 ==>
    mw2n [x1;x2:'a word] = n``,
  fs [markerTheory.Abbrev_def]
  \\ rw [multiwordTheory.mw2n_def]
  \\ fs [word_extract_n2w]
  \\ fs [bitTheory.BITS_THM2,dimword_def]
  \\ fs [DIV_MOD_MOD_DIV]
  \\ once_rewrite_tac [EQ_SYM_EQ]
  \\ simp [Once (MATCH_MP DIVISION (DECIDE ``0 < 4294967296n``))]);

val evaluate_WordOp64_on_32 = prove(
  ``!l.
    dimindex (:'a) = 32 ==>
    ?w27 w29.
      evaluate
       (WordOp64_on_32 opw,
        (t:('a,'ffi) wordSem$state) with
        locals :=
          insert 23 (Word ((31 >< 0) c''))
            (insert 21 (Word ((63 >< 32) c''))
               (insert 13 (Word ((31 >< 0) c'))
                  (insert 11 (Word ((63 >< 32) c')) l)))) =
     (NONE,t with locals :=
       insert 31 (Word ((63 >< 32) (opw_lookup opw c' c'')))
        (insert 33 (Word ((31 >< 0) (opw_lookup opw (c':word64) (c'':word64))))
          (insert 27 w27
            (insert 29 w29
              (insert 23 (Word ((31 >< 0) c''))
                (insert 21 (Word ((63 >< 32) c''))
                  (insert 13 (Word ((31 >< 0) c'))
                    (insert 11 (Word ((63 >< 32) c')) l))))))))``,
  Cases_on `opw`
  \\ fs [WordOp64_on_32_def,semanticPrimitivesPropsTheory.opw_lookup_def,
         list_Seq_def]
  \\ eval_tac \\ fs [lookup_insert]
  \\ fs [wordSemTheory.state_component_equality]
  \\ fs [GSYM WORD_EXTRACT_OVER_BITWISE]
  THEN1 metis_tac []
  THEN1 metis_tac []
  THEN1 metis_tac []
  \\ fs [wordSemTheory.inst_def,wordSemTheory.get_vars_def,lookup_insert,
         wordSemTheory.set_var_def,wordSemTheory.get_var_def]
  THEN1
   (qpat_abbrev_tac `c1 <=> dimword (:α) ≤
                    w2n ((31 >< 0) c') + w2n ((31 >< 0) c'')`
    \\ qpat_abbrev_tac `c2 <=> dimword (:α) ≤ _`
    \\ rpt strip_tac
    \\ qexists_tac `(Word 0w)`
    \\ qexists_tac `(Word (if c2 then 1w else 0w))`
    \\ AP_THM_TAC \\ AP_TERM_TAC \\ AP_TERM_TAC
    \\ simp [Once (Q.SPECL [`29`,`31`] insert_insert)]
    \\ simp [Once (Q.SPECL [`29`,`29`] insert_insert)]
    \\ simp [Once (Q.SPECL [`29`,`33`] insert_insert)]
    \\ simp [Once (Q.SPECL [`29`,`29`] insert_insert)]
    \\ simp [Once (Q.SPECL [`29`,`27`] insert_insert)]
    \\ simp [Once (Q.SPECL [`29`,`29`] insert_insert)]
    \\ qmatch_goalsub_abbrev_tac `insert 31 (Word w1)`
    \\ qmatch_goalsub_abbrev_tac `insert 33 (Word w2)`
    \\ qsuff_tac `w1 = (63 >< 32) (c' + c'') /\ w2 = (31 >< 0) (c' + c'')`
    THEN1 fs []
    \\ Cases_on `c'`
    \\ Cases_on `c''`
    \\ fs [word_add_n2w]
    \\ fs [word_extract_n2w]
    \\ fs [bitTheory.BITS_THM2,dimword_def] \\ rfs []
    \\ unabbrev_all_tac
    \\ reverse conj_tac
    THEN1 (once_rewrite_tac [GSYM n2w_mod] \\ fs [dimword_def])
    \\ strip_assume_tac (Q.SPEC `n` (MATCH_MP DIVISION (DECIDE ``0 < 4294967296n``))
                         |> ONCE_REWRITE_RULE [CONJ_COMM])
    \\ pop_assum (fn th => ONCE_REWRITE_TAC [th])
    \\ simp_tac std_ss [DIV_MULT,DIV_MOD_MOD_DIV
          |> Q.SPECL [`m`,`4294967296`,`4294967296`]
          |> SIMP_RULE std_ss [] |> GSYM,MOD_MULT]
    \\ strip_assume_tac (Q.SPEC `n'` (MATCH_MP DIVISION (DECIDE ``0 < 4294967296n``))
                         |> ONCE_REWRITE_RULE [CONJ_COMM])
    \\ pop_assum (fn th => ONCE_REWRITE_TAC [th])
    \\ simp_tac std_ss [DIV_MULT,DIV_MOD_MOD_DIV
          |> Q.SPECL [`m`,`4294967296`,`4294967296`]
          |> SIMP_RULE std_ss [] |> GSYM,MOD_MULT]
    \\ once_rewrite_tac [DECIDE ``(m1+n1)+(m2+n2)=m1+(m2+(n1+n2:num))``]
    \\ simp_tac std_ss [ADD_DIV_ADD_DIV]
    \\ simp [dimword_def]
    \\ AP_THM_TAC \\ AP_TERM_TAC
    \\ AP_TERM_TAC \\ AP_TERM_TAC
    \\ once_rewrite_tac [EQ_SYM_EQ]
    \\ fs [DIV_EQ_X]
    \\ CASE_TAC \\ fs []
    \\ `n MOD 4294967296 < 4294967296` by fs []
    \\ `n' MOD 4294967296 < 4294967296` by fs []
    \\ decide_tac)
  \\ qpat_abbrev_tac `c1 <=> dimword (:α) ≤ _ + (_ + 1)`
  \\ qpat_abbrev_tac `c2 <=> dimword (:α) ≤ _`
  \\ rpt strip_tac
  \\ qexists_tac `(Word (¬(63 >< 32) c''))`
  \\ qexists_tac `(Word (if c2 then 1w else 0w))`
  \\ AP_THM_TAC \\ AP_TERM_TAC \\ AP_TERM_TAC
  \\ simp [Once (Q.SPECL [`29`,`31`] insert_insert)]
  \\ simp [Once (Q.SPECL [`29`,`31`] insert_insert),insert_shadow]
  \\ simp [(Q.SPECL [`29`,`33`] insert_insert)]
  \\ simp [(Q.SPECL [`27`,`33`] insert_insert)]
  \\ simp [(Q.SPECL [`29`,`33`] insert_insert)]
  \\ simp [(Q.SPECL [`29`,`27`] insert_insert),insert_shadow]
  \\ qmatch_goalsub_abbrev_tac `insert 31 (Word w1)`
  \\ qmatch_goalsub_abbrev_tac `insert 33 (Word w2)`
  \\ qsuff_tac `w1 = (63 >< 32) (c' - c'') /\ w2 = (31 >< 0) (c' - c'')`
  THEN1 fs [insert_shadow]
  \\ qabbrev_tac `x2 = (63 >< 32) c'`
  \\ qabbrev_tac `x1 = (31 >< 0) c'`
  \\ qabbrev_tac `y2 = (63 >< 32) c''`
  \\ qabbrev_tac `y1 = (31 >< 0) c''`
  \\ `?c. mw_sub [x1;x2] [y1;y2] T = ([w2;w1],c)` by
    (fs [multiwordTheory.mw_sub_def,multiwordTheory.single_sub_def,
         multiwordTheory.single_add_def,EVAL ``multiword$b2w T``]
     \\ fs [GSYM word_add_n2w,multiwordTheory.b2n_def]
     \\ Cases_on `c1` \\ fs [multiwordTheory.b2w_def,multiwordTheory.b2n_def])
  \\ drule multiwordTheory.mw_sub_lemma
  \\ fs [multiwordTheory.b2n_def,multiwordTheory.dimwords_def]
  \\ strip_tac
  \\ drule (DECIDE ``m+(w+r)=k ==> w = k-m-r:num``)
  \\ strip_tac
  \\ drule mw2n_2_IMP
  \\ simp []
  \\ disch_then kall_tac
  \\ pop_assum kall_tac
  \\ Cases_on `c'`
  \\ Cases_on `c''`
  \\ `mw2n [x1;x2] = n /\ mw2n [y1;y2] = n'` by
    (rw [] \\ match_mp_tac IMP_mw2n_2 \\ fs [] \\ fs [markerTheory.Abbrev_def])
  \\ fs [] \\ ntac 2 (pop_assum kall_tac)
  \\ rewrite_tac [GSYM (SIMP_CONV (srw_ss()) [] ``w-x``)]
  \\ rewrite_tac [word_sub_def,word_2comp_n2w,word_add_n2w]
  \\ fs [word_extract_n2w]
  \\ fs [bitTheory.BITS_THM2,dimword_def] \\ rfs []
  \\ fs [DIV_MOD_MOD_DIV]
  \\ once_rewrite_tac [
      Q.SPECL [`4294967296`,`4294967296`] MOD_MULT_MOD
      |> SIMP_RULE std_ss [] |> GSYM]
  \\ qsuff_tac `(n + 18446744073709551616 − (n' + 18446744073709551616 * b2n c))
        MOD 18446744073709551616 =
      (n + 18446744073709551616 − n') MOD 18446744073709551616`
  THEN1 fs []
  \\ Cases_on `c` \\ fs [multiwordTheory.b2n_def]
  \\ `n' <= n` by decide_tac
  \\ fs [LESS_EQ_EXISTS]);

val th = Q.store_thm("assign_WordOpW64",
  `(?opw. op = WordOp W64 opw) ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH
  \\ fs[do_app]
  \\ every_case_tac \\ fs[]
  \\ clean_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_2]
  \\ clean_tac
  \\ fs[state_rel_thm] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac
  \\ fs[wordSemTheory.get_vars_def]
  \\ every_case_tac \\ fs[] \\ clean_tac
  \\ drule memory_rel_Word64_IMP
  \\ imp_res_tac memory_rel_tl
  \\ drule memory_rel_Word64_IMP
  \\ qhdtm_x_assum`memory_rel`kall_tac
  \\ simp[] \\ ntac 2 strip_tac
  \\ clean_tac
  \\ simp [assign_WordOp64(*assign_def*)]
  \\ Cases_on `dimindex (:'a) = 64` \\ simp [] THEN1
   (TOP_CASE_TAC \\ fs [] \\ clean_tac
    \\ eval_tac
    \\ `shift_length c < dimindex (:α)` by (fs [memory_rel_def] \\ NO_TAC)
    \\ rpt_drule get_var_get_real_addr_lemma
    \\ qpat_x_assum `get_var (adjust_var e2) t =
         SOME (Word (get_addr c ptr (Word 0w)))` assume_tac
    \\ rpt_drule get_var_get_real_addr_lemma
    \\ qpat_abbrev_tac`sow = word_op_CASE opw _ _ _ _ _`
    \\ qpat_abbrev_tac`sw = _ sow _ _ _ _ _`
    \\ qpat_abbrev_tac `w64 = opw_lookup opw _ _`
    \\ `sw = SOME (w2w w64)`
    by (
      simp[Abbr`sow`,Abbr`sw`,Abbr`w64`]
      \\ Cases_on`opw` \\ simp[]
      \\ simp[WORD_w2w_EXTRACT,WORD_EXTRACT_OVER_BITWISE]
      \\ fs[good_dimindex_def,WORD_EXTRACT_OVER_ADD,WORD_EXTRACT_OVER_MUL]
      \\ qpat_abbrev_tac`neg1 = (_ >< _) (-1w)`
      \\ `neg1 = -1w`
      by ( srw_tac[wordsLib.WORD_BIT_EQ_ss][Abbr`neg1`] )
      \\ pop_assum SUBST_ALL_TAC
      \\ simp[] )
    \\ qunabbrev_tac`sw` \\ pop_assum SUBST_ALL_TAC
    \\ simp[wordSemTheory.get_var_def,lookup_insert]
    \\ rpt strip_tac
    \\ assume_tac (GEN_ALL evaluate_WriteWord64)
    \\ SEP_I_TAC "evaluate"
    \\ pop_assum mp_tac \\ fs [join_env_locals_def]
    \\ fs [wordSemTheory.get_var_def,lookup_insert]
    \\ fs [inter_insert_ODD_adjust_set_alt]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
    \\ disch_then drule
    \\ impl_tac THEN1 fs [consume_space_def]
    \\ strip_tac \\ fs []
    \\ fs[FAPPLY_FUPDATE_THM]
    \\ fs [consume_space_def]
    \\ rveq \\ fs []
    \\ conj_tac THEN1 (rw [] \\ fs [])
    \\ `w2w ((w2w w64):'a word) = w64` by
      (Cases_on `w64` \\ fs [w2w_def,dimword_def])
    \\ fs []
    \\ match_mp_tac (GEN_ALL memory_rel_less_space) \\ fs []
    \\ asm_exists_tac \\ fs [])
  \\ TOP_CASE_TAC \\ fs []
  \\ `dimindex (:'a) = 32` by rfs [good_dimindex_def] \\ fs [] \\ rveq
  \\ eval_tac
  \\ `shift_length c < dimindex (:α)` by (fs [memory_rel_def] \\ NO_TAC)
  \\ once_rewrite_tac [list_Seq_def] \\ eval_tac
  \\ qpat_x_assum `get_var (adjust_var e1) t =
       SOME (Word (get_addr c _ (Word 0w)))` assume_tac
  \\ rpt_drule get_var_get_real_addr_lemma
  \\ qpat_x_assum `get_var (adjust_var e2) t =
       SOME (Word (get_addr c _ (Word 0w)))` assume_tac
  \\ rpt_drule get_var_get_real_addr_lemma
  \\ qpat_abbrev_tac `t1 = t with locals := insert 15 _ t.locals`
  \\ `get_var (adjust_var e2) t1 =
       SOME (Word (get_addr c ptr (Word 0w)))` by
   (fs [wordSemTheory.get_var_def,Abbr`t1`,lookup_insert]
    \\ rw [] \\ `EVEN 15` by metis_tac [EVEN_adjust_var] \\ fs [])
  \\ rpt_drule get_var_get_real_addr_lemma
  \\ fs [Abbr`t1`]
  \\ fs [WORD_MUL_LSL]
  \\ ntac 8 (once_rewrite_tac [list_Seq_def] \\ eval_tac \\ fs [lookup_insert])
  \\ assume_tac evaluate_WordOp64_on_32 \\ rfs []
  \\ SEP_I_TAC "evaluate"
  \\ fs [] \\ pop_assum kall_tac
  \\ rpt strip_tac
  \\ assume_tac (GEN_ALL evaluate_WriteWord64_on_32)
  \\ SEP_I_TAC "evaluate"
  \\ pop_assum mp_tac \\ fs [join_env_locals_def]
  \\ fs [wordSemTheory.get_var_def,lookup_insert]
  \\ fs [inter_insert_ODD_adjust_set_alt]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
  \\ disch_then drule
  \\ disch_then (qspec_then `opw_lookup opw c' c''` mp_tac)
  \\ simp []
  \\ impl_tac
  THEN1 (fs [consume_space_def,good_dimindex_def] \\ rw [] \\ fs [])
  \\ strip_tac \\ fs []
  \\ fs[FAPPLY_FUPDATE_THM]
  \\ fs [consume_space_def]
  \\ rveq \\ fs [] \\ rw [] \\ fs []);

val th = Q.store_thm("assign_WordShiftW8",
  `(?sh n. op = WordShift W8 sh n) ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH
  \\ fs[do_app]
  \\ every_case_tac \\ fs[]
  \\ clean_tac
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_2]
  \\ qhdtm_x_assum`$some`mp_tac
  \\ DEEP_INTRO_TAC some_intro \\ fs[]
  \\ strip_tac \\ clean_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs[state_rel_thm] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ disch_then drule \\ fs[] \\ strip_tac
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_2]
  \\ clean_tac \\ fs[]
  \\ qmatch_asmsub_rename_tac`Number (&w2n ww)`
  \\ `small_int (:α) (&w2n ww)` by1 simp[small_int_w2n]
  \\ rpt_drule memory_rel_Number_IMP
  \\ strip_tac \\ clean_tac
  \\ imp_res_tac get_vars_1_imp
  \\ fs[wordSemTheory.get_var_def]
  \\ simp[assign_def]
  \\ BasicProvers.CASE_TAC \\ eval_tac
  >- (
    IF_CASES_TAC
    >- (fs[good_dimindex_def,MIN_DEF] \\ rfs[])
    \\ simp[lookup_insert]
    \\ conj_tac >- rw[]
    \\ pop_assum kall_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert
    \\ qmatch_goalsub_abbrev_tac`Number i`
    \\ qmatch_goalsub_abbrev_tac`Word w`
    \\ `small_int (:'a) i`
    by (
      simp[Abbr`i`,small_int_def,WORD_MUL_LSL]
      \\ qmatch_goalsub_rename_tac`z * n2w _`
      \\ Cases_on`z` \\ fs[word_mul_n2w]
      \\ fs[good_dimindex_def,dimword_def]
      \\ qmatch_abbrev_tac`a MOD b < d`
      \\ `b < d` by simp[Abbr`b`,Abbr`d`]
      \\ qspecl_then[`a`,`b`]mp_tac MOD_LESS
      \\ (impl_tac >- simp[Abbr`b`])
      \\ decide_tac )
    \\ `w = Smallnum i`
    by (
      simp[Abbr`w`,Abbr`i`]
      \\ simp[Smallnum_i2w,integer_wordTheory.i2w_def]
      \\ qmatch_goalsub_rename_tac`w2n w`
      \\ qmatch_goalsub_rename_tac`w << n`
      \\ Cases_on`n=0`
      >- (
        simp[]
        \\ match_mp_tac lsl_lsr
        \\ simp[GSYM word_mul_n2w,dimword_def]
        \\ Q.ISPEC_THEN`w`mp_tac w2n_lt
        \\ fs[good_dimindex_def] )
      \\ simp[GSYM word_mul_n2w]
      \\ qspecl_then[`n2w(w2n w)`,`2`]mp_tac WORD_MUL_LSL
      \\ simp[] \\ disch_then (SUBST_ALL_TAC o SYM)
      \\ simp[]
      \\ `10 < dimindex(:'a)` by fs[good_dimindex_def]
      \\ simp[]
      \\ qspecl_then[`n2w(w2n (w<<n))`,`2`]mp_tac WORD_MUL_LSL
      \\ simp[] \\ disch_then (SUBST_ALL_TAC o SYM)
      \\ simp[GSYM w2w_def]
      \\ simp[w2w_LSL]
      \\ IF_CASES_TAC
      \\ simp[MIN_DEF]
      \\ simp[word_lsr_n2w]
      \\ simp[WORD_w2w_EXTRACT]
      \\ simp[WORD_EXTRACT_BITS_COMP]
      \\ `MIN (7 - n) 7 = 7 - n` by simp[MIN_DEF]
      \\ pop_assum SUBST_ALL_TAC
      \\ qmatch_abbrev_tac`_ ((7 >< 0) w << m) = _`
      \\ qispl_then[`7n`,`0n`,`m`,`w`](mp_tac o INST_TYPE[beta|->alpha]) WORD_EXTRACT_LSL2
      \\ impl_tac >- ( simp[Abbr`m`] )
      \\ disch_then SUBST_ALL_TAC
      \\ simp[Abbr`m`]
      \\ simp[WORD_BITS_LSL]
      \\ simp[SUB_LEFT_SUB,SUB_RIGHT_SUB]
      \\ qmatch_goalsub_abbrev_tac`_ -- z`
      \\ `z = 0` by simp[Abbr`z`]
      \\ simp[Abbr`z`]
      \\ simp[WORD_BITS_EXTRACT]
      \\ simp[WORD_EXTRACT_COMP_THM,MIN_DEF] )
    \\ simp[Abbr`w`]
    \\ match_mp_tac IMP_memory_rel_Number
    \\ simp[]
    \\ drule memory_rel_tl
    \\ simp_tac std_ss [GSYM APPEND_ASSOC])
  >- (
    IF_CASES_TAC
    >- (fs[good_dimindex_def,MIN_DEF] \\ rfs[])
    \\ simp[lookup_insert]
    \\ conj_tac >- rw[]
    \\ pop_assum kall_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert
    \\ qmatch_goalsub_abbrev_tac`Number i`
    \\ qmatch_goalsub_abbrev_tac`Word w`
    \\ `small_int (:'a) i`
    by (
      simp[Abbr`i`,small_int_def]
      \\ qmatch_goalsub_rename_tac`z >>> _`
      \\ Cases_on`z` \\ fs[w2n_lsr]
      \\ fs[good_dimindex_def,dimword_def]
      \\ qmatch_abbrev_tac`a DIV b < d`
      \\ `a < d` by simp[Abbr`a`,Abbr`d`]
      \\ qspecl_then[`b`,`a`]mp_tac (SIMP_RULE std_ss [PULL_FORALL]DIV_LESS_EQ)
      \\ (impl_tac >- simp[Abbr`b`])
      \\ decide_tac )
    \\ `w = Smallnum i`
    by (
      simp[Abbr`w`,Abbr`i`]
      \\ simp[Smallnum_i2w,integer_wordTheory.i2w_def]
      \\ simp[GSYM word_mul_n2w]
      \\ REWRITE_TAC[Once ADD_COMM]
      \\ REWRITE_TAC[GSYM LSR_ADD]
      \\ qmatch_goalsub_rename_tac`w2n w`
      \\ qmatch_goalsub_abbrev_tac`4w * ww`
      \\ `4w * ww = ww << 2` by simp[WORD_MUL_LSL]
      \\ pop_assum SUBST_ALL_TAC
      \\ qspecl_then[`ww`,`2`]mp_tac lsl_lsr
      \\ Q.ISPEC_THEN`w`assume_tac w2n_lt
      \\ impl_tac
      >- ( simp[Abbr`ww`] \\ fs[good_dimindex_def,dimword_def] )
      \\ disch_then SUBST_ALL_TAC
      \\ simp[WORD_MUL_LSL]
      \\ AP_TERM_TAC
      \\ simp[Abbr`ww`]
      \\ simp[w2n_lsr]
      \\ `w2n w < dimword(:'a)`
      by ( fs[good_dimindex_def,dimword_def] )
      \\ simp[GSYM n2w_DIV]
      \\ AP_THM_TAC \\ AP_TERM_TAC
      \\ rw[MIN_DEF] \\ fs[]
      \\ simp[LESS_DIV_EQ_ZERO]
      \\ qmatch_goalsub_rename_tac`2n ** k`
      \\ `2n ** 8 <= 2 ** k`
      by ( simp[logrootTheory.LE_EXP_ISO] )
      \\ `256n ≤ 2 ** k` by metis_tac[EVAL``2n ** 8``]
      \\ `w2n w < 2 ** k` by decide_tac
      \\ simp[LESS_DIV_EQ_ZERO] )
    \\ simp[Abbr`w`]
    \\ match_mp_tac IMP_memory_rel_Number
    \\ simp[]
    \\ drule memory_rel_tl
    \\ simp_tac std_ss [GSYM APPEND_ASSOC])
  >- (
    IF_CASES_TAC
    >- (fs[good_dimindex_def,MIN_DEF] \\ rfs[])
    \\ simp[lookup_insert]
    \\ IF_CASES_TAC
    >- (fs[good_dimindex_def,MIN_DEF] \\ rfs[])
    \\ simp[lookup_insert]
    \\ conj_tac >- rw[]
    \\ ntac 2 (pop_assum kall_tac)
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert
    \\ qmatch_goalsub_abbrev_tac`Number i`
    \\ qmatch_goalsub_abbrev_tac`Word w`
    \\ `small_int (:'a) i` by simp[Abbr`i`]
    \\ `w = Smallnum i`
    by (
      simp[Abbr`w`,Abbr`i`]
      \\ simp[Smallnum_i2w,integer_wordTheory.i2w_def]
      \\ simp[GSYM word_mul_n2w]
      \\ full_simp_tac(srw_ss()++wordsLib.WORD_MUL_LSL_ss)
           [good_dimindex_def,GSYM wordsTheory.w2w_def]
      \\ Cases_on `n' < 8`
      \\ asm_simp_tac(std_ss++wordsLib.WORD_BIT_EQ_ss)
           [MIN_DEF,
            DECIDE ``(32n <= n + 31) = (8 <= n + 7) /\
                     (32n <= n + 30) = (8 <= n + 6) /\
                     (32n <= n + 29) = (8 <= n + 5) /\
                     (32n <= n + 28) = (8 <= n + 4) /\
                     (32n <= n + 27) = (8 <= n + 3) /\
                     (32n <= n + 26) = (8 <= n + 2) /\
                     (32n <= n + 25) = (8 <= n + 1)``,
            DECIDE ``(64n <= n + 63) = (8 <= n + 7) /\
                     (64n <= n + 62) = (8 <= n + 6) /\
                     (64n <= n + 61) = (8 <= n + 5) /\
                     (64n <= n + 60) = (8 <= n + 4) /\
                     (64n <= n + 59) = (8 <= n + 3) /\
                     (64n <= n + 58) = (8 <= n + 2) /\
                     (64n <= n + 57) = (8 <= n + 1)``])
    \\ simp[Abbr`w`]
    \\ match_mp_tac IMP_memory_rel_Number
    \\ simp[]
    \\ drule memory_rel_tl
    \\ simp_tac std_ss [GSYM APPEND_ASSOC])
  >-
   (qmatch_asmsub_rename_tac `WordShift W8 Ror kk`
    \\ `~(2 ≥ dimindex (:α))` by (fs [good_dimindex_def] \\ fs [])
    \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma]
    \\ fs [lookup_insert,adjust_var_11] \\ rw []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert
    \\ qmatch_goalsub_abbrev_tac`Number i8`
    \\ qmatch_goalsub_abbrev_tac`Word w8`
    \\ `small_int (:'a) i8` by simp[Abbr`i8`]
    \\ qsuff_tac `w8 = Smallnum i8` THEN1
     (rw [] \\ fs []
      \\ match_mp_tac IMP_memory_rel_Number
      \\ simp[] \\ drule memory_rel_tl
      \\ simp_tac std_ss [GSYM APPEND_ASSOC])
    \\ simp[Abbr`w8`,Abbr`i8`]
    \\ simp[Smallnum_i2w,integer_wordTheory.i2w_def]
    \\ simp[GSYM word_mul_n2w]
    \\ full_simp_tac(srw_ss()++wordsLib.WORD_MUL_LSL_ss)
         [good_dimindex_def,GSYM wordsTheory.w2w_def]
    THEN
     (simp [fcpTheory.CART_EQ,word_or_def,fcpTheory.FCP_BETA,
           word_lsr_def,word_lsl_def,w2w,word_ror_def]
      \\ once_rewrite_tac
           [METIS_PROVE [] ``b1 /\ 2n <= i /\ c <=>
              b1 /\ 2n <= i /\ (b1 /\ 2n <= i ==> c)``]
      \\ simp [fcpTheory.CART_EQ,word_or_def,fcpTheory.FCP_BETA,
             word_lsr_def,word_lsl_def,w2w,word_ror_def]
      \\ rpt strip_tac
      \\ reverse (Cases_on `2 <= i`) \\ fs []
      THEN1
       (fs [fcpTheory.FCP_BETA] \\ CCONTR_TAC \\ fs []
        \\ `kk MOD 8 < 8` by fs [] \\ decide_tac)
      \\ `kk MOD 8 < 8` by fs []
      \\ simp []
      \\ reverse (Cases_on `i < 10`)
      THEN1
       (simp [fcpTheory.FCP_BETA]
        \\ CCONTR_TAC \\ fs []
        \\ rfs [fcpTheory.FCP_BETA])
      \\ fs []
      \\ `kk MOD 8 < 8` by fs []
      \\ simp [fcpTheory.FCP_BETA]
      \\ qpat_x_assum `2 ≤ i` mp_tac
      \\ simp [Once LESS_EQ_EXISTS] \\ strip_tac
      \\ rfs [] \\ rveq
      \\ `p < 8 /\ kk MOD 8 < 8` by fs []
      \\ once_rewrite_tac [GSYM (MATCH_MP MOD_PLUS (DECIDE ``0<8n``))]
      \\ drule (DECIDE ``n < 8n ==> n=0 \/ n=1 \/ n=2 \/ n=3 \/
                                    n=4 \/ n=5 \/ n=6 \/ n=7``)
      \\ strip_tac \\ fs []
      \\ drule (DECIDE ``n < 8n ==> n=0 \/ n=1 \/ n=2 \/ n=3 \/
                                    n=4 \/ n=5 \/ n=6 \/ n=7``)
      \\ strip_tac \\ fs [w2w])));

val assign_WordShift64 =
  ``assign c n l dest (WordShift W64 sh n) [e1] names_opt``
  |> SIMP_CONV (srw_ss()) [assign_def]

val evaluate_WordShift64_on_32 = prove(
  ``!l.
    dimindex (:'a) = 32 ==>
      evaluate
       (WordShift64_on_32 sh n,
        (t:('a,'ffi) wordSem$state) with
        locals :=
          (insert 13 (Word ((31 >< 0) c'))
          (insert 11 (Word ((63 >< 32) c')) l))) =
     (NONE,t with locals :=
       insert 31 (Word ((63 >< 32) (shift_lookup sh c' n)))
        (insert 33 (Word ((31 >< 0) (shift_lookup sh (c':word64) n)))
          (insert 13 (Word ((31 >< 0) c'))
            (insert 11 (Word ((63 >< 32) c')) l))))``,
  ntac 2 strip_tac \\ Cases_on `sh = Ror`
  THEN1
   (simp [WordShift64_on_32_def] \\ TOP_CASE_TAC
    \\ fs [list_Seq_def] \\ eval_tac
    \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma]
    \\ fs [lookup_insert]
    \\ qmatch_goalsub_abbrev_tac `insert 31 (Word w31)`
    \\ qmatch_goalsub_abbrev_tac `insert 33 (Word w33)`
    \\ once_rewrite_tac [EQ_SYM_EQ]
    \\ qmatch_goalsub_abbrev_tac `insert 31 (Word w31p)`
    \\ qmatch_goalsub_abbrev_tac `insert 33 (Word w33p)`
    \\ qsuff_tac `w31p = w31 /\ w33p = w33` \\ fs []
    \\ unabbrev_all_tac \\ rveq
    \\ fs [fcpTheory.CART_EQ,word_extract_def,word_bits_def,w2w,word_or_def,w2w,
           fcpTheory.FCP_BETA,word_lsl_def,word_0,word_lsr_def,word_ror_def]
    \\ rpt strip_tac
    THEN1
     (Cases_on `i + n MOD 64 < 32` \\ fs [w2w,fcpTheory.FCP_BETA]
      \\ once_rewrite_tac [DECIDE ``i+(n+32)=(i+32)+n:num``]
      \\ once_rewrite_tac [GSYM (MATCH_MP MOD_PLUS (DECIDE ``0<64n``))]
      \\ qabbrev_tac `nn = n MOD 64` \\ fs []
      \\ simp [GSYM SUB_MOD])
    THEN1
     (Cases_on `i + n MOD 64 < 32` \\ fs [w2w,fcpTheory.FCP_BETA]
      \\ once_rewrite_tac [GSYM (MATCH_MP MOD_PLUS (DECIDE ``0<64n``))]
      \\ qabbrev_tac `nn = n MOD 64` \\ fs [])
    THEN1
     (Cases_on `i + n MOD 64 < 64` \\ fs [w2w,fcpTheory.FCP_BETA]
      \\ once_rewrite_tac [DECIDE ``i+(n+32)=(i+32)+n:num``]
      \\ once_rewrite_tac [GSYM (MATCH_MP MOD_PLUS (DECIDE ``0<64n``))]
      \\ `n MOD 64 < 64` by fs []
      \\ qabbrev_tac `nn = n MOD 64` \\ fs []
      \\ simp [GSYM SUB_MOD])
    THEN1
     (Cases_on `i + n MOD 64 < 64` \\ fs [w2w,fcpTheory.FCP_BETA]
      \\ once_rewrite_tac [GSYM (MATCH_MP MOD_PLUS (DECIDE ``0<64n``))]
      \\ `n MOD 64 < 64` by fs []
      \\ qabbrev_tac `nn = n MOD 64` \\ fs []
      \\ simp [GSYM SUB_MOD]))
  \\ fs [WordShift64_on_32_def]
  \\ reverse TOP_CASE_TAC \\ fs [NOT_LESS]
  THEN1
   (Cases_on `sh` \\ fs [list_Seq_def] \\ eval_tac
    \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ fs [lookup_insert]
    \\ rpt strip_tac
    \\ qmatch_goalsub_abbrev_tac `insert 31 (Word w31)`
    \\ qmatch_goalsub_abbrev_tac `insert 33 (Word w33)`
    \\ once_rewrite_tac [EQ_SYM_EQ]
    \\ qmatch_goalsub_abbrev_tac `insert 31 (Word w31p)`
    \\ qmatch_goalsub_abbrev_tac `insert 33 (Word w33p)`
    \\ qsuff_tac `w31p = w31 /\ w33p = w33` \\ fs []
    \\ unabbrev_all_tac
    \\ fs [fcpTheory.CART_EQ,word_extract_def,word_bits_def,w2w,word_msb_def,
           fcpTheory.FCP_BETA,word_lsl_def,word_0,word_lsr_def,word_asr_def]
    THEN1
     (rw []
      \\ Cases_on `i + n < 64` \\ fs []
      \\ fs [fcpTheory.CART_EQ,word_extract_def,word_bits_def,w2w,
           fcpTheory.FCP_BETA,word_lsl_def,word_0,word_lsr_def])
    \\ rw [WORD_NEG_1_T,word_0] \\ fs [])
  \\ Cases_on `sh` \\ fs [list_Seq_def] \\ eval_tac
  \\ once_rewrite_tac [word_exp_set_var_ShiftVar_lemma] \\ fs [lookup_insert]
  \\ rpt strip_tac
  \\ qmatch_goalsub_abbrev_tac `insert 31 (Word w31)`
  \\ qmatch_goalsub_abbrev_tac `insert 33 (Word w33)`
  \\ once_rewrite_tac [EQ_SYM_EQ]
  \\ qmatch_goalsub_abbrev_tac `insert 31 (Word w31p)`
  \\ qmatch_goalsub_abbrev_tac `insert 33 (Word w33p)`
  \\ qsuff_tac `w31p = w31 /\ w33p = w33` \\ fs []
  \\ unabbrev_all_tac
  \\ fs [fcpTheory.CART_EQ,word_extract_def,word_bits_def,w2w,word_msb_def,
         fcpTheory.FCP_BETA,word_lsl_def,word_0,word_lsr_def,word_asr_def,
         word_or_def] \\ rw [] \\ fs []
  THEN1 (Cases_on `n <= i` \\ fs [] \\ fs [fcpTheory.FCP_BETA,w2w])
  THEN1 (Cases_on `i + n < 32` \\ fs [fcpTheory.FCP_BETA,w2w])
  THEN1 (Cases_on `i + n < 32` \\ fs [fcpTheory.FCP_BETA,w2w])
  THEN1 (Cases_on `i + n < 32` \\ fs [fcpTheory.FCP_BETA,w2w]));

val th = Q.store_thm("assign_WordShiftW64",
  `(?sh n. op = WordShift W64 sh n) ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH
  \\ fs[do_app]
  \\ every_case_tac \\ fs[]
  \\ clean_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_2]
  \\ clean_tac
  \\ simp[assign_def]
  \\ TOP_CASE_TAC \\ fs[]
  \\ TOP_CASE_TAC \\ fs[]
  THEN1 (* dimindex (:'a) = 64 *)
   (`dimindex (:'a) = 64` by fs [state_rel_def,good_dimindex_def]
    \\ fs [] \\ clean_tac
    \\ fs[state_rel_thm] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ strip_tac
    \\ fs[wordSemTheory.get_vars_def]
    \\ qpat_x_assum`_ = SOME [_]`mp_tac
    \\ TOP_CASE_TAC \\ fs[] \\ strip_tac \\ clean_tac
    \\ rpt_drule evaluate_LoadWord64
    \\ rfs[good_dimindex_def] \\ rfs[]
    \\ disch_then drule
    \\ simp[list_Seq_def]
    \\ simp[Once wordSemTheory.evaluate_def]
    \\ disch_then kall_tac
    \\ simp[Once wordSemTheory.evaluate_def]
    \\ simp[Once wordSemTheory.evaluate_def,word_exp_set_var_ShiftVar]
    \\ eval_tac
    \\ qmatch_goalsub_abbrev_tac`OPTION_MAP Word opt`
    \\ `∃w. opt = SOME w`
    by ( simp[Abbr`opt`] \\ CASE_TAC \\ simp[] )
    \\ qunabbrev_tac`opt` \\ simp[]
    \\ qhdtm_x_assum`memory_rel`kall_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,GSYM join_env_locals_def]
    \\ assume_tac(GEN_ALL evaluate_WriteWord64)
    \\ SEP_I_TAC "evaluate" \\ fs[]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ first_x_assum drule
    \\ simp[wordSemTheory.get_var_def]
    \\ fs[consume_space_def]
    \\ simp[lookup_insert]
    \\ disch_then(qspec_then`w`strip_assume_tac)
    \\ simp[]
    \\ clean_tac \\ fs[]
    \\ fs[lookup_insert]
    \\ conj_tac >- rw[]
    \\ match_mp_tac (GEN_ALL memory_rel_less_space)
    \\ qexists_tac`x.space-2` \\ simp[]
    \\ qmatch_abbrev_tac`memory_rel c be refs sp' st' m' md vars'`
    \\ qmatch_assum_abbrev_tac`memory_rel c be refs sp' st' m' md vars''`
    \\ `vars' = vars''` suffices_by simp[]
    \\ simp[Abbr`vars'`,Abbr`vars''`]
    \\ simp[Abbr`st'`,FAPPLY_FUPDATE_THM]
    \\ rpt(AP_TERM_TAC ORELSE AP_THM_TAC)
    \\ Cases_on`sh` \\ fs[] \\ clean_tac
    \\ simp[WORD_w2w_EXTRACT]
    >- srw_tac[wordsLib.WORD_BIT_EQ_ss][]
    >- (
      simp[fcpTheory.CART_EQ]
      \\ simp[word_extract_def,word_bits_def,w2w,word_lsr_index,fcpTheory.FCP_BETA]
      \\ rpt strip_tac
      \\ EQ_TAC \\ strip_tac \\ simp[]
      \\ rfs[w2w,fcpTheory.FCP_BETA] )
    >- (
      simp[fcpTheory.CART_EQ]
      \\ simp[word_extract_def,word_bits_def,w2w,word_asr_def,fcpTheory.FCP_BETA]
      \\ rpt strip_tac
      \\ IF_CASES_TAC \\ simp[]
      \\ simp[word_msb_def]
      \\ rfs[w2w,fcpTheory.FCP_BETA])
    >-
     (simp[fcpTheory.CART_EQ]
      \\ simp[word_extract_def,word_bits_def,w2w,word_ror_def,fcpTheory.FCP_BETA]
      \\ rpt strip_tac
      \\ eq_tac \\ fs []
      \\ `(i + n') MOD 64 < 64` by fs [] \\ simp []))
  \\ `dimindex (:'a) = 32` by fs [state_rel_def,good_dimindex_def]
  \\ fs [] \\ clean_tac
  \\ fs[state_rel_thm] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ strip_tac
  \\ fs[wordSemTheory.get_vars_def]
  \\ qpat_x_assum`_ = SOME [_]`mp_tac
  \\ TOP_CASE_TAC \\ fs[] \\ strip_tac \\ clean_tac
  \\ drule memory_rel_Word64_IMP
  \\ fs [good_dimindex_def]
  \\ strip_tac \\ fs []
  \\ `shift_length c < dimindex (:α)` by (fs [memory_rel_def] \\ NO_TAC)
  \\ once_rewrite_tac [list_Seq_def] \\ eval_tac
  \\ qpat_x_assum `get_var (adjust_var e1) t =
       SOME (Word (get_addr c _ (Word 0w)))` assume_tac
  \\ rpt_drule get_var_get_real_addr_lemma
  \\ fs [WORD_MUL_LSL,good_dimindex_def]
  \\ ntac 8 (once_rewrite_tac [list_Seq_def] \\ eval_tac \\ fs [lookup_insert])
  \\ assume_tac (GEN_ALL evaluate_WordShift64_on_32) \\ rfs []
  \\ SEP_I_TAC "evaluate"
  \\ fs [] \\ pop_assum kall_tac
  \\ rpt strip_tac
  \\ assume_tac (GEN_ALL evaluate_WriteWord64_on_32)
  \\ SEP_I_TAC "evaluate"
  \\ pop_assum mp_tac \\ fs [join_env_locals_def]
  \\ fs [wordSemTheory.get_var_def,lookup_insert]
  \\ fs [inter_insert_ODD_adjust_set_alt]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
  \\ disch_then drule
  \\ disch_then (qspec_then `shift_lookup sh c' n'` mp_tac)
  \\ simp []
  \\ impl_tac
  THEN1 (fs [consume_space_def,good_dimindex_def] \\ rw [] \\ fs [])
  \\ strip_tac \\ fs []
  \\ fs[FAPPLY_FUPDATE_THM]
  \\ fs [consume_space_def]
  \\ rveq \\ fs [] \\ rw [] \\ fs []);

val th = Q.store_thm("assign_Label",
  `(?lab. op = Label lab) ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ fs [assign_def] \\ fs [do_app]
  \\ Cases_on `vals` \\ fs []
  \\ qpat_assum `_ = Rval (v,s2)` mp_tac
  \\ IF_CASES_TAC \\ fs []
  \\ rveq \\ fs []
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs []
  \\ fs [state_rel_thm] \\ eval_tac
  \\ fs [domain_lookup,lookup_map]
  \\ reverse IF_CASES_TAC THEN1
   (`F` by all_tac \\ fs [code_rel_def]
    \\ rename1 `lookup _ s2.code = SOME zzz` \\ PairCases_on `zzz` \\ res_tac
    \\ fs []) \\ fs []
  \\ fs [lookup_insert,FAPPLY_FUPDATE_THM,adjust_var_11,FLOOKUP_UPDATE]
  \\ rw [] \\ fs [] \\ rw [] \\ fs []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs []
  \\ match_mp_tac memory_rel_CodePtr \\ fs []);

val do_app_Ref = Q.store_thm("do_app_Ref",
  `do_app Ref vals x =
    case consume_space (LENGTH vals + 1) x of
      NONE => Rerr (Rabort Rtype_error)
    | SOME s1 =>
      Rval
      (RefPtr (LEAST ptr. ptr ∉ FDOM (data_to_bvi s1).refs),
       bvi_to_data
         (bvl_to_bvi
            (bvi_to_bvl (data_to_bvi s1) with
             refs :=
               (data_to_bvi s1).refs |+
               ((LEAST ptr. ptr ∉ FDOM (data_to_bvi s1).refs),
                ValueArray vals)) (data_to_bvi s1)) s1)`,
  fs [do_app] \\ Cases_on `vals` \\ fs [LET_THM]);

val th = Q.store_thm("assign_Ref",
  `op = Ref ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs []
  \\ fs [assign_def] \\ fs [do_app_Ref]
  \\ Cases_on `consume_space (LENGTH vals + 1) x` \\ fs [] \\ rveq
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ clean_tac
  \\ fs [consume_space_def] \\ clean_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ TOP_CASE_TAC \\ fs []
  \\ fs [state_rel_thm] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ disch_then drule \\ fs [NOT_LESS,DECIDE ``n + 1 <= m <=> n < m:num``]
  \\ strip_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ qabbrev_tac `new = LEAST ptr. ptr ∉ FDOM x.refs`
  \\ `new ∉ FDOM x.refs` by metis_tac [LEAST_NOTIN_FDOM]
  \\ qpat_assum `_ = LENGTH _` assume_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule memory_rel_Ref \\ strip_tac
  \\ fs [list_Seq_def] \\ eval_tac
  \\ fs [wordSemTheory.set_store_def,FLOOKUP_UPDATE]
  \\ qpat_abbrev_tac `t5 = t with <| locals := _ ; store := _ |>`
  \\ pairarg_tac \\ fs []
  \\ `t.memory = t5.memory /\ t.mdomain = t5.mdomain` by
       (unabbrev_all_tac \\ fs []) \\ fs []
  \\ ntac 2 (pop_assum kall_tac)
  \\ drule evaluate_StoreEach
  \\ disch_then (qspecl_then [`3::MAP adjust_var args`,`1`] mp_tac)
  \\ impl_tac THEN1
   (fs [wordSemTheory.get_vars_def,Abbr`t5`,wordSemTheory.get_var_def,
        lookup_insert,get_vars_with_store,get_vars_adjust_var] \\ NO_TAC)
  \\ clean_tac \\ fs [] \\ UNABBREV_ALL_TAC
  \\ fs [lookup_insert,FAPPLY_FUPDATE_THM,adjust_var_11,FLOOKUP_UPDATE]
  \\ rw [] \\ fs [] \\ rw [] \\ fs []
  \\ fs [inter_insert_ODD_adjust_set]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs []
  \\ fs [make_ptr_def]
  \\ `TriggerGC <> EndOfHeap` by fs []
  \\ pop_assum (fn th => fs [MATCH_MP FUPDATE_COMMUTES th]));

val th = Q.store_thm("assign_Update",
  `op = Update ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs []
  \\ fs [do_app] \\ every_case_tac \\ fs [] \\ clean_tac
  \\ fs [INT_EQ_NUM_LEMMA] \\ clean_tac
  \\ fs [integerTheory.NUM_OF_INT,LENGTH_EQ_3] \\ clean_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [bvlSemTheory.Unit_def] \\ rveq
  \\ fs [GSYM bvlSemTheory.Unit_def] \\ rveq
  \\ fs [assign_def] \\ eval_tac \\ fs [state_rel_thm]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ disch_then drule \\ fs []
  \\ imp_res_tac get_vars_3_IMP \\ fs []
  \\ fs [integerTheory.NUM_OF_INT,LENGTH_EQ_3] \\ clean_tac
  \\ imp_res_tac get_vars_3_IMP \\ fs [] \\ strip_tac
  \\ drule reorder_lemma \\ strip_tac
  \\ drule (memory_rel_Update |> GEN_ALL) \\ fs []
  \\ strip_tac \\ clean_tac
  \\ `word_exp t (real_offset c (adjust_var a2)) = SOME (Word y) /\
      word_exp t (real_addr c (adjust_var a1)) = SOME (Word x')` by
        metis_tac [get_real_offset_lemma,get_real_addr_lemma]
  \\ fs [] \\ eval_tac \\ fs [EVAL ``word_exp s1 Unit``]
  \\ fs [wordSemTheory.mem_store_def]
  \\ fs [lookup_insert,adjust_var_11]
  \\ rw [] \\ fs []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs []
  \\ match_mp_tac memory_rel_Unit \\ fs []
  \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac memory_rel_rearrange)
  \\ rw [] \\ fs []);

val th = Q.store_thm("assign_Deref",
  `op = Deref ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs []
  \\ fs [do_app] \\ every_case_tac \\ fs [] \\ clean_tac
  \\ fs [INT_EQ_NUM_LEMMA] \\ clean_tac
  \\ fs [integerTheory.NUM_OF_INT,LENGTH_EQ_2] \\ clean_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [assign_def] \\ eval_tac \\ fs [state_rel_thm]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ disch_then drule \\ fs []
  \\ imp_res_tac get_vars_2_IMP \\ fs []
  \\ fs [integerTheory.NUM_OF_INT,LENGTH_EQ_2] \\ clean_tac
  \\ imp_res_tac get_vars_2_IMP \\ fs [] \\ strip_tac
  \\ drule (memory_rel_Deref |> GEN_ALL) \\ fs []
  \\ strip_tac \\ clean_tac
  \\ `word_exp t (real_offset c (adjust_var a2)) = SOME (Word y) /\
      word_exp t (real_addr c (adjust_var a1)) = SOME (Word x')` by
        metis_tac [get_real_offset_lemma,get_real_addr_lemma]
  \\ fs [] \\ eval_tac
  \\ fs [lookup_insert,adjust_var_11]
  \\ rw [] \\ fs []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs []
  \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac memory_rel_rearrange)
  \\ fs [] \\ rw [] \\ fs []);

val th = Q.store_thm("assign_UpdateByte",
  `op = UpdateByte ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs[]
  \\ fs[do_app] \\ every_case_tac \\ fs[] \\ clean_tac
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_3] \\ clean_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_3] \\ clean_tac
  \\ imp_res_tac get_vars_3_IMP
  \\ fs [bvlSemTheory.Unit_def] \\ rveq
  \\ fs [GSYM bvlSemTheory.Unit_def] \\ rveq
  \\ fs[bviPropsTheory.bvl_to_bvi_with_refs,
        bviPropsTheory.bvl_to_bvi_id,
        bvi_to_data_refs, data_to_bvi_refs]
  \\ fs[GSYM bvi_to_data_refs]
  \\ fs[data_to_bvi_def]
  \\ fs[state_rel_thm,set_var_def]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP )
  \\ strip_tac
  \\ fs[get_vars_def]
  \\ every_case_tac \\ fs[] \\ clean_tac
  \\ rpt_drule memory_rel_ByteArray_IMP
  \\ strip_tac \\ clean_tac
  \\ rpt_drule get_var_get_real_addr_lemma
  \\ imp_res_tac memory_rel_tl
  \\ `small_int (:'a) i`
  by (
    simp[small_int_def]
    \\ fs[good_dimindex_def]
    \\ rfs[dimword_def]
    \\ intLib.COOPER_TAC )
  \\ rpt_drule memory_rel_Number_IMP
  \\ imp_res_tac memory_rel_tl
  \\ `small_int (:'a) (&w2n w)`
  by (match_mp_tac small_int_w2n \\ fs[])
  \\ rpt_drule memory_rel_Number_IMP
  \\ ntac 2 (qhdtm_x_assum`memory_rel` kall_tac)
  \\ ntac 2 strip_tac \\ clean_tac
  \\ qpat_x_assum`get_var (adjust_var e2) _ = _`assume_tac
  \\ rpt_drule get_real_byte_offset_lemma
  \\ simp[assign_def,list_Seq_def] \\ eval_tac
  \\ fs[wordSemTheory.get_var_def]
  \\ simp[lookup_insert,wordSemTheory.inst_def]
  \\ `2 < dimindex(:'a)` by fs[good_dimindex_def]
  \\ simp[wordSemTheory.get_var_def,Unit_def]
  \\ eval_tac
  \\ simp[lookup_insert]
  \\ rpt strip_tac
  \\ simp[Smallnum_i2w,GSYM integer_wordTheory.word_i2w_mul]
  \\ qspecl_then[`ii`,`2`](mp_tac o Q.GEN`ii` o SYM) WORD_MUL_LSL
  \\ `i2w 4 = 4w` by EVAL_TAC
  \\ simp[]
  \\ `i2w i << 2 >>> 2 = i2w i`
  by (
    match_mp_tac lsl_lsr
    \\ Cases_on`i`
    \\ fs[small_int_def,X_LT_DIV,dimword_def,integer_wordTheory.i2w_def] )
  \\ pop_assum (CHANGED_TAC o SUBST_ALL_TAC)
  \\ `w2w w << 2 >>> 2 = w2w w`
  by (
    match_mp_tac lsl_lsr
    \\ simp[w2n_w2w]
    \\ reverse IF_CASES_TAC >- fs[good_dimindex_def]
    \\ fs[small_int_def,X_LT_DIV])
  \\ pop_assum (CHANGED_TAC o SUBST_ALL_TAC)
  \\ simp[w2w_w2w]
  \\ `dimindex(:8) ≤ dimindex(:α)` by fs[good_dimindex_def]
  \\ simp[integer_wordTheory.w2w_i2w]
  \\ `i2w i = n2w (Num i)`
  by (
    rw[integer_wordTheory.i2w_def]
    \\ `F` by intLib.COOPER_TAC )
  \\ pop_assum (CHANGED_TAC o SUBST_ALL_TAC)
  \\ disch_then kall_tac
  \\ qpat_x_assum`∀i. _ ⇒ mem_load_byte_aux _ _ _ _ = _`(qspec_then`Num i`mp_tac)
  \\ impl_tac
  >- (
    fs[GSYM integerTheory.INT_OF_NUM]
    \\ REWRITE_TAC[GSYM integerTheory.INT_LT]
    \\ PROVE_TAC[] )
  \\ simp[wordSemTheory.mem_load_byte_aux_def]
  \\ BasicProvers.TOP_CASE_TAC \\ fs[]
  \\ strip_tac
  \\ simp[wordSemTheory.mem_store_byte_aux_def]
  \\ simp[lookup_insert]
  \\ conj_tac >- rw[]
  \\ fs[inter_insert_ODD_adjust_set]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert
  \\ simp[]
  \\ match_mp_tac memory_rel_Unit
  \\ first_x_assum(qspecl_then[`Num i`,`w`]mp_tac)
  \\ impl_tac
  >- (
    fs[GSYM integerTheory.INT_OF_NUM]
    \\ REWRITE_TAC[GSYM integerTheory.INT_LT]
    \\ PROVE_TAC[] )
  \\ simp[theWord_def] \\ strip_tac
  \\ simp[WORD_ALL_BITS]
  \\ drule memory_rel_tl \\ simp[] \\ strip_tac
  \\ drule memory_rel_tl \\ simp[] \\ strip_tac
  \\ drule memory_rel_tl \\ simp[]);

val th = Q.store_thm("assign_DerefByte",
  `op = DerefByte ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs[]
  \\ fs[do_app] \\ every_case_tac \\ fs[] \\ clean_tac
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_2] \\ clean_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_2] \\ clean_tac
  \\ imp_res_tac get_vars_2_IMP
  \\ fs[bviPropsTheory.bvl_to_bvi_id]
  \\ fs[state_rel_thm,set_var_def]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP )
  \\ strip_tac
  \\ fs[get_vars_def]
  \\ every_case_tac \\ fs[] \\ clean_tac
  \\ fs[data_to_bvi_def]
  \\ rpt_drule memory_rel_ByteArray_IMP
  \\ strip_tac \\ clean_tac
  \\ first_x_assum(qspec_then`ARB`kall_tac)
  \\ rpt_drule get_var_get_real_addr_lemma
  \\ imp_res_tac memory_rel_tl
  \\ rename1 `i < &LENGTH l'`
  \\ `small_int (:'a) i`
  by (
    simp[small_int_def]
    \\ fs[good_dimindex_def]
    \\ rfs[dimword_def]
    \\ intLib.COOPER_TAC )
  \\ rpt_drule memory_rel_Number_IMP
  \\ qhdtm_x_assum`memory_rel` kall_tac
  \\ strip_tac
  \\ clean_tac
  \\ qpat_x_assum`get_var _ _ = SOME (Word(Smallnum _))`assume_tac
  \\ rpt_drule get_real_byte_offset_lemma
  \\ simp[assign_def,list_Seq_def] \\ eval_tac
  \\ simp[wordSemTheory.inst_def]
  \\ eval_tac
  \\ fs[Smallnum_i2w,GSYM integer_wordTheory.word_i2w_mul]
  \\ qspecl_then[`i2w i`,`2`](mp_tac o SYM) WORD_MUL_LSL
  \\ `i2w 4 = 4w` by EVAL_TAC
  \\ simp[]
  \\ `i2w i << 2 >>> 2 = i2w i`
  by (
    match_mp_tac lsl_lsr
    \\ REWRITE_TAC[GSYM integerTheory.INT_LT,
                   GSYM integerTheory.INT_MUL,
                   integer_wordTheory.w2n_i2w]
    \\ simp[]
    \\ reverse(Cases_on`i`) \\ fs[]
    >- (
      fs[dimword_def, integerTheory.INT_MOD0] )
    \\ simp[integerTheory.INT_MOD,dimword_def]
    \\ fs[small_int_def,dimword_def]
    \\ fs[X_LT_DIV] )
  \\ simp[]
  \\ first_x_assum(qspec_then`Num i`mp_tac)
  \\ impl_tac >- ( Cases_on`i` \\ fs[] )
  \\ `i2w i = n2w (Num i)`
  by (
    rw[integer_wordTheory.i2w_def]
    \\ Cases_on`i` \\ fs[] )
  \\ fs[]
  \\ `¬(2 ≥ dimindex(:α))` by fs[good_dimindex_def]
  \\ simp[lookup_insert]
  \\ ntac 4 strip_tac
  \\ conj_tac >- rw[]
  \\ fs[inter_insert_ODD_adjust_set]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert
  \\ qmatch_goalsub_abbrev_tac`(Number j,Word k)`
  \\ `small_int (:α) j` by1 (simp[Abbr`j`,small_int_w2n])
  \\ `k = Smallnum j`
  by (
    fs[small_int_def,Abbr`j`]
    \\ qmatch_goalsub_abbrev_tac`w2n w8`
    \\ Q.ISPEC_THEN`w8`strip_assume_tac w2n_lt
    \\ simp[integer_wordTheory.i2w_def,Smallnum_i2w]
    \\ simp[Abbr`k`,WORD_MUL_LSL]
    \\ simp[GSYM word_mul_n2w]
    \\ simp[w2w_def] )
  \\ simp[]
  \\ match_mp_tac IMP_memory_rel_Number
  \\ fs[]);

val th = Q.store_thm("assign_El",
  `op = El ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs []
  \\ fs [do_app] \\ every_case_tac \\ fs [] \\ clean_tac
  \\ fs [INT_EQ_NUM_LEMMA] \\ clean_tac
  \\ fs [integerTheory.NUM_OF_INT,LENGTH_EQ_2] \\ clean_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [assign_def] \\ eval_tac \\ fs [state_rel_thm]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ disch_then drule \\ fs []
  \\ imp_res_tac get_vars_2_IMP \\ fs []
  \\ fs [integerTheory.NUM_OF_INT,LENGTH_EQ_2] \\ clean_tac
  \\ imp_res_tac get_vars_2_IMP \\ fs [] \\ strip_tac
  \\ drule (memory_rel_El |> GEN_ALL) \\ fs []
  \\ strip_tac \\ clean_tac
  \\ `word_exp t (real_offset c (adjust_var a2)) = SOME (Word y) /\
      word_exp t (real_addr c (adjust_var a1)) = SOME (Word x')` by
        metis_tac [get_real_offset_lemma,get_real_addr_lemma]
  \\ fs [] \\ eval_tac
  \\ fs [lookup_insert,adjust_var_11]
  \\ rw [] \\ fs []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs []
  \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac memory_rel_rearrange)
  \\ fs [] \\ rw [] \\ fs []);

val th = Q.store_thm("assign_Const",
  `(?i. op = Const i) ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ fs [do_app] \\ every_case_tac \\ fs []
  \\ rpt var_eq_tac
  \\ fs [assign_def]
  \\ Cases_on `i` \\ fs []
  \\ fs [wordSemTheory.evaluate_def,wordSemTheory.word_exp_def]
  \\ fs [state_rel_def,wordSemTheory.set_var_def,set_var_def,
        lookup_insert,adjust_var_11]
  \\ rw [] \\ fs []
  \\ asm_exists_tac \\ fs []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac word_ml_inv_insert \\ fs []
  \\ TRY (match_mp_tac word_ml_inv_zero) \\ fs []
  \\ TRY (match_mp_tac word_ml_inv_num) \\ fs []
  \\ TRY (match_mp_tac word_ml_inv_neg_num) \\ fs []);

val th = Q.store_thm("assign_GlobalsPtr",
  `op = GlobalsPtr ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ fs [do_app] \\ every_case_tac \\ fs []
  \\ rpt var_eq_tac
  \\ fs [assign_def]
  \\ fs [data_to_bvi_def]
  \\ fs[wordSemTheory.evaluate_def,wordSemTheory.word_exp_def]
  \\ fs [state_rel_def]
  \\ fs [the_global_def,libTheory.the_def]
  \\ fs [FLOOKUP_DEF,wordSemTheory.set_var_def,lookup_insert,
         adjust_var_11,libTheory.the_def,set_var_def]
  \\ rw [] \\ fs []
  \\ asm_exists_tac \\ fs []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac word_ml_inv_insert \\ fs []
  \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
  \\ fs [] \\ rw [] \\ fs []);

val th = Q.store_thm("assign_SetGlobalsPtr",
  `op = SetGlobalsPtr ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ fs [do_app] \\ every_case_tac \\ fs []
  \\ rpt var_eq_tac
  \\ fs [assign_def]
  \\ imp_res_tac get_vars_SING \\ fs []
  \\ `args <> []` by (strip_tac \\ fs [dataSemTheory.get_vars_def])
  \\ fs[wordSemTheory.evaluate_def,wordSemTheory.word_exp_def,Unit_def]
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ Cases_on `ws` \\ fs [LENGTH_NIL] \\ rpt var_eq_tac
  \\ pop_assum (fn th => assume_tac th THEN mp_tac th)
  \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def]
  \\ every_case_tac \\ fs [] \\ rpt var_eq_tac
  \\ fs [state_rel_def,wordSemTheory.set_var_def,lookup_insert,
         adjust_var_11,libTheory.the_def,set_var_def,bvi_to_data_def,
         wordSemTheory.set_store_def,data_to_bvi_def]
  \\ rpt_drule heap_in_memory_store_IMP_UPDATE
  \\ disch_then (qspec_then `h` assume_tac)
  \\ rw [] \\ fs []
  \\ asm_exists_tac \\ fs [the_global_def,libTheory.the_def]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ drule (GEN_ALL word_ml_inv_get_vars_IMP)
  \\ disch_then drule
  \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def]
  \\ strip_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac word_ml_inv_insert \\ fs []
  \\ match_mp_tac word_ml_inv_Unit
  \\ pop_assum mp_tac \\ fs []
  \\ match_mp_tac word_ml_inv_rearrange \\ rw [] \\ fs [])

val th = Q.store_thm("assign_Cons",
  `(?tag. op = Cons tag) ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ Cases_on `LENGTH args = 0` THEN1
   (fs [assign_def] \\ IF_CASES_TAC \\ fs []
    \\ fs [LENGTH_NIL] \\ rpt var_eq_tac
    \\ fs [do_app] \\ every_case_tac \\ fs []
    \\ imp_res_tac get_vars_IMP_LENGTH \\ fs []
    \\ TRY (Cases_on `vals`) \\ fs [] \\ clean_tac
    \\ eval_tac \\ clean_tac
    \\ fs [state_rel_def,lookup_insert,adjust_var_11]
    \\ rw [] \\ fs []
    \\ asm_exists_tac \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac word_ml_inv_insert \\ fs []
    \\ fs [word_ml_inv_def,PULL_EXISTS] \\ rw []
    \\ qexists_tac `Data (Word (n2w (16 * tag + 2)))`
    \\ qexists_tac `hs` \\ fs [word_addr_def]
    \\ reverse conj_tac
    THEN1 (fs [GSYM word_mul_n2w,GSYM word_add_n2w,BlockNil_and_lemma])
    \\ `n2w (16 * tag + 2) = BlockNil tag : 'a word` by
         fs [BlockNil_def,WORD_MUL_LSL,word_mul_n2w,word_add_n2w]
    \\ fs [cons_thm_EMPTY])
  \\ fs [assign_def] \\ CASE_TAC \\ fs []
  \\ fs [do_app] \\ every_case_tac \\ fs []
  \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ clean_tac
  \\ fs [consume_space_def] \\ clean_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs [state_rel_thm] \\ eval_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ drule (memory_rel_get_vars_IMP |> GEN_ALL)
  \\ disch_then drule \\ fs [NOT_LESS,DECIDE ``n + 1 <= m <=> n < m:num``]
  \\ strip_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ `vals <> [] /\ (LENGTH vals = LENGTH ws)` by
         (fs [GSYM LENGTH_NIL] \\ NO_TAC)
  \\ rpt_drule memory_rel_Cons1 \\ strip_tac
  \\ fs [list_Seq_def] \\ eval_tac
  \\ fs [wordSemTheory.set_store_def]
  \\ qpat_abbrev_tac `t5 = t with <| locals := _ |>`
  \\ pairarg_tac \\ fs []
  \\ `t.memory = t5.memory /\ t.mdomain = t5.mdomain` by
       (unabbrev_all_tac \\ fs []) \\ fs []
  \\ ntac 2 (pop_assum kall_tac)
  \\ drule evaluate_StoreEach
  \\ disch_then (qspecl_then [`3::MAP adjust_var args`,`1`] mp_tac)
  \\ impl_tac THEN1
   (fs [wordSemTheory.get_vars_def,Abbr`t5`,wordSemTheory.get_var_def,
        lookup_insert,get_vars_with_store,get_vars_adjust_var]
    \\ `(t with locals := t.locals) = t` by
          fs [wordSemTheory.state_component_equality] \\ fs [] \\ NO_TAC)
  \\ clean_tac \\ fs [] \\ UNABBREV_ALL_TAC
  \\ fs [lookup_insert,FAPPLY_FUPDATE_THM,adjust_var_11,FLOOKUP_UPDATE]
  \\ rw [] \\ fs [] \\ rw [] \\ fs []
  \\ fs [inter_insert_ODD_adjust_set]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs []
  \\ fs [make_cons_ptr_def,get_lowerbits_def]);

val th = Q.store_thm("assign_FFI",
  `(?n. op = FFI n) ==> ^assign_thm_goal`,
  rpt strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ fs[do_app] \\ clean_tac
  \\ imp_res_tac get_vars_IMP_LENGTH
  \\ every_case_tac \\ fs[] \\ clean_tac
  \\ fs[CONJUNCT2 bvi_to_data_refs,
        SYM(CONJUNCT1 bvi_to_data_refs),
        data_to_bvi_refs,
        bviPropsTheory.bvl_to_bvi_with_refs,
        bviPropsTheory.bvl_to_bvi_id,
        data_to_bvi_ffi,
        bviPropsTheory.bvi_to_bvl_to_bvi_with_ffi,
        data_to_bvi_to_data_with_ffi]
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_2] \\ clean_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_2] \\ clean_tac
  \\ fs [bvlSemTheory.Unit_def] \\ rveq
  \\ fs [GSYM bvlSemTheory.Unit_def] \\ rveq
  \\ imp_res_tac get_vars_1_imp
  \\ fs[state_rel_thm,set_var_def]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule (memory_rel_get_vars_IMP )
  \\ strip_tac
  \\ fs[get_vars_def]
  \\ every_case_tac \\ fs[] \\ clean_tac
  \\ rpt_drule memory_rel_ByteArray_IMP
  \\ strip_tac \\ clean_tac
  \\ simp[assign_def,list_Seq_def] \\ eval_tac
  \\ rpt_drule get_var_get_real_addr_lemma
  \\ simp[]
  \\ qpat_abbrev_tac`tt = t with locals := _`
  \\ `get_var (adjust_var e1) tt = get_var (adjust_var e1) t`
  by fs[Abbr`tt`,wordSemTheory.get_var_def,lookup_insert]
  \\ rfs[]
  \\ rpt_drule get_var_get_real_addr_lemma
  \\ `tt.store = t.store` by simp[Abbr`tt`]
  \\ simp[]
  \\ IF_CASES_TAC >- ( fs[shift_def] )
  \\ simp[wordSemTheory.get_var_def,lookup_insert]
  \\ qpat_x_assum`¬_`kall_tac
  \\ BasicProvers.TOP_CASE_TAC
  >- (
    `F` suffices_by rw[]
    \\ pop_assum mp_tac
    \\ BasicProvers.CASE_TAC
    >- ( simp[wordSemTheory.cut_env_def,domain_lookup])
    \\ fs[cut_state_opt_def]
    \\ drule (#1(EQ_IMP_RULE cut_state_eq_some))
    \\ strip_tac
    \\ clean_tac
    \\ simp[wordSemTheory.cut_env_def]
    \\ rw[SUBSET_DEF,domain_lookup]
    \\ fs[dataSemTheory.cut_env_def]
    \\ clean_tac \\ fs[]
    \\ Cases_on`x=0` >- metis_tac[]
    \\ qmatch_assum_abbrev_tac`lookup x ss = SOME _`
    \\ `x ∈ domain ss` by metis_tac[domain_lookup]
    \\ qunabbrev_tac`ss`
    \\ imp_res_tac domain_adjust_set_EVEN
    \\ `∃z. x = adjust_var z`
    by (
      simp[adjust_var_def]
      \\ fs[EVEN_EXISTS]
      \\ Cases_on`m` \\ fs[ADD1,LEFT_ADD_DISTRIB] )
    \\ rveq
    \\ fs[lookup_adjust_var_adjust_set_SOME_UNIT]
    \\ last_x_assum(qspec_then`z`mp_tac)
    \\ simp[lookup_inter]
    \\ fs[IS_SOME_EXISTS]
    \\ disch_then match_mp_tac
    \\ BasicProvers.CASE_TAC
    \\ fs[SUBSET_DEF,domain_lookup]
    \\ res_tac \\ fs[])
  \\ qmatch_goalsub_abbrev_tac`read_bytearray aa len g`
  \\ qmatch_asmsub_rename_tac`LENGTH ls + 3`
  \\ qispl_then[`ls`,`LENGTH ls`,`aa`]mp_tac IMP_read_bytearray_GENLIST
  \\ impl_tac >- simp[]
  \\ `len = LENGTH ls`
  by (
    simp[Abbr`len`]
    \\ rfs[good_dimindex_def] \\ rfs[shift_def]
    \\ simp[bytes_in_word_def,GSYM word_add_n2w]
    \\ simp[dimword_def] )
  \\ qunabbrev_tac`len` \\ fs[]
  \\ rpt strip_tac
  \\ simp[Unit_def]
  \\ eval_tac
  \\ simp[lookup_insert]
  \\ fs[wordSemTheory.cut_env_def] \\ clean_tac
  \\ simp[lookup_inter,lookup_insert,lookup_adjust_var_adjust_set]
  \\ conj_tac >- ( simp[adjust_set_def,lookup_fromAList] )
  \\ fs[bvi_to_dataTheory.op_requires_names_def]
  \\ Cases_on`names_opt`\\fs[]
  \\ conj_tac
  >- (
    fs[cut_state_opt_def]
    \\ rw[]
    \\ first_assum drule
    \\ simp_tac(srw_ss())[IS_SOME_EXISTS] \\ strip_tac \\ fs[]
    \\ BasicProvers.TOP_CASE_TAC \\ simp[]
    \\ drule (#1(EQ_IMP_RULE cut_state_eq_some))
    \\ strip_tac \\ clean_tac
    \\ fs[dataSemTheory.cut_env_def] \\ clean_tac
    \\ fs[lookup_inter_alt,domain_lookup])
  \\ fs[inter_insert_ODD_adjust_set_alt]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert \\ fs[]
  \\ match_mp_tac memory_rel_Unit \\ fs[]
  \\ qmatch_goalsub_rename_tac`ByteArray F ls'`
  \\ `LENGTH ls' = LENGTH ls`
  by (
    qhdtm_x_assum`call_FFI`mp_tac
    \\ simp[ffiTheory.call_FFI_def]
    \\ BasicProvers.TOP_CASE_TAC \\ simp[]
    \\ BasicProvers.TOP_CASE_TAC \\ simp[]
    \\ BasicProvers.TOP_CASE_TAC \\ simp[]
    \\ rw[] \\ rw[] )
  \\ qmatch_asmsub_abbrev_tac`((RefPtr p,Word w)::vars)`
  \\ `∀n. n ≤ LENGTH ls ⇒
      let new_m = write_bytearray (aa + n2w (LENGTH ls - n)) (DROP (LENGTH ls - n) ls') t.memory t.mdomain t.be in
      memory_rel c t.be (x.refs |+ (p,ByteArray F (TAKE (LENGTH ls - n) ls ++ DROP (LENGTH ls - n) ls'))) x.space t.store
        new_m t.mdomain ((RefPtr p,Word w)::vars) ∧
      (∀i v. i < LENGTH ls ⇒
        memory_rel c t.be (x.refs |+ (p,ByteArray F (LUPDATE v i (TAKE (LENGTH ls - n) ls ++ DROP (LENGTH ls - n) ls'))))
          x.space t.store
          ((byte_align (aa + n2w i) =+
            Word (set_byte (aa + n2w i) v
                   (theWord (new_m (byte_align (aa + n2w i)))) t.be)) new_m)
           t.mdomain ((RefPtr p,Word w)::vars))`
  by (
    Induct \\ simp[]
    >- (
      simp[DROP_LENGTH_NIL_rwt,wordSemTheory.write_bytearray_def]
      \\ qpat_abbrev_tac`refs = x.refs |+ _`
      \\ `refs = x.refs`
      by(
        simp[Abbr`refs`,FLOOKUP_EXT,FUN_EQ_THM,FLOOKUP_UPDATE]
        \\ rw[] \\ rw[] )
      \\ rw[] )
    \\ strip_tac \\ fs[]
    \\ qpat_abbrev_tac`ls2 = TAKE _ _ ++ _`
    \\ qmatch_asmsub_abbrev_tac`ByteArray F ls1`
    \\ `ls2 = LUPDATE (EL (LENGTH ls - SUC n) ls') (LENGTH ls - SUC n) ls1`
    by (
      simp[Abbr`ls1`,Abbr`ls2`,LIST_EQ_REWRITE,EL_APPEND_EQN,EL_LUPDATE,DROP_def,TAKE_def]
      \\ rw[] \\ fs[] \\ simp[EL_TAKE,hd_drop,EL_DROP] \\ NO_TAC )
    \\ qunabbrev_tac`ls2` \\ fs[]
    \\ qmatch_goalsub_abbrev_tac`EL i ls'`
    \\ `i < LENGTH ls` by simp[Abbr`i`]
    \\ first_x_assum(qspecl_then[`i`,`EL i ls'`]mp_tac)
    \\ impl_tac >- rw[]
    \\ `DROP i ls' = EL i ls'::DROP(LENGTH ls - n)ls'`
    by (
      Cases_on`ls'` \\ fs[Abbr`i`]
      \\ simp[LIST_EQ_REWRITE,ADD1,EL_DROP,EL_CONS,PRE_SUB1]
      \\ Induct \\ rw[ADD1]
      \\ simp[EL_DROP]
      \\ `x'' + LENGTH ls - n = SUC(x'' + LENGTH ls - (n+1))` by decide_tac
      \\ pop_assum (CHANGED_TAC o SUBST1_TAC)
      \\ simp[EL] \\ NO_TAC)
    \\ first_assum SUBST1_TAC
    \\ qpat_abbrev_tac`wb = write_bytearray _ (_ :: _) _ _ _`
    \\ qpat_abbrev_tac `wb1 = write_bytearray _ _ _ _ _`
    \\ qpat_abbrev_tac`wb2 = _ wb1`
    \\ `wb2 = wb`
    by (
      simp[Abbr`wb2`,Abbr`wb`,wordSemTheory.write_bytearray_def]
      \\ `aa + n2w i + 1w = aa + n2w (LENGTH ls - n)`
      by(
        simp[Abbr`i`,ADD1]
        \\ REWRITE_TAC[GSYM WORD_ADD_ASSOC]
        \\ AP_TERM_TAC
        \\ simp[word_add_n2w] )
      \\ pop_assum SUBST_ALL_TAC \\ simp[]
      \\ simp[wordSemTheory.mem_store_byte_aux_def]
      \\ last_x_assum drule
      \\ simp[Abbr`g`,wordSemTheory.mem_load_byte_aux_def]
      \\ BasicProvers.TOP_CASE_TAC \\ simp[] \\ strip_tac
      \\ qmatch_assum_rename_tac`t.memory _ = Word v`
      \\ `∃v. wb1 (byte_align (aa + n2w i)) = Word v`
      by (
        `isWord (wb1 (byte_align (aa + n2w i)))`
        suffices_by (metis_tac[isWord_def,wordSemTheory.word_loc_nchotomy])
        \\ simp[Abbr`wb1`]
        \\ match_mp_tac write_bytearray_isWord
        \\ simp[isWord_def] )
      \\ simp[theWord_def] )
    \\ qunabbrev_tac`wb2`
    \\ pop_assum SUBST_ALL_TAC
    \\ strip_tac
    \\ conj_tac >- first_assum ACCEPT_TAC
    \\ drule (GEN_ALL memory_rel_ByteArray_IMP)
    \\ simp[FLOOKUP_UPDATE]
    \\ strip_tac
    \\ `LENGTH ls = LENGTH ls1`
    by ( unabbrev_all_tac \\ simp[] )
    \\ metis_tac[] )
  \\ first_x_assum(qspec_then`LENGTH ls`mp_tac)
  \\ simp[Abbr`vars`] \\ strip_tac
  \\ drule memory_rel_tl
  \\ ntac 10 (pop_assum kall_tac)
  \\ match_mp_tac memory_rel_rearrange
  \\ simp[join_env_def,MEM_MAP,PULL_EXISTS,MEM_FILTER,MEM_toAList,EXISTS_PROD,lookup_inter_alt]
  \\ rw[] \\ rw[] \\ metis_tac[]);

val assign_thm = Q.store_thm("assign_thm",
  `^assign_thm_goal`,
  Cases_on `op = AllocGlobal` \\ fs []
  THEN1 (fs [do_app] \\ every_case_tac \\ fs [])
  \\ Cases_on `?i. op = Global i` \\ fs []
  THEN1 (fs [do_app] \\ every_case_tac \\ fs [])
  \\ Cases_on `?i. op = SetGlobal i` \\ fs []
  THEN1 (fs [do_app] \\ every_case_tac \\ fs [])
  \\ Cases_on `op = Greater` \\ fs []
  THEN1 (fs [do_app] \\ every_case_tac \\ fs [])
  \\ Cases_on `op = GreaterEq` \\ fs []
  THEN1 (fs [do_app] \\ every_case_tac \\ fs [])
  \\ map_every (fn th =>
         (Cases_on `^(th |> concl |> dest_imp |> #1)` THEN1 (fs []
             \\ match_mp_tac th \\ fs [])))
      (DB.match ["-"] ``_ ==> ^assign_thm_goal`` |> map (#1 o #2))
  \\ fs [] \\ strip_tac
  \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ qsuff_tac `assign c n l dest op args names_opt = (GiveUp,l)` \\ fs []
  \\ `?f. f () = op` by (qexists_tac `K op` \\ fs []) (* here for debugging only *)
  \\ Cases_on `op` \\ fs []
  \\ fs [assign_def] \\ every_case_tac \\ fs []
  \\ qhdtm_x_assum`do_app`mp_tac \\ EVAL_TAC);

val none = ``NONE:(num # ('a wordLang$prog) # num # num) option``

val data_compile_correct = Q.store_thm("data_compile_correct",
  `!prog (s:'ffi dataSem$state) c n l l1 l2 res s1 (t:('a,'ffi)wordSem$state) locs.
      (dataSem$evaluate (prog,s) = (res,s1)) /\
      res <> SOME (Rerr (Rabort Rtype_error)) /\
      state_rel c l1 l2 s t [] locs /\
      t.termdep > 1
      ==>
      ?t1 res1.
        (wordSem$evaluate (FST (comp c n l prog),t) = (res1,t1)) /\
        (res1 = SOME NotEnoughSpace ==>
           t1.ffi.io_events ≼ s1.ffi.io_events ∧
           (IS_SOME t1.ffi.final_event ⇒ t1.ffi = s1.ffi)) /\
        (res1 <> SOME NotEnoughSpace ==>
         case res of
         | NONE => state_rel c l1 l2 s1 t1 [] locs /\ (res1 = NONE)
         | SOME (Rval v) =>
             ?w. state_rel c l1 l2 s1 t1 [(v,w)] locs /\
                 (res1 = SOME (Result (Loc l1 l2) w))
         | SOME (Rerr (Rraise v)) =>
             ?w l5 l6 ll.
               (res1 = SOME (Exception (mk_loc (jump_exc t)) w)) /\
               (jump_exc t <> NONE ==>
                LASTN (LENGTH s1.stack + 1) locs = (l5,l6)::ll /\
                !i. state_rel c l5 l6 (set_var i v s1)
                       (set_var (adjust_var i) w t1) [] ll)
         | SOME (Rerr (Rabort e)) => (res1 = SOME TimeOut) /\ t1.ffi = s1.ffi)`,
  recInduct dataSemTheory.evaluate_ind \\ rpt strip_tac \\ full_simp_tac(srw_ss())[]
  THEN1 (* Skip *)
   (full_simp_tac(srw_ss())[comp_def,dataSemTheory.evaluate_def,wordSemTheory.evaluate_def]
    \\ srw_tac[][])
  THEN1 (* Move *)
   (full_simp_tac(srw_ss())[comp_def,dataSemTheory.evaluate_def,wordSemTheory.evaluate_def]
    \\ Cases_on `get_var src s.locals` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
    \\ full_simp_tac(srw_ss())[] \\ imp_res_tac state_rel_get_var_IMP \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[wordSemTheory.get_vars_def,wordSemTheory.set_vars_def,alist_insert_def]
    \\ full_simp_tac(srw_ss())[state_rel_def,set_var_def,lookup_insert]
    \\ rpt strip_tac \\ full_simp_tac(srw_ss())[]
    THEN1 (srw_tac[][] \\ Cases_on `n = dest` \\ full_simp_tac(srw_ss())[])
    \\ asm_exists_tac
    \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC]
    \\ imp_res_tac word_ml_inv_get_var_IMP
    \\ match_mp_tac word_ml_inv_insert \\ full_simp_tac(srw_ss())[])
  THEN1 (* Assign *)
   (full_simp_tac(srw_ss())[comp_def,dataSemTheory.evaluate_def,wordSemTheory.evaluate_def]
    \\ imp_res_tac (METIS_PROVE [] ``(if b1 /\ b2 then x1 else x2) = y ==>
                                     b1 /\ b2 /\ x1 = y \/
                                     (b1 ==> ~b2) /\ x2 = y``)
    \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ Cases_on `cut_state_opt names_opt s` \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `get_vars args x.locals` \\ full_simp_tac(srw_ss())[]
    \\ reverse (Cases_on `do_app op x' x`) \\ full_simp_tac(srw_ss())[]
    THEN1 (imp_res_tac do_app_Rerr \\ srw_tac[][])
    \\ Cases_on `a`
    \\ drule (GEN_ALL assign_thm) \\ full_simp_tac(srw_ss())[]
    \\ rpt (disch_then drule)
    \\ disch_then (qspecl_then [`n`,`l`,`dest`] strip_assume_tac)
    \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
    \\ imp_res_tac do_app_io_events_mono \\ rev_full_simp_tac(srw_ss())[]
    \\ `s.ffi = t.ffi` by full_simp_tac(srw_ss())[state_rel_def] \\ full_simp_tac(srw_ss())[]
    \\ `x.ffi = s.ffi` by all_tac
    \\ imp_res_tac do_app_io_events_mono \\ rev_full_simp_tac(srw_ss())[]
    \\ Cases_on `names_opt` \\ full_simp_tac(srw_ss())[cut_state_opt_def] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[cut_state_def,cut_env_def] \\ every_case_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[])
  THEN1 (* Tick *)
   (full_simp_tac(srw_ss())[comp_def,dataSemTheory.evaluate_def,wordSemTheory.evaluate_def]
    \\ `t.clock = s.clock` by full_simp_tac(srw_ss())[state_rel_def] \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
    \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ rpt (pop_assum mp_tac)
    \\ full_simp_tac(srw_ss())[wordSemTheory.jump_exc_def,wordSemTheory.dec_clock_def] \\ srw_tac[][]
    \\ full_simp_tac(srw_ss())[state_rel_def,dataSemTheory.dec_clock_def,wordSemTheory.dec_clock_def]
    \\ full_simp_tac(srw_ss())[call_env_def,wordSemTheory.call_env_def]
    \\ asm_exists_tac \\ fs [])
  THEN1 (* MakeSpace *)
   (full_simp_tac(srw_ss())[comp_def,dataSemTheory.evaluate_def,
        wordSemTheory.evaluate_def,
        GSYM alloc_size_def,LET_DEF,wordSemTheory.word_exp_def,
        wordLangTheory.word_op_def,wordSemTheory.get_var_imm_def]
    \\ `?end next.
          FLOOKUP t.store TriggerGC = SOME (Word end) /\
          FLOOKUP t.store NextFree = SOME (Word next)` by
            full_simp_tac(srw_ss())[state_rel_def,heap_in_memory_store_def]
    \\ full_simp_tac(srw_ss())[wordSemTheory.the_words_def]
    \\ reverse CASE_TAC THEN1
     (every_case_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
      \\ full_simp_tac(srw_ss())[wordSemTheory.set_var_def,state_rel_insert_1]
      \\ match_mp_tac state_rel_cut_env \\ reverse (srw_tac[][])
      \\ full_simp_tac(srw_ss())[add_space_def] \\ match_mp_tac has_space_state_rel
      \\ full_simp_tac(srw_ss())[wordSemTheory.has_space_def,WORD_LO,NOT_LESS,
             asmTheory.word_cmp_def])
    \\ Cases_on `dataSem$cut_env names s.locals` \\ full_simp_tac(srw_ss())[]
    \\ srw_tac[][]
    \\ full_simp_tac(srw_ss())[add_space_def,wordSemTheory.word_exp_def,
         wordSemTheory.get_var_def,wordSemTheory.set_var_def]
    \\ Cases_on `(alloc (alloc_size k) (adjust_set names)
         (t with locals := insert 1 (Word (alloc_size k)) t.locals))
             :('a result option)#( ('a,'ffi) wordSem$state)`
    \\ full_simp_tac(srw_ss())[]
    \\ drule (GEN_ALL alloc_lemma)
    \\ rpt (disch_then drule)
    \\ rw [] \\ fs [])
  THEN1 (* Raise *)
   (full_simp_tac(srw_ss())[comp_def,dataSemTheory.evaluate_def,wordSemTheory.evaluate_def]
    \\ Cases_on `get_var n s.locals` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
    \\ full_simp_tac(srw_ss())[] \\ imp_res_tac state_rel_get_var_IMP \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `jump_exc s` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
    \\ imp_res_tac state_rel_jump_exc \\ full_simp_tac(srw_ss())[]
    \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ srw_tac[][mk_loc_def])
  THEN1 (* Return *)
   (full_simp_tac(srw_ss())[comp_def,dataSemTheory.evaluate_def,wordSemTheory.evaluate_def]
    \\ Cases_on `get_var n s.locals` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
    \\ `get_var 0 t = SOME (Loc l1 l2)` by
          full_simp_tac(srw_ss())[state_rel_def,wordSemTheory.get_var_def]
    \\ full_simp_tac(srw_ss())[] \\ imp_res_tac state_rel_get_var_IMP \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[state_rel_def,wordSemTheory.call_env_def,lookup_def,
           dataSemTheory.call_env_def,fromList_def,EVAL ``join_env LN []``,
           EVAL ``toAList (inter (fromList2 []) (insert 0 () LN))``]
    \\ asm_exists_tac \\ fs []
    \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC]
    \\ imp_res_tac word_ml_inv_get_var_IMP
    \\ pop_assum mp_tac
    \\ match_mp_tac word_ml_inv_rearrange
    \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[])
  THEN1 (* Seq *)
   (once_rewrite_tac [data_to_wordTheory.comp_def] \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `comp c n l c1` \\ full_simp_tac(srw_ss())[LET_DEF]
    \\ Cases_on `comp c n r c2` \\ full_simp_tac(srw_ss())[LET_DEF]
    \\ full_simp_tac(srw_ss())[dataSemTheory.evaluate_def,wordSemTheory.evaluate_def]
    \\ Cases_on `evaluate (c1,s)` \\ full_simp_tac(srw_ss())[LET_DEF]
    \\ `q'' <> SOME (Rerr (Rabort Rtype_error))` by
         (Cases_on `q'' = NONE` \\ full_simp_tac(srw_ss())[]) \\ full_simp_tac(srw_ss())[]
    \\ fs[GSYM AND_IMP_INTRO]
    \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` (fn th =>
           first_x_assum (fn th1 => mp_tac (MATCH_MP th1 th)))
    \\ fs[]
    \\ strip_tac \\ pop_assum (mp_tac o Q.SPECL [`n`,`l`])
    \\ rpt strip_tac \\ rev_full_simp_tac(srw_ss())[]
    \\ reverse (Cases_on `q'' = NONE`) \\ full_simp_tac(srw_ss())[]
    THEN1 (full_simp_tac(srw_ss())[] \\ rpt strip_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ Cases_on `q''` \\ full_simp_tac(srw_ss())[]
           \\ Cases_on `x` \\ full_simp_tac(srw_ss())[] \\ Cases_on `e` \\ full_simp_tac(srw_ss())[])
    \\ Cases_on `res1 = SOME NotEnoughSpace` \\ full_simp_tac(srw_ss())[]
    THEN1 (full_simp_tac(srw_ss())[]
      \\ imp_res_tac dataPropsTheory.evaluate_io_events_mono \\ full_simp_tac(srw_ss())[]
      \\ imp_res_tac IS_PREFIX_TRANS \\ full_simp_tac(srw_ss())[] \\ metis_tac []) \\ srw_tac[][]
    \\ qpat_x_assum `state_rel c l1 l2 _ _ [] locs` (fn th =>
             first_x_assum (fn th1 => mp_tac (MATCH_MP th1 th)))
    \\ imp_res_tac wordSemTheory.evaluate_clock \\ fs[]
    \\ strip_tac \\ pop_assum (mp_tac o Q.SPECL [`n`,`r`])
    \\ rpt strip_tac \\ rev_full_simp_tac(srw_ss())[] \\ rpt strip_tac \\ full_simp_tac(srw_ss())[]
    \\ BasicProvers.EVERY_CASE_TAC \\ full_simp_tac(srw_ss())[mk_loc_def] \\ full_simp_tac(srw_ss())[]
    \\ imp_res_tac evaluate_mk_loc_EQ \\ full_simp_tac(srw_ss())[]
    \\ imp_res_tac eval_NONE_IMP_jump_exc_NONE_EQ
    \\ full_simp_tac(srw_ss())[jump_exc_inc_clock_EQ_NONE] \\ metis_tac [])
  THEN1 (* If *)
   (once_rewrite_tac [data_to_wordTheory.comp_def] \\ full_simp_tac(srw_ss())[]
    \\ fs [LET_DEF]
    \\ pairarg_tac \\ fs [] \\ rename1 `comp c n4 l c1 = (q4,l4)`
    \\ pairarg_tac \\ fs [] \\ rename1 `comp c _ _ _ = (q5,l5)`
    \\ full_simp_tac(srw_ss())[dataSemTheory.evaluate_def,wordSemTheory.evaluate_def]
    \\ Cases_on `get_var n s.locals` \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[] \\ imp_res_tac state_rel_get_var_IMP
    \\ full_simp_tac(srw_ss())[wordSemTheory.get_var_imm_def,
          asmTheory.word_cmp_def]
    \\ imp_res_tac get_var_T_OR_F
    \\ fs[GSYM AND_IMP_INTRO]
    \\ Cases_on `x = Boolv T` \\ full_simp_tac(srw_ss())[] THEN1
     (qpat_x_assum `state_rel c l1 l2 s t [] locs` (fn th =>
               first_x_assum (fn th1 => mp_tac (MATCH_MP th1 th)))
      \\ strip_tac \\ pop_assum (qspecl_then [`n4`,`l`] mp_tac)
      \\ rpt strip_tac \\ rev_full_simp_tac(srw_ss())[])
    \\ Cases_on `x = Boolv F` \\ full_simp_tac(srw_ss())[] THEN1
     (qpat_x_assum `state_rel c l1 l2 s t [] locs` (fn th =>
               first_x_assum (fn th1 => mp_tac (MATCH_MP th1 th)))
      \\ strip_tac \\ pop_assum (qspecl_then [`n4`,`l4`] mp_tac)
      \\ rpt strip_tac \\ rev_full_simp_tac(srw_ss())[]))
  THEN1 (* Call *)
   (`t.clock = s.clock` by fs [state_rel_def]
    \\ once_rewrite_tac [data_to_wordTheory.comp_def] \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `ret`
    \\ full_simp_tac(srw_ss())[dataSemTheory.evaluate_def,wordSemTheory.evaluate_def,
           wordSemTheory.add_ret_loc_def,get_vars_inc_clock]
    THEN1 (* ret = NONE *)
     (full_simp_tac(srw_ss())[wordSemTheory.bad_dest_args_def]
      \\ Cases_on `get_vars args s.locals` \\ full_simp_tac(srw_ss())[]
      \\ imp_res_tac state_rel_0_get_vars_IMP \\ full_simp_tac(srw_ss())[]
      \\ Cases_on `find_code dest x s.code` \\ full_simp_tac(srw_ss())[]
      \\ rename1 `_ = SOME x9` \\ Cases_on `x9` \\ full_simp_tac(srw_ss())[]
      \\ Cases_on `handler` \\ full_simp_tac(srw_ss())[]
      \\ `t.clock = s.clock` by full_simp_tac(srw_ss())[state_rel_def]
      \\ drule (GEN_ALL find_code_thm) \\ rpt (disch_then drule)
      \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
      \\ Cases_on `s.clock = 0` \\ fs[] \\ srw_tac[][] \\ fs[]
      THEN1 (fs[call_env_def,wordSemTheory.call_env_def,state_rel_def])
      \\ Cases_on `evaluate (r,call_env q (dec_clock s))` \\ fs[]
      \\ Cases_on `q'` \\ full_simp_tac(srw_ss())[]
      \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ res_tac
      \\ pop_assum kall_tac
      \\ pop_assum mp_tac \\ impl_tac
      >-
        fs[wordSemTheory.call_env_def,wordSemTheory.dec_clock_def]
      \\ disch_then (qspecl_then [`n1`,`n2`] strip_assume_tac) \\ fs[]
      \\ `t.clock <> 0` by full_simp_tac(srw_ss())[state_rel_def]
      \\ Cases_on `res1` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ fs[]
      \\ every_case_tac \\ full_simp_tac(srw_ss())[mk_loc_def]
      \\ fs [wordSemTheory.jump_exc_def,wordSemTheory.call_env_def,
             wordSemTheory.dec_clock_def]
      \\ BasicProvers.EVERY_CASE_TAC \\ full_simp_tac(srw_ss())[mk_loc_def])
    \\ Cases_on `x` \\ full_simp_tac(srw_ss())[LET_DEF]
    \\ `domain (adjust_set r) <> {}` by fs[adjust_set_def,domain_fromAList]
    \\ Cases_on `handler` \\ full_simp_tac(srw_ss())[wordSemTheory.evaluate_def]
    \\ Cases_on `get_vars args s.locals` \\ full_simp_tac(srw_ss())[]
    \\ imp_res_tac state_rel_get_vars_IMP \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[wordSemTheory.add_ret_loc_def]
    THEN1 (* no handler *)
     (Cases_on `bvlSem$find_code dest x s.code` \\ fs[]
      \\ rename1 `_ = SOME x9` \\ Cases_on `x9` \\ full_simp_tac(srw_ss())[]
      \\ rename1 `_ = SOME (actual_args,called_prog)`
      \\ imp_res_tac bvl_find_code
      \\ `¬bad_dest_args dest (MAP adjust_var args)` by
        (full_simp_tac(srw_ss())[wordSemTheory.bad_dest_args_def]>>
        imp_res_tac get_vars_IMP_LENGTH>>
        metis_tac[LENGTH_NIL])
      \\ Q.MATCH_ASSUM_RENAME_TAC `bvlSem$find_code dest xs s.code = SOME (ys,prog)`
      \\ Cases_on `dataSem$cut_env r s.locals` \\ full_simp_tac(srw_ss())[]
      \\ imp_res_tac cut_env_IMP_cut_env \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
      \\ `t.clock = s.clock` by full_simp_tac(srw_ss())[state_rel_def]
      \\ full_simp_tac(srw_ss())[]
      \\ rpt_drule find_code_thm_ret
      \\ disch_then (qspecl_then [`n`,`l`] strip_assume_tac) \\ fs []
      \\ Cases_on `s.clock = 0` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
      THEN1 (fs[call_env_def,wordSemTheory.call_env_def,state_rel_def])
      \\ Cases_on `evaluate (prog,call_env ys (push_env x F (dec_clock s)))`
      \\ full_simp_tac(srw_ss())[] \\ Cases_on `q'` \\ full_simp_tac(srw_ss())[]
      \\ Cases_on `x' = Rerr (Rabort Rtype_error)` \\ full_simp_tac(srw_ss())[]
      \\ res_tac (* inst ind hyp *)
      \\ pop_assum kall_tac
      \\ pop_assum mp_tac \\ impl_tac >-
        fs[wordSemTheory.call_env_def,wordSemTheory.push_env_def,wordSemTheory.env_to_list_def,wordSemTheory.dec_clock_def]
      \\ disch_then (qspecl_then [`n1`,`n2`] strip_assume_tac)
      \\ full_simp_tac(srw_ss())[]
      \\ Cases_on `res1 = SOME NotEnoughSpace` \\ full_simp_tac(srw_ss())[]
      THEN1
       (`s1.ffi = r'.ffi` by all_tac \\ full_simp_tac(srw_ss())[]
        \\ every_case_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
        \\ full_simp_tac(srw_ss())[set_var_def]
        \\ imp_res_tac dataPropsTheory.pop_env_const \\ full_simp_tac(srw_ss())[]
        \\ imp_res_tac wordPropsTheory.pop_env_const \\ full_simp_tac(srw_ss())[])
      \\ reverse (Cases_on `x'` \\ full_simp_tac(srw_ss())[])
      THEN1 (Cases_on `e` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
        \\ full_simp_tac(srw_ss())[jump_exc_call_env,jump_exc_dec_clock,jump_exc_push_env_NONE]
        \\ Cases_on `jump_exc t = NONE` \\ full_simp_tac(srw_ss())[]
        \\ full_simp_tac(srw_ss())[jump_exc_push_env_NONE_simp]
        \\ `LENGTH r'.stack < LENGTH locs` by ALL_TAC
        \\ imp_res_tac LASTN_TL \\ full_simp_tac(srw_ss())[]
        \\ `LENGTH locs = LENGTH s.stack` by
           (full_simp_tac(srw_ss())[state_rel_def] \\ imp_res_tac LIST_REL_LENGTH \\ full_simp_tac(srw_ss())[]) \\ full_simp_tac(srw_ss())[]
        \\ imp_res_tac eval_exc_stack_shorter)
      \\ Cases_on `pop_env r'` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
      \\ rpt_drule state_rel_pop_env_set_var_IMP \\ fs []
      \\ disch_then (qspec_then `q` strip_assume_tac) \\ fs []
      \\ imp_res_tac evaluate_IMP_domain_EQ \\ full_simp_tac(srw_ss())[])
    (* with handler *)
    \\ PairCases_on `x` \\ full_simp_tac(srw_ss())[]
    \\ `?prog1 h1. comp c n (l + 2) x1 = (prog1,h1)` by METIS_TAC [PAIR]
    \\ fs[wordSemTheory.evaluate_def,wordSemTheory.add_ret_loc_def]
    \\ Cases_on `bvlSem$find_code dest x' s.code` \\ fs[] \\ Cases_on `x` \\ fs[]
    \\ imp_res_tac bvl_find_code
    \\ `¬bad_dest_args dest (MAP adjust_var args)` by
        (full_simp_tac(srw_ss())[wordSemTheory.bad_dest_args_def]>>
        imp_res_tac get_vars_IMP_LENGTH>>
        metis_tac[LENGTH_NIL])
    \\ Q.MATCH_ASSUM_RENAME_TAC `bvlSem$find_code dest xs s.code = SOME (ys,prog)`
    \\ Cases_on `dataSem$cut_env r s.locals` \\ full_simp_tac(srw_ss())[]
    \\ imp_res_tac cut_env_IMP_cut_env \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
    \\ rpt_drule find_code_thm_handler \\ fs []
    \\ disch_then (qspecl_then [`x0`,`n`,`prog1`,`n`,`l`] strip_assume_tac) \\ fs []
    \\ Cases_on `s.clock = 0` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
    THEN1 (fs[call_env_def,wordSemTheory.call_env_def,state_rel_def])
    \\ Cases_on `evaluate (prog,call_env ys (push_env x T (dec_clock s)))`
    \\ full_simp_tac(srw_ss())[] \\ Cases_on `q'` \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `x' = Rerr (Rabort Rtype_error)` \\ full_simp_tac(srw_ss())[]
    \\ res_tac (* inst ind hyp *)
    \\ pop_assum kall_tac
    \\ pop_assum mp_tac \\ impl_tac >-
        fs[wordSemTheory.call_env_def,wordSemTheory.push_env_def,wordSemTheory.env_to_list_def,wordSemTheory.dec_clock_def]
    \\ disch_then (qspecl_then [`n1`,`n2`] strip_assume_tac) \\ fs[]
    \\ Cases_on `res1 = SOME NotEnoughSpace` \\ full_simp_tac(srw_ss())[]
    THEN1 (full_simp_tac(srw_ss())[]
      \\ `r'.ffi.io_events ≼ s1.ffi.io_events ∧
          (IS_SOME t1.ffi.final_event ⇒ r'.ffi = s1.ffi)` by all_tac
      \\ TRY (imp_res_tac IS_PREFIX_TRANS \\ full_simp_tac(srw_ss())[] \\ NO_TAC)
      \\ every_case_tac \\ full_simp_tac(srw_ss())[]
      \\ imp_res_tac dataPropsTheory.evaluate_io_events_mono \\ full_simp_tac(srw_ss())[set_var_def]
      \\ imp_res_tac wordPropsTheory.pop_env_const \\ full_simp_tac(srw_ss())[]
      \\ imp_res_tac dataPropsTheory.pop_env_const \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
      \\ metis_tac [])
    \\ Cases_on `x'` \\ full_simp_tac(srw_ss())[] THEN1
     (Cases_on `pop_env r'` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
      \\ rpt strip_tac \\ full_simp_tac(srw_ss())[]
      \\ rpt_drule state_rel_pop_env_set_var_IMP \\ fs []
      \\ disch_then (qspec_then `q` strip_assume_tac) \\ fs []
      \\ imp_res_tac evaluate_IMP_domain_EQ \\ full_simp_tac(srw_ss())[])
    \\ reverse (Cases_on `e`) \\ full_simp_tac(srw_ss())[]
    THEN1 (full_simp_tac(srw_ss())[] \\ srw_tac[][])
    \\ full_simp_tac(srw_ss())[mk_loc_jump_exc]
    \\ imp_res_tac evaluate_IMP_domain_EQ_Exc \\ full_simp_tac(srw_ss())[]
    \\ qpat_x_assum `!x y z.bbb` (K ALL_TAC)
    \\ full_simp_tac(srw_ss())[jump_exc_push_env_NONE_simp,jump_exc_push_env_SOME]
    \\ imp_res_tac eval_push_env_T_Raise_IMP_stack_length
    \\ `LENGTH s.stack = LENGTH locs` by
         (full_simp_tac(srw_ss())[state_rel_def]
          \\ imp_res_tac LIST_REL_LENGTH \\ fs[]) \\ fs []
    \\ full_simp_tac(srw_ss())[LASTN_ADD1] \\ srw_tac[][]
    \\ first_x_assum (qspec_then `x0` assume_tac)
    \\ res_tac (* inst ind hyp *)
    \\ pop_assum kall_tac
    \\ pop_assum mp_tac \\ impl_tac >-
      (imp_res_tac wordSemTheory.evaluate_clock>>
      fs[wordSemTheory.set_var_def,wordSemTheory.call_env_def,wordSemTheory.push_env_def,wordSemTheory.env_to_list_def,wordSemTheory.dec_clock_def])
    \\ disch_then (qspecl_then [`n`,`l+2`] strip_assume_tac) \\ rfs []
    \\ `jump_exc (set_var (adjust_var x0) w t1) = jump_exc t1` by
          fs[wordSemTheory.set_var_def,wordSemTheory.jump_exc_def]
    \\ full_simp_tac(srw_ss())[] \\ rpt strip_tac \\ full_simp_tac(srw_ss())[]
    \\ imp_res_tac evaluate_IMP_domain_EQ_Exc \\ full_simp_tac(srw_ss())[]
    \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `res` \\ full_simp_tac(srw_ss())[]
    \\ rpt (CASE_TAC \\ full_simp_tac(srw_ss())[])
    \\ imp_res_tac mk_loc_eq_push_env_exc_Exception \\ full_simp_tac(srw_ss())[]
    \\ imp_res_tac eval_push_env_SOME_exc_IMP_s_key_eq
    \\ imp_res_tac s_key_eq_handler_eq_IMP
    \\ full_simp_tac(srw_ss())[jump_exc_inc_clock_EQ_NONE] \\ metis_tac []));

val compile_correct_lemma = Q.store_thm("compile_correct_lemma",
  `!(s:'ffi dataSem$state) c l1 l2 res s1 (t:('a,'ffi)wordSem$state) start.
      (dataSem$evaluate (Call NONE (SOME start) [] NONE,s) = (res,s1)) /\
      res <> SOME (Rerr (Rabort Rtype_error)) /\
      t.termdep > 1 /\
      state_rel c l1 l2 s t [] [] ==>
      ?t1 res1.
        (wordSem$evaluate (Call NONE (SOME start) [0] NONE,t) = (res1,t1)) /\
        (res1 = SOME NotEnoughSpace ==>
           t1.ffi.io_events ≼ s1.ffi.io_events ∧
           (IS_SOME t1.ffi.final_event ==> t1.ffi = s1.ffi)) /\
        (res1 <> SOME NotEnoughSpace ==>
         case res of
        | NONE => (res1 = NONE)
        | SOME (Rval v) => t1.ffi = s1.ffi /\
                           ?w. (res1 = SOME (Result (Loc l1 l2) w))
        | SOME (Rerr (Rraise v)) => (?v w. res1 = SOME (Exception v w))
        | SOME (Rerr (Rabort e)) => (res1 = SOME TimeOut) /\ t1.ffi = s1.ffi)`,
  rpt strip_tac
  \\ drule data_compile_correct \\ full_simp_tac(srw_ss())[]
  \\ ntac 2 (disch_then drule) \\ full_simp_tac(srw_ss())[comp_def]
  \\ strip_tac
  \\ qexists_tac `t1`
  \\ qexists_tac `res1`
  \\ full_simp_tac(srw_ss())[] \\ strip_tac \\ full_simp_tac(srw_ss())[]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[state_rel_def]);

val state_rel_ext_def = Define `
  state_rel_ext c l1 l2 s u <=>
    ?t l.
      state_rel c l1 l2 s t [] [] /\
      t.termdep > 1  /\
      (!n v. lookup n t.code = SOME v ==>
             ∃t' k' a' c' col.
             lookup n l = SOME (SND (full_compile_single t' k' a' c' ((n,v),col)))) /\
      u = t with <|code := l;termdep:=0|>`

val compile_correct = Q.store_thm("compile_correct",
  `!x (s:'ffi dataSem$state) l1 l2 res s1 (t:('a,'ffi)wordSem$state) start.
      (dataSem$evaluate (Call NONE (SOME start) [] NONE,s) = (res,s1)) /\
      res <> SOME (Rerr (Rabort Rtype_error)) /\
      state_rel_ext x l1 l2 s t ==>
      ?ck t1 res1.
        (wordSem$evaluate (Call NONE (SOME start) [0] NONE,
           (inc_clock ck t)) = (res1,t1)) /\
        (res1 = SOME NotEnoughSpace ==>
           t1.ffi.io_events ≼ s1.ffi.io_events ∧
           (IS_SOME t1.ffi.final_event ==> t1.ffi = s1.ffi)) /\
        (res1 <> SOME NotEnoughSpace ==>
         case res of
         | NONE => (res1 = NONE)
         | SOME (Rval v) => t1.ffi = s1.ffi /\
                            ?w. (res1 = SOME (Result (Loc l1 l2) w))
         | SOME (Rerr (Rraise v)) => (?v w. res1 = SOME (Exception v w))
         | SOME (Rerr (Rabort e)) => (res1 = SOME TimeOut) /\ t1.ffi = s1.ffi)`,
  gen_tac
  \\ full_simp_tac(srw_ss())[state_rel_ext_def,PULL_EXISTS] \\ srw_tac[][]
  \\ rename1 `state_rel x0 l1 l2 s t [] []`
  \\ drule compile_word_to_word_thm
  \\ impl_tac THEN1 fs [state_rel_def,gc_fun_const_ok_word_gc_fun]
  \\ srw_tac[][]
  \\ drule compile_correct_lemma \\ full_simp_tac(srw_ss())[]
  \\ `state_rel x0 l1 l2 s (t with permute := perm') [] []` by
   (full_simp_tac(srw_ss())[state_rel_def] \\ rev_full_simp_tac(srw_ss())[]
    \\ Cases_on `s.stack` \\ full_simp_tac(srw_ss())[] \\ metis_tac [])
  \\ `(t with permute := perm').termdep > 1` by fs[]
  \\ ntac 2 (disch_then drule) \\ strip_tac
  \\ qexists_tac `clk` \\ full_simp_tac(srw_ss())[]
  \\ qpat_x_assum `let prog = Call NONE (SOME start) [0] NONE in _` mp_tac
  \\ full_simp_tac(srw_ss())[LET_THM] \\ strip_tac
  THEN1 (full_simp_tac(srw_ss())[] \\ every_case_tac \\ full_simp_tac(srw_ss())[])
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[] \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[inc_clock_def]
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ every_case_tac \\ full_simp_tac(srw_ss())[]);

val state_rel_ext_with_clock = Q.prove(
  `state_rel_ext a b c s1 s2 ==>
    state_rel_ext a b c (s1 with clock := k) (s2 with clock := k)`,
  full_simp_tac(srw_ss())[state_rel_ext_def] \\ srw_tac[][]
  \\ drule state_rel_with_clock
  \\ strip_tac \\ asm_exists_tac \\ full_simp_tac(srw_ss())[]
  \\ qexists_tac `l` \\ full_simp_tac(srw_ss())[]);

(* observational semantics preservation *)

val compile_semantics_lemma = Q.store_thm("compile_semantics_lemma",
  `state_rel_ext conf 1 0 (initial_state (ffi:'ffi ffi_state) (fromAList prog) t.clock) t /\
   semantics ffi (fromAList prog) start <> Fail ==>
   semantics t start IN
     extend_with_resource_limit { semantics ffi (fromAList prog) start }`,
  simp[GSYM AND_IMP_INTRO] >> ntac 1 strip_tac >>
  simp[dataSemTheory.semantics_def] >>
  IF_CASES_TAC >> full_simp_tac(srw_ss())[] >>
  DEEP_INTRO_TAC some_intro >> simp[] >>
  conj_tac >- (
    qx_gen_tac`r`>>simp[]>>strip_tac>>
    strip_tac >>
    simp[wordSemTheory.semantics_def] >>
    IF_CASES_TAC >- (
      full_simp_tac(srw_ss())[] >> rveq >> full_simp_tac(srw_ss())[] >>
      qhdtm_x_assum`dataSem$evaluate`kall_tac >>
      last_x_assum(qspec_then`k'`mp_tac)>>simp[] >>
      (fn g => subterm (fn tm => Cases_on`^(assert(has_pair_type)tm)`) (#2 g) g) >>
      strip_tac >>
      drule compile_correct >> simp[] >> full_simp_tac(srw_ss())[] >>
      simp[RIGHT_FORALL_IMP_THM,GSYM AND_IMP_INTRO] >>
      impl_tac >- (
        strip_tac >> full_simp_tac(srw_ss())[] ) >>
      drule(GEN_ALL state_rel_ext_with_clock) >>
      disch_then(qspec_then`k'`strip_assume_tac) >> full_simp_tac(srw_ss())[] >>
      disch_then drule >>
      simp[comp_def] >> strip_tac >>
      qmatch_assum_abbrev_tac`option_CASE (FST p) _ _` >>
      Cases_on`p`>>pop_assum(strip_assume_tac o SYM o REWRITE_RULE[markerTheory.Abbrev_def]) >>
      drule (GEN_ALL wordPropsTheory.evaluate_add_clock) >>
      simp[RIGHT_FORALL_IMP_THM] >>
      impl_tac >- (strip_tac >> full_simp_tac(srw_ss())[]) >>
      disch_then(qspec_then`ck`mp_tac) >>
      fsrw_tac[ARITH_ss][inc_clock_def] >> srw_tac[][] >>
      every_case_tac >> full_simp_tac(srw_ss())[] ) >>
    DEEP_INTRO_TAC some_intro >> simp[] >>
    conj_tac >- (
      srw_tac[][extend_with_resource_limit_def] >> full_simp_tac(srw_ss())[] >>
      Cases_on`s.ffi.final_event`>>full_simp_tac(srw_ss())[] >- (
        Cases_on`r'`>>full_simp_tac(srw_ss())[] >> rveq >>
        drule(dataPropsTheory.evaluate_add_clock)>>simp[]>>
        disch_then(qspec_then`k'`mp_tac)>>simp[]>>strip_tac>>
        drule(compile_correct)>>simp[]>>
        drule(GEN_ALL state_rel_ext_with_clock)>>simp[]>>
        disch_then(qspec_then`k+k'`mp_tac)>>simp[]>>strip_tac>>
        disch_then drule>>
        simp[comp_def]>>strip_tac>>
        `t'.ffi.io_events ≼ t1.ffi.io_events ∧
         (IS_SOME t'.ffi.final_event ⇒ t1.ffi = t'.ffi)` by (
           qmatch_assum_abbrev_tac`evaluate (exps,tt) = (_,t')` >>
           Q.ISPECL_THEN[`exps`,`tt`]mp_tac wordPropsTheory.evaluate_add_clock_io_events_mono >>
           full_simp_tac(srw_ss())[inc_clock_def,Abbr`tt`] >>
           disch_then(qspec_then`k+ck`mp_tac)>>simp[]>>
           fsrw_tac[ARITH_ss][] ) >>
        Cases_on`r = SOME TimeOut` >- (
          every_case_tac >> full_simp_tac(srw_ss())[]>>
          Cases_on`res1=SOME NotEnoughSpace`>>full_simp_tac(srw_ss())[] >> rev_full_simp_tac(srw_ss())[] >>
          full_simp_tac(srw_ss())[] >> rev_full_simp_tac(srw_ss())[] ) >>
        qhdtm_x_assum`wordSem$evaluate`mp_tac >>
        drule(GEN_ALL wordPropsTheory.evaluate_add_clock) >>
        simp[] >>
        disch_then(qspec_then`ck+k`mp_tac) >>
        simp[inc_clock_def] >> ntac 2 strip_tac >>
        rveq >> full_simp_tac(srw_ss())[] >>
        every_case_tac >> full_simp_tac(srw_ss())[] >> srw_tac[][] >>
        full_simp_tac(srw_ss())[] >> rev_full_simp_tac(srw_ss())[] ) >>
      `∃r s'.
        evaluate
          (Call NONE (SOME start) [] NONE, initial_state ffi (fromAList prog) (k + k')) = (r,s') ∧
        s'.ffi = s.ffi` by (
          srw_tac[QUANT_INST_ss[pair_default_qp]][] >>
          metis_tac[dataPropsTheory.evaluate_add_clock_io_events_mono,SND,
                    initial_state_with_simp,IS_SOME_EXISTS,initial_state_simp]) >>
      drule compile_correct >> simp[] >>
      simp[GSYM AND_IMP_INTRO,RIGHT_FORALL_IMP_THM] >>
      impl_tac >- (
        last_x_assum(qspec_then`k+k'`mp_tac)>>srw_tac[][]>>
        strip_tac>>full_simp_tac(srw_ss())[])>>
      drule(GEN_ALL state_rel_ext_with_clock)>>simp[]>>
      disch_then(qspec_then`k+k'`mp_tac)>>simp[]>>strip_tac>>
      disch_then drule>>
      simp[comp_def]>>strip_tac>>
      `t'.ffi.io_events ≼ t1.ffi.io_events ∧
       (IS_SOME t'.ffi.final_event ⇒ t1.ffi = t'.ffi)` by (
        qmatch_assum_abbrev_tac`evaluate (exps,tt) = (_,t')` >>
        Q.ISPECL_THEN[`exps`,`tt`]mp_tac wordPropsTheory.evaluate_add_clock_io_events_mono >>
        full_simp_tac(srw_ss())[inc_clock_def,Abbr`tt`] >>
        disch_then(qspec_then`k+ck`mp_tac)>>simp[]>>
        fsrw_tac[ARITH_ss][] ) >>
      reverse(Cases_on`t'.ffi.final_event`)>>full_simp_tac(srw_ss())[] >- (
        Cases_on`res1=SOME NotEnoughSpace`>>full_simp_tac(srw_ss())[]>>
        full_simp_tac(srw_ss())[]>>rev_full_simp_tac(srw_ss())[]>>
        every_case_tac>>full_simp_tac(srw_ss())[]>>rev_full_simp_tac(srw_ss())[]>>
        rveq>>full_simp_tac(srw_ss())[]>>
        last_x_assum(qspec_then`k+k'`mp_tac) >> simp[]) >>
      Cases_on`r`>>full_simp_tac(srw_ss())[]>>
      qhdtm_x_assum`wordSem$evaluate`mp_tac >>
      drule(GEN_ALL wordPropsTheory.evaluate_add_clock) >>
      simp[RIGHT_FORALL_IMP_THM] >>
      impl_tac >- ( strip_tac >> full_simp_tac(srw_ss())[] ) >>
      disch_then(qspec_then`k+ck`mp_tac) >>
      fsrw_tac[ARITH_ss][inc_clock_def]>> srw_tac[][] >>
      every_case_tac>>full_simp_tac(srw_ss())[]>>rveq>>rev_full_simp_tac(srw_ss())[]>>
      full_simp_tac(srw_ss())[]>>rev_full_simp_tac(srw_ss())[]) >>
    srw_tac[][] >> full_simp_tac(srw_ss())[] >>
    drule compile_correct >> simp[] >>
    simp[RIGHT_FORALL_IMP_THM,GSYM AND_IMP_INTRO] >>
    impl_tac >- (
      last_x_assum(qspec_then`k`mp_tac)>>simp[] >>
      srw_tac[][] >> strip_tac >> full_simp_tac(srw_ss())[] ) >>
    drule(state_rel_ext_with_clock) >> simp[] >> strip_tac >>
    disch_then drule >>
    simp[comp_def] >> strip_tac >>
    first_x_assum(qspec_then`k+ck`mp_tac) >>
    full_simp_tac(srw_ss())[inc_clock_def] >>
    first_x_assum(qspec_then`k+ck`mp_tac) >>
    simp[] >>
    every_case_tac >> full_simp_tac(srw_ss())[] >> srw_tac[][]) >>
  srw_tac[][] >>
  simp[wordSemTheory.semantics_def] >>
  IF_CASES_TAC >- (
    full_simp_tac(srw_ss())[] >> rveq >> full_simp_tac(srw_ss())[] >>
    last_x_assum(qspec_then`k`mp_tac)>>simp[] >>
    (fn g => subterm (fn tm => Cases_on`^(assert(has_pair_type)tm)`) (#2 g) g) >>
    strip_tac >>
    drule compile_correct >> simp[] >>
    simp[RIGHT_FORALL_IMP_THM,GSYM AND_IMP_INTRO] >>
    impl_tac >- ( strip_tac >> full_simp_tac(srw_ss())[] ) >>
    drule(state_rel_ext_with_clock) >>
    simp[] >> strip_tac >>
    disch_then drule >>
    simp[comp_def] >> strip_tac >>
    qmatch_assum_abbrev_tac`option_CASE (FST p) _ _` >>
    Cases_on`p`>>pop_assum(strip_assume_tac o SYM o REWRITE_RULE[markerTheory.Abbrev_def]) >>
    drule (GEN_ALL wordPropsTheory.evaluate_add_clock) >>
    simp[RIGHT_FORALL_IMP_THM] >>
    impl_tac >- (strip_tac >> full_simp_tac(srw_ss())[]) >>
    disch_then(qspec_then`ck`mp_tac) >>
    fsrw_tac[ARITH_ss][inc_clock_def] >> srw_tac[][] >>
    every_case_tac >> full_simp_tac(srw_ss())[] ) >>
  DEEP_INTRO_TAC some_intro >> simp[] >>
  conj_tac >- (
    srw_tac[][extend_with_resource_limit_def] >> full_simp_tac(srw_ss())[] >>
    qpat_x_assum`∀x y. _`(qspec_then`k`mp_tac)>>
    (fn g => subterm (fn tm => Cases_on`^(assert(has_pair_type)tm)`) (#2 g) g) >>
    strip_tac >>
    drule(compile_correct)>>
    simp[RIGHT_FORALL_IMP_THM,GSYM AND_IMP_INTRO] >>
    impl_tac >- (
      strip_tac >> full_simp_tac(srw_ss())[] >>
      last_x_assum(qspec_then`k`mp_tac) >>
      simp[] ) >>
    drule(state_rel_ext_with_clock) >>
    simp[] >> strip_tac >>
    disch_then drule >>
    simp[comp_def] >> strip_tac >>
    `t'.ffi.io_events ≼ t1.ffi.io_events ∧
     (IS_SOME t'.ffi.final_event ⇒ t1.ffi = t'.ffi)` by (
      qmatch_assum_abbrev_tac`evaluate (exps,tt) = (_,t')` >>
      Q.ISPECL_THEN[`exps`,`tt`]mp_tac wordPropsTheory.evaluate_add_clock_io_events_mono >>
      full_simp_tac(srw_ss())[inc_clock_def,Abbr`tt`] >>
      disch_then(qspec_then`ck`mp_tac)>>simp[]) >>
    full_simp_tac(srw_ss())[] >>
    first_assum(qspec_then`k`mp_tac) >>
    first_x_assum(qspec_then`k+ck`mp_tac) >>
    fsrw_tac[ARITH_ss][inc_clock_def] >>
    qhdtm_x_assum`wordSem$evaluate`mp_tac >>
    drule(GEN_ALL wordPropsTheory.evaluate_add_clock)>>
    simp[]>>
    disch_then(qspec_then`ck`mp_tac)>>
    last_x_assum(qspec_then`k`mp_tac) >>
    every_case_tac >> full_simp_tac(srw_ss())[] >> rev_full_simp_tac(srw_ss())[]>>srw_tac[][]>>full_simp_tac(srw_ss())[] >>
    qpat_abbrev_tac`ll = IMAGE _ _` >>
    `lprefix_chain ll` by (
      unabbrev_all_tac >>
      Ho_Rewrite.ONCE_REWRITE_TAC[GSYM o_DEF] >>
      REWRITE_TAC[IMAGE_COMPOSE] >>
      match_mp_tac prefix_chain_lprefix_chain >>
      simp[prefix_chain_def,PULL_EXISTS] >>
      qx_genl_tac[`k1`,`k2`] >>
      qspecl_then[`k1`,`k2`]mp_tac LESS_EQ_CASES >>
      simp[LESS_EQ_EXISTS] >>
      metis_tac[
        dataPropsTheory.evaluate_add_clock_io_events_mono,
        dataPropsTheory.initial_state_with_simp,
        dataPropsTheory.initial_state_simp]) >>
    drule build_lprefix_lub_thm >>
    simp[lprefix_lub_def] >> strip_tac >>
    match_mp_tac (GEN_ALL LPREFIX_TRANS) >>
    simp[LPREFIX_fromList] >>
    QUANT_TAC[("l2",`fromList x`,[`x`])] >>
    simp[from_toList] >>
    asm_exists_tac >> simp[] >>
    first_x_assum irule >>
    simp[Abbr`ll`] >>
    qexists_tac`k`>>simp[] ) >>
  srw_tac[][extend_with_resource_limit_def] >>
  qmatch_abbrev_tac`build_lprefix_lub l1 = build_lprefix_lub l2` >>
  `(lprefix_chain l1 ∧ lprefix_chain l2) ∧ equiv_lprefix_chain l1 l2`
    suffices_by metis_tac[build_lprefix_lub_thm,lprefix_lub_new_chain,unique_lprefix_lub] >>
  conj_asm1_tac >- (
    UNABBREV_ALL_TAC >>
    conj_tac >>
    Ho_Rewrite.ONCE_REWRITE_TAC[GSYM o_DEF] >>
    REWRITE_TAC[IMAGE_COMPOSE] >>
    match_mp_tac prefix_chain_lprefix_chain >>
    simp[prefix_chain_def,PULL_EXISTS] >>
    qx_genl_tac[`k1`,`k2`] >>
    qspecl_then[`k1`,`k2`]mp_tac LESS_EQ_CASES >>
    simp[LESS_EQ_EXISTS] >>
    metis_tac[
      wordPropsTheory.evaluate_add_clock_io_events_mono,
      EVAL``((t:('a,'ffi) wordSem$state) with clock := k).clock``,
      EVAL``((t:('a,'ffi) wordSem$state) with clock := k) with clock := k2``,
      dataPropsTheory.evaluate_add_clock_io_events_mono,
      dataPropsTheory.initial_state_with_simp,
      dataPropsTheory.initial_state_simp]) >>
  simp[equiv_lprefix_chain_thm] >>
  unabbrev_all_tac >> simp[PULL_EXISTS] >>
  pop_assum kall_tac >>
  simp[LNTH_fromList,PULL_EXISTS] >>
  simp[GSYM FORALL_AND_THM] >>
  rpt gen_tac >>
  reverse conj_tac >> strip_tac >- (
    qmatch_assum_abbrev_tac`n < LENGTH (_ (_ (SND p)))` >>
    Cases_on`p`>>pop_assum(assume_tac o SYM o REWRITE_RULE[markerTheory.Abbrev_def]) >>
    drule compile_correct >>
    simp[GSYM AND_IMP_INTRO,RIGHT_FORALL_IMP_THM] >>
    impl_tac >- (
      last_x_assum(qspec_then`k`mp_tac)>>srw_tac[][]>>
      strip_tac >> full_simp_tac(srw_ss())[] ) >>
    drule(state_rel_ext_with_clock) >>
    simp[] >> strip_tac >>
    disch_then drule >>
    simp[comp_def] >> strip_tac >>
    qexists_tac`k+ck`>>full_simp_tac(srw_ss())[inc_clock_def]>>
    Cases_on`res1=SOME NotEnoughSpace`>>full_simp_tac(srw_ss())[]>-(
      first_x_assum(qspec_then`k+ck`mp_tac) >> simp[] >>
      CASE_TAC >> full_simp_tac(srw_ss())[] ) >>
    ntac 2 (pop_assum mp_tac) >>
    CASE_TAC >> full_simp_tac(srw_ss())[] >>
    TRY CASE_TAC >> full_simp_tac(srw_ss())[] >>
    TRY CASE_TAC >> full_simp_tac(srw_ss())[] >>
    strip_tac >> full_simp_tac(srw_ss())[] >>
    rveq >>
    rpt(first_x_assum(qspec_then`k+ck`mp_tac)>>simp[]) ) >>
    (fn g => subterm (fn tm => Cases_on`^(Term.subst [{redex = #1(dest_exists(#2 g)), residue = ``k:num``}] (assert(has_pair_type)tm))`) (#2 g) g) >>
  drule compile_correct >>
  simp[GSYM AND_IMP_INTRO,RIGHT_FORALL_IMP_THM] >>
  impl_tac >- (
    last_x_assum(qspec_then`k`mp_tac)>>srw_tac[][]>>
    strip_tac >> full_simp_tac(srw_ss())[] ) >>
  drule(state_rel_ext_with_clock) >>
  simp[] >> strip_tac >>
  disch_then drule >>
  simp[comp_def] >> strip_tac >>
  full_simp_tac(srw_ss())[inc_clock_def] >>
  Cases_on`res1=SOME NotEnoughSpace`>>full_simp_tac(srw_ss())[]>-(
    first_x_assum(qspec_then`k+ck`mp_tac) >> simp[] >>
    CASE_TAC >> full_simp_tac(srw_ss())[] ) >>
  qmatch_assum_abbrev_tac`n < LENGTH (SND (evaluate (exps,s))).ffi.io_events` >>
  Q.ISPECL_THEN[`exps`,`s`]mp_tac wordPropsTheory.evaluate_add_clock_io_events_mono >>
  disch_then(qspec_then`ck`mp_tac)>>simp[Abbr`s`]>>strip_tac>>
  qexists_tac`k`>>simp[]>>
  `r.ffi.io_events = t1.ffi.io_events` by (
    ntac 5 (pop_assum mp_tac) >>
    CASE_TAC >> full_simp_tac(srw_ss())[] >>
    every_case_tac >> full_simp_tac(srw_ss())[]>>srw_tac[][]>>
    rpt(first_x_assum(qspec_then`k+ck`mp_tac)>>simp[])) >>
  REV_FULL_SIMP_TAC(srw_ss()++ARITH_ss)[]>>
  fsrw_tac[ARITH_ss][IS_PREFIX_APPEND]>>
  simp[EL_APPEND1]);

fun define_abbrev name tm = let
  val vs = free_vars tm |> sort
    (fn v1 => fn v2 => fst (dest_var v1) <= fst (dest_var v2))
  val vars = foldr mk_pair (last vs) (butlast vs)
  val n = mk_var(name,mk_type("fun",[type_of vars, type_of tm]))
  in Define `^n ^vars = ^tm` end

val code_termdep_equiv = Q.prove(
  `t' with <|code := l; termdep := 0|> = t <=>
    ?x1 x2.
      t.code = l /\ t.termdep = 0 /\ t' = t with <|code := x1; termdep := x2|>`,
  fs [wordSemTheory.state_component_equality] \\ rw [] \\ eq_tac \\ rw [] \\ fs []);

val compile_semantics = save_thm("compile_semantics",let
  val th1 =
    compile_semantics_lemma |> Q.GEN `conf`
    |> SIMP_RULE std_ss [GSYM AND_IMP_INTRO,FORALL_PROD,PULL_EXISTS] |> SPEC_ALL
    |> REWRITE_RULE [state_rel_ext_def]
    |> ONCE_REWRITE_RULE [EQ_SYM_EQ]
    |> SIMP_RULE std_ss [GSYM AND_IMP_INTRO,
         FORALL_PROD,PULL_EXISTS] |> SPEC_ALL
    |> ONCE_REWRITE_RULE [EQ_SYM_EQ]
    |> REWRITE_RULE [ASSUME ``(t:('a,'ffi) wordSem$state).clock =
                              (t':('a,'ffi) wordSem$state).clock``]
    |> (fn th => MATCH_MP th (UNDISCH state_rel_init
            |> Q.INST [`l1`|->`1`,`l2`|->`0`,`code`|->`fromAList prog`,`t`|->`t'`]))
    |> CONV_RULE (RAND_CONV (ONCE_REWRITE_CONV [EQ_SYM_EQ]))
    |> SIMP_RULE std_ss [METIS_PROVE [] ``(!x. P x ==> Q) <=> ((?x. P x) ==> Q)``]
    |> DISCH ``(t':('a,'ffi) wordSem$state).code = code``
    |> SIMP_RULE std_ss [] |> UNDISCH |> UNDISCH
  val def = define_abbrev "code_rel_ext" (th1 |> concl |> dest_imp |> fst)
  in th1 |> REWRITE_RULE [GSYM def,code_termdep_equiv]
         |> SIMP_RULE std_ss [PULL_EXISTS,PULL_FORALL] |> SPEC_ALL
         |> DISCH_ALL |> GEN_ALL |> SIMP_RULE (srw_ss()) []
         |> Q.SPEC `2` |> SIMP_RULE std_ss []
         |> SPEC_ALL
         |> SIMP_RULE std_ss []
         |> UNDISCH
         |> REWRITE_RULE [AND_IMP_INTRO,GSYM CONJ_ASSOC] end);

val _ = (max_print_depth := 15);

val assign_def_extras = LIST_CONJ
  [LoadWord64_def,WriteWord64_def,BignumHalt_def,LoadBignum_def,
   AnyArith_code_def,Add_code_def,Sub_code_def,Mul_code_def,
   Div_code_def,Mod_code_def, Compare1_code_def, Compare_code_def,
   Equal1_code_def, Equal_code_def, LongDiv1_code_def, LongDiv_code_def,
   ShiftVar_def, generated_bignum_stubs_eq, DivCode_def,
   AddNumSize_def, AnyHeader_def, WriteWord64_on_32_def,
   WordOp64_on_32_def, WordShift64_on_32_def];

val extract_labels_def = wordPropsTheory.extract_labels_def;

val extract_labels_MemEqList = store_thm("extract_labels_MemEqList[simp]",
  ``!a x. extract_labels (MemEqList a x) = []``,
  Induct_on `x`
  \\ asm_rewrite_tac [MemEqList_def,extract_labels_def,APPEND]);

val data_to_word_lab_pres_lem = Q.prove(`
  ∀c n l p.
  l ≠ 0 ⇒
  let (cp,l') = comp c n l p in
  l ≤ l' ∧
  EVERY (λ(l1,l2). l1 = n ∧ l ≤ l2 ∧ l2 < l') (extract_labels cp) ∧
  ALL_DISTINCT (extract_labels cp)`,
  HO_MATCH_MP_TAC comp_ind>>Cases_on`p`>>rw[]>>
  once_rewrite_tac[comp_def]>>fs[extract_labels_def]
  >-
    (BasicProvers.EVERY_CASE_TAC>>fs[]>>rveq>>fs[extract_labels_def]>>
    rpt(pairarg_tac>>fs[])>>rveq>>fs[extract_labels_def]>>
    fs[EVERY_MEM,FORALL_PROD]>>rw[]>>
    res_tac>>fs[]>>
    CCONTR_TAC>>fs[]>>res_tac>>fs[])
  >-
    (fs[assign_def,assign_def_extras]>>
    Cases_on`o'`>>
    fs[extract_labels_def,GiveUp_def]>>
    BasicProvers.EVERY_CASE_TAC>>
    fs[extract_labels_def,list_Seq_def]>>
    qpat_abbrev_tac`A = 0w`>>
    qpat_abbrev_tac`ls = 3n::rest`>>
    rpt(pop_assum kall_tac)>>
    qid_spec_tac`A`>>Induct_on`ls`>>
    fs[StoreEach_def,extract_labels_def])
  >>
    (rpt (pairarg_tac>>fs[])>>rveq>>fs[extract_labels_def,EVERY_MEM,FORALL_PROD,ALL_DISTINCT_APPEND]>>
    rw[]>>
    res_tac>>fs[]>>
    CCONTR_TAC>>fs[]>>res_tac>>fs[]));

open match_goal

val labels_rel_emp = Q.prove(`
  labels_rel [] ls ⇒ ls = [] `,
  fs[word_simpProofTheory.labels_rel_def]);

val stub_labels = Q.prove(`
  EVERY (λ(n,m,p).
    EVERY (λ(l1,l2). l1 = n ∧ l2 ≠ 0) (extract_labels p)  ∧ ALL_DISTINCT (extract_labels p))
    (stubs (:'a) data_conf)`,
  simp[data_to_wordTheory.stubs_def,generated_bignum_stubs_eq]>>
  EVAL_TAC>>
  rw[]>>EVAL_TAC)

val data_to_word_compile_lab_pres = Q.store_thm("data_to_word_compile_lab_pres",`
  let (c,p) = compile data_conf word_conf asm_conf prog in
    MAP FST p = MAP FST (stubs(:α) data_conf) ++ MAP FST prog ∧
    EVERY (λn,m,(p:α wordLang$prog).
      let labs = extract_labels p in
      EVERY (λ(l1,l2).l1 = n ∧ l2 ≠ 0) labs ∧
      ALL_DISTINCT labs) p`,
  fs[data_to_wordTheory.compile_def]>>
  qpat_abbrev_tac`datap = _ ++ MAP (A B) prog`>>
  mp_tac (compile_to_word_conventions |>GEN_ALL |> Q.SPECL [`word_conf`,`datap`,`asm_conf`])>>
  rw[]>>
  pairarg_tac>>fs[Abbr`datap`]>>
  fs[EVERY_MEM]>>rw[]
  >-
    (match_mp_tac LIST_EQ>>rw[EL_MAP]>>
    Cases_on`EL x prog`>>Cases_on`r`>>fs[compile_part_def]) >>
  qmatch_assum_abbrev_tac`MAP FST p = MAP FST p1 ++ MAP FST p2`>>
  full_simp_tac std_ss [GSYM MAP_APPEND]>>
  qabbrev_tac`pp = p1 ++ p2` >>
  fs[EL_MAP,MEM_EL,FORALL_PROD]>>
  `EVERY (λ(n,m,p).
    EVERY (λ(l1,l2). l1 = n ∧ l2 ≠ 0) (extract_labels p)  ∧ ALL_DISTINCT (extract_labels p)) pp` by
    (unabbrev_all_tac>>fs[EVERY_MEM]>>CONJ_TAC
    >-
      (assume_tac stub_labels>>
      fs[EVERY_MEM])
    >>
      fs[MEM_MAP,MEM_EL,EXISTS_PROD]>>rw[]>>fs[compile_part_def]>>
      Q.SPECL_THEN [`data_conf`,`p_1`,`1n`,`p_2`]assume_tac data_to_word_lab_pres_lem>>
      fs[]>>pairarg_tac>>fs[EVERY_EL,PULL_EXISTS]>>
      rw[]>>res_tac>>
      pairarg_tac>>fs[])>>
  fs[LIST_REL_EL_EQN,EVERY_EL]>>
  rpt (first_x_assum(qspec_then`n` assume_tac))>>rfs[]>>
  rfs[EL_MAP]>>
  pairarg_tac>>fs[]>>
  pairarg_tac>>fs[]>>
  rw[] >>fs[word_simpProofTheory.labels_rel_def,SUBSET_DEF,MEM_EL,PULL_EXISTS]>>
  first_x_assum(qspec_then`n'''` assume_tac)>>rfs[]>>
  res_tac>>fs[]>>
  pairarg_tac>>fs[]>>
  qpat_x_assum`A=MAP FST pp` mp_tac>>simp[Once LIST_EQ_REWRITE,EL_MAP]>>
  disch_then(qspec_then`n` assume_tac)>>rfs[]);

val StoreEach_no_inst = Q.prove(`
  ∀a ls off.
  every_inst (inst_ok_less ac) (StoreEach a ls off)`,
  Induct_on`ls`>>rw[StoreEach_def,every_inst_def]);

val MemEqList_no_inst = Q.prove(`
  ∀a x.
  every_inst (inst_ok_less ac) (MemEqList a x)`,
  Induct_on `x` \\ fs [MemEqList_def,every_inst_def]);

val assign_no_inst = Q.prove(`
  ((a.has_longdiv ⇒ (ac.ISA = x86_64)) ∧
   (a.has_div ⇒ (ac.ISA ∈ {ARMv8; MIPS;RISC_V})) ∧
  addr_offset_ok ac 0w /\ byte_offset_ok ac 0w) ⇒
  every_inst (inst_ok_less ac) (FST(assign a b c d e f g))`,
  fs[assign_def]>>Cases_on`e`>>fs[every_inst_def]>>
  rw[]>>fs[every_inst_def,GiveUp_def]>>
  every_case_tac>>fs[every_inst_def,list_Seq_def,StoreEach_no_inst,
    inst_ok_less_def,assign_def_extras,MemEqList_no_inst]>>
  every_case_tac>>fs[every_inst_def,list_Seq_def,StoreEach_no_inst,
    inst_ok_less_def,assign_def_extras,MemEqList_no_inst]);

val comp_no_inst = Q.prove(`
  ∀c n m p.
  ((c.has_longdiv ⇒ (ac.ISA = x86_64)) ∧
   (c.has_div ⇒ (ac.ISA ∈ {ARMv8; MIPS;RISC_V})) ∧
  addr_offset_ok ac 0w /\ byte_offset_ok ac 0w) ⇒
  every_inst (inst_ok_less ac) (FST(comp c n m p))`,
  ho_match_mp_tac comp_ind>>Cases_on`p`>>rw[]>>
  simp[Once comp_def,every_inst_def]>>
  every_case_tac>>fs[]>>
  rpt(pairarg_tac>>fs[])>>
  fs[assign_no_inst]>>
  EVAL_TAC>>fs[]);

val data_to_word_compile_conventions = Q.store_thm("data_to_word_compile_conventions",`
  good_dimindex(:'a) ==>
  let (c,p) = compile data_conf wc ac prog in
  EVERY (λ(n,m,prog).
    flat_exp_conventions (prog:'a prog) ∧
    post_alloc_conventions (ac.reg_count - (5+LENGTH ac.avoid_regs)) prog ∧
    ((data_conf.has_longdiv ⇒ (ac.ISA = x86_64)) ∧
    (data_conf.has_div ⇒ (ac.ISA ∈ {ARMv8; MIPS;RISC_V})) ∧
    addr_offset_ok ac 0w /\
    byte_offset_ok ac 0w /\
    byte_offset_ok ac 1w /\
    byte_offset_ok ac 2w /\
    byte_offset_ok ac 3w /\
    (dimindex(:'a) <> 32 ==>
      byte_offset_ok ac 4w /\
      byte_offset_ok ac 5w /\
      byte_offset_ok ac 6w /\
      byte_offset_ok ac 7w )
    ⇒ full_inst_ok_less ac prog) ∧
    (ac.two_reg_arith ⇒ every_inst two_reg_inst prog)) p`,
 fs[data_to_wordTheory.compile_def]>>
 qpat_abbrev_tac`p= stubs(:'a) data_conf ++B`>>
 pairarg_tac>>fs[]>>
 Q.SPECL_THEN [`wc`,`p`,`ac`] mp_tac (GEN_ALL word_to_wordProofTheory.compile_to_word_conventions)>>
 rw[]>>fs[EVERY_MEM,LAMBDA_PROD,FORALL_PROD]>>rw[]>>
 res_tac>>fs[]>>
 first_assum match_mp_tac>>
 simp[Abbr`p`]>>rw[]
 >-
   (pop_assum mp_tac>>
   qpat_x_assum`data_conf.has_longdiv ⇒ P` mp_tac>>
   qpat_x_assum`data_conf.has_div⇒ P` mp_tac>>
   rpt(qpat_x_assum`byte_offset_ok _ _` mp_tac)>>
   qpat_x_assum`_ ==> byte_offset_ok _ _ /\ _` mp_tac>>
   qpat_x_assum`good_dimindex _` mp_tac>>
   rpt(pop_assum kall_tac)>>
   fs[stubs_def,generated_bignum_stubs_eq]>>rw[]>>
   EVAL_TAC>>rw[]>> TRY(pairarg_tac \\ fs[]) >> EVAL_TAC >> fs[] >>
   fs[good_dimindex_def] \\ fs[] \\ EVAL_TAC \\ fs[dimword_def] >>
   rpt(qhdtm_x_assum`offset_ok`mp_tac) >> EVAL_TAC \\ simp[] >>
   rpt(pairarg_tac \\ fs[]))
 >>
   fs[MEM_MAP]>>PairCases_on`y`>>fs[compile_part_def]>>
   match_mp_tac comp_no_inst>>fs[])

val _ = export_theory();
