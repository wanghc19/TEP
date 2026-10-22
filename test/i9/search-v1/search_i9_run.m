function state = search_i9_run(output_dir,mode)
%SEARCH_I9_RUN Common projected-gap discovery and two-resolution all-dip search.
% Purpose: Execute design-9-1a without historical candidates or old scripts.
% Input: output_dir for this run; mode 'run', 'selftest', or 'config'.
% Output: state contains points, interval lineage, rounds and final candidates.
% Based on: I8.5 scan_i8_search grid, scheduler and all-dip local manager.
% Main algorithm: independent leads -> common gaps -> coarse dips -> fine branches.
% Notes: Grid construction, physics, scheduling, detection and export are separate.
%   R_num and all spectral-distance evaluation are intentionally absent.
  if nargin < 2, mode = 'run'; end
  config = search_i9_config();
  if ~exist(output_dir,'dir'), mkdir(output_dir); end
  maxNumCompThreads(config.backend.threads);
  LOCAL_json(fullfile(output_dir,'environment.json'),struct('version',version, ...
    'platform',computer,'threads',maxNumCompThreads, ...
    'OMP_NUM_THREADS',getenv('OMP_NUM_THREADS'),'OMP_DYNAMIC',getenv('OMP_DYNAMIC'), ...
    'hfmm2d',which('hfmm2d'),'construct_S',which('bloch.construct_S')));
  LOCAL_json(fullfile(output_dir,'config.json'),config);
  if strcmp(mode,'config'), state=config; return; end
  if strcmp(mode,'selftest')
    state=LOCAL_selftest(config); LOCAL_json(fullfile(output_dir,'selftest.json'),state); return;
  end
  assert(strcmp(mode,'run'));
  assert(~exist(fullfile(output_dir,'checkpoint.mat'),'file'),'i91:ExistingRun');
  state=LOCAL_initial(config);
  timer=tic;
  selftest=LOCAL_selftest(config); LOCAL_json(fullfile(output_dir,'selftest.json'),selftest);
  LOCAL_lead_store('reset',config);
  evaluator=@(k,res) LOCAL_evaluate(k,res,config);
  geometry=LOCAL_geometry(config,output_dir); state.geometry=geometry;
  try
    state=LOCAL_gap_stage(state,output_dir,timer);
    if ~isempty(state.common_gaps)
      if ~any(cellfun(@(g) strcmp(g.status,'USABLE'),state.common_gaps))
        state.status='NO_USABLE_FINE_COMMON_GAP';
        LOCAL_save(state,output_dir,timer); LOCAL_display(state,output_dir); return;
      end
      state=LOCAL_seed_search(state,evaluator,output_dir,timer);
      if ~strcmp(state.status,'BUDGET_REASSESSMENT_REQUIRED')
        state=LOCAL_manage(state,evaluator,output_dir,timer);
      end
    else
      state.status='NO_USABLE_COMMON_GAP';
    end
  catch error
    state.status='OPERATIONAL_FAILURE'; state.error=struct('identifier',error.identifier, ...
      'message',error.message,'report',getReport(error,'extended','hyperlinks','off'));
    % An operational exception must not overwrite the latest completed checkpoint.
    LOCAL_json(fullfile(output_dir,'failure.json'),state.error);
    if ~exist(fullfile(output_dir,'checkpoint.mat'),'file')
      LOCAL_save(state,output_dir,timer);
    end
    rethrow(error);
  end
  LOCAL_save(state,output_dir,timer);
  LOCAL_display(state,output_dir);
end

%% ==================== State and grid construction ====================
% These helpers create exact actual grids and lightweight current-run records.
function state=LOCAL_initial(config)
  state=struct('schema','I91_SCAN_STATE_V1','config',config,'config_key',jsonencode(config), ...
    'points',{{}},'requests',{{}},'intervals',{{}},'history',{{}},'candidates',{{}}, ...
    'coarse_dips',{{}},'edge_records',{{}},'confirmations',{{}}, ...
    'common_gaps',{{}},'coarse_runs',{{}},'gap_sides',struct(),'representative_checks',{{}}, ...
    'status','RUNNING','coarse_done',false,'elapsed_before',0, ...
    'timing',struct('coarse',0,'fine',0,'confirmation',0,'gap',0,'validation',0), ...
    'counters',struct('requested',0,'computed',0,'cache_hits',0,'confirmation',0));
end

function k=LOCAL_grid(bounds,count,existing,kind,config)
% Grid construction has no access to physical scores or matrices.
  if strcmp(kind,'wide')
    k=config.search.wide_first+(0:config.search.wide_count-1)*config.search.wide_step;
  else
    k=linspace(bounds(1),bounds(2),count);
  end
  assert(all(isfinite(k)) && all(diff(k)>0),'i91:DuplicateGrid', ...
    'Actual binary64 grid is not finite and strictly increasing.');
  if ~isempty(existing)
    assert(~isequal(k,existing),'i91:RepeatedGrid','Actual grid did not change.');
  end
end

function task=LOCAL_task(id,parent,source,bounds,kind)
  task=struct('id',id,'parent_id',parent,'source_ids',source,'resolution_id','fine', ...
    'gap_id',1,'bounds',bounds,'initial_bounds',bounds,'kind',kind,'round',0, ...
    'status','PENDING','point_ids',[],'history_ids',[],'children',[], ...
    'best_id',0,'last_grid',[],'stop_reason','','pending_groups',{{}});
end

