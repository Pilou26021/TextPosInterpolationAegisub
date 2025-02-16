script_name = "Text & Position Interpolation for Aegisub"
script_description = "Adjusts text size over time between two selected subtitles"
script_author = "PilouFace_"
script_version = "1.0"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
	script_version="6.1.0"
	depRec=DependencyControl{feed="https://raw.githubusercontent.com/unanimated/luaegisub/master/DependencyControl.json"}
end

re=require'aegisub.re'
karaskel=require'karaskel'

-- Main function
function sizing_text(subtitles, selected_lines, active_line)
    if #selected_lines ~= 2 then
        aegisub.debug.out("Please select exactly two lines (start and end)!\n")
        return
    end


    local line1 = subtitles[selected_lines[1]]
    local line2 = subtitles[selected_lines[2]]


    
    local buttons, values = aegisub.dialog.display({
        {class="label", label="Number of steps for transition:", x=0, y=0, width=2, height=1},
        {class="intedit", name="steps", x=2, y=0, width=2, height=1, min=2, max=50, value=10}
    }, {"OK", "Cancel"})

    if buttons ~= "OK" then return end
    local steps = values.steps



    local start_size = extract_font_size(line1.text)
    local end_size = extract_font_size(line2.text)

    if not start_size or not end_size then
        aegisub.debug.out("Could not determine font size. Make sure the text has \\fs tags.\n")
        return
    end

    
    local total_duration = line2.start_time - line1.end_time
    local duration_per_step = total_duration / steps
    local previous_end_time = line1.end_time
    local size_step = (end_size - start_size) / steps
    
    for i = 1, steps do
        local new_line = table.copy(line1)
        new_line.start_time = previous_end_time
        new_line.end_time = new_line.start_time + duration_per_step
    
        if i == steps then
            new_line.end_time = line2.start_time
        end

        new_line.text = update_font_size(line1.text, start_size + (size_step * i))
        subtitles.insert(selected_lines[1] + i, new_line)
        previous_end_time = new_line.end_time
    end


    aegisub.set_undo_point("Sizing Text Effect")
end

function extract_font_size(text)
    local size = text:match("\\fs(%d+)")
    return size and tonumber(size)
end

function update_font_size(text, new_size)
    return text:gsub("\\fs%d+", "\\fs" .. new_size)
end

aegisub.register_macro(script_name, script_description, sizing_text)
