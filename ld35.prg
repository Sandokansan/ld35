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

    TILE_KIND_NONE = 0;
    TILE_KIND_NORMAL = 120;
    TILE_KIND_OTHER = 2;
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

    write(0,0,0,0,m320x240);

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
    switch(chr)
    case char("x"):
        return(TILE_KIND_NORMAL);
    end
    default:
        return(TILE_KIND_NONE);
    end
    end
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
Begin
    leveldata.fpg = 0;

    leveldata.loadedmap[0] = new_map(TILE_WIDTH, TILE_HEIGHT, 0, 0, 100);
    leveldata.loadedmap[1] = write_in_map(0, "FG", 0); //new_map(TILE_WIDTH, TILE_HEIGHT, 0, 0, 120);
    leveldata.loadedmap[2] = new_map(TILE_WIDTH, TILE_HEIGHT, 0, 0, 55);
    leveldata.loadedmaps = 3;


    lvlfile = fopen("/home/bergfi/development/ld35/1.lvl", "r");

    x = 0;
    y = 0;
    unit_size = 1;
    filesize = filelength(lvlfile);

    while(ftell(lvlfile) < filesize)
       fread(&chr, 1, lvlfile);

       if(chr == 10) y++; x = 0; continue; end

       kind = get_tile_kind(chr);
       leveldata.tiles[x+LEVEL_WIDTH*y].pid = tile(x, y, kind);

       x++;
    end


    //for(x=0; x<LEVEL_WIDTH; x++)
    //    for(y=0; y<LEVEL_HEIGHT; y++)
    //        leveldata.tiles[x+LEVEL_WIDTH*y].pid = tile(x, y, TILE_KIND_NORMAL);
    //    end
    //end

    herodata[0].pid = hero(0);
    herodata[1].pid = hero(1);
    heroes = 2;

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

Process player(idx)
Private
    heroidx = 0;
Begin

    ctype = C_SCROLL;

    while(heroidx<HEROES_MAX && herodata[heroidx].claimed)
        heroidx++;
    end
    if(heroidx == HEROES_MAX)
        return(0);
    end
    herodata[heroidx].claimed = true;

    Loop
        frame;
    End
End

Process hero(idx)
Begin
    ctype = C_SCROLL;
    Loop frame; End
End

Process tile(tx, ty, kind)
Begin

    if(kind == TILE_KIND_NONE) return; end

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