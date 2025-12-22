console.log('[PVP UI] Script chargé - Version 4.2.0 - Killfeed System Intégré');

// ========================================
// VARIABLES GLOBALES
// ========================================
let currentGroup = null;
let selectedMode = null;
let selectedPlayers = 1;
let isReady = false;
let currentSlotToInvite = null;
let isSearching = false;
let searchStartTime = 0;
let pendingInvitations = [];
let isInMatch = false;
let myAvatar = 'https://cdn.discordapp.com/embed/avatars/0.png';

// Variables pour les stats par mode
let currentStatsMode = '1v1';
let currentLeaderboardMode = '1v1';
let allModeStats = null;

// ========================================
// VARIABLES GLOBALES KILLFEED
// ========================================
let killfeedItems = [];
const MAX_KILLFEED_ITEMS = 5;
const KILLFEED_DURATION = 5000; // 5 secondes

// ========================================
// AVATAR PAR DÉFAUT
// ========================================
const DEFAULT_AVATAR = 'https://cdn.discordapp.com/embed/avatars/0.png';

// ========================================
// RANGS PAR ELO
// ========================================
const RANKS = [
    { id: 1, name: "Bronze", min: 0, max: 999, color: "#cd7f32" },
    { id: 2, name: "Argent", min: 1000, max: 1499, color: "#c0c0c0" },
    { id: 3, name: "Or", min: 1500, max: 1999, color: "#ffd700" },
    { id: 4, name: "Platine", min: 2000, max: 2499, color: "#4da6ff" },
    { id: 5, name: "Émeraude", min: 2500, max: 2999, color: "#50c878" },
    { id: 6, name: "Diamant", min: 3000, max: 9999, color: "#b9f2ff" }
];

function getRankByElo(elo) {
    for (const rank of RANKS) {
        if (elo >= rank.min && elo <= rank.max) {
            return rank;
        }
    }
    return RANKS[5];
}

function handleAvatarError(imgElement) {
    imgElement.onerror = function() {
        this.src = DEFAULT_AVATAR;
        console.log('[PVP UI] Erreur chargement avatar, fallback sur défaut');
    };
}

// ========================================
// GESTION DES MESSAGES DEPUIS LUA
// ========================================
window.addEventListener('message', function(event) {
    console.log('[PVP UI] Message reçu:', event.data);
    const data = event.data;
    
    if (data.action === 'openUI') {
        console.log('[PVP UI] Ouverture de l\'interface');
        openUI(data.isSearching || false);
    } else if (data.action === 'closeUI') {
        console.log('[PVP UI] Fermeture de l\'interface (depuis Lua)');
        closeUIVisual();
    } else if (data.action === 'updateGroup') {
        console.log('[PVP UI] Mise à jour du groupe:', data.group);
        updateGroupDisplay(data.group);
    } else if (data.action === 'showInvite') {
        console.log('[PVP UI] Invitation reçue de:', data.inviterName);
        addInvitationToQueue(data.inviterName, data.inviterId, data.inviterAvatar);
    } else if (data.action === 'searchStarted') {
        console.log('[PVP UI] Recherche démarrée:', data.mode);
        showSearchStatus(data.mode);
    } else if (data.action === 'updateSearchTimer') {
        updateSearchTimer(data.elapsed);
    } else if (data.action === 'matchFound') {
        console.log('[PVP UI] Match trouvé!');
        hideSearchStatus();
        isInMatch = true;
    } else if (data.action === 'searchCancelled') {
        console.log('[PVP UI] Recherche annulée');
        hideSearchStatus();
        
        const readyButton = document.getElementById('ready-btn');
        if (readyButton) {
            readyButton.disabled = false;
            readyButton.style.opacity = '1';
            readyButton.style.cursor = 'pointer';
            readyButton.title = '';
            console.log('[PVP UI] ✅ Bouton Prêt réactivé après annulation');
        }
    } else if (data.action === 'showRoundStart') {
        showRoundStart(data.round);
    } else if (data.action === 'showCountdown') {
        showCountdown(data.number);
    } else if (data.action === 'showGo') {
        showGo();
    } else if (data.action === 'showRoundEnd') {
        showRoundEnd(data.winner, data.score, data.playerTeam, data.isVictory);
    } else if (data.action === 'showMatchEnd') {
        showMatchEnd(data.victory, data.score, data.playerTeam);
        isInMatch = false;
    } else if (data.action === 'updateScore') {
        updateScoreHUD(data.score, data.round);
    } else if (data.action === 'showScoreHUD') {
        showScoreHUD(data.score, data.round);
    } else if (data.action === 'hideScoreHUD') {
        hideScoreHUD();
    } else if (data.action === 'closeInvitationsPanel') {
        console.log('[PVP UI] Fermeture forcée du panneau d\'invitations');
        hideInvitationsPanel();
    } else if (data.action === 'showKillfeed') {
        addKillfeed(data.killerName, data.victimName, data.weapon, data.isHeadshot);
    }
});

