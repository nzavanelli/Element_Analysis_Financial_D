function[varargout]=curvemoments(x,y,z)
%CURVEMOMENTS  Centroid, area, and many other moments of a closed curve.
%   _______________________________________________________________________
%   
%   *|* curvemoments.png --- Figure of CURVEMOMENTS applied to a QG model. 
%   Type 'jhelp curvemoments' to view this image. *|*
%   ______________________________________________________________________
%
%   CURVEMOMENTS returns various moments of a closed curve.  These occur in 
%   two sets, moments of the curve itself, and moments of the velocity
%   meausured along the curve.
%   __________________________________________________________________
%
%   Curve moments: Centroid, arc length, area, moment of inertia, etc.
%
%   [XO,YO,KAPPA,R,L,A,B,THETA]=CURVEMOMENTS(XC,YC), where the closed curve 
%   is specified by the column vectors XC and YC, returns the following:
%
%       XO    -- X-component of the centroid of the enclosed region     
%       YO    -- Y-component of the centroid of the enclosed region
%       KAPPA -- root-mean-square distance from the curve to the centroid
%       R     -- area radius, defined such that pi R^2 is the enclosed area    
%       L     -- arc length along the curve    
%       A     -- major axis of the area moment of inertia 
%       B     -- minor axis of the area moment of inertia 
%       THETA -- orientation angle of the area moment of inertia 
%
%   Note that the last three quantities describe the area moment of inertia
%   as an ellipse with semi-axes length A and B, and orientation THETA. 
%
%   The moments are calculated from the curve (XC,YC) using expressions
%   for converting spatial to line integrals derived from Green's theorem.
%
%   XC and YC may be matrices, with each column specifying a different 
%   closed curve.  In this case, all curves must contain the same number 
%   of points, corresponding to the rows.  No NaNs may be present. 
%   
%   XC and YC may also be cell arrays of column vectors.  In this case, the 
%   moments will be numerical arrays with the same lengths as XC and YC.
%
%   The above figure illustrates an application of CURVEMOMENTS to a
%   quasigeostrophic eddy field from QGSNAPSHOT.  The blue curves are
%   curves of constant Okubo-Weiss parameter.  These are well matched by
%   the red curves, constructed from the second central moment quantites
%   A, B, and THETA, and centered at the curve centroids XO, YO.  
%   __________________________________________________________________
%
%   Velocity moments: Vorticity, angular momentum, kinetic energy, etc.
%
%   CURVEMOMENTS can also compute various moments based on the velocity.
%
%   [ZETA,DIV,SIGMA,NU,MOM,KE]=CURVEMOMENTS(XC,YC,ZC) where ZC is the 
%   complex-valued velocity ZC=U+iV along the curve, returns the following:
%
%       ZETA  -- spatially-averaged vorticity  
%       DIV   -- spatially-averaged divergence    
%       SIGMA -- spatially-averaged shear strain
%       NU    -- spatially-averaged normal strain  
%       MOM   -- average angular momentum along the curve
%       KE    -- average kinetic energy along the curve
%
%   For the velocity moments, CURVEMOMENTS expects XC and YC to have units
%   of km while ZC is in cm/s.  ZETA, DIV, SIGMA, and NU then have units of
%   1/s, MOM and MOMSTD have units of cm^2/s, and KE has units of cm^2/s^2.
%
%   Note that ZETA and DIV are computed as integrals of the tangential and
%   normal velocities along the curve, respectively, then converted to area 
%   averages by applying Stokes' theorem and the divergence theorem.  The
%   strain components SIGMA and NU are similarly computed using an extended
%   version of Stokes' thereom derived by Lilly (2018).
%
%   MOM is the average angular momentum along the curve with respect to the
%   curve centroid. KE is the average value of the kinetic energy along the
%   curve, a velocity quantity analagous to averaged squared distance D^2.
%   __________________________________________________________________
%
%   See also CLOSEDCURVES, CURVEINTERP.
% 
%   'curvemoments --t' runs some tests.
%   'curvemoments --f' generates the above figure.
%
%   Usage: [xo,yo]=curvemoments(xc,yc);
%          [xo,yo,kappa,R,L]=curvemoments(xc,yc);
%          [xo,yo,kappa,R,L,a,b,theta]=curvemoments(xc,yc);
%          [zeta,div,sigma,nu,mom,ke,momstd]=curvemoments(xc,yc,zc);
%   __________________________________________________________________
%   This is part of JLAB --- type 'help jlab' for more information
%   (C) 2013--2015 J.M. Lilly --- type 'help jlab_license' for details

