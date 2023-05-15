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
clicked_y = nothing
bands = nothing

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
                            html_div(children = [
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
                                "d (m):", dcc_input(
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
                                )
                        ]),
                        ],
                    ),
                    html_h2("Metamaterial Configuration", className="section-title"),
                    html_div(
                        id="metamaterial-section",
                        className="metamaterial-section",
                        children=[
                            gui_section(1, "gui-section"),
                            gui_section(2, "gui-section"),
                            gui_section(3, "gui-section"),
                            gui_section(4, "gui-section"),
                            gui_section(5, "gui-section"),
                            dcc_checklist(
                                id="bragg-check",
                                options = [
                                    Dict("label" => "Bragg Mirror", "value" => "mirror") 
                                ]
                            )
                        ]
                    ),
                    html_div(
                        className="scan-section",
                        children=[
                            html_h2("Scan Configuration", className="section-title"),
                            html_div(
                                children=[
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
                                ]
                            ),
                            html_div(
                                children=[
                                    "Simulation View: ", dcc_dropdown(
                                        id="sim-view",
                                        value= "logabs",
                                        options=[
                                            (label="Absolute", value="abs"),
                                            (label="Log Absolute", value="logabs"),
                                            (label="Real", value="real"),
                                            (label="Imaginary", value="imag"),
                                        ]
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
                                ]
                            ),
                            html_button("Run", id="run", n_clicks=0, className="run-button"),
                            html_div(
                                className="slice-container",
                                children=[
                                    dcc_graph(id="slice-graph")
                                ]
                            ),
                        ],
                    ),
                ],
            ),
            html_div(
                className="right-column",
                children=[
                    html_div(
                        className="graphs-container",
                        children=[
                            html_h1("Simulation Results", className="heatmap-title"),
                            html_div(
                                className="heatmap-container",
                                children=[
                                    dcc_graph(id="heatmap-graph", className="heatmap-graph"),
                                    dcc_slider(id="heatmap-caxis-slider", min=0, max=10, step=0.1, value=5, vertical=true),
                                ]
                            ),
                            html_div(
                                className="fft-container",
                                children=[
                                    dcc_graph(id="fft-graph", className="heatmap-graph"),
                                    dcc_slider(id="fft-caxis-slider", min=0, max=100, step=1, value=10, vertical=true),
                                ]
                            ),
                            html_div(id="invs")
                        ],
                    ),
                    html_a("Tell us what you think!", href="mailto:yonathan.amir@mail.huji.ac.il,mordechai.gruda@mail.huji.ac.il")
                ],
            ),
        ],
    )

function choice_to_func(choice::String)
    if choice == "real"
        return real
    elseif choice == "imag"
        return imag
    elseif choice == "abs"
        return abs
    elseif choice == "logreal"
        return x -> log(real(x))
    elseif choice == "logimag"
        return x -> log(imag(x))
    elseif choice == "logabs"
        return x -> log(abs(x))
    end
end

