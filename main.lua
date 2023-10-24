--save chicago!

-- ensure min speeds, pos or neg
function minspeed(spd,minspd)
  if (abs(spd)!=0 and abs(spd)<minspd) then
    if spd<0 then spd=-minspd else spd=minspd end
  end
  return spd
end

function pad(string,length)
  string=""..string
  if (#string==length) return string
  return "0"..pad(string,length-1)
end

function is_offstage(obj,offset)
  offset=offset or 0
  return obj.x<0-offset or obj.x>128+offset or obj.x<0-offset or obj.y>128+offset
end

function _init()
  t=0
  level=1
  hiscore=0
  enemieskilled=0
  enemyspeed=1
  mode="title"
  explosions={}
  buildingcrash={}
  rumblingrows={}
  peopleleft=100
  bullets={}
  enemies={}
  supply={}
  balloon={}
  bonuscheck={x=0,y=15}
  bonuslastbrick=nil
  make_player()
  make_buildings()
  music(0,2500)
end

function game_over()
  t=0
  hiscore=max(hiscore,p.score)
  level=1
  p.respawn()
  sfx(04)
  mode="game over"
end

function status_bar()
  rectfill(0,0,128,8,1)
  local fuelclr=9
  -- blink fuel if low (and game isn't over)
  if (mode=="game" and t%40<20 and p.fuel<p.lowfuel) fuelclr=7
  print("fuel:"..flr(p.fuel),4,2,fuelclr)
  print("score:"..p.score.."0",48,2,9)
  print(p.life,100,2,9)
end

function check_level()
  if (enemieskilled>=5 and level==1 or enemieskilled>=10) then
    enemieskilled=0
    enemies={}
    supply={}
    balloon={}
    bullets={}
    t=0
    enemyspeed=level
    mode="bonus"
    -- set min/max starting points for bonuscheck
    for building in all(buildings) do
      bonuscheck.y = min(bonuscheck.y,15-building.height)
      bonuscheck.x = max(bonuscheck.x,building.x+building.width)
    end
  end
end

function start_game()
  music(-1)
  sfx(05)
  enemies={}
  mode="game"
end

function restart()
  t=0
  p.score=0
  p.enemieskilled=0
  p.life="♥♥♥"
  mode="title"
  make_buildings()
  music(0,2500)
end

function _update()
  t+=1
  building_update()

  if mode=="title" then

    building_blink(4)
    check_enemy_spawn(5)
    for grp in all({enemies,supply,balloon}) do
      for obj in all(grp) do
        obj.update(obj)
      end
    end
    -- enough time has elapsed and btn is pressed
    if t>5 and btn(4) then
      start_game()
    end

  elseif mode=="bonus" then

    for grp in all({explosions,rumblingrows}) do
      for obj in all(grp) do
        obj.update(obj)
      end
    end
    --
    if bonuslastbrick~=nil then
      mset(bonuslastbrick.x,bonuslastbrick.y,05)
      bonuslastbrick=nil
    end
    -- tally bonus points
    if (bonuscheck.y<16) then
      local map_sprite=mget(bonuscheck.x,bonuscheck.y)
      -- skip tiles until brick
      while map_sprite>5 and bonuscheck.y<16 do
        bonuscheck.x-=1
        if bonuscheck.x<0 then
          bonuscheck.y+=1
          bonuscheck.x=15
        end
        map_sprite=mget(bonuscheck.x,bonuscheck.y)
      end
      -- unbroken brick
      p.score+=1
      bonuslastbrick={x=bonuscheck.x,y=bonuscheck.y}
      sfx(12)
      mset(bonuscheck.x,bonuscheck.y,map_sprite+48) --white flash
      bonuscheck.x-=1
      if bonuscheck.x<0 then
        bonuscheck.y+=1
        bonuscheck.x=15
      end
    else
      building_blink(1)
      if (t>5 and btn(4)) then
        -- add remaining bonus
        t=0
        level+=1
        p.respawn()
        mode="game"
      end
    end

  elseif mode=="game" then

    p.update()
    building_blink(3)
    check_enemy_spawn(level+1)
    check_supply_spawn()
    for grp in all({bullets,enemies,supply,balloon,explosions,rumblingrows}) do
      for obj in all(grp) do
        obj.update(obj)
      end
    end

  elseif mode=="game over" then

    building_blink(1)
    for grp in all({enemies,supply,balloon,explosions,rumblingrows}) do
      for obj in all(grp) do
        obj.update(obj)
      end
    end
    if (t>5 and btn(4)) then
      restart()
    end

  end
end

function draw_bg()
  map(0,0,0,0,128,32)
end

-- draw!
function _draw()
  cls()
  draw_bg()

  if mode=="title" then

    for grp in all({enemies}) do
      for obj in all(grp) do
        obj.draw(obj)
      end
    end
    rectfill(0,0,128,8,1)
    rectfill(16,1,112,7,9)
    print("beaty softworks presents",17,2,1)
    print("save chicago!",39,31,1)
    print("save chicago!",39,30,9)
    print("save chicago!",39,29,7)
    print("🅾️ start game",39,45,1)
    rectfill(0,119,128,128,1)
    print("hi-score:"..pad(hiscore.."0",6),34,121,9)

  elseif mode=="game" then

    for grp in all({bullets,enemies,supply,balloon,explosions,rumblingrows}) do
      for obj in all(grp) do
        obj.draw(obj)
      end
    end
    p.draw()
    status_bar()

  elseif mode=="bonus" then

    for grp in all({explosions,rumblingrows}) do
      for obj in all(grp) do
        obj.draw(obj)
      end
    end
    status_bar()
    print("level "..level.." complete",32,31,1)
    if bonuscheck.y<16 and t%30<15 then
      print("bonus points",40,45,1)
    end

  elseif mode=="game over" then

    for grp in all({enemies,supply,balloon,explosions}) do
      for obj in all(grp) do
        obj.draw(obj)
      end
    end
      rectfill(0,0,128,8,1)
      print("score:"..p.score.."0",48,2,9)
      print("game  over",44,31,1)
      print("🅾️ restart",44,45,1)
  end
end
