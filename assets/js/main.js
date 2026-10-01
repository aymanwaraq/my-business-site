function setLang(l){try{localStorage.setItem('bts_lang',l);}catch(e){}}
function toggleMobile(){
  var nav=document.querySelector('.nav-links');if(!nav)return;
  var open=nav.style.display==='flex';
  nav.style.display=open?'':'flex';
  nav.style.position='absolute';nav.style.top='100%';
  nav.style.left='0';nav.style.right='0';
  nav.style.background='#fff';nav.style.flexDirection='column';
  nav.style.padding='16px 24px';
  nav.style.borderTop='1px solid var(--line)';
  nav.style.boxShadow='0 14px 40px rgba(11,26,43,.12)';
}
function closeMobile(){
  var nav = document.querySelector('.nav-links');
  if (nav) {
    nav.style.display = '';
  }
}
(function(){
  var KEY='bts_ga_consent';
  var b=document.getElementById('cookieBanner');if(!b)return;
  var saved=null;try{saved=localStorage.getItem(KEY);}catch(e){}
  if(!saved)b.classList.add('show');
  var acc=document.getElementById('cookieAccept');
  var rej=document.getElementById('cookieReject');
  if(acc)acc.addEventListener('click',function(){
    try{localStorage.setItem(KEY,'granted');}catch(e){}
    if(typeof gtag!=='undefined')gtag('consent','update',{analytics_storage:'granted'});
    b.classList.remove('show');
  });
  if(rej)rej.addEventListener('click',function(){
    try{localStorage.setItem(KEY,'denied');}catch(e){}
    if(typeof gtag!=='undefined')gtag('consent','update',{analytics_storage:'denied'});
    b.classList.remove('show');
  });
})();
(function(){
  var f=document.getElementById('contactForm');if(!f)return;
  f.addEventListener('submit',async function(e){
    e.preventDefault();
    var btn=e.target.querySelector('button[type=submit]');
    var orig=btn.textContent;btn.textContent='Sending...';btn.disabled=true;
    try{
      var r=await fetch('https://formspree.io/f/xjglbvzr',{
        method:'POST',body:new FormData(e.target),
        headers:{Accept:'application/json'}});
      if(!r.ok)throw 0;
      e.target.reset();alert('Thank you - we will respond within 24 hours.');
    }catch(err){alert('Something went wrong. Please email info@btsapp.net');}
    finally{btn.textContent=orig;btn.disabled=false;}
  });
})();

/* ═══════════════════════════════════════════════════════════════
   SERVICE MARQUEE — build the ticker items at runtime
   ═══════════════════════════════════════════════════════════════ */
(function () {
  var track = document.getElementById('tickerTrack');
  if (!track) return;

  var isRtl = document.body.classList.contains('rtl')
           || document.documentElement.getAttribute('dir') === 'rtl';

  var services = isRtl ? [
    { href: 'services/ai-automation.html',           label: 'أتمتة الذكاء الاصطناعي' },
    { href: 'services/custom-software.html',         label: 'برمجيات مخصصة' },
    { href: 'services/business-intelligence.html',   label: 'ذكاء الأعمال' },
    { href: 'services/system-integration.html',      label: 'تكامل الأنظمة' },
    { href: 'services/bilingual-systems.html',       label: 'أنظمة ثنائية اللغة' },
    { href: 'services/logistics-warehouse.html',     label: 'اللوجستيات والمستودعات' }
  ] : [
    { href: 'services/ai-automation.html',           label: 'AI Automation' },
    { href: 'services/custom-software.html',         label: 'Custom Software' },
    { href: 'services/business-intelligence.html',   label: 'Business Intelligence' },
    { href: 'services/system-integration.html',      label: 'System Integration' },
    { href: 'services/bilingual-systems.html',       label: 'Bilingual Systems' },
    { href: 'services/logistics-warehouse.html',     label: 'Logistics & Warehouse' }
  ];

  function buildGroup(ariaHidden) {
    var g = document.createElement('div');
    g.className = 'ticker-group';
    if (ariaHidden) g.setAttribute('aria-hidden', 'true');

    services.forEach(function (s) {
      var item = document.createElement('a');
      item.className = 'ticker-item';
      item.href = s.href;
      if (ariaHidden) item.tabIndex = -1;

      var dot = document.createElement('span');
      dot.className = 'dot';
      item.appendChild(dot);

      var label = document.createElement('span');
      label.textContent = s.label;
      item.appendChild(label);

      g.appendChild(item);
    });
    return g;
  }

  // Two identical groups; CSS translates -50% for the seamless loop.
  track.appendChild(buildGroup(false));
  track.appendChild(buildGroup(true));
})();