// ========================================
// FONCTIONS D'INTERFACE
// ========================================

function openUI(isSearching = false) {
    console.log('[PVP UI] ✨ openUI() appelée - VERSION 4.2.0');
    document.getElementById('container').classList.remove('hidden');
    
    if (isSearching) {
        console.log('[PVP UI] 🔍 Réouverture pendant recherche - Affichage écran matchmaking');
        showSearchScreen();
    }
    
    loadStatsWithCallback(function() {
        console.log('[PVP UI] ✅ Stats chargées, myAvatar mis à jour:', myAvatar);
        loadGroupInfo();
    });
    
    console.log('[PVP UI] Interface ouverte');
}

function showSearchScreen() {
    console.log('[PVP UI] Affichage de l\'écran de recherche');
    
    const mainMenu = document.querySelector('.lobby-content');
    if (mainMenu) {
        mainMenu.style.display = 'none';
    }
    
    const searchStatus = document.getElementById('search-status');
    if (searchStatus) {
        searchStatus.classList.remove('hidden');
        console.log('[PVP UI] 🔍 Écran de recherche affiché');
    }
}

function closeUIVisual() {
    document.getElementById('container').classList.add('hidden');
}

function closeUI() {
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).catch(err => console.error('[PVP UI] Erreur closeUI:', err));
}

// ========================================
// SYSTÈME D'INVITATIONS
// ========================================

function addInvitationToQueue(inviterName, inviterId, inviterAvatar) {
    const exists = pendingInvitations.find(inv => inv.inviterId === inviterId);
    if (exists) return;
    
    pendingInvitations.push({
        inviterName: inviterName,
        inviterId: inviterId,
        inviterAvatar: inviterAvatar || DEFAULT_AVATAR,
        timestamp: Date.now()
    });
    
    updateNotificationBadge();
    
    setTimeout(() => {
        removeInvitation(inviterId);
    }, 30000);
}

function updateNotificationBadge() {
    const badge = document.getElementById('notification-count');
    const count = pendingInvitations.length;
    
    if (count > 0) {
        badge.textContent = count;
        badge.classList.remove('hidden');
    } else {
        badge.classList.add('hidden');
    }
}

function removeInvitation(inviterId) {
    pendingInvitations = pendingInvitations.filter(inv => inv.inviterId !== inviterId);
    updateNotificationBadge();
    
    if (!document.getElementById('invitations-panel').classList.contains('hidden')) {
        renderInvitationsPanel();
    }
}

function showInvitationsPanel() {
    document.getElementById('invitations-panel').classList.remove('hidden');
    renderInvitationsPanel();
}

function hideInvitationsPanel() {
    document.getElementById('invitations-panel').classList.add('hidden');
}

function renderInvitationsPanel() {
    const list = document.getElementById('invitations-list');
    const noInvitations = document.getElementById('no-invitations');
    
    list.innerHTML = '';
    
    if (pendingInvitations.length === 0) {
        noInvitations.classList.remove('hidden');
        return;
    }
    
    noInvitations.classList.add('hidden');
    
    pendingInvitations.forEach(invitation => {
        const item = document.createElement('div');
        item.className = 'invitation-item';
        item.innerHTML = `
            <div class="invitation-avatar">
                <img src="${invitation.inviterAvatar}" alt="avatar" onerror="this.src='${DEFAULT_AVATAR}'">
            </div>
            <div class="invitation-info">
                <div class="invitation-from">${invitation.inviterName}</div>
                <div class="invitation-message">Vous invite à rejoindre son groupe</div>
            </div>
            <div class="invitation-actions">
                <button class="btn-accept-inv" data-inviter-id="${invitation.inviterId}">✓ Accepter</button>
                <button class="btn-decline-inv" data-inviter-id="${invitation.inviterId}">✕ Refuser</button>
            </div>
        `;
        list.appendChild(item);
    });
    
    document.querySelectorAll('.btn-accept-inv').forEach(btn => {
        btn.addEventListener('click', function() {
            acceptInvitation(parseInt(this.getAttribute('data-inviter-id')));
        });
    });
    
    document.querySelectorAll('.btn-decline-inv').forEach(btn => {
        btn.addEventListener('click', function() {
            declineInvitation(parseInt(this.getAttribute('data-inviter-id')));
        });
    });
}

