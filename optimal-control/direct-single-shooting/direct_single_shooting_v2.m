%
%     This file is part of CasADi.
%
%     CasADi -- A symbolic framework for dynamic optimization.
%     Copyright (C) 2010-2014 Joel Andersson, Joris Gillis, Moritz Diehl,
%                             K.U. Leuven. All rights reserved.
%     Copyright (C) 2011-2014 Greg Horn
%
%     CasADi is free software; you can redistribute it and/or
%     modify it under the terms of the GNU Lesser General Public
%     License as published by the Free Software Foundation; either
%     version 3 of the License, or (at your option) any later version.
%
%     CasADi is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%     Lesser General Public License for more details.
%
%     You should have received a copy of the GNU Lesser General Public
%     License along with CasADi; if not, write to the Free Software
%     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
%

% An implementation of direct single shooting
% Joel Andersson, 2016

import casadi.*

T = 10; % Time horizon
N = 20; % number of control intervals

% Declare model variables
x1 = SX.sym('x1');
x2 = SX.sym('x2');
x = [x1; x2];
u = SX.sym('u');

% Model equations
xdot = [(1-x2^2)*x1 - x2 + u; x1];

% Objective term
L = x1^2 + x2^2 + u^2;

% Formulate discrete time dynamics
if true
   % CVODES from the SUNDIALS suite
   dae  = struct('x',x,'p',u,'ode',xdot,'quad',L);
   opts = struct('tf',T/N);
   F    = integrator('F', 'cvodes', dae, opts);
else
   % Fixed step Runge-Kutta 4 integrator
   M = 4; % RK4 steps per interval
   DT = T/N/M;
   f = Function('f', {x, u}, {xdot, L});
   X0 = MX.sym('X0', 2);
   U = MX.sym('U');
   X = X0;
   Q = 0;
   for j=1:M
       [k1, k1_q] = f(X            , U);
       [k2, k2_q] = f(X + DT/2 * k1, U);
       [k3, k3_q] = f(X + DT/2 * k2, U);
       [k4, k4_q] = f(X + DT   * k3, U);
       X = X + DT/6*(k1 +2*k2 +2*k3 +k4);
       Q = Q + DT/6*(k1_q + 2*k2_q + 2*k3_q + k4_q);
    end
    F = Function('F', {X0, U}, {X, Q}, {'x0','p'}, {'xf', 'qf'});
end

% Evaluate at a test point
Fk = F('x0',[0.2; 0.3],'p',0.4);
disp(Fk.xf)
disp(Fk.qf)

% Start with an empty NLP
w   = {};
w0  = [];
lbw = [];
ubw = [];
J   = 0;
g   = {};
lbg = [];
ubg = [];

% Formulate the NLP
Xk = [0; 1];
for k=0:N-1
    % New NLP variable for the control
    Uk  = MX.sym(['U_' num2str(k)]);
    w   = {w{:}, Uk};
    lbw = [lbw, -1];
    ubw = [ubw,  1];
    w0  = [w0,   0];

    % Integrate till the end of the interval
    Fk = F('x0',Xk,'p', Uk);
    Xk = Fk.xf;
    J  = J+Fk.qf;

    % Add inequality constraint
    g = {g{:}, Xk(1)};
    lbg = [lbg; -.25];
    ubg = [ubg;  inf];
end

% Create an NLP solver
prob = struct('f', J, 'x', vertcat(w{:}), 'g', vertcat(g{:}));
solver = nlpsol('solver', 'ipopt', prob);

% Solve the NLP
sol = solver('x0', w0, 'lbx', lbw, 'ubx', ubw, ...
             'lbg', lbg, 'ubg', ubg);
w_opt = full(sol.x);

% Plot the solution
u_opt = w_opt;
x_opt = [0;1];
for k=0:N-1
    Fk    = F('x0', x_opt(:,end), 'p', u_opt(k+1));
    x_opt = [x_opt, full(Fk.xf)];
end
x1_opt = x_opt(1,:);
x2_opt = x_opt(2,:);
tgrid  = linspace(0, T, N+1);
clf;
hold on
plot(tgrid, x1_opt, '--')
plot(tgrid, x2_opt, '-')
stairs(tgrid, [u_opt; nan], '-.')
xlabel('t')
legend('x1','x2','u')
