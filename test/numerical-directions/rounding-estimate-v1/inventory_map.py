"""Map all 100 original inventory items to this estimate's four classes.
Input: read-only Stage 8a rows and current estimate rows. Output: CSV/JSON map.
"""
from pathlib import Path
import json,csv
here=Path(__file__).resolve().parent;old=json.loads((here.parent/'rounding-v1/probe/inventory-rows.json').read_text());new=json.loads((here/'output/estimates.json').read_text())['rows'];out=[]
for i,r in enumerate(old,1):
  stage=r['stage'];kind=r['kind'];scope=[z['id'] for z in new if z['stage']==stage];topic={1:'数据可容许性与自由试探数据',2:'绝对项和、积分/矩阵组装',3:'Hermitian符号/惯性及几何测试',4:'超越函数、标量和完整精度交接'}[kind]
  if r['treatment']=='E0':ids=[];explanation='自由试探选择或整数结构，不把生成误差重复加入最终残差；见数据可容许性。'
  elif r['treatment']=='other':
    ids=scope if stage=='handoffs' else [z for z in scope if z.startswith('B3-')];explanation='标准gamma模型及下溢条件见标准事实；未采用B3另列，BIE纯诊断不进入链。'
  else:
    ids=scope if kind in [2,3] else list(dict.fromkeys(scope+[z['id'] for z in new if z['stage']=='handoffs']));explanation='按该阶段共同核的绝对尺度传播；完整参数见对应ID.inputs。'
  out.append({'inventory_row':i,'stage':stage,'source':r['file']+':'+str(r['line']),'quantity':r['quantity'],'kind':kind,'class':topic,'estimate_ids':ids,'note':explanation})
assert len(out)==100 and all(z['estimate_ids'] or z['note'] for z in out)
(here/'output/inventory-map.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
with (here/'output/inventory-map.csv').open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(out[0]));w.writeheader();w.writerows({**z,'estimate_ids':';'.join(z['estimate_ids'])} for z in out)
print('mapped',len(out))
