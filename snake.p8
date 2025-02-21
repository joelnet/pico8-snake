pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- snake game
-- by cascade

-- game variables
local snake = {}
local food = {}
local direction = {x=1,y=0}
local next_direction = {x=1,y=0}
local score = 0
local game_over = false
local move_timer = 0
local move_delay = 15  -- adjust this to control snake speed
local sound_initialized = false
local grid_size = 14    -- 14x14 grid to fit on screen
local border_left = 4   -- border starts at x=4
local border_top = 9    -- border starts at y=9 (1px gap after score)

function init_food_sound()
    if not sound_initialized then
        -- food sound (sfx 1)
        memset(0x3248,0,68)  -- clear entire sound slot
        poke(0x3248,32)      -- frequency
        poke(0x3249,2)       -- waveform (square)
        poke(0x324a,0)       -- stop after first note
        sound_initialized = true
    end
end

function _init()
    -- initialize snake in middle of field
    snake = {{x=7,y=7},{x=6,y=7}}
    -- reset directions
    direction = {x=1,y=0}
    next_direction = {x=1,y=0}
    -- reset score
    score = 0
    -- reset game over
    game_over = false
    -- place initial food
    place_new_food()
    -- initialize sound
    init_food_sound()
    
    -- stop all sounds first
    music(-1)
    for i=0,1 do
        sfx(i,-1)
    end
    
    -- movement sound (sfx 0)
    memset(0x3200,0,68)  -- clear entire sound slot
    poke(0x3200,8)       -- frequency
    poke(0x3201,2)       -- waveform (square)
end

function _update60()
    if not game_over then
        -- handle input
        if btnp(⬅️) and direction.x != 1 then
            next_direction = {x=-1,y=0}
        elseif btnp(➡️) and direction.x != -1 then
            next_direction = {x=1,y=0}
        elseif btnp(⬆️) and direction.y != 1 then
            next_direction = {x=0,y=-1}
        elseif btnp(⬇️) and direction.y != -1 then
            next_direction = {x=0,y=1}
        end
        
        -- update movement timer
        move_timer += 1
        if move_timer >= move_delay then
            move_timer = 0
            direction = next_direction
            move_snake()
        end
    else
        if btnp(❎) then
            game_over = false
            score = 0
            _init()
        end
    end
end

function _draw()
    cls()
    
    -- draw score above play field in top-left corner
    print("score:"..score,5,2,7)
    
    -- draw border around play field
    -- 113x113 pixels to fully enclose the 14x14 grid
    rect(
        border_left - 1,       -- left edge with 1px border
        border_top - 1,        -- top edge with 1px gap after score
        border_left + 112,     -- right edge with 1px border (14 * 8 + 1)
        border_top + 112,      -- bottom edge with 1px border (14 * 8 + 1)
        7
    )
    
    -- draw snake
    for i,segment in pairs(snake) do
        rectfill(
            border_left + segment.x*8,     -- align to grid
            border_top + segment.y*8,      -- align to grid
            border_left + segment.x*8+7,   -- 8 pixels wide
            border_top + segment.y*8+7,    -- 8 pixels tall
            11
        )
    end
    
    -- draw food
    rectfill(
        border_left + food.x*8,     -- align to grid
        border_top + food.y*8,      -- align to grid
        border_left + food.x*8+7,   -- 8 pixels wide
        border_top + food.y*8+7,    -- 8 pixels tall
        8
    )
    
    if game_over then
        print("game over!",40,60,8)
        print("press ❎ to restart",24,70,7)
    end
end

function place_new_food()
    while true do
        -- random position within play field
        local new_food = {
            x = flr(rnd(grid_size)),
            y = flr(rnd(grid_size))  -- removed -1 to match visual border
        }
        
        -- check if position is valid
        local valid = true
        for i,segment in pairs(snake) do
            if new_food.x == segment.x and
               new_food.y == segment.y then
                valid = false
                break
            end
        end
        
        if valid then 
            food = new_food
            break 
        end
    end
end

function move_snake()
    -- get new head position
    local new_head = {
        x = snake[1].x + direction.x,
        y = snake[1].y + direction.y
    }
    
    -- check wall collision with play field boundaries
    if new_head.x < 0 or 
       new_head.x >= grid_size or
       new_head.y < 0 or 
       new_head.y >= grid_size then  -- removed -1 to match visual border
        game_over = true
        return
    end
    
    -- check self collision
    for i,segment in pairs(snake) do
        if new_head.x == segment.x and
           new_head.y == segment.y then
            game_over = true
            return
        end
    end
    
    -- create new snake array with new head
    local new_snake = {new_head}
    for i=1,#snake do
        add(new_snake, snake[i])
    end
    
    -- check food collision
    if new_head.x == food.x and
       new_head.y == food.y then
        -- play food sound
        sfx(1)
        -- increase score
        score += 1
        -- place new food
        place_new_food()
    else
        -- remove tail if no food eaten
        del(new_snake, new_snake[#new_snake])
    end
    
    -- update snake
    snake = new_snake
    -- play movement sound
    sfx(0)
end