function acceptInvitation(inviterId) {
    fetch(`https://${GetParentResourceName()}/acceptInvite`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ inviterId: inviterId })
    }).catch(err => console.error('[PVP UI] Erreur acceptation:', err));
    
    removeInvitation(inviterId);
    renderInvitationsPanel();
}

function declineInvitation(inviterId) {
    fetch(`https://${GetParentResourceName()}/declineInvite`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).catch(err => {});
    
    removeInvitation(inviterId);
    renderInvitationsPanel();
}

// ========================================
// EVENT LISTENERS
// ========================================

document.getElementById('notification-bell').addEventListener('click', function() {
    const panel = document.getElementById('invitations-panel');
    if (panel.classList.contains('hidden')) {
        showInvitationsPanel();
    } else {
        hideInvitationsPanel();
    }
});

document.getElementById('close-invitations').addEventListener('click', hideInvitationsPanel);

document.getElementById('close-button').addEventListener('click', closeUI);

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        const container = document.getElementById('container');
        const invitationsPanel = document.getElementById('invitations-panel');
        
        if (!invitationsPanel.classList.contains('hidden')) {
            hideInvitationsPanel();
            return;
        }
        
        if (!container.classList.contains('hidden')) {
            closeUI();
        }
    }
});

// ========================================
// GESTION DES ONGLETS
// ========================================

document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', function() {
        const tabName = this.getAttribute('data-tab');
        
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        
        this.classList.add('active');
        document.getElementById(tabName + '-tab').classList.add('active');
        
        if (tabName === 'stats') {
            loadAllModeStats();
        } else if (tabName === 'leaderboard') {
            loadLeaderboardByMode(currentLeaderboardMode);
        } else if (tabName === 'lobby') {
            loadGroupInfo();
        }
    });
});

// ========================================
// SÉLECTION DU MODE
// ========================================

document.querySelectorAll('.mode-card').forEach(card => {
    card.addEventListener('click', function() {
        const mode = this.getAttribute('data-mode');
        const players = parseInt(this.getAttribute('data-players'));
        
        document.querySelectorAll('.mode-card').forEach(c => c.classList.remove('selected'));
        this.classList.add('selected');
        
        selectedMode = mode;
        selectedPlayers = players;
        
        document.getElementById('mode-display').textContent = mode.toUpperCase();
        
        updatePlayerSlots();
        updateSearchButton();
    });
});

// ========================================
// GESTION DES SLOTS JOUEURS
// ========================================

function updatePlayerSlots() {
    const slots = document.querySelectorAll('.player-slot');
    
    slots.forEach((slot, index) => {
        if (index === 0) return;
        
        if (index < selectedPlayers) {
            slot.classList.remove('locked');
            
            if (slot.classList.contains('empty-slot')) {
                const slotText = slot.querySelector('.slot-text');
                if (slotText) {
                    slotText.textContent = 'Cliquez pour inviter';
                }
                
                slot.onclick = function() {
                    openInvitePopup(index);
                };
            }
        } else {
            slot.classList.add('locked');
            
            if (slot.classList.contains('empty-slot')) {
                const slotText = slot.querySelector('.slot-text');
                if (slotText) {
                    slotText.textContent = 'Non disponible';
                }
                slot.onclick = null;
            }
        }
    });
}

function openInvitePopup(slotIndex) {
    currentSlotToInvite = slotIndex;
    document.getElementById('invite-player-popup').classList.remove('hidden');
}

document.getElementById('confirm-invite-btn').addEventListener('click', function() {
    const input = document.getElementById('invite-input');
    const targetId = parseInt(input.value);
    
    if (!targetId || targetId < 1) return;
    
    fetch(`https://${GetParentResourceName()}/invitePlayer`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ targetId: targetId })
    }).catch(err => console.error('[PVP UI] Erreur invitation:', err));
    
    input.value = '';
    document.getElementById('invite-player-popup').classList.add('hidden');
});

document.getElementById('cancel-invite-btn').addEventListener('click', function() {
    document.getElementById('invite-input').value = '';
    document.getElementById('invite-player-popup').classList.add('hidden');
});

// ========================================
// BOUTONS READY ET GROUPE
// ========================================

