-- endpoints: one repo's inbound REST surface. Run by endpoints.sh, which binds :r.
-- Source: wires rows of kind rest_in (verb + path with the class-level prefix applied,
-- one row per config profile); handler = the first production method declared at or
-- after the annotation's line in the same file.
.headers off
.mode list
.separator "\t"
select 'scan', value from estate_meta where key = 'imported_at';
select 'repo', :r;
select 'context-path', group_concat(distinct value) from config
where repo = :r and key = 'server.servlet.context-path' and profile = 'default'
having count(*) > 0;

create temp table ep as
select w.path, w.line, case when w.method = '' then 'ANY' else w.method end as verb,
       w.resolved as route, count(distinct w.profile) as nprof,
       group_concat(distinct nullif(w.profile, '')) as profiles
from wires w
join files f on f.repo = w.repo and f.path = w.path and f.is_test = 0
where w.repo = :r and w.kind = 'rest_in'
group by w.path, w.line, verb, route;

-- profiles: '*' when the endpoint exists in every profile the repo's endpoints use.
select e.verb, e.route,
       coalesce((select substr(m.fqcn, length(rtrim(m.fqcn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_$')) + 1)
                        || '.' || m.name
                 from methods m
                 where m.repo = :r and m.path = e.path and m.is_test = 0 and m.line >= e.line
                 order by m.line limit 1), '?'),
       e.path || ':' || e.line,
       case when e.nprof = (select max(nprof) from ep) then '*' else coalesce(e.profiles, '') end
from ep e
order by e.route, e.verb;
