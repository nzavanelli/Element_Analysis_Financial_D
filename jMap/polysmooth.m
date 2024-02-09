function[varargout]=polysmooth(varargin)
%POLYSMOOTH  Mapping using local polynomial fitting, also known as loess.  
%
%   POLYSMOOTH generates a map from scattered data in two dimensions using
%   a locally weighted least squares fit to a polynomial.
%
%   This method is variously known as local polynomial fitting, local
%   polynomial smoothing, multivariate locally weighted least squares 
%   regression, lowess (originally for LOcally WEighted Scatterplot
%   Smoothing), and loess.  All of these are essentially synonyms.
%
%   POLYSMOOTH has the support for all of the following options:
%
%       --- Cartesian or spherical geometry
%       --- a constant, linear, or quadratic fit in space
%       --- an additional linear or quadartic fit in time
%       --- fixed-bandwidth or fixed population algorithms
%       --- prescribed spatially-varying bandwidth or population
%       --- multiple choices of weighting function or kernel
%       --- additional datapoint weighting factors, e.g. by confidence
%       --- the median-based robustification of Cleveland (1979)
%
%   POLYSMOOTH is implemented using a numerically efficient algorithm that
%   avoids using explicit loops. The data are pre-sorted so that different
%   mapping parameters can be tried out at little computational expense.
%
%   For algorithm details, see Lilly and Lagerloef (2018).
%   __________________________________________________________________
%
%   Local polynomial fitting on the plane
%
%   Let's say we have an array Z of data is at locations X,Y.  X,Y, and Z
%   can be arrays of any size provided they are all the same size.
%
%   The problem is to obtain a mapped field ZHAT on some regular grid 
%   specified by the vectors XO and YO.
%
%   Calling POLYSMOOTH is a two-step process: 
%
%       [DS,XS,YS,ZS]=TWODSORT(X,Y,Z,XO,YO,CUTOFF);
%       ZHAT=POLYSMOOTH(DS,XS,YS,[],ZS,[],RHO,H);
%
%   The empty arrays mark locations of optional arguments described later.
%
%   In the first step, one calls TWODSORT which returns ZS, a 3D array of 
%   data values at each grid point, sorted by increasing distance DS, and 
%   the corresponding positions XS and YS.  See TWODSORT for more details.
%  
%   CUTOFF determines the maximum distance included in the sorting and 
%   should be chosen to be greater than H.  
%
%   In the second step, POLYSMOOTH fits a RHOth order spatial polynomial at 
%   each gridpoint within a neighborhood specified by the "bandwidth" H.
%
%   The fit is found by minimizing the weighted mean squared error between 
%   the fitted surface and the observations.  The bandwidth H sets the 
%   decay of this weighting function, described in more detail shortly.
%
%   The fit order RHO may be chosen as RHO=0 (fit to a constant), RHO=1
%   (fit to a plane), or else RHO=2 (fit to a parabolic surface). 
%
%   The data locations (X,Y) and grid point locations (X0,Y0) shoud have
%   the same units as the bandwidth H (e.g., kilometers).
%
%   Note that H may either be a scalar, or a matrix of size M x N to
%   specify an imposed spatially-varying bandwidth. 
%
%   The dimensions of XO and YO are M x N x J, where J is the maximum
%   number of data points within bandwidth cutoff at any grid point 
%   location.  Then ZHAT is matrix of dimension M x N.
%   __________________________________________________________________
%
%   Choice of weighting function or kernel
%
%   POLYSMOOTH(DS,XS,YS,[],ZS,[],RHO,{H,KERN}) weights the data points in
%   the vicinity of each grid point by some decaying function of distance 
%   called the kernel, specified by KERN. 
%
%        KERN = 'uni' uses the uniform kernel, K=1
%        KERN = 'epa' uses the Epanechnikov (parabolic) kernel K=1-(DS/H)^2
%        KERN = 'bis' uses the bisquare kernel K=(1-(DS/H)^2)^2
%        KERN = 'tri' uses the tricubic kernel K=(1-(DS/H)^3)^3
%        KERN = 'gau' used the Gaussian kernel, K=EXP(-1/2*(3*DS/H)^2)
%
%   Note that all choices of weighting function are set to vanish for DS>H.
%
%   The default behavior is STR='gau' for the Gaussian kernel, which is 
%   specified to have a standard deviation of H/3.
%
%   KERN may also be an integer, in which the standard deviation of the 
%   Gaussian is set to H/KERN, with the default corresponding to KERN = 3.
%
%   KERN may also be a vector (of length greater than one) defining a 
%   custom kernel, with KERN(1) corresponding to DS/H=0 and KERN(end) to 
%   DS/H=1.  Kernel values at any distance are then linearly interpolated.
%   __________________________________________________________________
%
%   Inclusion of temporal variability
%
%   It may be that the data contributing to the map is taken at different
%   times, and that in constructing the map it is important to take into
%   account temporal variability of the underlying field.
%
%   In this case, data points with values Z are taken at locations X,Y and
%   also at times T. POLYSMOOTH is then called as follows:
%
%       [DS,XS,YS,TS,ZS]=TWODSORT(X,Y,T,Z,XO,YO,CUTOFF);
%       ZHAT=POLYSMOOTH(DS,XS,YS,TS,ZS,[],[RHO MU],H,TAU);
%
%   which will fit the data to the sum of spatial polynomial of bandwidth H
%   and order RHO, and a temporal polynomial of bandwidth TAU and order MU.
%
%   TAU, like H, may either be a scalar or an M x N matrix.  Its units
%   should be the same as those of the times T.  
%
%   Note that the times T should be given relative to the center of the 
%   time window, that is, time T=0 should correspond to the time at which
%   you wish to construct the map. 
%   
%   By default the Gaussian kernal is used in time.  One can also employ
%   a cell array, as in POLYSMOOTH(..,[RHO MU],H,{TAU,KERN}), to specify 
%   other behaviors for the time kernel, as described above.
%   __________________________________________________________________
%
%   Additional output arguments
%
%   [ZHAT,BETA,AUX]=POLYSMOOTH(...) returns two additional arguments.
%
%   BETA contains the estimated field, the same as ZHAT, together with 
%   estimates of all spatial derivatives of the field up to RHOth order:
% 
%        BETA(:,:,1) = ZHAT     --- The field z
%        BETA(:,:,2) = ZXHAT    --- The first derivative dz/dx
%        BETA(:,:,3) = ZYHAT    --- The first derivative dz/dy
%        BETA(:,:,4) = ZXXHAT   --- The second derivative d^2z/dx^2
%        BETA(:,:,5) = ZXYHAT   --- The second derivative d^2z/dxdy 
%        BETA(:,:,6) = ZYYHAT   --- The second derivative d^2z/dy^2
%
%   The length of the third dimension of BETA is set by the total number of
%   derivatives of order RHO or less.  This number, called Q, is equal to
%   Q = 1, 3, and 6 for RHO = 0, 1, and 2 respectively. 
%
%   After these, in the case that TS is input, the estimated time 
%   derivatives are returned up to order MU:
%
%       BETA(:,:,Q+1) = ZT   --- The first time derivative dz/dt
%       BETA(:,:,Q+2) = ZTT  --- The second time derivative d^2z/dt^2
%   
%   AUX is an M x N x 5 array of auxiliary fields associated with the fit.
%
%        AUX(:,:,1) = P  --- The total number of datapoints employed
%        AUX(:,:,2) = H  --- The bandwidth used at each point
%        AUX(:,:,3) = E  --- The rms error between the data and the fit
%        AUX(:,:,4) = W  --- The total weight used 
%        AUX(:,:,5) = R  --- The weighted mean distance to the data points
%        AUX(:,:,6) = V  --- The weighted standard deviation of data values
%        AUX(:,:,7) = C  --- The matrix condition number
%
%   P, called the population, is the total number of data points within one
%   bandwidth distance H from each of the (M,N) grid points. 
%
%   The root-mean-squared error E and standard deviation V are both 
%   computed using the same weighted kernal applied to the data.
%
%   The condition number C arises because a matrix must be inverted at each
%   (M,N) location for the RHO=1 or RHO=2 fits. C is equal to 1 for RHO=0. 
%
%   C is computed by COND.  At (M,N) points where C is large, the least 
%   squares solution is unstable, and one should consider using a lower-
%   order fit RHO or a larger value of the bandwidth H.
%   __________________________________________________________________
%
%   Fixed population
%
%   POLYSMOOTH(DS,XS,YS,[],ZS,[],RHO,P,'population') varies the spatial 
%   bandwidth H to be just large enough at each grid point to encompass P 
%   points. This is referred to here as the "fixed population" algorithm.
%
%   Note that the argument P relaces the bandwidth H.  So, if one chooses 
%   to specify a kernel, one use POLYSMOOTH(...,RHO,{P,KERN},'population'). 
%
%   When employed with the option for including a temporal fit, the fixed
%   population algorithm only applies to the spatial kernel.  The temporal 
%   kernel remains specified in terms of a temporal bandwidth. 
%
%   The fixed population algorithm can give good results when the data
%   spacing is uneven, particularly when used with a higher-order fit.
%
%   When using this method, the length of the third dimension of the fields
%   output by TWODSORT or SPHERESORT must be at least P. If it is greater 
%   than P, it may be truncated to exactly P, thus reducing the size of 
%   those fields and speeding up calculations.  This is done internally,
%   and also can be done externally by calling POLYSMOOTH_PRESORT.
%   __________________________________________________________________
%
%   Weighted data points
%
%   POLYSMOOTH can incorporate an additional weighting factor on the data
%   points. Let W be an array of positive values the same size as the data 
%   array Z.  One may form a map incorporating these weights as follows:
%
%       [DS,XS,YS,ZS,WS]=TWODSORT(X,Y,Z,W,XO,YO,CUTOFF);           
%       ZHAT=POLYSMOOTH(DS,XS,YS,[],ZS,WS,RHO,H);
%
%   The weights W could represent the confidence in the measurement values,
%   or an aggregation of invididual measurements into clusters.  The latter 
%   approach may be used to condense large datasets to a managable size.
%   __________________________________________________________________
%
%   Smoothing on the sphere
%
%   POLYSMOOTH supports a local polynomial fit on the sphere, as described
%   in Lilly and Lagerloef (2018).  As before this is a two-step process:
%
%       [DS,XS,YS,ZS]=SPHERESORT(LAT,LON,Z,LATO,LONO,CUTOFF);
%       ZHAT=POLYSMOOTH(DS,XS,YS,[],ZS,[],RHO,H);
%
%   The only different is that one firstly one calls SPHERESORT, the
%   analogue of TWODSORT for the sphere.  See SPHERESORT for more details.
%
%   The bandwidth in this case should have units of kilometers. 
%
%   Note that SPHERESORT and POLYSMOOTH both assume the sphere to be the 
%   radius of the earth, as specified by the function RADEARTH.
%
%   The derivatives appearing in BETA are now the derivatives given in a
%   local tangent plane.  These can be converted into derivatives in terms
%   of latitude and longitude following Lilly and Lagerloef (2018).
%   _________________________________________________________________
%
%   One grid, many fields
%
%   It is often the case that the field to be mapped, Z, consists of many 
%   repeated sets of observations at the same (X,Y) points. 
%
%   For example, X and Y could be mark the locations of measurements that
%   are repeated at different times (as in satellite altimetry), or else
%   there could be multiple fields Z that are measured simultaneously.  
%
%   There is a simple way to handle this situation without needing to 
%   resort the grid.  First one calls TWODSORT or SPHERESORT as follows:
%
%     [DS,XS,YS,INDEX]=TWODSORT(X,Y,XO,YO,CUTOFF);
%     --- or ---
%     [DS,XS,YS,INDEX]=SPHERESORT(LAT,LON,LATO,LONO,CUTOFF);
%
%   INDEX is now an index into the sorted datapoint locations, such that
%
%      ZS=POLYSMOOTH_INDEX(SIZE(DS),INDEX,K);
%
%   returns sorted values of Z that can be passed to POLYSMOOTH.  
%  
%   The virtue of this approach is that one only has to call TWODSORT or 
%   SPHERESORT once, no matter how many variable are to be mapped.
%   __________________________________________________________________
%
%   Robustification 
%
%   ZHAT=POLYSMOOTH(...,'robust',NI) implements the median-based iterative 
%   robust algorithm of Cleveland (1979), p 830--831, using NI iterations.  
%
%   This can be useful when outliers are present in the data.   Typically
%   a single iteration is sufficient to remove most outliers. 
%
%   ZHAT will in this case have NI+1 entries along its third dimension.
%   The iterative estimates are stored in reserve order, with the last 
%   iteration in ZHAT(:,:,1) and the original estimate in ZHAT(:,:,NI+1).
%   __________________________________________________________________
%
%   Parallelization
%
%   POLYSMOOTH(...,'parallel') parallelizes the computation using a PARFOR
%   loop, by operating on each latitude (or matrix row) separately.   This 
%   requires that Matlab's Parallel Computing toolbox be installed.  
%
%   POLYSMOOTH will then using an existing parallel pool, or if one does 
%   not exist, a pool will be created using all availabale workers.
%
%   POLYSMOOTH(...'parallel',Nworkers) alternately specifies the number of
%   workers to use. If you run into memory constraints, reduce Nworkers.
%
%   If you are working on multiple maps simultaneously, depending on the 
%   size of your problem, it may be faster to use an exterior PARFOR loop,
%   rather than calling POLYSMOOTH with the 'parallel' flag. 
%   __________________________________________________________________
%
%   Quiet option
%
%   By default, POLYSMOOTH displays a status message saying what row it is 
%   working on.  POLYSMOOTH(...,'quiet') suppresses this message.
%   ___________________________________________________
%
%   'polysmooth --t' runs some tests.
%   'polysmooth --f' generates some sample figures.
%
%   Usage:  [ds,xs,ys,zs]=twodsort(x,y,z,xo,yo,cutoff);  
%           zhat=polysmooth(ds,xs,ys,[],zs,[],rho,H);
%           [zhat,beta,aux]=polysmooth(ds,xs,ys,[],zs,[],rho,H);
%   --or--
%           [ds,xs,ys,zs,ws]=spheresort(lat,lon,z,w,lato,lono,cutoff); 
%           [zhat,beta,aux]=polysmooth(ds,xs,ys,[],zs,[],rho,H);
%   __________________________________________________________________
%   This is part of JLAB --- type 'help jlab' for more information
%   (C) 2008--2020 J.M. Lilly --- type 'help jlab_license' for details
 
