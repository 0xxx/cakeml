structure std_preludeLib =
struct

open HolKernel Parse boolLib bossLib;

open arithmeticTheory listTheory combinTheory pairTheory sumTheory;
open optionTheory oneTheory bitTheory stringTheory whileTheory;
open finite_mapTheory pred_setTheory;
open astTheory libTheory bigStepTheory semanticPrimitivesTheory;
open terminationTheory alistTheory;

open ml_translatorLib ml_translatorTheory mini_preludeTheory;

fun std_prelude () = let

val _ = mini_preludeLib.mini_prelude ();

(* pair *)

val res = translate FST;
val res = translate SND;
val res = translate CURRY_DEF;
val res = translate UNCURRY;

(* combin *)

val res = translate o_DEF;
val res = translate I_THM;
val res = translate C_DEF;
val res = translate K_DEF;
val res = translate S_DEF;
val res = translate UPDATE_def;
val res = translate W_DEF;

(* option *)

val res = translate THE_DEF;
val res = translate IS_NONE_DEF;
val res = translate IS_SOME_DEF;
val res = translate OPTION_MAP_DEF;
val res = translate OPTION_MAP2_DEF;

val the_side_def = prove(
  ``the_side = IS_SOME``,
  FULL_SIMP_TAC std_ss [FUN_EQ_THM] THEN Cases
  THEN FULL_SIMP_TAC (srw_ss()) [fetch "-" "the_side_def"])
  |> update_precondition;

val option_map2_side_def = prove(
  ``!f x y. option_map2_side f x y = T``,
  FULL_SIMP_TAC (srw_ss()) [fetch "-" "option_map2_side_def",the_side_def])
  |> update_precondition;

(* sum *)

val res = translate ISL;
val res = translate ISR;
val res = translate OUTL;
val res = translate OUTR;
val res = translate SUM_MAP_def;

val outl_side_def = prove(
  ``outl_side = ISL``,
  FULL_SIMP_TAC std_ss [FUN_EQ_THM] THEN Cases
  THEN FULL_SIMP_TAC (srw_ss()) [fetch "-" "outl_side_def"])
  |> update_precondition;

val outr_side_def = prove(
  ``outr_side = ISR``,
  FULL_SIMP_TAC std_ss [FUN_EQ_THM] THEN Cases
  THEN FULL_SIMP_TAC (srw_ss()) [fetch "-" "outr_side_def"])
  |> update_precondition;

(* list *)

val LENGTH_AUX_def = Define `
  (LENGTH_AUX [] n = (n:num)) /\
  (LENGTH_AUX (x::xs) n = LENGTH_AUX xs (n+1))`;

val LENGTH_AUX_THM = prove(
  ``!xs n. LENGTH_AUX xs n = LENGTH xs + n``,
  Induct THEN ASM_SIMP_TAC std_ss [LENGTH_AUX_def,LENGTH,ADD1,AC ADD_COMM ADD_ASSOC])
  |> Q.SPECL [`xs`,`0`] |> GSYM |> SIMP_RULE std_ss [];

val SUC_LEMMA = prove(``SUC = \x. x+1``,SIMP_TAC std_ss [FUN_EQ_THM,ADD1]);

val res = translate LENGTH_AUX_def;
val res = translate LENGTH_AUX_THM;
val res = translate MAP;
val res = translate FILTER;
val res = translate FOLDR;
val res = translate FOLDL;
val res = translate SUM;
val res = translate UNZIP;
val res = translate FLAT;
val res = translate TAKE_def;
val res = translate DROP_def;
val res = translate SNOC;
val res = translate EVERY_DEF;
val res = translate EXISTS_DEF;
val res = translate GENLIST;
val res = translate PAD_RIGHT;
val res = translate PAD_LEFT;
val res = translate MEMBER_def;
val res = translate (ALL_DISTINCT |> REWRITE_RULE [MEMBER_INTRO]);
val res = translate isPREFIX;
val res = translate FRONT_DEF;
val res = translate ZIP;
val res = translate EL;
val res = translate LAST_DEF;
val res = translate (splitAtPki_DEF |> REWRITE_RULE [SUC_LEMMA])

val front_side_def = prove(
  ``!xs. front_side xs = ~(xs = [])``,
  Induct THEN ONCE_REWRITE_TAC [fetch "-" "front_side_def"]
  THEN FULL_SIMP_TAC (srw_ss()) [CONTAINER_def])
  |> update_precondition;

