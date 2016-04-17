/*
 * Ludum Dare #35 Entry
 */
PROGRAM ld35;
CONST
    TILE_WIDTH = 128;
    TILE_HEIGHT = 128;
    MAX_LEVEL_WIDTH = 40;
    MAX_LEVEL_HEIGHT = 40;

    SCREEN_WIDTH = 1280;
    SCREEN_HEIGHT = 960;

    TILE_KIND_NONE = 0;     // other
    TILE_KIND_NORMAL = 120; // 'x'
    TILE_KIND_OTHER = 2;    //
    TILE_KIND_HERO1 = 49;   // '1'
    TILE_KIND_HERO2 = 50;   // '2'

    // IDs of loaded maps. I know *sigh* It got out of hand but this editor...
    TILE_GRAPH_NORMAL = 0;
    // 1, 2 reserved for scroll
    PCX_BOXSY_IDLE = 3;
    PCX_COGSY_IDLE = 4;
    PCX_COGSY_WALK = 5;
    PCX_TRIGSY_IDLE = 6;

    // Sprite sheet ids
    SPR_COGSY_WALK = 0;

    HEROES_MAX = 3;
    PLAYERS_MAX = 2;

    // Anim related
    ACT_IDLE = 0;
    ACT_WALK = 1;
    ACT_STOP = 2;
    MOM_RES = 1000; // momemtum "resolution" or scale

    HERO_BOXSY = 0;    // I see they're been called 1 and 2 but my memory be hazy so names D:
    HERO_COGSY = 1;
    HERO_TRIGSY= 2;
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
    heroes;
    struct herodata[HEROES_MAX]
        claimed = 0;
        pid;
        // Graphics related
        action;
        pcx_idle;
        spr_walk;
        // Movement
        walk_max_speed;
        walk_mom;
        walk_acc;
        walk_deacc;
    end
    players;
    struct playerdata[PLAYERS_MAX]
        pid;
    end
BEGIN

    set_fps(60,0);
    set_mode(SCREEN_WIDTH*1000 + SCREEN_HEIGHT);
    load_pal("ld35.pal");

    //splash();

    load_level("prg\ld35\1.lvl");   // prg\ld35\

    repeat
        frame;
    until(key(_ESC))

    unload_level();
END

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

Function get_tile_kind(chr)
Begin
    return(chr);
End

