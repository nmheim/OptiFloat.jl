using DynamicExpressions: parse_expression
using OptiFloat: Candidate, logsample, search_candidates!, infer_regimes, print_report
using Random

# FIXME: sometimes getting NaI in logsample
Random.seed!(1)

# Define expression. `features` contain a mapping from variable name to index in a sample
expr = :(x * (-1) - sqrt(x^2 - 1))
T = Float16
dexpr, features = parse_expression(T, expr)

# Sample points to test expression. Each sample with have arity(dexpr) inputs.
# Only points that produce valid outputs are accepted as samples.
batchsize = 1000
points = logsample(dexpr, batchsize; eval_exact=false)

# Create first candidate and kick of optifloat main function
original = Candidate(dexpr, points)
candidates = [original]
search_candidates!(candidates, points) # repeat this call to further improve new candidates

# infer good regimes for input variable `x`
regimes = infer_regimes(candidates, features["x"], points)

print_report(original, regimes)

################################################################################
# For a different expression
using OptiFloat
batchsize = 1000
T = Float16
expr = :(sqrt(x + 1) - sqrt(x))

dexpr, features = parse_expression(T, expr)
points = logsample(dexpr, batchsize; eval_exact=false)
original = Candidate(dexpr, points)
candidates = [original]
search_candidates!(candidates, points)
regimes = infer_regimes(candidates, features["x"], points; infimum=T(0))
print_report(original, regimes)
