<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, doa.DBConnection" %>
<%
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=Please login first");
        return;
    }
    String keyword = request.getParameter("keyword");
    boolean hasKeyword = (keyword != null && !keyword.trim().isEmpty());
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Products</title>
    <link rel="stylesheet" href="css/content.css">
    <style>
        /* ── Quick-add inline panel ── */
        .quick-add-panel {
            background: #f5f3ff;
            border: 2px solid #c8b7f6;
            border-radius: 14px;
            padding: 18px 22px;
            margin-bottom: 20px;
            display: flex;
            align-items: flex-end;
            gap: 14px;
            flex-wrap: wrap;
        }
        .quick-add-panel .qa-group {
            display: flex;
            flex-direction: column;
            gap: 5px;
            flex: 1;
            min-width: 160px;
        }
        .quick-add-panel label {
            font-size: 12px;
            font-weight: 700;
            color: #373279;
            letter-spacing: 0.3px;
        }
        .quick-add-panel input {
            padding: 9px 12px;
            border: 2px solid #c8b7f6;
            border-radius: 8px;
            font-size: 14px;
            color: #1a1a2a;
            background: #fff;
            outline: none;
            transition: border 0.2s;
            -moz-appearance: textfield;
        }
        .quick-add-panel input::-webkit-inner-spin-button,
        .quick-add-panel input::-webkit-outer-spin-button { -webkit-appearance: none; }
        .quick-add-panel input:focus { border-color: #7c73b8; }
        .qa-badge {
            background: linear-gradient(135deg, #2b0d73, #4a2fa0);
            color: #fff;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 700;
            letter-spacing: 0.5px;
            white-space: nowrap;
        }
        /* ── Quantity badge in table ── */
        .qty-badge {
            display: inline-block;
            padding: 3px 14px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 700;
        }
        .qty-ok   { background: #e8f5e9; color: #2e7d32; }
        .qty-low  { background: #fff3e0; color: #e65100; }
        .qty-zero { background: #ffebee; color: #c62828; }
        /* ── Delete btn ── */
        .btn-delete {
            padding: 5px 12px;
            background: #ff5252;
            color: #fff;
            border: none;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.2s;
        }
        .btn-delete:hover { background: #b71c1c; }
    </style>
</head>
<body>

<div class="content-wrapper">

    <!-- Status messages -->
    <% if (request.getParameter("success") != null) { %>
    <div class="alert alert-success">✅ <%= request.getParameter("success") %></div>
    <% } %>
    <% if (request.getParameter("error") != null) { %>
    <div class="alert alert-error">❌ <%= request.getParameter("error") %></div>
    <% } %>

    <!-- Quick-Add Product Form -->
    <form action="AddProductServlet" method="post"
          onsubmit="return validateProduct()">
        <div class="quick-add-panel">
            <span class="qa-badge">➕ Add New Product</span>

            <div class="qa-group">
                <label for="productName">Product Name *</label>
                <input type="text" id="productName" name="productName"
                       placeholder="Enter product name" maxlength="150" required>
            </div>

            <div class="qa-group" style="max-width:160px;">
                <label for="quantity">Initial Quantity *</label>
                <input type="number" id="quantity" name="quantity"
                       placeholder="0" min="0" required>
            </div>

            <button type="submit" class="btn-save" style="padding:10px 26px; font-size:14px;">
                💾 Save
            </button>
        </div>
    </form>

    <!-- Search Bar -->
    <form class="search-bar" action="view_products.jsp" method="get">
        <input type="text" name="keyword" placeholder="🔍 Search by Product Name or ID"
               value="<%= hasKeyword ? keyword : "" %>">
        <button type="submit" class="btn-search">Search</button>
        <a href="view_products.jsp" class="btn-reset">Reset</a>
    </form>

    <!-- Products Table -->
    <div class="table-container">
        <table>
            <thead>
                <tr>
                    <th>#</th>
                    <th>Product ID</th>
                    <th>Product Name</th>
                    <th>Quantity</th>
                    <th>Delete</th>
                </tr>
            </thead>
            <tbody>
            <%
                String sql = "SELECT * FROM products";
                if (hasKeyword) sql += " WHERE LOWER(product_name) LIKE ? OR id = ?";
                sql += " ORDER BY id ASC";

                try (Connection conn = DBConnection.getConnection();
                     PreparedStatement ps = conn.prepareStatement(sql)) {

                    if (hasKeyword) {
                        ps.setString(1, "%" + keyword.toLowerCase() + "%");
                        try { ps.setInt(2, Integer.parseInt(keyword)); }
                        catch (NumberFormatException ex) { ps.setInt(2, -1); }
                    }

                    ResultSet rs = ps.executeQuery();
                    boolean hasData = false;
                    int sNo = 1;

                    while (rs.next()) {
                        hasData = true;
                        int    id       = rs.getInt("id");
                        String pname    = rs.getString("product_name");
                        int    qty      = rs.getInt("quantity");
                        String qtyClass = qty == 0 ? "qty-zero" : (qty <= 10 ? "qty-low" : "qty-ok");
                        String qtyLabel = qty == 0 ? "Out of Stock" : (qty <= 10 ? "Low Stock" : "In Stock");
            %>
                <tr>
                    <td><%= sNo++ %></td>
                    <td><strong style="color:#2b0d73;">P-<%= String.format("%04d", id) %></strong></td>
                    <td style="text-align:left; font-weight:600;">
                        <span style="font-size:15px;">📦</span> <%= pname %>
                    </td>
                    <td>
                        <span class="qty-badge <%= qtyClass %>"><%= qty %></span>
                        <span style="font-size:11px; color:#999; margin-left:4px;">(<%= qtyLabel %>)</span>
                    </td>
                    <td>
                        <form action="DeleteProductServlet" method="post"
                              onsubmit="return confirm('Delete product: <%= pname %>?')">
                            <input type="hidden" name="id" value="<%= id %>">
                            <button type="submit" class="btn-delete">🗑 Delete</button>
                        </form>
                    </td>
                </tr>
            <%
                    }
                    if (!hasData) {
            %>
                <tr><td colspan="5" class="no-data">⚠ No products found. Add your first product above.</td></tr>
            <%
                    }
                } catch (Exception e) {
            %>
                <tr>
                    <td colspan="5" class="no-data">
                        ❌ Error: <%= e.getMessage() %><br>
                        <small style="color:#888;">Make sure the <code>products</code> table exists.</small>
                    </td>
                </tr>
            <%
                }
            %>
            </tbody>
        </table>
    </div>

    <!-- Stock summary chips -->
    <%
        int totalProducts = 0, inStock = 0, lowStock = 0, outStock = 0;
        try (Connection conn = DBConnection.getConnection()) {
            ResultSet r1 = conn.createStatement().executeQuery("SELECT COUNT(*) FROM products");
            if (r1.next()) totalProducts = r1.getInt(1);
            ResultSet r2 = conn.createStatement().executeQuery("SELECT COUNT(*) FROM products WHERE quantity > 10");
            if (r2.next()) inStock = r2.getInt(1);
            ResultSet r3 = conn.createStatement().executeQuery("SELECT COUNT(*) FROM products WHERE quantity > 0 AND quantity <= 10");
            if (r3.next()) lowStock = r3.getInt(1);
            ResultSet r4 = conn.createStatement().executeQuery("SELECT COUNT(*) FROM products WHERE quantity = 0");
            if (r4.next()) outStock = r4.getInt(1);
        } catch (Exception e) { /* ignore */ }
    %>
    <div class="stats-row" style="margin-top:18px;">
        <div class="stat-chip">
            <div class="s-label">Total Products</div>
            <div class="s-value"><%= totalProducts %></div>
        </div>
        <div class="stat-chip green">
            <div class="s-label">In Stock</div>
            <div class="s-value"><%= inStock %></div>
        </div>
        <div class="stat-chip">
            <div class="s-label">Low Stock (≤10)</div>
            <div class="s-value" style="color:#e65100;"><%= lowStock %></div>
        </div>
        <div class="stat-chip red">
            <div class="s-label">Out of Stock</div>
            <div class="s-value"><%= outStock %></div>
        </div>
    </div>

</div>

<script>
function validateProduct() {
    var name = document.getElementById('productName').value.trim();
    var qty  = document.getElementById('quantity').value;
    if (!name) { alert('⚠️ Please enter product name.'); return false; }
    if (qty === '' || parseInt(qty) < 0) { alert('⚠️ Please enter a valid quantity.'); return false; }
    return true;
}
</script>
</body>
</html>