document.getElementById('ready-btn').addEventListener('click', function() {
    const searchStatus = document.getElementById('search-status');
    const isSearching = searchStatus && !searchStatus.classList.contains('hidden');
    
    if (isSearching) {
        console.log('[PVP UI] ⚠️ Impossible de changer l\'état Prêt pendant la recherche');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/toggleReady`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).catch(err => console.error('[PVP UI] Erreur toggle ready:', err));
});

document.getElementById('leave-group-btn').addEventListener('click', function() {
    fetch(`https://${GetParentResourceName()}/leaveGroup`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).catch(err => console.error('[PVP UI] Erreur leaveGroup:', err));
});

// ========================================
// CHARGEMENT DES INFOS DE GROUPE
// ========================================

function loadGroupInfo() {
    fetch(`https://${GetParentResourceName()}/getGroupInfo`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).then(resp => resp.json()).then(groupInfo => {
        updateGroupDisplay(groupInfo);
    }).catch(err => {
        updateGroupDisplay(null);
    });
}

function updateGroupDisplay(group) {
    currentGroup = group;
    
    const slots = document.querySelectorAll('.player-slot');
    const readyBtn = document.getElementById('ready-btn');
    const leaveGroupBtn = document.getElementById('leave-group-btn');
    
    for (let i = 0; i < slots.length; i++) {
        const slot = slots[i];
        slot.className = 'player-slot empty-slot';
        
        if (selectedMode && i < selectedPlayers) {
            slot.classList.remove('locked');
            slot.innerHTML = `
                <div class="empty-content">
                    <div class="add-icon">+</div>
                    <div class="slot-text">Cliquez pour inviter</div>
                </div>
            `;
            slot.onclick = function() { openInvitePopup(i); };
        } else if (i > 0) {
            slot.classList.add('locked');
            slot.innerHTML = `
                <div class="empty-content">
                    <div class="add-icon">+</div>
                    <div class="slot-text">${selectedMode ? 'Non disponible' : 'Sélectionnez un mode'}</div>
                </div>
            `;
            slot.onclick = null;
        }
    }
    
    if (!group || !group.members || group.members.length === 0) {
        const firstSlot = slots[0];
        firstSlot.className = 'player-slot host-slot';
        firstSlot.innerHTML = `
            <div class="slot-content">
                <div class="player-avatar">
                    <img src="${myAvatar}" alt="avatar" onerror="this.src='${DEFAULT_AVATAR}'">
                </div>
                <div class="player-info">
                    <div class="player-name">Vous</div>
                    <div class="player-status">
                        <span class="host-badge">👑 Hôte</span>
                    </div>
                </div>
                <div class="player-ready">
                    <div class="ready-indicator"></div>
                </div>
            </div>
        `;
        
        isReady = false;
        readyBtn.classList.remove('ready');
        document.getElementById('ready-text').textContent = 'SE METTRE PRÊT';
        leaveGroupBtn.classList.add('hidden');
        updateSearchButton();
        return;
    }
    
    let currentPlayerIndex = -1;
    let isLeader = false;
    
    for (let i = 0; i < group.members.length; i++) {
        if (group.members[i].isYou) {
            currentPlayerIndex = i;
            isLeader = group.members[i].isLeader;
            isReady = group.members[i].isReady;
            myAvatar = group.members[i].avatar || DEFAULT_AVATAR;
            break;
        }
    }
    
    group.members.forEach((member, index) => {
        if (index >= slots.length) return;
        
        const slot = slots[index];
        slot.className = 'player-slot';
        
        if (member.isLeader) slot.classList.add('host-slot');
        if (member.isReady) slot.classList.add('ready');
        
        const canKick = isLeader && !member.isLeader && !member.isYou;
        const avatarUrl = member.avatar || DEFAULT_AVATAR;
        
        slot.innerHTML = `
            <div class="slot-content">
                <div class="player-avatar">
                    <img src="${avatarUrl}" alt="avatar" onerror="this.src='${DEFAULT_AVATAR}'">
                </div>
                <div class="player-info">
                    <div class="player-name">${member.name}${member.isYou ? ' (Vous)' : ''}</div>
                    <div class="player-status">
                        ${member.isLeader ? '<span class="host-badge">👑 Hôte</span>' : '<span class="player-id">ID: ' + member.id + '</span>'}
                    </div>
                </div>
                <div class="player-ready">
                    <div class="ready-indicator ${member.isReady ? 'ready' : ''}"></div>
                    ${canKick ? '<button class="btn-kick" onclick="kickPlayer(' + member.id + ')">KICK</button>' : ''}
                </div>
            </div>
        `;
        slot.onclick = null;
    });
    
    if (isReady) {
        readyBtn.classList.add('ready');
        document.getElementById('ready-text').textContent = '✓ PRÊT';
    } else {
        readyBtn.classList.remove('ready');
        document.getElementById('ready-text').textContent = 'SE METTRE PRÊT';
    }
    
    if (group.members.length > 1) {
        leaveGroupBtn.classList.remove('hidden');
    } else {
        leaveGroupBtn.classList.add('hidden');
    }
    
    const searchStatus = document.getElementById('search-status');
    const isSearchingNow = searchStatus && !searchStatus.classList.contains('hidden');
    
    if (isSearchingNow) {
        readyBtn.disabled = true;
        readyBtn.style.opacity = '0.5';
        readyBtn.style.cursor = 'not-allowed';
        readyBtn.title = 'Annulez d\'abord la recherche';
        console.log('[PVP UI] 🔒 Bouton Prêt désactivé (recherche active)');
    } else {
        readyBtn.disabled = false;
        readyBtn.style.opacity = '1';
        readyBtn.style.cursor = 'pointer';
        readyBtn.title = '';
    }
    
    updateSearchButton();
}

function kickPlayer(targetId) {
    fetch(`https://${GetParentResourceName()}/kickPlayer`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ targetId: targetId })
    }).catch(err => console.error('[PVP UI] Erreur kick:', err));
}

