__precompile__()
module MatrixClient

# package code goes here
include("HttpApi.jl")
import .HttpApi
include("MatrixTypes.jl")
import .MatrixTypes

end # module
