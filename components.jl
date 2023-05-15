using Dash

# include("./omegas.jl")

# Base values from experiment
capacitance_array = [0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.5, 1.8, 2.0, 2.2, 2.4, 2.7, 3.0, 3.3, 3.6, 3.9, 4.3, 4.7, 5.1, 5.6, 6.2, 6.8]
capacitance_array_factor = 1e-12

inductance_array = [1.0, 1.5, 1.8, 2.2, 2.7, 3.3, 3.9, 4.7, 5.6, 6.8, 8.2, 10.0, 12.0, 15.0, 18.0, 22.0, 27.0, 33.0, 39.0, 47.0, 56.0, 68.0, 82.0, 100.0, 120.0, 150.0, 180.0, 220.0]
inductance_array_factor = 1e-9

function gui_section(id, class_name)
    return html_div(
        className = class_name,
        children = [
            "Section $(id): ",
            "C ",
            dcc_dropdown(
                        id = "c$(id)",
                        options = [(label = "$(x) pF", value=x*capacitance_array_factor) for x in capacitance_array],
                    ),
            "L ",
            dcc_dropdown(
                        id = "l$(id)",
                        options = [(label = "$(x) nH", value=x*inductance_array_factor) for x in inductance_array],
                    ),
            "cells ",
            dcc_input(id="cells$(id)", value=0, type="number", className="input-field")
        ]
    )
end