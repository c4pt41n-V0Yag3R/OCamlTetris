(** [scale] is the length of each tile in pixels. *)
let scale = Tile.tile_length

(** [left_offset] defines the width between the left side of the window and 
    left side of the board *)
let left_offset = 150

(** [bottom_offset] defines the height between the bottom of the window and 
    bottom of the board *)
let bottom_offset = 70

(** [right_offset] defines the width between the right side of the board and 
    right side of the window *)
let right_offset = 200

(** [top_offset] defines the height between the top of the board and the 
    top of the window *)
let top_offset = 70

(** [x_dim] is the width of the tetris board *)
let x_dim = Tilearray.x_dim

(** [y_dim] is the height of the tetris board *)
let y_dim = Tilearray.y_dim

(** [outline_width] is the width of the line drawing the outline of the board. 
    In order for coordinates to work out perfectly in edge tiles 
    [outline_width] should be an even number.*)
let outline_width = 4

(** [gridline_width] is the width of the line drawing the inside grid of 
    the board *)
let gridline_width = 1



(** [lower ()] is the y coordinate in pixels of the lower boundary
    of the game board *)
let lower () = bottom_offset

(** [upper ()] is the y coordinate in pixels of the upper boundary
    of the game board *)
let upper () = lower () + y_dim * scale + 
               (y_dim - 1) * gridline_width + outline_width

(** [left ()] is the x coordinate in pixels of the left boundary
    of the game board *)
let left () = left_offset

(** [right ()] is the x coordinate in pixels of the right boundary
    of the game board *)
let right () = left () + x_dim * scale + 
               (x_dim - 1) * gridline_width + outline_width

(** [width ()] is the width in pixels of the game board *)
let width () = right () + right_offset

(** [height ()] is the height in pixels of the game board *)
let height () = upper () + top_offset




(* The array of keys to use to carry out different actions. *)
let key_array = ref [|'f'; 'h'; 't'; 'g'; 'b'|]

(* The actions carried out by each key. *)
let ctl_array = ref [|"Move Left"; "Move Right"; "Rotate CW"; 
                      "Rotate CCW"; "Fall Faster"|]


