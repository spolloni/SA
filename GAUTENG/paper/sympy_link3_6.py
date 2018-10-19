
import pickle
import matplotlib.pyplot as plt
from sympy import *
#init_printing()


save_sols = 1

spot = '/Users/williamviolette/southafrica/Generated/GAUTENG/'

u1,u2,u3,u4,u5,u6,a1,a2,a3,a4,a5,a6,z,k,z1,z2,z3,z4,z5,z6,k1,k2,k3,k4,k5,k6,N1,N2,N3,N4,N5,N6,N,g = symbols('u1,u2,u3,u4,u5,u6,a1,a2,a3,a4,a5,a6,z,k,z1,z2,z3,z4,z5,z6,k1,k2,k3,k4,k5,k6,N1,N2,N3,N4,N5,N6,N,g')

u1i,u2i,u3i,u4i,u5i,u6i,a1i,a2i,a3i,a4i,a5i,a6i,zi,ki,z1i,z2i,z3i,z4i,z5i,z6i,k1i,k2i,k3i,k4i,k5i,k6i,N1i,N2i,N3i,N4i,N5i,N6i,gd = symbols('u1i,u2i,u3i,u4i,u5i,u6i,a1i,a2i,a3i,a4i,a5i,a6i,zi,ki,z1i,z2i,z3i,z4i,z5i,z6i,k1i,k2i,k3i,k4i,k5i,k6i,N1i,N2i,N3i,N4i,N5i,N6i,gd')

# u1   = - z1 - k*N1 - g*2*N2i         - gd*N1i
# u2   = - z2 - k*N2 - g*(N1i+N3i)     - gd*N2i
# u3   = - z3 - k*N3 - g*(N2i+N4i)     - gd*N3i
# u4   = - z4 - k*N4 - g*(N3i+N5i)     - gd*N4i
# u5   = - z5 - k*N5 - g*2*N4i         - gd*N5i

u1   = - z1 - k*N1 - g*2*N2i        
u2   = - z2 - k*N2 - g*(N1i+N3i)    
u3   = - z3 - k*N3 - g*(N2i+N4i)   
u4   = - z4 - k*N4 - g*(N3i+N5i)    
u5   = - z5 - k*N5 - g*(N4i+N6i)    
u6   = - z6 - k*N6 - g*2*N5i        

u1i  = - z1i - ki*N1i - g*2*N2i      
u2i  = - z2i - ki*N2i - g*(N1i+N3i)  
u3i  = - z3i - ki*N3i - g*(N2i+N4i)  
u4i  = - z4i - ki*N4i - g*(N3i+N5i)  
u5i  = - z5i - ki*N5i - g*(N4i+N6i)  
u6i  = - z6i - ki*N6i - g*2*N5i


nn = N1+N2+N3+N4+N5+N6 + N1i+N2i+N3i+N4i+N5i+N6i - N

if save_sols == 1:
	sols =  solve([u1-u2,u2-u3,u3-u4,u4-u5,u6-u5,u1i-u2i,u2i-u3i,u3i-u4i,u5i-u4i,u6i-u5i,u1-u1i,nn],[N1,N2,N3,N4,N5,N6,N1i,N2i,N3i,N4i,N5i,N6i],set=True)
	with open(spot+'eq.txt', "w") as outf:
	    pickle.dump(sols, outf)

with open(spot+'eq.txt') as inf:
    sols = pickle.load(inf)

sols = list(sols[1])
sols = sols[0]

subscat = [(z1,1),(z2,1),(z3,1),(z4,1),(z5,1),(z6,1),(k,1),(z1i,1),(z2i,2),(z3i,1),(z4i,1),(z5i,1),(z6i,1),(ki,1),(g,.2),(gd,.1),(N,20)]
sols = [x.subs(subscat) for x in sols]

y = sols[::2]
yi = sols[1::2]

x = [1,2,3,4,5,6]

plt.plot(x, y)
plt.plot(x, yi)
#plt.axis([0, 6, 0, 20])
plt.show()



#pprint(sols)
# budget constraint
#tc = (lf*r + li*r + pi*mi + pf*mf)

#obj = tc + lam*(y - (f + i))

#obj = f + lam*(y-r*l-pf*mf)
#sols = solve([diff(obj,mf),diff(obj,l),diff(obj,lam)],[mf,l,lam],set=True)



