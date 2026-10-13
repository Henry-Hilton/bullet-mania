// All visuals are drawn with GameMaker primitives. No external assets.
randomize();
cyan = make_color_rgb(40, 240, 255);
pink = make_color_rgb(255, 55, 155);
gold = make_color_rgb(255, 210, 80);
violet = make_color_rgb(155, 90, 255);
bg = make_color_rgb(6, 8, 22);
state = "username";
player_name=""; name_entry=""; name_message="Enter a name to join the arcade.";
keyboard_string="";
leaderboard=[]; leaderboard_previous="title"; run_submitted=false;
clean_name = function(_text) {
    var result="";
    for(var k=1;k<=string_length(_text);k++) {
        var ch=string_upper(string_char_at(_text,k)), code=ord(ch);
        if((code>=65 && code<=90) || (code>=48 && code<=57) || ch==" " || ch=="_" || ch=="-") result+=ch;
        if(string_length(result)>=12) break;
    }
    while(string_length(result)>0 && string_char_at(result,1)==" ") result=string_delete(result,1,1);
    return result;
};
ini_open("bullet_mania_leaderboard.ini");
for(var k=0;k<10;k++) {
    var entry_name=clean_name(ini_read_string("entry"+string(k),"name",""));
    var entry_score=max(0,floor(ini_read_real("entry"+string(k),"score",0)));
    if(entry_name!="") array_push(leaderboard,{player:entry_name,points:entry_score,cleared:ini_read_real("entry"+string(k),"cleared",0)==1});
}
ini_close();
save_leaderboard = function() {
    ini_open("bullet_mania_leaderboard.ini");
    for(var k=0;k<10;k++) {
        var section="entry"+string(k);
        ini_section_delete(section);
        if(k<array_length(leaderboard)) {
            ini_write_string(section,"name",leaderboard[k].player);
            ini_write_real(section,"score",leaderboard[k].points);
            ini_write_real(section,"cleared",leaderboard[k].cleared?1:0);
        }
    }
    ini_close();
};
submit_score = function(_win) {
    if(run_submitted || player_name=="") return;
    run_submitted=true;
    var found=-1;
    for(var k=0;k<array_length(leaderboard);k++) if(leaderboard[k].player==player_name) found=k;
    var entry={player:player_name,points:score,cleared:_win};
    if(found<0) array_push(leaderboard,entry);
    else if(score>leaderboard[found].points || (score==leaderboard[found].points && _win)) leaderboard[found]=entry;
    // Stable descending order keeps earlier entries ahead on tied scores.
    for(var k=1;k<array_length(leaderboard);k++) {
        var j=k;
        while(j>0 && leaderboard[j].points>leaderboard[j-1].points) {
            var swap=leaderboard[j-1]; leaderboard[j-1]=leaderboard[j]; leaderboard[j]=swap; j--;
        }
    }
    if(array_length(leaderboard)>10) array_resize(leaderboard,10);
    save_leaderboard();
};
paused = false;
menu_index = 0;
menu_previous = "title";
options_previous = "title";
options_message = "Customize your controls and manage your record.";
fps_choices=[30,60,120,144,240]; fps_index=1; vsync_enabled=true;
ini_open("bullet_mania.ini");
var saved_fps=ini_read_real("display","fps",60);
for(var k=0;k<array_length(fps_choices);k++) if(fps_choices[k]==saved_fps) fps_index=k;
vsync_enabled=ini_read_real("display","vsync",1)==1;
ini_close();
apply_display = function() {
    game_set_speed(fps_choices[fps_index],gamespeed_fps);
    display_reset(0,vsync_enabled);
    ini_open("bullet_mania.ini");
    ini_write_real("display","fps",fps_choices[fps_index]);
    ini_write_real("display","vsync",vsync_enabled?1:0);
    ini_close();
};
apply_display();
sim_accumulator=0; sim_counter=0; dash_requested=false; pulse_requested=false;
menu_mouse_x = mouse_x;
menu_mouse_y = mouse_y;
binding_names=["MOVE UP","MOVE DOWN","MOVE LEFT","MOVE RIGHT","FOCUS","DASH","PULSE","PAUSE",
    "MOVE UP / ALT","MOVE DOWN / ALT","MOVE LEFT / ALT","MOVE RIGHT / ALT","RETRY RUN"];
binding_defaults=[ord("W"),ord("S"),ord("A"),ord("D"),vk_shift,vk_space,ord("X"),vk_escape,
    vk_up,vk_down,vk_left,vk_right,ord("R")];
