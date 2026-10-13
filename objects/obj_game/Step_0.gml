var frame_seconds=clamp(delta_time/1000000,0,0.1);
var frame_units=frame_seconds*60;
t+=frame_units;
scene_age+=frame_units;
scene_fade=max(0,scene_fade-0.05*frame_units);
for(var k=0;k<15;k++) menu_glow[k]=lerp(menu_glow[k],menu_index==k?1:0,1-power(0.78,frame_units));
if(scene_fade>0) exit;
if(surface_exists(scene_surface)) { surface_free(scene_surface); scene_surface=-1; }
if(state=="username") {
    name_entry=clean_name(keyboard_string);
    keyboard_string=name_entry;
    var clicked=mouse_check_button_pressed(mb_left) && mouse_x>=100 && mouse_x<=650 && mouse_y>=menu_top() && mouse_y<=menu_top()+50;
    if(keyboard_check_pressed(vk_enter) || clicked) {
        while(string_length(name_entry)>0 && string_char_at(name_entry,string_length(name_entry))==" ") name_entry=string_delete(name_entry,string_length(name_entry),1);
        if(name_entry=="") name_message="Please enter a non-empty name.";
        else { player_name=name_entry; keyboard_string=""; change_scene("title",false,0); }
    }
    exit;
}
if (input_pressed(12) && (state == "dead" || state == "win")) { start_run(); exit; }
if (state == "play" && !paused && input_pressed(7)) { change_scene("play",true,0); exit; }
if (state == "play" && paused && keyboard_check_pressed(vk_escape)) { change_scene("play",false,0); exit; }
if (state != "play" || paused) {
    if(state=="bindings" && rebind_slot>=0) {
        if(keyboard_check_pressed(vk_escape)) { rebind_slot=-1; binding_message="Cancelled. Binding unchanged."; exit; }
        // Wait for the activation key to release before capturing the next press.
        if(rebind_release) { if(!keyboard_check(vk_anykey)) rebind_release=false; exit; }
        for(var new_key=8;new_key<=255;new_key++) {
            if(!keyboard_check_pressed(new_key)) continue;
            var old_key=bindings[rebind_slot];
            for(var k=0;k<13;k++) {
                if(k!=rebind_slot && bindings[k]==new_key) bindings[k]=old_key;
            }
            bindings[rebind_slot]=new_key;
            binding_message=binding_names[rebind_slot]+" = "+key_label(new_key);
            save_bindings(); rebind_slot=-1; break;
        }
        exit;
    }
    var items=menu_buttons();
    if(keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) menu_index=(menu_index+1)%array_length(items);
    if(keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) menu_index=(menu_index+array_length(items)-1)%array_length(items);
    var top=menu_top(), spacing=menu_spacing(), height=state=="bindings"?26:50;
    var hovered=-1;
    for(var k=0;k<array_length(items);k++) {
        var row_y=top+k*spacing+button_offset(k);
        if(mouse_x>=100 && mouse_x<=650 && mouse_y>=row_y && mouse_y<=row_y+height) hovered=k;
    }
    if(hovered>=0 && (mouse_x!=menu_mouse_x || mouse_y!=menu_mouse_y)) menu_index=hovered;
    menu_mouse_x=mouse_x; menu_mouse_y=mouse_y;
    var confirm=keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space);
    if(mouse_check_button_pressed(mb_left) && hovered>=0) { menu_index=hovered; confirm=true; }
    if(state=="controls" && keyboard_check_pressed(vk_escape)) confirm=true;
    if(state=="leaderboard" && keyboard_check_pressed(vk_escape)) confirm=true;
    if(state=="bindings" && keyboard_check_pressed(vk_escape)) { menu_index=14; confirm=true; }
    if(state=="options" && keyboard_check_pressed(vk_escape)) { menu_index=4; confirm=true; }
    var setting_direction=keyboard_check_pressed(vk_right)-keyboard_check_pressed(vk_left);
    if(state=="options" && setting_direction!=0 && (menu_index==1 || menu_index==2)) confirm=true;
    if(state=="reset_score" && keyboard_check_pressed(vk_escape)) { menu_index=0; confirm=true; }
    if(confirm) {
        var action=items[menu_index];
        if(state=="shop" && menu_index<5) { shop_buy(menu_index); exit; }
        if(state=="bindings" && menu_index<13) { rebind_slot=menu_index; rebind_release=true; exit; }
        if(action=="START RUN" || action=="PLAY AGAIN") start_run();
        else if(action=="RESUME") change_scene("play",false,0);
        else if(action=="HOW TO PLAY") { menu_previous=state; change_scene("controls",paused,0); }
        else if(action=="OPTIONS") { options_previous=state; change_scene("options",paused,0); }
        else if(action=="LEADERBOARD") { leaderboard_previous=state; change_scene("leaderboard",paused,0); }
        else if(action=="KEY BINDINGS") change_scene("bindings",paused,0);
        else if(action=="FRAME RATE") {
            fps_index=(fps_index+array_length(fps_choices)+(setting_direction<0?-1:1)) mod array_length(fps_choices);
            apply_display();
        }
        else if(action=="V SYNC") { vsync_enabled=!vsync_enabled; apply_display(); }
        else if(action=="NEXT SECTOR") { wave_gap=90; change_scene("play",false,0); }
        else if(action=="RESET BEST SCORE") change_scene("reset_score",paused,0);
        else if(action=="CANCEL") change_scene("options",paused,3);
        else if(action=="CONFIRM RESET") {
            best=0;
            ini_open("bullet_mania.ini"); ini_write_real("record","score",0); ini_close();
            options_message="Best score reset. A fresh record awaits.";
            change_scene("options",paused,3);
        }
        else if(action=="RESTORE DEFAULTS") {
            array_copy(bindings,0,binding_defaults,0,13); save_bindings(); binding_message="Default controls restored.";
        }
        else if(action=="BACK") {
            if(state=="leaderboard") change_scene(leaderboard_previous,paused,leaderboard_previous=="title"?3:1);
            else if(state=="bindings") change_scene("options",paused,0);
            else if(state=="options") change_scene(options_previous,paused,2);
            else change_scene(menu_previous,paused,1);
        }
        else if(action=="MAIN MENU") change_scene("title",false,0);
        else if(action=="QUIT GAME") game_end();
    }
    exit;
}
dash_requested=dash_requested || input_pressed(5);
pulse_requested=pulse_requested || input_pressed(6);
sim_accumulator+=frame_seconds;
while(sim_accumulator+0.000000001>=1/60) {
    sim_accumulator=max(0,sim_accumulator-1/60);
    simulate();
    if(state!="play" || paused) { sim_accumulator=0; break; }
}
