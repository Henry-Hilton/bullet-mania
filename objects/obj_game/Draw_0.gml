if(state=="title" || state=="controls" || state=="bindings" || state=="options" || state=="reset_score" || state=="shop" || state=="username" || state=="leaderboard") { menu_draw(); transition_draw(); exit; }
draw_clear(bg);
draw_set_alpha(0.14); draw_set_color(violet);
for(var gx=0;gx<=1366;gx+=48) draw_line(gx,92,gx,768);
for(var gy=92;gy<768;gy+=48) { var yy=gy+(t*0.5)%48; draw_line(0,yy,1366,yy); }
draw_set_alpha(1);
draw_set_color(cyan); draw_rectangle(24,100,1342,744,true);
// Subtle moving stars add depth without textures.
for(var i=0;i<55;i++) {
    draw_set_alpha(0.2+(i%3)*0.15); draw_set_color(cyan);
    draw_circle((i*197+31)%1320+24,110+(i*89+t*(0.3+i%3*0.3))%620,1,false);
}
draw_set_alpha(1);
var ox = random_range(-shake,shake), oy = random_range(-shake,shake);
for(var i=0;i<array_length(trails);i++) {
    var trail=trails[i], alpha=(1-trail.age/15)*(trail.boost?0.45:0.12);
    draw_set_alpha(alpha); draw_set_color(trail.boost?cyan:violet);
    draw_triangle(trail.x+ox,trail.y-18+oy,trail.x-13+ox,trail.y+12+oy,trail.x+13+ox,trail.y+12+oy,true);
}
draw_set_alpha(1);
for(var i=0;i<array_length(shots);i++) {
    var s=shots[i]; draw_set_color(cyan);
    draw_set_alpha(0.2); draw_line_width(s.x+ox,s.y+oy,s.x-s.vx*3+ox,s.y-s.vy*3+oy,5);
    draw_set_alpha(1); draw_rectangle(s.x-2+ox,s.y+oy,s.x+2+ox,s.y+18+oy,false);
    draw_set_color(c_white); draw_line(s.x+ox,s.y+oy,s.x+ox,s.y+8+oy);
}
for(var i=0;i<array_length(enemies);i++) {
    var e=enemies[i], ex=e.x+ox, ey=e.y+oy;
    var col=e.kind>=3?boss_colors[e.kind-3]:(e.kind==0?pink:(e.kind==1?violet:gold));
    col=merge_color(col,c_white,e.hit/6);
    var visual_radius=e.r*(0.5+0.5*clamp(e.age/60,0,1));
    draw_set_color(col); draw_set_alpha(0.1); draw_circle(ex,ey,e.r*1.8,false); draw_set_alpha(1);
    var sides=e.kind>=3?e.kind+1:4;
    for(var k=0;k<sides;k++) {
        var a=k*360/sides+t*(e.kind==3?0.7:1.5);
        var aa=(k+1)*360/sides+t*(e.kind==3?0.7:1.5);
        draw_line_width(ex+lengthdir_x(visual_radius,a),ey+lengthdir_y(visual_radius,a),ex+lengthdir_x(visual_radius,aa),ey+lengthdir_y(visual_radius,aa),3);
    }
    glow(ex,ey,e.kind>=3?12:5,col);
    if(e.kind>=3) {
        draw_set_color(col); draw_circle(ex,ey,60+sin(t*0.08)*4,true);
        if(e.kind==3) {
            glow(ex-64,ey,7,pink); glow(ex+64,ey,7,violet);
        }
        if(e.kind==4) {
            draw_set_color(gold);
            draw_line_width(ex-80,ey-20,ex+80,ey-20,3);
            draw_line_width(ex-80,ey+20,ex+80,ey+20,3);
            if(e.warning>0) {
                draw_set_alpha(0.08+(sin(t*0.4)+1)*0.06);
                draw_rectangle(25,170,e.gap-100,743,false);
                draw_rectangle(e.gap+100,170,1341,743,false);
                draw_set_alpha(0.65); draw_set_color(cyan);
                draw_line(e.gap-100,175,e.gap-100,740);
                draw_line(e.gap+100,175,e.gap+100,740);
                draw_set_alpha(1); draw_set_halign(fa_center);
                label(e.gap,690,"SAFE LANE",1,cyan); draw_set_halign(fa_left);
            }
        }
        draw_set_color(make_color_rgb(25,30,50)); draw_rectangle(380,108,986,120,false);
        draw_set_color(merge_color(col,c_white,0.65)); draw_rectangle(380,108,380+606*clamp(e.display_hp/e.max_hp,0,1),120,false);
        draw_set_color(col); draw_rectangle(380,108,380+606*clamp(e.hp/e.max_hp,0,1),120,false);
        draw_set_color(bg); draw_line(582,108,582,120); draw_line(784,108,784,120);
        draw_set_halign(fa_center);
        label(683,130,boss_names[e.kind-3]+"  /  PHASE "+string(e.phase+1),1,c_white);
        if(e.age<120 || e.transition>0) {
            var announce=e.age<120?sin(pi*clamp(e.age/120,0,1)):sin(pi*e.transition/60);
            draw_set_alpha(announce); label(683,300+(1-announce)*18,e.age<120?"BOSS INBOUND":"PATTERN SHIFT",2,col); draw_set_alpha(1);
        }
        draw_set_halign(fa_left);
    }
}
for(var i=0;i<array_length(bullets);i++) {
    var b=bullets[i]; glow(b.x+ox,b.y+oy,b.r,b.col);
    draw_set_color(c_white); draw_circle(b.x+ox,b.y+oy,1.5,false);
}
for(var i=0;i<array_length(sparks);i++) {
    var p=sparks[i]; draw_set_alpha(min(1,p.life/20)); draw_set_color(p.col);
    draw_line_width(p.x+ox,p.y+oy,p.x-p.vx*2+ox,p.y-p.vy*2+oy,2);
}
for(var i=0;i<array_length(pickups);i++) {
    var p=pickups[i];
    if(p.age>480 && p.age mod 12<4) continue;
    var cx=p.x+ox, cy=p.y+oy, col=pickup_colors[p.kind];
    var orbit=t*2+p.kind*90;
    glow(cx+lengthdir_x(25,orbit),cy+lengthdir_y(25,orbit),2,col);
    draw_set_color(col); draw_set_alpha(0.13); draw_circle(cx,cy,28,false); draw_set_alpha(1);
    draw_set_color(bg); draw_circle(cx,cy,16,false);
    draw_set_color(col);
    draw_line_width(cx,cy-20,cx+20,cy,2); draw_line_width(cx+20,cy,cx,cy+20,2);
    draw_line_width(cx,cy+20,cx-20,cy,2); draw_line_width(cx-20,cy,cx,cy-20,2);
    draw_set_halign(fa_center);
    label(cx,cy-8,["W","S","+","P"][p.kind],1.1,col);
    label(cx,cy+24,pickup_names[p.kind],0.8,col);
    draw_set_halign(fa_left);
}
for(var i=0;i<array_length(ripples);i++) {
    var ripple=ripples[i], progress=ripple.age/30;
    draw_set_alpha((1-progress)*0.65); draw_set_color(ripple.col);
    draw_circle(ripple.x+ox,ripple.y+oy,8+ripple.size*(1-power(1-progress,3)),true);
}
draw_set_alpha(1);
if(state!="title" && state!="dead") {
    var xx=px+ox, yy=py+oy;
    if(shield>0) {
        draw_set_color(violet); draw_circle(xx,yy,25+sin(t*0.1)*2,true);
        if(shield==2) draw_circle(xx,yy,31+sin(t*0.1)*2,true);
    }
    if(inv==0 || t%8<4) {
        draw_set_color(cyan); draw_set_alpha(0.15); draw_circle(xx,yy,26,false); draw_set_alpha(1);
        var nose_x=xx+lengthdir_x(18,90+ship_bank), nose_y=yy+lengthdir_y(18,90+ship_bank);
        var left_x=xx+lengthdir_x(18,222+ship_bank), left_y=yy+lengthdir_y(18,222+ship_bank);
        var right_x=xx+lengthdir_x(18,318+ship_bank), right_y=yy+lengthdir_y(18,318+ship_bank);
        draw_triangle(nose_x,nose_y,left_x,left_y,right_x,right_y,true);
        draw_line_width(left_x,left_y,xx,yy+5,2); draw_line_width(right_x,right_y,xx,yy+5,2);
        glow(xx,yy+17+sin(t*0.6)*3,dash>0?7:4,violet);
    }
    draw_set_color(c_white); draw_circle(xx,yy,4,false);
    if(input_held(4)) { draw_set_color(cyan); draw_circle(xx,yy,7,true); }
}
if(flash>0) { draw_set_alpha(flash*0.4); draw_set_color(cyan); draw_rectangle(0,92,1366,768,false); draw_set_alpha(1); }
draw_set_color(bg); draw_rectangle(0,0,1366,90,false);
label(28,20,"BULLET / MANIA",2,cyan);
label(340,25,"SCORE  "+string(score),1.4,c_white);
label(600,25,"BEST  "+string(best),1.2,violet);
label(850,25,"HULL",1,pink);
for(var i=0;i<hp;i++) { draw_set_color(pink); draw_rectangle(900+i*18,25,910+i*18,40,false); }
label(1030,22,"PULSE  "+string(bombs),1.2,gold);
label(1180,22,dash_cd==0?"DASH READY":"DASH "+string(ceil(dash_cd/60))+"s",1,cyan);
draw_set_color(make_color_rgb(25,30,50)); draw_rectangle(1180,44,1322,48,false);
draw_set_color(cyan); draw_rectangle(1180,44,1180+142*(1-dash_cd/(90-15*dash_level)),48,false);
label(28,56,"WEAPON "+string(weapon_level)+"/3  |  SHIELD "+string(shield)+"/2",1,violet);
label(1030,60,"CREDITS / "+string(credits),1,gold);
label(340,56,key_label(bindings[4])+" focus   "+key_label(bindings[5])+" dash   "+key_label(bindings[6])+" pulse   "+key_label(bindings[7])+" pause",0.95,make_color_rgb(130,145,180));
if(pickup_notice_time>0) {
    draw_set_halign(fa_center); draw_set_alpha(min(1,pickup_notice_time/20));
    label(683,710-max(0,pickup_notice_time-100)*0.4,pickup_notice,1.25,cyan);
    draw_set_alpha(1); draw_set_halign(fa_left);
}
if(state=="play" && array_length(enemies)==0 && wave<array_length(stages)) {
    draw_set_halign(fa_center);
    var next_kind=stages[wave];
    var banner_alpha=min(1,(120-wave_gap)/18,wave_gap/18);
    draw_set_alpha(banner_alpha);
    label(683,310+(1-banner_alpha)*20,next_kind>=3?boss_names[next_kind-3]+" APPROACHING":"SECTOR "+string(1+wave div 3)+" / FORMATION "+string(1+wave mod 3),2,cyan);
    if(wave>0 && wave mod 3==0) label(683,355,"HULL +1 / PULSE +1",1,gold);
    draw_set_halign(fa_left);
    draw_set_alpha(1);
}
if(state=="dead" || state=="win" || paused) menu_draw();
draw_set_alpha(1); draw_set_color(c_white);
transition_draw();
