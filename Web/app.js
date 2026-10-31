// Sound Voices definition (exact match with trysnick.xyz)
const SOUNDS = [
  { id: "nok", name: "Nok", color: "#6366f1", desc: "Crisp detent", freq: 184, decay: 0.09, type: "sine" },
  { id: "vyl", name: "Vyl", color: "#a855f7", desc: "Vinyl tick", freq: 320, decay: 0.07, type: "triangle" },
  { id: "glu", name: "Glu", color: "#14b8a6", desc: "Gluey pop", freq: 140, decay: 0.16, type: "sine" },
  { id: "dib", name: "Dib", color: "#f97316", desc: "Tight blip", freq: 440, decay: 0.05, type: "square" },
  { id: "plo", name: "Plo", color: "#3b82f6", desc: "Low plop", freq: 96, decay: 0.18, type: "sine" },
  { id: "tok", name: "Tok", color: "#2dd4bf", desc: "Wooden tok", freq: 600, decay: 0.06, type: "square" },
  { id: "rub", name: "Rub", color: "#ef4444", desc: "Rubber snap", freq: 220, decay: 0.11, type: "sawtooth" }
];

// State
let isSoundEnabled = true;
let currentVoice = SOUNDS[0]; // Nok
let volumePercent = 72;
let notchSpacing = 30;
let rateLimitMs = 18;

let accumulatedDelta = 0;
let lastEventTime = 0;
let lastClickTime = 0;
let clickCount = 0;

// Audio Context & Buffers
let audioCtx = null;
const audioBuffers = {};

function initAudio() {
  if (!audioCtx) {
    audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  }
  if (audioCtx.state === 'suspended') {
    audioCtx.resume();
  }
}

// Pre-load audio buffers
async function loadAudioBuffers() {
  initAudio();
  for (const s of SOUNDS) {
    try {
      const resp = await fetch(`sounds/${s.id}.wav`);
      const arrayBuffer = await resp.arrayBuffer();
      const decoded = await audioCtx.decodeAudioData(arrayBuffer);
      audioBuffers[s.id] = decoded;
    } catch (e) {
      console.warn(`Could not preload ${s.id}.wav, will use synthesis:`, e);
    }
  }
}

// Synthetic Fallback Generator (exact synth params from trysnick.xyz)
function playSyntheticVoice(voice, gainValue) {
  if (!audioCtx) return;
  const now = audioCtx.currentTime;
  const osc = audioCtx.createOscillator();
  const gainNode = audioCtx.createGain();

  osc.type = voice.type || 'sine';
  osc.frequency.setValueAtTime(voice.freq, now);
  osc.frequency.exponentialRampToValueAtTime(voice.freq * 0.4, now + voice.decay);

  gainNode.gain.setValueAtTime(gainValue * 0.8, now);
  gainNode.gain.exponentialRampToValueAtTime(0.001, now + voice.decay);

  osc.connect(gainNode);
  gainNode.connect(audioCtx.destination);

  osc.start(now);
  osc.stop(now + voice.decay);
}

// Play Voice (Buffer or Synth)
function playVoice(voice, gainScale = 1.0) {
  if (!isSoundEnabled) return;
  initAudio();

  const finalGain = Math.min(1.0, Math.max(0.0, gainScale * (volumePercent / 100)));

  // Try playing preloaded AudioBuffer
  const buffer = audioBuffers[voice.id];
  if (buffer && audioCtx) {
    const src = audioCtx.createBufferSource();
    src.buffer = buffer;
    const gainNode = audioCtx.createGain();
    gainNode.gain.value = finalGain;
    src.connect(gainNode);
    gainNode.connect(audioCtx.destination);
    src.start();
  } else {
    // Fallback: Web Audio synthesis
    playSyntheticVoice(voice, finalGain);
  }

  // Trackpad / Mobile Vibration
  if (navigator.vibrate) {
    try { navigator.vibrate(8); } catch (_) {}
  }

  // Visual feedback
  animateWaveform(voice.color);
}

// Waveform Animation
function animateWaveform(color) {
  const bars = document.querySelectorAll('.waveform-display .bar');
  bars.forEach(bar => {
    const rndHeight = Math.floor(Math.random() * 85) + 15;
    bar.style.height = `${rndHeight}%`;
    bar.style.backgroundColor = color;
  });
  setTimeout(() => {
    bars.forEach((bar, i) => {
      bar.style.height = `${[40, 65, 90, 50, 75, 100, 60, 35][i % 8]}%`;
    });
  }, 120);
}

