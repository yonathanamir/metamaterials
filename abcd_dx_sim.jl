## Set up
using Plots
# plotlyjs()

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

## Manual Run
ωs = collect(1e9: 1e7: 14e9) * 2π 

d = 0.009
number_of_tls = 20
dx = d/number_of_tls
num_cells = 10

L = 6.8e-9
C = 2e-12
ω1 = 1.34e9 * 2π
ω2 = 2.26e9 * 2π

L₀ = 1/(ω1^2*C*d)
C₀ = 1/(ω2^2*L*d)

board = build_simple_board(L₀, C₀, L, C, dx, num_cells, number_of_tls)
sim_results = sim_board(board, ωs)
display(heatmap(1:size(sim_results)[2], ωs/2π, sim_results, title="L₀=$L₀, C₀=$C₀"))
gui()

## Resonator

num_cells_1 = 2
num_cells_2 = 4


L₁ = 6.8e-9
C₁ = 2e-12
L₂ = L₁/100
C₂ = C₁/100

board = build_resonator(L₀, C₀, L₁, C₁, L₂, C₂, dx, num_cells_1, num_cells_2, number_of_tls)
sim_results = sim_board(board, ωs)
display(heatmap(1:size(sim_results)[2], ωs/2π, sim_results, title="Resonator"))
gui()

## Permutations
# Permute omegas
function permute_array(arr)
    permutations = []
    for i in 1:length(arr)
        for j in 1:length(arr)
            if i != j
                push!(permutations, (arr[i], arr[j]))
            end
        end
    end
    return permutations
end

# tagged_ωs = [739e6, 824.1e6, 950e6, 1.134e9, 1.34e9, 2.26e9]
tagged_ωs = [1.34e9, 2.26e9]

ωs = collect(1e9: 1e7: 6e9) * 2π 

d = 0.009
number_of_tls = 20
dx = d/number_of_tls

L = 6.8e-9
C = 2e-12

num_cells = 10

for pair in permute_array(tagged_ωs)
    ω1, ω2 = pair
    ω1 *= 2π
    ω2 *= 2π

    text_ω1 = round(ω1/2π, digits=2)
    text_ω2 = round(ω2/2π, digits=2)

    print("Simulating ω1=$text_ω1, ω2=$text_ω2... ")

    L₀ = 1/(ω1^2*C*d)
    C₀ = 1/(ω2^2*L*d)

    print("L₀=$L₀, C₀=$C₀ ")

    board = build_simple_board(L₀, C₀, L, C, dx, num_cells, number_of_tls)
    sim_results = sim_board(board, ωs)    

    # sim_results = sim_steps(L₀, C₀, L, C, dx, num_cells, number_of_tls, ωs)
    # display(heatmap(z=sim_results, y=ωs/2π, title="ω1=$text_ω1, ω2=$text_ω2"))
    display(heatmap(1:size(sim_results)[2], ωs/2π, sim_results, title="ω1=$text_ω1, ω2=$text_ω2"))
    println("Done!")
end

gui()