%   Note that for oceanographic applications, MOM would be called the 
%   *relative* angular momentum, as opposed to the *absolute* angular 
%   momentum which includes the contribution of the planetary rotation.  

if ischar(x)
    if strcmpi(x, '--t')
        curvemoments_test,return
    elseif strcmpi(x, '--f')
        type makefigs_curvemoments
        makefigs_curvemoments;
        return
    end
end
if nargin==2
    z=[];
end

if isempty(z)
    [xo,yo,L,R,kappa,a,b,theta]=vempty;
    if iscell(x)
        [xo,yo,L,R,kappa,a,b,theta]=vzeros(length(x),1,'nan');
        for i=1:length(x)
            if ~isempty(x{i})
                [xi,yi]=curvemoments_curvecheck(x{i},y{i});
                [xo(i),yo(i),L(i),R(i),kappa(i),signC,dx,dy,ds,xp,yp]=curvemoments_position(xi,yi);
                if nargout>5
                    [a(i),b(i),theta(i)]=curvemoments_inertia(R(i),signC,dx,dy,xp,yp);
                end
            end
        end
    else
        [xo,yo,L,R,kappa,a,b,theta]=vempty;
        [xi,yi]=curvemoments_curvecheck(x,y);
        [xo,yo,L,R,kappa,signC,dx,dy,ds,xp,yp]=curvemoments_position(xi,yi);
        if nargout>5
            [a,b,theta]=curvemoments_inertia(R,signC,dx,dy,xp,yp);
        end
    end
    varargout{1}=xo;
    varargout{2}=yo;
    varargout{3}=kappa;
    varargout{4}=R;
    varargout{5}=L;
    varargout{6}=a;
    varargout{7}=b; 
    varargout{8}=theta;   
elseif ~isempty(z)
    [zeta,div,sigma,nu,mom,ke,momstd]=vempty;
    if iscell(x)
        [zeta,div,sigma,nu,mom,ke,momstd]=vzeros(length(x),1);
        for i=1:length(x)
            if ~isempty(x{i})
                [xi,yi,zi]=curvemoments_curvecheck(x{i},y{i},z{i});
                [xo,yo,L,R,kappa,signC,dx,dy,ds,xp,yp]=curvemoments_position(xi,yi);
                [zeta(i),div(i),sigma(i),nu(i),mom(i),ke(i),momstd(i)]=curvemoments_velocity(L,R,signC,dx,dy,ds,xp,yp,zi);
            end
        end
    else
        [xi,yi,zi]=curvemoments_curvecheck(x,y,z);
        [xo,yo,L,R,kappa,signC,dx,dy,ds,xp,yp]=curvemoments_position(xi,yi);
        [zeta,div,sigma,nu,mom,ke,momstd]=curvemoments_velocity(L,R,signC,dx,dy,ds,xp,yp,zi);
    end
    varargout{1}=zeta;
    varargout{2}=div;
    varargout{3}=sigma;
    varargout{4}=nu;
    varargout{5}=mom;
    varargout{6}=ke;
    varargout{7}=momstd;    
end


