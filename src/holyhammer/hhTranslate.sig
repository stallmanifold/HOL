signature hhTranslate =
sig

include Abbrev

  val must_pred : term -> bool
  val no_lambda : term -> bool
  val no_pred   : term -> bool
  val collect_arity : term -> (term, int list) Redblackmap.dict
  val has_fofarity_bv : term -> bool

  val prepare_tm    : term -> term

  (* conversions *)
  val ATOM_CONV     : conv -> conv
  val LIFT_CONV     : (int * int) ref -> conv
  val RPT_LIFT_CONV : (int * int) ref -> term -> thm list
  val LET_CONV_BVL  : conv

  (* arity equations *)
  val strip_type  : hol_type -> (hol_type list * hol_type)
  val mk_arity_eq : term -> int -> thm
  val all_arity_eq : term -> thm list

  (* translation *)
  val debug_translate_tm : int * term -> term list
  val translate_tm : term -> term list (* uses a cache *)

  (* problem *)
  val translate_pb  : (string * thm) list -> term ->
    term list * (string * term list) list * term list
  val name_pb :
    term list * (string * term list) list * term list ->
    (string * term) list * term

end
