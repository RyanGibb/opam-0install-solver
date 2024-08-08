let pp_pkg = Fmt.of_to_string OpamPackage.to_string

let env =
  Opam_0install.Dir_context.std_env
    ~arch:"x86_64"
    ~os:"linux"
    ~os_family:"debian"
    ~os_distribution:"debian"
    ~os_version:"10"
    ()

module Solver = Opam_0install.Solver.Make(Opam_0install.Dir_context)

let select repo verbose spec =
  let result = match spec with
  | [] -> OpamConsole.error "No packages requested!"; `Bad_arguments
  | spec ->
    (* Collect any user-provided constraints from the command-line arguments: *)
    let constraints =
      spec
      |> List.filter_map (function
          | _, None -> None
          | x, Some y -> Some (x, y)
        )
      |> OpamPackage.Name.Map.of_list in
    let pkgs = List.map fst spec in
    let context = Opam_0install.Dir_context.create repo ~constraints ~env in
    let r = Solver.solve context pkgs in
    match r with
    | Ok selections ->
      Fmt.pr "%a@." Fmt.(list ~sep:(any " ") pp_pkg) (Solver.packages_of_result selections);
      Solver.packages_of_result selections
      |> List.iter (fun pkg -> Printf.printf "- %s\n" (OpamPackage.to_string pkg));
      `Success
    | Error problem ->
      OpamConsole.error "No solution";
      print_endline (Solver.diagnostics ~verbose problem);
      `No_solution
  in
  OpamStd.Sys.get_exit_code result

open Cmdliner

(* name * version constraint
   Based on version in opam-client, which doesn't seem to be exposed. *)
let atom =
  let parse str =
    let re = Re.(compile @@ seq [
        bos;
        group @@ rep1 @@ diff any (set ">=<.!");
        group @@ alt [ seq [ set "<>"; opt @@ char '=' ];
                       set "=."; str "!="; ];
        group @@ rep1 any;
        eos;
      ]) in
    try
      let sub = Re.exec re str in
      let sname = Re.Group.get sub 1 in
      let sop = Re.Group.get sub 2 in
      let sversion = Re.Group.get sub 3 in
      let name = OpamPackage.Name.of_string sname in
      let sop = if sop = "." then "=" else sop in
      let op = OpamLexer.FullPos.relop sop in
      let version = OpamPackage.Version.of_string sversion in
      `Ok (name, Some (op, version))
    with Not_found | Failure _ | OpamLexer.Error _ ->
    try `Ok (OpamPackage.Name.of_string str, None)
    with Failure msg -> `Error msg
  in
  let print ppf atom =
    Fmt.string ppf (OpamFormula.short_string_of_atom atom) in
  parse, print

let repo =
  let doc = "Repository directory." in
  Arg.(required @@ opt (some string) None @@ info ["repo"] ~doc)

let spec =
  Arg.pos_all atom [] @@ Arg.info []

let verbose =
  let doc = "Show more details in the diagnostics." in
  Arg.(value @@ flag @@ info ["verbose"] ~doc)

let cmd =
  let doc = "Select opam packages using 0install backend" in
  let info = Cmd.info "opam-0install" ~doc in
  let term =
    Term.(const select $ repo $ verbose $ Arg.value spec)
  in
  Cmd.v info term

let () =
  exit @@ Cmd.eval' cmd