%   'polysmooth --f2' with jData installed generates the figure shown
%       above, which may require a relatively powerful computer.

if strcmpi(varargin{1}, '--t')
    polysmooth_test,return
elseif strcmpi(varargin{1}, '--f')
    type makefigs_polysmooth
    makefigs_polysmooth;
    return
elseif strcmpi(varargin{1}, '--f2')
    type makefigs_polysmooth2
    makefigs_polysmooth2;
    return
end

mu=0;
targ=[];
tau=[];
str='cells';
skern='gaussian';
tkern='gaussian';
geostr='cartesian';
varstr='bandwidth';
robstr='non';
verbstr='verbose';
iters=0;
Nworkers=[];

%First parse the string arguments
for i=1:5
    if ischar(varargin{end})
        tempstr=varargin{end};
        if strcmpi(tempstr(1:3),'car')||strcmpi(tempstr(1:3),'sph')
            geostr=tempstr;
        elseif strcmpi(tempstr(1:3),'ver')||strcmpi(tempstr(1:3),'qui')
            verbstr=tempstr;
        elseif strcmpi(tempstr(1:3),'cel')||strcmpi(tempstr(1:3),'par')
            str=tempstr;
        elseif strcmpi(tempstr(1:3),'ban')||strcmpi(tempstr(1:3),'pop')
            varstr=tempstr;
        end
        varargin=varargin(1:end-1);
    elseif ~ischar(varargin{end})&&ischar(varargin{end-1})
        tempstr=varargin{end-1};
        if strcmpi(tempstr(1:3),'rob')||strcmpi(tempstr(1:3),'non')
            robstr=tempstr;
            iters=varargin{end};
        elseif strcmpi(tempstr(1:3),'par')
            str=tempstr;
            Nworkers=varargin{end};
        end
        varargin=varargin(1:end-2);
    end
