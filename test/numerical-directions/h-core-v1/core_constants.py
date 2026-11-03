"""Core projection constants for the isolation-hypothesis certificate.
Input: output JSON path. Output: analytic cutoff table and reference differences.
"""
import math,json,sys
refs=[(15,8,.0198895,.00928355),(31,16,.00994657,.00232175),(47,24,.00663127,.00103196),(63,32,.00497352,.00058049)]
rows=[]
for x,y,ch,bc in refs:
 ast=1+min(((x+1)*math.pi)**2+.25,(2*math.pi*(y+1)-.5)**2);c=1/math.sqrt(ast);b=23.4676/ast
 rows.append(dict(Nx=x,Ny=y,base_dimension=(x+1)*(2*y+1),a_star=ast,C_h=c,q_C_squared=b,c_W=1-b,delta=b/(1-b),relative_C=abs(c/ch-1),relative_q=abs(b/bc-1)))
json.dump({'lambda':5.6169,'sigma':1,'q_max':23.4676,'table':rows},open(sys.argv[1],'w'),indent=2)
print(rows)
