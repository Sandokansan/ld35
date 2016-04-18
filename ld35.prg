/*
 * Ludum Dare #35 Entry
 */
PROGRAM ld35;

import "phys.dll";

CONST
    SCALE = 4;
    TILE_WIDTH = 32*SCALE;
    TILE_HEIGHT = 32*SCALE;
    MAX_LEVEL_WIDTH = 40;
    MAX_LEVEL_HEIGHT = 40;

    SCREEN_WIDTH = 320*SCALE;
    SCREEN_HEIGHT = 240*SCALE;

    TILE_KIND_NONE = 0;     // other
    TILE_KIND_COG = 111;    // 'o'
    TILE_KIND_NORMAL = 120; // 'x'
    TILE_KIND_HERO1 = 49;   // '1'
    TILE_KIND_HERO2 = 50;   // '2'

    // IDs of loaded maps. I know *sigh* It got out of hand but this editor...
    TILE_GRAPH_NORMAL = 0;
    // 1, 2 reserved for scroll
    PCX_BOXSY_IDLE = 3;
    PCX_COGSY_IDLE = 4;
    PCX_COGSY_WALK = 5;
    PCX_TRIGSY_IDLE = 6;
    TILE_GRAPH_COG = 7;
    PCX_FAGSY_IDLE = 8;

    // Sprite sheet ids
    SPR_COGSY_WALK = 0;

    HEROES_MAX = 2;
    PLAYERS_MAX = 2;
    HERO_TYPES_MAX = 4;

    // Anim related
    ACT_IDLE = 0;
    ACT_WALK = 1;
    ACT_STOP = 2;
    MOM_RES = 1000; // momemtum "resolution" or scale -- Since physics it's a bit different.

    HERO_BOXSY = 0;    // I see they're been called 1 and 2 but my memory be hazy so names D:
    HERO_COGSY = 1;
    HERO_TRIGSY= 2;
    HERO_FAGSY = 3;
GLOBAL
    struct leveldata
        fpg;
        loadedfpg[100];
        loadedfpgs;
        loadedmap[100];
        loadedmaps = 0;
        struct spritesheet[20] // As loadedmaps and fpgs are here ...
          spr[20];
          count;
        end
        struct tiles[MAX_LEVEL_WIDTH*MAX_LEVEL_HEIGHT]
            pid;
            state;
            kind;
        end
        struct start
            x0;
            y0;
            x1;
            y1;
        end
        width;
        height;
        p_width;
        p_height;
        p_width_cbound;
        p_height_cbound;
        scroll;
    end
    struct herotype[HERO_TYPES_MAX]
        in_use = 0;
        pcx_idle;
        spr_walk;
        // Movement
        walk_max_speed;
        walk_acc;
        walk_deacc;
    end
    heroes;
    struct herodata[HEROES_MAX]
        claimed = 0;  // I presume this is for claimed by a player, as opposed to being in use, hence the tape.
        my_type;
        pid;
        // Graphics related
        action = 0;
        anim_pos = 0;
        // Movement
        walk_mom;
    end
    players;
    struct playerdata[PLAYERS_MAX]
        pid;
    end
LOCAL
    kill;
BEGIN

    set_fps(60,0);
    write_int(0,SCREEN_WIDTH-20,0,0,&fps);
    set_mode(SCREEN_WIDTH*1000 + SCREEN_HEIGHT);
    load_pal("pal/ld35.PAL");

    phys_init();

    //splash();

    load_level("1.lvl");   // prg\ld35\

    repeat
        frame;
    until(key(_ESC))

    unload_level();
END

//////////////////////////////////////////////////////////////////////////////
//
// Splash code
//
//////////////////////////////////////////////////////////////////////////////

Function splash()
Private
    idx;
    sg[3];
    sgs;
    t;
    fade_speed;
