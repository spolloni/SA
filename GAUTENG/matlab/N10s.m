function out1 = N10s(N,g,k,z1,z2,z1i,z2i)
%N10S
%    OUT1 = N10S(N,G,K,Z1,Z2,Z1I,Z2I)

%    This function was generated by the Symbolic Math Toolbox version 8.2.
%    18-Oct-2018 17:18:13

t2 = g.^2;
t3 = t2.^2;
t4 = t3.^2;
t5 = k.^2;
t6 = z1i-z2i;
t7 = g.*t2.*4.0;
t8 = t2.*t3.*1.0e1;
t9 = g.*t2.*t3.*3.0;
t10 = t4.*6.0;
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
out1 = N./2.3e1+(z1.*(3.0./2.3e1)-z2.*(1.3e1./2.3e1)-z1i.*(3.0./2.3e1)+z2i.*(1.3e1./2.3e1))./k+(t6.*(t3.*3.2e1+t4.*1.3e1-g.*t2.*1.1e1+g.*t3.*1.6e1-g.*t4.*4.2e1-g.*t5.*3.3e1-k.*t2.*3.3e1+k.*t3.*6.1e1-k.*t5.*1.1e1-t2.*t3.*7.7e1+t2.*t5.*3.2e1+g.*k.*t2.*6.4e1-g.*k.*t3.*7.1e1+g.*t2.*t3.*5.0e1+g.*t2.*t5.*4.5e1-k.*t2.*t3.*2.5e1))./(t3.*4.6e1+t10.*4.6e1+t16.*4.6e1+t17.*4.6e1+t18.*4.6e1-g.*t3.*4.6e1-g.*t4.*5.06e2-t2.*t3.*2.3e2-t5.*(t2.*-6.0+t13+t14+t15-g.*t3.*4.0).*4.6e1+k.*(t3.*-3.0-t4.*6.0+t7+t8+t9+t11-g.*t3.*1.2e1).*4.6e1-k.*t5.*(g.*-4.0+t2+t12).*4.6e1)+(t6.*t22.*(g.*-9.0+t2.*2.4e1+t3.*4.0-g.*t2.*2.1e1+1.0).*(1.1e1./2.3e1))./(g+k-t2.*2.0+t12)+(t6.*t22.*(t3.*-1.763e3+t4.*1.8931e4+g.*t2.*1.85e2+g.*t3.*4.798e3+g.*t4.*1.4574e4+g.*t5.*5.55e2+k.*t2.*5.55e2+k.*t3.*1.3343e4+k.*t4.*1.149e3+k.*t5.*1.85e2+t2.*t3.*7.72e2-t2.*t4.*2.5682e4-t2.*t5.*4.725e3-t3.*t4.*7.4e2-t3.*t5.*7.278e3-g.*k.*t2.*5.007e3-g.*k.*t3.*4.327e3-g.*k.*t4.*7.561e3-g.*k.*t5.*1.481e3-g.*t2.*t3.*2.0085e4+g.*t2.*t4.*8.869e3+g.*t2.*t5.*1.2019e4-g.*t3.*t5.*8.748e3-k.*t2.*t3.*2.7146e4+k.*t2.*t4.*9.6e2+k.*t2.*t5.*3.474e3+k.*t3.*t5.*2.8e2+t2.*t3.*t5.*9.501e3+g.*k.*t2.*t3.*2.8128e4-g.*k.*t2.*t5.*2.505e3-g.*t2.*t3.*t5.*1.136e3))./(t3.*4.6e1+t10.*4.6e1-t16.*4.6e1-t17.*4.6e1+t18.*4.6e1+g.*t3.*4.6e1+g.*t4.*5.06e2-t2.*t3.*2.3e2+k.*(t3.*3.0+t7-t8+t9+t10+t11-g.*t3.*1.2e1).*4.6e1-t5.*(t2.*-6.0-t13+t14+t15+g.*t3.*4.0).*4.6e1+k.*t5.*(g.*4.0+t2-t12).*4.6e1);