callback!(
    app,
    Output("invs", "children"),
    Input("run", "n_clicks"),
    Input("sim-view", "value"),
    Input("fft-view", "value"),
    State("c0", "value"),
    State("l0", "value"),
    State("d", "value"),
    State("num_tls", "value"),
    State("c1", "value"),
    State("l1", "value"),
    State("cells1", "value"),
    State("c2", "value"),
    State("l2", "value"),
    State("cells2", "value"),
    State("c3", "value"),
    State("l3", "value"),
    State("cells3", "value"),
    State("c4", "value"),
    State("l4", "value"),
    State("cells4", "value"),
    State("c5", "value"),
    State("l5", "value"),
    State("cells5", "value"),
    State("start", "value"),
    State("step", "value"),
    State("stop", "value"),
    State("bragg-check", "value")
) do n_clicks, simfunc, fftfunc, c0, l0, d, num_tls, c1, l1, cells1, c2, l2, cells2, c3, l3, cells3, c4, l4, cells4, c5, l5, cells5, start, step, stop, bragg
    global data
    global fftdata
    global dx
    global ωs
    global xs
    global bands

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

    if l4 !== nothing && c4 !== nothing && cells4 !== nothing
        push!(sections, Section(l4, c4, cells4))
    end

    if l5 !== nothing && c5 !== nothing && cells5 !== nothing
        push!(sections, Section(l5, c5, cells5))
    end
    
    dx = d/num_tls

    if bragg !== nothing && "mirror" in bragg
        sections = build_bragg_sections(l0, c0, sections[1], sections[2], dx, num_tls)
    end

    bands = []
    for s in sections
        f1, f2 = get_fs(d, l0, c0, s.L, s.C)
        push!(bands, (f1=f1, f2=f2, length=s.num_cells))
    end

    if ~isempty(sections)
        ωs = collect(start:step:stop) .* 2π

        simfunc = choice_to_func(simfunc)
        fftfunc = choice_to_func(fftfunc)
        
        board = build_board(l0, c0, sections, dx, num_tls)
        
        println("Board built.")
        data = sim_board(board, ωs, simfunc)
        println("Sim done.")

        xs = collect(1:size(data,1)) .* dx/2
        
        println("Data size: $(size(data)), ωs size: $(size(ωs))")
        
        fftdata = ([fftfunc.(fft(data[:,i])) for i in 1:size(data,2)])
        fftdata = reduce(hcat,fftdata)[end:-1:1,:]
        
        println("FFT size: $(size(fftdata))")        
        
        println("FFT done.")
    end

    return ""
end

callback!(
    app,
    Output("heatmap-graph", "figure"),
    Input("heatmap-caxis-slider", "value"),
    Input("heatmap-graph", "clickData"),
    Input("invs", "children"),
    State("d", "value"),
) do caxis_value, clickData, children, d
    global data
    global ωs
    global xs
    global clicked_y

    if data !== nothing
        traces = AbstractTrace[]
        
        z = unpack_heatmap(data);
        h = PlotlyJS.heatmap(x=xs, y=ωs./2π, z=z, title="Board Scan", zmin=-caxis_value, zmax=caxis_value);
        push!(traces, h)

        if bands !== nothing
            total_length = sum([x.length for x in bands])

            xcursor = 0
            for band in bands
                relative_length = band.length*xs[end]/total_length
                xstart = xcursor
                xend = xstart + relative_length

                println("$xstart, $xend")

                push!(traces, PlotlyJS.scatter(x=[xstart, xend], y=[band.f1, band.f1], mode="lines", line_color="rgba(0,0,0,0.5)"))
                push!(traces, PlotlyJS.scatter(x=[xstart, xend], y=[band.f2, band.f2], mode="lines", line_color="rgba(0,0,0,0.5)"))
                xcursor = xend
            end
        end

        if clicked_y !== nothing
            line_data = [clicked_y for i in 1:size(data,1)]
            line_graph = PlotlyJS.scatter(x=xs, y=line_data, mode="lines", line_color="rgba(255,255,255,0.5)")
            push!(traces, line_graph)
        end

        layout = Layout(
            title = "Simulation Result",
            scene = attr(
                xaxis_title = "Board Location (m)",
                yaxis_title = "Frequency (Hz)"
            )
        )
        return PlotlyJS.plot(traces, layout)
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
    global xs

    if fftdata !== nothing
        z = unpack_heatmap(fftdata)
        fft_heatmap = PlotlyJS.heatmap(x=xs, y=ωs./2π, z=z, zmin=0, zmax=caxis_value, title="X-Axis FFT");
        return PlotlyJS.plot(fft_heatmap)
    else
        return PlotlyJS.plot(zeros((1,1)))
    end
end

callback!(
    app,
    Output("slice-graph", "figure"),
    Input("heatmap-graph", "clickData")
) do clickdata
    if clickdata !== nothing
        global data
        global ωs
        global xs
        global clicked_y
        
        clicked_y = clickdata.points[1].y
        ω =  clicked_y * 2π

        index = findall(x->x==ω, ωs)
        ys = data[:,index]

        return PlotlyJS.plot(PlotlyJS.scatter(x=xs, y=ys, mode="lines", title="$ω"))
    end
    return PlotlyJS.plot(PlotlyJS.scatter(x=[0], y=[0], mode="markers"))
end

function unpack_heatmap(data)
    return [data[i,:] for i in 1:size(data,1)];
end

run_server(app, "0.0.0.0", 8050, debug = true)