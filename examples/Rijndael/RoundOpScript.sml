(*---------------------------------------------------------------------------*)
(* Operations performed in a round:                                          *)
(*                                                                           *)
(*    - applying Sboxes                                                      *)
(*    - shifting rows                                                        *)
(*    - mixing columns                                                       *)
(*    - adding round keys                                                    *)
(*                                                                           *)
(* We prove "inversion" theorems for each of these                           *)
(*                                                                           *)
(*---------------------------------------------------------------------------*)

open HolKernel Parse boolLib bossLib pairTools;

(*---------------------------------------------------------------------------*)
(* Make bindings to pre-existing stuff                                       *)
(*---------------------------------------------------------------------------*)

val RESTR_EVAL_TAC = computeLib.RESTR_EVAL_TAC;

val Sbox_Inversion = sboxTheory.Sbox_Inversion;

(*---------------------------------------------------------------------------*)
(* Create the theory.                                                        *)
(*---------------------------------------------------------------------------*)

val _ = new_theory "RoundOp";


(*---------------------------------------------------------------------------*)
(* The state is 16 bytes                                                     *)
(*---------------------------------------------------------------------------*)

val _ = type_abbrev("state", 
                    Type`:word8 # word8 # word8 # word8 # 
                          word8 # word8 # word8 # word8 # 
                          word8 # word8 # word8 # word8 # 
                          word8 # word8 # word8 # word8`);

val _ = type_abbrev("key", Type`:state`);

val _ = type_abbrev("w8x4",Type`:word8 # word8 # word8 # word8`);


(*---------------------------------------------------------------------------*)
(*      Name some constants used in the code and specification               *)
(*---------------------------------------------------------------------------*)

val ZERO_def   = Define   `ZERO = (F,F,F,F,F,F,F,F)`;
val ONE_def    = Define    `ONE = (F,F,F,F,F,F,F,T)`;
val TWO_def    = Define    `TWO = (F,F,F,F,F,F,T,F)`;
val THREE_def  = Define  `THREE = (F,F,F,F,F,F,T,T)`;
val NINE_def   = Define   `NINE = (F,F,F,F,T,F,F,T)`;
val ONE_B_def  = Define  `ONE_B = (F,F,F,T,T,F,T,T)`;
val EIGHTY_def = Define `EIGHTY = (T,F,F,F,F,F,F,F)`;
val B_HEX_def  = Define  `B_HEX = (F,F,F,F,T,F,T,T)`;
val D_HEX_def  = Define  `D_HEX = (F,F,F,F,T,T,F,T)`;
val E_HEX_def  = Define  `E_HEX = (F,F,F,F,T,T,T,F)`;

(*---------------------------------------------------------------------------
    Bits and bytes and numbers
 ---------------------------------------------------------------------------*)

val B2N = Define `(B2N T = 1) /\ (B2N F = 0)`;

val BYTE_TO_NUM = Define 
  `BYTE_TO_NUM (b7,b6,b5,b4,b3,b2,b1,b0) =
     128*B2N(b7) + 64*B2N(b6) + 32*B2N(b5) + 
      16*B2N(b4) + 8*B2N(b3) + 4*B2N(b2) + 2*B2N(b1) + B2N(b0)`;

(*---------------------------------------------------------------------------*)
(* XOR and AND on bytes                                                      *)
(*---------------------------------------------------------------------------*)

val _ = (set_fixity "XOR"     (Infixr 350); 
         set_fixity "XOR8x4"  (Infixr 350);
         set_fixity "XOR8"    (Infixr 350);
         set_fixity "AND8"    (Infixr 350));

val XOR_def =  Define `(x:bool) XOR y = ~(x=y)`;

val XOR8_def = Define 
 `(a,b,c,d,e,f,g,h) XOR8 (a1,b1,c1,d1,e1,f1,g1,h1) 
                     = 
                 (a XOR a1, 
                  b XOR b1, 
                  c XOR c1, 
                  d XOR d1,
                  e XOR e1, 
                  f XOR f1, 
                  g XOR g1, 
                  h XOR h1)`;

