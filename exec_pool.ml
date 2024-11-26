(* use execution pool to invoke parallel requests *)
let api_request client ~sw = 
  let open Cohttp_eio in
  let url = Sys.getenv "URL" in
  let resp, _ = Client.get ~sw client (Uri.of_string url) in
  match resp.status with
  | `OK -> Eio.traceln "success request"
  | _ -> Eio.traceln  "http error"
  
let create_task accumulator exec_pool ~sw http_client = 
  let task_number = Sys.getenv "REQUEST_NUMBER" |> int_of_string in
  match task_number with
  | 0 -> accumulator
  | _ -> accumulator @ [fun () -> 
    Eio.Executor_pool.submit_exn exec_pool ~weight:0.01 (fun () -> api_request http_client ~sw)];;

let main ~domain_mgr http_client =
  Eio.Switch.run @@ fun sw -> 
  let exec_pool = 
    Eio.Executor_pool.create ~sw domain_mgr ~domain_count:(Domain.recommended_domain_count ())
  in
  let tasks = create_task [] exec_pool ~sw http_client in
  Eio.Fiber.all tasks;;