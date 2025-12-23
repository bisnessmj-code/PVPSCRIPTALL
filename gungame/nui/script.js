/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                        GUNGAME - NUI SCRIPT                                ║
 * ║              Classement TOP 5 et Kill Feed avec ID                         ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 */

// Cache DOM
const DOM = {
    container: document.getElementById('gungame-container'),
    leaderboardContent: document.getElementById('leaderboard-content'),
    weaponName: document.getElementById('weapon-name'),
    weaponCategory: document.getElementById('weapon-category'),
    weaponIndex: document.getElementById('weapon-index'),
    totalWeapons: document.getElementById('total-weapons'),
    progressBar: document.getElementById('progress-bar'),
    currentKills: document.getElementById('current-kills'),
    killsNeeded: document.getElementById('kills-needed'),
    killFeed: document.getElementById('kill-feed'),
    endScreen: document.getElementById('end-screen'),
    winnerName: document.getElementById('winner-name'),
    top3List: document.getElementById('top3-list')
};

let state = {
    isVisible: false
};

// Message handler
window.addEventListener('message', (event) => {
    const data = event.data;
    
    switch (data.action) {
        case 'show':
            showUI(data);
            break;
        case 'hide':
            hideUI();
            break;
        case 'updateProgress':
            updateProgress(data);
            break;
        case 'updateLeaderboard':
            updateLeaderboard(data.leaderboard);
            break;
        case 'killFeed':
            addKillFeed(data);
            break;
        case 'showEndScreen':
            showEndScreen(data);
            break;
    }
});

function showUI(data) {
    state.isVisible = true;
    DOM.container.classList.remove('hidden');
    DOM.endScreen.classList.add('hidden');
    
    if (data.totalWeapons) {
        DOM.totalWeapons.textContent = data.totalWeapons;
    }
    if (data.killsNeeded) {
        DOM.killsNeeded.textContent = data.killsNeeded;
    }
    
    updateProgress(data);
    
    fetch('https://gungame/uiReady', {
        method: 'POST',
        body: JSON.stringify({})
    });
}

function hideUI() {
    state.isVisible = false;
    DOM.container.classList.add('hidden');
    DOM.endScreen.classList.add('hidden');
    DOM.killFeed.innerHTML = '';
}

function updateProgress(data) {
    if (!state.isVisible) return;
    
    const { weaponIndex, weaponName, weaponCategory, kills, killsNeeded, totalWeapons } = data;
    
    if (weaponIndex !== undefined) {
        DOM.weaponIndex.textContent = weaponIndex;
    }
    if (totalWeapons !== undefined) {
        DOM.totalWeapons.textContent = totalWeapons;
    }
    if (weaponName !== undefined) {
        DOM.weaponName.textContent = weaponName;
    }
    if (weaponCategory !== undefined) {
        DOM.weaponCategory.textContent = weaponCategory.toUpperCase();
    }
    if (kills !== undefined) {
        DOM.currentKills.textContent = kills;
    }
    if (killsNeeded !== undefined) {
        DOM.killsNeeded.textContent = killsNeeded;
    }
    
    // Progress bar
    const currentKills = kills !== undefined ? kills : parseInt(DOM.currentKills.textContent);
    const neededKills = killsNeeded !== undefined ? killsNeeded : parseInt(DOM.killsNeeded.textContent);
    const progressPercent = (currentKills / neededKills) * 100;
    DOM.progressBar.style.width = progressPercent + '%';
}

// Classement TOP 5
function updateLeaderboard(leaderboard) {
    if (!state.isVisible || !leaderboard) return;
    
    DOM.leaderboardContent.innerHTML = '';
    
    // Limiter à 5 entrées maximum
    const topFive = leaderboard.slice(0, 5);
    
    topFive.forEach((player, index) => {
        const entry = document.createElement('div');
        entry.className = 'leaderboard-entry';
        
        if (index === 0) entry.classList.add('top1');
        else if (index === 1) entry.classList.add('top2');
        else if (index === 2) entry.classList.add('top3');
        
        // Rank
        const rank = document.createElement('span');
        rank.className = 'entry-rank';
        if (index === 0) rank.classList.add('gold');
        else if (index === 1) rank.classList.add('silver');
        else if (index === 2) rank.classList.add('bronze');
        rank.textContent = '#' + (index + 1);
        
        // ID
        const id = document.createElement('span');
        id.className = 'entry-id';
        id.textContent = '[' + player.id + ']';
        
        // Name
        const name = document.createElement('span');
        name.className = 'entry-name';
        name.textContent = player.name;
        
        // Weapon Index
        const weapon = document.createElement('span');
        weapon.className = 'entry-weapon';
        weapon.textContent = player.weaponIndex + '/40';
        
        // Total Kills
        const kills = document.createElement('span');
        kills.className = 'entry-kills';
        kills.textContent = player.totalKills + ' kills';
        
        entry.appendChild(rank);
        entry.appendChild(id);
        entry.appendChild(name);
        entry.appendChild(weapon);
        entry.appendChild(kills);
        
        DOM.leaderboardContent.appendChild(entry);
    });
}

// Kill Feed avec ID
function addKillFeed(data) {
    if (!state.isVisible) return;
    
    const { killer, killerID, victim, victimID, weapon } = data;
    
    const entry = document.createElement('div');
    entry.className = 'kill-entry';
    
    entry.innerHTML = `
        <span class="killer">${escapeHtml(killer)}</span>
        <span class="killer-id">[${killerID}]</span>
        <span class="arrow">→</span>
        <span class="victim">${escapeHtml(victim)}</span>
        <span class="victim-id">[${victimID}]</span>
        <span class="weapon">[${escapeHtml(weapon)}]</span>
    `;
    
    // Ajouter en haut
    DOM.killFeed.insertBefore(entry, DOM.killFeed.firstChild);
    
    // Limiter à 5 entrées
    while (DOM.killFeed.children.length > 5) {
        DOM.killFeed.removeChild(DOM.killFeed.lastChild);
    }
    
    // Supprimer après délai
    setTimeout(() => {
        entry.classList.add('fade-out');
        setTimeout(() => {
            if (entry.parentNode) {
                entry.parentNode.removeChild(entry);
            }
        }, 500);
    }, 4000);
}

// Écran de fin
function showEndScreen(data) {
    const { winner, top3 } = data;
    
    DOM.container.classList.add('hidden');
    DOM.endScreen.classList.remove('hidden');
    
    DOM.winnerName.textContent = winner || 'Personne';
    
    DOM.top3List.innerHTML = '';
    
    const medals = ['🥇', '🥈', '🥉'];
    
    if (top3 && top3.length > 0) {
        top3.forEach((player, index) => {
            const entry = document.createElement('div');
            entry.className = 'top3-entry';
            
            entry.innerHTML = `
                <span class="medal">${medals[index] || ''}</span>
                <span class="player-id">[${player.id}]</span>
                <span class="name">${escapeHtml(player.name)}</span>
                <span class="stats">Arme ${player.weaponIndex}/40 • ${player.totalKills} kills</span>
            `;
            
            DOM.top3List.appendChild(entry);
        });
    }
}

function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

console.log('[GunGame] NUI initialisée');
