(* ========================================================================= *)
(* SUBSTITUTIONS ON FIRST-ORDER TERMS AND FORMULAS                           *)
(* Created by Joe Hurd, June 2002                                            *)
(* ========================================================================= *)

(*
app load ["Binarymap", "mlibUseful", "mlibTerm"];
*)

(*
*)
structure mlibSubst :> mlibSubst =
struct

open mlibUseful mlibTerm;

infixr 8 ++;
infixr 7 >>;
infixr 6 ||;
infixr |-> ::> @> oo ##;

structure M = Binarymap; local open Binarymap in end;

(* ------------------------------------------------------------------------- *)
(* Helper functions.                                                         *)
(* ------------------------------------------------------------------------- *)

fun Mpurge (d, k) = fst (M.remove (d, k)) handle NotFound => d;

(* ------------------------------------------------------------------------- *)
(* The underlying representation.                                            *)
(* ------------------------------------------------------------------------- *)

datatype subst = Subst of (string, term) M.dict;

(* ------------------------------------------------------------------------- *)
(* Operations.                                                               *)
(* ------------------------------------------------------------------------- *)

val |<>| = Subst (M.mkDict String.compare);

fun (a |-> b) ::> (Subst d) = Subst (M.insert (d, a, b));

fun (Subst sub1) @> (Subst sub2) =
  Subst (M.foldl (fn (a, b, d) => M.insert (d, a, b)) sub2 sub1);

fun null (Subst s) = M.numItems s = 0;

fun find_redex r (Subst d) = M.peek (d, r);

fun purge v (Subst d) = Subst (Mpurge (d, v));

local
  exception Unchanged;

  fun always f x = f x handle Unchanged => x;

  fun pair_unchanged f (x, y) =
    let
      val (c, x) = (true, f x) handle Unchanged => (false, x)
      val (c, y) = (true, f y) handle Unchanged => (c, y)
    in
      if c then (x, y) else raise Unchanged
    end;

  fun list_unchanged f =
    let
      fun g (x, (b, l)) = (true, f x :: l) handle Unchanged => (b, x :: l)
      fun h (true, l) = rev l | h (false, _) = raise Unchanged
    in
      h o foldl g (false, [])
    end;

  fun find_unchanged v r =
    case find_redex v r of SOME t => t | NONE => raise Unchanged;

  fun tm_subst r =
    let
      fun f (Var v)     = find_unchanged v r
        | f (Fn (n, a)) = Fn (n, list_unchanged f a)
    in
      f
    end;

  fun fm_subst r =
    let
      fun f False       = raise Unchanged
        | f True        = raise Unchanged
        | f (Atom tm  ) = Atom (tm_subst r tm)
        | f (Not p    ) = Not (f p)
        | f (And pq   ) = And (pair_unchanged f pq)
        | f (Or  pq   ) = Or  (pair_unchanged f pq)
        | f (Imp pq   ) = Imp (pair_unchanged f pq)
        | f (Iff pq   ) = Iff (pair_unchanged f pq)
        | f (Forall vp) = fm_substq r Forall vp
        | f (Exists vp) = fm_substq r Exists vp
    in
      if null r then I else always f
    end
  and fm_substq r Q (v, p) =
    let val v' = variant v (FV (fm_subst (purge v r) p))
    in Q (v', fm_subst ((v |-> Var v') ::> r) p)
    end;
in
  fun term_subst    env tm = if null env then tm else always (tm_subst env) tm;
  fun formula_subst env fm = fm_subst env fm;
end;
  
fun norm (sub as Subst dict) =
  let
    fun check (a, b, (c, d)) =
      if Var a = b then (true, fst (M.remove (d, a))) else (c, d)
    val (removed, dict') = M.foldl check (false, dict) dict
  in
    if removed then Subst dict' else sub
  end;

fun to_maplets (Subst s) = map (op|->) (M.listItems s);

fun from_maplets ms = foldl (op ::>) |<>| (rev ms);

fun restrict vs =
  from_maplets o List.filter (fn (a |-> _) => mem a vs) o to_maplets;

(* Note: this just doesn't work with cyclic substitutions! *)
fun refine (Subst sub1) sub2 =
  let
    fun f ((a, b), s) =
      let val b' = term_subst sub2 b
      in if Var a = b' then s else (a |-> b') ::> s
      end
  in
    foldl f sub2 (M.listItems sub1)
  end;

local
  exception QF
  fun rs (v, Var w, l) = if mem w l then raise QF else w :: l
    | rs (_, Fn _, _) = raise QF
in
  fun is_renaming (Subst sub) = (M.foldl rs [] sub; true) handle QF => false;
end;

fun foldl f b (Subst sub) = M.foldl (fn (s, t, a) => f (s |-> t) a) b sub;

fun foldr f b (Subst sub) = M.foldr (fn (s, t, a) => f (s |-> t) a) b sub;

val pp_subst =
  pp_map to_maplets
  (fn pp =>
   (fn [] => pp_string pp "|<>|"
     | l => pp_list (pp_maplet pp_string pp_term) pp l));

end