bindings=array_create(13);
array_copy(bindings,0,binding_defaults,0,13);
rebind_slot=-1; rebind_release=false; binding_message="Select an action, then press a new key.";
ini_open("bullet_mania.ini");
var valid_bindings=true;
for(var k=0;k<13;k++) {
    bindings[k]=ini_read_real("keys",string(k),binding_defaults[k]);
    if(bindings[k]!=floor(bindings[k]) || bindings[k]<8 || bindings[k]>255) valid_bindings=false;
    for(var j=0;j<k;j++) if(bindings[k]==bindings[j]) valid_bindings=false;
}
ini_close();
if(!valid_bindings) array_copy(bindings,0,binding_defaults,0,13);
save_bindings = function() {
    ini_open("bullet_mania.ini");
    for(var k=0;k<13;k++) ini_write_real("keys",string(k),bindings[k]);
    ini_close();
};
key_label = function(_key) {
    if((_key>=48 && _key<=57) || (_key>=65 && _key<=90)) return chr(_key);
    if(_key>=112 && _key<=123) return "F"+string(_key-111);
    if(_key>=96 && _key<=105) return "NUM "+string(_key-96);
    switch(_key) {
        case vk_shift: return "SHIFT";
        case vk_control: return "CTRL";
        case vk_alt: return "ALT";
        case vk_space: return "SPACE";
        case vk_escape: return "ESC";
        case vk_enter: return "ENTER";
        case vk_tab: return "TAB";
        case vk_backspace: return "BACKSPACE";
        case vk_up: return "UP";
        case vk_down: return "DOWN";
        case vk_left: return "LEFT";
        case vk_right: return "RIGHT";
        case vk_home: return "HOME";
        case vk_end: return "END";
        case vk_delete: return "DELETE";
        case vk_insert: return "INSERT";
        case vk_pageup: return "PAGE UP";
        case vk_pagedown: return "PAGE DOWN";
    }
    return "KEY "+string(_key);
};
input_held = function(_action) {
    return keyboard_check(bindings[_action]) || (_action<4 && keyboard_check(bindings[_action+8]));
};
input_pressed = function(_action) { return keyboard_check_pressed(bindings[_action]); };
menu_top = function() { return state=="bindings"?222:((state=="controls" || state=="leaderboard" || state=="username")?610:(state=="shop"?306:(state=="options"?346:386))); };
menu_spacing = function() { return state=="bindings"?30:((state=="options" || state=="shop")?58:64); };
t = 0;
scene_age=0; scene_fade=1; scene_surface=-1;
menu_glow=array_create(15,0);
ship_bank=0; trails=[]; ripples=[];
change_scene = function(_state,_paused,_index) {
    if(surface_exists(scene_surface)) surface_free(scene_surface);
    scene_surface=-1;
    if(surface_exists(application_surface)) {
        scene_surface=surface_create(surface_get_width(application_surface),surface_get_height(application_surface));
        surface_copy(scene_surface,0,0,application_surface);
    }
    state=_state; paused=_paused; menu_index=_index;
    sim_accumulator=0; dash_requested=false; pulse_requested=false;
    scene_age=0; scene_fade=1; menu_glow=array_create(15,0);
};
transition_draw = function() {
    if(scene_fade>0) {
        var eased=scene_fade*scene_fade*(3-2*scene_fade);
        draw_set_alpha(eased);
        if(surface_exists(scene_surface)) draw_surface_stretched(scene_surface,0,0,1366,768);
        else { draw_set_color(bg); draw_rectangle(0,0,1366,768,false); }
        draw_set_alpha(1); draw_set_color(c_white);
    }
};
button_offset = function(_row) {
    var progress=clamp((scene_age-_row*0.6)/16,0,1);
    return -24*power(1-progress,3);
};
score = 0;
best = 0;
if (file_exists("bullet_mania.ini")) {
    ini_open("bullet_mania.ini");
    best = ini_read_real("record", "score", 0);
    ini_close();
}
px = 683; py = 620;
hp = 5; inv = 0; dash = 0; dash_cd = 0;
dx = 0; dy = -1;
bombs = 3; fire_cd = 0;
wave = 0; wave_time = 0; wave_gap = 120;
credits=0; shop_pending=false; dash_level=0;
shop_message="Spend credits to prepare for the next sector.";
shop_prices=[200,100,75,125,175];
shop_full = function(_item) {
    switch(_item) {
        case 0: return weapon_level>=3;
        case 1: return shield>=2;
        case 2: return hp>=5;
        case 3: return bombs>=3;
        case 4: return dash_level>=2;
    }
    return true;
};
shop_buy = function(_item) {
    if(shop_full(_item)) { shop_message="Already at capacity. No credits spent."; return; }
    if(credits<shop_prices[_item]) { shop_message="Not enough credits for this upgrade."; return; }
    credits-=shop_prices[_item];
    switch(_item) {
        case 0: weapon_level++; break;
        case 1: shield++; break;
        case 2: hp++; break;
        case 3: bombs++; break;
        case 4: dash_level++; break;
    }
    shop_message=(_item==4?"DASH REACTOR":pickup_names[_item])+" purchased / -"+string(shop_prices[_item])+" CR";
};
bullets = []; shots = []; enemies = []; sparks = [];
shake = 0; flash = 0;
pickups=[]; weapon_level=1; shield=0; kills=0;
pickup_notice=""; pickup_notice_time=0;
pickup_colors=[cyan,violet,pink,gold];
pickup_names=["WEAPON", "SHIELD", "REPAIR", "PULSE"];
drop_pickup = function(_x,_y,_type) {
    array_push(pickups,{x:clamp(_x,60,1306),y:clamp(_y,140,680),kind:_type,age:0});
};
collect_pickup = function(_type) {
    var message="";
    switch(_type) {
        case 0:
            if(weapon_level<3) { weapon_level++; message="WEAPON LEVEL "+string(weapon_level); }
            else { score+=500; message="WEAPON MAX / +500"; }
            break;
        case 1:
            if(shield<2) { shield++; message="SHIELD +1"; }
            else { score+=500; message="SHIELD FULL / +500"; }
            break;
        case 2:
            if(hp<5) { hp++; message="HULL REPAIRED +1"; }
            else { score+=500; message="HULL FULL / +500"; }
            break;
        case 3:
            if(bombs<3) { bombs++; message="PULSE +1"; }
            else { score+=500; message="PULSE FULL / +500"; }
            break;
    }
    pickup_notice=message; pickup_notice_time=120;
    burst(px,py,pickup_colors[_type],20);
};
// Stage order: two formations, a boss, repeated for three sectors.
stages = [0,0,3,0,0,4,0,0,5];
boss_names = ["HELIX WARDEN", "ION TEMPEST", "PRISM ENGINE"];
boss_colors = [violet,gold,cyan];
boss_health = [1000,1300,1600];

