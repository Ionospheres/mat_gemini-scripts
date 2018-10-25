%FLIES A VIRTUAL SPACECRAFT THROUGH THE MODEL
% only works with a cartesian grid for now, and I've found that the code will only work in a reasonable amount of time with plaid interpolations...


%INPUT DATA
direc='~/zettergmdata/simulations/Aether_discrete'

addpath ../script_utils;


%%READ IN THE SIMULATION INFORMATION
[ymd0,UTsec0,tdur,dtout,flagoutput,mloc]=readconfig([direc,filesep,'inputs', filesep, 'config.ini']);
ymd=ymd0; UTsec=UTsec0;


%CHECK WHETHER WE NEED TO RELOAD THE GRID (WHICH CAN BE TIME CONSUMING)
if ~exist('xg','var')
  fprintf('Loading grid...\n');
  xg = readgrid([direc,filesep,'inputs',filesep]);
  lx1=xg.lx(1); lx2=xg.lx(2); lx3=xg.lx(3);
  x1=xg.x1(3:end-2); x2=xg.x2(3:end-2); x3=xg.x3(3:end-2);
  [X2,X1,X3]=meshgrid(x2,x1,x3);

  %In case the simulation is cartesian we need to know the center geomgagetic coordinates of the grid
  thetactr=mean(xg.theta(:));
  phictr=mean(xg.phi(:));
  [glatctr,glonctr]=geomag2geog(thetactr,phictr);
end


%% COMPUTE SOURUCE LOCATION IN MCOORDS
if ~isempty(mloc)
 mlatctr=mloc(1);
 mlonctr=mloc(2);
else
 mlatctr=[];
 mlonctr=[];
end


%TIMES WHERE WE HAVE MODEL OUTPUT
times=UTsec0:dtout:UTsec0+tdur;
lt=numel(times);
datemod0=datenum([ymd0,UTsec0/3600,0,0]);
datemod=datemod0:dtout/86400:datemod0+tdur/86400;


%DEFINE SOME SORT OF SATELLITE ORB.
%Use a common time bases for all satellites (facilitates processes without having to reread files too much)
lorb=3000;    %number of times series for satellite orbit
UTsat=linspace(min(times),max(times),lorb);
ymdsat=repmat(ymd0,[lorb,1]);
datevecsat=[ymdsat,UTsat(:)/3600,zeros(lorb,1),zeros(lorb,1)];
datesat=datenum(datevecsat);

%THIS IS A TEST FOR AETHER
vsp=7e3;                %spacecraft velocity
toffset=linspace(0,180,12);      %spacecraft separations in seconds
ltoffset=numel(toffset);
lsat=ltoffset;
ysp0=min(xg.x3(:));     %spacecraft reference point is the end of the grid in N-S
ysp=zeros(lorb,ltoffset);
for itoffset=1:ltoffset
  ysp(:,itoffset)=ysp0+vsp*((datesat-datesat(1))*86400-toffset(itoffset));
end
xsp=zeros(lorb,ltoffset);
zsp=500e3*ones(lorb,ltoffset);
[altsat,glonsat,glatsat]=UEN2geog(zsp,xsp,ysp,thetactr,phictr);


%ATTEMPT TO COMPUTE FOR VARIOUS SPACECRAFT IN PARALLEL
parpool(floor(lsat/2));

%THIS IS A BASIC TWO SATELLITE TEST
%{
%Individual orbit alt,lon,lat
lsat=2;    %number of satellites
thetasat(:,1)=linspace(min(xg.theta(:)),max(xg.theta(:)),lorb);
phisat(:,1)=linspace(min(xg.phi(:)),max(xg.phi(:)),lorb);
altsat(:,1)=linspace(100e3,600e3,lorb);
thetasat(:,2)=flipud(thetasat(:,1));
phisat(:,2)=flipud(phisat(:,1));
altsat(:,2)=flipud(altsat(:,1));
glatsat=zeros(lorb,lsat);
glonsat=zeros(lorb,lsat);
for isat=1:lsat
  [glatsattmp,glonsattmp]=geomag2geog(thetasat(:,isat),phisat(:,isat));
  glatsat(:,isat)=glatsattmp(:);
  glonsat(:,isat)=glonsattmp(:);
end
%}

