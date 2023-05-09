using Gtk
include("./abcd_sim.jl")

win = GtkWindow("UI Application", 400, 200)

# Setup section
setup = GtkFrame("Setup")
setup_box = GtkBox(:v)

# Capacitors and Inductors inputs
capacitors_box = GtkBox(:h)
capacitors_label = GtkLabel("Capacitors")
capacitors_entry = GtkEntry()
capacitors_float_entry = GtkEntry()
push!(capacitors_box, capacitors_label)
push!(capacitors_box, capacitors_entry)
push!(capacitors_box, capacitors_float_entry)

inductors_box = GtkBox(:h)
inductors_label = GtkLabel("Inductors")
inductors_entry = GtkEntry()
inductors_float_entry = GtkEntry()
push!(inductors_box, inductors_label)
push!(inductors_box, inductors_entry)
push!(inductors_box, inductors_float_entry)

# Parameters inputs
params_box = GtkBox(:h)
c0_label = GtkLabel("C0")
c0_entry = GtkEntry()
l0_label = GtkLabel("L0")
l0_entry = GtkEntry()
d_label = GtkLabel("d")
d_entry = GtkEntry()
num_tls_label = GtkLabel("num_tls")
num_tls_entry = GtkEntry()
push!(params_box, c0_label)
push!(params_box, c0_entry)
push!(params_box, l0_label)
push!(params_box, l0_entry)
push!(params_box, d_label)
push!(params_box, d_entry)
push!(params_box, num_tls_label)
push!(params_box, num_tls_entry)

# Permutate button
permutate_button = GtkButton("Permutate")

# Cell sections
cell_boxes = []
for i in 1:4
    cell_box = GtkBox(:h)
    cell_label = GtkLabel("Cell $i")
    cell_dropdown = GtkComboBoxText()
    cell_textbox = GtkEntry()
    cell_numbox = GtkEntry()
    push!(cell_box, cell_label)
    push!(cell_box, cell_dropdown)
    push!(cell_box, cell_textbox)
    push!(cell_box, cell_numbox)
    push!(cell_boxes, cell_box)
end

# Start/Step/Stop inputs
start_step_stop_box = GtkBox(:h)
start_label = GtkLabel("Start")
start_entry = GtkEntry()
step_label = GtkLabel("Step")
step_entry = GtkEntry()
stop_label = GtkLabel("Stop")
stop_entry = GtkEntry()
push!(start_step_stop_box, start_label)
push!(start_step_stop_box, start_entry)
push!(start_step_stop_box, step_label)
push!(start_step_stop_box, step_entry)
push!(start_step_stop_box, stop_label)
push!(start_step_stop_box, stop_entry)

# Show Bands and Colormap inputs
show_bands_checkbutton = GtkCheckButton("Show Bands")
colormap_label = GtkLabel("Colormap")
colormap_dropdown = GtkComboBoxText()

# Simulate button
simulate_button = GtkButton("Simulate")

# Add all elements to setup section
push!(setup_box, capacitors_box)
push!(setup_box, inductors_box)
push!(setup_box, params_box)
push!(setup_box, permutate_button)
for cell_box in cell_boxes
    push!(setup_box, cell_box)
end
push!(setup_box, start_step_stop_box)
push!(setup_box, show_bands_checkbutton)
push!(setup_box, colormap_label)
push!(setup_box, colormap_dropdown)
push!(setup_box, simulate_button)

# Plot section
plot = GtkFrame("Plot")
plot_box = GtkBox(:v)

# Heatmap
heatmap_img = GtkImage()

# Save button
save_button = GtkButton("Save")

# Add all elements to plot section
push!(plot_box, heatmap_img)
push!(plot_box, save_button)

# Add all sections to window
push!(setup, setup_box)
push!(plot, plot_box)
main_box = GtkBox(:h)
push!(main_box, setup)
push!(main_box, plot)
push!(win, main_box)

# Callback function for "Permutate" button
function on_permutate_clicked(widget)
    # Get values from inputs
    capacitors = split(get(capacitors_entry), ",")
    inductors = split(get(inductors_entry), ",")
    c0 = parse(Float64, get(c0_entry))
    l0 = parse(Float64, get(l0_entry))
    d = parse(Float64, get(d_entry))
    num_tls = parse(Int, get(num_tls_entry))

    # Perform permutation and populate dropdowns
    println("Permutated!")
end

# Connect "Permutate" button to callback function
signal_connect(on_permutate_clicked, permutate_button, "clicked")

# Callback function for cell dropdowns
function on_cell_dropdown_changed(widget)
    # Get selected value from dropdown
    selected_value = get_active_text(widget)

    # Update textbox with selected value
    # ...
end

# Connect cell dropdowns to callback function
# for cell_box in cell_boxes
#     cell_dropdown = get_child_at_index(cell_box, 1)
#     signal_connect(on_cell_dropdown_changed, cell_dropdown, "changed")
# end

# Callback function for "Simulate" button
function on_simulate_clicked(widget)
    # Get values from inputs
    start = parse(Float64, get(start_entry))
    step = parse(Float64, get(step_entry))
    stop = parse(Float64, get(stop_entry))
    show_bands = get_active(show_bands_checkbutton)
    colormap = get_active_text(colormap_dropdown)

    # Perform simulation and update heatmap
    println("Simulated!")
end

# Connect "Simulate" button to callback function
signal_connect(on_simulate_clicked, simulate_button, "clicked")

# Callback function for "Save" button
function on_save_clicked(widget)
    # Save heatmap as PNG
    println("Saved!")
end

# Connect "Save" button to callback function
signal_connect(on_save_clicked, save_button, "clicked")

showall(win)