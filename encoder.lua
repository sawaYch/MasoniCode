#! /usr/bin/env lua
-- lgi modules
local lgi = require ('lgi')
local ffi = require("ffi")
local Gtk = lgi.Gtk
local Gdk = lgi.Gdk
local Pango = lgi.Pango
local GObject = lgi.GObject
local GdkPixbuf = lgi.GdkPixbuf
local Gio = lgi.Gio
-- dir used to get resources
local dir = Gio.File.new_for_commandline_arg(arg[0]):get_parent()

-- Meta Class
Encoder = {}

codeBuffer = Gtk.TextBuffer()
num_mode = false
case_mode = false

Encoder.Widget =
Gtk.VBox{
	margin_top = 5,
	margin_bottom = 5,
	spacing = 10,
	homogeneous = true,
	Gtk.ScrolledWindow {
		id = 'result_scroll',
		Gtk.TextView{
			id = 'result',
			buffer = codeBuffer,
			border_width = 10,
			left_margin= 10,
			right_margin= 10,
			top_margin= 10,
			bottom_margin = 10,
			cursor_visible = false,
			expand = false,
			editable = false,
			hexpand = true,
			vexpand = true,
		},
	},
	Gtk.Grid{
		Gtk.ScrolledWindow {
			Gtk.TextView{
				id = 'input',
				buffer = codeBuffer,
				left_margin= 10,
				right_margin= 10,
				top_margin= 10,
				bottom_margin = 10,
				expand = false,
				hexpand = true,
				vexpand = true,
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
					label = "Case\nSensitive",
				},
				Gtk.Switch{
					id = 'case_sw',
					halign = 3,
					valign = 3,
				},
			},
			Gtk.HBox{ id = 'num_sw_box',
			spacing = 10,
			margin_left = 10,
				Gtk.Label{ id = 'num_sw_lb',
						label = "Numbers",
					},
				Gtk.Switch{ id = 'num_sw',
					halign = 3,
					valign = 3,
				},
			},
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
			Gtk.Button{
				id = 'clear_bt',
				label = "Clear",
			},
		},
	}
}

-- placeholder of input field
function Encoder:show_placeholder()
	if not Encoder.Widget.child.input.is_focus and Encoder.Widget.child.input.buffer.text == '' then
		-- cut the buffer
		Encoder.Widget.child.result.buffer = Gtk.TextBuffer()
		local tag = Gtk.TextTag{ foreground = 'grey' }	
		Encoder.Widget.child.input.buffer.text = "Enter the stuffs you want to encode here."
		Encoder.Widget.child.input.buffer.tag_table:add(tag)
		Encoder.Widget.child.input.buffer:apply_tag(tag, Encoder.Widget.child.input.buffer:get_bounds())
	end
end

	
-- change bg color of result
Encoder.Widget.child.result:override_background_color(0, Gdk.RGBA { red = 0.2, green = 0.87, blue = 0.5, alpha = 0.2 })
masoniCode_font = Pango.FontDescription.from_string("FAM-Code-Standard 12")
Encoder.Widget.child.result:override_font(masoniCode_font)

-- wrap mode : wrap word
Encoder.Widget.child.result:set_wrap_mode(2)
Encoder.Widget.child.input:set_wrap_mode(2)
--Encoder.Widget.child.input:grab_focus()
Encoder.Widget.child.input:set_input_hints(4)

-- init state : show placeholder
Encoder:show_placeholder()

-- Popover message box for num_sw hint
Encoder.popover = Gtk.Popover()
Encoder.popover:set_relative_to(Encoder.Widget.child.num_sw)
messagebox = 
Gtk.VBox{
		Gtk.Label{
			label = "Number support is off",
			width_request = 125,
			height_request = 30,
		},		
}

Encoder.popover:add(messagebox)
Encoder.popover:set_transitions_enabled(true)
Encoder.popover:set_modal(false)


function Encoder.Widget.child.input:on_focus_in_event(event)
	if Encoder.Widget.child.result.buffer ~= Encoder.Widget.child.input.buffer then
		-- reconnect the buffer
		Encoder.Widget.child.result.buffer = Encoder.Widget.child.input.buffer
		Encoder.Widget.child.input.buffer.text = ''
	end
end

function Encoder.Widget.child.input:on_focus_out_event(event)
	if Encoder.Widget.child.input.buffer.text == '' then
		Encoder:show_placeholder()
	end
end