Begin

    fade_speed = 2;

    z = 1;
    x = SCREEN_WIDTH / 2;
    y = SCREEN_HEIGHT / 2;

    sg[sgs++] = new_map(200,200,100,100,100);
    fade(0,0,0,fade_speed);

    unsetz_on_any_key(id);

    while(idx<sgs && z)
        graph = sg[idx];
        fade(100,100,100,fade_speed);
        while(fading&&z) frame; end
        t = timer+200;
        while(timer<t && z) frame; end
        fade(0,0,0,fade_speed);
        while(fading) frame; end
        idx++;
    end

    fade(100,100,100,fade_speed);

End

Process unsetz_on_any_key(pid)
Begin
    repeat
        frame;
    until(ascii>0)
    pid.z = 0;
End

//////////////////////////////////////////////////////////////////////////////
//
// Level loading
//
//////////////////////////////////////////////////////////////////////////////

Function get_tile_kind(chr)
Begin
    return(chr);
End

Function lvl_load_pcx(mID, filename) // Shorthand for those that can't use square brackets or forward slashes
Begin
  leveldata.loadedmap[mID] = load_map("pcx/" + filename);
  leveldata.loadedmaps++;
End

Function lvl_pcx(mID)   // Shorthand for those that can't use square brackets
Begin
  return( leveldata.loadedmap[mID] );
End

Function extract_spr_sheet(source, target, num) // source and target = const id
Private
    i;
    w,h;
Begin
    w = graphic_info(0, lvl_pcx(source), g_wide) / num;
    h = graphic_info(0, lvl_pcx(source), g_height);

    for( i = 0 ; i < num ; i++ )
        leveldata.spritesheet[target].spr[i] = new_map(w, h, w/2, h-1, 0);
        map_block_copy(0, leveldata.spritesheet[target].spr[i], 0, 0, lvl_pcx(source), w * i, 0, w, h);
    end

    leveldata.spritesheet[target].count = num;
    unload_pcx(lvl_pcx(source));                  // good/bad?
End

Function spr_sheet(num, spr)
Begin
   return( leveldata.spritesheet[num].spr[spr]  );
End

Function next_spr(num, curr)
Private
    next;
Begin
    if( curr < (leveldata.spritesheet[num].count - 1) )
        next = curr + 1;
    else
        next = 0;
    end

    return( next );
End

Function init_hero_graphics(idx, idle, walk)
Begin
    herotype[idx].pcx_idle = idle;
    herotype[idx].spr_walk = walk;
End

Function init_hero_vars(idx, walk_speed, walk_acc, walk_deacc)
Begin
    herotype[idx].walk_max_speed = walk_speed;
    herotype[idx].walk_acc = walk_acc;
    herotype[idx].walk_deacc = walk_deacc;

    //herotype[idx].action = ACT_IDLE;
End

Function load_level(string s)
Private
    fg;
    bg;
    block;
    lvlfile;
    chr;
    kind;
    filesize = 0;
    h;
