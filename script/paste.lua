local event = require("__flib__.event")
local combinator = require("script.combinator")

function onEntityCopied(source, destination)
    if not global.entity_state then return end
    if not source or not source.valid then return end
    if not destination or not destination.valid then return end
    if source.type ~= "buffer-combinator" or destination.type ~= "buffer-combinator" then return end
    if not global.entity_state[source.unit_number] then return end
    
    combinator.applyEntityState(destination, {
        item_type = global.entity_state[source.unit_number].item_type,
        stack_count = global.entity_state[source.unit_number].stack_count,
        tank_count = global.entity_state[source.unit_number].tank_count
    })
end

function mapPositionX(pos)
    return pos[1] or pos.x
end

function mapPositionY(pos)
    return pos[2] or pos.y
end

function getEntityBoundingBox(blueprintEntity)
    local position = blueprintEntity.position
    local prototype = game.entity_prototypes[blueprintEntity.name]
    return {
        minX = mapPositionX(position) - prototype.tile_width,
        maxX = mapPositionX(position) + prototype.tile_width,
        minY = mapPositionY(position) - prototype.tile_height,
        maxY = mapPositionY(position) + prototype.tile_height
    }
end

function getBoundingBox(blueprintEntities)
    local total = getEntityBoundingBox(blueprintEntities[1])
    for _, blueprintEntity in ipairs(blueprintEntities) do
        local next = getEntityBoundingBox(blueprintEntity)
        total.minX = math.min(next.minX, total.minX)
        total.maxX = math.max(next.maxX, total.maxX)
        total.minY = math.min(next.minY, total.minY)
        total.maxY = math.max(next.maxY, total.maxY)
    end
    return total
end

function centreEntities(boundingBox, entities)
    -- We need to adjust the range here so instead of going from boundingBox.maxX/minX, we go from -x to +x
    -- This is subtracting minX, which gets us to zero, then subtract half the width, which moves the center exactly to zero.
    local result = {}
    local halfWidth = (boundingBox.maxX - boundingBox.minX) / 2
    local halfHeight = (boundingBox.maxY - boundingBox.minY) / 2
    for index, entity in ipairs(entities) do
        table.insert(result, {
            x = (mapPositionX(entity.position) - boundingBox.minX) - halfWidth,
            y = (mapPositionY(entity.position) - boundingBox.minY) - halfHeight,
            entity = entity
        })
    end
    return result
end

function mapToCursorSpace(cursorPosition, mappedEntities)
    -- Now that the entities are centered to 0,0, we can simply add the cursor position and be done
    local result = {}
    for _, mappedEntity in ipairs(mappedEntities) do
        table.insert(result, {
            x = mappedEntity.x + mapPositionX(cursorPosition),
            y = mappedEntity.y + mapPositionY(cursorPosition),
            entity = mappedEntity.entity
        })
    end
    return result
end

function flipBlueprint(horizontal, vertical, mappedEntities)    local result = {}
    local result = {}
    for _, mappedEntity in ipairs(mappedEntities) do
        local x = mappedEntity.x
        if horizontal then x = -x end
        local y = mappedEntity.y
        if vertical then y = -y end
        
        table.insert(result, {
            x = x,
            y = y,
            entity = mappedEntity.entity
        })
    end
    return result    
end

function round(num)
  return math.floor(num + 0.5)
end

function roundToTile(position, whole)
    if whole then return round(position) end
    return round(position + 0.5) - 0.5
end

function snapToTileBoundaries(mappedEntities)    
    local result = {}
    for _, mappedEntity in ipairs(mappedEntities) do
        local prototype = game.entity_prototypes[mappedEntity.entity.name]
        -- Even entities should have a position on a tile boundary; odd ones should have it in the center of the tile.
        local snapToWholeX = (prototype.tile_width % 2) == 0
        local snapToWholeY = (prototype.tile_height % 2) == 0
        
        table.insert(result, {
            x = roundToTile(mappedEntity.x),
            y = roundToTile(mappedEntity.y),
            entity = mappedEntity.entity
        })
    end
    return result
