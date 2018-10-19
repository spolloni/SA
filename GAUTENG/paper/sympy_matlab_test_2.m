

syms u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 
syms a1 a2 a3 a4 a5 a6 a7 a8 a9 a10
syms z k 
syms z1 z2 z3 z4 z5 z6 z7 z8 z9 z10
syms k1 k2 k3 k4 k5 k6 k7 k8 k9 k10
syms N1 N2 N3 N4 N5 N6 N7 N8 N9 N10
syms N g
syms u1i u2i u3i u4i u5i u6i u7i u8i u9i u10i
syms a1i a2i a3i a4i a5i a6i a7i a8i a9i a10i
syms zi ki 
syms z1i z2i z3i z4i z5i z6i z7i z8i z9i z10i
syms k1i k2i k3i k4i k5i k6i k7i k8i k9i k10i
syms N1i N2i N3i N4i N5i N6i N7i N8i N9i N10i
syms gd
syms N1s N2s N3s N4s N5s N6s N7s N8s N9s N10s 
syms N1is N2is N3is N4is N5is N6is N7is N8is N9is N10is

u1   = - z1 - k*N1 - g*2*N2i      - gd*N1i  ;        
u2   = - z2 - k*N2 - g*(N1i+N3i)    - gd*N2i  ;   
u3   = - z3 - k*N3 - g*(N2i+N4i)    - gd*N3i  ;  
u4   = - z4 - k*N4 - g*(N3i+N5i)        - gd*N4i  ;  
u5   = - z5 - k*N5 - g*(N4i+N6i)      - gd*N5i  ; 
u6   = - z5 - k*N6 - g*(N5i+N7i)      - gd*N6i  ; 
u7   = - z5 - k*N7 - g*(N6i+N8i)      - gd*N7i  ; 
u8   = - z5 - k*N8 - g*(N7i+N9i)      - gd*N8i  ; 
u9   = - z5 - k*N9 - g*(N8i+N10i)      - gd*N9i  ; 
u10   = - z10 - k*N10 - g*2*N9i      - gd*N10i  ;



u1i  = - z1i - ki*N1i - g*2*N2i     - gd*N1i ;
u2i  = - z2i - ki*N2i - g*(N1i+N3i) - gd*N2i ;
u3i  = - z3i - ki*N3i - g*(N2i+N4i) - gd*N3i ;
u4i  = - z4i - ki*N4i - g*(N3i+N5i) - gd*N4i ;
u5i  = - z5i - ki*N5i - g*(N4i+N6i) - gd*N5i ;
u6i  = - z6i - ki*N6i - g*(N5i+N7i) - gd*N6i ;
u7i  = - z7i - ki*N7i - g*(N6i+N8i) - gd*N7i ;
u8i  = - z8i - ki*N8i - g*(N7i+N9i) - gd*N8i ;
u9i  = - z9i - ki*N9i - g*(N8i+N10i) - gd*N9i ;
u10i  = - z10i - ki*N10i - g*2*N9i     - gd*N10i ;

nn = N1+N2+N3+N4+N5+N6+N4+N5+N6+N7+N8+N9+N10 + N1i+N2i+N3i+N4i+N5i+N6i+N7i+N8i+N9i+N10i - N;

solve_set = [u1-u2,u2-u3,u3-u4,u4-u5,u5-u6,u6-u7,u7-u8,u8-u9,u9-u10,...
       u1i-u2i,u2i-u3i,u3i-u4i,u5i-u4i,u5i-u6i,u6i-u7i,u7i-u8i,u8i-u9i,u9i-u10i,...
    u1-u1i,nn];

[N1s,N2s,N3s,N4s,N5s,N6s,N7s,N8s,N9s,N10s, ...
    N1is,N2is,N3is,N4is,N5is,N6is,N7is,N8is,N9is,N10is] ...
    =  solve(solve_set,[N1,N2,N3,N4,N5,N6,N7,N8,N9,N10,...
                N1i,N2i,N3i,N4i,N5i,N6i,N7i,N8i,N9i,N10i]);

            
var_set = [z1,z2,z3,z4,z5,z6,z7,z8,z9,z10, ...
            z1i,z2i,z3i,z4i,z5i,z6i,z7i,z8i,z9i,z10i, ...
            k,ki, g,gd, N ...
           ];
       
       

gdc = .3;
gc  = .5*gdc;

       
kc  = .5;
kic = .5;
NC   = 20;

var_eval = [1,1,1,1,1,1,1,1,1,1, ...
            1,1,1,2,1,1,1,1,1,1, ...
            kc,kic, gc,gdc, NC ...
           ];

       
df = eval([  subs(N1s,var_set,var_eval), ...
        subs(N2s,var_set,var_eval), ...
        subs(N3s,var_set,var_eval), ...
        subs(N4s,var_set,var_eval), ...
        subs(N5s,var_set,var_eval), ...
        subs(N6s,var_set,var_eval), ...  
        subs(N7s,var_set,var_eval), ...
        subs(N8s,var_set,var_eval), ...
        subs(N9s,var_set,var_eval), ...
        subs(N10s,var_set,var_eval)  
        ]);

    
di =  eval([   subs(N1is,var_set,var_eval), ...
          subs(N2is,var_set,var_eval), ...
          subs(N3is,var_set,var_eval), ...
          subs(N4is,var_set,var_eval), ...
          subs(N5is,var_set,var_eval), ...
          subs(N6is,var_set,var_eval), ...
          subs(N7is,var_set,var_eval), ...
          subs(N8is,var_set,var_eval), ...
          subs(N9is,var_set,var_eval), ...
          subs(N10is,var_set,var_eval) ]);

dist = (-1:1:size(di,2)-2);

plot(dist,df,dist,di)
      