function[x,y,z]=curvemoments_curvecheck(x,y,z)
%Check that contours are indeed closed
dz=x(2:end,:)+sqrt(-1)*y(2:end,:)-x(1:end-1,:)-sqrt(-1)*y(1:end-1,:);
tol=1e-6*sqrt(vmean(squared(dz),1));
dzend=x(1,:)+sqrt(-1)*y(1,:)-x(end,:)-sqrt(-1)*y(end,:);
index=find(abs(dzend)>tol);
%figure,plot(abs(dzend)./sqrt(vmean(squared(dz),1)))

if ~isempty(index)
    warning(['CURVEMOMENTS locating ' int2str(length(index)) ' open contours.'])
end

function[xo,yo,L,R,kappa,signC,dx,dy,ds,x,y]=curvemoments_position(x,y)
%Calculate various moments of position 

%Do not use first forward difference!  It is essential to use first central
%difference for calculating the integrals.  Otherwise, you get big 
%numerical errors, nonzero divergence, etc., especially for short curves
%To see this you can uncomment these lines, comment out dx and dy using 
%vdiff below, and use 'closedcurves --f'
%
%dx=diff(x,1,1);  %Do not use
%dy=diff(y,1,1);  %Do not use

x=x(1:end-1,:);
y=y(1:end-1,:);

% Timing check
% 1,tic;diff(x,1,1);toc
% 2,tic;frac(1,2)*vshift(x,1,1)-frac(1,2)*vshift(x,-1,1);toc
% 3,tic;vdiff(x,1);toc

%dx=vdiff(x,1,'periodic');
%dy=vdiff(y,1,'periodic');
%Somewhat faster way to compute first central difference

dx=frac(1,2)*vshift(x,1,1)-frac(1,2)*vshift(x,-1,1);
dy=frac(1,2)*vshift(y,1,1)-frac(1,2)*vshift(y,-1,1);

%The magic of Green's theorem
A = frac(1,2)*sum(x.*dy-y.*dx,1);
signC=sign(A);  %In case we have left-hand curves

A = abs(A);
R=sqrt(frac(A,pi));

%http://www.math.washington.edu/~king/coursedir/m324a10/as/centroid-green.pdf

%Removing the mean first prevents integration errors
mx=mean(x,1);
my=mean(y,1);
mxmat=vrep(mx,size(x,1),1);
mymat=vrep(my,size(x,1),1);

%vsize(x,mxmat,dy,mx,A,signC)

xo=signC.*frac(1,2*A).*sum((x-mxmat).^2.*dy,1)+mx; %dy and dx???
yo=-signC.*frac(1,2*A).*sum((y-mymat).^2.*dx,1)+my;

%Removing the centroid
x=x-vrep(xo,size(x,1),1);
y=y-vrep(yo,size(x,1),1);

ds=sqrt(dx.^2+dy.^2);
L=sum(ds,1);
kappa=sqrt(frac(sum((x.^2+y.^2).*ds,1),L));

vtranspose(xo,yo,L,R,kappa);

function[a,b,theta]=curvemoments_inertia(R,signC,dx,dy,x,y)
%Calculate moment of inertia
%Expecting x and y relative to the centroid

A=(pi*R.^2)';   %Transpose these back to a row vector

%http://www.infogoaround.org/JBook/CentroidInertia.pdf
Ixx=-signC.*frac(1,3).*frac(4,A).*sum(y.^3.*dx,1);
Ixy1=-signC.*frac(1,2).*frac(4,A).*sum(x.*y.^2.*dx,1);
Ixy2=signC.*frac(1,2).*frac(4,A).*sum(y.*x.^2.*dy,1);
Ixy=frac(1,2)*(Ixy1+Ixy2);
Iyy=signC.*frac(1,3).*frac(4,A).*sum(x.^3.*dy,1);

[a2,b2,theta]=specdiag(Ixx,Iyy,-Ixy);  %Note the minus sign there

%aresame([Ixx -Ixy; -Ixy Iyy],jmat2(theta)*[a2 0;0 b2]*jmat2(-theta),1e-5)
%aresame([Ixx -Ixy; -Ixy Iyy],jmat2(theta+pi/2)*[b2 0;0 a2]*jmat2(-theta-pi/2),1e-5)

