extends Control

export(StyleBox) var box_selection
export(StyleBox) var box_hover
export(Font) var font_label
export(Texture) var icon_collapsed
export(Texture) var icon_expanded

export var seperation = 2
export var row_height = 18

class Item:
    var depth = 0
    var collapsed = false
    var has_children = false
    var icon = null
    var label = ""
    var id = ""
    var buttons = {}
    var parent = null

    class ItemButton:
        var id = ""
        var icon = null
        var visible = true
        var modulate = Color("#ffffff")

    func is_visible():
        if parent:
            return parent.is_visible() and not parent.collapsed
        return true

    func add_button(id, icon):
        var but = ItemButton.new()
        buttons[id] = but
        but.id = id
        but.icon = icon
        return but

var items = []
var items_by_id = {}
var selection = []

func add_item(parent, id, label, icon = null):
    var item = Item.new()
    item.label  = label
    item.icon   = icon
    item.parent = parent
    
    if parent:
        item.depth = parent.depth + 1
        parent.has_children = true

    items.push_back(item)
    items_by_id[id] = item
    item.id = id
    minimum_size_changed()
    return item

func clear():
    items = []
    update()

func _draw():
    var y = 0
    for item in items:
        if not item.is_visible():
            continue

        var rect = Rect2(0, y, rect_size.x, row_height)
        var hover = rect.has_point(get_local_mouse_position())

        if selection.has(item) or selection.has(item.id):
            draw_style_box(box_selection, rect)
        elif hover:
            draw_style_box(box_hover, rect)

        var max_x = rect.end.x - seperation
        var max_y = rect.end.y

        for btn in item.buttons.values():
            if btn.visible and btn.icon:
                max_x -= btn.icon.get_width()
                draw_texture(btn.icon, Vector2(max_x, y), btn.modulate)

        var x = item.depth * 12 + seperation
        if item.has_children:
            if item.collapsed:
                draw_texture(icon_collapsed, Vector2(x, y))
                x += icon_collapsed.get_width() + seperation
            else:
                draw_texture(icon_expanded, Vector2(x, y))
                x += icon_expanded.get_width() + seperation
            
        if item.icon:
            draw_texture(item.icon, Vector2(x, y))
            x += item.icon.get_width() + seperation

        var remaining_width = max_x - x
        var shortened_label = Functions.shortn_visual(item.label, remaining_width, font_label)
        var center = ceil((y + max_y) / 2 + font_label.get_ascent() / 2)
        draw_string(font_label, Vector2(x, center), shortened_label)
        y += row_height

var last_row = null
var last_clicked_entry = null

func _gui_input(e):
    if e is InputEventMouseButton:
        if e.button_index in [BUTTON_WHEEL_DOWN, BUTTON_WHEEL_UP, BUTTON_WHEEL_LEFT, BUTTON_WHEEL_RIGHT]:
            return
        if e.is_pressed():
            var entry = null
            var button = null

            var y = 0
            for item in items:
                if item.is_visible():
                    if e.position.y > y and e.position.y < y + row_height:
                        entry = item
                        break
                    y += row_height
                
            var x = rect_size.x
            if entry:
                for btn in entry.buttons.values():
                    if btn.visible and btn.icon:
                        if e.position.x < x and e.position.x > x - btn.icon.get_width():
                            button = btn
                        x -= btn.icon.get_width()
            
            if entry:
                if entry.has_children:
                    entry.collapsed = not entry.collapsed
                    minimum_size_changed()
                    update()
                    
                if e.button_index == BUTTON_LEFT:
                    if button:
                        _button_left_click(entry, button)
                    else:
                        if e.doubleclick and entry == last_clicked_entry:
                            _entry_double_clicked(entry)
                        else:
                            _entry_left_click(entry)

                        last_clicked_entry = entry

                if e.button_index == BUTTON_RIGHT:
                    _entry_right_click(entry)

                accept_event()

func _input(e):
    if e is InputEventMouseMotion:
        var row = floor(e.position.y / row_height)
        if row != last_row:
            update()
                
func _entry_left_click(entry):
    selection = [entry]
    update()

func _entry_right_click(entry):
    pass

func _button_left_click(entry, button):
    pass

func _entry_double_clicked(entry):
    pass

func _get_minimum_size():
    var y = 0
    for item in items:
        if item.is_visible():
            y += row_height
    return Vector2(0, y)