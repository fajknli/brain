BEGIN{OFS="\t";BR=ENVIRON["BRAIN_ROOT"];T=ENVIRON["BRAIN_TMP"]}
FNR==1{if(NR>1&&fm<2)print"UNCLOSED_FM",prev_rel>>T"/c";fm=0;ln=0;err=0;uid="";t="";d="";ty="note";s="live";done=0;rel=substr(FILENAME,length(BR)+2);fname=FILENAME;sub(/.*\//,"",fname);sub(/\.md$/,"",fname);prev_rel=rel;if(FILENAME~/sync-conflict/){print"SYNC_CONFLICT",rel>>T"/c";done=1;next}}
done{next}
{if(fm<2){ln++;if(ln>50){print"INVALID_FM",rel>>T"/c";done=1;err=1;next}}}
/^---$/{fm++;if(fm==2){done=1;if(uid==""){print"UID_MISSING",fname,rel>>T"/c";err=1}else if(fname!=uid){print"UID_MISMATCH",fname,uid,rel>>T"/c";err=1}gsub(/\t/," ",t);gsub(/[\r\n]/,"",t);if(!err)print fname,t,d,ty,s,rel>>T"/m"}next}
fm==1&&!err{if(/^uid:/){sub(/^uid:[ \t]*/,"");uid=$0}else if(/^title:/){sub(/^title:[ \t]*/,"");t=$0}else if(/^date:/){sub(/^date:[ \t]*/,"");d=$0}else if(/^type:/){sub(/^type:[ \t]*/,"");ty=$0}else if(/^status:/){sub(/^status:[ \t]*/,"");s=$0}else if(/^\+tag:/){sub(/^\+tag:[ \t]*/,"");gsub(/^[ \t]+/,"");gsub(/[ \t]+$/,"");gsub(/[\t\r\n]/,"_");if($0!="")print $0,fname>>T"/t"}else if(/^\+link:/){sub(/^\+link:[ \t]*/,"");sp=index($0," ");if(sp>0){tuid=substr($0,1,sp-1);r=substr($0,sp+1);gsub(/^[ \t]+/,"",r);gsub(/[ \t]+$/,"",r);print fname,tuid,r>>T"/l"}}}
END{if(fm<2&&!done)print"UNCLOSED_FM",prev_rel>>T"/c"}
