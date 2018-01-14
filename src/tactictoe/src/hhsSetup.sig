signature hhsSetup =
sig
  
  (* recording *)
  val hhs_norecprove_flag  : bool ref
  val hhs_norecord_flag    : bool ref
  val hhs_nolet_flag       : bool ref
  
  (* learning *)
  val hhs_ortho_flag   : bool ref
  val hhs_ortho_number : int ref
  val hhs_selflearn_flag : bool ref

  (* evaluation *)
  val one_in_n      : unit -> bool
  val hhs_eval_flag : bool ref
  val hhs_noprove_flag : bool ref
  val hh_only_flag  : bool ref
  
  (* preselection *)
  val hhs_maxselect_pred : int ref
  
  (* search *)
  val hhs_cache_flag     : bool ref
  val hhs_mc_flag        : bool ref
  val hhs_mcrecord_flag  : bool ref
  val hhs_mcnoeval_flag  : bool ref
  val hhs_mctriveval_flag : bool ref
  val hhs_mc_radius      : int ref
  val hhs_mc_coeff       : real ref
  val hhs_timedepth_flag : bool ref
  val hhs_width_coeff    : real ref
  
  (* metis + holyhammer + synthetizing *)
  val hhs_metisexec_flag : bool ref
  val hhs_metishammer_flag : bool ref
  val hhs_metisrecord_flag : bool ref
  val hhs_metisortho_flag : bool ref
  val hhs_thmortho_flag : bool ref
  
  val hhs_metis_time  : real ref
  val hhs_metis_npred : int ref
  
  (* holyhammer *)
  val hhs_hhhammer_flag : bool ref 
  val hhs_hhhammer_time : int ref 
  val hhs_async_limit : int ref 
  
  (* synthetizing *)
  val hhs_thmlarg_flag : bool ref 
  val hhs_thmlarg_number : int ref
  val hhs_termarg_flag : bool ref
  
  (* minimization *)
  val hhs_prettify_flag : bool ref
  val hhs_minimize_flag : bool ref
  
  (* allows to test for the name of the theorem before evaluation *)
  val test_eval_hook : (string -> bool) ref
  
  (* init search *)
  val set_isearch : unit -> unit
  val set_isearch_hook : (unit -> unit) ref
  val set_esearch : unit -> unit
  
  (* init record and eval *)
  val set_irecord : unit -> unit
  val set_erecord : unit -> unit

end