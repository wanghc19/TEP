function integration_rate(output_dir,piece_limit)
%INTEGRATION_RATE Moment enclosure versus terminal-piece count; DtN is Dirichlet-to-Neumann.
% Input: output_dir is explicit; piece_limit overrides only the smoke engine cap.
% Output: original I9.6 outputs and template-rate.json extracted before block cleanup.
  c = dtn_bound_i96_config('smoke'); c.engine.piece_limit = piece_limit;
  result = dtn_bound_i96(c,[],output_dir);
  rows = struct([]);
  for i = 1:numel(result.levels)
    l = result.levels(i);
    if ~l.completed, continue, end
    x = l.exact; names = {'left','center','right'};
    for j = 1:3
      name = names{j}; e = l.engine(j);
      s = load(fullfile(output_dir,'blocks',l.name,['special_',name,'.mat']), ...
        'D_center_final','D_radius','cs');
      phi_l1 = (1/l.N)*[1,sqrt(3)/2,sqrt(3)/2,3/4];
      z = s.D_center_final; rad = s.D_radius;
      box = sqrt((abs(real(z))+rad).^2+(abs(imag(z))+rad).^2);
      dc = sqrt(sum(box.^2,'all')+sum(s.cs.dns_sq));
      d1 = sum(box.*phi_l1,'all')+sum(s.cs.dns_l1);
      upper = min(dc/x.shift_floor,x.CG*d1);
      width = min(norm(sqrt(2)*rad,'fro')/x.shift_floor, ...
        x.CG*sum(sqrt(2)*rad.*phi_l1,'all'));
      scale = l.C_rho/x.denominator;
      row = struct('piece_limit',piece_limit,'level',l.name,'N',l.N,'template',name, ...
        'terminal_pieces',e.counts.terminal_pieces,'final_level',e.counts.level_max, ...
        'stop_reason',e.stop,'moment_upper',upper,'moment_uncertainty_upper',width, ...
        'moment_share_Rmu',scale*upper/x.R_mu,'level_moment_upper',x.moment_term, ...
        'level_moment_share_Rmu',x.contributions.moment_term/x.R_mu, ...
        'R_mu',x.R_mu,'R_k',x.R_k,'E_v',x.E_v(2),'engine_seconds',e.seconds.total, ...
        'level_seconds',l.seconds.total,'moment_l1',x.CG*d1,'moment_l2',dc/x.shift_floor);
      if isempty(rows), rows = row; else, rows(end+1) = row; end
    end
  end
  fid = fopen(fullfile(output_dir,'template-rate.json'),'w');
  fwrite(fid,jsonencode(rows,'PrettyPrint',true)); fclose(fid);
  writetable(struct2table(rows),fullfile(output_dir,'template-rate.csv'));
end