%% ==================== Exact point scheduling ====================
% Only successful points with identical complete configuration and k are reused.
function [state,ids]=LOCAL_schedule(state,k,res,evaluator,bypass,output_dir,timer)
  ids=zeros(size(k));
  for j=1:numel(k)
    key=[state.config_key,'|',res,'|',num2hex(k(j))];
    state.counters.requested=state.counters.requested+1;
    hit=0;
    if ~bypass
      for p=1:numel(state.points)
        if strcmp(state.points{p}.key,key) && strcmp(state.points{p}.status,'SUCCESS')
          hit=p; break;
        end
      end
    end
    if hit>0
      ids(j)=hit; state.counters.cache_hits=state.counters.cache_hits+1;
      action='CACHE_HIT';
    else
      started=tic; evidence=[];
      try
        if bypass, [point,evidence]=evaluator(k(j),res); else, point=evaluator(k(j),res); end
        assert(strcmp(point.status,'SUCCESS'));
      catch error
        point=struct('k',k(j),'resolution_id',res,'status','FAILED', ...
          'seconds',toc(started),'error_identifier',error.identifier, ...
          'error_message',error.message);
      end
      point.id=numel(state.points)+1; point.key=key; point.k_hex=num2hex(k(j));
      point.resolution_id=res; point.bypass_cache=bypass;
      state.points{end+1}=point; ids(j)=point.id;
      state.counters.computed=state.counters.computed+1; action='COMPUTED';
      stage=res;
      if bypass, stage='confirmation'; state.counters.confirmation=state.counters.confirmation+1; end
      state.timing.(stage)=state.timing.(stage)+point.seconds;
      if bypass && ~isempty(output_dir) && strcmp(point.status,'SUCCESS')
        save(fullfile(output_dir,sprintf('candidate-evidence-%04d.mat',point.id)), ...
          'point','evidence','-v7');
      end
    end
    state.requests{end+1}=struct('id',state.counters.requested,'resolution_id',res, ...
      'k',k(j),'k_hex',num2hex(k(j)),'point_id',ids(j),'action',action,'bypass_cache',bypass);
    if ~isempty(output_dir)
      LOCAL_json(fullfile(output_dir,'progress.json'),struct('stage',res, ...
        'requested',state.counters.requested,'computed',state.counters.computed, ...
        'cache_hits',state.counters.cache_hits,'active_points',numel(k), ...
        'active_done',j,'elapsed',state.elapsed_before+toc(timer), ...
        'pending_intervals',sum(cellfun(@(t) ismember(t.status,{'PENDING','RUNNING'}),state.intervals))));
    end
  end
end

%% ==================== Dip identification ====================
% Every strict minimum and exact minimum plateau is retained before clustering.
function detection=LOCAL_dips(k,scores,valid,config,cluster)
  runs={}; j=1; n=numel(k);
  while j<=n
    if ~valid(j), j=j+1; continue; end
    last=j;
    while last<n && valid(last+1) && scores(last+1)==scores(j), last=last+1; end
    if j>1 && last<n && valid(j-1) && valid(last+1) && ...
        scores(j)<scores(j-1) && scores(last)<scores(last+1)
      runs{end+1}=struct('first',j,'last',last,'winner',j,'score',scores(j), ...
        'bounds',[k(j-1),k(last+1)],'plateau',last>j); %#ok<AGROW>
    end
    j=last+1;
  end
  groups={}; saddles={};
  tau=config.search.branch_eps_factor*eps*max([1,abs(scores(valid))]);
  for j=1:numel(runs)
    if j==1 || ~cluster
      groups{end+1}=j; %#ok<AGROW>
    else
      left=runs{j-1}; right=runs{j};
      saddle=max(scores(left.last:right.first));
      separate=(saddle-left.score)>tau && (saddle-right.score)>tau;
      saddles{end+1}=struct('left_run',j-1,'right_run',j,'score',saddle, ...
        'left_prominence',saddle-left.score,'right_prominence',saddle-right.score, ...
        'threshold',tau,'separate',separate); %#ok<AGROW>
      if separate, groups{end+1}=j; else, groups{end}(end+1)=j; end %#ok<AGROW>
    end
  end
  edge=[];
  if n>=2 && valid(1)
    last=1; while last<n && valid(last+1) && scores(last+1)==scores(1), last=last+1; end
    if last==n || (valid(last+1) && scores(1)<scores(last+1)), edge(end+1)=1; end
  end
  if n>=2 && valid(end)
    first=n; while first>1 && valid(first-1) && scores(first-1)==scores(end), first=first-1; end
    if first==1 || (valid(first-1) && scores(end)<scores(first-1)), edge(end+1)=n; end
  end
  detection=struct('runs',{runs},'groups',{groups},'saddles',{saddles}, ...
    'ambiguity_threshold',tau,'edge_indices',edge,'failed_indices',find(~valid));
end

function [scores,valid]=LOCAL_scores(state,ids)
  scores=nan(size(ids)); valid=false(size(ids));
  for j=1:numel(ids)
    p=state.points{ids(j)}; valid(j)=strcmp(p.status,'SUCCESS');
    if valid(j), scores(j)=p.aphys_ratio; end
  end
end

