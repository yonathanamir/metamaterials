using CSV
using DataFrames
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

app.layout = html_div(
        className="container",
        children=[
            html_div(
                className="left-column",
                children=[
                    html_div(
                        className="file-section",
                        children=[
                            html_h2("File Configuration", className="section-title"),
                            html_div(children = [
                                "File path:", dcc_input(
                                    id="file-path",
                                    value="D:\\ac\\physics\\lab3\\metam\\g\\metamaterials\\labdata\\2023_05_11_02.csv",
                                    type="text",
                                    className="input-field"
                                ),
                        ]),
                        ],
                    ),
                    html_div(
                        children=[
                            "Simulation View: ", dcc_dropdown(
                                id="sim-view",
                                value= "real",
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
                    html_div(
                        className="slice-container",
                        children=[
                            dcc_graph(id="slice-graph")
                        ]
                    ),
                    ],
                    ),
                html_div(
                    className="right-column",
                    children=[
                        html_div(
                            className="graphs-container",
                            children=[
                                html_h1("Lab Results", className="heatmap-title"),
                                html_div(
                                    className="heatmap-container",
                                    children=[
                                        dcc_graph(id="heatmap-graph", className="heatmap-graph"),
                                        dcc_slider(id="heatmap-caxis-slider", min=-100, max=100, step=0.1, value=-50, vertical=true),
                                    ]
                                ),
                                html_div(
                                    className="fft-container",
                                    children=[
                                        dcc_graph(id="fft-graph", className="heatmap-graph"),
                                        dcc_slider(id="fft-caxis-slider", min=-100, max=100, step=1, value=100, vertical=true),
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
    Input("file-path", "value"),
    Input("sim-view", "value"),
    Input("fft-view", "value"),
) do file_path, simfunc, fftfunc
    global data
    global fftdata
    global ωs
    global xs
    
    df = DataFrame(CSV.File(file_path))
    
    sections = Vector{Section}()

    ωs = collect(unique(df[!, "freq"])) .* 2π

    # Get unique x values and freq values
    x_values = unique(df.x)
    freq_values = unique(df.freq)

    # Initialize an empty matrix
    matrix = zeros(Float64, length(x_values), length(freq_values))

    # Iterate over the DataFrame rows
    for row in eachrow(df)
        freq_index = findfirst(freq_values .== row.freq)
        x_index = findfirst(x_values .== row.x)
        matrix[x_index, freq_index] = row.s12
    end

    simfunc = choice_to_func(simfunc)
    fftfunc = choice_to_func(fftfunc)

    data = simfunc.(matrix)
    println("Sim done.")

    xs = x_values
    
    println("Data size: $(size(data)), ωs size: $(size(ωs))")
    
    fftdata = ([fftfunc.(fft(data[:,i])) for i in 1:size(data,2)])
    fftdata = reduce(hcat,fftdata)[end:-1:1,:]
    
    println("FFT size: $(size(fftdata))")        
    
    println("FFT done.")

    return ""
end

callback!(
    app,
    Output("heatmap-graph", "figure"),
    Input("heatmap-caxis-slider", "value"),
    Input("heatmap-graph", "clickData"),
    Input("invs", "children")
) do caxis_value, clickData, children
    global data
    global ωs
    global xs
    global clicked_y

    if data !== nothing
        z = unpack_heatmap(data);
        h = PlotlyJS.heatmap(x=xs, y=ωs./2π, z=z, title="Board Scan", zmin=-caxis_value, zmax=caxis_value);

        if clicked_y !== nothing
            # TODO: Add line
            # line_data = [clicked_y for i in 1:size(data,1)]
            # line_graph = PlotlyJS.line(x=xs, y=line_data, line=(color="red", width=2), title="Horizontal Line")
            println(clicked_y)

            # layout = Layout(
            #     title = "Simulation Result",
            #     scene = attr(
            #         xaxis_title = "Frequency (Hz)",
            #         yaxis_title = "Input Voltage (V)"
            #     )
            # )

            # return Plot([h, line_graph], layout)
            # h.add_hline(y=clicked_y)
        end

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
    global xs

    if fftdata !== nothing
        # xs = collect(1:size(fftdata,1)) .* dx
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

        ω = clickdata.points[1].y * 2π
        clicked_y = ω

        index = findall(x->x==ω, ωs)
        ys = data[:,index]

        return PlotlyJS.plot(PlotlyJS.scatter(x=xs, y=ys, mode="lines", title="$ω"))
    end
    return PlotlyJS.plot(PlotlyJS.scatter(x=[0], y=[0], mode="markers"))
    # graph = PlotlyJS.scatter(x=, y=,)
end

function unpack_heatmap(data)
    return [data[i,:] for i in 1:size(data,1)];
end

run_server(app, "0.0.0.0", 8051, debug = true)