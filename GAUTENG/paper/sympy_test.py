
from sympy import *

l,mf,mi,a,b,y,r,pf,pi,bc,lam,lam2,obj,lf,li = symbols('l,mf,mi,a,b,y,r,pf,pi,bc,lam,lam2,obj,lf,li')

# prod
f = (lf**a)*(mf**(1-a))
i = (li**b)*(mi**(1-b))

# budget constraint
bc = y - (lf*r + li*r + pi*mi + pf*mf)

obj = f + i + lam*bc 

#obj = f + lam*(y-r*l-pf*mf)
#sols = solve([diff(obj,mf),diff(obj,l),diff(obj,lam)],[mf,l,lam],set=True)

sols =  solve([diff(obj,mf),diff(obj,mi),diff(obj,lf),diff(obj,li),diff(obj,lam)],[mf,mi,lf,li,lam],set=True)

print sols

