const sites = [
  ["Harbor Point", "Annapolis, MD", "Active", "3 modules on"],
  ["Severn Landing", "Edgewater, MD", "Active", "1 module on"],
  ["Chesapeake Yard", "Easton, MD", "Setup", "0 modules on"],
];
document.querySelector("#site-list").innerHTML = sites.map(([name, city, status, modules]) => `<div class="site"><span class="anchor">⚓</span><div><b>${name}</b><small>${city}</small></div><em class="${status.toLowerCase()}">${status}</em><p>${modules}</p><i>›</i></div>`).join("");
