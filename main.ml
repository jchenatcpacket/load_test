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
  let destined_time = Sys.getenv "DESTINED_UNIX_TIME" |> float_of_string in
  let cur_time = Eio.Time.now clock in
  let rec create_n_tasks n task = 
    match n with
    | 0 -> []
    | 1 -> [task]
    | _ -> task :: create_n_tasks (n-1) task
  in
  let task_number = Domain.recommended_domain_count () in
  let tasks = create_n_tasks task_number (fun () -> Eio.Domain_manager.run domain_mgr api_request)
  in
  Eio.traceln "current time:  %f" cur_time;
  Eio.traceln "destined time: %f" destined_time;
  if destined_time < cur_time then failwith "destined time is in the past, enter a future time"
  else
    Eio.traceln "start waiting";
    Eio.Time.sleep_until clock destined_time;
    Eio.traceln "done waiting. starting tasks";
    Eio.Fiber.all tasks;;

let () = Eio_main.run @@ fun env ->
  Eio.traceln "my name: %s, her name: %s" Helper.MyHelper.myname Helper.her_name;
  main ~domain_mgr:(Eio.Stdenv.domain_mgr env) ~clock:(Eio.Stdenv.clock env);;
