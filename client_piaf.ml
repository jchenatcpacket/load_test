let url = Sys.getenv "URL"

let create_client env ~sw =
  let open Piaf in
  let client_result = Client.create
    env 
    ~sw 
    ~config:{
      Config.default with allow_insecure = true;
    }
    (Uri.of_string "")
  in
  match client_result with 
  | Ok client -> client
  | Error err -> failwith ("fail to init client: " ^ Error.to_string err)

let parallel_count = Sys.getenv "REQUEST_NUMBER" |> int_of_string

let headers = 
  let user = Printf.sprintf "%s:%s" (Sys.getenv "USERNAME") (Sys.getenv "PASSWORD") in
  [("Authorization", "Basic " ^ Base64.encode_exn user)]

let api_request env ~sw = 
  Eio.traceln "starting request...";
  let client = create_client env ~sw in
  let res_result = Piaf.Client.get ~headers client "" in
  match res_result with
  | Ok res -> Piaf.Status.to_code res.status |> Eio.traceln "resp status: %d"
  | Error err -> failwith (Piaf.Error.to_string err);
  Piaf.Client.shutdown client;;

let api_request2 env ~sw =
  Eio.traceln "starting request...";
  match Piaf.Client.Oneshot.get 
    ~config:{
      Piaf.Config.default with 
        allow_insecure = true;
        connect_timeout = 1000000.0;
    }
    ~headers:headers
    ~sw
    env
    (Uri.of_string url)
  with
  | Ok resp -> 
    let body = Piaf.Response.body resp in
    let _ = Piaf.Body.drain body in 
    Piaf.Status.to_code resp.status |> Eio.traceln "resp status: %d"
  | Error err -> failwith ("error resp: " ^ Piaf.Error.to_string err);;

let api_request3 env ~sw =
  Eio.traceln "starting request...";
  match Piaf.Client.Oneshot.post 
    ~config:{
      Piaf.Config.default with 
        allow_insecure = true;
        connect_timeout = 1000000.0;
    }
    ~headers: (("Content-Type", "application/json") :: headers)
    ~body:(Piaf.Body.of_string {| 
    [
      {
        "port": "55",
        "protocol": "test-james"
      }
    ] |})
    ~sw
    env
    (Uri.of_string url)
  with
  | Ok resp -> 
    let body = Piaf.Response.body resp in
    let _ = Piaf.Body.drain body in 
    Piaf.Status.to_code resp.status |> Eio.traceln "resp status: %d"
  | Error err -> failwith ("error resp: " ^ Piaf.Error.to_string err);;

let api_request4 env ~sw =
    Eio.traceln "starting request...";
    let _ = Piaf.Client.Oneshot.get 
        ~config:{
        Piaf.Config.default with 
            allow_insecure = true;
            connect_timeout = 1000000.0;
        }
        ~headers:headers
        ~sw
        env
        (Uri.of_string url) in
    Eio.traceln "sent request";;


let main env =
  let domain_mgr = Eio.Stdenv.domain_mgr env in
  let clock = Eio.Stdenv.clock env in
  (* Helper.wait_until clock (); *)
  Eio.Switch.run @@ fun sw ->
    let pool = Eio.Executor_pool.create ~sw domain_mgr ~domain_count:(Domain.recommended_domain_count ()) in
    let task = Eio.Executor_pool.submit_exn pool ~weight:0.01 (fun () -> api_request4) in
    let tasks = List.init parallel_count (fun _ -> fun () -> task env ~sw) in
    let rec loop_tasks () = 
      Eio.Fiber.all tasks;
      Eio.traceln "sleeping for 3 sec:";
      Eio.Time.sleep clock 3.0;
      Eio.traceln "done sleeping, making req again";
      loop_tasks ();
    in 
    loop_tasks ();;

let _ = Eio_main.run @@ main
