function [] = OffsetFree( FI, G, Hy )

n = size(FI,1);
b = size(G,2);
%condizione di offset-free
OSF = Hy*inv(eye(n)-FI)*G;
cond_OSF = OSF/b;
if trace(cond_OSF)==1
    disp('*|------------------------------------------|*')
    disp('*|         Il sistema � Offset-Free         |*')
    disp('*|------------------------------------------|*')
else
    disp('*|------------------------------------------|*')
    disp('*|       Il sistema NON � Offset-Free       |*')
    disp('*|------------------------------------------|*')
end

end

