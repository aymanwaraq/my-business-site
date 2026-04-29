// FLOATING PIXELS
const container = document.getElementById('particles');

if (container) {
    for (let i = 0; i < 30; i++) {
        let pixel = document.createElement('span');

        pixel.style.left = Math.random() * 100 + 'vw';
        pixel.style.animationDuration = (4 + Math.random() * 4) + 's';
        pixel.style.animationDelay = Math.random() * 5 + 's';

        container.appendChild(pixel);
    }
}