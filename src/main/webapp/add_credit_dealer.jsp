<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, doa.DBConnection" %>
<%
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=Please login first");
        return;
    }
    String idStr = request.getParameter("id");
    if (idStr == null || idStr.trim().isEmpty()) {
        response.sendRedirect("view_dealers.jsp");
        return;
    }
    int dealerId = Integer.parseInt(idStr.trim());
    String dealerName  = "";
    String dealerPhone = "";
    double dealerCredit = 0;

    try (Connection conn = DBConnection.getConnection()) {
        PreparedStatement ps = conn.prepareStatement(
            "SELECT name, phone, credit FROM dealers WHERE id = ?");
        ps.setInt(1, dealerId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            dealerName   = rs.getString("name");
            dealerPhone  = rs.getString("phone");
            dealerCredit = rs.getDouble("credit");
        } else {
            response.sendRedirect("view_dealers.jsp?error=Dealer not found");
            return;
        }
    } catch (Exception e) {
        response.sendRedirect("view_dealers.jsp?error=" + e.getMessage());
        return;
    }

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
    <title>Add Credit — <%= dealerName %></title>
    <link rel="stylesheet" href="css/content.css">
    <style>
        .dealer-card { background:linear-gradient(135deg,#7a3800 0%,#d4681a 100%);color:#fff;border-radius:14px;padding:18px 24px;margin-bottom:22px;display:flex;align-items:center;gap:18px;flex-wrap:wrap;box-shadow:0 6px 20px rgba(0,0,0,0.18); }
        .dealer-card .avatar { width:50px;height:50px;background:rgba(255,255,255,0.15);border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:24px;border:2px solid rgba(255,255,255,0.3);flex-shrink:0; }
        .dealer-card .cinfo { flex:1; }
        .dealer-card .cinfo h3 { font-size:17px;font-weight:700;margin:0 0 3px; }
        .dealer-card .cinfo p  { font-size:12px;color:#ffd8b0;margin:0; }
        .dealer-card .credit-pill { background:rgba(255,255,255,0.13);border:1px solid rgba(255,255,255,0.25);border-radius:10px;padding:8px 18px;text-align:center; }
        .dealer-card .credit-pill .lbl { font-size:10px;color:#ffd0a0;text-transform:uppercase;letter-spacing:0.8px; }
        .dealer-card .credit-pill .val { font-size:18px;font-weight:800;color:#ffe082;margin-top:2px; }

        .main-layout { display:grid;grid-template-columns:320px 1fr;gap:20px;align-items:start; }
        @media (max-width:860px) { .main-layout { grid-template-columns:1fr; } }

        .input-panel { background:#fff;border-radius:14px;box-shadow:0 4px 16px rgba(0,0,0,0.09);overflow:hidden;position:sticky;top:10px; }
        .input-panel-header { background:linear-gradient(90deg,#7a3800,#d4681a);color:#fff;padding:13px 18px;font-size:13px;font-weight:700;letter-spacing:0.5px; }
        .input-panel-body { padding:18px;display:flex;flex-direction:column;gap:14px; }
        .ip-group { display:flex;flex-direction:column;gap:5px; }
        .ip-group label { font-size:12px;font-weight:700;color:#7a3800;letter-spacing:0.3px; }
        .ip-group select, .ip-group input { padding:9px 11px;border:2px solid #f5c89a;border-radius:8px;font-size:13px;color:#1a1a2a;background:#fff;outline:none;transition:border 0.2s;width:100%;-moz-appearance:textfield; }
        .ip-group select:focus, .ip-group input:focus { border-color:#d4681a;box-shadow:0 0 0 3px rgba(212,104,26,0.12); }
        .ip-group input::-webkit-inner-spin-button, .ip-group input::-webkit-outer-spin-button { -webkit-appearance:none; }

        .stock-strip { display:none;align-items:center;gap:8px;background:#e8f5e9;border:1px solid #a5d6a7;border-radius:7px;padding:6px 12px;font-size:12px;color:#1b5e20;font-weight:600;margin-top:4px; }
        .stock-strip .snum { background:#2e7d32;color:#fff;border-radius:20px;padding:1px 10px;font-size:12px;font-weight:700; }
        .after-strip { display:none;align-items:center;gap:8px;background:#f0f4ff;border:1px solid #c8d8f8;border-radius:7px;padding:6px 12px;font-size:12px;color:#2b0d73;font-weight:600;margin-top:4px; }
        .after-strip .anum { background:#4caf50;color:#fff;border-radius:20px;padding:1px 10px;font-size:12px;font-weight:700; }
        .row-total-preview { background:#fff8f0;border:1px dashed #f5c89a;border-radius:8px;padding:9px 14px;font-size:13px;color:#7a3800;font-weight:700;text-align:center;display:none; }
        .btn-add-to-table { width:100%;padding:11px;background:linear-gradient(135deg,#d4681a,#f5a623);color:#fff;border:none;border-radius:9px;font-size:14px;font-weight:700;cursor:pointer;transition:opacity 0.2s,transform 0.15s;letter-spacing:0.4px; }
        .btn-add-to-table:hover { opacity:0.88;transform:scale(1.02); }

        .table-panel { background:#fff;border-radius:14px;box-shadow:0 4px 16px rgba(0,0,0,0.09);overflow:hidden; }
        .table-panel-header { background:linear-gradient(90deg,#7a3800,#d4681a);color:#fff;padding:13px 18px;font-size:13px;font-weight:700;letter-spacing:0.5px;display:flex;align-items:center;justify-content:space-between; }
        .txn-table { width:100%;border-collapse:collapse;font-size:13px; }
        .txn-table thead th { background:#fff8f0;color:#7a3800;padding:10px 12px;text-align:center;font-weight:700;font-size:12px;letter-spacing:0.3px;border-bottom:2px solid #f5dab0; }
        .txn-table tbody td { padding:9px 11px;border-bottom:1px solid #fff3e0;text-align:center;vertical-align:middle; }
        .txn-table tbody tr:last-child td { border-bottom:none; }
        .txn-table tbody tr:hover { background:#fffaf5; }
        .txn-table tfoot td { padding:12px 14px;background:#7a3800;color:#fff;font-weight:700;font-size:14px;text-align:right; }
        .txn-table tfoot td.grand-val { text-align:center;font-size:16px;color:#ffe082; }
        .empty-msg td { padding:32px !important;color:#bbb;font-size:13px;font-style:italic;text-align:center !important; }
        .btn-remove { width:26px;height:26px;background:#ffebee;color:#e53935;border:none;border-radius:5px;font-size:14px;font-weight:700;cursor:pointer;display:inline-flex;align-items:center;justify-content:center;transition:background 0.2s;line-height:1; }
        .btn-remove:hover { background:#e53935;color:#fff; }
        .prod-tag { background:#fff3e0;color:#e65100;padding:3px 10px;border-radius:20px;font-size:12px;font-weight:600; }
        .qty-num { font-weight:700;color:#2e7d32; }
        .price-num { color:#555; }
        .total-num { font-weight:700;color:#1b5e20; }
        .after-num { font-size:12px;color:#2e7d32;font-weight:600; }

        .grand-bar { display:flex;align-items:center;justify-content:space-between;background:linear-gradient(90deg,#7a3800,#d4681a);color:#fff;border-radius:10px;padding:13px 20px;margin-top:16px; }
        .grand-bar .g-label { font-size:13px;color:#ffd8b0;font-weight:600; }
        .grand-bar .g-val   { font-size:22px;font-weight:800;color:#ffe082; }
        .grand-bar .g-count { font-size:11px;color:#ffc070;margin-top:1px; }
        .save-row { display:flex;gap:14px;margin-top:16px;justify-content:flex-end;flex-wrap:wrap;align-items:center; }

        /* ── Upload Bill button ── */
        .btn-upload-bill {
            display:inline-flex;align-items:center;gap:8px;
            padding:10px 20px;
            background:#fff;
            border:2px solid #f5c89a;
            border-radius:9px;
            font-family:'Outfit',sans-serif;
            font-size:14px;font-weight:700;
            color:#7a3800;cursor:pointer;
            transition:all 0.2s;
            white-space:nowrap;
        }
        .btn-upload-bill:hover { background:#fff3e0;border-color:#d4681a; }
        .btn-upload-bill.has-file { background:#e8f5e9;border-color:#a5d6a7;color:#1b5e20; }

        /* ── Bill preview strip ── */
        .bill-preview-strip {
            display:none;align-items:center;gap:10px;
            margin-top:10px;
            background:#fff8f0;
            border:1px solid #f5c89a;
            border-radius:8px;
            padding:9px 14px;
            font-size:13px;color:#7a3800;
        }
        .bill-preview-strip .bill-name { font-weight:600;flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap; }
        .bill-preview-strip .bill-size { font-size:11px;color:#aaa;white-space:nowrap; }
        .btn-clear-bill {
            width:24px;height:24px;background:#ffebee;color:#e53935;
            border:none;border-radius:5px;font-size:13px;font-weight:700;
            cursor:pointer;display:inline-flex;align-items:center;justify-content:center;
            flex-shrink:0;transition:background 0.2s;line-height:1;
        }
        .btn-clear-bill:hover { background:#e53935;color:#fff; }
    </style>
</head>
<body>
<div class="content-wrapper">

    <% if (request.getParameter("error") != null) { %>
    <div class="alert alert-error">❌ <%= request.getParameter("error") %></div>
    <% } %>

    <a href="view_dealers.jsp" class="back-link" data-i18n="btn.back_dealers">← Back to Dealers</a>

    <!-- Dealer Banner -->
    <div class="dealer-card">
        <div class="avatar">🏬</div>
        <div class="cinfo">
            <h3><%= dealerName %></h3>
            <p>📞 <%= dealerPhone %> &nbsp;|&nbsp; Dealer ID #<%= dealerId %></p>
        </div>
        <div class="credit-pill">
            <div class="lbl">
                <span class="lang-name-en">Current Credit</span>
                <span class="lang-name-mr" style="display:none;">सध्याची उधार</span>
            </div>
            <div class="val">₹ <%= String.format("%.2f", dealerCredit) %></div>
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
                        <span class="lang-name-en">Current Stock:</span>
                        <span class="lang-name-mr" style="display:none;">सध्याचा स्टॉक:</span>
                        <span class="snum" id="stockNum">0</span>
                    </div>
                </div>

                <div class="ip-group">
                    <label for="qty">
                        🔢
                        <span class="lang-name-en">Quantity Supplied</span>
                        <span class="lang-name-mr" style="display:none;">पुरवलेले प्रमाण</span>
                        <span style="color:#e53935;">*</span>
                    </label>
                    <input type="number" id="qty" placeholder="0" min="1"
                           oninput="updatePreview()" onchange="updatePreview()">
                    <div class="after-strip" id="afterStrip">
                        <span class="lang-name-en">Stock after save:</span>
                        <span class="lang-name-mr" style="display:none;">जतनानंतर स्टॉक:</span>
                        <span class="anum" id="afterNum">—</span>
                    </div>
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
                    <span>
                        <span class="lang-name-en">🧾 Supplied Items</span>
                        <span class="lang-name-mr" style="display:none;">🧾 पुरवलेली यादी</span>
                    </span>
                    <span id="itemCountBadge" style="background:rgba(255,255,255,0.15);border-radius:20px;padding:2px 12px;font-size:12px;">0 items</span>
                </div>
                <table class="txn-table">
                    <thead>
                        <tr>
                            <th data-i18n="ac.th_no">#</th>
                            <th data-i18n="ac.th_product">Product</th>
                            <th>
                                <span class="lang-name-en">Qty Supplied</span>
                                <span class="lang-name-mr" style="display:none;">पुरवलेले प्रमाण</span>
                            </th>
                            <th data-i18n="ac.th_price">Price / Unit (₹)</th>
                            <th data-i18n="ac.th_total">Total (₹)</th>
                            <th>
                                <span class="lang-name-en">Stock After</span>
                                <span class="lang-name-mr" style="display:none;">नंतरचा स्टॉक</span>
                            </th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody id="txnBody">
                        <tr class="empty-msg"><td colspan="7" id="emptyMsgText">← Add products using the form on the left</td></tr>
                    </tbody>
                    <tfoot>
                        <tr>
                            <td colspan="4" style="text-align:right;color:#ffd0a0;" data-i18n="ac.th_grand">Grand Total</td>
                            <td class="grand-val" id="footerGrand">₹ 0.00</td>
                            <td colspan="2"></td>
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
                <span style="font-size:32px;opacity:0.35;">📦</span>
            </div>

            <!-- Save Row with Upload Bill button -->
            <div class="save-row">
                <a href="view_dealers.jsp" class="btn-clear"
                   style="text-decoration:none;display:inline-flex;align-items:center;justify-content:center;padding:10px 28px;"
                   data-i18n="btn.cancel">Cancel</a>

                <!-- Upload Bill button -->
                <label id="uploadBillBtn" class="btn-upload-bill" title="Upload PDF or image bill">
                    📎
                    <span class="lang-name-en">Upload Bill</span>
                    <span class="lang-name-mr" style="display:none;">बिल अपलोड करा</span>
                    <input type="file" id="billFileInput" accept=".pdf,image/*"
                           style="display:none;" onchange="onBillFileSelected(this)">
                </label>

                <button type="button" class="btn-save" onclick="submitTransaction()">
                    💾 <span class="lang-name-en">Save Credit &amp; Update Stock</span>
                    <span class="lang-name-mr" style="display:none;">उधार जतन करा &amp; स्टॉक अपडेट करा</span>
                </button>
            </div>

            <!-- Bill preview strip (shown after file selected) -->
            <div class="bill-preview-strip" id="billPreviewStrip">
                <span>📎</span>
                <span class="bill-name" id="billFileName">—</span>
                <span class="bill-size" id="billFileSize"></span>
                <button class="btn-clear-bill" onclick="clearBill()" title="Remove file">✕</button>
            </div>
        </div>
    </div>

    <form id="submitForm" action="AddDealerCreditServlet" method="post" style="display:none;">
        <input type="hidden" name="dealerId" value="<%= dealerId %>">
        <input type="hidden" name="itemsJson" id="itemsJsonInput">
    </form>
</div>

<script src="js/i18n.js"></script>
<script>
var PRODUCTS = <%= productsJson.toString() %>;
var DEALER_ID = <%= dealerId %>;
var tableRows = [];
var rowSeq = 0;
var currentStock = 0;
var billFileData = null;   // { name, size, type, base64 }

function getLang() { return (typeof i18n !== 'undefined') ? i18n.getLang() : 'en'; }
function isMr()    { return getLang() === 'mr'; }

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
    var sel = document.getElementById('productId');
    var pid = sel.value;
    var strip = document.getElementById('stockStrip');
    if (!pid) { strip.style.display = 'none'; return; }
    var p = getProduct(pid);
    if (!p) return;
    currentStock = p.stock;
    document.getElementById('stockNum').textContent = p.stock;
    strip.style.display = 'flex';
    document.getElementById('qty').value = '';
    document.getElementById('afterStrip').style.display = 'none';
    updatePreview();
}

function updatePreview() {
    var qty   = parseFloat(document.getElementById('qty').value)       || 0;
    var price = parseFloat(document.getElementById('unitPrice').value) || 0;
    var prev  = document.getElementById('rowTotalPreview');
    var mr    = isMr();
    if (qty > 0 && price > 0) {
        prev.style.display = 'block';
        prev.textContent   = (mr ? 'एकूण: ₹ ' : 'Row Total: ₹ ') + (qty * price).toFixed(2);
    } else {
        prev.style.display = 'none';
    }
    var afterStrip = document.getElementById('afterStrip');
    if (qty > 0 && document.getElementById('productId').value) {
        document.getElementById('afterNum').textContent = (currentStock + parseInt(qty)) + (mr ? ' नग' : ' units');
        afterStrip.style.display = 'flex';
    } else {
        afterStrip.style.display = 'none';
    }
}

function addToTable() {
    var sel   = document.getElementById('productId');
    var pid   = parseInt(sel.value, 10);
    var qty   = parseInt(document.getElementById('qty').value, 10);
    var price = parseFloat(document.getElementById('unitPrice').value);
    var mr    = isMr();
    if (!pid)              { alert(mr ? '⚠️ कृपया उत्पाद निवडा.'         : '⚠️ Please select a product.');          return; }
    if (!qty || qty <= 0)  { alert(mr ? '⚠️ कृपया योग्य प्रमाण टाका.'   : '⚠️ Please enter a valid quantity.');    return; }
    if (!price || price <= 0) { alert(mr ? '⚠️ कृपया योग्य किंमत टाका.' : '⚠️ Please enter a valid unit price.');  return; }
    var p = getProduct(pid);
    if (!p) { alert(mr ? '⚠️ उत्पाद सापडले नाही.' : '⚠️ Product not found.'); return; }
    var rid = ++rowSeq;
    var amount = parseFloat((qty * price).toFixed(2));
    var stockAfter = p.stock + qty;
    var existingIdx = -1;
    tableRows.forEach(function(r, i) { if (r.productId === pid) existingIdx = i; });
    if (existingIdx >= 0) {
        tableRows[existingIdx].qty       += qty;
        tableRows[existingIdx].amount    += amount;
        tableRows[existingIdx].stockAfter = p.stock + tableRows[existingIdx].qty;
    } else {
        tableRows.push({ rid: rid, productId: pid, productName: p.name, qty: qty, unitPrice: price, amount: amount, stockAfter: stockAfter });
    }
    renderTable(); resetForm();
}

function renderTable() {
    var tbody = document.getElementById('txnBody');
    var mr    = isMr();
    tbody.innerHTML = '';
    if (tableRows.length === 0) {
        tbody.innerHTML = '<tr class="empty-msg"><td colspan="7">' +
            (mr ? '← डाव्या बाजूच्या फॉर्मचा वापर करून उत्पादे जोडा' : '← Add products using the form on the left') +
            '</td></tr>';
        updateGrandTotal(); return;
    }
    tableRows.forEach(function(r, idx) {
        var tr = document.createElement('tr');
        tr.innerHTML =
            '<td style="color:#888;font-size:12px;">' + (idx + 1) + '</td>' +
            '<td><span class="prod-tag">📦 ' + r.productName + '</span></td>' +
            '<td class="qty-num">↑ ' + r.qty + '</td>' +
            '<td class="price-num">₹ ' + r.unitPrice.toFixed(2) + '</td>' +
            '<td class="total-num">₹ ' + r.amount.toFixed(2) + '</td>' +
            '<td class="after-num">' + r.stockAfter + (mr ? ' नग' : ' units') + '</td>' +
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
    var grand = 0; var mr = isMr();
    tableRows.forEach(function(r) { grand += r.amount; });
    document.getElementById('footerGrand').textContent  = '₹ ' + grand.toFixed(2);
    document.getElementById('grandDisplay').textContent = '₹ ' + grand.toFixed(2);
    var n = tableRows.length;
    document.getElementById('grandCount').textContent   = n + (mr ? ' आयटम' : ' item(s)');
    document.getElementById('itemCountBadge').textContent = n + (mr ? ' आयटम' : ' item' + (n !== 1 ? 's' : ''));
}

function resetForm() {
    document.getElementById('productId').value  = '';
    document.getElementById('qty').value        = '';
    document.getElementById('unitPrice').value  = '';
    document.getElementById('stockStrip').style.display  = 'none';
    document.getElementById('afterStrip').style.display  = 'none';
    document.getElementById('rowTotalPreview').style.display = 'none';
    currentStock = 0;
}

// ── Upload Bill ────────────────────────────────────────────────────────────

function onBillFileSelected(input) {
    var file = input.files[0];
    if (!file) return;

    var maxSize = 5 * 1024 * 1024; // 5 MB
    if (file.size > maxSize) {
        var mr = isMr();
        alert(mr ? '⚠️ फाइल खूप मोठी आहे. जास्तीत जास्त 5 MB परवानगी आहे.' : '⚠️ File too large. Maximum 5 MB allowed.');
        input.value = '';
        return;
    }

    var reader = new FileReader();
    reader.onload = function(e) {
        billFileData = {
            name:   file.name,
            size:   file.size,
            type:   file.type,
            base64: e.target.result   // full data URL
        };
        document.getElementById('billFileName').textContent = file.name;
        document.getElementById('billFileSize').textContent = (file.size / 1024).toFixed(1) + ' KB';
        document.getElementById('billPreviewStrip').style.display = 'flex';
        document.getElementById('uploadBillBtn').classList.add('has-file');
    };
    reader.readAsDataURL(file);
}

function clearBill() {
    billFileData = null;
    document.getElementById('billFileInput').value = '';
    document.getElementById('billPreviewStrip').style.display = 'none';
    document.getElementById('uploadBillBtn').classList.remove('has-file');
}

function saveBillToLocalStorage(dealerId, grandTotal) {
    if (!billFileData) return;

    var STORAGE_KEY = 'dealer_bills';
    var bills = [];
    try {
        var existing = localStorage.getItem(STORAGE_KEY);
        if (existing) bills = JSON.parse(existing);
        if (!Array.isArray(bills)) bills = [];
    } catch(e) { bills = []; }

    var entry = {
        id:        Date.now(),
        dealerId:  dealerId,
        dealerName: '<%= dealerName.replace("'", "\\'") %>',
        amount:    parseFloat(grandTotal.toFixed(2)),
        date:      new Date().toISOString(),
        fileName:  billFileData.name,
        fileType:  billFileData.type,
        fileSize:  billFileData.size,
        fileData:  billFileData.base64
    };

    bills.unshift(entry);   // newest first

    // Keep only last 50 bills to avoid storage overflow
    if (bills.length > 50) bills = bills.slice(0, 50);

    try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(bills));
    } catch(e) {
        // Storage quota exceeded — try without file data
        try {
            entry.fileData = null;
            entry.storageError = 'File data omitted due to storage quota';
            bills[0] = entry;
            localStorage.setItem(STORAGE_KEY, JSON.stringify(bills));
        } catch(e2) {
            var mr = isMr();
            alert(mr
                ? '⚠️ बिल जतन केले, परंतु स्थानिक स्टोरेज भरले आहे.'
                : '⚠️ Bill saved to transaction but local storage is full.');
        }
    }
}

// ── Submit ─────────────────────────────────────────────────────────────────

function submitTransaction() {
    var mr = isMr();
    if (tableRows.length === 0) {
        alert(mr ? '⚠️ जतन करण्यापूर्वी किमान एक उत्पाद जोडा.' : '⚠️ Please add at least one product to the table before saving.');
        return;
    }

    // Calculate grand total for bill metadata
    var grandTotal = 0;
    tableRows.forEach(function(r) { grandTotal += r.amount; });

    // Save bill to localStorage BEFORE form submit (page navigates away after submit)
    saveBillToLocalStorage(DEALER_ID, grandTotal);

    var items = tableRows.map(function(r) {
        return { productId: r.productId, productName: r.productName, quantity: r.qty, unitPrice: r.unitPrice, amount: r.amount };
    });
    document.getElementById('itemsJsonInput').value = JSON.stringify(items);
    document.getElementById('submitForm').submit();
}
</script>
</body>
</html>
