using SMLMMetrics
using Documenter

DocMeta.setdocmeta!(SMLMMetrics, :DocTestSetup, :(using SMLMMetrics); recursive=true)

makedocs(;
    modules=[SMLMMetrics],
    authors="klidke@unm.edu",
    repo="https://github.com/JuliaSMLM/SMLMMetrics.jl/blob/{commit}{path}#{line}",
    sitename="SMLMMetrics.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaSMLM.github.io/SMLMMetrics.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaSMLM/SMLMMetrics.jl",
    devbranch="main",
)
