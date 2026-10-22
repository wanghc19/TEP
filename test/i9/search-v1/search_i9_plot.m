function search_i9_plot(output_dir)
%SEARCH_I9_PLOT Render saved current-run observations without numerical solves.
% Purpose: Presentation-only plots from this run's checkpoint; no physics calls.
% Input: Explicit current-run directory, not an external or historical dependency.
  data=load(fullfile(output_dir,'checkpoint.mat'),'state'); state=data.state;
  log=state.lead_log; sides={'negative','positive'};
  f=figure('Visible','off'); tiledlayout(2,1);
  for s=1:2
    nexttile; hold on; labels={'GAP','NEAR_UNIT_PROPAGATING','UNCERTAIN'};
    for l=1:numel(labels)
      selected=log.records(cellfun(@(r) strcmp(r.resolution_id,'coarse') && ...
        strcmp(r.(sides{s}).status,labels{l}),log.records));
      if isempty(selected), continue; end
      semilogy(cellfun(@(r) r.k,selected), ...
        cellfun(@(r) max(r.(sides{s}).minimum_distance,1e-17),selected),'.','DisplayName',labels{l});
    end
    yline(state.config.qualification.inner_floor,'--','inner guard');
    yline(state.config.qualification.outer_floor,':','outer guard');
    set(gca,'YScale','log'); grid on; xlabel('k'); ylabel('minimum homogeneous circle distance');
    title([sides{s},' lead: sampled Bloch classification']); legend('Location','best');
  end
  exportgraphics(f,fullfile(output_dir,'lead-gaps.png')); close(f);
  f=figure('Visible','off'); hold on;
  for s=1:2
    segments=state.gap_sides.(sides{s});
    for j=1:numel(segments)
      segment=segments{j}; ends=[segment.left.gap_point,segment.right.gap_point];
      plot(ends,[s,s],'-','LineWidth',6);
      text(ends(1),s+.12,segment.left.status,'FontSize',7,'Interpreter','none');
      text(ends(2),s-.12,segment.right.status,'FontSize',7,'HorizontalAlignment','right','Interpreter','none');
    end
  end
  for j=1:numel(state.common_gaps)
    plot(state.common_gaps{j}.bounds,[3,3],'-','LineWidth',6);
  end
  yticks(1:3); yticklabels({'negative','positive','buffered common'});
  ylim([.5,3.5]); grid on; xlabel('k'); title('I9.1 sampled segments and buffered search intersections');
  exportgraphics(f,fullfile(output_dir,'common-gaps.png')); close(f);
  for j=1:numel(state.coarse_runs)
    scan=state.coarse_runs{j}; score=nan(size(scan.k));
    for p=1:numel(scan.k)
      point=state.points{scan.point_ids(p)};
      if strcmp(point.status,'SUCCESS'), score(p)=point.aphys_ratio; end
    end
    f=figure('Visible','off'); semilogy(scan.k,score,'o-'); grid on;
    xlabel('k'); ylabel('aphys ratio'); title(sprintf('I9.1 common-gap %d coarse search',scan.gap_id));
    exportgraphics(f,fullfile(output_dir,sprintf('coarse-gap-%03d.png',scan.gap_id))); close(f);
  end
end
