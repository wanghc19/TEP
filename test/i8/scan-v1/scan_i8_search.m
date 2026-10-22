function state = scan_i8_search(output_dir,mode)
%SCAN_I8_SEARCH Two-resolution all-dip search with exact-double point reuse.
% Purpose: Execute design-8-5a without historical candidates or old scripts.
% Input: output_dir for this run; mode 'run', 'selftest', or 'config'.
% Output: state contains points, interval lineage, rounds and final candidates.
% Main algorithm: coarse grid -> all dips -> expanded fine grids -> all branches.
% Notes: Grid construction, physics, scheduling, detection and export are separate.
%   R_num and all spectral-distance evaluation are intentionally absent.
  if nargin < 2, mode = 'run'; end
  config = scan_i8_config();
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
  assert(~exist(fullfile(output_dir,'checkpoint.mat'),'file'),'i85:ExistingRun');
  state=LOCAL_initial(config);
  timer=tic;
  evaluator=@(k,res) scan_i8_point(k,res,config);
  try
    state=LOCAL_manage(state,evaluator,output_dir,timer);
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
  state=struct('schema','I85_SCAN_STATE_V1','config',config,'config_key',jsonencode(config), ...
    'points',{{}},'requests',{{}},'intervals',{{}},'history',{{}},'candidates',{{}}, ...
    'coarse_dips',{{}},'edge_records',{{}},'confirmations',{{}}, ...
    'status','RUNNING','coarse_done',false,'elapsed_before',0, ...
    'timing',struct('coarse',0,'fine',0,'confirmation',0), ...
    'counters',struct('requested',0,'computed',0,'cache_hits',0,'confirmation',0));
end

function k=LOCAL_grid(bounds,count,existing,kind,config)
% Grid construction has no access to physical scores or matrices.
  if strcmp(kind,'wide')
    k=config.search.wide_first+(0:config.search.wide_count-1)*config.search.wide_step;
  else
    k=linspace(bounds(1),bounds(2),count);
  end
  assert(all(isfinite(k)) && all(diff(k)>0),'i85:DuplicateGrid', ...
    'Actual binary64 grid is not finite and strictly increasing.');
  if ~isempty(existing)
    assert(~isequal(k,existing),'i85:RepeatedGrid','Actual grid did not change.');
  end
end

function task=LOCAL_task(id,parent,source,bounds,kind)
  task=struct('id',id,'parent_id',parent,'source_ids',source,'resolution_id','fine', ...
    'bounds',bounds,'initial_bounds',bounds,'kind',kind,'round',0, ...
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
        point.status='SUCCESS';
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
    if ~isempty(output_dir) && estimated+state.elapsed_before+toc(timer)>config.resources.soft_seconds
      state.status='BUDGET_REASSESSMENT_REQUIRED'; LOCAL_save(state,output_dir,timer); return;
    end
  end
  cursor=1;
  while cursor<=numel(state.intervals)
    task=state.intervals{cursor};
    if ~ismember(task.status,{'PENDING','RUNNING'}), cursor=cursor+1; continue; end
    task.status='RUNNING';
    while strcmp(task.status,'RUNNING')
      if task.round>=search.max_rounds
        task.status='ROUND_LIMIT'; task.stop_reason='maximum safety round count'; break;
      end
      if ~isempty(output_dir) && state.elapsed_before+toc(timer)>config.resources.soft_seconds- ...
          config.resources.reserve_seconds
        task.status='BUDGET_EXHAUSTED'; task.stop_reason='shared scientific time reserve'; break;
      end
      try
        grid=LOCAL_grid(task.bounds,search.refine_count,task.last_grid,'local',config);
      catch error
        if ~ismember(error.identifier,{'i85:DuplicateGrid','i85:RepeatedGrid'}), rethrow(error); end
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
  state.pending_edge_count=sum(cellfun(@(e) strcmp(e.status,'NONWINNING_EDGE_PENDING'),state.edge_records));
  confirmations_ok=all(cellfun(@(r) strcmp(r.status,'SUCCESS'),state.confirmations));
  if ~confirmations_ok
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
  checkpoint=fullfile(output_dir,'checkpoint.mat'); save(checkpoint,'state','-v7');
  LOCAL_json(fullfile(output_dir,'state.json'),state);
end

function LOCAL_json(path,value)
  fid=fopen(path,'w'); assert(fid>=0,'i85:Output'); closer=onCleanup(@() fclose(fid)); %#ok<NASGU>
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
    xlabel('k'); ylabel('aphys ratio'); title('I8.5 coarse C256 / L128 search window');
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
  error('i85:SyntheticFailure','Deliberate cheap synthetic evaluator failure.');
  point=[]; %#ok<UNRCH>
end
