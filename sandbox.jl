include("./abcd_sim.jl")

ωs = collect(0.5e9: 1e7: 7e9) * 2π 

## Manual Run

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
# display(heatmap(1:size(sim_results)[2], ωs/2π, sim_results, title="L₀=$L₀, C₀=$C₀"))
display(heatmap(1:size(sim_results)[2], ωs/2π, sim_results))
gui()

## 2 Parts
# print("Insert title: ")
# title = readline()
d = 0.009
number_of_tls = 20
dx = d/number_of_tls

num_cells_1 = 5
num_cells_2 = 5

L₀ = 7.84e-7
C₀ = 8.1e-11

L₁ = 1e-9
C₁ = 1.5-12
L₂ = 8.2e-9
C₂ = 1.5e-12

# title="High to Low"
# board = build_gap_change(L₀, C₀, L₁, C₁, L₂, C₂, dx, num_cells_1, num_cells_2, number_of_tls)

title="Low to High"
board = build_gap_change(L₀, C₀, L₂, C₂, L₁, C₁, dx, num_cells_1, num_cells_2, number_of_tls)

sim_results = sim_board(board, ωs)
display(heatmap(1:size(sim_results)[2], ωs/2π, sim_results, title=title))
# gui()

## 3 Parts
d = 0.009
number_of_tls = 20
dx = d/number_of_tls

num_cells_1 = 3
num_cells_2 = 3

L₀ = 7.84e-7
C₀ = 8.1e-11

L₁ = 1e-9
C₁ = 1.5-12
L₂ = 8.2e-9
C₂ = 1.5e-12

# title="3 Parts High Low High"
# board = build_resonator(L₀, C₀, L₁, C₁, L₂, C₂, dx, num_cells_1, num_cells_2, number_of_tls)

title="3 Parts Low High Low"
board = build_resonator(L₀, C₀, L₂, C₂, L₁, C₁, dx, num_cells_1, num_cells_2, number_of_tls)

sim_results = sim_board(board, ωs)
display(heatmap(1:size(sim_results)[2], ωs/2π, sim_results, title=title))


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
