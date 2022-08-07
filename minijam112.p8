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
	
	--camera
	shake=0
	intro_phase=0
	cam={
		dobj=create_dobj(0,-91),
	}

	report={
		dobj=create_dobj(130,-90),
		target_x=24,

		last_input=0,

		step=1,

		adj1="",

		sticker=false,
		sticker_spr=130+flr(rnd(5))*2,
		sticker_ox=rnd(6)-3,
		sticker_oy=rnd(6)-3,

		cur_mark=0,

		signature=false,
	}
	
	c={
		dobj=create_dobj(63,63),
		sel_index=1,
		mode="menu"
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

	dead_list=""
	dead_list_obj={
		dobj=create_dobj(128,-87)
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
	hide_bubble=false

	ingr_particles={}

	doctor_oy = 0

	new_ailment()

	g_ingredients={
		{
			obj=generate_ingredient(),
			dobj=create_dobj(-20,flr(rnd(10)+95))
		},
	}

	bubble_dobj=create_dobj(0,-10)
	speech_arrow_up=false

	clock=0
	maxclock=60*10 -- be careful about overflowing the tiny p8 limit
	-- clock=maxclock
	report_shifted_on_right = false
	main_menu = true

	if(debugmode) parse_speed = 1
end

function _update60()
	t+=1
	
	update_time()
	on_speech_end()

	if(report_shifted_on_right) dead_list_obj.dobj.oy-=1/6

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
		doctor_oy+=1
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
	camera(dx(cam.dobj),dy(cam.dobj))
	

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


	-- rectfill(-5,-5,135,34,2)
	rectfill(-5,-120,135,34,2)

	draw_report()

	if(intro_phase>=1) draw_time()

	-- draw dead list
	local x,y=dx(dead_list_obj.dobj),dy(dead_list_obj.dobj)
	rrect(x,-87+1,61,90,1)
	rrect(x,-87  ,61,90,4)
	print(dead_list,x+1,y,5)
	rectfill(x,5,127,3+31, 8)
	
	draw_pdoctor()
	draw_bubble()

	draw_ticks()
	
	
	draw_cursor()
	
	-- draw dialogue / bubble / speech
	if(not hide_bubble)then
		print(parse_output,6,5+dy(bubble_dobj),5)
		print(ailment_out,6,5+dy(bubble_dobj),3)
	end

	-- draw logo
	if (main_menu) then
		local camy = dy(cam.dobj)
		sspr(0,100,91,28, 18,camy+18 + sin(t/120)*3*0.99)
	end
	
	if(debugmode)print("debug",1,dy(cam.dobj),8)
end

-->8
--update

function update_dead_list()
	local out=" "
	local ways_to_die=split" WAS NEVER SEEN AGAIN, STILL GETS NIGHTMARES, HASNT STOPPED CRYING,'S FAMILY MISSES THEM, NEVER MADE IT HOME, WILL NEVER RETURN, DIED A GRUESOME DEATH, LEFT THEIR WALLET, NOW SUFFERS FROM ANXIETY, HASNT EATEN IN DAYS, WAS ARRESTED, IS NOW IN JAIL, SUFFERED A FATE WORSE THAN DEATH, IS NOT THE SAME ANYMORE"
	local died_of_variations=split" DIED OF , PERISHED OF "
	local list_h=0
	for customer in all(past_customers) do
		--if customer.score<0 then
		--	out..=to_fit(customer.name.." DIED OF "..customer.cause.."\n\n",14)
		--end
		local fate=rnd(ways_to_die)
		if(flr(rnd(2))==0)fate=rnd(died_of_variations)..customer.cause
		local fit=to_fit(customer.name..fate.."\n\n",11)
		out..=fit
		
		-- count number of lines
		local h=1
		for i=1,#fit do
			if(sub(fit,i,i)=="\n")h+=1
		end
		list_h+=h
	end

	dead_list_obj.dobj._y=-110
	dead_list_obj.dobj.oy=0
	dead_list=out
end

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

				sfx(58)
	
				cur_fx_dobj.target=t+60

				time_since_last=0
	
				
				c.sel_index=mid(1,c.sel_index,#g_ingredients) --fix cursor
			end
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
		if(pot.score>5) then
			adjectives=positive_adj 
		elseif(pot.score<5) then
			adjectives=negative_adj
		else
			adjectives=neutral_adj
		end
		
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

function update_time()
	if(c.mode=="ingredients")clock+=1

	if clock==maxclock then
		--end game
		c.mode="report"
		clock=0
		conveyor_active=false

		--anim_to_point(c,,130,0.97)

		dialogue_queue=pack("LOOKS LIKE IT'S TIME TO CLOSE UP SHOP ","","")
		dialogue_queue_time=30
		time_since_last=0
	end

	if(c.mode!="report")return

	local _x,_y=dx(report.dobj),dy(report.dobj)

	if time_since_last==0 then
		anim_to_point(c,nil,150,0.9)
	end

	if time_since_last==350 then
		anim_to_point({dobj=bubble_dobj}, 0, -10, 0.9)
		speech_arrow_up=false
		anim_to_point(cam, 0, -91, 0.9)
	end

	if time_since_last==430 then
		new_dialogue("WHAT A"," WONDERFUL ","DAY !")
	end

	if time_since_last==700 then
		hide_bubble=true
		anim_to_point(report, report.target_x, nil, 0.9)
	end

	if(time_since_last==720)anim_to_point(c,_x+10,_y+25)

	--report card input loop
	if(time_since_last>750 and time_since_last>report.last_input+60 and btnp(❎)) then

		if(report.step==1)report.adj1=rnd(positive_adj)
		if(report.step==2)report.sticker_ox=-3+rnd(6)report.sticker_oy=-3+rnd(6)report.sticker=true
		if(report.step>2 and report.step<=7)report.cur_mark+=1
		if(report.step==8)report.signature=true

		if(report.step!=0)sfx(47+report.step)shake=0.1
		if(report.step==8)sfx(55)shake=0.2

		if(report.step==1)anim_to_point(c,_x+70,_y+30)
		if(report.step>=2 and report.step<=6)anim_to_point(c,_x+10,_y+43+((report.step-2)*8))
		if(report.step==7)anim_to_point(c,_x+50,_y+90)
		
	

		report.last_input=time_since_last
		report.step+=1
	end

	if time_since_last==1100 then
		-- Shift report card to left
		anim_to_point(report, report.target_x-23, nil, 0.9)
		anim_to_point(c,c.dobj.wx-23,nil,0.9)
		anim_to_point(dead_list_obj, 83, nil, 0.9)
		report_shifted_on_right = true

		update_dead_list()
	end
end

function draw_time()
	if(c.mode=="report")return -- "this is scuffed as fuck I hate this line" - Louie

	local leftt = maxclock - clock
	local leftsecs= leftt\60
	local timesec = leftsecs%60
	local timemin = leftsecs\60
	local m = sub("000"..tostr(flr(timesec)), -2,-1)
	local h = sub("   "..tostr(flr(timemin)), -2,-1)
	
	-- flashing text
	ocol = 4
	if (leftsecs<=30 and t%60<=30) ocol=3
	text_bold(h..":"..m,105,3, 0,ocol)
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
	if(hide_bubble)return	
	local _x,_y=3,3
	local _w,_h=78,28
	local ox = 0
	local oy = dy(bubble_dobj)

	--78 is normal width
	_w=min(8+#parse_output*4,78)
	
	rrect(_x,_y+oy+1,_w,_h,1)
	rrect(_x,_y+oy,_w,_h,4)
	local spry=speech_arrow_up and 4 or 20
	sspr(0,27,7,5, _x+_w+1, _y+spry+oy+1)
	sspr(37,0,7,5, _x+_w+1, _y+spry+oy)
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

function draw_report()
	local _x,_y=dx(report.dobj),dy(report.dobj)
	local _w,_h=80,100

	rectfill(_x,_y,_x+_w,_y+_h,7)
	rect(_x,_y,_x+_w,_y+_h,5)

	text_bold2("SELF-REPORT CARD",_x+3,_y+2,7,1)
	line(_x+3,_y+10,_x+_w-3,_y+10,1)

	rect(_x+60,_y+22,_x+75,_y+37,6) --sticker area

	text_bold("TODAY I AM FEELING",_x+3,_y+13,7,1)
	text_bold(" - "..report.adj1,_x+3,_y+20,7,5)

	if(report.sticker)spr(report.sticker_spr,_x+60+report.sticker_ox,_y+22+report.sticker_oy,2,2)

	line(_x+3,_y+29,_x+_w-25,_y+29,1)

	text_bold("TODAY I...",_x+3,_y+35,7,1)

	local i=0
	for text in all(split"TRIED MY BEST,HELPED TIDY,USED MY MANNERS,ATE ALL MY FOOD,STAYED FOCUSED") do
		text_bold("[] "..text,_x+5,_y+43+i*8,7,5)
		i+=1
	end

	for i=1,5 do
		if(report.cur_mark>=i)spr(21,_x+5,_y+41+((i-1)*8))
	end

	local y_cont=43+(i*8)+2
	line(_x+3,_y+y_cont,_x+_w-3,_y+y_cont,1)

	text_bold2("SIGNED:",_x+4,_y+_h-10,7,1)
	line(_x+35,_y+_h-5,_x+_w-5,_y+_h-5,6)

	local sx,sy,sw,sh=39,21,41,8

	if(report.signature)sspr(sx,sy,sw,sh,_x+35,_y+_h-12)

	line(_x,_y+_h+1,_x+_w,_y+_h+1,0)

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

	--debug=time_since_last

	if(c.mode!="pot")return 

	if(time_since_last>30)anim_to_point(potion,30,potion.target_y)

	--when the secondary text is finished writing
	local text_finish_time=#text_parse*parse_speed+120
	for i=1,3 do
		if time_since_last==30+text_finish_time+i*23 then
			shake=0.07
			ticks[i]=true
			sfx(59)
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
	

	-- local default_text="--EMPTY SLOT-- \n"
	local default_text="- \n"
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

function on_speech_end()
	if intro_phase==0 and parsing==false and c.mode=="menu" and btnp(❎) then
		intro_phase=1

		anim_to_point(cam, 0,0, 0.9)
		anim_to_point({dobj=bubble_dobj}, 0,0, 0.9)
		speech_arrow_up=true
		c.mode="ingredients"

		clock=0

		time_since_last=0
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
		
		-- Land in pot
		if p.spawn>35 and dy(p.dobj)>80 then
			local bubble_amount=10
			local _vx=40
			local _vy=20
			for i=0,bubble_amount do
				spawn_bubble(p._tx+8,p._ty+16,rnd(_vx)-(_vx*0.5),-rnd(_vy),0.01)
			end

			del(ingr_particles,p)

			shake=0.07
			sfx(60)
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
	local unfilt_brstr=split(_text," ")
	local tmp=""
	local trails=false
	--clean up input
	local brstr={}
	-- local i=1
	for i=1,#unfilt_brstr do
		local word = unfilt_brstr[i]
		if #word > _w then
			local a,b = sub(word,1,_w), sub(word,_w+1,-1)
			add(brstr,a)
			add(brstr,b)
		else
			add(brstr,word)
		end
	end

-- [[
	local i=1
	local h=0
	while i<(#brstr+1) do
		if (#tmp+#brstr[i]) <= _w then
		    tmp=tmp..brstr[i].." "
		    i+=1  
		    trails=true
		else
			out=out..tmp.."\n".._ex
			tmp="" 
			trails=false
			h+=1
		end
	end
	if trails then
		out=out..tmp
	end
	return out
--]]
end

--screen shake function
function screen_shake()
  local fade = 0.95
  local offset_x=16-rnd(32)
  local offset_y=16-rnd(32)
  offset_x*=shake
  offset_y*=shake

  cam.dobj.ox=offset_x
  cam.dobj.oy=offset_y
  
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

all_effects=split"SUMMONS GIANT PEACH,GLOWS IN THE DARK,FINISHES YOUR ESSAY,SUMMONS A TORNADO,FACILITATES DIGESTION,MELTS FACE,FIGHTS POVERTY,SMELLS LIKE TEEN SPIRIT,TURNS INTO A SWORD,TURNS INTO A TOAD,SETS YOU ON FIRE,RELEASES INHIBITIONS,INCREASES MULTITASKING,LOWERS CHOLESTEROL,INCREASES MEMORY,REDUCES MEMORY LOSS,STRENGTHENS BONE MARROW,INCREASES CHARISMA,REJUVENATES HAIR GROWTH,FACILITATES CONFIDENCE,HARDENS SKIN,HIGH IN VITAMIN C,BREAKS FOURTH WALL,INCREASES PUNGENCY,UNTERRICHTET dEUTSCH,FINDS KEYS,GIVES A FEVER,HARDENS LIVER,DRIES MOUTH,INDUCES VOMITING,REMOVES TASTE,INCREASE COORDINATION,TURNS URINE GREEN,AMPLIFIES TINNITUS,EMITS 5G SIGNAL,BOOSTS TASTE,TASTES OF ORANGE,JUST GETS YOU STONED,INCREASES STRENGTH,INCREASES MAGIC,INCREASES RESISTANCE,INCREASES STEALTH,RAISES HIT POINTS,RAISES MAGIC POINTS,RAISES SPEED,INCREASES INTELLIGENCE,LOWERS INTELLIGENCE,LOWERS SPEED,LOWERS HP,DECREASES STEALTH,DECREASES MAGIC,DECREASES STRENGTH,DECREASES DEXTERITY,INCREASES CONSTITUTION,DECREASES CONSTITUTION,INCREASES WISDOM,DECREASES WISDOM,RAISES RECOVERY,INSTILLS PARANOIA,PROBABLY BOOSTS LUCK,FREAKS EVERYONE OUT,INCREASES POISON RES,INCREASES FIRE RES,LOWERS FIRE RES,LOWERS POISON RES,RAISES GLASS CEILING,INSTANT DEATH,RAISES SEX APPEAL,RELEASES PHEROMONES,THICKENS BLOOD,INDUCES STRESS,INDUCES MANIA,INDUCES VOMITING,CURES HANGOVER"
--TURNS INTO DRAGON,MAKES YOU SHRINK
all_solutions={
	"A BROKEN HEART|HIGH IN VITAMIN C,LOWERS CHOLESTEROL,RAISES SEX APPEAL,RELEASES PHEROMONES,FACILITATES CONFIDENCE,HARDENS SKIN",
	"BAD BODY ODOUR|RELEASES PHEROMONES,HIGH IN VITAMIN C,INCREASES CHARISMA,HARDENS SKIN,REMOVES TASTE,TASTES OF ORANGE",
	"LOW BLOOD PRESSURE|LOWERS CHOLESTEROL,HIGH IN VITAMIN C",
	"SOCIAL REJECTION|EMITS 5G SIGNAL,FACILITATES CONFIDENCE,RAISES SEX APPEAL,RELEASES PHEROMONES,BREAKS FOURTH WALL,JUST GETS YOU STONED",
	"BEING STABBED|FACILITATES CONFIDENCE,INCREASES CHARISMA,HARDENS SKIN,RAISES HP",
	"A BEAR ATTACK|RAISES HP,RAISES RECOVERY,HARDENS SKIN",
	"GANG VIOLENCE|RELEASES INHIBITIONS,INDUCES VOMITING,RAISES SPEED,RAISES HP,INCREASES STEALTH,PROBABLY BOOSTS LUCK,FREAKS EVERYONE OUT",
	"DRINKING THE WRONG POTION|INCREASES PUNGENCY,INCREASES INTELLIGENCE,INCREASES MEMORY,REDUCES MEMORY LOSS",
	"BEING ON THEIR PHONE WHILE DRIVING|INCREASES WISDOM,INCREASES MULTITASKING,INCREASES INTELLIGENCE",
	"FREEZING|SETS YOU ON FIRE,RAISES RECOVERY",
	"LEAVING THE OVEN ON|INCREASE COORDINATION,INCREASES FIRE RES",
	"A GUNSHOT|RAISES HP,HARDENS SKIN,INCREASES RESISTANCE",
	"NOT KNOWING WHEN TO HOLD 'EM|INCREASES STEALTH,FREAKS EVERYONE OUT",
	"WEAK BONES|STRENGTHENS BONE MARROW,HIGH IN VITAMIN C",
	"BALDING|REJUVENATES HAIR GROWTH,INCREASES CHARISMA",
	"LOSING THEIR KEYS|FINDS KEYS,INSTILLS PARANOIA,INCREASES WISDOM,INCREASES MEMORY,REDUCES MEMORY LOSS",
	"NOT SPEAKING GERMAN|UNTERRICHTET dEUTSCH",
	"FALLING OFF THEIR HORSE|INCREASE COORDINATION",
	"DRINKING TOO MUCH|HARDENS LIVER,INDUCES VOMITING,RELEASES INHIBITIONS",
	"A FIREBALL|INCREASES FIRE RES,HARDENS SKIN",
	"A SUDDEN STROKE|LOWERS CHOLESTEROL,INSTANT DEATH",
	"OLD AGE|LOWERS CHOLESTEROL,HARDENS LIVER,RAISES HP",
	"NO INTERNET|EMITS 5G SIGNAL",
	"BOREDOM|TURNS INTO A SWORD,INSTANT DEATH,INSTILLS PARANOIA,JUST GETS YOU STONED,EMITS 5G SIGNAL,AMPLIFIES TINNITUS,TURNS URINE GREEN,SETS YOU ON FIRE,REJUVENATES HAIR GROWTH,FINDS KEYS",
	"AGGRESSIVE SEALIFE|INCREASES STRENGTH,FACILITATES CONFIDENCE",
	"HUNGER|SUMMONS GIANT PEACH,FACILITATES DIGESTION,HIGH IN VITAMIN C,REMOVES TASTE,TASTES OF ORANGE,JUST GETS YOU STONED",
	"NOT BEING TO HANDLE OUR STRONGEST POTION|TURNS INTO DRAGON,RAISES HP,INCREASES MAGIC,INCREASES RESISTANCE,INCREASES STRENGTH,FACILITATES DIGESTION,",
	"DISCOVERING DYNAMITE|INCREASES RESISTANCE,RAISES HP,STRENGTHENS BONE MARROW,HARDENS SKIN",
	"CONSTIPATION|FACILITATES DIGESTION,TURNS INTO A TOAD",
	"POVERTY|INCREASES INTELLIGENCE,TURNS INTO A TOAD,INCREASES CHARISMA,FACILITATES CONFIDENCE",
	"BEING UGLY|INCREASES STEALTH,INCREASES CHARISMA,JUST GETS YOU STONED",
	-- "COMEDY|BREAKS FOURTH WALL",
}

titles=split"SIR,COUNT,BARON VON,DUCHES,PRINCE,KING,QUEEN,DOCTOR"
first_names=split"HARLAN,EDEN,EARNA,PAIGE,EDOLIE,WINFRED,LINDLEY,GRAHAM,HARLOW,ALLURA,WILTON,NORMA,GREYSEN,OPELINE,CARREEN,TIMOTHEA,EALHSTAN,GIMLI,OSCAR,ROHESIA,OPELINE,LUELLA,HEATH,BRIAR,DEAN"
last_names=split"GRAHAMES,HUMES,HARFORDE,DARWINE,GOODEE,ELWINE,EDISONE,SWEETE,TATUME,DYRE,BYRD,WEBBE,HEDLEYE,EVERLYE,HARRISE,FAIRBAIRNS,WESTCOTTE,EDGARE"

result_dialogue={
	split",WONDERS IF THIS WAS AS, FOR YOU AS IT WAS FOR THEM",
	split",THINKS THIS IS, !",
	split",IS GOING TO HAVE A, DAY !",
	split",THINKS YOUR SHOP IS, !",
	split",LEFT FEELING,.",
	split",WROTE THAT YOU WERE, IN THEIR BLOG",
	split",THINKS YOUR POTIONS ARE,.",
	split",HAS NEVER FELT THIS, BEFORE !",
	split",WILL LIKELY SUFFER A, DEATH !",
	split"YOU THOUGHT ,WAS,.",
	split",CAN'T STOP THINKING ABOUT HOW, YOU WERE",
	split",DOUBTS THEY'LL EVER FEEL THIS, AGAIN",
	split"I HEARD ,SHOUT HOW, THEY FELT ONCE OUTSIDE !",
	split",WONDERS IF THIS IS AS, AS IT GETS !",
}

potion_types=split"jumping,wonder,slime,speed,dexterity,anger,anxiety,invisibility,money,freedom,flight,love,romance,restoration,answering,attention,beauty,bravery,chaos,charm,charisma,cowardice,dancing,death,disguise,drunkenness,empathy,floating,fortitude,glowing,growth,happiness,healing,hearing,immunity,leadership,life,luck,loyalty,melting,noise,owl-eyes,shrinking,spiders,terror,strength"

positive_adj=split"FASCINATING,COURAGEOUS,GOOD,WONDERFUL,FANTASTIC,ENLIGHTENING,ELECTRIC,LIFE-CHANGING,POWERFUL,INCANDESCENT,FUN,CUTE,ROMANTIC,SEXY,COMELY,CARING,CLEAN,EXCITED,HAPPY,SWEET,BRIGHT,CREATIVE,DYNAMIC,FUNNY,LIKABLE,LOYAL,SINCERE,POLITE,FORTUITOUS,GORGEOUS,REMARKABLE,ROUSING,STELLAR,BRAVE,CAPABLE,PASSIONATE,SENSIBLE"
negative_adj=split"ASTOUNDING,WEIRD,BAD,SMELLY,CREEPY,SPOOKY,FEARFUL,UNCANNY,GHASTLY,ECCENTRIC,TERRIBLE,DISGUSTING,OFFENSIVE,UGLY,SUCKY,AWFUL,GARBAGE,POOR,SAD,UNACCEPTABLE,CRUMMY,CHEAP,BORING,NOT GOOD,GROTTY,GRUNGY,INSOLENT,IRRITATED,HOSTILE,VAIN,IMPATIENT,BLEAK,BLIND,BLOATED,BLOODIED,BLOODTHIRSTY,RUDE,BOSSY,CLUMSY,EMPTY,GLUM,FIENDISH,EXPLOITED,EVIL,SCARED,GROGGY,HUNGOVER,JADED,PUTRID"
neutral_adj=split"OK,NEUTRAL,SILLY,PECULIAR,KINKY,CAUSTIC,BIZARRE,DOWDY,BUSY,COLD,SHINY,REFLECTIVE,DRUNK,HIGH,SPONGE-Y,LIQUID,AROUSING,BRIGHT,SULFURIC"

__gfx__
fffffffffffffffffff000000ffffffffffff444444f0000f00fffff000fffffffffffffffffffff00000000fffffffffffffffffffffffffffffffffffff000
ffffffffffffffff00004444000ffffffffff444444400000440ff006440ffffffffffffffffffff00000000fffffffffffffffffffffffffffffffffffff000
fffffffffffffff0044444444400fffffffff444444400000444006406440fffffffffffffffffff00000000fffffffffffffffff00000000ffffffffffff000
fffffffffffffff04440000044400ffffffff444444400000644440644440fffffffffffffffffff00000000fffffffffffffff00444444440fffffffffff000
ffffffffffffff0440000000044400fffffff444444f0000f0644444446440ffffffffffffffffff00000000fffffffffffff00444444444440ffffffffff000
ffffffffffffff0400000000004440fffffff00000000000ff064444644640ffffffffffffffffff00000000ffffffffffff004444444444440ffffffffff000
ffffffffffffff00044444000044400ffffff00000000000ff006444464440ffffffffffffffffff00000000ffffffffffff0440000000004440fffffffff000
ffffffffffffff00044444440004440ffffff00000000000ff0dd6444444400fffffffffffffffff00000000ffffffffffff0000000000000440fffffffff000
ffffffffffffff00444444440004440ffffff000fffff3ffff0d664444440440ffffffffffffffff00000000ffffffffffff0000000000000440fffffffff000
fffffffffffff000444000444004440ffffff000ffff343ffff0664444444440ffffffffffffffff00000000ffffffffffff0044444444000000f00ffffff000
ffffffffff000444440440044004440ffffff000ffff343fffff06666604460fffffffffffffffff00000000ffffffffffff04444444440444440000fffff000
fffffffff0444444440440044404440ffffff000f333443ffffff000006460ffffffffffffffffff00000000fffffffffff0004400000440044400000ffff000
fffffff0044444444440000440044400fffff000344343ffffffffff0d660fffffffffffffffffff00000000ffffffffff00444404400440044000000ffff000
fffff004444444444444444040444400fffff000f34443ffffffffff0dd0ffffffffffffffffffff00000000ffffffff00444444400004400000000000fff000
fff00044444444444444444040444000fffff000ff3343fffffffffff00fffffffffffffffffffff00000000fffffff0044444444444404044000000000ff000
ff004444444444444444440400444000fffff000ffff3fff0000000000000000ffffffffffffffff00000000ffffff00444444444444404004000000000ff000
f004444440000000004444400044000ffffff000000000000000000000000000000000000000000000000000fffff0044444444444444040044000000000f000
f04440000ffffff0400000000440000ffffff000000000000000000000000000000000000000000000000000ffff04444444444444444400444000000000f000
04400ffffffffff004000000444000fffffff000000000000000000000000000000000000000000000000000fff0444444400000000000044440400000000000
000fffffffffffff0444444440000400fffff000000000000000000000000000000000000000000000000000ff0444440000ff04000000044400400000000000
ffffffffffffff000444444440000440fffff000000000000000000000000000000000000000000000000000f0444400fffff004444444444000440000000000
ffffffffffffff04004400000044440000fff00fffffffff333ffffffffffffffffffffff33333ff00000000044400ffffff0404444000000044400000000000
ffffffffffffff04404444404400000000fff003333333ff3f3fff3333fffffffff3fffff3ffffff000000000400ffffffff0400444444044400000000000000
fffffffffffff0004044400000000000000ff00f33ffff3f3f3fff3fff3ff3333ff3fffff3ffffff00000000000ffffffff00040444000000000000000000000
fffffffffffff00000444000000000000000f00f3fffff3f3f333f3fff3ff3fffff3fffff333ffff00000000fffffffffff00000444000000000000000000000
ffffffffffff000000040000000000000000f003ffffff3f3fff3f333333f3fffff3ff33ff3fffff00000000ffffffffff00000004000000000000000000f000
ffffffffffff000000040000000000000000f0033fffff3ff3ffff3ffff3f33ffff333ffff33333300000000ffffffffff0000000400000000000000000ff000
111111f00000000000000000000000000000000f33333f3fffffff3fffffff333fffffffffffffff000000000000000000000000000000000000000000000000
111111100000000000000000000000000000000fffff33ffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
11111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111111f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
ff0f02255220fffffff04645333350fffff0d333d330fffffff04633334440ffffff06446640fffffffff03040000fffffffff004250fffff0333331331330ff
fffff00245540fffffff0055333350ffffff0d3333d0fffffff0644336440fffffff06460660fffffffff04004410ffffff00002250ffffff0333331331330ff
ffffff0225220ffffffff064433460fffffff0d33d0ffffffff0444446440ffffffff060f060fffffffff0410000fffffffffff000fffffff0d333313333d0ff
fffffff00f00ffffffffff0644460fffffffff0000ffffffffff04444460fffffffff060f060ffffffffff0411ffffffffffffffffffffffff00d3333d000fff
fffffffffffffffffffffff00000fffffffffffffffffffffffff000000fffffffffff0fff0ffffffffffff000ffffffffffffffffffffffffff000000ffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
2222111222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222000000
5555222155555555fffff111111ffffffffff111111ffffffffff111111ffffffffff111111ffffffffff111111ffffffffffffffffff2222211111111000000
5555555215555555fff1113333111ffffff1113333111ffffff1113333111ffffff1113333111ffffff1113333111ffffffffffff22221111111111111000000
5555555521555555ff11d333333d11ffff11d333333d11ffff11d333333d11ffff11d333333d11ffff11d333333d11fffffffff2211111111111111111000000
5555555552155555ff1d33333333d1ffff1d33333333d1ffff1d33333333d1ffff1d34333343d1ffff1d33333333d1fffffff221111111111333333333000000
5555555552155555f11334333343311ff11444333344411ff11334333343311ff11344433444311ff11334433443311fffff2111111333333333333333000000
5555555555215555f13344433444331ff13334433443331ff13344433444331ff13344433444331ff13334433443331ffff21111333333333333333333000000
5555555555215555f13343433434331ff13344433444331ff13343433434331ff13334333343331ff13334433443331fff211133333333333333333333000000
5555555555125555f13333333333331ff13333333333331ff13333333333331ff13333333333331ff13334433443331ff2111333333333333333333333000000
5555555555125555f13344444444331ff13334444443331ff13343333334331ff13344444444331ff13433333333431ff2111433333333333333333333000000
5555555551255555f11344444444311ff11334444443311ff11334444443311ff11344444444311ff11344333344311ff2111143333333333333333333000000
5555555551255555ff1d34444443d1ffff1d33444433d1ffff1d33444433d1ffff1d34444443d1ffff1d34444443d1fff2111114443333333333333333000000
5555555512555555ff11d344443d11ffff11d333333d11ffff11d333333d11ffff11d344443d11ffff11d333333d11fff2114111114444333333333333000000
5555555125555555fff1113333111ffffff1113333111ffffff1113333111ffffff1113333111ffffff1113333111fffff211441111111444444444444000000
5555111255555555fffff111111ffffffffff111111ffffffffff111111ffffffffff111111ffffffffff111111fffffff211114411111111111111111000000
00555555555555ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff211111144441111111111111000000
ffff00000000ffffffffffffffffff000f00000000000000000000000000000000000000000000000000000000000000f2111111111114444411111111000000
fff0444444440ffffffffffffffff0466000000000000000000000000000000000000000000000000000000000000000f2111111111111111144444444000000
ff04ffffffff40fffffffffffffff066d000000000000000000000000000000000000000000000000000000000000000f2111111111111111111111111000000
ff04f444444f40ffffffffffffff06d00f0000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
fff04ffffff40fffffffffffffff060fff0000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
ffff04444440fffffffffffffff06d0fff0000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
ffff04555540fffffffffffffff060ffff0000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
ffff04355340ffffffffffffff06d0ffff0000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
fff0433333340fffffffffffff060fffff0000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
ff043333333340fffffffffff06d0fffff0000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
f04344333333340ffffffffff060ffffff0000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
f04344333333340fffffffff06d0ffffff0000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
f04433333333340fffffffff060fffffff0000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
ff044333333440fffff000006d0fffffff0000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
fff0044444400ffff006666660ffffffff0000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
fffff000000fffff06d6446d60ffffffff0000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
00000000000000000d6dddd60fffffffff0000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
0000000000000000f0d66660ffffffffff0000000000000000000000000000000000000000000000000000000000000021111111111111111111111111000000
0000000000000000ff00000fffffffffff00000000000000000000000000000000000000000000000000000000000000f2111111111111111111111111000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff211111111111111111111111000000
ffff55555555555555fffffffff5555555555555555555555555555555ff555555555555555555555555555ffff00000fff21111111111111111111111000000
ff555555555555555555555555555555555555555555555555555555555555555555555555555555555555555ff00000fff21111111111111111111111000000
f55555533335555555555555555555555553355555555553555555555555555333333555555555555555555555f00000ffff2111111111111111111111000000
f55555344443555555555555555555555534435555555534355555555555553444444355555555555555555555f00000ffff2211111111111111111111000000
f55553433344353555555555555555555533443555555344435555555555534434434433555555535555555555f00000fffff222111111111111111111000000
f55534433334434353335553335555333533443553335344335333555555533334433334353335343533355555f00000fffffff2211111111111111111000000
f55534434334433434443534443553444333443534443343333444335555533334433333434443334344435555f00000fffffffff22211111111111111000000
f55533434434433444344343344334433433443344334333344434443555555534435533444344334443443555f00000fffffffffff222111111111111000000
f55534433434433443343333344334433333443344343333334443333555555534435553443344334433443555f00000fffffffffffff2221111111111000000
ff553443333443344333333434433443333344334433335533334333355555553443555343334433443344355ff00000ffffffffffffffff2222222222000000
f55533433334333443333344444334433333343344433555533334435555553333433353443344334433433555f00000ffffffffffffffffffffffffff000000
f55533443334333443555344344334433433443344334355344434443555534434434433443344334433443555f00000ffffffffffffffffffffffffff000000
f55553344443333444355334344334434433444344344355333444333555533444444333443344334433443555f0000000000000000000000000000000000000
f55553333333334333355333433433443334333334433355333343333555533333333334333333343333333555f0000000000000000000000000000000000000
f55555333333533333355533333333333333333333333355553333335555555333333333333333333333333355f0000000000000000000000000000000000000
f55555555555533355555553333333333533355533335555555333355555555555555553335555533355555555f0000000000000000000000000000000000000
f55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555f0000000000000000000000000000000000000
ff555555555555555555555555555555555555555555555555555555555555555555555555555555555555555ff0000000000000000000000000000000000000
ff555555555555555555551115555555555555555555555555555555555555555555555555555555511555555ff0000000000000000000000000000000000000
ff11111111111111111111fff11111111111111111111111111111111111111111111111111111111ff111111ff0000000000000000000000000000000000000
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000
ffffff444f444f444f444f444f444ff44f444fffff444f444f4fff444f444f444f444f444f444f444f444ffffff0000000000000000000000000000000000000
ffffff454f454f454f455f545f545f455f445fffff444f454f4fff454f454f454f455f545f545f455f445ffffff0000000000000000000000000000000000000
ffffff444f445f444f4ffff4fff4ff5f4f45ffffff454f444f4fff444f445f444f4ffff4fff4ff4fff45fffffff0000000000000000000000000000000000000
ffffff455f454f454f444ff4ff444f445f444fffff4f4f454f444f455f454f454f444ff4ff444f444f444ffffff0000000000000000000000000000000000000
ffffff5fff5f5f5f5f555ff5ff555f55ff555fffff5f5f5f5f555f5fff5f5f5f5f555ff5ff555f555f555ffffff0000000000000000000000000000000000000
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssscccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7711111111117111117771111111111111111111111111777711111111111111177777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7117717771717177711111771177711771177177117771777117711771771177117777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7171117711717177117771717177117171717171711711777171117171717171717777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7111717111711171111111771171117771717177111711777171117771771171717777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7177111771177171111111717117717111771171711717777117717171717177117777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7111111111111111777771111111111111111111111117777111111111111111117777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7111171111111111777771111111111171111111111117777711111111111111177777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7711111111111111111111111111111111111111111111111111111111111111111111111111177scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7111111111111711111111777111117777111111117771111111111111117111111117111177777scccccccccccccccccccccccccccccccccccccccccccccc
cs7177711771771117717171777177717771177177717771777177717771717177717711177177777scccccccccccccccccccccccccccccccccccccccccccccc
cs7117117171717171717771777117117771717177717771771177117711717117117171711177777scccccccccccccccccccccccccccccccccccccccccccccc
cs7717117171717177711171777117117771777171717771711171117111711117117171717177777scccccccccccccccccccccccccccccccccccccccccccccc
cs7717117711771171717711777177717771717171717771717117711771177177717171777177777scccccccccccccccccccccccccccccccccccccccccccccc
cs7711111111111111111117777111117771111111117771117711111111111111111111111177777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs77777777777777ssssssssssssssssssss777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs77777sssss777ss77s7s7s777s777s777s777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs77777s777s777s7sss7s7s77ss77sss7ss777777777777777777777777766666666666666667777scccccccccccccccccccccccccccccccccccccccccccccc
cs77777sssss777sss7s777s7sss7ssss7s7777777777777777777777777767777111111117767777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777s77ss777ss77ss77ss7s77777777777777777777777777677711eeeeee11767777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777ssssssssssssssssssss7777777777777777777777777767711eeeeeeee1167777scccccccccccccccccccccccccccccccccccccccccccccc
cs777777777777777777777777777777777777777777777777777777777776711eeeeeeeeee117777scccccccccccccccccccccccccccccccccccccccccccccc
cs77777777777777777777777777777777777777777777777777777777777671eee77ee77eee17777scccccccccccccccccccccccccccccccccccccccccccccc
cs77777777777777777777777777777777777777777777777777777777777671eee77ee77eee17777scccccccccccccccccccccccccccccccccccccccccccccc
cs77111111111111111111111111111111111111111111111111111117777671eee77ee77eee17777scccccccccccccccccccccccccccccccccccccccccccccc
cs77777777777777777777777777777777777777777777777777777777777671eee77ee77eee17777scccccccccccccccccccccccccccccccccccccccccccccc
cs77777777777777777777777777777777777777777777777777777777777671eeeeeeeeeeee17777scccccccccccccccccccccccccccccccccccccccccccccc
cs77777777777777777777777777777777777777777777777777777777777671ee77777777ee17777scccccccccccccccccccccccccccccccccccccccccccccc
cs777777777777777777777777777777777777777777777777777777777776711ee777777ee117777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777767711ee7777ee1167777scccccccccccccccccccccccccccccccccccccccccccccc
cs71111111111117111111117771111177777777777777777777777777777677711eeeeee11767777scccccccccccccccccccccccccccccccccccccccccccccc
cs7177711771771117717171777177717777777777777777777777777777767777111111117767777scccccccccccccccccccccccccccccccccccccccccccccc
cs7117117171717171717771777117117777777777777777777777777777766666666666666667777scccccccccccccccccccccccccccccccccccccccccccccc
cs7717117171717177711171777117111117111711177777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7717117711771171717711777177711717171717177777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7711111111111111111117777111111117111711177777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777ssss7ssss7777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s77s7s77s777ssssssssssssssssssss7777sssssssss777sssssssssssssssss77777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s7ss7ss7s777s777s77ss777s777s77ss777s777s7s7s777s77ss777ss77s777s77777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s7s777s7s777ss7ss7s7ss7ss77ss7s7s777s777s777s777s77ss77ss7ssss7ss77777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s7ss7ss7s7777s7ss77sss7ss7sss7s7s777s7s7sss7s777s7s7s7sssss7ss7s777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s77s7s77s7777s7ss7s7s777ss77s77ss777s7s7s77ss777s777ss77s77sss7s777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777ssss7ssss7777sssssssssssssssssss7777ssssssss7777ssssssssssss7sss777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777ssss7ssss7777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s77s7s77s777sssssssssss77sssssssssss7777sssssssssssssssss7777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s7ss7ss7s777s7s7s777s7s7ss77s777s77ss777s777s777s77ss7s7s7777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s7s777s7s777s7s7s77ss7s7s7s7s77ss7s7s777ss7sss7ss7s7s777s7777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s7ss7ss7s777s777s7sss7sss777s7sss7s7s7777s7sss7ss7s7sss7s7777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s77s7s77s777s7s7ss77ss77s7ssss77s77ss7777s7ss777s77ss77ss7777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777ssss7ssss777sssssssssssssss77sssssss77777sssssssssssssss77777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777ssss7ssss7777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s77s7s77s777ssssssssssssssss7777sssssssss777ssssssssssssssssssssssss7ssss777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s7ss7ss7s777s7s7ss77s777s77ss777s777s7s7s777s777ss77s77ss77ss777s77sss77s777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s7s777s7s777s7s7s7sss77ss7s7s777s777s777s777s777s7s7s7s7s7s7s77ss7s7s7sss777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s7ss7ss7s777s7s7sss7s7sss7s7s777s7s7sss7s777s7s7s777s7s7s7s7s7sss77ssss7s777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s77s7s77s777ss77s77sss77s77ss777s7s7s77ss777s7s7s7s7s7s7s7s7ss77s7s7s77ss777scccccccccccccccccccccccccccccccccccccccccccccc
cs777ssss7ssss7777sssssss7sssssss7777ssssssss7777ssssssssssssssssssssssssssss7777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777ssss7ssss7777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s77s7s77s7777ssssssssssss7777ssssss7sss77777sssssssss777ssssssssssssssss7777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s7ss7ss7s777ss77s777s777s777ss77s7s7s7s77777s777s7s7s777s777ss77ss77s77ss777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s7s777s7s777s7s7ss7ss77ss777s7s7s7s7s7s77777s777s777s777s77ss7s7s7s7s7s7s777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s7ss7ss7s777s777ss7ss7sss777s777s7sss7sss777s7s7sss7s777s7sss7s7s7s7s7s7s777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s77s7s77s777s7s7ss7sss77s777s7s7ss77ss77s777s7s7s77ss777s7s7s77ss77ss77ss777scccccccccccccccccccccccccccccccccccccccccccccc
cs777ssss7ssss777ssssssss7ssss777sssssssssssss777ssssssss7777sss7ssssssssssss7777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777ssss7ssss7777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s77s7s77s7777sssssssssssssssssssssss7777ssssssssssssssssssssssssssss77777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s7ss7ss7s777ss77s777ss77s7s7s777s77ss777s777ss77ss77s7s7ss77s777s77ss7777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s7s777s7s777s7ssss7ss7s7s777s77ss7s7s777s77ss7s7s7sss7s7s7sss77ss7s7s7777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s7ss7ss7s777sss7ss7ss777sss7s7sss7s7s777s7sss7s7s7sss7s7sss7s7sss7s7s7777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777s77s7s77s777s77sss7ss7s7s77sss77s77ss777s7s7s77sss77ss77s77sss77s77ss7777777scccccccccccccccccccccccccccccccccccccccccccccc
cs777ssss7ssss777ssss7sssssssssss7sssssss7777sss7ssss7sssssssssss7sssssss77777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7711111111111111111111111111111111111111111111111111111111111111111111111111177scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777eee7777777777777777777777eeeee777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777eeeeeee77e7e777eeee777777777e77777e7777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs77711111111111111111111111711177777ee7777e7e7e777e777e77eeee77e77777e7777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs77117717771177177117771771117177777e77777e7e7eee7e777e77e77777e77777eee77777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7717111171171117171771171711117777e777777e7e777e7eeeeee7e77777e77ee77e777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7711171171171717171711171711717777ee77777e77e7777e7777e7ee7777eee7777eeeeee7777scccccccccccccccccccccccccccccccccccccccccccccc
cs77177117771777171711771771111177777eeeee7e7777777e7777777eee7777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs771111111111111111111111111111777766666ee66666666666666666666666666666666667777scccccccccccccccccccccccccccccccccccccccccccccc
cs7711111111111111111111111177777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccccccccccccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777scccccccccccccccccccccccccchhhhhhcccccccccccccc
cs7777777777777777777777777777777777777777777777777777777777777777777777777777777sccccccccccccccccccccccchhhh7777hhhcccccccccccc
cssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssscccccccccccccccccccccchh777777777hhccccccccccc
chhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhcccccccccccccccccccccch777hhhhh777hhcccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccch77hhhhhhhh777hhccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccch7hhhhhhhhhh777hccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchhh77777hhhh777hhcccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchhh7777777hhh777hcccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchh77777777hhh777hcccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchhh777hhh777hh777hcccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchhh77777h77hh77hh777hcccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccch77777777h77hh777h777hcccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchh7777777777hhhh77hh777hhccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchh7777777777777777h7h7777hhccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchhh77777777777777777h7h777hhhccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchh777777777777777777h7hh777hhhccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchh777777hhhhhhhhh77777hhh77hhhcccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccch777hhhhcccccch7hhhhhhhh77hhhhcccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccch77hhcccccccccchh7hhhhhh777hhhccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchhhccccccccccccch77777777hhhh7hhccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchhh77777777hhhh77hccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccch7hh77hhhhhh7777hhhhccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccch77h77777h77hhhhhhhhccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchhh7h777hhhhhhhhhhhhhhcccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchhhhh777hhhhhhhhhhhhhhhccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchhhhhhh7hhhhhhhhhhhhhhhhccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccchhhhhhh7hhhhhhhhhhhhhhhhccc
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh777hhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7hhhhhhhhhhhhhhhhhhh

__sfx__
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
010900001661413055130001300013000247053370500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500000
011000001661415055150001500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001661417055170001700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001661419055190001900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000166141b0551b0001b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000166141d0551d0001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000166141f0551f0001f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01080000180451c0451f045180451c0451f045180451c0451f045180351c0351f025180251c0251f015180151c0151f015180151c0001f000180001c0001f000180001c0001f0000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00090000167551b7552775527705057051f7052470533705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705
000500000b6240b634100141a5041a6040e5040e5040f6040d6041260412604126041260412604126042460428604006040060400604006040060400604006040060400604006040060400604006040060400604
000500000f11300103001031813300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103
9d0600000b635005010b7310050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100000000000000000000000000000000000
00010000197300e720207000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
910300001251500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505
910300001551500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505