%% ==================== Scan and interval management ====================
% All coarse sources and all resolvable fine sub-dips retain explicit lineage.
function state=LOCAL_manage(state,evaluator,output_dir,timer)
  config=state.config; search=config.search;
  domain=[search.wide_first,search.wide_first+(search.wide_count-1)*search.wide_step];
  if ~state.coarse_done
    grid=LOCAL_grid(domain,search.wide_count,[],'wide',config);
    [state,ids]=LOCAL_schedule(state,grid,'coarse',evaluator,false,output_dir,timer);
    [scores,valid]=LOCAL_scores(state,ids); detected=LOCAL_dips(grid,scores,valid,config,false);
    state.coarse_grid=grid; state.coarse_point_ids=ids; state.coarse_detection=detected;
    for d=1:numel(detected.runs)
      dip=detected.runs{d}; dip.id=d; dip.point_ids=ids(dip.first:dip.last);
      bounds=[grid(max(1,dip.first-2)),grid(min(numel(grid),dip.last+2))];
      id=numel(state.intervals)+1; dip.interval_id=id; state.coarse_dips{end+1}=dip;
      state.intervals{end+1}=LOCAL_task(id,0,d,bounds,'COARSE_DIP');
    end
    for edge=detected.edge_indices
      if edge==1, bounds=grid([1,min(4,numel(grid))]); else, bounds=grid([max(1,end-3),end]); end
      id=numel(state.intervals)+1;
      state.intervals{end+1}=LOCAL_task(id,0,[],bounds,'COARSE_ENDPOINT');
      state.edge_records{end+1}=struct('interval_id',id,'round',0,'index',edge, ...
        'status','FINE_ENDPOINT_CHECK_PENDING','point_id',ids(edge));
    end
    if any(~valid)
      state.status='EVALUATION_FAILURE'; state.failed_coarse_point_ids=ids(~valid);
      LOCAL_save(state,output_dir,timer); return;
    end
    state.coarse_done=true; LOCAL_save(state,output_dir,timer);
    % All registered branches must fit; no shallow-dip pruning is permitted.
    % Every later grid repeats its two endpoints; no speculative interior hits.
    estimated=numel(state.intervals)*(search.refine_count+20*(search.refine_count-2)+1)* ...
      config.resources.initial_fine_point_seconds+config.resources.reserve_seconds;
    state.coarse_budget_estimate_seconds=estimated;
    if ~isempty(output_dir) && estimated+state.elapsed_before+toc(timer)>config.resources.hard_seconds
      state.status='BUDGET_REASSESSMENT_REQUIRED'; LOCAL_save(state,output_dir,timer); return;
    end
  end
  cursor=1;
  while cursor<=numel(state.intervals)
    task=state.intervals{cursor};
    if ~isempty(state.common_gaps), domain=state.common_gaps{task.gap_id}.bounds; end
    if ~ismember(task.status,{'PENDING','RUNNING'}), cursor=cursor+1; continue; end
    task.status='RUNNING';
    while strcmp(task.status,'RUNNING')
      if task.round>=search.max_rounds
        task.status='ROUND_LIMIT'; task.stop_reason='maximum safety round count'; break;
      end
      if ~isempty(output_dir) && state.elapsed_before+toc(timer)>config.resources.hard_seconds- ...
          config.resources.reserve_seconds
        task.status='BUDGET_EXHAUSTED'; task.stop_reason='shared scientific time reserve'; break;
      end
      try
        grid=LOCAL_grid(task.bounds,search.refine_count,task.last_grid,'local',config);
      catch error
        if ~ismember(error.identifier,{'i91:DuplicateGrid','i91:RepeatedGrid'}), rethrow(error); end
        task.status='FLOATING_GRID_LIMIT'; task.stop_reason=error.message; break;
      end
      task.round=task.round+1;
      [state,ids]=LOCAL_schedule(state,grid,'fine',evaluator,false,output_dir,timer);
      task.point_ids=unique([task.point_ids,ids],'stable');
      [scores,valid]=LOCAL_scores(state,ids);
      detected=LOCAL_dips(grid,scores,valid,config,true);
      if any(~valid)
        task.status='EVALUATION_FAILURE'; task.stop_reason='one or more actual points failed';
        winner=0;
      else
        [~,winner]=min(scores);
      end
      good_ids=task.point_ids(cellfun(@(p) strcmp(p.status,'SUCCESS'),state.points(task.point_ids)));
      if ~isempty(good_ids)
        [~,best]=min(cellfun(@(p) p.aphys_ratio,state.points(good_ids))); task.best_id=good_ids(best);
      end
      record=struct('id',numel(state.history)+1,'interval_id',task.id,'round',task.round, ...
        'resolution_id','fine','k',grid,'point_ids',ids,'W',grid(end)-grid(1), ...
        'min_spacing',min(diff(grid)),'max_spacing',max(diff(grid)), ...
        'winner_index',winner,'winner_point_id',0,'interior',winner>1 && winner<numel(grid), ...
        'detection',detected,'decision','');
      if winner>0, record.winner_point_id=ids(winner); end
      task.last_grid=grid;
      if winner>0 && ~record.interior
        % Retain every internal group seen during endpoint expansion for later work.
        for g=1:numel(detected.groups)
          members=detected.groups{g}; first=detected.runs{members(1)}.first;
          last=detected.runs{members(end)}.last;
          anchors=[];
          for r=members, anchors=[anchors,ids(detected.runs{r}.first:detected.runs{r}.last)]; end %#ok<AGROW>
          pending=struct('bounds',grid([first-1,last+1]),'anchor_ids',anchors, ...
            'source_history_id',record.id,'status','PENDING','child_id',0);
          duplicate=false;
          for p=1:numel(task.pending_groups)
            old=task.pending_groups{p};
            duplicate=duplicate || isequal(old.anchor_ids,anchors) || isequal(old.bounds,pending.bounds);
          end
          if ~duplicate, task.pending_groups{end+1}=pending; end
        end
      end
      for edge=detected.edge_indices
        if edge==winner
          edge_status='GLOBAL_ENDPOINT_RECOVERY';
          edge_reason='global endpoint winner requires expansion or a boundary stop';
        else
          edge_status='NONWINNING_EDGE_PENDING';
          edge_reason='nonwinning edge is retained, not excluded as a possible external dip';
        end
        state.edge_records{end+1}=struct('interval_id',task.id,'round',task.round, ...
          'index',edge,'status',edge_status,'point_id',ids(edge), ...
          'direction',LOCAL_edge_direction(edge,numel(grid)), ...
          'reason',edge_reason);
      end
      if record.interior
        [state,task]=LOCAL_pending_children(state,task,detected,ids);
      end
      if strcmp(task.status,'EVALUATION_FAILURE')
        record.decision=task.status;
      elseif record.W<=search.width_target && record.interior && numel(detected.groups)<=1
        task.status='COMPLETE'; task.stop_reason='fine full width target and interior winner';
        task.candidate_id=ids(winner); record.decision='COMPLETE';
      elseif ~record.interior
        width=grid(end)-grid(1);
        if winner==1
          bounds=[max(domain(1),grid(1)-width),grid(end)];
        else
          bounds=[grid(1),min(domain(2),grid(end)+width)];
        end
        if isequal(bounds,task.bounds)
          task.status='BOUNDARY_UNRESOLVED'; task.stop_reason='descending winner at search window boundary';
        else
          task.bounds=bounds;
        end
        record.decision='ENDPOINT_EXPAND';
      elseif numel(detected.groups)>1
        task.status='SPLIT'; task.stop_reason='multiple numerically distinguishable fine dips';
        for g=1:numel(detected.groups)
          members=detected.groups{g}; first=detected.runs{members(1)}.first;
          last=detected.runs{members(end)}.last;
          bounds=grid([first-1,last+1]); child_id=numel(state.intervals)+1;
          child=LOCAL_task(child_id,task.id,task.source_ids,bounds,'FINE_SPLIT');
          child.gap_id=task.gap_id;
          child.point_ids=task.point_ids(bounds(1)<=cellfun(@(p) p.k,state.points(task.point_ids)) & ...
            cellfun(@(p) p.k,state.points(task.point_ids))<=bounds(end));
          state.intervals{end+1}=child; task.children(end+1)=child_id;
        end
        record.decision='SPLIT_ALL_DISTINGUISHABLE_DIPS';
      elseif numel(detected.groups)==1
        members=detected.groups{1}; first=detected.runs{members(1)}.first;
        last=detected.runs{members(end)}.last; bounds=grid([first-1,last+1]);
        if isequal(bounds,task.bounds)
          task.status='AMBIGUITY_UNRESOLVED'; task.stop_reason='entire ambiguity cluster cannot shrink';
        else
          task.bounds=bounds;
        end
        record.decision='REFINE_FULL_CLUSTER';
      else
        task.status='NO_INTERIOR_DIP'; task.stop_reason='no bracketed interior dip';
        record.decision=task.status;
      end
      state.history{end+1}=record; task.history_ids(end+1)=record.id;
      state.intervals{cursor}=task; LOCAL_save(state,output_dir,timer);
    end
    [state,task]=LOCAL_pending_children(state,task,struct('groups',{{}},'runs',{{}}),[]);
    state.intervals{cursor}=task;
    if ~strcmp(task.status,'SPLIT') && task.best_id>0
      if strcmp(task.status,'COMPLETE'), candidate_id=task.candidate_id; else, candidate_id=task.best_id; end
      point=state.points{candidate_id}; candidate=struct('interval_id',task.id, ...
        'source_ids',task.source_ids,'point_id',candidate_id,'best_id',task.best_id, ...
        'status',task.status,'stop_reason',task.stop_reason,'k',point.k, ...
        'resolution_id','fine','adef_sigma',point.adef_sigma,'adef_ratio',point.adef_ratio, ...
        'aphys_sigma',point.aphys_sigma,'aphys_ratio',point.aphys_ratio, ...
        'W',task.last_grid(end)-task.last_grid(1),'confirmation_id',0);
      [state,confirmation_ids]=LOCAL_schedule(state,point.k,'fine',evaluator,true,output_dir,timer);
      candidate.confirmation_id=confirmation_ids(1); confirmed=state.points{confirmation_ids(1)};
      if strcmp(confirmed.status,'SUCCESS')
        fields={'adef_sigma','adef_ratio','aphys_sigma','aphys_ratio'};
        differences=struct();
        for f=1:numel(fields), name=fields{f}; differences.(name)=abs(point.(name)-confirmed.(name)); end
      else
        differences=struct(); candidate.status='CONFIRMATION_FAILED';
      end
      state.confirmations{end+1}=struct('interval_id',task.id,'source_point_id',candidate_id, ...
        'confirmation_point_id',confirmation_ids(1),'absolute_differences',differences, ...
        'status',confirmed.status);
      state.candidates{end+1}=candidate;
    end
    LOCAL_save(state,output_dir,timer); cursor=cursor+1;
  end
  failed_coarse=any(cellfun(@(p) strcmp(p.resolution_id,'coarse') && ~strcmp(p.status,'SUCCESS'),state.points));
  state.pending_edge_count=sum(cellfun(@(e) strcmp(e.status,'NONWINNING_EDGE_PENDING'),state.edge_records));
  confirmations_ok=all(cellfun(@(r) strcmp(r.status,'SUCCESS'),state.confirmations));
  if failed_coarse
    state.status='SEARCH_FINISHED_WITH_COARSE_FAILURES';
  elseif ~confirmations_ok
    state.status='SEARCH_FINISHED_WITH_CONFIRMATION_FAILURES';
  elseif all(cellfun(@(t) ismember(t.status,{'COMPLETE','SPLIT'}),state.intervals)) && state.pending_edge_count==0
    state.status='SEARCH_FINISHED';
  else
    state.status='SEARCH_FINISHED_WITH_UNRESOLVED_INTERVALS';
  end
