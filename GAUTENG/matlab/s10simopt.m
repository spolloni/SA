

clear 

option = [ 2 3 4 5 6 7];

real = 1;

mult= 1;
given = [ 50 .4 .5  20 20 10 20];
    
ag = given(1,option);    
    
data_sim = pred(given);

if real==0
    data=data_sim;
elseif real==1
    real_data = csvread('for_con_pre.csv',1,1);
    data = [real_data(:,2); real_data(:,1)]; % reverse cus inf first!
end
       
obj = @(a1)s10objopt(a1,given,data,option);

ag
mult.*ag
res = fminunc(obj,mult.*ag)

res_out = given;
res_out(option) = res;
output = pred(res_out);

L = [];
hold on 
%yyaxis left
%plot([-2:7],data_sim(1:10),[-2:7],data_sim(11:end))
%yyaxis right
plot([-2:7],output(1:10),[-2:7],output(11:end))
plot([-2:7],data(1:10),[-2:7],data(11:end))

%legend('sim for', 'sim inf','out for','out inf','data for','data inf')
legend('output for','output inf','data for','data inf')
hold off




       