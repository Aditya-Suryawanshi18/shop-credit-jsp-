<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, doa.DBConnection" %>
<%
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=Please login first");
        return;
    }

    /* ── Optional: pre-select a customer via ?id=  ── */
    String idStr     = request.getParameter("id");
    int    preselect = -1;
    if (idStr != null && !idStr.trim().isEmpty()) {
        try { preselect = Integer.parseInt(idStr.trim()); } catch (NumberFormatException ignored) {}
    }

    /* ── If id was passed, load that customer directly ── */
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

    /* ── Load all customers for the dropdown ── */
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

    /* ── Load products ── */
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
        /* ── Page header banner ── */
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

        /* ══════════════════════════════════════════
           CUSTOMER SELECTOR AREA  (NEW)
        ══════════════════════════════════════════ */

        /* -- Mode toggle row -- */
        .cust-mode-row {
            display: flex;
            gap: 12px;
            margin-bottom: 16px;
            flex-wrap: wrap;
        }
        .cust-mode-btn {
            flex: 1; min-width: 200px;
            padding: 14px 20px;
            border-radius: 12px;
            border: 2px solid transparent;
            cursor: pointer;
            display: flex; align-items: center; gap: 12px;
            font-family: 'Outfit', sans-serif;
            font-size: 14px; font-weight: 700;
            transition: all 0.2s;
            background: #fff;
            box-shadow: 0 2px 8px rgba(0,0,0,0.07);
        }
        .cust-mode-btn .cmb-icon {
            width: 42px; height: 42px;
            border-radius: 10px;
            display: flex; align-items: center; justify-content: center;
            font-size: 20px; flex-shrink: 0;
        }
        .cust-mode-btn .cmb-text { display: flex; flex-direction: column; gap: 2px; }
        .cust-mode-btn .cmb-title { font-size: 14px; font-weight: 700; }
        .cust-mode-btn .cmb-sub   { font-size: 11px; font-weight: 500; opacity: 0.65; }

        /* existing customer option */
        .cust-mode-btn.mode-existing { color: #065f46; border-color: #d1fae5; }
        .cust-mode-btn.mode-existing .cmb-icon { background: #d1fae5; }
        .cust-mode-btn.mode-existing.active,
        .cust-mode-btn.mode-existing:hover {
            border-color: #059669;
            background: linear-gradient(135deg, #ecfdf5, #d1fae5);
            box-shadow: 0 4px 16px rgba(5,150,105,0.15);
        }

        /* new customer option */
        .cust-mode-btn.mode-new { color: #1e40af; border-color: #dbeafe; }
        .cust-mode-btn.mode-new .cmb-icon { background: #dbeafe; }
        .cust-mode-btn.mode-new.active,
        .cust-mode-btn.mode-new:hover {
            border-color: #2563eb;
            background: linear-gradient(135deg, #eff6ff, #dbeafe);
            box-shadow: 0 4px 16px rgba(37,99,235,0.15);
        }

        /* -- Existing customer card (shown when mode = existing) -- */
        .cust-select-card {
            background: #fff; border-radius: 14px;
            box-shadow: 0 4px 16px rgba(0,0,0,0.08);
            padding: 18px 20px; margin-bottom: 20px;
            display: flex; align-items: flex-end; gap: 16px; flex-wrap: wrap;
            border: 2px solid #d1fae5;
            animation: fadeIn 0.25s ease;
        }
        .cust-select-card .csg { display: flex; flex-direction: column; gap: 5px; flex: 1; min-width: 220px; }
        .cust-select-card label { font-size: 12px; font-weight: 700; color: #065f46; letter-spacing: 0.3px; }
        .cust-select-card select {
            padding: 10px 12px; border: 2px solid #6ee7b7; border-radius: 9px;
            font-size: 13px; color: #1a1a2a; outline: none;
            transition: border 0.2s; background: #fff;
            font-family: 'Outfit', sans-serif;
        }
        .cust-select-card select:focus { border-color: #059669; box-shadow: 0 0 0 3px rgba(5,150,105,0.1); }

        /* -- New customer redirect card -- */
        .new-cust-card {
            background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
            border: 2px solid #bfdbfe;
            border-radius: 14px; padding: 24px 26px;
            margin-bottom: 20px;
            display: flex; align-items: center; gap: 20px; flex-wrap: wrap;
            animation: fadeIn 0.25s ease;
        }
        .new-cust-card .ncc-icon {
            width: 56px; height: 56px;
            background: #2563eb; border-radius: 14px;
            display: flex; align-items: center; justify-content: center;
            font-size: 26px; flex-shrink: 0;
            box-shadow: 0 4px 12px rgba(37,99,235,0.3);
        }
        .new-cust-card .ncc-text { flex: 1; }
        .new-cust-card .ncc-text h3 { font-size: 16px; font-weight: 800; color: #1e40af; margin: 0 0 4px; }
        .new-cust-card .ncc-text p  { font-size: 13px; color: #3b82f6; margin: 0; }
        .btn-create-customer {
            padding: 12px 26px;
            background: linear-gradient(135deg, #2563eb, #1d4ed8);
            color: #fff; border: none; border-radius: 10px;
            font-family: 'Outfit', sans-serif;
            font-size: 14px; font-weight: 700;
            cursor: pointer; white-space: nowrap;
            text-decoration: none; display: inline-flex;
            align-items: center; gap: 8px;
            box-shadow: 0 4px 16px rgba(37,99,235,0.3);
            transition: all 0.2s;
        }
        .btn-create-customer:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 24px rgba(37,99,235,0.4);
        }

        /* -- Pre-selected customer banner (when ?id= passed) -- */
        .preselected-banner {
            background: linear-gradient(135deg, #059669 0%, #10b981 100%);
            color: #fff; border-radius: 14px; padding: 16px 22px;
            margin-bottom: 20px; display: flex; align-items: center; gap: 16px;
            flex-wrap: wrap; box-shadow: 0 4px 16px rgba(5,150,105,0.25);
            animation: fadeIn 0.3s ease;
        }
        .preselected-banner .pb-avatar {
            width: 48px; height: 48px; background: rgba(255,255,255,0.2);
            border-radius: 50%; display: flex; align-items: center;
            justify-content: center; font-size: 22px; flex-shrink: 0;
            border: 2px solid rgba(255,255,255,0.35);
        }
        .preselected-banner .pb-info { flex: 1; }
        .preselected-banner .pb-info h3 { font-size: 16px; font-weight: 700; margin: 0 0 3px; }
        .preselected-banner .pb-info p  { font-size: 12px; color: rgba(255,255,255,0.75); margin: 0; }
        .preselected-banner .pb-credit {
            background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.25);
            border-radius: 10px; padding: 8px 16px; text-align: center; flex-shrink: 0;
        }
        .preselected-banner .pb-credit .lbl { font-size: 10px; color: rgba(255,255,255,0.65); text-transform: uppercase; letter-spacing: 0.8px; }
        .preselected-banner .pb-credit .val { font-size: 17px; font-weight: 800; color: #d1fae5; margin-top: 2px; }
        .btn-change-cust {
            padding: 8px 16px; background: rgba(255,255,255,0.15);
            border: 1px solid rgba(255,255,255,0.3); color: #fff;
            border-radius: 8px; font-family: 'Outfit', sans-serif;
            font-size: 12px; font-weight: 700; cursor: pointer;
            transition: background 0.2s; white-space: nowrap;
            flex-shrink: 0;
        }
        .btn-change-cust:hover { background: rgba(255,255,255,0.28); }

        /* ── Selected customer pill (dropdown mode) ── */
        .cust-pill {
            display: none; background: linear-gradient(135deg, #f97316 0%, #fb923c 100%);
            color: #fff; border-radius: 10px; padding: 10px 18px;
            font-size: 13px; font-weight: 700; flex-shrink: 0;
        }
        .cust-pill .cp-credit { font-size: 11px; color: rgba(255,255,255,0.7); margin-top:2px; }

        /* ── Main layout ── */
        .main-layout { display: grid; grid-template-columns: 320px 1fr; gap: 20px; align-items: start; }
        @media (max-width: 860px) { .main-layout { grid-template-columns: 1fr; } }

        /* ── Input panel ── */
        .input-panel { background: #fff; border-radius: 14px; box-shadow: 0 4px 16px rgba(0,0,0,0.08); overflow: hidden; position: sticky; top: 10px; }
        .input-panel-header { background: linear-gradient(135deg, #f97316 0%, #fb923c 100%); color: #fff; padding: 13px 18px; font-size: 13px; font-weight: 700; }
        .input-panel-body { padding: 18px; display: flex; flex-direction: column; gap: 14px; }
        .ip-group { display: flex; flex-direction: column; gap: 5px; }
        .ip-group label { font-size: 12px; font-weight: 700; color: #065f46; }
        .ip-group select, .ip-group input {
            padding: 9px 11px; border: 2px solid #6ee7b7; border-radius: 8px;
            font-size: 13px; color: #1a1a2a; background: #fff; outline: none;
            transition: border 0.2s; width: 100%; -moz-appearance: textfield;
            font-family: 'Outfit', sans-serif;
        }
        .ip-group select:focus, .ip-group input:focus { border-color: #059669; box-shadow: 0 0 0 3px rgba(5,150,105,0.1); }
        .ip-group input::-webkit-inner-spin-button, .ip-group input::-webkit-outer-spin-button { -webkit-appearance: none; }

        .stock-strip { display: none; align-items: center; gap: 8px; background: #ecfdf5; border: 1px solid #6ee7b7; border-radius: 7px; padding: 6px 12px; font-size: 12px; color: #065f46; font-weight: 600; margin-top: 4px; }
        .stock-strip .snum { background: #059669; color: #fff; border-radius: 20px; padding: 1px 10px; font-size: 12px; font-weight: 700; }
        .stock-strip.low  { background: #fff8e1; border-color: #fde68a; color: #92400e; }
        .stock-strip.low  .snum { background: #f59e0b; }
        .stock-strip.zero { background: #fef2f2; border-color: #fecaca; color: #991b1b; }
        .stock-strip.zero .snum { background: #dc2626; }

        .row-preview { background: #ecfdf5; border: 1px dashed #6ee7b7; border-radius: 8px; padding: 9px 14px; font-size: 13px; color: #065f46; font-weight: 700; text-align: center; display: none; }
        .btn-add-to-table { width: 100%; padding: 11px; background: linear-gradient(135deg, #f97316 0%, #fb923c 100%); color: #fff; border: none; border-radius: 9px; font-size: 14px; font-weight: 700; cursor: pointer; transition: opacity 0.2s, transform 0.15s; }
        .btn-add-to-table:hover { opacity: 0.88; transform: scale(1.02); }

        /* ── Payment mode selector ── */
        .pay-mode-row { display: flex; gap: 10px; }
        .pay-opt { flex: 1; position: relative; }
        .pay-opt input[type="radio"] { position: absolute; opacity: 0; width: 0; height: 0; }
        .pay-opt label { display: flex; align-items: center; justify-content: center; gap: 7px; padding: 10px 14px; border: 2px solid #d1fae5; border-radius: 9px; background: #f0fdf4; cursor: pointer; font-size: 13px; font-weight: 700; color: #065f46; transition: all 0.18s; }
        .pay-opt input[type="radio"]:checked + label { border-color: #6ee7b7; background: linear-gradient(135deg, #f97316 0%, #fb923c 100%); color: #fff; box-shadow: 0 3px 12px rgba(5,150,105,0.25); }
        .pay-opt label:hover { border-color: #6ee7b7; }

        /* ── Table panel ── */
        .table-panel { background: #fff; border-radius: 14px; box-shadow: 0 4px 16px rgba(0,0,0,0.08); overflow: hidden; }
        .table-panel-header { background: linear-gradient(135deg, #f97316 0%, #fb923c 100%); color: #fff; padding: 13px 18px; font-size: 13px; font-weight: 700; display: flex; align-items: center; justify-content: space-between; }
        .txn-table { width: 100%; border-collapse: collapse; font-size: 13px; }
        .txn-table thead th { background: #f0fdf4; color: #065f46; padding: 10px 12px; text-align: center; font-weight: 700; font-size: 12px; border-bottom: 2px solid #6ee7b7; }
        .txn-table tbody td { padding: 9px 11px; border-bottom: 1px solid #ecfdf5; text-align: center; vertical-align: middle; }
        .txn-table tbody tr:last-child td { border-bottom: none; }
        .txn-table tbody tr:hover { background: #f0fdf4; }
        .txn-table tfoot td { padding: 12px 14px; background: orange; color: #fff; font-weight: 700; font-size: 14px; text-align: right; }
        .txn-table tfoot td.grand-val { text-align: center; font-size: 16px; color: #fff; }
        .empty-msg td { padding: 32px !important; color: #bbb; font-size: 13px; font-style: italic; text-align: center !important; }
        .btn-remove { width: 26px; height: 26px; background: #fee2e2; color: #dc2626; border: none; border-radius: 5px; font-size: 14px; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; transition: background 0.2s; }
        .btn-remove:hover { background: #dc2626; color: #fff; }
        .prod-tag { background: #ecfdf5; color: #065f46; padding: 3px 10px; border-radius: 20px; font-size: 12px; font-weight: 600; }
        .qty-num  { font-weight: 700; color: #065f46; }
        .price-num { color: #555; }
        .total-num { font-weight: 700; color: #065f46; }

        /* ── Grand total bar ── */
        .grand-bar { display: flex; align-items: center; justify-content: space-between; background: linear-gradient(135deg, #f97316 0%, #fb923c 100%); color: #fff; border-radius: 10px; padding: 13px 20px; margin-top: 16px; }
        .grand-bar .g-label { font-size: 13px; color: rgba(255,255,255,0.7); font-weight: 600; }
        .grand-bar .g-val   { font-size: 22px; font-weight: 800; }
        .grand-bar .g-count { font-size: 11px; color: rgba(255,255,255,0.6); margin-top: 1px; }
        .save-row { display: flex; gap: 14px; margin-top: 16px; justify-content: flex-end; }

        .badge-cash-sale { display: inline-flex; align-items: center; gap: 4px; background: rgba(255,255,255,0.15); padding: 3px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; }

        /* Product panel locked state */
        .panel-locked { opacity: 0.45; pointer-events: none; }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(8px); }
            to   { opacity: 1; transform: translateY(0); }
        }
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
        <span class="badge-cash-sale" style="margin-left:auto;" data-i18n="nav.cash">🟢 CASH SALE</span>
    </div>

    <!-- ══════════════════════════════════════════
         CUSTOMER SECTION
    ══════════════════════════════════════════ -->

    <% if (hasPreselected) { %>
    <!-- ── A: Customer ID was passed — show banner directly ── -->
    <div class="preselected-banner" id="preselectedBanner">
        <div class="pb-avatar">👤</div>
        <div class="pb-info">
            <h3><%= preselectedName %></h3>
            <p>📞 <%= preselectedPhone %> &nbsp;·&nbsp; Customer ID #<%= preselect %></p>
        </div>
        <div class="pb-credit">
            <div class="lbl">
                <span class="lang-name-en">Current Credit</span>
                <span class="lang-name-mr" style="display:none;">सध्याची उधार</span>
            </div>
            <div class="val">₹ <%= String.format("%.2f", preselectedCredit) %></div>
        </div>
        <button class="btn-change-cust" onclick="showModeSelector()">
            🔄 <span class="lang-name-en">Change</span>
            <span class="lang-name-mr" style="display:none;">बदला</span>
        </button>
    </div>
    <!-- Hidden input to carry the pre-selected ID -->
    <input type="hidden" id="fixedCustomerId" value="<%= preselect %>">

    <% } else { %>
    <!-- ── B: No ID passed — show mode selector ── -->
    <div id="modeSelectorArea">

        <!-- Mode toggle buttons -->
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

        <!-- Existing customer dropdown (hidden until mode = existing) -->
        <div class="cust-select-card" id="existingCustPanel" style="display:none;">
            <div class="csg">
                <label for="custSelect">
                    👤
                    <span class="lang-name-en">Select Customer</span>
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

        <!-- New customer redirect card (hidden until mode = new) -->
        <div class="new-cust-card" id="newCustPanel" style="display:none;">
            <div class="ncc-icon">👤</div>
            <div class="ncc-text">
                <h3>
                    <span class="lang-name-en">Customer not registered?</span>
                    <span class="lang-name-mr" style="display:none;">ग्राहक नोंदणीकृत नाही?</span>
                </h3>
                <p>
                    <span class="lang-name-en">Create a new customer account first, then come back to record the sale.</span>
                    <span class="lang-name-mr" style="display:none;">प्रथम नवीन ग्राहक खाते तयार करा, नंतर विक्री नोंद करण्यासाठी परत या.</span>
                </p>
            </div>
            <a href="add_customer.jsp" class="btn-create-customer">
                ➕
                <span class="lang-name-en">Create Customer</span>
                <span class="lang-name-mr" style="display:none;">ग्राहक तयार करा</span>
            </a>
        </div>

    </div>
    <% } %>

    <!-- ══════════════════════════════════════════
         PRODUCT + TABLE SECTION
    ══════════════════════════════════════════ -->
    <div id="saleSection" class="<%= hasPreselected ? "" : "panel-locked" %>">
        <div class="main-layout">

            <!-- LEFT: Input Panel -->
            <div class="input-panel">
                <div class="input-panel-header">🛒
                    <span class="lang-name-en">Add Product</span>
                    <span class="lang-name-mr" style="display:none;">उत्पाद जोडा</span>
                </div>
                <div class="input-panel-body">

                    <div class="ip-group">
                        <label for="productId">📦
                            <span class="lang-name-en">Product</span>
                            <span class="lang-name-mr" style="display:none;">उत्पाद</span>
                            <span style="color:#dc2626;">*</span>
                        </label>
                        <select id="productId" onchange="onProductChange()">
                            <option value="" disabled selected id="prodPlaceholder">— Select product —</option>
                        </select>
                        <div class="stock-strip" id="stockStrip">
                            <span class="lang-name-en">Available:</span>
                            <span class="lang-name-mr" style="display:none;">उपलब्ध:</span>
                            <span class="snum" id="stockNum">0</span>
                        </div>
                    </div>

                    <div class="ip-group">
                        <label for="qty">🔢
                            <span class="lang-name-en">Quantity</span>
                            <span class="lang-name-mr" style="display:none;">प्रमाण</span>
                            <span style="color:#dc2626;">*</span>
                        </label>
                        <input type="number" id="qty" placeholder="0" min="1"
                               oninput="updatePreview()" onchange="updatePreview()">
                    </div>

                    <div class="ip-group">
                        <label for="unitPrice">💰
                            <span class="lang-name-en">Price / Unit (₹)</span>
                            <span class="lang-name-mr" style="display:none;">किंमत / नग (₹)</span>
                            <span style="color:#dc2626;">*</span>
                        </label>
                        <input type="number" id="unitPrice" placeholder="0.00" step="0.01" min="0.01"
                               oninput="updatePreview()" onchange="updatePreview()">
                    </div>

                    <div class="row-preview" id="rowPreview">Row Total: ₹ 0.00</div>

                    <!-- Payment mode -->
                    <div class="ip-group">
                        <label>💳
                            <span class="lang-name-en">Payment Mode</span>
                            <span class="lang-name-mr" style="display:none;">देयक पद्धत</span>
                        </label>
                        <div class="pay-mode-row">
                            <div class="pay-opt">
                                <input type="radio" id="modeCash" name="payMode" value="CASH" checked>
                                <label for="modeCash">💵
                                    <span class="lang-name-en">Cash</span>
                                    <span class="lang-name-mr" style="display:none;">रोख</span>
                                </label>
                            </div>
                            <div class="pay-opt">
                                <input type="radio" id="modeOnline" name="payMode" value="ONLINE">
                                <label for="modeOnline">📱
                                    <span class="lang-name-en">Online</span>
                                    <span class="lang-name-mr" style="display:none;">ऑनलाइन</span>
                                </label>
                            </div>
                        </div>
                    </div>

                    <button type="button" class="btn-add-to-table" onclick="addToTable()">
                        ➕
                        <span class="lang-name-en">Add to Sale</span>
                        <span class="lang-name-mr" style="display:none;">विक्रीत जोडा</span>
                    </button>
                </div>
            </div>

            <!-- RIGHT: Table -->
            <div>
                <div class="table-panel">
                    <div class="table-panel-header">
                        <span>🧾
                            <span class="lang-name-en">Sale Items</span>
                            <span class="lang-name-mr" style="display:none;">विक्री यादी</span>
                        </span>
                        <span id="itemCountBadge" style="background:rgba(255,255,255,0.15);border-radius:20px;padding:2px 12px;font-size:12px;">0 items</span>
                    </div>
                    <table class="txn-table">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>
                                    <span class="lang-name-en">Product</span>
                                    <span class="lang-name-mr" style="display:none;">उत्पाद</span>
                                </th>
                                <th>
                                    <span class="lang-name-en">Qty</span>
                                    <span class="lang-name-mr" style="display:none;">प्रमाण</span>
                                </th>
                                <th>
                                    <span class="lang-name-en">Price/Unit (₹)</span>
                                    <span class="lang-name-mr" style="display:none;">किंमत/नग (₹)</span>
                                </th>
                                <th>
                                    <span class="lang-name-en">Total (₹)</span>
                                    <span class="lang-name-mr" style="display:none;">एकूण (₹)</span>
                                </th>
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
                                <td colspan="4" style="text-align:right;">
                                    <span class="lang-name-en">Grand Total</span>
                                    <span class="lang-name-mr" style="display:none;">एकूण</span>
                                </td>
                                <td class="grand-val" id="footerGrand">₹ 0.00</td>
                                <td></td>
                            </tr>
                        </tfoot>
                    </table>
                </div>

                <div class="grand-bar">
                    <div>
                        <div class="g-label">
                            <span class="lang-name-en">TOTAL SALE AMOUNT</span>
                            <span class="lang-name-mr" style="display:none;">एकूण विक्री रक्कम</span>
                        </div>
                        <div class="g-val" id="grandDisplay">₹ 0.00</div>
                        <div class="g-count" id="grandCount">0 item(s)</div>
                    </div>
                    <span style="font-size:32px;">💵</span>
                </div>

                <div class="save-row">
                    <a href="view_customers.jsp" class="btn-clear"
                       style="text-decoration:none;display:inline-flex;align-items:center;justify-content:center;padding:10px 28px;">
                        <span class="lang-name-en">Cancel</span>
                        <span class="lang-name-mr" style="display:none;">रद्द करा</span>
                    </a>
                    <button type="button" class="btn-save"
                            style="background:linear-gradient(135deg, #f97316 0%, #fb923c 100%);box-shadow:0 4px 16px rgba(249,115,22,0.3);"
                            onclick="submitSale()">
                        💾
                        <span class="lang-name-en">Save Cash Sale</span>
                        <span class="lang-name-mr" style="display:none;">रोख विक्री जतन करा</span>
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Hidden form for submission -->
    <form id="submitForm" action="CashSaleServlet" method="post" style="display:none;">
        <input type="hidden" name="customerId"   id="customerIdInput">
        <input type="hidden" name="itemsJson"    id="itemsJsonInput">
        <input type="hidden" name="paymentMode"  id="paymentModeInput">
    </form>
</div>

<script src="js/i18n.js"></script>
<script>
var CUSTOMERS  = <%= customersJson.toString() %>;
var PRODUCTS   = <%= productsJson.toString() %>;
var PRESELECT  = <%= preselect %>;
var HAS_PRESELECTED = <%= hasPreselected ? "true" : "false" %>;

var tableRows  = [];
var rowSeq     = 0;
var currentMode = ''; // 'existing' | 'new'

function getLang() { return (typeof i18n !== 'undefined') ? i18n.getLang() : 'en'; }
function isMr()    { return getLang() === 'mr'; }

/* ── Populate dropdowns ── */
(function () {
    /* Products */
    var ps  = document.getElementById('productId');
    var pph = document.getElementById('prodPlaceholder');
    if (pph) pph.text = isMr() ? '— उत्पाद निवडा —' : '— Select product —';
    PRODUCTS.forEach(function (p) {
        var opt  = document.createElement('option');
        opt.value = p.id;
        opt.text  = p.name + (isMr() ? '  (स्टॉक: ' + p.stock + ')' : '  (Stock: ' + p.stock + ')');
        opt.setAttribute('data-stock', p.stock);
        opt.setAttribute('data-name',  p.name);
        ps.appendChild(opt);
    });

    /* Customers (only needed in dropdown mode) */
    var cs = document.getElementById('custSelect');
    if (cs) {
        var cph = document.getElementById('custPlaceholder');
        if (cph) cph.text = isMr() ? '— ग्राहक निवडा —' : '— Select customer —';
        CUSTOMERS.forEach(function (c) {
            var opt  = document.createElement('option');
            opt.value = c.id;
            opt.text  = c.name + ' (📞 ' + c.phone + ')';
            opt.setAttribute('data-name',    c.name);
            opt.setAttribute('data-mr-name', c.marathiName || c.name);
            opt.setAttribute('data-phone',   c.phone);
            opt.setAttribute('data-credit',  c.credit);
            cs.appendChild(opt);
        });
        /* If PRESELECT is valid but no server-side match, still try JS select */
        if (PRESELECT > 0 && !HAS_PRESELECTED) {
            cs.value = PRESELECT;
            onCustChange();
        }
    }
})();

/* ══════════════════════════════════════════
   MODE SELECTOR  (only in no-preselect mode)
══════════════════════════════════════════ */
function setMode(mode) {
    currentMode = mode;

    var btnEx  = document.getElementById('btnModeExisting');
    var btnNew = document.getElementById('btnModeNew');
    var exPanel = document.getElementById('existingCustPanel');
    var newPanel = document.getElementById('newCustPanel');
    var saleSection = document.getElementById('saleSection');

    if (btnEx)  btnEx.classList.toggle('active',  mode === 'existing');
    if (btnNew) btnNew.classList.toggle('active',  mode === 'new');

    if (exPanel)  exPanel.style.display  = (mode === 'existing') ? 'flex' : 'none';
    if (newPanel) newPanel.style.display = (mode === 'new')      ? 'flex' : 'none';

    /* Lock the sale section when "new customer" is selected */
    if (saleSection) {
        saleSection.classList.toggle('panel-locked', mode === 'new');
    }

    /* Reset customer selection if switching back */
    if (mode === 'existing') {
        var cs = document.getElementById('custSelect');
        if (cs) { cs.value = ''; }
        document.getElementById('custPill').style.display = 'none';
        if (saleSection) saleSection.classList.add('panel-locked');
    }
}

/* Called from Change button when preselected banner is shown */
function showModeSelector() {
    /* Reload without the id param */
    window.location.href = 'cash_sale.jsp';
}

/* ── Customer change (dropdown mode) ── */
function onCustChange() {
    var sel  = document.getElementById('custSelect');
    if (!sel) return;
    var pill = document.getElementById('custPill');
    var cid  = sel.value;
    var saleSection = document.getElementById('saleSection');

    if (!cid) {
        if (pill) pill.style.display = 'none';
        if (saleSection) saleSection.classList.add('panel-locked');
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

    /* Unlock sale section once a customer is chosen */
    if (saleSection) saleSection.classList.remove('panel-locked');
}

/* ── Resolve final customer ID for submission ── */
function getSelectedCustomerId() {
    /* Preselected via URL */
    var fixed = document.getElementById('fixedCustomerId');
    if (fixed) return fixed.value;

    /* Dropdown mode */
    var cs = document.getElementById('custSelect');
    if (cs && cs.value) return cs.value;

    return null;
}

/* ── Product change ── */
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
    if (p.stock === 0)       strip.classList.add('zero');
    else if (p.stock <= 10)  strip.classList.add('low');
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

    if (!cid)             { alert(mr ? '⚠️ कृपया ग्राहक निवडा.'           : '⚠️ Please select a customer first.'); return; }
    if (!pid)             { alert(mr ? '⚠️ कृपया उत्पाद निवडा.'           : '⚠️ Please select a product.');         return; }
    if (!qty || qty <= 0) { alert(mr ? '⚠️ कृपया योग्य प्रमाण टाका.'     : '⚠️ Please enter a valid quantity.');   return; }
    if (!price || price <= 0) { alert(mr ? '⚠️ कृपया योग्य किंमत टाका.' : '⚠️ Please enter a valid unit price.'); return; }

    var p = getProduct(pid);
    if (!p) return;

    var alreadyQty = 0;
    tableRows.forEach(function (r) { if (r.productId === pid) alreadyQty += r.qty; });
    if (alreadyQty + qty > p.stock) {
        alert('⚠️ ' + (mr
            ? 'एकूण प्रमाण (' + (alreadyQty + qty) + ') उपलब्ध स्टॉकपेक्षा जास्त आहे (' + p.stock + ')'
            : 'Total quantity (' + (alreadyQty + qty) + ') exceeds available stock (' + p.stock + ') for: ' + p.name));
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
            '<td style="color:#888;font-size:12px;">' + (idx + 1) + '</td>' +
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

function submitSale() {
    var mr  = isMr();
    var cid = getSelectedCustomerId();
    if (!cid)                   { alert(mr ? '⚠️ कृपया ग्राहक निवडा.'          : '⚠️ Please select a customer.'); return; }
    if (tableRows.length === 0) { alert(mr ? '⚠️ किमान एक उत्पाद जोडा.'       : '⚠️ Please add at least one product.'); return; }

    var payMode = document.querySelector('input[name="payMode"]:checked');
    var pm = payMode ? payMode.value : 'CASH';

    var items = tableRows.map(function (r) {
        return { productId: r.productId, productName: r.productName, quantity: r.qty, unitPrice: r.unitPrice, amount: r.amount };
    });

    document.getElementById('customerIdInput').value  = cid;
    document.getElementById('itemsJsonInput').value   = JSON.stringify(items);
    document.getElementById('paymentModeInput').value = pm;
    document.getElementById('submitForm').submit();
}
</script>
</body>
</html>
