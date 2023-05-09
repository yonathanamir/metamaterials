using Dash

include("./omegas.jl")

function gui_section(id)
    return html_div(
        children = [
            "Section $(id): ",
            "C ",
            dcc_dropdown(
                        id = "c$(id)",
                        options = [(label = "$(x*1e12) pF", value=x) for x in capacitance_array],
                    ),
            "L ",
            dcc_dropdown(
                        id = "l$(id)",
                        options = [(label = "$(x*1e9) nH", value=x) for x in inductance_array],
                    ),
            "cells ",
            dcc_input(id="cells$(id)", value=0, type="number")
        ]
    )
end