let api_request = fun () ->
  let url = 
    match Sys.getenv_opt "URL" with
    | Some url -> url
    | None -> failwith "need URL environment variable" in
  let res = Eio.traceln "starting request to %s" url; Ezcurl.get ~url () in
  let content = 
    match res with 
    | Ok c -> c 
    | Error (_,s) -> failwith s 
  in
  Eio.traceln "res staus code: %d" content.Ezcurl.code;;

let main ~domain_mgr ~clock =
  let destined_unix_time = 
    match Sys.getenv_opt "DESTINED_UNIX_TIME" with
    | Some n -> float_of_string n
    | None -> 0.0
  in
  let rec create_n_tasks n task = 
    match n with
    | 0 -> []
    | 1 -> [task]
    | _ -> task :: create_n_tasks (n-1) task
  in
  let task_number = Domain.recommended_domain_count () in
  let tasks = create_n_tasks task_number (fun () -> Eio.Domain_manager.run domain_mgr api_request)
  in
  Eio.Time.sleep_until clock destined_unix_time;
  Eio.Fiber.all tasks;;

let () = Eio_main.run @@ fun env ->
  main ~domain_mgr:(Eio.Stdenv.domain_mgr env) ~clock:(Eio.Stdenv.clock env);;
