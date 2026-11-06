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

-- Edges per peer repo. rest/msg/call: runtime traffic; mvn: build dependency (Maven or
-- Gradle) on coordinates this repo publishes; imp: production code importing a package
-- this repo declares, unless the importer declares it too (repo_class.imported_by's rule).
create temp table pkg_decl as
select distinct repo, rtrim(rtrim(fqcn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_$'), '.') as pkg
from classes where is_test = 0;
create temp table pkg_imp as
select distinct repo, case when wildcard = 1 and static = 0 then name
	else rtrim(rtrim(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_$'), '.') end as pkg
from imports where is_test = 0;
create index temp.pkg_decl_pkg on pkg_decl(pkg, repo);

create temp table edge(dir, peer, kind);
insert into edge
select 'in', from_repo, 'rest' from rest_edges where to_repo = :r
union all select 'in', from_repo, 'msg' from msg_edges where to_repo = :r
union all select 'in', from_repo, 'call' from calls where to_repo = :r
union all select 'in', b.repo, 'mvn' from build_dep b
	join artifact_repo a using (group_id, artifact_id) where a.repo = :r
union all select distinct 'in', i.repo, 'imp' from pkg_decl d join pkg_imp i on i.pkg = d.pkg
	where d.repo = :r and not exists (select 1 from pkg_decl x where x.repo = i.repo and x.pkg = d.pkg)
union all select 'out', to_repo, 'rest' from rest_edges where from_repo = :r
union all select 'out', to_repo, 'msg' from msg_edges where from_repo = :r
union all select 'out', to_repo, 'call' from calls where from_repo = :r
union all select 'out', a.repo, 'mvn' from build_dep b
	join artifact_repo a using (group_id, artifact_id) where b.repo = :r
union all select distinct 'out', d.repo, 'imp' from pkg_imp i join pkg_decl d on d.pkg = i.pkg
	where i.repo = :r and not exists (select 1 from pkg_decl x where x.repo = :r and x.pkg = i.pkg);
delete from edge where peer = :r or peer is null or peer = '';

create temp view peer as
select e.dir, e.peer, coalesce(o.owner, '?') as owner,
       sum(e.kind = 'rest') as rest, sum(e.kind = 'msg') as msg,
       sum(e.kind = 'call') as call, sum(e.kind = 'mvn') as mvn, sum(e.kind = 'imp') as imp,
       count(*) as n
from edge e left join repo_owner o on o.repo = e.peer
group by e.dir, e.peer;

.print
select 'depends-on-this', count(*) || ' repos, ' || count(distinct owner) || ' owners'
from peer where dir = 'in';
.headers on
select peer, owner, rest, msg, call, mvn, imp from peer where dir = 'in' order by n desc, peer;
.headers off
.print
select 'this-depends-on', count(*) || ' repos, ' || count(distinct owner) || ' owners'
from peer where dir = 'out';
.headers on
select peer, owner, rest, msg, call, mvn, imp from peer where dir = 'out' order by n desc, peer;