function updateSearchButton() {
    const searchBtn = document.getElementById('search-btn');
    const searchText = document.getElementById('search-text');
    
    if (!selectedMode) {
        searchBtn.disabled = true;
        searchText.textContent = 'SÉLECTIONNEZ UN MODE';
        return;
    }
    
    if (!currentGroup || !currentGroup.members) {
        searchBtn.disabled = true;
        searchText.textContent = `IL FAUT ${selectedPlayers} JOUEUR(S)`;
        return;
    }
    
    let isLeader = false;
    for (let i = 0; i < currentGroup.members.length; i++) {
        if (currentGroup.members[i].isYou && currentGroup.members[i].isLeader) {
            isLeader = true;
            break;
        }
    }
    
    if (!isLeader) {
        searchBtn.disabled = true;
        searchText.textContent = 'SEUL L\'HÔTE PEUT LANCER';
        return;
    }
    
    const allReady = currentGroup.members.every(m => m.isReady);
    const correctSize = currentGroup.members.length === selectedPlayers;
    
    if (!correctSize) {
        searchBtn.disabled = true;
        searchText.textContent = `IL FAUT ${selectedPlayers} JOUEUR(S)`;
    } else if (!allReady) {
        searchBtn.disabled = true;
        searchText.textContent = 'TOUS LES JOUEURS DOIVENT ÊTRE PRÊTS';
    } else {
        searchBtn.disabled = false;
        searchText.textContent = 'RECHERCHER UNE PARTIE';
    }
}

// ========================================
// RECHERCHE DE PARTIE
// ========================================

document.getElementById('search-btn').addEventListener('click', function() {
    if (this.disabled) return;
    
    fetch(`https://${GetParentResourceName()}/joinQueue`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ mode: selectedMode })
    }).catch(err => console.error('[PVP UI] Erreur joinQueue:', err));
});

function showSearchStatus(mode) {
    isSearching = true;
    searchStartTime = Date.now();
    
    document.getElementById('search-btn').style.display = 'none';
    document.getElementById('search-status').classList.remove('hidden');
    document.getElementById('search-mode-display').textContent = mode.toUpperCase();
}

function hideSearchStatus() {
    isSearching = false;
    
    document.getElementById('search-status').classList.add('hidden');
    document.getElementById('search-btn').style.display = 'flex';
}

function updateSearchTimer(elapsed) {
    const minutes = Math.floor(elapsed / 60);
    const seconds = elapsed % 60;
    document.getElementById('search-timer').textContent = 
        `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
}

document.getElementById('cancel-search-btn').addEventListener('click', function() {
    fetch(`https://${GetParentResourceName()}/cancelSearch`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).catch(err => console.error('[PVP UI] Erreur annulation:', err));
});

// ========================================
// STATS PAR MODE
// ========================================

document.querySelectorAll('.stats-mode-btn').forEach(btn => {
    btn.addEventListener('click', function() {
        const mode = this.getAttribute('data-stats-mode');
        
        document.querySelectorAll('.stats-mode-btn').forEach(b => b.classList.remove('active'));
        this.classList.add('active');
        
        currentStatsMode = mode;
        
        document.getElementById('current-stats-mode-title').textContent = `Statistiques ${mode.toUpperCase()}`;
        
        if (allModeStats && allModeStats.modes && allModeStats.modes[mode]) {
            displayModeStats(allModeStats.modes[mode]);
        } else {
            loadStatsByMode(mode);
        }
    });
});

