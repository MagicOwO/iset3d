function StreetPlaced = piStreetlightPlace(streetlightlib,streetlightPosList)
%% Place the assets by given position list, exact names do not need to be matched.
for ii = 1: length(streetlightPosList)
    PosList{ii} = streetlightPosList(ii).name;
end
PosListCheck = unique(PosList);
for kk = 1:length(PosListCheck)
    count = 1;
    for jj = 1: length(PosList)
        if isequal(PosListCheck(kk),PosList(jj))
            buildingPosList_tmp(kk).name = PosListCheck(kk);
            buildingPosList_tmp(kk).count = count;
            count = count+1;
        end
    end
end
asset = streetlightlib;

for ii = 1: length(buildingPosList_tmp)
    
    % if ~isequal(buildingPosList_tmp(ii).count,1)
    n = buildingPosList_tmp(ii).count;
    for dd = 1: length(asset)
        assets_updated(dd) = asset(dd);
        for hh = 1: length(asset(dd).geometry)% change from ii to dd
            gg=1;
            position=cell(n,1);
            rotation=cell(n,1); 
            pos = asset(dd).geometry(hh).position;
            rot = asset(dd).geometry(hh).rotate;
            asset(dd).geometry(hh).position = repmat(pos,1,uint8(buildingPosList_tmp(ii).count));
            if isempty(rot)
                rot(:,1) = [0;1;0;0];
                rot(:,2) = [0;0;1;0];
                rot(:,3)   = [0;0;0;1];
            end
            asset(dd).geometry(hh).rotate = repmat(rot,1,uint8(buildingPosList_tmp(ii).count));
            
            for jj = 1:length(streetlightPosList)
                position{gg} = streetlightPosList(jj).position;
                rotation{gg} = streetlightPosList(jj).rotate;
                gg = gg+1;
            end
            assets_updated(dd).geometry(hh) = piAssetTranslate(asset(dd).geometry(hh),position,'Pos_demention',n);
            assets_updated(dd).geometry(hh) = piAssetRotate(assets_updated(dd).geometry(hh),rotation,'Pos_demention',n);
        end
    end
end
StreetPlaced = assets_updated;
end