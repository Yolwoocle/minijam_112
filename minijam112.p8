pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- minijam 112:chronos


-- main

debug="debug"
debugmode=false

sound_on=false

function _init()
	t=0
	anim={}
	
	pal({[0]=129,1,12,14,7,140},1)
	palt(0,false)palt(15,true)
	poke(0x5f2e,1)
	
	c={
		dobj=create_dobj(63,63),
		sel_index=0,
	}
	
	text_parse=""
	ailment=""
	new_dialogue("ALONZO CORTEZ WILLDIE OF ","LOW BLOOD  PRESSURE")
	parse_length=0
	
	parse_output=""
	ailment_out=""
end

function _update60()
	t+=1
	
	if(btnp(❎))new_dialogue("ALONZO CORTEZ WILLDIE OF ","LOW BLOOD  PRESSURE")
	
	if btnp(⬅️) then
		c.sel_index-=1
		anim_to_point(c,c.dobj.wx-16,nil,0.8)
		s(61)
	end
	if btnp(➡️) then
		c.sel_index+=1
		anim_to_point(c,c.dobj.wx+16,nil,0.8)
		s(61)
	end

	
	parse_dialogue()
	update_anim()
end

function _draw()
	cls(0)
	
	rectfill(-5,-5,135,34,2)
	draw_pdoctor()
	draw_bubble()
	draw_conveyor()
	
	draw_cursor()
	
	
	print(ailment_out,6,5,4)
	print(parse_output,6,5,5)
	
	if(debugmode)print(debug,1,1,8)
end

-->8
--update
-->8
--draw

--draw plague doctor
function draw_pdoctor()
	local _x,_y=89,8
	sspr(0,0,36,27,_x,_y)
	pset(_x+19,_y+27,4)
	pset(_x+19,_y+28,4)
	pset(_x+20,_y+27,4)
	pset(_x+18,_y+27,4)
end


