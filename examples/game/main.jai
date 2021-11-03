Entity :: struct {
    using entity_base: Entity_Base;
    position: Vector2;
    velocity: Vector2;
}

WINDOW_WIDTH : s32 : 640;
WINDOW_HEIGHT : s32 : 480;
WINDOW_TITLE :: "Example game";

TARGET_FPS :: 60;

C_BACKGROUND  : Vector4 : .{0.6875,0.765625,0.8671875,1};

game: struct {
    window: Window_Creation.Window_Type;
    should_quit := false;
    last_time: float64;
    elapsed_time: float64;
    fps := 0;
    fps_time := 0.0;
    fps_string: string;
    player: Handle(Player);
}

init_game :: () {
    //TODO: make OS-agnostic
    using Windows;
    x := GetSystemMetrics(SM_CXSCREEN) / 2 - WINDOW_WIDTH / 2;
    y := GetSystemMetrics(SM_CYSCREEN) / 2 - WINDOW_HEIGHT / 2;
    game.window = Window_Creation.create_window(window_name=WINDOW_TITLE, width=WINDOW_WIDTH, height=WINDOW_HEIGHT, window_x=x, window_y=y);
    Simp.simp_init(game.window, WINDOW_WIDTH, WINDOW_HEIGHT, xx WINDOW_WIDTH, xx WINDOW_HEIGHT);

    {p: Player; p.position=xy(100, 100); game.player=spawn(p); }
}

main :: () {
    init_game();

    while true {
        reset_temporary_storage();
        cleanup_despawning_entities();
        if game.should_quit break;
        if do_frame() {
            Simp.swap_buffers(game.window);
            update_window_events();
        }
    }
}

do_frame :: () -> did_render_Frame: bool {
    //handle_input_events();

    dt: float;
    now := get_time();
    if game.last_time dt = cast(float) (now - game.last_time);
    game.last_time = now;

    game.elapsed_time += dt;
    game.fps_time += dt;

    TICK_PERIOD : float64 : 1.0 / xx TARGET_FPS;
    need_to_render := false;
    while game.elapsed_time >= TICK_PERIOD {
        game.elapsed_time -= TICK_PERIOD;
        need_to_render = true;
        simulate(xx TICK_PERIOD);
    }
    if need_to_render {
        game.fps += 1;
        present();
    }
    if game.fps_time >= 1.0 {
        free(game.fps_string);
        game.fps_string = sprint("FPS: %", game.fps);
        game.fps_time -= 1.0;
        game.fps = 0;
    }
    return need_to_render;
}

simulate :: (dt: float) {
    using context.entity_storage;
    for _Player simulate(it, dt);
    for _Block  simulate(it, dt);
    for _Coin   simulate(it, dt);
}

present :: () {
    Simp.update_window(game.window, WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT);
    Simp.clear_render_target(C_BACKGROUND.x, C_BACKGROUND.y, C_BACKGROUND.z, C_BACKGROUND.w);

    using context.entity_storage;
    for _Block  present(it);
    for _Coin   present(it);
    for _Player present(it);
}

#import "Basic";
#import "Math";
#import "Entity_Storage";
#import "Input";

           Simp :: #import "Simp";
Window_Creation :: #import "Window_Creation";
        Windows :: #import "Windows";