burst = function(_x, _y, _col, _n) {
    if(_n>=15) array_push(ripples,{x:_x,y:_y,col:_col,age:0,size:min(180,_n*2)});
    for (var k = 0; k < _n; k++) {
        var a = random(360), s = random_range(1, 6);
        array_push(sparks, {x:_x, y:_y, vx:lengthdir_x(s,a), vy:lengthdir_y(s,a), life:random_range(15,35), col:_col});
    }
};
emit = function(_x, _y, _a, _s, _r, _col) {
    array_push(bullets, {x:_x, y:_y, vx:lengthdir_x(_s,_a), vy:lengthdir_y(_s,_a), r:_r, col:_col});
};
ring = function(_x, _y, _count, _angle, _speed, _col) {
    for (var k = 0; k < _count; k++) emit(_x,_y,_angle+k*360/_count,_speed,5,_col);
};
spawn = function(_kind, _x, _y) {
    var enemy_health = (_kind >= 3) ? boss_health[_kind-3] : ((_kind == 2) ? 85 : 35);
    array_push(enemies, {x:_x, y:_y, home:_x, kind:_kind, hp:enemy_health, max_hp:enemy_health,
        age:0, cd:60, r:(_kind>=3)?48:20, phase:0, transition:0, warning:0, gap:683, volley:0,
        hit:0, display_hp:enemy_health});
};
boss_tick = function(e) {
    e.y=lerp(e.y,190,0.035);
    e.x=683+sin(e.age*(e.kind==4?0.01:0.018))*(e.kind==4?220:300);
    // Entry and phase breaks give the player time to reposition.
    if(e.age<120) return;
    var next_phase = e.hp <= e.max_hp/3 ? 2 : (e.hp <= e.max_hp*2/3 ? 1 : 0);
    if(next_phase>e.phase) {
        e.phase=next_phase; e.transition=60; e.warning=0; e.cd=0;
        bullets=[]; burst(e.x,e.y,boss_colors[e.kind-3],35);
    }
    if(e.transition>0) { e.transition--; return; }
    var aim=point_direction(e.x,e.y,px,py);
    if(e.kind==3 && e.cd<=0) {
        // Helix: paired counter-rotating spirals, petals, then both with aimed shots.
        if(e.phase!=1) {
            for(var k=0;k<3;k++) {
                emit(e.x-30,e.y,e.age*4+k*120,3.0,5,violet);
                emit(e.x+30,e.y,-e.age*4+k*120,3.0,5,pink);
            }
            if(e.phase==2 && e.volley%6==0) {
                for(var k=-1;k<=1;k++) emit(e.x,e.y,aim+k*12,4.2,5,cyan);
            }
            e.cd=e.phase==2?9:12;
        } else {
            for(var k=0;k<12;k++) {
                emit(e.x,e.y,k*30+e.volley*13,2.2,5,violet);
                emit(e.x,e.y,k*30+e.volley*13,3.4,5,pink);
            }
            e.cd=42;
        }
        e.volley++;
    }
    if(e.kind==4) {
        // Ion: telegraphed rain curtains with an explicitly marked safe corridor.
        if(e.warning>0) {
            e.warning--;
            if(e.warning==0) {
                for(var bx=60;bx<1340;bx+=40) {
                    if(abs(bx-e.gap)<100) continue;
                    emit(bx,110,270,3.5+e.phase*0.6,6,gold);
                    if(e.phase==2) emit(bx,80,270,3.5+e.phase*0.6,6,pink);
                }
                e.cd=55; e.volley++;
            }
        } else if(e.cd<=0) {
            e.gap=clamp(px,170,1196); e.warning=50;
            if(e.phase>=1) {
                for(var k=-2;k<=2;k++) emit(e.x,e.y,aim+k*14,3.1,5,violet);
            }
        }
    }
    if(e.kind==5 && e.cd<=0) {
        // Prism: rotating rings, aimed fans, then four sweeping spiral arms.
        if(e.phase==0) { ring(e.x,e.y,18,e.volley*11,3.2,pink); e.cd=25; }
        if(e.phase==1) {
            for(var k=-3;k<=3;k++) emit(e.x,e.y,aim+k*11,4.5,6,gold);
            ring(e.x,e.y,12,-e.volley*17,2.4,violet); e.cd=35;
        }
        if(e.phase==2) {
            for(var k=0;k<4;k++) emit(e.x,e.y,e.age*4+k*90,3.8,6,cyan);
            if(e.volley%12==0) ring(e.x,e.y,12,e.age,2.1,pink);
            e.cd=8;
        }
        e.volley++;
    }
};
finish = function(_win) {
    submit_score(_win);
    change_scene(_win?"win":"dead",false,0);
    if (score > best) {
        best = score;
        ini_open("bullet_mania.ini");
        ini_write_real("record", "score", best);
        ini_close();
    }
};
glow = function(_x, _y, _r, _col) {
    draw_set_color(_col);
    draw_set_alpha(0.06); draw_circle(_x,_y,_r*2.6,false);
    draw_set_alpha(0.14); draw_circle(_x,_y,_r*1.7,false);
    draw_set_alpha(1); draw_circle(_x,_y,_r,false);
};
label = function(_x, _y, _text, _scale, _col) {
    draw_set_color(_col);
    draw_text_transformed(_x,_y,_text,_scale,_scale,0);
};

