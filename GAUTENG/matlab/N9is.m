function out1 = N9is(N,g,k,z1,z2,z1i,z2i)
%N9IS
%    OUT1 = N9IS(N,G,K,Z1,Z2,Z1I,Z2I)

%    This function was generated by the Symbolic Math Toolbox version 8.2.
%    18-Oct-2018 17:20:17

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
out1 = N./2.3e1+(z1.*(3.0./2.3e1)+z2.*(1.0e1./2.3e1)-z1i.*(3.0./2.3e1)-z2i.*(1.0e1./2.3e1))./k-(t7.*(t3.*-3.2e1-t4.*3.6e1+g.*t2.*1.1e1+g.*t3.*7.0+g.*t4.*4.2e1+g.*t5.*3.3e1+k.*t2.*3.3e1+k.*t3.*8.0+k.*t5.*1.1e1+t2.*t3.*1.0e2-t2.*t5.*3.2e1-g.*k.*t2.*6.4e1+g.*k.*t3.*9.4e1-g.*t2.*t3.*9.6e1+g.*t2.*t5-k.*t2.*t3.*6.7e1))./(t3.*4.6e1+t6.*4.6e1+t16.*4.6e1+t17.*4.6e1+t18.*4.6e1-g.*t3.*4.6e1-g.*t4.*5.06e2-t2.*t3.*2.3e2-t5.*(t2.*-6.0+t13+t14+t15-g.*t3.*4.0).*4.6e1+k.*(t3.*-3.0-t6+t8+t9+t10+t11-g.*t3.*1.2e1).*4.6e1-k.*t5.*(g.*-4.0+t2+t12).*4.6e1)-(t7.*t22.*(g.*-9.0+t2.*2.4e1+t3.*4.0-g.*t2.*2.1e1+1.0).*(1.2e1./2.3e1))./(g+k-t2.*2.0+t12)+(t7.*t22.*(t3.*-2.039e3+t4.*1.8287e4+g.*t2.*2.31e2+g.*t3.*4.821e3+g.*t4.*1.002e4+g.*t5.*6.93e2+k.*t2.*6.93e2+k.*t3.*1.4562e4-k.*t4.*5.498e3+k.*t5.*2.31e2+t2.*t3.*1.83e3-t2.*t4.*2.283e4-t2.*t5.*5.829e3-t3.*t4.*1.2e3-t3.*t5.*8.566e3-g.*k.*t2.*5.973e3-g.*k.*t3.*3.361e3-g.*k.*t4.*2.961e3-g.*k.*t5.*1.895e3-g.*t2.*t3.*1.9648e4+g.*t2.*t4.*1.0456e4+g.*t2.*t5.*1.4319e4-g.*t3.*t5.*7.506e3-k.*t2.*t3.*2.7399e4+k.*t2.*t4.*5.92e2+k.*t2.*t5.*4.578e3+k.*t3.*t5.*4.64e2+t2.*t3.*t5.*7.983e3+g.*k.*t2.*t3.*2.9531e4-g.*k.*t2.*t5.*3.471e3-g.*t2.*t3.*t5.*1.136e3))./(t3.*4.6e1+t6.*4.6e1-t16.*4.6e1-t17.*4.6e1+t18.*4.6e1+g.*t3.*4.6e1+g.*t4.*5.06e2-t2.*t3.*2.3e2+k.*(t3.*3.0+t6+t8-t9+t10+t11-g.*t3.*1.2e1).*4.6e1-t5.*(t2.*-6.0-t13+t14+t15+g.*t3.*4.0).*4.6e1+k.*t5.*(g.*4.0+t2-t12).*4.6e1);
