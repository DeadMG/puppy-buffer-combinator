local gui = require("lib.gui")
local event = require("__flib__.event")
local combinator = require("script.combinator")

local windowName = "buffer-combinator-settings"

function createWindow(player_index, entity)
    global.entity_state = global.entity_state or {}
    global.dialog_state = global.dialog_state or {}
    
    local rootgui = game.get_player(player_index).gui.screen
    local dialog = gui.build(rootgui, {
        {type="frame", direction="vertical", save_as="main_window", name=windowName, tags={unit_number=entity.unit_number}, children={
            -- Title Bar
            {type="flow", save_as="titlebar.flow", children={
                {type="label", style="frame_title", caption={"buffer-combinator.window-title"}, elem_mods={ignored_by_interaction=true}},
                {template="drag_handle"},
                {template="close_button", name=windowName, handlers="buffer_combinator_handlers.close_button"}}},      
            -- Main body                
            {type="frame", style="inside_shallow_frame_with_padding", style_mods={padding=8}, children={
                {type="flow", direction="vertical", style_mods={horizontal_align="left"}, children={
                    -- On/off switch
                    {type="label", caption={"buffer-combinator.output"}},
                    {type="switch", style_mods={top_padding=2}, save_as="on_off", handlers="buffer_combinator_handlers.on_off_switch", left_label_caption={"buffer-combinator.off"}, right_label_caption={"buffer-combinator.on"}},
                    -- Stack count
                    {type="label", caption={"buffer-combinator.stacks"}, style_mods={top_padding=8}},
                    {type="textfield", save_as="stack_count", style="long_number_textfield",handlers="buffer_combinator_handlers.stack_count", elem_mods={ numeric=true, allow_negative=true} },
                    -- Fluid tank size
                    {type="label", caption={"buffer-combinator.tanks"}, style_mods={top_padding=8}},
                    {type="textfield", save_as="tank_count", style="long_number_textfield",handlers="buffer_combinator_handlers.tank_count", elem_mods={ numeric=true, allow_negative=true} },
                    -- Item
                    {type="label", caption={"buffer-combinator.buffer"}, style_mods={top_padding=8}},
                    {type="choose-elem-button", save_as="item_type", style = "flib_slot_button_default", elem_type="signal", handlers="buffer_combinator_handlers.item_type" },
                    
                    {type="flow", style_mods={horizontal_align="right"}, children={              
                         {type="empty-widget", style_mods={horizontally_stretchable=true}},                    
                         {template="confirm_button", save_as="signal_value_confirm", handlers="buffer_combinator_handlers.confirm_button" }}}}}}}
            }}})
            
    dialog.titlebar.flow.drag_target = dialog.main_window
    dialog.main_window.force_auto_center()
    
    global.dialog_state[player_index] = { entity = entity, enabled = combinator.isEnabled(entity), tank_count = 0, stack_count = 0, item_type = nil }
    
    if global.dialog_state[player_index].enabled then
        dialog.on_off.switch_state = "right"
    else
        dialog.on_off.switch_state = "left"
    end
    
    local entityState = global.entity_state[entity.unit_number]
    local dialogState = global.dialog_state[player_index]
    
    if entityState then
        dialogState.item_type = entityState.item_type
        if entityState.item_type then
            dialog.item_type.elem_value = dialogState.item_type
        end
        
        dialogState.tank_count = entityState.tank_count
        if entityState.tank_count > 0 then        
            dialog.tank_count.text = tostring(entityState.tank_count)
        end
        
        dialogState.stack_count = entityState.stack_count
        if entityState.stack_count > 0 then
            dialog.stack_count.text = tostring(entityState.stack_count)       
        end        
    end
    
    return dialog
end

function openGui(player_index, entity)
    local player = game.get_player(player_index)
    local rootgui = player.gui.screen
    if rootgui[windowName] then
        if rootgui[windowName].tags.unit_number  == entity.unit_number then
          player.opened = rootgui[windowName]
          return
      end
      closeGui(player_index)
    end
    player.opened = createWindow(player_index, entity).main_window
    
end

function closeGui(player_index)
    local player = game.get_player(player_index)
    local rootgui = player.gui.screen
    if rootgui[windowName] then
        rootgui[windowName].destroy()	
    end
    if global.dialog_state ~= nil then
        global.dialog_state[player_index] = nil
    end
end

function registerHandlers()
    gui.add_handlers({
        buffer_combinator_handlers = {
            item_type = {
                on_gui_elem_changed = function(e)
                    global.dialog_state[e.player_index].item_type = e.element.elem_value
                end
            },
            stack_count = {
                on_gui_text_changed = function(e)                
                    local value = tonumber(e.element.text)
                    if not value then value = 0 end
                    global.dialog_state[e.player_index].stack_count = value
                end
            },
            tank_count = {
                on_gui_text_changed = function(e)                
                    local value = tonumber(e.element.text)
                    if not value then value = 0 end
                    global.dialog_state[e.player_index].tank_count = value
                end
            },
            confirm_button = {
                on_gui_click = function(e)
                    -- Apply whatever's in global.dialog_state to the combinator.
                    local dialog_state = global.dialog_state[e.player_index]
                    local entity = dialog_state.entity
                    if not entity or not entity.valid then return end
                    
                    combinator.applyEntityState(entity, {
                        item_type = dialog_state.item_type,
                        stack_count = dialog_state.stack_count,
                        tank_count = dialog_state.tank_count
                    })
                    
                    closeGui(e.player_index)
                end
            },
            close_button = {
                on_gui_click = function(e)
                    closeGui(e.player_index)
                end -- on_gui_click
            },
            on_off_switch = {
                on_gui_switch_state_changed = function(e)
                    global.dialog_state[e.player_index].enabled = e.element.switch_state == "right"
                end
            },
        }
    })
    gui.register_handlers()
end

function registerTemplates() 
  gui.add_templates{
    confirm_button = {template="frame_action_button", style="item_and_count_select_confirm", sprite="utility/check_mark"},
    frame_action_button = {type="sprite-button", style="frame_action_button", mouse_button_filter={"left"}},
    drag_handle = {type="empty-widget", style="flib_titlebar_drag_handle", elem_mods={ignored_by_interaction=true}},
    confirm_button = {template="frame_action_button", style="item_and_count_select_confirm", sprite="utility/check_mark"},
    cancel_button = {template="frame_action_button", style="red_button", style_mods={size=28, padding=0, top_margin=1}, sprite="utility/close_white"},
    close_button = {template="frame_action_button", sprite="utility/close_white", hovered_sprite="utility/close_black"},
  }
end

registerHandlers()
registerTemplates()

event.register(defines.events.on_gui_opened, function(e)
    if gui.dispatch_handlers(e) then return end
    if not (e.entity and e.entity.valid) then return end
    if e.entity.name == "buffer-combinator" then
        openGui(e.player_index, e.entity)
    else
        closeGui(e.player_index)
    end
end)

event.on_load(function()
  gui.build_lookup_tables()
end)

event.on_init(function()
  gui.init()
  gui.build_lookup_tables()
  global.dialog_state = {}
  global.entity_state = {}
end)

event.register({"buffer-combinator-close", "buffer-combinator-escape"}, function(e)
    closeGui(e.player_index)
end)