val zip_side_def = prove(
  ``!x. zip_side x = (LENGTH (FST x) = LENGTH (SND x))``,
  Cases THEN Q.SPEC_TAC (`r`,`r`) THEN Induct_on `q` THEN Cases_on `r`
  THEN ONCE_REWRITE_TAC [fetch "-" "zip_side_def"]
  THEN FULL_SIMP_TAC (srw_ss()) [])
  |> update_precondition;

val el_side_def = prove(
  ``!n xs. el_side n xs = (n < LENGTH xs)``,
  Induct THEN Cases_on `xs` THEN ONCE_REWRITE_TAC [fetch "-" "el_side_def"]
  THEN FULL_SIMP_TAC (srw_ss()) [CONTAINER_def])
  |> update_precondition;

val last_side_def = prove(
  ``!xs. last_side xs = ~(xs = [])``,
  Induct THEN ONCE_REWRITE_TAC [fetch "-" "last_side_def"]
  THEN FULL_SIMP_TAC (srw_ss()) [CONTAINER_def])
  |> update_precondition;

(* sorting *)

val res = translate sortingTheory.PART_DEF;
val res = translate sortingTheory.PARTITION_DEF;
val res = translate sortingTheory.QSORT_DEF;

(* arithmetic *)

val EXP_AUX_def = Define `
  EXP_AUX m n k = if n = 0 then k else EXP_AUX m (n-1:num) (m * k:num)`;

val EXP_AUX_THM = prove(
  ``!n k. EXP_AUX m n (m**k) = m**(k+n)``,
  Induct THEN SIMP_TAC std_ss [EXP,Once EXP_AUX_def,ADD1]
  THEN ASM_SIMP_TAC std_ss [GSYM EXP]
  THEN FULL_SIMP_TAC std_ss [ADD1,AC ADD_COMM ADD_ASSOC])
  |> Q.SPECL [`n`,`0`] |> SIMP_RULE std_ss [EXP] |> GSYM;

val res = translate EXP_AUX_def;
val res = translate EXP_AUX_THM; (* tailrec version of EXP *)
val res = translate MIN_DEF;
val res = translate MAX_DEF;
val res = translate EVEN_MOD2;
val res = translate (REWRITE_RULE [EVEN_MOD2,DECIDE ``~(n = 0) = (0 < n:num)``] ODD_EVEN);
val res = translate FUNPOW;
val res = translate ABS_DIFF_def;
val res = translate (DECIDE ``PRE n = n-1``);

(* string *)

val res = translate string_lt_def;
val res = translate string_le_def;
val res = translate string_gt_def;
val res = translate string_ge_def;

(* number to string conversion *)

val num_to_dec_def = Define `
  num_to_dec n =
    if n < 10 then [CHR (48 + n)] else
      CHR (48 + (n MOD 10))::num_to_dec (n DIV 10)`;

val _ = translate num_to_dec_def;

val num_to_dec_side_def = prove(
  ``!n. num_to_dec_side n = T``,
  HO_MATCH_MP_TAC (fetch "-" "num_to_dec_ind") THEN REPEAT STRIP_TAC
  THEN SIMP_TAC std_ss []
  THEN ONCE_REWRITE_TAC [fetch "-" "num_to_dec_side_def"]
  THEN FULL_SIMP_TAC std_ss [] THEN REPEAT STRIP_TAC
  THEN `n MOD 10 < 10` by FULL_SIMP_TAC std_ss []
  THEN DECIDE_TAC) |> SPEC_ALL
  |> update_precondition;

val toString_thm = prove(
  ``toString n = REVERSE (num_to_dec n)``,
  SIMP_TAC std_ss [ASCIInumbersTheory.num_to_dec_string_def,
    ASCIInumbersTheory.n2s_def]
  THEN AP_TERM_TAC THEN Q.SPEC_TAC (`n`,`n`)
  THEN HO_MATCH_MP_TAC (fetch "-" "num_to_dec_ind") THEN REPEAT STRIP_TAC
  THEN SIMP_TAC std_ss [Once numposrepTheory.n2l_def,Once num_to_dec_def]
  THEN Cases_on `n < 10` THEN FULL_SIMP_TAC std_ss [] THEN1
   (NTAC 5 (TRY (Cases_on `n`) THEN EVAL_TAC THEN TRY (Cases_on `n'`) THEN EVAL_TAC)
    THEN `F` by DECIDE_TAC)
  THEN ASM_SIMP_TAC std_ss [MAP,CONS_11]
  THEN `n MOD 10 < 10` by FULL_SIMP_TAC std_ss [MOD_LESS]
  THEN Cases_on `n MOD 10`
  THEN NTAC 5 (TRY (Cases_on `n`) THEN EVAL_TAC THEN
               TRY (Cases_on `n'`) THEN EVAL_TAC)
  THEN `F` by DECIDE_TAC);