end

pool = gcp('nocreate');
if strcmpi(str(1:3),'par')
    if isempty(Nworkers)
        if isempty(pool)
            parpool('local');
        end
    else
        if ~isempty(pool)
            parpool('local',Nworkers);
        elseif pool.NumWorkders~=Nworkers
            parpool('local',Nworkers);
        end
    end
end

d=varargin{1};
x=varargin{2};
y=varargin{3};
t=varargin{4};
z=varargin{5};
w=varargin{6};
rho=varargin{7};
sarg=varargin{8};
if length(varargin)==9
    targ=varargin{9};
end
 
if iscell(sarg)
    H=sarg{1};
    skern=sarg{2};
else
    H=sarg;
end

if iscell(targ)
    tau=targ{1};
    tkern=targ{2};
else
    tau=targ;
end

%this might be of length 2
if length(rho)==2
    mu=rho(2);
    rho=rho(1);
end

%Issue a warning if both T and TAU are empty or non-empty
if ~allall([isempty(t),isempty(tau)])&&...
    ~all([~isempty(t),~isempty(tau)])
    disp('POLYSMOOTH needs TS and TAU to be nonempty for a temporal fit.')
    tau=[];
end

% if isempty(tau)
%     disp(['POLYSMOOTH performing an order ' int2str(rho) ' spatial fit using a ' skern ' kernel.'])
% else
%     disp(['POLYSMOOTH performing an order ' int2str(rho) ' spatial fit using a ' skern ' kernel,'])
%     disp(['plus an order ' int2str(mu) ' temporal fit using a ' tkern ' kernel.'])
% end
%--------------------------------------------------------------------------
%vsize(x,y,t,z,w,xo,yo)
%size(H)
%tau,rho,mu,skern,tkern,varstr,str
%vsize(d,x,y,t,z,w)

