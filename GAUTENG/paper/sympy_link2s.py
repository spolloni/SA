

import matplotlib.pyplot as plt
from sympy import *
#init_printing()

u1,u2,u3,u4,u5,a1,a2,a3,a4,a5,z,k,z1,z2,z3,z4,z5,k1,k2,k3,k4,k5,N1,N2,N3,N4,N5,N,g = symbols('u1,u2,u3,u4,u5,a1,a2,a3,a4,a5,z,k,z1,z2,z3,z4,z5,k1,k2,k3,k4,k5,N1,N2,N3,N4,N5,N,g')

u1i,u2i,u3i,u4i,u5i,a1i,a2i,a3i,a4i,a5i,zi,ki,z1i,z2i,z3i,z4i,z5i,k1i,k2i,k3i,k4i,k5i,N1i,N2i,N3i,N4i,N5i = symbols('u1i,u2i,u3i,u4i,u5i,a1i,a2i,a3i,a4i,a5i,zi,ki,z1i,z2i,z3i,z4i,z5i,k1i,k2i,k3i,k4i,k5i,N1i,N2i,N3i,N4i,N5i')

u1   = - z1 - k*N1 - g*2*N2i
u2   = - z2 - k*N2 - g*(N1i+N3i)
u3   = - z3 - k*N3 - g*2*N2i

u1i  = - z1i - ki*N1i - g*2*N2i
u2i  = - z2i - ki*N2i - g*(N1i+N3i)
u3i  = - z3i - ki*N3i - g*2*N2i

nn = N1+N2+N3 + N1i+N2i+N3i - N

#nnk = N1+N2+N3  - N
#nni = N1i+N2i+N3i - N

sols =  solve([u1-u2,u2-u3,u1i-u2i,u2i-u3i,u1-u1i,nn],[N1,N2,N3,N1i,N2i,N3i],set=True)

print sols 

sols = list(sols[1])
sols = sols[0]

#print sols
n1e = sols[0]
n1ie = sols[1]

n2e = sols[2]
n2ie = sols[3]

n3e = sols[4]
n3ie = sols[5]


subscat = [(z1,1),(z2,1),(z3,1),(k,1),(z1i,2),(z2i,1),(z3i,1),(ki,1),(g,.2),(N,20)]

r1 = n1e.subs(subscat)
r2 = n2e.subs(subscat)
r3 = n3e.subs(subscat)

r1i = n1ie.subs(subscat)
r2i = n2ie.subs(subscat)
r3i = n3ie.subs(subscat)


y = [r1,r2,r3]

print y

x = [1,2,3]

plt.plot(x, y, 'ro')
#plt.axis([0, 6, 0, 20])
plt.show()



#pprint(sols)
# budget constraint
#tc = (lf*r + li*r + pi*mi + pf*mf)

#obj = tc + lam*(y - (f + i))

#obj = f + lam*(y-r*l-pf*mf)
#sols = solve([diff(obj,mf),diff(obj,l),diff(obj,lam)],[mf,l,lam],set=True)



