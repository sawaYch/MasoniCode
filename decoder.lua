#! /usr/bin/env lua
-- lgi modules
local lgi = require ('lgi')
local ffi = require('ffi')
local Gtk = lgi.Gtk
local Gdk = lgi.Gdk
local Pango = lgi.Pango

ffi.cdef[[
typedef unsigned char	FcChar8;
typedef int FcBool;
typedef struct _FcConfig    FcConfig;
FcBool FcConfigAppFontAddFile (FcConfig    *config, const FcChar8  *file);          
FcConfig * FcConfigGetCurrent (void);
]]

Decoder = {}

codeBuffer = Gtk.TextBuffer()

Decoder.Widget =
Gtk.VBox{ id = 'outer_vbox',
	spacing = 10,
	Gtk.ScrolledWindow { id = 'result_scroll',
		height_request = 150,
		Gtk.TextView{ id = 'result',
			buffer = codeBuffer,
			border_width = 10,
			left_margin= 10,
			right_margin= 10,
			top_margin= 10,
			bottom_margin = 10,
			cursor_visible = false,
			editable = false,
		},
	},
	Gtk.Grid{ id = 'grid',
		Gtk.ScrolledWindow {
			Gtk.TextView{ id = 'input',
				buffer = codeBuffer,
				left_margin= 10,
				right_margin= 10,
				top_margin= 10,
				bottom_margin = 10,
				expand = true,
			},
		},
		Gtk.VBox{
			margin_left = 10,
			margin_right = 5,
			margin_top = 5,
			margin_bottom = 5,
			spacing = 10,
			homogeneous = false,			
			Gtk.HBox{
			spacing = 10,
			margin_left = 10,
				Gtk.Label{
						label = "Overlap\nMapping",
					},
				Gtk.Switch{
					id = 'overlap_sw',
					halign = 3,
					valign = 3,
				},
			},
			Gtk.Button{ id = 'clear_bt',
				label = "Clear",
			},
		},		
	},
}


-- more details layout setting
Decoder.Widget.child.result:override_background_color(0, Gdk.RGBA { red = 0.87, green = 0.2, blue = 0.5, alpha = 0.2 })

-- standard code mode
famStdFontPath = "./font/FAM-Code-standard.ttf"
famFontPath =  "./font/FAM-Code-standard.ttf"
status = ffi.C.FcConfigAppFontAddFile(ffi.C.FcConfigGetCurrent(), famFontPath)
masoniCode_font_std = Pango.FontDescription.from_string("FAM-Code-Standard 9")
masoniCode_font_overlap = Pango.FontDescription.from_string("FAM-Code 9")

-- placeholder of input field
function Decoder:show_placeholder()
	if not Decoder.Widget.child.input.is_focus and Decoder.Widget.child.input.buffer.text == "" then
		-- cut the buffer
		Decoder.Widget.child.result.buffer = Gtk.TextBuffer()
		-- reset the font
		Decoder.Widget.child.input:override_font()
		local tag = Gtk.TextTag{ foreground = 'grey' }	
		Decoder.Widget.child.input.buffer.text = "Enter the stuffs you want to decode here."
		Decoder.Widget.child.input.buffer.tag_table:add(tag)
		Decoder.Widget.child.input.buffer:apply_tag(tag, Decoder.Widget.child.input.buffer:get_bounds())		
	end
end 
 

v_keyboard =
Gtk.VBox{ id = 'v_keyboard',
	height_request = 120,
	Gtk.HBox{	id = 'row_1',
		spacing = 1, margin_left = 1, margin_right = 1, margin_top = 1, margin_bottom = 1,
		Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},
	},
	Gtk.HBox{ id = 'row_2',
		halign = 3, width_request = 530,
		spacing = 1, margin_left = 1, margin_right = 1, margin_top = 1, margin_bottom = 1,
		Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},
	},
	Gtk.HBox{  id = 'row_3',
		halign = 3, width_request = 470,
		spacing = 1, margin_left = 1, margin_right = 1, margin_top = 1, margin_bottom = 1,
		Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},
	},
	Gtk.HBox{  id = 'row_4',
		halign = 3, width_request = 410,
		spacing = 1, margin_left = 1, margin_right = 1, margin_top = 1, margin_bottom = 2,
		Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},Gtk.Button{},
	}
}
	
-- v_keyborad color
v_keyboard:override_background_color(0, Gdk.RGBA { red = 0.87, green = 0.2, blue = 0.5, alpha = 0.2 })

-- Revealer container of virtual keyboard
v_keyboard_revealer =  Gtk.Revealer{id = "v_keyboard_container"}
v_keyboard_revealer:set_reveal_child(true)
v_keyboard_revealer:set_transition_duration(350)
v_keyboard_revealer:set_transition_type(5)
v_keyboard_revealer:add(v_keyboard)
Decoder.Widget.child.outer_vbox:pack_start(v_keyboard_revealer, false, true, 0)
v_keyboard_revealer:set_reveal_child(false)

-- v_keyboard 's keyboard layout
keylist = " 1234567890qwertyuiopasdfghjklzxcvbnm"
v_keyboard_uppercase = false

-- init generate v_keyboard label
local sum = 0
for j = 1, 4 do
	for i = 1, 12-j do 
		local ref = Decoder.Widget.child.v_keyboard.child["row_".. tostring(j)].child[i]
		ref:override_font(masoniCode_font_std)
		local index =  sum + i
		ref.label = keylist:sub(index, index)
		-- Declare v_keyboard button onclick event
		function  ref:on_clicked()
			if ref.label == "¿" or ref.label == "Å" then return end
