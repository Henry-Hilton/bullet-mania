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
        bullets: [], px: 683, py: 620, pink: 1, violet: 2, cyan: 3, gold: 4,
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
let overallPeak=0;
for(let kind=3;kind<=7;kind++) {
    for(let phase=0;phase<3;phase++) {
        const w=world(), e=enemy(kind,phase);
        for(let t=0;t<119;t++) tick(w,e);
        assert.equal(w.bullets.length,0,'entry must be safe');
        let emitted=0, peak=0;
        for(let t=0;t<3600;t++) {
            const before=w.bullets.length;
            tick(w,e);
            emitted+=w.bullets.length-before;
            w.bullets=w.bullets.filter(b => {
                b.x+=b.vx; b.y+=b.vy;
                assert(Number.isFinite(b.x+b.y+b.vx+b.vy));
                return b.x>=-40 && b.x<=1406 && b.y>=-50 && b.y<=810;
            });
            peak=Math.max(peak,w.bullets.length);
        }
        assert(emitted>200,`boss ${kind} phase ${phase} did not sustain attacks`);
        assert(peak<1000,`unexpected projectile accumulation: ${peak}`);
        overallPeak=Math.max(overallPeak,peak);
        // A phase break clears existing hazards, cancels warnings, and waits 60 ticks.
        if(phase<2) {
            e.hp=phase===0?500:200;
            tick(w,e);
            assert.equal(e.phase,phase+1);
            assert.equal(w.bullets.length,0);
            assert.equal(e.warning,0);
            for(let t=0;t<59;t++) tick(w,e);
            assert.equal(w.bullets.length,0);
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
    assert.equal(w.bullets.length,0,'no early release during warning');
    assert.equal(e.gap,gap,'passage must stay locked');
    assert.equal(e.lock,lock,'aim must stay locked');
    tick(w,e);
    assert(w.bullets.length>0);
    if(kind===4) assert(w.bullets.every(b=>Math.abs(b.x-gap)>=100));
    if(kind===6) assert(w.bullets.every(b=>Math.abs(b.y-gap)>=80));
}
// Run the actual production projectile-update loop at collision/graze boundaries.
const collisionLoop=source.slice(source.indexOf('for (var i = array_length(bullets)-1;'),source.indexOf('for(var i=array_length(sparks)-1;'));
for(const [offset,damage,graze] of [[8,1,0],[9,0,0],[10,0,1],[24,0,0]]) {
    const w=world();
    Object.assign(w,{inv:0,dash:0,shield:0,hp:5,score:0,shake:0,flash:0,
        sqr:x=>x*x,array_length:a=>a.length,array_pop:a=>a.pop(),finish:()=>{}});
    w.bullets=[{x:w.px+offset,y:w.py,vx:0,vy:0,r:5}];
    vm.runInContext(collisionLoop,w);
    assert.equal(w.hp,5-damage);
    assert.equal(w.score,graze);
    assert.equal(w.bullets.length,1-damage);
}
// Swap removal preserves every survivor exactly once during a backward update.
for(let count=0;count<100;count++) {
    const a=Array.from({length:count},(_,id)=>({id,updates:0}));
    for(let i=a.length-1;i>=0;i--) {
        a[i].updates++;
        if(a[i].id%3===0) { a[i]=a[a.length-1]; a.pop(); }
    }
    assert(a.every(x=>x.updates===1 && x.id%3!==0));
    assert.equal(a.length,count-Math.ceil(count/3));
}
console.log(`PASS: 20 stages, 15 boss phases, warnings, phase clears, collision/graze boundaries, swap removal. Max live bullets: ${overallPeak}`);