// Scroll Wheel Handler (matching trysnick.xyz algorithm)
window.addEventListener('wheel', (e) => {
  if (!isSoundEnabled) return;
  initAudio();

  const now = performance.now();
  const dt = Math.max(1, now - lastEventTime);
  lastEventTime = now;

  const absDelta = Math.abs(e.deltaY);
  if (absDelta === 0) return;

  const velocity = absDelta / dt;
  accumulatedDelta += absDelta;

  const timeSinceLastClick = now - lastClickTime;

  if (accumulatedDelta >= notchSpacing && timeSinceLastClick >= rateLimitMs) {
    accumulatedDelta = accumulatedDelta % notchSpacing;
    lastClickTime = now;
    clickCount++;

    // Velocity scaling (trysnick: minGain 0.25, velocityScale 0.18, maxGain 1.0)
    const scaledGain = Math.min(1.0, 0.25 + velocity * 0.18);
    playVoice(currentVoice, scaledGain);

    // Update UI counters
    document.getElementById('clickCounter').textContent = clickCount;
    document.getElementById('velocityDisplay').textContent = `${velocity.toFixed(2)} px/ms`;
  } else if (accumulatedDelta > 6 * notchSpacing) {
    accumulatedDelta = 6 * notchSpacing;
  }
}, { passive: true });

// Render Sound Voice Cards
function renderVoices() {
  const grid = document.getElementById('voicesGrid');
  grid.innerHTML = '';

  SOUNDS.forEach(s => {
    const card = document.createElement('div');
    card.className = `voice-card ${s.id === currentVoice.id ? 'active' : ''}`;
    card.dataset.id = s.id;

    card.innerHTML = `
      <div class="voice-info">
        <span class="voice-dot" style="background: ${s.color}; box-shadow: 0 0 10px ${s.color};"></span>
        <div>
          <span class="voice-name">${s.name}</span>
          <span class="voice-desc">${s.desc}</span>
        </div>
      </div>
      <div class="voice-play-icon" title="Preview sound">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
          <polygon points="5 3 19 12 5 21 5 3"></polygon>
        </svg>
      </div>
    `;

    card.addEventListener('click', () => {
      currentVoice = s;
      document.querySelectorAll('.voice-card').forEach(c => c.classList.remove('active'));
      card.classList.add('active');

      // Update pill badge & root accent color
      document.getElementById('pillVoice').textContent = s.name;
      document.documentElement.style.setProperty('--accent', s.color);

      // Play immediate preview
      playVoice(s, 1.0);
    });

    grid.appendChild(card);
  });
}

// Setup Event Listeners
function setupUI() {
  // Volume Slider
  const volumeSlider = document.getElementById('volumeSlider');
  const volumeVal = document.getElementById('volumeVal');
  volumeSlider.addEventListener('input', (e) => {
    volumePercent = parseInt(e.target.value, 10);
    volumeVal.textContent = `${volumePercent}%`;
  });

  // Spacing Slider
  const spacingSlider = document.getElementById('spacingSlider');
  const spacingVal = document.getElementById('spacingVal');
  spacingSlider.addEventListener('input', (e) => {
    notchSpacing = parseInt(e.target.value, 10);
    spacingVal.textContent = `${notchSpacing}px`;
  });

  // Floating Status Pill Button
  const toggleBtn = document.getElementById('toggleScrollSoundBtn');
  const pillDot = document.getElementById('pillDot');
  const pillText = document.getElementById('pillText');

  toggleBtn.addEventListener('click', () => {
    isSoundEnabled = !isSoundEnabled;
    toggleBtn.setAttribute('aria-pressed', isSoundEnabled ? 'true' : 'false');
    if (isSoundEnabled) {
      pillDot.classList.add('active');
      pillText.textContent = 'Scroll sound on · Scroll to hear';
      playVoice(currentVoice, 1.0);
    } else {
      pillDot.classList.remove('active');
      pillText.textContent = 'Scroll sound off';
    }
  });

  // Test preview button in hero
  const testClickBtn = document.getElementById('testClickBtn');
  testClickBtn.addEventListener('click', () => {
    initAudio();
    playVoice(currentVoice, 1.0);
  });

  // Unlock audio on first interaction
  window.addEventListener('pointerdown', initAudio, { once: true });
  window.addEventListener('keydown', initAudio, { once: true });
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
  renderVoices();
  setupUI();
  loadAudioBuffers();
});