if ~iscell(d)
    d(~isfinite(z))=nan;    %Set distance to nan for missing data; also swap infs for nans
    [d,x,y,t,z,w]=polysmooth_presort(d,x,y,t,z,w,H,tau,varstr);
    %This can speed things up if you have a lot of missing data. If you don't
    %sort, then you end up doing a lot of extra operations, because you can't
    %truncate the matrix.
    zhat=nan*zeros(size(d,1),size(d,2),iters+1);
else
    zhat=nan*zeros(length(d),maxmax(cellsize(d,2)),iters+1);
end

wo=w;
while iters+1>0
    if strcmpi(str(1:3),'cel')
        [beta,aux,res]=polysmooth_cells(d,x,y,t,z,w,H,tau,rho,mu,skern,tkern,varstr,verbstr);
    elseif strcmpi(str(1:3),'par')
        [beta,aux,res]=polysmooth_cells_parallel(d,x,y,t,z,w,H,tau,rho,mu,skern,tkern,varstr,verbstr);
    else
        error(['Algorithm type ' str ' is not supported.'])
    end
    %vsize(d,beta,zhat)
    zhat(:,:,iters+1)=beta(:,:,1);
    %----------------------------------------------------------------------
    %See Cleveland (1979), p 830--831
    %Note to self, this doesn't work with my loop testing nor with parallel
    if iters>=1
        disp(['Robustification iteration #' int2str(size(zhat,3)-iters) '.'])
        s=vrep(vmedian(abs(res),3),size(res,3),3);
        delta=squared(1-squared(frac(res,6*s)));
        delta(frac(res,6*s)>1)=0;
        %length(find(delta==0))
        %This gives new robustness weights for next iteration
        %vsize(d,x,y,s,z,wo,delta,res)
        if isempty(wo)
            w=delta;
        else
            w=wo.*delta;  
        end
    end
    %----------------------------------------------------------------------
    iters=iters-1;
