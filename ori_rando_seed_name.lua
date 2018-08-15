obs           = obslua
source_name   = ""
file_location = ""
hotkey_id     = obs.OBS_INVALID_HOTKEY_ID

function string_split(s)
	local arr = {}
	i = 1
	for v in string.gmatch(s, "(.*?),(.*?),.*?%|(.*)") do
		arr[i] = v
		i = i + 1
	end
	return arr
end

function file_exists(file)
	local f = io.open(file, "r")
	if f then
		f:close()
	end
	return f ~= nil
end

function read_file(f)
	if not file_exists(f) then
		return "Seed File Not Found"
	end
	
	local file = io.open(f)
	local difficulty, mode, seed = string.match(file:read(), "(.-),(.-),.-%|(.*)$")
	-- local params = string_split(file:read())
	file:close()
	
	return "Seed: " .. difficulty .. " " .. mode .. " " .. seed
end

function load_seed()
	local source = obs.obs_get_source_by_name(source_name)
	local text = read_file(file_location)
	if source ~= nil then
		local settings = obs.obs_data_create()
		obs.obs_data_set_string(settings, "text", text)
		obs.obs_source_update(source, settings)
		obs.obs_data_release(settings)
		obs.obs_source_release(source)
	end
end

----------------------------------------------------------

-- A function named script_properties defines the properties that the user
-- can change for the entire script module itself
function script_properties()
	local props = obs.obs_properties_create()
	local p = obs.obs_properties_add_list(props, "source", "Text Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local f = obs.obs_properties_add_path(props, "path", "Path to randomizer.dat file", obs.OBS_PATH_FILE, "Randomizer seed file (*.dat)", "C:/Program Files (x86)/Steam/steamapps/common/Ori DE")
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_id(source)
			if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			end
		end
	end
	obs.source_list_release(sources)

	return props
end

-- A function named script_description returns the description shown to
-- the user
function script_description()
	return "Reads the `randomizer.dat` file for Ori rando and outputs the name of the seed.\n\nMade by Jim"
end

-- A function named script_update will be called when settings are changed
function script_update(settings)
	source_name = obs.obs_data_get_string(settings, "source")
	file_location = obs.obs_data_get_string(settings, "path")

	load_seed()
end

-- A function named script_defaults will be called to set the default settings
function script_defaults(settings)
end

-- A function named script_save will be called when the script is saved
--
-- NOTE: This function is usually used for saving extra data (such as in this
-- case, a hotkey's save data).  Settings set via the properties are saved
-- automatically.
function script_save(settings)
	local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
	obs.obs_data_set_array(settings, "load_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end

-- a function named script_load will be called on startup
function script_load(settings)
	-- Connect hotkey and activation/deactivation signal callbacks
	--
	-- NOTE: These particular script callbacks do not necessarily have to
	-- be disconnected, as callbacks will automatically destroy themselves
	-- if the script is unloaded.  So there's no real need to manually
	-- disconnect callbacks that are intended to last until the script is
	-- unloaded.
	local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "source_activate", source_activated)
	obs.signal_handler_connect(sh, "source_deactivate", source_deactivated)

	hotkey_id = obs.obs_hotkey_register_frontend("load_seed_name", "Load Seed Name", load_seed)
	local hotkey_save_array = obs.obs_data_get_array(settings, "load_hotkey")
	obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end
