let sum_to n =
  Eio.traceln "Starting CPU-intensive task...";
  let total = ref 0 in
  for i = 1 to n do
    total := !total + i
  done;
  Eio.traceln "Finished: sum 1..%d = %d" n !total;;

[@@@warning "-32"]
let domain_task = fun () -> sum_to 10000

(* [@@@warning "-32"]
let domain_task_2 = fun () -> 
  let open Lwt in 
  let open Cohttp in
  let open Cohttp_lwt_unix in
  let open Eio in
  let url = "https://jsonplaceholder.typicode.com/todos/2" in
  let body =
    Client.get (Uri.of_string url) >>= fun (resp, body) ->
    let code = resp |> Response.status |> Code.code_of_status in
    traceln "Response code: %d\n" code;
    traceln "Headers: %s\n" (resp |> Response.headers |> Header.to_string);
    body |> Cohttp_lwt.Body.to_string >|= fun body ->
    traceln "Body of length: %d\n" (String.length body);
  body in
  let body = Lwt_main.run body in
  traceln "Received body: %s" body *)

[@@@warning "-32"]
let domain_task_3 = fun () ->
  let url = "https://jsonplaceholder.typicode.com/todos/2" in
  let res = Ezcurl.get ~url () in
  let content = 
    match res with 
    | Ok c -> c 
    | Error (_,s) -> failwith s 
  in
  Eio.traceln "res staus code: %d" content.Ezcurl.code;;

let main ~domain_mgr =
  let rec create_n_tasks n task = 
    match n with
    | 0 -> []
    | 1 -> [task]
    | _ -> task :: create_n_tasks (n-1) task
  in 
  let task_number = 
    match Sys.getenv_opt "TASK_NUMBER" with
    | Some n -> int_of_string n
    | None -> 0
  in
  let tasks = create_n_tasks task_number (fun () -> Eio.Domain_manager.run domain_mgr domain_task_3)
  in
  Eio.Fiber.all tasks;;

let () = Eio_main.run @@ fun env ->
  main ~domain_mgr:(Eio.Stdenv.domain_mgr env);;
