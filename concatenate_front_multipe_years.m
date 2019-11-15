function concat_var = concatenate_front_multipe_years(daily_path, fn_prefix, varname,dimsize,yy1,yy2)
% function to concatenate data of mutiple years 
concat_var = [];
for yy = yy1:yy2
    fn = [daily_path, '/',fn_prefix,num2str(yy),'.nc'];
    if ~exist(fn)
        continue
    end
    tmp = ncread(fn,varname);
    concat_var = cat(dimsize,concat_var,tmp);
end

end
