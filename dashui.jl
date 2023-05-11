using Dash
using PlotlyJS
using FFTW

include("./abcd_sim.jl")
include("./components.jl")

app = dash(assets_folder="./assests")

data = nothing
ωs = nothing

app.layout = html_div(
        className="container",
        children=[
            html_div(
                className="left-column",
                children=[
                    html_div(
                        className="board-section",
                        children=[
                            html_h2("board configuration", className="section-title"),
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
                    html_div(
                        className="metamaterial-section",
                        children=[
                            html_h2("metamaterial configuration", className="section-title"),
                            gui_section(1, "gui-section"),
                            gui_section(2, "gui-section"),
                            gui_section(3, "gui-section"),
                        ],
                    ),
                    html_div(
                        className="scan-section",
                        children=[
                            html_h2("scan configuration", className="section-title"),
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
                            html_h1("Heatmap: ", className="heatmap-title"),
                            dcc_graph(id="heatmap-graph", className="heatmap-graph"),
                            dcc_graph(id="fft-graph", className="heatmap-graph"),
                            dcc_slider(id="fft-caxis-slider", min=0, max=200, step=0.1, value=100),
                            html_div(id="invs")
                        ],
                    ),
                ],
            ),
        ],
    )

# app.layout = html_div() do
#     dcc_graph(id="heatmap-graph"),
#     dcc_slider(id="caxis-slider", min=0, max=1, step=0.1, value=0.5)
# end

# callback!(
#     app,
#     Output("heatmap-graph", "figure"),
#     Output("fft-graph", "figure"),
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
#     return sim_plot(c0, l0, d, num_tls, c1, c2, c3, l1, l2, l3, cells1, cells2, cells3, start, stop, step)
# end

callback!(
    app,
    Output("invs", "children"),
    Input("run", "n_clicks"),
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
    State("stop", "value"),
    State("step", "value")
) do n_clicks, c0, l0, d, num_tls, c1, c2, c3, l1, l2, l3, cells1, cells2, cells3, start, stop, step
    global data
    global fftdata

    data = sim_plot(c0, l0, d, num_tls, c1, c2, c3, l1, l2, l3, cells1, cells2, cells3, start, stop, step)
    fftdata = ([abs.(fft(data[i,:])) for i in 1:size(data,1)])
    # fftdata = ([abs.(fft(data[:,i])) for i in 1:size(data,2)])
    
    return ""
end

callback!(
    app,
    Output("heatmap-graph", "figure"),
    Input("invs", "children")
) do children
    global data
    global ωs
    global dx

    xs = collect(1:size(data,1)) .* dx

    z = [data[i,:] for i in 1:size(data,1)];
    h = PlotlyJS.heatmap(x=xs, y=ωs./2π, z=z);

    return PlotlyJS.plot(h)
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

    xs = collect(1:size(fftdata,1)) .* dx

    fft_heatmap = PlotlyJS.heatmap(x=xs, y=ωs./2π, z=fftdata, zmin=0, zmax=caxis_value);

    return PlotlyJS.plot(fft_heatmap)
end


function sim_plot(c0, l0, d, num_tls, c1, c2, c3, l1, l2, l3, cells1, cells2, cells3, start, stop, step)
    global ωs
    global dx

    dx = d/num_tls
    ωs = collect(start:step:stop) .* 2π

    board = build_3_section_baord(l0, c0, l1, c1, l2, c2, l3, c3, dx, cells1, cells2, cells3, num_tls);


    data = sim_board(board, ωs)
    A = Matrix{Float64}(transpose(data));

    return A
end

run_server(app, "0.0.0.0", 8050, debug = true)