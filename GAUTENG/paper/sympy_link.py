
from sympy import *
#init_printing()

z,k,z1,z2,z3,z4,k1,k2,k3,k4,N1,N2,N3,N4,N,g = symbols('z,k,z1,z2,z3,z4,k1,k2,k3,k4,N1,N2,N3,N4,N,g')

r1 = z1+k*N1 - g*N2
r2 = z2+k*N2 - g*(N1+N2)
r3 = z3+k*N3 - g*(N2+N4)
r4 = z4+k*N4 - g*N3

nn = N1+N2+N3+N4 - N

sols =  solve([r1-r2,r2-r3,r3-r4,nn],[N1,N2,N3,N4],set=True)
print sols

#pprint(sols)
# budget constraint
#tc = (lf*r + li*r + pi*mi + pf*mf)

#obj = tc + lam*(y - (f + i))

#obj = f + lam*(y-r*l-pf*mf)
#sols = solve([diff(obj,mf),diff(obj,l),diff(obj,lam)],[mf,l,lam],set=True)



