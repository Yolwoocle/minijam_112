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
	in_menu=true
	menu_new_dialogue_wait=400
	report_fin_time=0

	cam={
		dobj=create_dobj(-133,-200),
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

	logo={
		default_x=18,
		default_y=-80,
		dobj=create_dobj(18,-80),
	}
	
	c={
		dobj=create_dobj(63,63),
		sel_index=1,
		mode="launch"
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

	dead_list={}
	dead_list_obj={
		dobj=create_dobj(135,0)
	}


	bubbles={}

	conveyor_time=0 --conveyor time
	conv_mod=nil
	conv_default=5
	spawn_rate=80

	ailment_manager=
	{
		big_a="", --string containing ailment name
		solutions={}, --list containing all the "solution strings"
		customer=generate_name()
	}

	past_customers={}


	parse_speed=3
	text_parse=""
	ailment=""
	parse_length=0
	parsing=true

	parse_output=""
	ailment_out=""
	hide_bubble=false

	ingr_particles={}

	doctor_oy=0

	g_ingredients={
	}

	bubble_dobj=create_dobj(0,-10)
	speech_arrow_up=false

	time_percentage=0
	clock=0
	maxclock=60*60 -- be careful about overflowing the tiny p8 limit

	report_shifted_on_left = false

	bubbles_on_foreground = false
	time_before_confetti=-1

	spoon={
		dobj=create_dobj(0,0)
	}

	--credits stuff--
	credits_text={"made by","LOUIE CHAPMAN THE ","YOLWOOCLE THE "}
	lou_adj=rnd(positive_adj)
	yol_adj=rnd(positive_adj)
	while #lou_adj+#credits_text[2]>27 do
		lou_adj=rnd(positive_adj)
	end
	while #yol_adj+#credits_text[3]>27 do
		yol_adj=rnd(positive_adj)
	end

	anim_to_point(cam,nil,-91,0.9)
	prog_launch=0
	music(0)
end

function _update60()
	t+=1

	update_cursor()

	if c.mode=="launch" then
		prog_launch+=1
		if prog_launch==400 or btnp(???) or btnp(???????) or btnp(??????) or btnp(??????) then
			c.mode="menu"
			anim_to_point(cam,0,-91,0.9)
			sfx(58)
			new_dialogue("I CANT WAIT TO ","HELP"," PEOPLE TODAY!")
		end
	end

	conv_mod=conv_default
	if(time_percentage>30)conv_mod=4 spawn_rate=75
	if(time_percentage>50)conv_mod=3 spawn_rate=50
	if(time_percentage>70)conv_mod=2 spawn_rate=30
		
	
	update_time()
	leave_menu()

	update_menu()

	--if(report_shifted_on_left) dead_list_obj.dobj.oy-=1/6

	menuitem(3, "sound: "..(sound_on and "on" or "off"), function() sound_on=not sound_on end)
	menuitem(4, "end day", function() clock=maxclock-2 end)

	if(conveyor_active)conveyor_time+=1 --only iterate spawn timer is the conveyor is active
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
	
	-- spawn confetti
	if(time_before_confetti >-1)time_before_confetti-=1
	if time_before_confetti==0 then
		sfx(60)
		for i=1,30 do
			spawn_confetti(-5,-10, 10+rnd(80), -10-rnd(50), 0.05+rnd(0.1))
			spawn_confetti(128+5,-10, -10-rnd(80), -10-rnd(50), 0.05+rnd(0.1))
		end
	end

	
	animate_ingredients()
	
	animate_bubbles()
	animate_ingr_particles()
	
	parse_dialogue()
	update_anim()



	conveyor_spawner()
end

function _draw()
	cls(2)
	screen_shake()
	camera(dx(cam.dobj),dy(cam.dobj))
	
	rectfill(-150,35,130,130,0)

	draw_pot()
	draw_bubbles()
	rectfill(-150,110,130,130,0)
	
	
	draw_conveyor()

	draw_effects()

	draw_potion_names()

	if not in_menu then

		draw_ingredients()
		draw_ingr_particles()
		if(g_ingredients[c.sel_index]!=nil)selected_effects()
	end


	rectfill(-5,-40,60,30,2)


	draw_time()

	draw_report()
	draw_dead_list()
	
	draw_pdoctor()
	draw_bubble()
	draw_ticks()
	
	draw_cursor()
	
	--draw dialogue / bubble / speech
	if(not hide_bubble)then
		print(parse_output,6,5+dy(bubble_dobj),5)
		print(ailment_out,6,5+dy(bubble_dobj),3)
	end

	draw_logo()

	draw_credits()
	
	if(bubbles_on_foreground)draw_bubbles()

	if(debugmode)print(debug,1,dy(cam.dobj),8)
end

function reset_data()
	--reset clocks
	clock=0
	time_since_last=0
	conveyor_time=0

	past_customers={}
	dead_list={}

	report.step=1
	report.adj1=""
	report.sticker=false
	report.cur_mark=0
	report.signature=false
	report.last_input=0

	bubbles_on_foreground=false

	report_fin_time=0

	ticks={false,false,false}

	hide_bubble=false

	report.dobj.wx=130
	dead_list_obj.dobj.wx=135

	g_ingredients={}
	spawn_rate=80

end

function init_and_start_round()
	in_menu=false

	reset_data()
	
	--animate stuff
	anim_to_point(cam, 0,0, 0.9)
	anim_to_point({dobj=bubble_dobj}, 0,0, 0.9)
	speech_arrow_up=true

	--this is scuffed as fuck don't tell yol
	c.dobj.wx=-30
	c.dobj.wy=100
	
	add(g_ingredients,object)

	--get new ailment and return to belt
	new_ailment()
	return_to_belt()
end

-->8
--update

function draw_potion_names()
	local _text="potion of"
	local _y=dy(potion.dobj)
	text_bold2(_text,hcentre(_text)-35,_y,4,5)
	text_bold2(pot.name,hcentre(pot.name)-35,_y+7,4,5)
end

function draw_dead_list()
	-- draw dead list
	local x,y=dx(dead_list_obj.dobj),dy(dead_list_obj.dobj)
	--local x,y=30,dy(dead_list_obj.dobj)

	rrect(x,-87+1,61,90,1)
	rrect(x,-87  ,61,90,4)

	local _x=x+1
	local text_gap=35
	local scroll=t*0.1
	for i=0,#dead_list-1 do
		local y_pos=(i*text_gap)
		local y_pos=(y_pos-scroll)%(text_gap*#dead_list)
		print(dead_list[i+1],x+1,-120+y_pos,5)
	end

	--print(dead_list,x+1,y,5)



	-- foreground (to hide list)
	rectfill(x,-91,128,-88, 2)--blue top
	rectfill(x,5,128,3+31, 2)--blue bottom
	rectfill(x+1,4,128,4, 0)--lback shadow
	rectfill(x,35,128,37, 0)--black bottom
end

function update_menu()
	if(c.mode!="menu")return

	local phrases={
		pack("IM SO"," EXCITED"," !"),
		pack("I"," LOVE"," YOU !"),
		pack("I CAN'T WAIT TO "," HELP"," EVERYONE TODAY !"),
		pack("MY POISON IS YOUR"," MEDICINE"," !"),
		pack("MEDICINE IS MY"," PASSION"," !"),
		pack("YOU LOOK SO"," GOOD"," TODAY !"),
		pack("ALWAYS REMEMBER TO LIVE , LAUGH , AND"," LOVE"," !"),
		pack("THE REAL FRIENDS ARE THE"," POTIONS "," WE MADE ALONG THE WAY !"),
		pack("IF LIVE GIVES YOU"," LEMONS"," MAKE LEMONAIDE !"),
		pack("EVERYTHING HAPPENS FOR A"," REASON"," !"),
		pack("IM SO"," PROUD"," OF YOU !"),
	}
	if(time_since_last%menu_new_dialogue_wait==0 and not parsing and c.mode=="menu")then
		new_dialogue(unpack(rnd(phrases)))
		menu_new_dialogue_wait=flr(400+rnd(200))
		time_since_last=0
	end
end

function update_dead_list()
	local ways_to_die=split" WAS NEVER SEEN AGAIN, STILL GETS NIGHTMARES, HASNT STOPPED CRYING,S FAMILY MISSES THEM, NEVER MADE IT HOME, WILL NEVER RETURN, DIED A GRUESOME DEATH, LEFT THEIR WALLET, IS SUFFERING ANXIETY, HASNT EATEN IN DAYS, WAS ARRESTED, IS NOW IN JAIL, SUFFERED A FATE WORSE THAN DEATH, IS NOT THE SAME ANYMORE, COULDNT HANDLE OUR STRONGEST POTIONS"
	local died_of_variations=split" DIED OF "
	for customer in all(past_customers) do
		if customer.score<0 then
			local fate=rnd(ways_to_die)
			if(flr(rnd(2))==0 and #customer.cause<20)fate=rnd(died_of_variations)..customer.cause
			local fit=to_fit(customer.name..fate.."\n\n",11)
			add(dead_list,fit)
		end
	end

	if #dead_list!=0 then
		while(#dead_list<4) do
			add(dead_list,rnd(dead_list))
		end
	end

	dead_list_obj.dobj._y=200
	dead_list_obj.dobj.oy=0
end

function return_to_belt()
	c.mode="ingredients"
	conveyor_active=true
	ticks={false,false,false}
	new_ailment()
end

function animate_ingredients()
	for ingredient in all(g_ingredients) do
		local offset=0
		if(conveyor_time%conv_mod==0 and conveyor_active)offset=1
		ingredient.dobj.wx+=offset
		
		--destroy ingredient if it goes off screen
		if ingredient.dobj.wx>128 then
			del(g_ingredients,ingredient)
			c.sel_index=mid(1,c.sel_index-1,#g_ingredients) --fix weird cursor thing
		end
	end
end


function update_cursor()
	if c.mode=="menu" then
		if(btnp(??????) or btnp(??????) and time_since_last!=0) then
			c.mode="credits"
			credits_new_adj()
			anim_to_point(cam,-133,-91,0.9)
			sfx(58)
			return
		end
	end

	if c.mode=="credits" then
		if(btnp(??????) or btnp(??????) and time_since_last!=0) then
			c.mode="menu"
			anim_to_point(cam,0,-91,0.9)
			sfx(58)
			return
		end
	end

	if c.mode=="ingredients" then
		for i=0,1 do --move cursor direction from input
			if btnp(i) then
				sfx(61)
				local dir=split"1,-1"
				c.sel_index=mid(1,c.sel_index+dir[i+1],#g_ingredients)
			end
		end

		local ingr=g_ingredients[c.sel_index]
		if #g_ingredients>0 and ingr!=nil then --animate to selected ingredient location
			local ox,oy=10,8
			anim_to_point(c,dx(ingr.dobj)+ox,dy(ingr.dobj)+oy,0.9)
		
			if btnp(???) and time_since_last>30 and #g_ingredients>1 then
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
	if conveyor_time%spawn_rate==0 and conveyor_active then
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

		logo.dobj.wx=130

		--anim_to_point(c,,130,0.97)

		dialogue_queue=pack("LOOKS LIKE ITS TIME TO CLOSE UP SHOP ","","")
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
		in_menu=true --tells things that we're back on the menu, baby !
	end

	if time_since_last==430 then
		local adjectives=split" WONDERFUL , FANTASTIC , EXCITING "
		new_dialogue("WHAT A",rnd(adjectives),"DAY !")
	end

	if time_since_last==700 then
		hide_bubble=true
		anim_to_point(report, report.target_x, nil, 0.9)

		update_dead_list()
	end

	if(time_since_last==720)anim_to_point(c,_x+10,_y+25,0.9)

	--report card input loop
	if(time_since_last>750 and time_since_last>report.last_input+30 and btnp(???)) then
		local c_anim_speed=0.9

		if(report.step==1)report.adj1=rnd(positive_adj)
		if(report.step==2)report.sticker_ox=-3+rnd(6)report.sticker_oy=-3+rnd(6)report.sticker=true
		if(report.step>2 and report.step<=7)report.cur_mark+=1
		if(report.step==8)report.signature=true

		if(report.step<9)then
			if(report.step!=0)sfx(47+report.step)shake=0.1
			if(report.step==8)sfx(55)shake=0.2
		end

		if(report.step==1)anim_to_point(c,_x+70,_y+30,c_anim_speed)
		if(report.step>=2 and report.step<=6)anim_to_point(c,_x+8,_y+45+((report.step-2)*8),c_anim_speed)
		if(report.step==7)anim_to_point(c,_x+50,_y+90,c_anim_speed)
		if(report.step==8)anim_to_point(c,_x+50,_y+100,c_anim_speed) --move hand away after signature
	
		if(report.step==8) then
			report_fin_time=time_since_last
			time_before_confetti=50 
			bubbles_on_foreground=true
			anim_to_point(c,nil,45,0.95)
		end

		report.last_input=time_since_last
		report.step+=1
	end

	if time_since_last==900 and #dead_list!=0 then
		-- Shift report card to left
		anim_to_point(report, report.target_x-23, nil, 0.9)
		anim_to_point(c,c.dobj.wx-23,nil,0.9)
		anim_to_point(dead_list_obj, 83, nil, 0.9)
		report_shifted_on_left = true
	end

	--finished the report
	if report_fin_time>0 then
		local time_since_fin=time_since_last-report_fin_time

		if(time_since_fin==120)anim_to_point(report,130,nil)

		--to finish the round
		if(time_since_fin==150) then
			to_menu()
		end
	end
end

function to_menu()
	c.mode="menu"
	in_menu=true
	time_since_last=0

	report.dobj.wx=150
	anim_to_point(dead_list_obj,135,nil,0.9)

	logo.dobj.wx=logo.default_x
	logo.dobj.wy=-130
	anim_to_point(logo,nil,logo.default_y,0.95)

	hide_bubble=false
	new_dialogue("I CANT WAIT TO ","HELP"," PEOPLE TODAY!")
end

function draw_time()
	if(in_menu)return -- "this is scuffed as fuck I hate this line" - Louie

	time_percentage=(clock/maxclock)*100
	
	local start_time,end_time=9,17
	local shift_length=end_time-start_time
	local h_length=(100/shift_length)
	local h_hand=(start_time+((time_percentage\h_length)%12))
	
	local m_hand=15*(flr((time_percentage/(h_length)*60)%60)\15)


	--[[
	local leftt = maxclock - clock
	local leftsecs= leftt\60
	local timesec = leftsecs%60
	local timemin = leftsecs\60
	
	]]--

	local _end="AM"
	if(h_hand<start_time)_end="PM"

	local m = sub("000"..tostr(flr(m_hand)), -2,-1)
	local h = sub("   "..tostr(flr((h_hand-1)%12)+1), -2,-1)
	
	-- flashing text
	local ocol = 4
	if (time_percentage>90 and t%60<=30) ocol=3
	local out=h..":"..m.._end
	if(clock==0)out=" 5:00PM"
	text_bold(out,99,3, 0,ocol)
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

function draw_logo()
	sspr(0,100,91,28,dx(logo.dobj),dy(logo.dobj)+sin((t*0.5)/120)*3.99)
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

function credits_new_adj()
	lou_adj=rnd(positive_adj)
	yol_adj=rnd(positive_adj)
	
	while #lou_adj+#credits_text[2]>27 do
		lou_adj=rnd(positive_adj)
	end
	
	while #yol_adj+#credits_text[3]>27 do
		yol_adj=rnd(positive_adj)
	end
end

function draw_credits()
	local _x,_y=-133,-91
		
	local _c1,_c2=5,3
	local _y0,_y1,_y2=27+_y,40+_y,47+_y

	--made by
	rrect(hcentre(credits_text[1])-3+_x,_y0-3,32,11,1)
	rrect(hcentre(credits_text[1])-3+_x,_y0-3,32,10,7)
	print(credits_text[1],hcentre(credits_text[1])+_x,_y0,5)

	--names
	local w1,w2=(#credits_text[2]+#lou_adj)*4,(#credits_text[3]+#yol_adj)*4
	if(w2>w1)w1=w2
	local width=(w1)
	local left_align=64-(width*0.5)
	rrect(64-(width*0.5)-2+_x,_y1-1,2+width,16,1)
	rrect(64-(width*0.5)-2+_x,_y1-2,2+width,16,7)

	local align=hcentre(credits_text[2]..lou_adj)+_x
	print(credits_text[2],align,_y1,_c1)
	print(lou_adj,align+(#credits_text[2]*4),_y1,_c2)

	local align=hcentre(credits_text[3]..yol_adj)+_x
	print(credits_text[3],align,_y2,_c1)
	print(yol_adj,align+(#credits_text[3]*4),_y2,_c2)

	--twitter tags
	text_bold2("@0Xffb3",3+_x,108+_y,7,5)
	text_bold2("@YOOLWOOCLE_",3+_x,117+_y,7,5)
end


function draw_conveyor()
	local _y=105
	for i=0,10 do
		local _x=-20+(i*16)+(conveyor_time\conv_mod)%16
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

function leave_menu()
	if in_menu and parsing==false and c.mode=="menu" and time_since_last!=0 then
		if btnp(???) then
			init_and_start_round()
		end
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
		fill=false,
		col=4,
	}
	add(bubbles,new_bub)
end

function spawn_confetti(_x,_y,_vx,_vy,_gravity)
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
		size=rnd(3)+2,
		fill=true,
		col=rnd{2,3,4,5,13},
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

function draw_bubbles()
	for b in all(bubbles) do
		local f = b.fill and circfill or circ
		f(b._x,b._y,b.size,b.col)
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
	if(n==??? or n==???????)return oldbtn(???,p)or oldbtn(???????,p)
	return oldbtn(n,p)
end
oldbtnp=btnp
function btnp(n,p)
	if(n==??? or n==???????)return oldbtnp(???,p)or oldbtnp(???????,p)
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

all_effects=split"TURNS INTO DRAGON,MAKES YOU SHRINK,GLOWS IN THE DARK,SUMMONS A TORNADO,FACILITATES DIGESTION,MELTS FACE,FIGHTS POVERTY,SMELLS LIKE TEEN SPIRIT,TURNS INTO A SWORD,TURNS INTO A TOAD,SETS YOU ON FIRE,RELEASES INHIBITIONS,INCREASES MULTITASKING,LOWERS CHOLESTEROL,INCREASES MEMORY,REDUCES MEMORY LOSS,STRENGTHENS BONE MARROW,INCREASES CHARISMA,REJUVENATES HAIR GROWTH,FACILITATES CONFIDENCE,HARDENS SKIN,HIGH IN VITAMIN C,BREAKS FOURTH WALL,INCREASES PUNGENCY,UNTERRICHTET dEUTSCH,FINDS KEYS,GIVES A FEVER,HARDENS LIVER,DRIES MOUTH,INDUCES VOMITING,REMOVES TASTE,INCREASE COORDINATION,TURNS URINE GREEN,AMPLIFIES TINNITUS,EMITS 5G SIGNAL,BOOSTS TASTE,TASTES OF CITRUS,JUST GETS YOU STONED,INCREASES STRENGTH,INCREASES MAGIC,INCREASES RESISTANCE,INCREASES STEALTH,RAISES HIT POINTS,RAISES MAGIC POINTS,RAISES SPEED,INCREASES INTELLIGENCE,LOWERS INTELLIGENCE,LOWERS SPEED,LOWERS HP,DECREASES STEALTH,DECREASES MAGIC,DECREASES STRENGTH,DECREASES DEXTERITY,INCREASES CONSTITUTION,DECREASES CONSTITUTION,INCREASES WISDOM,DECREASES WISDOM,RAISES RECOVERY,INSTILLS PARANOIA,PROBABLY BOOSTS LUCK,FREAKS EVERYONE OUT,INCREASES POISON RES,INCREASES FIRE RES,LOWERS FIRE RES,LOWERS POISON RES,RAISES GLASS CEILING,INSTANT DEATH,RAISES SEX APPEAL,RELEASES PHEROMONES,THICKENS BLOOD,INDUCES STRESS,INDUCES MANIA,INDUCES VOMITING,CURES HANGOVER,TASTES LIKE MILK,MAKES YOU FLOAT,QUICKENS REACTIONS,HEIGHTENS AWARENESS,DISPELS GHOSTS,GIVES NIGHTMARES"
all_solutions={
	"EXPERIENCING KINETIC ENERGY|HARDENS SKIN,PROBABLY BOOSTS LUCK,RAISES GLASS CEILING",
	"BEING SHOT BY A SKELETON|TASTES LIKE MILK,QUICKENS REACTIONS",
	"SWIMMING TOO FAR FROM THE SHORE|MAKES YOU FLOAT",
	"TRYING TO SWIM IN LAVA|MAKES YOU FLOAT,INCREASES FIRE RES,INCREASES POISON RES",
	"SUMMONING A DEMON|BREAKS FOURTH WALL,PROBABLY BOOSTS LUCK,DISPELS GHOSTS",
	"LOSING A FIST FIGHT|RAISES HIT POINTS,INCREASES STRENGTH",
	"BEING POISONED|INDUCES VOMITING,BOOSTS TASTE",
	"AN ARROW TO THE KNEE|INCREASE COORDINATION",
	"SINKING IN QUICKSAND|MAKES YOU FLOAT",
	"ASSASSINATION|RAISES SEX APPEAL,HEIGHTENS AWARENESS,INSTILLS PARANOIA",
	"A HUNTING ACCIDENT|QUICKENS REACTIONS,HEIGHTENS AWARENESS,GLOWS IN THE DARK",
	"A BROKEN HEART|REJUVENATES HAIR GROWTH,HIGH IN VITAMIN C,LOWERS CHOLESTEROL,RAISES SEX APPEAL,RELEASES PHEROMONES,FACILITATES CONFIDENCE,HARDENS SKIN",
	"BAD BODY ODOUR|RELEASES PHEROMONES,HIGH IN VITAMIN C,INCREASES CHARISMA,HARDENS SKIN,REMOVES TASTE,TASTES OF ORANGE",
	"LOW BLOOD PRESSURE|LOWERS CHOLESTEROL,HIGH IN VITAMIN C",
	"SOCIAL REJECTION|REJUVENATES HAIR GROWTH,EMITS 5G SIGNAL,FACILITATES CONFIDENCE,RAISES SEX APPEAL,RELEASES PHEROMONES,BREAKS FOURTH WALL,JUST GETS YOU STONED",
	"BEING STABBED|FACILITATES CONFIDENCE,INCREASES CHARISMA,HARDENS SKIN,RAISES HP",
	"A BEAR ATTACK|RAISES HP,RAISES RECOVERY,HARDENS SKIN",
	"GANG VIOLENCE|RELEASES INHIBITIONS,INDUCES VOMITING,RAISES SPEED,RAISES HP,INCREASES STEALTH,PROBABLY BOOSTS LUCK,FREAKS EVERYONE OUT",
	"DRINKING THE WRONG POTION|INCREASES PUNGENCY,INCREASES INTELLIGENCE,INCREASES MEMORY,REDUCES MEMORY LOSS",
	"FREEZING|SETS YOU ON FIRE,RAISES RECOVERY",
	"LEAVING THE OVEN ON|INCREASE COORDINATION,INCREASES FIRE RES",
	"A GUNSHOT|RAISES HP,HARDENS SKIN,INCREASES RESISTANCE",
	"NOT KNOWING WHEN TO HOLD 'EM|INCREASES STEALTH,FREAKS EVERYONE OUT",
	"WEAK BONES|STRENGTHENS BONE MARROW,HIGH IN VITAMIN C",
	"BALDING|REJUVENATES HAIR GROWTH,INCREASES CHARISMA",
	"LOSING THEIR KEYS|FINDS KEYS,INSTILLS PARANOIA,INCREASES WISDOM,INCREASES MEMORY,REDUCES MEMORY LOSS",
	"NOT SPEAKING GERMAN|UNTERRICHTET dEUTSCH,MITS 5G SIGNAL",
	"FALLING OFF THEIR HORSE|INCREASE COORDINATION",
	"DRINKING TOO MUCH|HARDENS LIVER,INDUCES VOMITING,RELEASES INHIBITIONS",
	"A FIREBALL|INCREASES FIRE RES,HARDENS SKIN",
	"A SUDDEN STROKE|LOWERS CHOLESTEROL,INSTANT DEATH",
	"OLD AGE|LOWERS CHOLESTEROL,HARDENS LIVER,RAISES HP",
	"BOREDOM|TURNS INTO A SWORD,INSTANT DEATH,INSTILLS PARANOIA,JUST GETS YOU STONED,EMITS 5G SIGNAL,AMPLIFIES TINNITUS,TURNS URINE GREEN,SETS YOU ON FIRE,REJUVENATES HAIR GROWTH,FINDS KEYS",
	"AGGRESSIVE SEALIFE|INCREASES STRENGTH,FACILITATES CONFIDENCE",
	"HUNGER|FIGHTS POVERTY,SUMMONS GIANT PEACH,FACILITATES DIGESTION,HIGH IN VITAMIN C,REMOVES TASTE,TASTES OF ORANGE,JUST GETS YOU STONED",
	"DISCOVERING DYNAMITE|INCREASES RESISTANCE,RAISES HP,STRENGTHENS BONE MARROW,HARDENS SKIN",
	"CONSTIPATION|FACILITATES DIGESTION,TURNS INTO A TOAD,TASTES LIKE MILK",
	"POVERTY|INCREASES INTELLIGENCE,TURNS INTO A TOAD,INCREASES CHARISMA,FACILITATES CONFIDENCE,FIGHTS POVERTY",
	"BEING UGLY|INCREASES STEALTH,INCREASES CHARISMA,JUST GETS YOU STONED",
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
	split",CANT STOP THINKING ABOUT HOW, YOU WERE",
	split",DOUBTS THEYLL EVER FEEL THIS, AGAIN",
	split"I HEARD ,SHOUT HOW, THEY FELT ONCE OUTSIDE !",
	split",WONDERS IF THIS IS AS, AS IT GETS !",
}

potion_types=split"jumping,wonder,slime,speed,dexterity,anger,anxiety,invisibility,money,freedom,flight,love,romance,restoration,answering,attention,beauty,bravery,chaos,charm,charisma,cowardice,dancing,death,disguise,drunkenness,empathy,floating,fortitude,glowing,growth,happiness,healing,hearing,immunity,leadership,life,luck,loyalty,melting,noise,owl-eyes,shrinking,spiders,terror,strength"

positive_adj=split"FASCINATING,COURAGEOUS,GOOD,WONDERFUL,FANTASTIC,ENLIGHTENING,ELECTRIC,LIFE-CHANGING,POWERFUL,INCANDESCENT,FUN,CUTE,ROMANTIC,SEXY,COMELY,CARING,CLEAN,EXCITED,HAPPY,SWEET,BRIGHT,CREATIVE,DYNAMIC,FUNNY,LIKABLE,LOYAL,SINCERE,POLITE,FORTUITOUS,GORGEOUS,REMARKABLE,ROUSING,STELLAR,BRAVE,CAPABLE,PASSIONATE,SENSIBLE"
negative_adj=split"ASTOUNDING,WEIRD,BAD,SMELLY,CREEPY,SPOOKY,FEARFUL,UNCANNY,GHASTLY,ECCENTRIC,TERRIBLE,DISGUSTING,OFFENSIVE,UGLY,SUCKY,AWFUL,GARBAGE,POOR,SAD,UNACCEPTABLE,CRUMMY,CHEAP,BORING,NOT GOOD,GROTTY,GRUNGY,INSOLENT,IRRITATED,HOSTILE,VAIN,IMPATIENT,BLEAK,BLIND,BLOATED,BLOODIED,BLOODTHIRSTY,RUDE,BOSSY,CLUMSY,EMPTY,GLUM,FIENDISH,EXPLOITED,EVIL,SCARED,GROGGY,HUNGOVER,JADED,PUTRID"
neutral_adj=split"OK,NEUTRAL,SILLY,PECULIAR,KINKY,CAUSTIC,BIZARRE,DOWDY,BUSY,COLD,SHINY,REFLECTIVE,DRUNK,HIGH,SPONGE-Y,LIQUID,AROUSING,BRIGHT,SULFURIC"

__gfx__
fffffffffffffffffff000000ffffffffffff444444f0000f00fffff000fffffffffffffffffffff00000000fffffffffffffffffffffffffffffffffffff000
ffffffffffffffff00006444000ffffffffff444444400000440ff006440ffffffffffffffffffff00000000fffffffffffffffffffffffffffffffffffff000
fffffffffffffff0064444444600fffffffff444444400000444006406440fffffffffffffffffff00000000fffffffffffffffff00000000ffffffffffff000
fffffffffffffff06440000044600ffffffff444444400000644440644440fffffffffffffffffff00000000fffffffffffffff00644444460fffffffffff000
ffffffffffffff0640000000044400fffffff444444f0000f0644444446440ffffffffffffffffff00000000fffffffffffff00644444444460ffffffffff000
ffffffffffffff0400000000004460fffffff00000000000ff064444644640ffffffffffffffffff00000000ffffffffffff006444444444440ffffffffff000
ffffffffffffff00066444000044400ffffff00000000000ff006444464440ffffffffffffffffff00000000ffffffffffff0640000000004460fffffffff000
ffffffffffffff00044444460004460ffffff00000000000ff0dd6444444400fffffffffffffffff00000000ffffffffffff0000000000000440fffffffff000
ffffffffffffff00644444440004440ffffff000fffff3ffff0d664444440440ffffffffffffffff00000000ffffffffffff0000000000000440fffffffff000
fffffffffffff000444000444004440ffffff000ffff343ffff0664444444440ffffffffffffffff00000000ffffffffffff0064444446000000f00ffffff000
fffffffffff00444440440044004440ffffff000ffff343fffff06666604460fffffffffffffffff00000000ffffffffffff06444444440444440000fffff000
fffffffff0064444440440044604440ffffff000f333443ffffff000006460ffffffffffffffffff00000000ffffffffffff004400000440044600000ffff000
fffffff0064444444440000440044400fffff000344343ffffffffff0d660fffffffffffffffffff00000000ffffffffff00444404400440046000000ffff000
fffff004444444444444444060444600fffff000f34443ffffffffff0dd0ffffffffffffffffffff00000000ffffffff00644444400004400000000000fff000
fff00644444444444444444060444000fffff000ff3343fffffffffff00fffffffffffffffffffff00000000fffffff0644444444444604046000000000ff000
ff064444444444446666440600446000fffff000ffff3fff0000000000000000ffffffffffffffff00000000ffffff04444444444444404004000000000ff000
f064444660000000006666600044000ffffff000000000000000000000000000000000000000000000000000fffff0444444444444444060044000000000f000
066660000ffffff0600000000440000ffffff000000000000000000000000000000000000000000000000000ffff04444444444444444600444000000000f000
06600ffffffffff006000000446000fffffff000000000000000000000000000000000000000000000000000fff0644446600000000000044460400000000000
000fffffffffffff0444444440000400fffff000000000000000000000000000000000000000000000000000ff0644660000ff06000000044600400000000000
ffffffffffffff000444444460000460fffff000000000000000000000000000000000000000000000000000f0644600fffff004444444446000460000000000
ffffffffffffff04004400000044460000fff00fffffffff333ffffffffffffffffffffff33333ff00000000066600ffffff0404444000000044600000000000
ffffffffffffff06404444404400000000fff003333333ff3f3fff3333fffffffff3fffff3ffffff000000000600ffffffff0600444444044600000000000000
fffffffffffff0006044400000000000000ff00f33ffff3f3f3fff3fff3ff3333ff3fffff3ffffff0000000000fffffffff00060444000000000000000000000
fffffffffffff00000446000000000000000f00f3fffff3f3f333f3fff3ff3fffff3fffff333ffff00000000fffffffffff00000446000000000000000000000
ffffffffffff000000040000000000000000f003ffffff3f3fff3f333333f3fffff3ff33ff3fffff00000000ffffffffff00000004000000000000000000f000
ffffffffffff000000060000000000000000f0033fffff3ff3ffff3ffff3f33ffff333ffff33333300000000ffffffffff0000000600000000000000000ff000
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
5555222155555555fffff111111ffffffffff111111ffffffffff111111ffffffffff111111ffffffffff111111ffffffffffffffffff2222210111111000000
5555555215555555fff1113333111ffffff1113333111ffffff1113333111ffffff1113333111ffffff1113333111ffffffffffff22221000011011111000000
5555555521555555ff11d333333d11ffff11d333333d11ffff11d333333d11ffff11d333333d11ffff11d333333d11fffffffff2200011100000000000000000
5555555552155555ff1d33333333d1ffff1d33333333d1ffff1d33333333d1ffff1d33333333d1ffff1d33333333d1fffffff220000000000333ddd33d000000
5555555552155555f11334333343311ff11444333344411ff11334333343311ff11334433443311ff11334433443311fffff211100033dddd33ddddddd000000
5555555555215555f13344433444331ff13334433443331ff13344433444331ff13334433443331ff13334433443331ffff21100333ddddd3ddd33ddd3000000
5555555555215555f13343433434331ff13344433444331ff13343433434331ff13334433443331ff13334433443331fff21103333dddd3dddd33ddd33000000
5555555555125555f13333333333331ff13333333333331ff13333333333331ff13333333333331ff13334433443331ff2011333d3dddd3dd33333dddd000000
5555555555125555f13344444444331ff13334444443331ff13343333334331ff13344444444331ff13433333333431ff20114333dddd3ddd3333333dd000000
5555555551255555f11344444444311ff11334444443311ff11334444443311ff11344444444311ff11343333334311ff201114333333dddd333333333000000
5555555551255555ff1d34444443d1ffff1d33444433d1ffff1d33444433d1ffff1d34444443d1ffff1d34444443d1fff20011144433dddddd33333ddd000000
5555555512555555ff11d344443d11ffff11d333333d11ffff11d333333d11ffff11d344443d11ffff11d333333d11fff2004111114444dddddddddddd000000
5555555125555555fff1113333111ffffff1113333111ffffff1113333111ffffff1113333111ffffff1113333111fffff201441111111444444404000000000
5555111255555555fffff111111ffffffffff111111ffffffffff111111ffffffffff111111ffffffffff111111fffffff200114411111111111111111000000
00555555555555ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff200001144441111111111111000000
ffff00000000ffffffffffffffffff000f00000000000000000000000000000000000000000000000000000000000000f2000000111114444411111111000000
fff0444444440ffffffffffffffff0466000000000000000000000000000000000000000000000000000000000000000f2000001000011111144444444000000
ff04ffffffff40fffffffffffffff066d000000000000000000000000000000000000000000000000000000000000000f2000001111100001111111111000000
ff04f444444f40ffffffffffffff06d00f0000000000000000000000000000000000000000000000000000000000000020000001111110000000000000000000
fff04ffffff40fffffffffffffff060fff0000000000000000000000000000000000000000000000000000000000000020000001111110000111111111000000
ffff04444440fffffffffffffff06d0fff0000000000000000000000000000000000000000000000000000000000000020000011111100001111111111000000
ffff04555540fffffffffffffff060ffff0000000000000000000000000000000000000000000000000000000000000020000011111100001111111111000000
ffff04355340ffffffffffffff06d0ffff0000000000000000000000000000000000000000000000000000000000000020000011111100001111111111000000
fff0433333340fffffffffffff060fffff0000000000000000000000000000000000000000000000000000000000000020000011111100001111111111000000
ff043333333340fffffffffff06d0fffff0000000000000000000000000000000000000000000000000000000000000020000011111100001111111111000000
f04344333333340ffffffffff060ffffff0000000000000000000000000000000000000000000000000000000000000020000011111100001111111111000000
f04344333333340fffffffff06d0ffffff0000000000000000000000000000000000000000000000000000000000000020000011111100001111111111000000
f04433333333340fffffffff060fffffff0000000000000000000000000000000000000000000000000000000000000020000011111100001111111111000000
ff044333333440fffff000006d0fffffff0000000000000000000000000000000000000000000000000000000000000020000011111100001111111111000000
fff0044444400ffff006666660ffffffff0000000000000000000000000000000000000000000000000000000000000020000011111100001111111111000000
fffff000000fffff06d6446d60ffffffff0000000000000000000000000000000000000000000000000000000000000020000011111100001111111111000000
00000000000000000d6dddd60fffffffff0000000000000000000000000000000000000000000000000000000000000020000001111100001111111111000000
0000000000000000f0d66660ffffffffff0000000000000000000000000000000000000000000000000000000000000020000001111110001111111111000000
0000000000000000ff00000fffffffffff00000000000000000000000000000000000000000000000000000000000000f2000001111110000111111111000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff200000111110000111111111000000
ffff55555555555555fffffffff5555555555555555555555555555555ff555555555555555555555555555ffff00000fff20000111111000111111111000000
ff555555555555555555555555555555555555555555555555555555555555555555555555555555555555555ff00000fff20000111111000011111111000000
f55555533335555555555555555555555553355555555553555555555555555333333555555555555555555555f00000ffff2000011111000011111111000000
f55555344443555555555555555555555534435555555534355555555555553444444355555555555555555555f00000ffff2200011111100001111111000000
f55553433344353555555555555555555533443555555344435555555555534434434433555555535555555555f00000fffff222101111100001111111000000
f55534433334434353335553335555333533443553335344335333555555533334433334353335343533355555f00000fffffff2211111110000111111000000
f55534434334433434443534443553444333443534443343333444335555533334433333434443334344435555f00000fffffffff22211111000111111000000
f55533434434433444344343344334433433443344334333344434443555555534435533444344334443443555f00000fffffffffff222111000011111000000
f55534433434433443343333344334433333443344343333334443333555555534435553443344334433443555f00000fffffffffffff2221100001111000000
ff553443333443344333333434433443333344334433335533334333355555553443555343334433443344355ff00000ffffffffffffffff2222222222000000
f55533433334333443333344444334433333343344433555533334435555553333433353443344334433433555f00000ffffffffffffffffffffffffff000000
f55533443334333443555344344334433433443344334355344434443555534434434433443344334433443555f00000ffffffffffffffffffffffffff000000
f55553344443333444355334344334434433444344344355333444333555533444444333443344334433443555f0000000000000000000000000000000000000
f55553333333334333355333433433443334333334433355333343333555533333333334333333343333333555f0000000000000000000000000000000000000
f55555333333533333355533333333333333333333333355553333335555555333333333333333333333333355f0000000000000000000000000000000000000
f55555555555533355555553333333333533355533335555555333355555555555555553335555533355555555f0000000000000000000000000000000000000
f15555555555555555555555555555555555555555555555555555555555555555555555555555555555555551f0000000000000000000000000000000000000
ff555555555555555555555555555555555555555555555555555555555555555555555555555555555555555ff0000000000000000000000000000000000000
ff155555555555555555551115555555555555555555555555555555555555555555555555555555511555551ff0000000000000000000000000000000000000
fff1111111111111111111fff11111111111111111111111111111111111111111111111111111111ff11111fff0000000000000000000000000000000000000
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000
ffffff444f444f444f444f444f444ff44f444fffff444f444f4fff444f444f444f444f444f444f444f444ffffff0000000000000000000000000000000000000
ffffff454f454f454f455f545f545f455f445fffff444f454f4fff454f454f454f455f545f545f455f445ffffff0000000000000000000000000000000000000
ffffff444f445f444f4ffff4fff4ff5f4f45ffffff454f444f4fff444f445f444f4ffff4fff4ff4fff45fffffff0000000000000000000000000000000000000
ffffff455f454f454f444ff4ff444f445f444fffff4f4f454f444f455f454f454f444ff4ff444f444f444ffffff0000000000000000000000000000000000000
ffffff5fff5f5f5f5f555ff5ff555f55ff555fffff5f5f5f5f555f5fff5f5f5f5f555ff5ff555f555f555ffffff0000000000000000000000000000000000000
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000
__label__
hhhhhhhhhhhhh11111111111111111111111hhhhhhhhhhhhhhhh111111111111111111111111hhhhhhhhhhhhhhhh11111111111111111111111hhhhhhhhhhhhh
hhhhhhhhhhhhh11111111111111111111111hhhhhhhhhhhhhhhh111111111111111111111111hhhhhhhhhhhhhhhh11111111111111111111111hhhhhhhhhhhhh
hhhhhhhhhhhhh11111111111111111111111hhhhhhhhhhhhhhhh111111111111111111111111hhhhhhhhhhhhhhhh11111111111111111111111hhhhhhhhhhhhh
hhhhhhhhhhhhhh11111111111111111111111hhhhhhhhhhhhhhh111111111111111111111111hhhhhhhhhhhhhhh11111111111111111111111hhhhhhhhhhhhhh
hhhhhhhhhhhhhh11111111111111111111111hhhhhhhhhhhhhhh111111111111111111111111hhhhhhhhhhhhhhh11111111111111111111111hhhhhhhhhhhhhh
hhhhhhhhhhhhhh11111111111111111111111hhhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhhh11111111111111111111111hhhhhhhhhhhhhh
hhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhh11111111111111111111111hhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhh11111111111111111111111hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhh1111111111111111111111hhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhh1111hhhhhhhhhhhhhhhh1hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh11111hhhhhhhhhhhhhhhhh
1hhhhhhhhhhhhhhhh11hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh111hhhhhhhhhhhhhhhh1
1hhhhhhhhhhhhhhhh1hhhhsssssssssssssshhhhhhhhhssssssssssssssssssssssssssssssshhssssssssssssssssssssssssssshhhh11hhhhhhhhhhhhhhhh1
11hhhhhhhhhhhhhhhhhhssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssshhhhhhhhhhhhhhhhhhh11
11hhhhhhhhhhhhhhhhhsssssseeeesssssssssssssssssssssssseessssssssssessssssssssssssseeeeeessssssssssssssssssssshhhhhhhhhhhhhhhhhh11
11hhhhhhhhhhhhhhhhhssssse7777esssssssssssssssssssssse77esssssssse7essssssssssssse777777esssssssssssssssssssshhhhhhhhhhhhhhhhhh11
111hhhhhhhhhhhhhhhhsssse7eee77esesssssssssssssssssssee77esssssse777essssssssssse77e77e77eesssssssesssssssssshhhhhhhhhhhhhhhhh111
111hhhhhhhhhhhhhhhhssse77eeee77e7eseeessseeesssseeesee77esseeese77eeseeessssssseeee77eeee7eseeese7eseeessssshhhhhhhhhhhhhhhhh111
1111hhhhhhhhhhhhhhhssse77e7ee77ee7e777ese777esse777eee77ese777ee7eeee777eessssseeee77eeeee7e777eee7e777esssshhhhhhhhhhhhhhhh1111
1111hhhhhhhhhhhhhhhsssee7e77e77ee777e77e7ee77ee77ee7ee77ee77ee7eeee777e777essssssse77essee777e77ee777e77essshhhhhhhhhhhhhhhh1111
1111hhhhhhhhhhhhhhhssse77ee7e77ee77ee7eeeee77ee77eeeee77ee77e7eeeeee777eeeessssssse77essse77ee77ee77ee77essshhhhhhhhhhhhhhhh1111
11111hhhhhhhhhhhhhhhsse77eeee77ee77eeeeee7e77ee77eeeee77ee77eeeesseeee7eeeessssssse77essse7eee77ee77ee77esshhhhhhhhhhhhhhhh11111
11111hhhhhhhhhhhhhhsssee7eeee7eee77eeeee77777ee77eeeeee7ee777eesssseeee77esssssseeee7eeese77ee77ee77ee7eessshhhhhhhhhhhhhhh11111
111111hhhhhhhhhhhhhsssee77eee7eee77essse77e77ee77ee7ee77ee77ee7esse777e777esssse77e77e77ee77ee77ee77ee77essshhhhhhhhhhhhhh111111
111111hhhhhhhhhhhhhssssee7777eeee777essee7e77ee77e77ee777e77e77esseee777eeessssee777777eee77ee77ee77ee77essshhhhhhhhhhhhhh111111
1111111hhhhhhhhhhhhsssseeeeeeeee7eeeesseee7ee7ee77eee7eeeee77eeesseeee7eeeesssseeeeeeeeee7eeeeeee7eeeeeeessshhhhhhhhhhhhh1111111
1111111hhhhhhhhhhhhssssseeeeeeseeeeeessseeeeeeeeeeeeeeeeeeeeeeeesssseeeeeessssssseeeeeeeeeeeeeeeeeeeeeeeeesshhhhhhhhhhhhh1111111
1111111hhhhhhhhhhhhsssssssssssseeessssssseeeeeeeeeeseeessseeeessssssseeeesssssssssssssssseeessssseeesssssssshhhhhhhhhhhhh1111111
11111111hhhhhhhhhhhssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssshhhhhhhhhhhh11111111
11111111hhhhhhhhhhhhssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssshhhhhhhhhhhhh11111111
111111111hhhhhhhhchh1sssssssssssssssssss111ssssssssssssssssssssssssssssssssssssssssssssssssssssssss11ssssss1hhhhhhhhhhh111111111
111111111hhhhhhhhchhh1111111111111111111hhh11111111111111111111111111111111111111111111111111111111hh111111hhhhhhhhhhhh111111111
111111111hhhhhhhhhchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhchhhhhhhhh111111111
1111111111hhhhhhhhhchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhchhhhhhhhh1111111111
1111111111hhhhhhhhhhcchh777h777h777h777h777h777hh77h777hhhhh777h777h7hhh777h777h777h777h777h777h777h777hhccchhhhhhhhhh1111111111
11111111111hhhhhhhhhhhhh7s7h7s7h7s7h7sshs7shs7sh7ssh77shhhhh777h7s7h7hhh7s7h7s7h7s7h7sshs7shs7sh7ssh77shhhhhhhhhhhhhh11111111111
11111111111hhhhhhhhhhhhh777h77sh777h7hhhh7hhh7hhsh7h7shhhhhh7s7h777h7hhh777h77sh777h7hhhh7hhh7hh7hhh7shhhhhhhhhhhhhhh11111111111
11111111111hhhhhhhhhhhhh7ssh7s7h7s7h777hh7hh777h77sh777hhhhh7h7h7s7h777h7ssh7s7h7s7h777hh7hh777h777h777hhhhhhhhhhhhhh11111111111
111111111111hhhhhhhhhhhhshhhshshshshssshhshhssshsshhssshhhhhshshshshssshshhhshshshshssshhshhssshssshssshhhhhhhhhhhhh111111111111
111111111111hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhshhhhhhhhhh111111111111
1111111111111hhhhhhhhhchhhchhhhhhhhhhhhhhhhhhhhhhhhhhhhhc1chhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhcsshhhhhhhh1111111111111
1111111111111hhhhhhhhhhccc1ccccccccccccccccccccccccccccc111cccccccccccccccccccccccccccccccccccccccccccccsssshhhhhhh1111111111111
1111111111111hhhhhhhhhhhhh11111111111111111sshhhhhhhhhhh1111111111111111hhhhhhhhhhhsh11111111111111111sssssshhhhhhh1111111111111
11111111111111hhhhhhhhhhhhh1111111111111111sshhhhhhhhhhh1111111111111111hhhhhhhhsssss1111111111111111ssssssshhhhhh11111111111111
11111111111111hhhhhhhhhhhhh11111111111111111sshhhhhhhhhh1111111111111111hhhhhssssssh11111111111111111sssssssshhhhh11111111111111
111111111111111hhhhhhhhhhhh11111111111111111sshhhhhhhhhh1111111111111111hhhssssssshh11111111111111111sssssssshhhh111111111111111
111111111111111hhhhhhhhhhhhh1111111111111111ssshhhhhhhhh1111111111111111hhssssssshhh1111111111111111sssssssssshhh111111111111111
111111111111111hhhhhhhhhhhhh1111111111111111sssshhhhhhhh1111111111111111hssssssshhhh1111111111111111sssssssssshhh111111111111111
1111111111111111hhhhhhhhhhhh1111111111111111ssssshhhhhhh1111111111111111sssssssshhhh1111111111111111sssssssssshh1111111111111111
1111111111111111hhhhhhhhhhhhh111111111111111sssssshhhhhhh11111111111111ssssssssshhhh111111111111111ssssssssssssh1111111111111111
11111111111111111hhhhhhhhhhhh111111111111111sssssshhhhhhh11111111111111ssssssssshhhh111111111111111ssssssssssss11111111111111111
11111111111111111hhhhhhhhhhhh1111111111111111sssssshhhhhh11111111111111ssssssssshhh1111111111111111ssssssssssss11111111111111111
111111111111111111hhhhhhhhhhh1111111111111111ccccssshhhhh11111111111111ssssssssshhh1111111111111ccccssssssssss111111111111111111
111111111111111111hhhhhhhhhhhh1111111111111ccccccccsshhhh11111111111111ssssssssshhh11111111111ccccccccssssssss111111111111111111
h11111111111111111hhhhhhhhhhhh11111cc11111ccccccccccsshhh11111111111111sssssssssshh1111111111ccccccccccsssssss11111111111111111h
h111111111111111111hhhhhhhhhhh1111cccc1111ccccccccccsshhh11111111111111hssssssssssh1111111111ccccccccccssssss111111111111111111h
hh11111111111111111hhhhhhhhhhhh111cccc111ccccccccccccsshh11111111111111hssssssssssh111111111ccccccccccccsssss111111111111ccc11hh
hh111111111111111111hhhhhhhhhhh1111cc1111cccccccccccccssh11111111111111hhsssssssss1111111111ccccccccccccssss111111111111ccccc1hh
hhh11111111ccccc1111hhhhhhhhhhh1111111111ccccccccccccccss11111111111111hhsscccssss1111111111ccccccccccccssss111111111111ccccchhh
hhhh111111ccccccc111hhhhhhhhhhhh111111111cccccccccccccccs11111111111111hhhcccccsss1111111111ccccccccccccssss111111111111ccccchhh
hhhh11111ccccccccc111hshhhhhhhhh1111111111ccccccccccccccss11111ccc1111hhhccccccsss11111111111ccccccccccssss11111111111111ccchhhh
hhhhh111ccccccccccc11hsshhhhhhhh1111111111ccccccccccccccss1111cccccc11hhhccccccsss11111111111ccccccccccsssh1111111111111111hhhhh
hhhhh11ccccccccccccc11hssshhhhhhh1111111111cccccccccccccss111ccccccc11hhhccccccsss111111111111ccccccccsssh11cc1111111111111hhhhh
hhhhhh1ccccccccccccc11hhssshhhhhh111111111111ccccccccccsss11ccccccccc1hhhccccccss11111111111111sccccsssshh1cccc11111111111hhhhhh
hhhhhhhccccccccccccc11hhhssshhhhh11111111ccc111sccccccssss11ccccccccc1hhhhcccccss11111111111111sssssssshhh1cccc1111111111hhhhhhh
hhhhhhhccccccccccccc111hhsssshhhh1111111ccccc11ssccccsssss11cccccccc11hhhhcccccss11111cccc11111sssssscccc111cc11111111111hhhhhhh
hhhhhhhccccccccccccc111hhssssshhhh111111ccccc11sssssssssss1ccccccccc11hhhhcccccss1111cccccc111ssssshcccccc11111111111111hhhhhhhh
hhhhhhhhccccccccccc11111hssssshhhh111111ccccc11sssssssssss1cccccccc111hhhssccccss111cccccccc11sssshcccccccc1111111111111hhhhhhhh
hhhhhhhhhccccccccc111111hsssssshhh1111111ccc111sssssssssss1cccccccc111hhssscccsss11ccccccccc11sshhhcccccccc111111111111shhhhhhhh
hhhhhhhhhhccccccc1111111ssssssshhhh1111111111111ssssssssssccccccccc111hssssccsss111ccccccccc1sshhhhcccccccc11111111111hsshhhhhhh
hhhhhhhhhh1ccccc111111111ssssssshhh1111111111111sssssssssccccccccccc11ssssccssss11ccccccccc11shhhhhcccccccc11111111111hssshhhhhh
hhhhhhhhhhh11111111111cccssssssshhh1111111111111ssssssssscccccccccccccsssscsssss11cccccccc111hhhhhhhcccccc11111111111hhsssshhhhh
hhhhhhhhhhh1111111111cccccsssssshhhh111111111111ssssssssscccccccccccccccsscsssss11cccccccc11shhhhhhhhcccc111111111111hhssssshhhh
hhhhhhhhhhhh11111111cccccccsssssccch111111111111sssssssssccccccccccccccccsscssss11ccccccc111hhhhhhhsss11111111111111hhssssssshhh
hhhhhhhhhhhh1111111cccccccccsssccccc111111111111sccccsssssccccccccccccccccssssss11ccccccc111hhhhhhssss11111111111111hsssssssshhh
cchhhhhhhhhhh111111cccccccccsssccccch11111111111ccccccssssscccccccccccccccssssss11ccccccc11hhh777777s11111111111111sssssssssshhh
ccchhhhhhhhhhh11111ccccccccccssccccch1111111111ccccccccssss1cccccccccccccccssss111cccccc111777hhhhhh7711111ccc1111ssssssssssshhh
cccchhhhhhhhhh11111ccccccccccsssccchh111111111ccccccccccsss11ccccccccccccccssss11ccccccc117hhhh6777hhh7111ccccc111ssssssssssssss
ccccchhhhhhhhhh1111ccccccccccssshhhhh111111111ccccccc777sssccccccccccccccccc7cs11cccccc117hh677777776hh71ccccccccccccsssssssssss
cccccchhhhhhhhh11111ccccccccccsshhhhhh11111111cccccc7c7c7cccccccccccccccccc7e7c1cccccc1117h677hhhhh776hh7cccccccccccccssssssssss
cccccchhhhhhhhhh11111cccccccccshhhhhhh11111111cccccc7cc77ccccccccccccccccccc7cccccccc1117h67hhhhhhhh777hh7cccccccccccccsssssssss
cccccchhhhhhhhhhh111111cccccccchhhhhhh111111111ccccc7ccc7ccccccccccccccccccccccccccc11117h7hhhhhhhhhh776h7ccccccccccccccssssssss
cccccchhhhhhhhhhh1111111ccccccchhhhhhhh111111111ccccc777ccccccccccccccccccccccccc11111117hhh66777hhhh777hh7cccccccccccccssssssss
cccccchhhhhhhhhhhh1111111cccccchhhhhhhh1111111111ccccsccccccccccccccccccccccccccc11111117hhh7777776hhh776h711cccccccccccssssssss
ccccchhhhhhhhhhhhh11111111cccccchhhhhhh11111111111sssscccccccccccccc777cccccccccc11111117hh67777777hhh777h711cccccccccccssssssss
cccchhccchhhhhhhhss11111111ccccchhhhhhhh1111111111ssscccccccccccccc7d7d7cccccccc11111177hhh777hhh777hh777h711cccccccccccssssssss
ccchhccccchhhhhhhss111111111cccchhhhhhhh1111111111scccccccccccccccc7ed77ccccccc1111177hh77777h77hh77hh777h711scccccccccssssssssc
cchhhccccchhhhhhhsss111111111cccshhhhhhh1111111111ccccccccccccccccc7eed7cccccc111177hh6777777h77hh776h777h71ssscccccccsssssssscc
1hhhhccccchhhhhhsssss11111111cccssshhhhh1111111111cccccccccccccccccc777ccccccc1177hh6777777777hhhh77hh777hh7sssscccccssssssssscc
11hhhhccchhhhhhhsssss111111111cc1ssssssss111cccccccccccccccccccccccccccccccccc77hh7777777777777777h6h7776hh7sssssssssssssssssscc
111hsssshhhhhhhhssssss11111111cc1ssssssss11cccccccccccccccccccccccccccc77cccc7hh677777777777777777h6h777hhh7sssssssssssssssss1cc
1111sssssssshhhhssssss111111111c1ssssssss1cccccccccccccccccccccccccccc7c77cc7h6777777777777666677h6hh776hhh7ssssssssssssssss111c
11111sssssssshhhsssssss11111111c11sssssssccccccccccccccccccccccccccccc7cc7c7h6777766hhhhhhhhh66666hhh77hhh7ssssssssssssssss11111
111111sssssssshhssssssss1111111c11ssssssscccccccccccccccccccccccccccccc77c7h6666hhhh777777h6hhhhhhhh77hhhh7cssssssssssssss111111
1111111sssssssshhsssssss11111111111ssssssccccccccccccccccccccccccccccccccc7h66hh777711sss7hh6hhhhhh776hhh77ccssssccccssss1111111
11111111sssssssssssssssss1111111111ssssssccccc777cccccccccccc7cccccccccccc7hhh77cccc1ssss77h77777777hhhh7117ccsccccccccs11111111
111111111ssssssssssssssss1111111111sssssscccc7dde7cccccccccc7c7cccccccccccc777cccccc1sss7hhh77777776hhhh76h77ccccccccccc11111111
1111111111sssssssssccccsss1111111111sssscccc7dd77d7cccccccccc7cccccccccccccccccccccccss7117hh77hhhhhh777611117ccccccccccc1111111
11111111111ssssssccccccccs1111111111ssscccc7edd77dd7cccccccccccccccccccccccccccccccccs7h1167h77777177111h11117ccccccccccc1111111
111111111111ssssccccccccccs1111111111sscccc7eedee7d7ccccccccccccc777ccccccccccccccccc7hh1116h777h111111h1111117ccccccccccc111111
111111111cccccssccccccccccss111111111sccccc7deeedde7cccccccccccc7hhh7ccccccccccccccc711hh1111776h111111h11111hh7cccccccccc111111
11111111cccccccccccccccccccs111111111scccccc7dedde7ccccc7777777777777777ccccccccccc71111h111hh7hh11111111111hhh7cccccccccc111111
1111111ccccccccccccccccccccss1111111ccccccccc7dee7c77777h777hhhhhhhhhhhh77777cccc77111111111hh6hh11111h11111hhh7cccccccccc111111
111111cccccccccccccccccccccss11111cccccccccccc77777hhhhh7dee711111111111hhhhh777711111h1111hhh7hh11111h11111hhhh7cccccccc1111111
11111ccccccccccccccccccccccsss111cccccccccccc77hhhh11117ee77d7111111111111111hhhh771111h1111h777h1111h111111hhh17cccccccc1111111
11111cccccccccccccccccccccsssss1ccccccccccc77hh111111117ed77e7hhhhhhhhhhh11177711hh7711hh111hh7hh1111h111111hh117ccccccc11111111
s1111cccccccccccccccccccccsssssccccccccccc7hh1111hhhhhh7ddddd7edd7d77d777hh7dde7111hh711hh11hhhhh1111h111111h1117cccccc11111111s
sss11ccccccccccccccccccccsssssccccccccccc7h111hhhddddddd7dee7dddddddddded77ed77e7h111h71hh1hhhhhh1111h11111111117cccc11111111sss
ssss1ccccccccccccc1ccccssssssccccccccccc7h11hheeedddddddd777dddeedddeedddd7ee77d77hh11h7hhhhhhhhhh111h1111111117111111111111ssss
ssssssccccccccccc11111ssssssscccccccccc7h11heeeeddddedddeeedddeedde77eeddd7deedd7ed7h11h7hhhhhhhhh11hh111111111711111111111sssss
sssssssccccccccc1111111ssssscccccccccc7h111eeeded77deddeeeeeddddde7ee7edddd7ddd7eeeeh111h7hhhhhhhh11hh1111111117111111111ssccccc
ssssssssccccccc111111111sssscccccccccc7h1117eeed7dd7dddeeeeeeeddd7ee7e7eeddd777eeeddh171h7hhhhhhhhh1hhh11111111711111111sscccccc
sssssssssccccc1ccccc11111ssscccccccccc7h11117eee7ee7dddeeeeeeeeee7dded7eeeeeeeeedddh1171h7hhhhhhhhh1hhh1111111117111111ssccccccc
ssssssssssss1ccccccccc1111sscccccccccc7h11111777e77dddddeeeeedddee7777eeddeeeeeehhh11711h7hhhhhhhhh1hhh111h1111171111ssscccccccc
cccccssssssccccccccccccc111scccccccccc7h117111117777ddddddddddddddeeeddddddehhhh11117711h7hhhhhhhhhhhhh111h111117111sssscccccccc
cccccccsssccccccccccccccc111ccccccccccc7hh1771111111777777777hhhh777hhhhhhhh1111117771hh7hhhhhhhhhhhhhh111h111117ccccssscccccccc
ccccccccssccccccccccccccc111ccccccccccc7hhh117711111111111111111111111111111111177711h1h7hhhhhhhhhhhhhhh1hhh11117ccccccscccccccc
ccccccccccccccccccccccccccccccccccccccc7hhhhh11777711111111111111111111111111777711hhs1h7hhhhhhhhhhhhhhh1hhh11117ccccccccccccccc
cccccccccccccccccccccccccccccccccccccc7hhhhh1h111117777711111111111111117777711111h7ss11h7hhhhhhhhhhhhhh1hhh1h117ccccccccccccccc
cccccccccccccccccccccccccccccccccccccc7hhhhh11hhhh1111117777777777777777111111hhhhc77ss1h7hhhhhhhhhhhhhhhhhh1h117ccccccccccccccc
cccccccccccccccccccccccccccccccccccccc7hhhhh11hhhhhhhh11111111111111111111hhhh1hhcc77ss1h7hhhhhhhhhhhhhhhhhhhh1117cccccccccccccc
ccccccccccccccccccccccccccccccccccccc7hhhhh111hhh11111hhhhhhhhhhhhhhhhhhhh11cc1hhhcc77ss1h7hhhhhhhhhhhhhhhhhhh1117cccccccccccccc
ccccccccccccccccccccccccccccccccccccc7hhhhh11hhhh111111111111111111111111111ccc1hhcc77ss1h7hhhhhhhhhhhhhhhhhhh1117cccccccccccccc
ccccccccccccccccccccccccccccccccccccc7hhhh111hhh1111111111111111111111111111ccc1hhcc77ss1h7hhhhhhhhhhhhhhhhhhh1117cccccccccccccc
ccccccccccccccccccccccccccccccccccccc7hhhh111hhh11111111111111111111111111111ccc1hhcc77ssh7hhhhhhhhhhhhhhhhhhhh117cccccccccccccc

__sfx__
a92a0006185351b5451f5551b5551f5551b5550050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505
011005100051000521005210052100521005210052100521005210052100521005210052100521005210052100001000010000100001000010000100001000010000100001000010000100001000010000100001
930403001a6450c6410c6450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012a1800000351b0351b035000351b0351b035000351b0351b035000351b0351b0350703516035160350703516035160350703516035160350703516035160350700016000160000700016000160001600016000
c12a1800000001803518035070001803518035080001803518035070001803518035000001f0351f035030001f0351f035050001f0351f035070001f0351d0350000500005000050000500005000000000000000
012a1800000351b0351b035000351b0351b035000351b0351b035000351b0351b0350703516035160350703516035160350703516035160350703516035160350700016000160000700016000160001600016000
c12a1800000001803518035070001803518035080001803518035070001803518035000001f0351f035030001f0351f035050001f0351f035070001f0351d0350000500005000050000500005000000000000000
012a1800000351b0350303507035160351603508035180350a035070351603516035000351803505035030351b0351b0350503518035080350703517035170350000500005000050000500005000000000000000
c12a1800000001803518035070001303513035080001403514035070001a0351a035000001f0351f035030001f0351f035050001b0351b035070001f0351d0350000500005000050000500005000000000000000
c02a00181f5341f5301f5351b5341b5301b535185341a5301b5301a5341a5321a5351b5301a530185301653416530115301353014530185301753217532185350050000500005000050000500005000050000500
492a18001312413122131220c1240c1220c1220f1240f1220f1220e1240e1220e1220f1240f1220f1220e1240e1220e1220c1240c1220e1240b1240b1220b1220010000100001000010000100001000010000100
c12a18001b5341b535185241f5341f5351852422534185242253424524245222452527534265312452022534225301d5341f53420531225341f5321f5351d5140050000500005000050000500005000050000500
492a18000c1240c1220b1220e1240e1220c1220f1240e1220f1221312413122131221412414122111241312413122131220f1240f122111210e1240e1220e1220000000000000000000000000000000000000000
01540c001882018820188201882018820188201382013820138201382013820138201882018820188201882018820188201f8201f8201f8201f8201f8201f8200080000800008000080000800008000080000000
012a00180003500000000350703500000070350003500000000350203402032020350703507000070350503507000050350303507000030350003400032000350000000000000000000000000000000000000000
492a00000c0001b0341f0351b0001f0341b035180001b0341f0351a0341a0321a035230001a0341d0351a0001d03417035230001a0341d0351803418032180351800018000000000000000000000000000000000
492a00000c0001b0341f0351b0001f0341b035180001b0341f035200342003220035230001f0341d0351a0001d03417035230001a0341d0351803418032180350000000000000000000000000000000000000000
90080000187451b7451f745187351b7351f735187351b7351f735187251b7251f725187251b7251f705187151b7051f7151b7001f700187151b7001f7001f600187141871513714137150f7140f7150c7440c745
012a001800035000000003507035000000703500035000000003502034020320203507000070000700005000070000500003000070001300005035070350b0350000000000000000000000000000000000000000
492a18001852418522185221f5241f5221f522205221f521205241d5241d5221d5221f5241d5211f5221b5241b5221b5111a5241b5241a5241852418522185110050000500005000050000500005000050000500
492a18001852418522185111a5241a5221a5111b5241a5241b5242452124522245112b5242b5222b5112752427522275112652424521265242352423522235110050000500005000050000500005000050000500
012a1800000351803518035000351803502035030351b0351b035030351b0351b0350803514035140350803514035070350503511035110350503511035110350700016000160000700016000160001600016000
012a18000003518035180350003518035020350303516035160350303516035070350803518035180350803518035090350a0351a0351a0350a0351a0351a0350700016000160000700016000160001600016000
c12a1800000001f0351f0350e0001f0351f035080001f0351f0351c0001f0351d03500000180351803500000180351b0350500018035180350700018035160350000500005000050000500005000000000000000
c12a1800000001b0351b0350a0001b0351b035080001d0351d0351c0001d0351d035000001b0351b035030001b0351b035050001d0351d0350c0001d0351d0350000500005000050000500005000000000000000
492a18001850018500185001f5001f5001f500205001f500205001d5001d5001d5001f5001d5001f5001b5001b5001b5001a5001b5001a5001352416522175220050000500005000050000500005000050000500
0115000011024130241402413034140341604414044160441704418054180521805218052180311802118015180001800018000180001f000240000000000000000000c000000000000000000000000000000000
492a18001852418522185221852218511185121851218515185001850018500185001850018500185001850018500185001850018500185002350023500235000050000500005000050000500005000050000500
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
00080000180451c0651f065180551c0551f055180551c0451f035180351c0351f035180351c0351f025180251c0251f025180151c0151f015180151c0151f015180151c0001f0000000000000000000000000000
9d0600000b665005010b7610050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100000000000000000000000000000000000
00090000167551b7552775527705057051f7052470533705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705
000500000b6240b634100141a5041a6040e5040e5040f6040d6041260412604126041260412604126042460428604006040060400604006040060400604006040060400604006040060400604006040060400604
000500000f11300103001031813300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103
9d0600000b635005010b7310050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100000000000000000000000000000000000
00010000197300e720207000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
910300001251500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505
910300001551500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505
__music__
00 090a4344
01 0b0c0d4e
00 0b0c0f4e
00 0b0c0e44
00 0b0c1044
00 0c12534e
00 0c12134e
00 0c16144e
00 0b0c0e44
00 0b0c1044
00 191b1d44
00 191b1744
00 1a1c1844
00 0c12131f
02 0c16144e
00 41424344
03 0b0c4d44
00 1e424344
00 41424344
00 15424344
00 41424344
00 41424344
00 41424344
00 41424344
03 090a4344