val _ = translate toString_thm;

(* finite maps *)

val FMAP_EQ_ALIST_def = Define `
  FMAP_EQ_ALIST f l <=> (ALOOKUP l = FLOOKUP f)`;

val FMAP_TYPE_def = Define `
  FMAP_TYPE (a:'a -> v -> bool) (b:'b -> v -> bool) (f:'a|->'b) =
    \v. ?l. LIST_TYPE (PAIR_TYPE a b) l v /\ FMAP_EQ_ALIST f l`;

val _ = add_type_inv ``FMAP_TYPE (a:'a -> v -> bool) (b:'b -> v -> bool)``
                     ``:('a # 'b) list``;

val ALOOKUP_eval = translate ALOOKUP_def;

val Eval_FLOOKUP = prove(
  ``!v. ((LIST_TYPE (PAIR_TYPE (b:'b -> v -> bool) (a:'a -> v -> bool)) -->
          b --> OPTION_TYPE a) ALOOKUP) v ==>
        ((FMAP_TYPE b a --> b --> OPTION_TYPE a) FLOOKUP) v``,
  SIMP_TAC (srw_ss()) [Arrow_def,AppReturns_def,FMAP_TYPE_def,
    PULL_EXISTS,FMAP_EQ_ALIST_def] THEN METIS_TAC [])
  |> MATCH_MP (MATCH_MP Eval_WEAKEN ALOOKUP_eval)
  |> store_eval_thm;

val AUPDATE_def = Define `AUPDATE l (x:'a,y:'b) = (x,y)::l`;
val AUPDATE_eval = translate AUPDATE_def;

val FMAP_EQ_ALIST_UPDATE = prove(
  ``FMAP_EQ_ALIST f l ==> FMAP_EQ_ALIST (FUPDATE f (x,y)) (AUPDATE l (x,y))``,
  SIMP_TAC (srw_ss()) [FMAP_EQ_ALIST_def,AUPDATE_def,ALOOKUP_def,FUN_EQ_THM,
    finite_mapTheory.FLOOKUP_DEF,finite_mapTheory.FAPPLY_FUPDATE_THM]
  THEN METIS_TAC []);

val Eval_FUPDATE = prove(
  ``!v. ((LIST_TYPE (PAIR_TYPE a b) -->
          PAIR_TYPE (a:'a -> v -> bool) (b:'b -> v -> bool) -->
          LIST_TYPE (PAIR_TYPE a b)) AUPDATE) v ==>
        ((FMAP_TYPE a b --> PAIR_TYPE a b --> FMAP_TYPE a b) FUPDATE) v``,
  SIMP_TAC (srw_ss()) [Arrow_def,AppReturns_def,FMAP_TYPE_def,
    PULL_EXISTS] THEN REPEAT STRIP_TAC THEN RES_TAC
  THEN Q.EXISTS_TAC `u` THEN FULL_SIMP_TAC std_ss []
  THEN REPEAT STRIP_TAC THEN RES_TAC
  THEN Q.LIST_EXISTS_TAC [`u'`,`AUPDATE l x'`]
  THEN FULL_SIMP_TAC std_ss [] THEN METIS_TAC [FMAP_EQ_ALIST_UPDATE,PAIR])
  |> MATCH_MP (MATCH_MP Eval_WEAKEN AUPDATE_eval)
  |> store_eval_thm;

val NIL_eval = hol2deep ``[]:('a # 'b) list``

val Eval_FEMPTY = prove(
  ``!v. (LIST_TYPE (PAIR_TYPE (a:'a -> v -> bool) (b:'b -> v -> bool)) []) v ==>
        ((FMAP_TYPE a b) FEMPTY) v``,
  SIMP_TAC (srw_ss()) [Arrow_def,AppReturns_def,FMAP_TYPE_def,
    PULL_EXISTS,FMAP_EQ_ALIST_def] THEN REPEAT STRIP_TAC THEN Q.EXISTS_TAC `[]`
  THEN FULL_SIMP_TAC (srw_ss()) [ALOOKUP_def,FUN_EQ_THM,
         finite_mapTheory.FLOOKUP_DEF])
  |> MATCH_MP (MATCH_MP Eval_WEAKEN NIL_eval)
  |> store_eval_thm;

