-- estate-card: one repo's place in the estate. Run by estate-card.sh, which binds :r.
-- Repo-level only: no hosts, paths or findings.
.headers off
.mode list
.separator "\t"
select 'scan', value from estate_meta where key = 'imported_at';
select 'repo', :r;
select 'class', class || '  prod-java=' || java_prod || '  endpoints=' || endpoints
       || '  commits_1y=' || commits_1y || '  last=' || last_commit
from repo_class where repo = :r;
select 'owner', owner || case when others <> '' then '  others=' || others else '' end
from repo_owner where repo = :r;
select 'deploy', group_concat(profile, ',') from repo_deployed where repo = :r having count(*) > 0;
select 'archive', verdict || ': ' || reasons from repo_archive where repo = :r;

-- Edges per peer repo. rest/msg/call: runtime traffic; lib: Maven dependency.
create temp table edge(dir, peer, kind);
insert into edge
select 'in', from_repo, 'rest' from rest_edges where to_repo = :r
union all select 'in', from_repo, 'msg' from msg_edges where to_repo = :r
union all select 'in', from_repo, 'call' from calls where to_repo = :r
union all select 'in', b.repo, 'lib' from build_dep b
	join artifact_repo a using (group_id, artifact_id) where a.repo = :r
union all select 'out', to_repo, 'rest' from rest_edges where from_repo = :r
union all select 'out', to_repo, 'msg' from msg_edges where from_repo = :r
union all select 'out', to_repo, 'call' from calls where from_repo = :r
union all select 'out', a.repo, 'lib' from build_dep b
	join artifact_repo a using (group_id, artifact_id) where b.repo = :r;
delete from edge where peer = :r or peer is null or peer = '';

create temp view peer as
select e.dir, e.peer, coalesce(o.owner, '?') as owner,
       sum(e.kind = 'rest') as rest, sum(e.kind = 'msg') as msg,
       sum(e.kind = 'call') as call, sum(e.kind = 'lib') as lib, count(*) as n
from edge e left join repo_owner o on o.repo = e.peer
group by e.dir, e.peer;

.print
select 'depends-on-this', count(*) || ' repos, ' || count(distinct owner) || ' owners'
from peer where dir = 'in';
.headers on
select peer, owner, rest, msg, call, lib from peer where dir = 'in' order by n desc, peer;
.headers off
.print
select 'this-depends-on', count(*) || ' repos, ' || count(distinct owner) || ' owners'
from peer where dir = 'out';
.headers on
select peer, owner, rest, msg, call, lib from peer where dir = 'out' order by n desc, peer;
