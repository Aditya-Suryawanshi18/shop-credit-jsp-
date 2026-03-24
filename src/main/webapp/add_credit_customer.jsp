<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, doa.DBConnection" %>
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
            color: #fff;
            border-radius: 14px;
            padding: 18px 24px;
            margin-bottom: 22px;
            display: flex;
            align-items: center;
            gap: 18px;
            flex-wrap: wrap;
            box-shadow: 0 6px 20px rgba(0,0,0,0.18);
        }
        .customer-card .avatar {
            width: 50px; height: 50px;
            background: rgba(255,255,255,0.15);
            border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            font-size: 24px;
            border: 2px solid rgba(255,255,255,0.3);
            flex-shrink: 0;
        }
        .customer-card .cinfo { flex: 1; }
        .customer-card .cinfo h3 { font-size: 17px; font-weight: 700; margin: 0 0 3px; }
        .customer-card .cinfo p  { font-size: 12px; color: #b8d4f0; margin: 0; }
        .customer-card .credit-pill {
            background: rgba(255,255,255,0.13);
            border: 1px solid rgba(255,255,255,0.25);
            border-radius: 10px;
            padding: 8px 18px;
            text-align: center;
        }
        .customer-card .credit-pill .lbl { font-size: 10px; color: #90b8d4; text-transform: uppercase; letter-spacing: 0.8px; }
        .customer-card .credit-pill .val { font-size: 18px; font-weight: 800; color: #7dffb3; margin-top: 2px; }

        /* ── Main layout: form left | table right ── */
        .main-layout {
            display: grid;
            grid-template-columns: 320px 1fr;
            gap: 20px;
            align-items: start;
        }
        @media (max-width: 860px) {
            .main-layout { grid-template-columns: 1fr; }
        }

        /* ── Input Panel (left) ── */
        .input-panel {
            background: #fff;
            border-radius: 14px;
            box-shadow: 0 4px 16px rgba(0,0,0,0.09);
            overflow: hidden;
            position: sticky;
            top: 10px;
        }
        .input-panel-header {
            background: linear-gradient(90deg, #2b0d73, #4a2fa0);
            color: #fff;
            padding: 13px 18px;
            font-size: 13px;
            font-weight: 700;
            letter-spacing: 0.5px;
        }
        .input-panel-body {
            padding: 18px;
            display: flex;
            flex-direction: column;
            gap: 14px;
        }
        .ip-group { display: flex; flex-direction: column; gap: 5px; }
        .ip-group label {
            font-size: 12px;
            font-weight: 700;
            color: #373279;
            letter-spacing: 0.3px;
        }
        .ip-group select,
        .ip-group input {
            padding: 9px 11px;
            border: 2px solid #c8b7f6;
            border-radius: 8px;
            font-size: 13px;
            color: #1a1a2a;
            background: #fff;
            outline: none;
            transition: border 0.2s;
            width: 100%;
            -moz-appearance: textfield;
        }
        .ip-group select:focus,
        .ip-group input:focus { border-color: #7c73b8; box-shadow: 0 0 0 3px rgba(124,115,184,0.12); }
        .ip-group input::-webkit-inner-spin-button,
        .ip-group input::-webkit-outer-spin-button { -webkit-appearance: none; }

        .stock-strip {
            display: none;
            align-items: center;
            gap: 8px;
            background: #f0f4ff;
            border: 1px solid #c8d8f8;
            border-radius: 7px;
            padding: 6px 12px;
            font-size: 12px;
            color: #2b0d73;
            font-weight: 600;
            margin-top: 4px;
        }
        .stock-strip .snum {
            background: #2b0d73; color: #fff;
            border-radius: 20px; padding: 1px 10px;
            font-size: 12px; font-weight: 700;
        }
        .stock-strip.low  { background: #fff8e1; border-color: #ffe082; color: #7a5c00; }
        .stock-strip.low  .snum { background: #f5a623; }
        .stock-strip.zero { background: #ffebee; border-color: #ffcdd2; color: #b71c1c; }
        .stock-strip.zero .snum { background: #e53935; }

        .row-total-preview {
            background: #f5f3ff;
            border: 1px dashed #c8b7f6;
            border-radius: 8px;
            padding: 9px 14px;
            font-size: 13px;
            color: #2b0d73;
            font-weight: 700;
            text-align: center;
            display: none;
        }

        .btn-add-to-table {
            width: 100%;
            padding: 11px;
            background: linear-gradient(135deg, #2b0d73, #4a2fa0);
            color: #fff;
            border: none;
            border-radius: 9px;
            font-size: 14px;
            font-weight: 700;
            cursor: pointer;
            transition: opacity 0.2s, transform 0.15s;
            letter-spacing: 0.4px;
        }
        .btn-add-to-table:hover { opacity: 0.88; transform: scale(1.02); }

        /* ── Table Panel (right) ── */
        .table-panel {
            background: #fff;
            border-radius: 14px;
            box-shadow: 0 4px 16px rgba(0,0,0,0.09);
            overflow: hidden;
        }
        .table-panel-header {
            background: linear-gradient(90deg, #182542, #2a5a8f);
            color: #fff;
            padding: 13px 18px;
            font-size: 13px;
            font-weight: 700;
            letter-spacing: 0.5px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .txn-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
        }
        .txn-table thead th {
            background: #f5f3ff;
            color: #373279;
            padding: 10px 12px;
            text-align: center;
            font-weight: 700;
            font-size: 12px;
            letter-spacing: 0.3px;
            border-bottom: 2px solid #c8b7f6;
            position: static;
        }
        .txn-table tbody td {
            padding: 9px 11px;
            border-bottom: 1px solid #ede9ff;
            text-align: center;
            vertical-align: middle;
        }
        .txn-table tbody tr:last-child td { border-bottom: none; }
        .txn-table tbody tr:hover { background: #f7f5ff; }
        .txn-table tfoot td {
            padding: 12px 14px;
            background: #2b0d73;
            color: #fff;
            font-weight: 700;
            font-size: 14px;
            text-align: right;
        }
        .txn-table tfoot td.grand-val {
            text-align: center;
            font-size: 16px;
            color: #7dffb3;
        }

        .empty-msg td {
            padding: 32px !important;
            color: #bbb;
            font-size: 13px;
            font-style: italic;
            text-align: center !important;
        }

        .btn-remove {
            width: 26px; height: 26px;
            background: #ffebee; color: #e53935;
            border: none; border-radius: 5px;
            font-size: 14px; font-weight: 700;
            cursor: pointer;
            display: inline-flex; align-items: center; justify-content: center;
            transition: background 0.2s;
            line-height: 1;
        }
        .btn-remove:hover { background: #e53935; color: #fff; }

        .prod-tag {
            background: #e8f0fe; color: #1a56db;
            padding: 3px 10px; border-radius: 20px;
            font-size: 12px; font-weight: 600;
        }
        .qty-num { font-weight: 700; color: #2b0d73; }
        .price-num { color: #555; }
        .total-num { font-weight: 700; color: #1b5e20; }

        /* ── Grand total bar ── */
        .grand-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: linear-gradient(90deg, #1b5e20, #2e7d32);
            color: #fff;
            border-radius: 10px;
            padding: 13px 20px;
            margin-top: 16px;
        }
        .grand-bar .g-label { font-size: 13px; color: #a5d6a7; font-weight: 600; }
        .grand-bar .g-val   { font-size: 22px; font-weight: 800; color: #e8f5e9; }
        .grand-bar .g-count { font-size: 11px; color: #81c784; margin-top: 1px; }

        /* ── Save / Cancel buttons ── */
        .save-row {
            display: flex;
            gap: 14px;
            margin-top: 16px;
            justify-content: flex-end;
        }
    </style>
</head>
<body>
<div class="content-wrapper">

    <% if (request.getParameter("error") != null) { %>
    <div class="alert alert-error">❌ <%= request.getParameter("error") %></div>
    <% } %>

    <a href="view_customers.jsp" class="back-link">← Back to Customers</a>

    <!-- Customer Banner -->
    <div class="customer-card">
        <div class="avatar">👤</div>
        <div class="cinfo">
            <h3><%= custName %></h3>
            <p>📞 <%= custPhone %> &nbsp;|&nbsp; Customer ID #<%= customerId %></p>
        </div>
        <div class="credit-pill">
            <div class="lbl">Current Credit</div>
            <div class="val">₹ <%= String.format("%.2f", custCredit) %></div>
        </div>
    </div>

    <!-- Two-column layout -->
    <div class="main-layout">

        <!-- LEFT: Input Form -->
        <div class="input-panel">
            <div class="input-panel-header">➕ Add Product</div>
            <div class="input-panel-body">

                <div class="ip-group">
                    <label for="productId">📦 Product <span style="color:#e53935;">*</span></label>
                    <select id="productId" onchange="onProductChange()">
                        <option value="" disabled selected>— Select product —</option>
                    </select>
                    <div class="stock-strip" id="stockStrip">
                        Available: <span class="snum" id="stockNum">0</span>
                    </div>
                </div>

                <div class="ip-group">
                    <label for="qty">🔢 Quantity <span style="color:#e53935;">*</span></label>
                    <input type="number" id="qty" placeholder="0" min="1"
                           oninput="updatePreview()" onchange="updatePreview()">
                </div>

                <div class="ip-group">
                    <label for="unitPrice">💰 Price / Unit (₹) <span style="color:#e53935;">*</span></label>
                    <input type="number" id="unitPrice" placeholder="0.00"
                           step="0.01" min="0.01"
                           oninput="updatePreview()" onchange="updatePreview()">
                </div>

                <!-- Live row total preview -->
                <div class="row-total-preview" id="rowTotalPreview">Row Total: ₹ 0.00</div>

                <button type="button" class="btn-add-to-table" onclick="addToTable()">
                    ➕ Add to Table
                </button>

            </div>
        </div>

        <!-- RIGHT: Transaction Table -->
        <div>
            <div class="table-panel">
                <div class="table-panel-header">
                    <span>🧾 Transaction Items</span>
                    <span id="itemCountBadge" style="background:rgba(255,255,255,0.15);
                          border-radius:20px; padding:2px 12px; font-size:12px;">
                        0 items
                    </span>
                </div>
                <table class="txn-table">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Product</th>
                            <th>Qty</th>
                            <th>Price / Unit (₹)</th>
                            <th>Total (₹)</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody id="txnBody">
                        <tr class="empty-msg" id="emptyRow">
                            <td colspan="6">← Add products using the form on the left</td>
                        </tr>
                    </tbody>
                    <tfoot>
                        <tr>
                            <td colspan="4" style="text-align:right; color:#90b8d4;">Grand Total</td>
                            <td class="grand-val" id="footerGrand">₹ 0.00</td>
                            <td></td>
                        </tr>
                    </tfoot>
                </table>
            </div>

            <!-- Grand total summary bar -->
            <div class="grand-bar">
                <div>
                    <div class="g-label">TOTAL CREDIT TO ADD</div>
                    <div class="g-val" id="grandDisplay">₹ 0.00</div>
                    <div class="g-count" id="grandCount">0 item(s)</div>
                </div>
                <span style="font-size:32px; opacity:0.35;">💳</span>
            </div>

            <!-- Save / Cancel -->
            <div class="save-row">
                <a href="view_customers.jsp" class="btn-clear"
                   style="text-decoration:none; display:inline-flex; align-items:center; justify-content:center; padding:10px 28px;">
                    Cancel
                </a>
                <button type="button" class="btn-save" onclick="submitTransaction()">
                    💾 Save Credit Transaction
                </button>
            </div>
        </div>
    </div>

    <!-- Hidden form for final submission -->
    <form id="submitForm" action="AddCreditServlet" method="post" style="display:none;">
        <input type="hidden" name="customerId" value="<%= customerId %>">
        <input type="hidden" name="itemsJson" id="itemsJsonInput">
    </form>
</div>

<script>
var PRODUCTS = <%= productsJson.toString() %>;
var tableRows = []; // {productId, productName, qty, unitPrice, amount, stock}
var rowSeq = 0;

// ── Populate product dropdown ──────────────────────────────────────────────
(function() {
    var sel = document.getElementById('productId');
    PRODUCTS.forEach(function(p) {
        var opt = document.createElement('option');
        opt.value = p.id;
        opt.text  = p.name + '  (Stock: ' + p.stock + ')';
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

// ── Product select change ──────────────────────────────────────────────────
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

    // Set qty max
    document.getElementById('qty').max = p.stock;
    updatePreview();
}

// ── Live row-total preview ─────────────────────────────────────────────────
function updatePreview() {
    var qty   = parseFloat(document.getElementById('qty').value)       || 0;
    var price = parseFloat(document.getElementById('unitPrice').value) || 0;
    var prev  = document.getElementById('rowTotalPreview');
    if (qty > 0 && price > 0) {
        prev.style.display  = 'block';
        prev.textContent    = 'Row Total: ₹ ' + (qty * price).toFixed(2);
    } else {
        prev.style.display  = 'none';
    }
}

// ── Add row to table ───────────────────────────────────────────────────────
function addToTable() {
    var sel   = document.getElementById('productId');
    var pid   = parseInt(sel.value, 10);
    var qty   = parseInt(document.getElementById('qty').value, 10);
    var price = parseFloat(document.getElementById('unitPrice').value);

    if (!pid)              { alert('⚠️ Please select a product.');           return; }
    if (!qty || qty <= 0)  { alert('⚠️ Please enter a valid quantity.');     return; }
    if (!price || price <= 0) { alert('⚠️ Please enter a valid unit price.'); return; }

    var p = getProduct(pid);
    if (!p) { alert('⚠️ Product not found.'); return; }

    // Check available stock vs already-added qty for same product
    var alreadyQty = 0;
    tableRows.forEach(function(r) { if (r.productId === pid) alreadyQty += r.qty; });
    if (alreadyQty + qty > p.stock) {
        alert('⚠️ Total quantity (' + (alreadyQty + qty) + ') exceeds available stock (' + p.stock + ') for: ' + p.name);
        return;
    }

    var rid    = ++rowSeq;
    var amount = parseFloat((qty * price).toFixed(2));
    tableRows.push({ rid: rid, productId: pid, productName: p.name, qty: qty, unitPrice: price, amount: amount, stock: p.stock });

    renderTable();
    resetForm();
}

// ── Render table ───────────────────────────────────────────────────────────
function renderTable() {
    var tbody  = document.getElementById('txnBody');
    tbody.innerHTML = '';

    if (tableRows.length === 0) {
        tbody.innerHTML = '<tr class="empty-msg" id="emptyRow"><td colspan="6">← Add products using the form on the left</td></tr>';
        updateGrandTotal();
        return;
    }

    tableRows.forEach(function(r, idx) {
        var tr = document.createElement('tr');
        tr.innerHTML =
            '<td style="color:#888; font-size:12px;">' + (idx + 1) + '</td>' +
            '<td><span class="prod-tag">📦 ' + r.productName + '</span></td>' +
            '<td class="qty-num">' + r.qty + '</td>' +
            '<td class="price-num">₹ ' + r.unitPrice.toFixed(2) + '</td>' +
            '<td class="total-num">₹ ' + r.amount.toFixed(2) + '</td>' +
            '<td><button class="btn-remove" onclick="removeRow(' + r.rid + ')" title="Remove">✕</button></td>';
        tbody.appendChild(tr);
    });

    updateGrandTotal();
}

// ── Remove row ─────────────────────────────────────────────────────────────
function removeRow(rid) {
    tableRows = tableRows.filter(function(r) { return r.rid !== rid; });
    renderTable();
}

// ── Grand total ────────────────────────────────────────────────────────────
function updateGrandTotal() {
    var grand = 0;
    tableRows.forEach(function(r) { grand += r.amount; });
    document.getElementById('footerGrand').textContent = '₹ ' + grand.toFixed(2);
    document.getElementById('grandDisplay').textContent = '₹ ' + grand.toFixed(2);
    document.getElementById('grandCount').textContent   = tableRows.length + ' item(s)';
    document.getElementById('itemCountBadge').textContent = tableRows.length + ' item' + (tableRows.length !== 1 ? 's' : '');
}

// ── Reset input form ───────────────────────────────────────────────────────
function resetForm() {
    document.getElementById('productId').value = '';
    document.getElementById('qty').value       = '';
    document.getElementById('unitPrice').value = '';
    document.getElementById('stockStrip').style.display = 'none';
    document.getElementById('rowTotalPreview').style.display = 'none';
}

// ── Submit ─────────────────────────────────────────────────────────────────
function submitTransaction() {
    if (tableRows.length === 0) {
        alert('⚠️ Please add at least one product to the table before saving.');
        return;
    }
    var items = tableRows.map(function(r) {
        return {
            productId:   r.productId,
            productName: r.productName,
            quantity:    r.qty,
            unitPrice:   r.unitPrice,
            amount:      r.amount
        };
    });
    document.getElementById('itemsJsonInput').value = JSON.stringify(items);
    document.getElementById('submitForm').submit();
}
</script>
</body>
</html>