val AND8_def = Define 
 `(a,b,c,d,e,f,g,h) AND8 (a1,b1,c1,d1,e1,f1,g1,h1) 
                     = 
                 (a /\ a1, 
                  b /\ b1, 
                  c /\ c1, 
                  d /\ d1,
                  e /\ e1, 
                  f /\ f1, 
                  g /\ g1, 
                  h /\ h1)`;

(*---------------------------------------------------------------------------*)
(* Algebraic lemmas for XOR8                                                 *)
(*---------------------------------------------------------------------------*)

val XOR8_ZERO = Q.store_thm
("XOR8_ZERO",
 `!x. x XOR8 ZERO = x`,
 PGEN_TAC (Term `(a1,a2,a3,a4,a5,a6,a7,a8):word8`) THEN EVAL_TAC);

val XOR8_INV = Q.store_thm
("XOR8_INV",
 `!x. x XOR8 x = ZERO`,
 PGEN_TAC (Term `(a1,a2,a3,a4,a5,a6,a7,a8):word8`) THEN EVAL_TAC);

val XOR8_AC = Q.store_thm
("XOR8_AC",
 `(!x y z:word8. (x XOR8 y) XOR8 z = x XOR8 (y XOR8 z)) /\
  (!x y:word8. (x XOR8 y) = (y XOR8 x))`, 
 CONJ_TAC THEN
 PGEN_TAC (Term `(a1,a2,a3,a4,a5,a6,a7,a8):word8`) THEN 
 PGEN_TAC (Term `(b1,b2,b3,b4,b5,b6,b7,b8):word8`) THEN
 TRY (PGEN_TAC (Term `(c1,c2,c3,c4,c5,c6,c7,c8):word8`)) THEN
 EVAL_TAC THEN DECIDE_TAC);


(*---------------------------------------------------------------------------*)
(*    Moving data into and out of a state                                    *)
(*---------------------------------------------------------------------------*)

val to_state_def = Define
 `to_state (b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13,b14,b15) 
                =
            (b0,b4,b8,b12,
             b1,b5,b9,b13,
             b2,b6,b10,b14,
             b3,b7,b11,b15)`;

val from_state_def = Define
 `from_state (b0,b4,b8,b12,
              b1,b5,b9,b13,
              b2,b6,b10,b14,
              b3,b7,b11,b15) 
 = (b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13,b14,b15)`;

val to_state_Inversion = 
  Q.store_thm
  ("to_state_Inversion",
   `!s:state. from_state(to_state s) = s`,
   PGEN_TAC (Term `(b0,b1,b2,b3,b4,b5,b6,b7,b8,
                    b9,b10,b11,b12,b13,b14,b15):state`) THEN EVAL_TAC);


val from_state_Inversion = 
  Q.store_thm
  ("from_state_Inversion",
   `!s:state. to_state(from_state s) = s`,
   PGEN_TAC (Term `(b0,b1,b2,b3,b4,b5,b6,b7,b8,
                    b9,b10,b11,b12,b13,b14,b15):state`) THEN EVAL_TAC);


(*---------------------------------------------------------------------------*)
(*    Apply an Sbox to the state                                             *)
(*---------------------------------------------------------------------------*)

val _ = Parse.hide "S";

val genSubBytes_def = try Define
  `genSubBytes S (b00,b01,b02,b03,
                  b10,b11,b12,b13,
                  b20,b21,b22,b23,
                  b30,b31,b32,b33) 
                          = 
             (S b00, S b01, S b02, S b03,
              S b10, S b11, S b12, S b13,
              S b20, S b21, S b22, S b23,
              S b30, S b31, S b32, S b33)`;


val SubBytes_def    = Define `SubBytes = genSubBytes Sbox`;
val InvSubBytes_def = Define `InvSubBytes = genSubBytes InvSbox`;

