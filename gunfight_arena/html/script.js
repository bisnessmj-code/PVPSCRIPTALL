// ================================
// GUNFIGHT ARENA - SCRIPT.JS (VERSION PROFESSIONNELLE)
// Système d'onglets et interface plein écran
// ================================

// ================================
// VARIABLES GLOBALES
// ================================
let currentZoneData = [];
let currentActiveTab = 'zones';

// ================================
// EVENT LISTENER - NUI MESSAGES
// ================================
window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'show':
            if (data.zones && data.zones.length > 0) {
                currentZoneData = data.zones;
            }
            showMainUI();
            break;
        case 'showStats':
            showIngameStats(data.stats);
            break;
        case 'showPersonalStats':
            showPersonalStats(data.stats);
            break;
        case 'showGlobalLeaderboard':
            showGlobalLeaderboard(data.stats);
            break;
        case 'showLobbyScoreboard':
            // Non utilisé dans cette version
            break;
        case 'killFeed':
            addKillFeedMessage(data.message);
            break;
        case 'updateZonePlayers':
            updateZonePlayers(data.zones);
            break;
        case 'clearKillFeed':
            clearKillFeed();
            break;
    }
});

// ================================
// DOM READY - LISTENERS
// ================================
document.addEventListener('DOMContentLoaded', () => {
    // Bouton fermeture interface principale
    const closeMainBtn = document.getElementById('close-main-btn');
    if (closeMainBtn) {
        closeMainBtn.addEventListener('click', () => {
            closeMainUI();
        });
    }

    // Navigation tabs
    const tabButtons = document.querySelectorAll('.tab-btn');
    tabButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            const tabName = btn.getAttribute('data-tab');
            switchTab(tabName);
        });
    });

    // Bouton fermeture stats en jeu (G key)
    const ingameStatsClose = document.getElementById('ingame-stats-close');
    if (ingameStatsClose) {
        ingameStatsClose.addEventListener('click', () => {
            closeIngameStats();
        });
    }

    // ESC key handling
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            const mainUI = document.getElementById('main-ui');
            const ingameUI = document.getElementById('ingame-stats-ui');
            
            if (mainUI && mainUI.classList.contains('active')) {
                closeMainUI();
            } else if (ingameUI && ingameUI.classList.contains('active')) {
                closeIngameStats();
            }
        }
    });
});

// ================================
// SYSTÈME D'ONGLETS
// ================================
function switchTab(tabName) {
    // Mise à jour des boutons
    const tabButtons = document.querySelectorAll('.tab-btn');
    tabButtons.forEach(btn => {
        if (btn.getAttribute('data-tab') === tabName) {
            btn.classList.add('active');
        } else {
            btn.classList.remove('active');
        }
    });

    // Mise à jour du contenu
    const tabContents = document.querySelectorAll('.tab-content');
    tabContents.forEach(content => {
        if (content.id === `tab-${tabName}`) {
            content.classList.add('active');
        } else {
            content.classList.remove('active');
        }
    });

    currentActiveTab = tabName;

    // Charger les données si nécessaire
    if (tabName === 'personal') {
        postNUIMessage('getPersonalStats', {});
    } else if (tabName === 'global') {
        postNUIMessage('getGlobalLeaderboard', {});
    }
}

// ================================
// INTERFACE PRINCIPALE (LOBBY)
// ================================
function showMainUI() {
    const mainUI = document.getElementById('main-ui');
    if (!mainUI) return;

    // Afficher l'interface
    mainUI.classList.add('active');

    // Revenir à l'onglet zones
    switchTab('zones');

    // Remplir la liste des zones
    renderZones();
}

function closeMainUI() {
    const mainUI = document.getElementById('main-ui');
    if (mainUI) {
        mainUI.classList.remove('active');
    }
    
    postNUIMessage('closeUI', {});
}