val AEVERY_AUX_def = Define `
  (AEVERY_AUX aux P [] = T) /\
  (AEVERY_AUX aux P ((x:'a,y:'b)::xs) =
     if MEMBER x aux then AEVERY_AUX aux P xs else
       P (x,y) /\ AEVERY_AUX (x::aux) P xs)`;
val AEVERY_def = Define `AEVERY = AEVERY_AUX []`;
val _ = translate AEVERY_AUX_def;
val AEVERY_eval = translate AEVERY_def;

val AEVERY_AUX_THM = prove(
  ``!l aux P. AEVERY_AUX aux P l <=>
              !x y. (ALOOKUP l x = SOME y) /\ ~(MEM x aux) ==> P (x,y)``,
  Induct
  THEN FULL_SIMP_TAC std_ss [ALOOKUP_def,AEVERY_AUX_def,FORALL_PROD,
    MEM,GSYM MEMBER_INTRO] THEN REPEAT STRIP_TAC
  THEN SRW_TAC [] [] THEN METIS_TAC [SOME_11]);

val AEVERY_THM = prove(
  ``AEVERY P l <=> !x y. (ALOOKUP l x = SOME y) ==> P (x,y)``,
  SIMP_TAC (srw_ss()) [AEVERY_def,AEVERY_AUX_THM]);

val AEVERY_EQ_FEVERY = prove(
  ``FMAP_EQ_ALIST f l ==> (AEVERY P l <=> FEVERY P f)``,
  FULL_SIMP_TAC std_ss [FMAP_EQ_ALIST_def,FEVERY_DEF,AEVERY_THM]
  THEN FULL_SIMP_TAC std_ss [FLOOKUP_DEF]);

val Eval_FEVERY = prove(
  ``!v. (((PAIR_TYPE (a:'a->v->bool) (b:'b->v->bool) --> BOOL) -->
         LIST_TYPE (PAIR_TYPE a b) --> BOOL) AEVERY) v ==>
        (((PAIR_TYPE (a:'a->v->bool) (b:'b->v->bool) --> BOOL) -->
         FMAP_TYPE a b --> BOOL) FEVERY) v``,
  SIMP_TAC (srw_ss()) [Arrow_def,AppReturns_def,FMAP_TYPE_def,
    PULL_EXISTS] THEN REPEAT STRIP_TAC
  THEN RES_TAC THEN Q.EXISTS_TAC `u` THEN FULL_SIMP_TAC std_ss []
  THEN REPEAT STRIP_TAC THEN RES_TAC
  THEN Q.MATCH_ASSUM_RENAME_TAC `BOOL (AEVERY x l) u1`
  THEN Q.LIST_EXISTS_TAC [`u1`]
  THEN FULL_SIMP_TAC (srw_ss()) [BOOL_def,AEVERY_EQ_FEVERY])
  |> MATCH_MP (MATCH_MP Eval_WEAKEN AEVERY_eval)
  |> store_eval_thm;

val AMAP_def = Define `
  (AMAP f [] = []) /\
  (AMAP f ((x:'a,y:'b)::xs) = (x,(f y):'c) :: AMAP f xs)`;
val AMAP_eval = translate AMAP_def;

val ALOOKUP_AMAP = prove(
  ``!l. ALOOKUP (AMAP f l) a =
        case ALOOKUP l a of NONE => NONE | SOME x => SOME (f x)``,
  Induct THEN SIMP_TAC std_ss [AMAP_def,ALOOKUP_def,FORALL_PROD]
  THEN SRW_TAC [] []);

val FMAP_EQ_ALIST_o_f = prove(
  ``FMAP_EQ_ALIST m l ==> FMAP_EQ_ALIST (x o_f m) (AMAP x l)``,
  SIMP_TAC std_ss [FMAP_EQ_ALIST_def,FUN_EQ_THM,FLOOKUP_DEF,
    o_f_DEF,ALOOKUP_AMAP] THEN REPEAT STRIP_TAC THEN SRW_TAC [] []);

