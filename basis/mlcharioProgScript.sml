open preamble
     ml_translatorLib ml_progLib
     cfTheory cfHeapsTheory cfTacticsLib cfTacticsBaseLib basisFunctionsLib
     mlw8arrayProgTheory

val _ = new_theory "mlcharioProg";

val _ = translation_extends "mlw8arrayProg";

(* TODO: where should these be defined? *)

val Apps_def = tDefine "Apps" `
  (Apps [x;y] = App Opapp [x;y]) /\
  (Apps [] = ARB) /\
  (Apps xs = App Opapp [Apps (FRONT xs); LAST xs])`
  (WF_REL_TAC `measure LENGTH` \\ fs [LENGTH_FRONT]);

val LetApps_def = Define `
  LetApps n f args = Let (SOME n) (Apps (Var f::args))`;

(* -- *)

(* CharIO -- CF verified *)

val _ = ml_prog_update (open_module "CharIO");

(* TODO: does this occur more naturally somewhere else in the basis ? *)
val _ = trans "bool_of_byte" `\(w:word8). w <> 0w`
(* -- *)

val e = ``(App Aw8alloc [Lit (IntLit 2); Lit (Word8 0w)])``

val _ = ml_prog_update (add_Dlet (derive_eval_thm "read_state_loc" e) "read_state" [])

val e = ``(App Aw8alloc [Lit (IntLit 1); Lit (Word8 0w)])``

val _ = ml_prog_update (add_Dlet (derive_eval_thm "write_state_loc" e) "write_state" [])

val e =
  ``Let NONE (App (FFI "getChar") [Var (Short "read_state")])
     (LetApps "b" (Long "Word8Array" (Short "sub")) [Var (Short "read_state");  Lit (IntLit 0)]
       (LetApps "i" (Long "Word8" (Short "toInt")) [Var (Short "b")]
         (Apps [Var (Long "Char" (Short "chr")); Var (Short "i")])))``
  |> EVAL |> concl |> rand

val _ = ml_prog_update (add_Dlet_Fun ``"read"`` ``"u"`` e "read_v")

val e =
  ``LetApps "f" (Long "Word8Array" (Short "sub")) [Var (Short "read_state"); Lit (IntLit 1)]
      (Apps [Var (Short "bool_of_byte"); Var (Short "f")])``
  |> EVAL |> concl |> rand

val _ = ml_prog_update (add_Dlet_Fun ``"read_failed"`` ``"u"`` e "read_failed_v")

val e =
  ``Let (SOME "i") (Apps [Var (Long "Char" (Short "ord")); Var (Short "c")])
    (Let (SOME "b") (Apps [Var (Long "Word8" (Short "fromInt")); Var (Short "i")])
     (Let (SOME "u") (Apps [Var (Long "Word8Array" (Short "update"));
                          Var (Short "write_state");
                          Lit (IntLit 0); Var (Short "b")])
      (Let NONE (App (FFI "putChar") [Var (Short "write_state")]) (Var (Short "u")))))``
  |> EVAL |> concl |> rand

val _ = ml_prog_update (add_Dlet_Fun ``"write"`` ``"c"`` e "write_v")

val _ = ml_prog_update (close_module NONE);

val _ = monadsyntax.temp_add_monadsyntax();
val _ = temp_overload_on ("return", ``SOME``)
val _ = temp_overload_on ("fail", ``NONE``)
val _ = temp_overload_on ("SOME", ``SOME``)
val _ = temp_overload_on ("NONE", ``NONE``)
val _ = temp_overload_on ("monad_bind", ``OPTION_BIND``)
val _ = temp_overload_on ("monad_unitbind", ``OPTION_IGNORE_BIND``)
(*TODO: move these to a more sensible location *)

val ffi_putChar_def = Define`
  ffi_putChar bytes out =
    case(bytes, out) of
    | ([w], out) => SOME ([w], out ++ [CHR (w2n w)])
    | _ => NONE`

val stdout_fun_def = Define `
  stdout_fun i bytes s =
    if i = "putChar" then
      do
        out <- destStr s;
        (bytes, out) <- ffi_putChar bytes out;
        return (bytes, Str out)
      od
    else NONE`;

val ffi_getChar_def = Define`
  ffi_getChar bytes inp =
    case(bytes, inp) of
    | ([b;f], "") => SOME ([b; 1w], "")
    | ([b;f], h::t) => SOME ([n2w (ORD h); 0w], t)
    | _ => NONE`


val stdin_fun_def = Define `
  stdin_fun i bytes s =
    if i = "getChar" then
      do
        inp <- destStr s;
        (bytes, inp) <- ffi_getChar bytes inp;
        return (bytes, Str inp)
      od
    else NONE`;

val STDIN_def = Define `
  STDIN input read_failed =
    IO (Str input) stdin_fun ["getChar"] *
    SEP_EXISTS w. W8ARRAY read_state_loc [w;if read_failed then 1w else 0w]`;

val STDOUT_def = Define `
  STDOUT output =
    IO (Str output) stdout_fun ["putChar"] *
    SEP_EXISTS w. W8ARRAY write_state_loc [w]`;

