function dx = ode(t,x,u)                      
    %% Master: Chua's circuit piece-wise - Slave : chua's circuit poly
    alpha = 15.6;beta = 28;m0 = -1.143;m1 = -0.714; % master system parameter
    p = 10;q = 100/7;                  % slave system parameter
    
    x1 = x(1);y1 = x(2);z1 = x(3);     % master sys states 
    x2 = x(4);y2 = x(5);z2 = x(6);     % slave sys states
    
    ux = u(1);uy = u(2); uz = u(3);    % control to slave system
    
    f_x1 = m1*x1+0.5*(m0-m1)*(abs(x1+1)-abs(x1-1)); % non linearita master
    f_x2 = 2*x2^3 - x2/7;              % non linearity master sys
   
    dx = [alpha*(y1-x1-f_x1);% 
          x1 - y1+ z1;
          -beta*y1
          p*(y2-f_x2)+ux;        
          x2-y2+z2+uy;
          -q*y2+uz];                
end