(* used for printing current settings in key array *)
let pp_array pp_elt arr =
  let pp_elts arr =
    let rec loop n acc = function
      | [] -> acc
      | [h] -> acc ^ pp_elt h
      | h1 :: (h2 :: t as t') ->
        if n = 100 then acc ^ "..."  (* stop printing long list *)
        else loop (n + 1) (acc ^ (pp_elt h1) ^ "; ") t'
    in loop 0 "" arr
  in "[|" ^ pp_elts (Array.to_list arr) ^ "|]"


let set_settings () = 
  let explode str =
    let rec exp a b =
      if a < 0 then b
      else exp (a - 1) (str.[a] :: b)
    in
    (exp (String.length str - 1) []) |> Array.of_list in

  let rec do_key_settings kmode () = 
    ANSITerminal.(print_string [white] 
                    ("Your current keybinds are " ^ kmode ^".\n
                    Do you want to change?\n> "));
    try begin
      match read_line () with
      | "Yes" |"y" | "Y" | "yes" -> begin
          ANSITerminal.(print_string [white] 
                          ("Choose the keys you would like for \
                            Left, Right, Rotate CCW, Rotate CW, \
                            Fall Faster:\n
                        1. adwsx\n
                        2. jlik,\n
                        3. fhtgb\n>"));
          match read_int () with
          | 1 -> key_array := "adwsx" |> explode
          | 2 -> key_array := "jlik," |> explode
          | 3 -> key_array := "fhtgb" |> explode
          | _ -> ANSITerminal.(print_string [blue] "invalid input\n"); 
            do_key_settings (pp_array (fun x -> Char.escaped x) !key_array) ()
        end; ()
      | "No"  |"n" | "N" | "no" -> ()
      | _ -> ANSITerminal.(print_string [blue] "invalid input\n"); 
    end with
    |_ ->ANSITerminal.(print_string [blue] "invalid input\n");
      do_key_settings (pp_array (fun x -> Char.escaped x) !key_array) ()  in
  do_key_settings (pp_array (fun x -> Char.escaped x) !key_array) ();

  let rec set_colorblind_mode cb () = 
    ANSITerminal.(print_string [white] ("Are you colorblind? (Yes/No)\n> "));
    match read_line () with 
    | "Yes" | "Y" | "yes" |"y" -> begin
        ANSITerminal.(print_string [white] 
                        ("Do you know your specific colorblind subtype?\n
                        1. Yes, Deuteranopia (most common)\n
                        2. Yes, Protanopia\n
                        3. Yes, Tritanopia\n
                        4. Yes, Monochromacy\n
                        5. No\n>"));
        match read_int () with
        | 1 -> Shapes.colorblind := 1; ()
        | 2 -> Shapes.colorblind := 2; ()
        | 3 -> Shapes.colorblind := 3; ()
        | 4 -> Shapes.colorblind := 4; ()
        | 5 -> Shapes.colorblind := 5; ()
        | _ -> ANSITerminal.(print_string [blue] "invalid input\n");
          set_colorblind_mode cb () 
      end
    | "No" |"N" | "no" | "n" -> begin
        ANSITerminal.(print_string [white] 
                        ("Do you want to play Tetris in black and \ 
                        white mode? (Yes/No) \n>"));
        match read_line () with
        | "Yes" | "Y" | "y" | "yes" -> Shapes.colorblind := 4; ()
        | "No" | "N" | "n" | "no" -> Shapes.colorblind := 0; ()
        | _ -> ANSITerminal.(print_string [blue] "invalid input\n");
          set_colorblind_mode cb () 
      end
    | _ -> ANSITerminal.(print_string [blue] "invalid input\n");
      set_colorblind_mode cb () in 
  set_colorblind_mode false ()


(** [setup_board ()] opens a Graphics window and draws the board outline for 
    Tetris. The board is [x_dim] x [y_dim] blocks where each block is a square 
    with width and height both equal to [scale] pixels.*)
let setup_board () = 
  (* Draws the board outline *)
  let lower = lower () in 
  let upper = upper () in 
  let left = left () in
  let right = right () in

  Graphics.clear_graph ();
  Graphics.set_color (Graphics.rgb 0 0 0);
  Graphics.set_line_width outline_width;
  Graphics.moveto left lower;
  Graphics.lineto right lower;
  Graphics.lineto right upper;
  Graphics.lineto left upper;
  Graphics.lineto left lower;
  (* Draws the board grid *)
  Graphics.set_line_width gridline_width;
  for i = 1 to x_dim - 1 do 
    let x = left + i * (scale + gridline_width) + outline_width / 2 in
    Graphics.moveto x lower;
    Graphics.lineto x upper
  done;
  for i = 1 to y_dim - 1 do 
    let y = lower + i * (scale + gridline_width) + outline_width / 2 in
    Graphics.moveto left y;
    Graphics.lineto right y
  done


let refresh () = 
  Graphics.clear_graph (); 
  setup_board ()





let display_welcome_screen () = 
  let width = width () in
  let height = height () in 

  " " ^ (string_of_int width) ^ "x" ^ (string_of_int height) 
  |> Graphics.open_graph;
  Graphics.set_window_title "Tetris";
  Graphics.set_color (Graphics.rgb 0 0 0);

  Graphics.moveto (width / 2 - 55) ((height * 2) / 3);
  Graphics.draw_string "Welcome to Tetris";
  Graphics.moveto (width / 2 - 70) ((height * 2) / 3 - 30);
  Graphics.draw_string "Press any key to begin"


let display_game_over_screen score high_score = 
  let width = width () in
  let height = height () in 

  Graphics.clear_graph ();
  Graphics.set_color (Graphics.rgb 0 0 0);

  Graphics.moveto (width / 2 - 30) ((height * 2) / 3);
  Graphics.draw_string "Game Over!";
  Graphics.moveto (width / 2 - 90) ((height * 2) / 3 - 30);
  Graphics.draw_string ("Press 'r' to play another round");
  Graphics.moveto (width / 2 - 80) ((height * 2) / 3 - 60);
  Graphics.draw_string ("Press 'q' to quit the game");
  if score > high_score
  then begin
    Graphics.moveto (width / 2 - 48) ((height * 2) / 3 - 100);  
    Graphics.draw_string "New high score!";
    Graphics.moveto (width / 2 - 45) ((height * 2) / 3 - 130)
  end
  else 
    Graphics.moveto (width / 2 - 45) ((height * 2) / 3 - 100); 
  Graphics.draw_string ("Your score: " ^ string_of_int score)


let display_controls () =
  Graphics.set_color 0;
  Graphics.moveto (left_offset / 5) (y_dim * scale / 2);
  Graphics.draw_string ("Controls: ");
  for i = 0 to Array.length !ctl_array - 1 do 
    Graphics.moveto (left_offset / 5) ((y_dim * scale / 2) - (i + 1) * 20);
    Graphics.draw_string (!ctl_array.(i) ^ ": " 
                          ^ Char.escaped (!key_array.(i)))
  done;
  Graphics.moveto (left_offset / 5) 
    ((y_dim * scale / 2) - (Array.length !ctl_array + 1) * 20);
  Graphics.draw_string "Press ' ' to drop";
  Graphics.moveto (left_offset / 5) 
    ((y_dim * scale / 2) - (Array.length !ctl_array + 2) * 20);
  Graphics.draw_string "Press 'p' to pause"


let display_score score = 
  Graphics.set_color (Graphics.rgb 255 255 255);
  Graphics.fill_rect 0 bottom_offset 
    (left_offset - outline_width) (y_dim * scale + top_offset);
  Graphics.set_color 0;
  Graphics.moveto (left_offset / 5) (bottom_offset + y_dim * scale);
  Graphics.draw_string ("Score: " ^ string_of_int score)


let display_high_scores scores = 
  Graphics.set_color 0;
  Graphics.moveto (left_offset / 5) (y_dim * scale);
  Graphics.draw_string "High Score Board";
  for i = 0 to List.length scores - 1 do 
    Graphics.moveto (left_offset / 5) (y_dim * scale - (i + 1) * 20);
    Graphics.draw_string (string_of_int (i + 1) ^ ". " 
                          ^ string_of_int (List.nth scores i))
  done





(* functions for displaying different assets of the game *)

let draw_square bevel color tile_x tile_y = 
  let x = left_offset + tile_x * scale + 
          (tile_x + 1) * gridline_width  + outline_width / 2 in
  let y = bottom_offset + tile_y * scale + 
          (tile_y + 1) * gridline_width + outline_width / 2 in
  Graphics.set_color color;
  let fit_scale = scale - gridline_width in
  Graphics.fill_rect x y fit_scale fit_scale;
  if bevel
  then 
    let inner_scale = fit_scale - 10 in 
    let inner_x = x + 5 in
    let inner_y = y + 5 in 
    (* sides *)
    Graphics.set_color (color * 2);
    Graphics.fill_poly [|(x, y); 
                         (inner_x, inner_y); 
                         (inner_x, inner_y + inner_scale); 
                         (x, y + fit_scale)|];
    Graphics.fill_poly [|(x + fit_scale, y); 
                         (inner_x + inner_scale, inner_y); 
                         (inner_x + inner_scale, inner_y + inner_scale); 
                         (x + fit_scale, y + fit_scale)|];
    (* bottom *)
    Graphics.set_color (color * 7);
    Graphics.fill_poly [|(x, y); 
                         (x + fit_scale, y); 
                         (inner_x + inner_scale, inner_y);
                         (inner_x, inner_y)|];
    (* top *)
    Graphics.set_color (color * 3);
    Graphics.fill_poly [|(x, y + fit_scale); 
                         (x + fit_scale, y + fit_scale); 
                         (inner_x + inner_scale, inner_y + inner_scale);
                         (inner_x, inner_y + inner_scale)|]
  else ()


let display_tile tile bevel color = 
  let x = Tile.get_x tile in
  let y = Tile.get_y tile in
  draw_square bevel color x y 


let erase_coords x y = 
  draw_square false (Graphics.rgb 255 255 255) x y 


let erase_tile tile = 
  let x = Tile.get_x tile in
  let y = Tile.get_y tile in
  erase_coords x y





let rec display_each_tile shadow = function
  | [] -> ()
  | tile::t -> 
    if shadow 
    then display_tile tile false (Graphics.rgb 200 200 200)
    else display_tile tile true (Tile.get_color tile); 
    display_each_tile shadow t

let rec erase_each_tile = function
  | [] -> ()
  | tile::t -> erase_tile tile; erase_each_tile t

let display_shape shape = 
  shape 
  |> Shapes.get_tiles 
  |> display_each_tile false

let display_shadow shape = 
  shape 
  |> Shapes.get_tiles 
  |> display_each_tile true

let erase_shape shape = 
  shape 
  |> Shapes.get_tiles 
  |> erase_each_tile


let display_holding () = 
  Graphics.set_color 0;
  Graphics.moveto (right () + scale) (lower () + (y_dim-4) * scale);
  Graphics.draw_string "Holding:"

let display_next_shape_words () = 
  Graphics.set_color 0;
  Graphics.moveto (right () + scale) (lower () + y_dim * scale);
  Graphics.draw_string "The next shape will be:"

let rec shift_tiles_off_board acc = function
  | [] -> acc
  | tile :: t -> 
    let new_x = Tile.get_x tile + x_dim / 2 + 3 in
    let new_y = Tile.get_y tile - 1 in
    let new_tile = Tile.move_to tile new_x new_y in 
    shift_tiles_off_board (new_tile :: acc) t

let display_next_shape shape = 
  shape
  |> Shapes.get_tiles
  |> shift_tiles_off_board []
  |> display_each_tile false

let erase_last_next_shape shape = 
  shape
  |> Shapes.get_tiles
  |> shift_tiles_off_board []
  |> erase_each_tile







(*


  let check_if_fallen shape =
  let tile_list = Shapes.get_tiles shape in
  let rec helper_check = function
    | [] -> false
    | h :: t -> begin
        match (Tile.get_x h, Tile.get_y h) with
        | (x, 1) -> true
        | (x, y) -> helper_check t
      end
  in helper_check tile_list

  let rec full_row row sum =
  match row with
  | [] -> sum
  | h::t -> begin
      match h with 
      | None -> full_row t sum
      | Some h -> full_row t sum + 1
    end


  (** [check_rows board] checks each row in [board] to see if any are full.
    Returns a list of ints representing the indices at which the rows are 
    full. *)
  let check_rows board =
  let rows = ref [] in
  for y = 0 to y_dim - 1 do
    let row = board.(y) in
    let sum = full_row row 0 in
    match sum with
    | x_dim -> rows := y :: !rows
  done;
  !rows

*)
