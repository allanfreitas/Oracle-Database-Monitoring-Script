
select c.CON_ID, c.NAME, c.OPEN_MODE, c.RESTRICTED,
    case when c.OPEN_MODE not like 'READ%' and c.CON_ID = sys_context('USERENV', 'CON_ID') and c.CON_ID != 0 then
              'NOT OPEN! DBA_FEATURE_USAGE_STATISTICS is not accessible. *CURRENT CONTAINER'
         when c.OPEN_MODE not like 'READ%' then
              'NOT OPEN! DBA_FEATURE_USAGE_STATISTICS is not accessible.'
         when c.CON_ID = sys_context('USERENV', 'CON_ID') and d.CDB='YES' and c.CON_ID not in (0, 1) then
              '*CURRENT CONTAINER. Only data for this PDB will be listed.'
         when c.CON_ID = sys_context('USERENV', 'CON_ID') and d.CDB='YES' and c.CON_ID = 1 then
              '*CURRENT CONTAINER is CDB$ROOT. Information for all open PDBs will be listed.'
         else ''
    end as REMARKS
    from V$CONTAINERS c, V$DATABASE d
    order by CON_ID;