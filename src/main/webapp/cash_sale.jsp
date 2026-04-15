<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, doa.DBConnection, doa.ShopConfig, java.time.LocalDateTime, java.time.format.DateTimeFormatter" %>
<%
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=Please login first");
        return;
    }

    ShopConfig shop = ShopConfig.getInstance();
    String shopEnglishName = shop.getEnglishName();
    String shopMarathiName = shop.getMarathiName();

    String idStr     = request.getParameter("id");
    int    preselect = -1;
    if (idStr != null && !idStr.trim().isEmpty()) {
        try { preselect = Integer.parseInt(idStr.trim()); } catch (NumberFormatException ignored) {}
    }

    String preselectedName  = "";
    String preselectedPhone = "";
    double preselectedCredit = 0;
    boolean hasPreselected = false;

    if (preselect > 0) {
        try (Connection conn = DBConnection.getConnection()) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT name, NVL(marathi_name,'') AS marathi_name, phone, credit FROM customers WHERE id = ?");
            ps.setInt(1, preselect);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                hasPreselected    = true;
                preselectedName   = rs.getString("name");
                preselectedPhone  = rs.getString("phone");
                preselectedCredit = rs.getDouble("credit");
            }
        } catch (Exception e) { /* ignore */ }
    }

    StringBuilder customersJson = new StringBuilder("[");
    try (Connection conn = DBConnection.getConnection()) {
        ResultSet crs = conn.createStatement().executeQuery(
            "SELECT id, name, NVL(marathi_name,'') AS marathi_name, phone, credit " +
            "FROM customers ORDER BY name ASC");
        boolean first = true;
        while (crs.next()) {
            if (!first) customersJson.append(",");
            first = false;
            String nm  = crs.getString("name").replace("\"","\\\"");
            String mrn = crs.getString("marathi_name").replace("\"","\\\"");
            customersJson.append("{")
                .append("\"id\":").append(crs.getInt("id")).append(",")
                .append("\"name\":\"").append(nm).append("\",")
                .append("\"marathiName\":\"").append(mrn).append("\",")
                .append("\"phone\":\"").append(crs.getString("phone")).append("\",")
                .append("\"credit\":").append(crs.getDouble("credit"))
                .append("}");
        }
    } catch (Exception e) { /* ignore */ }
    customersJson.append("]");

    StringBuilder productsJson = new StringBuilder("[");
    try (Connection conn = DBConnection.getConnection()) {
        ResultSet prs = conn.createStatement().executeQuery(
            "SELECT id, product_name, quantity FROM products ORDER BY product_name ASC");
        boolean first = true;
        while (prs.next()) {
            if (!first) productsJson.append(",");
            first = false;
            productsJson.append("{")
                .append("\"id\":").append(prs.getInt("id")).append(",")
                .append("\"name\":\"").append(prs.getString("product_name").replace("\"","\\\"")).append("\",")
                .append("\"stock\":").append(prs.getInt("quantity"))
                .append("}");
        }
    } catch (Exception e) { /* ignore */ }
    productsJson.append("]");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Cash Sale</title>
    <link rel="stylesheet" href="css/content.css">
    <style>
        .sale-header {
            background: linear-gradient(135deg, #f97316 0%, #fb923c 100%);
            color: #fff; border-radius: 14px; padding: 18px 24px;
            margin-bottom: 22px; display: flex; align-items: center;
            gap: 16px; flex-wrap: wrap;
            box-shadow: 0 6px 20px rgba(0,0,0,0.15);
        }
        .sale-header .sh-icon { font-size: 36px; }
        .sale-header h2 { font-size: 18px; font-weight: 800; margin: 0 0 3px; }
        .sale-header p  { font-size: 12px; color: rgba(255,255,255,0.75); margin: 0; }

        .cust-mode-row { display: flex; gap: 12px; margin-bottom: 16px; flex-wrap: wrap; }
        .cust-mode-btn {
            flex: 1; min-width: 200px; padding: 14px 20px;
            border-radius: 12px; border: 2px solid transparent;
            cursor: pointer; display: flex; align-items: center; gap: 12px;
            font-family: 'Outfit', sans-serif; font-size: 14px; font-weight: 700;
            transition: all 0.2s; background: #fff;
            box-shadow: 0 2px 8px rgba(0,0,0,0.07);
        }
        .cust-mode-btn .cmb-icon { width:42px; height:42px; border-radius:10px; display:flex; align-items:center; justify-content:center; font-size:20px; flex-shrink:0; }
        .cust-mode-btn .cmb-text { display:flex; flex-direction:column; gap:2px; }
        .cust-mode-btn .cmb-title { font-size:14px; font-weight:700; }
        .cust-mode-btn .cmb-sub   { font-size:11px; font-weight:500; opacity:0.65; }
        .cust-mode-btn.mode-existing { color:#065f46; border-color:#d1fae5; }
        .cust-mode-btn.mode-existing .cmb-icon { background:#d1fae5; }
        .cust-mode-btn.mode-existing.active,
        .cust-mode-btn.mode-existing:hover { border-color:#059669; background:linear-gradient(135deg,#ecfdf5,#d1fae5); box-shadow:0 4px 16px rgba(5,150,105,0.15); }
        .cust-mode-btn.mode-new { color:#1e40af; border-color:#dbeafe; }
        .cust-mode-btn.mode-new .cmb-icon { background:#dbeafe; }
        .cust-mode-btn.mode-new.active,
        .cust-mode-btn.mode-new:hover { border-color:#2563eb; background:linear-gradient(135deg,#eff6ff,#dbeafe); box-shadow:0 4px 16px rgba(37,99,235,0.15); }

        .cust-select-card {
            background:#fff; border-radius:14px; box-shadow:0 4px 16px rgba(0,0,0,0.08);
            padding:18px 20px; margin-bottom:20px;
            display:flex; align-items:flex-end; gap:16px; flex-wrap:wrap;
            border:2px solid #d1fae5; animation:fadeIn 0.25s ease;
        }
        .cust-select-card .csg { display:flex; flex-direction:column; gap:5px; flex:1; min-width:220px; }
        .cust-select-card label { font-size:12px; font-weight:700; color:#065f46; letter-spacing:0.3px; }
        .cust-select-card select { padding:10px 12px; border:2px solid #6ee7b7; border-radius:9px; font-size:13px; color:#1a1a2a; outline:none; transition:border 0.2s; background:#fff; font-family:'Outfit',sans-serif; }
        .cust-select-card select:focus { border-color:#059669; box-shadow:0 0 0 3px rgba(5,150,105,0.1); }

        .new-cust-card { background:linear-gradient(135deg,#eff6ff 0%,#dbeafe 100%); border:2px solid #bfdbfe; border-radius:14px; padding:24px 26px; margin-bottom:20px; display:flex; align-items:center; gap:20px; flex-wrap:wrap; animation:fadeIn 0.25s ease; }
        .new-cust-card .ncc-icon { width:56px; height:56px; background:#2563eb; border-radius:14px; display:flex; align-items:center; justify-content:center; font-size:26px; flex-shrink:0; box-shadow:0 4px 12px rgba(37,99,235,0.3); }
        .new-cust-card .ncc-text { flex:1; }
        .new-cust-card .ncc-text h3 { font-size:16px; font-weight:800; color:#1e40af; margin:0 0 4px; }
        .new-cust-card .ncc-text p  { font-size:13px; color:#3b82f6; margin:0; }
        .btn-create-customer { padding:12px 26px; background:linear-gradient(135deg,#2563eb,#1d4ed8); color:#fff; border:none; border-radius:10px; font-family:'Outfit',sans-serif; font-size:14px; font-weight:700; cursor:pointer; white-space:nowrap; text-decoration:none; display:inline-flex; align-items:center; gap:8px; box-shadow:0 4px 16px rgba(37,99,235,0.3); transition:all 0.2s; }
        .btn-create-customer:hover { transform:translateY(-2px); box-shadow:0 8px 24px rgba(37,99,235,0.4); }

        .preselected-banner { background:linear-gradient(135deg,#059669 0%,#10b981 100%); color:#fff; border-radius:14px; padding:16px 22px; margin-bottom:20px; display:flex; align-items:center; gap:16px; flex-wrap:wrap; box-shadow:0 4px 16px rgba(5,150,105,0.25); animation:fadeIn 0.3s ease; }
        .preselected-banner .pb-avatar { width:48px; height:48px; background:rgba(255,255,255,0.2); border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:22px; flex-shrink:0; border:2px solid rgba(255,255,255,0.35); }
        .preselected-banner .pb-info { flex:1; }
        .preselected-banner .pb-info h3 { font-size:16px; font-weight:700; margin:0 0 3px; }
        .preselected-banner .pb-info p  { font-size:12px; color:rgba(255,255,255,0.75); margin:0; }
        .preselected-banner .pb-credit { background:rgba(255,255,255,0.15); border:1px solid rgba(255,255,255,0.25); border-radius:10px; padding:8px 16px; text-align:center; flex-shrink:0; }
        .preselected-banner .pb-credit .lbl { font-size:10px; color:rgba(255,255,255,0.65); text-transform:uppercase; letter-spacing:0.8px; }
        .preselected-banner .pb-credit .val { font-size:17px; font-weight:800; color:#d1fae5; margin-top:2px; }
        .btn-change-cust { padding:8px 16px; background:rgba(255,255,255,0.15); border:1px solid rgba(255,255,255,0.3); color:#fff; border-radius:8px; font-family:'Outfit',sans-serif; font-size:12px; font-weight:700; cursor:pointer; transition:background 0.2s; white-space:nowrap; flex-shrink:0; }
        .btn-change-cust:hover { background:rgba(255,255,255,0.28); }

        .cust-pill { display:none; background:linear-gradient(135deg,#f97316 0%,#fb923c 100%); color:#fff; border-radius:10px; padding:10px 18px; font-size:13px; font-weight:700; flex-shrink:0; }
        .cust-pill .cp-credit { font-size:11px; color:rgba(255,255,255,0.7); margin-top:2px; }

        .main-layout { display:grid; grid-template-columns:320px 1fr; gap:20px; align-items:start; }
        @media (max-width:860px) { .main-layout { grid-template-columns:1fr; } }

        .input-panel { background:#fff; border-radius:14px; box-shadow:0 4px 16px rgba(0,0,0,0.08); overflow:hidden; position:sticky; top:10px; }
        .input-panel-header { background:linear-gradient(135deg,#f97316 0%,#fb923c 100%); color:#fff; padding:13px 18px; font-size:13px; font-weight:700; }
        .input-panel-body { padding:18px; display:flex; flex-direction:column; gap:14px; }
        .ip-group { display:flex; flex-direction:column; gap:5px; }
        .ip-group label { font-size:12px; font-weight:700; color:#065f46; }
        .ip-group select, .ip-group input { padding:9px 11px; border:2px solid #6ee7b7; border-radius:8px; font-size:13px; color:#1a1a2a; background:#fff; outline:none; transition:border 0.2s; width:100%; -moz-appearance:textfield; font-family:'Outfit',sans-serif; }
        .ip-group select:focus, .ip-group input:focus { border-color:#059669; box-shadow:0 0 0 3px rgba(5,150,105,0.1); }
        .ip-group input::-webkit-inner-spin-button, .ip-group input::-webkit-outer-spin-button { -webkit-appearance:none; }

        .stock-strip { display:none; align-items:center; gap:8px; background:#ecfdf5; border:1px solid #6ee7b7; border-radius:7px; padding:6px 12px; font-size:12px; color:#065f46; font-weight:600; margin-top:4px; }
        .stock-strip .snum { background:#059669; color:#fff; border-radius:20px; padding:1px 10px; font-size:12px; font-weight:700; }
        .stock-strip.low  { background:#fff8e1; border-color:#fde68a; color:#92400e; }
        .stock-strip.low  .snum { background:#f59e0b; }
        .stock-strip.zero { background:#fef2f2; border-color:#fecaca; color:#991b1b; }
        .stock-strip.zero .snum { background:#dc2626; }

        .row-preview { background:#ecfdf5; border:1px dashed #6ee7b7; border-radius:8px; padding:9px 14px; font-size:13px; color:#065f46; font-weight:700; text-align:center; display:none; }
        .btn-add-to-table { width:100%; padding:11px; background:linear-gradient(135deg,#f97316 0%,#fb923c 100%); color:#fff; border:none; border-radius:9px; font-size:14px; font-weight:700; cursor:pointer; transition:opacity 0.2s,transform 0.15s; }
        .btn-add-to-table:hover { opacity:0.88; transform:scale(1.02); }

        .pay-mode-row { display:flex; gap:10px; }
        .pay-opt { flex:1; position:relative; }
        .pay-opt input[type="radio"] { position:absolute; opacity:0; width:0; height:0; }
        .pay-opt label { display:flex; align-items:center; justify-content:center; gap:7px; padding:10px 14px; border:2px solid #d1fae5; border-radius:9px; background:#f0fdf4; cursor:pointer; font-size:13px; font-weight:700; color:#065f46; transition:all 0.18s; }
        .pay-opt input[type="radio"]:checked + label { border-color:#6ee7b7; background:linear-gradient(135deg,#f97316 0%,#fb923c 100%); color:#fff; box-shadow:0 3px 12px rgba(5,150,105,0.25); }
        .pay-opt label:hover { border-color:#6ee7b7; }

        .table-panel { background:#fff; border-radius:14px; box-shadow:0 4px 16px rgba(0,0,0,0.08); overflow:hidden; }
        .table-panel-header { background:linear-gradient(135deg,#f97316 0%,#fb923c 100%); color:#fff; padding:13px 18px; font-size:13px; font-weight:700; display:flex; align-items:center; justify-content:space-between; }
        .txn-table { width:100%; border-collapse:collapse; font-size:13px; }
        .txn-table thead th { background:#f0fdf4; color:#065f46; padding:10px 12px; text-align:center; font-weight:700; font-size:12px; border-bottom:2px solid #6ee7b7; }
        .txn-table tbody td { padding:9px 11px; border-bottom:1px solid #ecfdf5; text-align:center; vertical-align:middle; }
        .txn-table tbody tr:last-child td { border-bottom:none; }
        .txn-table tbody tr:hover { background:#f0fdf4; }
        .txn-table tfoot td { padding:12px 14px; background:orange; color:#fff; font-weight:700; font-size:14px; text-align:right; }
        .txn-table tfoot td.grand-val { text-align:center; font-size:16px; color:#fff; }
        .empty-msg td { padding:32px !important; color:#bbb; font-size:13px; font-style:italic; text-align:center !important; }
        .btn-remove { width:26px; height:26px; background:#fee2e2; color:#dc2626; border:none; border-radius:5px; font-size:14px; font-weight:700; cursor:pointer; display:inline-flex; align-items:center; justify-content:center; transition:background 0.2s; }
        .btn-remove:hover { background:#dc2626; color:#fff; }
        .prod-tag { background:#ecfdf5; color:#065f46; padding:3px 10px; border-radius:20px; font-size:12px; font-weight:600; }
        .qty-num  { font-weight:700; color:#065f46; }
        .price-num { color:#555; }
        .total-num { font-weight:700; color:#065f46; }

        .grand-bar { display:flex; align-items:center; justify-content:space-between; background:linear-gradient(135deg,#f97316 0%,#fb923c 100%); color:#fff; border-radius:10px; padding:13px 20px; margin-top:16px; }
        .grand-bar .g-label { font-size:13px; color:rgba(255,255,255,0.7); font-weight:600; }
        .grand-bar .g-val   { font-size:22px; font-weight:800; }
        .grand-bar .g-count { font-size:11px; color:rgba(255,255,255,0.6); margin-top:1px; }
        .save-row { display:flex; gap:14px; margin-top:16px; justify-content:flex-end; }

        .badge-cash-sale { display:inline-flex; align-items:center; gap:4px; background:rgba(255,255,255,0.15); padding:3px 10px; border-radius:20px; font-size:11px; font-weight:700; }
        .panel-locked { opacity:0.45; pointer-events:none; }

        /* ── Receipt Modal ── */
        .receipt-modal { display:none; position:fixed; z-index:1000; inset:0; background:rgba(0,0,0,0.55); backdrop-filter:blur(5px); align-items:center; justify-content:center; padding:20px; }
        .receipt-modal.show { display:flex; animation:fadeIn 0.2s; }
        .receipt-modal-content { background:#fff; border-radius:16px; width:100%; max-width:520px; max-height:82vh; overflow-y:auto; box-shadow:0 20px 60px rgba(0,0,0,0.3); animation:slideUp 0.3s cubic-bezier(0.22,1,0.36,1); }
        .receipt-header { background:linear-gradient(135deg,#c2730a 0%,#f97316 100%); color:#fff; padding:20px; text-align:center; border-bottom:3px dashed rgba(255,255,255,0.25); }
        .receipt-header h2 { margin:0 0 4px; font-size:18px; font-weight:800; letter-spacing:1px; }
        .receipt-header .shop-name-r { font-size:14px; font-weight:700; color:rgba(255,255,255,0.85); }
        .receipt-body { padding:20px; }
        .receipt-info-box { display:grid; grid-template-columns:1fr 1fr; gap:6px 16px; background:#fff8f0; border:1px solid #f5c89a; border-radius:8px; padding:12px 14px; margin-bottom:14px; }
        .receipt-info-item { display:flex; flex-direction:column; gap:2px; }
        .receipt-info-label { font-size:9px; font-weight:700; color:#94a3b8; text-transform:uppercase; letter-spacing:0.8px; }
        .receipt-info-value { font-size:13px; font-weight:700; color:#0d1b2a; }
        .receipt-table { width:100%; border-collapse:collapse; font-size:12px; margin:12px 0; }
        .receipt-table thead th { background:#c2730a; color:#fff; padding:7px 10px; text-align:left; font-size:10px; text-transform:uppercase; letter-spacing:0.5px; }
        .receipt-table thead th:last-child, .receipt-table thead th:nth-child(3) { text-align:right; }
        .receipt-table thead th:nth-child(2) { text-align:center; }
        .receipt-table tbody td { padding:7px 10px; border-bottom:1px solid #f0e0d0; vertical-align:middle; }
        .receipt-table tbody td:nth-child(2) { text-align:center; }
        .receipt-table tbody td:nth-child(3), .receipt-table tbody td:last-child { text-align:right; }
        .receipt-table tfoot td { background:#c2730a; color:#fff; font-weight:800; padding:9px 10px; }
        .receipt-table tfoot td:last-child { text-align:right; font-size:15px; }
        .receipt-table tfoot td:first-child { text-align:right; font-size:12px; letter-spacing:0.5px; }
        .receipt-footer-msg { text-align:center; font-size:12px; color:#888; padding:10px 0 4px; border-top:1px dashed #e0d0c0; margin-top:8px; }
        .receipt-actions { display:flex; gap:10px; padding:14px 20px; border-top:1px solid #e0e0e0; background:#f9f9f9; border-radius:0 0 16px 16px; }
        .btn-receipt-action { flex:1; padding:11px; border:none; border-radius:8px; font-family:'Outfit',sans-serif; font-size:13px; font-weight:700; cursor:pointer; transition:all 0.2s; white-space:nowrap; }
        .btn-receipt-print { background:linear-gradient(135deg,#c2730a,#f97316); color:#fff; box-shadow:0 3px 12px rgba(194,115,10,0.3); }
        .btn-receipt-print:hover { transform:translateY(-2px); box-shadow:0 5px 18px rgba(194,115,10,0.4); }
        .btn-receipt-skip { background:transparent; color:#666; border:2px solid #ddd; }
        .btn-receipt-skip:hover { background:#f0f0f0; }

        @keyframes fadeIn  { from{opacity:0;} to{opacity:1;} }
        @keyframes slideUp { from{transform:translateY(32px) scale(0.98);opacity:0;} to{transform:translateY(0) scale(1);opacity:1;} }
    </style>
</head>
<body>
<div class="content-wrapper">

    <% if (request.getParameter("error") != null) { %>
    <div class="alert alert-error">❌ <%= request.getParameter("error") %></div>
    <% } %>

    <!-- Page Banner -->
    <div class="sale-header">
        <div class="sh-icon">💵</div>
        <div>
            <h2 data-i18n="nav.cash">Cash Sale</h2>
            <p>
                <span class="lang-name-en">Record an immediate cash / online payment sale — no credit added to the account.</span>
                <span class="lang-name-mr" style="display:none;">त्वरित रोख / ऑनलाइन विक्री नोंदवा — खात्यावर उधार जोडली जाणार नाही.</span>
            </p>
        </div>
        <span class="badge-cash-sale" style="margin-left:auto;">🟢 CASH SALE</span>
    </div>

    <!-- ══ CUSTOMER SECTION ══ -->
    <% if (hasPreselected) { %>
    <div class="preselected-banner" id="preselectedBanner">
        <div class="pb-avatar">👤</div>
        <div class="pb-info">
            <h3><%= preselectedName %></h3>
            <p>📞 <%= preselectedPhone %> &nbsp;·&nbsp; Customer ID #<%= preselect %></p>
        </div>
        <div class="pb-credit">
            <div class="lbl"><span class="lang-name-en">Current Credit</span><span class="lang-name-mr" style="display:none;">सध्याची उधार</span></div>
            <div class="val">₹ <%= String.format("%.2f", preselectedCredit) %></div>
        </div>
        <button class="btn-change-cust" onclick="showModeSelector()">
            🔄 <span class="lang-name-en">Change</span><span class="lang-name-mr" style="display:none;">बदला</span>
        </button>
    </div>
    <input type="hidden" id="fixedCustomerId" value="<%= preselect %>">

    <% } else { %>
    <div id="modeSelectorArea">
        <div class="cust-mode-row">
            <button class="cust-mode-btn mode-existing" id="btnModeExisting" onclick="setMode('existing')">
                <div class="cmb-icon">👥</div>
                <div class="cmb-text">
                    <span class="cmb-title lang-name-en">Existing Customer</span>
                    <span class="cmb-title lang-name-mr" style="display:none;">नोंदणीकृत ग्राहक</span>
                    <span class="cmb-sub lang-name-en">Select from your customer list</span>
                    <span class="cmb-sub lang-name-mr" style="display:none;">ग्राहक यादीतून निवडा</span>
                </div>
            </button>
            <button class="cust-mode-btn mode-new" id="btnModeNew" onclick="setMode('new')">
                <div class="cmb-icon">➕</div>
                <div class="cmb-text">
                    <span class="cmb-title lang-name-en">New Customer</span>
                    <span class="cmb-title lang-name-mr" style="display:none;">नवीन ग्राहक</span>
                    <span class="cmb-sub lang-name-en">Customer not registered yet</span>
                    <span class="cmb-sub lang-name-mr" style="display:none;">ग्राहक अद्याप नोंदणीकृत नाही</span>
                </div>
            </button>
        </div>

        <div class="cust-select-card" id="existingCustPanel" style="display:none;">
            <div class="csg">
                <label for="custSelect">
                    👤 <span class="lang-name-en">Select Customer</span>
                    <span class="lang-name-mr" style="display:none;">ग्राहक निवडा</span>
                    <span style="color:#dc2626;">*</span>
                </label>
                <select id="custSelect" onchange="onCustChange()">
                    <option value="" disabled selected id="custPlaceholder">— Select customer —</option>
                </select>
            </div>
            <div class="cust-pill" id="custPill">
                <div id="custPillName">—</div>
                <div class="cp-credit" id="custPillCredit"></div>
            </div>
        </div>

        <div class="new-cust-card" id="newCustPanel" style="display:none;">
            <div class="ncc-icon">👤</div>
            <div class="ncc-text">
                <h3><span class="lang-name-en">Customer not registered?</span><span class="lang-name-mr" style="display:none;">ग्राहक नोंदणीकृत नाही?</span></h3>
                <p><span class="lang-name-en">Create a new customer account first, then come back to record the sale.</span><span class="lang-name-mr" style="display:none;">प्रथम नवीन ग्राहक खाते तयार करा, नंतर विक्री नोंद करण्यासाठी परत या.</span></p>
            </div>
            <a href="add_customer.jsp" class="btn-create-customer">➕ <span class="lang-name-en">Create Customer</span><span class="lang-name-mr" style="display:none;">ग्राहक तयार करा</span></a>
        </div>
    </div>
    <% } %>

    <!-- ══ PRODUCT + TABLE SECTION ══ -->
    <div id="saleSection" class="<%= hasPreselected ? "" : "panel-locked" %>">
        <div class="main-layout">

            <!-- LEFT: Input Panel -->
            <div class="input-panel">
                <div class="input-panel-header">🛒 <span class="lang-name-en">Add Product</span><span class="lang-name-mr" style="display:none;">उत्पाद जोडा</span></div>
                <div class="input-panel-body">
                    <div class="ip-group">
                        <label for="productId">📦 <span class="lang-name-en">Product</span><span class="lang-name-mr" style="display:none;">उत्पाद</span> <span style="color:#dc2626;">*</span></label>
                        <select id="productId" onchange="onProductChange()">
                            <option value="" disabled selected id="prodPlaceholder">— Select product —</option>
                        </select>
                        <div class="stock-strip" id="stockStrip">
                            <span class="lang-name-en">Available:</span><span class="lang-name-mr" style="display:none;">उपलब्ध:</span>
                            <span class="snum" id="stockNum">0</span>
                        </div>
                    </div>
                    <div class="ip-group">
                        <label for="qty">🔢 <span class="lang-name-en">Quantity</span><span class="lang-name-mr" style="display:none;">प्रमाण</span> <span style="color:#dc2626;">*</span></label>
                        <input type="number" id="qty" placeholder="0" min="1"
                               oninput="updatePreview()" onchange="updatePreview()">
                    </div>
                    <div class="ip-group">
                        <label for="unitPrice">💰 <span class="lang-name-en">Price / Unit (₹)</span><span class="lang-name-mr" style="display:none;">किंमत / नग (₹)</span> <span style="color:#dc2626;">*</span></label>
                        <input type="number" id="unitPrice" placeholder="0.00" step="0.01" min="0.01"
                               oninput="updatePreview()" onchange="updatePreview()">
                    </div>
                    <div class="row-preview" id="rowPreview">Row Total: ₹ 0.00</div>
                    <div class="ip-group">
                        <label>💳 <span class="lang-name-en">Payment Mode</span><span class="lang-name-mr" style="display:none;">देयक पद्धत</span></label>
                        <div class="pay-mode-row">
                            <div class="pay-opt">
                                <input type="radio" id="modeCash" name="payMode" value="CASH" checked>
                                <label for="modeCash">💵 <span class="lang-name-en">Cash</span><span class="lang-name-mr" style="display:none;">रोख</span></label>
                            </div>
                            <div class="pay-opt">
                                <input type="radio" id="modeOnline" name="payMode" value="ONLINE">
                                <label for="modeOnline">📱 <span class="lang-name-en">Online</span><span class="lang-name-mr" style="display:none;">ऑनलाइन</span></label>
                            </div>
                        </div>
                    </div>
                    <button type="button" class="btn-add-to-table" onclick="addToTable()">
                        ➕ <span class="lang-name-en">Add to Sale</span><span class="lang-name-mr" style="display:none;">विक्रीत जोडा</span>
                    </button>
                </div>
            </div>

            <!-- RIGHT: Table -->
            <div>
                <div class="table-panel">
                    <div class="table-panel-header">
                        <span>🧾 <span class="lang-name-en">Sale Items</span><span class="lang-name-mr" style="display:none;">विक्री यादी</span></span>
                        <span id="itemCountBadge" style="background:rgba(255,255,255,0.15);border-radius:20px;padding:2px 12px;font-size:12px;">0 items</span>
                    </div>
                    <table class="txn-table">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th><span class="lang-name-en">Product</span><span class="lang-name-mr" style="display:none;">उत्पाद</span></th>
                                <th><span class="lang-name-en">Qty</span><span class="lang-name-mr" style="display:none;">प्रमाण</span></th>
                                <th><span class="lang-name-en">Price/Unit (₹)</span><span class="lang-name-mr" style="display:none;">किंमत/नग (₹)</span></th>
                                <th><span class="lang-name-en">Total (₹)</span><span class="lang-name-mr" style="display:none;">एकूण (₹)</span></th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody id="txnBody">
                            <tr class="empty-msg">
                                <td colspan="6">
                                    <span class="lang-name-en">← Add products using the form on the left</span>
                                    <span class="lang-name-mr" style="display:none;">← डाव्या बाजूच्या फॉर्मचा वापर करून उत्पादे जोडा</span>
                                </td>
                            </tr>
                        </tbody>
                        <tfoot>
                            <tr>
                                <td colspan="4" style="text-align:right;"><span class="lang-name-en">Grand Total</span><span class="lang-name-mr" style="display:none;">एकूण</span></td>
                                <td class="grand-val" id="footerGrand">₹ 0.00</td>
                                <td></td>
                            </tr>
                        </tfoot>
                    </table>
                </div>

                <div class="grand-bar">
                    <div>
                        <div class="g-label"><span class="lang-name-en">TOTAL SALE AMOUNT</span><span class="lang-name-mr" style="display:none;">एकूण विक्री रक्कम</span></div>
                        <div class="g-val" id="grandDisplay">₹ 0.00</div>
                        <div class="g-count" id="grandCount">0 item(s)</div>
                    </div>
                    <span style="font-size:32px;">💵</span>
                </div>

                <div class="save-row">
                    <a href="view_customers.jsp" class="btn-clear"
                       style="text-decoration:none;display:inline-flex;align-items:center;justify-content:center;padding:10px 28px;">
                        <span class="lang-name-en">Cancel</span><span class="lang-name-mr" style="display:none;">रद्द करा</span>
                    </a>
                    <button type="button" class="btn-save"
                            style="background:linear-gradient(135deg,#f97316 0%,#fb923c 100%);box-shadow:0 4px 16px rgba(249,115,22,0.3);"
                            onclick="submitSaleWithReceipt()">
                        💾 <span class="lang-name-en">Save &amp; View Receipt</span><span class="lang-name-mr" style="display:none;">जतन करा आणि पावती पहा</span>
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- ══ RECEIPT PREVIEW MODAL ══ -->
    <div class="receipt-modal" id="receiptModal">
        <div class="receipt-modal-content">

            <div class="receipt-header">
                <h2>🧾 <span class="lang-name-en">RECEIPT</span><span class="lang-name-mr" style="display:none;">पावती</span></h2>
                <div class="shop-name-r" id="receiptShopName"></div>
            </div>

            <div class="receipt-body">
                <!-- Info Box -->
                <div class="receipt-info-box">
                    <div class="receipt-info-item">
                        <span class="receipt-info-label"><span class="lang-name-en">Customer</span><span class="lang-name-mr" style="display:none;">ग्राहक</span></span>
                        <span class="receipt-info-value" id="receiptCustomer">—</span>
                    </div>
                    <div class="receipt-info-item">
                        <span class="receipt-info-label"><span class="lang-name-en">Payment Mode</span><span class="lang-name-mr" style="display:none;">देयक पद्धत</span></span>
                        <span class="receipt-info-value" id="receiptPayMode">—</span>
                    </div>
                    <div class="receipt-info-item" style="grid-column:span 2;">
                        <span class="receipt-info-label"><span class="lang-name-en">Date &amp; Time</span><span class="lang-name-mr" style="display:none;">दिनांक व वेळ</span></span>
                        <span class="receipt-info-value" id="receiptDateTime">—</span>
                    </div>
                </div>

                <!-- Items Table -->
                <table class="receipt-table">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th style="text-align:left;"><span class="lang-name-en">Product</span><span class="lang-name-mr" style="display:none;">उत्पाद</span></th>
                            <th><span class="lang-name-en">Qty</span><span class="lang-name-mr" style="display:none;">प्रमाण</span></th>
                            <th><span class="lang-name-en">Rate</span><span class="lang-name-mr" style="display:none;">दर</span></th>
                            <th><span class="lang-name-en">Total</span><span class="lang-name-mr" style="display:none;">एकूण</span></th>
                        </tr>
                    </thead>
                    <tbody id="receiptItems"></tbody>
                    <tfoot>
                        <tr>
                            <td colspan="4" style="text-align:right;letter-spacing:0.5px;">
                                <span class="lang-name-en">GRAND TOTAL</span>
                                <span class="lang-name-mr" style="display:none;">एकूण रक्कम</span>
                            </td>
                            <td id="receiptGrandTotal">₹ 0.00</td>
                        </tr>
                    </tfoot>
                </table>

                <div class="receipt-footer-msg">
                    <span class="lang-name-en">Thank you for your purchase! 🙏</span>
                    <span class="lang-name-mr" style="display:none;">खरेदीसाठी धन्यवाद! 🙏</span>
                </div>
            </div>

            <div class="receipt-actions">
                <button class="btn-receipt-action btn-receipt-print" onclick="printReceipt()">
                    🖨️ <span class="lang-name-en">Print Receipt</span><span class="lang-name-mr" style="display:none;">पावती छापा</span>
                </button>
                <button class="btn-receipt-action btn-receipt-skip" onclick="skipPrintAndSave()">
                    <span class="lang-name-en">Skip &amp; Save</span><span class="lang-name-mr" style="display:none;">वगळून जतन करा</span>
                </button>
            </div>
        </div>
    </div>

    <!-- Hidden Submit Form -->
    <form id="submitForm" action="CashSaleServlet" method="post" style="display:none;">
        <input type="hidden" name="customerId"  id="customerIdInput">
        <input type="hidden" name="itemsJson"   id="itemsJsonInput">
        <input type="hidden" name="paymentMode" id="paymentModeInput">
    </form>
</div>

<script src="js/i18n.js"></script>
<script>
var CUSTOMERS  = <%= customersJson.toString() %>;
var PRODUCTS   = <%= productsJson.toString() %>;
var PRESELECT  = <%= preselect %>;
var HAS_PRESELECTED = <%= hasPreselected ? "true" : "false" %>;
var SHOP_NAME  = "<%= shopEnglishName.replace("\"","\\\"") %>";
var SHOP_NAME_MR = "<%= shopMarathiName.replace("\"","\\\"") %>";

var tableRows  = [];
var rowSeq     = 0;
var currentMode = '';
var pendingSubmitData = null;

function getLang() { return (typeof i18n !== 'undefined') ? i18n.getLang() : 'en'; }
function isMr()    { return getLang() === 'mr'; }

/* ── Populate dropdowns ── */
(function () {
    var ps  = document.getElementById('productId');
    var pph = document.getElementById('prodPlaceholder');
    if (pph) pph.text = isMr() ? '— उत्पाद निवडा —' : '— Select product —';
    PRODUCTS.forEach(function (p) {
        var opt = document.createElement('option');
        opt.value = p.id;
        opt.text  = p.name + (isMr() ? '  (स्टॉक: ' + p.stock + ')' : '  (Stock: ' + p.stock + ')');
        opt.setAttribute('data-stock', p.stock);
        opt.setAttribute('data-name',  p.name);
        ps.appendChild(opt);
    });

    var cs = document.getElementById('custSelect');
    if (cs) {
        var cph = document.getElementById('custPlaceholder');
        if (cph) cph.text = isMr() ? '— ग्राहक निवडा —' : '— Select customer —';
        CUSTOMERS.forEach(function (c) {
            var opt = document.createElement('option');
            opt.value = c.id;
            opt.text  = c.name + ' (📞 ' + c.phone + ')';
            opt.setAttribute('data-name',    c.name);
            opt.setAttribute('data-mr-name', c.marathiName || c.name);
            opt.setAttribute('data-phone',   c.phone);
            opt.setAttribute('data-credit',  c.credit);
            cs.appendChild(opt);
        });
        if (PRESELECT > 0 && !HAS_PRESELECTED) {
            cs.value = PRESELECT;
            onCustChange();
        }
    }
})();

/* ── Mode Selector ── */
function setMode(mode) {
    currentMode = mode;
    var btnEx   = document.getElementById('btnModeExisting');
    var btnNew  = document.getElementById('btnModeNew');
    var exPanel = document.getElementById('existingCustPanel');
    var newPanel= document.getElementById('newCustPanel');
    var saleSec = document.getElementById('saleSection');
    if (btnEx)   btnEx.classList.toggle('active',  mode === 'existing');
    if (btnNew)  btnNew.classList.toggle('active',  mode === 'new');
    if (exPanel) exPanel.style.display  = (mode === 'existing') ? 'flex' : 'none';
    if (newPanel)newPanel.style.display = (mode === 'new')      ? 'flex' : 'none';
    if (saleSec) saleSec.classList.toggle('panel-locked', mode !== 'existing');
    if (mode === 'existing') {
        var cs = document.getElementById('custSelect');
        if (cs) cs.value = '';
        document.getElementById('custPill').style.display = 'none';
        document.getElementById('saleSection').classList.add('panel-locked');
    }
}

function showModeSelector() { window.location.href = 'cash_sale.jsp'; }

/* ── Customer change ── */
function onCustChange() {
    var sel  = document.getElementById('custSelect');
    if (!sel) return;
    var pill = document.getElementById('custPill');
    var cid  = sel.value;
    var saleSec = document.getElementById('saleSection');
    if (!cid) {
        if (pill) pill.style.display = 'none';
        if (saleSec) saleSec.classList.add('panel-locked');
        return;
    }
    var opt    = sel.options[sel.selectedIndex];
    var mr     = isMr();
    var name   = mr ? opt.getAttribute('data-mr-name') : opt.getAttribute('data-name');
    var credit = parseFloat(opt.getAttribute('data-credit') || 0);
    document.getElementById('custPillName').textContent   = '👤 ' + name;
    document.getElementById('custPillCredit').textContent =
        (mr ? 'सध्याची उधार: ₹ ' : 'Current Credit: ₹ ') + credit.toFixed(2);
    if (pill) pill.style.display = 'block';
    if (saleSec) saleSec.classList.remove('panel-locked');
}

function getSelectedCustomerId() {
    var fixed = document.getElementById('fixedCustomerId');
    if (fixed) return fixed.value;
    var cs = document.getElementById('custSelect');
    if (cs && cs.value) return cs.value;
    return null;
}

function getSelectedCustomerName() {
    var fixed = document.getElementById('fixedCustomerId');
    if (fixed) {
        var preN = document.querySelector('.preselected-banner .pb-info h3');
        return preN ? preN.textContent.trim() : 'Customer';
    }
    var cs = document.getElementById('custSelect');
    if (cs && cs.value) {
        var opt = cs.options[cs.selectedIndex];
        return opt.getAttribute('data-name') || 'Customer';
    }
    return 'Customer';
}

/* ── Product ── */
function getProduct(id) {
    for (var i = 0; i < PRODUCTS.length; i++) { if (PRODUCTS[i].id == id) return PRODUCTS[i]; }
    return null;
}

function onProductChange() {
    var sel   = document.getElementById('productId');
    var pid   = sel.value;
    var strip = document.getElementById('stockStrip');
    if (!pid) { strip.style.display = 'none'; return; }
    var p = getProduct(pid);
    if (!p) return;
    document.getElementById('stockNum').textContent = p.stock;
    strip.style.display = 'flex';
    strip.className = 'stock-strip';
    if (p.stock === 0)      strip.classList.add('zero');
    else if (p.stock <= 10) strip.classList.add('low');
    document.getElementById('qty').max = p.stock;
    updatePreview();
}

function updatePreview() {
    var qty   = parseFloat(document.getElementById('qty').value)       || 0;
    var price = parseFloat(document.getElementById('unitPrice').value) || 0;
    var prev  = document.getElementById('rowPreview');
    if (qty > 0 && price > 0) {
        prev.style.display = 'block';
        prev.textContent   = (isMr() ? 'एकूण: ₹ ' : 'Row Total: ₹ ') + (qty * price).toFixed(2);
    } else {
        prev.style.display = 'none';
    }
}

function addToTable() {
    var mr    = isMr();
    var cid   = getSelectedCustomerId();
    var pid   = parseInt(document.getElementById('productId').value, 10);
    var qty   = parseInt(document.getElementById('qty').value, 10);
    var price = parseFloat(document.getElementById('unitPrice').value);
    if (!cid)              { alert(mr ? '⚠️ कृपया ग्राहक निवडा.'          : '⚠️ Please select a customer first.'); return; }
    if (!pid)              { alert(mr ? '⚠️ कृपया उत्पाद निवडा.'           : '⚠️ Please select a product.');         return; }
    if (!qty || qty <= 0)  { alert(mr ? '⚠️ कृपया योग्य प्रमाण टाका.'    : '⚠️ Please enter a valid quantity.');    return; }
    if (!price || price <= 0) { alert(mr ? '⚠️ कृपया योग्य किंमत टाका.' : '⚠️ Please enter a valid unit price.'); return; }
    var p = getProduct(pid);
    if (!p) return;
    var alreadyQty = 0;
    tableRows.forEach(function (r) { if (r.productId === pid) alreadyQty += r.qty; });
    if (alreadyQty + qty > p.stock) {
        alert('⚠️ ' + (mr
            ? 'एकूण प्रमाण (' + (alreadyQty+qty) + ') उपलब्ध स्टॉकपेक्षा जास्त आहे (' + p.stock + ')'
            : 'Total quantity (' + (alreadyQty+qty) + ') exceeds available stock (' + p.stock + ') for: ' + p.name));
        return;
    }
    var amount = parseFloat((qty * price).toFixed(2));
    tableRows.push({ rid: ++rowSeq, productId: pid, productName: p.name, qty: qty, unitPrice: price, amount: amount });
    renderTable();
    resetInputs();
}

function renderTable() {
    var tbody = document.getElementById('txnBody');
    var mr    = isMr();
    tbody.innerHTML = '';
    if (tableRows.length === 0) {
        tbody.innerHTML = '<tr class="empty-msg"><td colspan="6">' +
            (mr ? '← डाव्या बाजूच्या फॉर्मचा वापर करून उत्पादे जोडा' : '← Add products using the form on the left') +
            '</td></tr>';
        updateGrand(); return;
    }
    tableRows.forEach(function (r, idx) {
        var tr = document.createElement('tr');
        tr.innerHTML =
            '<td style="color:#888;font-size:12px;">' + (idx+1) + '</td>' +
            '<td><span class="prod-tag">📦 ' + r.productName + '</span></td>' +
            '<td class="qty-num">' + r.qty + '</td>' +
            '<td class="price-num">₹ ' + r.unitPrice.toFixed(2) + '</td>' +
            '<td class="total-num">₹ ' + r.amount.toFixed(2) + '</td>' +
            '<td><button class="btn-remove" onclick="removeRow(' + r.rid + ')">✕</button></td>';
        tbody.appendChild(tr);
    });
    updateGrand();
}

function removeRow(rid) {
    tableRows = tableRows.filter(function (r) { return r.rid !== rid; });
    renderTable();
}

function updateGrand() {
    var grand = 0; var mr = isMr();
    tableRows.forEach(function (r) { grand += r.amount; });
    document.getElementById('footerGrand').textContent  = '₹ ' + grand.toFixed(2);
    document.getElementById('grandDisplay').textContent = '₹ ' + grand.toFixed(2);
    var n = tableRows.length;
    document.getElementById('grandCount').textContent     = n + (mr ? ' आयटम' : ' item(s)');
    document.getElementById('itemCountBadge').textContent = n + (mr ? ' आयटम' : ' item' + (n !== 1 ? 's' : ''));
}

function resetInputs() {
    document.getElementById('productId').value  = '';
    document.getElementById('qty').value        = '';
    document.getElementById('unitPrice').value  = '';
    document.getElementById('stockStrip').style.display = 'none';
    document.getElementById('rowPreview').style.display = 'none';
}

/* ═══════════════════════════════════════════
   RECEIPT LOGIC
   ═══════════════════════════════════════════ */
function submitSaleWithReceipt() {
    var mr  = isMr();
    var cid = getSelectedCustomerId();
    if (!cid)                   { alert(mr ? '⚠️ कृपया ग्राहक निवडा.'    : '⚠️ Please select a customer.'); return; }
    if (tableRows.length === 0) { alert(mr ? '⚠️ किमान एक उत्पाद जोडा.' : '⚠️ Please add at least one product.'); return; }

    var payMode = document.querySelector('input[name="payMode"]:checked');
    var pm = payMode ? payMode.value : 'CASH';

    pendingSubmitData = {
        customerId: cid,
        items: tableRows.map(function (r) {
            return { productId: r.productId, productName: r.productName,
                     quantity: r.qty, unitPrice: r.unitPrice, amount: r.amount };
        }),
        paymentMode: pm
    };

    showReceiptModal();
}

/* ── Populate the preview modal ── */
function showReceiptModal() {
    var mr  = isMr();
    var pm  = pendingSubmitData.paymentMode;
    var grand = 0;
    pendingSubmitData.items.forEach(function (item) { grand += item.amount; });

    document.getElementById('receiptShopName').textContent = mr ? SHOP_NAME_MR : SHOP_NAME;
    document.getElementById('receiptCustomer').textContent = getSelectedCustomerName();
    document.getElementById('receiptPayMode').textContent  =
        pm === 'CASH' ? (mr ? '💵 रोख' : '💵 Cash') : (mr ? '📱 ऑनलाइन' : '📱 Online');

    var now = new Date();
    document.getElementById('receiptDateTime').textContent =
        now.toLocaleString(mr ? 'mr-IN' : 'en-IN', {
            year:'numeric', month:'short', day:'2-digit',
            hour:'2-digit', minute:'2-digit'
        });

    /* Items table rows */
    var rowsHtml = '';
    pendingSubmitData.items.forEach(function (item, idx) {
        var bg = idx % 2 === 1 ? 'background:#fffbf5;' : '';
        rowsHtml +=
            '<tr style="' + bg + '">' +
            '<td style="padding:7px 10px;border-bottom:1px solid #f0e0d0;color:#888;">' + (idx+1) + '</td>' +
            '<td style="padding:7px 10px;border-bottom:1px solid #f0e0d0;font-weight:600;">' + item.productName + '</td>' +
            '<td style="padding:7px 10px;border-bottom:1px solid #f0e0d0;text-align:center;font-weight:700;">' + item.quantity + '</td>' +
            '<td style="padding:7px 10px;border-bottom:1px solid #f0e0d0;text-align:right;">&#8377;' + item.unitPrice.toFixed(2) + '</td>' +
            '<td style="padding:7px 10px;border-bottom:1px solid #f0e0d0;text-align:right;font-weight:700;color:#c2410c;">&#8377;' + item.amount.toFixed(2) + '</td>' +
            '</tr>';
    });
    document.getElementById('receiptItems').innerHTML    = rowsHtml;
    document.getElementById('receiptGrandTotal').textContent = '₹ ' + grand.toFixed(2);

    document.getElementById('receiptModal').classList.add('show');
}

/* ── Generate proper print popup (same style as statement prints) ── */
function printReceipt() {
    var mr       = isMr();
    var custName = getSelectedCustomerName();
    var pm       = pendingSubmitData.paymentMode;
    var pmLabel  = pm === 'CASH' ? (mr ? 'रोख (Cash)' : 'Cash') : (mr ? 'ऑनलाइन (Online)' : 'Online');
    var grand    = 0;
    pendingSubmitData.items.forEach(function (item) { grand += item.amount; });

    var shopName = mr ? SHOP_NAME_MR : SHOP_NAME;
    var now      = new Date();
    var dateStr  = now.toLocaleDateString('en-IN', { weekday:'long', year:'numeric', month:'long', day:'numeric' });
    var timeStr  = now.toLocaleTimeString('en-IN', { hour:'2-digit', minute:'2-digit' });

    /* ── Build item rows ── */
    var rows = '';
    pendingSubmitData.items.forEach(function (item, idx) {
        var bg = idx % 2 === 1 ? 'background:#fffbf5;' : '';
        rows +=
            '<tr style="' + bg + '">' +
            '<td style="padding:9px 12px;border-bottom:1px solid #f0e0d0;color:#888;">' + (idx+1) + '</td>' +
            '<td style="padding:9px 12px;border-bottom:1px solid #f0e0d0;font-weight:600;">' + item.productName + '</td>' +
            '<td style="padding:9px 12px;border-bottom:1px solid #f0e0d0;text-align:center;font-weight:700;">' + item.quantity + '</td>' +
            '<td style="padding:9px 12px;border-bottom:1px solid #f0e0d0;text-align:right;">&#8377; ' + item.unitPrice.toFixed(2) + '</td>' +
            '<td style="padding:9px 12px;border-bottom:1px solid #f0e0d0;text-align:right;font-weight:700;color:#c2410c;">&#8377; ' + item.amount.toFixed(2) + '</td>' +
            '</tr>';
    });

    var title   = mr ? 'रोख विक्री पावती' : 'Cash Sale Receipt';
    var headers = mr
        ? ['#', 'उत्पाद', 'प्रमाण', 'दर / नग (₹)', 'एकूण (₹)']
        : ['#', 'Product', 'Qty', 'Rate / Unit (Rs.)', 'Total (Rs.)'];
    var thHtml  = headers.map(function (h) { return '<th>' + h + '</th>'; }).join('');

    var html =
        '<!DOCTYPE html><html><head><meta charset="UTF-8">' +
        '<title>' + title + ' \u2014 ' + shopName + '</title>' +
        '<style>' +
        'body{font-family:Arial,sans-serif;margin:30px;color:#0d1b2a;font-size:13px;}' +
        '.header{text-align:center;border-bottom:3px double #c2730a;padding-bottom:14px;margin-bottom:18px;}' +
        '.shop-name{font-size:24px;font-weight:800;letter-spacing:2px;text-transform:uppercase;color:#0d1b2a;}' +
        '.receipt-title{font-size:14px;font-weight:700;color:#c2730a;margin-top:5px;letter-spacing:0.5px;}' +
        '.receipt-meta{font-size:12px;color:#94a3b8;margin-top:4px;}' +
        '.info-box{display:grid;grid-template-columns:1fr 1fr;gap:6px 24px;' +
        '  background:#fff8f0;border:1px solid #f5c89a;padding:12px 16px;' +
        '  margin-bottom:16px;border-radius:4px;}' +
        '.info-item{display:flex;flex-direction:column;gap:2px;}' +
        '.info-label{font-size:9px;font-weight:700;color:#94a3b8;text-transform:uppercase;letter-spacing:0.8px;}' +
        '.info-value{font-size:13px;font-weight:700;color:#0d1b2a;}' +
        'table{width:100%;border-collapse:collapse;font-size:13px;}' +
        'th{background:#c2730a;color:#fff;padding:9px 12px;text-align:left;' +
        '  font-size:10px;text-transform:uppercase;letter-spacing:0.5px;}' +
        'th:nth-child(3){text-align:center;}' +
        'th:nth-child(4),th:last-child{text-align:right;}' +
        '.total-row td{background:#c2730a;color:#fff;font-weight:800;' +
        '  border-top:2px solid #9a5316;padding:11px 12px;}' +
        '.total-row td:first-child{text-align:right;font-size:12px;letter-spacing:0.5px;}' +
        '.total-row td:last-child{text-align:right;font-size:16px;}' +
        '.footer{margin-top:18px;text-align:center;font-size:11px;color:#94a3b8;' +
        '  border-top:1px dashed #f0d0b0;padding-top:10px;}' +
        '@media print{body{margin:12px;}}' +
        '</style></head><body>' +

        '<div class="header">' +
        '<div class="shop-name">' + shopName + '</div>' +
        '<div class="receipt-title">💵 ' + title + '</div>' +
        '<div class="receipt-meta">' + dateStr + ' &nbsp;&middot;&nbsp; ' + timeStr + '</div>' +
        '</div>' +

        '<div class="info-box">' +
        '<div class="info-item">' +
          '<span class="info-label">' + (mr ? 'ग्राहकाचे नाव' : 'Customer Name') + '</span>' +
          '<span class="info-value">' + custName + '</span>' +
        '</div>' +
        '<div class="info-item">' +
          '<span class="info-label">' + (mr ? 'देयक पद्धत' : 'Payment Mode') + '</span>' +
          '<span class="info-value">' + pmLabel + '</span>' +
        '</div>' +
        '</div>' +

        '<table>' +
        '<thead><tr>' + thHtml + '</tr></thead>' +
        '<tbody>' + rows + '</tbody>' +
        '<tfoot><tr class="total-row">' +
          '<td colspan="4">' + (mr ? 'एकूण रक्कम' : 'GRAND TOTAL') + '</td>' +
          '<td>&#8377; ' + grand.toFixed(2) + '</td>' +
        '</tr></tfoot>' +
        '</table>' +

        '<div class="footer">' +
        '<p style="margin:0 0 3px;">' + (mr ? 'खरेदीसाठी धन्यवाद! 🙏' : 'Thank you for your purchase! 🙏') + '</p>' +
        '<p style="margin:0;">' + shopName + ' &middot; ' + title + '</p>' +
        '</div>' +
        '</body></html>';

    var pw = window.top.open('', '_blank', 'width=750,height=650');
    if (!pw) { alert('⚠️ Popup blocked. Please allow popups for this site.'); return; }
    pw.document.write(html);
    pw.document.close();
    pw.focus();
    pw.print();

    /* Submit after print dialog */
    setTimeout(function () { saveTransaction(); }, 600);
}

function skipPrintAndSave() {
    saveTransaction();
}

function saveTransaction() {
    document.getElementById('customerIdInput').value  = pendingSubmitData.customerId;
    document.getElementById('itemsJsonInput').value   = JSON.stringify(pendingSubmitData.items);
    document.getElementById('paymentModeInput').value = pendingSubmitData.paymentMode;
    document.getElementById('receiptModal').classList.remove('show');
    document.getElementById('submitForm').submit();
}
</script>
</body>
</html>
