function   data = pred(given)

    N  = given(1,1);
    g  = given(1,2);
    k  = given(1,3);
    z1 = given(1,4);
    z2 = given(1,5);
    z1i= given(1,6);
    z2i= given(1,7);
    
n1s  = N1s(N,g,k,z1,z2,z1i,z2i);
n2s  = N2s(N,g,k,z1,z2,z1i,z2i);
n3s  = N3s(N,g,k,z1,z2,z1i,z2i);
n4s  = N4s(N,g,k,z1,z2,z1i,z2i);
n5s  = N5s(N,g,k,z1,z2,z1i,z2i);
n6s  = N6s(N,g,k,z1,z2,z1i,z2i);
n7s  = N7s(N,g,k,z1,z2,z1i,z2i);
n8s  = N8s(N,g,k,z1,z2,z1i,z2i);
n9s  = N9s(N,g,k,z1,z2,z1i,z2i);
n10s = N10s(N,g,k,z1,z2,z1i,z2i);

n1is  = N1is(N,g,k,z1,z2,z1i,z2i);
n2is  = N2is(N,g,k,z1,z2,z1i,z2i);
n3is  = N3is(N,g,k,z1,z2,z1i,z2i);
n4is  = N4is(N,g,k,z1,z2,z1i,z2i);
n5is  = N5is(N,g,k,z1,z2,z1i,z2i);
n6is  = N6is(N,g,k,z1,z2,z1i,z2i);
n7is  = N7is(N,g,k,z1,z2,z1i,z2i);
n8is  = N8is(N,g,k,z1,z2,z1i,z2i);
n9is  = N9is(N,g,k,z1,z2,z1i,z2i);
n10is = N10is(N,g,k,z1,z2,z1i,z2i);
    
data = [n1s; n2s; n3s; n4s; n5s; n6s; n7s; n8s; n9s; n10s; ...
           n1is; n2is; n3is; n4is; n5is; n6is; n7is; n8is; n9is; n10is ];