end

function [state,task]=LOCAL_pending_children(state,task,detected,ids)
% Transfer every endpoint-recovery internal group, merging exact anchors only.
  current={};
  for g=1:numel(detected.groups)
    anchors=[];
    for r=detected.groups{g}, anchors=[anchors,ids(detected.runs{r}.first:detected.runs{r}.last)]; end %#ok<AGROW>
    current{end+1}=anchors; %#ok<AGROW>
  end
  for p=1:numel(task.pending_groups)
    pending=task.pending_groups{p};
    if ~strcmp(pending.status,'PENDING'), continue; end
    if any(cellfun(@(a) isequal(a,pending.anchor_ids),current))
      pending.status='EXACT_ANCHORS_IN_CURRENT_ROUND'; pending.child_id=task.id;
    else
      id=numel(state.intervals)+1;
      child=LOCAL_task(id,task.id,task.source_ids,pending.bounds,'RECOVERY_INTERNAL_DIP');
      child.gap_id=task.gap_id;
      child.point_ids=pending.anchor_ids; state.intervals{end+1}=child;
      task.children(end+1)=id; pending.child_id=id; pending.status='CHILD_REGISTERED';
    end
    task.pending_groups{p}=pending;
  end
end

%% ==================== Persistence and presentation ====================
% Saved artifacts never supply scientific parameters or select candidates.
function LOCAL_save(state,output_dir,timer)
  if isempty(output_dir), return; end
  state.elapsed_seconds=state.elapsed_before+toc(timer);
  state.lead_log=LOCAL_lead_store('log');
  checkpoint=fullfile(output_dir,'checkpoint.mat'); save(checkpoint,'state','-v7');
  LOCAL_json(fullfile(output_dir,'state.json'),state);
end

function LOCAL_json(path,value)
  fid=fopen(path,'w'); assert(fid>=0,'i91:Output'); closer=onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end

