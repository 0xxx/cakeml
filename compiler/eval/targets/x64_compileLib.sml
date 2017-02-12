structure x64_compileLib =
struct

open HolKernel boolLib bossLib

val _ = ParseExtras.temp_loose_equality()

open x64_targetLib asmLib;
open x64AssemblerLib;
open compilerComputeLib;
open configTheory

(* open x64_targetTheory *)

val cmp = wordsLib.words_compset ()
val () = computeLib.extend_compset
    [computeLib.Extenders
      [compilerComputeLib.add_compiler_compset
      ,x64_targetLib.add_x64_encode_compset
      ,asmLib.add_asm_compset
      ],
     computeLib.Defs
      [configTheory.x64_compiler_config_def
      ,configTheory.x64_names_def]
    ] cmp

val eval = computeLib.CBV_CONV cmp

fun print_asm res =
  let val res = (rand o concl) res
      val bytes = hd(pairSyntax.strip_pair (optionSyntax.dest_some res))
      val dis = x64_disassemble_term bytes
      val maxlen = 30
      fun pad 0 = ()
      |   pad n = (print" ";pad (n-1))
      fun printAsm [] = ()
      |   printAsm (x::xs) = case x of (hex,dis) =>
          ( print hex
          ; pad (maxlen-String.size hex)
          ; print dis;print"\n"
          ; printAsm xs)
      in
        print"Bytes";pad (maxlen -5);print"Instruction\n";
        printAsm dis
      end

end
