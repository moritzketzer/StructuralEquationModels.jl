using sem, Feather, ModelingToolkit, Statistics, LinearAlgebra,
    Optim, SparseArrays, Test

## Observed Data
three_path_dat = Feather.read("test/comparisons/three_path_dat.feather")
three_path_par = Feather.read("test/comparisons/three_path_par.feather")

semobserved = SemObsCommon(data = Matrix(three_path_dat))

loss = Loss([SemML(semobserved)])

diff = SemFiniteDiff(LBFGS(), Optim.Options())

## Model definition
@variables x[1:31]

S =[x[1]  0     0     0     0     0     0     0     0     0     0     0     0     0
    0     x[2]  0     0     0     0     0     0     0     0     0     0     0     0
    0     0     x[3]  0     0     0     0     0     0     0     0     0     0     0
    0     0     0     x[4]  0     0     0     x[15] 0     0     0     0     0     0
    0     0     0     0     x[5]  0     x[16] 0     x[17] 0     0     0     0     0
    0     0     0     0     0     x[6]  0     0     0     x[18] 0     0     0     0
    0     0     0     0     x[16] 0     x[7]  0     0     0     x[19] 0     0     0
    0     0     0     x[15] 0     0     0     x[8]  0     0     0     0     0     0
    0     0     0     0     x[17] 0     0     0     x[9]  0     x[20] 0     0     0
    0     0     0     0     0     x[18] 0     0     0     x[10] 0     0     0     0
    0     0     0     0     0     0     x[19] 0     x[20] 0     x[11] 0     0     0
    0     0     0     0     0     0     0     0     0     0     0     x[12] 0     0
    0     0     0     0     0     0     0     0     0     0     0     0     x[13] 0
    0     0     0     0     0     0     0     0     0     0     0     0     0     x[14]]

F =[1.0 0 0 0 0 0 0 0 0 0 0 0 0 0
    0 1 0 0 0 0 0 0 0 0 0 0 0 0
    0 0 1 0 0 0 0 0 0 0 0 0 0 0
    0 0 0 1 0 0 0 0 0 0 0 0 0 0
    0 0 0 0 1 0 0 0 0 0 0 0 0 0
    0 0 0 0 0 1 0 0 0 0 0 0 0 0
    0 0 0 0 0 0 1 0 0 0 0 0 0 0
    0 0 0 0 0 0 0 1 0 0 0 0 0 0
    0 0 0 0 0 0 0 0 1 0 0 0 0 0
    0 0 0 0 0 0 0 0 0 1 0 0 0 0
    0 0 0 0 0 0 0 0 0 0 1 0 0 0]

A =[0  0  0  0  0  0  0  0  0  0  0     1     0     0
    0  0  0  0  0  0  0  0  0  0  0     x[21] 0     0
    0  0  0  0  0  0  0  0  0  0  0     x[22] 0     0
    0  0  0  0  0  0  0  0  0  0  0     0     1     0
    0  0  0  0  0  0  0  0  0  0  0     0     x[23] 0
    0  0  0  0  0  0  0  0  0  0  0     0     x[24] 0
    0  0  0  0  0  0  0  0  0  0  0     0     x[25] 0
    0  0  0  0  0  0  0  0  0  0  0     0     0     1
    0  0  0  0  0  0  0  0  0  0  0     0     0     x[26]
    0  0  0  0  0  0  0  0  0  0  0     0     0     x[27]
    0  0  0  0  0  0  0  0  0  0  0     0     0     x[28]
    0  0  0  0  0  0  0  0  0  0  0     0     0     0
    0  0  0  0  0  0  0  0  0  0  0     x[29] 0     0
    0  0  0  0  0  0  0  0  0  0  0     x[30] x[31] 0]


S = sparse(S)

#F
F = sparse(F)

#A
A = sparse(A)

start_val = vcat(
    vec(var(Matrix(three_path_dat), dims = 1))./2,
    fill(0.05, 3),
    fill(0.0, 6),
    fill(1.0, 8),
    fill(0, 3)
    )



imply = ImplySymbolic(A, S, F, x, start_val)

model = Sem(semobserved, imply, loss, diff)

@benchmark solution = sem_fit(model)



model(vcat(solution.minimizer[1:29], 0.57, solution.minimizer[31]))

solution.minimum*75

@benchmark model.imply(start_val)

inverse = zeros(11,11)
pre = zeros(11,11)

@benchmark model(solution.minimizer)

par_order = [collect(21:34);  collect(15:20); 2;3; 5;6;7; collect(9:14)]

all(
    abs.(solution.minimizer - three_path_par.est[par_order]
        ) .< 0.05*abs.(solution.minimizer))

u = randn(10)
mat2 = model.imply.imp_cov

mat = copy(mat2)

@benchmark logdet($mat)
@benchmark logdet(cholesky($mat))

cholesky!(mat)



isposdef!(mat, zeros(11,11))
logdet(mat)




using LinearAlgebra, Optim

obs = abs.(randn(20))

obs = obs*transpose(obs)

obs .= abs.(obs)

function myf(par, A)
    A[1] = par[1]
    A[2] = par[2]
    A[3] = par[3]
    A[4] = par[1]
    if !isposdef(A)
        return Inf
    else
        cholesky!(A)
        F = logdet(A) + tr(obs*inv(A))
    end
end

A = ones(2,2)

mysol = optimize(par -> myf(par, A), [2.4,2.05, 2.05],
    Optim.Options(show_trace=true, extended_trace = true))

myf([2.4,2.05, 2.05], A)

mat = [2.4 2.05
        2.05 2.4]

logdet(mat)

logdet(cholesky(mat))

cholesky!(mat)

logdet(mat)

Inf > 0

a = isposdef!(mat)

@btime cholesky!(obs)

obs = copy(model.observed.obs_cov)

model.observed.obs_cov

obs