--draw speech bubble
function draw_bubble()
	local _x,_y=3,3
	local _w,_h=78,28	
	
	--78 is normal width
	_w=min(8+#parse_output*4,78)
	
	rrect(_x,_y,_w,_h,3)
	sspr(37,0,7,5,_x+_w+1,_y+4)
end


function draw_conveyor()
	local _y=105
	for i=0,10 do
		local _x=-20+(i*16)+(t*0.2)%16
		sspr(0,66,16,16,_x,_y)
	end
	line(-5,_y+15,130,_y+15,3)
	line(-5,_y+17,130,_y+17,3)
end

function draw_cursor()
	local _x,_y=dx(c.dobj),dy(c.dobj)
	sspr(48,0,16,15,_x,_y)
end


-->8
--recipes
function new_ingredient(name,spr,effects)
	return {
		name=name,
		spr=spr,
		effects=effects,
	}
end

function new_problem(name,good_fx,bad_fx,good_ending)
	return {
		name=name,
		good_fx=good_fx,
		bad_fx=bad_fx,
		good_ending=good_ending,
		bad_ending=bad_ending,
	}
end

effects={
	more_sugar="MORE SUGAR!",
	more_confidence="MORE CONFIDENCE",
	more_strength="STRONGER!",
	dog_legs="GROW DOG TOES"
}

problems={
	bear_attack=new_problem(
		"A BEAR ATTACK",
		{"more_strength", "more_confidence"},
		{"dog_legs"},
		"wow the dude completely fucks up the bear but destroys his house",
		"oh no poor dude :("
	)
}

ingredients={
	candy=new_ingredient("candy",102,{"more_sugar"}),
	dog_tongue=new_ingredient("tongue of dog",100,{"dog_legs"})
}
-->8
--
-->8
-- animation & vfx

--create renderer
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

--returns dobj final xpos
function dx(_dobj)
	return _dobj.wx+_dobj.ox+_dobj.ax
end

--returns dobj final ypos
function dy(_dobj)
	return _dobj.wy+_dobj.oy+_dobj.ay
end

--update animations
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

-->8
--tools

function s(_sfx)
	if(sound_on)sfx(_sfx)
end

--rounded rectangle
function rrect(_x,_y,_w,_h,_c)
	rectfill(_x+1,_y,_x+_w-1,_y+_h,_c)
	rectfill(_x,_y+1,_x+_w,_y+_h-1,_c)
end


function new_dialogue(_text,_ailment)
	parse_length=0
	local t_gap=""
	for i=1,#_ailment do t_gap..=" " end
	text_parse=_text..t_gap.." !"
	
	local a_gap=""
	for i=1,#_text do a_gap..=" " end
	ailment=a_gap.._ailment
	
	parse_output=""
	ailment_out=""	
end

function parse_dialogue()
	if(t%3!=0)return
	
	if parse_length<=#text_parse then
		local sfx_list={63,63,62}
		
		local next_char=sub(text_parse,parse_length,parse_length)
		if(next_char!=" ")s(rnd(sfx_list))
		parse_output..=next_char
		
		local next_char=sub(ailment,parse_length,parse_length)
		if(next_char!=" ")s(rnd(sfx_list))
		ailment_out..=next_char
		
		if parse_length%18==0 and parse_length!=0 then
			parse_output..="\n"
			ailment_out..="\n"
		end
		
		parse_length+=1
	end
end
			
		--[[
			ailment_out..=next_char
			if parse_length<=#text_parse then 
				parse_output..=next_char
			else
				if next_char=="\n" then
					parse_output..=next_char
				else
					local _next=" "
					if(parse_length==1+#text_parse+#ailment)_next="  !"
					parse_output..=_next
			end
		--]]

-->8
--data
__gfx__
fffffffffffffffffff000000ffffffffffff3333fff0000f00fffff000fffff0000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffff00007777000ffffffffff333333f00000770ff006770ffff0000000000000000000000000000000000000000000000000000000000000000
fffffffffffffff0077777777700fffffffff333333300000777006706770fff0000000000000000000000000000000000000000000000000000000000000000
fffffffffffffff07770000077700ffffffff333333300000677770677770fff0000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff0770000000077700fffffff33333330000f0677777776770ff0000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff0700000000007770fffffff00000000000ff067777677670ff0000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff00077777000077700ffffff00000000000ff006777767770ff0000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff00077777770007770ffffff00000000000ff0556777777700f0000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff00777777770007770ffffff00000000000ff056677777707700000000000000000000000000000000000000000000000000000000000000000
fffffffffffff000777000777007770ffffff00000000000fff06677777777700000000000000000000000000000000000000000000000000000000000000000
ffffffffff000777770770077007770ffffff00000000000ffff06666607760f0000000000000000000000000000000000000000000000000000000000000000
fffffffff0777777770770077707770ffffff00000000000fffff000006760ff0000000000000000000000000000000000000000000000000000000000000000
fffffff0077777777770000770077700fffff00000000000ffffffff05660fff0000000000000000000000000000000000000000000000000000000000000000
fffff007777777777777777070777700fffff00000000000ffffffff0550ffff0000000000000000000000000000000000000000000000000000000000000000
fff00077777777777777777070777000fffff00000000000fffffffff00fffff0000000000000000000000000000000000000000000000000000000000000000
ff007777777777777777770700777000fffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f007777770000000007777700077000ffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f07770000ffffff0700000000770000ffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07700ffffffffff007000000777000fffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000fffffffffffff0777777770000700fffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff000777777770000770fffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff07007700000077770000fff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff07707777707700000000fff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffffffff0007077700000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffffffff00000777000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffff000000070000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffff000000070000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
12222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01155555552200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00015555555520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001555555552000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000155555555200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000155555555200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000015555555520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000015555555520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000025555555510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000025555555510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000255555555100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000255555555100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00002555555551000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00025555555510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02255555551100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555555555555000055555555555500005555555555550000555555555555000000000000000000000000000000000000000000000000000000000000000000
055555555555555005552442555555500555555555555550055555d4444d55500000000000000000000000000000000000000000000000000000000000000000
0555555fff5555500524455455425550055555555555555005555d443334d5500000000000000000000000000000000000000000000000000000000000000000
05555fffffff55500544555544255550055557dd7755555005555443333345500000000000000000000000000000000000000000000000000000000000000000
0557fffffffff55005445555555555500555777dd775555005555433444335500000000000000000000000000000000000000000000000000000000000000000
055a77ffffff9550054455524442555005557777d775555005555434434335500000000000000000000000000000000000000000000000000000000000000000
055aaa77ff999550054445244444255005557777d775555005555434343335500000000000000000000000000000000000000000000000000000000000000000
055aaaa79999955005544244433445500555d777d775555005555d343333d5500000000000000000000000000000000000000000000000000000000000000000
055aaaa79999555005554241333315500555d777d775555005555254433d55500000000000000000000000000000000000000000000000000000000000000000
0555aaa799955550055555113333155005555d7777d5555005552225555555500000000000000000000000000000000000000000000000000000000000000000
055555a7955555500555552443342550055555d77d55555005522255555555500000000000000000000000000000000000000000000000000000000000000000
05555555555555500555555244425550055555555555555005522555555555500000000000000000000000000000000000000000000000000000000000000000
05555555555555500555555555555550055555555555555005555555555555500000000000000000000000000000000000000000000000000000000000000000
00555555555555000055555555555500005555555555550000555555555555000000000000000000000000000000000000000000000000000000000000000000
05000000000000500500000000000050050000000000005005000000000000500000000000000000000000000000000000000000000000000000000000000000
00555555555555000055555555555500005555555555550000555555555555000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55515555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55551555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555155555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555515555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555515555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555551555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555551555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555552555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555552555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555525555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555525555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555255555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55552555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55525555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22211111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001dcae7bca2aa9894b0bd0686c8a00fb1d5fc9b0400000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000197300e720207000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
910300001251500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505
910300001551500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505