end

function directionToAngle(direction)
    if not direction then return 0 end
    if direction == defines.direction.north then return 0 end
    if direction == defines.direction.northeast then return 45 end
    if direction == defines.direction.east then return 90 end
    if direction == defines.direction.southeast then return 135 end
    if direction == defines.direction.south then return 180 end
    if direction == defines.direction.southwest then return 225 end
    if direction == defines.direction.west then return 270 end
    if direction == defines.direction.northwest then return 315 end
    error("unknown direction")
end

function rotate(direction, mappedEntities)
    local result = {}    
    local angle = math.rad(directionToAngle(direction))
    
    for _, mappedEntity in ipairs(mappedEntities) do      
        table.insert(result, {
            x = (mappedEntity.x * math.cos(angle)) - (mappedEntity.y * math.sin(angle)),
            y = (mappedEntity.x * math.sin(angle)) + (mappedEntity.y * math.cos(angle)),
            entity = mappedEntity.entity
        })
    end
    return result
end

function onPrebuild(player_index, position, flippedHorizontally, flippedVerically, direction) 
    local player = game.get_player(player_index)
    local blueprint = player.cursor_stack
    if not blueprint or not blueprint.valid_for_read or not blueprint.is_blueprint then return end
        
    -- The player's cursor always occurs in a 1-tile sized box at the center of the blueprint. This box
    -- does not have to align with the world tile grid, e.g. if the box has an even number of tiles width
    -- or height.
    local entities = blueprint.get_blueprint_entities()
    
    if entities == nil or #entities == 0 then return end
    
    -- First we need to get a bounding box for the blueprint
    local boundingBox = getBoundingBox(entities)
    
    -- Then we need to adjust them so that the exact center is at 0,0 - this will give us their position relative to the cursor
    local centred = centreEntities(boundingBox, entities)
    
    -- The player may have flipped the blueprint; need to adjust our idea of it now it's centered
    local flipped = flipBlueprint(flippedHorizontally, flippedVerically, centred)
    
    -- The player may have rotated the blueprint. Note that normally flipping and rotation are not commutative
    -- but since we are restricted to both through 0,0, they are.
    local rotated = rotate(direction, flipped)
    
    -- Now we offset them relative to the cursor
    local inWorldSpace = mapToCursorSpace(position, rotated)
   
    -- We may not be aligned with any tile boundary depending on the exact size of blueprint and location of player cursor.
    -- Snap it.
    local snapped = snapToTileBoundaries(inWorldSpace)
        
    for _, mappedEntity in pairs(snapped) do
        if mappedEntity.entity.name == 'buffer-combinator' then   
            local position = { x = mappedEntity.x, y = mappedEntity.y }

            local entity = player.surface.find_entity('buffer-combinator', position)
            if entity and entity.valid then
                combinator.applyEntityState(entity, {
                    item_type = blueprint.get_blueprint_entity_tag(mappedEntity.entity.entity_number, 'buffer-combinator-item-type'),
                    stack_count = blueprint.get_blueprint_entity_tag(mappedEntity.entity.entity_number, 'buffer-combinator-stack-count'),
                    tank_count = blueprint.get_blueprint_entity_tag(mappedEntity.entity.entity_number, 'buffer-combinator-tank-count')
                })
            end
        end
    end
end

event.register(defines.events.on_entity_settings_pasted, function(event)
    onEntityCopied(event.source, event.destination)
end)

event.register(defines.events.on_entity_cloned, function(event)
    onEntityCopied(event.source, event.destination)
end)

event.register(defines.events.on_pre_build, function(event)
    onPrebuild(event.player_index, event.position, event.flip_horizontal, event.flip_vertical, event.direction)
end)