val w2n_lt_256 =
  w2n_lt |> INST_TYPE [``:'a``|->``:8``]
         |> SIMP_RULE std_ss [EVAL ``dimword (:8)``]
         |> curry save_thm "w2n_lt_256"

val basis_st = get_ml_prog_state;

val read_spec = Q.store_thm ("read_spec",
  `UNIT_TYPE u uv ==>
     app (p:'ffi ffi_proj) ^(fetch_v "CharIO.read" (basis_st()))
       [uv]
       (STDIN input read_failed)
       (POSTv cv. if input = "" then STDIN input T else
                  cond (CHAR (HD input) cv) * STDIN (TL input) F)`,
  xcf "CharIO.read" (basis_st())
  \\ Cases_on`input = ""` \\ fs[]
  >- (
    fs[STDIN_def] \\ xpull
    \\ xlet `POSTv x. STDIN "" T * cond (UNIT_TYPE () x)`
    >- (
      xffi
      \\ fs[STDIN_def, EVAL ``read_state_loc``]
      \\ `MEM "getChar" ["getChar"]` by simp[] \\ instantiate \\ xsimpl
      \\ fs[stdin_fun_def, ffi_getChar_def] )
    \\ fs[STDIN_def] \\ xpull
    \\ xlet `POSTv x. STDIN "" T * cond (WORD (w:word8) x)`
    >- (
      xapp \\ xsimpl \\ fs[STDIN_def]
      \\ fs[EVAL``read_state_loc``] \\ xsimpl)
    \\ xlet `POSTv x. STDIN "" T * cond (NUM (w2n w) x)`
    >- ( xapp \\ xsimpl \\ fs[] \\ metis_tac[] )
    \\ rw[STDIN_def] \\ xpull
    \\ xapp \\ xsimpl \\ instantiate
    \\ simp[w2n_lt_256] )
  \\ fs[STDIN_def] \\ xpull
  \\ xlet `POSTv x. IO (Str (TL input)) stdin_fun ["getChar"] *
                    W8ARRAY read_state_loc [n2w (ORD (HD input)); 0w]`
  >- (
    xffi
    \\ fs[STDIN_def, EVAL ``read_state_loc``]
    \\ `MEM "getChar" ["getChar"]` by simp[] \\ instantiate \\ xsimpl
    \\ fs[stdin_fun_def, ffi_getChar_def] \\ Cases_on `input` \\ rw[])
  \\ xlet `POSTv x. STDIN (TL input) F * cond (WORD ((n2w(ORD(HD input))):word8) x)`
  >- (
    xapp \\ xsimpl \\ fs[STDIN_def]
    \\ fs[EVAL``read_state_loc``] \\ xsimpl)
  \\ xlet `POSTv x. STDIN (TL input) F * cond (NUM (ORD (HD input)) x)`
  >- (xapp \\ xsimpl \\ instantiate \\ simp[ORD_BOUND])
  \\ rw[STDIN_def] \\ xpull
  \\ xapp \\ xsimpl \\ instantiate
  \\ simp[CHR_ORD,ORD_BOUND])

val read_failed_spec = Q.store_thm("read_failed_spec",
  `UNIT_TYPE u uv ==>
    app (p:'ffi ffi_proj) ^(fetch_v "CharIO.read_failed" (basis_st()))
      [uv]
      (STDIN input read_failed)
      (POSTv bv. STDIN input read_failed * cond (BOOL read_failed bv))`,
  xcf "CharIO.read_failed" (basis_st())
  \\ fs[STDIN_def] \\ xpull
  \\ xlet `POSTv x. STDIN input read_failed * cond (WORD (if read_failed then 1w else (0w:word8)) x)`
  >- (
    xapp
    \\ fs[STDIN_def]
    \\ fs[EVAL``read_state_loc``]
    \\ xsimpl)
  \\ fs[STDIN_def] \\ xpull
  \\ xapp
  \\ instantiate
  \\ xsimpl
  \\ rw[]);

val write_spec = Q.store_thm ("write_spec",
  `CHAR c cv ==>
     app (p:'ffi ffi_proj) ^(fetch_v "CharIO.write" (basis_st()))
       [cv]
       (STDOUT output)
       (POSTv uv. cond (UNIT_TYPE () uv) * STDOUT (output ++ [c]))`,
  xcf "CharIO.write" (basis_st())
  \\ fs [STDOUT_def] \\ xpull
  \\ xlet `POSTv zv. IO (Str output) stdout_fun ["putChar"] * W8ARRAY write_state_loc [w] *
                     & (NUM (ORD c) zv)`
  >- (xapp \\ xsimpl \\ metis_tac[])
  \\ xlet `POSTv zv. IO (Str output) stdout_fun ["putChar"] * W8ARRAY write_state_loc [w] *
                     & (WORD ((n2w (ORD c)):word8) zv)`
  >- (xapp \\ xsimpl \\ metis_tac[])
  \\ xlet `POSTv zv. IO (Str output) stdout_fun ["putChar"] * W8ARRAY write_state_loc [n2w (ORD c)] *
                     & UNIT_TYPE () zv`
  THEN1
   (xapp \\ xsimpl \\ fs [EVAL ``write_state_loc``]
    \\ instantiate \\ xsimpl \\ EVAL_TAC)
  \\ xlet `POSTv _. IO (Str (output ++ [c])) stdout_fun ["putChar"] * W8ARRAY write_state_loc [n2w (ORD c)]`
  THEN1
   (xffi
    \\ fs [EVAL ``write_state_loc``, STDOUT_def]
    \\ `MEM "putChar" ["putChar"]` by simp[] \\ instantiate \\ xsimpl \\ EVAL_TAC
    \\ simp[ORD_BOUND,CHR_ORD])
  \\ xret \\ xsimpl);

val _ = export_theory()