end
%Adjustment for complex-valued data
if ~allall(isreal(beta(:,:,1)))
    beta(isnan(real(beta(:))))=nan+sqrt(-1)*nan;
end
varargout{1}=zhat;
varargout{2}=beta;
varargout{3}=aux;

function[beta,aux,res]=polysmooth_cells(ds,xs,ys,ts,zs,ws,H,tau,rho,mu,skern,tkern,varstr,verbstr)
%maxmax(ts(isfinite(zs))),minmin(ts(isfinite(zs)))
M=length(ds);
N=maxmax(cellsize(ds,2));
Q=sum(0:rho+1)+mu;
%rho,mu, Q
%M,N,Q

mat=zeros(N,Q,Q);
vect=zeros(N,Q,1);
beta=nan*zeros(M,N,Q);
aux=nan*zeros(M,N,7);
[C,res,aux1,aux2,err,aux4,aux5,V,C]=vzeros(M,N,'nan');
C=ones(size(C));%initialize C to ones for the case of rho=1

if length(H)==1
    H=H+zeros(length(ds),1);
end
if ~isempty(ds)
   for i=1:M
        if strcmpi(verbstr(1:3),'ver')
            disp(['Polysmooth computing map for row ' int2str(i) ' of ' int2str(M) '.'])
        end
        if ~isempty(ds{i})
            %don't set distance to 0; we need to know the distance 
            [xs{i},ys{i},zs{i}]=vswap(xs{i},ys{i},zs{i},nan,0); 
            %length(find(isnan(vcolon(zs{i}))))
            %ds{i}=vswap(ds{i},nan,inf);
            %vsize(ds,xs,ys,ts,zs,ws,H,tau,rho,mu,skern,tkern,varstr)
            if strcmpi(varstr(1:3),'pop')  %Input H was actually P
                if isempty(ws)
                    Hi=polysmooth_bandwidth(H(i),ds{i},[]);  
                else
                    Hi=polysmooth_bandwidth(H(i),ds{i},ws{i}); 
                end
            else
                Hi=H(i);
            end
            
            if isempty(ws)
                W=polysmooth_kernel(ds{i},[],Hi,skern);
            else
                W=polysmooth_kernel(ds{i},ws{i},Hi,skern);
            end
            %figure,jpcolor(W(:,:,1))
            
            %multiply by the temporal weighting kernel, if requested
            if ~isempty(tau)
                %vsize(ts,ws,tau,tkern)
                W=W.*polysmooth_kernel(ts,ws,tau,tkern);
            end
            %figure,plot(W)
            %figure,jpcolor(log10(W(:,:,1)))            
            %faster to bring this inside the parfor loop because then 
            %you don't have to keep mat and vect for the earth in memory
            
            if isempty(ts)
                X=squeeze(polysmooth_xmat(xs{i},ys{i},[],rho,mu));
            else
                X=squeeze(polysmooth_xmat(xs{i},ys{i},ts{i},rho,mu));
            end
            %X is N x lons x Q
            XtimesW=X.*vrep(W,Q,3);
            XT=permute(X,[1 2 4 3]);
            %XT is N x lons x 1 x Q
            mat=squeeze(sum(vrep(XT,Q,3).*vrep(XtimesW,Q,4),1));
            vect=squeeze(sum(XtimesW.*vrep(zs{i},Q,3),1));
            
            if Q==1
                %simplifications possible for the local constant fit
                %Weird indexing here is to keep parfor from complaining
                %mat2=sum(W,1);%aresame(mat,mat2)
                %vect=squeeze(sum(W.*zs{i},1));
 
                betai=vect./mat;
                beta(i,:,:)=betai;
                %res=zs{i}-beta(i,:,:);
            else
               invmat=matinv(mat);
               beta(i,:,:)=matmult(invmat,vect,2);
            end
            %length(find(~isnan(mat(:))))
            %length(find(~isnan(vect(:))))
            res=zs{i}-sum(X.*vrep(beta(i,:,:),size(X,1),1),3);

            if rho>1
                for j=1:N
                    C(i,j)=cond(squeeze(mat(j,:,:)));
                end
            end
         
            %Have to assign individually for parfor not to complain 
            sumW=sum(W,1);
            aux1(i,:)=sum((W>0),1);             %population P
            aux2(i,:)=Hi;                       %bandwidth H
            err(i,:)=sqrt(sum(W.*squared(res),1)./sumW); %rms error E
            aux4(i,:)=sum(W,1);                 %total weight
            aux5(i,:)=sum(W.*ds{i},1)./sumW;    %weighted mean distance R   
            zbar=sum(W.*zs{i},1)./sumW;
            zbar=vrep(zbar,size(zs{i},1),1);
            V(i,:)=sqrt(sum(W.*squared(zs{i}-zbar),1)./sumW); %intercell standard deviation V
        end
    end
    aux(:,:,1)=aux1;             %population P
    aux(:,:,2)=aux2;             %bandwidth H
    aux(:,:,3)=err;              %rms error E
    aux(:,:,4)=aux4;             %total weight
    aux(:,:,5)=aux5;             %weighted mean distance R   
    aux(:,:,6)=V;                %intercell standard deviation V
    aux(:,:,7)=vswap(C,inf,nan); %condition number C
