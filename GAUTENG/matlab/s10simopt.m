

clear 

option = [ 2 3 4 5 6 7];

real= 1;
post= 0;

mult= 1;

    

if real==0
    data=data_sim;
    given = [ 50 .7 .5  20 20 10 20] ;
    
elseif real==1 && post==0
    real_data = csvread('for_con_pre.csv',1,1);
    data = [real_data(:,2); real_data(:,1)]; % reverse cus inf first!
    given = [ 50 .7 .5  20 20 10 20] ;
    
elseif real==1 && post==1
    real_data = csvread('for_con_post.csv',1,1);
    data = [real_data(:,2); real_data(:,1)]; % reverse cus inf first!   
    given = [ 80 .7 .5  15 20 15 20] ;
    
end
       

ag = given(1,option);    
data_sim = pred(given);
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
plot([-2:7],output(1:10),'--r',[-2:7],data(1:10),'r','LineWidth',2)
plot([-2:7],output(11:end),'--b',[-2:7],data(11:end),'b','LineWidth',2)

%legend('sim for', 'sim inf','out for','out inf','data for','data inf')
legend('Output Formal','Data Formal','Output Informal','Data Informal')
hold off


%hold on 
%plot([-2:7],[ones(1,3)*res_out(4) ones(1,7)*res_out(5)] ,'r','LineWidth',2)
%plot([-2:7],[ones(1,3)*res_out(6) ones(1,7)*res_out(7)] ,'b','LineWidth',2)







       