val SubBytes_Inversion = Q.store_thm
("SubBytes_Inversion",
 `!s:state. genSubBytes InvSbox (genSubBytes Sbox s) = s`,
 PGEN_TAC (Term `(b00,b01,b02,b03,b10,b11,b12,b13,
                  b20,b21,b22,b23, b30,b31,b32,b33):state`)
 THEN EVAL_TAC
 THEN RW_TAC std_ss [Sbox_Inversion]);


(*---------------------------------------------------------------------------
    Left-shift the first row not at all, the second row by 1, the 
    third row by 2, and the last row by 3. And the inverse operation.
 ---------------------------------------------------------------------------*)

val ShiftRows_def = Define
  `ShiftRows (b00,b01,b02,b03,
              b10,b11,b12,b13,
              b20,b21,b22,b23,
              b30,b31,b32,b33) 
                     =
             (b00,b01,b02,b03,
              b11,b12,b13,b10,
              b22,b23,b20,b21,
              b33,b30,b31,b32)`;

val InvShiftRows_def = Define
  `InvShiftRows (b00,b01,b02,b03,
                 b11,b12,b13,b10,
                 b22,b23,b20,b21,
                 b33,b30,b31,b32)
                     =
                (b00,b01,b02,b03,
                 b10,b11,b12,b13,
                 b20,b21,b22,b23,
                 b30,b31,b32,b33)`; 

(*---------------------------------------------------------------------------
        InvShiftRows inverts ShiftRows
 ---------------------------------------------------------------------------*)

val ShiftRows_Inversion = Q.store_thm
("ShiftRows_Inversion",
 `!s:state. InvShiftRows (ShiftRows s) = s`,
 PGEN_TAC (Term`(b00,b01,b02,b03,b10,b11,b12,b13,
                 b20,b21,b22,b23,b30,b31,b32,b33):state`)
 THEN EVAL_TAC);


(*---------------------------------------------------------------------------*)
(* For alternative decryption scheme                                         *)
(*---------------------------------------------------------------------------*)

val ShiftRows_SubBytes_Commute = Q.store_thm
 ("ShiftRows_SubBytes_Commute",
  `!s. ShiftRows (SubBytes s) = SubBytes (ShiftRows s)`,
  PGEN_TAC (Term `(v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,
                   v10,v11,v12,v13,v14,v15):state`) THEN EVAL_TAC);


val InvShiftRows_InvSubBytes_Commute = Q.store_thm
 ("InvShiftRows_InvSubBytes_Commute",
  `!s. InvShiftRows (InvSubBytes s) = InvSubBytes (InvShiftRows s)`,
  PGEN_TAC (Term `(v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,
                   v10,v11,v12,v13,v14,v15):state`) THEN EVAL_TAC);



(*---------------------------------------------------------------------------
        Shift a byte left and right
 ---------------------------------------------------------------------------*)

val LeftShift = Define
   `LeftShift (b7,b6,b5,b4,b3,b2,b1,b0) = (b6,b5,b4,b3,b2,b1,b0,F)`;

val RightShift = Define
   `RightShift (b7,b6,b5,b4,b3,b2,b1,b0) = (F,b7,b6,b5,b4,b3,b2,b1)`;

(*---------------------------------------------------------------------------
       Compare bits and bytes as if they were numbers. Not currently used
 ---------------------------------------------------------------------------*)

(*

val _ = Hol_datatype `order = LESS | EQUAL | GREATER`;

val BIT_COMPARE = Define 
  `(BIT_COMPARE F T = LESS) /\
   (BIT_COMPARE T F = GREATER) /\
   (BIT_COMPARE x y = EQUAL)`;
                        

val BYTE_COMPARE = Define
  `BYTE_COMPARE (a7,a6,a5,a4,a3,a2,a1,a0)
                (b7,b6,b5,b4,b3,b2,b1,b0) = 
    case BIT_COMPARE a7 b7 
     of EQUAL -> 
        (case BIT_COMPARE a6 b6
          of EQUAL -> 
             (case BIT_COMPARE a5 b5
               of EQUAL -> 
                  (case BIT_COMPARE a4 b4
                    of EQUAL ->
                       (case BIT_COMPARE a3 b3
                         of EQUAL -> 
                            (case BIT_COMPARE a2 b2
                              of EQUAL -> 
                                 (case BIT_COMPARE a1 b1
                                   of EQUAL -> BIT_COMPARE a0 b0
                                   || other -> other) 
                              || other -> other) 
                         || other -> other) 
                    || other -> other) 
               || other -> other) 
          || other -> other) 
     || other -> other`;
*)

