function concat_var = concatenate_front_multipe_years(daily_path, varname,yy1,yy2)
% function only for this script
concat_var = [];
for yy = yy1:yy2
    fn = [daily_path, '/concatenate_front_daily_',num2str(yy),'.nc'];
    tmp = ncread(fn,varname);
    concat_var = cat(3,concat_var,tmp);
end

end
