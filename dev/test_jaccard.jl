using Revise
using SMLMMetrics
MT = SMLMMetrics
using CairoMakie

# Generate some coorindates
n=70  #number of true emitters
m=50 # number of found emitters
d=3
x=5*rand(d,n)
x̂=5*rand(d,m)

# Match Coordinates
assignment = MT.match(x, x̂, [.1, .1, .5])

n_matched=sum(assignment.>0)
@info "found $(n_matched) matches"

#  Plot the matches
x_matched=x[:,assignment.>0]
x̂_matched=x̂[:,assignment[assignment.>0]]

fig=scatter(x,color=:red)
scatter!(x̂,color=:green)
if n_matched>0
    for i in 1:n_matched
        lines!([x̂_matched[1,i],x_matched[1,i]],[x̂_matched[2,i],x_matched[2,i]],
            [x̂_matched[3,i],x_matched[3,i]])
    end
end
fig
 
# Calculate the JI 
jac = MT.jaccard(x, x̂, [.1, .1, .5])

# Calculate the RMSE 


