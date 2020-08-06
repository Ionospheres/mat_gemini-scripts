% cwd = fileparts(mfilename('fullpath'));
% gemini_root = [cwd,filesep,'../../GEMINI'];
% addpath([gemini_root, filesep, 'script_utils'])
% addpath([gemini_root, filesep, 'vis'])
addpath ../script_utils/;

%direc='~/Projects/GEMINI/objects/test3d_glow/';
%direc='~/simulations/zenodo3d/';
%direc='~/simulations/junktest3d/';
direc='~/simulations/EIA_eq/';

ymd=[2011,03,10];
UTsec=65783;
file_format='raw';
realbits=64;
xg=readgrid(direc,file_format,realbits);
simdat=loadframe(direc,ymd,UTsec);
[alti,gloni,glati,nei]=model2geocoords(xg,simdat.ne);
[alti,gloni,glati,Tei]=model2geocoords(xg,simdat.Te);
[alti,gloni,glati,J1i]=model2geocoords(xg,simdat.J1);
[alti,gloni,glati,J2i]=model2geocoords(xg,simdat.J2);
[alti,gloni,glati,J3i]=model2geocoords(xg,simdat.J3);
[alti,gloni,glati,v3i]=model2geocoords(xg,simdat.v3);
[alti,gloni,glati,v2i]=model2geocoords(xg,simdat.v2);
[alti,gloni,glati,v1i]=model2geocoords(xg,simdat.v1);
[alti,gloni,glati,Tii]=model2geocoords(xg,simdat.Ti);


figure;
subplot(121)
imagesc(gloni,alti,nei(:,:,end/2));
axis xy;
colorbar;
subplot(122)
imagesc(glati,alti,squeeze(nei(:,end/2,:)));
axis xy;
colorbar;

figure;
subplot(121)
imagesc(gloni,alti,Tei(:,:,end/2));
axis xy;
colorbar;
subplot(122)
imagesc(glati,alti,squeeze(Tei(:,end/2,:)));
axis xy;
colorbar;

figure;
subplot(121)
imagesc(gloni,alti,J1i(:,:,end/2));
axis xy;
colorbar;
subplot(122);
imagesc(glati,alti,squeeze(J1i(:,end/2,:)));
axis xy;
colorbar;

figure;
subplot(121)
imagesc(gloni,alti,J3i(:,:,end/2));
axis xy;
colorbar;
subplot(122);
imagesc(glati,alti,squeeze(J3i(:,end/2,:)));
axis xy;
colorbar;

figure;
subplot(121)
imagesc(gloni,alti,J2i(:,:,end/2));
axis xy;
colorbar;
subplot(122);
imagesc(glati,alti,squeeze(J2i(:,end/2,:)));
axis xy;
colorbar;

figure;
subplot(121)
imagesc(gloni,alti,v3i(:,:,end/2));
axis xy;
colorbar;
subplot(122);
imagesc(glati,alti,squeeze(v3i(:,end/2,:)));
axis xy;
colorbar;

figure;
subplot(121)
imagesc(gloni,alti,v2i(:,:,end/2));
axis xy;
colorbar;
subplot(122);
imagesc(glati,alti,squeeze(v2i(:,end/2,:)));
axis xy;
colorbar;

figure;
subplot(121)
imagesc(gloni,alti,v1i(:,:,end/2));
axis xy;
colorbar;
subplot(122);
imagesc(glati,alti,squeeze(v1i(:,end/2,:)));
axis xy;
colorbar;

figure;
subplot(121)
imagesc(gloni,alti,Tii(:,:,end/2));
axis xy;
colorbar;
subplot(122);
imagesc(glati,alti,squeeze(Tii(:,end/2,:)));
axis xy;
colorbar;


%% lat/lon slices
ialt=min(find(alti>300e3));

figure;
imagesc(gloni,glati,squeeze(nei(ialt,:,:))');
axis xy;
colorbar;

figure;
imagesc(gloni,glati,squeeze(Tei(ialt,:,:))');
axis xy;
colorbar;

figure;
imagesc(gloni,glati,squeeze(v1i(ialt,:,:))');
axis xy;
colorbar;

figure;
imagesc(gloni,glati,squeeze(v2i(ialt,:,:))');
axis xy;
colorbar;

figure;
imagesc(gloni,glati,squeeze(v3i(ialt,:,:))');
axis xy;
colorbar;

figure;
imagesc(gloni,glati,squeeze(Tii(ialt,:,:))');
axis xy;
colorbar;