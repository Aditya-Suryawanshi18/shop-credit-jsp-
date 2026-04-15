<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, doa.DBConnection, doa.ShopConfig" %>
<%
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=Please login first");
        return;
    }
    String idStr = request.getParameter("id");
    if (idStr == null || idStr.trim().isEmpty()) {
        response.sendRedirect("view_customers.jsp");
        return;
    }
    int customerId = Integer.parseInt(idStr.trim());
    String custName  = "";
    String custPhone = "";
    double custCredit = 0;

    try (Connection conn = DBConnection.getConnection()) {
        PreparedStatement ps = conn.prepareStatement(
            "SELECT name, phone, credit FROM customers WHERE id = ?");
        ps.setInt(1, customerId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            custName   = rs.getString("name");
            custPhone  = rs.getString("phone");
            custCredit = rs.getDouble("credit");
        } else {
            response.sendRedirect("view_customers.jsp?error=Customer not found");
            return;
        }
    } catch (Exception e) {
        response.sendRedirect("view_customers.jsp?error=" + e.getMessage());
        return;
    }

    /* ── Load shop config for receipt header ── */
    ShopConfig shop = ShopConfig.getInstance();
    String shopEnglishName = shop.getEnglishName();
    String shopMarathiName = shop.getMarathiName();

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
    <title>Add Credit — <%= custName %></title>
    <link rel="stylesheet" href="css/content.css">
    <style>
        .customer-card {
            background: linear-gradient(135deg, #182542 0%, #2a5a8f 100%);
            color: #fff; border-radius: 14px; padding: 18px 24px; margin-bottom: 22px;
            display: flex; align-items: center; gap: 18px; flex-wrap: wrap;
            box-shadow: 0 6px 20px rgba(0,0,0,0.18);
        }
        .customer-card .avatar { width:50px;height:50px;background:rgba(255,255,255,0.15);border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:24px;border:2px solid rgba(255,255,255,0.3);flex-shrink:0; }
        .customer-card .cinfo { flex:1; }
        .customer-card .cinfo h3 { font-size:17px;font-weight:700;margin:0 0 3px; }
        .customer-card .cinfo p  { font-size:12px;color:#b8d4f0;margin:0; }
        .customer-card .credit-pill { background:rgba(255,255,255,0.13);border:1px solid rgba(255,255,255,0.25);border-radius:10px;padding:8px 18px;text-align:center; }
        .customer-card .credit-pill .lbl { font-size:10px;color:#90b8d4;text-transform:uppercase;letter-spacing:0.8px; }
        .customer-card .credit-pill .val { font-size:18px;font-weight:800;color:#7dffb3;margin-top:2px; }

        .main-layout { display:grid;grid-template-columns:320px 1fr;gap:20px;align-items:start; }
        @media (max-width:860px) { .main-layout { grid-template-columns:1fr; } }

        .input-panel { background:#fff;border-radius:14px;box-shadow:0 4px 16px rgba(0,0,0,0.09);overflow:hidden;position:sticky;top:10px; }
        .input-panel-header { background:linear-gradient(90deg,#2b0d73,#4a2fa0);color:#fff;padding:13px 18px;font-size:13px;font-weight:700;letter-spacing:0.5px; }
        .input-panel-body { padding:18px;display:flex;flex-direction:column;gap:14px; }
        .ip-group { display:flex;flex-direction:column;gap:5px; }
        .ip-group label { font-size:12px;font-weight:700;color:#373279;letter-spacing:0.3px; }
        .ip-group select, .ip-group input { padding:9px 11px;border:2px solid #c8b7f6;border-radius:8px;font-size:13px;color:#1a1a2a;background:#fff;outline:none;transition:border 0.2s;width:100%;-moz-appearance:textfield; }
        .ip-group select:focus, .ip-group input:focus { border-color:#7c73b8;box-shadow:0 0 0 3px rgba(124,115,184,0.12); }
        .ip-group input::-webkit-inner-spin-button, .ip-group input::-webkit-outer-spin-button { -webkit-appearance:none; }

        .stock-strip { display:none;align-items:center;gap:8px;background:#f0f4ff;border:1px solid #c8d8f8;border-radius:7px;padding:6px 12px;font-size:12px;color:#2b0d73;font-weight:600;margin-top:4px; }
        .stock-strip .snum { background:#2b0d73;color:#fff;border-radius:20px;padding:1px 10px;font-size:12px;font-weight:700; }
        .stock-strip.low  { background:#fff8e1;border-color:#ffe082;color:#7a5c00; }
        .stock-strip.low  .snum { background:#f5a623; }
        .stock-strip.zero { background:#ffebee;border-color:#ffcdd2;color:#b71c1c; }
        .stock-strip.zero .snum { background:#e53935; }

        .row-total-preview { background:#f5f3ff;border:1px dashed #c8b7f6;border-radius:8px;padding:9px 14px;font-size:13px;color:#2b0d73;font-weight:700;text-align:center;display:none; }
        .btn-add-to-table { width:100%;padding:11px;background:linear-gradient(135deg,#2b0d73,#4a2fa0);color:#fff;border:none;border-radius:9px;font-size:14px;font-weight:700;cursor:pointer;transition:opacity 0.2s,transform 0.15s;letter-spacing:0.4px; }
        .btn-add-to-table:hover { opacity:0.88;transform:scale(1.02); }

        .table-panel { background:#fff;border-radius:14px;box-shadow:0 4px 16px rgba(0,0,0,0.09);overflow:hidden; }
        .table-panel-header { background:linear-gradient(90deg,#182542,#2a5a8f);color:#fff;padding:13px 18px;font-size:13px;font-weight:700;letter-spacing:0.5px;display:flex;align-items:center;justify-content:space-between; }
        .txn-table { width:100%;border-collapse:collapse;font-size:13px; }
        .txn-table thead th { background:#f5f3ff;color:#373279;padding:10px 12px;text-align:center;font-weight:700;font-size:12px;letter-spacing:0.3px;border-bottom:2px solid #c8b7f6; }
        .txn-table tbody td { padding:9px 11px;border-bottom:1px solid #ede9ff;text-align:center;vertical-align:middle; }
        .txn-table tbody tr:last-child td { border-bottom:none; }
        .txn-table tbody tr:hover { background:#f7f5ff; }
        .txn-table tfoot td { padding:12px 14px;background:#2b0d73;color:#fff;font-weight:700;font-size:14px;text-align:right; }
        .txn-table tfoot td.grand-val { text-align:center;font-size:16px;color:#7dffb3; }
        .empty-msg td { padding:32px !important;color:#bbb;font-size:13px;font-style:italic;text-align:center !important; }
        .btn-remove { width:26px;height:26px;background:#ffebee;color:#e53935;border:none;border-radius:5px;font-size:14px;font-weight:700;cursor:pointer;display:inline-flex;align-items:center;justify-content:center;transition:background 0.2s;line-height:1; }
        .btn-remove:hover { background:#e53935;color:#fff; }
        .prod-tag { background:#e8f0fe;color:#1a56db;padding:3px 10px;border-radius:20px;font-size:12px;font-weight:600; }
        .qty-num { font-weight:700;color:#2b0d73; }
        .price-num { color:#555; }
        .total-num { font-weight:700;color:#1b5e20; }

        .grand-bar { display:flex;align-items:center;justify-content:space-between;background:linear-gradient(90deg,#1b5e20,#2e7d32);color:#fff;border-radius:10px;padding:13px 20px;margin-top:16px; }
        .grand-bar .g-label { font-size:13px;color:#a5d6a7;font-weight:600; }
        .grand-bar .g-val   { font-size:22px;font-weight:800;color:#e8f5e9; }
        .grand-bar .g-count { font-size:11px;color:#81c784;margin-top:1px; }
        .save-row { display:flex;gap:14px;margin-top:16px;justify-content:flex-end; }

        /* ══════════════════════════════
           RECEIPT MODAL
        ══════════════════════════════ */
        .receipt-modal {
            display: none;
            position: fixed; z-index: 1000;
            inset: 0;
            background: rgba(0,0,0,0.55);
            backdrop-filter: blur(5px);
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .receipt-modal.show { display: flex; animation: rcFadeIn 0.2s ease; }
        .receipt-modal-content {
            background: #fff;
            border-radius: 16px;
            width: 100%; max-width: 480px;
            max-height: 82vh;
            overflow-y: auto;
            box-shadow: 0 20px 60px rgba(0,0,0,0.35);
            animation: rcSlideUp 0.28s cubic-bezier(0.22,1,0.36,1);
        }
        .receipt-header {
            background: linear-gradient(135deg, #2b0d73 0%, #4a2fa0 100%);
            color: #fff;
            padding: 20px;
            text-align: center;
            border-bottom: 3px dashed rgba(255,255,255,0.15);
        }
        .receipt-header h2 { margin: 0; font-size: 18px; font-weight: 800; letter-spacing: 0.5px; }
        .receipt-header .receipt-shop { font-size: 13px; font-weight: 600; margin-top: 4px; color: rgba(255,255,255,0.75); }
        .receipt-body { padding: 20px; }
        .receipt-section { margin-bottom: 14px; padding-bottom: 12px; border-bottom: 1px solid #ede9ff; }
        .receipt-section:last-of-type { border-bottom: none; }
        .receipt-row { display: flex; justify-content: space-between; font-size: 13px; margin-bottom: 6px; }
        .receipt-row-label { font-weight: 600; color: #373279; }
        .receipt-row-value { text-align: right; color: #555; }
        .receipt-item-row {
            display: grid;
            grid-template-columns: 1fr 50px 70px 80px;
            gap: 6px;
            font-size: 12px;
            padding: 8px 0;
            border-bottom: 1px solid #f0eeff;
        }
        .receipt-item-row:last-child { border-bottom: none; }
        .receipt-item-row .col-name { color: #1a1a2a; font-weight: 600; }
        .receipt-item-row .col-qty  { text-align: center; color: #2b0d73; font-weight: 700; }
        .receipt-item-row .col-price { text-align: right; color: #555; }
        .receipt-item-row .col-amt  { text-align: right; font-weight: 700; color: #1b5e20; }
        .receipt-grand {
            display: flex;
            justify-content: space-between;
            padding: 12px 14px;
            background: linear-gradient(135deg, #2b0d73 0%, #4a2fa0 100%);
            color: #fff;
            border-radius: 10px;
            margin: 12px 0;
            font-weight: 700;
            font-size: 16px;
        }
        .receipt-grand .rg-label { color: rgba(255,255,255,0.7); font-size: 12px; display: block; margin-top: 2px; }
        .receipt-footer {
            text-align: center;
            font-size: 11px;
            color: #999;
            padding-top: 10px;
            border-top: 1px dashed #c8b7f6;
            margin-top: 2px;
        }
        .receipt-actions {
            display: flex;
            gap: 10px;
            padding: 14px 20px;
            border-top: 1px solid #ede9ff;
            background: #f9f7ff;
            border-radius: 0 0 16px 16px;
        }
        .btn-receipt-action {
            flex: 1;
            padding: 11px;
            border: none;
            border-radius: 9px;
            font-family: 'Outfit', sans-serif;
            font-size: 13px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.2s;
            white-space: nowrap;
        }
        .btn-receipt-print {
            background: linear-gradient(135deg, #2b0d73 0%, #4a2fa0 100%);
            color: #fff;
            box-shadow: 0 3px 12px rgba(43,13,115,0.28);
        }
        .btn-receipt-print:hover { transform: translateY(-2px); box-shadow: 0 5px 18px rgba(43,13,115,0.38); }
        .btn-receipt-skip {
            background: transparent;
            color: #666;
            border: 2px solid #c8b7f6;
        }
        .btn-receipt-skip:hover { background: #f0eeff; }

        @keyframes rcFadeIn  { from { opacity: 0; } to { opacity: 1; } }
        @keyframes rcSlideUp {
            from { transform: translateY(28px) scale(0.97); opacity: 0; }
            to   { transform: translateY(0) scale(1); opacity: 1; }
        }
    </style>
</head>
<body>
<div class="content-wrapper">

    <% if (request.getParameter("error") != null) { %>
    <div class="alert alert-error">❌ <%= request.getParameter("error") %></div>
    <% } %>

    <a href="view_customers.jsp" class="back-link" data-i18n="btn.back_customers">← Back to Customers</a>

    <!-- Customer Banner -->
    <div class="customer-card">
        <div class="avatar">👤</div>
        <div class="cinfo">
            <h3><%= custName %></h3>
            <p>📞 <%= custPhone %> &nbsp;|&nbsp; Customer ID #<%= customerId %></p>
        </div>
        <div class="credit-pill">
            <div class="lbl">
                <span class="lang-name-en">Current Credit</span>
                <span class="lang-name-mr" style="display:none;">सध्याची उधार</span>
            </div>
            <div class="val">₹ <%= String.format("%.2f", custCredit) %></div>
        </div>
    </div>

    <div class="main-layout">
        <!-- LEFT: Input Form -->
        <div class="input-panel">
            <div class="input-panel-header" data-i18n="ac.panel_hdr">➕ Add Product</div>
            <div class="input-panel-body">

                <div class="ip-group">
                    <label for="productId" data-i18n="ac.lbl_product">📦 Product <span style="color:#e53935;">*</span></label>
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
                    <label for="qty" data-i18n="ac.lbl_qty">🔢 Quantity <span style="color:#e53935;">*</span></label>
                    <input type="number" id="qty" placeholder="0" min="1"
                           oninput="updatePreview()" onchange="updatePreview()">
                </div>

                <div class="ip-group">
                    <label for="unitPrice" data-i18n="ac.lbl_price">💰 Price / Unit (₹) <span style="color:#e53935;">*</span></label>
                    <input type="number" id="unitPrice" placeholder="0.00" step="0.01" min="0.01"
                           oninput="updatePreview()" onchange="updatePreview()">
                </div>

                <div class="row-total-preview" id="rowTotalPreview">Row Total: ₹ 0.00</div>

                <button type="button" class="btn-add-to-table" onclick="addToTable()" data-i18n="ac.btn_add">
                    ➕ Add to Table
                </button>
            </div>
        </div>

        <!-- RIGHT: Transaction Table -->
        <div>
            <div class="table-panel">
                <div class="table-panel-header">
                    <span data-i18n="ac.table_hdr">🧾 Transaction Items</span>
                    <span id="itemCountBadge" style="background:rgba(255,255,255,0.15);border-radius:20px;padding:2px 12px;font-size:12px;">0 items</span>
                </div>
                <table class="txn-table">
                    <thead>
                        <tr>
                            <th data-i18n="ac.th_no">#</th>
                            <th data-i18n="ac.th_product">Product</th>
                            <th data-i18n="ac.th_qty">Qty</th>
                            <th data-i18n="ac.th_price">Price / Unit (₹)</th>
                            <th data-i18n="ac.th_total">Total (₹)</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody id="txnBody">
                        <tr class="empty-msg" id="emptyRow">
                            <td colspan="6" id="emptyMsgText">← Add products using the form on the left</td>
                        </tr>
                    </tbody>
                    <tfoot>
                        <tr>
                            <td colspan="4" style="text-align:right;color:#90b8d4;" data-i18n="ac.th_grand">Grand Total</td>
                            <td class="grand-val" id="footerGrand">₹ 0.00</td>
                            <td></td>
                        </tr>
                    </tfoot>
                </table>
            </div>

            <div class="grand-bar">
                <div>
                    <div class="g-label" data-i18n="ac.credit_label">TOTAL CREDIT TO ADD</div>
                    <div class="g-val" id="grandDisplay">₹ 0.00</div>
                    <div class="g-count" id="grandCount">0 item(s)</div>
                </div>
                <span style="font-size:32px;opacity:0.35;">💳</span>
            </div>

            <div class="save-row">
                <a href="view_customers.jsp" class="btn-clear"
                   style="text-decoration:none;display:inline-flex;align-items:center;justify-content:center;padding:10px 28px;"
                   data-i18n="btn.cancel">Cancel</a>
                <!-- Changed: calls showReceiptModal() instead of submitTransaction() -->
                <button type="button" class="btn-save" onclick="showReceiptModal()" data-i18n="ac.btn_save">
                    💾 Save &amp; View Receipt
                </button>
            </div>
        </div>
    </div>

    <!-- ══════════════════════════════
         RECEIPT MODAL
    ══════════════════════════════ -->
    <div class="receipt-modal" id="receiptModal">
        <div class="receipt-modal-content">

            <div class="receipt-header">
                <h2>🧾 CREDIT RECEIPT</h2>
                <div class="receipt-shop"><%= shopEnglishName %></div>
            </div>

            <div class="receipt-body">
                <!-- Customer Info -->
                <div class="receipt-section">
                    <div class="receipt-row">
                        <span class="receipt-row-label">Customer:</span>
                        <span class="receipt-row-value"><%= custName %></span>
                    </div>
                    <div class="receipt-row">
                        <span class="receipt-row-label">Phone:</span>
                        <span class="receipt-row-value">📞 <%= custPhone %></span>
                    </div>
                    <div class="receipt-row">
                        <span class="receipt-row-label">Date &amp; Time:</span>
                        <span class="receipt-row-value" id="receiptDateTime">—</span>
                    </div>
                </div>

                <!-- Items header -->
                <div class="receipt-section">
                    <div style="font-weight:700;font-size:12px;color:#373279;margin-bottom:8px;padding-bottom:6px;border-bottom:1px solid #ede9ff;display:grid;grid-template-columns:1fr 50px 70px 80px;gap:6px;">
                        <span>Product</span>
                        <span style="text-align:center;">Qty</span>
                        <span style="text-align:right;">Rate</span>
                        <span style="text-align:right;">Amount</span>
                    </div>
                    <div id="receiptItems"></div>
                </div>

                <!-- Grand total -->
                <div class="receipt-grand">
                    <div>
                        <span class="rg-label">TOTAL CREDIT ADDED</span>
                        <span id="receiptGrandTotal">₹ 0.00</span>
                    </div>
                    <span style="font-size:28px;opacity:0.5;">💳</span>
                </div>

                <!-- Footer -->
                <div class="receipt-footer">
                    <p style="margin:0;padding:6px 0;">Credit added to account</p>
                    <p style="margin:0;font-size:10px;color:#bbb;">खात्यावर उधार जमा केली</p>
                </div>
            </div>

            <!-- Actions -->
            <div class="receipt-actions">
                <button class="btn-receipt-action btn-receipt-print" onclick="printAndSave()">
                    🖨️
                    <span class="lang-name-en">Print &amp; Save</span>
                    <span class="lang-name-mr" style="display:none;">छापा आणि जतन करा</span>
                </button>
                <button class="btn-receipt-action btn-receipt-skip" onclick="skipAndSave()">
                    <span class="lang-name-en">Skip &amp; Save</span>
                    <span class="lang-name-mr" style="display:none;">वगळून जतन करा</span>
                </button>
            </div>

        </div>
    </div>

    <form id="submitForm" action="AddCreditServlet" method="post" style="display:none;">
        <input type="hidden" name="customerId" value="<%= customerId %>">
        <input type="hidden" name="itemsJson" id="itemsJsonInput">
    </form>
</div>

<script src="js/i18n.js"></script>
<script>
var PRODUCTS   = <%= productsJson.toString() %>;
var SHOP_NAME  = "<%= shopEnglishName.replace("\"","\\\"") %>";
var CUST_NAME  = "<%= custName.replace("\"","\\\"") %>";
var CUST_PHONE = "<%= custPhone %>";
var tableRows  = [];
var rowSeq     = 0;

function getLang() { return (typeof i18n !== 'undefined') ? i18n.getLang() : 'en'; }
function isMr()    { return getLang() === 'mr'; }

// ── Populate product dropdown ─────────────────────────────────────────
(function() {
    var sel = document.getElementById('productId');
    var ph  = document.getElementById('prodPlaceholder');
    ph.text = isMr() ? '— उत्पाद निवडा —' : '— Select product —';
    PRODUCTS.forEach(function(p) {
        var opt = document.createElement('option');
        opt.value = p.id;
        opt.text  = p.name + (isMr() ? '  (स्टॉक: ' + p.stock + ')' : '  (Stock: ' + p.stock + ')');
        opt.setAttribute('data-stock', p.stock);
        opt.setAttribute('data-name',  p.name);
        sel.appendChild(opt);
    });
})();

function getProduct(id) {
    for (var i = 0; i < PRODUCTS.length; i++) {
        if (PRODUCTS[i].id == id) return PRODUCTS[i];
    }
    return null;
}

function onProductChange() {
    var sel   = document.getElementById('productId');
    var pid   = sel.value;
    var strip = document.getElementById('stockStrip');
    var snum  = document.getElementById('stockNum');
    if (!pid) { strip.style.display = 'none'; return; }
    var p = getProduct(pid);
    if (!p) return;
    snum.textContent = p.stock;
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
    var prev  = document.getElementById('rowTotalPreview');
    if (qty > 0 && price > 0) {
        prev.style.display = 'block';
        prev.textContent   = (isMr() ? 'एकूण: ₹ ' : 'Row Total: ₹ ') + (qty * price).toFixed(2);
    } else {
        prev.style.display = 'none';
    }
}

function addToTable() {
    var sel   = document.getElementById('productId');
    var pid   = parseInt(sel.value, 10);
    var qty   = parseInt(document.getElementById('qty').value, 10);
    var price = parseFloat(document.getElementById('unitPrice').value);
    var mr    = isMr();

    if (!pid)              { alert(mr ? '⚠️ कृपया उत्पाद निवडा.'         : '⚠️ Please select a product.');           return; }
    if (!qty || qty <= 0)  { alert(mr ? '⚠️ कृपया योग्य प्रमाण टाका.'   : '⚠️ Please enter a valid quantity.');     return; }
    if (!price || price <= 0) { alert(mr ? '⚠️ कृपया योग्य किंमत टाका.' : '⚠️ Please enter a valid unit price.');   return; }

    var p = getProduct(pid);
    if (!p) { alert(mr ? '⚠️ उत्पाद सापडले नाही.' : '⚠️ Product not found.'); return; }

    var alreadyQty = 0;
    tableRows.forEach(function(r) { if (r.productId === pid) alreadyQty += r.qty; });
    if (alreadyQty + qty > p.stock) {
        alert('⚠️ ' + (mr
            ? 'एकूण प्रमाण (' + (alreadyQty + qty) + ') उपलब्ध स्टॉकपेक्षा जास्त आहे (' + p.stock + ') : ' + p.name
            : 'Total quantity (' + (alreadyQty + qty) + ') exceeds available stock (' + p.stock + ') for: ' + p.name));
        return;
    }

    var rid    = ++rowSeq;
    var amount = parseFloat((qty * price).toFixed(2));
    tableRows.push({ rid: rid, productId: pid, productName: p.name, qty: qty, unitPrice: price, amount: amount, stock: p.stock });
    renderTable();
    resetForm();
}

function renderTable() {
    var tbody = document.getElementById('txnBody');
    var mr    = isMr();
    tbody.innerHTML = '';
    if (tableRows.length === 0) {
        tbody.innerHTML = '<tr class="empty-msg"><td colspan="6">' +
            (mr ? '← डाव्या बाजूच्या फॉर्मचा वापर करून उत्पादे जोडा' : '← Add products using the form on the left') +
            '</td></tr>';
        updateGrandTotal(); return;
    }
    tableRows.forEach(function(r, idx) {
        var tr = document.createElement('tr');
        tr.innerHTML =
            '<td style="color:#888;font-size:12px;">' + (idx + 1) + '</td>' +
            '<td><span class="prod-tag">📦 ' + r.productName + '</span></td>' +
            '<td class="qty-num">' + r.qty + '</td>' +
            '<td class="price-num">₹ ' + r.unitPrice.toFixed(2) + '</td>' +
            '<td class="total-num">₹ ' + r.amount.toFixed(2) + '</td>' +
            '<td><button class="btn-remove" onclick="removeRow(' + r.rid + ')" title="Remove">✕</button></td>';
        tbody.appendChild(tr);
    });
    updateGrandTotal();
}

function removeRow(rid) {
    tableRows = tableRows.filter(function(r) { return r.rid !== rid; });
    renderTable();
}

function updateGrandTotal() {
    var grand = 0;
    var mr    = isMr();
    tableRows.forEach(function(r) { grand += r.amount; });
    document.getElementById('footerGrand').textContent = '₹ ' + grand.toFixed(2);
    document.getElementById('grandDisplay').textContent = '₹ ' + grand.toFixed(2);
    var n = tableRows.length;
    document.getElementById('grandCount').textContent     = n + (mr ? ' आयटम' : ' item(s)');
    document.getElementById('itemCountBadge').textContent = n + (mr ? ' आयटम' : ' item' + (n !== 1 ? 's' : ''));
}

function resetForm() {
    document.getElementById('productId').value = '';
    document.getElementById('qty').value       = '';
    document.getElementById('unitPrice').value = '';
    document.getElementById('stockStrip').style.display = 'none';
    document.getElementById('rowTotalPreview').style.display = 'none';
}

// ══════════════════════════════════════════════════════
//  RECEIPT LOGIC
// ══════════════════════════════════════════════════════

function showReceiptModal() {
    var mr = isMr();
    if (tableRows.length === 0) {
        alert(mr ? '⚠️ जतन करण्यापूर्वी किमान एक उत्पाद जोडा.' : '⚠️ Please add at least one product to the table before saving.');
        return;
    }

    // Set date/time
    var now = new Date();
    document.getElementById('receiptDateTime').textContent =
        now.toLocaleString(mr ? 'mr-IN' : 'en-IN', {
            year: 'numeric', month: '2-digit', day: '2-digit',
            hour: '2-digit', minute: '2-digit'
        });

    // Build items HTML
    var grand = 0;
    var itemsHTML = '';
    tableRows.forEach(function(r) {
        grand += r.amount;
        itemsHTML +=
            '<div class="receipt-item-row">' +
            '<span class="col-name">' + r.productName + '</span>' +
            '<span class="col-qty">'  + r.qty + '</span>' +
            '<span class="col-price">₹' + r.unitPrice.toFixed(2) + '</span>' +
            '<span class="col-amt">₹'  + r.amount.toFixed(2)    + '</span>' +
            '</div>';
    });
    document.getElementById('receiptItems').innerHTML     = itemsHTML;
    document.getElementById('receiptGrandTotal').textContent = '₹ ' + grand.toFixed(2);

    // Show modal
    document.getElementById('receiptModal').classList.add('show');
}

function printAndSave() {
    // Build print window
    var mr        = isMr();
    var shopName  = SHOP_NAME;
    var grand     = 0;
    var itemsHTML = '';
    tableRows.forEach(function(r) {
        grand += r.amount;
        var bg = (itemsHTML.split('<tr').length % 2 === 0) ? 'background:#f5f3ff;' : '';
        itemsHTML +=
            '<tr style="' + bg + '">' +
            '<td style="padding:8px 10px;border-bottom:1px solid #ede9ff;">' + r.productName + '</td>' +
            '<td style="padding:8px 10px;border-bottom:1px solid #ede9ff;text-align:center;font-weight:700;color:#2b0d73;">' + r.qty + '</td>' +
            '<td style="padding:8px 10px;border-bottom:1px solid #ede9ff;text-align:right;">₹' + r.unitPrice.toFixed(2) + '</td>' +
            '<td style="padding:8px 10px;border-bottom:1px solid #ede9ff;text-align:right;font-weight:700;color:#1b5e20;">₹' + r.amount.toFixed(2) + '</td>' +
            '</tr>';
    });

    var now     = new Date();
    var dateStr = now.toLocaleString('en-IN', {
        year:'numeric', month:'2-digit', day:'2-digit',
        hour:'2-digit', minute:'2-digit'
    });

    var html =
        '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Credit Receipt</title>' +
        '<style>body{font-family:Arial,sans-serif;margin:30px;color:#0d1b2a;font-size:13px;}' +
        '.hdr{text-align:center;border-bottom:3px double #2b0d73;padding-bottom:14px;margin-bottom:16px;}' +
        '.shop{font-size:22px;font-weight:800;letter-spacing:2px;text-transform:uppercase;color:#2b0d73;}' +
        '.ttl{font-size:13px;font-weight:600;color:#4a5568;margin-top:4px;}' +
        '.info{background:#f5f3ff;border:1px solid #c8b7f6;border-radius:6px;padding:10px 14px;margin-bottom:14px;display:grid;grid-template-columns:1fr 1fr;gap:6px;}' +
        '.il{font-size:9px;font-weight:700;color:#94a3b8;text-transform:uppercase;letter-spacing:0.8px;}' +
        '.iv{font-size:13px;font-weight:700;color:#0d1b2a;}' +
        'table{width:100%;border-collapse:collapse;}' +
        'th{background:#2b0d73;color:#fff;padding:8px 10px;text-align:left;font-size:11px;text-transform:uppercase;letter-spacing:0.5px;}' +
        'tfoot td{background:#f5f3ff;font-weight:700;border-top:2px solid #2b0d73;padding:9px 10px;}' +
        '.footer{margin-top:14px;text-align:center;font-size:10px;color:#94a3b8;border-top:1px dashed #c8b7f6;padding-top:8px;}' +
        '@media print{body{margin:12px;}}</style></head><body>' +
        '<div class="hdr"><div class="shop">' + shopName + '</div>' +
        '<div class="ttl">🧾 Credit Receipt</div>' +
        '<div style="font-size:11px;color:#94a3b8;margin-top:4px;">' + dateStr + '</div></div>' +
        '<div class="info">' +
        '<div><div class="il">Customer</div><div class="iv">' + CUST_NAME + '</div></div>' +
        '<div><div class="il">Phone</div><div class="iv">' + CUST_PHONE + '</div></div>' +
        '</div>' +
        '<table><thead><tr><th>Product</th><th style="text-align:center;">Qty</th><th style="text-align:right;">Rate (₹)</th><th style="text-align:right;">Amount (₹)</th></tr></thead>' +
        '<tbody>' + itemsHTML + '</tbody>' +
        '<tfoot><tr><td colspan="3" style="text-align:right;">Total Credit Added</td>' +
        '<td style="text-align:right;font-size:15px;">₹ ' + grand.toFixed(2) + '</td></tr></tfoot></table>' +
        '<div class="footer">' + shopName + ' · Credit added to account · ' + dateStr + '</div>' +
        '</body></html>';

    var pw = window.open('', '', 'height=600,width=480');
    pw.document.write(html);
    pw.document.close();
    pw.print();

    // Save after a short delay to let print dialog open
    setTimeout(function() { doSave(); }, 400);
}

function skipAndSave() {
    doSave();
}

function doSave() {
    var items = tableRows.map(function(r) {
        return { productId: r.productId, productName: r.productName, quantity: r.qty, unitPrice: r.unitPrice, amount: r.amount };
    });
    document.getElementById('itemsJsonInput').value = JSON.stringify(items);
    document.getElementById('receiptModal').classList.remove('show');
    document.getElementById('submitForm').submit();
}

// Close modal on backdrop click
document.getElementById('receiptModal').addEventListener('click', function(e) {
    if (e.target === this) this.classList.remove('show');
});
</script>
</body>
</html>
