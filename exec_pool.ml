(* use execution pool to invoke parallel requests *)
let api_request client ~sw = 
  let open Cohttp_eio in
  let url = Sys.getenv "URL" in
  let resp, _ = Client.get ~sw client (Uri.of_string url) in
  match resp.status with
  | `OK -> Eio.traceln "success request"
  | _ -> Eio.traceln  "http error"
  
let rec create_task task_number accumulator exec_pool ~sw http_client = 
  match task_number with
  | 0 -> accumulator
  | _ -> 
    let new_acc = accumulator @ [fun () -> 
    Eio.Executor_pool.submit_exn exec_pool ~weight:0.01 (fun () -> api_request http_client ~sw)] in
    create_task (task_number-1) new_acc exec_pool ~sw http_client

(* Fatal error: exception Invalid_argument("Switch accessed from wrong domain!") *)
(* let main ~domain_mgr http_client =
  Eio.Switch.run @@ fun sw -> 
  let exec_pool = 
    Eio.Executor_pool.create ~sw domain_mgr ~domain_count:(Domain.recommended_domain_count ())
  in
  let task_number = Sys.getenv "REQUEST_NUMBER" |> int_of_string in
  let tasks = create_task task_number [] exec_pool ~sw http_client in
  Eio.Fiber.all tasks;; *)

let main ~domain_mgr http_client ~clock =
  let open Eio in
  Switch.run @@ fun sw ->
  let pool =
    Eio.Executor_pool.create ~sw domain_mgr ~domain_count:(Domain.recommended_domain_count ())
  in
  let task =
    traceln "start http request";
    Eio.Executor_pool.submit_exn pool ~weight:0.01 (fun () -> api_request)
  in
  let task_number = Sys.getenv "REQUEST_NUMBER" |> int_of_string in
  let tasks = List.init task_number (fun _ -> fun () -> task ~sw http_client) in
  Helper.wait_until clock ();
  Fiber.all tasks;;