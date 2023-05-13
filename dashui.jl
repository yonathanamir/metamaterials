using Dash
using PlotlyJS
using FFTW

include("./abcd_sim.jl")
include("./components.jl")

app = dash(assets_folder="./assests")

data = nothing
fftdata = nothing
ωs = nothing
sections = nothing
possibilities = nothing

app.layout = html_div(
        className="container",
        children=[
            html_div(
                className="left-column",
                children=[
                    html_div(
                        className="board-section",
                        children=[
                            html_h2("Board Configuration", className="section-title"),
                            "C0:", dcc_input(
                                id="c0",
                                value=8.103e-11,
                                type="number",
                                className="input-field"
                            ),
                            "L0:", dcc_input(
                                id="l0",
                                value=7.837e-7,
                                type="number",
                                className="input-field"
                            ),
                            "d (mm):", dcc_input(
                                id="d",
                                value=9e-3,
                                type="number",
                                className="input-field"
                            ),
                            "num tls:", dcc_input(
                                id="num_tls",
                                value=20,
                                type="number",
                                className="input-field"
                            ),
                        ],
                    ),
                    html_h2("Metamaterial Configuration", className="section-title"),
                    html_div(
                        id="metamaterial-section",
                        className="metamaterial-section",
                        children=[
                            gui_section(1, "gui-section"),
                            gui_section(2, "gui-section"),
                            gui_section(3, "gui-section")
                        ]
                    ),
                    html_div(
                        className="scan-section",
                        children=[
                            html_h2("Scan Configuration", className="section-title"),
                            "start:", dcc_input(
                                id="start",
                                value=1e9,
                                type="number",
                                className="input-field"
                            ),
                            "stop:", dcc_input(
                                id="stop",
                                value=14e9,
                                type="number",
                                className="input-field"
                            ),
                            "step:", dcc_input(
                                id="step",
                                value=1e7,
                                type="number",
                                className="input-field"
                            ),
                            "FFT View: ", dcc_dropdown(
                                id="fft-view",
                                value= "real",
                                options=[
                                    (label="Real", value="real"),
                                    (label="Imaginary", value="imag"),
                                    (label="Absolute", value="abs"),
                                ]
                            ),
                            html_button("run", id="run", n_clicks=0, className="run-button"),
                        ],
                    ),
                ],
            ),
            html_div(
                className="right-column",
                children=[
                    html_div(
                        className="heatmap-container",
                        children=[
                            html_h1("Simulation Results", className="heatmap-title"),
                            dcc_graph(id="heatmap-graph", className="heatmap-graph"),
                            dcc_slider(id="heatmap-caxis-slider", min=0, max=10, step=0.1, value=5),
                            dcc_graph(id="fft-graph", className="heatmap-graph"),
                            dcc_slider(id="fft-caxis-slider", min=0, max=200, step=1, value=100),
                            html_div(id="invs")
                        ],
                    ),
                ],
            ),
        ],
    )


# callback!(
#     app,
#     Output("invs", "children"),
#     Input("run", "n_clicks"),
#     State("c0", "value"),
#     State("l0", "value"),
#     State("d", "value"),
#     State("num_tls", "value"),
#     State("c1", "value"),
#     State("c2", "value"),
#     State("c3", "value"),
#     State("l1", "value"),
#     State("l2", "value"),
#     State("l3", "value"),
#     State("cells1", "value"),
#     State("cells2", "value"),
#     State("cells3", "value"),
#     State("start", "value"),
#     State("stop", "value"),
#     State("step", "value")
# ) do n_clicks, c0, l0, d, num_tls, c1, c2, c3, l1, l2, l3, cells1, cells2, cells3, start, stop, step
#     global data
#     global fftdata

#     data = sim_plot(c0, l0, d, num_tls, c1, c2, c3, l1, l2, l3, cells1, cells2, cells3, start, stop, step)
#     fftdata = ([abs.(fft(data[i,:])) for i in 1:size(data,1)])
#     # fftdata = ([abs.(fft(data[:,i])) for i in 1:size(data,2)])
    
