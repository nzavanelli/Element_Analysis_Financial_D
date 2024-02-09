clear all
close all
T2 = readtable('BrentOilPrices.csv');
T2T = table2timetable(T2);
time = T2T.Date;
data = table2array(T2(:,2));

time = 1:length(data);
data = data(~isnan(data));
time = time(~isnan(data));
plot(time, data)

set(gcf,'color','w');

figure
Fs = 365;
% data = data + randn(length(data),1).*0.1;
cutoff = 3;
[bh, ah] = butter(3, cutoff*2/Fs, 'high');
data = filtfilt(bh, ah, data);

time = 1:length(data);
plot(time, data)
% set(gca,'xtick',[])
% set(gca,'ytick',[])
set(gcf,'color','w');


fb = cwtfilterbank('SignalLength',length(data),...
    'SamplingFrequency',Fs,...
    'VoicesPerOctave',12);

[cfs,frq] = wt(fb,data);
t = (0:length(data)-1)/Fs;figure;pcolor(t,frq,abs(cfs))
set(gca,'yscale','log');shading interp;axis tight;
title('Scalogram');xlabel('Time (s)');ylabel('Frequency (Hz)')

figure

cwt(data,'amor',years(1/12));
AX = gca;

N=12000;
ga=2;be=3;mu=1;
fs=morsespace(ga,be,{0.05,pi},{3,N});
w=wavetrans(data,{ga,be,fs},'mirror');
[index,ww,ff]=transmax(fs,w);
[ii,jj]=ind2sub(size(w),index);
[chat,rhohat,fhat]=maxprops(ww,ff,ga,be,mu);
figure, [h,hl]=wavespecplot(time,data,2*pi./fs,w);colormap lansey
ylim([5.6, 602])
set(gcf,'color','w');
% set(gca,'xtick',[])
% set(gca,'ytick',[])

