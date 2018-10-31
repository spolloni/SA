
from operator import add
import pickle
import matplotlib.pyplot as plt
from sympy import *
#init_printing()

save_sols = 0

spot = '/Users/williamviolette/southafrica/Generated/GAUTENG/'
loc  = "/Users/williamviolette/southafrica/Code/GAUTENG/paper/figures/"

##### SOLVE PROBLEM #####
u1,u2,u3,u4,u5,a1,a2,a3,a4,a5,z,k,z1,z2,z3,z4,z5,k1,k2,k3,k4,k5,N1,N2,N3,N4,N5,N,g,gd = symbols('u1,u2,u3,u4,u5,a1,a2,a3,a4,a5,z,k,z1,z2,z3,z4,z5,k1,k2,k3,k4,k5,N1,N2,N3,N4,N5,N,g,gd')

u1i,u2i,u3i,u4i,u5i,a1i,a2i,a3i,a4i,a5i,zi,ki,z1i,z2i,z3i,z4i,z5i,k1i,k2i,k3i,k4i,k5i,N1i,N2i,N3i,N4i,N5i = symbols('u1i,u2i,u3i,u4i,u5i,a1i,a2i,a3i,a4i,a5i,zi,ki,z1i,z2i,z3i,z4i,z5i,k1i,k2i,k3i,k4i,k5i,N1i,N2i,N3i,N4i,N5i')

u1   = - z1  - k*N1   - g*2*N2i     - gd*N1i
u2   = - z2  - k*N2   - g*(N1i+N3i) - gd*N2i
u3   = - z3  - k*N3   - g*(N2i+N4i) - gd*N3i
u4   = - z4  - k*N4   - g*2*N3i     - gd*N4i

u1i  = - z1i - ki*N1i  - g*2*N2i      - gd*N1i
u2i  = - z2i - ki*N2i  - g*(N1i+N3i)  - gd*N2i
u3i  = - z3i - ki*N3i  - g*(N2i+N4i)  - gd*N3i
u4i  = - z4i - ki*N4i  - g*2*N3i      - gd*N4i

nn   = N1+N2+N3+N4 + N1i+N2i+N3i+N4i - N

if save_sols == 1:
	sols =  solve([u1-u2,u2-u3,u3-u4,u1i-u2i,u2i-u3i,u3i-u4i,u1-u1i,nn],[N1,N2,N3,N4,N1i,N2i,N3i,N4i],set=True)
	with open(spot+'eq3.txt', "w") as outf:
	    pickle.dump(sols, outf)


##### MAKE GRAPHS #####

with open(spot+'eq3.txt') as inf:
    sols = pickle.load(inf)

sols = list(sols[1])
sols = sols[0]

### PRE
subscat = [(z1,2),(z2,1),(z3,1),(z4,1),(k,1),  (z1i,1.5),(z2i,1),(z3i,1),(z4i,1),  (ki,1),(g,.2),(gd,.4),(N,20)]
sols1 = [x.subs(subscat) for x in sols]

### POST
subscat = [(z1,.5),(z2,1),(z3,1),(z4,1),(k,1),  (z1i,3),(z2i,1),(z3i,1),(z4i,1),  (ki,1),(g,.2),(gd,.4),(N,20)]
sols2 = [x.subs(subscat) for x in sols]

xr = range(1,len(sols1[::2])+1)


yt = [1.5, 2.5, 3.5, 3.8]
## UNCONSTRUCTED PRE POST

z1_pre   = 2
z1i_pre  = .5

z1_post  = 2
z1i_post = .5

N_pre    = 20
N_post   = 25

g_set  = .4 # externality strength
gd_set = .5

subscat = [(z1,z1_pre),(z2,1),(z3,1),(z4,1),(k,1),  (z1i,z1i_pre),(z2i,1),(z3i,1),(z4i,1),  (ki,1),(g,g_set),(gd,gd_set),(N,N_pre)]
solspre = [x.subs(subscat) for x in sols]
subscat = [(z1,z1_post),(z2,1),(z3,1),(z4,1),(k,1),  (z1i,z1i_post),(z2i,1),(z3i,1),(z4i,1),  (ki,1),(g,g_set),(gd,gd_set),(N,N_post)]
solspost = [x.subs(subscat) for x in sols]

fig = plt.figure()
ax1 = plt.subplot(111)
ax1.plot(xr,solspre[::2],label='Pre  N: '+str(N_pre)+' Z For: '+str(z1_pre)+' Z Inf: '+str(z1i_pre))
ax1.plot(xr,solspost[::2],label='Post  N: '+str(N_post)+' Z For: '+str(z1_post)+' Z Inf: '+str(z1i_post))
ax1.set_title('Formal Unconstructed')
ax1.set_yticks(yt)
ax1.legend()
fig.savefig(loc+'unconstructed_formal.pdf')

