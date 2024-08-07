
local function seed_random()
    -- seed random
    math.randomseed(os.time())
    -- some platforms have a recurring first random
    math.random()
    math.random()
    math.random()
end

seed_random()
