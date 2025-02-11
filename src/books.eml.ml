module type DB = Caqti_lwt.CONNECTION
module R = Caqti_request
module T = Caqti_type

let list_comments =
  let query =
    let open Caqti_request.Infix in
    (T.unit ->* T.(t2 int string))
    "SELECT id, text FROM comment" in
  fun (module Db : DB) ->
    let%lwt comments_or_error = Db.collect_list query () in
    Caqti_lwt.or_fail comments_or_error

let add_comment =
  let query =
    let open Caqti_request.Infix in
    (T.string ->. T.unit)
    "INSERT INTO comment (text) VALUES ($1)" in
  fun text (module Db : DB) ->
    let%lwt unit_or_error = Db.exec query text in
    Caqti_lwt.or_fail unit_or_error

let list_users =
  let query =
    let open Caqti_request.Infix in
    (T.unit ->* T.(t2 int string))
    "SELECT id, name FROM users" in
  fun (module Db : DB) ->
    let%lwt users = Db.collect_list query () in
    Caqti_lwt.or_fail users

let render users comments request =
  <html>
  <body>

    <h2>Users</h2>
    <ul>
%     users |> List.iter (fun (id, name) ->
        <li>(<%s string_of_int id %>) <%s name %></li><% ); %>
    </ul>

    <h2>Comments</h2>
    <ul>
%     comments |> List.iter (fun (_id, comment) ->
        <li><%s comment %></li><% ); %>
    </ul>

    <form method="POST" action="/">
      <%s! Dream.csrf_tag request %>
      <input name="text" autofocus>
    </form>

  </body>
  </html>

let () =
  Dream.run ~interface:"0.0.0.0"
  @@ Dream.logger
  @@ Dream.sql_pool "postgresql://postgres:password@postgres/books"
  @@ Dream.sql_sessions
  @@ Dream.router [

    Dream.get "/" (fun request ->
      let%lwt users = Dream.sql request list_users in
      let%lwt comments = Dream.sql request list_comments in
      Dream.html (render users comments request));

    Dream.post "/" (fun request ->
      match%lwt Dream.form request with
      | `Ok ["text", text] ->
        let%lwt () = Dream.sql request (add_comment text) in
        Dream.redirect request "/"
      | _ ->
        Dream.empty `Bad_Request);

  ]