(*---------------------------------------------------------------------------
    Multiply a byte (representing a polynomial) by x. 

   xtime b = (LeftShift b) 
                XOR8 
             (case BYTE_COMPARE b EIGHTY
               of LESS  -> ZERO 
               || other -> ONE_B)

 ---------------------------------------------------------------------------*)

val xtime_def = Define
  `xtime (b7,b6,b5,b4,b3,b2,b1,b0)
     =
   if b7 then (b6,b5,b4,~b3,~b2,b1,~b0,T)
         else (b6,b5,b4,b3,b2,b1,b0,F)`;

val xtime_distrib = Q.store_thm
("xtime_distrib",
 `!a b. xtime (a XOR8 b) = (xtime a) XOR8 (xtime b)`,
 PGEN_TAC (Term `(a0,a1,a2,a3,a4,a5,a6,a7):word8`) THEN
 PGEN_TAC (Term `(b0,b1,b2,b3,b4,b5,b6,b7):word8`) THEN
 RW_TAC std_ss [xtime_def,XOR8_def,XOR_def] THEN DECIDE_TAC);

(*---------------------------------------------------------------------------*)
(* Multiplication by a constant                                              *)
(*---------------------------------------------------------------------------*)

val _ = set_fixity "**" (Infixl 600);

val (ConstMult_def,ConstMult_ind) = 
Lib.with_flag (Globals.priming,SOME "")
 Defn.tprove
  (Defn.Hol_defn "PolyMult"
     `b1 ** b2 =
        if b1 = ZERO then ZERO else 
        if (b1 AND8 ONE) = ONE 
           then b2 XOR8 ((RightShift b1) ** (xtime b2))
           else          (RightShift b1) ** (xtime b2)`,
   WF_REL_TAC `measure (BYTE_TO_NUM o FST)`
     THEN Cases THEN Cases_on `r` THEN Cases_on `r1`
     THEN Cases_on `r` THEN Cases_on `r1`
     THEN Cases_on `r` THEN Cases_on `r1`
     THEN RW_TAC arith_ss [ZERO_def,RightShift,BYTE_TO_NUM] 
     THEN RW_TAC arith_ss [B2N]);

val _ = save_thm("ConstMult_def",ConstMult_def);
val _ = save_thm("ConstMult_ind",ConstMult_ind);

val ConstMultDistrib = Q.store_thm
("ConstMultDistrib",
 `!x y z. x ** (y XOR8 z) = (x ** y) XOR8 (x ** z)`,
 recInduct ConstMult_ind
   THEN REPEAT STRIP_TAC
   THEN ONCE_REWRITE_TAC [ConstMult_def]
   THEN RW_TAC std_ss [XOR8_ZERO,xtime_distrib] 
   THEN REPEAT (WEAKEN_TAC (K true)) 
   THEN PROVE_TAC [XOR8_AC]);

(*---------------------------------------------------------------------------*)
(* Exponentiation                                                            *)
(*---------------------------------------------------------------------------*)

val PolyExp_def = Define
   `PolyExp x n = if n=0 then ONE else x ** PolyExp x (n-1)`;

(*---------------------------------------------------------------------------
        Column multiplication and its inverse
 ---------------------------------------------------------------------------*)

