module type DB = Caqti_lwt.CONNECTION
module R = Caqti_request
module T = Caqti_type

let list_users =
  let query =
    let open Caqti_request.Infix in
    (T.unit ->* T.(t2 int string))
    "SELECT id, name FROM users" in
  fun (module Db : DB) ->
    let%lwt users = Db.collect_list query () in
    Caqti_lwt.or_fail users

let add_user =
  let query =
    let open Caqti_request.Infix in
    (T.(t2 string string) ->. T.unit)
    "INSERT INTO users (name, password_digest) VALUES ($1, $2)" in
  fun name password (module Db : DB) ->
    let password_digest = Bcrypt.hash password |> Bcrypt.string_of_hash in
    let%lwt unit_or_error = Db.exec query (name, password_digest) in
    Caqti_lwt.or_fail unit_or_error

let render users request =
  <html>
  <body>

    <h2>Users</h2>
    <ul>
%     users |> List.iter (fun (id, name) ->
        <li>(<%s string_of_int id %>) <%s name %></li><% ); %>
    </ul>

    <form method="POST" action="/users">
      <%s! Dream.csrf_tag request %>
      <label for="name">Name:</label>
      <input id="name" name="name">
      <label for="password">Password:</label>
      <input id="password" type="password" name="password">
      <button>Add user</button>
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
      Dream.html (render users request));

    Dream.post "/users" (fun request ->
      match%lwt Dream.form request with
      | `Ok ["name", name; "password", password] ->
        let%lwt () = Dream.sql request (add_user name password) in
        Dream.redirect request "/"
      | _ ->
        Dream.empty `Bad_Request);

  ]