function LOCAL_display(state,output_dir)
  fields={'id','resolution_id','k','adef_sigma','adef_ratio','aphys_sigma','aphys_ratio','seconds','status','bypass_cache'};
  fid=fopen(fullfile(output_dir,'points.csv'),'w'); closer=onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid,'%s\n',strjoin(fields,','));
  for j=1:numel(state.points)
    p=state.points{j};
    if strcmp(p.status,'SUCCESS')
      fprintf(fid,'%d,%s,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%s,%d\n', ...
        p.id,p.resolution_id,p.k,p.adef_sigma,p.adef_ratio,p.aphys_sigma,p.aphys_ratio,p.seconds,p.status,p.bypass_cache);
    end
  end
  if isfield(state,'coarse_grid')
    [score,~]=LOCAL_scores(state,state.coarse_point_ids);
    f=figure('Visible','off'); semilogy(state.coarse_grid,score,'o-'); grid on;
    xlabel('k'); ylabel('aphys ratio'); title('I9.1 coarse C256 / L128 search window');
    exportgraphics(f,fullfile(output_dir,'coarse.png')); close(f);
  end
  for c=1:numel(state.candidates)
    candidate=state.candidates{c}; task=state.intervals{candidate.interval_id};
    histories=state.history(task.history_ids);
    histories=histories(cellfun(@(h) h.winner_point_id>0,histories));
    if isempty(histories), continue; end
    f=figure('Visible','off'); tiledlayout(1,2);
    nexttile; semilogy(cellfun(@(h) h.round,histories),cellfun(@(h) h.W,histories),'o-');
    grid on; xlabel('round'); ylabel('whole width W');
    nexttile; semilogy(cellfun(@(h) h.round,histories), ...
      cellfun(@(h) state.points{h.winner_point_id}.aphys_ratio,histories),'o-');
    grid on; xlabel('round'); ylabel('round winner aphys ratio');
    exportgraphics(f,fullfile(output_dir,sprintf('branch-%03d.png',task.id))); close(f);
  end
end

%% ==================== Cheap synthetic validation ====================
% Synthetic functions exercise scheduling and decisions without physical kernels.
function report=LOCAL_selftest(config)
  checks={};
  classification=search_i9_physics('classification_selftest',1,'coarse',config);
  assert(strcmp(classification.status,'PASS'));
  checks{end+1}='homogeneous QZ unit/annulus/zero/infinite/indeterminate';
  x=0:0.1:1; y=[3,2,1,1,2,3,2,0.5,2,3,4];
  d=LOCAL_dips(x,y,true(size(x)),config,false);
  assert(numel(d.runs)==2 && d.runs{1}.plateau); checks{end+1}='all dips and exact plateau';
  d=LOCAL_dips(x,1-x,true(size(x)),config,true);
  assert(isequal(d.edge_indices,numel(x))); checks{end+1}='descending endpoint pending';
  d=LOCAL_dips(1:4,[1,1,2,3],true(1,4),config,false);
  assert(isequal(d.edge_indices,1)); checks{end+1}='endpoint exact plateau pending';
  valid=true(size(x)); valid(4)=false; d=LOCAL_dips(x,y,valid,config,false);
  assert(isequal(d.failed_indices,4) && numel(d.runs)==1); checks{end+1}='failure neighborhood preserved';
  d=LOCAL_dips(1:5,[1,0,1e-16,0,1],true(1,5),config,true);
  assert(numel(d.runs)==2 && numel(d.groups)==1); checks{end+1}='roundoff ambiguity cluster';
  d=LOCAL_dips(1:5,[1,0,1e-6,0,1],true(1,5),config,true);
  assert(numel(d.groups)==2); checks{end+1}='distinguishable shallow dips split';
  state=LOCAL_initial(config); timer=tic;
  [state,ids]=LOCAL_schedule(state,[1,1,1+eps],'coarse',@LOCAL_fake,false,'',timer);
  [state,fine]=LOCAL_schedule(state,1,'fine',@LOCAL_fake,false,'',timer);
  [state,confirm]=LOCAL_schedule(state,1,'fine',@LOCAL_fake,true,'',timer);
  assert(ids(1)==ids(2) && ids(3)~=ids(1) && fine~=ids(1) && confirm~=fine);
  assert(state.counters.requested==5 && state.counters.computed==4 && state.counters.cache_hits==1);
  checks{end+1}='binary64 cache and resolution separation and bypass';
  test=config; test.search.wide_first=0; test.search.wide_step=1/32;
  test.search.width_target=1e-6; test.search.max_rounds=30;
  state=LOCAL_manage(LOCAL_initial(test),@LOCAL_fake,'',tic);
  assert(numel(state.coarse_dips)==2 && numel(state.candidates)>=2);
  assert(all(cellfun(@(c) strcmp(c.status,'COMPLETE'),state.candidates)));
  assert(all(cellfun(@(c) c.W<=test.search.width_target,state.candidates)));
  checks{end+1}='full two-dip manager with shifted fine minima';
  split=LOCAL_manage(LOCAL_initial(test),@LOCAL_split_fake,'',tic);
  assert(numel(split.coarse_dips)==1 && numel(split.candidates)==2);
  assert(any(cellfun(@(t) strcmp(t.status,'SPLIT'),split.intervals)));
  checks{end+1}='coarse single dip splits into two fine branches';
  failure=LOCAL_initial(config);
  [failure,failure_ids]=LOCAL_schedule(failure,1,'fine',@LOCAL_failure_fake,false,'',tic);
  assert(strcmp(failure.points{failure_ids}.status,'FAILED'));
  checks{end+1}='evaluation exception retained without artificial score';
  endpoint=LOCAL_manage(LOCAL_initial(test),@LOCAL_endpoint_fake,'',tic);
  assert(any(cellfun(@(t) strcmp(t.status,'BOUNDARY_UNRESOLVED'),endpoint.intervals)));
  assert(any(cellfun(@(t) strcmp(t.kind,'RECOVERY_INTERNAL_DIP'),endpoint.intervals)));
  checks{end+1}='endpoint recovery retains internal pending branches';
  multiple=LOCAL_initial(test); multiple.coarse_done=true;
  multiple.common_gaps={struct('bounds',[0.15,0.45]),struct('bounds',[0.55,0.85])};
  for g=1:2
    task=LOCAL_task(g,0,g,multiple.common_gaps{g}.bounds,'SYNTHETIC_COMMON_GAP');
    task.gap_id=g; multiple.intervals{end+1}=task;
  end
  multiple=LOCAL_manage(multiple,@LOCAL_fake,'',tic);
  assert(numel(multiple.candidates)==2);
  for h=1:numel(multiple.history)
    record=multiple.history{h}; task=multiple.intervals{record.interval_id};
    bounds=multiple.common_gaps{task.gap_id}.bounds;
    assert(all(record.k>=bounds(1) & record.k<=bounds(2)));
  end
  checks{end+1}='disjoint common-gap scheduling keeps every grid inside its source';
  report=struct('status','PASS','checks',{checks},'manager_counters',state.counters, ...
    'coarse_dips',numel(state.coarse_dips),'candidates',numel(state.candidates));
