<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="doa.ShopConfig" %>
<%
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=Please login first");
        return;
    }
    String adminUser  = (String) session.getAttribute("admin");
    String fullName   = (String) session.getAttribute("fullName");
    if (fullName == null) fullName = adminUser;

    ShopConfig shop   = ShopConfig.getInstance();
    String shopEnName = shop.getEnglishName();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= shopEnName %> — Credit Manager</title>
    <link rel="stylesheet" href="css/main.css">
    <style>
        /* ── Language toggle button ── */
        .lang-toggle {
            display: flex;
            align-items: center;
            gap: 0;
            background: rgba(255,255,255,0.06);
            border: 1px solid rgba(255,255,255,0.14);
            border-radius: 20px;
            overflow: hidden;
            flex-shrink: 0;
        }
        .lang-btn {
            padding: 6px 14px;
            font-family: 'Outfit', sans-serif;
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
            border: none;
            background: transparent;
            color: rgba(255,255,255,0.5);
            transition: all 0.2s;
            letter-spacing: 0.3px;
            white-space: nowrap;
        }
        .lang-btn.active {
            background: var(--gold);
            color: #0d1b2a;
            border-radius: 20px;
        }
        .lang-btn:hover:not(.active) {
            color: rgba(255,255,255,0.85);
            background: rgba(255,255,255,0.06);
        }
    </style>
</head>
<body>

<!-- ═══════ SIDEBAR ═══════ -->
<div class="sidebar" id="sidebar">

    <div class="profile-section">
        <div class="profile-avatar">👤</div>
        <div class="user-name"><%= fullName.toUpperCase() %></div>
        <div class="user-role">Administrator</div>
    </div>

    <ul class="menu" id="mainMenu">

        <li class="active" data-page="index.jsp">
            <a href="#" onclick="loadPage('index.jsp','Dashboard',this);return false;">
                <span class="menu-icon">🏠</span>
                <span class="menu-label" data-i18n="nav.dashboard">Dashboard</span>
            </a>
            <span class="tooltip-label" data-i18n="nav.dashboard">Dashboard</span>
        </li>

        <li data-page="add_customer.jsp">
            <a href="#" onclick="loadPage('add_customer.jsp','Add Customer',this);return false;">
                <span class="menu-icon">➕</span>
                <span class="menu-label" data-i18n="nav.add_customer">Add Customer</span>
            </a>
            <span class="tooltip-label" data-i18n="nav.add_customer">Add Customer</span>
        </li>

        <li data-page="view_customers.jsp">
            <a href="#" onclick="loadPage('view_customers.jsp','Customers',this);return false;">
                <span class="menu-icon">👥</span>
                <span class="menu-label" data-i18n="nav.customers">Customers</span>
            </a>
            <span class="tooltip-label" data-i18n="nav.customers">Customers</span>
        </li>

        <li data-page="add_dealer.jsp">
            <a href="#" onclick="loadPage('add_dealer.jsp','Add Dealer',this);return false;">
                <span class="menu-icon">🏬</span>
                <span class="menu-label" data-i18n="nav.add_dealer">Add Dealer</span>
            </a>
            <span class="tooltip-label" data-i18n="nav.add_dealer">Add Dealer</span>
        </li>

        <li data-page="view_dealers.jsp">
            <a href="#" onclick="loadPage('view_dealers.jsp','Dealers',this);return false;">
                <span class="menu-icon">📋</span>
                <span class="menu-label" data-i18n="nav.dealers">Dealers</span>
            </a>
            <span class="tooltip-label" data-i18n="nav.dealers">Dealers</span>
        </li>

        <li data-page="view_products.jsp">
            <a href="#" onclick="loadPage('view_products.jsp','Products',this);return false;">
                <span class="menu-icon">📦</span>
                <span class="menu-label" data-i18n="nav.products">Products</span>
            </a>
            <span class="tooltip-label" data-i18n="nav.products">Products</span>
        </li>

        <li data-page="request.jsp">
            <a href="#" onclick="loadPage('request.jsp','Requests',this);return false;">
                <span class="menu-icon">📋</span>
                <span class="menu-label" data-i18n="nav.requests">Requests</span>
            </a>
            <span class="tooltip-label" data-i18n="nav.requests">Requests</span>
        </li>

    </ul>

    <div class="logout">
        <a href="#" onclick="showLogoutModal(event)">
            <span class="menu-icon" style="font-size:15px;">🚪</span>
            <span class="logout-text" data-i18n="nav.sign_out">Sign Out</span>
        </a>
        <span class="tooltip-label" data-i18n="nav.sign_out">Sign Out</span>
    </div>
</div>

