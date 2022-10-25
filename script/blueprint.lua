local event = require("__flib__.event")
local combinator = require("script.combinator")

function getBlueprint(player)
    if player.blueprint_to_setup and player.blueprint_to_setup.valid_for_read then return player.blueprint_to_setup end
    if player.cursor_stack and player.cursor_stack.valid_for_read then return player.cursor_stack end
    return nil
end

function onPlayerSetupBlueprint(player_index)
    local player = game.get_player(player_index)
    local blueprint = getBlueprint(player)
    if not blueprint then return end
    for index, bpEntity in ipairs(blueprint.get_blueprint_entities() or {}) do
        local entity = player.surface.find_entity('buffer-combinator', bpEntity.position)
        if entity and entity.valid then
            local entityState = global.entity_state[entity.unit_number]
            if entityState then
                blueprint.set_blueprint_entity_tag(index, 'buffer-combinator-item-type', entityState.item_type)
                blueprint.set_blueprint_entity_tag(index, 'buffer-combinator-stack-count', entityState.stack_count)
                blueprint.set_blueprint_entity_tag(index, 'buffer-combinator-tank-count', entityState.tank_count) 
            end
        end
    end
end

function onEntityCreated(event)
  local built_entity = event.created_entity or event.entity
  if not built_entity or not built_entity.valid then return end
  local tags = event.tags
  if not tags then return end
  
  combinator.applyEntityState(built_entity, {
      item_type = tags['buffer-combinator-item-type'],
      stack_count = tags['buffer-combinator-stack-count'],
      tank_count = tags['buffer-combinator-tank-count']
  })
end

local ev = defines.events

event.register({ev.on_built_entity, ev.on_robot_built_entity, ev.script_raised_built, ev.script_raised_revive},
  onEntityCreated,
  {
    {filter="type", type="constant-combinator"},
    {filter="name", name="buffer-combinator", mode="and"}
  }
)

event.register(defines.events.on_player_setup_blueprint, function(event)
    onPlayerSetupBlueprint(event.player_index)
end)