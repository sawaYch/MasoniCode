#! /usr/bin/env luajit
-- lgi modules
local lgi = require ('lgi')
local ffi = require("ffi")
local Gtk = lgi.Gtk
local Gdk = lgi.Gdk
local GdkPixbuf = lgi.GdkPixbuf
local Gio = lgi.Gio
-- masonicode modules
local Decoder = require("decoder")
local Encoder = require("encoder")
-- dir used to get resources
local dir = Gio.File.new_for_commandline_arg(arg[0]):get_parent()

--print(package.searchpath('lgi', package.path))
--print(package.searchpath('ffi', package.path))

ffi.cdef([[
int prctl(int option, unsigned long arg2, unsigned long arg3,
    unsigned long arg4, unsigned long arg5);
]])
-- change process name
local PR_SET_NAME = 15
ffi.C.prctl(PR_SET_NAME, ffi.cast("unsigned long", "masonicode"),0,0,0);

-- create windows instance
local window = Gtk.Window {
   title = 'MasoniCode',
   icon_name = 'MasoniCode',
   on_destroy = Gtk.main_quit
}
 

-- Implement main interface  with stack view
local main_Interface = Gtk.Stack()
main_Interface:set_transition_type(7)
main_Interface:set_transition_duration(500)
main_Interface:add_named(Decoder:getWidget(), "decode_cipher")
main_Interface:add_named(Encoder:getWidget(), "encode_cipher")

-- Intro mode button
local int_ico_path = dir:get_child('image/icons8-About-32.png'):get_path()
local int_ico, _ = GdkPixbuf.Pixbuf.new_from_file(int_ico_path)
Gtk.IconTheme.add_builtin_icon("intro", 32, int_ico)
local intro_bt = Gtk.ToolButton()
intro_bt.icon_name = "intro"
intro_bt.tooltip_text = "Home"
function intro_bt:on_clicked()
    main_Interface:set_visible_child_name("home")
end


-- Encode mode button
local en_ico_path = dir:get_child('image/icons8-Password-32.png'):get_path()
local en_ico, _ = GdkPixbuf.Pixbuf.new_from_file(en_ico_path)
Gtk.IconTheme.add_builtin_icon("encode_mode", 32, en_ico)
local encode_mode_bt = Gtk.ToolButton()
encode_mode_bt.icon_name = "encode_mode"
encode_mode_bt.tooltip_text = "Encode Mode"
encode_mode_bt:override_color(0,  Gdk.RGBA { red = 0, green = 1, blue = 0, alpha = 1 })
function encode_mode_bt:on_clicked()
    main_Interface:set_visible_child_name("encode_cipher")
end


-- Decode mode button
local de_ico_path = dir:get_child('image/icons8-Unlock-32.png'):get_path()
local de_ico, _ = GdkPixbuf.Pixbuf.new_from_file(de_ico_path)
Gtk.IconTheme.add_builtin_icon("decode_mode", 32, de_ico)
local decode_mode_bt = Gtk.ToolButton()
decode_mode_bt.icon_name = "decode_mode"
decode_mode_bt.tooltip_text = "Decode Mode"
decode_mode_bt:override_color(0,  Gdk.RGBA { red = 1, green = 0, blue = 0, alpha = 1 })

function decode_mode_bt:on_clicked()
    main_Interface:set_visible_child_name("decode_cipher")
end

-- Preferences button
local prefer_theme_bt = Gtk.ToolButton { stock_id = "gtk-preferences" }
local theme_key = 'Dark'
prefer_theme_bt.tooltip_text = "Switch to "..theme_key.." Theme"
function prefer_theme_bt:on_clicked()
	-- Set prefer theme to 'Dark' or 'Light'
	local settings = Gtk.Settings.get_default()
	settings.gtk_application_prefer_dark_theme = not settings.gtk_application_prefer_dark_theme
	-- also set virtual keyboard to dark theme (become lighter)
	Decoder:dark_v_keyboard(settings.gtk_application_prefer_dark_theme)
	theme_key = (theme_key == 'Dark') and "Light" or "Dark"
	prefer_theme_bt.tooltip_text = "Switch to "..theme_key.." Theme"
end


