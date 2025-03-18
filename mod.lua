-- example function mod 

return {

  -- for what we want to do we don't need to load anything first
  -- so we just return true so that the game knows we're ready
  load = function(mod_id)
    return true
  end,

  -- for our autoplanter function we need to listen for the mouse press
  -- mtype is the type of mouse action, either 'pressed' or 'released'
  -- btn is 1 for left-click, 2 for right-click, 3 for middle-click
  -- phase is when the script is called, 'before' for before all the game's default click code, 'after' for after it's all done
  mouse = function(mtype, btn, phase)

    -- first check the player is using an axe
    -- the player has a special method for doing this cos I use it all the time 'game/class/player:492'
    local equipped = game.g.player:call('equipped') -- returns the equipped 'slot' either a hotbar slot or the 'mouse' slot
    if mtype == 'pressed' and equipped.props.item:find('axe') then
      print('mouse click with axe!')
      -- after the game has run it's logic, if a tree has been cut down it will be destroyed
      -- the highlight is still active at this point as the next frame hasn't run
      -- so we can check if we're highlighting a destroyed tree and do something!
      if phase == 'after' then
        -- all objects in the game have an 'oid' to indentify them
        -- see 'tngine/classes/tn_object' and 'game/class/cl_obj' for more
        if game.g.highlighted_obj and game.g.highlighted_obj.oid:find('tree') and game.g.highlighted_obj.destroyed then
          print('tree has been destroyed!')
          -- get the tree's current position, we'll use it later
          local tx = game.g.highlighted_obj.x
          local ty = game.g.highlighted_obj.y
          -- the game uses 2 main layers '0' for stuff on the water layer
          -- and '1' for stuff on the island layers
          -- in this example we're just gunna use the same layer the tree was on
          local tlayer = game.g.highlighted_obj.layer
          -- now we need to check we have some acorns to autoplant!
          -- this will depend on the type of tree we cut down, grass or water
          -- we can tell the type of tree using the 'game/resources/re_dictionary' definitions
          -- trees that use tooltip_oid == 'tree1' are grass trees
          -- trees that use tooltip_oid == 'tree2' are water trees
          local tree_def = game.g.dictionary[game.g.highlighted_obj.oid]
          -- lua doesn't have proper ternary operators! isn't that fun
          local acorn_type = tn.util.ternary(tree_def.tooltip_oid == 'tree1', 'acorn1', 'acorn2')
          -- now lets go through the player's inventory and see if they have those acorns
          local acorn_slot = nil
          -- all menus with slots have them stored as a 'slots' property
          -- see 'game/class/cl_slot' for more
          for s=1,#game.g.player.menu.slots do
            local slot = game.g.player.menu.slots[s]
            if slot.props.item == acorn_type then
              acorn_slot = slot
              -- exit early when we find the first matching slot
              break
            end
          end
          -- if we have an acorn slot then we can 'use it' to plant an acorn
          if acorn_slot then
            print('using an acorn')
            -- slots have a bunch of functions you can call, here we use 'decr' which will reduce 1 from the slot
            -- and then clear the slot if there's no more left
            acorn_slot:call('decr', 1)
            -- we can then create our new acorn, which is a generic 'game/class/cl_obj'
            -- you can see how the game makes placeable objects in 'game/events/ev_mouse:660'
            -- we need to check the region we're in to make the 'correct' sapling
            local region = game.g.player.props.region -- number, 1-7
            -- both acorn definitions have an entry for each of the 7 regions
            local sapling = game.g.dictionary[acorn_type].placeable[region]
            print('check placement', acorn_type, region, sapling)
            local new_sapling = game.class.obj:new(tx, ty, game.g.dictionary[sapling], tlayer)
            -- we also need to set some object properties to make it act properly
            -- first we need to set the 'world' the tree is in
            -- we do this based on the world we're currently in
            new_sapling.props.dream_only = game.g.world == 'dream'
            new_sapling.props.awake_only = game.g.world == 'awake'
            -- then we set a couple properties to save waiting for the camera to update
            -- whether the object is visible or not (as by default new objects are not)
            new_sapling.in_bounds = true
            new_sapling.visible = true
            new_sapling.active = true
            -- and that's it!
          end
        end
      end

      -- some ideas on how to expand this mod:
      
      -- what about auto-planting polyps when you harvest jellies?

      -- the code in 'game/events/ev_mouse:726' handles the 'plant lots of acorns' achievement
      -- you could make your auto-acorn count towards the achievement!

      -- if you wanted to be fancy, you could look for slots containing a backpack
      -- then check those slots for acorns too so the player can have them in their backpack instead!

    end
  
  end

  -- we dont actually need to handle the gamepad button presses
  -- as by default when the player uses A on a gamepad to interact 
  -- the game just reruns the 'ev_mouse' code
 
}
