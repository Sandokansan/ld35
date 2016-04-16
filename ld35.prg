/*
 * Ludum Dare #35 Entry
 */
PROGRAM ld35;
CONST
    TILE_WIDTH = 32;
    TILE_HEIGHT = 32;
    LEVEL_WIDTH = 10;
    LEVEL_HEIGHT = 10;

    TILE_KIND_NORMAL = 1;
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

    load_level();

    repeat
        frame;
    until(key(_ESC))

    unload_level();
END

Function load_level()
Private
    fg;
    bg;
    block;
Begin
    leveldata.fpg = 0;

    leveldata.loadedmap[0] = new_map(TILE_WIDTH, TILE_HEIGHT, 0, 0, 100);
    leveldata.loadedmap[1] = write_in_map(0, "FG", 0); //new_map(TILE_WIDTH, TILE_HEIGHT, 0, 0, 120);
    leveldata.loadedmap[2] = new_map(TILE_WIDTH, TILE_HEIGHT, 0, 0, 140);
    leveldata.loadedmaps = 3;

    for(x=0; x<LEVEL_WIDTH; x++)
        for(y=0; y<LEVEL_HEIGHT; y++)
            leveldata.tiles[x+LEVEL_WIDTH*y].pid = tile(x, y, TILE_KIND_NORMAL);
        end
    end

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
    ctype = C_SCROLL;
    x = TILE_WIDTH*tx;
    y = TILE_HEIGHT*ty;

    graph = write_in_map(0,"tile", 0);

    Loop
        frame;
    End
End

Process lift(minx, miny, maxx, maxy, startx, starty)
Begin
End