end

function [point,evidence]=LOCAL_fake(k,res)
  shift=0; if strcmp(res,'fine'), shift=0.003; end
  score=((k-(0.3+shift))*(k-(0.7+shift)))^2+1e-12;
  point=struct('k',k,'resolution_id',res,'adef_sigma',score,'adef_ratio',score, ...
    'aphys_sigma',score,'aphys_ratio',score,'seconds',0,'valid',true,'status','SUCCESS');
  evidence=[];
end

function [point,evidence]=LOCAL_endpoint_fake(k,res)
  [point,evidence]=LOCAL_fake(k,res);
  if strcmp(res,'coarse'), value=(k-0.6)^2+1e-3;
  else, value=k+1-0.03*exp(-((k-0.6)/0.01)^2); end
  point.adef_sigma=value; point.adef_ratio=value;
  point.aphys_sigma=value; point.aphys_ratio=value;
end

function direction=LOCAL_edge_direction(index,count)
  if index==1, direction='LEFT'; else, assert(index==count); direction='RIGHT'; end
end

function [point,evidence]=LOCAL_split_fake(k,res)
  [point,evidence]=LOCAL_fake(k,res);
  if strcmp(res,'coarse'), value=(k-0.5)^2+1e-3;
  else, value=((k-0.48)*(k-0.52))^2+1e-12; end
  point.adef_sigma=value; point.adef_ratio=value;
  point.aphys_sigma=value; point.aphys_ratio=value;
end

function point=LOCAL_failure_fake(~,~)
  error('i91:SyntheticFailure','Deliberate cheap synthetic evaluator failure.');
  point=[]; %#ok<UNRCH>
end

%% ==================== Bounded lead cache and point interface ====================
% Cache identity includes the entire configuration, resolution and exact binary64 k.
function varargout=LOCAL_lead_store(action,varargin)
  persistent cache records requests failures config bytes peak evictions
  switch action
    case 'reset'
      config=varargin{1}; cache={}; records={}; requests={}; failures={}; bytes=0; peak=0; evictions=0;
    case 'get'
      k=varargin{1}; res=varargin{2}; bypass=varargin{3};
      key=[jsonencode(config),'|',res,'|',num2hex(k)]; hit=0;
      if ~bypass
        for j=1:numel(cache), if strcmp(cache{j}.key,key), hit=j; break; end; end
      end
      if hit>0
        entry=cache{hit}; cache(hit)=[]; cache{end+1}=entry;
        lead=entry.lead; spent=0; record_id=entry.record_id; action_name='CACHE_HIT';
      else
        started=tic;
        try
          lead=search_i9_physics('leads',k,res,config);
        catch error
          failures{end+1}=struct('k',k,'k_hex',num2hex(k),'resolution_id',res, ...
            'identifier',error.identifier,'message',error.message,'seconds',toc(started),'bypass',bypass);
          rethrow(error);
        end
        spent=toc(started);
        record_id=numel(records)+1;
        records{end+1}=struct('id',record_id,'k',k,'k_hex',num2hex(k), ...
          'resolution_id',res,'common_gap',lead.common_gap,'seconds',spent, ...
          'negative',lead.negative_diagnostic,'positive',lead.positive_diagnostic, ...
          'negative_bie_residual',lead.negative.solve_relative_residual, ...
          'positive_bie_residual',lead.positive.solve_relative_residual, ...
          'proxy_calls',lead.proxy_calls,'bypass',bypass);
        info=whos('lead'); size_bytes=info.bytes;
        while ~isempty(cache) && bytes+size_bytes>config.gap.cache_bytes
          bytes=bytes-cache{1}.bytes; cache(1)=[]; evictions=evictions+1;
        end
        if size_bytes<=config.gap.cache_bytes
          cache{end+1}=struct('key',key,'lead',lead,'bytes',size_bytes,'record_id',record_id);
          bytes=bytes+size_bytes; peak=max(peak,bytes);
        end
        action_name='COMPUTED';
      end
      requests{end+1}=struct('k',k,'k_hex',num2hex(k),'resolution_id',res, ...
        'action',action_name,'record_id',record_id,'bypass',bypass);
      varargout={lead,spent,record_id};
    case 'log'
      varargout={struct('records',{records},'requests',{requests},'failures',{failures},'cache_peak_bytes',peak, ...
        'cache_bytes',bytes,'evictions',evictions)};
  end
end

function [point,evidence]=LOCAL_evaluate(k,res,config)
% nargout=2 is used only for fresh final confirmations, bypassing lead reuse too.
  timer=tic; bypass=nargout>1;
  [lead,~,record_id]=LOCAL_lead_store('get',k,res,bypass);
  assert(lead.common_gap,'i91:NotCommonGap','Fine/coarse point is not a qualified common gap.');
  [point,evidence]=search_i9_physics('match',k,res,config,lead);
  point.seconds=toc(timer); point.lead_record_id=record_id;
  values=[point.adef_sigma,point.adef_ratio,point.aphys_sigma,point.aphys_ratio];
  assert(all(isfinite(values)) && all(values>=0),'i91:NonfiniteMetrics');
end

