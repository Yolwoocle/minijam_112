pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- minijam 112: chronos
-- louiechapm & yolwoocle

-- main

debug="debug"
debugmode=false

sound_on=true

function _init()
	t=0
	anim={}
	
	pal({[0]=129,1,12,14,7,140},1)
	palt(0,false)palt(15,true)
	poke(0x5f2e,1)
	
	c={
		dobj=create_dobj(63,63),
		sel_index=1,
	}
	pot={
		ingr={},
		ingr_num=0,
	}
	
	bubbles={}

	st=0 --spawn time
	spawn_wait_time=80
	conveyor_speed=0.2

	ailment_manager=
	{
		big_a="", --string containing ailment name
		solutions={}, --list containing all the "solution strings"
	}

	text_parse=""
	ailment=""
	parse_length=0
	parsing=true

	parse_output=""
	ailment_out=""

	ingr_particles={}

	new_ailment()

	g_ingredients={
		{
			obj=generate_ingredient(),
			dobj=create_dobj(-20,flr(rnd(10)+100))
		},
	}
end

function _update60()
	t+=1
	st+=1
	
	local nums=split"90,103,173,302"
	for num in all(nums) do
		if(t%num==0)spawn_bubble() --
	end
	
	conveyor_spawner()
	
	update_cursor()
	animate_ingredients()
	
	animate_bubbles()
	animate_ingr_particles()
	
	parse_dialogue()
	update_anim()
end

function _draw()
	cls(0)
	
	rectfill(-5,-5,135,34,2)
	draw_pdoctor()
	draw_bubble()
	

	draw_pot()
	for b in all(bubbles) do
		circ(b._x,b._y,b.size,4)
	end
	rectfill(-5,110,130,130,0)
	
	draw_conveyor()

	
	draw_effects()
	
	draw_ingredients()
	draw_ingr_particles()

	selected_effects()
	
	
	draw_cursor()
	
	
	
	
	print(parse_output,6,5,5)
	print(ailment_out,6,5,4)
	
	if(debugmode)print(debug,1,1,8)
end

-->8
--update

