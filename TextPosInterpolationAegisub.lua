script_name = "Text And Position Interpolation for Aegisub"
script_description = "Adjusts text size over time between two selected subtitles"
script_author = "PilouFace_"
script_version = "1.01"

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
    
    local buttons, values = aegisub.dialog.display({
        {class="label", label="Select the interpolation algorithm:", x=0, y=2, width=2, height=1},
        {class="dropdown", name="interpolation", x=2, y=2, width=2, height=1, items={"Linear", "Ease In", "Ease Out", "Ease In-Out"}, value="Linear"},

        {class="label", label="Number of steps for transition:", x=0, y=0, width=2, height=1},
        {class="intedit", name="steps", x=2, y=0, width=2, height=1, min=2, max=50, value=10},
        {class="label", label="Note: The more steps, the smoother the transition(use the number of frames for the smooth transition)", x=0, y=1, width=4, height=1}
    }, {"OK", "Cancel"})

    if buttons ~= "OK" then return end
    local steps = values.steps

    if values.interpolation == "Linear" then
        linearinterpolation(subtitles, selected_lines, active_line, steps)
    else if values.interpolation == "Ease In" then
        easeininterpolation(subtitles, selected_lines, active_line, steps)
    else if values.interpolation == "Ease Out" then
        easeoutinterpolation(subtitles, selected_lines, active_line, steps)
    else if values.interpolation == "Ease In-Out" then
        easeinoutinterpolation(subtitles, selected_lines, active_line, steps)
    end
    end
    end
    end

    aegisub.set_undo_point("Text And Position Interpolation")
end

function extract_font_size(text)
    local size = text:match("\\fs(%d+)")
    return size and tonumber(size)
end

function extract_position(text)
    local x, y = text:match("\\pos%(([%d%.]+),([%d%.]+)%)")
    return {tonumber(x), tonumber(y)}
end

function update_position(text, x, y)
    return text:gsub("\\pos%b()", string.format("\\pos(%.1f,%.1f)", x, y))
end

function update_font_size(text, new_size)
    return text:gsub("\\fs%d+", "\\fs" .. new_size)
end

aegisub.register_macro(script_name, script_description, sizing_text)

-- Interpolation algorithm

-- Linear interpolation
function linearinterpolation (subtitles, selected_lines, active_line, steps)
    
    local line1 = subtitles[selected_lines[1]]
    local line2 = subtitles[selected_lines[2]]

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

    local start_pos = extract_position(line1.text)
    local end_pos = extract_position(line2.text)

    if not start_pos or not end_pos then
        aegisub.debug.out("Could not determine position. Make sure the text has \\pos tags.\n")
        return
    end

    local pos_step = {(end_pos[1] - start_pos[1]) / steps, (end_pos[2] - start_pos[2]) / steps}

    for i = 1, steps do
        local new_line = table.copy(line1)
        new_line.start_time = previous_end_time
        new_line.end_time = new_line.start_time + duration_per_step
    
        if i == steps then
            new_line.end_time = line2.start_time
        end

        new_line.x = start_pos[1] + (pos_step[1] * i)
        new_line.y = start_pos[2] + (pos_step[2] * i)

        new_line.text = update_font_size(line1.text, start_size + (size_step * i))
        new_line.text = update_position(new_line.text, new_line.x, new_line.y)
       
        subtitles.insert(selected_lines[1] + i, new_line)
        previous_end_time = new_line.end_time
    end
end

-- Ease In interpolation
function easeininterpolation(subtitles, selected_lines, active_line, steps)
    aegisub.debug.out("Ease In interpolation is not implemented yet.\n")
end

function easeoutinterpolation(subtitles, selected_lines, active_line, steps)
    aegisub.debug.out("Ease Out interpolation is not implemented yet.\n")
end

function easeinoutinterpolation(subtitles, selected_lines, active_line, steps)
    aegisub.debug.out("Ease In-Out interpolation is not implemented yet.\n")
end