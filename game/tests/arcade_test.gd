extends SceneTree
const Sim=preload('res://scripts/simulation.gd')
var sim=Sim.new()
var checks=0
var failures=0

func check(value: bool, label: String) -> void:
	checks+=1
	if not value: failures+=1;printerr('FAIL: ',label)

func begin(id: int) -> void:
	sim.begin(id,[{'name':'P1','peer':1,'bot':false},{'name':'P2','peer':2,'bot':false}],470)

func ticks(count: int, input: Dictionary={}) -> void:
	for n in range(count): sim.step(1.0/60,input)

func close_players(distance=0.17) -> void:
	sim.state.players[0].p=Vector2.ZERO;sim.state.players[0].face=0.0;sim.state.players[1].p=Vector2(distance,0)

func _initialize() -> void:
	check(Sim.GAMES.size()==32,'Catalog contains 32 playable game IDs')
	var names: Array=[]
	for game in Sim.GAMES:
		check(game.name not in names and game.duration>=60,'Every game has a distinct name and enough play time');names.append(game.name)
	begin(7);close_players()
	ticks(1,{0:{'action':true}})
	check(sim.state.players[1].hp<100,'Punch damages a nearby opponent')
	check(sim.state.players[0].score>0,'Punch awards attacker points')
	begin(7);close_players()
	sim.state.players[1].guard=0.5
	ticks(1,{0:{'action':true}})
	check(sim.state.players[1].hp==100,'Guard blocks a punch')
	begin(9);close_players();sim.state.players[1].guard=0.3
	ticks(1,{0:{'action':true}})
	check(sim.state.players[0].stun>0,'Sword parry stuns the attacker')
	begin(10);close_players(0.15)
	ticks(1,{0:{'action':true}})
	check(sim.state.players[1].impulse.length()>1,'Sumo shove creates knockback')
	sim.state.players[1].p=Vector2(1.1,0)
	ticks(1)
	check(sim.state.players[0].score>=4,'Sumo ring-out credits last shover')
	begin(8);sim.state.walls=[];close_players(0.45)
	ticks(1,{0:{'action':true}});ticks(30)
	check(sim.state.players[1].hp<100,'Tank projectile reaches opponent')
	begin(8);sim.state.walls=[];sim.state.players[0].p=Vector2.ZERO;sim.state.players[0].face=0
	ticks(1,{0:{'action':true}});ticks(60)
	check(sim.state.shots.any(func(b):return b.bounce==1),'Tank projectile bounces at arena boundary')
	begin(11);ticks(60,{0:{'action':true}});ticks(1)
	check(sim.state.shots.size()==1 and sim.state.shots[0].kind=='shell','Artillery release launches a ballistic shell')
	var old_y: float=sim.state.shots[0].v.y;ticks(10)
	check(sim.state.shots[0].v.y<old_y,'Gravity bends artillery shot')
	begin(12);sim.state.players[0].p=sim.state.flags[1].p;ticks(1)
	check(sim.state.players[0].carry==1,'Opponent flag can be picked up')
	sim.state.players[0].p=sim.state.bases[0];ticks(1)
	check(sim.state.players[0].score==5 and sim.state.players[0].carry==-1,'Flag return awards capture points')
	begin(13);sim.state.players[0].p=Vector2.ZERO;ticks(60)
	check(sim.state.players[0].score>1.8,'Uncontested crown earns time-based score')
	sim.state.players[1].p=Vector2(0.2,0);var score: float=sim.state.players[0].score;ticks(10)
	check(sim.state.players[0].score==score,'Contested crown stops scoring')
	begin(14);close_players(0.45);ticks(1,{0:{'action':true}});ticks(30)
	check(sim.state.players[1].hp<100,'Space laser damages opponent')
	for g in [15,17]:
		begin(g);ticks(1,{0:{'action':true}});ticks(14)
		check(sim.state.players[0].p.y>0.25,'Short jump press reaches a platform-sized height')
		check(sim.state.players[0].jumps==1,'One press starts one physics jump')
	begin(15);sim.state.players[0].ground=false;sim.state.players[0].coyote=0.1;ticks(1,{0:{'action':true}})
	check(sim.state.players[0].v.y>0,'Coyote time permits a late platform jump')
	begin(16);sim.state.hazards=[{'x':0.07,'high':false}];ticks(3)
	check(sim.state.players[0].hurt>0,'Runner ground obstacle causes a hit')
	begin(16);sim.state.hazards=[{'x':0.07,'high':true}];ticks(3,{0:{'secondary':true}})
	check(sim.state.players[0].hurt==0,'Slide avoids an overhead runner barrier')
	begin(18);sim.state.time=2.0;sim.state.players[0].p.y=0.4;sim.state.players[0].v.y=0;ticks(6)
	check(sim.state.players[0].score>0,'Airborne rope crossing earns points')
	begin(19);sim.state.hazards=[];sim.state.players[0].p=Vector2(0,-0.6);ticks(1,{0:{'axis':Vector2.UP}})
	check(sim.state.players[0].score==5,'Frog reaching far bank earns five points')
	begin(20);sim.state.last_hit=0;sim.state.puck=Vector2(0,1.1);ticks(1)
	check(sim.state.players[0].score==2 and sim.state.players[1].score==-1,'Pong boundary awards scorer and penalizes goal owner')
	begin(21);sim.state.puck=Vector2(1.02,0);ticks(1)
	check(sim.state.players[0].score==3 and sim.state.puck==Vector2.ZERO,'Football goal credits the correct team and resets ball')
	begin(22);ticks(35,{0:{'action':true}});ticks(160)
	check(sim.state.players[0].score>=2,'A physically reachable basketball shot can score')
	begin(23);ticks(70,{0:{'action':true}});ticks(170)
	check(sim.state.players[0].score>=10,'Powerful centered bowling shot knocks down the pins')
	begin(24);sim.state.players[0].p=Vector2(0.73,-0.65);ticks(1)
	check(sim.state.players[0].hole==1 and sim.state.players[0].score>0,'Golf cup accepts a stopped ball and advances hole')
	begin(24);ticks(30,{0:{'axis':Vector2.DOWN,'action':true}});ticks(1)
	check(sim.state.players[0].strokes==1 and sim.state.players[0].v.y>0,'Golf release applies aimed impulse and records a stroke')
	begin(25);var p: Dictionary=sim.state.players[0];var head: Vector2i=p.snake[0];sim.state.items=[head+Vector2i.RIGHT]
	ticks(10,{0:{'axis':Vector2.LEFT}})
	check(p.snake_dir==Vector2i.RIGHT,'Snake cannot reverse into its own neck')
	check(p.score==1 and p.snake.size()==4,'Snake food grows the tail and awards points')
	begin(26);p=sim.state.players[0];p.ball_held=false;p.ball=p.bricks[0].p+Vector2(0,0.07);p.ball_v=Vector2(0,-0.9);ticks(1)
	check(p.score==1 and p.ball_v.y>0,'Breakout brick hit scores and reflects ball')
	begin(27);sim.state.hazards=[{'p':Vector2(0.3,0),'v':Vector2.ZERO,'size':0.13}];sim.state.players[0].p=Vector2.ZERO;sim.state.players[0].face=0;ticks(1,{0:{'action':true}});ticks(10)
	check(sim.state.players[0].score>=2 and sim.state.hazards.size()>=2,'Asteroid hit scores and splits a large rock')
	begin(28);sim.state.players[0].p=sim.state.items[0];ticks(1)
	check(sim.state.players[0].bag>0,'Treasure pickup goes into inventory')
	sim.state.players[0].p=sim.state.bases[0];ticks(1)
	check(sim.state.players[0].score>0 and sim.state.players[0].bag==0,'Treasure bank deposits inventory for score')
	begin(29);sim.state.time=3.0;sim.state.sequence=[0,3];ticks(1,{0:{'axis':Vector2.RIGHT}});ticks(1);ticks(1,{0:{'axis':Vector2.UP}})
	check(sim.state.players[0].memory_done and sim.state.players[0].score==2,'Memory correct sequence completes and scores')
	begin(30);ticks(1,{0:{'action':true}})
	check(sim.state.players[0].score==-2,'Early reaction is penalized')
	begin(30);sim.state.signal=1;sim.state.signal_clock=1;ticks(1,{0:{'action':true}})
	check(sim.state.players[0].score==4 and sim.state.players[0].reaction>=0,'First green-light reaction earns four points')
	begin(31);ticks(1,{0:{'action':true}})
	check(sim.state.tiles.count(0)>4,'Paint wave captures multiple nearby tiles')
	# Run every complete match with four bots, validating serialized LAN size as play develops.
	for g in range(32):
		var roster: Array=[]
		for i in range(4): roster.append({'name':'Bot%d'%i,'peer':i+1,'bot':true})
		sim.begin(g,roster,831+g)
		for tick in range(int(Sim.GAMES[g].duration*60)+1):
			sim.step(1.0/60,{})
			if tick%120==0: check(var_to_bytes(sim.state).size()<65536,'Network snapshot fits decode limit')
		check(sim.state.phase=='result','Full-duration match completes: '+Sim.GAMES[g].name)
		if g==12: check(sim.state.players.any(func(v):return v.score>=5),'Four flag bots complete a capture instead of endlessly trading flags')
		var values: Array=[]
		for player in sim.state.players: values.append(snappedf(player.score,0.1))
		print('FULL_MATCH ',g,' ',values)
	print('ARCADE_CHECKS ',checks,' FAILURES ',failures)
	quit(0 if failures==0 else 1)
