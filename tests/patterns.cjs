// Run with node tests/patterns.cjs. Executes the production attack logic with
// GameMaker math/array built-ins supplied by this small, deterministic harness.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('objects/obj_game/Create_0.gml', 'utf8');
function method(name) {
    const start = source.indexOf(name + ' = function(');
    assert(start >= 0, name);
    const end = source.indexOf('\n};', start) + 3;
    return source.slice(start, end).replace(/\bmod\b/g, '%');
}
function world() {
    const context = vm.createContext({
        bullets: [], bullet_count: 0, inv: 0, dashing_this_tick: false, score: 0,
        sqr: x => x*x, array_length: a => a.length, px: 683, py: 620, pink: 1, violet: 2, cyan: 3, gold: 4,
        boss_colors: [2,4,3,1,4],
        sin: Math.sin, abs: Math.abs, min: Math.min, max: Math.max,
        clamp: (x,lo,hi) => Math.max(lo,Math.min(hi,x)),
        lerp: (a,b,t) => a+(b-a)*t,
        point_direction: (x,y,xx,yy) => Math.atan2(y-yy,xx-x)*180/Math.PI,
        lengthdir_x: (r,a) => r*Math.cos(a*Math.PI/180),
        lengthdir_y: (r,a) => -r*Math.sin(a*Math.PI/180),
        array_push: (a,x) => a.push(x), burst: () => {},
    });
    for (const name of ['emit','ring','boss_tick']) vm.runInContext(method(name), context);
    return context;
}
function enemy(kind, phase=0) {
    return {kind, phase, hp: 900-phase*300, max_hp: 900, age: 0, cd: 60,
        x:683, y:190, transition:0, warning:0, gap:683, volley:0, lock:270};
}
function tick(w,e) { e.age++; e.cd--; w.boss_tick(e); }
const stages = JSON.parse(source.match(/stages = (\[[^;]+\]);/)[1]);
assert.equal(stages.length,20);
for(let sector=0;sector<5;sector++) {
    assert.deepEqual(new Set(stages.slice(sector*4,sector*4+3)),new Set([0,-1,-2]));
    assert.equal(stages[sector*4+3],sector+3);
}
const collisionLoop=source.slice(source.indexOf('var can_hit=inv'),source.indexOf('for(var i=array_length(sparks)-1;'));
const updateBullets = new vm.Script(collisionLoop);
let overallPeak=0;
for(let kind=3;kind<=7;kind++) {
    for(let phase=0;phase<3;phase++) {
        const w=world(), e=enemy(kind,phase);
        for(let t=0;t<119;t++) tick(w,e);
        assert.equal(w.bullet_count,0,'entry must be safe');
        let emitted=0, peak=0;
        for(let t=0;t<3600;t++) {
            const before=w.bullet_count;
            tick(w,e);
            emitted+=w.bullet_count-before;
            w.inv=1;
            updateBullets.runInContext(w);
            assert(w.bullets.slice(0,w.bullet_count).every(b => Number.isFinite(b.x+b.y+b.vx+b.vy)));
            peak=Math.max(peak,w.bullet_count);
        }
        assert(emitted>200,`boss ${kind} phase ${phase} did not sustain attacks`);
        assert(peak<1000,`unexpected projectile accumulation: ${peak}`);
        overallPeak=Math.max(overallPeak,peak);
        // A phase break clears existing hazards, cancels warnings, and waits 60 ticks.
        if(phase<2) {
            e.hp=phase===0?500:200;
            tick(w,e);
            assert.equal(e.phase,phase+1);
            assert.equal(w.bullet_count,0);
            assert.equal(e.warning,0);
            for(let t=0;t<59;t++) tick(w,e);
            assert.equal(w.bullet_count,0);
        }
        console.log(`boss ${kind}, phase ${phase+1}: ${emitted} emitted / peak ${peak}`);
    }
}
for(const kind of [4,6,7]) {
    const w=world(),e=enemy(kind);
    e.age=120; e.cd=0;
    w.boss_tick(e);
    const warning=e.warning, gap=e.gap, lock=e.lock;
    assert(warning>=50);
    w.px=100; w.py=150;
    for(let t=0;t<warning-1;t++) tick(w,e);
    assert.equal(w.bullet_count,0,'no early release during warning');
    assert.equal(e.gap,gap,'passage must stay locked');
    assert.equal(e.lock,lock,'aim must stay locked');
    tick(w,e);
    assert(w.bullet_count>0);
    if(kind===4) assert(w.bullets.slice(0,w.bullet_count).every(b=>Math.abs(b.x-gap)>=100));
    if(kind===6) assert(w.bullets.slice(0,w.bullet_count).every(b=>Math.abs(b.y-gap)>=80));
}
// Run the actual production projectile-update loop at collision/graze boundaries.
for(const [offset,damage,graze] of [[8,1,0],[9,0,0],[10,0,1],[24,0,0]]) {
    const w=world();
    Object.assign(w,{inv:0,dash:0,shield:0,hp:5,score:0,shake:0,flash:0,
        sqr:x=>x*x,array_length:a=>a.length,array_pop:a=>a.pop(),finish:()=>{}});
    w.emit(w.px+offset,w.py,0,0,5,w.cyan);
    updateBullets.runInContext(w);
    assert.equal(w.hp,5-damage);
    assert.equal(w.score,graze);
    assert.equal(w.bullet_count,1-damage);
}
// A removal moves the survivor without updating it twice and preserves the freed slot.
const pooled=world();
pooled.emit(1406,200,0,2,5,pooled.cyan);
const freed=pooled.bullets[0];
pooled.emit(300,200,0,2,6,pooled.gold);
updateBullets.runInContext(pooled);
assert.equal(pooled.bullet_count,1);
assert.equal(pooled.bullets[0].x,302);
pooled.emit(400,220,0,0,6,pooled.pink);
assert.equal(pooled.bullets[1],freed);
assert.equal(freed.hit_radius_squared,100);
assert.equal(freed.col,pooled.pink);
assert.equal(freed.vx,0);
pooled.bullet_count=0;
pooled.emit(310,240,0,0,5,pooled.gold);
assert.equal(pooled.bullet_count,1);
assert.equal(pooled.bullets.length,2);
// The final dash movement tick still protects the player at its destination.
const dashTick = source.slice(source.indexOf('var dashing_this_tick='), source.indexOf('px = clamp(px'));
const dashWorld=world();
Object.assign(dashWorld,{dash:1, dx:1, dy:0, hp:5, shield:0, finish:()=>{}});
dashWorld.emit(dashWorld.px+15,dashWorld.py,0,0,5,dashWorld.pink);
vm.runInContext(dashTick,dashWorld);
updateBullets.runInContext(dashWorld);
assert.equal(dashWorld.dash,0);
assert.equal(dashWorld.hp,5);
dashWorld.dashing_this_tick=false;
updateBullets.runInContext(dashWorld);
assert.equal(dashWorld.hp,4);

// A defeated retreating enemy gets credit even on its final in-bounds tick.
const enemyTick=source.slice(source.indexOf('wave_time++;'),source.indexOf('for (var i = array_length(shots)-1;'))
    .replaceAll('((wave-1) div 4)','Math.floor((wave-1)/4)').replace(/\bmod\b/g,'%');
for(const hp of [0,5]) {
    const w=world(), e={...enemy(0),hp,age:1530,y:-59,hit:0,display_hp:5};
    const drops=[];
    Object.assign(w,{wave_time:0, enemies:[e], credits:0, kills:2, random:()=>0.99, irandom:()=>2,
        drop_pickup:(_x,_y,kind)=>drops.push(kind), array_delete:(a,i,n)=>a.splice(i,n)});
    vm.runInContext(enemyTick,w);
    assert.equal(w.enemies.length,0);
    assert.equal(w.score,hp===0?150:0);
    assert.equal(w.credits,hp===0?25:0);
    assert.deepEqual(drops,hp===0?[0]:[]);
}
console.log(`PASS: 20 stages, 15 boss phases, warnings, phase clears, collision/graze boundaries, final dash tick, retreat rewards, swap removal. Max live bullets: ${overallPeak}`);