function renderZones() {
    const zoneList = document.getElementById('zone-list');
    if (!zoneList) return;

    zoneList.innerHTML = "";

    currentZoneData.forEach((zone) => {
        const card = document.createElement('div');
        card.className = "zone-card";
        card.setAttribute("data-zone", zone.zone);

        const maxPlayers = zone.maxPlayers || 15;
        const currentPlayers = zone.players || 0;
        const isFull = currentPlayers >= maxPlayers;

        if (isFull) {
            card.setAttribute("data-full", "true");
        }

        card.innerHTML = `
            <img class="zone-image" src="${zone.image || 'images/default.png'}" alt="${zone.label || 'Zone ' + zone.zone}">
            <div class="zone-info">
                <div class="zone-text">${zone.label || 'Zone ' + zone.zone}</div>
                <div class="zone-players">
                    <span class="players-count">${currentPlayers}/${maxPlayers}</span>
                    <span class="zone-status ${isFull ? 'full' : ''}">${isFull ? 'COMPLET' : 'DISPONIBLE'}</span>
                </div>
            </div>
        `;

        if (!isFull) {
            card.addEventListener('click', () => {
                selectZone(zone.zone);
            });
        }

        zoneList.appendChild(card);
    });
}

function selectZone(zoneNumber) {
    postNUIMessage('zoneSelected', { zone: zoneNumber });
    closeMainUI();
}

// ================================
// UPDATE ZONE PLAYERS
// ================================
function updateZonePlayers(zones) {
    currentZoneData = zones;

    const mainUI = document.getElementById('main-ui');
    if (mainUI && mainUI.classList.contains('active') && currentActiveTab === 'zones') {
        zones.forEach((zone) => {
            const card = document.querySelector(`.zone-card[data-zone="${zone.zone}"]`);
            if (card) {
                const maxPlayers = zone.maxPlayers || 15;
                const currentPlayers = zone.players || 0;
                const isFull = currentPlayers >= maxPlayers;

                const playersCount = card.querySelector('.players-count');
                const status = card.querySelector('.zone-status');

                if (playersCount) {
                    playersCount.textContent = `${currentPlayers}/${maxPlayers}`;
                }

                if (status) {
                    status.textContent = isFull ? 'COMPLET' : 'DISPONIBLE';
                    status.classList.toggle('full', isFull);
                }

                if (isFull) {
                    card.setAttribute("data-full", "true");
                    card.onclick = null;
                } else {
                    card.removeAttribute("data-full");
                    card.onclick = () => selectZone(zone.zone);
                }
            }
        });
    }
}

// ================================
// STATISTIQUES PERSONNELLES (TAB)
// ================================
function showPersonalStats(stats) {
    // Mise à jour du nom du joueur
    const playerNameEl = document.getElementById('personal-player-name');
    if (playerNameEl) {
        playerNameEl.textContent = stats.player || "Votre profil de joueur";
    }

    // Mise à jour des statistiques
    const kdValue = parseFloat(stats.kd) || 0;

    const elements = {
        'personal-kills': stats.kills || 0,
        'personal-deaths': stats.deaths || 0,
        'personal-kd': kdValue.toFixed(2),
        'personal-streak': stats.best_streak || 0,
        'personal-headshots': stats.headshots || 0,
        'personal-playtime': formatPlaytime(stats.total_playtime || 0)
    };

    for (const [id, value] of Object.entries(elements)) {
        const el = document.getElementById(id);
        if (el) {
            el.textContent = value;
        }
    }

    // Session actuelle
    const sessionKills = document.getElementById('session-kills');
    if (sessionKills) sessionKills.textContent = stats.session_kills || 0;

    const sessionDeaths = document.getElementById('session-deaths');
    if (sessionDeaths) sessionDeaths.textContent = stats.session_deaths || 0;

    const currentStreak = document.getElementById('current-streak');
    if (currentStreak) currentStreak.textContent = stats.current_streak || 0;
}

