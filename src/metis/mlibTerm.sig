(* ========================================================================= *)
(* BASIC FIRST-ORDER LOGIC MANIPULATIONS                                     *)
(* Created by Joe Hurd, September 2001                                       *)
(* Partly ported from the CAML-Light code accompanying John Harrison's book  *)
(* ========================================================================= *)

signature mlibTerm =
sig

type 'a pp           = 'a mlibUseful.pp
type ('a, 'b) maplet = ('a, 'b) mlibUseful.maplet
type 'a quotation    = 'a mlibParser.quotation
type infixities      = mlibParser.infixities

(* Datatypes for terms and formulas *)
datatype term =
  Var of string
| Fn  of string * term list

datatype formula =
  True
| False
| Atom   of term
| Not    of formula
| And    of formula * formula
| Or     of formula * formula
| Imp    of formula * formula
| Iff    of formula * formula
| Forall of string * formula
| Exists of string * formula

(* A datatype to antiquote both terms and formulas *)
datatype thing = Term of term | Formula of formula;

(* Operators parsed as infix *)
val infixes : infixities ref

(* Contructors and destructors *)
val dest_var        : term -> string
val is_var          : term -> bool

val dest_fn         : term -> string * term list
val is_fn           : term -> bool
val fn_name         : term -> string
val fn_args         : term -> term list
val fn_arity        : term -> int
val fn_function     : term -> string * int

val mk_const        : string -> term
val dest_const      : term -> string
val is_const        : term -> bool

val mk_binop        : string -> term * term -> term
val dest_binop      : string -> term -> term * term
val is_binop        : string -> term -> bool

val dest_atom       : formula -> term
val is_atom         : formula -> bool

val list_mk_conj    : formula list -> formula
val strip_conj      : formula -> formula list
val flatten_conj    : formula -> formula list

val list_mk_disj    : formula list -> formula
val strip_disj      : formula -> formula list
val flatten_disj    : formula -> formula list

val list_mk_forall  : string list * formula -> formula
val strip_forall    : formula -> string list * formula

val list_mk_exists  : string list * formula -> formula
val strip_exists    : formula -> string list * formula

(* Deciding whether a string denotes a variable or constant *)
val var_string : string -> bool

(* Pretty-printing *)
val pp_term'           : infixities -> term pp         (* purely functional *)
val pp_formula'        : infixities -> formula pp
val term_to_string'    : infixities -> int -> term -> string
val formula_to_string' : infixities -> int -> formula -> string
val pp_term            : term pp                       (* using !infixes   *)
val pp_formula         : formula pp                    (* and !LINE_LENGTH *)
val term_to_string     : term -> string
val formula_to_string  : formula -> string

(* Parsing *)
val string_to_term'    : infixities -> string -> term  (* purely functional *)
val string_to_formula' : infixities -> string -> formula
val parse_term'        : infixities -> thing quotation -> term
val parse_formula'     : infixities -> thing quotation -> formula
val string_to_term     : string -> term                (* using !infixes *)
val string_to_formula  : string -> formula
val parse_term         : thing quotation -> term
val parse_formula      : thing quotation -> formula

(* Basic operations on terms and formulas *)
val new_var      : unit -> term
val new_vars     : int -> term list
val term_size    : term -> int
val formula_size : formula -> int

(* Operations on literals *)
val mk_literal   : bool * formula -> formula
val dest_literal : formula -> bool * formula
val is_literal   : formula -> bool
val literal_atom : formula -> formula

(* Operations on formula negations *)
val negative : formula -> bool
val positive : formula -> bool
val negate   : formula -> formula

(* Functions and relations in a formula *)
val functions      : formula -> (string * int) list
val function_names : formula -> string list
val relations      : formula -> (string * int) list
val relation_names : formula -> string list

(* The equality relation has a special status *)
val eq_rel          : string * int
val mk_eq           : term * term -> formula
val dest_eq         : formula -> term * term
val is_eq           : formula -> bool
val lhs             : formula -> term
val rhs             : formula -> term
val eq_occurs       : formula -> bool
val relations_no_eq : formula -> (string * int) list

(* Free variables *)
val FVT        : term -> string list
val FV         : formula -> string list
val FVL        : formula list -> string list
val specialize : formula -> formula
val generalize : formula -> formula

(* Subterms *)
val subterm         : int list -> term -> term
val rewrite         : (int list, term) maplet -> term -> term
val literal_subterm : int list -> formula -> term
val literal_rewrite : (int list, term) maplet -> formula -> formula

(* The Knuth-Bendix ordering *)
type Weight = string * int -> int
type Prec   = (string * int) * (string * int) -> order
val kb_weight  : Weight -> term -> int * string mlibMultiset.mset
val kb_compare : Weight -> Prec -> term * term -> order option

end