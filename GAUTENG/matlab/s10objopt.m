function h = s10objopt(a,given,data,option)

given(option)=a; % put guess in given

est_mom = pred(given);

h = sum( (est_mom-data).^2 );


end