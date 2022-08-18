set lines 500
col NEW_IDX_percentage format 999.99999
col idxname     format a38      head "Owner.Index"
col uniq        format a01      head "U"
col tsname      format a28      head "Tablespace"
col xtrblk      format 999999   head "Extra|Blocks"
col lfcnt       format 9999999  head "Leaf|Blocks"
col blk         format 9999999  head "Curr|Blocks"
col currmb      format 99999    head "Curr|MB"
col newmb       format 99999    head "New|MB"
select
  u.name ||'.'|| o.name  idxname,
  decode(bitand(i.property, 1), 0,' ', 1, 'x','?') uniq,
  ts.name tsname,
  seg.blocks blk,
  i.leafcnt lfcnt,
  floor((1 - i.pctfree$/100) * i.leafcnt - i.rowcnt * (sum(h.avgcln) + 11) / (8192 - 66 - i.initrans * 24)  ) xtrblk,
    round(seg.bytes/(1024*1024)) currmb,
  (1 + i.pctfree$/100) * (i.rowcnt * (sum(h.avgcln) + 11) / (i.leafcnt * (8192 - 66 - i.initrans * 24)) 
* seg.bytes/(1024*1024)) newmb,
  ((1 + i.pctfree$/100) * (i.rowcnt * (sum(h.avgcln) + 11) / (i.leafcnt * (8192 - 66 - i.initrans * 24)) 
* seg.bytes/(1024*1024)))*100/(seg.bytes/(1024*1024)) NEW_IDX_percentage,
  (100-((1 + i.pctfree$/100) * (i.rowcnt * (sum(h.avgcln) + 11) / (i.leafcnt * (8192 - 66 - i.initrans * 24)) 
* seg.bytes/(1024*1024)))*100/(seg.bytes/(1024*1024))) Benifit_percent
from
  sys.ind$  i,
  sys.icol$  ic,
  sys.hist_head$  h,
  sys.obj$  o,
  sys.user$  u,
  sys.ts$ ts,
  dba_segments seg
where
  i.leafcnt > 1 and
  i.type# in (1,4,6) and                -- exclude special types
  ic.obj# = i.obj# and
  h.obj# = i.bo# and
  h.intcol# = ic.intcol# and
  o.obj# = i.obj# and
  o.owner# != 0 and
  u.user# = o.owner# and
  i.ts# = ts.ts# and
  u.name = seg.owner and
  o.name = seg.segment_name and
  seg.blocks > i.leafcnt                -- if i.leafcnt > seg.blocks then statistics are not up-to-date
group by
   u.name,
  decode(bitand(i.property, 1), 0,' ', 1, 'x','?'),
  ts.name,
  o.name,
  i.rowcnt,
  i.leafcnt,
  i.initrans,
  i.pctfree$,
--p.value,
  i.blevel,
  i.leafcnt,
  seg.bytes,
  i.pctfree$,
  i.initrans,
  seg.blocks
 having
  50 * i.rowcnt * (sum(h.avgcln) + 11)
  < (i.leafcnt * (8192 - 66 - i.initrans * 24)) * (50 - i.pctfree$) and
  floor((1 - i.pctfree$/100) * i.leafcnt -
    i.rowcnt * (sum(h.avgcln) + 11) / (8192 - 66 - i.initrans * 24)  ) > 0 and
((1 + i.pctfree$/100) * (i.rowcnt * (sum(h.avgcln) + 11) / (i.leafcnt * (8192 - 66 - i.initrans * 24))
 * seg.bytes/(1024*1024)))*100/(seg.bytes/(1024*1024)) <80
and round(seg.bytes/(1024*1024)) > 50
order by 10,9, 2;
quit;