end

function[beta,aux,res]=polysmooth_cells_parallel(ds,xs,ys,ts,zs,ws,H,tau,rho,mu,skern,tkern,varstr,verbstr)
%this is exactly the smae as the above but with a parfor instead of a for
M=length(ds);
N=maxmax(cellsize(ds,2));
Q=sum(0:rho+1)+mu;
%rho,mu, Q
%M,N,Q

mat=zeros(N,Q,Q);
vect=zeros(N,Q,1);
beta=nan*zeros(M,N,Q);
aux=nan*zeros(M,N,7);
[C,res,aux1,aux2,err,aux4,aux5,V,C]=vzeros(M,N,'nan');
C=ones(size(C));%initialize C to ones for the case of rho=1

if length(H)==1
    H=H+zeros(length(ds),1);
end
if ~isempty(ds)
   parfor i=1:M
        if strcmpi(verbstr(1:3),'ver')
            disp(['Polysmooth computing map for row ' int2str(i) ' of ' int2str(M) '.'])
        end
        if ~isempty(ds{i})
            %don't set distance to 0; we need to know the distance 
            [xs{i},ys{i},zs{i}]=vswap(xs{i},ys{i},zs{i},nan,0); 
            %ds{i}=vswap(ds{i},nan,inf);
            %vsize(ds,xs,ys,ts,zs,ws,H,tau,rho,mu,skern,tkern,varstr)
            if strcmpi(varstr(1:3),'pop')  %Input H was actually P
                if isempty(ws)
                    Hi=polysmooth_bandwidth(H(i),ds{i},[]);  
                else
                    Hi=polysmooth_bandwidth(H(i),ds{i},ws{i}); 
                end
            else
                Hi=H(i);
            end

            if isempty(ws)
                W=polysmooth_kernel(ds{i},[],Hi,skern);
            else
                W=polysmooth_kernel(ds{i},ws{i},Hi,skern);
            end
            %figure,jpcolor(W(:,:,1))
            
            %multiply by the temporal weighting kernel, if requested
            if ~isempty(tau)
                %vsize(ts,ws,tau,tkern)
                W=W.*polysmooth_kernel(ts,ws,tau,tkern);
            end
            %figure,plot(W)
            %figure,jpcolor(log10(W(:,:,1)))            
            %faster to bring this inside the parfor loop because then 
            %you don't have to keep mat and vect for the earth in memory
            
            if isempty(ts)
                X=squeeze(polysmooth_xmat(xs{i},ys{i},[],rho,mu));
            else
                X=squeeze(polysmooth_xmat(xs{i},ys{i},ts{i},rho,mu));
            end
            %X is N x lons x Q
            XtimesW=X.*vrep(W,Q,3);
            XT=permute(X,[1 2 4 3]);
            %XT is N x lons x 1 x Q
            mat=squeeze(sum(vrep(XT,Q,3).*vrep(XtimesW,Q,4),1));
            vect=squeeze(sum(XtimesW.*vrep(zs{i},Q,3),1));
            
            if Q==1
                %simplifications possible for the local constant fit
                %Weird indexing here is to keep parfor from complaining
                %mat2=sum(W,1);%aresame(mat,mat2)
                %vect=squeeze(sum(W.*zs{i},1));
                betai=vect./mat;
                beta(i,:,:)=betai;
                %res=zs{i}-beta(i,:,:);
            else
               invmat=matinv(mat);
               beta(i,:,:)=matmult(invmat,vect,2);
            end
            res=zs{i}-sum(X.*vrep(beta(i,:,:),size(X,1),1),3);

            if rho>1
                for j=1:N
                    C(i,j)=cond(squeeze(mat(j,:,:)));
                end
            end
         
            %Have to assign individually for parfor not to complain 
            sumW=sum(W,1);
            aux1(i,:)=sum((W>0),1);             %population P
            aux2(i,:)=Hi;                       %bandwidth H
            err(i,:)=sqrt(sum(W.*squared(res),1)./sumW); %rms error E
            aux4(i,:)=sum(W,1);                 %total weight
            aux5(i,:)=sum(W.*ds{i},1)./sumW;    %weighted mean distance R   
            zbar=sum(W.*zs{i},1)./sumW;
            zbar=vrep(zbar,size(zs{i},1),1);
            V(i,:)=sqrt(sum(W.*squared(zs{i}-zbar),1)./sumW); %intercell standard deviation V
        end
    end
    aux(:,:,1)=aux1;             %population P
    aux(:,:,2)=aux2;             %bandwidth H
    aux(:,:,3)=err;              %rms error E
    aux(:,:,4)=aux4;             %total weight
    aux(:,:,5)=aux5;             %weighted mean distance R   
    aux(:,:,6)=V;                %intercell standard deviation V
    aux(:,:,7)=vswap(C,inf,nan); %condition number C
