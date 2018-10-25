function xgf=readgrid(inID)

%--------------------------------------------------------
%-----THIS READS A GRID FROM A BINARY FILE CREATED
%-----BY MATLAB OR POSSIBLY FORTRAN (THOUGH THIS IS
%-----NOT YET IMPLEMENTED AS OF 9/15/2016)
%--------------------------------------------------------

  filename=[inID,'simsize.dat'];
  fid=fopen(filename,'r');
  xgf.lx=fread(fid,3,'integer*4');
  fclose(fid);
  lx1=xgf.lx(1); lx2=xgf.lx(2); lx3=xgf.lx(3);
  lgrid=lx1*lx2*lx3;
  lgridghost=(lx1+4)*(lx2+4)*(lx3+4);
  gridsize=[lx1,lx2,lx3];
  gridsizeghost=[lx1+4,lx2+4,lx3+4];
  
  fid=fopen([inID,'simgrid.dat'],'r');
  
  xgf.x1=fread(fid,lx1+4,'real*8');    %coordinate values
  xgf.x1i=fread(fid,lx1+1,'real*8');
  xgf.dx1b=fread(fid,lx1+3,'real*8');    %ZZZ - need to check that differences have appropriate ghost cell values, etc.
  xgf.dx1h=fread(fid,lx1,'real*8');
  
  xgf.x2=fread(fid,lx2+4,'real*8');
  xgf.x2i=fread(fid,lx2+1,'real*8');
  xgf.dx2b=fread(fid,lx2+3,'real*8');
  xgf.dx2h=fread(fid,lx2,'real*8');
  
  xgf.x3=fread(fid,lx3+4,'real*8');
  xgf.x3i=fread(fid,lx3+1,'real*8');
  xgf.dx3b=fread(fid,lx3+3,'real*8');
  xgf.dx3h=fread(fid,lx3,'real*8');
  
  tmp=fread(fid,lgridghost,'real*8');   %cell-centered metric coefficients
  xgf.h1=reshape(tmp,gridsizeghost);
  tmp=fread(fid,lgridghost,'real*8');
  xgf.h2=reshape(tmp,gridsizeghost);
  tmp=fread(fid,lgridghost,'real*8');
  xgf.h3=reshape(tmp,gridsizeghost);

  tmpsize=[lx1+1,lx2,lx3];
  ltmp=prod(tmpsize);
  tmp=fread(fid,ltmp,'real*8');    %interface metric coefficients
  xgf.h1x1i=reshape(tmp,tmpsize);
  tmp=fread(fid,ltmp,'real*8');
  xgf.h2x1i=reshape(tmp,tmpsize);
  tmp=fread(fid,ltmp,'real*8');
  xgf.h3x1i=reshape(tmp,tmpsize);
  
  tmpsize=[lx1,lx2+1,lx3];
  ltmp=prod(tmpsize);  
  tmp=fread(fid,ltmp,'real*8');
  xgf.h1x2i=reshape(tmp,tmpsize);
  tmp=fread(fid,ltmp,'real*8');
  xgf.h2x2i=reshape(tmp,tmpsize);
  tmp=fread(fid,ltmp,'real*8');
  xgf.h3x2i=reshape(tmp,tmpsize);
  
  tmpsize=[lx1,lx2,lx3+1];
  ltmp=prod(tmpsize); 
  tmp=fread(fid,ltmp,'real*8');
  xgf.h1x3i=reshape(tmp,tmpsize);
  tmp=fread(fid,ltmp,'real*8');
  xgf.h2x3i=reshape(tmp,tmpsize);
  tmp=fread(fid,ltmp,'real*8');
  xgf.h3x3i=reshape(tmp,tmpsize);
  
  %gravity, geographic coordinates, magnetic field strength? unit vectors?
  tmp=fread(fid,lgrid,'real*8');    %gravitational field components
  xgf.gx1=reshape(tmp,gridsize);
  tmp=fread(fid,lgrid,'real*8');
  xgf.gx2=reshape(tmp,gridsize);
  tmp=fread(fid,lgrid,'real*8');
  xgf.gx3=reshape(tmp,gridsize);
  
  tmp=fread(fid,lgrid,'real*8');    %geographic coordinates
  xgf.alt=reshape(tmp,gridsize);
  tmp=fread(fid,lgrid,'real*8');
  xgf.glat=reshape(tmp,gridsize);
  tmp=fread(fid,lgrid,'real*8');
  xgf.glon=reshape(tmp,gridsize);
  
  tmp=fread(fid,lgrid,'real*8');    %magnetic field strength
  xgf.Bmag=reshape(tmp,gridsize);
  
  tmp=fread(fid,lx2*lx3,'real*8');    %magnetic field inclination - only one value for each field line
  xgf.I=reshape(tmp,[lx2,lx3]);
  
  tmp=fread(fid,lgrid,'real*8');    %points not to be solved
  xgf.nullpts=reshape(tmp,gridsize);
  
  
  %STUFF PAST THIS POINT ISN'T USED IN FORTRAN CODE BUT INCLUDED IN THE
  %GRID FILE FOR COMPLETENESS
  if (~feof(fid))
      tmpsize=[lx1,lx2,lx3,3];
      ltmp=prod(tmpsize);
      tmp=fread(fid,ltmp,'real*8');   %4D unit vectors (in cartesian components)
      
      if (feof(fid))    %for whatever reason, we sometimes don't hit eof until after first unit vector read...
         return;   %lazy as hell 
      end
      
      xgf.e1=reshape(tmp,tmpsize);
      tmp=fread(fid,ltmp,'real*8');
      xgf.e2=reshape(tmp,tmpsize);
      tmp=fread(fid,ltmp,'real*8');
      xgf.e3=reshape(tmp,tmpsize);
      
      tmpsize=[lx1,lx2,lx3,3];
      ltmp=prod(tmpsize);
      tmp=fread(fid,ltmp,'real*8');
      xgf.er=reshape(tmp,tmpsize);
      tmp=fread(fid,ltmp,'real*8');
      xgf.etheta=reshape(tmp,tmpsize);
      tmp=fread(fid,ltmp,'real*8');
      xgf.ephi=reshape(tmp,tmpsize);
      
      tmp=fread(fid,lgrid,'real*8');    %spherical coordinates
      xgf.r=reshape(tmp,gridsize);
      tmp=fread(fid,lgrid,'real*8');
      xgf.theta=reshape(tmp,gridsize);
      tmp=fread(fid,lgrid,'real*8');
      xgf.phi=reshape(tmp,gridsize);
      
      tmp=fread(fid,lgrid,'real*8');     %cartesian coordinates
      xgf.x=reshape(tmp,gridsize);
      tmp=fread(fid,lgrid,'real*8');
      xgf.y=reshape(tmp,gridsize);
      tmp=fread(fid,lgrid,'real*8');
      xgf.z=reshape(tmp,gridsize);
  end
  
  fclose(fid);  
end