* fake_poisson.do

clear

set obs 1000

g formal = _n*(_n<=500)+0*(_n>500)

