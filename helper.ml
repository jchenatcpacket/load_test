let her_name = "Cali"

(* let dt_str_to_tm (dt: string): Unix.tm = 
  Scanf.sscanf dt "%d-%d-%dT%d:%d:%d"
  (fun year month day hour minute second ->
    year := y - 1900;
    month := m - 1;
    day := d;
    hour := h;
    minute := min;
    second := s
  ); *)

let dt_to_tm (dt: string): Unix.tm =
  let year = ref 0 in
  let month = ref 0 in
  let day = ref 0 in
  let hour = ref 0 in
  let minute = ref 0 in
  let second = ref 0 in
  
  (* Use Scanf to parse the string *)
  Scanf.sscanf dt "%d-%d-%dT%d:%d:%d" (fun y m d h min s ->
    year := y - 1900;  (* Adjust to Unix tm year format *)
    month := m - 1;    (* Adjust to 0-based month *)
    day := d;
    hour := h;
    minute := min;
    second := s
  );
  
  {
    tm_sec = !second;
    tm_min = !minute;
    tm_hour = !hour;
    tm_mday = !day;
    tm_mon = !month;
    tm_year = !year;
    tm_wday = 0;  (* Day of week (0-6) - not calculated here *)
    tm_yday = 0;  (* Day in the year (0-365) - not calculated here *)
    tm_isdst = false;  (* Daylight saving time flag *)
  };;

let tm_to_unix (dt: Unix.tm): float = 
  let unix_time, _ = Unix.mktime dt in
  unix_time;;

let compose f g x = g (f x)

let dt_to_unix = compose dt_to_tm tm_to_unix

module MyHelper = struct
  let myname = "james"
end