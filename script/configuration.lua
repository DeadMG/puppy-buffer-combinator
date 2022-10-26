local combinator = require("script.combinator")

function onConfigurationChanged()
    -- Our signals might be out of sync; re-sync them to the combinator
    if not global.entity_state then return end
    for unit_number, state in pairs(global.entity_state) do
        if state.entity and state.entity.valid then
            combinator.applyStateToEntity(state.entity)
        end
    end 
end

script.on_configuration_changed(onConfigurationChanged)
