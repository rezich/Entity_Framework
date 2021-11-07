WINDOW_WIDTH : s32 : 640;
WINDOW_HEIGHT : s32 : 480;
WINDOW_TITLE :: "Example game";

TARGET_FPS :: 60;

C_BACKGROUND  : Vector4 : .{0.6875,0.765625,0.8671875,1};

app: struct {
    window: Window_Creation.Window_Type;
}

game: struct {
    player: Handle(Player);
    score: int;
}

assets: struct {
    font: *Simp.Dynamic_Font;
}

time: struct {
    last_time: float64;
    elapsed_time: float64;
    fps := 0;
    fps_time := 0.0;
    fps_string: string;
}

init_game :: () {
    x, y: s32;
    #if OS == .WINDOWS {
        Windows :: #import "Windows";
        using Windows;
        x = GetSystemMetrics(SM_CXSCREEN)/2 - WINDOW_WIDTH/2;
        y = GetSystemMetrics(SM_CYSCREEN)/2 - WINDOW_HEIGHT/2;
    }
    app.window = Window_Creation.create_window(window_name=WINDOW_TITLE, width=WINDOW_WIDTH, height=WINDOW_HEIGHT, window_x=x, window_y=y);
    Simp.simp_init(app.window, WINDOW_WIDTH, WINDOW_HEIGHT, xx WINDOW_WIDTH, xx WINDOW_HEIGHT);
    set_working_directory(String.path_strip_filename(System.get_path_of_running_executable()));
    assets.font = Simp.get_font_at_size("./", "type_writer.ttf", 8);
    reset_game();
}

reset_game :: () {
    reset_entity_storage();
    random_seed(xx get_time());
    game = .{};

    {p: Player; p.position=xy(100,100); game.player=spawn(p);}

    {b: Block; b.position=xy(200,200); spawn(b);}
    {b: Block; b.position=xy(250,210); spawn(b);}
    {b: Block; b.position=xy(140, 80); spawn(b);}
    {b: Block; b.position=xy(300,100); spawn(b);}
}

main :: () {
    init_game();

    quitting := false;
    while !quitting if do_frame() == {
        case .RESET; reset_game();
        case .QUIT; quitting = true;
    }

    do_frame :: () -> Frame_Result {
        reset_temporary_storage();
        using time;
        dt: float;
        now := get_time();
        if last_time then dt = cast(float) (now - last_time);
        last_time = now;
        elapsed_time += dt;
        fps_time += dt;

        TICK_PERIOD : float64 : 1.0 / xx TARGET_FPS;
        need_to_render := false;

        while elapsed_time >= TICK_PERIOD {
            elapsed_time -= TICK_PERIOD;
            need_to_render = true;
            update_window_events();
            for events_this_frame if it.type == {
                case .QUIT; return .QUIT;
                case .KEYBOARD; if it.key_pressed then if it.key_code == {
                    case .F5; return .RESET;
                    case .ESCAPE; return .QUIT;
                }
            }
            simulate(xx TICK_PERIOD);
            cleanup_despawning_entities();
        }

        if fps_time >= 1.0 {
            free(fps_string);
            fps_string = sprint("FPS:  %", fps);
            fps_time -= 1.0;
            fps = 0;
        }

        if need_to_render {
            fps += 1;
            present();
            Simp.swap_buffers(app.window);
        }

        return .CONTINUE;
    }

    Frame_Result :: enum {
        CONTINUE;
        RESET;
        QUIT;
    }
}

simulate :: (dt: float) {
    using context.entity_storage;
    for _Player simulate(it, dt);
    for _Bullet simulate(it, dt);
    for _Block  simulate(it, dt);
    for _Coin   simulate(it, dt);
}

present :: () {
    Simp.update_window(app.window, WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT);
    Simp.clear_render_target(C_BACKGROUND.x, C_BACKGROUND.y, C_BACKGROUND.z, C_BACKGROUND.w);

    using context.entity_storage;
    for _Block  present(it);
    for _Coin   present(it);
    for _Bullet present(it);
    for _Player present(it);

    draw_text_outlined(4, 4, time.fps_string);
    draw_text_outlined(4, 20, tprint("Bullets:  %", _Bullet.storage.count));
    draw_text_outlined(4, 36, tprint("Score:  %", game.score));
}

Entity :: struct {
    using entity_base: Entity_Base;
    position: Vector2;
    position_previous: Vector2;
    velocity: Vector2;
    size: int;
}

simulate_entity :: (using entity: *$T/Entity, dt: float) {
    position += velocity * dt;
    position_previous = position;
}

draw_text_outlined :: (x: s64, y: s64, text: string, color := Vector4.{1,1,1,1}, background := Vector4.{0,0,0,1}, effect_flags: Simp.Font_Effects = 0) {
    OFFSETS :: s64.[-1, -1, -1, 0, 1, 1, 1, 0];
    for OFFSETS Simp.draw_text(assets.font, x+it, y+OFFSETS[(it_index + 2) % OFFSETS.count], text, background, effect_flags);
    Simp.draw_text(assets.font, x, y, text, color, effect_flags);
}

#import "Basic";
#import "Math";
#import "Entity_Storage";
#import "Input";
#import "Random";

           Simp :: #import "Simp";
Window_Creation :: #import "Window_Creation";
         System :: #import "System";
         String :: #import "String";
