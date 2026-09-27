/* ==========================================================================
   btsapp.net — blog.js
   Shared logic for:
     • /blog/index.html         (EN index)
     • /blog/ar/index.html      (AR index)
     • /blog/article.html       (single template, both languages)

   Entry point:
     Blog.init({ mode: "index",  lang: "en", postsUrl: "/blog/posts.json" });
     Blog.init({ mode: "index",  lang: "ar", postsUrl: "/blog/posts.json" });
     Blog.init({ mode: "article",              postsUrl: "/blog/posts.json" });
   ========================================================================== */

(function (global) {
  "use strict";

  /* ---------- Localization strings ---------- */
  const STRINGS = {
    en: {
      loading:        "Loading posts…",
      emptyTitle:     "No posts yet",
      emptyText:      "New articles will appear here soon.",
      notFoundTitle:  "Article not found",
      notFoundText:   "We couldn't find that post. It may have been moved or removed.",
      readMore:       "Read more",
      backToIndex:    "Back to all posts",
      backToBlog:     "Back to blog",
      by:             "By",
      minRead:        "min read",
      dateLocale:     "en-GB",
      switchLang:     "العربية",
      switchLangHref: null // set by init for cross-linking
    },
    ar: {
      loading:        "جارٍ تحميل المقالات…",
      emptyTitle:     "لا توجد مقالات بعد",
      emptyText:      "ستظهر المقالات الجديدة هنا قريبًا.",
      notFoundTitle:  "لم يتم العثور على المقال",
      notFoundText:   "تعذّر العثور على هذا المقال. ربما تم نقله أو حذفه.",
      readMore:       "اقرأ المزيد",
      backToIndex:    "العودة إلى كل المقالات",
      backToBlog:     "العودة إلى المدونة",
      by:             "بقلم",
      minRead:        "دقيقة قراءة",
      dateLocale:     "ar-EG-u-nu-latn", // Arabic, Western digits
      switchLang:     "English",
      switchLangHref: null
    }
  };

  /* ---------- State ---------- */
  const state = {
    mode: "index",
    lang: "en",
    postsUrl: "/blog/posts.json",
    posts: [],
    t: STRINGS.en
  };

  /* ---------- Utils ---------- */

  function escapeHtml(str) {
    if (str == null) return "";
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function formatDate(iso, locale) {
    if (!iso) return "";
    const d = new Date(iso + "T00:00:00");
    if (isNaN(d)) return iso;
    try {
      return new Intl.DateTimeFormat(locale, {
        year: "numeric", month: "long", day: "numeric"
      }).format(d);
    } catch (e) {
      return iso;
    }
  }

  function splitCategories(cat) {
    if (!cat) return [];
    return String(cat)
      .split(",")
      .map(s => s.trim())
      .filter(Boolean);
  }

  function getParam(name) {
    return new URLSearchParams(window.location.search).get(name);
  }

  function el(tag, attrs, children) {
    const node = document.createElement(tag);
    if (attrs) {
      for (const k in attrs) {
        if (k === "class") node.className = attrs[k];
        else if (k === "html") node.innerHTML = attrs[k];
        else if (k === "text") node.textContent = attrs[k];
        else if (attrs[k] != null && attrs[k] !== false) {
          node.setAttribute(k, attrs[k]);
        }
      }
    }
    if (children) {
      (Array.isArray(children) ? children : [children]).forEach(c => {
        if (c == null) return;
        node.appendChild(typeof c === "string" ? document.createTextNode(c) : c);
      });
    }
    return node;
  }

  /* ---------- Data ---------- */

  function fetchPosts() {
    return fetch(state.postsUrl, { cache: "no-cache" })
      .then(r => {
        if (!r.ok) throw new Error("HTTP " + r.status);
        return r.json();
      })
      .then(data => Array.isArray(data) ? data : [])
      .catch(err => {
        console.error("[blog] failed to load posts.json:", err);
        return [];
      });
  }

  function postsForLang(lang) {
    return state.posts
      .filter(p => p.lang === lang)
      .sort((a, b) => (b.date || "").localeCompare(a.date || ""));
  }

  function findPostBySlug(slug) {
    return state.posts.find(p => p.slug === slug) || null;
  }

  /* ---------- Index rendering ---------- */

  function renderPostCard(post) {
    const chips = splitCategories(post.category).map(c =>
      el("li", { class: "chip", text: c })
    );

    const card = el("article", { class: "post-card" }, [
      el("a", {
        class: "post-card__cover-link",
        href: articleUrl(post),
        "aria-hidden": "true",
        tabindex: "-1"
      }, [
        el("img", {
          class: "post-card__cover",
          src: post.cover || "",
          alt: "",
          loading: "lazy",
          decoding: "async"
        })
      ]),
      el("div", { class: "post-card__body" }, [
        el("div", { class: "post-card__meta" }, [
          el("time", { class: "post-card__date", datetime: post.date || "", text: formatDate(post.date, state.t.dateLocale) }),
          post.author ? el("span", { class: "post-card__meta-sep" }) : null,
          post.author ? el("span", { text: post.author }) : null
        ]),
        el("h2", { class: "post-card__title" }, [
          el("a", { href: articleUrl(post), text: post.title || "" })
        ]),
        el("p", { class: "post-card__summary", text: post.summary || "" }),
        chips.length ? el("ul", { class: "post-card__chips" }, chips) : null
      ])
    ]);

    return card;
  }

  function articleUrl(post) {
    return "/blog/article.html?slug=" + encodeURIComponent(post.slug);
  }

  function renderIndex() {
    const root = document.getElementById("blog-index-root");
    if (!root) return;

    const posts = postsForLang(state.lang);
    root.innerHTML = "";

    if (!posts.length) {
      root.appendChild(el("div", { class: "blog-empty" }, [
        el("h2", { class: "blog-empty__title", text: state.t.emptyTitle }),
        el("p", { class: "blog-empty__text", text: state.t.emptyText })
      ]));
      return;
    }

    const grid = el("div", { class: "blog-grid" },
      posts.map(renderPostCard)
    );
    root.appendChild(grid);
  }

  /* ---------- Article rendering ---------- */

  function renderContentBlock(block) {
    if (!block || typeof block !== "object") return null;

    switch (block.type) {
      case "heading":
        return el("h2", { text: block.text || "" });

      case "paragraph":
        return el("p", { text: block.text || "" });

      case "image":
        return el("figure", null, [
          el("img", {
            src: block.src || "",
            alt: block.caption || "",
            loading: "lazy",
            decoding: "async"
          }),
          block.caption ? el("figcaption", { text: block.caption }) : null
        ]);

      /* ---- Video support (YouTube, Vimeo, or self-hosted MP4) ---- */
      case "video": {
        const caption = block.caption
          ? el("figcaption", { text: block.caption })
          : null;

        let media;
        if (block.provider === "youtube" && block.id) {
          media = el("iframe", {
            src: "https://www.youtube-nocookie.com/embed/" + encodeURIComponent(block.id),
            title: block.caption || "Video",
            loading: "lazy",
            allow: "accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture",
            allowfullscreen: "true",
            frameborder: "0"
          });
        } else if (block.provider === "vimeo" && block.id) {
          media = el("iframe", {
            src: "https://player.vimeo.com/video/" + encodeURIComponent(block.id),
            title: block.caption || "Video",
            loading: "lazy",
            allow: "autoplay; fullscreen; picture-in-picture",
            allowfullscreen: "true",
            frameborder: "0"
          });
        } else if (block.src) {
          media = el("video", {
            src: block.src,
            poster: block.poster || "",
            controls: "controls",
            preload: "metadata",
            playsinline: "playsinline"
          });
        } else {
          return null;
        }

        return el("figure", { class: "article__video" }, [media, caption]);
      }

      default:
        return null;
    }
  }

  function renderArticle() {
    const root = document.getElementById("blog-article-root");
    if (!root) return;

    const slug = getParam("slug");
    const post = slug ? findPostBySlug(slug) : null;

    /* 404 state */
    if (!post) {
      root.innerHTML = "";
      root.appendChild(el("div", { class: "article-missing" }, [
        el("span", { class: "article-missing__code", text: slug ? "?slug=" + slug : "no slug" }),
        el("h1", { class: "article-missing__title", text: state.t.notFoundTitle }),
        el("p", { text: state.t.notFoundText }),
        el("p", null, [
          el("a", {
            href: state.lang === "ar" ? "/blog/ar/" : "/blog/",
            text: state.t.backToIndex
          })
        ])
      ]));
      return;
    }

    /* Language of THIS article overrides the page default */
    const lang = post.lang || state.lang;
    const t = STRINGS[lang] || STRINGS.en;

    /* Set <html lang> and <html dir> to match the article */
    document.documentElement.lang = lang;
    document.documentElement.dir = lang === "ar" ? "rtl" : "ltr";

    /* Update <title> */
    if (post.title) {
      document.title = post.title + " | BTS Blog";
    }

    const chips = splitCategories(post.category).map(c =>
      el("li", { class: "chip", text: c })
    );

    const backHref = lang === "ar" ? "/blog/ar/" : "/blog/";

    /* Content blocks */
    const contentNodes = (post.content || [])
      .map(renderContentBlock)
      .filter(Boolean);

    const contentWrap = el("div", { class: "article__content" });
    contentNodes.forEach(n => contentWrap.appendChild(n));

    /* Header */
    const header = el("header", { class: "article__header" }, [
      chips.length ? el("ul", { class: "article-chips article__chips" }, chips) : null,
      el("h1", { class: "article__title", text: post.title || "" }),
      el("div", { class: "article__meta" }, [
        el("time", { datetime: post.date || "", text: formatDate(post.date, t.dateLocale) }),
        post.author ? el("span", { class: "article__meta-sep" }) : null,
        post.author ? el("span", { text: t.by + " " + post.author }) : null
      ])
    ]);

    /* Hero */
    const hero = post.cover
      ? el("div", { class: "article__hero" }, [
          el("img", { src: post.cover, alt: "", loading: "eager", decoding: "async" })
        ])
      : null;

    /* Back link */
    const back = el("a", { class: "article__back", href: backHref }, [
      el("span", { class: "article__back-arrow", text: lang === "ar" ? "→" : "←" }),
      el("span", { text: t.backToIndex })
    ]);

    /* Footer with language cross-link if a twin exists */
    const twinLang = lang === "ar" ? "en" : "ar";
    const twinSlug = lang === "ar"
      ? post.slug.replace(/-ar$/, "")
      : post.slug + "-ar";
    const twin = findPostBySlug(twinSlug);

    const footer = el("footer", { class: "article__footer" }, [
      el("a", { href: backHref, text: t.backToBlog }),
      twin
        ? el("a", {
            class: "blog-lang-switch",
            href: "/blog/article.html?slug=" + encodeURIComponent(twin.slug)
          }, [ el("span", { text: STRINGS[twinLang].switchLang }) ])
        : null
    ]);

    root.innerHTML = "";
    root.appendChild(back);
    root.appendChild(header);
    if (hero) root.appendChild(hero);
    root.appendChild(contentWrap);
    root.appendChild(footer);
  }

  /* ---------- Boot ---------- */

  function showLoading() {
    const root =
      document.getElementById("blog-index-root") ||
      document.getElementById("blog-article-root");
    if (!root) return;
    root.innerHTML = "";
    root.appendChild(el("div", { class: "blog-loading" }, [
      el("p", { text: state.t.loading }),
      el("div", { class: "blog-loading__dots" }, [
        el("span"), el("span"), el("span")
      ])
    ]));
  }

  function init(opts) {
    opts = opts || {};
    state.mode = opts.mode || "index";
    state.lang = opts.lang || "en";
    state.postsUrl = opts.postsUrl || "/blog/posts.json";
    state.t = STRINGS[state.lang] || STRINGS.en;

    showLoading();

    fetchPosts().then(posts => {
      state.posts = posts;
      if (state.mode === "article") renderArticle();
      else renderIndex();
    });
  }

  global.Blog = { init: init };

})(window);