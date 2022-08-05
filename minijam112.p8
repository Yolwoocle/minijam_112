pico-8 cartridge // http://www.pico-8.com
version 36
__lua__

debug="debug"
debugmode=false

function _init()
	t=0
	
	pal({[0]=129,1,12,14,7,140},1)
	palt(0,false)palt(15,true)
	poke(0x5f2e,1)
	
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

	
	parse_dialogue()
end

function _draw()
	cls(0)
	
	rectfill(-5,-5,135,34,2)
	draw_pdoctor()
	draw_bubble()
	draw_conveyor()
	
	
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
		local _x=-20+(i*16)+(-t*0.2)%16
		sspr(48,0,16,16,_x,_y)
	end
	line(-5,_y+16,130,_y+16,3)
	line(-5,_y+18,130,_y+18,3)
end
-->8
--
-->8
--
-->8
--
-->8
--tools

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
		if(next_char!=" ")sfx(rnd(sfx_list))
		parse_output..=next_char
		
		local next_char=sub(ailment,parse_length,parse_length)
		if(next_char!=" ")sfx(rnd(sfx_list))
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
fffffffffffffffffff000000ffffffffffff3333fff000055555555555555550000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffff00007777000ffffffffff333333f000000200000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffffffffff0077777777700fffffffff3333333000000020000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffffffffff07770000077700ffffffff3333333000000002000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff0770000000077700fffffff3333333000000000200000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff0700000000007770fffffff0000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff00077777000077700ffffff0000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff00077777770007770ffffff0000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff00777777770007770ffffff0000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000
fffffffffffff000777000777007770ffffff0000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffff000777770770077007770ffffff0000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000
fffffffff0777777770770077707770ffffff0000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000
fffffff0077777777770000770077700fffff0000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000
fffff007777777777777777070777700fffff0000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000
fff00077777777777777777070777000fffff0000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000
ff007777777777777777770700777000fffff0000000000055555555555555550000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
00000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffffffffff5fff111111ffffffffffff3333fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff5f11117777111ffffffffff333333f000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffffffff5f1177777777711fffffffff3333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffffffff5f17771111177711ffffffff3333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffff5f1771111111177711fffffff3333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffff5f1711111111117771fffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffff55ff11177777111177711ffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffff5fff11177777771117771ffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff11777777771117771ffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffffffff111777111777117771ffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffff111777771771177117771ffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffff1777777771771177717771ffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffff1177777777771111771177711fffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff117777777777777777171777711fffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fff11177777777777777777171777111fffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff117777777777777777771711777111fffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f117777771111111117777711177111ffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f17771111ffffff1711111111771111ffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17711ffffffffff117111111777111fffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111fffffffffffff1777777771111711fffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff111777777771111771fffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff17117711111177771111fff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff17717777717711111111fff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffffffff1117177711111111111111ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffffffff11111777111111111111111f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffff111111171111111111111111f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffff111111171111111111111111f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666661222222222000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660115555555220000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660001555555552000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000155555555200000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000015555555520000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000015555555520000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000001555555552000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000001555555552000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000002555555551000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000002555555551000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000025555555510000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000025555555510000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000255555555100000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660002555555551000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660225555555110000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666662111111111000000000000000000000000000000000000000000000000000000
000000000d72c895c1d645ad0b9a43a19ed2b143b9c2d2e800000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c00100001202500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505
c00100001502500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505