end

function[X]=polysmooth_xmat(x,y,t,rho,mu)
Q1=sum(0:rho+1);
Q=sum(0:rho+1)+mu;
X=ones(size(x,1),size(x,2),size(x,3),Q);
if rho>=1
    X(:,:,:,2)=x;
    X(:,:,:,3)=y;
end
if rho==2
    X(:,:,:,4)=frac(1,2)*x.^2;  
    X(:,:,:,5)=x.*y;
    X(:,:,:,6)=frac(1,2)*y.^2;   
end
if mu>=1
    X(:,:,:,Q1+1)=t;
end
if mu==2
    X(:,:,:,Q1+2)=frac(1,2)*t.^2;
end
function[]=polysmooth_test

%tstart=tic;polysmooth_test_cartesian;toc(tstart)
%tstart=tic;polysmooth_test_sphere;toc(tstart)
polysmooth_test_tangentplane;

function[]=polysmooth_test_tangentplane

%Testing tangent plane equations from Lilly and Lagerloef
load goldsnapshot
use goldsnapshot

phip=vshift(lat,-1,1);
phin=vshift(lat,1,1);
thetap=vshift(lon,-1,1);
thetan=vshift(lon,1,1);

[long,latg]=meshgrid(lon,lat);
[thetapg,phipg]=meshgrid(thetap,phip);
[thetang,phing]=meshgrid(thetan,phin);

xp=radearth*cosd(latg).*sind(thetapg-long);
xn=radearth*cosd(latg).*sind(thetang-long);
yp=radearth*(cosd(latg).*sind(phipg)-sind(latg).*cosd(phipg));%.*cosd(thetapg-long));
yn=radearth*(cosd(latg).*sind(phing)-sind(latg).*cosd(phing));%.*cosd(thetang-long));