Begin
    leveldata.fpg = 0;

    leveldata.loadedmap[TILE_GRAPH_NORMAL] = new_map(TILE_WIDTH, TILE_HEIGHT, 0, 0, 255);
    leveldata.loadedmap[1] = load_pcx("pcx/background_fg.pcx"); //new_map(TILE_WIDTH, TILE_HEIGHT, 0, 0, 120);  fore, next bg
    leveldata.loadedmap[2] = load_pcx("pcx/background_bg.pcx"); //  new_map(TILE_WIDTH, TILE_HEIGHT, 0, 0, 55);
    leveldata.loadedmaps = 3;

    lvl_load_pcx(PCX_BOXSY_IDLE, "boxsy.map"); // does above
    lvl_load_pcx(PCX_COGSY_IDLE, "cogsy.map");
    lvl_load_pcx(PCX_COGSY_WALK, "cogsy_walk.pcx");
    lvl_load_pcx(PCX_TRIGSY_IDLE, "trigsy.map");
    lvl_load_pcx(TILE_GRAPH_COG, "cog.pcx");
    lvl_load_pcx(PCX_FAGSY_IDLE, "fagsy.map");

    extract_spr_sheet(PCX_COGSY_WALK, SPR_COGSY_WALK, 9);

    init_hero_graphics(HERO_BOXSY, PCX_BOXSY_IDLE, SPR_COGSY_WALK);         // INCORRECT WALK
    init_hero_graphics(HERO_COGSY, PCX_COGSY_IDLE, SPR_COGSY_WALK);
    init_hero_graphics(HERO_TRIGSY, PCX_TRIGSY_IDLE, SPR_COGSY_WALK);
    init_hero_graphics(HERO_FAGSY, PCX_FAGSY_IDLE, SPR_COGSY_WALK);

    init_hero_vars(HERO_BOXSY, 8, 125, 300);
    init_hero_vars(HERO_COGSY, 8, 250, 500);
    init_hero_vars(HERO_TRIGSY, 8, 250, 500);
    init_hero_vars(HERO_FAGSY, 10, 200, 400);

    herodata[0].pid = hero(0, HERO_BOXSY);
    herodata[1].pid = hero(1, HERO_COGSY);
    heroes = 2;

    //lvlfile = fopen(s, "r");

    if( lvlfile == 0 )
        s = "prg/ld35/" + s;
    end

    lvlfile = fopen(s, "r");

    x = 0;
    y = 0;
    unit_size = 1;
    filesize = filelength(lvlfile);

    while(ftell(lvlfile) < filesize)
        fread(&chr, 1, lvlfile);

        if(chr == 10)
            if(x>leveldata.width) leveldata.width=x; end
            y++;
            x = 0;
            continue;
        end

        if(y+1>leveldata.height) leveldata.height=y+1; end

        leveldata.tiles[x+MAX_LEVEL_WIDTH*y].kind = chr;//get_tile_kind(chr);
        x++;
    end

    for(x=0; x<leveldata.width; x++)
    for(y=0; y<leveldata.height; y++)
        kind = leveldata.tiles[x+MAX_LEVEL_WIDTH*y].kind;
        switch(kind)
        case TILE_KIND_HERO1:
            //herodata[0].pid.x = x*TILE_WIDTH + TILE_WIDTH/2;
            //herodata[0].pid.y = y*TILE_HEIGHT + TILE_HEIGHT/2;
            phy_body_set_position(herodata[0].pid, x*TILE_WIDTH + TILE_WIDTH/2, y*TILE_HEIGHT + TILE_HEIGHT/2);
        end
        case TILE_KIND_HERO2:
            herodata[1].pid.x = x*TILE_WIDTH + TILE_WIDTH/2;
            herodata[1].pid.y = y*TILE_HEIGHT + TILE_HEIGHT/2;
            phy_body_set_position(herodata[1].pid, x*TILE_WIDTH + TILE_WIDTH/2, y*TILE_HEIGHT + TILE_HEIGHT/2);
        end
        case TILE_KIND_COG:
            leveldata.tiles[x+MAX_LEVEL_WIDTH*y].pid = Cog(lvl_pcx(TILE_GRAPH_COG), x, y);
        end
        default:
            leveldata.tiles[x+MAX_LEVEL_WIDTH*y].pid = tile(x, y, kind);
        end
        end

    end
    end

    leveldata.p_width = TILE_WIDTH * leveldata.width;
    leveldata.p_height = TILE_HEIGHT * leveldata.height;
    leveldata.p_width_cbound = leveldata.p_width - SCREEN_WIDTH/2;
    leveldata.p_height_cbound = leveldata.p_height - SCREEN_HEIGHT/2;

    //for(x=0; x<LEVEL_WIDTH; x++)
    //    for(y=0; y<LEVEL_HEIGHT; y++)
    //        leveldata.tiles[x+LEVEL_WIDTH*y].pid = tile(x, y, TILE_KIND_NORMAL);
    //    end
    //end


    playerdata[0].pid = player(0);
    players = 1;

    fg = leveldata.loadedmap[1];
    bg = leveldata.loadedmap[2];
    leveldata.scroll = 0;
    start_scroll(leveldata.scroll, 0, fg, bg, 0, 15); // n, f, g, bg, r, flags
    scroll[leveldata.scroll].camera = camera();
    //scroll[leveldata.scroll].ratio = 600; // bg speed = 200 seeing no difference???
    //scroll[leveldata.scroll].speed = 0; // fg speed = 0
