open Piaf

let hostname = "https://lin-jchen-01.int.cpacket.com"
let host = "https://10.50.4.134"
let api = "/api/epg_fr/known_udp_protocols/"

let create_client env ~sw = 
  let client_result = Client.create 
    env 
    ~sw 
    ~config:{
      Config.default with allow_insecure = true;
    }
    (Uri.of_string host)
  in
  match client_result with 
  | Ok client -> client
  | _ -> failwith " fail to init client"

let headers = 
  let user = Printf.sprintf "%s:%s" (Sys.getenv "USERNAME") (Sys.getenv "PASSWORD") in
  [("Authorization", "Basic " ^ Base64.encode_exn user)]

let _ =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let client = create_client env ~sw in
  let res_result = Client.get ~headers client api in
  let res_body = 
    match res_result with
    | Ok res -> Body.to_string res.body
    | Error error -> failwith ("Error: " ^ Error.to_string error)
  in
  match res_body with 
  | Ok body_str -> Eio.traceln "%s" body_str;Client.shutdown client
  | _ -> failwith "error parsing res";;