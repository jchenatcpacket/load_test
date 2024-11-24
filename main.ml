let sum_to n =
  Eio.traceln "Starting CPU-intensive task...";
  let total = ref 0 in
  for i = 1 to n do
    total := !total + i
  done;
  Eio.traceln "Finished";
  !total;;

let main ~domain_mgr =
  let test n =
    Eio.traceln "sum 1..%d = %d" n
      (Eio.Domain_manager.run domain_mgr
        (fun () -> sum_to n))
  in
  let rec create_n_tasks n task_definition = 
    match n with
    | 0 -> []
    | 1 -> [task_definition]
    | _ -> task_definition :: create_n_tasks (n-1) task_definition
  in 
  let task_number = 
    match Sys.getenv_opt "TASK_NUMBER" with
    | Some n -> int_of_string n
    | None -> 0
  in
  let tasks = create_n_tasks task_number (fun () -> test 100)
  in
  Eio.Fiber.all tasks;;

let () = Eio_main.run @@ fun env ->
  main ~domain_mgr:(Eio.Stdenv.domain_mgr env);;