val MultCol_def = Define
 `MultCol (a,b,c,d) = 
   ((TWO ** a)   XOR8 (THREE ** b) XOR8  c           XOR8 d,
     a           XOR8 (TWO ** b)   XOR8 (THREE ** c) XOR8 d,
     a           XOR8  b           XOR8 (TWO ** c)   XOR8 (THREE ** d),
    (THREE ** a) XOR8  b           XOR8  c           XOR8 (TWO ** d))`;

val InvMultCol_def = Define
 `InvMultCol (a,b,c,d) = 
   ((E_HEX ** a) XOR8 (B_HEX ** b) XOR8 (D_HEX ** c) XOR8 (NINE  ** d),
    (NINE  ** a) XOR8 (E_HEX ** b) XOR8 (B_HEX ** c) XOR8 (D_HEX ** d),
    (D_HEX ** a) XOR8 (NINE  ** b) XOR8 (E_HEX ** c) XOR8 (B_HEX ** d),
    (B_HEX ** a) XOR8 (D_HEX ** b) XOR8 (NINE  ** c) XOR8 (E_HEX ** d))`;

(*---------------------------------------------------------------------------*)
(* Inversion lemmas for column multiplication.                               *)
(*---------------------------------------------------------------------------*)

val BYTE_CASES_TAC = 
 PGEN_TAC (Term `(a0,a1,a2,a3,a4,a5,a6,a7):word8`) THEN EVAL_TAC
   THEN REWRITE_TAC [REWRITE_RULE [ZERO_def] XOR8_ZERO]
   THEN MAP_EVERY Cases_on [`a0`, `a1`, `a2`, `a3`, `a4`, `a5`, `a6`, `a7`];


