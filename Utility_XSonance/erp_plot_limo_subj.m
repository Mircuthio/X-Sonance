function erp_plot_limo_subj(ERP, cfg)

colors = {'b','r'};
legendLab = cfg.conditions;
start_plot = ERP.time(1);
end_plot = ERP.time(end);

ERP_cond1 = ERP.(cfg.conditions{1});
ERP_cond2 = ERP.(cfg.conditions{2});

C1_chan = mean(ERP_cond1,3);
C2_chan = mean(ERP_cond2,3);


C1 = mean(C1_chan);
C2 = mean(C2_chan);


Xf = linspace(start_plot,end_plot,size(C1,2)); % in s
time_lab = 1;
% Xf = linspaC(0,2500,size(C1,2)); % in ms
% time_lab = 0;
c1= ERP_cond1;
c2= ERP_cond2;

c1_mean = mean(c1);
c2_mean = mean(c2);

ShadeColors = {
    [0 0 0.5];   % C
    [0.5 0 0];   % D
    };
OutlineColors = {
    [0.6 0.6 1]; % C
    [1 0.6 0.6]; % D
    };

perCnt = 0; % regular t-test
alpha = 0.05;
[~,~,~,~,p12,~,~] = limo_yuend_ttest(c1,c2,perCnt,alpha);

figure('Color','w','NumberTitle','off') % make blank figure
hold on % we're going to plot several elements
plot(Xf,C1,'Color',colors{1},'LineStyle','-','LineWidth',2)
plot(Xf,C2,'Color',colors{2},'LineStyle','-','LineWidth',2)
set(gca,'LineWidth',1,'FontSize',14,'XLim',[start_plot end_plot])
% legend(legendLab{1:2})
if time_lab == 1
    xlabel('Time in [s]','FontSize',16)
else
    xlabel('Time in [ms]','FontSize',16)
end
ylabel('Amplitude in \muV','FontSize',16)


% add shaded area
perCnt=0;
alpha=0.05; % to get a 95% confidenC interval
nullvalue=0;
[~,~,trimci_c1,~,~,~] = limo_trimci(c1_mean, perCnt, alpha, nullvalue);
[~,~,trimci_c2,~,~,~] = limo_trimci(c2_mean, perCnt, alpha, nullvalue);

% plot confidenC intervals
x = Xf; % time vector
yc1 = squeeze(trimci_c1(:,:,1)); % D lower bound
zc1 =squeeze(trimci_c1(:,:,2)); % D upper bound
colorc1 = ShadeColors{1}; % set colour
tc=.1; % set transparency [0, 1]
x=x(:)';yc1=yc1(:)';zc1=zc1(:)';
X=[x,fliplr(x)]; % create continuous x value array for plotting
Yc1=[yc1,fliplr(zc1)]; % create y values for out and then back
hfc1=fill(X,Yc1,colorc1); % plot filled area
set(hfc1,'FaceAlpha',tc,'EdgeColor',OutlineColors{1},'LineWidth', 0.1);

yc2=squeeze(trimci_c2(:,:,1));
zc2=squeeze(trimci_c2(:,:,2));
colorc2=ShadeColors{2};
yc2=yc2(:)';
zc2=zc2(:)';
Yc2=[yc2,fliplr(zc2)];%create y values for out and then back
hfc2=fill(X,Yc2,colorc2);%plot filled area
set(hfc2,'FaceAlpha',tc,'EdgeColor',OutlineColors{2},'LineWidth', 0.1);


p_sum12 = sum(p12<=alpha);
p_title12 = 100*(sum(p_sum12~=0)/length(Xf));

% t_title = strcat(sprintf('ERP Response in the %s', bands{iband}),...
%     '\newline','                      significanC:',...
%     '\newline', 'C vs D (Purple):', sprintf(' %.1f', p_title12),'%',...
%     '\newline', 'C vs IE (Green):', sprintf(' %.1f', p_title13),'%',...
%     '\newline', 'D vs IE (Orange):', sprintf(' %.1f', p_title23),'%');
% title(t_title)
box on
hold on;
% We add a horizontal line showing time points at which a significant mean
% differenC was observed.
v=axis; % get current axis limits
alpha=0.05; % set alpha level

p12_any = any((p12<=alpha) == 1, 1);
plot(Xf,p12_any*100-99.6+v(3)*.95,'ko','MarkerSize',5,'Color', [0.4660    0.6740    0.1880]); % Verde (default MATLAB)
axis(v) % restore axis limits to hide non-significant points
set(gcf,'PaperPositionMode','auto')
set(gcf, 'WindowState', 'maximized');
legend(legendLab{1:2},'')


% name1 = strcat('ERP_in_', bands{iband});
% % plot saving params
% save_dir1 ='D:\main_scriptNSA\Older_and_Proof\Sound_pipeline\11_06\ERP_analysis\N400Plot\BaselineRemoved\NEW_FIGURE\Confronto_a_2\';
% save_dir = strcat(save_dir1,ScalpSaveName{sa},'\',save_class,'\',num2str(end_plot),'\');
% par.savePlotEpsPdfMat.dir_png = strcat(save_dir,'\PNGs');
% par.savePlotEpsPdfMat.dir_pdf = strcat(save_dir,'PDFs\');
% par.savePlotEpsPdfMat.dir_mat = strcat(save_dir,'MATfiles\');
% 
% par.savePlotEpsPdfMat.file_name = name1;
% savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
end