--			Decoder.Widget.child.input:grab_focus()
			Decoder.Widget.child.input.buffer:insert_at_cursor(ref.label, 1)
		end
	end
	sum = sum + (12-j)
end


-- switch to uppercase / lowercase 
function toggle_vk_case()
	for j = 1, 4 do
		for i = 1, 12-j do 
			if (i ~= 1 and j ~= 1 ) and (i ~=8 and j ~=4) then
				local ref = Decoder.Widget.child.v_keyboard.child["row_".. tostring(j)].child[i]
--				ref:override_font(masoniCode_font_std)
				local index =  (j-1) * (12-j+2) + i 
				if not v_keyboard_uppercase then 
					ref.label = string.upper(keylist:sub(index, index)) 
				else 
					ref.label = string.lower(keylist:sub(index, index)) 
				end
			end
		end
	end
	v_keyboard_uppercase = not v_keyboard_uppercase
end


-- special key style
-- key to toggle up/low case
local tmp_case_vk = Decoder.Widget.child.v_keyboard.child["row_1"].child[1]
tmp_case_vk.label = "¿"
tmp_case_vk:override_color(0, Gdk.RGBA { red = 0.87, green = 0.2, blue = 0.5, alpha = 1 })
function tmp_case_vk:on_clicked()
	toggle_vk_case()
end

-- implement overlap mapping virtual keyboard layout
function Decoder.Widget.child.overlap_sw:on_state_set(state)
	for j = 1, 4 do
		for i = 1, 12-j do 
			if (i ~= 1 and j ~= 1 ) and (i ~=8 and j ~=4) then
				local ref = Decoder.Widget.child.v_keyboard.child["row_".. tostring(j)].child[i]
				if state then ref:override_font(masoniCode_font_overlap)
					else ref:override_font(masoniCode_font_std) end
			end
		end
	end
end

-- key to hide virtualboard
local tmp_hide_vk = Decoder.Widget.child.v_keyboard.child["row_4"].child[8]
tmp_hide_vk.label = "Å"
tmp_hide_vk:override_background_color(0, Gdk.RGBA { red = 0.5, green = 0.5, blue = 0.5, alpha = 0.8 })
function tmp_hide_vk:on_clicked()
		v_keyboard_revealer:set_reveal_child(not v_keyboard_revealer:get_child_revealed())
end



-- wrap mode : wrap word
Decoder.Widget.child.result:set_wrap_mode(2)
Decoder.Widget.child.input:set_wrap_mode(2)
Decoder.Widget.child.input:set_input_hints(4) 
 
 -- init placeholder
Decoder:show_placeholder() 
		
-- Focus in event - show v_keyboard and remove place holder
function Decoder.Widget.child.input:on_focus_in_event()
	if Decoder.Widget.child.result.buffer ~= Decoder.Widget.child.input.buffer then
		-- override font when in
		Decoder.Widget.child.input:override_font(masoniCode_font_std)
		--reconnect the buffer
		Decoder.Widget.child.result.buffer = Decoder.Widget.child.input.buffer
		Decoder.Widget.child.input.buffer.text = ''
	end
	--Anyway, show v_keyborad
	v_keyboard_revealer:set_reveal_child(true)
end 

-- Focus out - show place holder again
function Decoder.Widget.child.input:on_focus_out_event()
	if Decoder.Widget.child.input.buffer.text == ""  and 	Decoder.Widget:get_focus_child() ~= Decoder.Widget.child.v_keyboard_container then
		Decoder:show_placeholder()
	end
end

function Decoder.Widget.child.result:on_focus_in_event()
	--Anyway, hide v_keyborad
	v_keyboard_revealer:set_reveal_child(false)
end 
 
-- shortcut virtual keyboard 
function Decoder.Widget:on_key_press_event(event)
	local action = event.keyval
	local ctrl_down = event.state.CONTROL_MASK
	
	-- better ux for input between v_keyboard and keyboard		
	if Decoder.Widget:get_focus_child() ==  Decoder.Widget.child.v_keyboard_container then
		Decoder.Widget.child.input:grab_focus()
		if action == 32 then Decoder.Widget.child.input.buffer:insert_at_cursor(" ", 1) end
	end
	-- Press ctrl + k to show/hide virtual keyboard
	
	if action == 107 and ctrl_down then
		v_keyboard_revealer:set_reveal_child(not v_keyboard_revealer:get_child_revealed())
	end
end 
 
 
function Decoder.Widget.child.clear_bt:on_clicked()
	if Decoder.Widget.child.input.buffer.text == "Enter the stuffs you want to decode here." then return end
	Decoder.Widget.child.input.buffer.text = ''
	Decoder:show_placeholder()
end 
 
function Decoder:dark_v_keyboard(bool)
	if bool then
		v_keyboard:override_background_color(0, Gdk.RGBA { red = 0.87, green = 0.2, blue = 0.5, alpha = 1 })
	else
		v_keyboard:override_background_color(0, Gdk.RGBA { red = 0.87, green = 0.2, blue = 0.5, alpha = 0.3 })
	end
end
 
function Decoder:getWidget()
	return Decoder.Widget
end
 
return Decoder