function loadAllModeStats() {
    console.log('[PVP UI] 📊 Chargement de toutes les stats par mode...');
    
    fetch(`https://${GetParentResourceName()}/getPlayerAllModeStats`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).then(resp => resp.json()).then(data => {
        console.log('[PVP UI] ✅ Stats par mode reçues:', data);
        allModeStats = data;
        
        if (data && data.avatar) {
            myAvatar = data.avatar;
            document.getElementById('stats-avatar').src = data.avatar;
        }
        
        if (data && data.name) {
            document.getElementById('stats-player-name').textContent = data.name;
        }
        
        if (data && data.modes && data.modes[currentStatsMode]) {
            displayModeStats(data.modes[currentStatsMode]);
        }
    }).catch(err => {
        console.error('[PVP UI] ❌ Erreur chargement stats par mode:', err);
    });
}

function loadStatsByMode(mode) {
    console.log('[PVP UI] 📊 Chargement stats pour le mode:', mode);
    
    fetch(`https://${GetParentResourceName()}/getPlayerStatsByMode`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ mode: mode })
    }).then(resp => resp.json()).then(stats => {
        console.log('[PVP UI] ✅ Stats reçues pour', mode, ':', stats);
        displayModeStats(stats);
    }).catch(err => {
        console.error('[PVP UI] ❌ Erreur chargement stats:', err);
    });
}

function displayModeStats(stats) {
    if (!stats) {
        console.error('[PVP UI] Stats null ou undefined');
        return;
    }
    
    const elo = stats.elo || 0;
    const kills = stats.kills || 0;
    const deaths = stats.deaths || 0;
    const wins = stats.wins || 0;
    const losses = stats.losses || 0;
    const matches = stats.matches_played || 0;
    const winStreak = stats.win_streak || 0;
    const bestWinStreak = stats.best_win_streak || 0;
    const bestElo = stats.best_elo || elo;
    
    const ratio = deaths > 0 ? (kills / deaths).toFixed(2) : kills.toFixed(2);
    const winrate = matches > 0 ? Math.round((wins / matches) * 100) : 0;
    const rank = getRankByElo(elo);
    
    document.getElementById('stat-elo').textContent = elo;
    document.getElementById('stat-kills').textContent = kills;
    document.getElementById('stat-deaths').textContent = deaths;
    document.getElementById('stat-ratio').textContent = ratio;
    document.getElementById('stat-matches').textContent = matches;
    document.getElementById('stat-wins').textContent = wins;
    document.getElementById('stat-losses').textContent = losses;
    document.getElementById('stat-winrate').textContent = winrate + '%';
    document.getElementById('stat-streak').textContent = winStreak;
    document.getElementById('stat-best-streak').textContent = bestWinStreak;
    document.getElementById('stat-best-elo').textContent = bestElo;
    
    const rankEl = document.getElementById('stat-rank');
    if (rankEl) {
        rankEl.textContent = rank.name;
        rankEl.style.color = rank.color;
    }
    
    console.log('[PVP UI] ✅ Stats affichées avec succès');
}

// ========================================
// LEADERBOARD PAR MODE
// ========================================

document.querySelectorAll('.lb-mode-btn').forEach(btn => {
    btn.addEventListener('click', function() {
        const mode = this.getAttribute('data-lb-mode');
        
        document.querySelectorAll('.lb-mode-btn').forEach(b => b.classList.remove('active'));
        this.classList.add('active');
        
        currentLeaderboardMode = mode;
        loadLeaderboardByMode(mode);
    });
});

function loadLeaderboardByMode(mode) {
    console.log('[PVP UI] 🏆 Chargement leaderboard pour le mode:', mode);
    
    fetch(`https://${GetParentResourceName()}/getLeaderboardByMode`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ mode: mode })
    }).then(resp => resp.json()).then(leaderboard => {
        console.log('[PVP UI] ✅ Leaderboard reçu:', leaderboard.length, 'entrées');
        displayLeaderboard(leaderboard);
    }).catch(err => {
        console.error('[PVP UI] ❌ Erreur chargement leaderboard:', err);
        displayLeaderboard([]);
    });
}