%MAIN LOOP OVER ORBIT SEGMENTS
datebufprev=datemod0;
datebufnext=datemod0;
neprev=[]; nenext=[];
viprev=[]; vinext=[];
Tiprev=[]; Tinext=[];
Teprev=[]; Tenext=[];
J1prev=[]; J1next=[];
J2prev=[]; J2next=[];
J3prev=[]; J3next=[];
v2prev=[]; v2next=[];
v3prev=[]; v3next=[];
nesat=zeros(lorb,lsat);
visat=zeros(lorb,lsat);
Tisat=zeros(lorb,lsat);
Tesat=zeros(lorb,lsat);
J1sat=zeros(lorb,lsat);
J2sat=zeros(lorb,lsat);
J3sat=zeros(lorb,lsat);
v2sat=zeros(lorb,lsat);
v3sat=zeros(lorb,lsat);
for iorb=1:lorb
  datenow=datesat(iorb);


  %FIND THE TWO FRAMES THAT BRACKET THIS ORBIT TIME
  datemodnext=datemod0;
  datemodprev=datemod0;
  while(datemodnext<datenow & datemodnext<=datemod(end))
    datemodprev=datemodnext;
    datemodnext=datemodnext+dtout/86400;    %matlab datenums are in units of days from 0000
  end
  datestr(datemodprev),datestr(datenow),datestr(datemodnext)


  if (datemodnext==datemodprev | datemodnext>datemod(end))    %set everything to NaNs if outside model time domain
    fprintf('Requested time is out of bounds...\n');
    neprev=zeros(lx1,lx2,lx3); nenext=neprev;
    viprev=neprev; vinext=neprev;
    Tiprev=neprev; Tinext=neprev;
    Teprev=neprev; Tenext=neprev;
    J1prev=neprev; J1next=neprev;
    J2prev=neprev; J2next=neprev;
    J3prev=neprev; J3next=neprev;
    v2prev=neprev; v2next=neprev;
    v3prev=neprev; v3next=neprev;
    datestr(datenow)
  else     %go ahead and read in data and set up the interpolations
    %DATA BUFFER UPDATES
    if (datebufprev~=datemodprev | isempty(neprev))    %need to reload the previous output frame data buffers
      fprintf('Loading previous buffer...\n');
      datevecmodprev=datevec(datemodprev);
      ymd=datevecmodprev(1:3);
      UTsec=datevecmodprev(4)*3600+datevecmodprev(5)*60+datevecmodprev(6);
      UTsec=round(UTsec);    %some accuracy problems...  this is fishy and an infuriating kludge that needs to be fixed...
      [ne,mlatsrc,mlonsrc,v1,Ti,Te,J1,v2,v3,J2,J3,filename,Phitop]=loadframe(direc,UTsec,ymd,UTsec0,ymd0,mloc,xg);
      neprev=ne; viprev=v1; Tiprev=Ti; Teprev=Te;
      J1prev=J1; J2prev=J2; J3prev=J3; v2prev=v2; v3prev=v3;
      clear ne v1 Ti Te J1 v2 v3 J2 J3 Phitop;    %avoid keeping extra copies of large data
      datebufprev=datemodprev; 
    end
    if (datebufnext~=datemodnext | isempty(nenext))    %need to reload the next output frame data buffers
      fprintf('Loading next buffer...\n');
      datevecmodnext=datevec(datemodnext);
      ymd=datevecmodnext(1:3);
      UTsec=datevecmodnext(4)*3600+datevecmodnext(5)*60+datevecmodnext(6);
      UTsec=round(UTsec);
      [ne,mlatsrc,mlonsrc,v1,Ti,Te,J1,v2,v3,J2,J3,filename,Phitop]=loadframe(direc,UTsec,ymd,UTsec0,ymd0,mloc,xg);
      nenext=ne; vinext=v1; Tinext=Ti; Tenext=Te;
      J1next=J1; J2next=J2; J3next=J3; v2next=v2; v3next=v3;
      clear ne v1 Ti T3 J1 v2 v3 J2 J3 Phitop;    %avoid keeping extra copies of large data
      datebufnext=datemodnext;
    end
  end


    %INTERPOLATIONS
    parfor isat=1:lsat
      [x1sat,x2sat,x3sat]=geog2UEN(altsat(iorb,isat),glonsat(iorb,isat),glatsat(iorb,isat),thetactr,phictr);
      fprintf('Starting interpolations for satellite:  %d\n',isat);
      nesatprev=interp3(X2,X1,X3,neprev,x2sat,x1sat,x3sat);
      visatprev=interp3(X2,X1,X3,viprev,x2sat,x1sat,x3sat);
      Tisatprev=interp3(X2,X1,X3,Tiprev,x2sat,x1sat,x3sat);
      Tesatprev=interp3(X2,X1,X3,Teprev,x2sat,x1sat,x3sat);
      J1satprev=interp3(X2,X1,X3,J1prev,x2sat,x1sat,x3sat);
      J2satprev=interp3(X2,X1,X3,J2prev,x2sat,x1sat,x3sat);
      J3satprev=interp3(X2,X1,X3,J3prev,x2sat,x1sat,x3sat);
      v2satprev=interp3(X2,X1,X3,v2prev,x2sat,x1sat,x3sat);
      v3satprev=interp3(X2,X1,X3,v3prev,x2sat,x1sat,x3sat);
  
      nesatnext=interp3(X2,X1,X3,nenext,x2sat,x1sat,x3sat);
      visatnext=interp3(X2,X1,X3,vinext,x2sat,x1sat,x3sat);
      Tisatnext=interp3(X2,X1,X3,Tinext,x2sat,x1sat,x3sat);
      Tesatnext=interp3(X2,X1,X3,Tenext,x2sat,x1sat,x3sat);
      J1satnext=interp3(X2,X1,X3,J1next,x2sat,x1sat,x3sat);
      J2satnext=interp3(X2,X1,X3,J2next,x2sat,x1sat,x3sat);
      J3satnext=interp3(X2,X1,X3,J3next,x2sat,x1sat,x3sat);
      v2satnext=interp3(X2,X1,X3,v2next,x2sat,x1sat,x3sat);
      v3satnext=interp3(X2,X1,X3,v3next,x2sat,x1sat,x3sat);
  
      nesattmp(isat)=nesatprev+(nesatnext-nesatprev)/(datemodnext-datemodprev)*(datenow-datemodprev);
      visattmp(isat)=visatprev+(visatnext-visatprev)/(datemodnext-datemodprev)*(datenow-datemodprev);
      Tisattmp(isat)=Tisatprev+(Tisatnext-Tisatprev)/(datemodnext-datemodprev)*(datenow-datemodprev);
      Tesattmp(isat)=Tesatprev+(Tesatnext-Tesatprev)/(datemodnext-datemodprev)*(datenow-datemodprev);
      J1sattmp(isat)=J1satprev+(J1satnext-J1satprev)/(datemodnext-datemodprev)*(datenow-datemodprev);
      J2sattmp(isat)=J2satprev+(J2satnext-J2satprev)/(datemodnext-datemodprev)*(datenow-datemodprev);
      J3sattmp(isat)=J3satprev+(J3satnext-J3satprev)/(datemodnext-datemodprev)*(datenow-datemodprev);
      v2sattmp(isat)=v2satprev+(v2satnext-v2satprev)/(datemodnext-datemodprev)*(datenow-datemodprev);
      v3sattmp(isat)=v3satprev+(v3satnext-v3satprev)/(datemodnext-datemodprev)*(datenow-datemodprev);
    end
    nesat(iorb,:)=nesattmp(:)';
    visat(iorb,:)=visattmp(:)';
    Tisat(iorb,:)=Tisattmp(:)';
    Tesat(iorb,:)=Tesattmp(:)';
    J1sat(iorb,:)=J1sattmp(:)';
    J2sat(iorb,:)=J2sattmp(:)';
    J3sat(iorb,:)=J3sattmp(:)';
    v2sat(iorb,:)=v2sattmp(:)';
    v3sat(iorb,:)=v3sattmp(:)';
end

rmpath ../script_utils;

