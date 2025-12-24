/* ═══════════════════════════════════════════════════════════════
   FIGHTLEAGUE COURSE - SCRIPT NUI
   ═══════════════════════════════════════════════════════════════ */

// Variables globales
let captureInterval = null;
let currentCaptureProgress = 0;

// ═══════════════════════════════════════════════════════════════
// GESTION DES MESSAGES LUA → JS
// ═══════════════════════════════════════════════════════════════

window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'showCapture':
            showCaptureUI();
            break;
            
        case 'hideCapture':
            hideCaptureUI();
            break;
            
        case 'updateCapture':
            updateCaptureProgress(data.progress);
            break;
            
        case 'showRoundResult':
            showRoundResult(data);
            break;
            
        case 'hideRoundResult':
            hideRoundResult();
            break;
            
        case 'showGameEnd':
            showGameEnd(data);
            break;
            
        case 'hideGameEnd':
            hideGameEnd();
            break;
    }
});

// ═══════════════════════════════════════════════════════════════
// INTERFACE DE CAPTURE
// ═══════════════════════════════════════════════════════════════

function showCaptureUI() {
    const ui = document.getElementById('capture-ui');
    ui.classList.remove('hidden');
    currentCaptureProgress = 0;
    updateCaptureProgress(0);
}

function hideCaptureUI() {
    const ui = document.getElementById('capture-ui');
    ui.classList.add('fade-out');
    
    setTimeout(() => {
        ui.classList.add('hidden');
        ui.classList.remove('fade-out');
        currentCaptureProgress = 0;
        updateCaptureProgress(0);
    }, 300);
}

function updateCaptureProgress(progress) {
    currentCaptureProgress = Math.min(100, Math.max(0, progress));
    
    const fill = document.getElementById('capture-bar-fill');
    const percentage = document.getElementById('capture-percentage');
    
    fill.style.width = currentCaptureProgress + '%';
    percentage.textContent = Math.floor(currentCaptureProgress) + '%';
}

// ═══════════════════════════════════════════════════════════════
// INTERFACE DE RÉSULTAT DE ROUND
// ═══════════════════════════════════════════════════════════════

function showRoundResult(data) {
    // Fermer l'UI de capture si elle est ouverte
    hideCaptureUI();
    
    const ui = document.getElementById('round-result-ui');
    const roundText = document.getElementById('result-round');
    const titleText = document.getElementById('result-title');
    const reasonText = document.getElementById('result-reason');
    const scoreText = document.getElementById('result-score');
    
    // Mettre à jour les textes
    roundText.textContent = `ROUND ${data.round}`;
    titleText.textContent = data.won ? 'VICTOIRE' : 'DÉFAITE';
    
    // Textes de raison
    const reasonTexts = {
        'escape': 'Fuite réussie !',
        'capture': 'Capture réussie',
        'timeout': 'Temps écoulé'
    };
    reasonText.textContent = reasonTexts[data.reason] || '';
    
    scoreText.textContent = data.score || '0';
    
    // Appliquer le style victoire/défaite
    titleText.classList.remove('victory', 'defeat');
    titleText.classList.add(data.won ? 'victory' : 'defeat');
    
    // Afficher
    ui.classList.remove('hidden');
    
    // Masquer automatiquement après 4 secondes
    setTimeout(() => {
        hideRoundResult();
    }, 4000);
}

function hideRoundResult() {
    const ui = document.getElementById('round-result-ui');
    ui.classList.add('fade-out');
    
    setTimeout(() => {
        ui.classList.add('hidden');
        ui.classList.remove('fade-out');
    }, 300);
}

// ═══════════════════════════════════════════════════════════════
// INTERFACE DE FIN DE PARTIE
// ═══════════════════════════════════════════════════════════════

function showGameEnd(data) {
    // Fermer toutes les autres UIs
    hideCaptureUI();
    hideRoundResult();
    
    const ui = document.getElementById('game-end-ui');
    const titleText = document.getElementById('game-end-title');
    const subtitleText = document.getElementById('game-end-subtitle');
    const scoreText = document.getElementById('game-end-score');
    
    // Déterminer le titre
    if (data.winner === 'draw') {
        titleText.textContent = 'ÉGALITÉ';
        titleText.classList.add('draw');
        subtitleText.textContent = 'Match nul !';
    } else if (data.won) {
        titleText.textContent = 'VICTOIRE';
        titleText.classList.add('victory');
        subtitleText.textContent = 'Vous avez gagné la partie !';
    } else {
        titleText.textContent = 'DÉFAITE';
        titleText.classList.add('defeat');
        subtitleText.textContent = 'Vous avez perdu la partie';
    }
    
    // Score final (si disponible)
    if (data.finalScoreText) {
        scoreText.textContent = data.finalScoreText;
    } else {
        scoreText.textContent = data.finalScore || '0';
    }
    
    // Afficher
    ui.classList.remove('hidden');
    
    // Masquer automatiquement après 5 secondes
    setTimeout(() => {
        hideGameEnd();
    }, 5000);
}

function hideGameEnd() {
    const ui = document.getElementById('game-end-ui');
    ui.classList.add('fade-out');
    
    setTimeout(() => {
        ui.classList.add('hidden');
        ui.classList.remove('fade-out');
        
        // Reset des classes
        const titleText = document.getElementById('game-end-title');
        titleText.classList.remove('victory', 'defeat', 'draw');
    }, 300);
}

// ═══════════════════════════════════════════════════════════════
// UTILITAIRES
// ═══════════════════════════════════════════════════════════════

// Fonction pour envoyer des messages au client Lua (si nécessaire)
function sendNUIMessage(data) {
    fetch(`https://${GetParentResourceName()}/nuiCallback`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    });
}

// Récupérer le nom de la ressource
function GetParentResourceName() {
    let resourceName = 'fightleaguecourse';
    
    if (window.location.href.includes('nui://')) {
        const match = window.location.href.match(/nui:\/\/([^\/]+)\//);
        if (match) {
            resourceName = match[1];
        }
    }
    
    return resourceName;
}
