(** This module maps between the opam and 0install concepts. Roughly:
    
    - An opam package name is a 0install role.
    - An opam package is a 0install implementation.
    - An opam version formula is a 0install restriction.

    For dependencies:

    - depends become "essential" dependencies
    - depopts are ignored (the opam solver ignores them too; they don't have constraints)
    - conflicts become "restricts" (with the test reversed)

    Dependencies on alternatives (e.g. "ocaml-base-compiler | ocaml-variants")
    become a dependency on a virtual package which has each choice as an
    implementation. *)

module Make (Context : S.CONTEXT) : sig
  include Zeroinstall_solver.S.SOLVER_INPUT with type rejection = Context.rejection

  val version : impl -> OpamPackage.t option
  (** [version impl] is the Opam package for [impl], if any.
      Virtual and dummy implementations return [None]. *)

  val package_name : Role.t -> OpamPackage.Name.t option
  (** [package_name role] is the Opam package name for [role], if any.
      Return [None] on virtual roles. *)

  val formula : restriction -> [`Ensure | `Prevent] * OpamFormula.version_formula
  (** [formula restriction] returns the version formula represented by this
      restriction along with its negation status: [(`Prevent, formula)] roughly
      means [not formula]. *)

  val root_role : context:Context.t -> OpamPackage.Name.t list -> Role.t
  (** [root_role pkg_names] is a virtual package that depends on all
      the packages in pkg_names with version constraints from
      [Context.user_restrictions]. *)
end