fig = plt.figure()
ax1 = plt.subplot(111)
ax1.plot(xr, solspre[1::2],label='Pre  N: '+str(N_pre)+' Z For: '+str(z1_pre)+' Z Inf: '+str(z1i_pre))
ax1.plot(xr, solspost[1::2],label='Post  N: '+str(N_post)+' Z For: '+str(z1_post)+' Z Inf: '+str(z1i_post))
ax1.set_title('Informal Unconstructed')
ax1.set_yticks(yt)
ax1.legend()
fig.savefig(loc+'unconstructed_informal.pdf')


## CONSTRUCTED PRE POST

z1_post  = 1.2
z1i_post = .8

subscat = [(z1,z1_pre),(z2,1),(z3,1),(z4,1),(k,1),  (z1i,z1i_pre),(z2i,1),(z3i,1),(z4i,1),  (ki,1),(g,g_set),(gd,gd_set),(N,N_pre)]
solspre = [x.subs(subscat) for x in sols]
subscat = [(z1,z1_post),(z2,1),(z3,1),(z4,1),(k,1),  (z1i,z1i_post),(z2i,1),(z3i,1),(z4i,1),  (ki,1),(g,g_set),(gd,gd_set),(N,N_post)]
solspost = [x.subs(subscat) for x in sols]

fig = plt.figure()
ax1 = plt.subplot(111)
ax1.plot(xr,solspre[::2],label='Pre  N: '+str(N_pre)+' Z For: '+str(z1_pre)+' Z Inf: '+str(z1i_pre))
ax1.plot(xr,solspost[::2],label='Post  N: '+str(N_post)+' Z For: '+str(z1_post)+' Z Inf: '+str(z1i_post))
ax1.set_title('Formal Constructed')
ax1.set_yticks(yt)
ax1.legend()
fig.savefig(loc+'constructed_formal.pdf')

fig = plt.figure()
ax1 = plt.subplot(111)
ax1.plot(xr, solspre[1::2],label='Pre  N: '+str(N_pre)+' Z For: '+str(z1_pre)+' Z Inf: '+str(z1i_pre))
ax1.plot(xr, solspost[1::2],label='Post  N: '+str(N_post)+' Z For: '+str(z1_post)+' Z Inf: '+str(z1i_post))
ax1.set_title('Informal Constructed')
ax1.set_yticks(yt)
ax1.legend()
fig.savefig(loc+'constructed_informal.pdf')









# fig = plt.figure()
# ax2 = plt.subplot(122)
# ax2.plot(x, sols2[::2],label="for")
# ax2.plot(x, sols2[1::2],label="inf")
# ax2.plot(x,[sum(z) for z in zip(sols2[::2],sols2[1::2])],label="total")
# ax2.set_title('Post : 0.5 Z For, 3 Z Inf')
# ax2.legend()
# fig.savefig(loc+'theory_1.pdf')



# plt.show()



# fig = plt.figure()
# ax1 = plt.subplot(121)
# ax1.plot(x, sols1[::2],label="for")
# ax1.plot(x, sols1[1::2],label="inf")
# ax1.plot(x,[sum(z) for z in zip(sols1[::2],sols1[1::2])],label="total")
# ax1.set_title('Pre : 2 Z For, 1.5 Z Inf')
# ax1.legend()
# ax2 = plt.subplot(122)
# ax2.plot(x, sols2[::2],label="for")
# ax2.plot(x, sols2[1::2],label="inf")
# ax2.plot(x,[sum(z) for z in zip(sols2[::2],sols2[1::2])],label="total")
# ax2.set_title('Post : 0.5 Z For, 3 Z Inf')
# ax2.legend()



# #plt.title('RDP Impacts')

# fig.savefig(loc+'theory_1.pdf')

# plt.show()




#plt.plot(x, sols1[::2],label="for")
#plt.plot(x, sols1[1::2],label="inf")
#plt.plot(x,[sum(z) for z in zip(sols1[::2],sols1[1::2])],label="total")
#plt.plot(x, sols2[::2],label="post for")
#plt.plot(x, sols2[1::2],label="post inf")
#plt.plot(x,[sum(z) for z in zip(sols2[::2],sols2[1::2])],label="post total")



#pprint(sols)
# budget constraint
#tc = (lf*r + li*r + pi*mi + pf*mf)

#obj = tc + lam*(y - (f + i))

#obj = f + lam*(y-r*l-pf*mf)
#sols = solve([diff(obj,mf),diff(obj,l),diff(obj,lam)],[mf,l,lam],set=True)