for i=1:4
    if i==1
        ssh=latg;
    elseif i==2
        ssh=squared(latg);
    elseif i==3
        ssh=squared(long);
    elseif i==4
        ssh=goldsnapshot.ssh;
    end
    
    sshp=vshift(ssh,-1,2);
    sshn=vshift(ssh,1,2);
    dZdx=frac(sshn-sshp,xn-xp);
    
    sshp=vshift(ssh,-1,1);
    sshn=vshift(ssh,1,1);
    dZdy=frac(sshn-sshp,yn-yp);
    
    [fx,fy]=spheregrad(lat,lon,ssh);
    fx=fx*1000;fy=fy*1000;
 
    %figure,
    %subplot(1,3,1),jpcolor(fx),caxis([-1 1]/5)
    %subplot(1,3,2),jpcolor(dZdx),caxis([-1 1]/5)
    %subplot(1,3,3),jpcolor(fx-dZdx),caxis([-1 1]/1000/1000/5)
    
    %figure
    %subplot(1,3,1),jpcolor(fy),caxis([-1 1]/5)
    %subplot(1,3,2),jpcolor(dZdy),caxis([-1 1]/5)
    %subplot(1,3,3),jpcolor(fy-dZdy),caxis([-1 1]/1000/1000/5)
    
    %Gradients agree to like one part in one million
    
    del2=spherelap(lat,lon,ssh)*1000*1000;
    
    sshp=vshift(ssh,-1,2);
    sshn=vshift(ssh,1,2);
    %d2Zdx2=frac(2,xn-xp).*(frac(sshn-ssh,xn)-frac(ssh-sshp,-xp));
    d2Zdx2=frac(1,squared((xn-xp)/2)).*(sshn+sshp-2*ssh);
    
    sshp=vshift(ssh,-1,1);
    sshn=vshift(ssh,1,1);
    %d2Zdy2=frac(2,yn-yp).*(frac(sshn-ssh,yn)-frac(ssh-sshp,-yp));
    d2Zdy2=frac(1,squared((yn-yp)/2)).*(sshn+sshp-2*ssh);
    
    del2hat=d2Zdx2+d2Zdy2-frac(tand(lat),radearth).*dZdy;
    %del2hat=d2Zdx2+d2Zdy2;%-frac(tand(lat),radearth).*dZdy;
        
    if i==1
        index=find(abs(latg)<89.5);
        bool=allall(log10(abs(del2hat(index)-del2(index))./abs(del2(index)))<-5);
        reporttest('POLYSMOOTH Laplacian of linear function of y',bool)
    elseif i==2
        %figure,plot(lat,log10(abs(del2))),hold on,plot(lat,log10(abs(del2-del2hat)))
        index=find(abs(latg)<88.5);
        bool=allall(log10(abs(del2hat(index)-del2(index)))<-6);
        reporttest('POLYSMOOTH Laplacian of quadratic function of y',bool)
    elseif i==3
        %figure, plot(lon,log10(abs(del2-del2hat)./abs(del2))')
        index=find(abs(long)<178.5&isfinite(del2hat));
        %length(find(~isfinite(del2)))
        %length(find(~isfinite(del2hat)))
        bool=allall(log10(abs(del2hat(index)-del2(index))./abs(del2(index)))<-5);
        reporttest('POLYSMOOTH Laplacian of quadratic function of x',bool)
    elseif i==4
        xx=log10(abs(fx-dZdx)./abs(fx));
        index=find(isfinite(xx));
        bool=allall(xx(index)<-5);
        reporttest('POLYSMOOTH longitude gradient of GOLDSNAPSHOT',bool)
        yy=log10(abs(fy-dZdy)./abs(fy));
        index=find(isfinite(yy));
        bool=allall(yy(index)<-5);
        reporttest('POLYSMOOTH latitude gradient of GOLDSNAPSHOT',bool)
        %figure
        %subplot(1,3,1),jpcolor(log10(abs(del2))),caxis([-3 0])
        %subplot(1,3,2),jpcolor(log10(abs(del2hat))),caxis([-3 0])
        %subplot(1,3,3),jpcolor(log10(abs(del2-del2hat))),caxis([-3 0])
    end
end

function[]=polysmooth_test_cartesian

%Use peaks for testing... random assortment
[x,y,z]=peaks;
index=randperm(length(z(:)));
index=index(1:200);
[xdata,ydata,zdata]=vindex(x(:),y(:),z(:),index,1);

xo=(-3:.5:3);
yo=(-3:.6:3);

H=2;

for i=0:2
    [ds,xs,ys,zs]=twodsort(xdata,ydata,zdata,xo,yo,H);
    %tic;[z1,beta1]=polysmooth(xdata,ydata,[],zdata,[],xo,yo,i,{H,'epan'},'loop');etime1=toc;
    tic;[z2,beta2]=polysmooth(ds,xs,ys,[],zs,[],i,{H,'epan'});etime2=toc;
    
    %disp(['POLYSMOOTH was ' num2str(etime1./etime2) ' times faster than loop, zeroth-order fit.'])
    
    tol=1e-8;
   %b1=aresame(z1,z2,tol)&&aresame(beta1,beta2,tol);
    %reporttest(['POLYSMOOTH speed and loop methods are identical for order ' int2str(i) ' fit'],b1)
end

function[]=polysmooth_test_sphere
 
%Use peaks for testing... random assortment
rng(0);
[x,y,z]=peaks;
index=randperm(length(z(:)));
index=index(1:1000);

%Convert to Lat and Longitude
lon=x.*60;
lat=y.*30;

[latdata,londata,zdata]=vindex(lat(:),lon(:),z(:),index,1);
wdata=10*abs(rand(size(zdata)));  %For heavy data point test

lono=(-180:20:180);
lato=(-90:20:90);

H=2000;

for i=0:2
    [ds,xs,ys,zs,ws]=spheresort(latdata,londata,zdata,wdata,lato,lono,H);
   % tic;[z1,beta1]=polysmooth(latdata,londata,[],zdata,[],lato,lono,i,{H,'epan'},'loop','sphere');etime1=toc;
    tic;[z2,beta2]=polysmooth(ds,xs,ys,[],zs,[],i,{H,'epan'});etime2=toc;
    
   % disp(['POLYSMOOTH was ' num2str(etime1./etime2) ' times faster than loop, zeroth-order fit.'])
    
    %tol=1e-8;
    %b1=aresame(z1,z2,tol)&&aresame(beta1,beta2,tol);
    %reporttest(['POLYSMOOTH speed and loop methods are identical for order ' int2str(i) ' fit'],b1)
end


%ok, this test shows large outliers are removed in a single iteration
%znoisy=zdata+randn(size(zdata));
% znoisy=zdata;
% znoisy(500)=200;
% [ds,xs,ys,zs,znoisys]=spheresort(latdata,londata,zdata,znoisy,lato,lono,H);
% tic;[z2,beta2]=polysmooth(ds,xs,ys,[],zs,[],2,{H,'epan'});etime2=toc;
% tic;zhat=polysmooth(ds,xs,ys,[],znoisys,[],0,{H,'epan'},'robust',5);etime2=toc;

% %Zeroth-order fit at 200~km radius
% [zhat0,rbar,beta,b]=polysmooth(ds,xs,ys,[],zs,[],200,0,'sphere');
% 
% figure
% contourf(lono,lato,zhat0,[0:1/2:50]),nocontours,caxis([0 45]),
% latratio(30),[h,h2]=secondaxes;topoplot continents,
% title('Standard Deviation of SSH from TPJAOS.MAT, mapped using 200~km smoothing')
% hc=colorbar('EastOutside');axes(hc);ylabel('SSH Standard Deviation (cm)')
% set(h,'position',get(h2,'position'))
% 
% currentdir=pwd;
% cd([whichdir('jlab_license') '/figures'])
% print -dpng alongtrack_std_constant
% crop alongtrack_std.png
% cd(currentdir)


