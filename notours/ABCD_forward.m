%% simulate the Transmision line 

clear; clc; %close all; 
%% set the system value
L = 5.6 *10^(-9); %[H] the inductor 
C = 1 *10^(-12); %[H] the capacitor 
L_s = 242.892 *10 ^(-9); % [H/m]
C_s = 113.445 *10^(-12); %[F/m ] 
l = 0.009; %[m]
W_l = 1*10^10: 1*10^8:9*10^10; % range of frequancies for the code scan

DX = 0.09; %lenth of the board 
n_s = 200 ;% number of itration
dx = DX / n_s ; 

V_out = 1;
V = [ V_out ; V_out/(50)];
step_ind = 1 ;

for j  = 1  : size(W_l,2)
    step_ind = 1 ;
    W = W_l(j); % omega for the loop
    M_L0= [1 ,  (1i *W *L_s *  dx ); 0  ,1];
    M_C0= [1 ,  0 ; (1i *W *C_s * dx )   ,1 ] ;
    M_L = [1 , 0 ; 1./(1i * W *L/2) , 1 ] ;
    M_C = [1 ,1/(1i *W *C) ; 0 ,1 ] ;
%     M_s = (M_C0*M_L0)^k ; % the board element 
    V = [ V_out ; V_out/(50)];
   for k = 1:n_s 
        Z_0 =  ((L_s - 1/(W.^2 *C*dx))./(C_s - 1 /(W.^2 * L*dx*k)))^0.5;
        if k == 1 
            V_in(:,k,j) = M_L0*M_C0*V;
        else 
            V_in(:, k ,j)  = M_L0*M_C0 * V_in(:, k-1 ,j);
%             fprintf('loop number: %d ' ,k)
        end 
        if floor(k*dx/(DX/9)) >= step_ind
             V_in(:,k,j) = M_L *M_C*V_in(:,k ,j);
             step_ind = step_ind + 1 ; 
%              fprintf('noe in !!!  %d' , k )
        end
   end

    
end
 figure(2) 
 X = (1:n_s)*dx;
 COl =(squeeze(V_in(1,:,:)));  
 COl = flip(COl);
 P =imagesc(X, W_l,real(COl)');
 colorbar;
caxis([0 6])
 set(gca, 'Ydir', 'normal')
%  set(P, 'EdgeColor', 'none')