

clear 

option = 1;

real = 1;

mult= 1;

if option==1
    given = [ 20  .5  20 20 10 20];
    ag = .4;
    N  = given(1,1);
    g  = ag(1,1);
    k  = given(1,2);
    z1 = given(1,3);
    z2 = given(1,4);
    z1i= given(1,5);
    z2i= given(1,6);
    
elseif option==2
    given = [ 20 ];
    ag = [ .4 .5  1.5 2 1 2.5];
    N  = given(1,1);
    g  = ag(1,1);
    k  = ag(1,2);
    z1 = ag(1,3);
    z2 = ag(1,4);
    z1i= ag(1,5);
    z2i= ag(1,6);
elseif option==3
    given = [ 20 4 ];
    ag = [ .4 .6   1 1 4];
    N  = given(1,1);
    g  = ag(1,1);
    k  = ag(1,2);
    z1 = given(1,2);
    z2 = ag(1,3);
    z1i= ag(1,4);
    z2i= ag(1,5);    
end

n1s = N1s(N,g,k,z1,z2,z1i,z2i);
n2s = N2s(N,g,k,z1,z2,z1i,z2i);
n3s = N3s(N,g,k,z1,z2,z1i,z2i);
n4s = N4s(N,g,k,z1,z2,z1i,z2i);
n5s = N5s(N,g,k,z1,z2,z1i,z2i);
n6s = N6s(N,g,k,z1,z2,z1i,z2i);
n7s = N7s(N,g,k,z1,z2,z1i,z2i);
n8s = N8s(N,g,k,z1,z2,z1i,z2i);
n9s = N9s(N,g,k,z1,z2,z1i,z2i);
n10s = N10s(N,g,k,z1,z2,z1i,z2i);

n1is = N1is(N,g,k,z1,z2,z1i,z2i);
n2is = N2is(N,g,k,z1,z2,z1i,z2i);
n3is = N3is(N,g,k,z1,z2,z1i,z2i);
n4is = N4is(N,g,k,z1,z2,z1i,z2i);
n5is = N5is(N,g,k,z1,z2,z1i,z2i);
n6is = N6is(N,g,k,z1,z2,z1i,z2i);
n7is = N7is(N,g,k,z1,z2,z1i,z2i);
n8is = N8is(N,g,k,z1,z2,z1i,z2i);
n9is = N9is(N,g,k,z1,z2,z1i,z2i);
n10is = N10is(N,g,k,z1,z2,z1i,z2i);
    
data_sim = [n1s; n2s; n3s; n4s; n5s; n6s; n7s; n8s; n9s; n10s; ...
           n1is; n2is; n3is; n4is; n5is; n6is; n7is; n8is; n9is; n10is ];

if real==0
    data=data_sim;
elseif real==1
    real_data = csvread('for_con_pre.csv',1,1);
    data = [real_data(:,1); real_data(:,2)];
end
       
obj = @(a1)s10obj(a1,given,data,option);

ag
mult.*ag
res = fminunc(obj, mult.*ag )


hold on 
yyaxis left
plot([-2:7],data_sim(1:10),[-2:7],data_sim(11:end))
yyaxis right
plot([-2:7],data(1:10),[-2:7],data(11:end))
hold off
       