%% ==================== Gap discovery and numerical transition brackets ====================
% A numerical GAP segment never crosses an unqualified or failed sample.
function state=LOCAL_gap_stage(state,output_dir,timer)
  config=state.config; started=tic;
  grid=config.search.wide_first+(0:config.search.wide_count-1)*config.search.wide_step;
  [negative,positive,ids]=LOCAL_classify_grid(grid,'coarse');
  state.gap_exploration=struct('k',grid,'negative',{negative},'positive',{positive},'lead_record_ids',ids);
  state=LOCAL_gap_segments(state,grid,negative,positive,output_dir,timer);
  if isempty(state.common_gaps)
    grid=linspace(config.gap.extension_bounds(1),config.gap.extension_bounds(2),config.gap.extension_count);
    [negative,positive,ids]=LOCAL_classify_grid(grid,'coarse');
    state.gap_extension=struct('k',grid,'negative',{negative},'positive',{positive},'lead_record_ids',ids);
    state=LOCAL_gap_segments(state,grid,negative,positive,output_dir,timer);
  end
  state.timing.gap=toc(started);
  % The representative checks use both side-specific S blocks at three points.
  validation_timer=tic;
  for g=1:numel(state.common_gaps)
    interval=state.common_gaps{g}; nodes=unique([interval.bounds,mean(interval.bounds)]);
    usable=true;
    for k=nodes
      [coarse,~,cid]=LOCAL_lead_store('get',k,'coarse',false);
      [fine,~,fid]=LOCAL_lead_store('get',k,'fine',false);
      check=struct('gap_id',g,'k',k,'coarse_record_id',cid,'fine_record_id',fid, ...
        'coarse_common_gap',coarse.common_gap,'fine_common_gap',fine.common_gap);
      for side={'negative','positive'}
        name=side{1}; c=coarse.(name); f=fine.(name);
        Sc=[c.R_L,c.T_RL;c.T_LR,c.R_R]; Sf=[f.R_L,f.T_RL;f.T_LR,f.R_R];
        check.([name,'_scatter_absolute'])=norm(Sc-Sf,'fro');
        check.([name,'_scatter_relative'])=norm(Sc-Sf,'fro')/max(norm(Sf,'fro'),realmin);
      end
      state.representative_checks{end+1}=check;
      usable=usable && coarse.common_gap && fine.common_gap;
    end
    if usable, interval.status='USABLE'; else, interval.status='FINE_CLASSIFICATION_UNRESOLVED'; end
    state.common_gaps{g}=interval;
  end
  first=find(cellfun(@(g) strcmp(g.status,'USABLE'),state.common_gaps),1);
  if ~isempty(first)
    k=mean(state.common_gaps{first}.bounds); lead=LOCAL_lead_store('get',k,'coarse',false);
    [state.equal_validation,evidence]=search_i9_physics('equal_validation',k,'coarse',config,lead);
    save(fullfile(output_dir,'equal-lead-validation.mat'),'evidence','-v7');
    assert(state.equal_validation.Adef_absolute<1e-10 && state.equal_validation.Aphys_absolute<1e-10, ...
      'i91:EqualLeadRegression');
    assert(state.equal_validation.negative_positive_S_difference>1e-8,'i91:DistinctLeads');
  end
  state.timing.validation=toc(validation_timer);
  LOCAL_save(state,output_dir,timer);
end

function [negative,positive,ids]=LOCAL_classify_grid(grid,res)
  negative=cell(size(grid)); positive=cell(size(grid)); ids=zeros(size(grid));
  for j=1:numel(grid)
    try
      [lead,~,ids(j)]=LOCAL_lead_store('get',grid(j),res,false);
      negative{j}=lead.negative_diagnostic.status; positive{j}=lead.positive_diagnostic.status;
    catch error
      negative{j}='FAILED'; positive{j}='FAILED';
      % Keep the actual failure in the run log; failed samples remain explicit.
      fprintf(2,'LEAD_FAILURE k=%.17g %s %s\n',grid(j),error.identifier,error.message);
    end
  end
end

function state=LOCAL_gap_segments(state,grid,negative,positive,output_dir,timer)
  sides={'negative','positive'}; labels={negative,positive};
  state.gap_sides=struct(); state.common_gaps={};
  for s=1:2
    segments={}; classes=labels{s}; gap=strcmp(classes,'GAP'); j=1;
    while j<=numel(grid)
      if ~gap(j), j=j+1; continue; end
      first=j; while j<numel(grid) && gap(j+1), j=j+1; end; last=j;
      left=LOCAL_edge(grid,classes,first,-1,sides{s},state.config);
      right=LOCAL_edge(grid,classes,last,1,sides{s},state.config);
      safe=[left.gap_point+state.config.gap.buffer,right.gap_point-state.config.gap.buffer];
      segments{end+1}=struct('id',numel(segments)+1,'side',sides{s},'grid_first',first, ...
        'grid_last',last,'left',left,'right',right,'safe_bounds',safe,'usable',safe(2)>safe(1));
      j=j+1;
    end
    state.gap_sides.(sides{s})=segments;
  end
  for n=1:numel(state.gap_sides.negative)
    neg=state.gap_sides.negative{n};
    for p=1:numel(state.gap_sides.positive)
      pos=state.gap_sides.positive{p};
      bounds=[max(neg.safe_bounds(1),pos.safe_bounds(1)),min(neg.safe_bounds(2),pos.safe_bounds(2))];
      if neg.usable && pos.usable && bounds(2)>bounds(1)
        state.common_gaps{end+1}=struct('id',numel(state.common_gaps)+1,'negative_segment',n, ...
          'positive_segment',p,'bounds',bounds,'status','REPRESENTATIVE_CHECK_PENDING');
      end
    end
  end
  LOCAL_save(state,output_dir,timer);
end

function edge=LOCAL_edge(grid,classes,index,direction,side,config)
  inside=grid(index); neighbor=index+direction;
  if neighbor<1 || neighbor>numel(grid)
    edge=struct('status','WINDOW_TRUNCATED','gap_point',inside,'excluded_point',inside, ...
      'excluded_class','OUTSIDE_WINDOW','width',0,'iterations',0); return;
  end
  outside=grid(neighbor); excluded=classes{neighbor}; iterations=0;
  eligible={'NEAR_UNIT_PROPAGATING','UNCERTAIN'};
  if ~ismember(excluded,eligible)
    edge=struct('status','FAILED_OR_UNQUALIFIED_NEIGHBOR','gap_point',inside, ...
      'excluded_point',outside,'excluded_class',excluded,'width',abs(outside-inside),'iterations',0); return;
  end
  status='NUMERICAL_TRANSITION_BRACKET';
  while abs(outside-inside)>config.gap.edge_width
    mid=(inside+outside)/2;
    try
      lead=LOCAL_lead_store('get',mid,'coarse',false); diagnostic=lead.([side,'_diagnostic']);
      label=diagnostic.status;
    catch error
      fprintf(2,'EDGE_FAILURE k=%.17g %s %s\n',mid,error.identifier,error.message);
      status='FAILED_UNRESOLVED'; break;
    end
    iterations=iterations+1;
    if strcmp(label,'GAP'), inside=mid;
    elseif ismember(label,eligible), outside=mid; excluded=label;
    else, status='UNQUALIFIED_UNRESOLVED'; break; end
  end
  edge=struct('status',status,'gap_point',inside,'excluded_point',outside, ...
    'excluded_class',excluded,'width',abs(outside-inside),'iterations',iterations);
