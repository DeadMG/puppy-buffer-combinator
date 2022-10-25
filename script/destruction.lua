local event = require("__flib__.event")

function cleanup(unit_number)
    if not unit_number then return end
    if not global.entity_state then return end
    if not global.entity_state[unit_number] then return end
    global.entity_state[unit_number] = nil
end

event.register(defines.events.on_entity_destroyed, function(event)
    cleanup(event.unit_number)
end)