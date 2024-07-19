using DynamicExpressions: parse_expression
using OptiFloat: Candidate, logsample, optifloat!, infer_regimes, print_report
using Random

# FIXME: sometimes getting NaI in logsample
Random.seed!(1)

# Define expression. `features` contain a mapping from variable name to index in a sample
expr = :((b * (-1) - sqrt(b^2 - 4c)) / (2c))
T = Float16
dexpr, features = parse_expression(T, expr)


# Sample points to test expression. Each sample with have arity(dexpr) inputs.
# Only points that produce valid outputs are accepted as samples.
batchsize = 1000
points = logsample(dexpr, batchsize; eval_exact=false)

# Create first candidate and kick of optifloat main function
original = Candidate(dexpr, points)
candidates = [original]
optifloat!(candidates, points) # repeat this call to further improve new candidates

# infer good regimes for input variable `b`
regimes = infer_regimes(candidates, features["b"], points)

print_report(original, regimes)
