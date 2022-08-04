pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- init

debug=""
debugmode=true

function _init()
	--data init
	t=0
	
	--palette
	pal({[0]=130,2,14,137,135},1)
	palt(0,false)palt(15,true) --15 is transparent
	poke(0x5f2e,1)

	--create objects
	c={ --cursor object
		dobj=create_dobj(150,63), --for this object init position doesn't really matter . because it's pos is updated every frame
		lx=4,ly=4, --local x/y can be changed , not a great representation , just one way of doing it
	}
	scary_obj={ --example enemy object
		dobj=create_dobj(32,32),
	}
	anim={} --animation comtroller
end
-->8
-- update60

function _update()
	t+=1
	
	move_cursor()
	
	update_anim()
end

--object update
function move_cursor()
	--find a new direction based
	--off button input
	local dir={0,0}
	if(btnp(➡️))dir[1]+=1
	if(btnp(⬅️))dir[1]-=1
	if(btnp(⬆️))dir[2]-=1
	if(btnp(⬇️))dir[2]+=1

	--if its not 0 then 
	--do the object update shit
	local pos={c.lx,c.ly}
	if dir!={0,0} then
		--update object local pos
		c.lx+=dir[1]
		c.ly+=dir[2]
		
		--object object screen pos
		--each lx/ly is 16 screen pos
		anim_to_point(c,c.lx*16,c.ly*16,0.8)
	end
end

-->8
-- draw

function _draw()
	--
	cls(0)	
	
	draw_scary_obj()
	
	draw_cursor() --draw cursor??
		
	--debugmode
	if debugmode then 
		print(debug,1,1,7) --always have last
		sspr(0,24,8,8,120,120)
	end
end


--object drawcalls

function draw_cursor()
	sspr(0,0,16,15,dx(c),dy(c))
end

function draw_scary_obj()
	sspr(16,0,16,14,dx(scary_obj),dy(scary_obj))
end
-->8
--
-->8
--
-->8
--data management

--create ""display obj""
--basically used to control
--all objects as they appear
--on screen
function create_dobj(_x,_y)	
	return {
		--world x,y
		--position on screen
		wx=_x,
		wy=_y,
		
		--offset x,y
		--used as an unmoving offset
		--think raised tiles
		ox=0,
		oy=0,
		
		--anim x,y
		--value that slowly gets
		--reduced to 0 . used for
		--animation
		ax=0,
		ay=0,
	}
end

--returns x screen loc of dobj
function dx(_obj)
	local _d=_obj.dobj
	return _d.wx+_d.ox+_d.ax
end

--returns y screen loc of dobj
function dy(_obj)
	local _d=_obj.dobj
	return _d.wy+_d.oy+_d.ay
end

--animate object to location
--nil value for x/y means 0
function anim_to_point(_o,_x,_y,_s)
	local _d,_s=_o.dobj,_s or 0.8
	local _x=_x or _d.wx
	local _y=_y or _d.wy
	
	--delete anim if object
	--already has an anim
	for a in all(anim) do
		if a.o==_d then
			del(anim,a)
		end
	end
	
	_d.ax=_d.ax+_d.wx-_x
	_d.ay=_d.ay+_d.wy-_y
	_d.wx,_d.wy=_x,_y
	
	
	add(anim,{o=_d,speed=_s})
end

--update animations
--lower every anim.ax/ay by
--anim.speed every frame
--remove if it's close to 0
function update_anim()
	for a in all(anim) do
		--make the anim offset smaller	
		_aoax,_aoay=a.o.ax*a.speed,a.o.ay*a.speed
		
		--delete the anim obj
		--if the obj is ""home""
		if abs(_aoax)<0.3 and abs(_aoay)<0.5 then
			_aoax,_aoay=0,0
			del(anim,a)
		end
		a.o.ax,a.o.ay=_aoax,_aoay
	end
end
-->8
--tools
-->8
--data
__gfx__
f00fffff000fffff0111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0770ff006770ffff1112211111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0777006706770fff1111221111112211000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0677770677770fff1111122111122111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f0677777776770ff1111111211211111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff067777677670ff1112221211112111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff006777767770ff1112221111222111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff0556777777700f1111211111122111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff056677777707701111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fff06677777777701111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffff06666607760f1112222222211111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff000006760ff1111111111222111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffff05660fff0111111111112211000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffff0550ffffffff111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffff00fffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000ffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00112233000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00112233000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44556677000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44556677000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8899aabb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8899aabb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccddee67000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccddee76000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