a=sqrt(a2);
b=real(sqrt(b2));  %Sometimes small imaginary part
theta=theta+pi/2;  %That's subtle

vtranspose(a,b,theta);


function[zeta,div,sigma,nu,mom,ke,momstd]=curvemoments_velocity(L,R,signC,dx,dy,ds,x,y,z)
%Calculate velocity moments
%Expecting x and y relative to the centroid

dx=100*1000*dx;  %Convert km to cm
dy=100*1000*dy;  %Convert km to cm
ds=100*1000*ds;  %Convert km to cm
x=100*1000*x;    %Convert km to cm
y=100*1000*y;    %Convert km to cm
R=100*1000*R;    %Convert km to cm
L=100*1000*L;    %Convert km to cm

A=pi*R.^2;  
[A,L]=vtranspose(A,L);  %Transpose these back to row vectors

z=z(1:end-1,:);

%vsize(A,signC,z,dx,dy,L,ds)
zeta=frac(1,A).*signC.*sum(real(z).*dx+imag(z).*dy,1); %udx+vdy
div=frac(1,A).*signC.*sum(real(z).*dy-imag(z).*dx,1);  %udy-vdx
sigma=frac(1,A).*signC.*sum(imag(z).*dy-real(z).*dx,1);  %vdy-udx
nu=frac(1,A).*signC.*sum(imag(z).*dx+real(z).*dy,1);  %udu+vdx

%Note, don't need signC in integrals with ds
momcurv=x.*imag(z)-y.*real(z);  %Instantaneous angular momentum r x v
mom=frac(1,L).*sum(momcurv.*ds,1);  % Integral ds

kecurv=frac(1,2)*abs(z).^2;  %Instantaneous kinetic energy
ke=frac(1,L).*sum(kecurv.*ds,1);  % Integral ds
%figure,plot(kecurv)

momstd=sqrt(frac(1,L).*sum(squared(momcurv-vrep(mom,size(ds,1),1)).*ds,1));

% xn=x+real(z)/100/1000;
% yn=y+imag(z)/100/1000;
% 
% [xon,yon,Ln,An,an,bn]=curvemoments(xn,yn);
% %kenorm=frac(ke'.*L',x2bar*squared(1000*100));squared(frac(1,dt*3600*24))
% exp=frac(1,2).*squared(abs(frac(sqrt(an.^2+bn.^2)-sqrt(a.^2+b.^2),sqrt(a.^2+b.^2))));

%CIRC,MOM,DIV,EXP,KE,MOMVAR]
%mom=frac(1,1000*100)*signC.*frac(1,A).*sum(imag(z).*dx-real(z).*dy,1);  %vdx-udy
%ke=frac(1,L).*frac(1,2).*sum(abs(z).^2.*ds,1);
%ke=frac(1,sum((x-mxmat).^2+(y-mymat).^2,1)).*frac(1,2).*sum(abs(z).^2./squared(100*1000),1);

vtranspose(zeta,div,sigma,nu,mom,ke,momstd);


function[]=curvemoments_test
load qgsnapshot

[cv,V,N,S,P]=psi2fields(qgsnapshot.x(2)-qgsnapshot.x(1),qgsnapshot.psi);
P=frac(P,std(P(:)));

[xc,yc]=closedcurves(qgsnapshot.x,qgsnapshot.y,P,-4);
[xo,yo,kappa,R,L,a,b,theta]=curvemoments(xc,yc);

A=0*R;
for i=1:length(xc)
    A(i,1)=polyarea(xc{i},yc{i});
end

reporttest('CURVEMOMENTS area calculation matches POLYAREA',aresame(pi*R.^2,A,2.5e-10))
%Basically the same speed as POLYAREA

zc=curveinterp(qgsnapshot.x,qgsnapshot.y,cv,xc,yc);
[zeta,div,sigma,nu,mom,ke,momstd]=curvemoments(xc,yc,zc);

