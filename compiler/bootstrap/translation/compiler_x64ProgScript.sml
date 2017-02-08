open preamble
     x64ProgTheory
     configTheory
     ml_translatorLib
     ioProgLib

val () = new_theory "compiler_x64Prog";

val () = translation_extends "x64Prog";

(* TODO: move to inferencer (or update init_config?) *)
val prim_config_def = Define`
  prim_config = <|
    inf_decls := <|
        inf_defined_mods := [];
        inf_defined_types := [Short "option"; Short "list"; Short "bool"];
        inf_defined_exns := [Short "Subscript"; Short "Div"; Short "Chr"; Short "Bind"] |>;
    inf_env := init_env |>`;
(*
``env_rel prim_tenv prim_config.inf_env``
EVAL_TAC \\ rw[FEVERY_ALL_FLOOKUP]
\\ qexists_tac`[]` \\ EVAL_TAC

``prim_tdecs = convert_decls prim_config.inf_decls``
EVAL_TAC \\ rw[SUBSET_DEF]
*)

val res = translate inferTheory.init_env_def;

val res = translate prim_config_def;

(* TODO: x64_compiler_config should be called x64_backend_config, and should
         probably be defined elsewhere *)
val compiler_x64_def = Define`
  compiler_x64 = compile_to_bytes <| inferencer_config := prim_config; backend_config := x64_compiler_config |>`;

val res = translate
  (x64_compiler_config_def
   |> SIMP_RULE(srw_ss())[FUNION_FUPDATE_1])

val res = translate compiler_x64_def;

val res = append_main_call "compiler_x64" ``compiler_x64``;

val () = Feedback.set_trace "TheoryPP.include_docs" 0;

val () = export_theory();
