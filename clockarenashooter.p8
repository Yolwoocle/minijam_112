pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- init

function _init()
	actors={}
	clock_a=0
	
	is_atck=false
	atck_t = 0
	
	spwn_t = 0
end
-->8
-- update60

function _update60()
	if(btn(⬅️))clock_a+=0.01
	if(btn(➡️))clock_a-=0.01
	
	-- attack
	if btnp(❎) then
		is_atck = true
		atck_t = 40
	end
	
	atck_t -=1
	is_atck = atck_t > 0 

	-- spawn enemies
	spwn_t-=1
	if spwn_t<0 then
		spwn_t = 4
		
		local a=rnd()
		local x=64+cos(a)*rnd()*63
		local y=64+sin(a)*rnd()*63
		add(actors,new_obj(
			x,y
		))
	end
	
	-- compute clock hitbox
	l1x=64
	l1y=64
	l2x=64+cos(clock_a)*64
	l2y=64+sin(clock_a)*64

	-- update enems
	for a in all(actors)do
		a.x += a.vx
		a.y += a.vy
		local d= dist2seg(a,
			{x=l1x,y=l1y},
			{x=l2x,y=l2y}
		)
		if d<5 and is_atck then
			del(actors,a)
		end
	end
end

-->8
-- draw

function _draw()
	cls(7)
	
	-- draw enemies
	for i=1,12 do
		local a=.25 - i/12
		print(i,
		64+cos(a)*50,
		64+sin(a)*50, 0)
	end
	
	-- draw actors
	for a in all(actors)do
		circfill(a.x,a.y,2,11)
	end

	-- draw clock 
	local col=is_atck and 8 or 0
	for ox=-2,2 do
		for oy=-2,2 do
			line(l1x+ox, l1y+oy, 
				l2x+ox, l2y+oy, col)
		end
	end

end
-->8
-- object
function new_obj(x,y)
	return {
		x=x,
		y=y,
		vx=0,
		vy=0,
	}
end
-->8
-- utility
-- i have no idea how this works
-- i just copied from the internet

function linedist(px,py, l1x, l1y, l2x, l2y) 
 local dividend = abs((l2x - l1x)*(l1y - py) - (l1x - px)*(l2y - l1y));
 local divisor = sqrt((l2x - l1x) ^ 2 + (l2y - l1y) ^ 2);

 if divisor != 0 then
     return dividend / divisor;
 else -- points l1 and l2 are the same, choose one
    	return sqrt((px - l1x) ^ 2 + (py - l1y) ^ 2);
	end
end

---------------------------


function sqr(x)
  return x * x
end
function dist2(v, w)
  return sqr(v.x - w.x) + sqr(v.y - w.y)
end
function dist2segsq(p, v, w)
  local l2 = dist2(v, w)
  if (l2 == 0) return dist2(p, v)
  local t = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l2
  t = max(0, min(1, t))
  return dist2(p, { x= v.x + t * (w.x - v.x),
                    y= v.y + t * (w.y - v.y) })
end
function dist2seg(p, v, w) 
  return sqrt(dist2segsq(p, v, w))
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
