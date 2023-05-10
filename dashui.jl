using Dash
using PlotlyJS

include("./abcd_sim.jl")
include("./components.jl")

app = dash(assets_folder="./assests")

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
                                value=4000000000,
                                type="number",
                                className="input-field"
                            ),
                            "stop:", dcc_input(
                                id="stop",
                                value=84000000000,
                                type="number",
                                className="input-field"
                            ),
                            "step:", dcc_input(
                                id="step",
                                value=300000000,
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
                        ],
                    ),
                ],
            ),
        ],
    )

callback!(
    app,
    Output("heatmap-graph", "figure"),
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
    return sim_plot(c0, l0, d, num_tls, c1, c2, c3, l1, l2, l3, cells1, cells2, cells3, start, stop, step)
end

function sim_plot(c0, l0, d, num_tls, c1, c2, c3, l1, l2, l3, cells1, cells2, cells3, start, stop, step)
    board = build_3_section_baord(l0, c0, l1, c1, l2, c2, l3, c3, d/num_tls, cells1, cells2, cells3, num_tls);
    data = sim_board(board, collect(start:step:stop))
    A = data;
    return PlotlyJS.plot(PlotlyJS.heatmap(z=[A[i,:] for i in 1:size(A,1)]))
end

run_server(app, "0.0.0.0", 8050, debug = true)