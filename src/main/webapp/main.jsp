<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=Please login first");
        return;
    }
    String adminUser = (String) session.getAttribute("admin");
    String fullName  = (String) session.getAttribute("fullName");
    if (fullName == null) fullName = adminUser;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mauali Tredars — Credit Manager</title>
    <link rel="stylesheet" href="css/main.css">
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
                <span class="menu-label">Dashboard</span>
            </a>
            <span class="tooltip-label">Dashboard</span>
        </li>

        <li data-page="add_customer.jsp">
            <a href="#" onclick="loadPage('add_customer.jsp','Add Customer',this);return false;">
                <span class="menu-icon">➕</span>
                <span class="menu-label">Add Customer</span>
            </a>
            <span class="tooltip-label">Add Customer</span>
        </li>

        <li data-page="view_customers.jsp">
            <a href="#" onclick="loadPage('view_customers.jsp','Customers',this);return false;">
                <span class="menu-icon">👥</span>
                <span class="menu-label">Customers</span>
            </a>
            <span class="tooltip-label">Customers</span>
        </li>

        <li data-page="add_dealer.jsp">
            <a href="#" onclick="loadPage('add_dealer.jsp','Add Dealer',this);return false;">
                <span class="menu-icon">🏬</span>
                <span class="menu-label">Add Dealer</span>
            </a>
            <span class="tooltip-label">Add Dealer</span>
        </li>

        <li data-page="view_dealers.jsp">
            <a href="#" onclick="loadPage('view_dealers.jsp','Dealers',this);return false;">
                <span class="menu-icon">📋</span>
                <span class="menu-label">Dealers</span>
            </a>
            <span class="tooltip-label">Dealers</span>
        </li>

        <li data-page="view_products.jsp">
            <a href="#" onclick="loadPage('view_products.jsp','Products',this);return false;">
                <span class="menu-icon">📦</span>
                <span class="menu-label">Products</span>
            </a>
            <span class="tooltip-label">Products</span>
        </li>

    </ul>

    <div class="logout">
        <a href="#" onclick="showLogoutModal(event)">
            <span class="menu-icon" style="font-size:15px;">🚪</span>
            <span class="logout-text">Sign Out</span>
        </a>
        <span class="tooltip-label">Sign Out</span>
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
                <h1 class="bank-title">Mauali Tredars</h1>
            </div>
        </div>
        <div class="nav-row">
            <div class="current-date" id="currentDate"></div>
            <div class="shop-badge" id="pageTitle">Dashboard</div>
        </div>
    </header>

    <iframe id="contentFrame" frameborder="0" src="index.jsp"></iframe>
</div>

<!-- Logout Modal -->
<div id="logoutModal" class="logout-modal">
    <div class="logout-modal-content">
        <h2>Sign Out?</h2>
        <p>You'll need to sign in again to access the system.</p>
        <div class="modal-btns">
            <button class="btn-cancel" onclick="closeLogoutModal()">Cancel</button>
            <button class="btn-confirm" onclick="confirmLogout()">Yes, Sign Out</button>
        </div>
    </div>
</div>

<script>
// ── Sidebar collapse ──
var isCollapsed = sessionStorage.getItem('sidebarCollapsed') === 'true';

function applyState() {
    var sidebar = document.getElementById('sidebar');
    sidebar.classList.toggle('collapsed', isCollapsed);
    document.body.classList.toggle('sidebar-collapsed', isCollapsed);
    sessionStorage.setItem('sidebarCollapsed', isCollapsed);
}
function toggleSidebar() { isCollapsed = !isCollapsed; applyState(); }
applyState();

// ── Tooltip positioning ──
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

// ── Page loading ──
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

// ── Restore last page ──
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
    // Date
    var d = new Date();
    var opts = { weekday:'short', year:'numeric', month:'short', day:'numeric' };
    document.getElementById('currentDate').textContent = d.toLocaleDateString('en-IN', opts);
};

// ── Logout ──
function showLogoutModal(e) { e.preventDefault(); document.getElementById('logoutModal').classList.add('show'); }
function closeLogoutModal() { document.getElementById('logoutModal').classList.remove('show'); }
function confirmLogout()    { sessionStorage.clear(); window.location.href = 'LogoutServlet'; }
window.onclick = function(e) { if (e.target === document.getElementById('logoutModal')) closeLogoutModal(); };
document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeLogoutModal(); });
</script>
</body>
</html>
