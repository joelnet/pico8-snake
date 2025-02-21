pico-8 cartridge // http://www.pico-8.com
version 42
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
local grid_size = 14    -- 14x14 grid to fit on screen
local border_left = 8   -- centered horizontally (8px on each side)
local border_top = 9    -- border starts at y=9 (1px gap after score)

-- Initialize game state and sound effects
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
    
    -- Initialize sound effects for movement, food collection, and game over
    -- movement sound (sfx 0)
    memset(0x3200,0,68)  -- clear entire sound slot
    poke(0x3200,8)       -- frequency
    poke(0x3201,2)       -- waveform (square)

    -- food sound (sfx 1)
    memset(0x3248,0,68)  -- clear entire sound slot
    poke(0x3248,32)      -- frequency
    poke(0x3249,2)       -- waveform (square)
    poke(0x324a,0)       -- stop after first note
    
    -- game over buzz (sfx 2)
    memset(0x3290,0,68)  -- clear entire sound slot
    poke(0x3290,16)      -- frequency
    poke(0x3291,3)       -- waveform (triangle)
    poke(0x3292,8)       -- volume
    poke(0x3293,3)       -- effect (slide)
    poke(0x3294,12)      -- note 2 frequency
    poke(0x3295,3)       -- note 2 waveform
    poke(0x3296,8)       -- note 2 volume
    poke(0x3297,3)       -- note 2 effect
    poke(0x3298,8)       -- note 3 frequency
    poke(0x3299,3)       -- note 3 waveform
    poke(0x329a,8)       -- note 3 volume
    poke(0x329b,3)       -- note 3 effect
end

-- Handle user input and update game state
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

-- Draw game state
function _draw()
    cls()
    
    -- draw score above play field in top-left corner
    print("score:"..score,border_left,2,7)
    
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

-- Place new food at a random position on the grid
function place_new_food()
    while true do
        local new_food = {
            x = flr(rnd(grid_size)),
            y = flr(rnd(grid_size))
        }
        
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

-- Handle game over state
function handle_game_over()
    game_over = true
    sfx(2)
end

-- Move the snake and update game state
function move_snake()
    local new_head = {
        x = snake[1].x + direction.x,
        y = snake[1].y + direction.y
    }
    
    -- Check for collision with boundaries
    if new_head.x < 0 or 
       new_head.x >= grid_size or
       new_head.y < 0 or 
       new_head.y >= grid_size then
        handle_game_over()
        return
    end
    
    -- Check for collision with self
    for i,segment in pairs(snake) do
        if new_head.x == segment.x and
           new_head.y == segment.y then
            handle_game_over()
            return
        end
    end
    
    -- Create new snake array with new head
    local new_snake = {new_head}
    for i=1,#snake do
        add(new_snake, snake[i])
    end
    
    -- Check for food collision
    if new_head.x == food.x and
       new_head.y == food.y then
        sfx(1)
        score += 10
        place_new_food()
    else
        -- Remove tail if no food eaten
        del(new_snake, new_snake[#new_snake])
    end
    
    -- Update snake
    snake = new_snake
    sfx(0)
end