function animate_ingredients()
	for ingredient in all(g_ingredients) do
		local speed=conveyor_speed
		ingredient.dobj.wx+=speed
		
		--destroy ingredient if it goes off screen
		if ingredient.dobj.wx>128 then
			del(g_ingredients,ingredient)
			c.sel_index=mid(1,c.sel_index-1,#g_ingredients) --fix weird cursor thing
		end
	end
end


function update_cursor()
	for i=0,1 do --move cursor direction from input
		if btnp(i) then
			sfx(61)
			local dir=split"1,-1"
			c.sel_index=mid(1,c.sel_index+dir[i+1],#g_ingredients)
		end
	end


	if #g_ingredients>0 then --animate to selected ingredient location
		local ox,oy=10,8
		local ingr=g_ingredients[c.sel_index]
		anim_to_point(c,dx(ingr.dobj)+ox,dy(ingr.dobj)+oy,0.9)
	
		if btnp(❎) and #g_ingredients>1 then
			local a_in={
				dobj=ingr.dobj,
				_s=ingr.obj._s,
				spawn=0,
				death=60,
				_tx=10+rnd(22), --22 is middle
				_ty=70+rnd(5),
				ox=dx(ingr.dobj),
				
				ny=0,
				vy=-2.5-rnd(),
				gravity=0.1,
			} --animation ingredient
			
			--anim_to_point(a_in,a_in._tx,a_in._ty,0.95)
			a_in.dobj.oy=1
			add(ingr_particles,a_in)
			
			del(g_ingredients,ingr)
			commit_ingredient(ingr.obj)
			
			c.sel_index=mid(1,c.sel_index,#g_ingredients) --fix cursor
		end
	end
end

--spawns objects onto the
--conveyor
function conveyor_spawner()
	if st%spawn_wait_time==0 then
		local object={
			obj=generate_ingredient(),
			dobj=create_dobj(-20,95+rnd(10))
		}
		add(g_ingredients,object)
		spawn_wait_time=80+flr(rnd(100))
		st=0
	end
end


--commits the selected ingredient
--to the brew , and chooses
--a random effect to add
function commit_ingredient(_ingr)
	local effect=nil

	i=1
	for _fx in all(_ingr.effects) do
		if(in_list(ailment_manager.solutions,_fx))effect=_ingr.effects_modified[i]
		i+=1
	end
	if(not effect)effect=rnd(_ingr.effects_modified)
	add(pot.ingr,effect)
	pot.ingr_num+=1

	if	pot.ingr_num>=3 then 
		--conveyor_speed=0
		new_ailment()
	end
end
-->8
--draw

--draw plague doctor
function draw_pdoctor()
	local _x,_y=89,8
	if parsing then
		sspr(88,0,36,27,_x+2,_y)
	else
		sspr(0,0,36,27,_x,_y)
	end
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
		local _x=-20+(i*16)+(t*conveyor_speed)%16
		sspr(0,64,16,16,_x,_y)
	end
	line(-5,_y+15,130,_y+15,3)
	line(-5,_y+17,130,_y+17,3)
end

function draw_cursor()
	local _x,_y=dx(c.dobj),dy(c.dobj)
	sspr(48,0,16,15,_x,_y)
end

function draw_ingredients()
	for ingredient in all(g_ingredients) do
		local _x,_y=dx(ingredient.dobj), dy(ingredient.dobj)
		spr(ingredient.obj._s, _x, _y, 2, 2)
	end
end

function selected_effects()
	local ingredient=g_ingredients[c.sel_index]
	for i=1,#ingredient.obj.effects do
		local fx=ingredient.obj.effects_modified[i]
		rrect(2,24+i*13,55,15,1)
		print(fx,4,25+i*13,2)
	end
end


function draw_effects()
	local _x,_y=61,39
	local _w,_h=62,60
	
	rrect(_x,_y,_w,_h,3)
	
	print("effects",_x+3,_y+3,5)
	line(_x+4,_y+10,_x+_w-4,_y+10)
	
	rectfill(_x+(_w*0.5)-2,_y+8,_x+(_w*0.5)+2,_y+12,3)
	line(_x+(_w*0.5)-1,_y+11,_x+(_w*0.5)+1,_y+11,5)
	line(_x+(_w*0.5),_y+8,_x+(_w*0.5),_y+12,5)
	
	local default_text="[EMPTY] \n"	
	for i=0,2 do
		local text=pot.ingr[i+1] or default_text
		print(text,_x+4,_y+14+i*14,4)
	end
	
end


function draw_pot()
	local _x,_y=3,80
	
	sspr(96,64,26,46,_x,_y)
	sspr(96,64,26,46,_x+26,_y,26,46,true)
end

-->8
--recipes
-- function new_conveyor_ingredient()
-- 	{
-- 		obj=ingredients.candy,
-- 		dobj=create_dobj(-80,rnd(10)+90)
-- 	},
-- end

--[[
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
	dog_legs="GROW DOG LEGS",
	hug_charm="WANTS TO HUG EVERYONE",
	long_tongue="GROW A REALLY LONG TONGUE",
	become_older="BECOME OLDER",
}

problems={
	bear_attack=new_problem(
		"WILL DIE OF A BEAR ATTACK",
		{"more_strength","more_confidence"},
		{"dog_legs","hug_charm","become_older"},
		"wow the dude completely fucks up the bear but destroys his house",
		"oh no poor dude became bear meal :("
	),
	no_friends=new_problem(
		"HAS NO FRIENDS",
		{"more_confidence","hug_charm"},
		{"long_tongue","dog_legs"},
		"dude is now friends with everyone but [??? dies of being nice?]",
		"dude is isolated and now lives in the jungle or something"
	),
	keys_fell_in_hole=new_problem(
		"HAS DROPPED HIS KEYS INTO A HOLE",
		{"dog_legs", "long_tongue"},
		{"become_older"},
		"guy now has the key to the king's treasure room and steals everything. oops!",
		"guy tries to get his keys but falls into the hole. oops!"
	)
}

ingredients={
	candy=new_ingredient("candy",102,{"more_sugar"}),
	dog_tongue=new_ingredient("tongue of dog",100,{"dog_legs"}),
	mummy_tooth=new_ingredient("mummy_tooth",104,{"become_older"}),
	snake_tongue=new_ingredient("snake tongue",106,{"long_tongue"}),
}
]]--
-->8
-- recipies 2

all_effects=split"LOWERS CHOLESTEROL,INCREASES MEMORY,REDUCES MEMORY LOSS,STRENGTHENS BONE MARROW,INCREASES CHARISMA,REJUVENATES HAIR GROWTH,FACILITATES CONFIDENCE,HARDENS SKIN,HIGH IN VITAMIN C,BREAKS FOURTH WALL,INCREASES PUNGENCY,UNTERRICHTET dEUTSCH,FINDS KEYS,GIVES INSTANT FEVER,HARDENS LIVER,DRIES MOUTH,INDUCES VOMITING,REMOVES TASTE,INCREASE COORDINATION,TURNS URINE GREEN,AMPLIFIES TINNITUS,EMITS 5G SIGNAL,BOOSTS TASTE,TASTES OF ORANGE,JUST GETS YOU STONED,INCREASES STRENGTH,INCREASES MAGIC,INCREASES RESISTANCE,INCREASES STEALTH,RAISES HP,RAISES MP,RAISES SPEED,INCREASES INTELLIGENCE,LOWERS INTELLIGENCE,LOWERS SPEED,LOWERS HP,DECREASES STEALTH,DECREASES MAGIC,DECREASES STRENGTH,DECREASES DEXTERITY,INCREASES CONSTITUTION,DECREASES CONSTITUTION,INCREASES WISDOM,DECREASES WISDOM,RAISES RECOVERY,INSTILLS PARANOIA,PROBABLY BOOSTS LUCK,FREAKS EVERYONE OUT,INCREASES POISON RES,INCREASES FIRE RES,LOWERS FIRE RES,LOWERS POISON RES,RAISES GLASS CEILING,INSTANT DEATH,RAISES SEX APPEAL,RELEASES PHEROMONES,THICKENS BLOOD,INDUCES STRESS,INDUCES MANIA,INDUCES VOMITING"
all_solutions={
	"A BROKEN HEART|LOWERS CHOLESTEROL,RAISES SEX APPEAL,RELEASES PHEROMONES,FACILITATES CONFIDENCE,HARDENS SKIN",
	"BAD BODY ODOUR|RELEASES PHEROMONES",
	"LOW BLOOD PRESSURE|LOWERS CHOLESTEROL",
	"SOCIAL REJECTION|FACILITATES CONFIDENCE,RAISES SEX APPEAL,RELEASES PHEROMONES,BREAKS FOURTH WALL,JUST GETS YOU STONED",
	"BEING STABBED|HARDENS SKIN,RAISES HP",
	"A BEAR ATTACK|RAISES HP,RAISES RECOVERY",
	"GANG VIOLENCE|RAISES HP,INCREASES STEALTH,PROBABLY BOOSTS LUCK,FREAKS EVERYONE OUT",
	"DRINKING THE WRONG POTION|INCREASES INTELLIGENCE",
	"FORGETFULNESS|INCREASES INTELLIGENCE",
	"BEING ON THEIR PHONE WHILE DRIVING|INCREASES INTELLIGENCE",
	"FREEZING|RAISES RECOVERY",
	"LEAVING THE OVEN ON|INCREASE COORDINATION",
	"A GUNSHOT|RAISES HP",
	"NOT KNOWING WHEN TO HOLD 'EM|INCREASES STEALTH,FREAKS EVERYONE OUT",
	"WEAK BONES|STRENGTHENS BONE MARROW",
	"BALDING|REJUVENATES HAIR GROWTH",
	"LOSING THEIR KEYS|INCREASES WISDOM",
	"NOT SPEAKING GERMAN|UNTERRICHTET dEUTSCH",
	"NOT HAVING ENOUGH HP|RAISES HP",
	"NOT HAVING ENOUGH MP|RAISES MP",
	"FALLING OFF THEIR HORSE|INCREASE COORDINATION",
	"DRINKING TOO MUCH|HARDENS LIVER,INDUCES VOMITING",
	"A FIREBALL|INCREASES FIRE RES",
	"A SUDDEN STROKE|LOWERS CHOLESTEROL",
	"OLD AGE|LOWERS CHOLESTEROL,HARDENS LIVER",
}

titles=split"SIR,COUNT,BARON VON,DUCHES,PRINCE,KING,QUEEN"
first_names=split"HARLAN,EDEN,EARNA,PAIGE,EDOLIE,WINFRED,LINDLEY,GRAHAM,HARLOW,ALLURA,WILTON,NORMA,GREYSEN,OPELINE,CARREEN,TIMOTHEA,EALHSTAN,GIMLI,OSCAR,ROHESIA,OPELINE,LUELLA,HEATH,BRIAR,DEAN"
last_names=split"GRAHAMES,HUMES,HARFORDE,DARWINE,GOODEE,ELWINE,EDISONE,SWEETE,TATUME,DYRE,BYRD,WEBBE,HEDLEYE,EVERLYE,HARRISE,FAIRBAIRNS,WESTCOTTE,EDGARE"

function generate_ingredient()
	local sprite = rnd{64,96} + flr(rnd(8))*2
	local gen_ingr={
		_s=sprite,
		effects={},
		effects_modified={},
	}
	
	local num_effects=2+flr(rnd(2))
	for i=0,num_effects do
		local effect=rnd(all_effects)
		if not in_list(gen_ingr.effects,effect) then
			add(gen_ingr.effects,effect)
			add(gen_ingr.effects_modified,to_fit(effect,12," "))
		end
	end
	
	return gen_ingr
end
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


function spawn_bubble(_x,_y,_vx,_vy,_gravity)
	o_vx=0
	if(_vx!=nil)o_vx=_vx*0.1
	o_vy=-0.1
	if(_vy!=nil)o_vy=_vy*0.1

	local new_bub={
		_x= _x or 15+rnd(28),
		_y= _y or 80+rnd(8),
		vx= o_vx,
		vy= o_vy,
		gravity=_gravity or 0,
		size=rnd(3)+1,
	}
	add(bubbles,new_bub)
end

function animate_bubbles()
	for b in all(bubbles)do
		b.size-=rnd(10)*0.01
		b._x+=b.vx
		b._y+=b.vy
		if(b.vx!=nil) b.vx*=0.9
		if(b.vy!=nil) b.vy*=0.9
		if(b.gravity!=nil) b.vy+=b.gravity
		if(b.size<=0)del(bubbles,b)
	end
end


function animate_ingr_particles()
	for p in all(ingr_particles) do
		p.spawn+=1
		local amount=p.spawn/p.death --should be a number between 0-1
		
		p.dobj.wx=lerp(p.ox,p._tx,amount) --fix this mess
		
		p.vy+=p.gravity
		p.ny+=p.vy

		p.dobj.oy=p.ny
		
		if p.spawn>35 and dy(p.dobj)>80 then
			local bubble_amount=10
			local _vx=40
			local _vy=20
			for i=0,bubble_amount do
				spawn_bubble(p._tx+8,p._ty+16,rnd(_vx)-(_vx*0.5),-rnd(_vy),0.01)
			end

			del(ingr_particles,p)
		end

		if t%5==0 then
			p.rx=rnd{true,false}
			p.ry=rnd{true,false}
		end
	end
end

function draw_ingr_particles()
	for p in all(ingr_particles) do
		spr(p._s,dx(p.dobj),dy(p.dobj),2,2,p.rx,p.ry)
	end
end


-->8
--tools

oldsfx=sfx
function sfx(_sfx)
	if(sound_on)oldsfx(_sfx)
end

oldbtn=btn
function btn(n,p)
	if(n==❎ or n==🅾️)return oldbtn(❎,p)or oldbtn(🅾️,p)
	return oldbtn(n,p)
end
oldbtnp=btnp
function btnp(n,p)
	if(n==❎ or n==🅾️)return oldbtnp(❎,p)or oldbtnp(🅾️,p)
	return oldbtnp(n,p)
end

function lerp(a,b,t)
	return a+(b-a)*t
end

--rounded rectangle
function rrect(_x,_y,_w,_h,_c)
	rectfill(_x+1,_y,_x+_w-1,_y+_h,_c)
	rectfill(_x,_y+1,_x+_w,_y+_h-1,_c)
end

--updates the current ailment , and the current solutions
function new_ailment()
	local _a=flr(rnd(#all_solutions)+1)

	--reset solutions
	local sol=split(all_solutions[_a],"|")
	ailment_manager.big_a=sol[1]
	ailment_manager.solutions=split(sol[2])

	--reset pot
	pot.ingr={}
	pot.ingr_num=0

	--reset dialogue
	new_dialogue()
end

--updates the dialogue
function new_dialogue()
    parse_length=0
    parsing=true

	local first_name=rnd(first_names)
	local last_name=rnd(last_names)
	local title=""
	if(flr(rnd(10))==0)title=rnd(titles).." "
	local name=title..first_name.." "..last_name
	local _text=name.." WILL DIE OF "
	local _ailment=ailment_manager.big_a

    text_parse=to_fit(_text.._ailment.." !",19)
    ailment=""
    for i=1,#text_parse do
        local char=sub(text_parse,i,i)
        if char=="\n" then
            ailment..="\n"
        else
            if i<#_text+1 or i==#text_parse then
                ailment..=" "
            else
                ailment..=char
            end
        end
    end
    

    parse_output=""
    aliment_out=""    
end

function parse_dialogue()
	if(t%5!=0)return
	
	if parse_length<=#text_parse then
		local sfx_list={63,63,62}
		
		local next_char=sub(text_parse,parse_length,parse_length)
		if(next_char!=" ")sfx(rnd(sfx_list))
		parse_output..=next_char
		
		local next_char=sub(ailment,parse_length,parse_length)
		if(next_char!=" ")sfx(rnd(sfx_list))
		ailment_out..=next_char
		
		parse_length+=1
	else
		parsing=false
	end
end


function in_list(list,item)
	for i in all(list) do
		if(item==i)return true
	end
	return false
end


function to_fit(_text,_w,_extra)
	local out=_text
	local _ex=_extra or ""
	local length=#_text
	for i=1,length do
		--letter is over width limit
		if i%_w==0 then
			local steps=0
			while sub(out,i-steps,i-steps)!=" "do
					steps+=1
			end
			out=sub(out,1,i-steps).."\n".._ex..sub(out,i+1-steps,-1)
		end
	end
	
	return out
end
-->8
--data
__gfx__
fffffffffffffffffff000000ffffffffffff3333fff0000f00fffff000fffff000000000000000000000000fffffffffffffffffffffffffffffffffffff000
ffffffffffffffff00004444000ffffffffff333333f00000440ff006440ffff000000000000000000000000fffffffffffffffffffffffffffffffffffff000
fffffffffffffff0044444444400fffffffff333333300000444006406440fff000000000000000000000000fffffffffffffffff00000000ffffffffffff000
fffffffffffffff04440000044400ffffffff333333300000644440644440fff000000000000000000000000fffffffffffffff00444444440fffffffffff000
ffffffffffffff0440000000044400fffffff33333330000f0644444446440ff000000000000000000000000fffffffffffff00444444444440ffffffffff000
ffffffffffffff0400000000004440fffffff00000000000ff064444644640ff000000000000000000000000ffffffffffff004444444444440ffffffffff000
ffffffffffffff00044444000044400ffffff00000000000ff006444464440ff000000000000000000000000ffffffffffff0440000000004440fffffffff000
ffffffffffffff00044444440004440ffffff00000000000ff0dd6444444400f000000000000000000000000ffffffffffff0000000000000440fffffffff000
ffffffffffffff00444444440004440ffffff00000000000ff0d664444440440000000000000000000000000ffffffffffff0000000000000440fffffffff000
fffffffffffff000444000444004440ffffff00000000000fff0664444444440000000000000000000000000ffffffffffff0044444444000000f00ffffff000
ffffffffff000444440440044004440ffffff00000000000ffff06666604460f000000000000000000000000ffffffffffff04444444440444440000fffff000
fffffffff0444444440440044404440ffffff00000000000fffff000006460ff000000000000000000000000fffffffffff0004400000440044400000ffff000
fffffff0044444444440000440044400fffff00000000000ffffffff0d660fff000000000000000000000000ffffffffff00444404400440044000000ffff000
fffff004444444444444444040444400fffff00000000000ffffffff0dd0ffff000000000000000000000000ffffffff00444444400004400000000000fff000
fff00044444444444444444040444000fffff00000000000fffffffff00fffff000000000000000000000000fffffff0044444444444404044000000000ff000
ff004444444444444444440400444000fffff000000000000000000000000000000000000000000000000000ffffff00444444444444404004000000000ff000
f004444440000000004444400044000ffffff000000000000000000000000000000000000000000000000000fffff0044444444444444040044000000000f000
f04440000ffffff0400000000440000ffffff000000000000000000000000000000000000000000000000000ffff04444444444444444400444000000000f000
04400ffffffffff004000000444000fffffff000000000000000000000000000000000000000000000000000fff0444444400000000000044440400000000000
000fffffffffffff0444444440000400fffff000000000000000000000000000000000000000000000000000ff0444440000ff04000000044400400000000000
ffffffffffffff000444444440000440fffff000000000000000000000000000000000000000000000000000f0444400fffff004444444444000440000000000
ffffffffffffff04004400000044440000fff000000000000000000000000000000000000000000000000000044400ffffff0404444000000044400000000000
ffffffffffffff04404444404400000000fff0000000000000000000000000000000000000000000000000000400ffffffff0400444444044400000000000000
fffffffffffff0004044400000000000000ff000000000000000000000000000000000000000000000000000000ffffffff00040444000000000000000000000
fffffffffffff00000444000000000000000f000000000000000000000000000000000000000000000000000fffffffffff00000444000000000000000000000
ffffffffffff000000040000000000000000f000000000000000000000000000000000000000000000000000ffffffffff00000004000000000000000000f000
ffffffffffff000000040000000000000000f000000000000000000000000000000000000000000000000000ffffffffff0000000400000000000000000ff000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffff000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0fffffff
ffffff0000ffffffffff02250ffffffffffffff0000fffffffffffffffffffffffff000000fffffffffff0000fffffffffffffff0ffffffffffffff040ffffff
fffff033440ffffffff022220fffffffffff00064460fffffffffffffffffffffff03355550fffffffff0d33d0fffffffffff0f0f000ffffffffff03440fffff
ffff03000330fffffff025520ffffffffff064444420fffffffffff00ffffffffff033355330fffffff0d3d44d0fffffffffff0500330fffff000f033440ffff
fff000fff0330fffffff055220fffffffff044200600ffffffffff0420ffffffff0553300000fffffff03d3d4000fffffffff00204330fffff0440333330ffff
fff0fffff0430fffffff022550ffffffffff000264640ffffffff062250fffffff05000666660ffffff0d3d330250fffffff040250440fffff034033344000ff
ffffffff06430ffffffff0252200fffffff02464644640fffffff022240fffffff00666640660ffffff00dd0052250fffff034402040ffffff043403340340ff
ffff000033440ffffffff002255200fffff044644646460fffff02224440ffffff0666044000ffffff050301022220fffff0334020330ffffff03403440d30ff
fff0064433460fffffff02525225440fff0446444644640fffff02224440fffffff0000440ffffffff020d05022220ffffff004052030ffffff04303440d0fff
ff0d30433340fffffff040220502060fff0446444644640fffff02222440ffffffffff04460fffffff05200505220ffffffff04302040fffffff030440d0ffff
ff0333033460fffffff00f020050f00fff0646444464460fffff06422250fffffffff0644440fffffff0220510250ffffffff0330500ffffffff0034400fffff
ff033303360ffffffffff020f040fffffff04444446440fffffff064250ffffffffff0444460fffffff052200050fffffffff030f0fffffffffff00000ffffff
fff03d0340fffffffffff050f060ffffffff006444460fffffffff0000fffffffffff064460fffffffff0052500fffffffffff0fffffffffffffffffffffffff
ffff00000ffffffffffff040ff00ffffffffff000000ffffffffffffffffffffffffff0000ffffffffffff000fffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffff0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffff0000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000ffffff
ffffffffffffffffff0064460f00ffffffffffffffffffffffffffff00fffffffffff00f000ffffffff0000ffffffffffffffffffff0fffffffff0030d0fffff
ffff000ffffffffff064400400460ffffffff00000fffffffffffff0440fffffffff06606660fffffff0d3d0ffffffffffffffffff00ffffffff0300330fffff
ffff011000fffffff0440ff04460ffffffff03dd330fffffffff00044440fffffff0666464460ffffff03330fffffffffffffff000450fffffff0d330005ffff
fffff01124000ffff0440ff00000fffffff0333dd330fffffff0446444400ffffff0664444440ffffff0d330ffffffffffffff0524040ffffff55000555dffff
ffff0111225240fff0440f0644460ffffff03333d330ffffff044464334640fffff0644444440fffffff033d0ffffffffffff05224040ffffff0555131130fff
fff01100255220fff0444064444460fffff03333d330ffffff044443333440fffff0644444440fffffff03330ffffffffffff02240420fffff0d33131313d0ff
fff0002452200fffff044644433440fffff0d333d330fffffff04433333440ffffff064444460fffffff0d330ffffffffffff04404250ffff0d33313113330ff
fff0f02255220ffffff04645333350fffff0d333d330fffffff04633334440ffffff06446640fffffffff03080000fffffffff004250fffff0333331331330ff
ffffff00245540ffffff0055333350ffffff0d3333d0fffffff0644336440fffffff06460660fffffffff08008810ffffff00002250ffffff0333331331330ff
fffffff0225220fffffff064433460fffffff0d33d0ffffffff0444446440ffffffff060f060fffffffff0810000fffffffffff000fffffff0d333313333d0ff
ffffffff00f00fffffffff0644460fffffffff0000ffffffffff04444460fffffffff060f060ffffffffff0811ffffffffffffffffffffffff00d3333d000fff
fffffffffffffffffffffff00000fffffffffffffffffffffffff000000fffffffffff0fff0ffffffffffff000ffffffffffffffffffffffffff000000ffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
222211122222222200000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffff22222222000000
555522215555555500000000000000000000000000000000000000000000000000000000000000000000000000000000fffffffffffff2222200000000000000
555555521555555500000000000000000000000000000000000000000000000000000000000000000000000000000000fffffffff22220000000000000000000
555555552155555500000000000000000000000000000000000000000000000000000000000000000000000000000000fffffff2200000000000000000000000
555555555215555500000000000000000000000000000000000000000000000000000000000000000000000000000000fffff220000000000333333333000000
555555555215555500000000000000000000000000000000000000000000000000000000000000000000000000000000ffff2000000333333333333333000000
555555555521555500000000000000000000000000000000000000000000000000000000000000000000000000000000fff20000333333333333333333000000
555555555521555500000000000000000000000000000000000000000000000000000000000000000000000000000000ff200033333333333333333333000000
555555555512555500000000000000000000000000000000000000000000000000000000000000000000000000000000f2000333333333333333333333000000
555555555512555500000000000000000000000000000000000000000000000000000000000000000000000000000000f2000433333333333333333333000000
555555555125555500000000000000000000000000000000000000000000000000000000000000000000000000000000f2000043333333333333333333000000
555555555125555500000000000000000000000000000000000000000000000000000000000000000000000000000000f2000004443333333333333333000000
555555551255555500000000000000000000000000000000000000000000000000000000000000000000000000000000f2004000004444333333333333000000
555555512555555500000000000000000000000000000000000000000000000000000000000000000000000000000000ff200440000000444444444444000000
555511125555555500000000000000000000000000000000000000000000000000000000000000000000000000000000ff200004400000000000000000000000
00555555555555ff00000000000000000000000000000000000000000000000000000000000000000000000000000000ff200000044440000000000000000000
ffff00000000ffff00000000000000000000000000000000000000000000000000000000000000000000000000000000f2000000000004444400000000000000
fff0444444440fff00000000000000000000000000000000000000000000000000000000000000000000000000000000f2000000000000000044444444000000
ff04ffffffff40ff00000000000000000000000000000000000000000000000000000000000000000000000000000000f2000000000000000000000000000000
ff04f444444f40ff0000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000
fff04ffffff40fff0000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000
ffff04444440ffff0000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000
ffff04555540ffff0000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000
ffff04355340ffff0000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000
fff0433333340fff0000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000
ff043333333340ff0000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000
f04344333333340f0000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000
f04344333333340f0000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000
f04433333333340f0000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000
ff044333333440ff0000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000
fff0044444400fff0000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000
fffff000000fffff0000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff200000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fff20000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fff20000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffff2000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffff2200000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffff222000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffff2200000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffffff22200000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffffffff222000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffffffffff2220000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffff2222222222000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffff000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffff000000
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccceeeesseessessseseeesssesseessseeeeesseeeeeeeecccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccceeesesesesesseeseeeeseesesesseeeeeeseseeeeeeeeeeecccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccceeesesessseseeeseeeeseeseseseeeeeeeseseeeeeeeeeeeeecccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccceeesseeseeeesseessessseseseesseeeeesseeeeeeeeeeeeeeeccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccccccccccccccccccccccccccccccccccccccccccccccccccccchhhhhhhhcccccccccccc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccccccccccccccccccccccccccccccccccccccccccccccccccchh77777777hccccccccccc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecccccccccccccccccccccccccccccccccccccccccccccccccccccccchh77777777777hcccccccccc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccccccccccccccccccccccccccccccccccccccccccccccccccccccchh777777777777hcccccccccc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccccccccccccccccccccccccccccccccccccccccccccccccccccccch77hhhhhhhhh777hccccccccc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccccccccccccccccccccccccccccccccccccccccccccccccccccccchhhhhhhhhhhhh77hccccccccc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccccccccccccccccccccccccccccccccccccccccccccccccccccccchhhhhhhhhhhhh77hccccccccc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccccccccccccccccccccccccccccccccccccccccccccccccccccccchh77777777hhhhhhchhcccccc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccccccccccccccccccccccccccccccccccccccccccccccccccccccch777777777h77777hhhhccccc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecccccccccccccccccccccccccccccccccccccccccccccccccccccchhh77hhhhh77hh777hhhhhcccc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccccccccccccccccccccccccccccccccccccccccccccccccccccchh7777h77hh77hh77hhhhhhcccc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccccccccccccccccccccccccccccccccccccccccccccccccccchh7777777hhhh77hhhhhhhhhhhccc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecccccccccccccccccccccccccccccccccccccccccccccccccchh777777777777h7h77hhhhhhhhhcc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccccccccccccccccccccccccccccccccccccccccccccccccchh7777777777777h7hh7hhhhhhhhhcc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecccccccccccccccccccccccccccccccccccccccccccccccchh77777777777777h7hh77hhhhhhhhhc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccccccccccccccccccccccccccccccccccccccccccccccch77777777777777777hh777hhhhhhhhhc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecccccccccccccccccccccccccccccccccccccccccccccch7777777hhhhhhhhhhhh7777h7hhhhhhhc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccccccccccccccccccccccccccccccccccccccccccccch77777hhhhcch7hhhhhhh777hh7hhhhhhhc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecccccccccccccccccccccccccccccccccccccccccccch7777hhccccchh7777777777hhh77hhhhhhc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccccccccccccccccccccccccccccccccccccccccccch777hhcccccch7h7777hhhhhhh777hhhhhhhc
ccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccccccccccccccccccccccccccccccccccccccccccch7hhcccccccch7hh777777h777hhhhhhhhhhc
cccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecccccccccccccccccccccccccccccccccccccccccccchhhcccccccchhh7h777hhhhhhhhhhhhhhhhhc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchhhhh777hhhhhhhhhhhhhhhhhc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchhhhhhh7hhhhhhhhhhhhhhhhhhc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchhhhhhh7hhhhhhhhhhhhhhhhhcc
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh777hhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7hhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhchchcchhccchccchcchhcchhccchhcchchchccchccchccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhchchchchhchhcchhchchchchhchhchhhchchhchhcchhhchhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhhh
hhhhchchchchhchhchhhcchhcchhhchhchhhccchhchhchhhhchhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhcchchchhchhhcchchchchchccchhcchchchhchhhcchhchhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeesssesssesssessseessessseesseeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhcchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeseeeseeeseeeseeeseeeeseeseeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhchchccchchchccchhcchhcchchchhhhhhhhhhhhhhhhhhhhhhhhhheeesseesseesseesseeseeeeseessseeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhchchcchhchchhchhchhhchhhchchhhhhhhhhhhhhhhhhhhhhhhhhheeeseeeseeeseeeseeeseeeeseeeeseeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhchchchhhchchhchhhhchchhhccchhhhhhhhhhhhhhhhhhhhhhhhhheeessseseeeseeessseesseeseesseeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhccchhcchhcchhchhcchhhcchchchhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeseeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeseeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeessssssssssssssssssssssssseeseessssssssssssssssssssssssseeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeessseeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhchhhhcchchchccchcchhhcchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeseeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhchhhchchchchcchhchchchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhchhhchchccchchhhcchhhhchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhcchcchhccchhcchchchcchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeee777e777ee77e777e7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeee77ee777e7e7ee7ee777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeee7eee7e7e777ee7eeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhcchhcchccchhcchhcchcchhhhhhcchhccchhcchhhhhhhhhhhhhheeeee77e7e7e7eeee7ee77eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhchchchchhchhchhhchchchchhhhhchchcchhchhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhccchchchhchhhhchchchchchhhhhcchhchhhhhchhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhchhhcchhccchcchhcchhchchhhhhchchhcchcchhhhhhhhhhhhhhheeeeeeee777e77eee77e77ee777e77ee777e777e77ee777eeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeee7ee7e7e7eee7e7e77ee7e7ee7ee77ee7e7ee7eeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeee7ee7e7e7e7e77ee7eee7e7ee7ee7eee7e7ee7eeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeee777e7e7e777e7e7ee77e77ee777ee77e7e7ee7eeeeeeeeeeeeeeeeehhhh
hhhhccchhcchhcchccchchhhccchccchhcchccchccchhcchhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhcchhchchchhhhchhchhhhchhhchhchchhchhcchhchhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhchhhccchchhhhchhchhhhchhhchhccchhchhchhhhhchhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhchhhchchhcchccchhcchccchhchhchchhchhhcchcchhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeee777e777ee77e777e7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeee77ee777e7e7ee7ee777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhcchhcchcchhccchccchcchhccchcchhhcchccchhhhhhhhhhhhhheeee7eee7e7e777ee7eeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhchhhchchchchcchhhchhchchcchhchchchhhcchhhhhhhhhhhhhhheeeee77e7e7e7eeee7ee77eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhchhhchchchchchhhhchhchchchhhchchchhhchhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhcchcchhchchchhhccchcchhhcchchchhcchhcchhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeee777e77eee77e77ee777e77ee777e777e77ee777eeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeee7ee7e7e7eee7e7e77ee7e7ee7ee77ee7e7ee7eeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeee7ee7e7e7e7e77ee7eee7e7ee7ee7eee7e7ee7eeeeeeeeeeeeeeeeehhhh
hhhhccchhcchhcchccchccchhhhhhcchccchhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeee777e7e7e777e7e7ee77e77ee777ee77e7e7ee7eeeeeeeeeeeeeeeeehhhh
hhhhhchhchchchhhhchhcchhhhhhchchcchhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhchhccchhhchhchhchhhhhhhchchchhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhchhchchcchhhchhhcchhhhhcchhchhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeee777e777ee77e777e7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhcchcchhhcchcchhhcchccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeee77ee777e7e7ee7ee777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhchchchchchchchchchhhcchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeee7eee7e7e777ee7eeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhchchcchhccchchchchchchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeee77e7e7e7eeee7ee77eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhcchhchchchchchchccchhcchhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeee777e77eee77e77ee777e77ee777e777e77ee777eeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeee7ee7e7e7eee7e7e77ee7e7ee7ee77ee7e7ee7eeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeee7ee7e7e7e7e77ee7eee7e7ee7ee7eee7e7ee7eeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeee777e7e7e777e7e7ee77e77ee777ee77e7e7ee7eeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeehhhhh
7777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
77777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
77777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
e7777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
e7777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
eee77ccccc111ccccccccccccc111ccccccccccccc111ccccccccccccc111ccccccccccccc111ccccccccccccc111ccccccccccccc111ccccccccccccc111ccc
e7e77sssssccc1ssssssssssssccc1ssssssssssssccc1ssssssssssssccc1ssssssssssssccc1ssssssssssssccc1ssssssssssssccc1ssssssssssssccc1ss
hhe77sshhhsssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1s
77h77hh677hsssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1
777hh67h677hsssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc
67777h67777hsssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc
h67777777677hsssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssss
7h6777767767hsssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssssc1ssssssssssssss
7hh677776777hsss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss
ehss67777777hhss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss
chs66777777h77h1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1
csh66777777777h1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1
sssh66666h776h1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1c
sssshhhhh676h1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cssssssssssssss1cs
ssssssshs66h1cssssssssssss111cssssssssssss111cssssssssssss111cssssssssssss111cssssssssssss111cssssssssssss111cssssssssssss111css
eeeeeeehssheeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh

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