(*---------------------------------------------------------------------------*)
(* Note: could just use case analysis with Sbox_ind, then EVAL_TAC, but      *)
(* that's far slower.                                                        *)
(*---------------------------------------------------------------------------*)

val lemma_a1 = Q.prove
(`!a. E_HEX ** (TWO ** a) XOR8 
      B_HEX ** a          XOR8 
      D_HEX ** a          XOR8 
      NINE  ** (THREE ** a) = a`,
 BYTE_CASES_TAC THEN EVAL_TAC);

val lemma_a2 = Q.prove
(`!b. E_HEX ** (THREE ** b) XOR8 
      B_HEX ** (TWO ** b)   XOR8 
      D_HEX ** b            XOR8 
      NINE  ** b             = ZERO`,
 BYTE_CASES_TAC THEN EVAL_TAC);

val lemma_a3 = Q.prove
(`!c. E_HEX ** c            XOR8 
      B_HEX ** (THREE ** c) XOR8 
      D_HEX ** (TWO ** c)   XOR8 
      NINE ** c               =  ZERO`,
 BYTE_CASES_TAC THEN EVAL_TAC);

val lemma_a4 = Count.apply Q.prove
(`!d. E_HEX ** d            XOR8 
      B_HEX ** d            XOR8 
      D_HEX ** (THREE ** d) XOR8 
      NINE ** (TWO ** d)      = ZERO`,
 BYTE_CASES_TAC THEN EVAL_TAC);

val lemma_b1 = Q.prove
(`!a. NINE ** (TWO ** a) XOR8 
      E_HEX ** a         XOR8 
      B_HEX ** a         XOR8 
      D_HEX  ** (THREE ** a) = ZERO`,
 BYTE_CASES_TAC THEN EVAL_TAC);

val lemma_b2 = Q.prove
(`!b. NINE ** (THREE ** b) XOR8 
      E_HEX ** (TWO ** b)  XOR8 
      B_HEX ** b           XOR8 
      D_HEX ** b             = b`,
 BYTE_CASES_TAC THEN EVAL_TAC);

val lemma_b3 = Q.prove
(`!c. NINE ** c             XOR8 
      E_HEX ** (THREE ** c) XOR8 
      B_HEX ** (TWO ** c)   XOR8 
      D_HEX ** c              = ZERO`,
 BYTE_CASES_TAC THEN EVAL_TAC);

val lemma_b4 = Count.apply Q.prove
(`!d. NINE ** d             XOR8 
      E_HEX ** d            XOR8 
      B_HEX ** (THREE ** d) XOR8 
      D_HEX ** (TWO ** d)     = ZERO`,
 BYTE_CASES_TAC THEN EVAL_TAC);

val lemma_c1 = Q.prove
(`!a. D_HEX ** (TWO ** a) XOR8 
      NINE ** a           XOR8 
      E_HEX ** a          XOR8 
      B_HEX  ** (THREE ** a) = ZERO`,
 BYTE_CASES_TAC THEN EVAL_TAC);

val lemma_c2 = Q.prove
(`!b. D_HEX ** (THREE ** b) XOR8 
      NINE ** (TWO ** b)    XOR8 
      E_HEX ** b            XOR8 
      B_HEX ** b              = ZERO`,
 BYTE_CASES_TAC THEN EVAL_TAC);

val lemma_c3 = Q.prove
(`!c. D_HEX ** c           XOR8 
      NINE ** (THREE ** c) XOR8 
      E_HEX ** (TWO ** c)  XOR8 
      B_HEX ** c             = c`,
 BYTE_CASES_TAC THEN EVAL_TAC);

val lemma_c4 = Count.apply Q.prove
(`!d. D_HEX ** d            XOR8 
      NINE ** d             XOR8 
      E_HEX ** (THREE ** d) XOR8 
      B_HEX ** (TWO ** d)     = ZERO`,
 BYTE_CASES_TAC THEN EVAL_TAC);

val lemma_d1 = Q.prove
(`!a. B_HEX ** (TWO ** a) XOR8 
      D_HEX ** a          XOR8 
      NINE ** a           XOR8 
      E_HEX  ** (THREE ** a) = ZERO`,
 BYTE_CASES_TAC THEN EVAL_TAC);

val lemma_d2 = Q.prove
(`!b. B_HEX ** (THREE ** b) XOR8 
      D_HEX ** (TWO ** b)   XOR8 
      NINE ** b             XOR8 
      E_HEX ** b              = ZERO`,
 BYTE_CASES_TAC THEN EVAL_TAC);

val lemma_d3 = Q.prove
(`!c. B_HEX ** c            XOR8 
      D_HEX ** (THREE ** c) XOR8 
      NINE ** (TWO ** c)    XOR8 
      E_HEX ** c              = ZERO`,
 BYTE_CASES_TAC THEN EVAL_TAC);

val lemma_d4 = Count.apply Q.prove
(`!d. B_HEX ** d           XOR8 
      D_HEX ** d           XOR8 
      NINE ** (THREE ** d) XOR8 
      E_HEX ** (TWO ** d)     = d`,
 BYTE_CASES_TAC THEN EVAL_TAC);

(*---------------------------------------------------------------------------*)
(*  Set up permutative rewriting for XOR8                                    *)
(*---------------------------------------------------------------------------*)

val [c,a] = CONJUNCTS XOR8_AC;

(*---------------------------------------------------------------------------*)
(* The following lemma is hideous to prove without permutative rewriting     *)
(*---------------------------------------------------------------------------*)

val rearrange_xors = Q.prove   
(`(a1 XOR8 b1 XOR8 c1 XOR8 d1) XOR8
  (a2 XOR8 b2 XOR8 c2 XOR8 d2) XOR8
  (a3 XOR8 b3 XOR8 c3 XOR8 d3) XOR8
  (a4 XOR8 b4 XOR8 c4 XOR8 d4) 
     = 
  (a1 XOR8 a2 XOR8 a3 XOR8 a4) XOR8
  (b1 XOR8 b2 XOR8 b3 XOR8 b4) XOR8
  (c1 XOR8 c2 XOR8 c3 XOR8 c4) XOR8
  (d1 XOR8 d2 XOR8 d3 XOR8 d4)`,
 RW_TAC (std_ss ++ simpLib.ac_ss [(c,a)]) []);


val mix_lemma1 = Q.prove
(`!a b c d. 
   (E_HEX ** ((TWO ** a) XOR8 (THREE ** b) XOR8 c XOR8 d)) XOR8
   (B_HEX ** (a XOR8 (TWO ** b) XOR8 (THREE ** c) XOR8 d)) XOR8
   (D_HEX ** (a XOR8 b XOR8 (TWO ** c) XOR8 (THREE ** d))) XOR8
   (NINE  ** ((THREE ** a) XOR8 b XOR8 c XOR8 (TWO ** d)))
      = a`,
 RW_TAC std_ss [ConstMultDistrib] 
   THEN ONCE_REWRITE_TAC [rearrange_xors] 
   THEN RW_TAC std_ss [lemma_a1,lemma_a2,lemma_a3,lemma_a4,XOR8_ZERO]);

val mix_lemma2 = Q.prove
(`!a b c d. 
   (NINE ** ((TWO ** a) XOR8 (THREE ** b) XOR8 c XOR8 d)) XOR8
   (E_HEX ** (a XOR8 (TWO ** b) XOR8 (THREE ** c) XOR8 d)) XOR8
   (B_HEX ** (a XOR8 b XOR8 (TWO ** c) XOR8 (THREE ** d))) XOR8
   (D_HEX ** ((THREE ** a) XOR8 b XOR8 c XOR8 (TWO ** d)))
     = b`,
 RW_TAC std_ss [ConstMultDistrib] 
   THEN ONCE_REWRITE_TAC [rearrange_xors] 
   THEN RW_TAC std_ss [lemma_b1,lemma_b2,lemma_b3,lemma_b4,
                       XOR8_ZERO, ONCE_REWRITE_RULE [XOR8_AC] XOR8_ZERO]);

val mix_lemma3 = Q.prove
(`!a b c d. 
   (D_HEX ** ((TWO ** a) XOR8 (THREE ** b) XOR8 c XOR8 d)) XOR8
   (NINE ** (a XOR8 (TWO ** b) XOR8 (THREE ** c) XOR8 d)) XOR8
   (E_HEX ** (a XOR8 b XOR8 (TWO ** c) XOR8 (THREE ** d))) XOR8
   (B_HEX ** ((THREE ** a) XOR8 b XOR8 c XOR8 (TWO ** d)))
     = c`,
 RW_TAC std_ss [ConstMultDistrib] 
   THEN ONCE_REWRITE_TAC [rearrange_xors] 
   THEN RW_TAC std_ss [lemma_c1,lemma_c2,lemma_c3,lemma_c4,
                       XOR8_ZERO, ONCE_REWRITE_RULE [XOR8_AC] XOR8_ZERO]);

val mix_lemma4 = Q.prove
(`!a b c d. 
   (B_HEX ** ((TWO ** a) XOR8 (THREE ** b) XOR8 c XOR8 d)) XOR8
   (D_HEX ** (a XOR8 (TWO ** b) XOR8 (THREE ** c) XOR8 d)) XOR8
   (NINE ** (a XOR8 b XOR8 (TWO ** c) XOR8 (THREE ** d))) XOR8
   (E_HEX ** ((THREE ** a) XOR8 b XOR8 c XOR8 (TWO ** d)))
     = d`,
 RW_TAC std_ss [ConstMultDistrib] 
   THEN ONCE_REWRITE_TAC [rearrange_xors] 
   THEN RW_TAC std_ss [lemma_d1,lemma_d2,lemma_d3,lemma_d4,
                       XOR8_ZERO, ONCE_REWRITE_RULE [XOR8_AC] XOR8_ZERO]);

(*---------------------------------------------------------------------------*)
(* Get the constants of various definitions                                  *)
(*---------------------------------------------------------------------------*)

val [mult]     = decls "**";
val [TWO]      = decls "TWO";
val [THREE]    = decls "THREE";
val [NINE]     = decls "NINE";
val [B_HEX]    = decls "B_HEX";
val [D_HEX]    = decls "D_HEX";
val [E_HEX]    = decls "E_HEX";

val genMixColumns_def = Define
 `genMixColumns MC (b00,b01,b02,b03,
                    b10,b11,b12,b13,
                    b20,b21,b22,b23,
                    b30,b31,b32,b33)
 = let (b00', b10', b20', b30') = MC (b00,b10,b20,b30) in
   let (b01', b11', b21', b31') = MC (b01,b11,b21,b31) in
   let (b02', b12', b22', b32') = MC (b02,b12,b22,b32) in
   let (b03', b13', b23', b33') = MC (b03,b13,b23,b33)
   in 
    (b00', b01', b02', b03',
     b10', b11', b12', b13',
     b20', b21', b22', b23',
     b30', b31', b32', b33')`;


val MixColumns_def    = Define `MixColumns    = genMixColumns MultCol`;
val InvMixColumns_def = Define `InvMixColumns = genMixColumns InvMultCol`;


val MixColumns_Inversion = Q.store_thm
("MixColumns_Inversion",
 `!s. genMixColumns InvMultCol (genMixColumns MultCol s) = s`,
 PGEN_TAC (Term `(b00,b01,b02,b03,b10,b11,b12,b13,
                  b20,b21,b22,b23,b30,b31,b32,b33):state`)
  THEN RESTR_EVAL_TAC [mult,B_HEX,D_HEX,E_HEX,TWO,THREE,NINE]
  THEN RW_TAC std_ss [mix_lemma1,mix_lemma2,mix_lemma3,mix_lemma4]);


(*---------------------------------------------------------------------------
    Pairwise XOR the state with the round key
 ---------------------------------------------------------------------------*)

val AddRoundKey_def = Define
 `AddRoundKey 
         (k00,k01,k02,k03,k10,k11,k12,k13,k20,k21,k22,k23,k30,k31,k32,k33)
         (b00,b01,b02,b03,b10,b11,b12,b13,b20,b21,b22,b23,b30,b31,b32,b33)
       =
  (b00 XOR8 k00, b01 XOR8 k01, b02 XOR8 k02, b03 XOR8 k03,
   b10 XOR8 k10, b11 XOR8 k11, b12 XOR8 k12, b13 XOR8 k13, 
   b20 XOR8 k20, b21 XOR8 k21, b22 XOR8 k22, b23 XOR8 k23,
   b30 XOR8 k30, b31 XOR8 k31, b32 XOR8 k32, b33 XOR8 k33)`;


val AddRoundKey_Idemp = Q.store_thm
("AddRoundKey_Idemp",
 `!v u. AddRoundKey v (AddRoundKey v u) = u`,
 PGEN_TAC (Term `(v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,
                  v10,v11,v12,v13,v14,v15):state`) THEN 
 PGEN_TAC (Term `(u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,
                  u10,u11,u12,u13,u14,u15):state`)
 THEN EVAL_TAC THEN RW_TAC std_ss [CONJUNCT1 XOR8_AC,XOR8_INV,XOR8_ZERO]);


(*---------------------------------------------------------------------------*)
(* For alternative decryption scheme                                         *)
(*---------------------------------------------------------------------------*)

val InvMixColumns_Distrib = Q.store_thm
("InvMixColumns_Distrib",
 `!s k. InvMixColumns (AddRoundKey s k) 
            = 
        AddRoundKey (InvMixColumns s) (InvMixColumns k)`,
 PGEN_TAC (Term `(s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,
                  s10,s11,s12,s13,s14,s15):state`) THEN
 PGEN_TAC (Term `(k0,k1,k2,k3,k4,k5,k6,k7,k8,k9,
                  k10,k11,k12,k13,k14,k15):key`) THEN
 RW_TAC (std_ss ++ simpLib.ac_ss [(c,a)]) 
        [AddRoundKey_def, InvMixColumns_def,
         genMixColumns_def, InvMultCol_def, ConstMultDistrib]);


val _ = export_theory();