Function lvl_load_pcx(mID, filename) // Shorthand for those that can't use square brackets or forward slashes
Begin
  leveldata.loadedmap[mID] = load_map("pcx\" + filename);
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
    herodata[idx].pcx_idle = idle;
    herodata[idx].spr_walk = walk;
End

Function init_hero_vars(idx, walk_speed, walk_acc, walk_deacc)
Begin
    herodata[idx].walk_max_speed = walk_speed;
    herodata[idx].walk_acc = walk_acc;
    herodata[idx].walk_deacc = walk_deacc;
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
    leveldata.loadedmap[1] = load_pcx("pcx\background_fg.pcx"); //new_map(TILE_WIDTH, TILE_HEIGHT, 0, 0, 120);  fore, next bg
    leveldata.loadedmap[2] = load_pcx("pcx\background_bg.pcx"); //  new_map(TILE_WIDTH, TILE_HEIGHT, 0, 0, 55);
    leveldata.loadedmaps = 3;

    lvl_load_pcx(PCX_BOXSY_IDLE, "boxsy.map"); // does above
    lvl_load_pcx(PCX_COGSY_IDLE, "cogsy.map");
    lvl_load_pcx(PCX_COGSY_WALK, "cogsy_walk.pcx");
    lvl_load_pcx(PCX_TRIGSY_IDLE, "trigsy.map");

    extract_spr_sheet(PCX_COGSY_WALK, SPR_COGSY_WALK, 9);

    init_hero_graphics(HERO_BOXSY, PCX_BOXSY_IDLE, SPR_COGSY_WALK);         // INCORRECT WALK
    init_hero_graphics(HERO_COGSY, PCX_COGSY_IDLE, SPR_COGSY_WALK);
    init_hero_graphics(HERO_TRIGSY, PCX_TRIGSY_IDLE, SPR_COGSY_WALK);

    init_hero_vars(HERO_BOXSY, 8, 25, 90);
    init_hero_vars(HERO_COGSY, 8, 250, 500);
    init_hero_vars(HERO_TRIGSY, 8, 250, 500);

    herodata[0].pid = hero(HERO_BOXSY);
    herodata[1].pid = hero(HERO_COGSY);
    herodata[2].pid = hero(HERO_TRIGSY);
    heroes = 2;

    lvlfile = fopen(s, "r");

    x = 0;
    y = 0;
    unit_size = 1;
    filesize = filelength(lvlfile);

    while(ftell(lvlfile) < filesize)
        fread(&chr, 1, lvlfile);

        if(chr == 10)
            if(x>leveldata.width) leveldata.width=x; end
            leveldata.height++;
            y++;
            x = 0;
            continue;
        end

        kind = get_tile_kind(chr);
        switch(kind)
        case TILE_KIND_HERO1:
            herodata[0].pid.x = x*TILE_WIDTH + TILE_WIDTH/2;
            herodata[0].pid.y = y*TILE_HEIGHT + TILE_HEIGHT/2;
        end
        case TILE_KIND_HERO2:
            herodata[1].pid.x = x*TILE_WIDTH + TILE_WIDTH/2;
            herodata[1].pid.y = y*TILE_HEIGHT + TILE_HEIGHT/2;
        end
        default:
            leveldata.tiles[x+MAX_LEVEL_WIDTH*y].pid = tile(x, y, kind);
        end
        end

        x++;
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
        signal(playerdata[x].pid, S_KILL);
    end
    for(x=0; x<MAX_LEVEL_WIDTH; x++)
        for(y=0; y<MAX_LEVEL_HEIGHT; y++)
            if(leveldata.tiles[x+MAX_LEVEL_WIDTH*y].pid)
                signal(leveldata.tiles[x+MAX_LEVEL_WIDTH*y].pid, S_KILL);
            end
        end
    end
    for(x=0; x<heroes; x++)
        signal(herodata[x].pid, S_KILL);
    end

    for(x=0; x<leveldata.loadedmaps; x++)
        unload_map(leveldata.loadedmap[x]);
    end
    leveldata.loadedmaps = 0;
    for(x=0; x<leveldata.loadedfpgs; x++)
        unload_fpg(leveldata.loadedfpg[x]);
    end
    leveldata.loadedfpgs = 0;
End

//
// Player code
//
Process player(idx)
Private
    heroidx = 0;
    k_n;
    heroid;
Begin

    ctype = C_SCROLL;

    heroidx = player_next_hero(1);     // Changed this right here so that mr Cog is first
    if(heroidx<0) return(0); end

    herodata[heroidx].claimed = true;
    heroid = herodata[heroidx].pid;
    Loop
        if(key(_n))
            if(!k_n)
                k_n = 1;
                heroidx = player_next_hero(heroidx);
                heroid = herodata[heroidx].pid;
            end
        else
            k_n = 0;
        end

        if(key(_left))
            heroid.flags = 1;
            herodata[heroidx].walk_mom -= herodata[heroidx].walk_acc;
            //heroid.x -= herodata[heroidx].walk_speed;
            herodata[heroidx].action = ACT_WALK;
        else
            if(key(_right))
                heroid.flags = 0;
                herodata[heroidx].walk_mom += herodata[heroidx].walk_acc;
                //heroid.x += herodata[heroidx].walk_speed;
                herodata[heroidx].action = ACT_WALK;
            else
                herodata[heroidx].action = ACT_STOP;
            end
        end

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

        write_int(0,0,0,0,&x);
        write_int(0,0,10,0,&y);
        frame;
    end
end

Function player_next_hero(current)
Private
    heroidx;
Begin
    heroidx = 0;
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
//
// Level objects and hero code
//
Process hero(idx)
Private
    anim_pos = 0;
Begin
    herodata[idx].action = ACT_IDLE;

    ctype = C_SCROLL;
    size = 400;

    Loop
        if( herodata[idx].walk_mom <> 0 )
            if( abs(herodata[idx].walk_mom) > herodata[idx].walk_max_speed * MOM_RES )
                herodata[idx].walk_mom = sign(herodata[idx].walk_mom) * herodata[idx].walk_max_speed * MOM_RES;
            end

            if( herodata[idx].action != ACT_WALK )

                herodata[idx].walk_mom += asign(herodata[idx].walk_mom) * herodata[idx].walk_deacc;

                if( abs(herodata[idx].walk_mom) <= herodata[idx].walk_deacc )
                    herodata[idx].walk_mom = 0;
                end
            end

            x += herodata[idx].walk_mom / MOM_RES;
        else
            herodata[idx].action = ACT_IDLE;
        end

        switch(herodata[idx].action)   // oh lol
        case ACT_IDLE:
            graph = lvl_pcx(herodata[idx].pcx_idle);
        end
        case ACT_WALK, ACT_STOP:
            anim_pos = next_spr(herodata[idx].spr_walk, anim_pos);
            graph = spr_sheet(herodata[idx].spr_walk, anim_pos);
        end
        end

        if( herodata[idx].action == ACT_STOP )
            frame( 200 );
         else
            frame( 800 - 700 * (abs(herodata[idx].walk_mom) / herodata[idx].walk_max_speed) / MOM_RES);
         end
    End
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
Begin

    switch(kind)
    case TILE_KIND_NORMAL:
        graph = leveldata.loadedmap[TILE_GRAPH_NORMAL];
    end
    default:
        graph = write_in_map(0,"t:" + kind, 0);
        return;
    end
    end

    ctype = C_SCROLL;
    x = TILE_WIDTH*tx;
    y = TILE_HEIGHT*ty;

    Loop
        frame;
    End
End

Process lift(minx, miny, maxx, maxy, startx, starty)
Begin
End