using Plots


function gen_γ_Z₀(R, G, C, L, d)
    function _inner(ω)
        # a₁ = (L₀ - 1/(ω^2*C*d))
        # a₂ = (C₀ - 1/(ω^2*L*d))
        a₁ = (R+im*ω*L)
        a₂ = (G+im*ω*C)

        kₘ = ω * sqrt(a₁*a₂)
        Z₀ = sqrt(a₁/a₂)

        return im * kₘ, Z₀
    end

    return _inner
end


function abcd_transmission_line(L₀, C₀, C, L, d, l)
    gamma_z_func = gen_γ_Z₀(L₀, C₀, C, L, d)

    function _inner(ω)
        γ, Z = gamma_z_func(ω)

        return [
            cos(γ*l) im*Z*sin(γ*l);
            (im/Z)*sin(γ*l) cos(γ*l)
        ]
    end

    return _inner
end


function abcd_series_element(z_func)
    function _inner(ω)
        Z = z_func(ω)
        return [
            1 Z;
            0 1
        ]
    end

    return _inner
end


function abcd_shunt_element(z_func)
    function _inner(ω)
        Z = z_func(ω)
        return [
            1 0;
            1/Z 1
        ]
    end

    return _inner
end


function impedence_resistor(R)
    function _inner(ω)
        return R
    end

    return _inner
end


function impedence_capacitator(C)
    function _inner(ω)
        return 1/(im*ω*C)
    end

    return _inner
end


function impedence_inductor(L)
    function _inner(ω)
        return im*ω*L
    end

    return _inner
end


# function abcd_clrh_cell(L₀, C₀, C, L, d)
#     tl1 = abcd_transmission_line(L₀, C₀, C, L, d, 3*d/4)
#     inductor = abcd_shunt_element(impedence_inductor(L))
#     tl2 = abcd_transmission_line(L₀, C₀, C, L, d, d/4)
#     capacitator = abcd_series_element(impedence_capacitator(C))

#     function _inner(ω)
#         tl1_ω = tl1(ω)
#         inductor_ω = inductor(ω)
#         tl2_ω = tl2(ω)
#         capacitator_ω = capacitator(ω)

#         return tl1_ω * inductor_ω * tl2_ω * capacitator_ω
#     end

#     return _inner
# end


function abcd_clrh_cell(L₀, C₀, C, L, d)
    inductor = abcd_series_element(impedence_inductor(L₀*d))
    inductor_ground = abcd_shunt_element(impedence_inductor(L*d))
    capacitator = abcd_series_element(impedence_capacitator(C*d))
    capacitator_ground = abcd_shunt_element(impedence_capacitator(C₀*d))

    function _inner(ω)
        is = inductor(ω)
        ig = inductor_ground(ω)
        cs = capacitator(ω)
        cg = capacitator_ground(ω)

        return is * cs * ig * cg
    end

    return _inner
end


function abcd_metamaterial_system(L₀, C₀, C, L, d, num_cells)
    function _inner(ω)
        sys = ones(2, 2)
        for _ in collect(1:num_cells)
            sys *= abcd_clrh_cell(L₀, C₀, C, L, d)(ω)
        end
        return sys
    end

    return _inner
end


function abcd_sim(ωs, abcd_system)
    end_vals = [1, 1/50]

    # unpack(x) = (x[1] + 50*x[2])/(x[1] - 50*x[2])

    return [
        unpack(real(abcd_system(ω) * end_vals)) for ω in ωs
    ]
end


function unpack(x)
    return (x[1] + 50*x[2])/(x[1] - 50*x[2])
end


L₀ = 7.9
C₀ = 84.5
L = 5.6e-9
C = 1e-12
d = 1e-3

# ωs = collect(1e8: 1e6: 10e9)
ω = 3e9

abcd_system = abcd_metamaterial_system(L₀, C₀, C, L, d, 9)(ω)

end_vals = [10e100, 10e100/50]
init_vals = abcd_system * end_vals

res = unpack(init_vals)

# sim_results = abcd_sim(ωs, abcd_system)

# scatter(ωs, round.(sim_results*1000000))