end

function state=LOCAL_seed_search(state,evaluator,output_dir,timer)
  for g=1:numel(state.common_gaps)
    interval=state.common_gaps{g};
    if ~strcmp(interval.status,'USABLE'), continue; end
    log=LOCAL_lead_store('log');
    available=cellfun(@(r) r.k,log.records(cellfun(@(r) strcmp(r.resolution_id,'coarse'),log.records)));
    grid=LOCAL_gap_grid(interval.bounds,available,state.config);
    [state,ids]=LOCAL_schedule(state,grid,'coarse',evaluator,false,output_dir,timer);
    [scores,valid]=LOCAL_scores(state,ids); detected=LOCAL_dips(grid,scores,valid,state.config,false);
    state.coarse_runs{end+1}=struct('gap_id',g,'k',grid,'point_ids',ids,'detection',detected);
    for r=1:numel(detected.runs)
      dip=detected.runs{r}; dip.id=numel(state.coarse_dips)+1; dip.gap_id=g;
      dip.point_ids=ids(dip.first:dip.last);
      bounds=grid([max(1,dip.first-2),min(numel(grid),dip.last+2)]);
      id=numel(state.intervals)+1; dip.interval_id=id;
      state.coarse_dips{end+1}=dip;
      task=LOCAL_task(id,0,dip.id,bounds,'COARSE_DIP'); task.gap_id=g;
      state.intervals{end+1}=task;
    end
    for edge=detected.edge_indices
      if edge==1, bounds=grid([1,min(4,numel(grid))]);
      else, bounds=grid([max(1,numel(grid)-3),numel(grid)]); end
      id=numel(state.intervals)+1; task=LOCAL_task(id,0,[],bounds,'COARSE_ENDPOINT'); task.gap_id=g;
      state.intervals{end+1}=task;
      state.edge_records{end+1}=struct('interval_id',id,'round',0,'index',edge, ...
        'status','FINE_ENDPOINT_CHECK_PENDING','point_id',ids(edge));
    end
    if any(~valid)
      state.common_gaps{g}.search_status='COARSE_MATCHING_OR_CLASSIFICATION_FAILURE';
      state.common_gaps{g}.failed_point_ids=ids(~valid);
    else, state.common_gaps{g}.search_status='COARSE_SEARCH_DONE'; end
    LOCAL_save(state,output_dir,timer);
  end
  state.coarse_done=true;
  estimate=numel(state.intervals)*(11+20*9+1)*state.config.resources.initial_fine_point_seconds;
  state.remaining_search_estimate=estimate;
  if estimate+toc(timer)+state.config.resources.reserve_seconds>state.config.resources.hard_seconds
    state.status='BUDGET_REASSESSMENT_REQUIRED';
    LOCAL_save(state,output_dir,timer);
  end
end

%% ==================== Geometry validation and figures ====================
% Analytic radial derivatives use the existing [x,xprime,xsecond,y,...] layout.
function report=LOCAL_geometry(config,output_dir)
  n=config.validation.geometry_nodes; model=config.model;
  [negative,~,nd]=search_i9_geometry(n,model.a_negative,model.R,model);
  [positive,~,pd]=search_i9_geometry(n,model.a_positive,model.R,model);
  [center,~]=geom.construct_cont(n,'star',0,0); center=center*model.star_scale;
  report=struct('negative',nd,'positive',pd, ...
    'center_minimum_speed',min(hypot(center(2,:),center(5,:))), ...
    'center_wall_clearance',min(model.X_R-max(center(1,:)),min(center(1,:))-model.X_L), ...
    'center_vertical_clearance',model.d/2-max(abs(center(4,:))), ...
    'center_scale',model.star_scale,'center_position_envelope',[0.36,0.26]*model.star_scale, ...
    'center_expected_area',0.0618*pi*model.star_scale^2,'center_area', ...
    sum(center(1,:).*center(5,:)-center(4,:).*center(2,:))*pi/n);
  assert(abs(nd.area-nd.exact_area)<1e-12 && abs(pd.area-pd.exact_area)<1e-12);
  assert(abs(report.center_area-report.center_expected_area)<1e-12);
  assert(max(abs(center(1,:)))<=report.center_position_envelope(1)+1e-12 && ...
    max(abs(center(4,:)))<=report.center_position_envelope(2)+1e-12);
  assert(report.center_minimum_speed>0 && ...
    report.center_wall_clearance>=min(model.X_R,-model.X_L)-report.center_position_envelope(1)-1e-12 && ...
    report.center_vertical_clearance>=model.d/2-report.center_position_envelope(2)-1e-12);
  if isempty(output_dir), return; end
  f=figure('Visible','off'); hold on;
  for x=-3:3
    if x<0, C=negative; elseif x>0, C=positive; else, C=center; end
    for y=-1:1
      plot(C(1,:)+x*model.L,C(4,:)+y*model.d,'LineWidth',1.2);
    end
  end
  for x=-3.5:1:3.5, xline(x,':','Color',[.7,.7,.7]); end
  axis equal; grid on; xlabel('global x'); ylabel('global y');
  title(sprintf('I9.1 negative a=0.12 | center scale %.8g | positive a=0.20',model.star_scale));
  exportgraphics(f,fullfile(output_dir,'geometry.png')); close(f);
  LOCAL_json(fullfile(output_dir,'geometry.json'),report);
end

function grid=LOCAL_gap_grid(bounds,existing,config)
% Build from endpoints and current-run nodes, with exact binary64 uniqueness.
  grid=unique([bounds,existing(existing>bounds(1) & existing<bounds(2))]);
  additions=[];
  for j=1:numel(grid)-1
    count=ceil((grid(j+1)-grid(j))/config.search.wide_step);
    if count>1, additions=[additions,linspace(grid(j),grid(j+1),count+1)]; end %#ok<AGROW>
  end
  grid=unique([grid,additions]);
  if numel(grid)<config.search.refine_count
    grid=unique([grid,linspace(bounds(1),bounds(2),config.search.refine_count)]);
  end
  assert(all(diff(grid)>0) && max(diff(grid))<=config.search.wide_step+8*eps);
end