val Eval_o_f = prove(
  ``!v. (((b --> c) --> LIST_TYPE (PAIR_TYPE (a:'a->v->bool) (b:'b->v->bool)) -->
          LIST_TYPE (PAIR_TYPE a (c:'c->v->bool))) AMAP) v ==>
        (((b --> c) --> FMAP_TYPE a b --> FMAP_TYPE a c) $o_f) v``,
  SIMP_TAC (srw_ss()) [Arrow_def,AppReturns_def,FMAP_TYPE_def,
    PULL_EXISTS] THEN REPEAT STRIP_TAC
  THEN RES_TAC THEN Q.EXISTS_TAC `u` THEN FULL_SIMP_TAC std_ss []
  THEN REPEAT STRIP_TAC THEN RES_TAC
  THEN Q.MATCH_ASSUM_RENAME_TAC `LIST_TYPE (PAIR_TYPE a c) (AMAP x l) u1`
  THEN Q.LIST_EXISTS_TAC [`u1`,`AMAP x l`]
  THEN FULL_SIMP_TAC std_ss [FMAP_EQ_ALIST_o_f])
  |> MATCH_MP (MATCH_MP Eval_WEAKEN AMAP_eval)
  |> store_eval_thm;

val ALOOKUP_APPEND = prove(
  ``!l1 l2 x.
      ALOOKUP (l1 ++ l2) x =
      case ALOOKUP l1 x of NONE => ALOOKUP l2 x
                         | SOME y => SOME y``,
  Induct THEN FULL_SIMP_TAC std_ss [APPEND,ALOOKUP_def,FORALL_PROD]
  THEN SRW_TAC [] []);

val APPEND_eval = ``x ++ (y:('a # 'b) list)``
  |> repeat rator |> hol2deep
  |> DISCH_ALL |> Q.INST [`shaddow_env`|->`env`]
  |> REWRITE_RULE [] |> UNDISCH_ALL

val Eval_FUNION = prove(
  ``!v. (LIST_TYPE (PAIR_TYPE a b) --> LIST_TYPE (PAIR_TYPE a b) -->
         LIST_TYPE (PAIR_TYPE a b)) APPEND v ==>
        (FMAP_TYPE a b --> FMAP_TYPE a b --> FMAP_TYPE a b) $FUNION v``,
  SIMP_TAC (srw_ss()) [Arrow_def,AppReturns_def,FMAP_TYPE_def,
    PULL_EXISTS,FMAP_EQ_ALIST_def]
  THEN REPEAT STRIP_TAC
  THEN RES_TAC THEN Q.EXISTS_TAC `u` THEN FULL_SIMP_TAC std_ss []
  THEN Q.MATCH_ASSUM_RENAME_TAC `LIST_TYPE (PAIR_TYPE a b) l1 v1`
  THEN REPEAT STRIP_TAC
  THEN Q.MATCH_ASSUM_RENAME_TAC `LIST_TYPE (PAIR_TYPE a b) l2 v2`
  THEN Q.PAT_ASSUM `!x v. bbb` (MP_TAC o Q.SPECL [`l2`,`v2`])
  THEN FULL_SIMP_TAC std_ss [] THEN STRIP_TAC
  THEN Q.LIST_EXISTS_TAC [`u'`,`l1 ++ l2`]
  THEN FULL_SIMP_TAC std_ss []
  THEN FULL_SIMP_TAC std_ss [ALOOKUP_APPEND,FUN_EQ_THM]
  THEN FULL_SIMP_TAC std_ss [FLOOKUP_DEF,FUNION_DEF,IN_UNION]
  THEN REPEAT STRIP_TAC THEN SRW_TAC [] [] THEN FULL_SIMP_TAC std_ss [])
  |> MATCH_MP (MATCH_MP Eval_WEAKEN APPEND_eval)
  |> store_eval_thm;

val ADEL_def = Define `
  (ADEL [] z = []) /\
  (ADEL ((x:'a,y:'b)::xs) z = if x = z then ADEL xs z else (x,y)::ADEL xs z)`
val ADEL_eval = translate ADEL_def;

val ALOOKUP_ADEL = prove(
  ``!l a x. ALOOKUP (ADEL l a) x = if x = a then NONE else ALOOKUP l x``,
  Induct THEN SRW_TAC [] [ALOOKUP_def,ADEL_def] THEN Cases_on `h`
  THEN SRW_TAC [] [ALOOKUP_def,ADEL_def]);

val FMAP_EQ_ALIST_ADEL = prove(
  ``!x l. FMAP_EQ_ALIST x l ==>
          FMAP_EQ_ALIST (x \\ a) (ADEL l a)``,
  FULL_SIMP_TAC std_ss [FMAP_EQ_ALIST_def,ALOOKUP_def,fmap_domsub,FUN_EQ_THM]
  THEN REPEAT STRIP_TAC THEN SRW_TAC [] [ALOOKUP_ADEL,FLOOKUP_DEF,DRESTRICT_DEF]
  THEN FULL_SIMP_TAC std_ss []);

val Eval_fmap_domsub = prove(
  ``!v. ((LIST_TYPE (PAIR_TYPE a b) --> a -->
          LIST_TYPE (PAIR_TYPE a b)) ADEL) v ==>
        ((FMAP_TYPE a b --> a --> FMAP_TYPE a b) $\\) v``,
  SIMP_TAC (srw_ss()) [Arrow_def,AppReturns_def,FMAP_TYPE_def,
    PULL_EXISTS] THEN REPEAT STRIP_TAC THEN RES_TAC
  THEN Q.EXISTS_TAC `u` THEN FULL_SIMP_TAC std_ss []
  THEN REPEAT STRIP_TAC THEN RES_TAC
  THEN Q.LIST_EXISTS_TAC [`u'`,`ADEL l x'`]
  THEN FULL_SIMP_TAC std_ss [FMAP_EQ_ALIST_ADEL])
  |> MATCH_MP (MATCH_MP Eval_WEAKEN ADEL_eval)
  |> store_eval_thm;


(* while, owhile and least *)

val _ = add_preferred_thy "-";

val IS_SOME_OWHILE_THM = prove(
  ``!g f x. (IS_SOME (OWHILE g f x)) =
            ?n. ~ g (FUNPOW f n x) /\ !m. m < n ==> g (FUNPOW f m x)``,
  REPEAT STRIP_TAC THEN Cases_on `OWHILE g f x`
  THEN FULL_SIMP_TAC (srw_ss()) [OWHILE_EQ_NONE]
  THEN FULL_SIMP_TAC std_ss [OWHILE_def]
  THEN Q.EXISTS_TAC `LEAST n. ~g (FUNPOW f n x)`
  THEN (Q.INST [`P`|->`\n. ~g (FUNPOW f n x)`] FULL_LEAST_INTRO
      |> SIMP_RULE std_ss [] |> IMP_RES_TAC)
  THEN ASM_SIMP_TAC std_ss [] THEN REPEAT STRIP_TAC
  THEN IMP_RES_TAC LESS_LEAST THEN FULL_SIMP_TAC std_ss []);

val WHILE_ind = store_thm("WHILE_ind",
  ``!P. (!p g x. (p x ==> P p g (g x)) ==> P p g x) ==>
        !p g x. IS_SOME (OWHILE p g x) ==> P p g x``,
  SIMP_TAC std_ss [IS_SOME_OWHILE_THM,PULL_EXISTS,PULL_FORALL]
  THEN Induct_on `n` THEN SRW_TAC [] []
  THEN FIRST_ASSUM MATCH_MP_TAC
  THEN SRW_TAC [] [] THEN FULL_SIMP_TAC std_ss [AND_IMP_INTRO]
  THEN Q.PAT_ASSUM `!x1 x2 x3 x4. bbb` MATCH_MP_TAC
  THEN SRW_TAC [] [] THEN FULL_SIMP_TAC std_ss [FUNPOW]
  THEN `SUC m < SUC n` by DECIDE_TAC
  THEN METIS_TAC [FUNPOW]);

val OWHILE_ind = save_thm("OWHILE_ind",WHILE_ind);

val _ = translate WHILE;
val _ = translate OWHILE_THM;

val LEAST_LEMMA = prove(
  ``$LEAST P = WHILE (\x. ~(P x)) (\x. x + 1) 0``,
  SIMP_TAC std_ss [LEAST_DEF,o_DEF,SUC_LEMMA]);

val res = translate LEAST_LEMMA;

val FUNPOW_LEMMA = prove(
  ``!n m. FUNPOW (\x. x + 1) n m = n + m``,
  Induct THEN FULL_SIMP_TAC std_ss [FUNPOW,ADD1,AC ADD_COMM ADD_ASSOC]);

val least_side_thm = prove(
  ``!s. least_side s = ~(s = {})``,
  SIMP_TAC std_ss [fetch "-" "least_side_def"]
  THEN FULL_SIMP_TAC std_ss [OWHILE_def,FUNPOW_LEMMA,FUN_EQ_THM,EMPTY_DEF]
  THEN METIS_TAC [IS_SOME_DEF])
  |> update_precondition;

in () end;

end
