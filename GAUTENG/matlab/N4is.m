function out1 = N4is(N,g,k,z1,z2,z1i,z2i)
%N4IS
%    OUT1 = N4IS(N,G,K,Z1,Z2,Z1I,Z2I)

%    This function was generated by the Symbolic Math Toolbox version 8.2.
%    18-Oct-2018 17:19:03

t2 = g.^2;
t3 = t2.^2;
t4 = t3.^2;
t5 = k.^2;
t6 = t4.*6.0;
t7 = z1i-z2i;
t8 = g.*t2.*4.0;
t9 = t2.*t3.*1.0e1;
t10 = g.*t2.*t3.*3.0;
t11 = g.*t4.*4.0;
t12 = g.*t2.*2.0;
t13 = g.*t2.*3.0;
t14 = t3.*9.0;
t15 = t2.*t3.*2.0;
t16 = g.*t2.*t3.*6.0;
t17 = g.*t2.*t4.*5.0;
t18 = t5.^2;
t19 = t2.*1.74e2;
t20 = t3.*1.6e1;
t21 = g.*-7.3e1+t19+t20-g.*t2.*1.29e2+9.0;
t22 = 1.0./t21;
out1 = N./2.3e1+(z1.*(3.0./2.3e1)+z2.*(1.0e1./2.3e1)-z1i.*(3.0./2.3e1)-z2i.*(1.0e1./2.3e1))./k-(t7.*(t3.*7.0+t4.*5.0-g.*t2.*6.0+g.*t3.*1.5e1-g.*t4.*2.0-g.*t5.*1.8e1-k.*t2.*1.8e1+k.*t3.*2.7e1-k.*t5.*6.0-t2.*t3.*1.9e1+t2.*t5.*7.0+g.*k.*t2.*1.4e1-g.*k.*t3.*2.2e1-g.*t2.*t3.*2.0+g.*t2.*t5.*1.2e1+k.*t2.*t3))./(t3.*2.3e1+t6.*2.3e1+t16.*2.3e1+t17.*2.3e1+t18.*2.3e1-g.*t3.*2.3e1-g.*t4.*2.53e2-t2.*t3.*1.15e2-t5.*(t2.*-6.0+t13+t14+t15-g.*t3.*4.0).*2.3e1+k.*(t3.*-3.0-t6+t8+t9+t10+t11-g.*t3.*1.2e1).*2.3e1-k.*t5.*(g.*-4.0+t2+t12).*2.3e1)+(t7.*t22.*(g.*-9.0+t2.*2.4e1+t3.*4.0-g.*t2.*2.1e1+1.0).*(1.1e1./2.3e1))./(g+k-t2.*2.0+t12)+(t7.*t22.*(t3.*1.5e1-t4.*5.31e2+t9-g.*t2-g.*t3.*6.0e1-g.*t4.*1.3e2-g.*t5.*3.0-k.*t2.*3.0-k.*t3.*1.41e2+k.*t4-k.*t5+t2.*t4.*7.04e2+t2.*t5.*3.3e1+t3.*t4.*5.0e1+t3.*t5.*5.6e1+g.*k.*t2.*3.9e1+g.*k.*t3.*4.9e1+g.*k.*t4.*2.47e2+g.*k.*t5.*9.0+g.*t2.*t3.*3.51e2-g.*t2.*t4.*4.05e2-g.*t2.*t5.*1.05e2+g.*t3.*t5.*1.92e2+k.*t2.*t3.*5.12e2-k.*t2.*t4.*4.0e1-k.*t2.*t5.*2.4e1-k.*t3.*t5.*4.0-t2.*t3.*t5.*2.09e2-g.*k.*t2.*t3.*6.66e2+g.*k.*t2.*t5.*2.1e1+g.*t2.*t3.*t5.*3.2e1).*(1.1e1./2.3e1))./(t3+t6-t16-t17+t18+g.*t3+g.*t4.*1.1e1-t2.*t3.*5.0+k.*(t3.*3.0+t6+t8-t9+t10+t11-g.*t3.*1.2e1)-t5.*(t2.*-6.0-t13+t14+t15+g.*t3.*4.0)+k.*t5.*(g.*4.0+t2-t12));