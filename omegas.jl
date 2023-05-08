struct Possibility
    L::Float64
    C::Float64
    f1::Float64
    f2::Float64
    gap::Float64
end

capacitance_array = [0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.5, 1.8, 2.0, 2.2, 2.4, 2.7, 3.0, 3.3, 3.6, 3.9, 4.3, 4.7, 5.1, 5.6, 6.2, 6.8]
capacitance_array *= 1e-12

inductance_array = [1.0, 1.5, 1.8, 2.2, 2.7, 3.3, 3.9, 4.7, 5.6, 6.8, 8.2, 10.0, 12.0, 15.0, 18.0, 22.0, 27.0, 33.0, 39.0, 47.0, 56.0, 68.0, 82.0, 100.0, 120.0, 150.0, 180.0, 220.0]
inductance_array *= 1e-9

d = 9e-3
L0 = 7.837e-7
C0 = 8.103e-11
c = 299792458  # speed of light in m/s

possibilities = Possibility[]

# loop through each capacitance value and inductance value
for C1 in capacitance_array
    for L1 in inductance_array
        # calculate the first frequency and its corresponding refractive index
        w11 = sqrt(1/(d*L0*C1))/2π
        w12 = sqrt(1/(d*C0*L1))/2π
        # n1 = round(c^2 * sqrt((L0-(1/(w1^2*C1*d))) * (C0-(1/(w1^2*L1*d)))), digits=3)
        
        p = Possibility(L1, C1, w11, w12, w12-w11)
        if 0.5e9 < p.gap < 5e9 && p.f1 > 1.5e9
            push!(possibilities, p)
        end
        # for C2 in capacitance_array
        #     for L2 in inductance_array
        #         # calculate the second frequency and its corresponding refractive index
        #         w21 = sqrt(1/complex(d*L0*C2))
        #         w22 = sqrt(1/complex(d*C0*L2))
        #         n2 = round(c^2 * sqrt((L0-(1/(w2^2*C2*d))) * (C0-(1/(w2^2*L2*d)))), digits=3)
                

        #         # print the collection of capacitance, inductance, frequency, and refractive index values
        #         println("C1: $C1, C2: $C2, L1: $L1, L2: $L2, w1: $w1, w2: $w2, n1: $n1, n2: $n2")
        #     end
        # end
    end
end

sorted = sort(possibilities, by = p -> p.gap, rev=true)
