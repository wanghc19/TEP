"""Prepare I9 (inherited experiment identifier) source inputs in an explicit run.
The gap classification and fine sigma-minimum manager are copied unchanged;
only the dispatcher and output handling differ. No old numerical output is read.
"""
from pathlib import Path
import re

def prepare(source, destination):
  source=Path(source);dest=Path(destination);dest.mkdir(parents=True,exist_ok=False)
  text=(source/'search_i9_run.m').read_text();suffix=text[text.index('%% ==================== State and grid construction'):]
  suffix=suffix.replace("checkpoint=fullfile(output_dir,'checkpoint.mat'); save(checkpoint,'state','-v7');",'% Compact JSON checkpoints only.')
  suffix=suffix.replace("save(fullfile(output_dir,'equal-lead-validation.mat'),'evidence','-v7');",'% The equal-lead assertions below are retained; no large evidence file.')
  suffix=re.sub(r'Equal-lead matrix regression exceeds the .*? tolerance\.', 'Equal-lead matrix regression tolerance exceeded.', suffix)
  header='''function state=i9_adapter(action,out,config,arg)
%I9_ADAPTER I9 gap classifier and sigma-minimum fallback dispatcher.
% Input
%   action: gap, reset, lead, or fallback; out: explicit output directory;
%   config: original scientific configuration; arg: k or bracket specification.
% Output
%   state: original gap/refinement state, or a compact reusable lead bundle.
% Source: test/i9/search-v1/search_i9_run.m local algorithms. Their numerical
%   bodies are retained; gap/checkpoint MAT writes become JSON. The original
%   fresh-confirmation MAT evidence remains in the fallback output.
  if nargin<4,arg=[];end
  if strcmp(action,'reset'),LOCAL_lead_store('reset',config);state=[];return;end
  if strcmp(action,'lead'),state=LOCAL_lead_store('get',arg,'fine',false);return;end
  state=LOCAL_initial(config);timer=tic;
  if strcmp(action,'gap')
    LOCAL_lead_store('reset',config);state=LOCAL_gap_stage(state,out,timer);
  elseif strcmp(action,'fallback')
    state.common_gaps={struct('bounds',arg.domain,'status','USABLE')};
    task=LOCAL_task(1,0,[],arg.bounds,'DETERMINANT_FALLBACK');task.gap_id=1;
    state.intervals={task};state.coarse_done=true;
    evaluator=@(k,res) LOCAL_evaluate(k,res,config);
    state=LOCAL_manage(state,evaluator,out,timer);
  else,error('detsearch:Action','Unknown adapter action.');end
  state.elapsed_seconds=toc(timer);state.lead_log=LOCAL_lead_store('log');
  LOCAL_json(fullfile(out,'state.json'),state);
end

'''
  (dest/'i9_adapter.m').write_text(header+suffix)
  for name in ['search_i9_physics.m','search_i9_config.m','search_i9_classify.m','search_i9_geometry.m']:
    (dest/name).write_text((source/name).read_text())
