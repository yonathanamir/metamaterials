using Plots

struct Possibility
    L::Float64
    C::Float64
    f1::Float64
    f2::Float64
    gap::Float64
    id::Int64
end

struct Section
    L::Float64
    C::Float64
    num_cells::Int64
end

function permutate_possibilities(d, L₀, C₀, min_f=1.5e9, min_gap=0.5e9, max_gap=5e9)
    possibilities = Possibility[]
    capacitance_array = [0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.5, 1.8, 2.0, 2.2, 2.4, 2.7, 3.0, 3.3, 3.6, 3.9, 4.3, 4.7, 5.1, 5.6, 6.2, 6.8]
    capacitance_array *= 1e-12

    inductance_array = [1.0, 1.5, 1.8, 2.2, 2.7, 3.3, 3.9, 4.7, 5.6, 6.8, 8.2, 10.0, 12.0, 15.0, 18.0, 22.0, 27.0, 33.0, 39.0, 47.0, 56.0, 68.0, 82.0, 100.0, 120.0, 150.0, 180.0, 220.0]
    inductance_array *= 1e-9

    index = 1
    # loop through each capacitance value and inductance value
    for C in capacitance_array
        for L in inductance_array
            # calculate the first frequency and its corresponding refractive index
            f1 = sqrt(1/(d*L₀*C))/2π
            f2 = sqrt(1/(d*C₀*L))/2π
            
            p = Possibility(L, C, f1, f2, f2-f1, index)
            if min_gap < p.gap < max_gap && p.f1 > min_f
                push!(possibilities, p)
            end
            index += 1
        end
    end

    sorted = sort(possibilities, by = p -> p.gap, rev=true)
    return sorted
end

function get_ωs(d, L₀, C₀, L, C)
    ω1 = 1/(2π*sqrt(L₀*C*d))
    ω2 = 1/(2π*sqrt(C₀*L*d))

    return ω1, ω2
end

function z_capacitor(C)
    function _inner(ω)
        return 1/(im*ω*C)
    end

    return _inner
end

function z_inductor(L)
    function _inner(ω)
        return im*ω*L
    end

    return _inner
end

function series_element(z_func) 
    function _inner(ω)
        Z = z_func(ω)
        return [
            1 Z;
            0 1
        ]
    end

    return _inner
end

function shunt_element(z_func) 
    function _inner(ω)
        Z = z_func(ω)
        return [
            1 0;
            1/Z 1
        ]
    end

    return _inner
end

function r_value(x)
    return log(abs(x[1])) 
    # return real((x[1] + 50*x[2])/(x[1] - 50*x[2]))
end

function build_simple_board(L₀, C₀, L, C, dx, num_cells, number_of_tls)
    L_element = shunt_element(z_inductor(L))
    C_element = series_element(z_capacitor(C))
    L₀_element = series_element(z_inductor(L₀*dx))
    C₀_element = shunt_element(z_capacitor(C₀*dx))

    cell = vcat([L_element, C_element], repeat([L₀_element, C₀_element], number_of_tls))
    board = repeat(cell, num_cells)
    return board
end

function build_resonator(L₀, C₀, L₁, C₁, L₂, C₂, dx, num_cells_1, num_cells_2, number_of_tls)
    L₀_element = series_element(z_inductor(L₀*dx))
    C₀_element = shunt_element(z_capacitor(C₀*dx))
    L₁_element = shunt_element(z_inductor(L₁))
    C₁_element = series_element(z_capacitor(C₁))
    L₂_element = shunt_element(z_inductor(L₂))
    C₂_element = series_element(z_capacitor(C₂))


    cell1 = vcat([L₁_element, C₁_element], repeat([L₀_element, C₀_element], number_of_tls))
    cell2 = vcat([L₂_element, C₂_element], repeat([L₀_element, C₀_element], number_of_tls))
    board = vcat(repeat(cell1, num_cells_1), repeat(cell2, num_cells_2), repeat(cell1, num_cells_1))
    return board
end

function build_gap_change(L₀, C₀, L₁, C₁, L₂, C₂, dx, num_cells_1, num_cells_2, number_of_tls)
    L₀_element = series_element(z_inductor(L₀*dx))
    C₀_element = shunt_element(z_capacitor(C₀*dx))
    L₁_element = shunt_element(z_inductor(L₁))
    C₁_element = series_element(z_capacitor(C₁))
    L₂_element = shunt_element(z_inductor(L₂))
    C₂_element = series_element(z_capacitor(C₂))


    cell1 = vcat([L₁_element, C₁_element], repeat([L₀_element, C₀_element], number_of_tls))
    cell2 = vcat([L₂_element, C₂_element], repeat([L₀_element, C₀_element], number_of_tls))
    board = vcat(repeat(cell1, num_cells_1), repeat(cell2, num_cells_2))
    return board
end

function build_3_section_baord(L₀, C₀, L₁, C₁, L₂, C₂, L₃, C₃, dx, num_cells_1, num_cells_2, num_cells_3, number_of_tls)
    L₀_element = series_element(z_inductor(L₀*dx))
    C₀_element = shunt_element(z_capacitor(C₀*dx))
    
    L₁_element = shunt_element(z_inductor(L₁))
    C₁_element = series_element(z_capacitor(C₁))
    cell1 = vcat([L₁_element, C₁_element], repeat([L₀_element, C₀_element], number_of_tls))
    
    L₂_element = shunt_element(z_inductor(L₂))
    C₂_element = series_element(z_capacitor(C₂))
    cell2 = vcat([L₂_element, C₂_element], repeat([L₀_element, C₀_element], number_of_tls))

    L₃_element = shunt_element(z_inductor(L₃))
    C₃_element = series_element(z_capacitor(C₃))
    cell3 = vcat([L₃_element, C₃_element], repeat([L₀_element, C₀_element], number_of_tls))


    board = vcat(repeat(cell1, num_cells_1), repeat(cell2, num_cells_2), repeat(cell3, num_cells_3))
    return board
end

function build_board(L₀, C₀, sections::Vector{Section}, dx, number_of_tls)
    cells = []

    L₀_element = series_element(z_inductor(L₀*dx))
    C₀_element = shunt_element(z_capacitor(C₀*dx))

    for s in sections
        L_element = shunt_element(z_inductor(s.L))
        C_element = series_element(z_capacitor(s.C))
        cell = vcat([L_element, C_element], repeat([L₀_element, C₀_element], number_of_tls))

        push!(cells, repeat(cell, s.num_cells))
    end

    board = reduce(vcat, cells)
    println(size(board))
    return board
end

function sim_board(board, ωs)
    all_r_values = []
    probe = [1, 1/50]

    for ω in ωs
        global probe
        probe = [1, 1/50]
        ω_r_values = []
        for step in reverse(board)
            global probe
            abcd = step(ω)
            probe = abcd*probe
            append!(ω_r_values, r_value(probe))
        end
        append!(all_r_values, ω_r_values)
    end

    data = transpose(reshape(all_r_values, length(board), length(ωs)))[:,end:-1:1]
    return data
end