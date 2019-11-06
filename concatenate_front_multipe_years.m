function concat_var = concatenate_front_multipe_years(daily_path, varname,dimsize,yy1,yy2)
% function only for this script
concat_var = [];
for yy = yy1:yy2
    fn = [daily_path, '/concatenate_front_daily_',num2str(yy),'.nc'];
    if ~exist(fn)
        continue
    end
    tmp = ncread(fn,varname);
    concat_var = cat(dimsize,concat_var,tmp);
end

end