#     return ""
# end

callback!(
    app,
    Output("invs", "children"),
    Input("run", "n_clicks"),
    Input("fft-view", "value"),
    State("c0", "value"),
    State("l0", "value"),
    State("d", "value"),
    State("num_tls", "value"),
    State("c1", "value"),
    State("c2", "value"),
    State("c3", "value"),
    State("l1", "value"),
    State("l2", "value"),
    State("l3", "value"),
    State("cells1", "value"),
    State("cells2", "value"),
    State("cells3", "value"),
    State("start", "value"),
    State("step", "value"),
    State("stop", "value")
) do n_clicks, fftfunc, c0, l0, d, num_tls, c1, c2, c3, l1, l2, l3, cells1, cells2, cells3, start, step, stop
    global data
    global fftdata
    global dx
    global ωs

    sections = Vector{Section}()

    if l1 !== nothing && c1 !== nothing && cells1 !== nothing
        push!(sections, Section(l1, c1, cells1))
    end

    if l2 !== nothing && c2 !== nothing && cells2 !== nothing
        push!(sections, Section(l2, c2, cells2))
    end

    if l3 !== nothing && c3 !== nothing && cells3 !== nothing
        push!(sections, Section(l3, c3, cells3))
    end

    if ~isempty(sections)
        dx = d/num_tls
        ωs = collect(start:step:stop) .* 2π

        board = build_board(l0, c0, sections, dx, num_tls)
        println("Board built.")
        data = Matrix{Float64}(transpose(sim_board(board, ωs)))
        println("Sim done.")
        
        println("Data size: $(size(data)), ωs size: $(size(ωs))")
        # fftdata = ([abs.(fft(data[i,:])) for i in 1:size(data,1)])
        
        func = nothing
        if fftfunc == "real"
            func = real
        elseif fftfunc == "imag"
            func = imag
        elseif fftfunc == "abs"
            func = abs
        end
        fftdata = ([func.(fft(data[:,i])) for i in 1:size(data,2)])
        fftdata = reduce(hcat,fftdata)
        
        println("FFT size: $(size(fftdata))")
        
        
        println("FFT done.")
    end

    return ""
end

callback!(
    app,
    Output("heatmap-graph", "figure"),
    Input("heatmap-caxis-slider", "value"),
    Input("invs", "children")
) do caxis_value, children
    global data
    global ωs
    global dx

    if data !== nothing
        println("Heatmap Hi")
        xs = collect(1:size(data,1)) .* dx

        z = unpack_heatmap(data);
        h = PlotlyJS.heatmap(x=xs, y=ωs./2π, z=z, title="Board Scan", zmin=-caxis_value, zmax=caxis_value);

        return PlotlyJS.plot(h)
    else
        return PlotlyJS.plot(zeros((1,1)))
    end
end

callback!(
    app,
    Output("fft-graph", "figure"),
    Input("fft-caxis-slider", "value"),
    Input("invs", "children")
) do caxis_value, children
    global fftdata
    global ωs
    global dx

    if fftdata !== nothing
        xs = collect(1:size(fftdata,1)) .* dx
        z = unpack_heatmap(fftdata)
        fft_heatmap = PlotlyJS.heatmap(x=xs, y=ωs./2π, z=z, zmin=0, zmax=caxis_value, title="X-Axis FFT");
        return PlotlyJS.plot(fft_heatmap)
    else
        return PlotlyJS.plot(zeros((1,1)))
    end
end

function unpack_heatmap(data)
    return [data[i,:] for i in 1:size(data,1)];
end


function sim_plot(board, start, stop, step)
    global ωs
    global dx

    ωs = collect(start:step:stop) .* 2π

    data = sim_board(board, ωs)
    A = Matrix{Float64}(transpose(data));

    return A
end

run_server(app, "0.0.0.0", 8050, debug = true)