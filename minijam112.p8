pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- minijam 112: chronos
-- louiechapm & yolwoocle

-- main

debug=""
debugmode=true

sound_on=true

function _init()
	t=0
	anim={}
	
	pal({[0]=129,1,12,14,7,140},1)
	palt(0,false)palt(15,true)
	poke(0x5f2e,1)
	
	--screen shake
	shake=0
	
	c={
		dobj=create_dobj(63,63),
		sel_index=1,
		mode="ingredients"
	}

	ticks={false,false,false}
	time_since_last=0
	dialogue_queue=""
	dialogue_queue_time=0

	pot={
		ingr={},
		ingr_num=0,
		_x=22,
		_y=90,
		name=rnd(potion_types),
		score=0,
		points={}
	}
	
	cur_fx_dobj={
		dobj=create_dobj(3,25),
		target=nil,
		dx=3,
		dy=25,
	}

	potion={
		dobj=create_dobj(50,0),
		target_y=40,
	}

	bubbles={}

	st=0 --spawn time
	spawn_wait_time=80
	conveyor_speed_original=0.2
	conveyor_speed=conveyor_speed_original
	conveyor_active=true

	ailment_manager=
	{
		big_a="", --string containing ailment name
		solutions={}, --list containing all the "solution strings"
		customer=generate_name()
	}

	past_customers={}


	parse_speed=5
	text_parse=""
	ailment=""
	parse_length=0
	parsing=true

	parse_output=""
	ailment_out=""

	ingr_particles={}

	doctor_oy = 0

	new_ailment()

	g_ingredients={
		{
			obj=generate_ingredient(),
			dobj=create_dobj(-20,flr(rnd(10)+95))
		},
	}
end

function _update60()
	t+=1
	
	menuitem(3, "sound: "..(sound_on and "on" or "off"), function() sound_on=not sound_on end)

	if(conveyor_active)st+=1 --only iterate spawn timer is the conveyor is active
	time_since_last+=1


	if dialogue_queue!="" and time_since_last>dialogue_queue_time then
		new_dialogue(unpack(dialogue_queue))
		dialogue_queue=""
	end

	animate_score_mode()

	local nums=split"90,103,173,302"
	for num in all(nums) do
		if(t%num==0)spawn_bubble()
	end

	if dy(cur_fx_dobj.dobj)!=25 and cur_fx_dobj.target==t and c.mode=="ingredients" then
		anim_to_point(cur_fx_dobj,cur_fx_dobj.dx,cur_fx_dobj.dy)
	end

	-- update doctor bop
	doctor_oy=lerp(doctor_oy,0,0.5)
	if(abs(doctor_oy)<0.1)doctor_oy=0
	if parsing and t%5==0 then
		doctor_oy=-2
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
	screen_shake()
	

	draw_pot()
	for b in all(bubbles) do
		circ(b._x,b._y,b.size,4)
	end
	rectfill(-5,110,130,130,0)
	
	draw_conveyor()

	
	draw_effects()
	
	draw_ingredients()
	draw_ingr_particles()
	
	local _text="potion of"
	local _y=dy(potion.dobj)
	text_bold2(_text,hcentre(_text)-35,_y,4,5)
	text_bold2(pot.name,hcentre(pot.name)-35,_y+7,4,5)

	selected_effects()


	rectfill(-5,-5,135,34,2)
	draw_pdoctor()
	draw_bubble()

	draw_ticks()
	
	
	draw_cursor()
	
	
	
	
	print(parse_output,6,5,5)
	print(ailment_out,6,5,4)
	
	if(debugmode)print(debug,1,1,7)
end

-->8
--update

function return_to_belt()
	c.mode="ingredients"
	conveyor_active=true
	ticks={false,false,false}
	new_ailment()