function Encoder.Widget.child.clear_bt:on_clicked()
	if Encoder.Widget.child.input.buffer.text == "Enter the stuffs you want to encode here." then return end
	Encoder.Widget.child.input.buffer.text = ''
	Encoder:show_placeholder()
end


function Encoder.Widget.child.case_sw:on_state_set(state)
	-- cursor save point
	local cursor_save_pt = Encoder.Widget.child.input.buffer.cursor_position
	if state then
		Encoder.case_mode = true
	-- prevent apply mode effect to place holder
	else if Encoder.Widget.child.input.buffer.text ~= "Enter the stuffs you want to encode here." then
		Encoder.case_mode = false
		Encoder.Widget.child.input.buffer.text = string.lower(Encoder.Widget.child.input.buffer.text)
		end
	end
	local iter = Encoder.Widget.child.input.buffer:get_iter_at_offset(cursor_save_pt)
	Encoder.Widget.child.input.buffer:place_cursor(iter)
end

function Encoder.Widget.child.num_sw:on_state_set(state)
	-- cursor save point
	local cursor_save_pt = Encoder.Widget.child.input.buffer.cursor_position
	if state then
		Encoder.num_mode = true
	else if Encoder.Widget.child.input.buffer.text ~= "Enter the stuffs you want to encode here." then
			Encoder.num_mode = false
			Encoder.Widget.child.input.buffer.text = Encoder.Widget.child.input.buffer.text:gsub("[0-9]*","")
		end
	end
	local iter = Encoder.Widget.child.input.buffer:get_iter_at_offset(cursor_save_pt)
	Encoder.Widget.child.input.buffer:place_cursor(iter)
end

function Encoder.Widget.child.overlap_sw:on_state_set(state)
	-- cursor save point
	local cursor_save_pt = Encoder.Widget.child.input.buffer.cursor_position
	if state then
		masoniCode_font_full = Pango.FontDescription.from_string("FAM-Code 12")
		Encoder.Widget.child.result:override_font(masoniCode_font_full)
	else
		masoniCode_font_std = Pango.FontDescription.from_string("FAM-Code-Standard 12")
		Encoder.Widget.child.result:override_font(masoniCode_font_std)
	end
	local iter = Encoder.Widget.child.input.buffer:get_iter_at_offset(cursor_save_pt)
	Encoder.Widget.child.input.buffer:place_cursor(iter)
end

function Encoder.Widget.child.num_sw:on_enter_notify_event(event)	
	if not Encoder.Widget.child.num_sw:get_active() then
		Encoder.popover:popup()
		Encoder.popover:show_all()
	end
end

function Encoder.Widget.child.num_sw:on_leave_notify_event(event)	
	if Encoder.popover:get_visible() then
		Encoder.popover:popdown()
	end
end

function Encoder.Widget.child.num_sw:on_button_press_event(bt_event)
	if Encoder.popover:get_visible() then
		Encoder.popover:popdown()
	end
end

function Encoder.Widget.child.input.buffer:on_end_user_action()
	-- cursor save point
	local cursor_save_pt = Encoder.Widget.child.input.buffer.cursor_position
-- performance hit ( ! ) mark*
	-- Get current input char	
--	local start_iter = Encoder.Widget.child.input.buffer:get_iter_at_offset(cursor_save_pt-1)
--	local end_iter = Encoder.Widget.child.input.buffer:get_iter_at_offset(cursor_save_pt)
--	local curr_char = Encoder.Widget.child.input.buffer:get_text(start_iter, end_iter)
--	if tonumber(curr_char) ~= nil then
--		Encoder.popover:popup()
--		Encoder.popover:show_all()
--	else if Encoder.popover:get_visible() then
--		Encoder.popover:popdown()
--		print("running")
--		end
--	end
	-- check whether it case-sensitive mode on or not
	if  not Encoder.case_mode then
		Encoder.Widget.child.input.buffer.text = string.lower(Encoder.Widget.child.input.buffer.text)
	end
	if not Encoder.num_mode then
		Encoder.Widget.child.input.buffer.text = Encoder.Widget.child.input.buffer.text:gsub("[0-9]*","")
	end
-- Bug discover(fixed) : Backspace delete character --> save cursor position and move back after stuffs finished
	local iter = Encoder.Widget.child.input.buffer:get_iter_at_offset(cursor_save_pt)
	Encoder.Widget.child.input.buffer:place_cursor(iter)
end

function Encoder.getWidget()
	return Encoder.Widget
end

return Encoder