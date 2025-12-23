const music = document.getElementById("music");
const indicator = document.getElementById("mute-indicator");
music.volume = 0.2;

// Démarrage auto
music.play().catch(() => {
    // certains navigateurs bloquent, OK sur FiveM
});

// Toggle mute avec ESPACE
document.addEventListener("keydown", (e) => {
    if (e.code === "Space") {
        e.preventDefault();
        music.muted = !music.muted;
        indicator.textContent = music.muted ? "🔇" : "🔊";
    }
});

// Toggle mute en cliquant sur l'icône
indicator.addEventListener("click", () => {
    music.muted = !music.muted;
    indicator.textContent = music.muted ? "🔇" : "🔊";
});