start_run = function() {
    run_submitted=false;
    change_scene("play",false,0);
    score=0; px=683; py=620; hp=5; inv=0; dash=0; dash_cd=0;
    dx=0; dy=-1; bombs=3; fire_cd=0; wave=0; wave_time=0; wave_gap=120;
    bullets=[]; shots=[]; enemies=[]; sparks=[]; shake=0; flash=0;
    pickups=[]; weapon_level=1; shield=0; kills=0;
    pickup_notice=""; pickup_notice_time=0;
    trails=[]; ripples=[]; ship_bank=0;
    credits=0; shop_pending=false; dash_level=0; shop_message="Spend credits to prepare for the next sector.";
};
menu_buttons = function() {
    if(state=="username") return ["ENTER ARCADE"];
    if(state=="leaderboard") return ["BACK"];
    if(state=="shop") return ["WEAPON UPGRADE", "SHIELD CHARGE", "HULL REPAIR", "PULSE REFILL", "DASH REACTOR", "NEXT SECTOR"];
    if(state=="options") return ["KEY BINDINGS", "FRAME RATE", "V SYNC", "RESET BEST SCORE", "BACK"];
    if(state=="reset_score") return ["CANCEL", "CONFIRM RESET"];
    if(state=="bindings") {
        var rows=[];
        for(var k=0;k<13;k++) array_push(rows,binding_names[k]);
        array_push(rows,"RESTORE DEFAULTS"); array_push(rows,"BACK");
        return rows;
    }
    if(state=="controls") return ["BACK"];
    if(state=="title") return ["START RUN", "HOW TO PLAY", "OPTIONS", "LEADERBOARD", "QUIT GAME"];
    if(paused) return ["RESUME", "HOW TO PLAY", "OPTIONS", "MAIN MENU"];
    return ["PLAY AGAIN", "LEADERBOARD", "MAIN MENU"];
};
menu_draw = function() {
    var muted=make_color_rgb(130,145,180);
    var full=(state=="title" || state=="controls" || state=="bindings" || state=="options" || state=="reset_score" || state=="shop" || state=="username" || state=="leaderboard");
    if(full) {
        draw_clear(bg);
        // A receding grid and orbiting bullet sculpture, built from primitives.
        draw_set_color(violet); draw_set_alpha(0.18);
        for(var k=-10;k<=10;k++) draw_line(900+k*20,330,900+k*160,768);
        for(var k=0;k<12;k++) { var gy=330+power((k+(t*0.008)%1)/12,2)*438; draw_line(0,gy,1366,gy); }
        draw_set_alpha(1);
        for(var k=0;k<72;k++) {
            var a=k*137.5+t*0.28;
            var radius=80+(k%12)*17;
            var bx=985+lengthdir_x(radius,a), by=345+lengthdir_y(radius,a)*0.85;
            glow(bx,by,3+k%3,k%2==0?pink:violet);
        }
        draw_set_color(cyan);
        for(var k=0;k<6;k++) {
            var a=k*60+t*0.3, aa=(k+1)*60+t*0.3;
            draw_line_width(985+lengthdir_x(62,a),345+lengthdir_y(62,a),985+lengthdir_x(62,aa),345+lengthdir_y(62,aa),2);
        }
        glow(985,345,9,cyan);
        label(78,54,"BM / ARCADE SYSTEMS",1,cyan);
        draw_set_halign(fa_right); label(1288,54,"PERSONAL BEST  /  "+string(best),1,gold); draw_set_halign(fa_left);
        draw_set_color(cyan); draw_line(78,84,1288,84);
    } else {
        draw_set_color(bg); draw_set_alpha(0.94); draw_rectangle(0,0,1366,768,false); draw_set_alpha(1);
    }
    if(state=="username") {
        label(100,140,"PILOT SIGN-IN",3,cyan);
        label(100,225,"What should we call you?",1.5,c_white);
        draw_set_color(make_color_rgb(17,30,48)); draw_rectangle(100,300,650,375,false);
        draw_set_color(cyan); draw_rectangle(100,300,650,375,true);
        label(125,323,name_entry+(t mod 60<30?"_":""),2,c_white);
        label(100,405,name_message,1.1,pink);
        label(100,450,"1-12 characters / letters, numbers, spaces, - and _",1,make_color_rgb(130,145,180));
        label(810,590,"LOCAL ARCADE / TOP 10 PILOTS",1,cyan);
        label(810,630,"Your name is requested every launch.",1,muted);
    } else if(state=="leaderboard") {
        label(100,120,"LEADERBOARD",3,cyan);
        label(100,180,"LOCAL TOP 10 / BEST RUN PER PILOT",1,muted);
        for(var k=0;k<10;k++) {
            var row=226+k*34;
            var own=k<array_length(leaderboard) && leaderboard[k].player==player_name;
            draw_set_color(own?make_color_rgb(18,48,62):make_color_rgb(14,19,35)); draw_rectangle(100,row,740,row+30,false);
            label(118,row+7,string(k+1),1,k==0?gold:muted);
            label(175,row+7,k<array_length(leaderboard)?leaderboard[k].player:"---",1,own?cyan:c_white);
            draw_set_halign(fa_right);
            label(580,row+7,k<array_length(leaderboard)?string(leaderboard[k].points):"---",1,gold);
            label(720,row+7,k<array_length(leaderboard)?(leaderboard[k].cleared?"CLEARED":"DEFEATED"):"",0.8,muted);
            draw_set_halign(fa_left);
        }
        label(810,610,"PILOT / "+player_name,1.2,cyan);
        label(810,650,"Scores save after victory or defeat.",1,muted);
    } else if(state=="shop") {
        label(100,140,"NEON SUPPLY",3,cyan);
        label(100,212,"SECTOR "+string(wave div 3)+" CLEARED / UPGRADE DOCK",1.2,c_white);
        label(100,280,shop_message,1,gold);
        label(810,548,"CREDITS / "+string(credits),2,gold);
        label(810,595,"WEAPON "+string(weapon_level)+"/3   SHIELD "+string(shield)+"/2",1,cyan);
        label(810,625,"HULL "+string(hp)+"/5   PULSES "+string(bombs)+"/3",1,pink);
        label(810,653,"DASH "+string(dash_level)+"/2 / "+string((90-15*dash_level)/60)+"s recharge",1,violet);
        label(810,678,"Credits last for this run. Reactor: -0.25s.",0.9,muted);
    } else if(state=="options") {
        label(100,140,"OPTIONS",4,cyan);
        label(100,238,"Make the cockpit your own.",1.3,c_white);
        label(100,302,options_message,1,muted);
        label(810,580,"PERSONAL BEST / "+string(best),1.3,gold);
        label(810,622,"Controls and records save automatically.",1,muted);
        label(810,652,"VSync may limit FPS to your display refresh.",0.9,muted);
    } else if(state=="reset_score") {
        label(100,140,"RESET RECORD?",3,pink);
        label(100,238,"Your saved best score will be set to zero.",1.2,c_white);
        label(100,284,"Current run score and key bindings stay the same.",1,muted);
        label(810,580,"PERSONAL BEST / "+string(best),1.3,gold);
    } else if(state=="bindings") {
        label(100,120,"KEY BINDINGS",3,cyan);
        label(100,178,"Keyboard controls / saved automatically",1.1,muted);
        label(780,580,rebind_slot>=0?"PRESS A KEY / ESC CANCELS":"DUPLICATE KEYS SWAP ACTIONS",1,cyan);
        label(780,616,binding_message,0.9,c_white);
        label(780,652,"Menu navigation stays on arrows + Enter.",1,muted);
    } else if(state=="controls") {
        label(100,120,"FLIGHT MANUAL",3,cyan);
        label(100,192,"Keep your core clear. Everything else is neon.",1.25,muted);
        var keys=["MOVE",key_label(bindings[4]),key_label(bindings[5]),key_label(bindings[6]),key_label(bindings[7])];
        var tips=[key_label(bindings[0])+" / "+key_label(bindings[1])+" / "+key_label(bindings[2])+" / "+key_label(bindings[3])+" (or alternate keys)", "Focus: slow movement + visible hitbox", "Dash through bullets / 1.5s recharge", "Pulse: clear bullets + damage enemies", "Pause the run"];
        for(var k=0;k<5;k++) {
            var row=258+k*53;
            draw_set_color(make_color_rgb(17,23,42)); draw_rectangle(100,row-8,740,row+33,false);
            label(118,row,keys[k],1.15,k%2==0?cyan:pink);
            label(330,row,tips[k],1, c_white);
        }
        label(810,525,"SUPPLY CORES / FLY CLOSE TO COLLECT",1,c_white);
        label(810,551,"W  Weapon upgrade / up to five shots",1,cyan);
        label(810,577,"S  Shield / absorbs a hit, stacks to two",1,violet);
        label(810,603,"+  Repair / restores one hull point",1,pink);
        label(810,629,"P  Pulse / refills one bomb",1,gold);
        label(810,662,"Auto-fire online. White core = hitbox.",1,muted);
    } else {
        var title=state=="title"?"BULLET":(paused?"SIGNAL":"STORM");
        var subtitle=state=="title"?"MANIA":(paused?"PAUSED":(state=="win"?"CLEARED":"LOST"));
        label(96,140,title,4,c_white);
        label(92,212,subtitle,5,state=="dead"?pink:cyan);
        label(100,310,state=="title"?"SURVIVE THE NEON STORM":(paused?"Take a breath. The storm can wait.":"FINAL SCORE  /  "+string(score)),1.3,state=="dead"?pink:muted);
        if(state=="title") {
            label(100,345,"PILOT / "+player_name,1,violet);
            label(810,580,"01 / HELIX WARDEN",1,violet);
            label(810,610,"02 / ION TEMPEST",1,gold);
            label(810,640,"03 / PRISM ENGINE",1,cyan);
        }
        if(state=="dead" || state=="win") label(100,345,"PILOT / "+player_name+"  /  SCORE SAVED",1,gold);
    }
    var items=menu_buttons();
    var top=menu_top(), spacing=menu_spacing();
    for(var k=0;k<array_length(items);k++) {
        var yy=top+k*spacing+button_offset(k), selected=(menu_index==k);
        var warmth=menu_glow[k];
        var unavailable=state=="shop" && k<5 && (shop_full(k) || credits<shop_prices[k]);
        var height=state=="bindings"?26:50;
        var inset=state=="bindings"?6:14;
        var scale=state=="bindings"?1:1.3;
        draw_set_color(merge_color(make_color_rgb(14,19,35),make_color_rgb(18,60,75),warmth));
        draw_rectangle(100,yy,650,yy+height,false);
        draw_set_color(merge_color(make_color_rgb(45,55,80),cyan,warmth)); draw_rectangle(100,yy,650,yy+height,true);
        if(selected) { draw_set_color(cyan); draw_rectangle(100,yy,104,yy+height,false); }
        label(122,yy+inset,selected?">":" ",scale,cyan);
        label(157+warmth*6,yy+inset,items[k],scale,merge_color(muted,c_white,warmth));
        var right_text=state=="bindings"?(k<13?(rebind_slot==k?"PRESS KEY...":key_label(bindings[k])):""):"0"+string(k+1);
        if(state=="options") {
            if(k==1) right_text=string(fps_choices[fps_index])+" FPS";
            if(k==2) right_text=vsync_enabled?"ON":"OFF";
        }
        if(state=="shop" && k<5) right_text=shop_full(k)?"FULL":string(shop_prices[k])+" CR";
        if(unavailable) {
            draw_set_color(bg); draw_set_alpha(0.35); draw_rectangle(145,yy,650,yy+height,false); draw_set_alpha(1);
        }
        draw_set_halign(fa_right); label(630,yy+inset,right_text,1,selected?cyan:muted); draw_set_halign(fa_left);
    }
    draw_set_color(make_color_rgb(45,55,80)); draw_line(78,702,1288,702);
    label(78,723,"UP / DOWN select    ENTER confirm    MOUSE point + click",1,muted);
    draw_set_halign(fa_right); label(1288,723,"BULLET MANIA / NEON EDITION",1,violet); draw_set_halign(fa_left);
    draw_set_color(c_white); draw_set_alpha(1);
};

