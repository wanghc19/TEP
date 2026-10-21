function plot_i7_refinement(result,filename)
%PLOT_I7_REFINEMENT Plot the two separately varied I7.3 discretization axes.
% Purpose:
%   Display fixed-point diagnostics from an explicitly supplied result.
% Input:
%   result   - Six-configuration output from check_i7_refinement.
%   filename - Destination PNG path; existing files are not overwritten.
% Notes:
%   The joint configuration is a separate marker, not part of either pure axis.

  if isfile(filename)
    error('i73:FigureExists','Refusing to overwrite %s.',filename);
  end
  f = figure('Visible','off','Color','w','Position',[100,100,1050,720]);
  cleanup = onCleanup(@() close(f)); %#ok<NASGU>
  tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
  groups = {[1,2,3],[1,4,5]};
  fields = {'M','ntot'};
  labels = {'Rayleigh order M (ntot = 256)', ...
    'Inclusion nodes ntot (M = 48)'};
  for axis_index = 1:2
    index = groups{axis_index};
    x = arrayfun(@(j) result.configs(j).(fields{axis_index}),index);
    nexttile(axis_index);
    plot(x,[result.points(index,1).distance_2],'-o','LineWidth',1.4);
    hold on;
    plot(x,[result.points(index,3).distance_2],'-s','LineWidth',1.4);
    plot(x(end),result.points(6,1).distance_2,'kd','MarkerFaceColor','k');
    plot(x(end),result.points(6,3).distance_2,'kd','HandleVisibility','off');
    xlabel(labels{axis_index}); ylabel('Non-Hermitian defect dH');
    legend('Left endpoint','Right endpoint','Joint N512/M64','Location','best');
    grid on;
    nexttile(axis_index+2);
    plot(x,[result.points(index,2).aphys_ratio],'-o','LineWidth',1.4);
    hold on;
    plot(x(end),result.points(6,2).aphys_ratio,'kd','MarkerFaceColor','k');
    xlabel(labels{axis_index}); ylabel('Aphys singular-value ratio at fixed k0');
    legend('Pure axis','Joint N512/M64','Location','best'); grid on;
  end
  sgtitle('I7.3: fixed-point discretization sensitivity');
  exportgraphics(f,filename,'Resolution',180);
end
