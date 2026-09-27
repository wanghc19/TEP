function plot_i7_local(result,filename)
%PLOT_I7_LOCAL Plot the six local dip curves on their common uniform grid.
% Purpose:
%   Display ratio and absolute singular value without implying root accuracy.
% Input:
%   result - Local-mode output of check_i7_refinement.
%   filename - New PNG destination; an existing file is never overwritten.
% Notes:
%   Coincident curves indicate agreement at sampled k values only.

  if isfile(filename)
    error('i73:FigureExists','Refusing to overwrite %s.',filename);
  end
  assert(strcmp(result.mode,'LOCAL'));
  f = figure('Visible','off','Color','w','Position',[100,100,1050,460]);
  cleanup = onCleanup(@() close(f)); %#ok<NASGU>
  tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
  fields = {'aphys_ratio','aphys_sigma'};
  labels = {'sigma_{min}(Aphys) / sigma_{max}(Aphys)', ...
    'sigma_{min}(Aphys)'};
  styles = {'-o','--s',':^','-.d','-x','--+'};
  for ip = 1:2
    nexttile; hold on;
    for ic = 1:numel(result.configs)
      plot((result.k_values-result.k0)*1e5, ...
        [result.points(ic,:).(fields{ip})],styles{ic},'LineWidth',1.1, ...
        'DisplayName',result.configs(ic).id);
    end
    xlabel('(k - k0) / 10^{-5}'); ylabel(labels{ip}); grid on;
    legend('Location','best');
  end
  sgtitle('I7.3 local scan: fixed auxiliary discretization, common grid');
  exportgraphics(f,filename,'Resolution',180);
end