simulate = function() {
    sim_counter++;
    var consume_dash=dash_requested, consume_pulse=pulse_requested;
    dash_requested=false; pulse_requested=false;
inv = max(0,inv-1); dash_cd = max(0,dash_cd-1);
pickup_notice_time=max(0,pickup_notice_time-1);
shake *= 0.86; flash = max(0,flash-0.04);
var mx = input_held(3)-input_held(2);
var my = input_held(1)-input_held(0);
var mag = sqrt(mx*mx+my*my);
if (mag > 0) { mx /= mag; my /= mag; dx = mx; dy = my; }
ship_bank=lerp(ship_bank,-mx*15,0.18);
if (consume_dash && dash_cd == 0) { dash = 11; dash_cd = 90-15*dash_level; burst(px,py,cyan,20); }
var spd = input_held(4) ? 2.5 : 5.3;
if (dash > 0) { dash--; px += dx*15; py += dy*15; burst(px,py,cyan,2); }
else { px += mx*spd; py += my*spd; }
px = clamp(px,42,1324); py = clamp(py,120,722);
if(dash>0 || sim_counter mod 3==0) array_push(trails,{x:px,y:py,age:0,boost:dash>0});
for(var k=array_length(trails)-1;k>=0;k--) { trails[k].age++; if(trails[k].age>15) array_delete(trails,k,1); }
for(var k=array_length(ripples)-1;k>=0;k--) { ripples[k].age++; if(ripples[k].age>30) array_delete(ripples,k,1); }
fire_cd--;
if (fire_cd <= 0) {
    fire_cd = weapon_level==3?4:5;
    array_push(shots,{x:px-9,y:py-16,vx:-0.15,vy:-13});
    array_push(shots,{x:px+9,y:py-16,vx:0.15,vy:-13});
    if(weapon_level>=2) array_push(shots,{x:px,y:py-22,vx:0,vy:-13});
    if(weapon_level>=3) {
        array_push(shots,{x:px-16,y:py-8,vx:-2.4,vy:-12});
        array_push(shots,{x:px+16,y:py-8,vx:2.4,vy:-12});
    }
}
if (consume_pulse && bombs > 0) {
    bombs--; bullets = []; flash = 1; shake = 12;
    burst(px,py,cyan,80);
    array_push(ripples,{x:px,y:py,col:cyan,age:0,size:1100});
    for (var i = 0; i < array_length(enemies); i++) {
        var e=enemies[i];
        if(e.kind<3 || (e.age>=120 && e.transition==0)) e.hp -= 130;
    }
}
// Three sectors, each with two formations and its own boss.
if (array_length(enemies) == 0) {
    wave_gap--;
    if (wave_gap <= 0) {
        if(shop_pending) {
            // Secure uncollected boss rewards before docking; pickups never expire in the shop.
            for(var k=0;k<array_length(pickups);k++) collect_pickup(pickups[k].kind);
            pickups=[]; shots=[]; bullets=[]; shop_pending=false;
            shop_message="Spend credits to prepare for the next sector.";
            change_scene("shop",false,0); return;
        }
        wave++; wave_time = 0; wave_gap = 120;
        if(wave>array_length(stages)) { score += hp*1000; finish(true); }
        else if (stages[wave-1] == 0) {
            var count = 3 + ceil(wave*2/3);
            for (var i = 0; i < count; i++) spawn((i+wave)%3,160+i*(1046/max(1,count-1)),-40-i%2*65);
        } else { bullets=[]; shots=[]; spawn(stages[wave-1],683,-80); }
    }
}
wave_time++;
for (var i = array_length(enemies)-1; i >= 0; i--) {
    var e = enemies[i]; e.age++; e.cd--;
    e.hit=max(0,e.hit-1); e.display_hp=lerp(e.display_hp,max(0,e.hp),0.16);
    if (e.kind >= 3) {
        boss_tick(e);
    } else {
        e.y = lerp(e.y,180+(i%3)*60,0.025);
        e.x = e.home+sin(e.age*0.025+e.home)*65;
        if (e.cd <= 0 && e.age > 70) {
            var aim = point_direction(e.x,e.y,px,py);
            if(e.kind==0) { for(var k=-1;k<=1;k++) emit(e.x,e.y,aim+k*16,3.5+wave*0.12,5,pink); }
            if(e.kind==1) ring(e.x,e.y,10,e.age*1.5,2.3+wave*0.1,violet);
            if(e.kind==2) { for(var k=-2;k<=2;k++) emit(e.x,e.y,270+k*22+sin(e.age*0.03)*30,3,6,gold); }
            e.cd = max(45,100-wave*6);
        }
        // Formations retreat so a wave cannot stall forever.
        if(e.age>1500) { e.y-=8; if(e.y < -60) { array_delete(enemies,i,1); continue; } }
    }
    if (e.hp <= 0) {
        score += e.kind>=3 ? 8000+(e.kind-3)*2000 : 150+e.kind*100;
        credits+=e.kind>=3?250+(e.kind-3)*100:25+e.kind*10;
        burst(e.x,e.y,e.kind>=3?boss_colors[e.kind-3]:pink,e.kind>=3?100:28); shake = 6;
        if(e.kind>=3) {
            bullets=[]; hp=min(5,hp+1); bombs=min(3,bombs+1); inv=120;
            if(e.kind<5) { drop_pickup(e.x-35,e.y,0); drop_pickup(e.x+35,e.y,1); shop_pending=true; }
        } else {
            kills++;
            // Every third kill guarantees a drop, plus occasional bonus supplies.
            if(kills mod 3==0 || random(1)<0.15) {
                var supply=irandom(3);
                if(kills==3 || kills==6) supply=0;
                drop_pickup(e.x,e.y,supply);
            }
        }
        array_delete(enemies,i,1);
    }
}
for (var i = array_length(shots)-1; i >= 0; i--) {
    var s = shots[i]; s.x+=s.vx; s.y+=s.vy;
    var hit = false;
    for(var j=0;j<array_length(enemies);j++) {
        var e=enemies[j];
        if(point_distance(s.x,s.y,e.x,e.y)<e.r+6) {
            if(e.kind<3 || (e.age>=120 && e.transition==0)) { e.hp-=5; e.hit=6; }
            hit=true; burst(s.x,s.y,cyan,2); break;
        }
    }
    if(hit || s.y < -20) array_delete(shots,i,1);
}
// Collect before collision checks so a shield or repair helps immediately.
for(var i=array_length(pickups)-1;i>=0;i--) {
    var p=pickups[i]; p.age++; p.y+=1.15;
    var distance_to_player=point_distance(p.x,p.y,px,py);
    if(distance_to_player<125) {
        var direction_to_player=point_direction(p.x,p.y,px,py);
        p.x+=lengthdir_x(5,direction_to_player); p.y+=lengthdir_y(5,direction_to_player);
    }
    if(point_distance(p.x,p.y,px,py)<26) { collect_pickup(p.kind); array_delete(pickups,i,1); }
    else if(p.y>760 || p.age>600) array_delete(pickups,i,1);
}
for (var i = array_length(bullets)-1; i >= 0; i--) {
    var b=bullets[i]; b.x+=b.vx; b.y+=b.vy;
    var dist=point_distance(px,py,b.x,b.y);
    if(inv==0 && dash==0 && dist<b.r+4) {
        if(shield>0) {
            shield--; inv=75; shake=7; flash=0.25; burst(px,py,violet,35);
            pickup_notice="SHIELD ABSORBED HIT"; pickup_notice_time=90;
        } else {
            hp--; inv=110; shake=15; flash=0.5; burst(px,py,cyan,40);
        }
        array_delete(bullets,i,1);
        if(hp<=0) { finish(false); break; }
        continue;
    }
    if(dist<24 && dist>b.r+4 && inv==0 && dash==0) score++;
    if(b.x < -40 || b.x>1406 || b.y < -50 || b.y>810) array_delete(bullets,i,1);
}
for(var i=array_length(sparks)-1;i>=0;i--) {
    var p=sparks[i]; p.x+=p.vx; p.y+=p.vy; p.vx*=0.96; p.vy*=0.96; p.life--;
    if(p.life<=0) array_delete(sparks,i,1);
}

};
