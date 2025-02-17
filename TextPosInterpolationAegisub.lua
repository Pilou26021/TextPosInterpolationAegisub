script_name = "Text And Position Interpolation for Aegisub"
script_description = "Adjusts text size over time between two selected subtitles"
script_author = "PilouFace_"
script_version = "1.1"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
	script_version="6.1.0"
	depRec=DependencyControl{feed="https://raw.githubusercontent.com/unanimated/luaegisub/master/DependencyControl.json"}
end

re=require'aegisub.re'
karaskel=require'karaskel'

-- Interpolation Map
local interpolation_map = {
    Linear = { Linear = "Linear" },
    Sine = { In = "easeInSine", Out = "easeOutSine", InOut = "easeInOutSine" },
    Cubic = { In = "easeInCubic", Out = "easeOutCubic", InOut = "easeInOutCubic" },
    Quint = { In = "easeInQuint", Out = "easeOutQuint", InOut = "easeInOutQuint" },
    Circ = { In = "easeInCirc", Out = "easeOutCirc", InOut = "easeInOutCirc" },
    Elastic = { In = "easeInElastic", Out = "easeOutElastic", InOut = "easeInOutElastic" },
    Quad = { In = "easeInQuad", Out = "easeOutQuad", InOut = "easeInOutQuad" },
    Quart = { In = "easeInQuart", Out = "easeOutQuart", InOut = "easeInOutQuart" },
    Expo = { In = "easeInExpo", Out = "easeOutExpo", InOut = "easeInOutExpo" },
    Back = { In = "easeInBack", Out = "easeOutBack", InOut = "easeInOutBack" },
    Bounce = { In = "easeInBounce", Out = "easeOutBounce", InOut = "easeInOutBounce" }
}

local interpolation_math_map = {
    Linear = function(t) return t end,
    easeInSine = function(t) return 1 - math.cos((t * math.pi) / 2) end,
    easeOutSine = function(t) return math.sin((t * math.pi) / 2) end,
    easeInOutSine = function(t) return -(math.cos(math.pi * t) - 1) / 2 end,
    easeInCubic = function(t) return t^3 end,
    easeOutCubic = function(t) return 1 - (1 - t)^3 end,
    easeInOutCubic = function(t) return t < 0.5 and 4 * t^3 or 1 - (-2 * t + 2)^3 / 2 end,
    easeInQuint = function(t) return t^5 end,
    easeOutQuint = function(t) return 1 - (1 - t)^5 end,
    easeInOutQuint = function(t) return t < 0.5 and 16 * t^5 or 1 - (-2 * t + 2)^5 / 2 end,
    easeInCirc = function(t) return 1 - math.sqrt(1 - t^2) end,
    easeOutCirc = function(t) return math.sqrt(1 - (t - 1)^2) end,
    easeInOutCirc = function(t) return t < 0.5 and (1 - math.sqrt(1 - (2 * t)^2)) / 2 or (math.sqrt(1 - (-2 * t + 2)^2) + 1) / 2 end,
    easeInElastic = function(t) return t == 0 and 0 or t == 1 and 1 or -2^(10 * t - 10) * math.sin((t * 10 - 10.75) * (2 * math.pi) / 3) end,
    easeOutElastic = function(t) return t == 0 and 0 or t == 1 and 1 or 2^(-10 * t) * math.sin((t * 10 - 0.75) * (2 * math.pi) / 3) + 1 end,
    easeInOutElastic = function(t) return t == 0 and 0 or t == 1 and 1 or t < 0.5 and -(2^(20 * t - 10) * math.sin((20 * t - 11.125) * (2 * math.pi) / 4.5)) / 2 or (2^(-20 * t + 10) * math.sin((20 * t - 11.125) * (2 * math.pi) / 4.5)) / 2 + 1 end,
    easeInQuad = function(t) return t^2 end,
    easeOutQuad = function(t) return 1 - (1 - t)^2 end,
    easeInOutQuad = function(t) return t < 0.5 and 2 * t^2 or 1 - (-2 * t + 2)^2 / 2 end,
    easeInQuart = function(t) return t^4 end,
    easeOutQuart = function(t) return 1 - (1 - t)^4 end,
    easeInOutQuart = function(t) return t < 0.5 and 8 * t^4 or 1 - (-2 * t + 2)^4 / 2 end,
    easeInExpo = function(t) return t == 0 and 0 or 2^(10 * t - 10) end,
    easeOutExpo = function(t) return t == 1 and 1 or 1 - 2^(-10 * t) end,
    easeInOutExpo = function(t) return t == 0 and 0 or t == 1 and 1 or t < 0.5 and 2^(20 * t - 10) / 2 or (2^(-20 * t + 10) + 1) / 2 end,
    easeInBack = function(t) return 2.70158 * t^3 - 1.70158 * t^2 end,
    easeOutBack = function(t) return 1 + 2.70158 * (t - 1)^3 + 1.70158 * (t - 1)^2 end,
    easeInOutBack = function(t) return t < 0.5 and (2 * t)^3 - 2 * t^2 or 1 + 2 * (2 * t - 2)^3 + 2 * (2 * t - 2)^2 end,
    easeInBounce = function(t) return 1 - interpolation_math_map.easeOutBounce(1 - t) end,
    easeOutBounce = function(t) if t < 1 / 2.75 then return 7.5625 * t^2 elseif t < 2 / 2.75 then t = t - 1.5 / 2.75 return 7.5625 * t^2 + 0.75 elseif t < 2.5 / 2.75 then t = t - 2.25 / 2.75 return 7.5625 * t^2 + 0.9375 else t = t - 2.625 / 2.75 return 7.5625 * t^2 + 0.984375 end end,
    easeInOutBounce = function(t) return t < 0.5 and interpolation_math_map.easeInBounce(t * 2) / 2 or interpolation_math_map.easeOutBounce(t * 2 - 1) / 2 + 0.5 end
}