% tic;[xc2,yc2]=closedcurves(qgsnapshot.x,qgsnapshot.y,P,-4,'interp',256);toc
% zc2=curveinterp(qgsnapshot.x,qgsnapshot.y,cv,xc2,yc2);
% [xo2,yo2,L2,R2,D2]=curvemoments(xc2,yc2);
% [zeta2,div2,mom2,ke2,momstd2]=curvemoments(xc2,yc2,zc2);

[xg,yg]=meshgrid(qgsnapshot.x,qgsnapshot.y);

[zetam,divm,sigmam,num]=vzeros(size(zeta));
for i=1:length(xc)
    bool=inpolygon(xg,yg,xc{i},yc{i});
    zetam(i)=mean(V(bool));
    sigmam(i)=mean(S(bool));
    num(i)=mean(N(bool));
end
% figure,
% subplot(2,2,1),plot(zeta,'.'),hold on,plot(zetam,'ro')
% subplot(2,2,2),plot(div,'.'),hold on,plot(divm,'ro')
% subplot(2,2,3),plot(sigma,'.'),hold on,plot(sigmam,'ro')
% subplot(2,2,4),plot(nu,'.'),hold on,plot(num,'ro')

err1=frac(abs(zeta-zetam).^2,frac(1,2)*abs(zeta).^2+frac(1,2)*abs(zetam).^2);
err2=frac(abs(sigma-sigmam).^2,frac(1,2)*abs(zeta).^2+frac(1,2)*abs(zetam).^2);
err3=frac(abs(nu-num).^2,frac(1,2)*abs(zeta).^2+frac(1,2)*abs(zetam).^2);
%Note I normalize by *vorticity* for strain terms, as their own magnitude
%can be close to zero and is therefore not suitable to normalize by
bool1=allall(err1(cellength(xc)>10)<0.25e-2);
bool2=allall(err2(cellength(xc)>10)<0.25e-2);
bool3=allall(err3(cellength(xc)>10)<0.25e-2);
reporttest('CURVEMOMENTS vorticity agrees with spatial average to within 0.25% for more than 10 curve points',bool1)
reporttest('CURVEMOMENTS shear strain agrees with spatial average to within 0.25% for more than 10 curve points',bool2)
reporttest('CURVEMOMENTS normal strain agrees with spatial average to within 0.25% for more than 10 curve points',bool3)

kec=curveinterp(qgsnapshot.x,qgsnapshot.y,frac(1,2)*abs(cv).^2,xc,yc);
ke2=0*ke;
for i=1:length(kec)
    ke2(i)=mean(kec{i});
end
err1=2*abs(ke-ke2).^2./(abs(ke2).^2+abs(ke).^2);
bool=allall(err1<5e-2);
reporttest('CURVEMOMENTS kinetic energy agrees to within 5%',bool)

xc1=[xc{1} xc{1} xc{1}];
yc1=[yc{1} yc{1} yc{1}];
zc1=[zc{1} zc{1} zc{1}];
[xo1,yo1,kappa1,R1,L1,a1,b1,theta1]=curvemoments(xc1,yc1);
[zeta1,div1,sigma1,nu1,mom1,ke1]=curvemoments(xc1,yc1,zc1);

clear bool
bool(1)=allall(xo1==xo(1));
bool(2)=allall(yo1==yo(1));
bool(3)=allall(kappa1==kappa(1));
bool(4)=allall(R1==R(1));
bool(5)=allall(L1==L(1));
bool(6)=allall(a1==a(1));
bool(7)=allall(b1==b(1));
bool(8)=allall(theta1==theta(1));
bool(9)=allall(zeta1==zeta(1));
bool(10)=allall(div1==div(1));
bool(11)=allall(sigma1==sigma(1));
bool(12)=allall(nu1==nu(1));
bool(13)=allall(mom1==mom(1));
bool(14)=allall(ke1==ke(1));
reporttest('CURVEMOMENTS matrix input format results match column input format',allall(bool))