/* ═══════════════════════════════════════════════════════════════
   THEME TOGGLE — persist manual override in localStorage
   First visit: respects prefers-color-scheme (see <head> inline)
   Return visit: uses saved value
   ═══════════════════════════════════════════════════════════════ */
(function () {
  var KEY = 'bts_theme';
  var root = document.documentElement;

  function current() {
    return root.getAttribute('data-theme') === 'dark' ? 'dark' : 'light';
  }

  function apply(theme) {
    if (theme === 'dark') root.setAttribute('data-theme', 'dark');
    else                  root.removeAttribute('data-theme');
  }

  function bind() {
    var btn = document.getElementById('themeToggle');
    if (!btn || btn.dataset.bound === '1') return;
    btn.dataset.bound = '1';

    btn.addEventListener('click', function () {
      var next = current() === 'dark' ? 'light' : 'dark';
      apply(next);
      try { localStorage.setItem(KEY, next); } catch (e) {}
      btn.setAttribute('aria-label',
        next === 'dark' ? 'Switch to light mode' : 'Switch to dark mode');
      btn.setAttribute('title',
        next === 'dark' ? 'Switch to light mode' : 'Switch to dark mode');
    });

    // Initial aria state
    var isDark = current() === 'dark';
    btn.setAttribute('aria-label',
      isDark ? 'Switch to light mode' : 'Switch to dark mode');
    btn.setAttribute('title',
      isDark ? 'Switch to light mode' : 'Switch to dark mode');
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', bind);
  } else {
    bind();
  }

  // Follow the OS if the user has NOT made a manual choice
  try {
    if (!localStorage.getItem(KEY)) {
      var mq = window.matchMedia('(prefers-color-scheme: dark)');
      mq.addEventListener('change', function (e) {
        if (localStorage.getItem(KEY)) return;   // user has chosen — respect it
        apply(e.matches ? 'dark' : 'light');
      });
    }
  } catch (e) {}
})();

/* ═══════════════════════════════════════════════════════════════
   VIDEO PAUSE/PLAY + SCROLL-TO-TOP
   ═══════════════════════════════════════════════════════════════ */

/* ─── Hero video pause/play toggle ────────────────────────────── */
(function () {
  var btn = document.getElementById('videoControl');
  if (!btn) return;
  var video = document.querySelector('.hero-video');
  if (!video) return;

  // Respect user's reduced-motion preference on load
  try {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      video.pause();
      btn.classList.add('is-paused');
      btn.setAttribute('aria-label', 'Play background video');
      btn.setAttribute('title', 'Play video');
    }
  } catch (e) {}

  btn.addEventListener('click', function () {
    if (video.paused) {
      video.play();
      btn.classList.remove('is-paused');
      btn.setAttribute('aria-label', 'Pause background video');
      btn.setAttribute('title', 'Pause video');
    } else {
      video.pause();
      btn.classList.add('is-paused');
      btn.setAttribute('aria-label', 'Play background video');
      btn.setAttribute('title', 'Play video');
    }
  });

  video.addEventListener('pause', function () {
    btn.classList.add('is-paused');
    btn.setAttribute('aria-label', 'Play background video');
  });
  video.addEventListener('play', function () {
    btn.classList.remove('is-paused');
    btn.setAttribute('aria-label', 'Pause background video');
  });
})();

/* ─── Scroll-to-top button ─────────────────────────────────────── */
(function () {
  var btn = document.getElementById('scrollTopBtn');
  if (!btn) return;

  var showAt = 300;
  var ticking = false;

  function update() {
    if (window.scrollY > showAt) {
      btn.classList.add('show');
    } else {
      btn.classList.remove('show');
    }
    ticking = false;
  }

  window.addEventListener('scroll', function () {
    if (!ticking) {
      window.requestAnimationFrame(update);
      ticking = true;
    }
  }, { passive: true });

  update();

  btn.addEventListener('click', function () {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });
})();