function displayLeaderboard(leaderboard) {
    const tbody = document.getElementById('leaderboard-body');
    tbody.innerHTML = '';
    
    if (leaderboard && leaderboard.length > 0) {
        leaderboard.forEach((player, index) => {
            const row = document.createElement('tr');
            const kills = player.kills || 0;
            const deaths = player.deaths || 0;
            const wins = player.wins || 0;
            const matches = player.matches_played || 0;
            const ratio = deaths > 0 ? (kills / deaths).toFixed(2) : kills.toFixed(2);
            const winrate = matches > 0 ? Math.round((wins / matches) * 100) : 0;
            const avatarUrl = player.avatar || DEFAULT_AVATAR;
            const rank = getRankByElo(player.elo);
            
            let rankBadge = '';
            if (index === 0) rankBadge = '<span class="rank-badge gold">🥇</span>';
            else if (index === 1) rankBadge = '<span class="rank-badge silver">🥈</span>';
            else if (index === 2) rankBadge = '<span class="rank-badge bronze">🥉</span>';
            
            row.innerHTML = `
                <td class="rank">${rankBadge || '#' + (index + 1)}</td>
                <td class="player-cell">
                    <img class="leaderboard-avatar" src="${avatarUrl}" alt="avatar" onerror="this.src='${DEFAULT_AVATAR}'">
                    <div class="player-lb-info">
                        <span class="player-name-lb">${player.name}</span>
                        <span class="player-rank-lb" style="color: ${rank.color}">${rank.name}</span>
                    </div>
                </td>
                <td class="elo-cell">${player.elo}</td>
                <td>${ratio}</td>
                <td>${wins}</td>
                <td>${winrate}%</td>
            `;
            
            tbody.appendChild(row);
        });
    } else {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align: center; color: #5B5A56;">Aucune donnée disponible</td></tr>';
    }
}

// ========================================
// STATS AVEC CALLBACK
// ========================================

function loadStatsWithCallback(callback) {
    fetch(`https://${GetParentResourceName()}/getStats`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).then(resp => resp.json()).then(stats => {
        if (stats && stats.avatar) {
            myAvatar = stats.avatar;
            
            const statsAvatarEl = document.getElementById('stats-avatar');
            if (statsAvatarEl) {
                statsAvatarEl.src = myAvatar;
            }
        }
        
        if (callback) callback();
    }).catch(err => {
        console.error('[PVP UI] ❌ Erreur chargement stats:', err);
        if (callback) callback();
    });
}

// ========================================
// ANIMATIONS DE COMBAT
// ========================================

function showRoundStart(roundNumber) {
    const overlay = document.getElementById('combat-overlay');
    const message = document.getElementById('combat-message');
    const subtitle = document.getElementById('combat-subtitle');
    
    overlay.classList.remove('hidden');
    message.textContent = `ROUND ${roundNumber}`;
    subtitle.textContent = 'Préparez-vous';
    
    setTimeout(() => overlay.classList.add('hidden'), 1000);
}

function showCountdown(number) {
    const overlay = document.getElementById('combat-overlay');
    const message = document.getElementById('combat-message');
    const subtitle = document.getElementById('combat-subtitle');
    
    overlay.classList.remove('hidden');
    message.textContent = number;
    subtitle.textContent = '';
    
    setTimeout(() => overlay.classList.add('hidden'), 1000);
}

function showGo() {
    const overlay = document.getElementById('combat-overlay');
    const message = document.getElementById('combat-message');
    const subtitle = document.getElementById('combat-subtitle');
    
    overlay.classList.remove('hidden');
    message.textContent = 'GO!';
    subtitle.textContent = 'Combattez !';
    
    setTimeout(() => overlay.classList.add('hidden'), 1000);
}

function showRoundEnd(winningTeam, score, playerTeam, isVictory) {
    const overlay = document.getElementById('round-end-overlay');
    const title = document.getElementById('round-end-title');
    const subtitle = document.getElementById('round-end-subtitle');
    
    if (isVictory) {
        title.textContent = 'VICTOIRE';
        title.className = 'round-end-title victory';
        subtitle.textContent = 'Manche remportée !';
    } else {
        title.textContent = 'DÉFAITE';
        title.className = 'round-end-title defeat';
        subtitle.textContent = 'Manche perdue';
    }
    
    document.getElementById('round-score-team1').textContent = score.team1;
    document.getElementById('round-score-team2').textContent = score.team2;
    
    overlay.classList.remove('hidden');
    setTimeout(() => overlay.classList.add('hidden'), 1500);
}

