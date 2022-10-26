local combinator = {}

function combinator.applyStateToEntity(entity)
    if not global.entity_state then return end
    local entityState = global.entity_state[entity.unit_number]
    if not entityState then return end
    
    local behaviour = entity.get_or_create_control_behavior()
    
    if entityState.item_type then
        if entityState.item_type.type == "item" then 
            local prototype = game.item_prototypes[entityState.item_type.name]
            if prototype and entityState.stack_count ~= 0 then 
                behaviour.set_signal(1, { signal = entityState.item_type, count = entityState.stack_count * prototype.stack_size })
            else
                behaviour.set_signal(1, nil)
            end
        end
        if entityState.item_type.type == "fluid" then
            if entityState.tank_count ~= 0 then
                behaviour.set_signal(1, { signal = entityState.item_type, count = entityState.tank_count })
            else
                behaviour.set_signal(1, nil)
            end
        end
    else
        behaviour.set_signal(1, nil)
    end    
end

function combinator.setEnabled(entity, enabled)
    entity.get_or_create_control_behavior().enabled = enabled
end

function combinator.isEnabled(entity) 
     return entity.get_or_create_control_behavior().enabled
end

function combinator.applyEntityState(entity, data)
    global.entity_state = global.entity_state or {}
    
    local entityTable = global.entity_state[entity.unit_number] or { entity = entity }
    entityTable.item_type = data.item_type
    entityTable.stack_count = data.stack_count or 0
    entityTable.tank_count = data.tank_count or 0
    global.entity_state[entity.unit_number] = entityTable
    
    combinator.applyStateToEntity(entity)
    
    script.register_on_entity_destroyed(entity)
end

return combinator