End

Function unload_level()
Begin
    signal(scroll[leveldata.scroll].camera, S_KILL);
    stop_scroll(leveldata.scroll);

    for(x=0; x<players; x++)
        signal(playerdata[x].pid, S_KILL_TREE);
    end
    for(x=0; x<MAX_LEVEL_WIDTH; x++)
        for(y=0; y<MAX_LEVEL_HEIGHT; y++)
            if(leveldata.tiles[x+MAX_LEVEL_WIDTH*y].pid)
                //signal(leveldata.tiles[x+MAX_LEVEL_WIDTH*y].pid, S_KILL);
                leveldata.tiles[x+MAX_LEVEL_WIDTH*y].pid.kill = 1;
            end
        end
    end
    for(x=0; x<heroes; x++)
        signal(herodata[x].pid, S_KILL_TREE);
    end

    for(x=0; x<leveldata.loadedmaps; x++)
        unload_map(leveldata.loadedmap[x]);
    end
    leveldata.loadedmaps = 0;
    for(x=0; x<leveldata.loadedfpgs; x++)
        unload_fpg(leveldata.loadedfpg[x]);
    end
    leveldata.loadedfpgs = 0;

    let_me_alone(); // TAPE to kill hero_animators()
End

//////////////////////////////////////////////////////////////////////////////
//
// Player code
//
//////////////////////////////////////////////////////////////////////////////

Process player(idx)
Private
    heroidx = 0;
    k_n, k_m;
    heroid;
    forcex;
    forcey;
Begin

    ctype = C_SCROLL;

    heroidx = player_next_hero(1);     // Changed this right here so that mr Cog is first
    if(heroidx<0) return(0); end

    herodata[heroidx].claimed = true;
    heroid = herodata[heroidx].pid;

    Loop
        // Next hero
        if(key(_n))
            if(!k_n)
                k_n = 1;
                heroidx = player_next_hero(heroidx);
                heroid = herodata[heroidx].pid;
            end
        else
            k_n = 0;
        end

        if( key(_m) )
            if( !k_m )
                k_m = 1;
                hero_next_hero(heroidx);
            end
        else
           k_m = 0;
        end

        // Movement
        if(key(_left))
            heroid.flags = 1;
            herodata[heroidx].walk_mom -= herotype[herodata[heroidx].my_type].walk_acc;
            //heroid.x -= herodata[heroidx].walk_speed;
            herodata[heroidx].action = ACT_WALK;
            //forcex = -5000;
        else
            if(key(_right))
                heroid.flags = 0;
                herodata[heroidx].walk_mom += herotype[herodata[heroidx].my_type].walk_acc;
                //heroid.x += herodata[heroidx].walk_speed;
                herodata[heroidx].action = ACT_WALK;
                //forcex = 5000;
            else
                //forcex = 0;
                herodata[heroidx].action = ACT_STOP;
            end
        end

        //phy_body_move(heroid, herodata[heroidx].walk_mom / MOM_RES, 0);
        /*
        if(phy_body_get_speed(heroid) < 500)
            phy_body_apply_force_xy(heroid, forcex, forcey);
        end
        */
        frame;
    End
End

Process camera()
Begin
    priority = -1;

    loop
        if(  abs(herodata[0].pid.x - herodata[1].pid.x) < SCREEN_WIDTH
          && abs(herodata[0].pid.y - herodata[1].pid.y) < SCREEN_HEIGHT
          )
            x = (herodata[0].pid.x + herodata[1].pid.x) / 2;
            y = (herodata[0].pid.y + herodata[1].pid.y) / 2;
        else
            x = herodata[0].pid.x;
            y = herodata[0].pid.y;
        end

        if(leveldata.p_width>SCREEN_WIDTH)
            if(x<SCREEN_WIDTH/2)
                x = SCREEN_WIDTH/2;
            else if(x > leveldata.p_width_cbound)
                x = leveldata.p_width_cbound;
            end end
        else
            x = leveldata.p_width/2;
        end

        if(leveldata.p_height>SCREEN_HEIGHT)
            if(y<SCREEN_HEIGHT/2)
                y = SCREEN_HEIGHT/2;
            else if(y > leveldata.p_height_cbound)
                y = leveldata.p_height_cbound;
            end end
        else
            y = leveldata.p_height/2;
        end

        write_int(0, 0, 0,0,&x);
        write_int(0,50, 0,0,&y);
        write_int(0, 0,20,0,&herodata[0].pid.x);
        write_int(0,50,20,0,&herodata[0].pid.y);
        write_int(0, 0,30,0,&herodata[1].pid.x);
        write_int(0,50,30,0,&herodata[1].pid.y);
        frame;
    end