function showMatchEnd(victory, score, playerTeam) {
    clearAllKillfeeds(); // 🔧 NOUVEAU: Nettoyer killfeed en fin de match
    
    const overlay = document.getElementById('match-end-overlay');
    const result = document.getElementById('match-end-result');
    const message = document.getElementById('match-end-message');
    
    if (victory) {
        result.textContent = 'VICTOIRE';
        result.className = 'match-end-result victory';
        message.textContent = 'Félicitations ! Vous avez gagné le match ! 🎉';
    } else {
        result.textContent = 'DÉFAITE';
        result.className = 'match-end-result defeat';
        message.textContent = 'Dommage... Vous avez perdu le match. Réessayez !';
    }
    
    document.getElementById('final-score-team1').textContent = score.team1;
    document.getElementById('final-score-team2').textContent = score.team2;
    
    overlay.classList.remove('hidden');
    setTimeout(() => overlay.classList.add('hidden'), 1500);
}

// ========================================
// HUD DE SCORE IN-GAME
// ========================================

function showScoreHUD(score, round) {
    updateScoreHUD(score, round);
    document.getElementById('score-hud').classList.remove('hidden');
}

function hideScoreHUD() {
    document.getElementById('score-hud').classList.add('hidden');
}

function updateScoreHUD(score, round) {
    document.getElementById('team1-score').textContent = score.team1;
    document.getElementById('team2-score').textContent = score.team2;
    document.getElementById('current-round-display').textContent = `Round ${round}`;
}

// ========================================
// KILLFEED SYSTEM
// ========================================

function addKillfeed(killerName, victimName, weapon, isHeadshot) {
    console.log('[KILLFEED]', killerName, 'eliminated', victimName, 'with', weapon, isHeadshot ? '(HEADSHOT)' : '');
    
    const container = document.getElementById('killfeed-container');
    if (!container) {
        console.error('[KILLFEED] Container introuvable');
        return;
    }
    
    const item = document.createElement('div');
    item.className = 'killfeed-item';
    
    if (isHeadshot) {
        item.classList.add('headshot');
    }
    
    if (!killerName) {
        item.classList.add('suicide');
        item.innerHTML = `
            <span class="killfeed-icon">💀</span>
            <span class="killfeed-victim">${sanitizeName(victimName)}</span>
            <span class="killfeed-weapon">${weapon}</span>
        `;
    } else {
        item.innerHTML = `
            <span class="killfeed-killer">${sanitizeName(killerName)}</span>
            <span class="killfeed-icon">${isHeadshot ? '🎯' : '☠️'}</span>
            <span class="killfeed-weapon">${weapon}</span>
            ${isHeadshot ? '<span class="killfeed-headshot-badge">HEADSHOT</span>' : ''}
            <span class="killfeed-victim">${sanitizeName(victimName)}</span>
        `;
    }
    
    container.appendChild(item);
    
    killfeedItems.push({
        element: item,
        timestamp: Date.now()
    });
    
    if (killfeedItems.length > MAX_KILLFEED_ITEMS) {
        removeOldestKillfeed();
    }
    
    setTimeout(() => {
        removeKillfeedItem(item);
    }, KILLFEED_DURATION);
}

function removeOldestKillfeed() {
    if (killfeedItems.length === 0) return;
    const oldest = killfeedItems.shift();
    removeKillfeedItem(oldest.element);
}

function removeKillfeedItem(element) {
    if (!element || !element.parentNode) return;
    element.classList.add('fade-out');
    setTimeout(() => {
        if (element.parentNode) {
            element.remove();
        }
        killfeedItems = killfeedItems.filter(item => item.element !== element);
    }, 400);
}

function sanitizeName(name) {
    if (!name || name === '') return 'Unknown';
    const maxLength = 15;
    if (name.length > maxLength) {
        return name.substring(0, maxLength - 3) + '...';
    }
    return name;
}

function clearAllKillfeeds() {
    killfeedItems.forEach(item => {
        if (item.element && item.element.parentNode) {
            item.element.remove();
        }
    });
    killfeedItems = [];
}

// ========================================
// HELPER - NOM DE LA RESSOURCE
// ========================================

function GetParentResourceName() {
    if (window.location.protocol === 'file:') {
        return 'pvp_gunfight';
    }
    
    const nuiMatch = window.location.href.match(/nui:\/\/([^\/]+)\//);
    if (nuiMatch) {
        return nuiMatch[1];
    }
    
    return 'pvp_gunfight';
}

console.log('[PVP UI] ✅ Script initialisé - Version 4.2.0 - Killfeed System Intégré');