-- About button
local about_bt =  Gtk.ToolButton { stock_id = 'gtk-about' }
about_bt.tooltip_text = "About"
function about_bt:on_clicked()
   local dlg = Gtk.AboutDialog {
      program_name = 'MasoniCode',
      transient_for = window,
      modal = true,
      title = 'About',
      name = 'MasoniCode',
      copyright = '(C) Copyright 2017 Sato Sawa',
      authors = { 'Sato Sawa'},
   }
   dlg.comments = "A pigpen cipher encoder/decoder"
   dlg.website = "https://github.com/SatoSawa/MasoniCode"
   dlg.website_label = "Github"
   dlg.default_height = 300
   if tonumber(Gtk._version) >= 3 then
      dlg.license_type = Gtk.License.GPL_3_0
   end
   dlg:run()
   dlg:hide()
end


-- Toolbar stuff
local toolbar = Gtk.Toolbar()
toolbar.tooltip_text = "Ctrl+p (Hide)"
--toolbar:insert(intro_bt, -1)
toolbar:insert(decode_mode_bt, -1)
toolbar:insert(encode_mode_bt, -1)
toolbar:insert(prefer_theme_bt,-1)
toolbar:insert(about_bt, -1)
toolbar:insert(Gtk.ToolButton {
		  stock_id = 'gtk-quit',
		  on_clicked = function() window:destroy() end,
      tooltip_text = "Quit" }, -1)
toolbar:override_background_color(0, Gdk.RGBA { red = 0.5, green = 0.5, blue = 0.5, alpha = 0.5 })

toolbar.orientation = 'VERTICAL'
toolbar.toolbar_style = 0 --enum 0 equals to show 'TOOLBAR_ICONS' only

-- Revealer of toolbar: implement show/hide transition
local toolbar_revealer =  Gtk.Revealer()
toolbar_revealer:set_reveal_child(true)
toolbar_revealer:set_transition_duration(350)
toolbar_revealer:set_transition_type(2)
toolbar_revealer:add(toolbar)


-- Toggle toolbar show/hide
function window:on_key_press_event(event)
	-- event.keyval -> num | event.state -> ctrl/shift
	-- Press ctrl + p to show/hide toolbar
	local action = event.keyval
	local ctrl_down = event.state.CONTROL_MASK
	if action == 112 and ctrl_down then
		toolbar_revealer:set_reveal_child(not toolbar_revealer:get_child_revealed())
	end
	if action == 116 and ctrl_down then
		  -- Set prefer theme to 'Dark' or 'Light'
		  local settings = Gtk.Settings.get_default()
		  settings.gtk_application_prefer_dark_theme = not settings.gtk_application_prefer_dark_theme
		  theme_key = (theme_key == 'Dark') and "Light" or "Dark"
		  prefer_theme_bt.tooltip_text = "Switch to "..theme_key.." Theme"
	end
	if action == 49 and ctrl_down then
		main_Interface:set_visible_child_name("decode_cipher")
	end
	if action == 50 and ctrl_down then
		main_Interface:set_visible_child_name("encode_cipher")
	end
end


-- Pack all components into the window
local hbox = Gtk.HBox()
hbox:pack_start(toolbar_revealer, false, false, 0)
hbox:pack_start(main_Interface, true, true, 5)
window:add(hbox)

-- Create GTK application
local app = Gtk.Application { application_id = 'com.sawa.masonicode' }
function app:on_activate()
   -- Setup default application icon.
   local pixbuf, err = GdkPixbuf.Pixbuf.new_from_file(
      dir:get_child('image/MasoniCode_icon_64.png'):get_path())
   if pixbuf then
      pixbuf = Gtk.Window.set_default_icon(pixbuf)
   else
      -- Report the error.
      local dialog = Gtk.MessageDialog {
	 message_type = 'ERROR', buttons = 'CLOSE',
	 text = ("Failed to read icon file: %s"):format(err),
	 on_response = Gtk.Widget.destroy
      }
      dialog:show_all()
   end

   -- Assign the window as the application one and display it.
    window.application = self
    window.default_width = 650
    window.default_height = 450
    window.resizable = false
    window:show_all()
    Gtk.main()
end


---- Show window and start the loop.
app:run { arg[0], ... }
