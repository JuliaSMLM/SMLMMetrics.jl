using GLMakie

A = zeros(256, 256)

for i in 1:256
    for j in 1:256
        if abs.((((i - 128))^2 + (j - 128) ^2) - 10^2) <= 20
            A[i,j] = 1
        end
    end
end

fig = GLMakie.Figure(resolution=(1000,1000))
ax = GLMakie.Axis(fig[1,1], aspect = DataAspect())
heatmap!(ax, A)
GLMakie.activate!(inline=false)
display(fig)
