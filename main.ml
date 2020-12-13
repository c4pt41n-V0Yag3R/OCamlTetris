



(* This is the knuth shuffle algorithm, and the code was adapted
   from code on the OCaml discussion board: 
   https://discuss.ocaml.org/t/more-natural-preferred-way-to-shuffle-an-array/217 *)
let generate_new_bag shapes =
  Random.self_init ();
  let n = Array.length shapes in
  let sh = Array.copy shapes in 
  for i = n - 1 downto 1 do 
    let k = Random.int (i + 1) in 
    let x = sh.(k) in 
    sh.(k) <- sh.(i);
    sh.(i) <- x
  done;
  sh

let generate_shape shape_type = 
  let x = Tilearray.x_dim/2 - 1 in
  let y = Tilearray.y_dim - 3 in
  let coords = 
    if shape_type = 'I' 
    then (x + 1, y + 1)
    else if shape_type = 'O'
    then (x, y + 1)
    else (x, y) in
  Shapes.make_shape shape_type coords 0



let shape_options = [|'I'; 'J'; 'L'; 'T'; 'Z'; 'S'; 'O'|]
let bag_ref = ref (0, (generate_new_bag shape_options))

let shape_ref = ref (generate_shape 'I')
let next_shape_ref = ref (generate_shape (snd !bag_ref).(fst !bag_ref))



let erase_previous previous_shape = 
  match previous_shape with
  | None -> ()
  | Some shape -> 
    shape |> Board.erase_shape;
    shape |> Shapes.shape_shadow |> Board.erase_shape

let draw_shape previous_shape current_shape = 
  erase_previous previous_shape;
  current_shape |> Shapes.shape_shadow |> Board.display_shadow;
  current_shape |> Board.display_shape


let rec move_shape key_press key_array = 
  let current_shape = !shape_ref in
  let next_shape = 
    match key_press with 
    | lk when lk = key_array.(0) -> Shapes.move_l current_shape
    | rk when rk = key_array.(1) -> Shapes.move_r current_shape
    | rot_lk when rot_lk = key_array.(2) -> Shapes.rotate_l current_shape
    | rot_rk when rot_rk = key_array.(3) -> Shapes.rotate_r current_shape
    | fk when fk = key_array.(4) -> Shapes.fall current_shape
    | ' ' -> Shapes.fall current_shape
    | _ -> current_shape
  in draw_shape (Some current_shape) next_shape;
  shape_ref := next_shape;
  if key_press = ' '
  then move_shape ' ' key_array
  else ()

let fall_shape _ = 
  let current_shape = !shape_ref in
  let next_shape = Shapes.fall current_shape in
  draw_shape (Some current_shape) next_shape;
  shape_ref := next_shape;
  ignore (Unix.alarm 1)

let new_falling_shape () = 
  ignore (Sys.signal Sys.sigalrm (Sys.Signal_handle fall_shape));
  ignore (Unix.alarm 1);
  shape_ref := !next_shape_ref;
  draw_shape None !shape_ref;

  Board.erase_last_next_shape !next_shape_ref;

  if fst !bag_ref >= Array.length shape_options - 1 
  then bag_ref := (0, (generate_new_bag shape_options))
  else bag_ref := (fst !bag_ref + 1, snd !bag_ref);

  next_shape_ref := generate_shape (snd !bag_ref).(fst !bag_ref);
  Board.display_next_shape !next_shape_ref





let rec get_tile_ys acc = function
  | [] -> acc
  | tile :: t -> get_tile_ys (Tile.get_y tile :: acc) t

let get_ys shape = get_tile_ys [] (Shapes.get_tiles shape)


let redraw_tiles () = 
  for ind = 0 to (Tilearray.y_dim * Tilearray.x_dim) - 1 do
    let entry = Tilearray.tile_array.(ind) in 
    match entry with
    | None -> 
      let x = ind mod Tilearray.x_dim in 
      let y = (ind - x)/Tilearray.x_dim in 
      Board.erase_coords x y
    | Some tile -> Board.display_tile tile true (Tile.get_color tile)
  done



let rec main () = 
  try
    new_falling_shape ();
    while true do
      try
        let k = Graphics.read_key () in
        move_shape k !Board.key_array
      with 
      | Shapes.DoneFalling -> 
        let ys = get_ys !shape_ref in
        Tilearray.delete_rows ys;
        redraw_tiles ();
        Board.display_score !Tilearray.score;
        Board.display_high_scores (Array.to_list Tilearray.high_scores);
        Board.display_controls Board.key_array;
        Board.display_next_shape_words ();
        new_falling_shape ();
      | Tilearray.End -> raise Tilearray.End
    done
  with
  | Tilearray.End | Shapes.DoneFalling -> 
    wait_for_restart ()

and wait_for_restart () = 
  try
    Board.display_game_over_screen !Tilearray.score Tilearray.high_scores.(0);
    let k = Graphics.read_key () in
    if k = !Board.key_array.(5) then 
      begin
        Board.refresh ();
        Tilearray.update_high_score !Tilearray.score;
        Tilearray.score := 0;
        Board.display_score !Tilearray.score;
        Board.display_high_scores (Array.to_list Tilearray.high_scores);
        Board.display_controls Board.key_array;
        Board.display_next_shape_words ();
        Tilearray.clear ();
        main ()
      end
    else wait_for_restart ()
  with Tilearray.End -> wait_for_restart ()

let start () = 
  ANSITerminal.(print_string [red] "\n\nWelcome to Tetris for OCaml! ");
  Board.set_settings ();
  Board.display_welcome_screen ();
  ignore (Graphics.read_key ());
  Board.setup_board ();
  Board.display_score !Tilearray.score;
  Board.display_high_scores (Array.to_list Tilearray.high_scores);
  Board.display_controls Board.key_array;
  Board.display_next_shape_words ();
  main () 




let pause () = ()