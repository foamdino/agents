// page-probe.sh probe for pages built from templates/report.html.
// Clicks every tab and every filter button; for each tab reports how many sections are
// visible (must be exactly 1) and how many table rows it shows. Throws on a broken tab.
//   ~/.config/agents/tools/page-probe.sh <report.html> ~/.config/agents/templates/report-probe.js
const tabs = $$(".tabs button");
if (tabs.length === 0) throw new Error("no .tabs buttons");
for (const t of tabs) {
	t.click();
	await sleep(20);
	const shown = $$(".view").filter(s => !s.hidden);
	if (shown.length !== 1 || shown[0].id !== t.dataset.view)
		throw new Error("tab " + t.dataset.view + " shows " + shown.map(s => s.id).join(","));
	const rows = $$("tbody tr", shown[0]).filter(r => !r.hidden).length;
	log("tab " + t.dataset.view + ": rows " + rows);
	for (const b of $$(".filt button", shown[0])) {
		b.click();
		await sleep(10);
		log("  filter " + b.dataset.f + ": rows " + $$("tbody tr", shown[0]).filter(r => !r.hidden).length);
	}
}
