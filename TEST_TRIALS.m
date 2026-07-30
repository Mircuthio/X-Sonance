rootFolder = 'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\EXTRACTED_DATA';

tmp=struct();
for i=1:4
    name =sprintf('trial%d',i);
    tmp.(name)=load(fullfile(rootFolder,'Subj3',sprintf('Subj3_trial%d_data_extracted',i)));
end

triggertrial1= trial1.y(end,:);

length(find(diff([0 triggertrial1~=0])==1))
unique(triggertrial1)
tabulate(triggertrial1(triggertrial1~=0))

tmp = load(fullfile(rootFolder,'Subj3','EDP_trial'));
y = tmp.y;
trigger= y(end,:);
idx = find(diff(trigger)~=0);
length(idx)

trialBoundaries = tmp.trialBoundaries;

for k = 1:length(trialBoundaries)

    idx1 = trialBoundaries(k).startSample;
    idx2 = trialBoundaries(k).endSample;

    tr = trigger(idx1:idx2);

    fprintf('Trial %d : %d eventi\n',...
        k,...
        sum(diff([0 tr~=0])==1));

end