<!-- ═══════ MAIN CONTENT ═══════ -->
<div class="main-content" id="mainContent">
    <header>
        <div class="title-row">
            <button class="sidebar-toggle" id="sidebarToggle" onclick="toggleSidebar()" title="Toggle menu">
                <span></span><span></span><span></span>
            </button>
            <div class="bank-section">
                <span class="bank-icon">🏪</span>
                <h1 class="bank-title"><%= shopEnName %></h1>
            </div>
        </div>
        <div class="nav-row">
            <!-- Language Toggle -->
            <div class="lang-toggle">
                <button class="lang-btn" id="btnEN" onclick="switchLang('en')">EN</button>
                <button class="lang-btn" id="btnMR" onclick="switchLang('mr')">मर</button>
            </div>
            <div class="current-date" id="currentDate"></div>
            <div class="shop-badge" id="pageTitle">Dashboard</div>
        </div>
    </header>

    <iframe id="contentFrame" frameborder="0" src="index.jsp"></iframe>
</div>

<!-- Logout Modal -->
<div id="logoutModal" class="logout-modal">
    <div class="logout-modal-content">
        <h2 data-i18n="logout.title">Sign Out?</h2>
        <p data-i18n="logout.msg">You'll need to sign in again to access the system.</p>
        <div class="modal-btns">
            <button class="btn-cancel" onclick="closeLogoutModal()" data-i18n="logout.cancel">Cancel</button>
            <button class="btn-confirm" onclick="confirmLogout()" data-i18n="logout.confirm">Yes, Sign Out</button>
        </div>
    </div>
</div>

<!-- i18n for main frame -->
<script src="js/i18n.js"></script>

<script>
// ── Sidebar collapse ──────────────────────────────────────────────────────
var isCollapsed = sessionStorage.getItem('sidebarCollapsed') === 'true';

function applyState() {
    var sidebar = document.getElementById('sidebar');
    sidebar.classList.toggle('collapsed', isCollapsed);
    document.body.classList.toggle('sidebar-collapsed', isCollapsed);
    sessionStorage.setItem('sidebarCollapsed', isCollapsed);
}
function toggleSidebar() { isCollapsed = !isCollapsed; applyState(); }
applyState();

// ── Tooltip positioning ──────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('.menu li, .logout').forEach(function (item) {
        var tip = item.querySelector('.tooltip-label');
        if (!tip) return;
        item.addEventListener('mouseenter', function () {
            if (!isCollapsed) return;
            var r = item.getBoundingClientRect();
            tip.style.top = (r.top + r.height / 2) + 'px';
            tip.style.transform = 'translateY(-50%) translateX(0)';
        });
    });
});

// ── Language toggle ───────────────────────────────────────────────────────
function switchLang(lang) {
    i18n.setLang(lang);
    i18n.apply();            // apply to sidebar / modal
    updateLangButtons();
    // Reload iframe so content page re-applies translations
    var frame = document.getElementById('contentFrame');
    var src = frame.src;
    frame.src = '';
    frame.src = src;
}

function updateLangButtons() {
    var lang = i18n.getLang();
    document.getElementById('btnEN').classList.toggle('active', lang === 'en');
    document.getElementById('btnMR').classList.toggle('active', lang === 'mr');
}

// Initialise button state on load
updateLangButtons();

// ── Page loading ──────────────────────────────────────────────────────────
function loadPage(page, title, el) {
    document.getElementById('contentFrame').src = page;
    document.getElementById('pageTitle').textContent = title;
    sessionStorage.setItem('currentPage',  page);
    sessionStorage.setItem('currentTitle', title);
    document.querySelectorAll('.menu li').forEach(function(li){ li.classList.remove('active'); });
    if (el && el.closest) el.closest('li').classList.add('active');
}
function loadDetailPage(page, title) {
    document.getElementById('contentFrame').src = page;
    document.getElementById('pageTitle').textContent = title;
}
window.updateParentBreadcrumb = function(path, page) {
    document.getElementById('pageTitle').textContent = path;
    sessionStorage.setItem('currentPage',  page);
    sessionStorage.setItem('currentTitle', path);
};

// ── Restore last page ─────────────────────────────────────────────────────
window.onload = function() {
    var savedPage  = sessionStorage.getItem('currentPage');
    var savedTitle = sessionStorage.getItem('currentTitle');
    if (savedPage) {
        document.getElementById('contentFrame').src = savedPage;
        document.getElementById('pageTitle').textContent = savedTitle || '';
        document.querySelectorAll('.menu li').forEach(function(li){
            li.classList.toggle('active', li.dataset.page === savedPage);
        });
    }
    var d = new Date();
    var opts = { weekday:'short', year:'numeric', month:'short', day:'numeric' };
    document.getElementById('currentDate').textContent = d.toLocaleDateString('en-IN', opts);
};

// ── Logout ────────────────────────────────────────────────────────────────
function showLogoutModal(e) { e.preventDefault(); document.getElementById('logoutModal').classList.add('show'); }
function closeLogoutModal() { document.getElementById('logoutModal').classList.remove('show'); }
function confirmLogout()    { sessionStorage.clear(); window.location.href = 'LogoutServlet'; }
window.onclick = function(e) { if (e.target === document.getElementById('logoutModal')) closeLogoutModal(); }
document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeLogoutModal(); });
</script>
</body>
</html>
