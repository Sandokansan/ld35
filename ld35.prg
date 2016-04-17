/*
 * Ludum Dare #35 Entry
 */
PROGRAM ld35;
CONST
    TILE_WIDTH = 32;
    TILE_HEIGHT = 32;
    LEVEL_WIDTH = 40;
    LEVEL_HEIGHT = 40;

    SCREEN_WIDTH = 320;
    SCREEN_HEIGHT = 240;

    TILE_KIND_NONE = 0;     // other
    TILE_KIND_NORMAL = 120; // 'x'
    TILE_KIND_OTHER = 2;    //
    TILE_KIND_HERO1 = 49;   // '1'
    TILE_KIND_HERO2 = 50;   // '2'
    HEROES_MAX = 2;
    PLAYERS_MAX = 2;
GLOBAL
    struct leveldata
        fpg;
        loadedfpg[100];
        loadedfpgs;
        loadedmap[100];
        loadedmaps;
        struct tiles[LEVEL_WIDTH*LEVEL_HEIGHT]
            pid;
            state;
        end
        struct start
            x0;
            y0;
            x1;
            y1;
        end
    end
    heroes;
    struct herodata[HEROES_MAX]
        claimed = 0;
        pid;
    end
    players;
    struct playerdata[PLAYERS_MAX]
        pid;
    end
BEGIN

    set_fps(60,0);
    set_mode(SCREEN_WIDTH*1000 + SCREEN_HEIGHT);

    splash();

    load_level("1.lvl");

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

    leveldata.loadedmap[0] = new_map(TILE_WIDTH, TILE_HEIGHT, 0, 0, 100);
    leveldata.loadedmap[1] = write_in_map(0, "FG", 0); //new_map(TILE_WIDTH, TILE_HEIGHT, 0, 0, 120);
    leveldata.loadedmap[2] = new_map(TILE_WIDTH, TILE_HEIGHT, 0, 0, 55);
    leveldata.loadedmaps = 3;

    herodata[0].pid = hero(0);
    herodata[1].pid = hero(1);
    heroes = 2;

    lvlfile = fopen("/home/bergfi/development/ld35/1.lvl", "r");

    x = 0;
    y = 0;
    unit_size = 1;
    filesize = filelength(lvlfile);

    while(ftell(lvlfile) < filesize)
        fread(&chr, 1, lvlfile);

        if(chr == 10) y++; x = 0; continue; end

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
            leveldata.tiles[x+LEVEL_WIDTH*y].pid = tile(x, y, kind);
        end
        end

        x++;
    end


    //for(x=0; x<LEVEL_WIDTH; x++)
    //    for(y=0; y<LEVEL_HEIGHT; y++)
    //        leveldata.tiles[x+LEVEL_WIDTH*y].pid = tile(x, y, TILE_KIND_NORMAL);
    //    end
    //end


    playerdata[0].pid = player(0);
    players = 1;

    fg = leveldata.loadedmap[1];
    bg = leveldata.loadedmap[2];
    start_scroll(0, 0, 0, bg, 0, 15);
End

Function unload_level()
Begin

    stop_scroll(0);

    for(x=0; x<players; x++)
        signal(playerdata[x].pid, S_KILL);
    end
    for(x=0; x<LEVEL_WIDTH; x++)
        for(y=0; y<LEVEL_HEIGHT; y++)
            signal(leveldata.tiles[x+LEVEL_WIDTH*y].pid, S_KILL);
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

    heroidx = player_next_hero(0);
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
        if(key(_left)) heroid.x--; end
        if(key(_right)) heroid.x++; end

        frame;
    End
End

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
Begin
    ctype = C_SCROLL;

    graph = new_map(20,20,10,10,70+16*idx);

    Loop frame; End
End

Process tile(tx, ty, kind)
Begin

    switch(kind)
    case TILE_KIND_NORMAL:
    end
    default:
        return;
    end
    end


    ctype = C_SCROLL;
    x = TILE_WIDTH*tx;
    y = TILE_HEIGHT*ty;

    graph = write_in_map(0,"t:" + kind, 0);

    Loop
        frame;
    End
End

Process lift(minx, miny, maxx, maxy, startx, starty)
Begin
End