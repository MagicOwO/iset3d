function [ obj ] = render( obj, varargin )

renderTargets = [];

if isfield(obj.targets,'groupLabel')
    
    groupLabels = [obj.targets(:).groupLabel];
    uniqueLabels = unique(groupLabels);
    
    for i=1:length(uniqueLabels)
       
        subTargets = {obj.targets(groupLabels == uniqueLabels(i)).remote};
        if length(subTargets) > 1
            indx = 1;
            while all(strncmp(subTargets(1),subTargets(2:end),indx))
                indx = indx+1;
            end
            cmd = sprintf('%s*',subTargets{1}(1:indx-1));
        else
            cmd = subTargets{1};
        end
        
        currentTarget.remote = cmd;
        currentTarget.map = groupLabels == uniqueLabels(i);
        currentTarget.renderingStarted = all([obj.targets(groupLabels == uniqueLabels(i)).renderingStarted]);
        currentTarget.renderingComplete = all([obj.targets(groupLabels == uniqueLabels(i)).renderingComplete]);
        
        renderTargets = cat(1,renderTargets,currentTarget);        
    end

else
    
    for i=1:length(obj.targets)
        currentTarget.remote = obj.targets(i).remote;
        currentTarget.map = i;
        currentTarget.renderingStarted = obj.targets(i).renderingStarted;
        currentTarget.renderingComplete = obj.targets(i).renderingComplete;
            
        renderTargets = cat(1,renderTargets,currentTarget);

    end
end





symbols = ['a':'z' '0':'9'];

for t=1:length(renderTargets)
    
    if renderTargets(t).renderingStarted == 1
         continue;
    end
    
    if renderTargets(t).renderingComplete == 1
        continue;
    end
        
    
    jobName = lower(renderTargets(t).remote);
    jobName(jobName == '_' | jobName == '.' | jobName == '-' | jobName == '/' | jobName == ':' | jobName == '*') = '';
    fprintf('Rendering: %s\n',jobName);
    jobName = jobName(max(1,length(jobName)-30):end);
    
    nums = randi(numel(symbols),[1 31]);
    randName = symbols(nums);
    jobName = [randName jobName];
    
    
    % Kubernetess does not allow two jobs with the same name.
    % We need to delete the old one first
    kubeCmd = sprintf('kubectl delete job --namespace=%s %s',obj.namespace,jobName);
    [status, result] = system(kubeCmd);
    
    
    pos = strfind(obj.instanceType,'-');
    nCores = str2double(obj.instanceType(pos(end)+1:end));
    
    
    % Before we can issue a new one
    kubeCmd = sprintf('kubectl run %s --image=%s --namespace=%s --restart=OnFailure --limits cpu=%im  -- ./cloudRenderPBRT2ISET.sh  "%s" ',...
        jobName,...
        obj.dockerImage,...
        obj.namespace,...
        (nCores-0.9)*1000,...
        renderTargets(t).remote);
    
    cntr = 0;
    while cntr < 100
        [status, result] = system(kubeCmd);
        if status == 0, break; end;
        pause(60);
        fprintf('Error issuing kubectl command, pausing for 60 seconds, %i/%i\n',cntr,100);
    end
    
    [obj.targets(renderTargets(t).map).renderingStarted] = deal(1);
    
    fprintf('%s\n',result);
end

end