end

Function player_next_hero(current)
Private
    heroidx = 0;
Begin
    while(heroidx<heroes && herodata[(current+heroidx)%heroes].claimed)
        heroidx++;
    end
    if(heroidx == heroes)
        return(-1);
    end

    herodata[current].claimed = false;
    herodata[(current+heroidx)%heroes].claimed = true;
    return((current+heroidx)%heroes);
End

Function hero_next_hero(heroidx)
Private
    n;
Begin
    n = iter_next_hero(herodata[heroidx].my_type);

    if( n != herodata[heroidx].my_type )
        herodata[heroidx].my_type = n;
    end
End

Function iter_next_hero(current)
Begin
    for( x = current ; x < HERO_TYPES_MAX ; x++ )
        if( !(herotype[x].in_use) ) return( x ); end
    end
    for( x = 0 ; x < current ; x++ )
        if( !(herotype[x].in_use) ) return( x ); end
    end

    return( current );
End

//
// Level objects and hero code
//
Process hero(idx,my_type)
Private
    prev_y = 0;
    falling =0;
    speed = 0;
Begin
    ctype = C_SCROLL;
    size = 100*SCALE;

    x = 300+idx*100;
    y = 300;
    // Elasticity and friction seem to be hard coded D:
    phy_body_create_box_center(id, 16*SCALE, 32*SCALE, 100, MAX_INT, 0, 0, 8*SCALE, 32*SCALE); //, 10000, 1, 100); // x y mass moment elasticity friction
    //phy_body_create_box(id, 16*SCALE, 32*SCALE, 100);

    herodata[idx].my_type = my_type;
    herotype[my_type].in_use = true;

    hero_animator(idx);

    write_int(0,10,100 + 20 * idx, 0, &falling);

    Loop
        speed = phy_body_get_speed(id);
        falling = 1000 - 900 * clamp(speed * 100 / get_hero_max_speed(idx), 0, 100) / 100;
        // Shapeshift
        if( herodata[idx].my_type != my_type )
            herotype[my_type].in_use = false;
            my_type = herodata[idx].my_type;
            herotype[my_type].in_use = true;
            herodata[idx].anim_pos = 0;
        end

        // Movement
        if( herodata[idx].walk_mom <> 0 )
            if( abs(herodata[idx].walk_mom) > herotype[my_type].walk_max_speed * MOM_RES )
                herodata[idx].walk_mom = sign(herodata[idx].walk_mom) * herotype[my_type].walk_max_speed * MOM_RES;
            end

            if( herodata[idx].action != ACT_WALK )

                herodata[idx].walk_mom += asign(herodata[idx].walk_mom) * herotype[my_type].walk_deacc;

                if( abs(herodata[idx].walk_mom) <= herotype[my_type].walk_deacc )
                    herodata[idx].walk_mom = 0;
                end
            end

            //x += herodata[idx].walk_mom / MOM_RES;
        else
            if( speed == 0 or y <> prev_y )
                herodata[idx].action = ACT_IDLE;
            end
        end

        // Physics / moving
        if(phy_body_get_speed(id) < herotype[my_type].walk_max_speed * 50)  // ugh
            phy_body_apply_force_xy(id, herodata[idx].walk_mom, 0);
        end

        prev_y = y;
        frame;
    End
End

Function get_hero_max_speed(idx)
Begin
    return( herotype[herodata[idx].my_type].walk_max_speed * 50 ); // ugh
End