-- Function to dynamically get interpolation options
function get_interpolation_options(algorithm)
    local options = {}
    if interpolation_map[algorithm] then
        for key, _ in pairs(interpolation_map[algorithm]) do
            table.insert(options, key)
        end
    else
        table.insert(options, "Linear") -- Default fallback
    end
    return options
end

function get_interpolation_final_function(algorithm, interpolation_type)
    return interpolation_map[algorithm][interpolation_type] or "Linear"
end

-- Main function
function sizing_text(subtitles, selected_lines, active_line)
    if #selected_lines ~= 2 then
        aegisub.debug.out("Please select exactly two lines (start and end)!\n")
        return
    end

    -- Calculate number of frames between the two selected lines
    local start_line = subtitles[selected_lines[1]]
    local end_line = subtitles[selected_lines[2]]
    local frames = aegisub.frame_from_ms(end_line.start_time) - aegisub.frame_from_ms(start_line.end_time)

    -- Step 1: Select Interpolation Algorithm
    local first_buttons, first_values = aegisub.dialog.display({
        {class="label", label="Select the interpolation algorithm:", x=0, y=0, width=2, height=1},
        {class="dropdown", name="interpolationalgorithm", x=2, y=0, width=2, height=1,
         items={"Linear", "Sine", "Cubic", "Quint", "Circ", "Elastic", "Quad", "Quart", "Expo", "Back", "Bounce"}, value="Linear"}
    }, {"Next", "Cancel"})

    if first_buttons ~= "Next" then return end
    local algorithm = first_values.interpolationalgorithm

    -- Step 2: Select Interpolation Type (In, Out, InOut)
    local interpolation_options = get_interpolation_options(algorithm)
    local second_buttons, second_values = aegisub.dialog.display({
        {class="label", label="Select the interpolation type:", x=0, y=0, width=2, height=1},
        {class="dropdown", name="interpolationtype", x=2, y=0, width=2, height=1, items=interpolation_options, value=interpolation_options[1]}
    }, {"Next", "Cancel"})

    if second_buttons ~= "Next" then return end
    local interpolation_type = second_values.interpolationtype
    local interpolation_final = get_interpolation_final_function(algorithm, interpolation_type)

    -- Step 3: Choose Steps for Transition
    local third_buttons, third_values = aegisub.dialog.display({
        {class="label", label="Algorithm selected: " .. interpolation_final, x=0, y=0, width=4, height=1},
        {class="label", label="Number of steps for transition:", x=0, y=1, width=2, height=1},
        {class="intedit", name="steps", x=2, y=1, width=2, height=1, min=2, max=50, value=frames},
        {class="label", label="Note: The more steps, the smoother the transition.", x=0, y=2, width=4, height=1}
    }, {"OK", "Cancel"})

    if third_buttons ~= "OK" then return end
    local steps = third_values.steps

    -- Call the appropriate function
    if interpolation_function == "Linear" then
        linear_interpolation(subtitles, selected_lines, steps)
    else
        advanced_interpolation(subtitles, selected_lines, steps, interpolation_final)
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
function linear_interpolation (subtitles, selected_lines, steps)
    
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

function advanced_interpolation(subtitles, selected_lines, steps, interpolation_final)
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

    -- Apply easing function
    local easing = interpolation_math_map[interpolation_final]
    if not easing then
        aegisub.debug.out("Invalid interpolation function.\n")
        return
    end

    for i = 1, steps do
        local new_line = subtitles[selected_lines[1] + i]
        local t = (i - 1) / (steps - 1) 
        local easing_t = easing(t)

        new_line.text = update_font_size(new_line.text, start_size + (size_step * i * easing_t))
        new_line.text = update_position(new_line.text, start_pos[1] + (pos_step[1] * i * easing_t), start_pos[2] + (pos_step[2] * i * easing_t))
    end

end