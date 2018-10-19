

syms u1 u2 u3 u4 u5 u6 a1 a2 a3 a4 a5 a6 z k z1 z2 z3 z4 z5 z6 k1 k2 k3 k4 k5 k6 N1 N2 N3 N4 N5 N6 N g
syms u1i u2i u3i u4i u5i u6i a1i a2i a3i a4i a5i a6i zi ki z1i z2i z3i z4i z5i z6i k1i k2i k3i k4i k5i k6i N1i N2i N3i N4i N5i N6i gd

syms N1s N2s N3s N4s N5s N6s N1is N2is N3is N4is N5is N6is

u1   = - z1 - k*N1 - g*2*N2i ;        
u2   = - z2 - k*N2 - g*(N1i+N3i) ;   
u3   = - z3 - k*N3 - g*(N2i+N4i) ;  
u4   = - z4 - k*N4 - g*(N3i+N5i)  ;  
u5   = - z5 - k*N5 - g*(N4i+N6i)   ; 
u6   = - z6 - k*N6 - g*2*N5i        ;

u1i  = - z1i - ki*N1i - g*2*N2i      ;
u2i  = - z2i - ki*N2i - g*(N1i+N3i)  ;
u3i  = - z3i - ki*N3i - g*(N2i+N4i)  ;
u4i  = - z4i - ki*N4i - g*(N3i+N5i)  ;
u5i  = - z5i - ki*N5i - g*(N4i+N6i)  ;
u6i  = - z6i - ki*N6i - g*2*N5i ;

nn = N1+N2+N3+N4+N5+N6 + N1i+N2i+N3i+N4i+N5i+N6i - N;

[N1s,N2s,N3s,N4s,N5s,N6s,N1is,N2is,N3is,N4is,N5is,N6is] =  solve([u1-u2,u2-u3,u3-u4,u4-u5,u6-u5,u1i-u2i,u2i-u3i,u3i-u4i,u5i-u4i,u6i-u5i,u1-u1i,nn],[N1,N2,N3,N4,N5,N6,N1i,N2i,N3i,N4i,N5i,N6i]);

N1s


simp=simplify(N3s,'IgnoreAnalyticConstraints',true,'Steps',100)

% zT = z1i/6 + z2i/6 + z3i/6 + z4i/6 + z5i/6 + z6i/6;

syms zT ziT gT5 giT5 gT4 giT4 gT3 giT3 gT2 giT2 gT1 giT1 kiT5

pieces = [z1i/6 + z2i/6 + z3i/6 + z4i/6 + z5i/6 + z6i/6, ...
          z1/6  + z2/6  + z3/6  + z4/6  + z5/6  + z6/6,  ...
         2*g^5*z1        + 2*g^5*z2        + 2*g^5*z4 + 2*g^5*z5 + 2*g^5*z6, ... %%% 5
         2*g^5*z1i       + 2*g^5*z2i       + 2*g^5*z4i + 2*g^5*z5i + 2*g^5*z6i,...
         g^4*ki*z1       + g^4*ki*z2       + g^4*ki*z4 + g^4*ki*z5 +g^4*ki*z6 , ... %%% 4
         2*g^4*ki*z1i    + 3*g^4*ki*z2i    -  11*g^4*ki*z4i + 3*g^4*ki*z5i + 8*g^4*ki*z6i,...
         6*g^3*ki^2*z1   + 6*g^3*ki^2*z2   + 6*g^3*ki^2*z4 + 6*g^3*ki^2*z5+ 6*g^3*ki^2*z6, ... %%% 3
        - 5*g^3*ki^2*z1i + 4*g^3*ki^2*z2i  + 13*g^3*ki^2*z4i - 2*g^3*ki^2*z5i + g^3*ki^2*z6i, ...
         3*g^2*ki^3*z1   + 3*g^2*ki^3*z2   - 15*g^2*ki^3*z3  + 3*g^2*ki^3*z4 + 3*g^2*ki^3*z5  + 3*g^2*ki^3*z6, ... %%% 2
         g^2*ki^3*z1i    + 2*g^2*ki^3*z2i  + 3*g^2*ki^3*z3i + 3*g^2*ki^3*z4i  - 4*g^2*ki^3*z5i - 5*g^2*ki^3*z6i, ...
         2*g*ki^4*z1     + 2*g*ki^4*z2     + 2*g*ki^4*z4 + 2*g*ki^4*z5  + 2*g*ki^4*z6 , ... %%% 1
         g*ki^4*z1i  - 3*g*ki^4*z2i        - 4*g*ki^4*z4i  + 3*g*ki^4*z5i + g*ki^4*z6i, ...
         ki^5*z1        + ki^5*z2 + ki^5*z4 + ki^5*z5 + ki^5*z6 ...
        ];
    
subs(simp,pieces,[zT,ziT,gT5,giT5,gT4,giT4,gT3,giT3,gT2,giT2,gT1,giT1,kiT5])

new_pieces = [gT5 + gT4 + gT3 + gT2 +gT1 ]

% z_total*(2*g^5+g^4*k+6*g^3*k^2+3*g^2*ki^3+2*g*k^4 + k^5)




