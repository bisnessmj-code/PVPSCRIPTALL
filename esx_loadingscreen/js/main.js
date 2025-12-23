/**
 * ════════════════════════════════════════════════════════════════
 * LOADING SCREEN JAVASCRIPT - 2025
 * Serveur GunFight KichtaBoy
 * ════════════════════════════════════════════════════════════════
 */

'use strict';

// ════════════════════════════════════════════════════════════════
// CLASSE PRINCIPALE
// ════════════════════════════════════════════════════════════════

class LoadingScreenManager {
    constructor() {
        this.elements = {
            backgroundMusic: null,
            musicControls: null,
            playPauseBtn: null,
            volumeBtn: null,
            volumeSlider: null,
            stopBtn: null,
            musicIndicator: null
        };
        
        this.audioState = {
            isPlaying: false,
            isMuted: false,
            currentVolume: 0.4
        };
    }
    
    init() {
        this.cacheElements();
        this.initAudioSystem();
    }
    
    cacheElements() {
        this.elements.backgroundMusic = document.getElementById('backgroundMusic');
        this.elements.musicControls = document.getElementById('musicControls');
        this.elements.playPauseBtn = document.getElementById('playPauseBtn');
        this.elements.volumeBtn = document.getElementById('volumeBtn');
        this.elements.volumeSlider = document.getElementById('volumeSlider');
        this.elements.stopBtn = document.getElementById('stopBtn');
        this.elements.musicIndicator = document.querySelector('.music-indicator');
    }
    
    // ════════════════════════════════════════════════════════════
    // SYSTÈME AUDIO
    // ════════════════════════════════════════════════════════════
    
    initAudioSystem() {
        if (!this.elements.backgroundMusic) {
            return;
        }
        
        this.setupAudioElement();
        this.setupAudioControls();
        
        setTimeout(() => {
            this.playMusic();
        }, 1000);
    }
    
    setupAudioElement() {
        const audio = this.elements.backgroundMusic;
        
        audio.volume = this.audioState.currentVolume;
        audio.loop = true;
        audio.preload = 'auto';
        
        audio.addEventListener('play', () => {
            this.audioState.isPlaying = true;
            this.updatePlayPauseButton();
            this.updateMusicIndicator(true);
        });
        
        audio.addEventListener('pause', () => {
            this.audioState.isPlaying = false;
            this.updatePlayPauseButton();
            this.updateMusicIndicator(false);
        });
        
        audio.addEventListener('error', (e) => {
            // Gestion silencieuse des erreurs
        });
    }
    
    setupAudioControls() {
        if (!this.elements.musicControls) {
            return;
        }
        
        // PLAY/PAUSE
        if (this.elements.playPauseBtn) {
            this.elements.playPauseBtn.addEventListener('click', () => {
                this.togglePlayPause();
            });
        }
        
        // VOLUME/MUTE
        if (this.elements.volumeBtn) {
            this.elements.volumeBtn.addEventListener('click', () => {
                this.toggleMute();
            });
        }
        
        // SLIDER
        if (this.elements.volumeSlider) {
            this.elements.volumeSlider.value = this.audioState.currentVolume * 100;
            
            this.elements.volumeSlider.addEventListener('input', (e) => {
                const newVolume = e.target.value / 100;
                this.setVolume(newVolume);
            });
        }
        
        // STOP
        if (this.elements.stopBtn) {
            this.elements.stopBtn.addEventListener('click', () => {
                this.stopMusic();
            });
        }
    }
    
    playMusic() {
        if (!this.elements.backgroundMusic) {
            return;
        }
        
        const audio = this.elements.backgroundMusic;
        const playPromise = audio.play();
        
        if (playPromise !== undefined) {
            playPromise
                .then(() => {
                    // Lecture démarrée avec succès
                })
                .catch((error) => {
                    // Autoplay bloqué par le navigateur
                });
        }
    }
    
    pauseMusic() {
        if (this.elements.backgroundMusic) {
            this.elements.backgroundMusic.pause();
        }
    }
    
    stopMusic() {
        if (this.elements.backgroundMusic) {
            this.elements.backgroundMusic.pause();
            this.elements.backgroundMusic.currentTime = 0;
            this.audioState.isPlaying = false;
            this.updatePlayPauseButton();
            this.updateMusicIndicator(false);
        }
    }
    
    togglePlayPause() {
        if (this.audioState.isPlaying) {
            this.pauseMusic();
        } else {
            this.playMusic();
        }
    }
    
    toggleMute() {
        if (!this.elements.backgroundMusic) return;
        
        this.audioState.isMuted = !this.audioState.isMuted;
        this.elements.backgroundMusic.muted = this.audioState.isMuted;
        
        this.updateVolumeButton();
    }
    
    setVolume(volume) {
        if (!this.elements.backgroundMusic) return;
        
        volume = Math.max(0, Math.min(1, volume));
        this.audioState.currentVolume = volume;
        this.elements.backgroundMusic.volume = volume;
        
        if (volume > 0 && this.audioState.isMuted) {
            this.audioState.isMuted = false;
            this.elements.backgroundMusic.muted = false;
            this.updateVolumeButton();
        }
    }
    
    updatePlayPauseButton() {
        if (!this.elements.playPauseBtn) return;
        
        const iconPlay = this.elements.playPauseBtn.querySelector('.icon-play');
        const iconPause = this.elements.playPauseBtn.querySelector('.icon-pause');
        
        if (this.audioState.isPlaying) {
            iconPlay.style.display = 'none';
            iconPause.style.display = 'block';
        } else {
            iconPlay.style.display = 'block';
            iconPause.style.display = 'none';
        }
    }
    
    updateVolumeButton() {
        if (!this.elements.volumeBtn) return;
        
        const iconHigh = this.elements.volumeBtn.querySelector('.icon-volume-high');
        const iconMute = this.elements.volumeBtn.querySelector('.icon-volume-mute');
        
        if (this.audioState.isMuted) {
            iconHigh.style.display = 'none';
            iconMute.style.display = 'block';
        } else {
            iconHigh.style.display = 'block';
            iconMute.style.display = 'none';
        }
    }
    
    updateMusicIndicator(isPlaying) {
        if (!this.elements.musicIndicator) return;
        
        if (isPlaying) {
            this.elements.musicIndicator.classList.add('playing');
        } else {
            this.elements.musicIndicator.classList.remove('playing');
        }
    }
}

// ════════════════════════════════════════════════════════════════
// INITIALISATION
// ════════════════════════════════════════════════════════════════

const loadingScreen = new LoadingScreenManager();

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        loadingScreen.init();
    });
} else {
    loadingScreen.init();
}

window.LoadingScreen = loadingScreen;