Process hero_animator(idx)   // Because frame; stuff and physics don't dance together
Begin
    Loop
        switch(herodata[idx].action)   // oh lol
        case ACT_IDLE:
            father.graph = lvl_pcx(herotype[herodata[idx].my_type].pcx_idle);
        end
        case ACT_WALK, ACT_STOP:
            herodata[idx].anim_pos = next_spr(herotype[herodata[idx].my_type].spr_walk, herodata[idx].anim_pos);
            father.graph = spr_sheet(herotype[herodata[idx].my_type].spr_walk, herodata[idx].anim_pos);
        end
        end

        if( herodata[idx].action == ACT_IDLE )
            frame( 200 );
        else
            frame( 1000 - 900 * clamp(phy_body_get_speed(father) * 100 / get_hero_max_speed(idx), 0, 100) / 100 );
            //frame( 800 - 700 * (abs(herodata[idx].walk_mom) / herotype[herodata[idx].my_type].walk_max_speed) / MOM_RES);
        end
    End
End

Function clamp(val, min, max)
Begin
    if( val < min ) return( min ); end
    if( val > max ) return( max ); end
    return( val );
End

Function sign(val)
Begin
    if( val < 0 ) return(-1); end return(1);
End

Function asign(val)
Begin
    if( val < 0 ) return(1); end return(-1);
End

Process tile(tx, ty, kind)
Private
    wall[4];
    walls;
    //draws[4];
    w;
Begin

    kill = 0;
    x = TILE_WIDTH*tx;
    y = TILE_HEIGHT*ty;
    w = 5;

    switch(kind)
    case TILE_KIND_NORMAL:
        graph = leveldata.loadedmap[TILE_GRAPH_NORMAL];
    end
    default:
        //graph = write_in_map(0,"t:" + kind, 0);
        return;
    end
    end

    if(tx>0)
    if(leveldata.tiles[(tx-1)+ty*MAX_LEVEL_WIDTH].kind != TILE_KIND_NORMAL)
        //draws[walls] = draw(1,140,15,0,x,y,x,y+TILE_HEIGHT);
        wall[walls++] = add_fixed_body(x,y,x,y+TILE_HEIGHT,w);
    end end

    if(tx<leveldata.width-1)
    if(leveldata.tiles[(tx+1)+ty*MAX_LEVEL_WIDTH].kind != TILE_KIND_NORMAL)
        //draws[walls] = draw(1,140,15,0,x+TILE_WIDTH,y,x+TILE_WIDTH,y+TILE_HEIGHT);
        wall[walls++] = add_fixed_body(x+TILE_WIDTH,y,x+TILE_WIDTH,y+TILE_HEIGHT,w);
    end end

    if(ty>0)
    if(leveldata.tiles[tx+(ty-1)*MAX_LEVEL_WIDTH].kind != TILE_KIND_NORMAL)
        //draws[walls] = draw(1,140,15,0,x,y,x+TILE_WIDTH,y);
        wall[walls++] = add_fixed_body(x,y,x+TILE_WIDTH,y,w);
    end end

    if(ty<leveldata.height-1)
    if(leveldata.tiles[tx+(ty+1)*MAX_LEVEL_WIDTH].kind != TILE_KIND_NORMAL)
        //draws[walls] = draw(1,140,15,0,x,y+TILE_HEIGHT,x+TILE_WIDTH,y+TILE_HEIGHT);
        wall[walls++] = add_fixed_body(x,y+TILE_HEIGHT,x+TILE_WIDTH,y+TILE_HEIGHT,w);
    end end

    ctype = C_SCROLL;

    Repeat
        frame;
    Until(kill)

    for(;walls--;)
        remove_fixed_body(wall[walls]);
        //delete_draw(draws[walls]);
    end
End

Process lift(minx, miny, maxx, maxy, startx, starty)
Begin
End

Process Cog(graph,x,y)
Begin
    size=25*SCALE;
  ctype = C_SCROLL;
  x *= TILE_WIDTH;
  y *= TILE_HEIGHT;

  Repeat
    angle += 10000;
    frame(200);
  Until(kill)
End