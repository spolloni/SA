function out1 = N3s(N,g,k,z1,z2,z1i,z2i)
%N3S
%    OUT1 = N3S(N,G,K,Z1,Z2,Z1I,Z2I)

%    This function was generated by the Symbolic Math Toolbox version 8.2.
%    18-Oct-2018 17:16:46

t2 = g.^2;
t3 = t2.^2;
t4 = t3.^2;
t5 = k.^2;
t6 = t3.*9.0;
t7 = g.*t4.*4.0;
t8 = z1i-z2i;
t9 = g.*t2.*4.0;
t10 = t2.*t3.*1.0e1;
t11 = g.*t2.*t3.*3.0;
t12 = t4.*6.0;
t13 = g.*t2.*2.0;
t14 = g.*t2.*3.0;
t15 = t2.*t3.*2.0;
t16 = g.*t2.*t3.*6.0;
t17 = g.*t2.*t4.*5.0;
t18 = t5.^2;
t19 = t2.*1.74e2;
t20 = t3.*1.6e1;
t21 = g.*-7.3e1+t19+t20-g.*t2.*1.29e2+9.0;
t22 = 1.0./t21;
out1 = N./2.3e1-(z1.*(2.0e1./2.3e1)-z2.*(1.0e1./2.3e1)-z1i.*(2.0e1./2.3e1)+z2i.*(1.0e1./2.3e1))./k+(t8.*(t4.*1.3e1+t6+t7-g.*t2.*1.1e1+g.*t3.*3.9e1-g.*t5.*3.3e1-k.*t2.*3.3e1+k.*t3.*6.1e1-k.*t5.*1.1e1-t2.*t3.*3.1e1+t2.*t5.*9.0+g.*k.*t2.*1.8e1-g.*k.*t3.*2.5e1-g.*t2.*t3.*1.9e1+g.*t2.*t5.*2.2e1-k.*t2.*t3.*2.0))./(t3.*4.6e1+t12.*4.6e1+t16.*4.6e1+t17.*4.6e1+t18.*4.6e1-g.*t3.*4.6e1-g.*t4.*5.06e2-t2.*t3.*2.3e2-t5.*(t2.*-6.0+t6+t14+t15-g.*t3.*4.0).*4.6e1+k.*(t3.*-3.0-t4.*6.0+t7+t9+t10+t11-g.*t3.*1.2e1).*4.6e1-k.*t5.*(g.*-4.0+t2+t13).*4.6e1)-(t8.*t22.*(g.*-9.0+t2.*2.4e1+t3.*4.0-g.*t2.*2.1e1+1.0).*(1.2e1./2.3e1))./(g+k-t2.*2.0+t13)-(t8.*t22.*(t3.*-1.526e3+t4.*1.2303e4+g.*t2.*1.83e2+g.*t3.*3.206e3+g.*t4.*8.61e3+g.*t5.*5.49e2+k.*t2.*5.49e2+k.*t3.*1.0117e4-k.*t4.*2.115e3+k.*t5.*1.83e2+t2.*t3.*2.701e3-t2.*t4.*1.6109e4-t2.*t5.*4.452e3-t3.*t4.*6.4e2-t3.*t5.*4.843e3-g.*k.*t2.*4.515e3+g.*k.*t3.*4.17e2-g.*k.*t4.*4.1e3-g.*k.*t5.*1.463e3-g.*t2.*t3.*1.5611e4+g.*t2.*t4.*6.955e3+g.*t2.*t5.*1.0337e4-g.*t3.*t5.*7.329e3-k.*t2.*t3.*2.4259e4+k.*t2.*t4.*5.12e2+k.*t2.*t5.*3.426e3+k.*t3.*t5.*2.72e2+t2.*t3.*t5.*6.484e3+g.*k.*t2.*t3.*2.3277e4-g.*k.*t2.*t5.*2.463e3-g.*t2.*t3.*t5.*7.04e2))./(t3.*4.6e1+t12.*4.6e1-t16.*4.6e1-t17.*4.6e1+t18.*4.6e1+g.*t3.*4.6e1+g.*t4.*5.06e2-t2.*t3.*2.3e2+k.*(t3.*3.0+t7+t9-t10+t11+t12-g.*t3.*1.2e1).*4.6e1-t5.*(t2.*-6.0+t6-t14+t15+g.*t3.*4.0).*4.6e1+k.*t5.*(g.*4.0+t2-t13).*4.6e1);