// ================================
// CLASSEMENT MONDIAL (TAB)
// ================================
function showGlobalLeaderboard(stats) {
    const leaderboardList = document.getElementById('global-leaderboard-list');
    if (!leaderboardList) return;

    leaderboardList.innerHTML = "";

    stats.forEach((item) => {
        const row = document.createElement('div');
        row.className = "table-row";

        const kdValue = parseFloat(item.kd) || 0;

        row.innerHTML = `
            <div class="td rank-col">
                <div class="rank-badge">${item.rank}</div>
            </div>
            <div class="td player-col">${item.player || 'Inconnu'}</div>
            <div class="td stat-col">${item.kills || 0}</div>
            <div class="td stat-col">${item.deaths || 0}</div>
            <div class="td stat-col">${item.best_streak || 0}</div>
            <div class="td stat-col">${kdValue.toFixed(2)}</div>
        `;

        leaderboardList.appendChild(row);
    });
}

// ================================
// STATS EN JEU (TOUCHE G)
// ================================
function showIngameStats(stats) {
    const ingameUI = document.getElementById('ingame-stats-ui');
    const statsList = document.getElementById('ingame-stats-list');
    
    if (!ingameUI || !statsList) return;

    statsList.innerHTML = "";

    stats.forEach((item, index) => {
        const row = document.createElement('div');
        row.className = "table-row";

        const rank = index + 1;
        const kdValue = parseFloat(item.kd) || 0;

        row.innerHTML = `
            <div class="td rank-col">
                <div class="rank-badge">${rank}</div>
            </div>
            <div class="td player-col">${item.player || 'Inconnu'}</div>
            <div class="td stat-col">${item.kills || 0}</div>
            <div class="td stat-col">${item.deaths || 0}</div>
            <div class="td stat-col">${kdValue.toFixed(2)}</div>
        `;

        statsList.appendChild(row);
    });

    ingameUI.classList.add('active');
}

function closeIngameStats() {
    const ingameUI = document.getElementById('ingame-stats-ui');
    if (ingameUI) {
        ingameUI.classList.remove('active');
    }
    
    postNUIMessage('closeStatsUI', {});
}

// ================================
// KILL FEED
// ================================
function addKillFeedMessage(message) {
    const killfeedUI = document.getElementById('killfeed-ui');
    if (!killfeedUI) return;

    const messageDiv = document.createElement('div');
    messageDiv.className = 'killfeed-message';

    let iconHTML = '<div class="kill-icon">⚔️</div>';
    if (message.headshot) {
        iconHTML = '<div class="kill-icon">💀</div>';
    }

    let multiplierHTML = '';
    if (message.multiplier && message.multiplier > 1) {
        multiplierHTML = `<div class="kill-multiplier">x${message.multiplier}</div>`;
    }

    messageDiv.innerHTML = `
        ${iconHTML}
        <div class="kill-text">
            <span class="kill-killer">${message.killer}</span>
            <span> a éliminé </span>
            <span class="kill-victim">${message.victim}</span>
        </div>
        ${multiplierHTML}
    `;

    killfeedUI.appendChild(messageDiv);

    setTimeout(() => {
        if (messageDiv.parentNode) {
            messageDiv.remove();
        }
    }, 5000);
}

function clearKillFeed() {
    const killfeedUI = document.getElementById('killfeed-ui');
    if (killfeedUI) {
        killfeedUI.innerHTML = '';
    }
}

// ================================
// FONCTIONS UTILITAIRES
// ================================
function formatPlaytime(seconds) {
    if (seconds < 60) {
        return seconds + 's';
    } else if (seconds < 3600) {
        return Math.floor(seconds / 60) + 'min';
    } else {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return hours + 'h' + (minutes > 0 ? ' ' + minutes + 'min' : '');
    }
}

function postNUIMessage(action, data = {}) {
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    }).catch(err => {});
}

function GetParentResourceName() {
    if (window.location.hostname === 'localhost' || window.location.hostname === '' || window.location.hostname === '127.0.0.1') {
        return 'gunfight_arena';
    }
    
    const pathArray = window.location.pathname.split('/');
    const resourceIndex = pathArray.findIndex(part => part === 'html') - 1;
    if (resourceIndex >= 0 && pathArray[resourceIndex]) {
        return pathArray[resourceIndex];
    }
    
    return 'gunfight_arena';
}