/* ═══════════════════════════════════════════════════════════════
   IMAGE LIGHTBOX — click any content image to view full size
   ═══════════════════════════════════════════════════════════════ */
(function () {
  var lightbox = document.getElementById('imgLightbox');
  var lightboxImg = document.getElementById('imgLightboxImg');
  var closeBtn = document.getElementById('imgLightboxClose');
  if (!lightbox || !lightboxImg) return;

  // Selectors we EXCLUDE from becoming zoomable
  var excludeSelectors = [
    '.brand img',          // logo in nav
    '.nav img',            // any nav image
    '.utility-bar img',    // utility bar
    '.footer img',         // footer logos
    '.hero-video',         // hero video element
    '.video-control',      // video control button
    '.theme-toggle',       // theme toggle
    '.mobile-toggle',      // mobile hamburger
    '.img-lightbox-img',   // the lightbox itself
    'picture source',      // picture sources
    'a[href] img'          // images already wrapped in a link
  ];

  function isExcluded(img) {
    for (var i = 0; i < excludeSelectors.length; i++) {
      if (img.closest(excludeSelectors[i])) return true;
    }
    // Skip tiny icons / tracking pixels
    if (img.naturalWidth && img.naturalWidth < 120) return true;
    if (img.width && img.width < 120 && img.height && img.height < 120) return true;
    // Skip SVG icons
    if (img.src && img.src.endsWith('.svg')) return true;
    return false;
  }

  function enhanceImages() {
    var images = document.querySelectorAll('main img, section img, article img, figure img, .section img, .post img, .svc img, .loc img, .art-body img, .flow-visual img, .hero-intro img');
    images.forEach(function (img) {
      if (img.dataset.zoomable === '1') return;
      if (isExcluded(img)) return;
      img.dataset.zoomable = '1';
      img.classList.add('img-zoomable');
      img.setAttribute('role', 'button');
      img.setAttribute('tabindex', '0');
      img.setAttribute('aria-label', 'Click to view full size: ' + (img.alt || 'image'));

      var open = function (e) {
        e.preventDefault();
        e.stopPropagation();
        openLightbox(img.src, img.alt || '');
      };
      img.addEventListener('click', open);
      img.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); open(e); }
      });
    });
  }

  function openLightbox(src, alt) {
    lightboxImg.src = src;
    lightboxImg.alt = alt;
    lightbox.classList.add('active');
    document.body.style.overflow = 'hidden';
    setTimeout(function () { closeBtn && closeBtn.focus(); }, 50);
  }

  function closeLightbox() {
    lightbox.classList.remove('active');
    document.body.style.overflow = '';
    lightboxImg.src = '';
  }

  // Close on click outside the image
  lightbox.addEventListener('click', function (e) {
    if (e.target === lightbox) closeLightbox();
  });

  // Close button
  closeBtn && closeBtn.addEventListener('click', function (e) {
    e.stopPropagation();
    closeLightbox();
  });

  // Escape key
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && lightbox.classList.contains('active')) {
      closeLightbox();
    }
  });

  // Enhance images on initial load
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', enhanceImages);
  } else {
    enhanceImages();
  }

  // Re-enhance if content is added dynamically (blog grids, etc.)
  var observer = new MutationObserver(function () {
    enhanceImages();
  });
  observer.observe(document.body, { childList: true, subtree: true });
})();
/* ═══════════════════════════════════════════════════════════════
   MOBILE MENU AUTO-CLOSE
   Closes the mobile menu when any navigation link is clicked.
   ═══════════════════════════════════════════════════════════════ */
document.addEventListener('DOMContentLoaded', function () {
    var navLinks = document.querySelectorAll('.nav-links a');
    
    navLinks.forEach(function (link) {
        link.addEventListener('click', function () {
            closeMobile();
        });
    });

    // Also close the menu if the user clicks outside of it
    document.addEventListener('click', function (e) {
        var nav = document.querySelector('.nav-links');
        var toggle = document.querySelector('.mobile-toggle');
        
        if (!nav || !toggle) return;
        
        // If the menu is open and the click is NOT inside the nav or the toggle button, close it
        var menuIsOpen = nav.style.display === 'flex';
        var clickedInsideMenu = nav.contains(e.target);
        var clickedOnToggle = toggle.contains(e.target);
        
        if (menuIsOpen && !clickedInsideMenu && !clickedOnToggle) {
            closeMobile();
        }
    });
});