end

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
	if c.mode=="ingredients" then
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
		
			if btnp(❎) and time_since_last>30 then
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
				

				anim_to_point(cur_fx_dobj,nil,10)

				local object={
					obj=generate_ingredient(),
					dobj=create_dobj(-20,95+rnd(10))
				}
				add(g_ingredients,object)

				del(g_ingredients,ingr)
				commit_ingredient(ingr.obj)
	
				cur_fx_dobj.target=t+60

				time_since_last=0
	
				
				c.sel_index=mid(1,c.sel_index,#g_ingredients) --fix cursor
			end
		end
	elseif c.mode=="pot" then
		if btnp(❎) and time_since_last>300 then
			return_to_belt()
		end
	end
end

--spawns objects onto the
--conveyor
function conveyor_spawner()
	if st%spawn_wait_time==0 and conveyor_active then
		local object={
			obj=generate_ingredient(),
			dobj=create_dobj(-20,95+rnd(10))
		}
		add(g_ingredients,object)
	end
end


--commits the selected ingredient
--to the brew , and chooses
--a random effect to add
function commit_ingredient(_ingr)
	local effect=nil

	i=1

	local points=flr(rnd(6))-4
	for _fx in all(_ingr.effects) do
		if in_list(ailment_manager.solutions,_fx) then
			effect=_ingr.effects_modified[i]
			points=flr(rnd(5))+5
		end
		i+=1
	end
	if(not effect)effect=rnd(_ingr.effects_modified)

	add(pot.points,points)
	add(pot.ingr,effect)
	pot.ingr_num+=1


	pot.score+=points

	if	pot.ingr_num>=3 then 
		--cam_y_active=true
		
		c.mode="pot" --change cursor mode
		anim_to_point(c,pot._x,pot._y,0.95)

		anim_to_point(cur_fx_dobj,nil,-50)

		local format=rnd(result_dialogue)

		--check scores and create new dialogue
		if(pot.score>5) then adjectives=positive_adj else adjectives=negative_adj end
		if(flr(rnd(10))==0)adjectives=neutral_adj
		
		--set up dialogue queue
		dialogue_queue=pack(format[1]..ailment_manager.customer.." "..format[2].." ",rnd(adjectives),format[3])
		dialogue_queue_time=120

		--add customer to past_customers list
		add(past_customers,{name=ailment_manager.customer,score=pot.score,cause=ailment_manager.big_a})

		--stop the conveyor
		conveyor_active=false

		--generate new potion name
		pot.name=rnd(potion_types) 

		time_since_last=0

		--new_ailment()
	end
end
-->8
--draw

--draw plague doctor
function draw_pdoctor()
	local _x,_y=89,8
	local oy=doctor_oy

	if parsing then
		sspr(88,0,36,27,_x+2,_y+oy)
	else
		sspr(0,0,36,27,_x,_y+oy)
	end
	pset(_x+19,_y+27+oy,4)
	pset(_x+19,_y+28+oy,4)
	pset(_x+20,_y+27+oy,4)
	pset(_x+18,_y+27+oy,4)
end

function draw_ticks()
	local _x,_y=80,40
	for i=1,3 do
		if ticks[i] then
			local text=pot.points[i] or "0"
			if text>=0 then text="+"..text end
			text_bold(text,_x,_y+i*15,7,1)
		end
	end
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
		local _x=-20+(i*16)+(st*conveyor_speed)%16
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
	local _y=dy(cur_fx_dobj.dobj)
	local ingredient=g_ingredients[c.sel_index]
	for i=1,#ingredient.obj.effects do
		local fx=ingredient.obj.effects_modified[i]
		rrect(2,_y-1+i*13,55,15,1)
		print(fx,4,_y+i*13,4)
	end
end

function animate_score_mode()
	conveyor_speed=conveyor_speed_original
	if(not conveyor_active)conveyor_speed=0

	if(c.mode!="pot")return 

	if(time_since_last>30)anim_to_point(potion,30,potion.target_y)

	--when the secondary text is finished writing
	local text_finish_time=#text_parse*parse_speed+120
	for i=1,3 do
		if time_since_last==30+text_finish_time+i*23 then
			shake=0.07
			ticks[i]=true
		end
	end

	if(time_since_last>text_finish_time+250)return_to_belt()
end


function draw_effects()
	local _x,_y=61,39
	local _w,_h=62,60
	
	rrect(_x,_y,_w,_h,3)
	

	text_wave("effects",_x+5,_y+2,7,5,7)
	line(_x+4,_y+10,_x+_w-4,_y+10,5)
	
	rectfill(_x+(_w*0.5)-2,_y+8,_x+(_w*0.5)+2,_y+12,3)
	line(_x+(_w*0.5)-1,_y+11,_x+(_w*0.5)+1,_y+11,5)
	line(_x+(_w*0.5),_y+8,_x+(_w*0.5),_y+12,5)
	

	local default_text="--EMPTY SLOT-- \n"
	for i=0,2 do
		local text=pot.ingr[i+1] or default_text
		local col=1
		if(pot.ingr[i+1]!=nil)col=7
		print(text,_x+4,_y+14+i*14,col)
	end
	
end


function draw_pot()
	local _x,_y=3,80
	
	sspr(96,64,26,46,_x,_y)
	sspr(96,64,26,46,_x+26,_y,26,46,true)
end

-->8
--recipes

-->8
-- recipies 2

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
		if(flr(rnd(20))==0)then
			effect=rnd(ailment_manager.solutions)
		end
		if not in_list(gen_ingr.effects,effect) then
			add(gen_ingr.effects,effect)
			add(gen_ingr.effects_modified,to_fit(effect,12," "))
		end
	end
	
	spawn_wait_time=st+flr(rnd(100))+20
	--st=0

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

			shake=0.07
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
	ailment_manager.customer=generate_name()

	--reset pot
	pot.ingr={}
	pot.ingr_num=0
	pot.score=0
	pot.points={}

	parse_output=""
    aliment_out="" 

	--reset dialogue
	new_dialogue(generate_dialogue())

	anim_to_point(cur_fx_dobj,cur_fx_dobj.dx,cur_fx_dobj.dy)
end

function generate_name()
	local first_name=rnd(first_names)
	local last_name=rnd(last_names)
	local title=""
	if(flr(rnd(10))==0)title=rnd(titles).." "
	local name=title..first_name.." "..last_name
	return name
end

function generate_dialogue()
	local _text=ailment_manager.customer.." WILL DIE OF "
	local _ailment=ailment_manager.big_a

	return unpack({_text,_ailment," !"})
end

--updates the dialogue
function new_dialogue(_text,_text_bold,_end)
	parse_length=0
	parsing=true

	text_parse=to_fit(_text.._text_bold.._end,18)
	ailment=""
	for i=1,#text_parse do
		local char=sub(text_parse,i,i)
		if char=="\n" then
			ailment..="\n"
		else
			if i<#_text+2 or i>=#text_parse-#_end then
				ailment..=" "
			else
				ailment..=char
			end
		end
	end
	

	parse_output=""
	ailment_out=""	
end

function parse_dialogue()
	if(t%parse_speed!=0)return
	
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
 local out=""
 local _ex=_extra or ""
 local length=#_text
 local brstr=split(_text," ")
 local i=1
 local tmp=""
 local trails=false
 while i<(#brstr+1) do
  if (#tmp+#brstr[i]) <= _w then
            tmp=tmp..brstr[i].." "
            i+=1  
            trails=true
  else
   out=out..tmp.."\n".._ex
   tmp="" 
   trails=false
  end
 end
 if trails then
  out=out..tmp
 end
 return (out)
end

--screen shake function
function screen_shake()
  local fade = 0.95
  local offset_x=16-rnd(32)
  local offset_y=16-rnd(32)
  offset_x*=shake
  offset_y*=shake
  
  camera(offset_x,offset_y)
  shake*=fade
  if shake<0.05 then
    shake=0
  end
end

function hcentre(s)
	if(not s)return 64
	return 64-#s*2
end

--pretty 3d text
function text_bold(_s,_x,_y,_c1,_c2)
	for i in all(split"\-f,\-h,\|f,\|h,\+ff,\+hh,\+fh,\+hf") do
		?i.._s,_x,_y,_c2
	end
	?_s,_x,_y,_c1
end
--pretty 3d text
function text_bold2(_s,_x,_y,_c1,_c2)
	for i in all(split"\-f,\-h,\|f,\|h,\+ff,\+hh,\+fh,\+hf,\|i,,\+fi,\+hi") do
		?i.._s,_x,_y,_c2
	end
	?_s,_x,_y,_c1
end

--wave function text
function text_wave(str,x,y,c,c2,spd)
	for i=0,#str do
		local _y=y
		if t\spd%(#str+15)==i then _y-=1 end
		text_bold(sub(str,i,i),x-6+(i*4),_y,c,c2)
	end
end
-->8
--data

all_effects=split"LOWERS CHOLESTEROL,INCREASES MEMORY,REDUCES MEMORY LOSS,STRENGTHENS BONE MARROW,INCREASES CHARISMA,REJUVENATES HAIR GROWTH,FACILITATES CONFIDENCE,HARDENS SKIN,HIGH IN VITAMIN C,BREAKS FOURTH WALL,INCREASES PUNGENCY,UNTERRICHTET dEUTSCH,FINDS KEYS,GIVES A FEVER,HARDENS LIVER,DRIES MOUTH,INDUCES VOMITING,REMOVES TASTE,INCREASE COORDINATION,TURNS URINE GREEN,AMPLIFIES TINNITUS,EMITS 5G SIGNAL,BOOSTS TASTE,TASTES OF ORANGE,JUST GETS YOU STONED,INCREASES STRENGTH,INCREASES MAGIC,INCREASES RESISTANCE,INCREASES STEALTH,RAISES HIT POINTS,RAISES MAGIC POINTS,RAISES SPEED,INCREASES INTELLIGENCE,LOWERS INTELLIGENCE,LOWERS SPEED,LOWERS HP,DECREASES STEALTH,DECREASES MAGIC,DECREASES STRENGTH,DECREASES DEXTERITY,INCREASES CONSTITUTION,DECREASES CONSTITUTION,INCREASES WISDOM,DECREASES WISDOM,RAISES RECOVERY,INSTILLS PARANOIA,PROBABLY BOOSTS LUCK,FREAKS EVERYONE OUT,INCREASES POISON RES,INCREASES FIRE RES,LOWERS FIRE RES,LOWERS POISON RES,RAISES GLASS CEILING,INSTANT DEATH,RAISES SEX APPEAL,RELEASES PHEROMONES,THICKENS BLOOD,INDUCES STRESS,INDUCES MANIA,INDUCES VOMITING,CURES HANGOVER"
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

result_dialogue={
	split",WONDERS IF THIS WAS AS, FOR YOU AS IT WAS THEM",
	split",THINKS THIS IS, !",
	split",IS GOING TO HAVE A, DAY !",
	split",THINKS YOUR SHOP IS, !",
	split",LEFT FEELING,.",
	split",WROTE THAT YOU WERE, IN THEIR BLOG",
	split",THINKS YOUR POTIONS ARE,.",
	split",HAS NEVER FELT THIS, BEFORE !",
	split",WILL LIKELY SUFFER A, DEATH !",
	split"YOU THOUGHT ,WAS,.",
	split",CANT STOP THINKING ABOUT HOW, YOU WERE",
	split",DOUBTS THEYLL EVER FEEL THIS, AGAIN",
	split"I HEARD ,SHOUT HOW , THEY FELT ONCE OUTSIDE !"
}

potion_types=split"slime,speed,dexterity,anger,anxiety,invisibility,money,freedom,flight,love,romance,restoration,answering,attention,beauty,bravery,chaos,charm,charisma,cowardice,dancing,death,disguise,drunkenness,empathy,floating,fortitude,glowing,groth,happiness,healing,hearing,immunity,leadership,life,luck,loyalty,melting,noise,owl-eyes,shrinking,spiders,terror,strength"

positive_adj=split"GOOD,WONDERFUL,FANTASTIC,ENLIGHTENING,ELECTRIC,LIFE-CHANGING,POWERFUL,FUN,CUTE,ROMANTIC,SEXY,COMELY,CARING,CLEAN,EXCITED,HAPPY,SWEET,BRIGHT,CREATIVE,DYNAMIC,FUNNY,LIKABLE,LOYAL,SINCERE,POLITE,FORTUITOUS,GORGEOUS,REMARKABLE,ROUSING,STELLAR,BRAVE,CAPABLE,PASSIONATE,SENSIBLE"
negative_adj=split"BAD,TERRIBLE,DISGUSTING,OFFENSIVE,UGLY,SUCKY,AWFUL,GARBAGE,POOR,SAD,UNACCEPTABLE,CRUMMY,CHEAP,BORING,NOT GOOD,GROTTY,GRUNGY,INSOLENT,IRRITATED,BORING,HOSTILE,VAIN,IMPATIENT,VAGUE,BLEAK,BLIND,BLOATED,BLOODIED,BLOODTHIRSTY,RUDE,BOSSY,CLUMSY,EMPTY,GLUM,FIENDISH,EXPLOITED,EVIL,SCARED,GROGGY,HUNGOVER,JADED,PUTRID"
neutral_adj=split"WEIRD,STRANGE,OK,NEUTRAL,SMELLY,CREEPY,SPOOKY,GHASTLY,ECCENTRIC,SILLY,PECULIAR,KINKY,FEARFUL,UNCANNY,CAUSTIC,BIZARRE,CORPULENT,DOWDY,FECUND,LIMPID,PERSUASIVE,QUERULOUS,TRENCHANT,TURGID,INCANDESCENT,BUSY,COLD,SHORT"

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
ffff03000330fffffff025520ffffffffff0644444d0fffffffffff00ffffffffff033355330fffffff0d3d44d0fffffffffff0500330fffff000f033440ffff
fff000fff0330fffffff055220fffffffff044600600ffffffffff0420ffffffff0553300000fffffff03d3d4000fffffffff00204330fffff0440333330ffff
fff0fffff0430fffffff022550ffffffffff000d64640ffffffff062250fffffff05000666660ffffff0d3d330250fffffff040250440fffff034033344000ff
ffffffff06430ffffffff0252200fffffff0d464644640fffffff022240fffffff00666640660ffffff00dd0052250fffff034402040ffffff043403340340ff
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
fff000fffffffffff064400400460ffffffff00000fffffffffffff0440fffffffff06606660fffffff0d3d0ffffffffffffffffff00ffffffff0300330fffff
fff011000ffffffff0440ff04460ffffffff03dd330fffffffff00044440fffffff0666464460ffffff03330fffffffffffffff000450fffffff0d330005ffff
ffff01124000fffff0440ff00000fffffff0333dd330fffffff0446444400ffffff0664444440ffffff0d330ffffffffffffff0524040ffffff55000555dffff
fff0111225240ffff0440f0644460ffffff03333d330ffffff044464334640fffff0644444440fffffff033d0ffffffffffff05224040ffffff0555131130fff
ff01100255220ffff0444064444460fffff03333d330ffffff044443333440fffff0644444440fffffff03330ffffffffffff02240420fffff0d33131313d0ff
ff0002452200ffffff044644433440fffff0d333d330fffffff04433333440ffffff064444460fffffff0d330ffffffffffff04404250ffff0d33313113330ff
ff0f02255220fffffff04645333350fffff0d333d330fffffff04633334440ffffff06446640fffffffff03080000fffffffff004250fffff0333331331330ff
fffff00245540fffffff0055333350ffffff0d3333d0fffffff0644336440fffffff06460660fffffffff08008810ffffff00002250ffffff0333331331330ff
ffffff0225220ffffffff064433460fffffff0d33d0ffffffff0444446440ffffffff060f060fffffffff0810000fffffffffff000fffffff0d333313333d0ff
fffffff00f00ffffffffff0644460fffffffff0000ffffffffff04444460fffffffff060f060ffffffffff0811ffffffffffffffffffffffff00d3333d000fff
fffffffffffffffffffffff00000fffffffffffffffffffffffff000000fffffffffff0fff0ffffffffffff000ffffffffffffffffffffffffff000000ffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
222211122222222200000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffff22222222000000
555522215555555500000000000000000000000000000000000000000000000000000000000000000000000000000000fffffffffffff2222211111111000000
555555521555555500000000000000000000000000000000000000000000000000000000000000000000000000000000fffffffff22221111111111111000000
555555552155555500000000000000000000000000000000000000000000000000000000000000000000000000000000fffffff2211111111111111111000000
555555555215555500000000000000000000000000000000000000000000000000000000000000000000000000000000fffff221111111111333333333000000
555555555215555500000000000000000000000000000000000000000000000000000000000000000000000000000000ffff2111111333333333333333000000
555555555521555500000000000000000000000000000000000000000000000000000000000000000000000000000000fff21111333333333333333333000000
555555555521555500000000000000000000000000000000000000000000000000000000000000000000000000000000ff211133333333333333333333000000
555555555512555500000000000000000000000000000000000000000000000000000000000000000000000000000000f2111333333333333333333333000000
555555555512555500000000000000000000000000000000000000000000000000000000000000000000000000000000f2111433333333333333333333000000
555555555125555500000000000000000000000000000000000000000000000000000000000000000000000000000000f2111143333333333333333333000000
555555555125555500000000000000000000000000000000000000000000000000000000000000000000000000000000f2111114443333333333333333000000
555555551255555500000000000000000000000000000000000000000000000000000000000000000000000000000000f2114111114444333333333333000000
555555512555555500000000000000000000000000000000000000000000000000000000000000000000000000000000ff211441111111444444444444000000
555511125555555500000000000000000000000000000000000000000000000000000000000000000000000000000000ff211114411111111111111111000000
00555555555555ff00000000000000000000000000000000000000000000000000000000000000000000000000000000ff211111144441111111111111000000
ffff00000000ffff00000000000000000000000000000000000000000000000000000000000000000000000000000000f2111111111114444411111111000000
fff0444444440fff00000000000000000000000000000000000000000000000000000000000000000000000000000000f2111111111111111144444444000000
ff04ffffffff40ff00000000000000000000000000000000000000000000000000000000000000000000000000000000f2111111111111111111111111000000
ff04f444444f40ff0000000000000000000000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
fff04ffffff40fff0000000000000000000000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
ffff04444440ffff0000000000000000000000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
ffff04555540ffff0000000000000000000000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
ffff04355340ffff0000000000000000000000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
fff0433333340fff0000000000000000000000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
ff043333333340ff0000000000000000000000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
f04344333333340f0000000000000000000000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
f04344333333340f0000000000000000000000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
f04433333333340f0000000000000000000000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
ff044333333440ff0000000000000000000000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
fff0044444400fff0000000000000000000000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
fffff000000fffff0000000000000000000000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2111111111111111111111111000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff211111111111111111111111000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fff21111111111111111111111000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fff21111111111111111111111000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffff2111111111111111111111000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffff2211111111111111111111000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffff222111111111111111111000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffff2211111111111111111000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffffff22211111111111111000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffffffff222111111111111000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffffffffff2221111111111000000
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
